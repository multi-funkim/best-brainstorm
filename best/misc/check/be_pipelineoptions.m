function OPT = be_pipelineoptions(OPT, pipeline, DataTypes)

if nargin == 1
    pipeline = OPT.mandatory.pipeline;
end
if nargin < 2
    DataTypes = [];
end

switch pipeline
    
    case 'cMEM'
        DEF = be_cmem_pipelineoptions(DataTypes);

    case 'cMNE'
        DEF = be_cmne_pipelineoptions(DataTypes);   

    case 'wMEM'
        DEF = be_wmem_pipelineoptions(DataTypes);
        
    case 'rMEM'
        DEF = be_rmem_pipelineoptions(DataTypes);

    otherwise
        DEF = be_cmem_pipelineoptions(DataTypes);   
        
end

OPT = be_struct_copy_fields(OPT, DEF, [], 0);
OPT.mandatory.pipeline = pipeline;

return

