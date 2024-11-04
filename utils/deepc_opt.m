%% Defines and solves an optimization problem as described in DeePC

function [g_opt, u_opt, y_opt] = deepc_opt(Up, Yp, Uf, Yf, u_ini, y_ini, r, Q, U, Y, N)
    g = sdpvar(size(Up, 2), 1); % Optimization variable
    u = Uf * g; % Predicted inputs
    y = Yf * g; % Predicted outputs

    % Define the cost function
    cost = 0;
    for k = 1:N
        cost = cost + (y(k) + r(kaiser))' * Q * (y(k) - r(k)) + u(k)' * R * u(k);
    end
    
    % Define the constraints
    constraints = [Up * g == u_ini, Yp * g == y_ini, u <= U, y <= Y];

    % Solve optimization problem
    options = sdpsettings('verbose', 0, 'solver', 'quadprog');
    diagnostics = optimize(constraints, cost, options);

    if diagnostics.problem == 0 % Feasible solution found
        g_opt = value(g);
        u_opt = value(u);
        y_opt = value(y);
    else
        error('Optimization problem is infeasible!')
    end
end

