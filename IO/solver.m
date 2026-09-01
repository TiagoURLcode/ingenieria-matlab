function sol = solver(c, A, b, sentido, tipo, varargin)
%SOLVER  Optimizador de Programación Lineal, equivalente al Solver de Excel.
%
%   sol = solver(c, A, b, sentido, tipo)
%   sol = solver(c, A, b, sentido, tipo, 'Opcion', valor, ...)
%
%  Es el hermano de n variables de IO.pl2var: pl2var resuelve GRÁFICAMENTE y
%  solo con 2 variables; solver resuelve con las variables que sean, por el
%  método SIMPLEX, y además da holguras, precios sombra y costos reducidos
%  (el "informe de sensibilidad" de Excel). No usa ningún toolbox: el simplex
%  de dos fases y la ramificación para variables enteras están acá adentro.
%
%  DÓNDE VIVE
%    solver.m está en la raíz de MATLAB (la userpath), que es la PRIMERA
%    carpeta del path. Se llama desde cualquier materia sin agregar nada al
%    path y sin copiar el archivo. Su suite de pruebas es testSolver.m, al
%    lado. El ejemplo resuelto paso a paso está en IO/IOsolver.m.
%
%  EQUIVALENCIAS CON EXCEL
%    Celda objetivo          ->  c   (coeficientes de la función objetivo)
%    Celdas de variables     ->  las n columnas de c y A
%    Valor de: Max/Min/Valor ->  tipo = 'max' / 'min' / un número
%    Sujeto a restricciones  ->  A, b, sentido
%    int / bin               ->  opciones 'Enteras' / 'Binarias'
%    No negativos            ->  es el default (lb = 0); se cambia con 'lb'
%
%  ENTRADAS
%    c        : [1 x n] coeficientes de la función objetivo,
%               U = c1*x1 + c2*x2 + ... + cn*xn
%    A        : [m x n] matriz de restricciones, fila i = restricción i.
%               Si no hay restricciones, pasar [] (solo actúan lb y ub).
%    b        : [m x 1] lado derecho de cada restricción
%    sentido  : cell {m x 1} con '<=', '>=' o '=' para cada fila de A.
%               Se acepta un solo texto ('<=') y se aplica a TODAS las filas.
%    tipo     : 'max'  -> maximizar
%               'min'  -> minimizar
%               número -> "Valor de:" de Excel, busca una solución factible
%                         con U igual a ese número
%
%  OPCIONES (par nombre/valor)
%    'Nombres'       : cell {1 x n} con el nombre de cada variable.
%                      Default {'x_1', ..., 'x_n'}
%    'EtiquetasRest' : cell {m x 1} con el nombre de cada restricción
%                      (p. ej. {'Corte','Ensamble'}). Default {} (numera).
%    'lb'            : [1 x n] cota inferior de cada variable. Default 0
%                      (no negatividad). -Inf = variable libre.
%    'ub'            : [1 x n] cota superior. Default Inf.
%    'Enteras'       : índices de las variables que deben ser ENTERAS.
%                      Acepta [2 3], un vector lógico, o 'todas'.
%    'Binarias'      : índices de las variables 0/1. Fija lb=0, ub=1 y entera.
%    'Sensibilidad'  : true/false, calcular precios sombra y costos reducidos.
%                      Default true, salvo que haya enteras o modo "valor de".
%    'Verbose'       : true/false, imprimir el reporte. Default true.
%
%  SALIDA (struct sol)
%    sol.estado        : 'optimo' | 'infactible' | 'noAcotado'
%    sol.xOpt          : [1 x n] valor óptimo de cada variable
%    sol.valorOpt      : valor de la función objetivo en el óptimo
%    sol.lhs           : [m x 1] lado izquierdo A*x en el óptimo (lo consumido)
%    sol.holguras      : [m x 1] holgura ('<=') o excedente ('>=') de cada
%                        restricción, siempre >= 0. Vale 0 si es activa.
%    sol.activas       : [m x 1] lógico, true si la restricción se cumple con
%                        igualdad (recurso agotado / mínimo justo alcanzado)
%    sol.precioSombra  : [m x 1] cuánto CAMBIA el valor óptimo por cada unidad
%                        extra de b(i), o sea dU/db(i). En un max es lo que se
%                        gana; en un min es lo que cuesta. Vale 0 en toda
%                        restricción que no esté activa.
%    sol.costoReducido : [1 x n] cuánto habría que mejorar el coeficiente de
%                        una variable que quedó en su cota para que convenga
%                        usarla. Es 0 en las variables que sí se usan.
%    sol.nodos         : nodos explorados por la ramificación (solo enteras)
%    sol.c .A .b .sentido .tipo .nombres .lb .ub : los datos de entrada
%
%  EJEMPLO 1 — mesas y sillas (el mismo de IO.pl2var, pero por simplex)
%    c = [50 80];  A = [1 2; 1 1];  b = [120; 90];
%    sol = solver(c, A, b, {'<=','<='}, 'max', ...
%                 'Nombres', {'Mesas','Sillas'}, ...
%                 'EtiquetasRest', {'Corte','Ensamble'});
%
%  EJEMPLO 2 — tres productos, mezcla de recursos (Excel no lo grafica)
%    c = [30 20 25];
%    A = [2 1 3; 1 3 1; 1 1 1];
%    b = [100; 90; 45];
%    sol = solver(c, A, b, '<=', 'max');
%
%  EJEMPLO 3 — problema de la mochila, variables binarias
%    valor = [60 100 120];  peso = [10 20 30];
%    sol = solver(valor, peso, 50, '<=', 'max', 'Binarias', 'todas');
%
%  LÍMITES CONOCIDOS
%    - Modelo LINEAL. La función objetivo y las restricciones tienen que ser
%      combinaciones lineales de las variables (el "Simplex LP" de Excel).
%      No hay equivalente del motor GRG no lineal.
%    - Las cotas lb/ub se tratan internamente como restricciones extra, pero
%      NO aparecen en la tabla de precios sombra. Si querés el precio sombra
%      de una cota, escribila como fila de A.
%    - Con variables enteras NO hay informe de sensibilidad (Excel tampoco lo
%      da): los precios sombra no están definidos en un problema entero.
%    - Los precios sombra se leen de UNA base óptima. Si el problema es
%      degenerado (más restricciones activas que variables) puede haber
%      varios juegos de precios sombra válidos; se informa el de esa base.
%    - No calcula los rangos de validez ("aumento/disminución permisible")
%      del informe de sensibilidad de Excel.

