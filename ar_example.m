% load the audio file
data = audioread('audio-samples/solo-guitar.wav');

% pull outthe frame of interest
N = 2048;
data_offset = 600000;  % offset into the audio file
x_frame = data((1:N) + data_offset, 1);

% create and ar model object
P = 60;
ar = ARInterpolator().init(x_frame, P).ml_fit();

% create a random, contiguous set of corrupted samples to simulate
% a frame with a click
n_corrupt = 100;
buffer = 400; % don't create corrupt indices at beginning or end of frame
corrupt_idx = (0:n_corrupt - 1) + randi(N - 2*buffer) + buffer;
i_corrupt = false(N, 1); i_corrupt(corrupt_idx) = true;

% interpoate over "bad" data
x_synth = ufunc.synthesize(ar, i_corrupt);
err = ufunc.compute_error(x_frame, x_synth, n_corrupt);


% plot some results
cla;
plot(x_frame, '.-'); grid on; hold on;
plot(x_synth, '-o'); title(sprintf('error: %f', err))
legend({'truth', 'synth'});
