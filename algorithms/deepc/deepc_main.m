%% DeePC algorithm
debug_toggle = true; % Toggle debug mode
save_to_file = true; % Set to true if log file desired
log_interval = 1; % Log every <log_interval> iterations

%% Step 0: Define global parameters, fetch system
% Fetch system
%sys = linear_system("cruise_control");
%sys = nonlinear_system("inverted_pendulum");
%sys = nonlinear_system("deepc_quadrotor");
%sys = nonlinear_system("ddsf_quadrotor");
%sys = LTI("single_integrator");
%sys = LTI('double_integrator');
sys = LTI("dc_motor");

   
% Access DeePC configuration parameters from the system struct
deepc_config = sys.deepc_config;

T = deepc_config.T; % # Data points
T_ini = deepc_config.T_ini; % Length of initial trajectory
N = deepc_config.N; % Prediction horizon
s = deepc_config.s; % Sliding length
Q = deepc_config.Q * eye(sys.params.p); % Output cost matrix
R = deepc_config.R * eye(sys.params.m); % Control cost matrix

m = sys.params.m;  % Input dimension
p = sys.params.p; % Output dimension
n = sys.params.n; % Dim. of the minimal state-space representation

%% Step 1: Data collection
[u_d, y_d, ~, ~, ~] = generate_data(sys, T); % Simulate the system

%% Step 2: Generate the Hankel matrices
[Up, Yp, Uf, Yf] = deepc_hankel(u_d, y_d, sys);

%% Step 3: Define Initial Condition
u_ini = u_d(:, 1:T_ini).'; % Initial input trajectory
y_ini = y_d(:, 1:T_ini).'; % Initial output trajectory

if debug_toggle
    disp('--- SYSTEM PARAMETERS ---');
    disp(sys.deepc_config);
    disp('Initial u_ini:');
    disp(u_ini);
    disp('Initial y_ini:');
    disp(y_ini);
    disp('-------------------------');
end

%% Step 4: Receding Horizon Loop
max_iter = 50; % Simulation steps
u_hist = zeros(N, size(sys.C, 1)); % For later storage of applied inputs
y_hist = zeros(N, size(sys.B, 2)); % For later storage of resulting outputs

ref_trajectory = repmat(sys.target.', N, 1);

for k = 0:max_iter-1
    t = k * s + 1; % Calculate the current time step
    
    if t > max_iter
        break; % Exit the loop if t exceeds max_iter
    end

    % Solve the quadratic optimization problem 
    [g_opt, u_opt, y_opt] = deepc_opt(Up, Yp, Uf, Yf, ...
        u_ini, y_ini, ...
        ref_trajectory, sys);

    % Apply the first s optimal control inputs
    u_t = value(u_opt);
    y_t = value(y_opt);

    u_hist(t: t+s) = u_t(1:(s + 1));
    y_hist(t: t+s) = y_t(1:(s + 1));

    %% TODO: Check if the returned y corresponds to this system update
    % Simulate system response
    % y_t = sys.C * y_seq(max(t - 1, 1)) + sys.D * u_t; % already returned
    % by _opt
    %y_seq(:,t) = y_t; % Store the output
    
    debug_log(debug_toggle, t, log_interval, save_to_file, ...
        'u_ini', u_ini, 'y_ini', y_ini, 'u_t', u_t, 'y_t', y_t, ...
         'ref_trajectory', ref_trajectory);

    % Update the initial trajectory / slide the window by s
    u_ini = [u_ini((s + 1):end, :); u_t(1:s)];
    y_ini = [y_ini((s + 1):end, :); y_t(1:s)];
end

debug_log(max_iter, 1, debug_toggle, save_to_file, 'u_hist', u_hist, 'y_hist', y_hist); 

%% Final Output
% Display the applied control inputs and resulting system outputs
figure;
subplot(2,1,2);
plot(u_hist);
title('Control Inputs');
xlabel('Time'); ylabel('Control Input');
grid on;
subplot(2,1,1);
hold on;
plot(y_hist, 'b');
plot(1:max_iter, ref_trajectory(1)*ones(1, max_iter), 'r--', 'LineWidth', 1.5);
title('System Outputs');
xlabel('Time'); ylabel('Output');
grid on;
hold off;







