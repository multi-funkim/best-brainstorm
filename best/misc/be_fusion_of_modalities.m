function [obj] = be_fusion_of_modalities(obj, OPTIONS, isVerbose)
%BE_FUSION_OF_MODALITIES fuses data and leadfields from different modalities 
% for multimodal sources estimation using MEM
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
%
%   OUTPUTS:
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

if nargin < 3 || isempty(isVerbose)
    isVerbose =  OPTIONS.optional.verbose;
end

% Display information
if isVerbose && length(OPTIONS.mandatory.DataTypes) > 1 
    fprintf('%s, MULTIMODAL data ... %s found \n',OPTIONS.mandatory.pipeline, strjoin(OPTIONS.mandatory.DataTypes,', '));
elseif isVerbose && length(OPTIONS.mandatory.DataTypes) == 1
    fprintf('%s, No multimodalities ... \n',OPTIONS.mandatory.pipeline);
end

% Concatenate Gain and normalized gain
obj.gain = vertcat(OPTIONS.automatic.Modality.gain);

obj.gain_normalized = [];
if isfield(OPTIONS.automatic.Modality(1), 'gain_struct') && isfield(OPTIONS.automatic.Modality(1).gain_struct, 'Gn')
    for ii=1:length(OPTIONS.mandatory.DataTypes)
        obj.gain_normalized   = vertcat(obj.gain_normalized, OPTIONS.automatic.Modality(ii).gain_struct.Gn);
    end
end
% Concatenate data and normalized data
data = [];
data_normalized = [];

for ii=1:length(OPTIONS.mandatory.DataTypes)
    if isfield(obj, 'data') % wavelet
        data_mod = obj.data{ii};
    else % Time-series
        data_mod = OPTIONS.automatic.Modality(ii).data;
    end
    
    data = vertcat(data, data_mod);
    data_normalized = vertcat(data_normalized, bsxfun(@rdivide, data_mod, sqrt(sum(data_mod.^2, 1))));
end
% remove nan from normalized data
data_normalized(isnan(data_normalized)) = 0;

obj.data = data;
obj.data_normalized = data_normalized;

% Concatenate idata(complex data) if present
if isfield(OPTIONS.automatic.Modality(1),'idata')
    obj.idata   = vertcat(OPTIONS.automatic.Modality.idata);
end

% Concatenate noise covariance
if size(OPTIONS.automatic.Modality(1).covariance,3) > 1  % we concatanate for each covariance matrix
    obj.noise_var = OPTIONS.automatic.Modality(1).covariance;
    for ii=2:length(OPTIONS.mandatory.DataTypes)
        tmp = [];
        for ibaseline = 1:size(obj.noise_var,3)
            tmp(:,:,ibaseline) = blkdiag(obj.noise_var(:,:,ibaseline),OPTIONS.automatic.Modality(ii).covariance(:,:,ibaseline));
        end
        obj.noise_var = tmp;
    end
else
    obj.noise_var   = blkdiag(OPTIONS.automatic.Modality.covariance);
end

% Concatenate baseline and channels
obj.baseline    = vertcat(OPTIONS.automatic.Modality.baseline);
obj.channels    = vertcat(OPTIONS.automatic.Modality.channels);

if isVerbose, fprintf(' done.\n'); end

end
