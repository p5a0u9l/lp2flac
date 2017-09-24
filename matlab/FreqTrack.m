classdef FreqTrack < handle
    properties
        measurement
        estimate
        history
        count_since_last
    end

    properties(Constant)
        ALPHA = 0.2;
        BETA = 0.8;
        MOFN = 3;
    end

    properties(Dependent)
        state
        count
    end

    methods
        function me = init(me, detect)
            me.set_meas(detect);
            me.estimate = detect(1);
            me.history = me.measurement;
        end

        function me = set_meas(me, detect)
            me.measurement.freq = detect(1);
            me.measurement.index = detect(4);
            me.measurement.snr = detect(3);
        end

        function result = try_associate(me, detects)
            [val, idx] = min(abs(detects - me.estimate));
            if val > 20
                result = false;
            else
                result = true;
                me.set_meas(detects(idx, :));
            end
        end

        function me = update(me, has_new)
            if has_new
                me.history(me.count + 1) = me.measurement;
                me.count_since_last = 0;
                keyboard
            else
                keyboard
                me.count_since_last = me.count_since_last + 1;
            end
        end

        function val = get.state(me)
            if me.count < me.MOFN
                val = 'tentative';
            elseif me.count_since_last < 3
                val = 'confirmed';
            else
                val = 'stale';
            end
        end

        function val = get.count(me)
            val = length(me.history);
        end
    end
end
