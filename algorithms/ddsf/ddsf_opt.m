function [alpha, u_opt, y_opt] = ddsf_opt(u_l, H_u, H_y, traj_ini, sys)
    %% Setup
    % Extract system parameters
    N_p = sys.ddsf_config.N_p; % Prediction horizon
    T = sys.ddsf_config.T; % Data length
    T_ini = sys.ddsf_config.T_ini;
    R = sys.ddsf_config.R;
    S_f = sys.S_f; % TODO: Should only be computed if ddsf_main is bring run
                   %       but still store S_f as an attribute of sys.

   % Initialize decision variables as symbolic variables
   alpha = sdpvar(size(H_u, 2), 1, 'full');
   u_opt = sdpvar(sys.params.m, N_p, 'full'); % TODO: check
   y_opt = sdpvar(sys.params.p, N_p, 'full');

   %% Define the optimization problem
   cost = (u_opt - u_l).' * R * (u_opt - u_l); % Objective function

   u_p = H_u * alpha; 
   y_p = H_y * alpha; 
   traj_p = [u_p; y_p]; % Predicted trajectory
   traj = [u_ini; u_p; y_ini; y_p];
   
   constraints = [-u_opt <= -sys.U(1) * ones(size(u_opt)), ...
               u_opt <= sys.U(2) * ones(size(u_opt)), ...
               -y_opt <= -sys.Y(1) * ones(size(y_opt)), ...
               y_opt <= sys.Y(2) * ones(size(y_opt)), ...
               traj == [H_u; H_y] * alpha, ...
               traj_ini == traj_p * [H_u; H_y]];
   %% TODO: Add constraints related to S_f

   % Solve the optimization problem using YALMIP
   options = sdpsettings('solver', 'quadprog', 'verbose', 0);
   %% TODO: Add error handling + fmincon
   diagnostics = optimize(constraints, cost, options);

   if diagnostics.problem == 0
       alpha = value(alpha);
       u_opt = value(u_opt);
       y_opt = value(y_opt);
   else
       % Check if failure is due to nonconvexity and retry with fmincon
        warning('Quadprog failed. Trying with fmincon...');
        options_fmincon = sdpsettings('verbose', 1, 'solver', 'fmincon');  

        diagnostics = optimize(constraints, cost, options_fmincon);
    
        if diagnostics.problem == 0 % Feasible solution found with fmincon
            % Extract optimal values
            alpha = value(alpha);
            u_opt = value(u_opt);
            y_opt = value(y_opt);
        else
            error('Optimization problem is infeasible even with fmincon!');
        end
   end
end
