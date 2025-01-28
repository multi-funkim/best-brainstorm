function [OPTIONS, mem, active_var_out] = be_memstruct(OPTIONS, obj)
%BE_MEMSTRUCT Generates the MEM initial structure.
%   MEM = BE_MEMSTRUCT(obj, OPTIONS) initializes all the parameters to 
%   launch the MEM  and returns them in a structure. See below for 
%   description of all the fields.  
%   The input parameter obj is a structure containing the field data, the
%   field gain, a field clusters and a field containing the initialize
%   alphas (active_probability).
%   The structure MEM can be used with the fuction solve_mem.
%
%   INPUTS:
%       -obj: structure containing data, gain and other parameters. See
%             be_memsolver_multiM for more details.
%       -OPTIONS: structure for setting optional parameters. See
%             be_memsolver_multiM for more details.
%
%   Details of the MEM output structure
%       MEM                             STRUCT  [1x1]
%           with fields:
%       LAMBDA:                         DOUBLE  [Nb Sensors x 1]
%
%       M (mesures normalized):         DOUBLE  [Nb Sensors x 1]
%
%       NOISE_VAR (sigma):              DOUBLE  [1 x 1]
%
%       NB_SOURCES (number of sources)  DOUBLE  [1 x 1]
%
%       NB_CLUSTERS (number of clusters) DOUBLE [1 x 1]
%
%       CLUSTERS:                       STRUCT  [1 x Nb Clusters]
%           with fields:
%           G (normalized):             DOUBLE  [NB Sensors x 
%                                                    Nb Dipoles In Cluster]
%           ACTIVE_PROBABILITY (alpha): DOUBLE  [1 x 1]
%
%           ACVIVE_MEAN (mu):           DOUBLE  [Nb Dipoles In Cluster x 1]
%
%           ACTIVE_VAR (capital sigma): DOUBLE  [Nb Dipoles In Cluster x 
%                                                   Nb Dipoles In Cluster]
%           INACTIVE_VAR (omega):       DOUBLE  [Nb Dipoles In Cluster x 
%                                                    Nb Dipoles In Cluster]
%           INDICES                     DOUBLE  [1 x Nb Dipoles In Cluster] 
%
%   Description of each field of the MEM structure:
%   LAMBDA is the hyperparameter to maximize. M are the normalized mesures.
%   NOISE_VAR represents the variance of the noise function.  NB_SOURCES is
%   the number of sources in the solution.  CLUSTERS is a structure that
%   contains all the information of each cluster. 
%
%   Description of each field of the CLUSTERS structure:
%   G is the normalized lead field matrix associated with the cluster.
%   ACTIVE_PROBABILITY is a DOUBLE representing the probability for the 
%   cluster of being active (1 = active). ACTIVE_MEAN and ACTIVE_VAR is the
%   mean and the variance-covariance matrix of the active state function.
%   INACTIVE_VAR is the variance-covariance matrix of the inactive state 
%   fuction.  INDICES is the index number of each dipole in the cluster.  
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

% some basic parameters
nb_clusters = max(obj.clusters);
nb_sources  = obj.nb_sources;
nb_sensors  = obj.nb_channels;

% some definitions 
clusters_struct(nb_clusters) = struct;
cluster_G   = cell(1,nb_clusters);
cID         = cell(1,nb_clusters);
active_mean = cell(1,nb_clusters);
inactive_var= cell(1,nb_clusters);
active_var_out = zeros(obj.nb_sources,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the following loop goes though each of the clusters (non null clusters)
% and initializes the parameters of the model attached to each of them

% ALPHA: activation probability (alpha's) 
proba = num2cell(obj.active_probability);

for ii = 1:nb_clusters

    % CLUSTER: Extraction of the parcel-wise lead field and index of sources
    idx_cluster     = find(obj.clusters == ii);
    cluster_G{ii}   = obj.gain(:,idx_cluster);
    cID{ii}         = idx_cluster;

    if ~isempty(obj.active_mean)
        active_mean{ii} = obj.active_mean(ii) * ones(length(idx_cluster),1);
    end

    % Multiply the active variance by the MNE energy
    obj.active_var{ii} = obj.active_var{ii}     * obj.mne_energy(ii);
    obj.G_active_var_Gt{ii}     = obj.G_active_var_Gt{ii} * obj.mne_energy(ii);
    active_var_out(idx_cluster) = diag( obj.active_var{ii} );
    
    % SIGMA0: variance of the inactive state (not relevant for the present version)
    if OPTIONS.solver.inactive_var_mult ~= 0 
        inactive_var{ii} = eye(length(idx_cluster)) * abs(OPTIONS.solver.inactive_var_mult);   
    else
        inactive_var{ii} = [];
    end

end  
        

% Creation of the cluster structure 
[clusters_struct.G]                  = cluster_G{:};
[clusters_struct.active_probability] = proba{:};
[clusters_struct.active_mean]        = active_mean{:};
[clusters_struct.active_var]         = obj.active_var{:};
[clusters_struct.inactive_var]       = inactive_var{:};  
[clusters_struct.G_active_var_Gt]    = obj.G_active_var_Gt{:};  
[clusters_struct.indices]            = cID{:};

% Creation of the structure to solve the MEM
mem.clusters                         = clusters_struct;
mem.noise_var                        = obj.noise_var;
mem.M                                = obj.data;
mem.nb_sources                       = nb_sources;
mem.nb_clusters                      = nb_clusters;
mem.optim_algo                       = OPTIONS.solver.Optim_method;
mem.optimoptions                     = OPTIONS.solver.optimoptions;
mem.G_active_var_Gt                  = cat(3,obj.G_active_var_Gt{:});

% Lambda initialization
switch OPTIONS.model.initial_lambda 
    
    case 0
        mem.lambda	=   zeros(nb_sensors,1);
    
    case 1
        mem.lambda	=   randn(nb_sensors,1) /mean( abs(mem.M) ); % initial value for threshold diff 0

end


end
