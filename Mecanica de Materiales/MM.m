classdef MM
    % MM — Caja de herramientas de Mecánica de Materiales I.
    %      Todos los métodos son estáticos: se llaman MM.nombre(...).
    %      Cubre las fórmulas de formulario_mecanica.pdf que se pueden
    %      calcular. El número entre paréntesis es el de la ecuación.
    %
    % ÍNDICE POR SECCIÓN DEL FORMULARIO
    %   1. Esfuerzo y deformación normal
    %      (1) (2)               MM.axial
    %      (3)                   MM.reales          esfuerzo y deformación reales
    %      (4)                   MM.concentracion   factor de concentración
    %   2. Propiedades mecánicas
    %      (5) (6)               MM.axial           Hooke y Poisson
    %      (7) (8)               MM.elastica        G, K volumétrico, dilatación
    %   3. Deformación axial
    %      (9) (10) (14)         MM.axial           rigidez, flexibilidad, energía
    %      (11)                  MM.escalonada      barra por tramos
    %      (12)                  MM.ahusada         sección o carga variable
    %      (13)                  MM.pesoPropio
    %   4. Sistemas indeterminados axiales
    %      (15) (19)             MM.indeterminada   superposición y desajuste
    %      (16)                  MM.biempotrada
    %      (17) (18)             MM.paralelo        cilindros concéntricos
    %   5. Esfuerzo cortante y conexiones
    %      (20) (21) (24) (25)   MM.cortante
    %      (22)                  MM.apoyo           aplastamiento
    %      (26)                  MM.axial           cortante máximo a 45°
    %   6. Torsión en ejes circulares
    %      (25) (27) (28) (31) (33) (43)  MM.torsion
    %      (29) (30)             MM.seccionPolar    J macizo o tubular
    %      (31)                  MM.escalonadaT     eje por tramos
    %      (32)                  MM.ahusadaT        J o T variables
    %      (34)                  MM.potencia
    %      indeterminada         MM.indeterminadaT
    %   7. Diseño y factor de seguridad
    %      (35) (36) (37)        MM.seguridad
    %      (38)                  MM.lrfd
    %      (39) a (42)           MM.diseno
    %
    %   Cada sistema tiene dos caras: MM.ecXxx declara las ecuaciones sin
    %   resolver, y el atajo MM.xxx('dato',valor, ...) las resuelve y
    %   devuelve un struct numérico con todo lo que los datos permiten.
    %
    % CONVENCIONES DE TODA LA CLASE
    %   - SISTEMA COHERENTE. No hay conversión de unidades adentro. Si entrás
    %     en [N] y [m], E va en [Pa] y salís en [m]. Si entrás en [N] y [mm],
    %     E va en [MPa] y salís en [mm]. Mezclar es el error #1 del parcial:
    %     E = 200 GPa con A en mm^2 da un delta 1e6 veces equivocado.
    %   - SIGNOS: tensión POSITIVA, compresión NEGATIVA. Vale para P, sig,
    %     eps y delta a la vez. Un delta negativo es un acortamiento.
    %   - P es la fuerza INTERNA del tramo (la del DCL después del corte),
    %     no la carga externa aplicada. Cortar y hacer suma de fuerzas es
    %     trabajo tuyo; el código no arma diagramas de cuerpo libre.
    %   - Modelo LINEAL ELÁSTICO: E constante, sin fluencia, sin necking.
    %     Vale solo mientras sig < límite de proporcionalidad. La única
    %     excepción es MM.reales, que existe justo para después.
    %   - ÁNGULOS en RADIANES (phi, gam, gxy, thetap). rad2deg para leerlos.
    %
    % MOTOR DE DESPEJE
    %   El que resuelve es Motor.despejar (Motor.m, en la raíz del repo): es
    %   el mismo motor que usan VM, FV, IE y sp, no una copia. Para que MATLAB
    %   lo encuentre parado en esta carpeta, correr UNA vez setup.m (raíz).
    %
    % LO QUE NO ESTÁ, y por qué
    %   - Creep, la hipótesis de torsión circular y los 3 pasos de los
    %     indeterminados son texto: no hay nada que calcular. Los 3 pasos
    %     están aplicados en MM.indeterminada.
    %   - (23) tau_xy = tau_yx es una identidad: el valor es el mismo.
    %   - Efectos térmicos: no figuran en formulario_mecanica.pdf.
    %   Para agregar algo, Motor.despejar ya sirve: alcanza con escribir
    %   otra función ecXXX y pasársela.
    %
    % A REVISAR — POISSON FUERA DE LA SECCIÓN CIRCULAR
    %   La deformación lateral entra hoy por una sola ecuación del modelo,
    %   epsp == ddia/dia, y eso amarra el cálculo a una sección CIRCULAR.
    %   Con una cuadrada o rectangular no hay 'dia' que pasar y la cuenta
    %   queda a mano: da = epsp*a, db = epsp*b (ver la nota al final de
    %   ecAxial).
    %   Falta una función aparte que tome epsp —o nu y eps— y devuelva el
    %   cambio de CADA dimensión según la geometría, del mismo modo que
    %   MM.seccion resuelve el área para dia, para (a,b) o para A directa.
    %   Ojo al hacerlo: si las dimensiones laterales pasan a ser variables
    %   del sistema, dejan de ser independientes de A, y ahí sí conviene
    %   que el área y la geometría estén atadas por ecuación (hoy no lo
    %   están: axial acepta A y dia que no cierran entre sí y no protesta).
    %   Sin implementar ni depurar todavía.

    methods(Static)

        %% ===================================================================
        %  DEFORMACIÓN AXIAL — nomenclatura común
        %    P      fuerza interna normal a la sección       [N]
        %    A      área de la sección transversal           [m^2]
        %    sig    esfuerzo normal, sigma = P/A             [Pa]
        %    eps    deformación unitaria, epsilon = delta/L  [-]
        %    E      módulo de elasticidad (Young)            [Pa]
        %    L      longitud original sin deformar           [m]
        %    delta  elongación (+) o acortamiento (-) total  [m]
        %    k      rigidez, k = P/delta                     [N/m]
        %    nu     relación de Poisson (nu > 0)             [-]
        %    epsp   deformación unitaria LATERAL, epsilon'   [-]
        %    dia    diámetro original de la sección          [m]
        %    ddia   cambio de diámetro, (-) si se achica     [m]
        %    f      flexibilidad, f = 1/k                    [m/N]
        %    U      energía de deformación de la barra       [J]
        %    u      densidad de energía, U por volumen       [J/m^3]
        %    sigY   esfuerzo de fluencia                     [Pa]
        %    ur     módulo de resiliencia, u en la fluencia  [J/m^3]
        %    tmax   cortante máximo, en el plano a 45°       [Pa]
        %  Ojo con la pareja k y E*A: k es la rigidez de LA BARRA (depende de
        %  L), E*A es la rigidez AXIAL de la sección (no depende de L).
        %  k = E*A/L es la que las une.
        %% ===================================================================

        %% ===================================================================
        %  ecAxial — Declara el modelo de la barra uniforme.
        %  No resuelve nada; solo entrega el sistema y el diccionario de
        %  símbolos para que otras funciones lo usen.
        %
        %  Salidas:
        %    eqs : vector simbólico con las 15 relaciones, sin resolver.
        %    S   : struct-diccionario. S.P es el SÍMBOLO P (no un valor).
        %          Es indispensable devolverlo: cada llamada a sym() crea
        %          objetos nuevos, así que una P declarada afuera NO es la
        %          misma P que está dentro de eqs. Usando S siempre pegan.
        %
        %  POR QUÉ HAY ECUACIONES REDUNDANTES:
        %    delta == P*L/(E*A) sale de las tres primeras, y k == E*A/L sale
        %    de las otras dos. Lo mismo f == L/(E*A) y U == P*delta/2.
        %    Están igual, a propósito, por dos motivos:
        %    1) ENTRADA: Motor.despejar sustituye hacia adelante, así que tener
        %       el mismo dato por varios caminos permite entrar por donde
        %       venga el enunciado (por el esfuerzo, por la carga o por la
        %       rigidez) sin que falte un eslabón intermedio.
        %    2) CONTROL: si los datos no cierran entre sí, despejar aborta
        %       con MM:datosContradictorios en vez de devolver un número
        %       mentiroso.
        %
        %  EJEMPLO DE USO
        %    [eqs, S] = MM.ecAxial();
        %    eqs = subs(eqs, [S.P S.L S.E S.A], [20e3 2 200e9 300e-6]);
        %    double(solve(eqs, S.delta))
        %% ===================================================================
        function [eqs, S] = ecAxial()

            % sym() y NO syms: dentro de un método, syms falla si el nombre
            % choca con una función existente del path. Acá el caso es grave:
            % 'eps' y 'E' son funciones de MATLAB (epsilon de máquina y la
            % exponencial integral). sym('eps') crea el símbolo igual y nunca
            % colisiona.
            nom = {'P','A','sig','eps','E','L','delta','k','nu','epsp', 'dia', 'ddia', ...
                   'f','U','u','sigY','ur','tmax'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            P = S.P; A = S.A; sig = S.sig; eps = S.eps;
            E = S.E; L = S.L; delta = S.delta; k = S.k;
            nu = S.nu; epsp = S.epsp; dia = S.dia; ddia = S.ddia;
            f = S.f; U = S.U; u = S.u; sigY = S.sigY; ur = S.ur; tmax = S.tmax;

            % == (doble igual) en contexto simbólico construye una ECUACIÓN,
            % no una comparación lógica. Con = simple sería una asignación.
            eqs = [ sig   == P/A                % esfuerzo normal
                    eps   == delta/L            % deformación unitaria
                    sig   == E*eps              % ley de Hooke
                    delta == P*L/(E*A)          % barra uniforme (redundante)
                    k     == P/delta            % rigidez de la barra
                    k     == E*A/L              % rigidez axial (redundante)
                    epsp  == -nu*eps            % Poisson (ver abajo)
                    epsp  == ddia/dia           % cambio de diámetro
                    f     == 1/k                % (9) flexibilidad
                    f     == L/(E*A)            % (9) (redundante)
                    U     == P^2*L/(2*E*A)      % (14) energía
                    U     == P*delta/2          % (14) (redundante)
                    u     == sig^2/(2*E)        % (14) densidad de energía
                    ur    == sigY^2/(2*E)       % (14) resiliencia
                    tmax  == sig/2 ];           % (26) cortante a 45°

            % POISSON: epsp == -nu*eps
            %   Lo que la barra se alarga a lo largo, se encoge a lo ancho.
            %   El signo menos es la física, no una convención: con eps > 0
            %   (tracción) sale epsp < 0, o sea la sección se achica. Por eso
            %   nu se tabula POSITIVO y el menos va acá, en la ecuación.
            %   Solo vale en el rango ELÁSTICO y para material ISÓTROPO.
            %
            % DIÁMETRO: epsp == ddia/dia
            %   Es la definición de deformación unitaria otra vez, pero en la
            %   dirección transversal: epsp = (cambio) / (medida original).
            %   Va DIVIDIDA por dia, no multiplicada: epsp es adimensional y
            %   ddia tiene unidades de longitud.
            %   ddia sale NEGATIVO en tracción: es el diámetro que se pierde.
            %   Ojo con dos cosas:
            %   - Vale para sección CIRCULAR. Para una rectangular la misma
            %     cuenta se hace a mano con cada lado: da = epsp*a, db = epsp*b.
            %   - dia y A no están atados por ninguna ecuación (A puede ser
            %     rectangular o dato directo). Si pasás los dos y no cierran,
            %     el sistema no lo detecta. MM.seccion sí lo controla.
            %
            % ENERGÍA: U == P^2*L/(2*E*A) y u == sig^2/(2*E)
            %   La energía ve P al CUADRADO: no distingue tracción de
            %   compresión y U siempre es >= 0. Si entrás por U para sacar P
            %   (o por u para sacar sig) hay dos raíces, +P y -P, y
            %   datosAxial se queda con la POSITIVA. El signo sale del DCL.
            %
            % RESILIENCIA: ur == sigY^2/(2*E)
            %   Es u evaluada justo en la fluencia: la energía máxima por
            %   unidad de volumen que el material devuelve al descargar.
            %   sigY solo entra acá. No controla si sig la supera; eso lo
            %   avisa MM.escalonada.
            %
            % CORTANTE A 45°: tmax == sig/2
            %   Una barra con carga axial también tiene cortante: vale cero
            %   en la sección recta y es máximo en el plano inclinado 45°.
            %   En compresión sale negativo; la magnitud es la misma.
        end

        %% ===================================================================
        %  datosAxial — Atajo sobre el modelo de la barra uniforme.
        %  Los argumentos son los datos, en pares nombre-valor o en un struct:
        %
        %    r = MM.datosAxial('P',20e3, 'L',2, 'E',200e9, 'A',300e-6);
        %    r = MM.datosAxial(d)                 % d = struct(...)
        %    double(r.delta)                      % para número
        %
        %  NO se pide una incógnita: despeja TODO lo que los datos permitan
        %  y elegís del struct. Si el campo que buscás no está, es que los
        %  datos no alcanzaban.
        %
        %  Funciona en cualquier dirección: dado delta despeja P, dado sig
        %  despeja A, dada la rigidez despeja L. No hay "entrada" fija. Eso
        %  es lo que justifica el motor, y es la diferencia con los sisXXX
        %  de sp: el modelo axial es una MALLA de relaciones chicas y
        %  redundantes, donde se entra por cualquier lado.
        %% ===================================================================
        function res = datosAxial(varargin)
            if nargin < 1
                error('MM:parInvalido', ...
                    ['Faltan los datos. Ej: ' ...
                     'MM.datosAxial(''sig'',s, ''E'',E)']);
            end
            % Motor.datos(args, pref) — convierte el varargin en struct.
            %   args : pares nombre-valor {'P',20e3, 'L',2, ...} o {struct}
            %   pref : 'MM', para que los errores salgan como MM:parInvalido
            d = Motor.datos(varargin, 'MM');

            [eqs, S] = MM.ecAxial();

            % Motor.despejar(eqs, S, d, opciones...) — sustitución hacia
            % adelante: despeja todo lo que los datos permitan.
            %   'prefijo'   : 'MM' -> MM:datosContradictorios, MM:campoDesconocido
            %   'positivos' : variables que la física obliga a ser > 0. Solo
            %                 actúa cuando solve devuelve VARIAS raíces:
            %                 descarta las negativas y complejas. Una raíz
            %                 única negativa NO la rechaza.
            %                 P, sig y sigY están por la energía: U, u y ur
            %                 las tienen al cuadrado y dan dos raíces, y se
            %                 toma la de tracción. Un P negativo que entra
            %                 como dato o sale de sig == P/A no se toca.
            res = Motor.despejar(eqs, S, d, 'prefijo','MM', ...
                'positivos',{'A','E','L','dia','P','sig','sigY'});
        end

        %% ===================================================================
        %  axial — Resuelve TODO lo que se pueda de la barra uniforme y lo
        %  devuelve numérico, sin tener que pedir variable por variable.
        %
        %  Acá NO hay incógnita que pasar: son todos datos.
        %    MM.axial('P',20e3, 'L',2, 'E',200e9, 'A',300e-6)
        %    MM.axial(d)                          % d = struct(...)
        %
        %  Salida r (struct) con los campos que quedaron determinados, en
        %  orden fijo: P, A, sig, eps, E, L, delta, k, nu, epsp, dia, ddia,
        %  f, U, u, sigY, ur, tmax.
        %  Lo que no se pudo determinar simplemente NO aparece: mirá los
        %  campos que faltan para saber qué dato te está faltando.
        %% ===================================================================
        function r = axial(varargin)
            d = Motor.datos(varargin, 'MM');

            % Se pasa por datosAxial y no directo a Motor.despejar: así las
            % opciones de despeje ('prefijo', 'positivos') están en UN lugar.
            res = MM.datosAxial(d);

            % Motor.numerico(res, d, orden) — junta datos y despejes.
            %   res   : lo que se DESPEJÓ (no trae lo que entró como dato)
            %   d     : lo que entró como dato
            %   orden : orden de los campos en la salida
            % Baja a double lo que puede; lo que quedó en función de un
            % símbolo libre se deja simbólico.
            r = Motor.numerico(res, d, ...
                {'P','A','sig','eps','E','L','delta','k','nu','epsp','dia','ddia', ...
                 'f','U','u','sigY','ur','tmax'});
        end

        %% ===================================================================
        %  seccion — Área de la sección a partir de la geometría.
        %  Es la pieza que usan escalonada y ahusada para no repetir el
        %  cálculo del área en cada tramo.
        %
        %  DOS FORMAS DE LLAMARLA, la misma cuenta (ver Motor.datos):
        %    MM.seccion('dia', 0.225)              <- pares nombre-valor
        %    MM.seccion(struct('dia', 0.225))      <- struct
        %  La segunda es la que usa escalonada, que le pasa el tramo entero
        %  —un struct que ya trae N, L y E adentro—. Los campos de más se
        %  ignoran.
        %
        %  Se acepta UNA de estas tres geometrías:
        %      A      área directa                        [m^2]
        %      dia    diámetro (sección circular maciza)  [m] -> A = pi*dia^2/4
        %      a, b   lados (sección rectangular)         [m] -> A = a*b
        %  Nombre opcional:
        %      hueco  diámetro INTERIOR, solo con 'dia'   [m]
        %             -> A = pi*(dia^2 - hueco^2)/4  (tubo)
        %
        %  Si das A junto con la geometría, se controla que coincidan y se
        %  aborta si no. Es el chequeo que atrapa el error de unidades:
        %  A = 300 (mm^2) con dia = 0.02 (m) no cierra y salta acá.
        %
        %  EJEMPLOS
        %    MM.seccion('dia', 0.02)                 barra circular maciza
        %    MM.seccion('dia', 0.02, 'hueco', 0.016) tubo
        %    MM.seccion('a', 0.02, 'b', 0.015)       rectangular
        %    MM.seccion('A', 300e-6)                 área ya calculada
        %% ===================================================================
        function A = seccion(varargin)

            % varargin — cell array con TODO lo que se pasó, sin nombres
            % fijos. Es lo que permite aceptar 1, 2, 4 o 6 argumentos con la
            % misma firma. Motor.datos se encarga de interpretarlo; 'MM' es
            % el prefijo de los errores (MM:parInvalido).
            s = Motor.datos(varargin, 'MM');

            tieneDia = isfield(s,'dia') && ~isempty(s.dia);
            tieneAB  = isfield(s,'a') && isfield(s,'b') && ...
                       ~isempty(s.a) && ~isempty(s.b);

            if tieneDia
                di = 0;
                if isfield(s,'hueco') && ~isempty(s.hueco), di = s.hueco; end
                if di >= s.dia
                    error('MM:huecoInvalido', ...
                        'hueco (%g) debe ser menor que dia (%g).', di, s.dia);
                end
                Ag = pi*(s.dia^2 - di^2)/4;
            elseif tieneAB
                Ag = s.a * s.b;
            else
                if ~isfield(s,'A') || isempty(s.A)
                    error('MM:faltaArea', ...
                        'La sección necesita A, o dia, o bien a y b.');
                end
                A = s.A;
                if A <= 0
                    error('MM:geometriaInvalida', 'A debe ser > 0.');
                end
                return
            end

            if isfield(s,'A') && ~isempty(s.A) && ...
                    abs(Ag - s.A) > 1e-9*max(1, abs(Ag))
                error('MM:areaInconsistente', ...
                    ['La geometría da A = %g pero pasaste A = %g. ' ...
                     'Casi siempre es un problema de unidades.'], Ag, s.A);
            end
            A = Ag;
            if A <= 0
                error('MM:geometriaInvalida', 'A debe ser > 0.');
            end
        end

        %% ===================================================================
        %  escalonada — BARRA ESCALONADA. delta = sum( Ni*Li / (Ei*Ai) ).
        %  Es la pieza con la que se resuelve cualquier barra real: si la
        %  carga, el material o la sección cambian, ahí empieza otro tramo.
        %
        %     |===|=====|==|      delta_total = suma de los delta de cada tramo
        %      1    2    3        (con SIGNO: los acortamientos restan)
        %
        %  Entradas:
        %    tramos : struct array O cell array de structs {t1, t2, ...}.
        %             El cell array existe porque concatenar structs con
        %             campos distintos ([a b] con a sin 'dia' y b con 'dia')
        %             es un error de MATLAB. Con llaves no hay que emparejar.
        %             Campos de cada tramo:
        %               N    fuerza interna, + tensión / - compresión  [N]
        %               L    longitud del tramo                        [m]
        %               E    módulo de elasticidad                     [Pa]
        %               A / dia / (a,b)  la sección (ver MM.seccion)
        %             El orden del array ES el orden físico de los tramos:
        %             de eso depende r.acum.
        %    sigY   : esfuerzo de fluencia [Pa] (opcional). Si algún tramo
        %             lo supera, avisa. Sin él no se controla nada.
        %
        %  Salida r (struct):
        %    r.delta   deformación TOTAL de la barra              [m]
        %    r.dt      deformación de cada tramo                  [m]
        %    r.acum    desplazamiento acumulado al FINAL de cada
        %              tramo, respecto del extremo fijo inicial   [m]
        %              -> es lo que responde "cuánto se movió el punto C"
        %    r.sig     esfuerzo de cada tramo                     [Pa]
        %    r.eps     deformación unitaria de cada tramo         [-]
        %    r.k       rigidez E*A/L de cada tramo                [N/m]
        %    r.A       área usada en cada tramo                   [m^2]
        %    r.frac    fracción del delta total que aporta el tramo, en
        %              valor absoluto. Sirve para ver quién manda.
        %    r.fluye   lógico: tramos con |sig| > sigY
        %
        %  N ES LA FUERZA INTERNA, no la carga aplicada. Sale del DCL: cortás
        %  el tramo y sumás todo lo que queda de un lado. Si la barra tiene
        %  una sola carga P en la punta, todos los tramos tienen N = P; con
        %  cargas intermedias, no.
        %% ===================================================================
        function r = escalonada(tramos, sigY)
            if nargin < 2 || isempty(sigY), sigY = []; end

            if iscell(tramos), lista = tramos(:);
            else,              lista = num2cell(tramos(:)); end
            nt = numel(lista);
            if nt == 0
                error('MM:sinTramos', 'La barra no tiene tramos.');
            end

            N = zeros(nt,1); L = zeros(nt,1); E = zeros(nt,1); A = zeros(nt,1);
            for i = 1:nt
                t = lista{i};
                for req = {'N','L','E'}
                    if ~isfield(t, req{1}) || isempty(t.(req{1}))
                        error('MM:faltaDato', ...
                            'Al tramo %d le falta el campo "%s".', i, req{1});
                    end
                end
                A(i) = MM.seccion(t);
                N(i) = t.N;  L(i) = t.L;  E(i) = t.E;
                if L(i) <= 0 || E(i) <= 0
                    error('MM:geometriaInvalida', ...
                        'Tramo %d: L y E deben ser > 0.', i);
                end
            end

            r.dt    = N .* L ./ (E .* A);
            r.delta = sum(r.dt);
            r.acum  = cumsum(r.dt);         % el orden del array es el físico
            r.sig   = N ./ A;
            r.eps   = r.dt ./ L;
            r.k     = E .* A ./ L;
            r.A     = A;

            % En valor absoluto: con tramos de signo opuesto, las fracciones
            % con signo pueden pasarse de 1 y no querrían decir nada.
            suma = sum(abs(r.dt));
            if suma > 0, r.frac = abs(r.dt)/suma; else, r.frac = zeros(nt,1); end

            r.fluye = false(nt,1);
            if ~isempty(sigY)
                r.fluye = abs(r.sig) > sigY;
                if any(r.fluye)
                    warning('MM:fluencia', ...
                        ['Tramo(s) %s con sig = %s Pa, por encima de ' ...
                         'sigY = %g Pa. Este modelo es LINEAL ELÁSTICO ' ...
                         '(delta = N*L/(E*A) solo vale antes del límite de ' ...
                         'proporcionalidad): la deformación real es MAYOR ' ...
                         'que la calculada. Hay que ir al diagrama sig-eps ' ...
                         'a mano.'], mat2str(find(r.fluye)'), ...
                        mat2str(r.sig(r.fluye)', 3), sigY);
                end
            end
        end

        %% ===================================================================
        %  ahusada — BARRA AHUSADA (sección variable).
        %      delta = int( N(x) / (E * A(x)) , x, 0, L )
        %
        %  Entradas:
        %    Nx : fuerza interna. Número (constante) o expresión en x.
        %    Ax : área de la sección. Expresión en x. Si le pasás un número
        %         estás diciendo que es constante, y entonces esto es una
        %         barra uniforme: usá MM.axial, es más barato.
        %    x  : la variable simbólica de integración (syms x).
        %    L  : longitud total (número o símbolo).
        %    E  : módulo de elasticidad (número o expresión en x, si el
        %         material también varía).
        %
        %  Salidas:
        %    delta : resultado de la integral. SIMBÓLICO. Para número:
        %            double(delta) o vpa(delta, 6).
        %    integ : el integrando N/(E*A), por si querés verlo o graficarlo.
        %
        %  EJEMPLO — barra cónica, diámetro de d0 a d1 a lo largo de L:
        %    syms x
        %    dx = d0 + (d1-d0)*x/L;
        %    delta = MM.ahusada(P, pi*dx^2/4, x, L, E);
        %
        %  Si int() no encuentra primitiva devuelve la integral sin evaluar.
        %  En ese caso: double(vpa(delta)) la resuelve numéricamente, o
        %  matlabFunction + integral() si necesitás velocidad.
        %% ===================================================================
        function [delta, integ] = ahusada(Nx, Ax, x, L, E)
            if ~isa(x, 'sym')
                error('MM:xNoSimbolica', ...
                    'x debe ser una variable simbólica: syms x');
            end
            if isnumeric(Ax) && isnumeric(E) && isnumeric(Nx)
                warning('MM:seccionConstante', ...
                    ['N, A y E son constantes: no hay nada que ahusar. ' ...
                     'MM.axial hace lo mismo sin integrar.']);
            end
            integ = Nx / (E * Ax);
            delta = int(integ, x, 0, L);
        end

        %% ===================================================================
        %  ESFUERZO Y DEFORMACIÓN REALES — (3)
        %    P     fuerza axial en el instante de la medición     [N]
        %    Ai    área INSTANTÁNEA, la que queda con estricción  [m^2]
        %    sigt  esfuerzo real (true stress)                    [Pa]
        %    Li    longitud instantánea                           [m]
        %    L0    longitud original                              [m]
        %    epst  deformación real (true strain)                 [-]
        %
        %  La ingenieril divide por A0 y L0 fijos; la real divide por lo que
        %  la probeta mide EN ESE MOMENTO. Se separan de verdad en la
        %  estricción, así que este sistema NO asume régimen elástico.
        %  log de MATLAB es el logaritmo natural (ln del formulario).
        %
        %  EJEMPLO
        %    r = MM.reales('P',30e3, 'Ai',80e-6, 'Li',0.056, 'L0',0.050);
        %    r.sigt, r.epst
        %% ===================================================================
        function [eqs, S] = ecReales()
            % Motor.simbolos(nombres) — struct con un símbolo por nombre,
            % lo mismo que el cell2struct de ecAxial en una línea.
            S = Motor.simbolos({'P','Ai','sigt','epst','Li','L0'});
            P = S.P; Ai = S.Ai; sigt = S.sigt; epst = S.epst; Li = S.Li; L0 = S.L0;

            eqs = [ sigt == P/Ai                % (3)
                    epst == log(Li/L0) ];       % (3)
        end

        function r = reales(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecReales, varargin, {'Ai','Li','L0'});
        end

        %% ===================================================================
        %  CONCENTRACIÓN DE ESFUERZOS — (4)
        %    P      fuerza axial interna                          [N]
        %    Anet   área NETA: la sección menos el orificio o la
        %           muesca, medida donde está la discontinuidad   [m^2]
        %    sprom  esfuerzo promedio sobre el área neta          [Pa]
        %    K      factor de concentración                       [-]
        %    smax   esfuerzo máximo, en el borde del orificio     [Pa]
        %
        %  K se lee de una gráfica según la geometría (r/d, D/d): acá entra
        %  como dato, o sale al revés si conocés smax.
        %  Ojo: cada gráfica dice sobre qué área define el promedio. Este
        %  sistema usa la neta, como el formulario.
        %
        %  EJEMPLO — placa de 40 x 5 mm con un agujero de 10 mm
        %    r = MM.concentracion('P',10e3, 'Anet',(0.040-0.010)*0.005, 'K',2.2);
        %    r.smax
        %% ===================================================================
        function [eqs, S] = ecConcentracion()
            S = Motor.simbolos({'P','Anet','sprom','K','smax'});
            P = S.P; Anet = S.Anet; sprom = S.sprom; K = S.K; smax = S.smax;

            eqs = [ sprom == P/Anet             % (4)
                    smax  == K*sprom            % (4)
                    smax  == K*P/Anet ];        % (4) (redundante)
        end

        function r = concentracion(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecConcentracion, varargin, {'Anet','K'});
        end

        %% ===================================================================
        %  CONSTANTES ELÁSTICAS — (7) y (8)
        %    E           módulo de elasticidad (Young)            [Pa]
        %    G           módulo de rigidez al cortante            [Pa]
        %    nu          relación de Poisson                      [-]
        %    K           módulo volumétrico                       [Pa]
        %    sx, sy, sz  esfuerzos normales en x, y, z            [Pa]
        %    e           dilatación cúbica, cambio de volumen
        %                sobre volumen original                   [-]
        %
        %  Un material ISÓTROPO tiene solo DOS constantes independientes:
        %  con E y otra cualquiera salen las demás, y lo mismo con nu y otra.
        %  La excepción es G con K, sin E ni nu: cada ecuación queda con dos
        %  incógnitas (E y nu) y la sustitución hacia adelante no arranca.
        %
        %  e necesita los TRES esfuerzos. En carga axial pasá sy = 0 y
        %  sz = 0; si falta uno, e no aparece.
        %
        %  EL FORMULARIO USA K PARA DOS COSAS: en (4) es el factor de
        %  concentración y en (8) el módulo volumétrico. Viven en sistemas
        %  separados (MM.ecConcentracion y MM.ecElastica), así que no se pisan.
        %
        %  EJEMPLO
        %    r = MM.elastica('E',200e9, 'nu',0.30);                   r.G, r.K
        %    r = MM.elastica('E',70e9, 'nu',0.33, 'sx',80e6, 'sy',0, 'sz',0);
        %    r.e
        %% ===================================================================
        function [eqs, S] = ecElastica()
            S = Motor.simbolos({'E','G','nu','K','sx','sy','sz','e'});
            E = S.E; G = S.G; nu = S.nu; K = S.K;
            sx = S.sx; sy = S.sy; sz = S.sz; e = S.e;

            eqs = [ G == E/(2*(1 + nu))                 % (7)
                    K == E/(3*(1 - 2*nu))               % (8)
                    e == (1 - 2*nu)/E*(sx + sy + sz) ]; % (8)
        end

        function r = elastica(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecElastica, varargin, {'E','G','K'});
        end

        %% ===================================================================
        %  DEFORMACIÓN POR PESO PROPIO — (13)
        %  Barra uniforme COLGADA de un extremo, sin otra carga. La fuerza
        %  interna crece de 0 en la punta libre a W en el apoyo, así que el
        %  delta es la MITAD del que daría W colgado entero de la punta.
        %    delta  alargamiento total por peso propio            [m]
        %    gam    peso específico, gam = rho*g                  [N/m^3]
        %    rho    densidad                                      [kg/m^3]
        %    g      gravedad. No tiene valor por defecto: depende
        %           del sistema de unidades                       [m/s^2]
        %    L      longitud                                      [m]
        %    E      módulo de elasticidad                         [Pa]
        %    A      área de la sección                            [m^2]
        %    W      peso total de la barra, W = gam*A*L           [N]
        %
        %  delta no depende de A: una barra más gruesa pesa más, pero
        %  también es más rígida en la misma proporción. A solo hace falta
        %  para pasar por W.
        %
        %  EJEMPLO — cable de acero de 300 m colgando
        %    r = MM.pesoPropio('rho',7850, 'g',9.81, 'L',300, 'E',200e9);
        %    r.delta
        %% ===================================================================
        function [eqs, S] = ecPesoPropio()
            S = Motor.simbolos({'delta','gam','rho','g','L','E','A','W'});
            delta = S.delta; gam = S.gam; rho = S.rho; g = S.g;
            L = S.L; E = S.E; A = S.A; W = S.W;

            eqs = [ gam   == rho*g              % (13)
                    W     == gam*A*L            % (13)
                    delta == gam*L^2/(2*E)      % (13)
                    delta == W*L/(2*E*A) ];     % (13) (redundante)
        end

        function r = pesoPropio(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            % L está en positivos: entrando por delta, L sale de L^2.
            r = MM.resolver(@MM.ecPesoPropio, varargin, ...
                {'gam','rho','g','L','E','A','W'});
        end

        %% ===================================================================
        %  BARRA BIEMPOTRADA CON CARGA PUNTUAL — (16)
        %
        %     A |======a======P==========b==========| B      a + b = L
        %
        %    P    carga axial aplicada en el punto intermedio     [N]
        %    a    distancia del empotramiento A a la carga        [m]
        %    b    distancia del empotramiento B a la carga        [m]
        %    L    longitud total                                  [m]
        %    RA   reacción en A                                   [N]
        %    RB   reacción en B                                   [N]
        %
        %  Cada reacción es proporcional a la distancia al OTRO extremo: el
        %  empotramiento más cercano a la carga se lleva la mayor parte.
        %  Vale solo si E*A es el MISMO en toda la barra. Con tramos de
        %  distinto material o sección, usá MM.indeterminada.
        %  Son magnitudes. Si P apunta hacia B, el tramo a queda en tracción
        %  (N = RA) y el tramo b en compresión (N = -RB).
        %
        %  EJEMPLO
        %    r = MM.biempotrada('P',30e3, 'a',0.4, 'L',1.0);   r.RA, r.RB
        %% ===================================================================
        function [eqs, S] = ecBiempotrada()
            S = Motor.simbolos({'P','a','b','L','RA','RB'});
            P = S.P; a = S.a; b = S.b; L = S.L; RA = S.RA; RB = S.RB;

            eqs = [ L  == a + b                 % (16)
                    RA == P*b/L                 % (16)
                    RB == P*a/L                 % (16)
                    P  == RA + RB ];            % equilibrio (control)
        end

        function r = biempotrada(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecBiempotrada, varargin, {'a','b','L'});
        end

        %% ===================================================================
        %  BARRAS EN PARALELO — (17) y (18)
        %  Dos elementos que cargan JUNTOS entre las mismas placas rígidas:
        %  un tubo con un núcleo adentro (cilindros concéntricos), o dos
        %  barras que cuelgan del mismo punto de una viga rígida.
        %    P         carga total que reparten                   [N]
        %    P1, P2    fuerza interna de cada elemento            [N]
        %    E1, E2    módulos de elasticidad                     [Pa]
        %    A1, A2    áreas                                      [m^2]
        %    L1, L2    longitudes                                 [m]
        %    k1, k2    rigideces, ki = Ei*Ai/Li                   [N/m]
        %    delta     deformación COMÚN de los dos               [m]
        %    sig1, sig2  esfuerzo en cada elemento                [Pa]
        %
        %  POR QUÉ ESTÁN k1 Y k2, que el formulario no escribe: (17) son dos
        %  ecuaciones acopladas en P1 y P2. Cada una tiene dos incógnitas y
        %  la sustitución hacia adelante no puede empezar por ninguna.
        %  Resuelto el par a mano:
        %      P1 = P*k1/(k1 + k2),   P2 = P*k2/(k1 + k2)
        %  la carga se reparte en proporción a la RIGIDEZ. Esas dos son
        %  explícitas y destraban el sistema; las de (17) quedan de control.
        %
        %  (18) es el caso L1 = L2. Ahí k1/(k1 + k2) = E1*A1/(E1*A1 + E2*A2)
        %  y sig1 = P1/A1 da exactamente P*E1/(E1*A1 + E2*A2). No se escribe
        %  aparte porque con L1 distinta de L2 sería falsa.
        %
        %  CARGA MÁXIMA con dos permisibles: cada elemento da su propia P.
        %  Pasar sig1 y sig2 juntos aborta por contradicción; son dos
        %  llamadas, y manda la P más chica.
        %
        %  EJEMPLO — núcleo de acero en tubo de aluminio, misma longitud
        %    r = MM.paralelo('P',50e3, 'E1',200e9, 'A1',3e-4, 'L1',0.5, ...
        %                    'E2',70e9,  'A2',6e-4, 'L2',0.5);
        %    r.sig1, r.sig2
        %% ===================================================================
        function [eqs, S] = ecParalelo()
            S = Motor.simbolos({'P','P1','P2','E1','A1','L1','E2','A2','L2', ...
                                'k1','k2','delta','sig1','sig2'});
            P = S.P; P1 = S.P1; P2 = S.P2;
            E1 = S.E1; A1 = S.A1; L1 = S.L1;
            E2 = S.E2; A2 = S.A2; L2 = S.L2;
            k1 = S.k1; k2 = S.k2; delta = S.delta; sig1 = S.sig1; sig2 = S.sig2;

            eqs = [ k1    == E1*A1/L1           % rigidez de cada elemento
                    k2    == E2*A2/L2
                    P1    == P*k1/(k1 + k2)     % (17) resuelto
                    P2    == P*k2/(k1 + k2)     % (17) resuelto
                    P     == P1 + P2            % (17) equilibrio
                    delta == P1*L1/(E1*A1)      % (17) compatibilidad
                    delta == P2*L2/(E2*A2)      % (17) compatibilidad
                    sig1  == P1/A1              % (18) con L1 = L2
                    sig2  == P2/A2 ];           % (18) con L1 = L2
        end

        function r = paralelo(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecParalelo, varargin, ...
                {'E1','A1','L1','E2','A2','L2','k1','k2'});
        end

        %% ===================================================================
        %  indeterminada — BARRA AXIAL HIPERESTÁTICA, por compatibilidad.
        %  Resuelve (15) superposición y (19) desajuste con la misma cuenta.
        %
        %  Los 3 pasos del formulario, y quién hace cada uno:
        %    1. Equilibrio: VOS. Elegís la reacción redundante (syms R) y
        %       escribís la N de cada tramo en función de R y de las cargas.
        %    2. Compatibilidad: acá. La barra entera cambia de largo lo que
        %       le permiten los apoyos:
        %           sum( Ni*Li/(Ei*Ai) ) == desajuste
        %    3. Fuerza-desplazamiento: acá, delta = N*L/(E*A) en cada tramo.
        %  Después reemplaza R en cada N y le pasa la barra a MM.escalonada.
        %
        %  Superposición (15) es la misma ecuación partida en dos: los
        %  términos de sum() que no tienen R son delta_L, los que tienen R
        %  son delta_R.
        %
        %  Entradas:
        %    tramos    : como en MM.escalonada, pero N puede ser una
        %                expresión en R: struct('N', 30e3 - R, 'L',0.4, ...)
        %    R         : la redundante, simbólica (syms R)
        %    desajuste : cambio de longitud TOTAL que la geometría le exige
        %                a la barra [m]. Opcional; 0 por defecto (entre dos
        %                paredes fijas, la barra no cambia de largo).
        %                (+) holgura: hay un espacio y la barra se ESTIRA
        %                    para cerrarlo.
        %                (-) exceso: la barra es más larga que el lugar y
        %                    se ACORTA para entrar.
        %
        %  Salidas:
        %    Rv : valor de la redundante                             [N]
        %    r  : el struct de MM.escalonada con las N ya numéricas: r.sig,
        %         r.dt, r.acum...
        %
        %  OJO CON EL SIGNO DE (19). El formulario escribe
        %      sum(Pi*Li/(Ei*Ai)) + delta_desajuste = 0,   holgura (+)
        %  y con tracción positiva eso queda al revés. Una barra de largo
        %  L + e metida entre paredes a distancia L termina midiendo L: se
        %  acortó e, así que sum(delta) = -e. Con "+ desajuste = 0" ese
        %  exceso necesitaría desajuste = +e, contra la etiqueta (-).
        %  Acá la ecuación es sum(delta) == desajuste, que respeta las
        %  etiquetas del formulario: holgura (+), exceso (-).
        %
        %  EJEMPLO — biempotrada, 30 kN hacia B aplicados a 0.4 m de A
        %    syms R                                   % reacción de B, hacia A
        %    tAC = struct('N', 30e3 - R, 'L',0.4, 'E',200e9, 'A',3e-4);
        %    tCB = struct('N', -R,       'L',0.6, 'E',200e9, 'A',3e-4);
        %    [RB, r] = MM.indeterminada({tAC, tCB}, R);  % 12e3 = P*a/L, (16)
        %% ===================================================================
        function [Rv, r] = indeterminada(tramos, R, desajuste)
            if nargin < 3 || isempty(desajuste), desajuste = 0; end

            % La flexibilidad axial de cada tramo es L/(E*A): multiplicada
            % por N da el delta del tramo.
            flex = @(t) t.L/(t.E*MM.seccion(t));
            [Rv, lista] = MM.redundante(tramos, R, desajuste, {'N','L','E'}, flex);
            r = MM.escalonada(lista);
        end

        %% ===================================================================
        %  ESFUERZO CORTANTE — (20), (21), (24), (25)
        %    F       carga que transmite la unión                 [N]
        %    n       planos de corte: 1 simple, 2 doble           [-]
        %    V       fuerza cortante en CADA plano, V = F/n       [N]
        %    A       área de UN plano de corte                    [m^2]
        %    tau     esfuerzo cortante promedio                   [Pa]
        %    G       módulo de rigidez al cortante                [Pa]
        %    gxy     deformación angular                          [rad]
        %    thetap  ángulo que queda del recto original          [rad]
        %
        %  SIMPLE O DOBLE: contá por cuántas secciones hay que cortar el
        %  perno para que la unión se separe. Dos placas solapadas: 1. Una
        %  horquilla con el perno pasando por las dos orejas: 2. En doble
        %  cada plano lleva la mitad, por eso tau = F/(2A) y no F/A.
        %
        %  gxy positivo: el ángulo recto se CIERRA (thetap < pi/2).
        %  (23) tau_xy = tau_yx: la cara vecina tiene el mismo cortante, no
        %  hace falta otra variable.
        %
        %  EJEMPLO — perno de 12 mm en cortante doble
        %    r = MM.cortante('F',20e3, 'n',2, 'A',pi*0.012^2/4);   r.tau
        %% ===================================================================
        function [eqs, S] = ecCortante()
            S = Motor.simbolos({'F','n','V','A','tau','G','gxy','thetap'});
            F = S.F; n = S.n; V = S.V; A = S.A;
            tau = S.tau; G = S.G; gxy = S.gxy; thetap = S.thetap;

            eqs = [ tau    == V/A               % (20)
                    V      == F/n               % (21) n planos de corte
                    tau    == F/(n*A)           % (21) (redundante)
                    thetap == pi/2 - gxy        % (24)
                    tau    == G*gxy ];          % (25)
        end

        function r = cortante(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecCortante, varargin, {'A','n','G'});
        end

        %% ===================================================================
        %  ESFUERZO DE APOYO (APLASTAMIENTO) — (22)
        %    P     fuerza entre el perno y ESA placa             [N]
        %    t     espesor de la placa                           [m]
        %    d     diámetro del perno                            [m]
        %    Ab    área proyectada, el rectángulo t*d            [m^2]
        %    sigb  esfuerzo de apoyo                             [Pa]
        %
        %  Ab NO es el área del agujero ni la del perno: es la sombra del
        %  perno sobre la placa, un rectángulo de t por d.
        %  En una horquilla, cada oreja recibe F/2 y la placa del medio F:
        %  son dos cuentas, con su t cada una.
        %
        %  EJEMPLO
        %    r = MM.apoyo('P',20e3, 't',0.010, 'd',0.012);   r.sigb
        %% ===================================================================
        function [eqs, S] = ecApoyo()
            S = Motor.simbolos({'P','t','d','Ab','sigb'});
            P = S.P; t = S.t; d = S.d; Ab = S.Ab; sigb = S.sigb;

            eqs = [ sigb == P/Ab                % (22)
                    Ab   == t*d                 % (22)
                    sigb == P/(t*d) ];          % (22) (redundante)
        end

        function r = apoyo(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecApoyo, varargin, {'Ab','t','d'});
        end

        %% ===================================================================
        %  seccionPolar — Momento polar de inercia J, (29) y (30).
        %  Hace para la torsión lo que MM.seccion hace para la carga axial.
        %
        %    MM.seccionPolar('dia', 0.05)                  eje macizo
        %    MM.seccionPolar('dia', 0.05, 'hueco', 0.04)   eje tubular
        %    MM.seccionPolar('J', 6.136e-7)                J ya calculado
        %    MM.seccionPolar(tramo)                        struct con esos campos
        %
        %  Salidas:
        %    J : momento polar de inercia                           [m^4]
        %    c : radio exterior, dia/2. NaN si pasaste J solo: sin el
        %        diámetro no hay tmax = T*c/J                       [m]
        %
        %  Si das J junto con la geometría, controla que coincidan. La
        %  tolerancia es RELATIVA (1e-3, la de Motor.despejar), no la
        %  absoluta de MM.seccion: un eje de 10 mm tiene J = 1e-9 m^4, y con
        %  una tolerancia absoluta de 1e-9 pasaría cualquier valor.
        %% ===================================================================
        function [J, c] = seccionPolar(varargin)
            s = Motor.datos(varargin, 'MM');

            if isfield(s,'dia') && ~isempty(s.dia)
                di = 0;
                if isfield(s,'hueco') && ~isempty(s.hueco), di = s.hueco; end
                if di >= s.dia
                    error('MM:huecoInvalido', ...
                        'hueco (%g) debe ser menor que dia (%g).', di, s.dia);
                end
                Jg = pi*(s.dia^4 - di^4)/32;    % (29) con di = 0; (30) tubo
                c  = s.dia/2;
            else
                if ~isfield(s,'J') || isempty(s.J)
                    error('MM:faltaJ', ...
                        'La sección necesita J, o dia (y hueco si es tubo).');
                end
                J = s.J;
                c = NaN;
                if J <= 0
                    error('MM:geometriaInvalida', 'J debe ser > 0.');
                end
                return
            end

            if isfield(s,'J') && ~isempty(s.J) && abs(Jg - s.J) > 1e-3*abs(Jg)
                error('MM:JInconsistente', ...
                    ['La geometría da J = %g pero pasaste J = %g. ' ...
                     'Casi siempre es un problema de unidades.'], Jg, s.J);
            end
            J = Jg;
        end

        %% ===================================================================
        %  TORSIÓN EN EJE CIRCULAR — (25), (27), (28), (31), (33), (43)
        %    T     par torsor INTERNO del tramo                    [N*m]
        %    J     momento polar de inercia                        [m^4]
        %    c     radio exterior                                  [m]
        %    rho   distancia radial al punto, 0 <= rho <= c        [m]
        %    tau   cortante en rho                                 [Pa]
        %    tmax  cortante máximo, en la superficie (rho = c)     [Pa]
        %    gam   deformación angular en rho                      [rad]
        %    gmax  deformación angular máxima                      [rad]
        %    phi   ángulo de torsión entre los extremos            [rad]
        %    L     longitud                                        [m]
        %    G     módulo de rigidez al cortante                   [Pa]
        %    kT    rigidez torsional, kT = T/phi                   [N*m/rad]
        %    fT    flexibilidad torsional, fT = 1/kT               [rad/(N*m)]
        %    U     energía de deformación                          [J]
        %    u     densidad de energía PROMEDIO. Solo eje macizo   [J/m^3]
        %
        %  J y c van por separado, como en el formulario: en un tubo, c es
        %  el radio EXTERIOR y J lleva los dos diámetros. Sacalos juntos:
        %    [J, c] = MM.seccionPolar('dia',0.05, 'hueco',0.04);
        %
        %  Entrando por U o por u, T y tmax salen POSITIVOS: la energía los
        %  ve al cuadrado (ver la nota de energía en MM.ecAxial).
        %
        %  EJEMPLO
        %    [J, c] = MM.seccionPolar('dia', 0.05);
        %    r = MM.torsion('T',1500, 'J',J, 'c',c, 'L',1.2, 'G',77e9);
        %    r.tmax, rad2deg(r.phi)
        %% ===================================================================
        function [eqs, S] = ecTorsion()
            S = Motor.simbolos({'T','J','c','rho','tau','tmax','gam','gmax', ...
                                'phi','L','G','kT','fT','U','u'});
            T = S.T; J = S.J; c = S.c; rho = S.rho; tau = S.tau; tmax = S.tmax;
            gam = S.gam; gmax = S.gmax; phi = S.phi; L = S.L; G = S.G;
            kT = S.kT; fT = S.fT; U = S.U; u = S.u;

            eqs = [ tau  == T*rho/J             % (28)
                    tmax == T*c/J               % (28)
                    gam  == rho*phi/L           % (27)
                    gmax == c*phi/L             % (27)
                    gam  == rho/c*gmax          % (27) (redundante)
                    tau  == G*gam               % (25)
                    tmax == G*gmax              % (25)
                    phi  == T*L/(J*G)           % (31) uniforme
                    kT   == T/phi               % (33)
                    kT   == J*G/L               % (33) (redundante)
                    fT   == 1/kT                % (33)
                    fT   == L/(J*G)             % (33) (redundante)
                    U    == T^2*L/(2*J*G)       % (43)
                    U    == T*phi/2             % (43) (redundante)
                    u    == tmax^2/(4*G) ];     % (43) promedio, eje macizo
        end

        function r = torsion(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecTorsion, varargin, ...
                {'J','c','L','G','T','tmax'});
        end

        %% ===================================================================
        %  escalonadaT — EJE POR TRAMOS. phi = sum( Ti*Li / (Ji*Gi) ), (31).
        %  La MM.escalonada de la torsión: empieza un tramo nuevo cada vez
        %  que cambia el par, el material o la sección.
        %
        %  Entradas:
        %    tramos : struct array o cell array {t1, t2, ...}. Campos:
        %               T    par torsor interno, con signo       [N*m]
        %               L    longitud del tramo                  [m]
        %               G    módulo de rigidez                   [Pa]
        %               J / dia / (dia, hueco)  la sección (MM.seccionPolar)
        %             El orden del array ES el orden físico de los tramos.
        %
        %  Salida r (struct):
        %    r.phi    ángulo TOTAL entre los extremos             [rad]
        %    r.phit   ángulo de cada tramo                        [rad]
        %    r.acum   giro acumulado al FINAL de cada tramo,
        %             respecto del extremo inicial                [rad]
        %    r.tmax   cortante máximo de cada tramo. NaN si el
        %             tramo trae J sin dia                        [Pa]
        %    r.kT     rigidez J*G/L de cada tramo                 [N*m/rad]
        %    r.J      J usado en cada tramo                       [m^4]
        %
        %  El signo de T lo fija tu convención (mano derecha, vector
        %  saliendo de la sección = +). Con signos mezclados los giros se
        %  restan, igual que los delta en MM.escalonada.
        %% ===================================================================
        function r = escalonadaT(tramos)
            if iscell(tramos), lista = tramos(:);
            else,              lista = num2cell(tramos(:)); end
            nt = numel(lista);
            if nt == 0
                error('MM:sinTramos', 'El eje no tiene tramos.');
            end

            T = zeros(nt,1); L = zeros(nt,1); G = zeros(nt,1);
            J = zeros(nt,1); c = zeros(nt,1);
            for i = 1:nt
                t = lista{i};
                for req = {'T','L','G'}
                    if ~isfield(t, req{1}) || isempty(t.(req{1}))
                        error('MM:faltaDato', ...
                            'Al tramo %d le falta el campo "%s".', i, req{1});
                    end
                end
                [J(i), c(i)] = MM.seccionPolar(t);
                T(i) = t.T;  L(i) = t.L;  G(i) = t.G;
                if L(i) <= 0 || G(i) <= 0
                    error('MM:geometriaInvalida', ...
                        'Tramo %d: L y G deben ser > 0.', i);
                end
            end

            r.phit = T .* L ./ (J .* G);
            r.phi  = sum(r.phit);
            r.acum = cumsum(r.phit);        % el orden del array es el físico
            r.tmax = T .* c ./ J;           % NaN donde c es NaN
            r.kT   = J .* G ./ L;
            r.J    = J;
        end

        %% ===================================================================
        %  ahusadaT — EJE CON SECCIÓN O PAR VARIABLE, (32).
        %      phi = int( T(x) / (J(x) * G) , x, 0, L )
        %  Mismas entradas y salidas que MM.ahusada, cambiando N por T, A
        %  por J y E por G. Para un eje cónico, J(x) = pi*d(x)^4/32.
        %
        %  EJEMPLO — eje cónico de 60 a 30 mm en 1.5 m
        %    syms x
        %    dx  = 0.06 + (0.03 - 0.06)*x/1.5;
        %    phi = MM.ahusadaT(800, pi*dx^4/32, x, 1.5, 77e9);
        %    double(phi)
        %% ===================================================================
        function [phi, integ] = ahusadaT(Tx, Jx, x, L, G)
            if ~isa(x, 'sym')
                error('MM:xNoSimbolica', ...
                    'x debe ser una variable simbólica: syms x');
            end
            integ = Tx / (Jx * G);
            phi   = int(integ, x, 0, L);
        end

        %% ===================================================================
        %  TRANSMISIÓN DE POTENCIA — (34)
        %    Ppot  potencia transmitida                            [W]
        %    T     par torsor en el eje                            [N*m]
        %    w     velocidad angular                               [rad/s]
        %    f     frecuencia de giro                              [Hz]
        %    rpm   velocidad en revoluciones por minuto            [rpm]
        %
        %  rpm es la N del formulario; se llama distinto para no confundirla
        %  con la N de las fuerzas internas. Esta f es frecuencia, no la
        %  flexibilidad f de MM.ecAxial: viven en sistemas separados.
        %  Caballos de fuerza: se convierten al cargar el dato,
        %    'Ppot', 50*745.7      % 50 hp [W]   (1 hp = 550 ft*lb/s)
        %
        %  EJEMPLO
        %    r = MM.potencia('Ppot',10e3, 'rpm',1750);   r.T
        %% ===================================================================
        function [eqs, S] = ecPotencia()
            S = Motor.simbolos({'Ppot','T','w','f','rpm'});
            Ppot = S.Ppot; T = S.T; w = S.w; f = S.f; rpm = S.rpm;

            eqs = [ Ppot == T*w                 % (34)
                    w    == 2*pi*f              % (34)
                    w    == 2*pi*rpm/60         % (34)
                    Ppot == 2*pi*f*T ];         % (34) (redundante)
        end

        function r = potencia(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecPotencia, varargin, {});
        end

        %% ===================================================================
        %  indeterminadaT — EJE HIPERESTÁTICO A TORSIÓN.
        %  Lo mismo que MM.indeterminada, con pares en vez de fuerzas:
        %    1. Equilibrio: VOS. Escribís el T de cada tramo en función del
        %       par redundante (syms TB).
        %    2. Compatibilidad, empotrado-empotrado: acá.
        %           sum( Ti*Li/(Ji*Gi) ) == 0
        %  Después le pasa el eje resuelto a MM.escalonadaT.
        %
        %  Salidas:
        %    Rv : valor del par redundante                          [N*m]
        %    r  : el struct de MM.escalonadaT
        %
        %  EJEMPLO — eje biempotrado, par de 500 N*m a 0.3 m de A, L = 1 m
        %    syms TB
        %    t1 = struct('T', 500 - TB, 'L',0.3, 'G',77e9, 'dia',0.04);
        %    t2 = struct('T', -TB,      'L',0.7, 'G',77e9, 'dia',0.04);
        %    [TB, r] = MM.indeterminadaT({t1, t2}, TB);     % 150 N*m
        %% ===================================================================
        function [Rv, r] = indeterminadaT(tramos, R)
            flex = @(t) t.L/(t.G*MM.seccionPolar(t));
            [Rv, lista] = MM.redundante(tramos, R, 0, {'T','L','G'}, flex);
            r = MM.escalonadaT(lista);
        end

        %% ===================================================================
        %  FACTOR DE SEGURIDAD — (35), (36), (37)
        %    FS      factor de seguridad, > 1                     [-]
        %    Pfalla  carga de falla                               [N]
        %    Pperm   carga permisible                             [N]
        %    sfalla  esfuerzo normal de falla                     [Pa]
        %    sperm   esfuerzo normal permisible                   [Pa]
        %    tfalla  esfuerzo cortante de falla                   [Pa]
        %    tperm   esfuerzo cortante permisible                 [Pa]
        %
        %  (36) y (37) son (35) despejada: sperm = sfalla/FS. Qué va en
        %  sfalla lo decide el material: sigY si es dúctil, sigU si es
        %  frágil. Igual con tfalla.
        %  Los tres cocientes comparten FS. Si el enunciado usa un FS para
        %  normal y otro para cortante, son dos llamadas.
        %
        %  EJEMPLO
        %    r = MM.seguridad('sfalla',250e6, 'FS',1.67);   r.sperm
        %% ===================================================================
        function [eqs, S] = ecSeguridad()
            S = Motor.simbolos({'FS','Pfalla','Pperm','sfalla','sperm', ...
                                'tfalla','tperm'});
            FS = S.FS; Pfalla = S.Pfalla; Pperm = S.Pperm;
            sfalla = S.sfalla; sperm = S.sperm; tfalla = S.tfalla; tperm = S.tperm;

            eqs = [ FS == Pfalla/Pperm          % (35)
                    FS == sfalla/sperm          % (35) y (36)
                    FS == tfalla/tperm ];       % (35) y (37)
        end

        function r = seguridad(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecSeguridad, varargin, {});
        end

        %% ===================================================================
        %  DISEÑO LRFD — (38)
        %    gD, gL  factores de carga muerta y viva, > 1          [-]
        %    PD, PL  cargas de servicio muerta y viva              [N]
        %    Pu      carga factorizada, gD*PD + gL*PL              [N]
        %    fi      factor de reducción de resistencia, < 1       [-]
        %    Pnreq   resistencia nominal MÍNIMA, Pu/fi             [N]
        %
        %  (38) es una DESIGUALDAD: gD*PD + gL*PL <= fi*Pn. El sistema la
        %  resuelve en el límite, así que lo que sale es Pnreq, la Pn más
        %  chica que cumple. El elemento sirve si su Pn >= Pnreq, y esa
        %  comparación es tuya. No pases la Pn real como Pnreq: el sistema
        %  la trata como igualdad y aborta si no coincide.
        %
        %  EJEMPLO
        %    r = MM.lrfd('gD',1.2, 'PD',20e3, 'gL',1.6, 'PL',35e3, 'fi',0.9);
        %    r.Pnreq
        %% ===================================================================
        function [eqs, S] = ecLRFD()
            S = Motor.simbolos({'gD','PD','gL','PL','Pu','fi','Pnreq'});
            gD = S.gD; PD = S.PD; gL = S.gL; PL = S.PL;
            Pu = S.Pu; fi = S.fi; Pnreq = S.Pnreq;

            eqs = [ Pu == gD*PD + gL*PL         % (38) lado de las cargas
                    Pu == fi*Pnreq ];           % (38) en el límite
        end

        function r = lrfd(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MM.resolver(@MM.ecLRFD, varargin, {});
        end

        %% ===================================================================
        %  DIMENSIONAMIENTO — (39) a (42)
        %  Cuánto material hace falta para no pasar el permisible. Son las
        %  fórmulas de esfuerzo al revés, con el permisible (MM.seguridad)
        %  en lugar del esfuerzo calculado.
        %
        %    (39) barra axial
        %      P       carga axial                                 [N]
        %      sperm   esfuerzo normal permisible                  [Pa]
        %      Areq    área mínima                                 [m^2]
        %    (40) perno a cortante
        %      V       cortante en UN plano (en doble, F/2)        [N]
        %      tperm   cortante permisible                         [Pa]
        %      Aperno  área mínima del perno                       [m^2]
        %      dperno  diámetro mínimo del perno                   [m]
        %    (41) apoyo
        %      P       fuerza sobre la placa (la misma P de (39))  [N]
        %      sbperm  esfuerzo de apoyo permisible                [Pa]
        %      td      producto t*d mínimo                         [m^2]
        %    (42) eje macizo a torsión
        %      T       par torsor, en MAGNITUD                     [N*m]
        %      tperm   (la misma de (40))                          [Pa]
        %      Zp      módulo de sección polar mínimo, J/c         [m^3]
        %      c       radio mínimo                                [m]
        %      deje    diámetro mínimo                             [m]
        %
        %  Todo sale en el LÍMITE: son mínimos. Se redondea hacia ARRIBA al
        %  tamaño comercial, nunca hacia abajo.
        %  P y tperm están compartidas. Si el perno y el eje tienen distinto
        %  permisible, son dos llamadas.
        %  T va en magnitud porque con T < 0 la raíz cúbica de (42) sale
        %  compleja.
        %
        %  EJEMPLO
        %    r = MM.diseno('T',1500, 'tperm',60e6);        r.deje
        %    r = MM.diseno('V',10e3, 'tperm',100e6);       r.dperno
        %% ===================================================================
        function [eqs, S] = ecDiseno()
            S = Motor.simbolos({'P','sperm','Areq','V','tperm','Aperno', ...
                                'dperno','sbperm','td','T','Zp','c','deje'});
            P = S.P; sperm = S.sperm; Areq = S.Areq;
            V = S.V; tperm = S.tperm; Aperno = S.Aperno; dperno = S.dperno;
            sbperm = S.sbperm; td = S.td;
            T = S.T; Zp = S.Zp; c = S.c; deje = S.deje;

            eqs = [ Areq   == P/sperm                   % (39)
                    Aperno == V/tperm                   % (40)
                    dperno == sqrt(4*Aperno/pi)         % (40)
                    td     == P/sbperm                  % (41)
                    Zp     == T/tperm                   % (42)
                    c      == (2*T/(pi*tperm))^(1/3)    % (42)
                    Zp     == pi*c^3/2                  % (42) eje macizo
                    Zp     == pi*deje^3/16 ];           % (42) eje macizo
        end

        function r = diseno(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            % Los diámetros salen de cuadrados y cubos: positivos elige la
            % raíz real y positiva.
            r = MM.resolver(@MM.ecDiseno, varargin, ...
                {'sperm','Areq','tperm','Aperno','dperno','sbperm','td', ...
                 'Zp','c','deje'});
        end
    end

    methods(Static, Access = private)

        function r = resolver(ecFun, args, positivos)
            % Lo que hacen todos los atajos, escrito una vez. Es MM.axial
            % en tres pasos:
            %   ecFun     : handle al sistema, @MM.ecTorsion
            %   args      : el varargin del atajo, sin desarmar
            %   positivos : variables que se filtran cuando solve devuelve
            %               varias raíces (ver 'positivos' en MM.datosAxial)
            % Motor.numerico(res, d, S) usa el orden del diccionario S para
            % los campos de la salida.
            d = Motor.datos(args, 'MM');
            [eqs, S] = ecFun();
            res = Motor.despejar(eqs, S, d, 'prefijo','MM', 'positivos',positivos);
            r = Motor.numerico(res, d, S);
        end

        function [Rv, lista] = redundante(tramos, R, objetivo, req, flex)
            % La cuenta común de MM.indeterminada y MM.indeterminadaT.
            %   tramos   : struct array o cell array de tramos
            %   R        : la redundante, simbólica
            %   objetivo : lo que tiene que sumar la compatibilidad [m o rad]
            %   req      : campos obligatorios de cada tramo. El PRIMERO es
            %              la fuerza o el par que depende de R: {'N','L','E'}
            %   flex     : handle con la flexibilidad del tramo, L/(E*A) o
            %              L/(J*G). La compatibilidad es sum(N.*flex).
            % Devuelve R numérica y los tramos con R ya reemplazada.
            if ~isa(R, 'sym')
                error('MM:RNoSimbolica', ...
                    'La redundante debe ser simbólica: syms R');
            end
            if iscell(tramos), lista = tramos(:);
            else,              lista = num2cell(tramos(:)); end
            if isempty(lista)
                error('MM:sinTramos', 'No hay tramos.');
            end

            campo = req{1};
            suma  = sym(0);
            for i = 1:numel(lista)
                t = lista{i};
                for q = req
                    if ~isfield(t, q{1}) || isempty(t.(q{1}))
                        error('MM:faltaDato', ...
                            'Al tramo %d le falta el campo "%s".', i, q{1});
                    end
                end
                suma = suma + t.(campo)*flex(t);
            end

            % Compatibilidad: una ecuación LINEAL en R, una sola raíz.
            sol = solve(suma == objetivo, R);
            try
                Rv = double(sol);
            catch
                Rv = [];
            end
            if ~isscalar(Rv) || ~isfinite(Rv)
                error('MM:sinSolucion', ...
                    ['La compatibilidad no fija %s. Revisá que alguna %s ' ...
                     'dependa de %s y de ningún otro símbolo.'], ...
                    char(R), campo, char(R));
            end

            % sym() primero: un tramo con N numérica no tiene R, y subs
            % sobre un double pelado no está garantizado.
            for i = 1:numel(lista)
                lista{i}.(campo) = double(subs(sym(lista{i}.(campo)), R, Rv));
            end
        end
    end
end
