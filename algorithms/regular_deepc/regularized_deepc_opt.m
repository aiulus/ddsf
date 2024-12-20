%% Defines and solves an optimization problem as described in DeePC

function [g_opt, u_opt, y_opt, sigma_y] = regularized_deepc_opt(Up, Yp, Uf, Yf, u_ini, y_ini, r, Q, R, U, Y, N, lambda_g, lambda_y)
    T_ini = max(size(u_ini));
    g = sdpvar(size(Uf, 2), 1); % Canocical optimization variable € R^{(T - T_{ini} - N + 1) x 1}
    sigma_y = sdpvar(T_ini * size(Yf, 3), 1);

    u = Uf * g; % Predicted inputs
    y = Yf * g; % Predicted outputs 

    % Define the cost function
    cost = 0;
    for k = 1:N
        cost = cost + (y(k) - r(k))' * Q * (y(k) - r(k)) + u(k)' * R * u(k);
    end
    
    % Add the regularization terms to the cost function
    cost = cost + lambda_g * norm(g, 1);
    cost = cost + lambda_y * norm(sigma_y, 1);

    % Define the constraints
    constraints = [Up * g == u_ini, Yp * g == y_ini + sigma_y, ...,
               u >= U(1), u <= U(2), ...
               y >= Y(1), y <= Y(2)];


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

