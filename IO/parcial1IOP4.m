%%Parcial 1 prob 4
%% IO_P3.m — Práctica 3: método gráfico de Programación Lineal (2 variables)
% Dos problemas en un solo archivo. Un único clear al inicio y las variables
% numeradas por problema (c1, A1, b1 / c2, A2, b2), para que al terminar
% queden en el workspace los datos y las soluciones de los dos.
clear; clc

%% ====================================================================

%  Q30 por unidad de A, Q20 por unidad de B
%% ====================================================================

%% 0. Analizar qué se solicita
% Combinación de materias primas que minimice el costo.

%% 1. Tabular datos
%  Materia                   Al           Vidrio    MDO      Equipo
%   V Corrediza    (x1)      5.5kg        1.8m2     55          20
%   Puerta abat    (x2)      8  kg        2.2m2     90          15
%   Total          2         880kg        270m2     9000        2400

%% 2. Variables de decisión
%   x1 = Ventana corrediza
%   x2 = Puerta abatible

%% 3. Función objetivo
%   Maz U = 280*x1 + 420*x2
c1 = [280 420];

%% 4. Restricciones
%   Unidades X requeridas:  2*x1 +   x2 >= 60
%   Unidades Y requeridas:    x1 + 3*x2 >= 75
%   Mezcla:                   x1 +   x2 >= 40
%   No negatividad: x1, x2 >= 0   (la maneja IO.pl2var automáticamente)
A1 = [5.5 8;
      1.8 2.2;
      55  90;
      20 15];
b1 = [880; 270; 9000; 2400];
sentido1 = {'<=', '<=', '<=', '<='};

%% 5-9. Graficar, región factible, vértices, evaluación y solución
sol1 = IO.pl2var(c1, A1, b1, sentido1, 'max', 'Nombres', {'Ventana Corrediza','Puerta Abatible'}, ...
    'Titulo', 'Problema 4 — maximizar utilidad de Aluvent', ...
    'EtiquetasRest', {'Aluminio','Vidrio','Mano de obra','Equipo corte/ensamble'});

fprintf('\nFabricar %.2f ventanas correderas y %.2f puertas abatibles -> utilidad máxima Q%.2f\n', ...
    sol1.xOpt(1), sol1.xOpt(2), sol1.valorOpt);