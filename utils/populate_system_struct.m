function sys = populate_system_struct(A, B, C, D, params)
    % Constructs the system struct with matrices, dimensions, and constraints.
    sys.A = A;
    sys.B = B;
    sys.C = C;
    sys.D = D;

    % Dimensions
    sys.dims.state = size(A, 1);
    sys.dims.input = size(B, 2);
    sys.dims.output = size(C, 1);

    % Parameters and target
    sys.params = params;
    sys.target = params.target;

    k = min(size(B));
    n = size(A, 1);
    T_u = sparse_pinv(B, k) * (eye(n) - A);
    x_eq = ones(n, 1);
    u_eq = T_u * x_eq;
    y_eq = C * x_eq + D * u_eq;

    %sys.S_f = struct( ...
    %    'u_eq', u_eq, ...
    %    'y_eq', y_eq ...
    %    );

    % Initialize terminal safe set with an equlibrium point
    S_f = table([], [], 'VariableNames',{'u_eq', 'y_eq'});
    S_f = [S_f; {u_eq, y_eq}];
    sys.S_f = S_f;

    sys.equilibrium.U = T_u;
end