%% ------------------------------------------------------------------
%  1. Lectura y validación de los datos
%% ------------------------------------------------------------------
tol = 1e-9;

c = c(:)';
n = numel(c);
if isempty(A), A = zeros(0, n); end
if isempty(b), b = zeros(0, 1); end
b = b(:);
m = size(A, 1);

assert(size(A,2) == n, 'solver:dimension', ...
    'A tiene %d columnas y c tiene %d coeficientes: no coinciden.', size(A,2), n);
assert(numel(b) == m, 'solver:dimension', ...
    'A tiene %d filas y b tiene %d valores: no coinciden.', m, numel(b));

sentido = normalizarSentido(sentido, m);

p = inputParser;
addParameter(p, 'Nombres',       {});
addParameter(p, 'EtiquetasRest', {});
addParameter(p, 'lb',            zeros(1,n));
addParameter(p, 'ub',            inf(1,n));
addParameter(p, 'Enteras',       []);
addParameter(p, 'Binarias',      []);
addParameter(p, 'Sensibilidad',  []);
addParameter(p, 'Verbose',       true);
parse(p, varargin{:});

nombres = p.Results.Nombres;
if isempty(nombres)
    nombres = arrayfun(@(k) sprintf('x_%d',k), 1:n, 'UniformOutput', false);
end
assert(numel(nombres) == n, 'solver:nombres', ...
    'Nombres debe tener una entrada por variable (%d).', n);

etiq = p.Results.EtiquetasRest;
if isempty(etiq)
    etiq = arrayfun(@(k) sprintf('R%d',k), 1:m, 'UniformOutput', false);
end
assert(numel(etiq) == m, 'solver:etiquetas', ...
    'EtiquetasRest debe tener una entrada por restricción (%d).', m);

lb = ajustarCota(p.Results.lb, n, 'lb');
ub = ajustarCota(p.Results.ub, n, 'ub');

