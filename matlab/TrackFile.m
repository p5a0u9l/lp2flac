classdef TrackFile < handle
    properties
        tracks
        history
        trackidx
    end

    properties(Hidden)
        histcount
    end

    properties(Dependent)
        trackcount
    end

    methods
        function me = init(me, new_detects)
            % sort detects by power
            me.histcount = 0;
            me.history = cell(10000, 1);
            new_detects = new_detects(...
                F.argfunc(@sort, new_detects(:, 3)), :);
            for i = 1:size(new_detects, 1)
                me.tracks = [me.tracks; ...
                    FreqTrack().init(i, new_detects(i, :))];
            end
            me.trackidx = i;
        end

        function me = update(me, new_detects)
            %UPDATE tracks not stale
            % --- if one of new detects associates, update
            % --- else if track is confirmed, update the stale ticker
            % --- else delete the track

            new_tracks = false(size(new_detects, 1), 1);
            delidx = false(me.trackcount, 1);
            for i = 1:me.trackcount
                trk0 = me.tracks(i);
                didx = trk0.try_associate(new_detects);
                if didx > 0
                    % remove associated detect from candidates
                    new_detects(didx, :) = [];
                    trk0.update(true);
                elseif trk0.state == "confirmed"
                    trk0.update(false);
                elseif trk0.state == "stale"
                    me.append_to_history(trk0);
                    delidx(i) = true;
                elseif trk0.state == "tentative"
                    delidx(i) = true;
                end
            end

            me.delete_track(delidx);

            idx = find(new_tracks);
            for i = 1:length(idx)
                me.tracks(me.trackcount + 1) = ...
                    FreqTrack().init(new_detects(idx(i), :));
            end
        end

        function me = append_to_history(me, trk0)
            me.histcount = me.histcount + 1;
            tmp.freq = trk0.estimate;
            tmp.freq = trk0.estimate;
            me.history{me.histcount + 1, :} = copy(me.tracks(idx));
        end

        function me = delete_track(me, idx)
            me.tracks(idx) = [];
        end

        function you = state_filter(me, state)
            you = me.tracks([me.tracks.state] ~= state);
        end

        function val = get.trackcount(me)
            val = length(me.tracks);
        end
    end
end
