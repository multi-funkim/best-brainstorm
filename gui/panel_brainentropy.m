function varargout = panel_brainentropy(varargin)
% PANEL_BRAINENTROPY: Options for BrainEntropy MEM.
% 
% USAGE:  bstPanelNew = panel_brainentropy('CreatePanel')
%                   s = panel_brainentropy('GetPanelContents')
%
%% ==============================================   
% Copyright (C) 2012 - LATIS Team
%
%  Authors: LATIS, 2012
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


eval(macro_method);

end


%% ===== CREATE PANEL =====
function [bstPanelNew, panelName] = CreatePanel(OPTIONS,varargin)  %#ok<DEFNU> 


    
    global MEMglobal
    MEMglobal = [];

    global ExpertButtonTexts
    ExpertButtonTexts = {'Show details', 'Hide details'};

    panelName       =   'InverseOptionsMEM';
    bstPanelNew     =   [];
    
    % Check caller and Load data
    if isfield(OPTIONS, 'Comment') & strcmp(OPTIONS.Comment,'Compute sources: BEst')
        % Call from the process
        inputData   =   varargin{1};
        DTS         =   {inputData.FileName};
        SUBJ        =   cellfun( @(a) strrep( bst_fileparts( bst_fileparts( a ) ), filesep, '' ), DTS, 'uni', 0 );
        [dum,STD]   =   cellfun( @(a) bst_get('Study', fullfile( bst_fileparts(a), 'brainstormstudy.mat' ) ), DTS, 'uni', 0 );
        STD         =   cell2mat( STD );
        
        ChannelTypes = inputData.ChannelTypes;  
        OPTIONS     =   OPTIONS.options.mem.Value; 
        
        if isfield(OPTIONS,'MEMpaneloptions') && ~isempty(OPTIONS.MEMpaneloptions)
            OPTIONS = OPTIONS.MEMpaneloptions;
        end
        OPTIONS = be_struct_copy_fields(OPTIONS,be_main,[],0);
    elseif numel(varargin)==0
        % Call from the GUI
        bstPanel        = bst_get('Panel', 'Protocols');
        jTree           = get(bstPanel,'sControls');
        selectedPaths   = awtinvoke(jTree.jTreeProtocols, 'getSelectionPaths()');
        SUBJ={}; DTS={};STD=[];
        for ii = 1 : numel( selectedPaths )
            last    = awtinvoke( selectedPaths(ii), 'getLastPathComponent');
            DTS{ii} = char(last.getFileName);
            curS    = strrep( bst_fileparts( bst_fileparts( DTS{ii} ) ), filesep, '' );
            SUBJ    = [SUBJ {curS}];
            [st,is] = bst_get('Study', fullfile( bst_fileparts(DTS{ii}), 'brainstormstudy.mat' ) );
            STD     = [STD is];
        end
        ChannelTypes = {};  
        OPTIONS = be_main();
    else
        % Unexpected call
        fprintf('\n\n***\tError in call to panel_brainentropy\t***\n\tPlease report this bug to: latis@gmail.com\n\n')
        return
    end       

    OPTIONS = be_struct_copy_fields(OPTIONS,be_cmem_pipelineoptions(ChannelTypes),[],0);
    OPTIONS = be_struct_copy_fields(OPTIONS,be_wmem_pipelineoptions(ChannelTypes),[],0);
    OPTIONS = be_struct_copy_fields(OPTIONS, be_rmem_pipelineoptions(ChannelTypes),[],0);
        
    % Version
    OPTIONS.automatic.version       =   '3.0.0';
    OPTIONS.automatic.last_update   =   '';

    jTXTver =   JTextField(OPTIONS.automatic.version);
    jTXTupd =   JTextField(OPTIONS.automatic.last_update);

    nsub = numel( unique(SUBJ) );
    MEMglobal.DataToProcess = DTS;
    MEMglobal.SubjToProcess = SUBJ;
    MEMglobal.StudToProcess = STD;


    % Java initializations
    import java.awt.*;
    import javax.swing.*;

    % Constants
    TEXT_WIDTH      = 60;
    DEFAULT_HEIGHT  = 20;

    % Create main main panel
    jPanelMain = gui_component('Panel');
    jPanelMain.setPreferredSize(Dimension(1000,900));
    jPanelMain.setBorder(BorderFactory.createEmptyBorder(20,20,20,20));
    % Default grid bag constrains (for Left and Right panels)
    c = GridBagConstraints();
    c.fill    = GridBagConstraints.HORIZONTAL;
    c.weightx = 1;
    c.weighty = 0;

    %% --------------------- REGULAR OPTIONS PANEL --------------------- %%
    % ===== MEM METHOD =====

    ctrl = struct();

    % Left panel
    jPanelLeft = java_create('javax.swing.JPanel');
    jPanelLeft.setLayout(GridBagLayout());
    jPanelMain.add(jPanelLeft, BorderLayout.WEST);
    % Counter for elements in panel L
    gridyL = 1;

    % Add MEM type selection
    [jPanelType, ctrl_tmp] = CreatePanelType();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyL;
    jPanelLeft.add(jPanelType, c);
    gridyL = gridyL + 1;

    % Add MEM references
    [jPanelRef, ctrl_tmp] = CreatePanelRef();
    jPanelRef.setMinimumSize(Dimension(10*TEXT_WIDTH, 40*DEFAULT_HEIGHT));
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyL;
    jPanelLeft.add(jPanelRef, c);
    gridyL = gridyL + 1;

    [jPanelData, ctrl_tmp] = CreatePanelData();
    jPanelData.setMinimumSize(Dimension(10*TEXT_WIDTH, 40*DEFAULT_HEIGHT));
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyL;
    jPanelLeft.add(jPanelData, c);
    gridyL = gridyL + 1;

    [jPanel, ctrl_tmp] = CreatePanelOscillation();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyL;
    jPanelLeft.add(jPanel, c);
    gridyL = gridyL + 1;

    [jPanel, ctrl_tmp] = CreatePanelSynchrony();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyL;
    jPanelLeft.add(jPanel, c);
    gridyL = gridyL + 1;

    % Solver
    [jPanel, ctrl_tmp] = CreatePanelSolver();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyL;
    jPanelLeft.add(jPanel, c);
    gridyL = gridyL + 1;

    % ===== GROUP ANALYSIS =====
    % Group analysis - conditional
    [jPanel, ctrl_tmp] = CreatePanelGroup();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyL;
    jPanelLeft.add(jPanel, c);
    gridyL = gridyL + 1;

    % Add glue to fill vertical space at the end
    c.gridy   = gridyL;
    c.weighty = 1;
    jPanelLeft.add(Box.createVerticalGlue(), c);
    c.weighty = 0;

    %% ----------------------------------------------------------------- %%
    % Right panel
    jPanelRight = java_create('javax.swing.JPanel');
    jPanelRight.setLayout(GridBagLayout());
    jPanelMain.add(jPanelRight, BorderLayout.CENTER);
    % Counter for elements in panel R
    gridyR = 1;



    %% ---------------------- EXPERT OPTIONS PANEL --------------------- %%
    % ===== depth-weighting METHOD =====
    [jPanel, ctrl_tmp] = CreatePanelDepthWeighting();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyR;
    jPanelRight.add(jPanel, c);
    gridyR = gridyR + 1;

        % Clustering
    [jPanel, ctrl_tmp] = CreatePanelClustering();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyR;
    jPanelRight.add(jPanel, c);
    gridyR = gridyR + 1;

    % Add priors to panel
    [jPanel, ctrl_tmp] = CreatePanelModelPrior();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyR;
    jPanelRight.add(jPanel, c);
    gridyR = gridyR + 1;

    % Add glue to fill vertical space at the end
    c.gridy   = gridyR;
    c.weighty = 1;
    jPanelRight.add(Box.createVerticalGlue(), c);
    c.weighty = 0;

        % Right panel
    jPanelRightRight = java_create('javax.swing.JPanel');
    jPanelRightRight.setLayout(GridBagLayout());
    jPanelMain.add(jPanelRightRight, BorderLayout.EAST);
    % Counter for elements in panel R
    gridyRR = 1;

    % ==== Wavelet processing
    [jPanel, ctrl_tmp] = CreatePanelWavelet();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyRR;
    jPanelRightRight.add(jPanel, c);
    gridyRR = gridyRR + 1;

    % ==== Ridges
    [jPanel, ctrl_tmp] = CreatePanelRidge();
    ctrl = struct_copy_fields(ctrl,ctrl_tmp);
    c.gridy = gridyRR;
    jPanelRightRight.add(jPanel, c);
    gridyRR = gridyRR + 1;

    % Add glue to fill vertical space at the end
    c.gridy   = gridyRR;
    c.weighty = 1;
    jPanelRightRight.add(Box.createVerticalGlue(), c);
    c.weighty = 0;

    % ===== VALIDATION BUTTONS =====
    jPanelBottom = gui_river([1,1], [0,6,6,6]);
    jPanelMain.add(jPanelBottom, BorderLayout.SOUTH);
    JButEXP = gui_component('button', jPanelBottom, 'br center', ExpertButtonTexts{1}, [], [], @SwitchExpertMEM, []);
    gui_component('button', jPanelBottom, [], 'Cancel', [], [], @(src,ev)ButtonCancel_Callback(), []);
    JButOK = gui_component('button', jPanelBottom, [], 'OK', [], [], @ButtonOk_Callback, []);
    JButOK.setEnabled(0);

    ctrl = struct_copy_fields(ctrl,struct( 'jPanelTop',            jPanelMain, ...
                                           'jButEXP',              JButEXP, ...
                                           'jButOk',               JButOK, ...
                                           'jTXTver',              jTXTver, ...
                                           'jTXTupd',              jTXTupd));


    % ===== PANEL CREATION =====
    bst_mutex('create', panelName);
    bstPanelNew = BstPanel(panelName, jPanelMain, ctrl);
    setOptions(OPTIONS);
    UpdatePanel()

