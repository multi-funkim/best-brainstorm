function [J,varargout] = be_jmne(obj, OPTIONS)
% Compute the regularisation parameter based on what brainstorm already
% do. Note that this function replace be_solve_l_curve:
% BAYESEST2 solves the inverse problem by estimating the maximal posterior probability (MAP estimator).
%
%   INPUTS:
%       -   obj.gain       : matrice des lead-fields (donnee par le probleme direct)
%       -   obj.data       : vecteur colonne contenant les donnees sur les capteurs
%       -   varargin{1}    : param (alpha = param. trace(W*W')./trace(G*G')
%
%   OUTPUTS:
%       -   J       : MAP estimator
%       -   varargout{1} : param
%       -   varargout{2} : pseudo-inverse of G
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
% -------------------------------------------------------------------------

G = obj.gain; 
[n_capt, n_sour] = size(G);

% selection of the data:
M = obj.data;
if ~isempty(OPTIONS.automatic.selected_samples)   
    selected_samples = OPTIONS.automatic.selected_samples(1,:);
    M = M(:,selected_samples);
end

% We solve J = (W'W)^-1.G'.( G.(W'W)^-1.G' + alpha.Id )^-1.M
GG = G*G';
TrG   = trace(GG);

ratio = TrG/n_capt;

param1 = 1/9; %This parameter is the same as used in brainstorm
alpha  = param1*ratio;

invG = G'*( GG + alpha.*eye(n_capt))^-1;
J = invG*M; %Regularisation parameter

if nargout > 1
    varargout{1} = param1;
end
end
