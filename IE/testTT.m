classdef testTT < matlab.unittest.TestCase
    % TESTTT Suite de TT.m. Cubre el zig-zag agregado y deja fijadas las
    % cuatro conexiones que ya existian, para que un cambio en el modelo
    % comun no las mueva sin que nadie se entere.
    %   runtests('testTT')

    properties (Constant)
        D = struct('V_LP',13800, 'a',10, 'S',300e3, 'theta',30);
    end

    methods (Test)

        function conexionesViejasNoSeMovieron(tc)
            % REGRESION. Estos numeros se midieron ANTES de tocar
            % TT.factores y TT.modelo para meter el zig-zag. Si el zig-zag
            % hubiera ensuciado el modelo comun, rompen aca.
            esp = struct( ...
                'YY', [1380.0000, 125.5109,   0], ...
                'DD', [1380.0000, 125.5109,   0], ...
                'YD', [ 796.7434, 217.3913,  30], ...
                'DY', [2390.2301,  72.4638, -30]);
            for c = fieldnames(esp)'
                r = TT.(c{1})(tc.D);
                tc.verifyEqual(double(r.V_LS), esp.(c{1})(1), 'RelTol', 1e-6, c{1});
                tc.verifyEqual(double(r.I_LS), esp.(c{1})(2), 'RelTol', 1e-6, c{1});
                tc.verifyEqual(double(r.desf), esp.(c{1})(3), 'AbsTol', 1e-9, c{1});
            end
        end

        function zigzagSeComportaComoEstrellaEnLineaYFase(tc)
            % El zig-zag es una estrella para la relacion linea-fase:
            % V_LS = sqrt(3)*V_phiS. Con V_LP = 13800 y a = 10 da los
            % mismos 1380 V que una Y-Y; lo que cambia son las vueltas.
            r = TT.YZ(tc.D);
            tc.verifyEqual(double(r.V_LS), 1380, 'RelTol', 1e-9);
            tc.verifyEqual(double(r.V_LS), sqrt(3)*double(r.V_phiS), ...
                'RelTol', 1e-9);
        end

        function desfaseYz1(tc)
            % Y-Z da grupo Yz1: el secundario atrasa 30 grados.
            tc.verifyEqual(double(TT.YZ(tc.D).desf), 30, 'AbsTol', 1e-9);
        end

        function desfaseDz0(tc)
            % D-Z da grupo Dz0: en fase. La delta no mete los 30 grados
            % que mete la estrella, y se cancelan con los -30 internos del
            % zig-zag.
            tc.verifyEqual(double(TT.DZ(tc.D).desf), 0, 'AbsTol', 1e-9);
        end

        function elZigzagCuesta15PorCientoMasDeCobre(tc)
            % EL NUMERO QUE JUSTIFICA LA CONEXION. Para la MISMA relacion
            % de tension y el mismo primario, el zig-zag necesita
            % 2/sqrt(3) = 1.1547 veces las vueltas de una estrella comun.
            d = tc.D;  d.N_P = 1000;
            NsY = double(TT.YY(d).N_S);
            NsZ = double(TT.YZ(d).N_S);
            tc.verifyEqual(NsY, 100, 'RelTol', 1e-9);
            tc.verifyEqual(NsZ/NsY, 2/sqrt(3), 'RelTol', 1e-9);
            tc.verifyEqual(NsZ, 115.4700538379252, 'RelTol', 1e-9);
        end

        function yzYDzSoloDifierenEnElPrimario(tc)
            % Lo que dice el cuestionario del curso: entre Y-Z y Delta-Z la
            % unica diferencia es la conexion del primario. Partiendo de la
            % MISMA tension de fase primaria, el secundario sale identico y
            % solo cambia el desfase.
            d = struct('V_phiP',7967.433714, 'a',10);
            ry = TT.YZ(d);  rz = TT.DZ(d);
            tc.verifyEqual(double(ry.V_phiS), double(rz.V_phiS), 'RelTol', 1e-9);
            tc.verifyEqual(double(ry.V_LS),   double(rz.V_LS),   'RelTol', 1e-9);
            tc.verifyNotEqual(double(ry.desf), double(rz.desf));
        end

        % NO hay test del codigo de conexion invalido: TT.resolver es
        % privado y los seis metodos publicos pasan codigos validos, asi
        % que el 'otherwise' de TT.factores es inalcanzable desde afuera.
        % Queda como guarda interna, no como comportamiento verificable.

    end
end
