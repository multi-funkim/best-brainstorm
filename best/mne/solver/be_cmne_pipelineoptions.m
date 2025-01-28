function DEF = be_cmne_pipelineoptions(DataTypes)

        if nargin < 1 || isempty(DataTypes)
            DataTypes = {'EEG'};
        end

        % clustering
        DEF.clustering.clusters_type     	= 'static';
        DEF.solver.mne_method               = 'mne_lcurve';

        DEF.model.alpha_threshold          	= 0.0;
        DEF.model.active_mean_method      	= 2;
        DEF.model.alpha_method              = 3;

        if any(ismember( 'NIRS', DataTypes))
            DEF.model.depth_weigth_MNE          = 0.3;
        else
            DEF.model.depth_weigth_MNE          = 0.5;
        end


        % automatic 
        DEF.automatic.selected_samples       = [];
        
        % solver
        DEF.solver.NoiseCov_method           = 2;
        DEF.solver.mne_use_noiseCov          = 1;

        % optional
        DEF.optional.normalization           = 'fixed'; 

end