%% =================================================================================
%  === INTERNAL CALLBACKS ==========================================================
%  =================================================================================

    %% Create Panels REF
    function [jPanel, ctrl] = CreatePanelType()
        % Panel: Selection of the type of MEM (cMEM, wMEM, rMEM)

        jPanel = gui_river([1,1], [0, 6, 6, 6],'MEM type');
        jButtonGroupMemType = ButtonGroup();
    
        jTypeCMEM = gui_component('radio', jPanel, [], 'cMEM', jButtonGroupMemType, [], @(h,ev)SwitchPipeline(), []);
        jTypeCMEM.setToolTipText('<HTML><B>Default MEM</B>:<BR>temporal series</HTML>');
    
        jTypeWMEM = gui_component('radio', jPanel, [], 'wMEM', jButtonGroupMemType, [], @(h,ev)SwitchPipeline(), []);
        jTypeWMEM.setToolTipText('<HTML><B>wavelet-MEM</B>:<BR>targets strong oscillatory source activity<BR>(MEM on discrete time-scale boxes)</HTML>');
    
        jTypeRMEM = gui_component('radio', jPanel, [], 'rMEM', jButtonGroupMemType, [], @(h,ev)SwitchPipeline(), []);
        jTypeRMEM.setToolTipText('<HTML><B>ridge-MEM</B>:<BR>targets strong synchronous souce activity<BR>(MEM on ridge signals of AWT)</HTML>');
        
        
       ctrl = struct('JPanelMemType',jPanel , ....
                    'jMEMdef',              jTypeCMEM, ...
                    'jMEMw',                jTypeWMEM, ...
                    'jMEMr',                jTypeRMEM);
                  
    end

    function [jPanel, ctrl] = CreatePanelRef()
        % Panel: Showing MEM references 

        % put references
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'References:');
        % Amblard
        jPanel.add('br', JLabel(''));
        ml = jPanel.add('br', JLabel('MEM for neuroimaging:')); ml.setForeground(java.awt.Color(1,0,0));
        jPanel.add('br', JLabel('Amblard, Lapalme, and Lina (2004)'));
        jPanel.add('br', JLabel('IEEE TBME, 55(3): 427-442'));
        jPanel.add('br hfill', JLabel(' '));
            
        %Separator
        jsep = gui_component('label', jPanel, 'br hfill', ' ');
        jsep.setBackground(java.awt.Color(.4,.4,.4));
        jsep.setOpaque(1);
        jsep.setPreferredSize(Dimension(1,1));
        jPanel.add('br', JLabel(' '));
    
        % Grova
        jPanel.add('br', JLabel(''));
        ml = jPanel.add('br', JLabel('MEM on simulated spikes:')); ml.setForeground(java.awt.Color(1,0,0));
        jPanel.add('br', JLabel('Grova, Daunizeau, Lina, Benar, Benali and Gotman (2006)'));
        jPanel.add('br', JLabel('Neuroimage 29 (3), 734-753, 2006'));
        jPanel.add('br', JLabel(' '));
            
        %Separator
        jsep = gui_component('label', jPanel, 'br hfill', ' ');
        jsep.setBackground(java.awt.Color(.4,.4,.4));
        jsep.setOpaque(1);
        jsep.setPreferredSize(Dimension(1,1));
        jPanel.add('br', JLabel(' '));
            
        % Chowdhury
        jPanel.add('br', JLabel(''));
        ml = jPanel.add('br', JLabel('cMEM on epileptic spikes:')); ml.setForeground(java.awt.Color(1,0,0));
        jPanel.add('br', JLabel('Chowdhury, Lina, Kobayashi and Grova (2013)'));
        jPanel.add('br', JLabel('PLoS One vol.8(2), e55969'));
        jPanel.add('br', JLabel(' '));
    
        %Separator
        jsep = gui_component('label', jPanel, 'br hfill', ' ');
        jsep.setBackground(java.awt.Color(.4,.4,.4));
        jsep.setOpaque(1);
        jsep.setPreferredSize(Dimension(1,1));
        jPanel.add('br', JLabel(' '));

        % Lina
        jPanel.add('br', JLabel(''));
        ml = jPanel.add('br', JLabel('wMEM on epileptic spikes:')); ml.setForeground(java.awt.Color(1,0,0));
        jPanel.add('br', JLabel('Lina, Chowdhury, Lemay, Kobayashi and Grova (2012)'));
        jPanel.add('br', JLabel('IEEE TBME 61(8):2350-2364, 2014'));
        jPanel.add('br', JLabel(' '));
            
        %Separator
        jsep = gui_component('label', jPanel, 'br hfill', ' ');
        jsep.setBackground(java.awt.Color(.4,.4,.4));
        jsep.setOpaque(1);
        jsep.setPreferredSize(Dimension(1,1));
        jPanel.add('br', JLabel(' '));
            
        % Zerouali
        jPanel.add('br', JLabel(''));
        ml = jPanel.add('br', JLabel('rMEM on cognitive data:')); ml.setForeground(java.awt.Color(1,0,0));
        jPanel.add('br', JLabel('Zerouali, Herry, Jemel and Lina (2011)'));
        jPanel.add('br', JLabel('IEEE TBME 60(3):770-780, 2011'));
        jPanel.add('br', JLabel(' '));

        ctrl = struct('JPanelref',jPanel);
    end

    function [jPanel, ctrl] = CreatePanelData()
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Data definition');
        % ===== TIME SEGMENT =====
        jPanel.add('br', JLabel(''));
        jLabelTime = JLabel('Time window: ');
        jLabelTime.setToolTipText('<HTML><B>Time window</B>:<BR>Define a window of interest within the data<BR>(localize only relevant activity)</HTML>');
        jPanel.add(jLabelTime);

        % START
        jTextTimeStart = JTextField( num2str(OPTIONS.optional.TimeSegment(1)) );
        jTextTimeStart.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextTimeStart.setHorizontalAlignment(JTextField.RIGHT);
        hndl    =   handle(jTextTimeStart, 'callbackproperties');
        set(hndl, 'FocusLostCallback', @(src,ev)check_time('time', '', ''));
        jPanel.add(jTextTimeStart);
        % STOP
        jPanel.add(JLabel('-'));
        jTextTimeStop = JTextField( num2str(OPTIONS.optional.TimeSegment(2)) );
        jTextTimeStop.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextTimeStop.setHorizontalAlignment(JTextField.RIGHT);
        hndl    =   handle(jTextTimeStop, 'callbackproperties');
        set(hndl, 'FocusLostCallback', @(src,ev)check_time('time', '', ''));
        %set(jTextTimeStop, 'FocusLostCallback', @(src,ev)check_time('time', '', ''));
        jPanel.add(jTextTimeStop);
        jPanel.add(JLabel('s'));
            
        % Separator
        jPanel.add('br', JLabel(''));
        gui_component('label', jPanel, [], ' ');
        jsep = gui_component('label', jPanel, 'br hfill', ' ');
        jsep.setBackground(java.awt.Color(.4,.4,.4));
        jsep.setOpaque(1);
        jsep.setPreferredSize(Dimension(1,1));
        gui_component('label', jPanel, 'br', '');
            

        % ===== BASELINE =====
        jPanel.add('br', JLabel('Baseline'));
        jPanel.add('br', JLabel(''));

        jButtonGroupBslType = ButtonGroup();

    
        jRadioWithinData = gui_component('radio', jPanel, [], 'Within data', jButtonGroupBslType, [], @(h,ev)SwitchBaseline(), []);
        jRadioWithinData.setToolTipText(['<HTML><B>Within data</B>:', ...
            '<BR>Extracts baseline from within the recording data ', ...
            'used for source estimation.</HTML>']);

        jRadioWithinBrainstorm = gui_component('radio', jPanel, [], 'Within Brainstorm', jButtonGroupBslType, [], @(h,ev)SwitchBaseline(), []);
        jRadioWithinBrainstorm.setToolTipText(['<HTML><B>Within Brainstorm</B>:', ...
            '<BR>Extracts baseline from a recording within your brainstorm database </HTML>']);
        jPanel.add('br', JLabel(''));

        jRadioExternal = gui_component('radio', jPanel, [], 'External', jButtonGroupBslType, [], @(h,ev)SwitchBaseline(), []);
        jRadioExternal.setToolTipText(['<HTML><B>External</B>:', ...
            '<BR>Extracts baseline from a recording external to your brainstorm database </HTML>']);

        jRadioReshuffle= gui_component('radio', jPanel, [], 'All data (resting-state)', jButtonGroupBslType, [], @(h,ev)SwitchBaseline(), []);
        jRadioReshuffle.setToolTipText(['<HTML><B>All data</B>:', ...
            '<BR>Use Phase-reshuffling to generate surogate data as baseline (recommended for resting state analysis)</HTML>']);
        jPanel.add('br', JLabel(''));

        % -- Import Baseline from Brainstorm 

        jBaselineWithinBst = gui_river( '');

        jTextLoadAutoBsl = JTextField('baseline name...');
        jTextLoadAutoBsl.setToolTipText(['<HTML>Type in a substring ', ...
            'contained in the name of the baseline file to load and ', ...
            'click on the "find" button.</HTML>']);
        jBaselineWithinBst.add('hfill', jTextLoadAutoBsl);
        h = handle(jTextLoadAutoBsl, 'callbackproperties');
        set(h, 'FocusLostCallback', @(src, ev) UpdatePanel);

        jBaselineWithinBst.add( gui_component('button', jBaselineWithinBst, 'br center', 'find', [], ['<HTML><B>Find baseline</B>:', ...
                                                                                    '<BR>Automatically loads a recording from the current protocol using the given substring.</HTML>'], ...
                                                                                    @(h, ev)  load_auto_bsl, []));

        jPanel.add('hfill',jBaselineWithinBst);
        jBaselineWithinBst.hide();

        % -- Separator
                
        jPanel.add('br', JLabel(''));
       
        % -- Import External Baseline

        jBaselineExternal = gui_river( '');
        % -- Text field
        jTextPathBsl = JTextField('');
        jTextPathBsl.setEditable(0);
        jBaselineExternal.add('hfill', jTextPathBsl);
        jButtonImport = gui_component('button', jBaselineExternal, 'br center', 'Select file', [], ['<HTML><B>Baseline file</B>:', ...
                                                                                                        '<BR>Import baseline from a file.</HTML>'], @(h, ev) import_baseline(), []);

        jBaselineExternal.add(jButtonImport);
        jPanel.add('hfill',jBaselineExternal);
        jBaselineExternal.hide();

        % -- Separator
        jPanel.add('br', JLabel(''));
                
                
    
        % - Baseline time window
        jBaselineTimeSelect = gui_river( '');
        jBaselineTimeSelect.add(JLabel('Time window: '));
        jTextBSLStart = JTextField( num2str(OPTIONS.optional.BaselineSegment(1)) );
        jTextBSLStart.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextBSLStart.setHorizontalAlignment(JTextField.RIGHT);
        hndl    =   handle(jTextBSLStart, 'callbackproperties');
        set(hndl, 'FocusLostCallback', @(src,ev)check_time('bsl', '', ''));
        %set(jTextBSLStart, 'FocusLostCallback', @(src,ev)check_time('bsl', '', ''));
        jBaselineTimeSelect.add(jTextBSLStart);
        % Baseline STOP
        jBaselineTimeSelect.add(JLabel('-'));
        jTextBSLStop = JTextField( num2str(OPTIONS.optional.BaselineSegment(2)) );
        jTextBSLStop.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextBSLStop.setHorizontalAlignment(JTextField.RIGHT);
        hndl    =   handle(jTextBSLStop, 'callbackproperties');
        set(hndl, 'FocusLostCallback', @(src,ev)check_time('bsl', '', ''));
        %set(jTextBSLStop, 'FocusLostCallback', @(src,ev)check_time('bsl', '', ''));
        jBaselineTimeSelect.add(jTextBSLStop);
        jBaselineTimeSelect.add('tab', JLabel('s'));

        jBaselineTimeSelect.hide();
        jPanel.add(jBaselineTimeSelect);

        jPanel.add('br', JLabel(''));

        jBaselineShuffleWindowsSelect = gui_river( '');
        jBaselineShuffleWindowsSelect.add(JLabel('Window length: '));
        jTextBSLSize = JTextField( num2str(OPTIONS.optional.baseline_shuffle_windows) );
        jTextBSLSize.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextBSLSize.setHorizontalAlignment(JTextField.RIGHT);
        jBaselineShuffleWindowsSelect.add(jTextBSLSize);
        jBaselineShuffleWindowsSelect.add('tab', JLabel('s'));
        jBaselineShuffleWindowsSelect.hide();
        jPanel.add(jBaselineShuffleWindowsSelect);
        

        ctrl = struct( ...
            'jTextTimeStart',   jTextTimeStart, ...
            'jTextTimeStop',    jTextTimeStop,...
            'jRadioWithinData',jRadioWithinData, ...
            'jRadioWithinBrainstorm', jRadioWithinBrainstorm, ...
            'jRadioExternal', jRadioExternal, ...
            'jRadioReshuffle',jRadioReshuffle, ...
            'jTextLoadAutoBsl', jTextLoadAutoBsl, ...
            'jradimp',          jRadioExternal, ...
            'jBaselineWithinBst', jBaselineWithinBst, ...
            'jBaselineExternal',jBaselineExternal, ...
            'jBaselineTimeSelect', jBaselineTimeSelect, ...
            'jTextBSLStart',    jTextBSLStart, ...
            'jTextBSLStop',     jTextBSLStop, ...
            'jTextBSL',         jTextPathBsl, ...
            'jBaselineShuffleWindowsSelect',jBaselineShuffleWindowsSelect ,...
            'jTextBSLSize', jTextBSLSize, ...
            'JPanelData'  ,     jPanel);
    end

    function [jPanel, ctrl] = CreatePanelOscillation()
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Oscillations options');
        % Scales
        jBoxWAVsc  = JComboBox({''});
        jBoxWAVsc.setPreferredSize(Dimension(TEXT_WIDTH+60, DEFAULT_HEIGHT));
        jBoxWAVsc.setToolTipText('<HTML><B>Analyzed scales</B>:<BR>vector = analyze scales in vector<BR>integer = analyze scales up to integer<BR>0 = analyze all scales</HTML>');        
        jBoxWAVsc.setEditable(1);
        jPanel.add('p left', JLabel('Scales analyzed') );
        jPanel.add('tab hfill', jBoxWAVsc);

        ctrl = struct('JPanelnwav',jPanel,...
                     'jBoxWAVsc', jBoxWAVsc, ...
                     'jWavScales', jBoxWAVsc);
    end

    function [jPanel, ctrl] = CreatePanelSynchrony()
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Synchrony options');
        % RDG frq rng
        jTxtRfrs  = JComboBox( {''} );  
        jTxtRfrs.setPreferredSize(Dimension(TEXT_WIDTH+30, DEFAULT_HEIGHT));
        jTxtRfrs.setToolTipText('<HTML><B>Ridge frequency band</B>:<BR>delta=1-3, theta=4-7, alpha=8-12, beta=13-30, gamma=31-100<BR>(type in either a string or a frequency range) </HTML>');        
        jTxtRfrs.setEditable(1);

        jPanel.add('p left', JLabel('Frequency (Hz)') );
        jPanel.add('tab', jTxtRfrs);
        % RDG min dur
        jTxtRmd  = JTextField( num2str(OPTIONS.ridges.min_duration) );
        jTxtRmd.setPreferredSize(Dimension(TEXT_WIDTH+30, DEFAULT_HEIGHT));
        jTxtRmd.setHorizontalAlignment(JTextField.RIGHT);
        jTxtRmd.setToolTipText('<HTML><B>Arbitrary threshold on ridges duration (ms)<BR>(ridges shorter than this threshold will be discarded)</HTML>');        
        jPanel.add('p left', JLabel('Duration (ms)') );
        jPanel.add('tab', jTxtRmd);
                
        
        ctrl= struct( 'JPanelnosc', jPanel , ...
                      'jRDGrangeS', jTxtRfrs, ...
                      'jRDGmindur', jTxtRmd);

    end

    function [jPanel, ctrl] = CreatePanelClustering()

     % ===== CLUSTERING METHOD =====
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Clustering');
             
        % Method
        jButtonGroupCLS = ButtonGroup();
        % Clustering : Dynamic (RadioButton)
        jPanel.add('br', JLabel(''));
        jRadioDynamic = JRadioButton('Dynamic (blockwise)', strcmp(OPTIONS.clustering.clusters_type,'blockwise') );
        java_setcb(jRadioDynamic, 'ActionPerformedCallback', @(h,ev)UpdatePanel());
        jRadioDynamic.setToolTipText('<HTML><B>Dynamic clustering</B>:<BR>cortical parcels are computed within<BR>consecutive time windows</HTML>');jButtonGroupCLS.add(jRadioDynamic);
        jButtonGroupCLS.add(jRadioDynamic);
        jPanel.add(jRadioDynamic); 
        % MSP window
        jTextMspWindow = JTextField(num2str(OPTIONS.clustering.MSP_window));
        jTextMspWindow.setToolTipText('<HTML><B>Dynamic clustering</B>:<BR>size of the sliding window (ms)</HTML>');        
        jTextMspWindow.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextMspWindow.setHorizontalAlignment(JTextField.RIGHT);
        jPanel.add('tab', jTextMspWindow);
        
        % Clustering : Static (RadioButton)
        jPanel.add('br', JLabel(''));
        jRadioStatic = JRadioButton('Stable in time', strcmp(OPTIONS.clustering.clusters_type,'static') );
        java_setcb(jRadioStatic, 'ActionPerformedCallback', @(h,ev)UpdatePanel());
        jRadioStatic.setToolTipText('<HTML><B>Static clustering</B>:<BR>one set of cortical parcels<BR>computed for the whole data</HTML>');        
        jButtonGroupCLS.add(jRadioStatic);
        jPanel.add(jRadioStatic); 
        
        % Clustering : Frequency-adapted (RadioButton)
        jPanel.add('br', JLabel(''));
        jRadioFreq = JRadioButton('wavelet-adaptive', strcmp(OPTIONS.clustering.clusters_type,'wfdr') );
        java_setcb(jRadioFreq, 'ActionPerformedCallback', @(h,ev)UpdatePanel());
        jRadioFreq.setToolTipText('<HTML><B>Dynamic clustering</B>:<BR>Size of time windows are adapted<BR>to the size of time-scale boxes</HTML>');        
        jButtonGroupCLS.add(jRadioFreq);
        jPanel.add(jRadioFreq);
            
         % Separator
        jPanel.add('br', JLabel(''));
        gui_component('label', jPanel, [], ' ');
        jsep = gui_component('label', jPanel, 'br hfill', ' ');
        jsep.setBackground(java.awt.Color(.4,.4,.4));
        jsep.setOpaque(1);
        jsep.setPreferredSize(Dimension(1,1));
        gui_component('label', jPanel, 'br', ' ');
                        
        jPanel.add('br', JLabel(''));
        
        % MSP scores threshold
        jPanel.add('br', JLabel('MSP scores threshold : '));
        jButtonMSPscth = ButtonGroup();
        % Arbitrary
        jPanel.add('br', JLabel(''));
        jRadioSCRarb = JRadioButton('Arbitrary', ~strcmp(OPTIONS.clustering.MSP_scores_threshold,'fdr') );
        java_setcb(jRadioSCRarb, 'ActionPerformedCallback', @(h,ev)switchMspThresholdType());
        jRadioSCRarb.setToolTipText('<HTML><B>Arbitrary threshold</B>:<BR>whole brain parcellation if set to 0 ([0 1])</HTML>');        
        jButtonMSPscth.add(jRadioSCRarb);
        jPanel.add(jRadioSCRarb);
        jTextMspThresh = JTextField(num2str(OPTIONS.clustering.MSP_scores_threshold));
        jTextMspThresh.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextMspThresh.setHorizontalAlignment(JTextField.RIGHT);
        java_setcb(jTextMspThresh, 'ActionPerformedCallback', @(h,ev)adjust_range('jTextMspThresh', [0 1]));
        jPanel.add('tab tab', jTextMspThresh);
        % FDR
        jPanel.add('br', JLabel(''));
        jRadioSCRfdr = JRadioButton('FDR method', strcmp(OPTIONS.clustering.MSP_scores_threshold,'fdr') );
        java_setcb(jRadioSCRfdr, 'ActionPerformedCallback', @(h,ev)switchMspThresholdType());
        jRadioSCRfdr.setToolTipText('<HTML><B>Adaptive threshold</B>:<BR>thresholds are learned from baseline<BR>using the FDR method</HTML>');        
        jButtonMSPscth.add(jRadioSCRfdr);
        jPanel.add(jRadioSCRfdr);
        
       
         % Separator
        jPanel.add('br', JLabel(''));
        gui_component('label', jPanel, [], ' ');
        jsep = gui_component('label', jPanel, 'br hfill', ' ');
        jsep.setBackground(java.awt.Color(.4,.4,.4));
        jsep.setOpaque(1);
        jsep.setPreferredSize(Dimension(1,1));
        gui_component('label', jPanel, 'br', ' ');
                    
        jPanel.add('br', JLabel(''));
        
                
        % Neighborhood order
        jPanel.add('br', JLabel(''));
        jTextNeighbor = JTextField( num2str(OPTIONS.clustering.neighborhood_order)); 
        jTextNeighbor.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextNeighbor.setHorizontalAlignment(JTextField.RIGHT);
        jTextNeighbor.setToolTipText('<HTML><B>Neighborhood order</B>:<BR>sets maximal size of cortical parcels<BR>(initial source configuration for MEM)</HTML>');        
        jPanel.add(JLabel('Neighborhood order:'));
        jPanel.add('tab', jTextNeighbor);


        % Spatial smoothing
        jPanel.add('br', JLabel(''));
        jTextSmooth = JTextField(num2str(OPTIONS.solver.spatial_smoothing));
        jTextSmooth.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextSmooth.setHorizontalAlignment(JTextField.RIGHT);
        jTextSmooth.setToolTipText('<HTML><B>Smoothness of MEM solution</B>:<BR>spatial regularization of  the MEM<BR>(linear decay of spatial source correlations [0 1])</HTML>');        
        java_setcb(jTextSmooth, 'ActionPerformedCallback', @(h,ev)adjust_range('jTextSmooth', [0 1]));
        jPanel.add(JLabel('Spatial smoothing:'));
        jPanel.add('tab', jTextSmooth);

        

        ctrl = struct('JPanelCLSType',jPanel , ...
                      'jCLSd',                jRadioDynamic, ...
                      'jCLSs',                jRadioStatic, ...
                      'jCLSf',                jRadioFreq, ...
                      'jRadioSCRarb',         jRadioSCRarb, ...
                      'jRadioSCRfdr',         jRadioSCRfdr, ...
                      'jTextMspWindow',       jTextMspWindow, ...
                      'jTextMspThresh',       jTextMspThresh, ...
                      'jTextNeighbor',        jTextNeighbor,...
                      'jTextSmooth',          jTextSmooth);
    end

    function [jPanel, ctrl] = CreatePanelGroup()
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Group analysis');

        % Spatial smoothing
        jCheckGRP = JCheckBox('Multi-subjects spatial priors', OPTIONS.optional.groupAnalysis);
        jCheckGRP.setToolTipText('<HTML><B>Warning</B>:<BR>Computations may take a lot of time</HTML>');        

        jPanel.add('tab', jCheckGRP);
        
        % Add 'Method' panel to main panel (jPanelNew)
        jPanel.add('br', JLabel(''));
        JW = JLabel('    WARNING: very slow');
        jPanel.add('tab', JW);

        ctrl = struct('JPanelGRP',jPanel, ...
                      'jCheckGRP', jCheckGRP);
    end
    
    function [jPanel, ctrl] = CreatePanelDepthWeighting()
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Depth-weighting');

        jCheckDepthWeighting = gui_component('checkbox', jPanel, [], 'Use depth-weighting', [], [], @switchDepth, []);

        jTxtDepthMNE  = JTextField( num2str(OPTIONS.model.depth_weigth_MNE ) );
        jTxtDepthMNE.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtDepthMNE.setHorizontalAlignment(JTextField.RIGHT);
        jTxtDepthMNE.setToolTipText('Depth-weitghing coeficient for MNE (between 0 and 1)');        
        jTxtDepthMNE.setEnabled(0);
    
        jPanel.add('p left', JLabel('Weight for MNE:') );
        jPanel.add('tab', jTxtDepthMNE);
    
        jTxtDepthMEM  = JTextField( num2str(OPTIONS.model.depth_weigth_MEM ) );
        jTxtDepthMEM.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtDepthMEM.setHorizontalAlignment(JTextField.RIGHT);
        jTxtDepthMEM.setToolTipText('Depth-weitghing coeficient for MNE (between 0 and 1)');        
        jTxtDepthMEM.setEnabled(0);
    
        jPanel.add('p left', JLabel('Weight for MEM:') );
        jPanel.add('tab', jTxtDepthMEM);

 
        ctrl = struct( 'JPanelDepth', jPanel, ...
                        'jCheckDepthWeighting',jCheckDepthWeighting,...
                        'jTxtDepthMNE', jTxtDepthMNE, ...
                        'jTxtDepthMEM', jTxtDepthMEM);
    end
    
    function [jPanel, ctrl] = CreatePanelModelPrior()

        % Model priors
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Model priors');

        % mu
        jTxtMuMet  = JTextField( num2str(OPTIONS.model.active_mean_method) );
        jTxtMuMet.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtMuMet.setHorizontalAlignment(JTextField.RIGHT);
        jTxtMuMet.setToolTipText('<HTML><B>Initialization of cluster k''s active mean (&mu)</B>:<BR>1 = regular minimum norm J (&mu<sub>k</sub> = mean(J<sub>k</sub>))<BR>2 = null hypothesis (&mu<sub>k</sub> = 0)<BR>3 = MSP-regularized minimum norm mJ (&mu<sub>k</sub> = mean(mJ<sub>k</sub>))<BR>4 = L-curve optimized Minimum Norm Estimate</HTML>');        
        java_setcb(jTxtMuMet, 'ActionPerformedCallback', @(h,ev)adjust_range('jTxtMuMet', [1 4]) );

        jPanel.add('p left', JLabel('Active mean intialization') );
        jPanel.add('tab tab', jTxtMuMet);

        % alpha m
        jTxtAlMet  = JTextField( num2str(OPTIONS.model.alpha_method) );
        jTxtAlMet.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtAlMet.setHorizontalAlignment(JTextField.RIGHT);
        jTxtAlMet.setToolTipText('<HTML><B>Initialization of cluster k''s active probability (&alpha)</B>:<BR>1 = average MSP scores (&alpha<sub>k</sub> = mean(MSP<sub>k</sub>))<BR>2 = max MSP scores (&alpha<sub>k</sub> = max(MSP<sub>k</sub>))<BR>3 = median MSP scores (&alpha<sub>k</sub> = mean(MSP<sub>k</sub>))<BR>4 = equal (&alpha = 0.5)<BR>5 = equal (&alpha = 1)<BR>6 = % of MNE Energy<BR>7 = % of MNE Energy (using l-curve)</HTML>');
        java_setcb(jTxtMuMet, 'ActionPerformedCallback', @(h,ev)adjust_range('jTxtMuMet', [1 7]) );
        jPanel.add('p left', JLabel('Active probability intialization') );
        jPanel.add('tab', jTxtAlMet);

        % alpha t
        jTxtAlThr  = JTextField( num2str(OPTIONS.model.alpha_threshold) );
        jTxtAlThr.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtAlThr.setHorizontalAlignment(JTextField.RIGHT);
        jTxtAlThr.setToolTipText('<HTML><B>Active probability threshold(&alpha)</B>:<BR>exclude clusters with low probability from solution<BR>&alpha<sub>k</sub> < threshold = 0</HTML>');        
        java_setcb(jTxtAlThr, 'ActionPerformedCallback', @(h,ev)adjust_range('jAlphaThresh', [0 1]) );
        jPanel.add('p left', JLabel('Active probability threshold') );
        jPanel.add('tab', jTxtAlThr);

        % lambda
        jTxtLmbd  = JTextField( num2str(OPTIONS.model.initial_lambda) );
        jTxtLmbd.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtLmbd.setHorizontalAlignment(JTextField.RIGHT);
        jTxtLmbd.setToolTipText('<HTML><B>Initialization of sensor weights vector (&lambda)</B>:<BR>0 = null hypothesis (&lambda = 0)<BR>1 = random</HTML>');        
        jPanel.add('p left', JLabel('Lambda') );
        jPanel.add('tab', jTxtLmbd);

        % Active var
        jTxtActV  = JTextField( num2str(OPTIONS.solver.active_var_mult) );
        jTxtActV.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtActV.setHorizontalAlignment(JTextField.RIGHT);
        jTxtActV.setToolTipText('<HTML><B>Initialization of cluster k''s active variance(&Sigma<sub>1,k</sub>)</B>:<BR>enter a coefficient value ([0 1])<BR>&Sigma<sub>1,k</sub> = coeff * &mu<sub>k</sub></HTML>');        
        java_setcb(jTxtActV, 'ActionPerformedCallback', @(h,ev)adjust_range('jActiveVar', [0 1]) );
        jPanel.add('p left', JLabel('Active variance coeff.') );
        jPanel.add('tab', jTxtActV);

        % Inactive var
        jTxtInactV  = JTextField( num2str(OPTIONS.solver.inactive_var_mult) );
        jTxtInactV.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtInactV.setHorizontalAlignment(JTextField.RIGHT);
        jTxtInactV.setToolTipText('<HTML><B>Initialization of cluster k''s inactive variance(&Sigma<sub>0,k</sub>)</B>:<BR>Not implemented yet</HTML>');            
        jPanel.add('p left', JLabel('Inactive variance coeff.') );
        jPanel.add('tab', jTxtInactV);

        jsep = gui_component('label', jPanel, 'br hfill', ' ');
        jsep.setBackground(java.awt.Color(.4,.4,.4));
        jsep.setOpaque(1);
        jsep.setPreferredSize(Dimension(1,1));
        gui_component('label', jPanel, 'br', '');
        % Compute new matrix?
        jBoxNewC  = JCheckBox( 'Recompute covariance matrix' );
        jBoxNewC.setSelected(OPTIONS.solver.NoiseCov_recompute);
        jBoxNewC.setToolTipText('<HTML><B>Noise covariance matrix</B>:<BR>The performance of the MEM is tied to<BR>a consistent estimation of this matrix<BR>(keep checked)</HTML>');
        jPanel.add('p left', jBoxNewC);
        % Matrix type
        jTxtVCOV  = JTextField( num2str(OPTIONS.solver.NoiseCov_method) );
        jTxtVCOV.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtVCOV.setHorizontalAlignment(JTextField.RIGHT);
        jTxtVCOV.setToolTipText(['<HTML><B>Sensors noise covariance matrix</B>:<BR>' ...
             '0 = identity matrix<BR>' ...
             '1 = diagonal (same variance along diagonal)<BR>' ...
             '2 = diagonal<BR>' ...
             '3 = full<BR>' ...
             '4 = wavelet-based estimation (scale j = 1, diagonal)<BR>' ...
             '5 = wavelet-based (scale j = 1, same variance along diagonal)<BR>'...
             '6 = wavelet-based (scale j = 2, diagonal)<BR> </HTML>']);               
        java_setcb(jTxtVCOV, 'FocusLostCallback', @(h,ev)adjust_range('jVarCovar', {[1 4], [4 6], [1 5]}));
        jPanel.add('p left', JLabel('Covariance matrix type') );
        jPanel.add('tab tab', jTxtVCOV);

        ctrl = struct( 'jPanelModP',           jPanel , ...
                       'jMuMethod',            jTxtMuMet, ... 
                       'jAlphaMethod',         jTxtAlMet, ...
                       'jAlphaThresh',         jTxtAlThr, ...
                       'jLambda',              jTxtLmbd, ...
                       'jActiveVar',           jTxtActV, ...
                       'jInactiveVar',         jTxtInactV,...
                       'jNewCOV',              jBoxNewC,...
                       'jVarCovar',            jTxtVCOV);
    end
    
    function [jPanel, ctrl] = CreatePanelWavelet()
        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Wavelet processing');
        jTxtWAVtp  = JTextField(OPTIONS.wavelet.type);
        jTxtWAVtp.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtWAVtp.setHorizontalAlignment(JTextField.RIGHT);
        jTxtWAVtp.setToolTipText('<HTML><B>Wavelet type</B>:<BR>CWT = Continous wavelet transform (Morse)<BR>RDW = Discrete wavelet transform (real Daubechies)</HTML>');        
        jTxtWAVvm  = JTextField( num2str(OPTIONS.wavelet.vanish_moments) );
        jTxtWAVvm.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtWAVvm.setHorizontalAlignment(JTextField.RIGHT);
        jTxtWAVvm.setToolTipText('<HTML><B>Vanishing moments</B>:<BR>high polynomial order filtered out by the wavelet<BR>(compromise between frequency resolution and temporal decorrelation)</HTML>');        

        % Wavelet type
        jPanel.add('p left', JLabel('Wavelet type') );
        jPanel.add('tab', jTxtWAVtp);
        % Vanish
        jPanel.add('p left', JLabel('Vanishing moments') );
        jPanel.add('tab', jTxtWAVvm);
        
        % Shrinkage
        jTxtWAVsh  = JTextField( num2str(OPTIONS.wavelet.shrinkage) );
        jTxtWAVsh.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtWAVsh.setHorizontalAlignment(JTextField.RIGHT);
        jTxtWAVsh.setToolTipText('<HTML><B>DWT denoising</B>:<BR>0 = no denoising<BR>1 = soft denoising (remove low energy coeff.)</HTML>');        
        
        jTxtWAVshLabel = JLabel('Coefficient shrinkage');
        jPanel.add('p left', jTxtWAVshLabel );
        jPanel.add('tab', jTxtWAVsh);            
    
        % Order
        jTxtWAVorLabel =  JLabel('Wavelet order');

        jTxtWAVor  = JTextField( num2str(OPTIONS.wavelet.order) );
        jTxtWAVor.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtWAVor.setHorizontalAlignment(JTextField.RIGHT);
        jPanel.add('p left', jTxtWAVorLabel );
        jPanel.add('tab', jTxtWAVor);

        % Levels
        jTxtWAVlvLabel = JLabel('Decomposition levels');
        jTxtWAVlv  = JTextField( num2str(OPTIONS.wavelet.nb_levels) );
        jTxtWAVlv.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtWAVlv.setHorizontalAlignment(JTextField.RIGHT);

        jPanel.add('p left', jTxtWAVlvLabel );
        jPanel.add('tab', jTxtWAVlv);

        ctrl = struct('jPanelWAV',      jPanel, ...
                      'jWavType',       jTxtWAVtp, ...
                      'jWavVanish',     jTxtWAVvm,...
                      'jWavShrinkage',  jTxtWAVsh, ...
                      'jWavShrinkageLabel' , jTxtWAVshLabel, ...
                      'jWavOrder',      jTxtWAVor,...
                      'jWavOrderLabel', jTxtWAVorLabel, ... 
                      'jWavLevels',     jTxtWAVlv, ...
                      'jWavLevelsLabel', jTxtWAVlvLabel);
    end

    function [jPanel, ctrl] = CreatePanelRidge()

        jPanel = gui_river([1,1], [0, 6, 6, 6], 'Ridge processing');
        % SC NRJ
        jTxtRsct  = JTextField( num2str(OPTIONS.ridges.scalo_threshold) );
        jTxtRsct.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtRsct.setHorizontalAlignment(JTextField.RIGHT);
        jTxtRsct.setToolTipText('<HTML><B>Scalogram threshold</B>:<BR>Keep local maxima up to threshod * total energy of the CWT</HTML>');        
        jPanel.add('p left', JLabel('Scalogram energy threshold') );
        jPanel.add('tab', jTxtRsct);

        % BSL cumul thr
        jTxtRbct  = JTextField( num2str(OPTIONS.ridges.energy_threshold) );
        jTxtRbct.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtRbct.setHorizontalAlignment(JTextField.RIGHT);
        jTxtRbct.setToolTipText('<HTML><B>Baseline cumulative threshold</B>:<BR>Adaptive cutoff for selecting signifciant ridges<BR>Learned from the distribution of ridge strengths in the baseline<BR>Cutoff is the percentile of that distribution indicated by threshold</HTML>');        
        jPanel.add('p left', JLabel('Baseline cumulative threshold') );
        jPanel.add('tab', jTxtRbct);

        % RDG str thr
        jTxtRst  = JTextField( num2str(OPTIONS.ridges.strength_threshold) );
        jTxtRst.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtRst.setHorizontalAlignment(JTextField.RIGHT);
        jTxtRst.setToolTipText('<HTML><B>Ridge strength threshold</B>:<BR>double = arbitrary threshold ([0 1])<BR>blank = adaptive threshold (recommanded)</HTML>');        
        jPanel.add('p left', JLabel('Ridge strength threshold') );
        jPanel.add('tab', jTxtRst);     

        % Cycles
        jTxtRmc  = JTextField( num2str(OPTIONS.ridges.cycles_in_window) );
        jTxtRmc.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTxtRmc.setHorizontalAlignment(JTextField.RIGHT);
        jTxtRmc.setToolTipText('<HTML><B>Number of cycles within MSP</B><BR>only available for wavelet-adaptive clustering</HTML>');        
        jPanel.add('p left', JLabel('Ridge minimum cycles') );
        jPanel.add('tab', jTxtRmc);

        ctrl = struct('jPanelRDG',      jPanel, ...
                       'jRDGscaloth',   jTxtRsct, ...
                       'jRDGnrjth',     jTxtRbct,...
                       'jRDGstrength',  jTxtRst, ...
                       'jRDGmincycles',	jTxtRmc);
    end

    function [jPanel, ctrl] = CreatePanelSolver()
       jPanel = gui_river([1,1], [0, 6, 6, 6], 'Solver options');
    
        % Optimization routine
        % Show "fminuc function only if avaiable"
        if be_canUsefminunc()
            optFnChoices = { "fminunc"  "minFunc" "minFuncNM" };
        else
            optFnChoices = { "minFunc" "minFuncNM" };
        end

        jTxtOptFn  = JComboBox(optFnChoices);
        jTxtOptFn.setPreferredSize(Dimension(TEXT_WIDTH + 40, DEFAULT_HEIGHT));
        jTxtOptFn.setSelectedItem(OPTIONS.solver.Optim_method);
        tooltip_text = ['<HTML>', ...
            '<B>Optimization routine</B>:', ...
            '<BR>fminunc = Matlab standard unconst. optimization', ...
            '<BR><span style="margin-left:30px;">&emsp;(optimization toolbox required)</span>', ...
            '<BR>minFunc = Unconstrained optimization (using MEX files)', ...
            '<BR><span style="margin-left:30px;">&emsp;copyright Mark Schmidt, INRIA (faster)</span>', ...
            '<BR>minFuncNM = Unconstrained optimization (not using MEX files)', ...
            '<BR><span style="margin-left:30px;">&emsp;copyright Mark Schmidt, INRIA</span>', ...
            '</HTML>'];
        jTxtOptFn.setToolTipText(tooltip_text);
        jPanel.add('p left', JLabel('Optimization routine') );
        jPanel.add('tab tab', jTxtOptFn);
         
        % Display
        jBoxShow  = JCheckBox( 'Activate MEM display' );
        jBoxShow.setSelected( OPTIONS.optional.display );   
        jPanel.add('p left', jBoxShow);
        % Parallel computing
        jBoxPara  = JCheckBox( 'Matlab parallel computing' );
        jBoxPara.setSelected(OPTIONS.solver.parallel_matlab);

        jPanel.add('p left', jBoxPara);
        % Separator
        jPanel.add('br', JLabel(''));
    
        

        ctrl = struct('jPanelSensC', jPanel ,...
                      'jOptimFN',    jTxtOptFn, ...
                      'jBoxShow',    jBoxShow, ...
                      'jParallel',   jBoxPara);

    end
    
    function setOptions(OPTIONS)

        choices = {'cMEM', 'wMEM', 'rMEM'};
        selected = strcmp(OPTIONS.mandatory.pipeline , choices);
        MEM_button  = [ctrl.jMEMdef ctrl.jMEMw ctrl.jMEMr ];
        
        if any(selected)
            MEM_button(selected).setSelected(1);
        end
        
        % OPTIONS from CreatePanelData
        ctrl.jTextTimeStart.setText(num2str(OPTIONS.optional.TimeSegment(1)))
        ctrl.jTextTimeStop.setText(num2str(OPTIONS.optional.TimeSegment(2)))
        check_time('time', '', '');

        choices = {'within-data', 'within-brainstorm', 'external','all-data'};
        baseline_control = [ctrl.jRadioWithinData ctrl.jRadioWithinBrainstorm ctrl.jRadioExternal, ctrl.jRadioReshuffle];
    
        if any(strcmp(OPTIONS.optional.BaselineType, choices ))
            baseline_control(strcmp(OPTIONS.optional.BaselineType, choices )).setSelected(1);

            if strcmp(OPTIONS.optional.BaselineType, 'all-data' )
                ctrl.jTextBSLSize.setVisible(1);
            else
                ctrl.jBaselineTimeSelect.setVisible(1);
            end

            if strcmp(OPTIONS.optional.BaselineType, 'within-brainstorm' )
                ctrl.jTextLoadAutoBsl.setText(OPTIONS.optional.BaselineHistory{2});
                ctrl.jBaselineWithinBst.setVisible(1);
                load_auto_bsl();
            elseif strcmp(OPTIONS.optional.BaselineType, 'external' )
                disp(OPTIONS.optional.BaselineHistory{3})
                import_baseline( OPTIONS.optional.Baseline,OPTIONS.optional.BaselineHistory{2} );
                ctrl.jBaselineExternal.setVisible(1);
            end

            check_time('bsl', '', '', 'checkOK');
        end

        ctrl.jTextBSLStart.setText(num2str(OPTIONS.optional.BaselineSegment(1)));
        ctrl.jTextBSLStop.setText(num2str(OPTIONS.optional.BaselineSegment(2)));
        ctrl.jTextBSLSize.setText(num2str(OPTIONS.optional.baseline_shuffle_windows));

        check_time('set_scales', '', '');
        check_time('set_freqs', '', '');

        % OPTIONS from CreatePanelOscillation()
        if length(OPTIONS.wavelet.selected_scales) == 1
            ctrl.jWavScales.setSelectedIndex(OPTIONS.wavelet.selected_scales+1);
        else % all scale
            ctrl.jWavScales.setSelectedIndex(1);
        end

        % OPTIONS from CreatePanelSynchrony()

        if ~isempty(OPTIONS.ridges.frequency_range)
            freq_label= {'gamma', 'beta', 'alpha', 'theta', 'delta'};
            freqs = [ [30 100] ; ... % gamma
                    [13 29]; ... % beta
                    [8 12]; ... % alpha
                    [4 7]; ... % delta
                    [1 3]]; %theta 

            selected_scale = find(all(freqs == OPTIONS.ridges.frequency_range,2));
            if any(selected_scale)
                ctrl.jRDGrangeS.setSelectedIndex(selected_scale+1);
            else
                ctrl.jRDGrangeS.setSelectedIndex(1);
            end
        end
        ctrl.jRDGmindur.setText(num2str(OPTIONS.ridges.min_duration));



        % OPTIONS from CreatePanelClustering
        ctrl.jCLSd.setSelected(strcmp(OPTIONS.clustering.clusters_type,'blockwise'));
        ctrl.jCLSs.setSelected(strcmp(OPTIONS.clustering.clusters_type,'static'));
        ctrl.jCLSf.setSelected(strcmp(OPTIONS.clustering.clusters_type,'wfdr') );

        ctrl.jTextMspWindow.setText(num2str(OPTIONS.clustering.MSP_window));


       ctrl.jRadioSCRarb.setSelected(~strcmp(OPTIONS.clustering.MSP_scores_threshold,'fdr'))
       ctrl.jRadioSCRfdr.setSelected(strcmp(OPTIONS.clustering.MSP_scores_threshold,'fdr'))
       if strcmp(OPTIONS.clustering.MSP_scores_threshold,'fdr')
            ctrl.jTextMspThresh.setText(OPTIONS.clustering.MSP_scores_threshold);
       else
            ctrl.jTextMspThresh.setText(num2str(OPTIONS.clustering.MSP_scores_threshold));
       end

       ctrl.jTextNeighbor.setText(num2str(OPTIONS.clustering.neighborhood_order));
       ctrl.jTextSmooth.setText(num2str(OPTIONS.solver.spatial_smoothing));


        % OPTIONS from CreatePanelGroup
        ctrl.jCheckGRP.setSelected(OPTIONS.optional.groupAnalysis)


        % OPTIONS from CreatePanelDepthWeighting
        if  (OPTIONS.model.depth_weigth_MNE > 0 || OPTIONS.model.depth_weigth_MEM > 0)
            ctrl.jCheckDepthWeighting.setSelected(1);
            ctrl.jTxtDepthMNE.setText(num2str(OPTIONS.model.depth_weigth_MNE));
            ctrl.jTxtDepthMEM.setText(num2str(OPTIONS.model.depth_weigth_MEM));
            ctrl.jTxtDepthMNE.setEnabled(1);
            ctrl.jTxtDepthMEM.setEnabled(1);

        else 
            ctrl.jCheckDepthWeighting.setSelected(0);
        end

        % OPTIONS from CreatePanelModelPrior
        ctrl.jMuMethod.setText(num2str(OPTIONS.model.active_mean_method));
        ctrl.jAlphaMethod.setText(num2str(OPTIONS.model.alpha_method));
        ctrl.jAlphaThresh.setText(num2str(OPTIONS.model.alpha_threshold));
        ctrl.jLambda.setText(num2str(OPTIONS.model.initial_lambda));
        ctrl.jActiveVar.setText(num2str(OPTIONS.solver.active_var_mult));
        ctrl.jInactiveVar.setText(num2str(OPTIONS.solver.inactive_var_mult));


        % OPTIONS from CreatePanelWavelet
        ctrl.jWavType.setText(OPTIONS.wavelet.type);
        ctrl.jWavVanish.setText(num2str(OPTIONS.wavelet.vanish_moments))
        ctrl.jWavShrinkage.setText(num2str(OPTIONS.wavelet.shrinkage))
        ctrl.jWavOrder.setText(num2str(OPTIONS.wavelet.order))
        ctrl.jWavLevels.setText(num2str(OPTIONS.wavelet.nb_levels))

        % OPTIONS from CreatePanelRidge()

        ctrl.jRDGscaloth.setText(num2str(OPTIONS.ridges.scalo_threshold))
        ctrl.jRDGnrjth.setText(num2str(OPTIONS.ridges.energy_threshold))
        ctrl.jRDGstrength.setText(num2str(OPTIONS.ridges.strength_threshold))
        ctrl.jRDGmincycles.setText(num2str(OPTIONS.ridges.cycles_in_window))

        % OPTIONS from CreatePanelSolver
        ctrl.jOptimFN.setSelectedItem(OPTIONS.solver.Optim_method);
        ctrl.jBoxShow.setSelected(OPTIONS.optional.display);
        ctrl.jParallel.setSelected(OPTIONS.solver.parallel_matlab);
        ctrl.jNewCOV.setSelected(OPTIONS.solver.NoiseCov_recompute);
        ctrl.jVarCovar.setText(num2str(OPTIONS.solver.NoiseCov_method) );
    end


    %% ===== CANCEL BUTTON =====
    function ButtonCancel_Callback()
        gui_hide(panelName);
    end

    %% ===== OK BUTTON =====
    function ButtonOk_Callback(varargin)       
        % Release mutex and keep the panel opened
        bst_mutex('release', panelName);
        be_print_best(OPTIONS);
    end

    function switchMspThresholdType()
        if ctrl.jRadioSCRarb.isSelected()
            ctrl.jTextMspThresh.setText('0');
        else 
            ctrl.jTextMspThresh.setText('fdr')
        end
    end

    function SetAllExpertPanelsVisiblity(visibility)
        panels = [ctrl.JPanelCLSType, ctrl.jPanelModP, ctrl.JPanelDepth , ctrl.jPanelWAV, ctrl.jPanelRDG];

        for iPanel = 1:length(panels)
            panels(iPanel).setVisible(visibility);

            comps = panels(iPanel).getComponents();
            for iComp = 1:length(comps)
                comps(iComp).setVisible(visibility);
            end
        end
    end

    %% ===== SWITCH EXPERT MODE =====
    function SwitchExpertMEM(varargin)
        wasExpert = OPTIONS.automatic.MEMexpert;
        isExpert = ~wasExpert;

        OPTIONS.automatic.MEMexpert = isExpert;
        MEMglobal.isExpert = isExpert;

        ctrl.jButEXP.setText(ExpertButtonTexts(isExpert + 1));


        UpdatePanel()
    end   

    %% ===== SWITCH PIPELINE =====
    function SwitchPipeline(varargin)
        

        choices = {'cMEM', 'wMEM', 'rMEM'};
        selected = [ctrl.jMEMdef.isSelected() ctrl.jMEMw.isSelected() ctrl.jMEMr.isSelected()];
        if any(selected)

            if strcmp(choices(selected), 'cMEM')
                NEW_OPTIONS = be_struct_copy_fields(OPTIONS, be_cmem_pipelineoptions(ChannelTypes),[],1);
            elseif strcmp(choices(selected), 'wMEM')
                NEW_OPTIONS = be_struct_copy_fields(OPTIONS, be_wmem_pipelineoptions(ChannelTypes),[],1);
            elseif strcmp(choices(selected), 'rMEM')
                NEW_OPTIONS = be_struct_copy_fields(OPTIONS, be_rmem_pipelineoptions(ChannelTypes),[],1);
            end

            %% Save options while changing the pipeline
            % Save "Activate MEM Display"
            NEW_OPTIONS.optional.display = ctrl.jBoxShow.isSelected();
            % Save time window
            NEW_OPTIONS.optional.TimeSegment = [ ...
                str2double(char(ctrl.jTextTimeStart.getText())) ...
                str2double(char(ctrl.jTextTimeStop.getText()))];
            % Save Optimization routine
            NEW_OPTIONS.solver.Optim_method = ctrl.jOptimFN.getSelectedItem();
            % Save Baseline start and stop
            NEW_OPTIONS.optional.BaselineSegment    = [ ...
                str2double(char(ctrl.jTextBSLStart.getText())), ...
                str2double(char(ctrl.jTextBSLStop.getText()))];

                NEW_OPTIONS.mandatory.pipeline = choices(selected);
            setOptions(NEW_OPTIONS)
        end

        UpdatePanel()
    end

    function SwitchBaseline(varargin)
        choices = {'within-data', 'within-brainstorm', 'external','all-data'};
        selected = [ctrl.jRadioWithinData.isSelected() ctrl.jRadioWithinBrainstorm.isSelected() ctrl.jRadioExternal.isSelected(), ctrl.jRadioReshuffle.isSelected()];
        
        if ~any(selected)
            return;
        end

       if strcmp( choices(selected), 'within-data') 
           ctrl.jBaselineTimeSelect.setVisible(1);
           ctrl.jBaselineWithinBst.setVisible(0);
           ctrl.jBaselineExternal.setVisible(0);
           ctrl.jBaselineShuffleWindowsSelect.setVisible(0);

          check_time('bsl', '', '', 'checkOK');
       elseif strcmp( choices(selected), 'within-brainstorm') 
            ctrl.jBaselineTimeSelect.setVisible(0);
            ctrl.jBaselineWithinBst.setVisible(1);
            ctrl.jBaselineExternal.setVisible(0);
            ctrl.jBaselineShuffleWindowsSelect.setVisible(0);

       elseif strcmp( choices(selected), 'external') 
            ctrl.jBaselineTimeSelect.setVisible(0);
            ctrl.jBaselineWithinBst.setVisible(0);
            ctrl.jBaselineExternal.setVisible(1);
            ctrl.jBaselineShuffleWindowsSelect.setVisible(0);

       elseif strcmp( choices(selected), 'all-data')  
            ctrl.jBaselineTimeSelect.setVisible(0);
            ctrl.jBaselineWithinBst.setVisible(0);
            ctrl.jBaselineExternal.setVisible(0);
            ctrl.jBaselineShuffleWindowsSelect.setVisible(1);
            check_time('bsl', '', '', 'checkOK');
       end
    end

    function switchDepth(varargin)
         ctrl.jTxtDepthMNE.setEnabled( ctrl.jCheckDepthWeighting.isSelected());
         ctrl.jTxtDepthMEM.setEnabled( ctrl.jCheckDepthWeighting.isSelected());
    end

    %% ===== UPDATE PANEL =====
    function UpdatePanel()

        choices = {'cMEM', 'wMEM', 'rMEM'};
        selected = [ctrl.jMEMdef.isSelected() ctrl.jMEMw.isSelected() ctrl.jMEMr.isSelected()];
        if ~any(selected)
            ctrl.JPanelref.setPreferredSize(java_scaled('dimension', 500, 450));
            ctrl.JPanelData.setVisible(0);
            ctrl.JPanelnwav.setVisible(0);
            ctrl.JPanelnosc.setVisible(0);
            ctrl.JPanelCLSType.setVisible(0);
            ctrl.JPanelGRP.setVisible(0);
            ctrl.JPanelDepth.setVisible(0);
            ctrl.jPanelModP.setVisible(0);
            ctrl.jPanelWAV.setVisible(0);
            ctrl.jPanelRDG.setVisible(0);
            ctrl.jPanelSensC.setVisible(0);
        else

            SetAllExpertPanelsVisiblity(OPTIONS.automatic.MEMexpert);

            ctrl.JPanelData.setPreferredSize(java_scaled('dimension', 320, 270));
            ctrl.JPanelref.setVisible(0);
            ctrl.JPanelData.setVisible(1);
            ctrl.jPanelSensC.setVisible(1);

            if nsub > 1 
                ctrl.JPanelGRP.setVisible(1);
            else
                ctrl.JPanelGRP.setVisible(0);
            end

            if strcmp(choices(selected), 'cMEM')
                ctrl.JPanelnwav.setVisible(0);
                ctrl.JPanelnosc.setVisible(0);
                ctrl.jPanelWAV.setVisible(0);
                ctrl.jPanelRDG.setVisible(0);

                ctrl.jCLSf.setEnabled(0);
                ctrl.jCLSd.setEnabled(1);
                ctrl.jCLSs.setEnabled(1);
                ctrl.jTextMspWindow.setEnabled(1);

                ctrl.jRadioReshuffle.setEnabled(0);
                if ctrl.jRadioReshuffle.isSelected()
                    ctrl.jRadioWithinData.setSelected(1);
                    ctrl.jBaselineShuffleWindowsSelect.setVisible(0);
                end

            elseif strcmp(choices(selected), 'wMEM')
                ctrl.JPanelnwav.setVisible(1);
                ctrl.JPanelnosc.setVisible(0);
                ctrl.jPanelRDG.setVisible(0);

                ctrl.jRadioReshuffle.setEnabled(1);

                ctrl.jCLSf.setEnabled(1);
                ctrl.jCLSd.setEnabled(0);
                ctrl.jCLSs.setEnabled(1);
                ctrl.jTextMspWindow.setEnabled(0);

                ctrl.jWavOrder.setVisible(0);
                ctrl.jWavOrderLabel.setVisible(0);
                ctrl.jWavLevelsLabel.setVisible(0);
                ctrl.jWavShrinkage.setVisible(1);
                ctrl.jWavShrinkageLabel.setVisible(1);
                ctrl.jWavLevels.setVisible(0);

            elseif  strcmp(choices(selected), 'rMEM')
                ctrl.JPanelnwav.setVisible(0);
                ctrl.JPanelnosc.setVisible(1);
                ctrl.JPanelDepth.setVisible(0);

                ctrl.jRadioReshuffle.setEnabled(0);
                if ctrl.jRadioReshuffle.isSelected()
                    ctrl.jRadioWithinData.setSelected(1);
                    ctrl.jBaselineShuffleWindowsSelect.setVisible(0);
                end


                ctrl.jCLSf.setEnabled(1);
                ctrl.jCLSd.setEnabled(1);
                ctrl.jCLSs.setEnabled(0);
                ctrl.jTextMspWindow.setEnabled(1);

                ctrl.jWavOrder.setVisible(1);
                ctrl.jWavOrderLabel.setVisible(1);
                ctrl.jWavLevelsLabel.setVisible(1);
                ctrl.jWavLevels.setVisible(1);
                ctrl.jWavShrinkage.setVisible(0);
                ctrl.jWavShrinkageLabel.setVisible(0);
            end
    
        end            
    end

    function set_scales(time)
        
        if numel(time)>127 && ~ (isfield(MEMglobal, 'selected_scale_index') && MEMglobal.selected_scale_index > 0)
    
            if ~isfield(MEMglobal, 'available_scales')
                Nj      = fix( log2(numel(time)) );
                sf      = 1/diff(time([1 2]));
                Noff    = min(Nj-1, 3);
    
                scalesU = 1./2.^(1:Nj-Noff) * sf;
                scalesD = 1./2.^(1:Nj-Noff)/2 * sf;
    
                MEMglobal.available_scales  = [scalesU; scalesD];
            end
                
            % Fill fields
            ctrl.jWavScales.removeAllItems();
            ctrl.jWavScales.insertItemAt( '', 0)
            ctrl.jWavScales.insertItemAt( 'all', 1)
            for ii = 1 : size(MEMglobal.available_scales,2)
                IT = [num2str(ii) ' (' num2str(MEMglobal.available_scales(2,ii)) ':' num2str(MEMglobal.available_scales(1,ii)) ' Hz)'];
                ctrl.jWavScales.insertItemAt(IT, ii+1);
            end
            ctrl.jWavScales.setSelectedIndex(1); 
            
        elseif numel(time)<128
            ctrl.jWavScales.insertItemAt( 'NOT ENOUGH SAMPLES', 0)
            ctrl.jWavScales.insertItemAt( 'NOT ENOUGH SAMPLES', 1)
            ctrl.jWavScales.setSelectedIndex(0); 
            ctrl.jWavScales.setEnabled(0);
            
        else
            ctrl.jWavScales.setSelectedIndex(MEMglobal.selected_scale_index);
            
        end
                 
    end


    function [freqs] = set_freqs(time)
        if ~isfield(MEMglobal, 'selected_freqs_index') && numel(time)>127
            
            if ~isfield(MEMglobal, 'freqs_available')
                O.wavelet.vanish_moments=   str2double( ctrl.jWavVanish.getText() );
                O.wavelet.order     	=   str2double( ctrl.jWavOrder.getText() );
                O.wavelet.nb_levels  	=   str2double( ctrl.jWavLevels.getText() );
                O.wavelet.verbose       =   0;  
                O.mandatory.DataTime    =   time;
    
                [dum, O] = be_cwavelet( time, O, 1);
                FRQ = O.wavelet.freqs_analyzed;
    
                freqs = {'','all'};
                if max(FRQ)>100    
                    if min( abs(FRQ-30) ) < 1
                        freqs = [freqs {'gamma'}];        
                        if min( abs(FRQ-13) ) < 1
                            freqs = [freqs {'beta'}];            
                            if min( abs(FRQ-8) ) < 1
                                freqs = [freqs {'alpha'}];                
                                if min( abs(FRQ-4) ) < 1
                                    freqs = [freqs {'theta'}];                   
                                    if min( abs(FRQ-1) ) < 1
                                        freqs = [freqs {'delta'}];
                                    end
                                end
                            end
                        end
                    end
                end
                MEMglobal.freqs_available = freqs;
                MEMglobal.freqs_analyzed  = FRQ;
            end
            
            % Fill fields
            ctrl.jRDGrangeS.removeAllItems();
            for ii = 1 : numel(MEMglobal.freqs_available)
                ctrl.jRDGrangeS.insertItemAt(MEMglobal.freqs_available{ii}, ii-1);
            end        
            ctrl.jRDGrangeS.setSelectedIndex(1);   
        
        elseif numel(time)<128
            ctrl.jRDGrangeS.insertItemAt( 'NOT ENOUGH SAMPLES', 0)
            ctrl.jRDGrangeS.insertItemAt( 'NOT ENOUGH SAMPLES', 1)
            ctrl.jRDGrangeS.setSelectedIndex(0); 
            ctrl.jRDGrangeS.setEnabled(0); 
            
        else
            ctrl.jRDGrangeS.setSelectedIndex(MEMglobal.selected_freqs_index);
         
        end
        
    end
    
    function check_time(varargin)
        % Check time limits
        iP  = bst_get('ProtocolInfo');
        iS  = MEMglobal.DataToProcess;
        
        % Checks input 
        Tm = {};
        for ii = 1 : numel(iS)
            data = in_bst(fullfile(iP.STUDIES, iS{ii})); % load( fullfile(iP.STUDIES, iS{ii}), 'Time' );
            Tm{ii} = data.Time;
        end
        sf = cellfun(@(a) round(1/diff(a([1 2]))), Tm, 'uni', false);
        St = cellfun(@(a,b) round(a(1)*b), Tm, sf, 'uni', false); St = max( [St{:}] );
        Nd = cellfun(@(a,b) round(a(end)*b), Tm, sf, 'uni', false); Nd = min( [Nd{:}] );
        
        if St > Nd
            ctrl.jTextTimeStart.setEnabled(0);
            ctrl.jTextTimeStop.setEnabled(0);
        
        else
            Time = (St : Nd)/max([sf{:}]);
        
            % process input arguments
            switch varargin{1}
                case 'time',
                    hndlst = ctrl.jTextTimeStart;
                    hndlnd = ctrl.jTextTimeStop;
        
                case 'bsl'
                    hndlst = ctrl.jTextBSLStart;
                    hndlnd = ctrl.jTextBSLStop;
                    
                    switch varargin{2}
                        case ''
                            if isfield(MEMglobal, 'Baseline') && ~isempty(MEMglobal.Baseline) 
                                Time = getfield(load(MEMglobal.Baseline, 'Time'), 'Time');
                            end
                        case {'auto', 'import'}
                            Time = getfield(load(MEMglobal.Baseline, 'Time'), 'Time');   
                    end

                case 'set_scales'
                    set_scales(Time);
                    return;
                case 'set_freqs'
                    set_freqs(Time);
                    return;
            end
        
            switch varargin{3}
                case 'true'
                    hndlst.setText('-9999')
                    hndlnd.setText('9999')
            end
        
            ST  = str2double( char( hndlst.getText()) ); 
            ND  = str2double( char( hndlnd.getText()) ); 
        
            if isnan(ST), ST = Time(1);   else, ST = Time( be_closest(ST,Time) ); end
            if isnan(ND), ND = Time(end); else, ND = Time( be_closest(ND,Time) ); end
        
            if ST> min([ND Time(end)]) 
                ST=min([ND Time(end)]);
            end
            if ND< max([ST Time(1)])
                ND=max([ST Time(1)]);
            end
        
            hndlst.setText( num2str( max( ST, Time(1) ) ) );
            hndlnd.setText( num2str( min( ND, Time(end) ) ) );
        
            if numel(varargin)==4 
                if strcmp(varargin{4}, 'checkOK')
                    ctrl.jButOk.setEnabled(1);
                elseif strcmp(varargin{4}, 'set_TF')
                    if ctrl.jMEMw.isSelected()
                        set_scales(Time);
                    elseif ctrl.jMEMr.isSelected()
                        set_freqs(Time);
                    end           
                end
            end
        end
        
        
    end
    function import_baseline( Lst,Frmt  )
        
        DefaultFormats = bst_get('DefaultFormats');
        iP  = bst_get('ProtocolInfo');  

        if nargin < 2 || isempty(Lst)
            [Lst, Frmt]   = java_getfile( 'open', ...
                    'Import EEG/MEG recordings...', ...       % Window title
                    iP.STUDIES, ...                           % default directory
                    'single', 'files_and_dirs', ...           % Selection mode
                    {{'.*'},                 'MEG/EEG: 4D-Neuroimaging/BTi (*.*)',   '4D'; ...
                     {'_data'},              'MEG/EEG: Brainstorm (*data*.mat)',     'BST-MAT'; ...
                     {'.meg4','.res4'},      'MEG/EEG: CTF (*.ds;*.meg4;*.res4)',    'CTF'; ...
                     {'.fif'},               'MEG/EEG: Elekta-Neuromag (*.fif)',     'FIF'; ...
                     {'*'},                  'EEG: ASCII text (*.*)',                'EEG-ASCII'; ...
                     {'.avr','.mux','.mul'}, 'EEG: BESA exports (*.avr;*.mul;*.mux)','EEG-BESA'; ...
                     {'.eeg','.dat'},        'EEG: BrainAmp (*.eeg;*.dat)',          'EEG-BRAINAMP'; ...
                     {'.txt'},               'EEG: BrainVision Analyzer (*.txt)',    'EEG-BRAINVISION'; ...
                     {'.sef','.ep','.eph'},  'EEG: Cartool (*.sef;*.ep;*.eph)',      'EEG-CARTOOL'; ...
                     {'.edf','.rec'},        'EEG: EDF / EDF+ (*.rec;*.edf)',        'EEG-EDF'; ...
                     {'.set'},               'EEG: EEGLAB (*.set)',                  'EEG-EEGLAB'; ...
                     {'.raw'},               'EEG: EGI Netstation RAW (*.raw)',      'EEG-EGI-RAW'; ...
                     {'.erp','.hdr'},        'EEG: ERPCenter (*.hdr;*.erp)',         'EEG-ERPCENTER'; ...
                     {'.mat'},               'EEG: Matlab matrix (*.mat)',           'EEG-MAT'; ...
                     {'.cnt','.avg','.eeg','.dat'}, 'EEG: Neuroscan (*.cnt;*.eeg;*.avg;*.dat)', 'EEG-NEUROSCAN'; ...
                     {'.mat'},               'NIRS: MFIP (*.mat)',                   'NIRS-MFIP'; ...
                    }, DefaultFormats.DataIn);
                
            if isempty(Lst) 
                check_time('bsl', '', '');
                return
            end
        end
        ctrl.jTextBSL.setText(Lst);
        MEMglobal.BSLinfo.file    = Lst;
        MEMglobal.BSLinfo.format  = Frmt; 
        
        if strcmp(Frmt, 'BST-MAT')
            BSL = Lst;
            BSLc = fullfile(iP.STUDIES, bst_get('ChannelFileForStudy', Lst));
        else
            try
                % This code block should not be correct as it is not consistent with the
                % signature of in_data()...
                [BSL, BSLc] = in_data( Lst, Frmt, [], []);
                if numel(BSL)>1
                    ctrl.jTextBSL.setText('loading only trial 1');
                    pause(2)
                    ctrl.jTextBSL.setText(Lst);
                end    
                BSL = BSL(1).FileName;
            catch
                java_dialog('warning', 'File cannot be used. Select new file')
                ctrl.jTextBSL.setText('');    
                return;
            end
        end
        
        MEMglobal.Baseline              = BSL;
        MEMglobal.BaselineChannels      = BSLc;
        MEMglobal.BaselineHistory{1}    = 'import';
        MEMglobal.BaselineHistory{2}    = Frmt;
        MEMglobal.BaselineHistory{3}    = Lst;
        
        check_time('bsl', 'import', 'true', 'checkOK');
        ctrl.jBaselineTimeSelect.setVisible(1);
    end


    function success = load_auto_bsl()
    % Look in the database for a recording with a given substring
    success = false;
    bsl_name = char(ctrl.jTextLoadAutoBsl.getText());
    % This global variable should be removed, kept here for compatibility with
    % previous code
    
    if isfield(MEMglobal,'BSLinfo')  &&  isfield(MEMglobal.BSLinfo,'comment') && ~isempty(MEMglobal.BSLinfo.comment)
        success = true;
        return;
    end
    
    
    MEMglobal.BSLinfo.comment = '';
    MEMglobal.BSLinfo.file = '';
    
    % Nothing to do
    if isempty(bsl_name)
        disp('BEst> No baseline to find')
        disp(['BEst> Type in a substring contained in the name of the ', ...
            'baseline file to load and tick the "find" button.'])
        return
    end
    
    % Look through the studies of the current protocol
    % (why not giving precedence to the studies currently selected for analyses?)
    S = getfield(bst_get('ProtocolStudies'), 'Study');
    S = [S.Data];
    
    % This should never happen
    if isempty(S)
        disp('BEst> No study with recordings found in the current protocol.')
        return
    end
    
    
    tmp = cellfun(@(x) strsplit(x,'/'), {S.FileName}, 'UniformOutput', false);
    subjectNames = cellfun(@(x) x{1}, tmp, 'UniformOutput', false);
    conditionNames = cellfun(@(x) x{2}, tmp, 'UniformOutput', false);
    
    idx = false(size(subjectNames));
    for iSubject = 1:length(MEMglobal.SubjToProcess)
        idx = idx | strcmp(subjectNames,MEMglobal.SubjToProcess{iSubject});
    end
    idx = idx & strcmp({S.DataType}, 'recordings');
    
    S               = S(idx);
    subjectNames    = subjectNames(idx);
    conditionNames  = conditionNames(idx);
    
    K = find(cellfun(@(k) ~isempty(k), strfind({S.Comment}, bsl_name)));
    
    % User should check the baseline name, beware case sensitivity
    if isempty(K)
        disp(['BEst> No recording with ''', bsl_name, ''' in their name was ', ...
            'found in the current protocol.'])
        return
    end
    
    % A baseline has been found
    success = true;
    
    % Warning if multiple recordings are valid
    if (nnz(K) > 1)
        potentials_baseline = S(K);
    
        names = strcat(subjectNames(K)', {' /  '},conditionNames(K)' ,{' /  '} , {potentials_baseline.Comment}');
        try
            ChanSelected = java_dialog('radio', 'Select baseline to use:', 'Baseline selection', [], names);
        catch 
            disp(['BEst> No baseline selected'])
            return
        end
        if isempty(ChanSelected)
            disp(['BEst> No baseline selected'])
            return
        end
        K = K(ChanSelected);
    end
    
    disp('BEst> Selecting the baseline file:')
    disp(['BEst>    ''', S(K(1)).FileName, ''''])
    
    % This should be revisited, only file paths should be returned, not the file
    % contents. 'be_main_call.m' should be able to load files.
    MEMglobal.BSLinfo.comment = S(K(1)).Comment;
    MEMglobal.BSLinfo.file = S(K(1)).FileName;
    if ~isfield(MEMglobal, 'BaselineHistory') || ~strcmp(MEMglobal.BSLinfo.file, ...
            MEMglobal.BaselineHistory{3})
        MEMglobal.Baseline = file_fullpath(MEMglobal.BSLinfo.file);
        MEMglobal.BaselineChannels = file_fullpath(bst_get(...
            'ChannelFileForStudy', MEMglobal.BSLinfo.file));
        MEMglobal.BaselineHistory{1} = 'auto';
        MEMglobal.BaselineHistory{2} = MEMglobal.BSLinfo.comment;
        MEMglobal.BaselineHistory{3} = MEMglobal.BSLinfo.file;
    end
    check_time('bsl', 'auto', 'true', 'checkOK');
    ctrl.jBaselineTimeSelect.setVisible(1);
    end

end


%% =================================================================================
%  === EXTERNAL CALLBACKS ==========================================================
%  =================================================================================  

% ===== GET PANEL CONTENTS =====
function s = GetPanelContents(varargin) %#ok<DEFNU>

    % Get panel controls
    ctrl = bst_get('PanelControls', 'InverseOptionsMEM');
    global MEMglobal

    MEMpaneloptions.InverseMethod           = 'MEM';
    if isfield(MEMglobal, 'isExpert')
        MEMpaneloptions.automatic.MEMexpert = MEMglobal.isExpert; 
    else
        MEMpaneloptions.automatic.MEMexpert = 0;
    end
    MEMpaneloptions.automatic.version       = char( ctrl.jTXTver.getText() ); 
    MEMpaneloptions.automatic.last_update   = char( ctrl.jTXTupd.getText() ); 

    % Get MEM method
    choices = {'cMEM', 'wMEM', 'rMEM'};
    selected = [ctrl.jMEMdef.isSelected() ctrl.jMEMw.isSelected() ctrl.jMEMr.isSelected()];
    MEMpaneloptions.mandatory.pipeline      =   choices{ selected };
    

    % Get Data
    MEMpaneloptions.optional.TimeSegment              = [str2double(char(ctrl.jTextTimeStart.getText())) ...
                                                         str2double(char(ctrl.jTextTimeStop.getText()))];
    MEMpaneloptions.optional.TimeSegment(isnan(MEMpaneloptions.optional.TimeSegment) ) = [];

    % Get Baseline
    choices = {'within-data', 'within-brainstorm', 'external','all-data'};
    selected = [ctrl.jRadioWithinData.isSelected() ctrl.jRadioWithinBrainstorm.isSelected() ctrl.jRadioExternal.isSelected()  ctrl.jRadioReshuffle.isSelected()];

    
    MEMpaneloptions.optional.BaselineType = choices(selected);
    if strcmp(choices(selected), 'within-data') 
        MEMpaneloptions.optional.Baseline = [];
        MEMpaneloptions.optional.BaselineHistory{1} = 'within';
    elseif strcmp(choices(selected), 'within-brainstorm')  || strcmp(choices(selected), 'external')
        if isfield(MEMglobal, 'Baseline')
            MEMpaneloptions.optional.Baseline = MEMglobal.Baseline;
        else
            MEMpaneloptions.optional.Baseline = [];
        end
        if isfield(MEMglobal, 'BaselineChannels')
            MEMpaneloptions.optional.BaselineChannels = MEMglobal.BaselineChannels;
        else
            MEMpaneloptions.optional.BaselineChannels = [];
        end
        if isfield(MEMglobal, 'BaselineHistory')
            MEMpaneloptions.optional.BaselineHistory = MEMglobal.BaselineHistory;
        else
            MEMpaneloptions.optional.BaselineHistory = [];
        end

    elseif strcmp(choices(selected), 'all-data')
        MEMpaneloptions.optional.Baseline = [];
        MEMpaneloptions.optional.BaselineHistory{1} = 'within';
        MEMpaneloptions.optional.baseline_shuffle   = 1;
        MEMpaneloptions.optional.baseline_shuffle_windows = str2double(char(ctrl.jTextBSLSize.getText())); % in seconds

    end
    
    if strcmp(choices(selected), 'all-data')
        MEMpaneloptions.optional.BaselineSegment    = MEMpaneloptions.optional.TimeSegment;
    else
        MEMpaneloptions.optional.BaselineSegment    = [str2double(char(ctrl.jTextBSLStart.getText())), ...
                                                       str2double(char(ctrl.jTextBSLStop.getText()))];

        if any(isnan( MEMpaneloptions.optional.BaselineSegment ) )
            MEMpaneloptions.optional.BaselineSegment = [];
        end
    end




    % Get clustering options

    MEMpaneloptions.clustering.neighborhood_order     = str2double(char(ctrl.jTextNeighbor.getText()));

    choices = {'blockwise', 'static', 'wfdr'};
    selected = [ctrl.jCLSd.isSelected() ctrl.jCLSs.isSelected() ctrl.jCLSf.isSelected()];
    MEMpaneloptions.clustering.clusters_type = choices{ selected };
    
    if strcmp(choices(selected), 'blockwise')
        MEMpaneloptions.clustering.MSP_window = str2double(char(ctrl.jTextMspWindow.getText()));
    end

    % Get MSP thresholding method
    if ctrl.jRadioSCRarb.isSelected()
        MEMpaneloptions.clustering.MSP_scores_threshold = str2double(char(ctrl.jTextMspThresh.getText()));
        if isnan(MEMpaneloptions.clustering.MSP_scores_threshold)
            MEMpaneloptions.clustering.MSP_scores_threshold = 0;       
        end
    else
        MEMpaneloptions.clustering.MSP_scores_threshold = 'fdr';
    end
   
   % Group analysis
   MEMpaneloptions.optional.groupAnalysis            = ctrl.jCheckGRP.isSelected(); 


    % Depth-weighting options
    if ctrl.jCheckDepthWeighting.isSelected() && any( strcmp(MEMpaneloptions.mandatory.pipeline, {'cMEM','wMEM'}) )
        MEMpaneloptions.model.depth_weigth_MNE  = str2double( ctrl.jTxtDepthMNE.getText() );
        MEMpaneloptions.model.depth_weigth_MEM  = str2double( ctrl.jTxtDepthMEM.getText() );
    else
        MEMpaneloptions.model.depth_weigth_MNE  =  0;
        MEMpaneloptions.model.depth_weigth_MEM  =  0;
    end
    
    % Advanced options
    MEMpaneloptions.model.active_mean_method    = str2double( ctrl.jMuMethod.getText() );
    MEMpaneloptions.model.alpha_method          = str2double( ctrl.jAlphaMethod.getText() );
    MEMpaneloptions.model.alpha_threshold      	= str2double( ctrl.jAlphaThresh.getText() );
    MEMpaneloptions.model.initial_lambda        = str2double( ctrl.jLambda.getText() );
    MEMpaneloptions.solver.spatial_smoothing    = str2double(char(ctrl.jTextSmooth.getText()));
    MEMpaneloptions.solver.active_var_mult      = str2double( ctrl.jActiveVar.getText() );
    MEMpaneloptions.solver.inactive_var_mult  	= str2double( ctrl.jInactiveVar.getText() );

    
    MEMpaneloptions.solver.Optim_method       	= char( ctrl.jOptimFN.getSelectedItem() );
    MEMpaneloptions.solver.parallel_matlab      = double( ctrl.jParallel.isSelected() );
    MEMpaneloptions.optional.display            = ctrl.jBoxShow.isSelected();
    MEMpaneloptions.solver.NoiseCov_recompute   = double( ctrl.jNewCOV.isSelected() );
    MEMpaneloptions.solver.NoiseCov_method    	= str2double( ctrl.jVarCovar.getText() );

    if any( strcmp(MEMpaneloptions.mandatory.pipeline, {'wMEM','rMEM'}) )
        MEMpaneloptions.wavelet.type            = char( ctrl.jWavType.getText() );
        MEMpaneloptions.wavelet.vanish_moments 	= str2double( ctrl.jWavVanish.getText() );
        MEMpaneloptions.wavelet.order     	=   str2double( ctrl.jWavOrder.getText() );
        MEMpaneloptions.wavelet.nb_levels  	=   str2double( ctrl.jWavLevels.getText() );

    end

    if strcmp(MEMpaneloptions.mandatory.pipeline, 'wMEM') 
        MEMpaneloptions.wavelet.shrinkage   =  str2double( ctrl.jWavShrinkage.getText() );
        
        % process scales
        SCL = lower( char( ctrl.jWavScales.getSelectedItem() ) );
        if any( strcmpi( SCL, {'all','0'} ) )||isempty(SCL)
            nSC = ctrl.jWavScales.getItemCount();
            MEMpaneloptions.wavelet.selected_scales = 1 : nSC-2;                
        
        elseif strcmpi( SCL, 'not enough samples' )
            MEMpaneloptions.wavelet.selected_scales = []; 
            
        else                
            id1 = find(SCL=='(');
            id2 = find(SCL==')');
            for ii = 1: numel(id1)
                SCL(id1(ii):id2(ii)) = '';
            end
            MEMpaneloptions.wavelet.selected_scales = eval(['[' SCL ']']);
        end
        
    elseif strcmp(MEMpaneloptions.mandatory.pipeline, 'rMEM')

        MEMpaneloptions.ridges.scalo_threshold       =   str2double( ctrl.jRDGscaloth.getText() );
        MEMpaneloptions.ridges.energy_threshold      =   str2double( ctrl.jRDGnrjth.getText() );
        MEMpaneloptions.ridges.strength_threshold    =   str2double( ctrl.jRDGstrength.getText() );
        MEMpaneloptions.ridges.min_duration          =   str2double( ctrl.jRDGmindur.getText() );
        MEMpaneloptions.ridges.cycles_in_window    	 =   str2double( ctrl.jRDGmincycles.getText() );
        
        % process frq range
        freq_label= {'gamma', 'beta', 'alpha', 'theta', 'delta'};
        freqs = [ [30 100] ; ... % gamma
                  [13 29]; ... % beta
                  [8 12]; ... % alpha
                  [4 7]; ... % delta
                  [1 3]]; %theta 
        RNG = strrep( lower(strtrim( char( ctrl.jRDGrangeS.getSelectedItem() ) ) ), '-', ' ' );
        
        if strcmpi( RNG, 'all') || isempty(RNG)
            MEMpaneloptions.ridges.frequency_range      =   [MEMglobal.freqs_analyzed(1) MEMglobal.freqs_analyzed(end)];
            
        elseif strcmpi( RNG, 'not enough samples')
            MEMpaneloptions.ridges.frequency_range      =   [];
            
        else
            selected_freq = strcmpi(freq_label, RNG);
            MEMpaneloptions.ridges.frequency_range      =   freqs(selected_freq,:);
            
            if MEMpaneloptions.ridges.frequency_range(1)<MEMglobal.freqs_analyzed(1)
                MEMpaneloptions.ridges.frequency_range(1)   =   MEMglobal.freqs_analyzed(1);
                fprintf('panel_brainentropy:\tmin. ridge frequency was out of range\n\t\t\tset to: %f\n', MEMglobal.freqs_analyzed(1));
            elseif MEMpaneloptions.ridges.frequency_range(1)>MEMglobal.freqs_analyzed(end)
                MEMpaneloptions.ridges.frequency_range(1)   =   MEMglobal.freqs_analyzed(1);
                fprintf('panel_brainentropy:\tmin. ridge frequency was out of range\n\t\t\tset to: %f\n', MEMglobal.freqs_analyzed(1));
            end
            if MEMpaneloptions.ridges.frequency_range(2)>MEMglobal.freqs_analyzed(end)
                MEMpaneloptions.ridges.frequency_range(2)   =   MEMglobal.freqs_analyzed(end);
                fprintf('panel_brainentropy:\tmin. ridge frequency was out of range\n\t\tset to: %f\n', MEMglobal.freqs_analyzed(end));
            elseif MEMpaneloptions.ridges.frequency_range(2)<MEMpaneloptions.ridges.frequency_range(1)
                MEMpaneloptions.ridges.frequency_range(2)   =   MEMglobal.freqs_analyzed(end);
                fprintf('panel_brainentropy:\tmin. ridge frequency was invalid\n\t\tset to: %f\n', MEMglobal.freqs_analyzed(end));
            end

        end
    end
    
    
    clear global BSLinfo
    s.MEMpaneloptions = MEMpaneloptions;

end


function adjust_range(WTA, rng)
    % Get info
    ctrl =  bst_get('PanelControls', 'InverseOptionsMEM');
    VAL  =  str2double( char(ctrl.(WTA).getText()) ); 
    
    % custom range
    if strcmp(WTA, 'jVarCovar')
        idX     =   [ctrl.jMEMdef.isSelected() ctrl.jMEMw.isSelected() ctrl.jMEMr.isSelected()];
        rng     =   rng{idX};
    end
    
    % adjust value
    VAL  =  max( VAL, rng(1) );
    VAL  =  min( VAL, rng(2) );
    
    % set value
    ctrl.(WTA).setText( num2str(VAL) );
end