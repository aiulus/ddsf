function [u_d, y_d] = generate_data(A, B, C, D, T, x_ini)
    %   Inputs:
    %   A, B, C, D - System matrices (default: C=1, D=0 for SISO systems)
    %   T - data length
    %   m - scaling factor
    %
    %   Outputs:
    %   u_d - input data
    %   y_d - output data

    fprintf("DATA GENERATOR running..."); % DEBUG STATEMENT

    % Set default values for SISO systems
    if nargin < 4 || isempty(C), C = 1; end
    if nargin < 5 || isempty(D), D = 0; end

    % Generate a persistently exciting, pseudo-random control input
    % m = L^2;
    % PE_input = m * (idinput([size(B, 2), L], 'prbs') + 1);
    % PE_input = idinput([L, size(B,2)], 'prbs', [0, 1], [-1,1]).'; % Generates a pseudo-random binary signal
    PE_input = idinput([T, size(B,2)], 'rgs', [0, 1], [-1,1]).';
    disp("PE_input: "); disp(PE_input);

    % Initialize input-output storage
    u_d = zeros(size(B, 2), T);
    y_d = zeros(size(C, 1), T);
    x_data = zeros(size(A, 1), 1); % Initial state
    x_data(1, 1) = x_ini;

    % Generate data by simulating the system on random inputs for L steps
    for i = 1:T
        u_d(:, i) = PE_input(:, i);
        %% TODO: This is computed with x_data = 0 at i=1, instead, 
        %% it must be initialized with the initial state of the system
        y_d(:, i) = C * x_data(i, 1) + D * u_d(:, i);
        x_data(i + 1, 1) = A * x_data(i, 1) + B * u_d(:, i);
    end
    fprintf("x_data = [%s]\n", join(string(x_data), ',')); % DEBUG STATEMENT
end

