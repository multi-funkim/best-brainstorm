function [OPTIONS, obj_slice, obj_const] = be_slice_obj(Data, obj, OPTIONS)

    nbSmp       = size(Data,2); 
    nb_sensors  = size(Data,1); 

    obj_slice(nbSmp)    = struct();

    % Normalize MNE at each time-point
    Jmne = OPTIONS.automatic.Modality(1).Jmne;
    Jmne = Jmne ./ max(abs(Jmne));


    for i = 1:nbSmp
        
        obj_slice(i).data   = Data(:,i);
        obj_slice(i).time   = obj.time(:,i);
        obj_slice(i).scale  = obj.scale(:,i);

        clusters            = obj.CLS(:,i);
        nb_clusters         = max(clusters);
        active_probability  = zeros(nb_clusters,1);

        for ii = 1:nb_clusters
            idx_cluster  = find(clusters == ii);
            active_probability(ii) = obj.ALPHA(idx_cluster(1),i);
        end

        obj_slice(i).active_probability = active_probability;
        
        % estimate active mean
        % Method 1: initialization FROM the null hypothesis (alpha=1, mu=0)
        % Method 2: Method used by Christophe
        % Method 3: initialization from the null hypothesis (witout null parcels)
        % Method 4: initialization from the MNE with l-curve

        active_mean = [];
        % Preliminar computation (used in the minimum norm solution)
        if OPTIONS.model.active_mean_method == 3
            GpGpt = obj.gain(:,clusters~=0)*obj.gain(:,clusters~=0)';
            regul = trace(GpGpt)/sum(clusters~=0);
            [U,S,V] = svd(GpGpt + regul*eye(nb_sensors));
            eigen = diag(S);
            I = find(cumsum(eigen.^2)./ sum(eigen.^2) > 0.9,1,'first');
            GpGptinv_M = V(:,1:I) * diag(1./eigen(1:I)) * U(:,1:I)' * Data(:,i);
        end

        if OPTIONS.model.active_mean_method ~= 2 % active mean == 0
            active_mean = zeros(nb_clusters,1);
            for ii = 1:nb_clusters
                idx_cluster     = find(clusters == ii);
                switch OPTIONS.model.active_mean_method
                    case 1  % Method 1
                        % the following function is in /misc
                        MNS = be_solve_wmn(Data(:,i)+rand(size(Data(:,i)))*10, obj.gain, speye(nb_sources) );
                        active_mean(ii) = mean( MNS(idx_cluster) );
                    case 3  % Methode 3 (Minimum Norm regularized without null parcel)
                        active_mean(ii) = mean( obj.gain(:,idx_cluster)'*GpGptinv_M);
                    case 4
                        active_mean(ii) = mean( Jmne(idx_cluster,i));
                    otherwise
                        error('Wrong MU Method')
                end
             end
        end
        obj_slice(i).active_mean = active_mean;

        % check if there's a noise cov for each scale
        if (size(obj.noise_var,3) > 1) && OPTIONS.optional.baseline_shuffle ~= 1
            obj_slice(i).noise_var = squeeze(obj.noise_var(:,:,OPTIONS.automatic.selected_samples(2,ii)) );
        
        elseif (size(obj.noise_var,3)>1) && OPTIONS.optional.baseline_shuffle == 1
            tol = OPTIONS.optional.baseline_shuffle_windows / 2; 
            idx_baseline = find(obj.time(i) > OPTIONS.automatic.Modality(1).BaselineTime(1,:) & ...
                                obj.time(i) <=  (OPTIONS.automatic.Modality(1).BaselineTime(end,:)+tol));
        
            if isempty(idx_baseline) && obj.time(i) > max(max(OPTIONS.automatic.Modality(1).BaselineTime))
                idx_baseline = size(OPTIONS.automatic.Modality(1).BaselineTime,2);
            elseif isempty(idx_baseline) && obj.time(i) < min(min(OPTIONS.automatic.Modality(1).BaselineTime))
                idx_baseline = 1;
            elseif length(idx_baseline) > 1
                idx_baseline = idx_baseline(2);
            end
    
            obj_slice(i).noise_var = squeeze(obj.noise_var(:,:, idx_baseline) );
        else
            obj_const.noise_var = obj.noise_var;
        end

    end



    % Smooth the coveriance matrix along the cortical surface
    if strcmp(OPTIONS.clustering.clusters_type, 'static')
        obj_const.clusters = obj.CLS(:,1);
        if isfield(OPTIONS.optional.clustering, 'initial_sigma')
            [ obj_const.active_var,  obj_const.G_active_var_Gt]   = be_smooth_sigma_s(obj.gain, OPTIONS.optional.clustering.initial_sigma, obj_const.clusters,  obj.GreenM2);
        else
            [ obj_const.active_var,  obj_const.G_active_var_Gt]   = be_smooth_sigma_s(obj.gain, obj.Sigma_s, obj_const.clusters,  obj.GreenM2);
        end

    else
        for i = 1:nbSmp
            obj_slice(i).clusters = obj.CLS(:,i);
            if isfield(OPTIONS.optional.clustering, 'initial_sigma')
                [obj_slice(i).active_var, obj_slice(i).G_active_var_Gt]   = be_smooth_sigma_s(obj.gain, OPTIONS.optional.clustering.initial_sigma, obj_slice(i).clusters,  obj.GreenM2);
            else
                [obj_slice(i).active_var, obj_slice(i).G_active_var_Gt]   = be_smooth_sigma_s(obj.gain, obj.Sigma_s, obj_slice(i).clusters,  obj.GreenM2);
            end
        end
    end


    % Estimate the active variance 
    % Multiply Signa_s by 5% of the MNE solution
    if strcmp(OPTIONS.clustering.clusters_type, 'static')
        clusters = obj.CLS(:,1);
        energy = zeros(max(clusters),nbSmp);
        for ii = 1:max(clusters)
            energy(ii,:)  = OPTIONS.solver.active_var_mult * mean(Jmne(clusters == ii,:).^2);
        end

        for i = 1:nbSmp
            obj_slice(i).mne_energy = energy(:,i);            
        end
    else
        for i = 1:nbSmp
            clusters = obj.CLS(:,i);
            energy = zeros(max(clusters),1);
            for ii = 1:max(clusters)
                energy(ii) = OPTIONS.solver.active_var_mult * mean(Jmne(clusters == ii,i).^2);        
            end
            obj_slice(i).mne_energy = energy;
        end
    end
    

    obj_const.gain          = obj.gain;
    obj_const.nb_sources    = obj.nb_sources;
    obj_const.nb_channels   = obj.nb_channels;
    obj_const.nb_dipoles    = obj.nb_dipoles;

    OPTIONS.automatic   = rmfield(OPTIONS.automatic,'Modality');
    OPTIONS             = rmfield(OPTIONS,'mandatory');
    OPTIONS.optional.TimeSegment = [];
    OPTIONS.optional.Baseline    = [];

    MAX_ITER = 10000;  % The maximum number of itterations

    if strcmpi(OPTIONS.solver.Optim_method, 'fminunc') && ...
       license('test', 'Optimization_Toolbox') && ...
       exist('fminunc', 'file')

        OPTIONS.solver.optimoptions =   optimoptions('fminunc','GradObj', 'on', ...
                                                    'MaxIter', MAX_ITER, ...
                                                    'MaxFunEvals', MAX_ITER, ...
                                                    'algorithm', 'quasi-newton',... % 'quasi-newton' trust-region'
                                                    'Display', 'off' );
    else

        if strcmpi(OPTIONS.solver.Optim_method, 'fminunc')
            disp(['BEst> No license found for the Optimization Toolbox or ', ...
                'missing the function ''fminunc''.'])
            disp('BEst> Using alternate optimization routine...')

            OPTIONS.solver.Optim_method = 'minfuncnm';
        end
    
        options = [];
        options.MaxIter = MAX_ITER;
        options.MaxFunEvals = MAX_ITER;
        options.Display = 'off';
        if strcmpi(OPTIONS.solver.Optim_method, 'minfuncnm')
            options.useMex = 0;
        end

        OPTIONS.solver.optimoptions = options;
    end

end
