function [J, varargout] = be_jmne_normalized(obj, OPTIONS)
% Compute the MNE solution on the normalized data.
% Similar to be_jme with a regularization parameter of 0; applied on the
% normalized data
%% ==============================================
% Copyright (C) 2011 - Christophe Grova
%
%  Authors: Christophe Grova, 2011
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
% --------------------



    Gn = obj.gain_normalized; 
    
    % selection of the data:
    Mn = obj.data_normalized;
    if ~isempty(OPTIONS.automatic.selected_samples)   
        selected_samples = OPTIONS.automatic.selected_samples(1,:);
        Mn = Mn(:,selected_samples);
    end
    
    
    Op  = Gn'*pinv(Gn*Gn');
    J   = Op * Mn;

    if nargout > 1
        varargout{1} =  0;
    end

end