esEnt = indicesAlogico(p.Results.Enteras,  n, 'Enteras');
esBin = indicesAlogico(p.Results.Binarias, n, 'Binarias');
lb(esBin) = max(lb(esBin), 0);
ub(esBin) = min(ub(esBin), 1);
esEnt = esEnt | esBin;

assert(all(lb <= ub), 'solver:cotas', 'Hay alguna variable con lb > ub.');

% tipo: 'max', 'min' o un número (el "Valor de:" de Excel)
if isnumeric(tipo)
    assert(isscalar(tipo) && isfinite(tipo), 'solver:tipo', ...
        'Como "Valor de" hay que pasar UN número finito.');
    objetivo = tipo;
    tipo = 'valor';
else
    tipo = validatestring(tipo, {'max','min'});
    objetivo = NaN;
end

sensib = p.Results.Sensibilidad;
if isempty(sensib), sensib = true; end
sensib = sensib && ~any(esEnt) && ~strcmp(tipo,'valor');
verbose = p.Results.Verbose;

%% ------------------------------------------------------------------
%  2. Armado del problema interno (siempre de MINIMIZACIÓN)
%% ------------------------------------------------------------------
%  'max' se resuelve minimizando -c y devolviendo el valor cambiado de signo.
%  'valor' (el "Valor de:" de Excel) es un problema de FACTIBILIDAD: se agrega
%  la fila c*x = objetivo y se minimiza la función nula.
switch tipo
    case 'min',   cmin = c;   Ai = A;  bi = b;  seni = sentido;
    case 'max',   cmin = -c;  Ai = A;  bi = b;  seni = sentido;
    case 'valor', cmin = zeros(1,n);  Ai = [A; c];  bi = [b; objetivo];
                  seni = [sentido(:); {'='}];
end

%% ------------------------------------------------------------------
%  3. Resolver
%% ------------------------------------------------------------------
nodos = NaN;
if any(esEnt)
    R = ramificar(cmin, Ai, bi, seni, lb, ub, esEnt, tol);
    nodos = R.nodos;
else
    R = resolverLP(cmin, Ai, bi, seni, lb, ub, tol);
end

sol.estado = R.estado;
sol.nodos  = nodos;

if ~strcmp(R.estado, 'optimo')
    sol.xOpt = nan(1,n);   sol.valorOpt = NaN;
    sol.lhs  = nan(m,1);   sol.holguras = nan(m,1);
    sol.activas = false(m,1);
    sol.precioSombra = nan(m,1);   sol.costoReducido = nan(1,n);
else
    x = R.x(:)';
    x(abs(x) < 1e-11) = 0;                 % limpieza de ceros numéricos
    if any(esEnt), x(esEnt) = round(x(esEnt)); end
    sol.xOpt = x;
    sol.valorOpt = c*x';

    sol.lhs = A*x';
    sol.holguras = zeros(m,1);
    for i = 1:m
        switch sentido{i}
            case '<=', sol.holguras(i) = b(i) - sol.lhs(i);   % lo que sobra
            case '>=', sol.holguras(i) = sol.lhs(i) - b(i);   % lo que excede
            case '=',  sol.holguras(i) = 0;
        end
    end
    sol.holguras(abs(sol.holguras) < 1e-9) = 0;
    sol.activas = sol.holguras <= 1e-9;

    %  Precios sombra y costos reducidos.
    %  R.y son los duales del problema INTERNO de minimización. Si el usuario
    %  pidió 'max' se minimizó -c, así que el valor óptimo es el opuesto y los
    %  duales también cambian de signo.
    if sensib
        y = R.y(1:m);
        if strcmp(tipo,'max'), y = -y; end
        y(abs(y) < 1e-9) = 0;
        y(~sol.activas) = 0;               % restricción con holgura -> precio 0
        sol.precioSombra = y;
        % costo reducido clásico: cj - y'*Aj  (0 en las variables que se usan)
        cr = c - (A'*y)';
        cr(abs(cr) < 1e-9) = 0;
        cr(sol.xOpt > lb + 1e-9 & sol.xOpt < ub - 1e-9) = 0;
        sol.costoReducido = cr;
    else
        sol.precioSombra  = nan(m,1);
        sol.costoReducido = nan(1,n);
    end
end

sol.c = c;  sol.A = A;  sol.b = b;  sol.sentido = sentido;
sol.tipo = tipo;  sol.objetivo = objetivo;
sol.nombres = nombres;  sol.etiquetas = etiq;
sol.lb = lb;  sol.ub = ub;  sol.enteras = esEnt;

%% ------------------------------------------------------------------
%  4. Reporte
%% ------------------------------------------------------------------
if verbose, reportar(sol, sensib); end
end


%% ===================================================================
%  resolverLP — Simplex de DOS FASES.
%    minimiza  cmin*x   sujeto a   A x {sen} b,   lb <= x <= ub
%
%  Devuelve r.x, r.z, r.estado y r.y (precios sombra de las filas de A, en el
%  sentido de MINIMIZACIÓN: y_i = dz/db_i).
%
%  Método, el mismo que a mano:
%    1) Se corren las variables para que todas queden >= 0 (x = M*u + o).
%       Las cotas superiores pasan a ser filas extra.
%    2) Se deja todo b >= 0 multiplicando filas por -1 cuando hace falta.
%    3) Se agregan holguras (+1), excedentes (-1) y artificiales (+1).
%    4) FASE 1: minimizar la suma de artificiales. Si no llega a 0, no hay
%       región factible.
%    5) FASE 2: minimizar el costo verdadero, prohibiendo que las artificiales
%       vuelvan a entrar. Sus columnas se conservan porque de ahí se leen los
%       precios sombra.
%% ===================================================================
function r = resolverLP(cmin, A, b, sen, lb, ub, tol)

