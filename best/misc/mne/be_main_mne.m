function [obj, OPTIONS] = be_main_mne(obj, OPTIONS, method)
% Compute the MNE solition based on the choosen method and store the result
% in OPTIONS.automatic.Modality(ii).Jmne
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
%       -   method
%
%   OUTPUTS:
%       -   OPTIONS
%       -   obj

    if nargin < 3 || isempty(method)
        if OPTIONS.model.depth_weigth_MNE > 0 || any(strcmp( OPTIONS.mandatory.DataTypes,'NIRS')) 
            method = 'mne_lcurve';
        else
            method = 'mne';
        end
    end

    % apply the fusion of modalities
    OBJ_FUS = be_fusion_of_modalities(obj, OPTIONS, 0);
    
    switch(method)
        case 'mne_lcurve'
            J   =   be_jmne_lcurve(OBJ_FUS, OPTIONS, struct('hfig',obj.hfig, 'hfigtab',obj.hfigtab)); 
        case 'mne'
            J   =   be_jmne(OBJ_FUS, OPTIONS);
        case 'mne_normalized'
            J   =   be_jmne_normalized(OBJ_FUS, OPTIONS);  
    end

    for ii  =   1 : numel(OPTIONS.mandatory.DataTypes)
        OPTIONS.automatic.Modality(ii).Jmne = J ;
    end

end
