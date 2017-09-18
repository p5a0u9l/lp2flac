clear;
source = 'Jesu, Joy of Man''s Desiring.wav';

[x, fs] = audioread(source);

dt = 1/fs;
t_frame = 0.04;
p = 53; q = 11;
[n_samp, n_chan] = size(x);

n_frame = round(t_frame*fs);
start_window = 1000;
n_window = floor(n_samp/n_frame);
t = 0:dt:(n_samp - 1)*dt;

pe_ms_est = zeros(2, n_window);
% y_intercept = zeros(2, n_window);
% noise = zeros(2, n_window);
% fpe = zeros(2, n_window);
x_synth = zeros(size(x));


for i = start_window:n_window
    x_win = x((-p:n_frame + p) + i*n_frame, :);
    % [y_intercept(:, i), A, C, sbc, fpe(i), th] = arfit(x_win, p, p);
    % noise(:, i) = diag(C)';
    % G = makearmat(x_win, p);
    [A, pe_ms_est(1, i), G] = ar_model(x_win(:, 1), p);
    x2 = G*A;
    keyboard
    [A, pe_ms_est(2, i), G] = ar_model(x_win(:, 2), p);
end

newfig = @() figure('WindowStyle', 'docked');

newfig();
plot(x(p:end)); grid on; hold on;
plot(x2 + w + C);

newfig();
plot(x(p + 1:end) - x2);
