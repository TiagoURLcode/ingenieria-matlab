%% ejercicio_solver.m — Programación Lineal con solver.m (y método gráfico con IO.pl2var)
% Problema planteado en el pizarrón:
%   Función Objetivo: Max Z = 500*x1 + 300*x2
%   Restricciones:
%     R1: 15*x1 +  5*x2 <= 300
%     R2: 10*x1 +  6*x2 <= 240
%     R3:  8*x1 + 12*x2 <= 450
%     No negatividad: x1 >= 0, x2 >= 0
clear; clc

%% 0. Analizar qué se solicita
% Maximizar la función objetivo Z sujeta a las 3 restricciones de recursos/capacidad.

%% 1. Tabular datos
%                   x1     x2     Signo   Resultado (LD)
%   Objetivo Z     500    300
%   R1              15      5      <=          300
%   R2              10      6      <=          240
%   R3               8     12      <=          450

%% 2. Variables de decisión
%   x1 = Variable de decisión 1
%   x2 = Variable de decisión 2

%% 3. Función objetivo
%   Max Z = 500*x1 + 300*x2
c = [500 300];

%% 4. Restricciones
A = [15   5;    % R1
    10   6;    % R2
    8  12];   % R3

b = [300; 210; 450];

sentido = {'<=', '<=', '<='};

%% 5. Resolver con solver.m (Simplex)
sol = solver(c, A, b, sentido, 'max', ...
    'Nombres',       {'x1', 'x2'}, ...
    'EtiquetasRest', {'R1', 'R2', 'R3'});

fprintf('\n=== SOLUCIÓN ÓPTIMA CON SOLVER ===\n');
fprintf('x1 = %.2f\n', sol.xOpt(1));
fprintf('x2 = %.2f\n', sol.xOpt(2));
fprintf('Valor óptimo Z = %.2f\n\n', sol.valorOpt);

%% 6. Resolver y graficar con IO.pl2var (Método Gráfico)
% Al tener 2 variables, también se puede resolver y graficar con la caja de herramientas IO:
solGrafico = IO.pl2var(c, A, b, sentido, 'max', ...
    'Nombres',       {'x1', 'x2'}, ...
    'Titulo',        'Problema Pizarrón — Método Gráfico', ...
    'EtiquetasRest', {'R1', 'R2', 'R3'});

fprintf('\n=== SOLUCIÓN CON MÉTODO GRÁFICO (IO.pl2var) ===\n');
fprintf('x1 = %.2f, x2 = %.2f -> Z = %.2f\n', ...
    solGrafico.xOpt(1), solGrafico.xOpt(2), solGrafico.valorOpt);
