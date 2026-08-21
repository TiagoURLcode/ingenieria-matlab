%% IOprogralineal.m — Método gráfico de Programación Lineal (2 variables)
% Mezcla de materias primas
%Q30 por unidad de A
%Q20 por unidad de B
clear; clc

%% 0. Analizar qué se solicita
% combinacion de materias primas para minimizar costos

%% 1. Tabular datos
%  Materia         X            Y      
%   A    (x1)      1            1             
%   B    (x2)      3            1             
%   Total          2           90
%   

%% 2. Variables de decisión
%   x1 = unidades de materia prima A
%   x2 = unidades de materia prima B

%% 3. Función objetivo
%   Min U = 30*x1 + 20*x2
c = [30 20];

%% 4. Restricciones
%   Unidades X requeridas:  2*x1 +   x2 >= 60
%   Unidades Y requeridas:    x1 + 3*x2 >= 75
%   No negatividad: x1, x2 >= 0   (la maneja IO.pl2var automáticamente)
A = [2 1;
    1 3];
b = [60; 75];
sentido = {'>=', '>='};

%% 5-9. Graficar, región factible, vértices, evaluación y solución
sol = IO.pl2var(c, A, b, sentido, 'min', 'Nombres', {'A','B'}, ...
    'Titulo', 'Combinacion de materia prima A y B para reducir costos');

fprintf('\nComprar %.0f de materia A y %.0f de materia B -> costo mínimo Q%.2f\n', ...
    sol.xOpt(1), sol.xOpt(2), sol.valorOpt);
