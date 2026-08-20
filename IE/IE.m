classdef IE
    % IE — Caja de herramientas de Instalaciones/Ingeniería Eléctrica.
    %      Todos los métodos son estáticos: se llaman IE.nombre(...).
    %
    % CONVENCIONES DE TODA LA CLASE
    %   - Ángulos en GRADOS en la interfaz (cosd/sind/deg2rad adentro).
    %   - Magnitudes de tensión/corriente en RMS salvo aviso explícito.
    %   - Secuencia de fases POSITIVA (ABC): B atrasa 120° a A, C atrasa 240°.
    %   - mu es SIEMPRE permeabilidad RELATIVA (adimensional); mu0 va aparte.
    %   - dA es un crecimiento PROPORCIONAL del área en el entrehierro:
    %     A_gap = A*(1 + dA). dA = 0.10 -> 10% más de área por fringing.

    methods(Static)

        %% ===================================================================
        %  pol2rec — Polar a rectangular. Vectorizada: x y teta pueden ser
        %  vectores de igual largo (o uno escalar y el otro vector).
        %    x    : módulo(s)
        %    teta : ángulo(s) en grados
        %  Ej: IE.pol2rec([8; 12], [-30; 45])
        %% ===================================================================
        function X = pol2rec(x, teta)
            X = x(:) .* exp(1j*deg2rad(teta(:)));
        end

        %% ===================================================================
        %  parZ — Equivalente de impedancias EN PARALELO.
        %    Z : vector [z1 z2 ... zn]
        %% ===================================================================
        function Zp = parZ(Z)
            Zp = 1/sum(1./Z(:));
        end

        %% ===================================================================
        %  f2l — FASE a LÍNEA  (E_L = sqrt(3)*E_F)
        %  l2f — LÍNEA a FASE  (E_F = E_L/sqrt(3))
        %
        %  Solo módulos: la línea además adelanta 30° a la fase en secuencia
        %  positiva (ver IE.fasores). Válido en sistemas equilibrados, sin
        %  impedancias colgando fuera del triángulo.
        %% ===================================================================
        function E_L = f2l(E_F)
            E_L = E_F*sqrt(3);
        end

        function E_F = l2f(E_L)
            E_F = E_L/sqrt(3);
        end

        %% ===================================================================
        %  d2e — DELTA a ESTRELLA   (transformación de Kennelly)
        %  e2d — ESTRELLA a DELTA
        %
        %  OJO: esto es para IMPEDANCIAS, no para tensiones. Para tensiones
        %  el par es IE.f2l / IE.l2f. Confundirlos es el error clásico:
        %  el sqrt(3) es de tensiones, el 3 es de impedancias.
        %
        %  CASO EQUILIBRADO (entrada ESCALAR, salida ESCALAR):
        %      Z_Y = Z_D/3        Z_D = 3*Z_Y
        %  Una carga en triángulo consume 3 veces la potencia que la MISMA
        %  impedancia en estrella: por eso Z_Y = Z_D/3.
        %
        %  CASO GENERAL (entrada VECTOR de 3, salida VECTOR de 3):
        %    Orden fijo -> D: [Zab; Zbc; Zca]   Y: [Za; Zb; Zc]
        %    (Za es el brazo que cuelga del nodo A hacia el neutro.)
        %
        %      D->Y :  Za = Zab*Zca / (Zab+Zbc+Zca)
        %              Zb = Zab*Zbc / (Zab+Zbc+Zca)
        %              Zc = Zbc*Zca / (Zab+Zbc+Zca)
        %              -> cada brazo Y = producto de las DOS ramas D que
        %                 tocan ese nodo, sobre la suma de las tres.
        %
        %      Y->D :  P = Za*Zb + Zb*Zc + Zc*Za
        %              Zab = P/Zc,  Zbc = P/Za,  Zca = P/Zb
        %              -> cada rama D = P sobre el brazo Y OPUESTO.
        %
        %  Acepta complejos. Ej: IE.d2e(IE.pol2rec([30;30;30],[60;60;60]))
        %% ===================================================================
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

        %% ===================================================================
        %  fasores — Tabla completa de un sistema trifásico equilibrado.
        %
        %  Entradas:
        %    E_AN : magnitud RMS de la fase A (ESCALAR)
        %    ang0 : ángulo de E_AN en grados (opcional, 0 por defecto)
        %
        %  Salida: matriz 6x4 -> [RMS  ang(°)  Pico  Pico-pico]
        %          filas: AN, BN, CN, AB, BC, CA
        %
        %  Secuencia POSITIVA (ABC): BN atrasa 120°, CN atrasa 240°.
        %  Comprobación: E_AB = E_AN - E_BN = sqrt(3)*E_AN /_(ang0 + 30°).
        %% ===================================================================
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

        %% ===================================================================
        %  divV — Divisor de tensión.
        %    V : tensión total aplicada a la SERIE
        %    Z : vector de impedancias EN SERIE [z1; z2; ...; zn]
        %  Salida: tensión sobre cada impedancia.
        %  Ej: Z = [10+5j; IE.pol2rec([8; 12], [-30; 45])];
        %% ===================================================================
        function Vz = divV(V, Z)
            Vz = V * Z(:) / sum(Z(:));
        end

        %% ===================================================================
        %  divI — Divisor de corriente.
        %    I : corriente total que entra al nodo
        %    Z : vector de impedancias EN PARALELO [z1; z2; ...; zn]
        %  Salida: corriente por cada rama.
        %% ===================================================================
        function Iz = divI(I, Z)
            Y  = 1./Z(:);
            Iz = I * Y / sum(Y);
        end

        %% ===================================================================
        %  potencias — Triángulo de potencias a partir de fasores RMS.
        %    V, I : fasores complejos (escalares o vectores del mismo tamaño)
        %
        %  Salida struct:
        %    S, P [W], Q [VAR], magS [VA], theta [°], FP, tipo
        %    Stot : suma compleja (útil si V,I son vectores de varias cargas)
        %  'tipo' se evalúa ELEMENTO A ELEMENTO -> string array.
        %% ===================================================================
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

        %% ===================================================================
        %  CIRCUITO MAGNÉTICO — nomenclatura común
        %    B    densidad de flujo magnético           [T] = [Wb/m^2]
        %    H    intensidad de campo                   [A/m]
        %    mu   permeabilidad RELATIVA del medio      [adimensional]
        %    mu0  permeabilidad del vacío = 4*pi*1e-7   [H/m]
        %    len  longitud media del camino magnético   [m]  (2*pi*R en toroide)
        %    N    número de vueltas                     [-]
        %    I    corriente                             [A]
        %    Fi   flujo magnético                       [Wb]
        %    dFi  derivada del flujo, dFi/dt            [Wb/s]
        %    A    área transversal                      [m^2]
        %    v    tensión inducida                      [V]
        %    R    reluctancia                           [A-vuelta/Wb]
        %% ===================================================================

        %% ===================================================================
        %  ecB — Declara el modelo del circuito magnético.
        %  No resuelve nada; solo entrega el sistema y el diccionario de
        %  símbolos para que otras funciones lo usen.
        %
        %  Salidas:
        %    eqs : vector simbólico con las 4 leyes, sin resolver.
        %    S   : struct-diccionario. S.N es el SÍMBOLO N (no un valor).
        %          Es indispensable devolverlo: cada llamada a syms crea
        %          objetos nuevos, así que una N declarada afuera NO es la
        %          misma N que está dentro de eqs. Usando S siempre pegan.
        %
        %  POR QUÉ dFi Y NO diff(Fi,t):
        %    solve() es un solucionador ALGEBRAICO. Si Faraday se escribe
        %    como v == N*diff(Fi(t),t), solve no sabe derivar la relación
        %    Fi = B*A y devuelve VACÍO sin avisar (verificado en R2026a).
        %    Acá dFi = dFi/dt es un símbolo más, el sistema queda 100%
        %    algebraico y siempre resuelve. Para el análisis temporal real
        %    está IE.faradayB, que sí deriva.
        %
        %  EJEMPLO DE USO
        %    [eqs, S] = IE.ecB();
        %    eqs = subs(eqs, [S.N S.A S.len S.mu], [200 1e-3 0.3 5000]);
        %    eqs = subs(eqs, S.I, 2);
        %    double(solve(eqs, S.Fi))
        %% ===================================================================
        function [eqs, S] = ecB()

            % sym() y NO syms: dentro de un método, syms falla si el nombre
            % choca con una función existente del path ('Fi' colisiona en
            % R2026a y aborta con "Unable to create symbolic variable").
            % sym('Fi') crea el símbolo igual y nunca colisiona.
            nom = {'B','H','mu','len','N','I','Fi','dFi','A','v','t'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            B = S.B; H = S.H; mu = S.mu; len = S.len; N = S.N;
            I = S.I; Fi = S.Fi; dFi = S.dFi; A = S.A; v = S.v;

            mu0 = 4*pi*1e-7;        % permeabilidad del vacío [H/m]
            % numérico, no simbólico: es constante.

            % == (doble igual) en contexto simbólico construye una ECUACIÓN,
            % no una comparación lógica. Con = simple sería una asignación.
            eqs = [ H  == N*I/len            % Ley de Ampère
                    B  == mu*mu0*H           % Relación B-H del material
                    B  == Fi/A               % Definición de densidad de flujo
                    v  == N*dFi ];           % Ley de Faraday
            % Ampère y B-H se dejan SEPARADAS a propósito: fusionarlas en
            % B == mu*mu0*N*I/len obliga a repetir mu con dos significados
            % distintos (relativa acá, absoluta en mu == B/H) y el sistema
            % queda contradictorio.

            % Nota: S ya quedó armado arriba. Un solo lugar donde se listan
            % los nombres -> imposible que el diccionario se desincronice
            % de los símbolos que están dentro de eqs.
            % 'len' y no 'l': en pantalla l y 1 son casi idénticos.
        end

        %% ===================================================================
        %  despejar — MOTOR de despeje. Lo usan datosB y datosSeg.
        %
        %  Entradas:
        %    eqs : sistema simbólico (de IE.ecB, IE.ecSeg, ...)
        %    S   : diccionario de símbolos del MISMO sistema
        %    d   : struct con SOLO lo que conocés, en cualquier orden
        %
        %  Salida:
        %    res : struct con TODAS las variables que quedaron determinadas.
        %          Para número: double(res.Fi) o vpa(res.Fi, 6).
        %
        %  NO SE PIDE UNA INCÓGNITA, A PROPÓSITO.
        %    La sustitución hacia adelante determina TODO lo que los datos
        %    permitan, en la misma pasada. Pedir una variable no ahorraba
        %    trabajo: solo elegía cuál de las ya calculadas devolver y
        %    escondía el resto. Elegís vos, del struct.
        %    Si un campo NO está en res, es que los datos no alcanzaron para
        %    determinarlo. Ese es el diagnóstico: mirá qué falta.
        %
        %  POR QUÉ NO ES UN solve() PELADO:
        %    solve(eqs, x) exige que TODAS las ecuaciones se satisfagan
        %    eligiendo únicamente x. Como el sistema tiene varias incógnitas
        %    intermedias (H, B, Rn, ...), cualquier ecuación que no contenga
        %    x lo vuelve insatisfacible y solve devuelve VACÍO aunque los
        %    datos alcancen de sobra. Verificado en R2026a.
        %    Acá se hace SUSTITUCIÓN HACIA ADELANTE, que es exactamente el
        %    método a mano: se busca una ecuación con una sola incógnita, se
        %    despeja, se propaga el valor, y se repite hasta que no queda nada
        %    por despejar.
        %% ===================================================================
        function res = despejar(eqs, S, d)

            % fieldnames — devuelve los nombres de los campos del struct como
            % CELL ARRAY de texto: {'mu'; 'len'; 'N'; ...}. Permite que la
            % función no sepa de antemano qué datos le van a pasar.
            campos = fieldnames(d);

            for k = 1:numel(campos)
                if ~isfield(S, campos{k})
                    error('IE:campoDesconocido', ...
                        ['"%s" no es una variable del modelo. ' ...
                         'Válidas: %s'], campos{k}, strjoin(fieldnames(S)', ', '));
                end
                % campos{k}  -> LLAVES porque es cell array; da el texto 'N'.
                % S.(...)    -> acceso DINÁMICO a campo. S.N exige saber el
                %               nombre al escribir el código; S.('N') acepta
                %               el nombre como variable en ejecución.
                %               S.(campos{k}) = el SÍMBOLO
                %               d.(campos{k}) = el VALOR
                % subs(eqs, simbolo, valor) reemplaza en TODAS las ecuaciones
                % de una vez. El loop es necesario: subs no recorre structs.
                eqs = subs(eqs, S.(campos{k}), d.(campos{k}));
            end

            % --- sustitución hacia adelante -------------------------------
            res    = struct();
            cambio = true;
            while cambio
                cambio = false;
                for k = 1:numel(eqs)
                    libres = symvar(eqs(k));

                    % Sin incógnitas libres, la ecuación ya es un veredicto.
                    % OJO: subs NO la colapsa a symfalse, la deja como
                    % "999 == 100" (verificado en R2026a), así que hay que
                    % preguntarle a isAlways en vez de comparar con sym(false).
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

        %% ===================================================================
        %  datosB — Atajo sobre el modelo del circuito magnético.
        %    d   : struct con lo conocido. Ej:
        %          struct('mu',5000,'len',0.3,'N',200,'I',2,'A',1e-3)
        %  Devuelve un struct con TODO lo que los datos permitan despejar.
        %  Ej: double(IE.datosB(d).Fi)
        %% ===================================================================
        function res = datosB(d)
            [eqs, S] = IE.ecB();
            res = IE.despejar(eqs, S, d);
        end

        %% ===================================================================
        %  datosSeg — Atajo sobre el modelo de UN tramo con entrehierro.
        %    d   : struct con len, A, mu, g, dA, Fi... lo que tengas
        %  Devuelve un struct con TODO lo que los datos permitan despejar.
        %  Ej: double(IE.datosSeg(struct('len',.3,'A',1e-3,'mu',5e3, ...
        %                                'g',1e-3,'dA',.1)).Rs)
        %% ===================================================================
        function res = datosSeg(d)
            [eqs, S] = IE.ecSeg();
            res = IE.despejar(eqs, S, d);
        end

        %% ===================================================================
        %  faradayB — Análisis TEMPORAL. Esto es lo que ecB no puede
        %  hacer: derivar de verdad.
        %
        %  Entradas:
        %    d   : struct con N, A, len, mu (permeabilidad RELATIVA)
        %    I_t : corriente como EXPRESIÓN simbólica en t.
        %          Ej: syms t; I_t = 2*sin(377*t);
        %    t   : (opcional) la variable de tiempo usada en I_t.
        %          Por defecto sym('t'). PASALA si tu t viene de otro lado.
        %
        %  Salidas:
        %    v_t  : tensión inducida v(t) = N*dFi/dt   [V]
        %    Fi_t : flujo Fi(t) = mu*mu0*N*A*I(t)/len  [Wb]
        %    L    : inductancia N^2/R = mu*mu0*N^2*A/len [H]
        %
        %  Ej: [v, Fi, L] = IE.faradayB(struct('N',200,'A',1e-3, ...
        %                     'len',0.3,'mu',5000), 2*sin(377*t));
        %      vpa(v, 6)
        %% ===================================================================
        function [v_t, Fi_t, L] = faradayB(d, I_t, t)
            if nargin < 3, t = sym('t'); end
            mu0 = 4*pi*1e-7;

            L    = d.mu*mu0*d.N^2*d.A/d.len;     % inductancia [H]
            Fi_t = d.mu*mu0*d.N*d.A*I_t/d.len;   % flujo [Wb]
            v_t  = d.N*diff(Fi_t, t);            % Faraday: v = N dFi/dt
            % Equivalente: v_t = L*diff(I_t, t). Se deja la forma de Faraday
            % porque es la que hay que reconocer en el parcial.
        end

        %% ===================================================================
        %  ecTrafo — Modelo simbólico del TRANSFORMADOR IDEAL.
        %  Mismo esquema que IE.ecB: declara el sistema y devuelve
        %  el diccionario. No resuelve nada. Se despeja con IE.despejar
        %  (o el atajo IE.datosTrafo / IE.trafo).
        %
        %  DE DÓNDE SALE: es Faraday aplicado al MISMO núcleo. Las dos
        %  bobinas ven el mismo dFi/dt, así que
        %      Vp = Np*dFi      Vs = Ns*dFi      ->   Vp/Vs = Np/Ns = a
        %  y la FMM neta del núcleo ideal es cero (R -> 0):
        %      Np*Ip = Ns*Is    ->   Is/Ip = Np/Ns = a
        %
        %  CONSTANTES (las dos, como pediste):
        %      a = Np/Ns   -> "vista desde el PRIMARIO". Multiplica lo del
        %                     secundario para referirlo al primario.
        %      b = Ns/Np   -> "vista desde el SECUNDARIO". Es 1/a.
        %      a > 1 : reductor (baja tensión, sube corriente).
        %      a < 1 : elevador.
        %
        %  VARIABLES DEL DICCIONARIO S
        %    a    Np/Ns, relación de transformación          [-]
        %    b    Ns/Np = 1/a                                [-]
        %    Np   vueltas del primario                       [-]
        %    Ns   vueltas del secundario                     [-]
        %    Vp   tensión en el primario                     [V]
        %    Vs   tensión en el secundario                   [V]
        %    Ip   corriente del primario                     [A]
        %    Is   corriente del secundario                   [A]
        %    Zp   impedancia VISTA desde el primario         [ohm]
        %    Zs   impedancia conectada al secundario (carga) [ohm]
        %    dFi  dFi/dt común a las dos bobinas             [Wb/s]
        %
        %  RESUMEN DE REFERIR (lo que hay que tener a mano en el parcial):
        %      Vp = a*Vs      Ip = Is/a      Zp = a^2*Zs
        %      Vs = b*Vp      Is = Ip/b      Zs = b^2*Zp
        %  La tensión y la corriente van con a; la impedancia con a AL
        %  CUADRADO. Ese cuadrado es el que casi siempre se olvida.
        %
        %  IDEAL significa: sin dispersión, sin resistencia de bobinado, sin
        %  pérdidas en el hierro y con corriente de magnetización nula
        %  (mu -> inf). No hay rama de excitación ni caída interna: si el
        %  problema pide regulación de tensión o rendimiento, este modelo
        %  no alcanza, hay que agregar Req y Xeq a mano.
        %
        %  EJEMPLO
        %    [eqs, S] = IE.ecTrafo();
        %    eqs = subs(eqs, [S.Np S.Ns S.Vp], [500 100 220]);
        %    double(IE.despejar(eqs, S, struct(), 'Vs'))
        %% ===================================================================
        function [eqs, S] = ecTrafo()

            % sym() y no syms: ver la nota en IE.ecB.
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

            % b == 1/a y no b == Ns/Np a propósito: así b sale también cuando
            % te dan 'a' pelado y nunca te dieron Np ni Ns (el caso normal).
            % Las tres últimas son redundantes entre sí, y eso está buscado:
            % IE.despejar sustituye hacia adelante, y tener el mismo dato por
            % varios caminos es lo que permite entrar por donde venga el
            % enunciado (por Vp/Ip, por la carga, o por la relación).
            % Como redundantes que son, también actúan de CONTROL: si los
            % datos no cierran, despejar aborta con IE:datosContradictorios
            % en vez de devolver un número mentiroso.

            % NO hay ecuación de potencia. La tentación es poner S = Vp*Ip,
            % pero con fasores la potencia compleja es V*conj(I) y conj()
            % rompe a solve(). Si necesitás el triángulo: IE.potencias(Vp,Ip).
        end

        %% ===================================================================
        %  datosTrafo — Atajo sobre el modelo del transformador ideal.
        %    d   : struct con lo conocido, en cualquier orden. Ej:
        %          struct('a',5,'Vp',220,'Zs',10)
        %  Devuelve un struct con TODO lo que los datos permitan despejar.
        %  Ej: double(IE.datosTrafo(struct('Np',500,'Ns',100,'Vp',220)).Vs)
        %% ===================================================================
        function res = datosTrafo(d)
            [eqs, S] = IE.ecTrafo();
            res = IE.despejar(eqs, S, d);
        end

        %% ===================================================================
        %  trafo — Resuelve TODO lo que se pueda del transformador ideal y lo
        %  devuelve numérico, sin tener que pedir variable por variable.
        %
        %    d : struct con lo conocido. Ej:
        %        IE.trafo(struct('a',10,'Vp',2200,'Zs',5))
        %
        %  Salida r (struct) con los campos que quedaron determinados, en
        %  orden fijo: a, b, Np, Ns, Vp, Vs, Ip, Is, Zp, Zs, dFi.
        %  Lo que no se pudo determinar simplemente NO aparece: mirá los
        %  campos que faltan para saber qué dato te está faltando.
        %
        %  Acepta complejos (Zs = 8+6j y Vp complejo salen bien: a es real,
        %  así que referir no rota fases).
        %% ===================================================================
        function r = trafo(d)
            [eqs, S] = IE.ecTrafo();

            % despejar determina todo lo que los datos permitan. Los campos
            % que falten en la salida cuentan solos qué no se pudo sacar.
            res = IE.despejar(eqs, S, d);

            % Lo que entró como dato también va a la salida: res solo trae lo
            % que se DESPEJÓ, no lo que se dio.
            orden = {'a','b','Np','Ns','Vp','Vs','Ip','Is','Zp','Zs','dFi'};
            r = struct();
            for k = 1:numel(orden)
                nk = orden{k};
                if isfield(d, nk)
                    r.(nk) = d.(nk);
                elseif isfield(res, nk)
                    v = res.(nk);
                    % double() falla si quedó en función de un símbolo libre;
                    % en ese caso se deja la expresión simbólica tal cual.
                    try, v = double(v); catch, end %#ok<NOCOM>
                    r.(nk) = v;
                end
            end
        end

        %% ===================================================================
        %  ecSeg — Modelo simbólico de UN tramo con entrehierro.
        %  Mismo modelo que IE.reluctSeg, en versión simbólica.
        %    A_gap = A*(1 + dA)  -> crecimiento PROPORCIONAL por fringing.
        %% ===================================================================
        function [eqs, S] = ecSeg()

            % sym() y no syms: ver la nota en IE.ecB.
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

        %% ===================================================================
        %  reluctSeg — Reluctancia de UN tramo, con o sin entrehierro.
        %  Es la pieza con la que se arma cualquier núcleo: si tu circuito
        %  no es un O ni un E, calculá los tramos con esto y sumalos/
        %  combinalos a mano (serie: suma; paralelo: IE.parZ).
        %
        %  s : struct de tramo. Campos:
        %      len  longitud media del tramo            [m]   OBLIGATORIO
        %      mu   permeabilidad RELATIVA              [-]   OBLIGATORIO
        %      A    sección                             [m^2] (o dar a y b)
        %      a,b  lados de la sección rectangular     [m]   -> A = a*b
        %      g    entrehierro dentro del tramo        [m]   (opcional, 0)
        %      dA   crecimiento proporcional del área   [-]   (opcional)
        %      n    veces que el tramo aparece en serie [-]   (opcional, 1)
        %
        %  FRINGING (dA): el flujo se abre al cruzar el gap, así que la
        %  sección efectiva del entrehierro es MAYOR que la del hierro.
        %      A_gap = A*(1 + dA)
        %  Si das a y b y NO das dA, se calcula de la geometría con la regla
        %  estándar de agregarle g a cada lado:
        %      A_gap = (a + g)*(b + g)   ->   dA = (a+g)(b+g)/(a*b) - 1
        %  Si das dA explícito, MANDA el tuyo (el dato de la cátedra gana).
        %
        %  Salidas:
        %    R   : reluctancia total del tramo, ya multiplicada por n
        %    det : struct con Rn (hierro), Rg (gap), A, Agap, g, dA, n, mu
        %% ===================================================================
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

        %% ===================================================================
        %  fluxO — Núcleo tipo O: camino magnético CERRADO en SERIE.
        %  Cuadrado, rectangular, toroide, U+I, E-I armado... todos son un
        %  solo lazo: el flujo no se divide, las reluctancias se suman.
        %
        %     ┌───────┐      Rt = R1 + R2 + R3 + R4 (+ Rgap)
        %     │       │      Fi = FMM / Rt = N*I / sum(R)
        %     │       │
        %     └───────┘
        %
        %  Entradas:
        %    seg  : tramos. struct array O cell array de structs {s1, s2, ...}.
        %           El cell array existe porque concatenar structs con campos
        %           distintos ([a b] con a sin 'g' y b con 'g') es un error
        %           de MATLAB. Con llaves no hay que emparejar campos.
        %           Campos de cada tramo: ver IE.reluctSeg.
        %    N, I : vueltas y corriente de la bobina
        %    Bsat : umbral de saturación [T] (opcional, 1.5 por defecto).
        %
        %  Salida r (struct):
        %    r.fmm    N*I                                   [A-vuelta]
        %    r.Rt     reluctancia total                     [A-v/Wb]
        %    r.Fi     flujo (único, es un lazo serie)       [Wb]
        %    r.L      inductancia N^2/Rt                    [H]
        %    r.R      reluctancia por tramo                 [A-v/Wb]
        %    r.frac   fracción de Rt que aporta cada tramo  [-]
        %    r.caida  caída de fmm por tramo, Fi*R          [A-vuelta]
        %    r.B      densidad en el HIERRO de cada tramo   [T]
        %    r.Bg     densidad en el ENTREHIERRO (NaN si no hay) [T]
        %    r.F      fuerza de atracción por entrehierro   [N]
        %    r.Ftot   fuerza total                          [N]
        %    r.sat    lógico: tramos con B > Bsat
        %
        %  FUERZA: F = Bg^2 * Agap / (2*mu0) por cada superficie de contacto.
        %  Si el tramo tiene n = 2, la fuerza ya viene multiplicada por 2.
        %
        %  U+I (electroimán, contactor): es un O con DOS entrehierros, uno
        %  en cada contacto. No necesita función aparte — poné n = 2 en el
        %  tramo del gap y r.Ftot ya te da la fuerza de las dos superficies:
        %      gap.n = 2;
        %      r = IE.fluxO({pierna1, yugo, pierna2, barra, gap}, N, I);
        %
        %  LÍMITE: modelo LINEAL. mu es constante, no hay curva B-H. Si algún
        %  tramo satura, avisa — y el flujo real será MENOR que el calculado.
        %% ===================================================================
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

        %% ===================================================================
        %  fluxE — Núcleo tipo E. Bobina en UNA pierna; el flujo vuelve
        %  repartido por las otras dos, que quedan en PARALELO.
        %
        %     ┌─┬─┐        Rt = R(b) + (R(otra1) // R(otra2))
        %     │ │ │        Fi(b) = FMM / Rt
        %     └─┴─┘        Fi(otras) = divisor de corriente sobre R
        %
        %  Entradas:
        %    R : reluctancias de las 3 piernas. Vector numérico [R1 R2 R3],
        %        struct array, o cell array de 3 tramos (ver IE.reluctSeg).
        %        Los YUGOS no van acá: ver el punto 1 de abajo.
        %    b : índice (1,2,3) de la pierna bobinada
        %    N, I    : vueltas y corriente
        %    sentido : +1 / -1, orientación de la FMM (opcional, +1)
        %
        %  Salidas:
        %    Fi : 3x1. SIGNO: todos los flujos medidos ENTRANDO al yugo
        %         superior, así que sum(Fi) = 0 (ley de nodos magnética).
        %         Las dos piernas de retorno salen con signo opuesto a Fi(b).
        %    Rt : reluctancia vista por la bobina
        %    r  : struct. Siempre trae R, frac y L. Si pasaste tramos (no
        %         números pelados) trae además B, Bg, F y sat por pierna.
        %
        %  QUÉ DESPRECIA ESTE MODELO — leer antes de confiar en el número:
        %    1) Los YUGOS (las barras horizontales que unen las 3 piernas)
        %       no están. Se asume que su reluctancia es despreciable frente
        %       a la de las piernas. Es razonable si los yugos son cortos y
        %       gruesos; deja de serlo si hay entrehierro en el yugo.
        %    2) Flujo de dispersión entre piernas: cero. Todo el flujo que
        %       sale de la pierna b vuelve por las otras dos.
        %    3) Es LINEAL: sin saturación (salvo el aviso, si pasás tramos).
        %    Para el E simétrico con la bobina en la pierna central —el caso
        %    de clase— el error es chico. Con piernas muy asimétricas o gap
        %    en el yugo, armá las mallas a mano con IE.reluctSeg y IE.parZ.
        %% ===================================================================
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
