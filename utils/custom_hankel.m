function H = custom_hankel(data, order)
    % CUSTOM_HANKEL - Constructs a Hankel matrix with shape 
    %                 [order x (T - order + 1) x m]
    %
    % Inputs:
    %   data - A T x m matrix, where T is #time steps, and m is the input
    %         dimension.
    %   order - The desired Hankel matrix order.
    %
    % Output:
    % 
    % H - A bl. Hankel matrix of size [order x (T - order + 1) x m]

    [m, T] = size(data);

    % if square
    %    order = ceil(T/2);
    % end

    if order > T
        error("Data matrix has %d rows, but at least %d rows" + ...
            " are required for order %d", T, order, order);
    end
    
    num_columns = T - order + 1; % #columns in the resulting Hankel matrix
    
    H = zeros(order, num_columns, m); % Preallocate the Hankel matrix

    for l=1:order
        u = data(:, l:(l + num_columns - 1));
        H(l, :, :) = u;
    end
     disp("Hankel Matrix H of order: "); % DEBUG STATEMENT
     fprintf("[%d, %d]", size(H, 1), size(H, 2)); % DEBUG STATEMENT
     disp(H), % DEBUG STATEMENT
end

