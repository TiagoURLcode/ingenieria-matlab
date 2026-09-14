%% PROTRAC - Problema #1 (Programación Lineal)
% Variables de decisión:
%   x(1) = E-9  (unidades a fabricar el próximo mes)
%   x(2) = F-9  (unidades a fabricar el próximo mes)
%
% Objetivo: maximizar margen de contribución
%   max Z = 5000*E9 + 4000*F9
%
% Restricciones:
%   Torneado Depto A:  10*E9 + 15*F9 <= 150
%   Torneado Depto B:  20*E9 + 10*F9 <= 160
%   Horas de prueba:   30*E9 + 10*F9 >= 135     (10% por debajo de meta 150)
%   Mezcla (mercado):  F9 >= (1/3)*E9  ->  (1/3)*E9 - F9 <= 0
%   Pedido mínimo:     E9 + F9 >= 5
%   No negatividad:    E9, F9 >= 0

clear; clc;

%% Datos crudos
margen        = [5000, 4000];      % $/unidad [E-9, F-9]

hrs_A         = [10, 15];          % horas depto A por unidad
cap_A         = 150;               % horas disponibles A

hrs_B         = [20, 10];          % horas depto B por unidad
cap_B         = 160;               % horas disponibles B

hrs_prueba    = [30, 10];          % horas de prueba por unidad
meta_prueba   = 150;               % meta convenida con el sindicato
tol_prueba    = 0.10;              % desviación permitida hacia abajo
min_prueba    = meta_prueba*(1 - tol_prueba);   % = 135

razon_F_por_E = 1/3;               % al menos 1 F-9 por cada 3 E-9
pedido_min    = 5;                 % unidades totales (E-9 + F-9) comprometidas

%% Forma que come solver.m
% Cada fila va con SU sentido: no hay que negar el objetivo ni invertir los
% >= multiplicando por -1, como pedía linprog.
c = margen;                        % 'max' lo maneja solver

A = [ hrs_A;                       % 10*E9 + 15*F9 <= 150
      hrs_B;                       % 20*E9 + 10*F9 <= 160
%     hrs_prueba;                  % 30*E9 + 10*F9 >= 135  <- SINDICATO, quitada
%     razon_F_por_E, -1;           % (1/3)*E9 - F9 <= 0    <- MEZCLA, quitada
      1, 1 ];                      % E9 + F9 >= 5

b = [ cap_A;
      cap_B;
%     min_prueba;                  % <- SINDICATO, quitada
%     0;                           % <- MEZCLA, quitada
      pedido_min ];

sentido = {'<=', '<=', '>='};
% sentido = {'<=', '<=', '>=', '<=', '>='};   % con Sindicato y Mezcla

% lb = 0 es el default de solver, no hace falta pasarlo.

%% Etiquetas (útiles para reportar precios sombra / holguras)
nombres_var  = {'E-9', 'F-9'};
nombres_rest = {'Torneado A', 'Torneado B', ...
                'Pedido distribuidor'};   % sin 'Horas de prueba' ni 'Mezcla F-9/E-9'

%% Resolver
% No se fabrican fracciones de maquina: E-9 y F-9 son ENTERAS.
sol = solver(c, A, b, sentido, 'max', ...
    'Enteras',       'todas', ...
    'Nombres',       nombres_var, ...
    'EtiquetasRest', nombres_rest);

fprintf('\nFabricar %.0f E-9 y %.0f F-9 -> margen maximo $%.2f\n', ...
    sol.xOpt(1), sol.xOpt(2), sol.valorOpt);
