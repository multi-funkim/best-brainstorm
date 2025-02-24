function [ImageGridAmp, OPTIONS] = be_launch_mem(obj, OPTIONS)
% BE_LAUNCH_MEM loops on all time samples and solves the MEM 
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
%
%   OUTPUTS:
%       -   ImageGridAMp    :   MEM solution (matrix NsourcesxNtimesamples)
%       -   OPTIONS
%       -   obj
%
%% ==============================================   
% Copyright (C) 2011 - LATIS Team
%
%  Authors: LATIS team, 2011
%
%% ==============================================
% License 
%
% BEst is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    BEst is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with BEst. If not, see <http://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------   

% All samples or a selection?
Data  = [];

if ~isempty(OPTIONS.automatic.selected_samples)        
    Data = obj.data(:,OPTIONS.automatic.selected_samples(1,:));                 
elseif ~strcmp(OPTIONS.mandatory.pipeline,'wMEM')
    Data  = obj.data;
end

% time series or wavelet representation
nbSmp           = size(Data,2);

if strcmp(OPTIONS.mandatory.pipeline,'wMEM')
    obj.time     = OPTIONS.automatic.selected_samples(6,:); 
    obj.scale    = OPTIONS.automatic.selected_samples(2,:); 
    if ~OPTIONS.wavelet.single_box
        ImageSourceAmp  = zeros(length(obj.iModS), nbSmp);
    else
        ImageSourceAmp  = zeros( length(obj.iModS), 1 );
    end
else
    obj.time        = obj.t0+(1:nbSmp)/OPTIONS.automatic.sampling_rate; 
    obj.scale       = zeros(1,nbSmp); 
    ImageSourceAmp  = zeros(length(obj.iModS), nbSmp);  
end

% fixed parameters
entropy_drop    = zeros(1,nbSmp);
final_alpha     = cell(1,nbSmp);
final_sigma     = cell(1,nbSmp);


% Pre-compute Sigma_s
G = obj.gain;
if OPTIONS.model.depth_weigth_MEM > 0 

    p = OPTIONS.model.depth_weigth_MEM;
    obj.Sigma_s  = sparse(diag(power(diag(G'*G) ,-p))) ;
else

    obj.Sigma_s  = speye(size(G,2)) ; 
end

if ~OPTIONS.automatic.stand_alone
    bst_progress('start', 'Solving MEM', 'Solving MEM', 0, nbSmp);
end

isVerbose       = OPTIONS.optional.verbose;
isStandAlone    = OPTIONS.automatic.stand_alone;

[OPTIONS_litle, obj_slice, obj_const] = be_slice_obj(Data, obj, OPTIONS);


if OPTIONS.solver.parallel_matlab == 1    
    
    q = parallel.pool.DataQueue;
    if ~OPTIONS.automatic.stand_alone
        afterEach(q, @(x) bst_progress('inc', 1));
    end

    time_it_starts = tic;
    parfor ii = 1 : nbSmp
        
        [R, E, A, S] = MEM_mainLoop(ii, obj_slice(ii), obj_const, OPTIONS_litle);

        entropy_drop(ii)        =  E;
        final_alpha{ii}         =  A;
        final_sigma{ii}         =  S;
        ImageSourceAmp(:, ii)   =  R;
        if ~isStandAlone
            send(q, 1); 
        end
    end
    time_it_ends = toc(time_it_starts);
    if isVerbose
        fprintf('%s, Elapsed CPU time is %5.2f seconds.\n', OPTIONS.mandatory.pipeline, time_it_ends);
    end

else
    if isVerbose
        fprintf('%s, MEM at each samples (%d samples, may be done in parallel):', OPTIONS.mandatory.pipeline, nbSmp);
        fprintf('\nMultiresolution sample (j,t): j=0 corresponds to the sampling scale.\n');
    end

    time_it_starts = tic;
    for ii = 1 : nbSmp

        [R, E, A, S] = MEM_mainLoop(ii, obj_slice(ii), obj_const, OPTIONS_litle);

        entropy_drop(ii)	    = E;        
        final_alpha{ii}  	    = A;
        final_sigma{ii}         = S;
        ImageSourceAmp(:, ii)   = R;

        if ~isStandAlone
            bst_progress('inc', 1);
        end
        
    end
    time_it_ends = toc(time_it_starts);
    if isVerbose
        fprintf('%s, Elapsed CPU time is %5.2f seconds.\n', OPTIONS.mandatory.pipeline, time_it_ends);
    end
end

if ~isStandAlone
    bst_progress('stop');
end

% store the results where it should be
if strcmp(OPTIONS.mandatory.pipeline, 'wMEM') && OPTIONS.wavelet.single_box
    ImageGridAmp = [];
    OPTIONS.automatic.wActivation   =   full(ImageSourceAmp);
else
    ImageGridAmp = zeros( obj.nb_dipoles, size(ImageSourceAmp,2) );
    ImageGridAmp(obj.iModS,:) = ImageSourceAmp;
    
    OPTIONS.automatic.wActivation = [];
end


OPTIONS.automatic.entropy_drops = entropy_drop;
OPTIONS.automatic.final_alpha   = final_alpha;
OPTIONS.automatic.final_sigma   = final_sigma;

end

% =========================================================================

function [R, E, A, S] = MEM_mainLoop(ii, obj, obj_const, OPTIONS)
    obj = be_struct_copy_fields(obj, obj_const, []);
    
    if ~sum(obj.clusters)
        if OPTIONS.optional.verbose
            disp(['MEM warning: The distributed dipoles could not be clusterized at sample ' num2str(ii) '. (null solution returned)']);
        end
        
        % Save empty solution
        R   = zeros( size(obj.iModS) );
        E   = NaN; A   = NaN; S   = [];
        return;
    end
    
        
    % initialize the MEM
    [OPTIONS, mem_structure, act_var] = be_memstruct(OPTIONS,obj);
    
    % solve the MEM for the current time
    [J, mem_results_struct] = be_solve_mem(mem_structure);  

    nclus       = max(obj.clusters);
    niter       = mem_results_struct.iterations;
    entropy_drop= mem_results_struct.entropy;
    act_proba   = mem_results_struct.active_probability;    

    if OPTIONS.optional.verbose, fprintf('Sample %3d(%2d,%3.3f):',ii,obj.scale,obj.time); end
    
    % Print output
    if any(isnan(J))
        fprintf('killed\n');
        J(isnan(J)) = 0;

        
    elseif OPTIONS.optional.verbose
        fprintf('\n\t\t%3d clusters,\n\t\t%3d iter.\n\t\tEntropy drop:%4.1f\n',nclus,niter,entropy_drop); 
    end
        
    
    R = J;
    E = entropy_drop;
    A = act_proba;
    S = act_var;
    
end
