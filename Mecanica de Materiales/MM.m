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
    % LO QUE NO ESTÁ (todavía)
    %   Efectos térmicos, sistemas indeterminados y factor de seguridad
    %   (secciones 4 y 5 del formulario). El motor MM.despejar ya sirve para
    %   eso: alcanza con escribir otra función ecuacionesXXX y pasársela.

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
        %  Ojo con la pareja k y E*A: k es la rigidez de LA BARRA (depende de
        %  L), E*A es la rigidez AXIAL de la sección (no depende de L).
        %  k = E*A/L es la que las une.
        %% ===================================================================

        %% ===================================================================
        %  ecuacionesAxial — Declara el modelo de la barra uniforme.
        %  No resuelve nada; solo entrega el sistema y el diccionario de
        %  símbolos para que otras funciones lo usen.
        %
        %  Salidas:
        %    eqs : vector simbólico con las 6 relaciones, sin resolver.
        %    S   : struct-diccionario. S.P es el SÍMBOLO P (no un valor).
        %          Es indispensable devolverlo: cada llamada a sym() crea
        %          objetos nuevos, así que una P declarada afuera NO es la
        %          misma P que está dentro de eqs. Usando S siempre pegan.
        %
        %  POR QUÉ HAY ECUACIONES REDUNDANTES:
        %    delta == P*L/(E*A) sale de las tres primeras, y k == E*A/L sale
        %    de las otras dos. Están igual, a propósito, por dos motivos:
        %    1) ENTRADA: MM.despejar sustituye hacia adelante, así que tener
        %       el mismo dato por varios caminos permite entrar por donde
        %       venga el enunciado (por el esfuerzo, por la carga o por la
        %       rigidez) sin que falte un eslabón intermedio.
        %    2) CONTROL: si los datos no cierran entre sí, despejar aborta
        %       con MM:datosContradictorios en vez de devolver un número
        %       mentiroso.
        %
        %  EJEMPLO DE USO
        %    [eqs, S] = MM.ecuacionesAxial();
        %    eqs = subs(eqs, [S.P S.L S.E S.A], [20e3 2 200e9 300e-6]);
        %    double(solve(eqs, S.delta))
        %% ===================================================================
        function [eqs, S] = ecuacionesAxial()

            % sym() y NO syms: dentro de un método, syms falla si el nombre
            % choca con una función existente del path. Acá el caso es grave:
            % 'eps' y 'E' son funciones de MATLAB (epsilon de máquina y la
            % exponencial integral). sym('eps') crea el símbolo igual y nunca
            % colisiona.
            nom = {'P','A','sig','eps','E','L','delta','k'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            P = S.P; A = S.A; sig = S.sig; eps = S.eps;
            E = S.E; L = S.L; delta = S.delta; k = S.k;

            % == (doble igual) en contexto simbólico construye una ECUACIÓN,
            % no una comparación lógica. Con = simple sería una asignación.
            eqs = [ sig   == P/A                % esfuerzo normal
                    eps   == delta/L            % deformación unitaria
                    sig   == E*eps              % ley de Hooke
                    delta == P*L/(E*A)          % barra uniforme (redundante)
                    k     == P/delta            % rigidez de la barra
                    k     == E*A/L ];           % rigidez axial (redundante)
        end

        %% ===================================================================
        %  despejar — MOTOR de despeje. Lo usa datosAxial.
        %
        %  Entradas:
        %    eqs : sistema simbólico (de MM.ecuacionesAxial, ...)
        %    S   : diccionario de símbolos del MISMO sistema
        %    d   : struct con SOLO lo que conocés, en cualquier orden
        %    inc : incógnita. Acepta texto ('P') o el símbolo de S (S.P)
        %
        %  Salidas:
        %    val : expresión simbólica. Para número: double(val) o vpa(val,6).
        %    res : struct con TODAS las variables que quedaron determinadas
        %          de paso. Sale gratis y sirve para verificar el resultado.
        %
        %  POR QUÉ NO ES UN solve(eqs, inc) PELADO:
        %    solve(eqs, inc) exige que TODAS las ecuaciones se satisfagan
        %    eligiendo únicamente inc. Como el sistema tiene varias incógnitas
        %    intermedias (sig, eps, k...), cualquier ecuación que no contenga
        %    inc lo vuelve insatisfacible y solve devuelve VACÍO aunque los
        %    datos alcancen de sobra.
        %    Acá se hace SUSTITUCIÓN HACIA ADELANTE, que es exactamente el
        %    método a mano: se busca una ecuación con una sola incógnita, se
        %    despeja, se propaga el valor, y se repite hasta que no queda nada
        %    por despejar.
        %
        %  ES EL MISMO MOTOR QUE IE.despejar, COPIADO A PROPÓSITO.
        %    MM.m y IE.m viven en carpetas distintas y cada uno tiene que
        %    funcionar solo (se trabaja parado en la carpeta de la materia).
        %    Precio de eso: si acá aparece un bug, hay que arreglarlo en los
        %    dos archivos. No hay una sola fuente de verdad y conviene saberlo.
        %% ===================================================================
        function [val, res] = despejar(eqs, S, d, inc)

            % fieldnames — devuelve los nombres de los campos del struct como
            % CELL ARRAY de texto: {'P'; 'L'; 'E'; ...}. Permite que la
            % función no sepa de antemano qué datos le van a pasar.
            campos = fieldnames(d);

            for k = 1:numel(campos)
                if ~isfield(S, campos{k})
                    error('MM:campoDesconocido', ...
                        ['"%s" no es una variable del modelo. ' ...
                         'Válidas: %s'], campos{k}, strjoin(fieldnames(S)', ', '));
                end
                % campos{k}  -> LLAVES porque es cell array; da el texto 'P'.
                % S.(...)    -> acceso DINÁMICO a campo. S.P exige saber el
                %               nombre al escribir el código; S.('P') acepta
                %               el nombre como variable en ejecución.
                %               S.(campos{k}) = el SÍMBOLO
                %               d.(campos{k}) = el VALOR
                % subs(eqs, simbolo, valor) reemplaza en TODAS las ecuaciones
                % de una vez. El loop es necesario: subs no recorre structs.
                eqs = subs(eqs, S.(campos{k}), d.(campos{k}));
            end

            % ischar   -> texto con comillas simples: 'P'
            % isstring -> texto con comillas dobles:  "P"  (otro tipo)
            % char()   -> normaliza a comillas simples; el acceso dinámico
            %             de campos SOLO acepta char, no string.
            % Traducir por S y no por str2sym es crítico: str2sym('P') crearía
            % una P nueva, ajena a eqs, y solve devolvería vacío sin avisar.
            if ischar(inc) || isstring(inc)
                if ~isfield(S, char(inc))
                    error('MM:campoDesconocido', ...
                        ['"%s" no es una variable del modelo. ' ...
                         'Válidas: %s'], char(inc), strjoin(fieldnames(S)', ', '));
                end
                inc = S.(char(inc));
            end
            nombreInc = char(inc);

            % --- sustitución hacia adelante -------------------------------
            res    = struct();
            cambio = true;
            while cambio
                cambio = false;
                for k = 1:numel(eqs)
                    libres = symvar(eqs(k));

                    % Sin incógnitas libres, la ecuación ya es un veredicto.
                    % OJO: subs NO la colapsa a symfalse, la deja como
                    % "999 == 100", así que hay que preguntarle a isAlways en
                    % vez de comparar con sym(false).
                    if isempty(libres)
                        if ~isAlways(eqs(k), 'Unknown', 'false')
                            error('MM:datosContradictorios', ...
                                ['Los datos violan la ecuación %d del ' ...
                                 'modelo: %s'], k, char(eqs(k)));
                        end
                        continue
                    end
                    if numel(libres) ~= 1, continue; end

                    s = solve(eqs(k), libres);
                    if isempty(s), continue; end
                    if numel(s) > 1
                        warning('MM:variasSoluciones', ...
                            '%s tiene %d soluciones; se toma la primera.', ...
                            char(libres), numel(s));
                    end
                    res.(char(libres)) = s(1);
                    eqs    = subs(eqs, libres, s(1));   % propaga a todas
                    cambio = true;
                end
            end

            if isfield(res, nombreInc)
                val = res.(nombreInc);   % sin double(): se mantiene simbólico
                return
            end

            % Si no se determinó, todavía puede quedar una relación útil
            % (ej. delta en función de P). Se devuelve eso.
            val = solve(eqs, inc);
            if isempty(val)
                warning('MM:sinSolucion', ...
                    ['No se puede despejar %s con esos datos. ' ...
                     'Determinadas hasta ahora: %s'], nombreInc, ...
                    strjoin([{'(ninguna)'}, fieldnames(res)'], ', '));
            end
        end

        %% ===================================================================
        %  datosAxial — Atajo sobre el modelo de la barra uniforme.
        %    d   : struct con lo conocido, en cualquier orden. Ej:
        %          struct('P',20e3,'L',2,'E',200e9,'A',300e-6)
        %    inc : incógnita, texto ('delta') o símbolo (S.delta)
        %  Ej: double(MM.datosAxial(d, 'delta'))
        %
        %  Funciona en cualquier dirección: dado delta despeja P, dado sig
        %  despeja A, dada la rigidez despeja L. No hay "entrada" fija.
        %% ===================================================================
        function [val, res] = datosAxial(d, inc)
            [eqs, S] = MM.ecuacionesAxial();
            [val, res] = MM.despejar(eqs, S, d, inc);
        end

        %% ===================================================================
        %  axial — Resuelve TODO lo que se pueda de la barra uniforme y lo
        %  devuelve numérico, sin tener que pedir variable por variable.
        %
        %    d : struct con lo conocido. Ej:
        %        MM.axial(struct('P',20e3,'L',2,'E',200e9,'A',300e-6))
        %
        %  Salida r (struct) con los campos que quedaron determinados, en
        %  orden fijo: P, A, sig, eps, E, L, delta, k.
        %  Lo que no se pudo determinar simplemente NO aparece: mirá los
        %  campos que faltan para saber qué dato te está faltando.
        %% ===================================================================
        function r = axial(d)
            [eqs, S] = MM.ecuacionesAxial();

            % La incógnita es de mentira: acá interesa 'res', no 'val'. Si
            % 'delta' no se puede determinar, despejar avisa — se calla ese
            % aviso concreto porque no es un error: los campos que falten en
            % la salida ya cuentan la misma historia.
            w = warning('off', 'MM:sinSolucion');
            limpiar = onCleanup(@() warning(w));   %#ok<NASGU> restaura al salir
            [~, res] = MM.despejar(eqs, S, d, 'delta');

            % Lo que entró como dato también va a la salida: res solo trae lo
            % que se DESPEJÓ, no lo que se dio.
            orden = {'P','A','sig','eps','E','L','delta','k'};
            r = struct();
            for i = 1:numel(orden)
                ni = orden{i};
                if isfield(d, ni)
                    r.(ni) = d.(ni);
                elseif isfield(res, ni)
                    v = res.(ni);
                    % double() falla si quedó en función de un símbolo libre;
                    % en ese caso se deja la expresión simbólica tal cual.
                    try, v = double(v); catch, end %#ok<NOCOM>
                    r.(ni) = v;
                end
            end
        end

        %% ===================================================================
        %  seccion — Área de la sección a partir de la geometría.
        %  Es la pieza que usan escalonada y ahusada para no repetir el
        %  cálculo del área en cada tramo.
        %
        %  s : struct de sección. Se acepta UNA de estas tres formas:
        %      A      área directa                        [m^2]
        %      dia    diámetro (sección circular maciza)  [m] -> A = pi*dia^2/4
        %      a, b   lados (sección rectangular)         [m] -> A = a*b
        %  Campo opcional:
        %      hueco  diámetro INTERIOR, solo con 'dia'   [m]
        %             -> A = pi*(dia^2 - hueco^2)/4  (tubo)
        %
        %  Si das A junto con la geometría, se controla que coincidan y se
        %  aborta si no. Es el chequeo que atrapa el error de unidades:
        %  A = 300 (mm^2) con dia = 0.02 (m) no cierra y salta acá.
        %% ===================================================================
        function A = seccion(s)
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