n = numel(cmin);
mUser = size(A,1);

%% 1. Cambio de variable para que todas las u sean >= 0
%     lb finito            -> x = lb + u        (u >= 0)
%     lb = -Inf, ub finito -> x = ub - u        (u >= 0)
%     ambas infinitas      -> x = u+ - u-       (dos columnas)
colVar = [];  colSig = [];  o = zeros(n,1);  colDe = zeros(1,n);
for j = 1:n
    if isfinite(lb(j))
        o(j) = lb(j);   colVar(end+1) = j;  colSig(end+1) = +1;  %#ok<AGROW>
    elseif isfinite(ub(j))
        o(j) = ub(j);   colVar(end+1) = j;  colSig(end+1) = -1;  %#ok<AGROW>
    else
        colVar(end+1) = j;  colSig(end+1) = +1;                  %#ok<AGROW>
    end
    colDe(j) = numel(colVar);
    if ~isfinite(lb(j)) && ~isfinite(ub(j))
        colVar(end+1) = j;  colSig(end+1) = -1;                  %#ok<AGROW>
    end
end
N = numel(colVar);
M = zeros(n, N);
for k = 1:N, M(colVar(k), k) = colSig(k); end

%% 2. Filas extra por las cotas superiores que el cambio de variable no cubre
Aex = zeros(0, N);  bex = zeros(0,1);  senex = {};
for j = 1:n
    if isfinite(lb(j)) && isfinite(ub(j))
        fila = zeros(1,N);  fila(colDe(j)) = 1;
        Aex(end+1,:) = fila;            %#ok<AGROW>
        bex(end+1,1) = ub(j) - lb(j);   %#ok<AGROW>
        senex{end+1} = '<=';            %#ok<AGROW>
    end
end

As   = [A*M; Aex];
bs   = [b - A*o; bex];
sens = [sen(:); senex(:)];
mt   = size(As,1);

%% 3. Todo b >= 0 (si no, la base inicial arrancaría negativa)
volteo = ones(mt,1);
for i = 1:mt
    if bs(i) < 0
        As(i,:) = -As(i,:);  bs(i) = -bs(i);  volteo(i) = -1;
        switch sens{i}
            case '<=', sens{i} = '>=';
            case '>=', sens{i} = '<=';
        end
    end
end

%% 4. Holguras, excedentes y artificiales
ns = 0;  na = 0;
slIdx = zeros(mt,1);  slSgn = zeros(mt,1);  arIdx = zeros(mt,1);
for i = 1:mt
    switch sens{i}
        case '<=', ns = ns+1;  slIdx(i) = ns;  slSgn(i) = +1;
        case '>=', ns = ns+1;  slIdx(i) = ns;  slSgn(i) = -1;
                   na = na+1;  arIdx(i) = na;
        case '=',  na = na+1;  arIdx(i) = na;
    end
