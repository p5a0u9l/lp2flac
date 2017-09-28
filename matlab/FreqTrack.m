classdef FreqTrack < handle
    properties
        measurement
        power
        estimate
        frame_window
        number
    end

    properties(Hidden)
        continuous_count
        count_since_last
        % hash
    end

    properties(Hidden, Constant)
        ALPHA = 0.2;
        BETA = 0.8;
        MOFN = 3;
        MAX_FREQ_ERR = 20;
    end

    properties(Dependent)
        state
        total_count
    end

    methods
        function me = init(me, number, detect)
            me.number = number;
            me.power = detect(3);
            me.measurement = detect(1);
            me.estimate = detect(1);
            me.frame_window = [detect(4), detect(4) + 1];

            me.history = me.measurement;
            me.continuous_count = 1;
            me.count_since_last = 0;

            % me.hash = string(py.hashlib.sha256(...
                % sprintf('%f, %f, %f, %f', ...
                % detect(1), detect(2), detect(3), detect(4)...
                % )).hexdigest());
        end

        function result = try_associate(me, detects)
            [val, idx] = min(abs(detects - me.estimate));
            if val > me.MAX_FREQ_ERR
                result = -1;
            else
                result = idx;
                me.set_meas(detects(idx, :));
            end
        end

        function me = update(me, has_new)
            if has_new
                me.estimate = me.estimate*me.BETA + ...
                                me.measurement.freq*me.ALPHA;
                me.history(me.total_count + 1).freq = me.measurement.freq;
                me.history(me.total_count + 1).index = me.measurement.index;
                me.history(me.total_count + 1).snr = me.measurement.snr;
                me.history(me.total_count + 1).est = me.estimate;
                if me.count_since_last == 0
                    me.continuous_count = me.continuous_count + 1;
                end
                me.count_since_last = 0;
            else
                me.count_since_last = me.count_since_last + 1;
            end
        end

        function val = get.state(me)
            if me.total_count < me.MOFN
                val = "tentative";
            elseif me.count_since_last < 3
                val = "confirmed";
            else
                val = "stale";
            end
        end

        function val = get.total_count(me)
            val = length(me.history);
        end
    end
end
