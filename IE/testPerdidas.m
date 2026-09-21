classdef testPerdidas < matlab.unittest.TestCase
    % TESTPERDIDAS Balance de perdidas y rendimiento de IE.perdidas.
    % Caso de referencia: trafo de 15 kVA, 2400/240 V, con los dos ensayos.
    %   runtests('testPerdidas')

    properties (Constant)
        D = struct('Poc',80, 'Voc',240, 'Ioc',1.2, ...
                   'Psc',300, 'Vsc',120, 'Isc',6.25, ...
                   'Snom',15e3, 'V',2400, 'FP',0.85, 'x',1);
    end

    methods (Test)

        function balanceAPlenaCarga(tc)
            % Valores a mano: Pfe = Poc = 80 W, Pcu = Psc = 300 W a la
            % corriente nominal, Pout = 15000*0.85 = 12750 W.
            r = IE.perdidas(tc.D);
            tc.verifyEqual(r.Pfe,   80,    'RelTol', 1e-12);
            tc.verifyEqual(r.Pcu,   300,   'RelTol', 1e-12);
            tc.verifyEqual(r.Pperd, 380,   'RelTol', 1e-12);
            tc.verifyEqual(r.Pout,  12750, 'RelTol', 1e-12);
            tc.verifyEqual(r.etapct, 100*12750/13130, 'RelTol', 1e-10);
        end

        function ramaDeExcitacionDelEnsayoDeVacio(tc)
            % Rc = Voc^2/Poc = 240^2/80 = 720 ohm.
            r = IE.perdidas(tc.D);
            tc.verifyEqual(r.Rc, 720, 'RelTol', 1e-12);
        end

        function xoptCuentaLasAdicionales(tc)
            % REGRESION. xopt tiene que salir donde las perdidas VARIABLES
            % igualan a las FIJAS, y las fijas son Pfe + Padd, no solo Pfe.
            % Antes se calculaba con Pfe pelado y devolvia 0.516 cuando el
            % maximo real estaba en 0.632: un 18 por ciento de error en la
            % fraccion de carga. El barrido numerico de abajo es la
            % verificacion independiente, no la formula.
            d = tc.D;  d.Padd = 40;
            r = IE.perdidas(d);
            tc.verifyEqual(r.xopt, sqrt(120/300), 'RelTol', 1e-12);

            x = linspace(0.2, 1.2, 20001);
            Po = d.Snom*d.FP*x;
            eta = Po ./ (Po + 80 + 40 + 300*x.^2);
            [~, k] = max(eta);
            tc.verifyEqual(r.xopt, x(k), 'AbsTol', 2e-3);
        end

        function sinAdicionalesXoptNoCambia(tc)
            % Con Padd = 0 la formula vieja y la nueva coinciden: la
            % correccion no movio el caso comun.
            r = IE.perdidas(tc.D);
            tc.verifyEqual(r.xopt, sqrt(80/300), 'RelTol', 1e-12);
        end

        function enElOptimoLasFijasIgualanALasVariables(tc)
            % La propiedad que define el maximo, comprobada sobre el
            % resultado y no sobre la formula que lo produjo.
            d = tc.D;  d.Padd = 40;
            r = IE.perdidas(d);
            variables = r.PcuNom * r.xopt^2;
            fijas     = r.Pfe + r.Padd;
            tc.verifyEqual(variables, fijas, 'RelTol', 1e-10);
        end

        function separacionDelNucleoSumaAlTotal(tc)
            % Dando kh se obtiene Ph, y Pe sale por resta: Ph + Pe = Pfe.
            d = tc.D;
            d.kh = 0.49;  d.f = 60;  d.Bmax = 1.4;  d.nst = 1.6;
            r = IE.perdidas(d);
            tc.verifyEqual(r.Ph + r.Pe, r.Pfe, 'RelTol', 1e-10);
            tc.verifyGreaterThan(r.Ph, 0);
            tc.verifyGreaterThan(r.Pe, 0);
        end


        function panelesDeLaInterfazSeArman(tc)
            % REGRESION. El texto de los dos paneles se concatena en
            % VERTICAL, y tablaTexto devolvia un cell FILA: la
            % concatenacion reventaba con "Dimensions of arrays being
            % concatenated are not consistent" y la interfaz quedaba con
            % los dos paneles vacios. Ni el modo exportar ni el resto de
            % las suites tocaban ese armado, porque solo existia dentro de
            % refrescar. Por eso simPerdidas('texto') existe: para que
            % esta parte de la interfaz se pueda verificar sin pantalla.
            [cat, inf] = simPerdidas('texto');
            tc.verifyEqual(size(cat,2), 1, 'el catalogo tiene que ser columna');
            tc.verifyEqual(size(inf,2), 1, 'el panel info tiene que ser columna');
            tc.verifyGreaterThan(size(cat,1), 4);
            tc.verifyGreaterThan(size(inf,1), 4);
            tc.verifyTrue(all(cellfun(@ischar, cat)));
            tc.verifyTrue(all(cellfun(@ischar, inf)));
            % Y que no se cuele el marcado que mete disp() sobre una table
            tc.verifyFalse(any(contains(cat, '<strong>')));
        end

        function laSeparacionNoSePisaConLasFormulas(tc)
            % REGRESION. Dando kh Y ke a la vez, IE.perdidas calcula Ph y
            % Pe cada una por su formula y dejan de sumar Pfe: con las
            % constantes de ejemplo daba Pe = 6e-7 W y el desglose no
            % cerraba. Hay que dar UNA sola y dejar que la otra salga por
            % resta, que es lo que dice la doc de IE.perdidas.
            d = tc.D;
            d.kh = 0.49;  d.f = 60;  d.Bmax = 1.4;  d.nst = 1.6;
            r = IE.perdidas(d);
            tc.verifyEqual(r.Ph + r.Pe, r.Pfe, 'RelTol', 1e-10);
            tc.verifyGreaterThan(r.Pe, 1);   % no puede ser cero

            % Con las dos constantes, el desglose NO cierra: queda
            % documentado para que nadie lo use asi sin saberlo.
            d2 = d;  d2.ke = 3.5e-4;  d2.esp = 0.5e-3;
            r2 = IE.perdidas(d2);
            tc.verifyGreaterThan(abs(r2.Ph + r2.Pe - r2.Pfe), 1);
        end

    end
end
