function X = stft(x, n, n_overlap)
    n_samp = length(x);
    n_frame = floor(n_samp/(n - n_overlap));
    X = zeros(n_frame, n);
    w = hanning(n);
    for i = 1:n_frame
        X(i, :) = w.*x((1:n) + (i - 1)*n_overlap);
    end
end
