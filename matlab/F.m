classdef F
    % a static class to encapsulate small functions
    %
    methods(Static)  % MATH
        function y = argfunc(func, x)
            [~, y] = func(x);
        end

        function y = complex2dB(z)
            y = 10*log10(F.complex2pow(z) + eps);
        end

        function y = complex2pow(z)
            y = abs(z).^2;
        end
    end

    methods(Static)  % SIGNAL
        function X = stft(x, n, n_overlap)
            n_samp = length(x);
            n_advance = n - n_overlap;
            n_frame = floor(n_samp/n_advance);
            X = zeros(n_frame, n);
            w = chebwin(n);
            for i = 1:n_frame
                idx = (1:n) + (i - 1)*n_advance;
                if max(idx) <= n_samp
                    z = fft(w.*x(idx), 2*n);
                    X(i, :) = z(1:n);
                end
            end
        end

        function G = matrix_G(x, P)
            % basis matrix G
            % cf. DAR 4.47
            N = size(x, 1);
            G = zeros(N - P, P);
            for k = 1:P
                G(:, k) = x(P + 1 - k:N - k);
            end
        end

        function A = matrix_A(a, N)
            % cf. DAR 4.53
            P = size(a, 1);
            A = zeros(N - P, N);
            row = [-fliplr(a'), 1, zeros(1, N - P - 1)];
            for k = 1:N - P
                A(k, :) = circshift(row, [0, k - 1]);
            end
        end

        function mad = compute_mad(x_synth, x_true, n_corrupt)
            % the ground truth used inner product
            mse = F.compute_mse(x_synth, x_true, n_corrupt);
            se = (x_true - x_synth).^2;
            mad = max(abs(se - mse));
        end

        function mse = compute_mse(x_synth, x_true, n_corrupt)
            % compute the mean error between the syntehtic (interpolated) data and
            % the ground truth used inner product
            mse = x_true - x_synth;
            mse = mse'*mse/n_corrupt;
        end
    end

    methods(Static)  % PLOT
        function stft_image(x, fs)
            df = fs/size(x, 2);
            f = 0:df:fs/2 - df;
            st = (0:size(x, 1))*size(x, 2)/fs;
            F.new_docked_fig();
            imagesc(f, st, x);
            nf = median(x(:));
            pk = max(x(:));
            colorbar(); colormap('hot');
            caxis([nf + 9, pk + 2])
            axdrag(); grid on;
            xlabel('Hz'); ylabel('slow time');
        end

        function add_line(orientation, position)
            ax = gca();
            N = 100;
            if strcmp(orientation, 'V')
                y = linspace(ax.YLim(1), ax.YLim(2), N);
                x = ones(1, N)*position;
            elseif strcmp(orientation, 'H')
                x = linspace(ax.XLim(1), ax.XLim(2), N);
                y = ones(1, N)*position;
            end
            plot(x, y, 'w--');
        end

        function f = new_docked_fig()
            f = figure();
            f.WindowStyle = 'docked';
        end
    end
end