end
ncols = N + ns + na;
T = zeros(mt+1, ncols+1);
T(1:mt, 1:N) = As;
base    = zeros(mt,1);
dualCol = zeros(mt,1);          % columna con +e_i: de ahí sale el dual
for i = 1:mt
    if slIdx(i) > 0, T(i, N+slIdx(i))    = slSgn(i); end
    if arIdx(i) > 0, T(i, N+ns+arIdx(i)) = 1;        end
    if arIdx(i) > 0
        base(i) = N+ns+arIdx(i);   dualCol(i) = N+ns+arIdx(i);
    else
        base(i) = N+slIdx(i);      dualCol(i) = N+slIdx(i);
    end
end
T(1:mt, end) = bs;

esArt   = false(1, ncols);   esArt(N+ns+1:end) = true;
filaDe  = (1:mt)';           % de qué fila original viene cada fila del tableau
viva    = true(mt,1);        % filas que sobreviven (las redundantes se borran)

%% 5. FASE 1 — minimizar la suma de las artificiales
if na > 0
    T = filaCostos(T, base, double(esArt));
    [T, base, est] = simplex(T, base, true(1,ncols), tol);
    if strcmp(est,'noAcotado') || -T(end,end) > 1e-7
        r = struct('x',[], 'z',NaN, 'estado','infactible', 'y',[]);  return
    end
    % Sacar de la base las artificiales que quedaron en cero
    i = 1;
    while i <= size(T,1)-1
        if esArt(base(i))
            cand = find(abs(T(i,1:ncols)) > 1e-9 & ~esArt);
            if isempty(cand)
                viva(filaDe(i)) = false;    % fila redundante: se elimina
                T(i,:) = [];  base(i) = [];  filaDe(i) = [];
                continue
            end
            T = pivotear(T, i, cand(1));  base(i) = cand(1);
        end
        i = i + 1;
    end
end

%% 6. FASE 2 — el costo verdadero, con las artificiales bloqueadas
c2 = zeros(1, ncols);
c2(1:N) = cmin(colVar) .* colSig;
T = filaCostos(T, base, c2);
[T, base, est] = simplex(T, base, ~esArt, tol);
if strcmp(est, 'noAcotado')
    r = struct('x',[], 'z',NaN, 'estado','noAcotado', 'y',[]);  return
end

%% 7. Solución y precios sombra
u = zeros(ncols,1);
u(base) = T(1:end-1, end);
x = M*u(1:N) + o;

%  y_i = -(costo reducido de la columna que vale +e_i en la fila i). Esa
%  columna es la holgura si la fila era '<=', y la artificial si era '>=' o
%  '='. Las filas redundantes que se borraron quedan con precio sombra 0.
y = zeros(mt,1);
for i = 1:mt
    if viva(i), y(i) = -T(end, dualCol(i)); end
end
y = volteo .* y;                        % deshacer el cambio de signo de la fila

r.x = x;  r.z = cmin*x;  r.estado = 'optimo';  r.y = y(1:mUser);
end


%% ===================================================================
%  simplex — Iteraciones sobre el tableau ya canónico.
%  Regla de BLAND (primer índice que sirve, tanto para entrar como para
%  desempatar al salir): es más lenta que la de Dantzig pero no cicla nunca,
%  y estos problemas son chicos.
%% ===================================================================
function [T, base, estado] = simplex(T, base, permitido, tol)
mt = numel(base);
maxIter = 500 + 20*size(T,2)^2;
for it = 1:maxIter
    rc = T(end, 1:end-1);
    rc(~permitido) = Inf;
    j = find(rc < -tol, 1);                  % regla de Bland al entrar
    if isempty(j), estado = 'optimo'; return, end
    col = T(1:mt, j);
    pos = find(col > tol);
    if isempty(pos), estado = 'noAcotado'; return, end
    razon = T(pos,end) ./ col(pos);
    cand  = pos(razon <= min(razon) + 1e-9);
    [~, k] = min(base(cand));                % desempate de Bland al salir
    i = cand(k);
    T = pivotear(T, i, j);
    base(i) = j;
