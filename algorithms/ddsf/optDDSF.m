function [u_opt, y_opt] = optDDSF(lookup, u_l, traj_ini)
    reg_params = struct( ...
        'lambda', 0.01, ... % For regularizing H
        'epsilon', 0.5, ... % For constraint relaxation
        'ridge', 0.1 ...   % Penalty on higher alpha-norms
        );

    verbose = lookup.IO_params.verbose;
    %% Extract parameters
    opt_params = lookup.opt_params;

    % Lengths and dimensions
    T_ini = lookup.config.T_ini;
    N = lookup.config.N;
    L = N + 2 * T_ini;
    s = lookup.config.s;
    m = lookup.dims.m;
    p = lookup.dims.p;
    num_cols = lookup.dims.hankel_cols;
    
    % Matrices
    R = lookup.opt_params.R;
    H = lookup.H;
    T = eye(L, L);
    
    % Constraints
    U = lookup.sys.constraints.U;
    Y = lookup.sys.constraints.Y;
    u_min = U(:, 1);
    u_max = U(:, 2);
    y_min = Y(:, 1);
    y_max = Y(:, 2);

    % Initial trajectory and equilibrium states
    u_ini = traj_ini(1:m, :);
    y_ini = traj_ini(m+1:end, :);

    u_eq = lookup.sys.S_f.u_eq(1);
    y_eq = lookup.sys.S_f.y_eq(1);

    if iscell(u_eq)
        u_eq = cell2mat(u_eq);
    end
    if iscell(y_eq)
        y_eq = cell2mat(y_eq);
    end



    %% TODO: S_f can be used to encode a desired target state

    %% Define symbolic variables
    alpha = sdpvar(num_cols, 1);
    control_u = sdpvar(m, L);
    control_y = sdpvar(p, L);
    
    %% Populate the initial and terminal parts of the trajectory
    % Replaces the encodings in constraints
    control_u(:, 1:T_ini) = u_ini;
    control_y(:, 1:T_ini) = y_ini;
    control_u(:, end - T_ini + 1 : end) = repmat(u_eq, 1, T_ini); % T_ini + N + 1 : end
    control_y(:, end - T_ini + 1 : end) = repmat(y_eq, 1, T_ini);

    %% Flatten the variables 
    u_bar = reshape(control_u.', [], 1);
    y_bar = reshape(control_y.', [], 1);
    traj_p_bar = [u_bar; y_bar];

    %% Define the objective function and the constraints
    % delta_u = control_u(:, 1+T_ini:end) - u_l;
    % objective = delta_u * R * delta_u.';
    
    delta_u = reshape(control_u(:, 1+T_ini:end-T_ini) - u_l, [], 1);
    objective = delta_u.' * kron(eye(N), R) * delta_u;

    if opt_params.regularize
        % H = regHankelDDSF(lookup.H_u, lookup.H_y);
        % num_cols = size(H, 2);
        H = H / norm(H, 'fro'); % Normalize with Frobenius norm
        lambda = reg_params.lambda;
        H = H + lambda * eye(size(H)); % Tikhonov regularization

        ridge = reg_params.ridge;
        objective = objective + ridge * (alpha.' * alpha);
    end

    if lookup.opt_params.target_penalty
        % FOR DEBUGGING 

        target = lookup.sys.params.target;
        target(isnan(target)) = 0;
        target = repmat(target, L, 1);        
        delta_y = y_bar - target;
        delta_y = reshape(delta_y, p, L);

        discount = 0.9;
        gamma = discount .^ (L:-1:1);
        gamma = repmat(gamma, p, 1);
        delta_y = delta_y .* gamma;

        tpt = trace(delta_y * T * delta_y.');
        objective = objective + tpt;
    end

    constraints = traj_p_bar == H * alpha; 
    
    switch opt_params.constr_type
        case 's' % Just enforce system behavior
            % No additional constraints needed
        case 'u' % Just encode input constraints
            constraints = [constraints, ...
                           control_u >= repmat(u_min, 1, N + 2 * T_ini), ...
                           control_u <= repmat(u_max, 1, N + 2 * T_ini)];
        case 'y' % Just encode output constraints
            constraints = [constraints, ...
                           control_y >= repmat(y_min, 1, N + 2 * T_ini), ...
                           control_y <= repmat(y_max, 1, N + 2 * T_ini)];
        case 'f' % All constraints
            constraints = [constraints, ...
                           control_u >= repmat(u_min, 1, N + 2 * T_ini), ...
                           control_u <= repmat(u_max, 1, N + 2 * T_ini), ...
                           control_y >= repmat(y_min, 1, N + 2 * T_ini), ...
                           control_y <= repmat(y_max, 1, N + 2 * T_ini)];
    end

    %% Define solver settings and run optimization
    switch opt_params.solver_type
        case 'q'
            options = sdpsettings('verbose', verbose, 'solver', 'quadprog');
        case 'f'
            options = sdpsettings('verbose', verbose, 'solver', 'fmincon');
        case 'o'
            options = sdpsettings('solver', 'OSQP', ...
                  'verbose', verbose, ...             % Detailed solver output
                  'osqp.max_iter', 20000, ...         % Set maximum iterations
                  'osqp.eps_abs', 1e-3, ...           % Absolute tolerance
                  'osqp.eps_rel', 1e-3, ...           % Relative tolerance
                  'osqp.adaptive_rho', true, ...      % Enable adaptive rho
                  'osqp.adaptive_rho_interval', 50, ...
                  'osqp.adaptive_rho_tolerance', 1, ...
                  'osqp.polish_refine_iter', 2, ...
                  'osqp.scaling', 10, ...             % Number of scaling iterations
                  'warmstart', 0);                    % Disable warm start
        case 'b'
            options = sdpsettings('solver', 'bmibnb', 'verbose', verbose);
    end


    diagnostics = optimize(constraints, objective, options);
        
    if diagnostics.problem == 0 % Feasible solution found
        % Extract optimal values
        u_opt = value(control_u);
        y_opt = value(control_y);
    else
        % fprintf('\n---------------------------- OPTIMIZER FAILED ----------------------------\n');
        disp(diagnostics.problem); % Solver exit code
        disp(diagnostics.info);    % Detailed solver feedback        
    end

    if lookup.IO_params.verbose
        disp('---- Debug: Objective Function Evaluation ----');
        disp('Objective value:');
        disp(value(objective)); % Ensure it computes as expected
        disp('---- Debug: Feasibility Check ----');
        disp('Max constraint violation:');
        disp(max(check(constraints))); % Show largest constraint violation
    end

end

%% Helper methods
function [u, y] = alpha2traj(H_u, H_y, alpha)
    u = H_u * value(alpha);
    u = reshape(u, lookup.dims.m, []);

    y = H_y * value(alpha);
    y = reshape(y, lookup.dims.p, []);
end

function H = lra_svd(H)
    [U, S, V] = svd(H);
    rank_cutoff = floor(size(H, 2) * 0.9); % Retain 90% of singular values
    S(rank_cutoff+1:end, rank_cutoff+1:end) = 0;
    H = U * S * V'; % Reconstruct low-rank approximation
end

