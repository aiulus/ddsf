function plotDDSF(time, logs, lookup)    
    sys = lookup.sys;
    ul_hist = logs.u_d;
    u_hist = logs.u;
    y_hist = logs.y;
    loss_hist = logs.loss;
        
    figure(1);
    m = size(u_hist, 1);
    tiledlayout(m, 1); % Use tiled layout for better control
    
    % Plot learning vs safe inputs
    for i = 1:m
        nexttile;
        stairs(0:size(ul_hist, 2)-1, ul_hist(i, :), 'r', 'LineWidth', 1.25, 'DisplayName', sprintf('ul[%d]', i));
        hold on;
        stairs(0:size(u_hist, 2)-1, u_hist(i, :), 'b', 'LineWidth', 1.5, 'DisplayName', sprintf('u[%d]', i));
    
        bounds = sys.constraints.U(i, :);
    
        % Plot boundaries
        if bounds(1) ~= -inf
            plot(time, bounds(1) * ones(size(time)), 'm--', 'DisplayName', 'Lower Bound');
        end
        if bounds(2) ~= inf
            plot(time, bounds(2) * ones(size(time)), 'k--', 'DisplayName', 'Upper Bound');
        end
    
        title(sprintf('Learning vs Safe Input %d', i));
        xlabel('t');
        ylabel(sprintf('Input %d', i));
        grid on;
        legend show;
        hold off;
    end
        
    figure(2);
    tiledlayout(m, 1); % Combine all inputs into a single layout
    
    % Plot learning vs safe inputs
    for i = 1:m
        nexttile;
        stairs(0:size(ul_hist, 2) - 1, ul_hist(i, :), 'r', 'LineStyle', ':','LineWidth', 1.75, 'DisplayName', sprintf('ul[%d]', i));
        hold on;
        stairs(0:size(u_hist, 2) - 1, u_hist(i, :), 'b', 'LineWidth', 1.25, 'DisplayName', sprintf('u[%d]', i));
    
        bounds = sys.constraints.U(i, :);
    
        % Plot boundaries
        if bounds(1) ~= -inf
            plot(time, bounds(1) * ones(size(time)), 'm--', 'DisplayName', 'Lower Bound');
        end
        if bounds(2) ~= inf
            plot(time, bounds(2) * ones(size(time)), 'k--', 'DisplayName', 'Upper Bound');
        end
    
        title(sprintf('Learning vs Safe Input %d', i));
        xlabel('t');
        ylabel(sprintf('Input %d', i));
        grid on;
        legend show;
        hold off;
    end        
    sgtitle('Learning Inputs vs. Safe Inputs');

    figure(3);
    p = size(y_hist, 1);
    tiledlayout(p, 1); % Combine all inputs into a single layout

    for i = 1:p
        nexttile; hold on;
        plot(time, y_hist(i, :), 'k', 'LineWidth', 1.25, 'DisplayName', sprintf('y[%d]', i));
        bounds = sys.constraints.Y(i, :);
    
        % Plot boundaries
        if bounds(1) ~= -inf
            plot(time, bounds(1) * ones(size(time)), 'b--', 'DisplayName', 'Lower Bound');
        end
        if bounds(2) ~= inf
            plot(time, bounds(2) * ones(size(time)), 'r--', 'DisplayName', 'Upper Bound');
        end
        if lookup.opt_params.target_penalty
            pi = sys.params.target(i);
            plot(time, pi * ones(size(time)), 'g--', 'DisplayName', 'Target');
        end
    
        title(sprintf('System Output %d', i));
        xlabel('t');
        ylabel(sprintf('Output %d', i));
        grid on;
        legend show;
        hold off;
    end
    sgtitle("Resulting Outputs");


    figure(4);
    hold on;
    plot(0:size(loss_hist, 2) - 1, loss_hist(1, :), 'r', 'LineWidth', 1.25, 'DisplayName', 'delta_u');
    plot(0:size(loss_hist, 2) - 1, loss_hist(2, :), 'b', 'LineWidth', 1.25, 'DisplayName', 'delta_u + distance to target convergence point');
    grid on; legend show; hold off;
    sgtitle('Losses');

    figure(2);
    matlab2tikz('quad_inputs_t50.tex');
    figure(3);
    matlab2tikz('quad_outputs_t50.tex');
end

function single_plots(time, logs, sys)
    ul_hist = logs.u_d;
    u_hist = logs.u;
    y_hist = logs.y;

    figure(1);
    p = size(y_hist, 1);
    for i = 1:p
        subplot(p, 1, i);
        plot(0:size(y_hist, 2), y_hist(i, :), 'r', 'LineWidth', 1.25, 'DisplayName', sprintf('y[%d]', i));
        bounds = sys.constraints.Y(i, :);
        if bounds(1) ~= -inf
            plot(time, bounds(1) * ones(size(time)), 'm--', 'DisplayName', 'Lower Bound');
        end
        if bounds(2) ~= inf
            plot(time, bounds(2) * ones(size(time)), 'k--', 'DisplayName', 'Upper Bound');
        end
        title(sprintf('System Output %d', i));
        xlabel('t');
        ylabel(sprintf('Output %d', i));
        grid on;
        legend show;
    end
    sgtitle('System Outputs');
    
        
    figure(2);
    m = size(u_hist, 1);
    tiledlayout(m, 1); % Use tiled layout for better control
    
    for i = 1:m
        nexttile; % Equivalent to subplot
        stairs(time, ul_hist(i, :), 'r', 'LineWidth', 1.25, 'DisplayName', sprintf('ul[%d]', i));
        bounds = sys.constraints.U(i, :);
    
        % Plot boundaries
        if bounds(1) ~= -inf
            hold on;
            plot(time, bounds(1) * ones(size(time)), 'm--', 'DisplayName', 'Lower Bound');
        end
        if bounds(2) ~= inf
            hold on;
            plot(time, bounds(2) * ones(size(time)), 'k--', 'DisplayName', 'Upper Bound');
        end
    
        title(sprintf('Learning Input %d', i));
        xlabel('t');
        ylabel(sprintf('Learning Input %d', i));
        grid on;
        legend show;
        hold off;
    end
    
    sgtitle('Learning Inputs');
    
    
    figure(3);
    m = size(u_hist, 1);
    tiledlayout(m, 1); % Use tiled layout for better control
    
    for i = 1:m
        nexttile;
        stairs(time, u_hist(i, :), 'b', 'LineWidth', 1.5, 'DisplayName', sprintf('u[%d]', i));
        bounds = sys.constraints.U(i, :);
    
        % Plot boundaries
        if bounds(1) ~= -inf
            hold on;
            plot(time, bounds(1) * ones(size(time)), 'm--', 'DisplayName', 'Lower Bound');
        end
        if bounds(2) ~= inf
            hold on;
            plot(time, bounds(2) * ones(size(time)), 'k--', 'DisplayName', 'Upper Bound');
        end
    
        title(sprintf('Safe Input %d', i));
        xlabel('t');
        ylabel(sprintf('Safe Input %d', i));
        grid on;
        legend show;
        hold off;
    end
    
    sgtitle('Safe Inputs');
    
end