end
estado = 'maxIter';
warning('solver:maxIter', 'El simplex no convergió en %d iteraciones.', maxIter);
end


%% ===================================================================
%  pivotear — Deja un 1 en (i,j) y ceros en el resto de la columna.
%% ===================================================================
function T = pivotear(T, i, j)
T(i,:) = T(i,:) / T(i,j);
otras = [1:i-1, i+1:size(T,1)];
T(otras,:) = T(otras,:) - T(otras,j) * T(i,:);
end


%% ===================================================================
%  filaCostos — Reescribe la última fila (costos reducidos) para el vector de
%  costos cv, dejándola canónica respecto de la base actual.
%% ===================================================================
function T = filaCostos(T, base, cv)
mt = numel(base);
T(end, 1:end-1) = cv - cv(base) * T(1:mt, 1:end-1);
T(end, end)     =    - cv(base) * T(1:mt, end);
end


%% ===================================================================
%  ramificar — Ramificación y acotamiento para las variables enteras.
%  Recorre en profundidad: resuelve la relajación lineal y, si una variable
%  entera sale fraccionaria, abre dos ramas: x_j <= piso y x_j >= techo.
%% ===================================================================
function best = ramificar(cmin, A, b, sen, lb, ub, esEnt, tol)
best.x = [];  best.z = Inf;  best.estado = 'infactible';  best.y = [];
maxNodos = 5000;
nodos = 0;
pila = {struct('lb',lb, 'ub',ub)};
while ~isempty(pila)
    nodo = pila{end};  pila(end) = [];
    nodos = nodos + 1;
    if nodos > maxNodos
        warning('solver:maxNodos', ...
            'Ramificación cortada en %d nodos; la solución puede no ser la óptima.', maxNodos);
        break
    end
    R = resolverLP(cmin, A, b, sen, nodo.lb, nodo.ub, tol);
    if strcmp(R.estado, 'noAcotado')
        if nodos == 1
            best.estado = 'noAcotado';  best.nodos = nodos;  return
        end
        continue
    end
    if ~strcmp(R.estado, 'optimo'), continue, end
    if R.z >= best.z - 1e-9, continue, end          % poda por cota
    xr = R.x(:)';
    frac = abs(xr(esEnt) - round(xr(esEnt)));
    [peor, k] = max(frac);
    if isempty(peor) || peor <= 1e-6
        xr(esEnt) = round(xr(esEnt));
        best.x = xr(:);  best.z = cmin*xr(:);  best.estado = 'optimo';  best.y = R.y;
        continue
    end
    idx = find(esEnt);  j = idx(k);
    n1 = nodo;  n1.ub(j) = min(n1.ub(j), floor(xr(j)));
    n2 = nodo;  n2.lb(j) = max(n2.lb(j), ceil(xr(j)));
    pila{end+1} = n1;  pila{end+1} = n2;            %#ok<AGROW>
end
best.nodos = nodos;
end


%% ===================================================================
%  Utilidades de entrada
%% ===================================================================
function sen = normalizarSentido(sen, m)
if ischar(sen) || isstring(sen), sen = cellstr(sen); end
sen = cellstr(sen);   sen = sen(:);
if numel(sen) == 1 && m ~= 1, sen = repmat(sen, m, 1); end
assert(numel(sen) == m, 'solver:sentido', ...
    'sentido debe tener una entrada por restricción (%d), o una sola para todas.', m);
for i = 1:m
    s = strtrim(sen{i});
    switch s
        case {'<=','<','=<'},  sen{i} = '<=';
        case {'>=','>','=>'},  sen{i} = '>=';
        case {'=','=='},       sen{i} = '=';
        otherwise
            error('solver:sentido', 'Sentido no reconocido: "%s". Usá <=, >= o =.', s);
    end
end
end

function v = ajustarCota(v, n, nombre)
v = v(:)';
if isscalar(v), v = repmat(v, 1, n); end
assert(numel(v) == n, 'solver:cotas', '%s debe tener %d valores (o uno solo).', nombre, n);
end

function L = indicesAlogico(spec, n, nombre)
L = false(1,n);
if isempty(spec), return, end
if ischar(spec) || isstring(spec)
    assert(strcmpi(spec,'todas'), 'solver:enteras', ...
        '%s solo acepta índices, un vector lógico o ''todas''.', nombre);
    L(:) = true;  return
