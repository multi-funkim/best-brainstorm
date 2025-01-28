function [J,varargout] = be_jmne_lcurve_MAP(obj, OPTIONS, sfig)
% Compute the minimum norm estimate using the Maximum a posteriori (MAP) formula
% The regularization parameter is estiamted using l-curve. This approach is
% equivalent to the regularized pseudo-inverse estimator in be_jmne_lcurve.
%
%   INPUTS:
%       -   G       : matrice des lead-fields (donnee par le probleme direct)
%       -   M       : vecteur colonne contenant les donnees sur les capteurs
%
%   OUTPUTS:
%       -   J       : MAP estimator
%       -   varargout{1} : regularization parameter based on l-curve
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

if nargin < 4 
    sfig = struct('hfig', [], 'hfigtab', []);
end

% selection of the data:
M = obj.data;
if ~isempty(OPTIONS.automatic.selected_samples)   
    selected_samples = OPTIONS.automatic.selected_samples(1,:);
    M = M(:,selected_samples);
end

G = obj.gain; 

param1  = [0.1:0.1:1 1:5:100 100:100:1000]; 
p       = OPTIONS.model.depth_weigth_MNE;

fprintf('%s, solving MNE by L-curve ...', OPTIONS.mandatory.pipeline);

% Compute some preliminary quantity required for MNE
[U,S,V] = svd(G,'econ');
GtG = V * S.^2 * V'; 

Sigma_s_diag = diag(GtG).^p;
Sigma_s = diag(Sigma_s_diag);

W = diag(Sigma_s_diag.^0.5);

scale = sum(diag(S).^2) / sum(Sigma_s_diag);       % Scale alpha using trace(G*G')./trace(W'*W)
alpha = param1.*scale;

G2 = U*S;
Sigma_s2 = V'*Sigma_s*V;
WV = diag(W).*V;

G2tG2 = S.^2; % (U*S)' * U*S = S*U'*U*S  = S^2

Fit     = zeros(1,length(alpha));
Prior   = zeros(1,length(alpha));


for i = 1:length(alpha)
    Kernel = ((G2tG2 + alpha(i).*Sigma_s2)^-1)*G2';
    J = Kernel*M;

    Fit(i) = normest(M-G2*J);       % Define Fit as a function of alpha
    Prior(i) = normest(WV*J);       % Define Prior as a function of alpha
end

[~,Index] = min(Fit/max(Fit)+Prior/max(Prior));  % Find the optimal alpha
J = ((GtG + alpha(Index).*Sigma_s)^-1)*G'*M;

if nargout > 1
    varargout{1} = alpha(Index);
end

fprintf('done. \n');

if OPTIONS.optional.display
    if isempty(sfig.hfig)
        sfig.hfig =  figure();
        sfig.hfigtab = uitabgroup;
    end

    onglet = uitab(sfig.hfigtab,'title','L-curve');

    hpc = uipanel('Parent', onglet, ...
              'Units', 'Normalized', ...
              'Position', [0.01 0.01 0.98 0.98], ...
              'FontWeight','demi');
    set(hpc,'Title',' L-curve ','FontSize',8);

    ax = axes('parent',hpc, ...
              'outerPosition',[0.01 0.01 0.98 0.98]);

    hold on; 
    plot(ax, Prior, Fit,'b.');
    plot(ax, Prior(Index), Fit(Index),'ro');
    hold off;
    xlabel('Norm |WJ|');
    ylabel('Residual |M-GJ|');
end

end