classdef ARplusBasis < handle
    % x_n = \sum_{i = 1}^P a_i x_{n - 1} + e_n + \sum_{i = 1}^Q c_i \psi[n]
    %
    %   If Q = 0, the data is modelled as an AR process of order P. For
    %   Q > 0, the data is modelled as weighted sum of basis functions
    %   plus a residual term modelled as an AR process of order P.
    %
    properties
        P   % the AR model order
        Q   % the Basis function model order
        a   % the (unknown) AR model parameters (P x 1)
        c   % the (unknown) basis function parameters (Q x 1)
        e   % the innovation corresponding to a
        x   % the observed datas
        x0  % the first P values of the data
        x1  % the remaining N - P values of the data
        N   % size of the data samples
    end

    methods
        function me = init(me, data, p, q)
            me.P = p;
            me.Q = q;
            me.x = data;
            me.N = length(me.x);
            me.x0 = me.x(1:me.P);
            me.x1 = me.x(me.P + 1:me.N);
        end

        function me = ml_fit(me)
            % covariance estimate, cf. DAR 4.51
            G = F.matrix_G(me.x, me.P);
            me.a = (G' * G) \ (G' * me.x1);
        end

        function x_interp = ls_interp(me, i_corrupt)
            % the missing sample indicators, cf. DAR 5.15
            A = F.matrix_A(me.a, me.N);
            i = i_corrupt;
            x_interp = -(A(:, i)'*A(:, i)) \ A(:, i)' * (A(:, ~i) * me.x(~i));
        end

        function s = synthesize(me, i_corrupt)
            % given an ar object, containing the observed signal, x, and a logical index
            % into the corrupted samples, run an interpolator to reconstruct
            % (synthesize) the missing audio and form the restored audio vector
            s = me.x;
            s(i_corrupt, :) = me.ls_interp(i_corrupt);
        end
    end
end
