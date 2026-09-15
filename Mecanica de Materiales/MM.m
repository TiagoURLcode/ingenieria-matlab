classdef MM
    % MM — Caja de herramientas de Mecánica de Materiales I.
    %      Todos los métodos son estáticos: se llaman MM.nombre(...).
    %      Alcance de esta versión: DEFORMACIÓN AXIAL ELÁSTICA
    %      (secciones 1, 2 y 3 del formulario del parcial).
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
    %     Vale solo mientras sig < límite de proporcionalidad.
    %
    % MOTOR DE DESPEJE
    %   El que resuelve es Motor.despejar (Motor.m, en la raíz del repo): es
    %   el mismo motor que usan VM, FV, IE y sp, no una copia. Para que MATLAB
    %   lo encuentre parado en esta carpeta, correr UNA vez setup.m (raíz).
    %
    % LO QUE NO ESTÁ (todavía)
    %   Efectos térmicos, sistemas indeterminados y factor de seguridad
    %   (secciones 4 y 5 del formulario). Motor.despejar ya sirve para eso:
    %   alcanza con escribir otra función ecXXX y pasársela.
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
        %    eqs : vector simbólico con las 8 relaciones, sin resolver.
        %    S   : struct-diccionario. S.P es el SÍMBOLO P (no un valor).
        %          Es indispensable devolverlo: cada llamada a sym() crea
        %          objetos nuevos, así que una P declarada afuera NO es la
        %          misma P que está dentro de eqs. Usando S siempre pegan.
        %
        %  POR QUÉ HAY ECUACIONES REDUNDANTES:
        %    delta == P*L/(E*A) sale de las tres primeras, y k == E*A/L sale
        %    de las otras dos. Están igual, a propósito, por dos motivos:
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
            nom = {'P','A','sig','eps','E','L','delta','k','nu','epsp', 'dia', 'ddia'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            P = S.P; A = S.A; sig = S.sig; eps = S.eps;
            E = S.E; L = S.L; delta = S.delta; k = S.k;
            nu = S.nu; epsp = S.epsp; dia = S.dia; ddia = S.ddia;

            % == (doble igual) en contexto simbólico construye una ECUACIÓN,
            % no una comparación lógica. Con = simple sería una asignación.
            eqs = [ sig   == P/A                % esfuerzo normal
                    eps   == delta/L            % deformación unitaria
                    sig   == E*eps              % ley de Hooke
                    delta == P*L/(E*A)          % barra uniforme (redundante)
                    k     == P/delta            % rigidez de la barra
                    k     == E*A/L              % rigidez axial (redundante)
                    epsp  == -nu*eps            % Poisson (ver abajo)
                    epsp  == ddia/dia ];        % cambio de diámetro

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
            res = Motor.despejar(eqs, S, d, 'prefijo','MM', ...
                'positivos',{'A','E','L','dia'});
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
        %  orden fijo: P, A, sig, eps, E, L, delta, k, nu, epsp, dia, ddia.
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
                {'P','A','sig','eps','E','L','delta','k','nu','epsp','dia','ddia'});
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
    end
end
