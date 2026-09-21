classdef testLineal < matlab.unittest.TestCase
    % TESTLINEAL Suite de la maquina lineal CC (IE.ecLineal, IE.lineal,
    % IE.trayLineal). Correr con:  runtests('testLineal')
    %
    % El caso de referencia es el ejemplo clasico de Chapman:
    %   B = 0.5 T, l = 1 m, R = 0.25 ohm, VB = 120 V, m = 10 kg
    % cuyos valores analiticos se conocen y estan escritos a mano en cada
    % test, no calculados con las mismas funciones que se estan probando.

    properties (Constant)
        D = struct('B',0.5, 'l',1, 'R',0.25, 'VB',120, 'm',10);
        % Ejemplo 1-10 de Chapman
        C = struct('B',0.1, 'l',10, 'R',0.3, 'VB',120, 'm',10);
    end

    methods (Test)

        function vacioDaVelocidadMaxima(tc)
            % Sin carga la corriente se anula y la barra llega a VB/(B*l).
            d = tc.D;  d.Fcarga = 0;
            r = IE.lineal(d);
            tc.verifyEqual(double(r.v), 240, 'RelTol', 1e-12);   % 120/0.5
            tc.verifyEqual(double(r.i), 0,   'AbsTol', 1e-12);
            tc.verifyEqual(double(r.eind), 120, 'RelTol', 1e-12);
        end

        function cargadoDaElPuntoDeChapman(tc)
            % Con 30 N de carga: i = F/(B*l) = 60 A, eind = 120-60*0.25 =
            % 105 V, v = 105/0.5 = 210 m/s. Valores analiticos a mano.
            d = tc.D;  d.Fcarga = 30;
            r = IE.lineal(d);
            tc.verifyEqual(double(r.i),    60,  'RelTol', 1e-12);
            tc.verifyEqual(double(r.eind), 105, 'RelTol', 1e-12);
            tc.verifyEqual(double(r.v),    210, 'RelTol', 1e-12);
        end

        function picoDeArranqueSinContraFem(tc)
            % Con la barra quieta eind = 0 y la corriente es VB/R. Es el
            % numero que justifica la resistencia de arranque.
            d = tc.D;  d.Fcarga = 0;
            r = IE.lineal(d);
            tc.verifyEqual(double(r.iarr), 480, 'RelTol', 1e-12);  % 120/0.25
        end

        function balanceDePotencia(tc)
            % Pbat = PR + Pmec. Lo que entrega la bateria se disipa en R o
            % se convierte en mecanica, sin tercer destino.
            d = tc.D;  d.Fcarga = 30;
            r = IE.lineal(d);
            tc.verifyEqual(double(r.Pbat), ...
                double(r.PR) + double(r.Pmec), 'RelTol', 1e-10);
        end

        function conversionSinPerdidas(tc)
            % eind*i = F*v: la conversion electromecanica no pierde nada,
            % toda la perdida esta en R. Si difieren, hay error de signo.
            for Fc = [-50 0 30 55]
                d = tc.D;  d.Fcarga = Fc;
                r = IE.lineal(d);
                tc.verifyEqual(double(r.Pconv), double(r.Pmec), ...
                    'RelTol', 1e-10, sprintf('Fcarga = %g', Fc));
            end
        end

        function invertirCampoInvierteLaMarcha(tc)
            % Cambiar el sentido de B invierte la velocidad de equilibrio
            % pero no su magnitud.
            d = tc.D;  d.Fcarga = 0;
            r1 = IE.lineal(d);
            d.B = -d.B;
            r2 = IE.lineal(d);
            tc.verifyEqual(double(r2.v), -double(r1.v), 'RelTol', 1e-12);
        end

        function invertirBateriaInvierteLaMarcha(tc)
            % Cambiar la polaridad de VB hace lo mismo que cambiar B.
            d = tc.D;  d.Fcarga = 0;
            r1 = IE.lineal(d);
            d.VB = -d.VB;
            r2 = IE.lineal(d);
            tc.verifyEqual(double(r2.v), -double(r1.v), 'RelTol', 1e-12);
        end

        function cargaQueEmpujaLoVuelveGenerador(tc)
            % Con la carga a favor del movimiento la barra pasa de vvacio,
            % eind supera a VB, la corriente se invierte y la bateria
            % RECIBE potencia: Pbat negativa.
            d = tc.D;  d.Fcarga = -30;
            r = IE.lineal(d);
            tc.verifyLessThan(double(r.i), 0);
            tc.verifyGreaterThan(double(r.eind), d.VB);
            tc.verifyLessThan(double(r.Pbat), 0);
        end

        function cargaQueDetieneLaBarra(tc)
            % Caso limite: la carga que consume todo VB en R deja v = 0.
            % Fcarga = B*l*VB/R = 0.5*480 = 240 N.
            d = tc.D;  d.Fcarga = 240;
            r = IE.lineal(d);
            tc.verifyEqual(double(r.v), 0, 'AbsTol', 1e-10);
            tc.verifyEqual(double(r.i), 480, 'RelTol', 1e-12);
        end

        function transitorioLlegaAlEstacionario(tc)
            % EL TEST QUE ATA LOS DOS CAMINOS. trayLineal integra con
            % ode45 desde el sistema sustituido; IE.lineal despeja el
            % mismo sistema con dvdt = 0. Integrando 12 constantes de
            % tiempo, los dos tienen que coincidir. Un error de signo o de
            % factor en cualquiera de los dos caminos rompe esto.
            d = tc.D;  d.Fcarga = 30;
            r = IE.lineal(d);
            d.tf = 12*d.m*d.R/(d.B*d.l)^2;
            [~, vv, ii] = IE.trayLineal(d);
            tc.verifyEqual(vv(end), double(r.v), 'RelTol', 1e-4);
            tc.verifyEqual(ii(end), double(r.i), 'RelTol', 1e-4);
        end

        function resistenciaDeArranqueBajaElPico(tc)
            % Con Rarr en serie el pico inicial es VB/(R+Rarr), muy por
            % debajo de VB/R. Es el unico efecto que se le pide.
            d = tc.D;  d.Fcarga = 0;  d.Rarr = 1.75;
            [~, ~, ii, ~, n] = IE.trayLineal(d);
            tc.verifyEqual(n.iarr, 60, 'RelTol', 1e-12);      % 120/2
            tc.verifyLessThan(max(abs(ii)), 61);
            tc.verifyEqual(n.Rini, 2, 'RelTol', 1e-12);
        end

        function faltaDatoAvisa(tc)
            % trayLineal necesita los cinco parametros del sistema.
            tc.verifyError(@() IE.trayLineal(struct('B',0.5,'l',1)), ...
                'IE:faltaDato');
        end


        %% ================================================================
        %  EJEMPLO 1-10 DE CHAPMAN, contra los valores impresos del libro
        %  VB = 120 V, R = 0.3 ohm, B = 0.1 T, l = 10 m  ->  B*l = 1
        %% ================================================================

        function chapman110_arranqueYVacio(tc)
            % a) i de arranque = 120/0.3 = 400 A; v de vacio = 120 m/s.
            d = tc.C;  d.Fcarga = 0;
            r = IE.lineal(d);
            tc.verifyEqual(double(r.iarr),   400, 'RelTol', 1e-12);
            tc.verifyEqual(double(r.vvacio), 120, 'RelTol', 1e-12);
            tc.verifyEqual(double(r.v),      120, 'RelTol', 1e-12);
        end

        function chapman110_generador(tc)
            % b) 30 N hacia la DERECHA, o sea a favor del movimiento: en
            % este modelo es Fcarga NEGATIVA. El libro da |i| = 30 A,
            % eind = 129 V, v = 129 m/s, la barra entrega 3870 W, la
            % bateria absorbe 3600 W y en R se pierden 270 W.
            d = tc.C;  d.Fcarga = -30;
            r = IE.lineal(d);
            tc.verifyEqual(abs(double(r.i)), 30,  'RelTol', 1e-12);
            tc.verifyEqual(double(r.eind),   129, 'RelTol', 1e-12);
            tc.verifyEqual(double(r.v),      129, 'RelTol', 1e-12);
            tc.verifyEqual(abs(double(r.Pmec)), 3870, 'RelTol', 1e-12);
            tc.verifyEqual(abs(double(r.Pbat)), 3600, 'RelTol', 1e-12);
            tc.verifyEqual(double(r.PR),        270,  'RelTol', 1e-12);
            % El signo es el que dice que es generador: la bateria recibe.
            tc.verifyLessThan(double(r.Pbat), 0);
        end

        function chapman110_motor(tc)
            % c) 30 N hacia la IZQUIERDA, opuesta al movimiento: Fcarga
            % positiva. El libro da i = 30 A, eind = 111 V, v = 111 m/s.
            d = tc.C;  d.Fcarga = 30;
            r = IE.lineal(d);
            tc.verifyEqual(double(r.i),    30,  'RelTol', 1e-12);
            tc.verifyEqual(double(r.eind), 111, 'RelTol', 1e-12);
            tc.verifyEqual(double(r.v),    111, 'RelTol', 1e-12);
            tc.verifyGreaterThan(double(r.Pbat), 0);   % la bateria entrega
        end

        function chapman110_barridoDeFuerza(tc)
            % d) v contra F para F = 0:10:50. Con B*l = 1 la recta es
            % v = 120 - 0.3*F, que se escribe a mano y no sale del codigo
            % que se esta probando.
            F = 0:10:50;
            esperado = 120 - 0.3*F;
            for k = 1:numel(F)
                d = tc.C;  d.Fcarga = F(k);
                r = IE.lineal(d);
                tc.verifyEqual(double(r.v), esperado(k), 'RelTol', 1e-12, ...
                    sprintf('F = %g N', F(k)));
            end
        end

        function chapman110_codigoDelLibroUsaOtrosDatos(tc)
            % d) OJO: el script del libro declara l = 1 y B = 0.6, que NO
            % son los datos del enunciado (l = 10, B = 0.1). Con B*l = 0.6
            % la recta es v = 200 - (5/6)*F, y esa es la que dibuja la
            % figura 1-28: arranca en 200 y termina en 158.33, no en 120 y
            % 105. Este test fija las dos lecturas para que la diferencia
            % quede documentada y no se descubra de nuevo.
            d = struct('VB',120, 'R',0.3, 'l',1, 'B',0.6, 'm',10);
            d.Fcarga = 0;
            tc.verifyEqual(double(IE.lineal(d).v), 200, 'RelTol', 1e-12);
            d.Fcarga = 50;
            tc.verifyEqual(double(IE.lineal(d).v), 158.3333333333333, ...
                'RelTol', 1e-10);
        end

        function chapman110_campoDebilitadoAcelera(tc)
            % e) En vacio, si B cae de 0.1 a 0.08 T la barra se ACELERA de
            % 120 a 150 m/s. Es el mismo efecto que en un motor CC real:
            % debilitar el campo lo hace girar mas rapido.
            d = tc.C;  d.Fcarga = 0;
            tc.verifyEqual(double(IE.lineal(d).v), 120, 'RelTol', 1e-12);
            d.B = 0.08;
            tc.verifyEqual(double(IE.lineal(d).v), 150, 'RelTol', 1e-12);
        end

    end
end
