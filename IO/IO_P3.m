%% IO_P3.m — Práctica 3: método gráfico de Programación Lineal (2 variables)
% Dos problemas en un solo archivo. Un único clear al inicio y las variables
% numeradas por problema (c1, A1, b1 / c2, A2, b2), para que al terminar
% queden en el workspace los datos y las soluciones de los dos.
clear; clc

%% ====================================================================
%  PROBLEMA 1 — Mezcla de materias primas
%  Q30 por unidad de A, Q20 por unidad de B
%% ====================================================================

%% 0. Analizar qué se solicita
% Combinación de materias primas que minimice el costo.

%% 1. Tabular datos
%  Materia         X            Y
%   A    (x1)      1            1
%   B    (x2)      3            1
%   Total          2           90

%% 2. Variables de decisión
%   x1 = unidades de materia prima A
%   x2 = unidades de materia prima B

%% 3. Función objetivo
%   Min U = 30*x1 + 20*x2
c1 = [30 20];

%% 4. Restricciones
%   Unidades X requeridas:  2*x1 +   x2 >= 60
%   Unidades Y requeridas:    x1 + 3*x2 >= 75
%   Mezcla:                   x1 +   x2 >= 40
%   No negatividad: x1, x2 >= 0   (la maneja IO.pl2var automáticamente)
A1 = [2 1;
      1 3;
      1 1];
b1 = [60; 75; 40];
sentido1 = {'>=', '>=', '>='};

%% 5-9. Graficar, región factible, vértices, evaluación y solución
sol1 = IO.pl2var(c1, A1, b1, sentido1, 'min', 'Nombres', {'A','B'}, ...
    'Titulo', 'Problema 1 — mezcla de materias primas A y B');

fprintf('\nComprar %.0f de materia A y %.0f de materia B -> costo mínimo Q%.2f\n', ...
    sol1.xOpt(1), sol1.xOpt(2), sol1.valorOpt);

%% ====================================================================
%  PROBLEMA 2 — Piezas A y B por corte, soldadura y pintura
%  Q120 por pieza A, Q150 por pieza B
%% ====================================================================

%% 0. Analizar qué se solicita
% Cuántas piezas de cada tipo producir para maximizar la contribución
% marginal, sin pasarse de las horas disponibles de cada proceso.

%% 1. Tabular datos
%  Proceso        Pieza A       Pieza B       Capacidad
%   Corte          2h            3h            180h
%   Soldadura      4h            2h            240h
%   Pintura        1h            2h            120h
%  Contribución marginal: Q120 por pieza A, Q150 por pieza B

%% 2. Variables de decisión
%   x1 = piezas A a producir
%   x2 = piezas B a producir

%% 3. Función objetivo
%   Max U = 120*x1 + 150*x2
c2 = [120 150];

%% 4. Restricciones
%  Los tres procesos son CAPACIDAD (<=): no se pueden usar más horas de las
%  que hay. Las dos últimas son exigencias de producción (>=), y por eso el
%  modelo mezcla los dos sentidos en el mismo vector.
%   Corte:              2*x1 + 3*x2 <= 180
%   Soldadura:          4*x1 + 2*x2 <= 240
%   Pintura:              x1 + 2*x2 <= 120
%   Mínimo de A:          x1        >=  20
%   Producción total:     x1 +   x2 >=  50
%   No negatividad: x1, x2 >= 0   (la maneja IO.pl2var automáticamente)
A2 = [2 3;
      4 2;
      1 2;
      1 0;
      1 1];
b2 = [180; 240; 120; 20; 50];
sentido2 = {'<=', '<=', '<=', '>=', '>='};

%% 5-9. Graficar, región factible, vértices, evaluación y solución
sol2 = IO.pl2var(c2, A2, b2, sentido2, 'max', 'Nombres', {'Pieza A','Pieza B'}, ...
    'Titulo', 'Problema 2 — producción metalúrgica');

fprintf('\nProducir %.0f piezas A y %.0f piezas B -> contribución máxima Q%.2f\n', ...
    sol2.xOpt(1), sol2.xOpt(2), sol2.valorOpt);
