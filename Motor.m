classdef Motor
    % =========================================================================
    % Motor.m - Motor compartido de despeje simbolico.
    %
    % Es la parte que NO es fisica: traduce los datos, resuelve un sistema de
    % ecuaciones en la direccion que los datos permitan, y controla que los
    % datos cierren entre si. Lo usan VM, sp, IE, FV y MM. Cada clase sigue
    % siendo duena de sus sistemas (ecXxx / sisXxx); lo unico que comparten
    % es esto.
    %
    % USO DESDE UNA CLASE (patron de tres capas):
    %   1. Sistema:  [eqs, S] = FV.ecRel()          declara simbolos y ecuaciones
    %   2. Motor:    res = Motor.despejar(eqs, S, d) resuelve lo que se pueda
    %   3. Atajo:    FV.rel('v',..., 'mo',...)       = datos + sistema + motor
    %
    % INSTALACION: la raiz del repo tiene que estar en el path. Correr una
    % vez setup.m, que esta al lado de este archivo.
    %
    % FUNCIONES:
    %   Motor.simbolos(nom)             diccionario de simbolos desde nombres
    %   Motor.datos(args, pref)         pares nombre-valor o struct -> struct
    %   Motor.despejar(eqs, S, d, ...)  sustitucion hacia adelante
    %   Motor.numerico(res, d, orden)   junta datos y despejes en un struct double
    %   Motor.probar(ecFun, dFull, ...) test de ida y vuelta sobre un sistema
    %
    % OPCIONES DE despejar (pares nombre-valor despues de d):
    %   'prefijo'   texto para los identificadores de error: 'VM', 'sp', ...
    %               Por defecto 'Motor'. Asi VM.subA sigue tirando
    %               VM:datosContradictorios y los try/catch viejos siguen
    %               andando.
    %   'libres'    cell de nombres de S que se dejan como PARAMETROS. No se
    %               despejan ni cuentan como incognita. Ejemplo: {'t'} en
    %               VM.ecSubA deja x == f(t) resuelto como expresion en t.
    %   'positivos' cell de nombres de S que son positivos por fisica (v, m,
    %               n, wn...). Cuando solve devuelve varias raices, se
    %               descartan las negativas y complejas antes de elegir.
    %   'tol'       tolerancia RELATIVA del control de contradiccion. Por
    %               defecto 1e-3: absorbe el redondeo de un enunciado
    %               (c = 4472 contra ccr = 4472.1359 pasa) y atrapa un error
    %               de signo (x2) o de unidades (x1e6).
    % =========================================================================

    methods(Static)

        function S = simbolos(nom)
            % DICCIONARIO DE SIMBOLOS a partir de una lista de nombres.
            %   S = Motor.simbolos({'m','k','wn'});   S.wn es el SIMBOLO wn
            % sym() y NO syms: dentro de un metodo, syms falla si el nombre
            % choca con una funcion del path ('eps', 'E', 'P', 'Q').
            % Hay que devolver S y usar S.x en las ecuaciones: cada sym()
            % crea un objeto nuevo, y una wn declarada afuera NO es la que
            % esta adentro de eqs.
            nom = cellstr(string(nom(:)));
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false), nom, 1);
        end

        function s = datos(args, pref)
            % ARGUMENTOS DE ENTRADA -> STRUCT DE DATOS.
            %   args : el varargin de quien llama. Se acepta
            %          {structDeDatos}  o  {'nombre',valor, 'nombre',valor, ...}
            %   pref : prefijo del identificador de error (opcional, 'Motor')
            % Los pares nombre-valor son la convencion de MATLAB
            % (plot('LineWidth',1.5) es exactamente esto). El struct se acepta
            % porque a veces el dato YA es un struct.
            if nargin < 2, pref = 'Motor'; end
            n = numel(args);

            if n == 1 && isstruct(args{1})
                s = args{1};
                return
            end
            if n == 0 || mod(n,2) ~= 0
                error([pref ':parInvalido'], ...
                    ['Se esperaban pares nombre-valor (cantidad par de ' ...
                    'argumentos) o un struct. Llegaron %d.'], n);
            end

            % Impares = nombres, pares = valores. 1:2:end recorre 1,3,5...
            % Se indexa con () y no con {}: el resultado sigue siendo cell.
            nombres = args(1:2:end);
            valores = args(2:2:end);

            if ~all(cellfun(@(c) ischar(c) || isstring(c), nombres))
                error([pref ':parInvalido'], ...
                    ['Los argumentos impares tienen que ser nombres. ' ...
                    'Ej: VM.subA(''m'',1, ''k'',100, ''c'',2)']);
            end

            % cellstr(string(...)) normaliza "m" (comillas dobles) y 'm'
            % (simples) al mismo tipo.
            s = cell2struct(valores(:), cellstr(string(nombres(:))), 1);
        end

        function res = despejar(eqs, S, d, varargin)
            % SUSTITUCION HACIA ADELANTE. Es el metodo a mano: se busca una
            % ecuacion con UNA sola incognita, se despeja, se propaga el valor
            % a las demas, y se repite hasta que no queda nada por despejar.
            %
            % ENTRADAS:
            %   eqs : vector simbolico de ecuaciones (de un ecXxx / sisXxx)
            %   S   : diccionario de simbolos del MISMO sistema
            %   d   : struct con SOLO lo que conoces, en cualquier orden.
            %         Los valores pueden ser numeros o expresiones simbolicas
            %         en simbolos AJENOS al sistema (t2 = w*t): esos simbolos
            %         pasan de largo como parametros.
            %   ... : opciones, ver la cabecera de la clase
            % SALIDA:
            %   res : struct con TODAS las variables que quedaron determinadas.
            %         Para numero: double(res.wd). Si un campo no esta, los
            %         datos no alcanzaron: ese es el diagnostico.
            %
            % POR QUE NO ES UN solve() PELADO: solve(eqs, x) exige que TODAS
            % las ecuaciones se satisfagan eligiendo unicamente x. Con
            % incognitas intermedias (wn, ccr, z...), cualquier ecuacion que
            % no contenga x lo vuelve insatisfacible y devuelve VACIO aunque
            % los datos alcancen de sobra.
            %
            % QUE CUENTA COMO INCOGNITA: un simbolo del diccionario S que no
            % vino en d, no esta en 'libres' y todavia no se despejo. Los
            % simbolos que no estan en S (el w y el t de t2 = w*t) no cuentan:
            % son parametros y la solucion sale en funcion de ellos.
            %
            % CAMINO RAPIDO: casi todas las ecuaciones tienen la forma
            % simbolo == expresion. Si la unica incognita es ese simbolo, el
            % resultado es la expresion y no hace falta llamar a solve, que
            % es lo caro. solve solo se llama cuando la incognita esta
            % adentro de la expresion (despejar v de gam == 1/sqrt(1-v^2/c^2)).
            %
            % CONTROL: una ecuacion que se queda sin incognitas es un
            % veredicto sobre los datos. Se evalua |lhs - rhs| contra 'tol'
            % relativa y, si no cierra, aborta con <prefijo>:datosContradictorios
            % en vez de devolver un numero mentiroso. Por eso conviene dejar
            % ecuaciones redundantes en los sistemas: la que sobra controla.

            opt = Motor.opciones(varargin);
            pref = opt.prefijo;

            nomS   = fieldnames(S);
            campos = fieldnames(d);

            for k = 1:numel(campos)
                if ~isfield(S, campos{k})
                    error([pref ':campoDesconocido'], ...
                        ['"%s" no es una variable de este modelo. ' ...
                        'Validas: %s'], campos{k}, strjoin(nomS', ', '));
                end
            end
            for k = 1:numel(opt.libres)
                if ~isfield(S, opt.libres{k})
                    error([pref ':campoDesconocido'], ...
                        '"%s" (libres) no es una variable de este modelo.', ...
                        opt.libres{k});
                end
            end

            % Todos los datos entran en UNA sola llamada a subs. S.(c) es el
            % SIMBOLO y d.(c) es el VALOR.
            if ~isempty(campos)
                viejos = cellfun(@(c) S.(c), campos, 'UniformOutput', false);
                nuevos = cellfun(@(c) d.(c), campos, 'UniformOutput', false);
                eqs = subs(eqs, viejos, nuevos);
            end

            % pendientes: lo que falta determinar. Sale de S, no de symvar.
            pendientes = setdiff(nomS, [campos; opt.libres(:)]);

            res        = struct();
            verificada = false(size(eqs));   % control hecho una sola vez
            cambio     = true;
            while cambio
                cambio = false;
                for k = 1:numel(eqs)
                    if verificada(k), continue; end

                    libresK = arrayfun(@char, symvar(eqs(k)), ...
                        'UniformOutput', false);
                    inc = intersect(libresK, pendientes);

                    if isempty(inc)
                        Motor.controlar(eqs(k), k, opt);
                        verificada(k) = true;
                        continue
                    end
                    if numel(inc) ~= 1, continue; end

                    nombre = inc{1};
                    sol = Motor.aislar(eqs(k), S.(nombre), nombre, opt);
                    if isempty(sol), continue; end

                    res.(nombre) = sol;
                    eqs          = subs(eqs, S.(nombre), sol);   % propaga a todas
                    pendientes   = setdiff(pendientes, nombre);
                    verificada(k) = true;   % esta ecuacion ya dio lo suyo
                    cambio = true;
                end
            end
        end

        function r = numerico(res, d, orden)
            % JUNTA DATOS Y DESPEJES en un solo struct, en orden fijo y en
            % double donde se pueda. res solo trae lo que se DESPEJO; lo que
            % entro como dato esta en d. Este struct trae las dos cosas.
            %   orden : cell de nombres, o el propio diccionario S (se usa
            %           el orden de sus campos)
            % Un campo que quedo en funcion de un parametro libre no se puede
            % bajar a double: se deja simbolico tal cual.
            if isstruct(orden), orden = fieldnames(orden); end
            r = struct();
            for i = 1:numel(orden)
                ni = orden{i};
                if isfield(d, ni)
                    r.(ni) = d.(ni);
                elseif isfield(res, ni)
                    v = res.(ni);
                    try, v = double(v); catch, end %#ok<NOCOM>
                    r.(ni) = v;
                end
            end
        end

        function [ok, T] = probar(ecFun, dFull, varargin)
            % TEST DE IDA Y VUELTA sobre un sistema. Con un juego de datos
            % COMPLETO y consistente, quita una variable por vez y verifica
            % que despejar la recupera. Reemplaza los "probado: se traba en
            % la direccion contraria" por una verificacion que corre sola.
            %
            % ENTRADAS:
            %   ecFun : handle al sistema, @FV.ecRel
            %   dFull : struct con TODAS las variables del sistema, numericas
            %           y consistentes entre si (sacalas de una corrida
            %           directa con Motor.numerico)
            %   ...   : las mismas opciones de despejar
            % SALIDAS:
            %   ok : logico, true si TODAS las variables se recuperan
            %   T  : tabla con una fila por variable: si se recupero, el
            %        valor esperado, el obtenido y el error relativo
            %
            % Una variable que NO se recupera no siempre es un bug: puede ser
            % que las ecuaciones no permitan esa direccion (los sistemas en
            % cadena de sp). La tabla dice cual; vos decidis si importa.
            %
            %   [ok, T] = Motor.probar(@MM.ecAxial, dFull, 'prefijo','MM');
            %   disp(T)

            opt = Motor.opciones(varargin);
            [eqs, S] = ecFun();
            nom = fieldnames(dFull);
            n   = numel(nom);

            % Paso 0: los datos completos tienen que cerrar entre si. Si no,
            % el juego de datos esta mal y el resto del test no dice nada.
            Motor.despejar(eqs, S, dFull, varargin{:});

            recuperada = false(n,1);
            esperado   = nan(n,1);
            obtenido   = nan(n,1);
            errRel     = nan(n,1);
            nota       = strings(n,1);

            for i = 1:n
                d = rmfield(dFull, nom{i});
                esperado(i) = double(dFull.(nom{i}));
                try
                    res = Motor.despejar(eqs, S, d, varargin{:});
                catch ME
                    nota(i) = string(ME.identifier);
                    continue
                end
                if ~isfield(res, nom{i})
                    nota(i) = "no determinada";
                    continue
                end
                try
                    obtenido(i) = double(res.(nom{i}));
                catch
                    nota(i) = "quedo simbolica";
                    continue
                end
                escala = max(abs(esperado(i)), realmin);
                errRel(i) = abs(obtenido(i) - esperado(i))/escala;
                recuperada(i) = errRel(i) <= opt.tol;
                if ~recuperada(i), nota(i) = "valor distinto"; end
            end

            ok = all(recuperada);
            T  = table(string(nom), recuperada, esperado, obtenido, errRel, nota, ...
                'VariableNames', {'variable','recuperada','esperado', ...
                'obtenido','errRel','nota'});
        end
    end

    methods(Static, Access = private)

        function opt = opciones(args)
            % Valores por defecto y parseo de las opciones de despejar.
            opt = struct('prefijo','Motor', 'libres',{{}}, 'positivos',{{}}, ...
                'tol',1e-3);
            if mod(numel(args), 2) ~= 0
                error('Motor:opcionInvalida', ...
                    'Las opciones van en pares nombre-valor.');
            end
            for k = 1:2:numel(args)
                nombre = char(args{k});
                if ~isfield(opt, nombre)
                    error('Motor:opcionInvalida', ...
                        '"%s" no es una opcion. Validas: %s', nombre, ...
                        strjoin(fieldnames(opt)', ', '));
                end
                opt.(nombre) = args{k+1};
            end
            opt.libres    = cellstr(string(opt.libres));
            opt.positivos = cellstr(string(opt.positivos));
            opt.prefijo   = char(opt.prefijo);
        end

        function sol = aislar(ek, x, nombre, opt)
            % Despeja x de la ecuacion ek. Camino rapido si ek ya es
            % x == expresion (o expresion == x); solve solo si hace falta.
            %
            % TODO POR STRING Y symvar, NADA DE isequal/has(). has(r,x)
            % prueba "r == subs(r,x,otro)" para decidir si x aparece en r, y
            % con expresiones grandes (piecewise con abs y radicales en
            % w*t, como las de sp.sisL4V con t2 simbolico) MATLAB no puede
            % DEMOSTRAR esa igualdad y sym/logical aborta en vez de asumir
            % que no. Probado: pasa exactamente eso en sp.datosSis('L4V',
            % ..., 't2',w*t). symvar es estructural (lista los simbolos, no
            % prueba nada) y char() de un simbolo pelado es su nombre: la
            % comparacion de strings no evalua ninguna igualdad simbolica.
            l = lhs(ek);
            r = rhs(ek);
            nx = char(x);
            if strcmp(char(l), nx) && ~Motor.contiene(r, nx), sol = r; return; end
            if strcmp(char(r), nx) && ~Motor.contiene(l, nx), sol = l; return; end

            sol = solve(ek, x);
            if isempty(sol), return; end
            if numel(sol) > 1 && ismember(nombre, opt.positivos)
                sol = Motor.soloPositivas(sol);
                if isempty(sol)
                    warning([opt.prefijo ':sinRaizPositiva'], ...
                        ['%s esta declarada positiva y ninguna raiz lo es. ' ...
                        'Se deja sin despejar.'], nombre);
                    return
                end
            end
            if numel(sol) > 1
                % Varias raices y ninguna regla para elegir: se toma la
                % primera y se avisa. Pasa con los radicales y los cuadrados
                % (v en gamma, n en Bohr) cuando entras al reves.
                warning([opt.prefijo ':variasSoluciones'], ...
                    '%s tiene %d soluciones; se toma la primera.', ...
                    nombre, numel(sol));
            end
            sol = sol(1);
        end

        function tf = contiene(expr, nombreX)
            % Si el simbolo de nombre nombreX aparece en expr. symvar lista
            % los simbolos libres sin probar nada; ver la nota larga en
            % Motor.aislar sobre por que NO se usa has().
            nombres = arrayfun(@char, symvar(expr), 'UniformOutput', false);
            tf = ismember(nombreX, nombres);
        end

        function sol = soloPositivas(sol)
            % Filtra raices reales y positivas. Una raiz que no se puede
            % evaluar (depende de un parametro) se conserva.
            keep = true(size(sol));
            for i = 1:numel(sol)
                try
                    v = double(sol(i));
                    keep(i) = isreal(v) && v > 0;
                catch
                    keep(i) = true;
                end
            end
            sol = sol(keep);
        end

        function controlar(ek, k, opt)
            % Una ecuacion sin incognitas es un veredicto sobre los datos.
            % subs NO la colapsa siempre: puede quedar como "999 == 100".
            % Se compara con tolerancia RELATIVA, no exacta: asi el pi doble,
            % las constantes redondeadas del formulario y el c = 4472 de un
            % enunciado no abortan sobre datos perfectamente buenos.
            pref = opt.prefijo;
            try
                l = lhs(ek);
                r = rhs(ek);
            catch
                % Ya colapso a symtrue / symfalse.
                if ~isAlways(ek, 'Unknown', 'false')
                    error([pref ':datosContradictorios'], ...
                        'Los datos violan la ecuacion %d del modelo.', k);
                end
                return
            end
            try
                ln = double(l);
                rn = double(r);
            catch
                % Quedan parametros libres (t, w): control simbolico. Si el
                % motor no puede demostrarla, avisa y sigue: con parametros
                % una identidad puede ser cierta y no demostrable.
                try
                    cierra = isAlways(simplify(l - r) == 0, 'Unknown', 'false');
                catch
                    cierra = false;
                end
                if ~cierra
                    warning([pref ':controlSimbolico'], ...
                        'La ecuacion %d no se pudo verificar: %s', k, char(ek));
                end
                return
            end
            escala = max(abs(ln), abs(rn));
            if escala == 0, return; end          % 0 == 0
            dif = abs(ln - rn)/escala;
            if dif > opt.tol
                error([pref ':datosContradictorios'], ...
                    ['Los datos violan la ecuacion %d del modelo: %s ' ...
                    '(diferencia relativa %.2g)'], k, char(ek), dif);
            end
        end
    end
end
