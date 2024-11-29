function lat = system_latency(A, C)
    %   LAT = SYSTEM_LATENCY(A, C) returns the smallest integer LAT such that
    %   the observability matrix constructed from A and C has full rank.
    %
    %   Inputs:
    %       A - State matrix
    %       C - Output matrix

    n = size(A, 1);
    H = C; % l = 0

    for l = 0:n-1
        if custom_rank(H) == n
            lat = l; 
            return;
        end
        H = [H; C * A ^ l];
    end
    error("System is not observable");
end
