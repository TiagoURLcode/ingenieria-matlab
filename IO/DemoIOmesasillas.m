%% DemoIOmesasillas.m — Método gráfico de Programación Lineal (2 variables)
% Problema del pizarrón: una fábrica produce mesas y sillas.
%   Corte     disponible: 120 horas
%   Ensamble  disponible:  90 horas
%   Contribución: mesas Q.50.00, sillas Q.80.00
% Objetivo: maximizar la utilidad U.
clear; clc

%% 0. Analizar qué se solicita
% Determinar dos materias primas Q30(x1) Q20(x2) 
% la utilidad, sin exceder las horas disponibles de corte y ensamble.

%% 1. Tabular datos
%              Corte (h)   Ensamble (h)   Utilidad (Q)
%   Mesa (x1)      1            1             50
%   Silla (x2)     2            1             80
%   Disponible    120           90

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