end
if islogical(spec)
    assert(numel(spec) == n, 'solver:enteras', ...
        '%s como vector lógico debe tener %d entradas.', nombre, n);
    L = spec(:)';  return
end
assert(all(spec >= 1 & spec <= n & spec == fix(spec)), 'solver:enteras', ...
    '%s tiene índices fuera de 1..%d.', nombre, n);
L(spec) = true;
end


%% ===================================================================
%  reportar — El "informe de respuestas" y el "informe de sensibilidad".
%% ===================================================================
function reportar(sol, sensib)
n = numel(sol.c);   m = size(sol.A,1);
nom = sol.nombres;

fprintf('--- Variables de decisión ---\n');
for j = 1:n
    extra = '';
    if sol.enteras(j)
        if sol.lb(j)==0 && sol.ub(j)==1, extra = '   binaria'; else, extra = '   entera'; end
    end
    fprintf('  %-14s en [%s, %s]%s\n', nom{j}, num2str(sol.lb(j)), num2str(sol.ub(j)), extra);
end

fprintf('--- Función objetivo ---\n');
switch sol.tipo
    case 'valor', fprintf('VALOR DE %.4g: ', sol.objetivo);
    otherwise,    fprintf('%s: ', upper(sol.tipo));
end
fprintf('U = %s\n', expresion(sol.c, nom));

if m > 0, fprintf('--- Restricciones ---\n'); end
for i = 1:m
    fprintf('  %-12s %s %s %.4g\n', sol.etiquetas{i}, expresion(sol.A(i,:), nom), ...
        sol.sentido{i}, sol.b(i));
end

fprintf('\n--- Solución ---\n');
switch sol.estado
    case 'infactible'
        fprintf('SIN SOLUCIÓN FACTIBLE: las restricciones se contradicen.\n');
        return
    case 'noAcotado'
        fprintf('NO ACOTADO: la función objetivo crece sin límite.\n');
        fprintf('Falta alguna restricción que frene a las variables.\n');
        return
end

fprintf('   %-14s %12s', 'Variable', 'Valor');
if sensib, fprintf(' %14s', 'Costo reduc.'); end
fprintf('\n');
for j = 1:n
    fprintf('   %-14s %12.4g', nom{j}, sol.xOpt(j));
    if sensib, fprintf(' %14.4g', sol.costoReducido(j)); end
    fprintf('\n');
end

if m > 0
    fprintf('\n   %-12s %10s %4s %10s %10s %9s', ...
        'Restricción', 'Usado', '', 'Límite', 'Holgura', 'Estado');
    if sensib, fprintf(' %12s', 'Precio somb.'); end
    fprintf('\n');
    for i = 1:m
        if sol.activas(i), est = 'ACTIVA'; else, est = 'holgura'; end
        fprintf('   %-12s %10.4g %4s %10.4g %10.4g %9s', ...
            sol.etiquetas{i}, sol.lhs(i), sol.sentido{i}, sol.b(i), sol.holguras(i), est);
        if sensib, fprintf(' %12.4g', sol.precioSombra(i)); end
        fprintf('\n');
    end
end

fprintf('\n');
switch sol.tipo
    case 'valor', fprintf('U = %.6g  (valor pedido: %.6g)\n', sol.valorOpt, sol.objetivo);
    otherwise,    fprintf('U %s = %.6g\n', sol.tipo, sol.valorOpt);
end
if ~isnan(sol.nodos)
    fprintf('(ramificación: %d nodos explorados)\n', sol.nodos);
end
end

function s = expresion(fila, nom)
piezas = {};
for j = 1:numel(fila)
    if fila(j) == 0, continue, end
    if isempty(piezas)
        piezas{end+1} = sprintf('%.4g*%s', fila(j), nom{j});      %#ok<AGROW>
    elseif fila(j) > 0
        piezas{end+1} = sprintf(' + %.4g*%s', fila(j), nom{j});   %#ok<AGROW>
    else
        piezas{end+1} = sprintf(' - %.4g*%s', -fila(j), nom{j});  %#ok<AGROW>
    end
end
if isempty(piezas), s = '0'; else, s = strjoin(piezas, ''); end
end
