function [obj, OPTIONS] = be_unormalize_and_units(obj, OPTIONS)
% be_unormalize_and_units: Un-normalize the result source map.
% Inverse function of be_normalize_and_units
% -------------------------------------------------------------------------
%   Author: LATIS 2012
%
% ==============================================
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


if  strcmp(OPTIONS.optional.normalization,'adaptive')
    obj.ImageGridAmp = obj.ImageGridAmp/OPTIONS.automatic.Modality(1,1).ratioAmp;
else
    obj.ImageGridAmp = obj.ImageGridAmp*OPTIONS.automatic.Modality(1).units_dipoles; %Modified by JSB August 17th 2015
end

OPTIONS.automatic.Modality(1).Jmne = OPTIONS.automatic.Modality(1).Jmne * OPTIONS.automatic.Modality(1).MNEAmp;


end