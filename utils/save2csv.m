function save2csv(time, u_sim, y_sim)
    % Ensure time vector is a column vector
    time = time(:);

    u_csv = [time, u_sim.'];
    y_csv = [time, y_sim.'];

    writematrix(u_csv, 'u.csv', 'Delimiter', ',', 'WriteMode', 'overwrite');
    writematrix(y_csv, 'y.csv', 'Delimiter', ',', 'WriteMode', 'overwrite');
end