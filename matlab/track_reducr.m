function track_reducr(filepath)
    [data, fs] = audioread(filepath);
    framr = Framer().init(data, 2048, 0.5, fs);
    n_fft = 4096;
    df = fs/n_fft;
    f_grid = (0:n_fft/2 - 1)*df;
    for i = 1:framr.n_total
        x = fft(framr.x, n_fft);
        x2 = abs(x(1:n_fft/2, :)).^2;
        clusters = peak_detector(x2, f_grid, 20);
        if i == 100
            keyboard
        end

        framr.next();
    end

end
