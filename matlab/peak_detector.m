function clusters = peak_detector(y2, x_grid, n_pk)
    % detect
    kernel = [ones(1, 4), zeros(1, 4), ones(1, 4)]';
    cfar = filter(kernel/sum(kernel), 1, y2, [], 1);
    alpha = 3;
    [n_samp, n_chan] = size(y2);
    pks = y2 > alpha*cfar;

    % cluster
    dpks = [zeros(1, n_chan); diff(pks)];
    rises = find(dpks == +1);
    falls = find(dpks == -1);
    clusters = zeros(length(rises), 2);

    % centroid
    for i = 1:length(rises)
        % add a neighbor on either side
        idx = max(1, rises(i) - 1):min(falls(i) + 1, n_samp);

        % centroid the freq measurement
        clusters(i, 1) = x_grid(idx)*y2(idx)'/sum(y2(idx));
        clusters(i, 2) = max(y2(idx));
    end

    % down select to n_pk
    if isempty(clusters); return; end

    [~, sidx] = sort(clusters(:, 2), 'descend');
    clusters = clusters(sidx(1:n_pk), :);
    keyboard
end


