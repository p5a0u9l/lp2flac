function clusters = peak_detector(y2, x_grid, n_pk)
    % detect

    kernel = [ones(1, 4), zeros(1, 4), ones(1, 4)]';
    n_kernel = length(kernel);
    cfar = conv2(y2, kernel/n_kernel, 'same');
    alpha = 3;
    [n_samp, n_chan] = size(y2);

    pks = y2 > alpha*cfar;

    % cluster
    dpks = [zeros(1, n_chan); diff(pks)];
    rises = find(dpks == +1);
    falls = find(dpks == -1);
    n_rise = length(rises);
    clusters = zeros(n_rise, 2);

    % centroid
    for i = 1:n_rise
        % add a neighbor on either side

        if length(falls) >= i && falls(i) > rises(i)
            idx = max(1, rises(i) - 1):min(falls(i) + 1, n_samp);
        else
            idx = max(1, rises(i) - 1):min(rises(i) + 1, n_samp);
        end

        % centroid the freq measurement
        clusters(i, 1) = x_grid(idx)*y2(idx)/sum(y2(idx));
        clusters(i, 2) = max(y2(idx));
    end

    % down select to n_pk

    [~, sidx] = sort(clusters(:, 2), 'descend');

    if n_rise >= n_pk
        clusters = clusters(sidx(1:n_pk), :);
    else
        clusters = [clusters; zeros(n_pk - n_rise, 2)];
    end
end


