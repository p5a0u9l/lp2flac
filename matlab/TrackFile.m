classdef TrackFile < handle
    properties
        tracks
    end
    properties(Dependent)
        trackcount
    end

    methods
        function me = init(me, new_detects)
            me.tracks = repmat(FreqTrack(), size(new_detects, 1), 1);
            for i = 1:size(new_detects, 1)
                me.tracks(i).init(new_detects(i, :));
            end
        end

        function me = update(me, new_detects)
            for i = 1:me.trackcount
                trk0 = me.tracks(i);
                trk0.update(trk0.try_associate(new_detects));
            end
        end

        function val = get.trackcount(me)
            val = length(me.tracks);
        end
    end
end
