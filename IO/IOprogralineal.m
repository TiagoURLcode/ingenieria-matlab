%% DemoIOmesasillas.m — Método gráfico de Programación Lineal (2 variables)
% Mezcla de materias primas
%Q30 por unidad de A
%Q20 por unidad de B
clear; clc

%% 0. Analizar qué se solicita
% combinacion de materias primas para minimizar costos

%% 1. Tabular datos
%              Materia       componente X        
%   A    (x1)      1            0             
%   B    (x2)      0            1             
%   Total          2           90
%   

%% 2. Variables de decisión
%   x1 = número de mesas a producir
%   x2 = número de sillas a producir

%% 3. Función objetivo
%   Max U = 50*x1 + 80*x2
c = [50 80];

%% 4. Restricciones
%   Corte:     x1 + 2*x2 <= 120
%   Ensamble:  x1 +   x2 <=  90
%   No negatividad: x1, x2 >= 0   (la maneja IO.pl2var automáticamente)
A = [1 2;
    1 1];
b = [120; 90];
sentido = {'<=', '<='};

%% 5-9. Graficar, región factible, vértices, evaluación y solución
sol = IO.pl2var(c, A, b, sentido, 'max', 'Nombres', {'Mesas','Sillas'}, ...
    'Titulo', 'Mesas y sillas — Corte y Ensamble');

fprintf('\nProducir %.0f mesas y %.0f sillas -> utilidad máxima Q%.2f\n', ...
    sol.xOpt(1), sol.xOpt(2), sol.valorOpt);
