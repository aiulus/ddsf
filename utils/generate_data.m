function [u_d, y_d] = generate_data(sys, T)
    A = sys.A;
    B = sys.B;
    C = sys.C;
    D = sys.D;

    % Generate a persistently exciting, pseudo-random control input
    PE_input = idinput([T, size(B,2)], 'prbs', [0, 1], [-1,1]).'; % Generates a pseudo-random binary signal
    % PE_input = idinput([T, size(B,2)], 'rgs', [0, 1], [-1,1]).';
    %PE_input = idinput([T, sys.params.m], 'prbs', [0, 1], [-1,1]).'; 
    disp("PE_input: "); disp(PE_input);

    % Initialize input-output storage
    u_d = zeros(sys.params.m, T);
    y_d = zeros(sys.params.p, T);
    x_d = zeros(sys.params.n, T); % Initial state

    % Generate data by simulating the system on random inputs for L steps
    for i = 1:T
        u_d(:, i) = PE_input(:, i);
        %% TODO: This is computed with x_data = 0 at i=1, instead, 
        %% it must be initialized with the initial state of the system
        x_d(:, i + 1) = A * x_d(:, i) + B * u_d(:, i);
        y_d(:, i) = C * x_d(:, i) + D * u_d(:, i);
    end
end

