function [J,varargout] = be_jmne_lcurve(G,M,OPTIONS, sfig)
% Compute the regularisation parameter based on what brainstorm already
% do. Note that this function replace be_solve_l_curve:
% BAYESEST2 solves the inverse problem by estimating the maximal posterior probability (MAP estimator).
%
%   INPUTS:
%       -   G       : matrice des lead-fields (donnee par le probleme direct)
%       -   M       : vecteur colonne contenant les donnees sur les capteurs
%       -   InvCovJ : inverse covariance matrix of the prior distribution
%       -   varargin{1} : param (alpha = param. trace(W*W')./trace(G*G')
%                   NB: sinon, alpha est evalue par la methode de la courbe en L
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

if nargin < 4 
    sfig = struct('hfig', [], 'hfigtab', []);
end

% selection of the data:
if ~isempty(OPTIONS.automatic.selected_samples)   
    selected_samples = OPTIONS.automatic.selected_samples(1,:);
    M = M(:,selected_samples);
end

param1 = [0.1:0.1:1 1:5:100 100:100:1000]; 

fprintf('%s, solving MNE by L-curve ...', OPTIONS.mandatory.pipeline);


p       = OPTIONS.model.depth_weigth_MNE;
Sigma_s = diag(power(diag(G'*G),p)); 
W       = sqrt(Sigma_s);
scale   = trace(G*G')./trace(W'*W);       % Scale alpha using trace(G*G')./trace(W'*W)
alpha   = param1.*scale;

Fit     = [];
Prior   = [];

[U,S,V] = svd(G,'econ');
G2 = U*S;
Sigma_s2 = V'*Sigma_s*V;

for i = 1:length(param1)
    J = ((G2'*G2+alpha(i).*Sigma_s2)^-1)*G2'*M; % Weighted MNE solution
    Fit = [Fit,norm(M-G2*J)];       % Define Fit as a function of alpha
    Prior = [Prior,norm(W*V*J)];          % Define Prior as a function of alpha
end
[~,Index] = min(Fit/max(Fit)+Prior/max(Prior));  % Find the optimal alpha
J = ((G'*G+alpha(Index).*Sigma_s)^-1)*G'*M;

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
    set(hpc,'Title',[' L-curve '],'FontSize',8);

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