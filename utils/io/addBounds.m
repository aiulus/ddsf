function addBounds(time, bounds, configname)
    factor = filename2param(configname, 'constr');
    if isempty(factor)
        factor = 1;
    end
    bounds = updateBounds(bounds, factor);
    if bounds(1) ~= -inf && bounds(1) < 1e+8
        plot(time, bounds(1) * ones(size(time)), 'm--', 'LineWidth', 1.25, 'DisplayName', 'Lower Bound'); 
    end
    if bounds(2) ~= inf && bounds(1) < 1e+8
        plot(time, bounds(2) * ones(size(time)), 'm--', 'LineWidth', 1.25, 'DisplayName', 'Upper Bound'); 
    end
end