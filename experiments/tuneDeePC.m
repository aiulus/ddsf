% mode  -   Options: {
%                       'nt':       vary T_ini and N (prediction horizon) simultaneously,    
%                       'qr':       vary input (Q) and output (R) cost matrices simultaneously                 
%                       'mixed':    vary all of the above simulteneously
%          
mode = 'nt';

vals = struct( ...
    'NvsTini', [ ... % value range for mode 'nt'
    1 * ones(6, 1), (5:5:30)'; ...
    2 * ones(6, 1), (5:5:30)'; ...
    5 * ones(5, 1), (10:5:30)'; ...
    10 * ones(4, 1), (15:5:30)' ...
    ], ...
    'QvsR', table2array(combinations(logspace(-2, 4, 7), logspace(-2, 2, 5))), ... % value range for mode 'qr'
    'mixed', struct( ... % value ranges for mode 'mixed'
                    'nt', [ ...
                    2 * ones(6, 1), (5:5:30)'; ...
                    5 * ones(5, 1), (10:5:30)' ...
                    ], ...
                    'qr', table2array(combinations(logspace(-2, 1, 4), logspace(-2, 1, 4))) ...
                    ) ...
    );

% systype   - Options: {'test', 'example0', 'cruise_control', 'quadrotor', 
%                        'inverted_pendulum', 'dc_motor', 'dampler', 
%                        'thermostat', 'cstr'}
%           - Specifies the type of system to initialize.
%           - See systems\sysInit.m for details.
systype = 'dampler';

% #Simulation steps to be performed by (deepcTunerFlex >) runParamDPC.m
T_sim = 10;

% Whether the output CSV-file (containing simulation data) should be saved
% - configured to be true by default in deepcTunerFlex.m
toggle_save = 1;

[u, y, descriptions, filename] = deepcTunerFlex(mode, vals, systype, T_sim, toggle_save);

batchplot(filename);