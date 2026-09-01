%% IOsolver.m — Programación Lineal con solver.m (el Solver de Excel en MATLAB)
% IO.pl2var solo sirve con 2 variables porque resuelve GRAFICANDO. Cuando el
% problema tiene 3 o más variables no hay gráfico posible y hay que ir por
% simplex: eso es solver.m.
clear; clc

%% ============================================================
%  CASO 1 — Mezcla de producción, 3 productos
%  ============================================================

%% 0. Analizar qué se solicita
% Cuántas unidades fabricar de cada producto para MAXIMIZAR la utilidad.

%% 1. Tabular datos
%  Recurso          Silla   Mesa   Estante   Disponible
%   Madera   [m2]     2      1        3          80
%   Mano obra [h]     1      3        1          90
%   Barniz   [L]      1      1        1          45
%   Utilidad  [Q]    30     20       25

%% 2. Variables de decisión
%   x1 = sillas, x2 = mesas, x3 = estantes

%% 3. Función objetivo
%   Max U = 30*x1 + 20*x2 + 25*x3
c = [30 20 25];

%% 4. Restricciones
A = [2 1 3;      % madera
     1 3 1;      % mano de obra
     1 1 1];     % barniz
b = [80; 90; 45];
sentido = {'<=', '<=', '<='};

%% 5-9. Resolver e interpretar
sol = solver(c, A, b, sentido, 'max', ...
    'Nombres',       {'Sillas','Mesas','Estantes'}, ...
    'EtiquetasRest', {'Madera','Mano obra','Barniz'});

fprintf('\nProducir %.0f sillas, %.0f mesas y %.0f estantes -> utilidad Q%.2f\n', ...
    sol.xOpt(1), sol.xOpt(2), sol.xOpt(3), sol.valorOpt);

% COSTO REDUCIDO: los estantes quedan en cero. Su costo reducido dice cuánto
% se PIERDE por cada estante que se fabrique a la fuerza; visto al revés, es
% cuánto tendría que subir su utilidad unitaria para que valga la pena.
fprintf('Fabricar un estante costaría Q%.2f de utilidad; recién conviene a Q%.2f c/u\n', ...
    -sol.costoReducido(3), c(3) - sol.costoReducido(3));

% PRECIO SOMBRA: qué recurso conviene comprar de más. Por cada unidad extra
% del recurso i la utilidad sube sol.precioSombra(i). Los recursos con
% holgura tienen precio sombra 0: sobran, comprar más no sirve de nada.
[mejor, iMejor] = max(sol.precioSombra);
fprintf('El recurso que más conviene ampliar es %s: cada unidad extra da Q%.2f\n', ...
    sol.etiquetas{iMejor}, mejor);


%% ============================================================
%  CASO 2 — Selección de proyectos: variables BINARIAS
%  ============================================================
% Es el "bin" del Solver de Excel: cada variable vale 0 (no se hace) o 1 (se
% hace). No hay medio proyecto, así que la relajación lineal no alcanza y
% solver ramifica.
fprintf('\n\n=== Selección de proyectos (binarias) ===\n');

%  Proyecto        P1    P2    P3    P4    P5
beneficio =     [120    90   150    70   110];   % ganancia [miles de Q]
inversion =     [ 40    30    55    25    45];   % costo    [miles de Q]
personal  =     [  3     2     4     2     3];   % ingenieros que ocupa

solP = solver(beneficio, [inversion; personal], [120; 9], '<=', 'max', ...
    'Binarias',      'todas', ...
    'Nombres',       {'P1','P2','P3','P4','P5'}, ...
    'EtiquetasRest', {'Presupuesto','Personal'});

elegidos = find(solP.xOpt > 0.5);
fprintf('\nHacer los proyectos: %s -> beneficio Q%.0f mil\n', ...
    strjoin(solP.nombres(elegidos), ', '), solP.valorOpt);

% Cuánto cuesta la exigencia de que sean enteros: se compara contra la misma
% cartera sin la condición binaria (proyectos "divisibles").
solPc = solver(beneficio, [inversion; personal], [120; 9], '<=', 'max', ...
    'lb', 0, 'ub', 1, 'Verbose', false);
fprintf('Sin la condición 0/1 daría Q%.1f mil: la indivisibilidad cuesta Q%.1f mil\n', ...
    solPc.valorOpt, solPc.valorOpt - solP.valorOpt);


%% ============================================================
%  CASO 3 — Dieta de costo mínimo (restricciones >=)
%  ============================================================
% Minimizar el costo de una mezcla que cumpla mínimos nutricionales.
fprintf('\n\n=== Dieta de costo mínimo ===\n');

costo = [0.60 0.80 0.45];              % Q por unidad de cada alimento
Anut  = [ 20  30  10;                  % proteína por unidad
          40  20  35;                  % calorías
           5  10   3];                 % fibra
minim = [200; 500; 60];                % mínimos exigidos

solD = solver(costo, Anut, minim, '>=', 'min', ...
    'Nombres',       {'Avena','Leche','Pan'}, ...
    'EtiquetasRest', {'Proteína','Calorías','Fibra'});

fprintf('\nCosto mínimo de la dieta: Q%.2f\n', solD.valorOpt);
% En un MIN el precio sombra es lo que CUESTA exigir una unidad más del
% nutriente. La proteína sale con holgura: ya sobra, subir su mínimo un poco
% no encarece nada.
fprintf('Subir el mínimo de calorías en 1 encarece la dieta Q%.4f\n', ...
    solD.precioSombra(2));
