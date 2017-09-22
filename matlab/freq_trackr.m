function freq_trackr(filepath)
    [data, fs] = audioread(filepath);
    framr = Framer().init(data, 2048, 0.0, fs);
    n_fft = 4096;
    df = fs/n_fft;
    f_grid = (0:n_fft/2 - 1)*df;
    max_freq = 15e3;
    f_grid = f_grid(f_grid < max_freq);
    raw_stft = zeros(framr.n_total, length(f_grid));
    sdt = framr.n_frame/fs;
    slow_time = (0:framr.n_total - 1)*sdt;

    P = 20;
    detects = zeros(P, 2, framr.n_total);
    for i = 1:framr.n_total - 1
        % spectrum for this frame
        X = fft(framr.x, n_fft);

        % avg over channels
        X2 = mean(abs(X(1:n_fft/2, :)).^2, 2);

        % truncate to freq < max
        X2 = X2(f_grid < max_freq);
        raw_stft(i, :) = X2;

        % peak freqs for this frame
        detects(:, :, i) = peak_detector(X2, f_grid, P);

        if mod(i, 100) == 0
            fprintf('detecting %d of %d...\n', i, framr.n_total);
        end

        framr.next();
    end
    plots(detects, f_grid, slow_time, raw_stft);
    keyboard
end

function plots(detects, f_grid, slow_time, raw_stft)
    F.new_docked_fig();
    rdb = 10*log10(raw_stft);
    imagesc(f_grid, slow_time, rdb); colormap hot; colorbar
    ax(1) = gca();
    title('raw stft'); xlabel('f [Hz]'); ylabel('slow time [s]');
    F.clim(rdb);

    % unpack
    freqs = squeeze(detects(:, 1, :));
    ampls = 20*log10(squeeze(detects(:, 2, :)));

    % decompress into image
    f_quant = 0:20:max(f_grid);
    img = zeros(length(slow_time), length(f_quant));
    for i = 1:length(slow_time)
        ifreq = discretize(freqs(:, i), f_quant);
        if any(isnan(ifreq)); continue; end
        img(i, ifreq) = ampls(:, i);
    end

    F.new_docked_fig();
    imagesc(f_quant, slow_time, img); colormap hot; colorbar
    ax(2) = gca();
    title('feature stft'); xlabel('f [Hz]'); ylabel('slow time [s]');
    F.clim(img);

    linkaxes(ax);

    keyboard
end

function detects = peak_detector(y2, x_grid, n_pk)
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
    detects = zeros(n_rise, 2);

    % centroid
    for i = 1:n_rise
        % add a neighbor on either side

        if length(falls) >= i && falls(i) > rises(i)
            idx = max(1, rises(i) - 1):min(falls(i) + 1, n_samp);
        else
            idx = max(1, rises(i) - 1):min(rises(i) + 1, n_samp);
        end

        % centroid the freq measurement
        detects(i, 1) = x_grid(idx)*y2(idx)/sum(y2(idx));
        detects(i, 2) = max(y2(idx));
        detects(i, 3) = max(y2(idx) - alpha*cfar(idx));
    end

    % down select to n_pk
    [~, sidx] = sort(detects(:, 2), 'descend');

    if n_rise >= n_pk
        detects = detects(sidx(1:n_pk), :);
    else
        detects = [detects; zeros(n_pk - n_rise, 2)];
    end
end
