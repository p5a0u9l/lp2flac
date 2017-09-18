function ar_interp_monte(n_trial)
    % randomly iterate over frames, locations within frame and vary the the number of
    % corrupted samples. Record the average parameter estimation err for each iteration
    % in a table whos columns are number of corrupted samples.
    %
    % We want to visualize how the pe err varies with missing sample size
    % We note that two statistics from each iteration are wanted - that of the
    % overall mean sq. error, given by e'*e/n_corrupt, as well as the maximum
    % error
    %
    % This experiment indicates that more comlicated, polyphonic music s more sensitive
    % to missing samples
    %
    audio_types = {'solo-guitar.wav', 'chamber-orchestra.wav'};
    audio_type_alias = {'guitar', 'chamber'};
    n_audio_types = length(audio_types);
    stepsize = 5;
    n_corrupt_steps = 5:stepsize:100;
    n_corrupt_trials = length(n_corrupt_steps);
    n_corrupt_sigma = stepsize/5;
    recompute = true;

    % perform the missing sample simulation
    err = struct();
    if recompute
        for i_audio_type = 1:n_audio_types
            at_alias = audio_type_alias{i_audio_type};
            err.(at_alias) = zeros(length(n_corrupt_trials*n_trial), 3);
            [data, fs] = audioread(fullfile(...
                'audio-samples', audio_types{i_audio_type}));

            tic();
            for i_trial = 1:n_trial
                fprintf('%12s - %4d / %4d... ', at_alias, i_trial, n_trial); toc();

                % pull a frame of interest a random offset into the audio file
                data_offset = 2*fs + randi(100*fs);
                x_frame = data((1:N) + data_offset, 1);
                keyboard

                % create an ar model object
                P = 60;
                ar = ARplusBasis().init(x_frame, P, 0).ml_fit();

                % iterate over varying number of corrupted samples
                for i_corrupt = 1:n_corrupt_trials
                    n_corrupt = n_corrupt_steps(i_corrupt) + ...
                        round(n_corrupt_sigma*randn());
                    index = (i_trial - 1) * n_corrupt_trials + i_corrupt;
                    [err.(at_alias)(index, 1), err.(at_alias)(index, 2)] = ...
                        single_iteration(ar, n_corrupt);
                    err.(at_alias)(index, 3) = n_corrupt;
                end
            end
        end
        save ar_interp_montecarlo_error err
    else
        load ar_interp_montecarlo_error
    end

    % compute error statistics
    epit = struct();
    for i = 1:n_audio_types
        at_alias = audio_type_alias{i};
        x = err.(at_alias)(:, 3);
        for k = 1:n_corrupt_trials
            if k == 1
                xi = x < n_corrupt_steps(k + 1) - n_corrupt_sigma;
            elseif k == n_corrupt_trials
                xi = x >= n_corrupt_steps(k - 1) + n_corrupt_sigma;
            else
                xi = x < n_corrupt_steps(k + 1) - n_corrupt_sigma ...
                    & ...
                    x >= n_corrupt_steps(k - 1) + n_corrupt_sigma;
            end
            for j = 1:2
                y = err.(at_alias)(xi, j);
                epit.(at_alias).x(k, j) = n_corrupt_steps(k);
                epit.(at_alias).mse(k, j) = mean(y);
                epit.(at_alias).std(k, j) = std(y);
            end
        end
    end

    plots(err, epit);

    keyboard
end

function plots(err, epit)
    % plots
    figure(1); clf
    errorbar(epit.guitar.x(:, 1), ...
        log(epit.guitar.mse(:, 1)), log(epit.guitar.std(:, 1)));
    hold on; grid on;
    errorbar(epit.chamber.x(:, 1), ...
        log(epit.chamber.mse(:, 1)), log(epit.chamber.std(:, 1)));
    plot(err.guitar(:, 3), log(err.guitar(:, 1)), '.', 'markersize', 2);
    plot(err.chamber(:, 3), log(err.chamber(:, 1)), '.', 'markersize', 2);
    xlabel('number of corrupted samples per trial');
    title('log(MSE) parameter estimation error');
    legend({...
        'fit - solo guitar', 'fit - chamber music'...
        'data - solo guitar', 'data - chamber music', ...
        });

    figure(2); clf
    errorbar(epit.guitar.x(:, 2), ...
        log(epit.guitar.mse(:, 2)), log(epit.guitar.std(:, 2)));
    hold on; grid on;
    errorbar(epit.chamber.x(:, 2), ...
        log(epit.chamber.mse(:, 2)), log(epit.chamber.std(:, 2)));
    plot(err.guitar(:, 3), log(err.guitar(:, 2)), '.', 'markersize', 2);
    plot(err.chamber(:, 3), log(err.chamber(:, 2)), '.', 'markersize', 2);
    xlabel('number of corrupted samples per trial');
    title('log(MAD) parameter estimation error');
    legend({...
        'fit - solo guitar', 'fit - chamber music'...
        'data - solo guitar', 'data - chamber music', ...
        });
end

function [mse, mad] = single_iteration(ar, n_corrupt)
    % perform a single monte carlo trial given an ar object and specified number
    % of missing data samples. return the MSE (mean-squared error) and the MAD
    % (max absolute deviation) of the ar-interpolated data.
    %
    % create a random, contiguous set of corrupted samples to simulate
    % a frame with a click
    buffer = 5*ar.P; % don't create corrupt indices at beginning or end of frame
    corrupt_idx = (0:n_corrupt - 1) + randi(ar.N - 2*buffer) + buffer;
    i_corrupt = false(ar.N, 1);
    i_corrupt(corrupt_idx) = true;

    % interpolate over "bad" data
    x_synth = ar.synthesize(i_corrupt);
    mse = F.compute_mse(x_synth, ar.x, n_corrupt);
    mad = F.compute_mad(x_synth, ar.x, n_corrupt);
end
