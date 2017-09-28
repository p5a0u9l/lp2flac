function freq_trackr(filepath)
    [data, fs] = audioread(filepath);
    n_frame = 2048;
    framr = Framer().init(data, n_frame, 0.0, fs);
    n_fft = 2*n_frame;
    df = fs/n_fft;
    f_grid = (0:n_fft/2 - 1)*df;
    max_freq = 15e3;
    f_grid = f_grid(f_grid < max_freq);
    raw_stft = zeros(framr.n_total, length(f_grid));
    sdt = framr.n_frame/fs;
    slow_time = (0:framr.n_total - 1)*sdt;

    P = 20;
    all_detects = zeros(P*framr.n_total, 4);
    for i = 1:framr.n_total - 1
        % spectrum for this frame
        X = fft(framr.x, n_fft);

        % avg over channels
        X2 = mean(abs(X(1:n_fft/2, :)).^2, 2);

        % truncate to freq < max
        X2 = X2(f_grid < max_freq);
        raw_stft(i, :) = X2;

        % peak freqs for this frame
        detect0 = peak_detector(X2, f_grid, P, framr.i_frame);

        if ~any(detect0(:))
            framr.next();
            continue;
        end

        if mod(i, 100) == 0
            fprintf('detecting %d of %d...\n', i, framr.n_total);
        end

        all_detects((1:P) + (i - 1)*P, :) = detect0;
        framr.next();
    end
    audio_gen(all_detects, fs, n_frame);
    plots(all_detects, f_grid, slow_time, raw_stft);
end

function audio_gen(ad, fs, n_frame)
    % set up
    ad = array2table(ad, 'VariableNames', {'Freq', 'Power', 'Snr', 'Frame'});
    ad = sortrows(ad, 'Frame');
    ad = ad(ad.Power > 0.01, :);
    unqfr = unique(ad.Frame);
    n_total = length(unqfr);
    max_pow = max(ad.Power);
    t = (0:n_frame - 1)/fs;
    x = zeros(1, n_total*n_frame);

    % iterate over frames
    for i = 1:n_total
        if mod(i, 100) == 0
            fprintf('generating %d of %d...\n', i, n_total);
        end

        % set this frame's parameters
        offset = (i - 1)*n_frame;
        frame = ad(ad.Frame == unqfr(i), :);
        w = frame.Power/max_pow;
        f0 = frame.Freq;

        % match phasing of previous frame
        if i > 1
            a0 = w'*sin(2*pi*f0*t);
            x0 = x((-1:0) + offset);  % last two samples of previous frame
            x_extrap = interp1(1:2, x0, 3, 'linear', 'extrap');
            if F.within(x0(2), F.minmax(a0))
                phi0 = asin(x_extrap/sum(w));
                phi0 = phi0 + ...
                    double(sign(diff(x0)) ~= sign(diff(a0(1:2))))*(pi - 2*phi0);
            else
                % if last value of previous frame is not within range
                % of this frame, apply an artificial fade out
                tgt_ampl_adjst = abs(x0(2)) - max(abs(a0));

                n_hann = 2*n_frame;
                fade = hanning(n_hann)';
                % only the diminishing side
                fade = fade(n_hann/2:n_hann);
                % find the fade value that matches target amplitude
                itgt = 1 + F.argfunc(@min, abs(1 - fade - tgt_ampl_adjst));
                fade = fade(1:itgt);
                x((-itgt + 1:0) + offset) = x((-itgt + 1:0) + offset).*fade;

                x0 = x((-1:0) + offset);  % last two samples of previous frame
                x_extrap = interp1(1:2, x0, 3, 'linear', 'extrap');
                phi0 = asin(x_extrap/sum(w));
                phi0 = phi0 + ...
                    double(sign(diff(x0)) ~= sign(diff(a0(1:2))))*(pi - 2*phi0);
            end
        else
            phi0 = 0;
        end

        % compute/apply the syntehtic frame
        a = w'*sin(2*pi*f0*t + phi0);
        if ~isreal(a)
            keyboard
        end
        x((1:n_frame) + offset) = a;
    end
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

function detects = peak_detector(y2, x_grid, n_pk, iframe)
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
    detects = zeros(n_rise, 4);

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
        detects(i, 4) = iframe;
    end

    % down select to n_pk
    [~, sidx] = sort(detects(:, 2), 'descend');

    if n_rise >= n_pk
        detects = detects(sidx(1:n_pk), :);
    else
        detects = [detects; zeros(n_pk - n_rise, 4)];
    end
end
