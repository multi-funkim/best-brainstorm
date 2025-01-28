function [obj, OPTIONS] = be_main_mne(obj, OPTIONS, method)
% BE_MAIN_MEM sets the appropriate options for the MNE 
% accroding to the chosen MEM pipeline. Populate the fields
%   OPTIONS.automatic.Modality(ii).Jmne = J * ratioAmp;
%   OPTIONS.automatic.Modality(ii).ratioAmp = ratioAmp; with ratioAmp =  1 / max(max(abs(J))); 
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
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

    
    MNEAmp =  max(max(abs(J))); %Same for both modalities
    for ii  =   1 : numel(OPTIONS.mandatory.DataTypes)
        OPTIONS.automatic.Modality(ii).Jmne = J / MNEAmp;
        OPTIONS.automatic.Modality(ii).MNEAmp = MNEAmp;
    end
    
end
