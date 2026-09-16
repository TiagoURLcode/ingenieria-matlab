%% CanonRetroceso.m - Cañón de Tanque con Retroceso Crítico
% =========================================================================
% REFERENCIA: Tarea 2 - Problema 4 (Vibraciones Libres Amortiguadas)
% SIMULADOR ASOCIADO: sim4_canonRetroceso.m
% IMAGEN DEL SISTEMA: CanonRetroceso.png
%
% ENUNCIADO:
%   El cañón de un tanque posee un peso W = 1500 lbs y un amortiguador con
%   c = 1100 lbs-s/ft.
%   Determinar:
%     a) La constante de rigidez K del resorte para que el cañón regrese a su
%        posición inicial en el menor tiempo posible sin oscilar (crítico).
%     b) El tiempo necesario para moverse 2/3 de su posición máxima en el retorno.
% =========================================================================

clear; clc; close all;

% 0. Rutas hacia VM y Motor
subfolderActual = fileparts(mfilename('fullpath'));
addpath(fullfile(subfolderActual, '..'));       % Contiene VM.m
addpath(fullfile(subfolderActual, '..', '..')); % Contiene Motor.m

fprintf('=========================================================================\n');
fprintf('  CASO: Cañón con Mecanismo de Retroceso Crítico (Tarea 2 - Prob 4)      \n');
fprintf('=========================================================================\n');

%% 1. Parámetros en Sistema Inglés
W4   = 1500;            % Peso [lbs]
g_us = 32.2;            % Gravedad [ft/s^2]
m4   = W4 / g_us;       % Masa [slug]
c4   = 1100;            % Amortiguador [lbs*s/ft]

%% 2. Rigidez K para amortiguamiento crítico (zeta = 1)
[eqs4, S4] = VM.ecCritA();
datos4 = struct('m', m4, 'c', c4);
R4 = Motor.despejar(eqs4, S4, datos4);

k4  = double(R4.k);     % [lb/ft]
wn4 = double(R4.wn);    % [rad/s]

%% 3. Tiempo para recorrer 2/3 de Xmax
% Curva de retorno normalizada: (1 + wn*t)*exp(-wn*t) = 2/3
x_norm_sym = (1 + S4.wn * S4.t) * exp(-S4.wn * S4.t);
x_norm_sym = subs(x_norm_sym, S4.wn, wn4);
x_norm_fun = matlabFunction(x_norm_sym, 'Vars', S4.t);

t_exacto = fzero(@(t) x_norm_fun(t) - 2/3, 0.1);
t_clave  = (1.4054 - 1) / wn4;   % Aproximación lineal de la clave docente

fprintf('Resultados:\n');
fprintf('   a) Rigidez del resorte:   K  = %.2f lb/ft (clave: 6494 lb/ft)\n', k4);
fprintf('      Frecuencia natural:    wn = %.4f rad/s\n', wn4);
fprintf('   b) Tiempo para recorrer 2/3 de Xmax:\n');
fprintf('      - Solución exacta:     t  = %.4f s (evaluación no lineal fzero)\n', t_exacto);
fprintf('      - Solución de clave:   t  = %.4f s (clave docente: 0.034 s)\n\n', t_clave);

%% 4. Esquema Físico del Sistema
imgFile = fullfile(subfolderActual, 'CanonRetroceso.png');
if exist(imgFile, 'file')
    fig = figure('Name', 'Esquema Físico - Retroceso del Cañón', 'Color', 'w', 'Position', [100, 100, 650, 650]);
    image(imread(imgFile));
    axis image off;
    title('Esquema del Mecanismo de Retroceso', 'FontSize', 12, 'FontWeight', 'bold');
end
