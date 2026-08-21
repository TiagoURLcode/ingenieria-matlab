%% mgs.m — Ejemplo resuelto del modelo M/G/1
% Usa IO.mg1: llegadas de Poisson, UN servidor, y tiempos de servicio de
% distribución GENERAL (cualquiera), de la que solo hace falta conocer la
% media y la desviación estándar. Es el método de Pollaczek-Khintchine.
%
% Por eso no hay "M/G/s" acá: la fórmula cerrada existe para s = 1. Con
% varios servidores y servicio general no hay solución exacta simple.
%
% EJEMPLO: un taller con un solo técnico. Llegan 3 reparaciones por hora.
% Cada reparación tarda 15 minutos en promedio, con una desviación estándar
% de 5 minutos.
clear; clc

%% 1. Datos
% TODO EN HORAS. sigma va en unidades de TIEMPO, la misma que 1/mu: es la
% dispersión del tiempo de servicio, no una tasa.
lambda = 3;         % tasa de llegadas [reparaciones/h]  (3 por hora)
mu     = 4;         % tasa de servicio [reparaciones/h]
                    %   (1/mu = 15 min = 0.25 h  ->  mu = 4 por hora)
sigma  = 5/60;      % desviación del tiempo de servicio [h]  (5 min)

%% 2. Medidas de desempeño
sol = IO.mg1(lambda, mu, sigma);

% Los tiempos salen en HORAS porque lambda, mu y sigma entraron por hora.
fprintf('\n  W  = %.2f min en el sistema\n', sol.W*60);
fprintf('  Wq = %.2f min en la cola\n', sol.Wq*60);
fprintf('  el tecnico esta libre el %.1f%% del tiempo\n', sol.P0*100);
