%% DeePC algorithm

%% Step 0: Define global parameters
deepc_alg = struct();
   
T = 25; % Window length (must be at least N + T_ini!!)
T_ini = 5; % Length of initial trajectory
N = 10; % Prediction horizon
s = 1; % length of slice from u* that's actually applied to the system 
Q = 1; % Output cost matrix (in R^pxp; p: output dim.)
R = 0; % Control cost matrix (in R^mxm; m: input dim.)

deepc_alg.params.t = T;
deepc_alg.params.tini = T_ini;
deepc_alg.params.tp = N;
deepc_alg.params.s = s;
deepc_alg.params.Q = Q;
deepc_alg.params.R = R;

% Fetch system
sys = linear_system("cruise_control");


%% Step 1: Data collection

% Simulate the system
[u_d, y_d] = generate_data(sys, T);

%% Step 2: Generate the Hankel matrices
[Up, Yp, Uf, Yf] = deepc_hankel(u_d, y_d, T_ini, N);

%% Step 3: Define Initial Condition
u_ini = u_d(1:T_ini).'; % Initial input trajectory
y_ini = y_d(1:T_ini).'; % Initial output trajectory

%% Step 4: Receding Horizon Loop
max_iter = 50; % Simulation steps
u_seq = zeros(N, size(sys.C, 1)); % For later storage of applied inputs
y_seq = zeros(N, size(sys.B, 2)); % For later storage of resulting outputs

ref_trajectory = sys.target * ones(N, 1);

counter = 0; % DEBUG VARIABLE

for t = 1:max_iter
    % Solve the quadratic optimization problem
    % Up, Yp, Uf, Y
    % f, u_ini, y_ini, r, Q, R, U, Y, N
    [g_opt, u_opt, y_opt] = deepc_opt(Up, Yp, Uf, Yf, ...
        u_ini, y_ini, ...
        ref_trajectory, Q, R, sys.constraints.U, sys.constraints.Y, N, T);
    counter = counter + 1; fprintf("Running %d - th optimizazion step", counter); % DEBUG STATEMENT

    % Apply the first optimal control input
    u_t = value(u_opt);
    y_t = value(y_opt);
    u_seq(:,t) = u_t;
    y_seq(:,t) = y_t;

    % Simulate system response
    % y_t = sys.C * y_seq(max(t - 1, 1)) + sys.D * u_t; % already returned
    % by _opt
    %y_seq(:,t) = y_t; % Store the output

    % Update the initial trajectory
    % Just using one step of the optimal input for receding horizon
    u_ini = [u_ini(2:end, :); u_t(1)];
    y_ini = [y_ini(2:end, :),; y_t(1).'];

    % DEBUG STATEMENTS
    fprintf('Iteration %d:', t);
    fprintf('Control Input of shape (%s): u_t = [%s]\n', join(string(size(u_t)), ','), join(string(u_t), ','));
    fprintf('Output of shape (%s): y_t = [%s]\n', join(string(size(y_t)), ','), join(string(y_t), ','));
    fprintf('Initial output trajectory of shape (%s): y_ini = [%s]\n', join(string(size(y_ini)), ','), join(string(y_ini), ','));
    fprintf('Initial control trajectory of shape (%s): u_ini = [%s]\n', join(string(size(u_ini)), ','), join(string(u_ini), ','));
end

%% Final Output
% Display the applied control inputs and resulting system outputs
figure;
subplot(2,1,1);
plot(u_seq);
title('Applied Control Inputs');
subplot(2,1,2);
plot(y_seq);
title('System Outputs');

