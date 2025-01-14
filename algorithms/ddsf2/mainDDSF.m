%% Step 1: Configuration
T_sim = 50; % Simulation length
run_options = struct( ...
    'datagen_mode', 'scaled_gaussian', ...
    'system_type', 'quadrotor', ...
    'T_sim', T_sim, ...
    'T_d', 0 ... % Input delay [s] / dt [s]
    );

IO_params = struct( ...
    'debug', true, ...
    'save', true, ...
    'log_interval', 1, ... % Log every n-the step of the simulation
    'verbose', false ...
    );

% TODO: Add information on various the configuration options
opt_params = struct( ...
                    'discretize', false, ... 
                    'regularize', false, ...
                    'constr_type', 'f', ...
                    'solver_type', 'o', ...
                    'target_penalty', false, ...    
                    'init', true, ... % Encode initial condition
                    'R', 10 ...
                   );

% Initialize the system
sys = systemsDDSF(run_options.system_type, opt_params.discretize); 
dims = sys.dims;
opt_params.R = opt_params.R * eye(dims.m);

% Create struct object 'lookup' for central and extensive parameter passing.
lookup = struct( ...
                'sys', sys, ...
                'sys_params', sys.params, ...
                'opt_params', opt_params, ...
                'config', sys.config, ...
                'dims', dims, ...
                'IO_params', IO_params, ...
                'T_sim', run_options.T_sim, ...
                'datagen_mode', run_options.datagen_mode, ...
                'T_d', run_options.T_d ...
                );


%% Step 2: Generate data & Hankel matrices
[u_d, y_d, x_d, ~, ~] = gendataDDSF(lookup); 

[H_u, H_y] = hankelDDSF(u_d, y_d, sys);
 
lookup.H = [H_u; H_y];
lookup.H_u = H_u; lookup.H_y = H_y;
lookup.dims.hankel_cols = size(H_u, 2);

% START DEBUG STATEMENTS
% lookup.config.R = 150;
%lookup.config.T = 100;
epsilon = 0.01;
lookup.H_u = H_u + epsilon * eye(size(H_u)); 
lookup.H_y = H_y + epsilon * eye(size(H_y));
lookup.H = [H_u; H_y];
% END DEBUG STATEMENTS

%% Initialize objects to log simulation history
T_ini = lookup.config.T_ini;
logs = struct( ...
        'u_d', zeros(dims.m, T_sim + T_ini), ...
        'u', [u_d(:, 1:(1+ T_ini)).'; ...
        zeros(dims.m, T_sim).'].', ... 
        'y', [y_d(:, 1:(1 + T_ini)).'; ...
        zeros(dims.p, T_sim).'].', ... 
        'x', [x_d(:, 1:(1+T_ini)).'; ...
        zeros(dims.n, T_sim).'].', ... % TODO: tracking x not necessary
        'loss', zeros(2, T_ini + T_sim) ...
    );

% TODO: Wrap debug statements in if-statements with IO_params.debug

% Obtain an L-step random control policy
u_l = learning_policy(lookup);
T_d = run_options.T_d;
%% Step 3: Receding Horizon Loop
for t=(T_ini + 1):(T_ini + T_sim)
    fprintf("----------------- DEBUG Information -----------------\n");
    fprintf("CURRENT SIMULATION STEP: t = %d\n", t - T_ini);

    u_ini = logs.u(:, (t - T_ini):(t-1));
    y_ini = logs.y(:, (t - T_ini):(t-1));
    traj_ini = [u_ini; y_ini];
    
    %fprintf("Submitting u_l with value: "); disp(u_l);
    if (t - T_ini - T_d) < 1
        ul_t = 0;
    else 
        ul_t = u_l(:, t - T_ini - T_d);
    end    

    [u_opt, y_opt] = optDDSF(lookup, ul_t, traj_ini);
    loss_t = get_loss(lookup, ul_t, u_opt, y_opt);
    %fprintf("Received optimal values u_opt = %d, y_opt = %d\n", value(u_opt), value(y_opt));

    u_next = u_opt(:, 1 + T_ini);
    y_next = y_opt(:, 1 + T_ini);
    %fprintf("Storing first optimal values u_opt[1] = %d, y_opt[1] = %d\n", value(u_opt(:, 1)), value(y_opt(:, 1)));
    
    logs.u_d(:, t) = ul_t;
    logs.u(:, t) = u_next;
    logs.y(:, t) = y_next;
    logs.loss(:, t) = loss_t;

    % Add recursively feasible points to the safe terminal set
    lookup.sys.S_f.u_eq = [lookup.sys.S_f.u_eq, u_next];
    lookup.sys.S_f.y_eq = [lookup.sys.S_f.y_eq, y_next];
end

%% Plot the results
time = 0:(T_sim + lookup.config.T_ini);
plotDDSF(time, logs, lookup)

% Should this use the same policy as data generation?
function u_l = learning_policy(lookup)
    sys = lookup.sys;
    m = sys.dims.m;
    % L = lookup.config.N_p + 2 * lookup.config.T_ini;
    T_sim = lookup.T_sim;
    mode = lookup.datagen_mode;

    lb = sys.constraints.U(:, 1);
    lb(lb == -inf) = 1;
    ub = sys.constraints.U(:, 2);
    ub(ub == inf) = 1;
    %fprintf("1. <learning_policy> Lower and Upper bounds: [%d, %d]\n", lb, ub);

    switch mode
        case 'scaled_gaussian'
            scale = 1.25;
            ub = (ub > 0) .* (scale .* ub) + (ub < 0) .* ((scale^(-1)) .* ub) + (ub == 0) .* (10^scale);
            lb = (lb < 0) .* (scale .* lb) + (lb > 0) .* ((scale^(-1)) .* lb) + (lb == 0) .* (- 10^scale);
            ub = (ub > 0) .* (scale .* ub) + (ub < 0) .* ((scale^(-1)) .* ub);
            lb = (lb < 0) .* (scale .* lb) + (lb > 0) .* ((scale^(-1)) .* lb);
            u_l = lb + (ub - lb) .* rand(m, T_sim);
            % DEBUG STATEMENT
            % u_l = ones(m, L);
            %fprintf("2. <learning_policy> Relaxed lower and Upper bounds: [%d, %d]\n", lb, ub);
        case 'rbs'
            u_l = idinput([m, T_sim], 'rbs', [0, 1], [-1,1]); 
        case 'scaled_rbs'            
            lower = 0.5;
            upper = 0.8;
            num = 10;
            probs = (1/num) * ones(1, num);
            factors = linspace(lower, upper, num);
            scaler = randsample(factors, T_sim, true, probs);
            lb = lb .* scaler;
            ub = ub .* scaler;

            u_l = idinput([m, T_sim], 'rbs', [0, 1], [-1,1]); 
            u_l = u_l .* (lb + (ub - lb) .* rand(1));
    end
end

%   Can later be changed to:
%       u_l = learning_policy(y, y_d)
%
%   INPUTS:
%       y   - Current system output (px1)
%       y_d - Desired system output

function loss = get_loss(lookup, u_l, u_opt, y_opt)
    R = lookup.opt_params.R;
    y_target = lookup.sys.params.target;

    loss1 = det(R) * norm(u_l - u_opt);    
    loss2 = loss1 + norm(y_target - y_opt);
    
    loss = [loss1; loss2];
end