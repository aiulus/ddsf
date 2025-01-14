function [H_u, H_y] = hankelDDSF(u_d, y_d, sys)
    T_ini = sys.config.T_ini;
    N_p = sys.config.N_p;
    PE_order = N_p + 2 * T_ini;

    [~, H_u] = construct_hankel(u_d, PE_order);
    [~, H_y] = construct_hankel(y_d, PE_order);

    full_rank = PEness_check(H_u);
    if ~full_rank
        error(['Persistency of excitation check failed. ' ...
            'Please provide richer input data or adjust T_ini and N.']);
    end
end