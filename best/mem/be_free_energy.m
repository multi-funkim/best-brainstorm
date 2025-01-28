function [D, dD] = be_free_energy(lambda, M, noise_var, G_active_var_Gt, clusters)
%CALCULATE_FREE_ENERGY gives the free energy of a system
%   [D, dD] = CALCULATE_FREE_ENERGY(LAMBDA, M, NOISE_VAR, CLUSTERS,
%   NB_CLUSTERS)
%   calculates the free energy of the system for a given LAMBDA and 
%   returns it in D. The function also returns the derivative of D with 
%   respect to LAMBDA in dD.  This method should not be called by itself.
%
%   The method uses the methodoly described in :
%   Amblard, C., Lapalme, E., Lina, J. 2004. Biomagnetic Source Detection
%       by Maximyum Entropy and Graphical  Models, IEEE Transactions on 
%       Biomedical Engineering, vol. 51, no 3, p. 427-442.
%
%   The formulas are :
%       D(lambda) = lambda' * M - 
%                   (1/2)* noise_var * lambda' * lambda - 
%                   sum(F* * (G' * lambda))
%
%       F*(xi) = ln[(1- alpha) * exp(F0) + alpha * exp(F1)]
%           where F0 is the inactive state and
%                 F1 is the active state
%       F0(xi) = 1/2 * xi' * omega * xi
%       F1(xi) = 1/2 * xi' * sigma * xi + xi' * mu
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

lambda_trans = lambda';      
isUsingActiveMean  = ~isempty(clusters(1).active_mean);
isUsingInactiveVar = ~isempty(clusters(1).inactive_var);


% Estimate dF1 and F1 (separating the contribution  of the mean and
% covariance for optimization purpose)
dF1     = squeeze(be_pagemtimes(G_active_var_Gt,lambda));
F1      =  1/2 * lambda_trans*dF1; 

if isUsingActiveMean

    dF1b = zeros(size(dF1));
    for ii = 1:size(dF1b,2)

        active_mean = clusters(ii).active_mean;
        dF1b(:,ii)  = clusters(ii).G * active_mean;

    end
    dF1 = dF1 + dF1b;
    F1  = F1 + lambda_trans * dF1b;

end

% Estimate dF0 and F0
% F0 is set to a dirac by default (omega=0).
if isUsingInactiveVar
    dF0 = zeros(size(dF1));
    F0  = zeros(size(F1));
    for ii = 1:size(dF0,2)
        xi = clusters(ii).G' * lambda;
        dF0(:,ii) = clusters(ii).G * clusters(ii).inactive_var * xi;
        F0(ii) = 1/2 * xi' * clusters(ii).inactive_var * xi;
    end
end

p = [clusters.active_probability];

% Finally estimate dF and F
% We separate the case where mu_k = 0 and Dirac for inactive parcel for
% optimization purpose
if ~isUsingActiveMean && ~isUsingInactiveVar

    coeffs_free_energy  = (1-p) .* exp(-F1)  +  p;
    s1   = p ./ coeffs_free_energy;

    F = F1 + log(coeffs_free_energy);
    dF  = s1 .* dF1;
else 
    if  ~isUsingInactiveVar
        dF0 = zeros(size(dF1));
        F0  = zeros(size(F1));
    end
    
    F_max = max(F0,F1);
    
    free_energy = exp([F0;F1] - F_max);
    coeffs_free_energy = (1-p) .* free_energy(1,:) +  p .*  free_energy(2,:);
    
    F = F_max + log(coeffs_free_energy);

    s0   = (1-p) ./ coeffs_free_energy ;
    s1   =    p  ./ coeffs_free_energy ;

    dF = s0 .* dF0 +  s1.* dF1;
end

% The outcome of the equations produces a strictly convex function
% (with a maximum).
dD  = -(               M - sum(dF,2)                     - noise_var * lambda);
D   = -(lambda_trans * M - sum(F) - (1/2) * lambda_trans * noise_var * lambda);

end
