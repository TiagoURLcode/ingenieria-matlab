classdef IE
    %{
    IE — Caja de herramientas de Instalaciones/Ingeniería Eléctrica.
         Todos los métodos son estáticos: se llaman IE.nombre(...).

    CONVENCIONES DE TODA LA CLASE
      - Ángulos en GRADOS en la interfaz (cosd/sind/deg2rad adentro).
      - Magnitudes de tensión/corriente en RMS salvo aviso explícito.
      - Secuencia de fases POSITIVA (ABC): B atrasa 120° a A, C atrasa 240°.
      - mu es SIEMPRE permeabilidad RELATIVA (adimensional); mu0 va aparte.
      - dA es un crecimiento PROPORCIONAL del área en el entrehierro:
        A_gap = A*(1 + dA). dA = 0.10 -> 10% más de área por fringing.
    %}

    methods(Static)

        %{
        pol2rec — Polar a rectangular. Vectorizada: x y teta pueden ser
        vectores de igual largo (o uno escalar y el otro vector).
          x    : módulo(s)
          teta : ángulo(s) en grados
        Ej: IE.pol2rec([8; 12], [-30; 45])
        %}
        function X = pol2rec(x, teta)
            X = x(:) .* exp(1j*deg2rad(teta(:)));
        end

        %{
        parZ — Equivalente de impedancias EN PARALELO.
          Z : vector [z1 z2 ... zn]
        %}
        function Zp = parZ(Z)
            Zp = 1/sum(1./Z(:));
        end

        %{
        f2l — FASE a LÍNEA  (E_L = sqrt(3)*E_F)
        l2f — LÍNEA a FASE  (E_F = E_L/sqrt(3))

        Solo módulos: la línea además adelanta 30° a la fase en secuencia
        positiva (ver IE.fasores). Válido en sistemas equilibrados, sin
        impedancias colgando fuera del triángulo.
        %}
        function E_L = f2l(E_F)
            E_L = E_F*sqrt(3);
        end

        function E_F = l2f(E_L)
            E_F = E_L/sqrt(3);
        end

        %{
        d2e — DELTA a ESTRELLA   (transformación de Kennelly)
        e2d — ESTRELLA a DELTA

        OJO: esto es para IMPEDANCIAS, no para tensiones. Para tensiones
        el par es IE.f2l / IE.l2f. Confundirlos es el error clásico:
        el sqrt(3) es de tensiones, el 3 es de impedancias.

        CASO EQUILIBRADO (entrada ESCALAR, salida ESCALAR):
            Z_Y = Z_D/3        Z_D = 3*Z_Y
        Una carga en triángulo consume 3 veces la potencia que la MISMA
        impedancia en estrella: por eso Z_Y = Z_D/3.

        CASO GENERAL (entrada VECTOR de 3, salida VECTOR de 3):
          Orden fijo -> D: [Zab; Zbc; Zca]   Y: [Za; Zb; Zc]
          (Za es el brazo que cuelga del nodo A hacia el neutro.)

            D->Y :  Za = Zab*Zca / (Zab+Zbc+Zca)
                    Zb = Zab*Zbc / (Zab+Zbc+Zca)
                    Zc = Zbc*Zca / (Zab+Zbc+Zca)
                    -> cada brazo Y = producto de las DOS ramas D que
                       tocan ese nodo, sobre la suma de las tres.

            Y->D :  P = Za*Zb + Zb*Zc + Zc*Za
                    Zab = P/Zc,  Zbc = P/Za,  Zca = P/Zb
                    -> cada rama D = P sobre el brazo Y OPUESTO.

        Acepta complejos. Ej: IE.d2e(IE.pol2rec([30;30;30],[60;60;60]))
        %}
        function Zy = d2e(Zd)
            Zd = Zd(:);
            switch numel(Zd)
                case 1                       % equilibrado
                    Zy = Zd/3;
                case 3
                    st = sum(Zd);
                    if st == 0
                        error('IE:deltaDegenerado', ...
                            'Zab+Zbc+Zca = 0: el triángulo no tiene equivalente Y.');
                    end
                    Zab = Zd(1); Zbc = Zd(2); Zca = Zd(3);
                    Zy = [Zab*Zca; Zab*Zbc; Zbc*Zca] / st;
                otherwise
                    error('IE:d2eTamano', ...
                        ['d2e espera 1 impedancia (equilibrado) o 3 ' ...
                        '[Zab; Zbc; Zca], recibió %d.'], numel(Zd));
            end
        end

        function Zd = e2d(Zy)
            Zy = Zy(:);
            switch numel(Zy)
                case 1                       % equilibrado
                    Zd = 3*Zy;
                case 3
                    if any(Zy == 0)
                        error('IE:estrellaDegenerada', ...
                            ['Un brazo de la estrella es 0: la delta ' ...
                            'equivalente tiene ramas infinitas.']);
                    end
                    Za = Zy(1); Zb = Zy(2); Zc = Zy(3);
                    P  = Za*Zb + Zb*Zc + Zc*Za;
                    Zd = [P/Zc; P/Za; P/Zb];
                otherwise
                    error('IE:e2dTamano', ...
                        ['e2d espera 1 impedancia (equilibrado) o 3 ' ...
                        '[Za; Zb; Zc], recibió %d.'], numel(Zy));
            end
        end

        %{
        fasores — Tabla completa de un sistema trifásico equilibrado.

        Entradas:
          E_AN : magnitud RMS de la fase A (ESCALAR)
          ang0 : ángulo de E_AN en grados (opcional, 0 por defecto)

        Salida: matriz 6x4 -> [RMS  ang(°)  Pico  Pico-pico]
                filas: AN, BN, CN, AB, BC, CA

        Secuencia POSITIVA (ABC): BN atrasa 120°, CN atrasa 240°.
        Comprobación: E_AB = E_AN - E_BN = sqrt(3)*E_AN /_(ang0 + 30°).
        %}
        function M = fasores(E_AN, ang0)
            if nargin < 2, ang0 = 0; end
            if ~isscalar(E_AN)
                error('IE:fasoresEscalar', 'E_AN debe ser escalar.');
            end

            desfase = [0; -120; -240];      % secuencia positiva ABC

            magF = E_AN * [1; 1; 1];
            angF = ang0 + desfase;

            % líneas: sqrt(3) mayores y +30° respecto de SU fase homóloga
            magL = E_AN*sqrt(3) * [1; 1; 1];
            angL = ang0 + 30 + desfase;

            mag = [magF; magL];
            ang = mod([angF; angL], 360);        % deja todo en [0, 360)

            M = [mag, ang, mag*sqrt(2), 2*mag*sqrt(2)];
        end

        %{
        divV — Divisor de tensión.
          V : tensión total aplicada a la SERIE
          Z : vector de impedancias EN SERIE [z1; z2; ...; zn]
        Salida: tensión sobre cada impedancia.
        Ej: Z = [10+5j; IE.pol2rec([8; 12], [-30; 45])];
        %}
        function Vz = divV(V, Z)
            Vz = V * Z(:) / sum(Z(:));
        end

        %{
        divI — Divisor de corriente.
          I : corriente total que entra al nodo
          Z : vector de impedancias EN PARALELO [z1; z2; ...; zn]
        Salida: corriente por cada rama.
        %}
        function Iz = divI(I, Z)
            Y  = 1./Z(:);
            Iz = I * Y / sum(Y);
        end

        %{
        potencias — Triángulo de potencias a partir de fasores RMS.
          V, I : fasores complejos (escalares o vectores del mismo tamaño)

        Salida struct:
          S, P [W], Q [VAR], magS [VA], theta [°], FP, tipo
          Stot : suma compleja (útil si V,I son vectores de varias cargas)
        'tipo' se evalúa ELEMENTO A ELEMENTO -> string array.
        %}
        function T = potencias(V, I)
            S = V .* conj(I);            % potencia compleja

            T.S     = S;
            T.P     = real(S);           % activa   [W]
            T.Q     = imag(S);           % reactiva [VAR]
            T.magS  = abs(S);            % aparente [VA]
            T.theta = rad2deg(angle(S)); % ángulo del triángulo
            T.FP    = cos(angle(S));
            T.Stot  = sum(S(:));

            % Q > 0 -> inductiva -> la corriente ATRASA a la tensión.
            T.tipo = repmat("unitario", size(S));
            T.tipo(T.Q >  1e-9) = "atrasado";      % inductiva
            T.tipo(T.Q < -1e-9) = "adelantado";    % capacitiva
        end

        %{
        ecB — Declara el modelo del circuito magnético.
        No resuelve nada; solo entrega el sistema y el diccionario de
        símbolos para que otras funciones lo usen.

        Nomenclatura común:
          B    densidad de flujo magnético           [T] = [Wb/m^2]
          H    intensidad de campo                   [A/m]
          mu   permeabilidad RELATIVA del medio      [adimensional]
          mu0  permeabilidad del vacío = 4*pi*1e-7   [H/m]
          len  longitud media del camino magnético   [m]  (2*pi*R en toroide)
          N    número de vueltas                     [-]
          I    corriente                             [A]
          Fi   flujo magnético                       [Wb]
          dFi  derivada del flujo, dFi/dt            [Wb/s]
          A    área transversal                      [m^2]
          v    tensión inducida                      [V]
          R    reluctancia                           [A-vuelta/Wb]

        Salidas:
          eqs : vector simbólico con las 4 leyes, sin resolver.
          S   : struct-diccionario. S.N es el SÍMBOLO N (no un valor).
                Es indispensable devolverlo: cada llamada a syms crea
                objetos nuevos, así que una N declarada afuera NO es la
                misma N que está dentro de eqs. Usando S siempre pegan.

        POR QUÉ dFi Y NO diff(Fi,t):
          solve() es un solucionador ALGEBRAICO. Si Faraday se escribe
          como v == N*diff(Fi(t),t), solve no sabe derivar la relación
          Fi = B*A y devuelve VACÍO sin avisar (verificado en R2026a).
          Acá dFi = dFi/dt es un símbolo más, el sistema queda 100%
          algebraico y siempre resuelve. Para el análisis temporal real
          está IE.faradayB, que sí deriva.

        EJEMPLO DE USO
          [eqs, S] = IE.ecB();
          eqs = subs(eqs, [S.N S.A S.len S.mu], [200 1e-3 0.3 5000]);
          eqs = subs(eqs, S.I, 2);
          double(solve(eqs, S.Fi))
        %}
        function [eqs, S] = ecB()
            nom = {'B','H','mu','len','N','I','Fi','dFi','A','v','t'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            B = S.B; H = S.H; mu = S.mu; len = S.len; N = S.N;
            I = S.I; Fi = S.Fi; dFi = S.dFi; A = S.A; v = S.v;

            mu0 = 4*pi*1e-7;        % permeabilidad del vacío [H/m]

            eqs = [ H  == N*I/len            % Ley de Ampère
                B  == mu*mu0*H           % Relación B-H del material
                B  == Fi/A               % Definición de densidad de flujo
                v  == N*dFi ];           % Ley de Faraday
        end

        %{
        despejar — MOTOR de despeje. Lo usan datosB y datosSeg.

        Entradas:
          eqs : sistema simbólico (de IE.ecB, IE.ecSeg, ...)
          S   : diccionario de símbolos del MISMO sistema
          d   : struct con SOLO lo que conocés, en cualquier orden

        Salida:
          res : struct con TODAS las variables que quedaron determinadas.
                Para número: double(res.Fi) o vpa(res.Fi, 6).

        NO SE PIDE UNA INCÓGNITA, A PROPÓSITO.
          La sustitución hacia adelante determina TODO lo que los datos
          permitan, en la misma pasada. Pedir una variable no ahorraba
          trabajo: solo elegía cuál de las ya calculadas devolver y
          escondía el resto. Elegís vos, del struct.
          Si un campo NO está en res, es que los datos no alcanzaron para
          determinarlo. Ese es el diagnóstico: mirá qué falta.

        POR QUÉ NO ES UN solve() PELADO:
          solve(eqs, x) exige que TODAS las ecuaciones se satisfagan
          eligiendo únicamente x. Como el sistema tiene varias incógnitas
          intermedias (H, B, Rn, ...), cualquier ecuación que no contenga
          x lo vuelve insatisfacible y solve devuelve VACÍO aunque los
          datos alcancen de sobra. Verificado en R2026a.
          Acá se hace SUSTITUCIÓN HACIA ADELANTE, que es exactamente el
          método a mano: se busca una ecuación con una sola incógnita, se
          despeja, se propaga el valor, y se repite hasta que no queda nada
          por despejar.
        %}
        function res = despejar(eqs, S, d)
            campos = fieldnames(d);

            for k = 1:numel(campos)
                if ~isfield(S, campos{k})
                    error('IE:campoDesconocido', ...
                        ['"%s" no es una variable del modelo. ' ...
                        'Válidas: %s'], campos{k}, strjoin(fieldnames(S)', ', '));
                end
                eqs = subs(eqs, S.(campos{k}), d.(campos{k}));
            end

            res    = struct();
            cambio = true;
            while cambio
                cambio = false;
                for k = 1:numel(eqs)
                    libres = symvar(eqs(k));

                    if isempty(libres)
                        if ~isAlways(eqs(k), 'Unknown', 'false')
                            error('IE:datosContradictorios', ...
                                ['Los datos violan la ecuación %d del ' ...
                                'modelo: %s'], k, char(eqs(k)));
                        end
                        continue
                    end
                    if numel(libres) ~= 1, continue; end

                    s = solve(eqs(k), libres);
                    if isempty(s), continue; end
                    if numel(s) > 1
                        warning('IE:variasSoluciones', ...
                            '%s tiene %d soluciones; se toma la primera.', ...
                            char(libres), numel(s));
                    end
                    res.(char(libres)) = s(1);
                    eqs    = subs(eqs, libres, s(1));   % propaga a todas
                    cambio = true;
                end
            end
        end

        %{
        datosB — Atajo sobre el modelo del circuito magnético.
          d   : struct con lo conocido. Ej:
                struct('mu',5000,'len',0.3,'N',200,'I',2,'A',1e-3)
        Devuelve un struct con TODO lo que los datos permitan despejar.
        Ej: double(IE.datosB(d).Fi)
        %}
        function res = datosB(d)
            [eqs, S] = IE.ecB();
            res = IE.despejar(eqs, S, d);
        end

        %{
        datosSeg — Atajo sobre el modelo de UN tramo con entrehierro.
          d   : struct con len, A, mu, g, dA, Fi... lo que tengas
        Devuelve un struct con TODO lo que los datos permitan despejar.
        Ej: double(IE.datosSeg(struct('len',.3,'A',1e-3,'mu',5e3, ...
                                      'g',1e-3,'dA',.1)).Rs)
        %}
        function res = datosSeg(d)
            [eqs, S] = IE.ecSeg();
            res = IE.despejar(eqs, S, d);
        end

        %{
        faradayB — Análisis TEMPORAL. Esto es lo que ecB no puede
        hacer: derivar de verdad.

        Entradas:
          d   : struct con N, A, len, mu (permeabilidad RELATIVA)
          I_t : corriente como EXPRESIÓN simbólica en t.
                Ej: syms t; I_t = 2*sin(377*t);
          t   : (opcional) la variable de tiempo usada en I_t.
                Por defecto sym('t'). PASALA si tu t viene de otro lado.

        Salidas:
          v_t  : tensión inducida v(t) = N*dFi/dt   [V]
          Fi_t : flujo Fi(t) = mu*mu0*N*A*I(t)/len  [Wb]
          L    : inductancia N^2/R = mu*mu0*N^2*A/len [H]

        Ej: [v, Fi, L] = IE.faradayB(struct('N',200,'A',1e-3, ...
                           'len',0.3,'mu',5000), 2*sin(377*t));
            vpa(v, 6)
        %}
        function [v_t, Fi_t, L] = faradayB(d, I_t, t)
            if nargin < 3, t = sym('t'); end
            mu0 = 4*pi*1e-7;

            L    = d.mu*mu0*d.N^2*d.A/d.len;     % inductancia [H]
            Fi_t = d.mu*mu0*d.N*d.A*I_t/d.len;   % flujo [Wb]
            v_t  = d.N*diff(Fi_t, t);            % Faraday: v = N dFi/dt
        end

        %{
        ecTrafo — Modelo simbólico del TRANSFORMADOR IDEAL.
        Mismo esquema que IE.ecB: declara el sistema y devuelve
        el diccionario. No resuelve nada. Se despeja con IE.despejar
        (o el atajo IE.datosTrafo / IE.trafo).

        DE DÓNDE SALE: es Faraday aplicado al MISMO núcleo. Las dos
        bobinas ven el mismo dFi/dt, así que
            Vp = Np*dFi      Vs = Ns*dFi      ->   Vp/Vs = Np/Ns = a
        y la FMM neta del núcleo ideal es cero (R -> 0):
            Np*Ip = Ns*Is    ->   Is/Ip = Np/Ns = a

        CONSTANTES:
            a = Np/Ns   -> "vista desde el PRIMARIO". Multiplica lo del
                           secundario para referirlo al primario.
            b = Ns/Np   -> "vista desde el SECUNDARIO". Es 1/a.
            a > 1 : reductor (baja tensión, sube corriente).
            a < 1 : elevador.

        VARIABLES DEL DICCIONARIO S:
          a    Np/Ns, relación de transformación          [-]
          b    Ns/Np = 1/a                                [-]
          Np   vueltas del primario                       [-]
          Ns   vueltas del secundario                     [-]
          Vp   tensión en el primario                     [V]
          Vs   tensión en el secundario                   [V]
          Ip   corriente del primario                     [A]
          Is   corriente del secundario                   [A]
          Zp   impedancia VISTA desde el primario         [ohm]
          Zs   impedancia conectada al secundario (carga) [ohm]
          dFi  dFi/dt común a las dos bobinas             [Wb/s]

        RESUMEN DE REFERIR:
            Vp = a*Vs      Ip = Is/a      Zp = a^2*Zs
            Vs = b*Vp      Is = Ip/b      Zs = b^2*Zp
        La tensión y la corriente van con a; la impedancia con a AL CUADRADO.

        IDEAL significa: sin dispersión, sin resistencia de bobinado, sin
        pérdidas en el hierro y con corriente de magnetización nula (mu -> inf).

        EJEMPLO:
          [eqs, S] = IE.ecTrafo();
          eqs = subs(eqs, [S.Np S.Ns S.Vp], [500 100 220]);
          double(IE.despejar(eqs, S, struct(), 'Vs'))
        %}
        function [eqs, S] = ecTrafo()
            nom = {'a','b','Np','Ns','Vp','Vs','Ip','Is','Zp','Zs','dFi'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            a = S.a; b = S.b; Np = S.Np; Ns = S.Ns;
            Vp = S.Vp; Vs = S.Vs; Ip = S.Ip; Is = S.Is;
            Zp = S.Zp; Zs = S.Zs; dFi = S.dFi;

            eqs = [ a  == Np/Ns        % constante primaria
                b  == 1/a          % constante secundaria (= Ns/Np)
                Vp == Np*dFi       % Faraday en el primario
                Vs == Ns*dFi       % Faraday en el secundario, MISMO dFi
                Vp == a*Vs         % consecuencia de las dos anteriores
                Is == a*Ip         % FMM neta nula: Np*Ip = Ns*Is
                Zs == Vs/Is        % carga real, en bornes del secundario
                Zp == Vp/Ip        % lo que "ve" la fuente del primario
                Zp == a^2*Zs ];    % la de referir: a al CUADRADO
        end

        %{
        datosTrafo — Atajo sobre el modelo del transformador ideal.
          d   : struct con lo conocido, en cualquier orden. Ej:
                struct('a',5,'Vp',220,'Zs',10)
        Devuelve un struct con TODO lo que los datos permitan despejar.
        Ej: double(IE.datosTrafo(struct('Np',500,'Ns',100,'Vp',220)).Vs)
        %}
        function res = datosTrafo(d)
            [eqs, S] = IE.ecTrafo();
            res = IE.despejar(eqs, S, d);
        end

        %{
        trafo — Resuelve TODO lo que se pueda del transformador ideal y lo
        devuelve numérico, sin tener que pedir variable por variable.

          d : struct con lo conocido. Ej:
              IE.trafo(struct('a',10,'Vp',2200,'Zs',5))

        Salida r (struct) con los campos que quedaron determinados, en
        orden fijo: a, b, Np, Ns, Vp, Vs, Ip, Is, Zp, Zs, dFi.

        Acepta complejos.
        %}
        function r = trafo(d)
            [eqs, S] = IE.ecTrafo();
            res = IE.despejar(eqs, S, d);

            orden = {'a','b','Np','Ns','Vp','Vs','Ip','Is','Zp','Zs','dFi'};
            r = struct();
            for k = 1:numel(orden)
                nk = orden{k};
                if isfield(d, nk)
                    r.(nk) = d.(nk);
                elseif isfield(res, nk)
                    v = res.(nk);
                    try, v = double(v); catch, end %#ok<NOCOM>
                    r.(nk) = v;
                end
            end
        end

        %{
        ecPerdidas — Modelo simbólico de las PÉRDIDAS y el RENDIMIENTO de un
        transformador real. Se usa con IE.despejar (o con IE.datosPerdidas,
        que es el atajo), igual que ecB y ecTrafo.

        ================================================================
         QUÉ REPRESENTA CADA PÉRDIDA
        ================================================================

        PÉRDIDAS EN EL COBRE — Pcu = I^2 * Req            [W]
          Efecto Joule en la resistencia de los DOS devanados, primario y
          secundario, ya referidos a un mismo lado (por eso una sola Req).
          Es energía que se va en calentar el alambre. La corriente es la
          de CARGA: si no hay carga, no hay cobre.

        PÉRDIDAS EN EL NÚCLEO O EN EL HIERRO — Pfe = Ph + Pe   [W]
          De origen magnético, ocurren dentro del material, y existen desde
          que se energiza el transformador aunque el secundario esté
          abierto. Son dos fenómenos distintos:

          HISTÉRESIS — Ph = kh * f * Bmax^n     (n = 1.6 a 2, Steinmetz)
            Energía que hay que gastar en cada ciclo para dar vuelta los
            dominios magnéticos del hierro. Es, literalmente, el ÁREA que
            encierra el lazo B-H, multiplicada por los f ciclos por
            segundo. Se combate con materiales de lazo angosto: acero al
            silicio de grano orientado.

          CORRIENTES PARÁSITAS (Foucault, eddy) — Pe = ke*f^2*Bmax^2*esp^2
            El flujo variable induce fem DENTRO del propio hierro, que
            también es conductor. Esas corrientes circulan en cortocircuito
            adentro del núcleo y lo calientan. Van con el CUADRADO del
            espesor de la chapa: por eso el núcleo se LAMINA en chapas
            finas aisladas entre sí en vez de ser macizo.

        PÉRDIDAS ADICIONALES O DISPERSAS (stray)
          El flujo de dispersión induce corrientes en el tanque, los pernos
          y las sujeciones. NO se calculan aparte en este modelo: el ensayo
          de cortocircuito ya las mide junto con el cobre, así que quedan
          adentro de Pcu. (Si te las dan sueltas, IE.perdidas las acepta
          como campo Padd.)

        MECÁNICAS: no hay. El transformador no tiene partes móviles, así
          que no hay rozamiento ni ventilación. Esas aparecen recién en las
          máquinas rotativas.

        ================================================================
         CÓMO SE CATALOGAN
        ================================================================

        1) POR SU DEPENDENCIA DE LA CARGA  <- la clasificación que importa
             VARIABLES : Pcu. Van con el CUADRADO de la corriente, o sea
                         con el cuadrado de la fracción de carga:
                         Pcu(x) = x^2 * PcuNom.  En vacío valen CERO.
             FIJAS o CONSTANTES : Pfe. Dependen de la TENSIÓN aplicada y de
                         la FRECUENCIA, no de la carga. Están siempre, aun
                         con el secundario abierto, y no cambian cuando la
                         carga sube. También se las llama "de vacío".

        2) POR DÓNDE SE PRODUCEN
             en el COBRE (los devanados)  /  en el HIERRO (el núcleo)  /
             adicionales (dispersión)

        3) POR EL ENSAYO QUE LAS MIDE
             Ensayo de VACÍO (circuito abierto, se hace por el lado de
               BAJA): la corriente es la de excitación, 2-5% de la nominal,
               así que el I^2*Req es despreciable. El vatímetro lee Pfe.
             Ensayo de CORTOCIRCUITO (por el lado de ALTA): se aplica una
               tensión chica, 3-10% de la nominal, hasta llegar a la
               corriente nominal. Como el flujo va con la tensión, Pfe es
               despreciable. El vatímetro lee Pcu.
             Los dos ensayos separan limpio las dos familias porque cada
             uno anula a la otra. Ese es todo el truco.

        RENDIMIENTO
          eta = Pout / Pin = Pout / (Pout + Pfe + Pcu)
          Es MÁXIMO cuando las pérdidas variables igualan a las fijas,
          Pcu = Pfe. Como Pcu = x^2*PcuNom, eso pasa en la fracción de
          carga  xopt = sqrt(Pfe/PcuNom)  (la calcula IE.perdidas). Un
          trafo de distribución, que pasa muchas horas con poca carga, se
          diseña a propósito con xopt < 1.

        ================================================================
         VARIABLES DEL MODELO
        ================================================================
          Pcu    pérdidas en el cobre                      [W]
          Ph     pérdidas por histéresis                   [W]
          Pe     pérdidas por corrientes parásitas         [W]
          Pfe    pérdidas en el núcleo, Ph + Pe            [W]
          Pperd  pérdidas totales, Pfe + Pcu               [W]
          Pin    potencia de entrada                       [W]
          Pout   potencia útil entregada a la carga        [W]
          S      potencia aparente de la carga             [VA]
          FP     factor de potencia de la carga            [-]
          eta    rendimiento, 0 a 1 (no en %)              [-]
          I      corriente de carga                        [A]
          Inom   corriente nominal                         [A]
          x      fracción de carga, I/Inom                 [-]
          PcuNom pérdidas en el cobre a plena carga        [W]
          Req    resistencia equivalente serie             [ohm]
          V      tensión en bornes de la carga             [V]
          V1     tensión aplicada al primario              [V]
          Rc     resistencia que modela el núcleo          [ohm]
          f      frecuencia                                [Hz]
          Bmax   densidad de flujo máxima                  [T]
          kh, ke constantes del material                   [-]
          nst    exponente de Steinmetz, 1.6 a 2           [-]
          esp    espesor de la laminación                  [m]

        EJEMPLO
          d = struct('Pfe',350, 'Req',0.05, 'I',100, 'S',50e3, 'FP',0.8);
          r = IE.datosPerdidas(d);
          double(r.eta)      % 0.9821
        %}
        function [eqs, S] = ecPerdidas()
            nom = {'Pcu','Ph','Pe','Pfe','Pperd','Pin','Pout','S','FP', ...
                'eta','I','Inom','x','PcuNom','Req','V','V1','Rc', ...
                'f','Bmax','kh','ke','nst','esp'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);

            eqs = [ S.Pcu   == S.I^2 * S.Req              % Joule en los devanados
                S.Ph    == S.kh * S.f * S.Bmax^S.nst      % Steinmetz: histéresis
                S.Pe    == S.ke * (S.f*S.Bmax*S.esp)^2    % Foucault: va con esp^2
                S.Pfe   == S.Ph + S.Pe                    % el núcleo son las dos
                S.Pfe   == S.V1^2 / S.Rc                  % rama de excitación
                S.Pperd == S.Pfe + S.Pcu                  % fijas + variables
                S.S     == S.V * S.I                      % aparente de la carga
                S.Pout  == S.S * S.FP                     % útil = aparente * FP
                S.Pin   == S.Pout + S.Pperd               % balance de potencia
                S.eta   == S.Pout / S.Pin                 % rendimiento
                S.I     == S.x * S.Inom                   % fracción de carga
                S.Pcu   == S.x^2 * S.PcuNom ];            % el cobre va con x^2
        end

        %{
        datosPerdidas — Atajo sobre el modelo de pérdidas.
          d : struct con lo conocido, en cualquier orden.
        Devuelve un struct con TODO lo que los datos permitan despejar.
        Funciona en cualquier dirección: si le das el rendimiento y la
        salida, te saca las pérdidas.

        Ej: double(IE.datosPerdidas(struct('Pout',40e3,'eta',0.98)).Pperd)
        %}
        function res = datosPerdidas(d)
            [eqs, S] = IE.ecPerdidas();
            res = IE.despejar(eqs, S, d);
        end

        %{
        perdidas — Balance de pérdidas y rendimiento a partir de los DOS
        ENSAYOS, que es como viene el dato en el parcial. Numérico, no
        simbólico. La teoría de qué es cada pérdida está en IE.ecPerdidas.

          r = IE.perdidas(d)

        ENTRADAS (struct d, todos los campos opcionales: se usa lo que haya)

          Ensayo de VACÍO — mide las pérdidas FIJAS
            Poc  potencia leída [W]      -> es directamente Pfe
            Voc  tensión aplicada [V]    -> con Poc da Rc
            Ioc  corriente de excitación [A] -> da FP0, Im, Xm

          Ensayo de CORTOCIRCUITO — mide las pérdidas VARIABLES
            Psc  potencia leída [W]      -> con Isc da Req
            Vsc  tensión aplicada [V]    -> con Isc da Zeq y Xeq
            Isc  corriente [A]           -> si es la nominal, Psc = PcuNom

          Datos directos, por si no hay ensayos
            Pfe, Pcu, PcuNom, Req, Xeq   [W, W, W, ohm, ohm]
            Padd  pérdidas adicionales   [W]   (default 0)

          Punto de carga que se quiere analizar
            x     fracción de carga (0.75 = al 75%)   (default 1)
            I     corriente de carga [A]
            Inom  corriente nominal  [A]
            S     potencia aparente de la carga [VA]
            Snom  potencia aparente nominal (la de placa) [VA]
            V     tensión en bornes de la carga [V]
            FP    factor de potencia de la carga (default 1)
            tipoFP 'atrasado' (default) o 'adelantado'

          Separación del núcleo (opcional, para partir Pfe en dos)
            kh, ke, f, Bmax, esp, nst    (nst default 1.6)
            Alcanza con dar Ph o Pe para que salga la otra por resta.

        SALIDA (struct r, con los campos que los datos permitan)
            r.Pfe r.Ph r.Pe    núcleo: total, histéresis, Foucault  [W]
            r.Pcu r.PcuNom     cobre: en el punto y a plena carga   [W]
            r.Padd r.Pperd     adicionales y TOTAL de pérdidas      [W]
            r.Pout r.Pin       potencia útil y de entrada           [W]
            r.eta r.etapct     rendimiento en tanto por uno y en %
            r.x                fracción de carga analizada          [-]
            r.xopt r.etamax    carga de rendimiento MÁXIMO y su eta
            r.Req r.Xeq r.Zeq  impedancia serie equivalente       [ohm]
            r.Rc r.Xm r.Im     rama de excitación             [ohm, A]
            r.Vp_a r.RV        Vp/a del diagrama fasorial y la
                               regulación de tensión en %
            r.tabla            TABLA con cada pérdida: cuántos W, qué
                               porcentaje del total, si es fija o
                               variable, de qué depende y qué ensayo la
                               mide. Es el resumen para copiar al examen:
                               >> disp(r.tabla)

        OJO CON EL LADO AL QUE ESTÁ REFERIDO CADA VALOR
          Las POTENCIAS no tienen lado: 80 W de núcleo son 80 W se midan
          donde se midan. Las IMPEDANCIAS sí: como el ensayo de vacío se
          hace por BAJA y el de cortocircuito por ALTA, r.Rc y r.Xm quedan
          referidas al lado de BAJA y r.Req, r.Xeq al de ALTA. Para pasarlas
          al otro lado hay que multiplicar o dividir por a^2 (ver IE.trafo).
          Los campos V, I, Inom, S que le pases tienen que ser todos del
          MISMO lado que Req y Xeq, porque con esos se calculan Pcu y la
          regulación.

        REGULACIÓN: se calcula con Vs como referencia a 0 grados, o sea
          Vp/a = Vs + (Req + j*Xeq)*Is,   RV = (|Vp/a| - Vs)/Vs * 100
          El signo del ángulo de Is lo pone tipoFP: atrasado -> negativo.

        EJEMPLO (ensayos de un trafo de 15 kVA, 2400/240 V)
          d = struct('Poc',80, 'Voc',240, 'Ioc',1.2, ...
                     'Psc',300, 'Vsc',120, 'Isc',6.25, ...
                     'Snom',15e3, 'V',2400, 'FP',0.85, 'x',1);
          r = IE.perdidas(d);
          r.etapct        % rendimiento a plena carga
          r.xopt          % a qué fracción de carga rinde más
          disp(r.tabla)   % el catálogo de pérdidas
        %}
        function r = perdidas(d)
            if nargin < 1, d = struct(); end
            def = struct('nst',1.6, 'FP',1, 'tipoFP','atrasado', 'Padd',0, 'x',1);
            nd  = fieldnames(def);
            for k = 1:numel(nd)
                if ~isfield(d, nd{k}), d.(nd{k}) = def.(nd{k}); end
            end
            hay = @(k) isfield(d,k) && ~isempty(d.(k));
            r   = struct();

            %% ENSAYO DE VACÍO -> pérdidas FIJAS y rama de excitación.
            %  La corriente de excitación es 2-5% de la nominal, así que el
            %  I^2*Req del cobre es despreciable: lo que lee el vatímetro
            %  es el núcleo.
            if hay('Poc'), r.Pfe = d.Poc; end
            if hay('Poc') && hay('Voc')
                r.Rc = d.Voc^2 / d.Poc;
                if hay('Ioc')
                    r.FP0 = d.Poc / (d.Voc*d.Ioc);
                    r.Ife = d.Poc / d.Voc;                        % en fase con V
                    r.Im  = sqrt(max(d.Ioc^2 - r.Ife^2, 0));      % magnetizante
                    if r.Im > 0, r.Xm = d.Voc / r.Im; end
                end
            end

            %% ENSAYO DE CORTOCIRCUITO -> pérdidas VARIABLES e impedancia serie.
            %  La tensión aplicada es 3-10% de la nominal, y el flujo va con
            %  la tensión: el núcleo casi no trabaja y el vatímetro lee cobre.
            if hay('Psc') && hay('Isc')
                r.Req    = d.Psc / d.Isc^2;
                r.PcuNom = d.Psc;              % vale si el ensayo llegó a Inom
                if hay('Vsc')
                    r.Zeq = d.Vsc / d.Isc;
                    r.Xeq = sqrt(max(r.Zeq^2 - r.Req^2, 0));
                end
                if ~hay('Inom'), d.Inom = d.Isc; end
            end
            if hay('Pfe'), r.Pfe = d.Pfe; end          % el dato directo manda
            if hay('Req'), r.Req = d.Req; end
            if hay('Xeq'), r.Xeq = d.Xeq; end
            if isfield(r,'Req') && isfield(r,'Xeq')
                r.Zeq = hypot(r.Req, r.Xeq);
            end

            %% PUNTO DE CARGA
            r.x = d.x;
            if hay('I') && hay('Inom'),  r.x = d.I/d.Inom;   end
            if hay('S') && hay('Snom'),  r.x = d.S/d.Snom;   end
            if hay('I'),                       r.I = d.I;
            elseif hay('Inom'),                r.I = r.x*d.Inom;
            elseif hay('S') && hay('V'),       r.I = d.S/d.V;
            elseif hay('Snom') && hay('V'),    r.I = r.x*d.Snom/d.V;
            end

            %% COBRE: I^2*Req, o el escalado x^2 desde el valor nominal
            if hay('PcuNom'), r.PcuNom = d.PcuNom; end
            if ~isfield(r,'PcuNom') && isfield(r,'Req') && hay('Inom')
                r.PcuNom = d.Inom^2 * r.Req;
            end
            if hay('Pcu'),                                r.Pcu = d.Pcu;
            elseif isfield(r,'Req') && isfield(r,'I'),    r.Pcu = r.I^2 * r.Req;
            elseif isfield(r,'PcuNom'),                   r.Pcu = r.x^2 * r.PcuNom;
            end

            %% NÚCLEO: separación histéresis / Foucault, si hay constantes
            if hay('kh') && hay('f') && hay('Bmax')
                r.Ph = d.kh * d.f * d.Bmax^d.nst;
            end
            if hay('ke') && hay('f') && hay('Bmax') && hay('esp')
                r.Pe = d.ke * (d.f*d.Bmax*d.esp)^2;
            end
            if hay('Ph'), r.Ph = d.Ph; end
            if hay('Pe'), r.Pe = d.Pe; end
            if  isfield(r,'Ph') &&  isfield(r,'Pe') && ~isfield(r,'Pfe')
                r.Pfe = r.Ph + r.Pe;
            elseif isfield(r,'Pfe') && isfield(r,'Ph') && ~isfield(r,'Pe')
                r.Pe = r.Pfe - r.Ph;
            elseif isfield(r,'Pfe') && isfield(r,'Pe') && ~isfield(r,'Ph')
                r.Ph = r.Pfe - r.Pe;
            end

            %% SALIDA, ENTRADA Y RENDIMIENTO
            r.Padd = d.Padd;
            if hay('S'),                        r.S = d.S;
            elseif hay('Snom'),                 r.S = r.x*d.Snom;
            elseif hay('V') && isfield(r,'I'),  r.S = d.V*r.I;
            end
            if hay('Pout'),          r.Pout = d.Pout;
            elseif isfield(r,'S'),   r.Pout = r.S * d.FP;
            end
            if isfield(r,'Pfe') && isfield(r,'Pcu')
                r.Pperd = r.Pfe + r.Pcu + r.Padd;
                if isfield(r,'Pout')
                    r.Pin    = r.Pout + r.Pperd;
                    r.eta    = r.Pout / r.Pin;
                    r.etapct = 100*r.eta;
                end
                %  MÁXIMO RENDIMIENTO: donde las variables igualan a las
                %  fijas, Pcu = Pfe. Como Pcu = x^2*PcuNom, sale la raíz.
                if isfield(r,'PcuNom') && r.PcuNom > 0
                    r.xopt = sqrt(r.Pfe / r.PcuNom);
                    if hay('Snom')
                        Po = r.xopt * d.Snom * d.FP;
                        r.etamax = 100 * Po / (Po + 2*r.Pfe + r.Padd);
                    end
                end
            end

            %% REGULACIÓN — el diagrama fasorial: Vs a 0 grados de referencia
            if isfield(r,'Req') && isfield(r,'Xeq') && isfield(r,'I') && hay('V')
                th = acosd(min(max(d.FP,-1),1));
                if strcmpi(d.tipoFP,'adelantado'), th = +th; else, th = -th; end
                Is     = IE.pol2rec(r.I, th);
                r.Vp_a = d.V + (r.Req + 1j*r.Xeq)*Is;
                r.RV   = 100*(abs(r.Vp_a) - d.V)/d.V;
            end

            %% TABLA-CATÁLOGO: qué es cada pérdida y en qué casilla cae
            nombre = {}; W = []; cat = {}; dep = {}; ens = {};
            if isfield(r,'Ph')
                nombre{end+1} = 'Histeresis';
                W(end+1) = r.Ph;  cat{end+1} = 'fija';
                dep{end+1} = 'kh*f*Bmax^n';   ens{end+1} = 'vacio';
            end
            if isfield(r,'Pe')
                nombre{end+1} = 'Corrientes parasitas';
                W(end+1) = r.Pe;  cat{end+1} = 'fija';
                dep{end+1} = 'ke*f^2*Bmax^2*esp^2';  ens{end+1} = 'vacio';
            end
            if isfield(r,'Pfe')
                nombre{end+1} = 'NUCLEO (Pfe)';
                W(end+1) = r.Pfe; cat{end+1} = 'fija';
                dep{end+1} = 'tension y frecuencia';  ens{end+1} = 'vacio';
            end
            if isfield(r,'Pcu')
                nombre{end+1} = 'COBRE (Pcu)';
                W(end+1) = r.Pcu; cat{end+1} = 'variable';
                dep{end+1} = 'I^2*Req  ->  x^2';  ens{end+1} = 'cortocircuito';
            end
            if r.Padd ~= 0
                nombre{end+1} = 'Adicionales';
                W(end+1) = r.Padd; cat{end+1} = 'variable';
                dep{end+1} = 'flujo de dispersion';  ens{end+1} = 'cortocircuito';
            end
            if ~isempty(nombre)
                if isfield(r,'Pperd'), tot = r.Pperd; else, tot = NaN; end
                pct = 100*W(:)/tot;
                %  Las subfilas de histéresis y Foucault no se cuentan en el
                %  porcentaje: ya están adentro de la fila del núcleo.
                sub = ismember(nombre, {'Histeresis','Corrientes parasitas'});
                pct(sub) = NaN;
                r.tabla = table(string(nombre(:)), W(:), pct, string(cat(:)), ...
                    string(dep(:)), string(ens(:)), 'VariableNames', ...
                    {'Perdida','W','PctDelTotal','Categoria','Depende','Ensayo'});
            end
        end

        %{
        ecPerAprox — CIRCUITO EQUIVALENTE APROXIMADO del transformador real.
        Aproximación: la rama de excitación (Rc // jXm) se corre a los bornes
        de entrada, así que toda la caída Req + jXeq queda del lado de la
        carga y las dos ramas quedan en paralelo directo. Es el modelo del
        diagrama fasorial: Vp/a = Vs + (Req + jXeq)*Is.

                  Ip      Req     jXeq        Is
            o----->----[====]---[====]----->----o
                       |     |                  |
          Vp/a        Rc   jXm                  Vs   (carga)
                       |     |                  |
            o----------+-----+------------------o

        Todo REFERIDO AL SECUNDARIO y en FASORES (complejos, no módulos).
          Vpa  = Vp/a, tensión del primario referida  [V]
          Vp   tensión aplicada al primario           [V]
          Vs   tensión en bornes de la carga          [V]
          a    relación de transformación             [-]
          Is   corriente de carga                     [A]
          Ip   corriente del primario                 [A]
          Zeq  impedancia serie, Req + j*Xeq          [ohm]
          Rc   rama de pérdidas del núcleo            [ohm]
          Xm   rama de magnetización                  [ohm]
          Iexc corriente de excitación, Ic + Im       [A]

        Ej: [eqs,S] = IE.ecPerAprox();
            r = IE.despejar(eqs, S, struct('Vs',240,'Is',IE.pol2rec(50,-30), ...
                                           'Req',0.05,'Xeq',0.12,'a',10));
        %}
        function [eqs, S] = ecPerAprox()
            nom = {'Vpa','Vp','Vs','a','Is','Ip','Zeq','Req','Xeq', ...
                'Rc','Xm','Iexc','Ic','Im'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);

            eqs = [ S.Vpa  == S.Vp / S.a              % referir el primario
                S.Vpa  == S.Vs + S.Zeq*S.Is       % LVK: la de la foto
                S.Zeq  == S.Req + 1j*S.Xeq        % impedancia serie
                S.Ic   == S.Vpa / S.Rc            % pérdidas del núcleo
                S.Im   == S.Vpa / (1j*S.Xm)       % magnetización
                S.Iexc == S.Ic + S.Im             % rama de excitación
                S.a*S.Ip == S.Is + S.Iexc ];      % LCK en el nodo de entrada
        end

        %{
        ecSeg — Modelo simbólico de UN tramo con entrehierro.
        Mismo modelo que IE.reluctSeg, en versión simbólica.
          A_gap = A*(1 + dA)  -> crecimiento PROPORCIONAL por fringing.
        %}
        function [eqs, S] = ecSeg()
            nom = {'len','A','mu','g','dA','Rn','Rg','Rs','Fi','B','Bg'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            len = S.len; A = S.A; mu = S.mu; g = S.g; dA = S.dA;
            Rn = S.Rn; Rg = S.Rg; Rs = S.Rs; Fi = S.Fi; B = S.B; Bg = S.Bg;

            mu0 = 4*pi*1e-7;

            eqs = [ Rn == (len - g)/(mu*mu0*A)   % hierro: se descuenta el gap
                Rg == g/(mu0*A*(1 + dA))     % gap: mu_r = 1, área ampliada
                Rs == Rn + Rg                % reluctancia del segmento
                B  == Fi/A                   % densidad en el hierro
                Bg == Fi/(A*(1 + dA)) ];     % densidad en el gap
        end

        %{
        reluctSeg — Reluctancia de UN tramo, con o sin entrehierro.
        Es la pieza con la que se arma cualquier núcleo: si tu circuito
        no es un O ni un E, calculá los tramos con esto y sumalos/
        combinalos a mano (serie: suma; paralelo: IE.parZ).

        s : struct de tramo. Campos:
            len  longitud media del tramo            [m]   OBLIGATORIO
            mu   permeabilidad RELATIVA              [-]   OBLIGATORIO
            A    sección                             [m^2] (o dar a y b)
            a,b  lados de la sección rectangular     [m]   -> A = a*b
            g    entrehierro dentro del tramo        [m]   (opcional, 0)
            dA   crecimiento proporcional del área   [-]   (opcional)
            n    veces que el tramo aparece en serie [-]   (opcional, 1)

        FRINGING (dA): el flujo se abre al cruzar el gap, así que la
        sección efectiva del entrehierro es MAYOR que la del hierro:
            A_gap = A*(1 + dA)
        Si das a y b y NO das dA, se calcula:
            dA = (a+g)(b+g)/(a*b) - 1

        Salidas:
          R   : reluctancia total del tramo, ya multiplicada por n
          det : struct con Rn (hierro), Rg (gap), A, Agap, g, dA, n, mu
        %}
        function [R, det] = reluctSeg(s)
            mu0 = 4*pi*1e-7;

            if ~isfield(s,'g') || isempty(s.g), s.g = 0; end
            if ~isfield(s,'n') || isempty(s.n), s.n = 1; end

            % --- sección: a*b si está la geometría, si no A directo -------
            tieneAB = isfield(s,'a') && isfield(s,'b') && ...
                ~isempty(s.a) && ~isempty(s.b);
            if tieneAB
                A = s.a * s.b;
                if isfield(s,'A') && ~isempty(s.A) && ...
                        abs(A - s.A) > 1e-9*max(1,A)
                    error('IE:areaInconsistente', ...
                        'a*b = %g m^2 no coincide con A = %g m^2.', A, s.A);
                end
            else
                if ~isfield(s,'A') || isempty(s.A)
                    error('IE:faltaArea', ...
                        'El tramo necesita A, o bien a y b.');
                end
                A = s.A;
            end

            % --- fringing: explícito manda; si no, se calcula; si no, 0 ---
            if isfield(s,'dA') && ~isempty(s.dA)
                dA = s.dA;
            elseif tieneAB && s.g > 0
                dA = ((s.a + s.g)*(s.b + s.g))/A - 1;
            else
                dA = 0;
            end

            % --- validaciones ---------------------------------------------
            if s.g > s.len
                error('IE:gapMayorQueTramo', ...
                    'g (%g m) no puede superar len (%g m).', s.g, s.len);
            end
            if s.mu < 1
                error('IE:muRelativa', ...
                    ['mu = %g. Es la permeabilidad RELATIVA (>= 1), ' ...
                    'no la absoluta. El aire es mu = 1.'], s.mu);
            end
            if A <= 0 || s.len <= 0
                error('IE:geometriaInvalida', 'len y A deben ser > 0.');
            end

            Rn = (s.len - s.g)/(s.mu*mu0*A);          % hierro, gap descontado
            Rg = 0;
            Agap = A*(1 + dA);
            if s.g > 0
                Rg = s.g/(mu0*Agap);                  % gap, mu_r = 1
            end

            R   = s.n * (Rn + Rg);
            det = struct('Rn',s.n*Rn, 'Rg',s.n*Rg, 'A',A, 'Agap',Agap, ...
                'g',s.g, 'dA',dA, 'n',s.n, 'mu',s.mu);
        end

        %{
        fluxO — Núcleo tipo O: camino magnético CERRADO en SERIE.
        Cuadrado, rectangular, toroide, U+I, E-I armado... todos son un
        solo lazo: el flujo no se divide, las reluctancias se suman.

           ┌───────┐      Rt = R1 + R2 + R3 + R4 (+ Rgap)
           │       │      Fi = FMM / Rt = N*I / sum(R)
           │       │
           └───────┘

        Entradas:
          seg  : tramos. struct array O cell array de structs {s1, s2, ...}.
          N, I : vueltas y corriente de la bobina
          Bsat : umbral de saturación [T] (opcional, 1.5 por defecto).

        Salida r (struct):
          r.fmm    N*I                                   [A-vuelta]
          r.Rt     reluctancia total                     [A-v/Wb]
          r.Fi     flujo (único, es un lazo serie)       [Wb]
          r.L      inductancia N^2/Rt                    [H]
          r.R      reluctancia por tramo                 [A-v/Wb]
          r.frac   fracción de Rt que aporta cada tramo  [-]
          r.caida  caída de fmm por tramo, Fi*R          [A-vuelta]
          r.B      densidad en el HIERRO de cada tramo   [T]
          r.Bg     densidad en el ENTREHIERRO (NaN si no hay) [T]
          r.F      fuerza de atracción por entrehierro   [N]
          r.Ftot   fuerza total                          [N]
          r.sat    lógico: tramos con B > Bsat

        FUERZA: F = Bg^2 * Agap / (2*mu0) por cada superficie de contacto.
        %}
        function r = fluxO(seg, N, I, Bsat)
            if nargin < 4 || isempty(Bsat), Bsat = 1.5; end
            mu0 = 4*pi*1e-7;

            if iscell(seg), lista = seg(:); else, lista = num2cell(seg(:)); end
            nt = numel(lista);
            if nt == 0
                error('IE:sinTramos', 'El camino magnético no tiene tramos.');
            end

            R = zeros(nt,1); Ah = zeros(nt,1); Ag = zeros(nt,1);
            g = zeros(nt,1); mult = zeros(nt,1); muR = zeros(nt,1);
            for k = 1:nt
                [R(k), d] = IE.reluctSeg(lista{k});
                Ah(k) = d.A;  Ag(k) = d.Agap;  g(k) = d.g;
                mult(k) = d.n;  muR(k) = d.mu;
            end

            r.fmm   = N*I;
            r.Rt    = sum(R);
            r.Fi    = r.fmm / r.Rt;
            r.L     = N^2 / r.Rt;          % L = N^2/Rt = N*Fi/I
            r.R     = R;
            r.frac  = R / r.Rt;
            r.caida = r.Fi * R;            % suma = fmm (ley de Ampère)

            r.B  = r.Fi ./ Ah;             % en el hierro
            r.Bg = nan(nt,1);
            r.F  = zeros(nt,1);
            hayGap = g > 0;
            r.Bg(hayGap) = r.Fi ./ Ag(hayGap);
            % F = Bg^2*Agap/(2*mu0) por superficie; n superficies -> n veces
            r.F(hayGap)  = mult(hayGap) .* r.Bg(hayGap).^2 .* ...
                Ag(hayGap) / (2*mu0);
            r.Ftot = sum(r.F);

            % El aire no satura: solo se controlan los tramos ferromagnéticos.
            r.sat = (muR > 1) & (abs(r.B) > Bsat);
            if any(r.sat)
                warning('IE:saturacion', ...
                    ['Tramo(s) %s con B = %s T, por encima de Bsat = %.2f T. ' ...
                    'Este modelo es LINEAL (mu constante): en la realidad mu ' ...
                    'se desploma y el flujo es MENOR que el calculado. ' ...
                    'Hay que ir a la curva B-H a mano.'], ...
                    mat2str(find(r.sat)'), mat2str(r.B(r.sat)', 3), Bsat);
            end
        end

        %{
        fluxE — Núcleo tipo E. Bobina en UNA pierna; el flujo vuelve
        repartido por las otras dos, que quedan en PARALELO.

           ┌─┬─┐        Rt = R(b) + (R(otra1) // R(otra2))
           │ │ │        Fi(b) = FMM / Rt
           └─┴─┘        Fi(otras) = divisor de corriente sobre R

        Entradas:
          R : reluctancias de las 3 piernas. Vector numérico [R1 R2 R3],
              struct array, o cell array de 3 tramos (ver IE.reluctSeg).
          b : índice (1,2,3) de la pierna bobinada
          N, I    : vueltas y corriente
          sentido : +1 / -1, orientación de la FMM (opcional, +1)

        Salidas:
          Fi : 3x1. SIGNO: todos los flujos medidos ENTRANDO al yugo
               superior, así que sum(Fi) = 0 (ley de nodos magnética).
          Rt : reluctancia vista por la bobina
          r  : struct (R, frac, L, B, Bg, F, sat)
        %}
        function [Fi, Rt, r] = fluxE(R, b, N, I, sentido)
            if nargin < 5 || isempty(sentido), sentido = 1; end

            % --- normalizar la entrada a un vector de reluctancias --------
            det = [];
            if iscell(R) || isstruct(R)
                if iscell(R), lista = R(:); else, lista = num2cell(R(:)); end
                Rv = zeros(numel(lista),1);
                for k = 1:numel(lista)
                    [Rv(k), dk] = IE.reluctSeg(lista{k});
                    if isempty(det), det = dk; else, det(k) = dk; end %#ok<AGROW>
                end
                R = Rv;
            else
                R = R(:);
            end
            if numel(R) ~= 3
                error('IE:fluxETresPiernas', ...
                    'fluxE espera 3 piernas, recibió %d.', numel(R));
            end
            if ~ismember(b, 1:3)
                error('IE:fluxEPierna', ...
                    'b debe ser 1, 2 o 3 (pierna bobinada), no %g.', b);
            end

            otras = setdiff(1:3, b);

            Rt    = R(b) + IE.parZ(R(otras));
            Fi    = zeros(3,1);
            Fi(b) = sentido * (N*I)/Rt;

            % mismo divisor que en corriente: se reparte inverso a R.
            % signo negado -> el flujo VUELVE por estas piernas.
            Fi(otras) = -IE.divI(Fi(b), R(otras));

            r.R    = R;
            r.frac = R / sum(R);
            r.L    = N^2 / Rt;             % vista desde la bobina
            r.Fi   = Fi;

            if ~isempty(det)               % hubo geometría: hay B, Bg y F
                mu0  = 4*pi*1e-7;
                Ah   = [det.A]';    Ag = [det.Agap]';
                gv   = [det.g]';    mv = [det.n]';   muv = [det.mu]';
                r.B  = Fi ./ Ah;
                r.Bg = nan(3,1);
                r.F  = zeros(3,1);
                hay  = gv > 0;
                r.Bg(hay) = Fi(hay) ./ Ag(hay);
                r.F(hay)  = mv(hay) .* r.Bg(hay).^2 .* Ag(hay) / (2*mu0);
                r.Ftot = sum(r.F);
                r.sat  = (muv > 1) & (abs(r.B) > 1.5);
                if any(r.sat)
                    warning('IE:saturacion', ...
                        ['Pierna(s) %s con B = %s T > 1.5 T. Modelo lineal: ' ...
                        'el flujo real es MENOR.'], ...
                        mat2str(find(r.sat)'), mat2str(r.B(r.sat)', 3));
                end
            end
        end
    end
end
