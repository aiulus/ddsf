%% Defines and solves an optimization problem as described in DeePC

function [g_opt, u_opt, y_opt] = deepc_opt(Up, Yp, Uf, Yf, u_ini, y_ini, r, Q, R, U, Y, N)
    g = sdpvar(size(Up, 2), 1); % Optimization variable
    u = Uf * g; % Predicted inputs
    y = Yf * g; % Predicted outputs

    % Display debug information
    disp("size of Up: "); disp(size(Up));
    disp("Up: "); disp(Up);
    disp("size of Yp: "); disp(size(Yp));
    disp("Yp: "); disp(Yp);
    disp("size of Uf: "); disp(size(Uf));
    disp("Uf: "); disp(Uf);
    disp("size of Yf: "); disp(size(Yf));
    disp("Yf: "); disp(Yf);
    disp("size of g: "); disp(size(g));
    disp("size of u: "); disp(size(u));
    disp("size of U: "); disp(size(U));
    disp("U: "); disp(U);
    disp("size of y: "); disp(size(y));
    disp("size of Y: "); disp(size(Y));
    disp("Y: "); disp(Y);
    disp("size of u_ini: "); disp(size(u_ini));


    % Define the cost function
    cost = 0;
    for k = 1:N
        cost = cost + (y(k) + r(k))' * Q * (y(k) - r(k)) + u(k)' * R * u(k);
    end
    
    % Define the constraints
    % constraints = [Up * g == u_ini, Yp * g == y_ini, u <= U, y <= Y];
    % constraints = [Up * g == u_ini, Yp * g == y_ini];

    constraints = [Up * g == u_ini, Yp * g == y_ini, ...
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
        disp("Constraints:");  disp(constraints);
        disp("Cost function:"); disp(cost);        
        error('Optimization problem is infeasible!')
    end
end

