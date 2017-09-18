classdef Framer < handle
    properties
        x           % the current frame of audio
        n_frame     % the size of the frame
        i_frame     % index to current frame
        overlap     % 0 <= overlap <= 1, the overlap ratio
        n_total     % total number of frames
    end

    properties(Hidden)
        fs          % sample rate of the data
        offset      % the sample offset into the data
        n_incre     % the number of samples by which to increment to get next frame
        data        % the entire stream
    end

    methods
        function me = init(me, data, n, o, fs)
            me.n_frame = n;
            me.overlap = o;
            me.i_frame = 1;
            me.offset = 0;
            me.fs = fs;
            me.n_incre = n*(1 - o);
            me.n_total = floor(length(data)/me.n_incre);
            me.data = data(1:me.n_incre*me.n_total, :);
            if length(me.data) < length(data)
                fprintf('INFO: truncated stream by %d samples...\n', ...
                    length(data) - length(me.data));
            end
            me.current();
        end

        function me = next(me)
            % retrieve the current frame
            me.i_frame = me.i_frame + 1;
            me.offset = me.offset + me.n_incre;
            me.current();
        end

        function me = current(me)
            % retrieve the current frame
            me.x = me.data((1:me.n_frame) + me.offset, :);
        end

        function me = plot_frame(me)
            ax = gca();
            if isempty(ax.Children)
                is_init = true;
            else
                is_init = false;
            end

            if mod(me.i_frame, 2) == 0
                ax.ColorOrderIndex = 1;
            end
            plot((0:me.n_frame - 1)/me.fs + me.offset/me.fs, me.x, '.-');

            if is_init
                hold on; grid on;
                xlabel('time [sec]'); axdrag;
            end
        end

        function me = animate(me)
            plot((0:me.n_frame*me.n_total - 1)/me.fs, me.data, '.');
            hold on; grid on;
            xlabel('time [sec]'); axdrag;
        end
    end
end

