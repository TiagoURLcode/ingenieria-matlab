%% OscilogramaMotor.m - Identificación de Parámetros desde Oscilograma
% =========================================================================
% REFERENCIA: Tarea 2 - Problema 2 (Vibraciones Libres Amortiguadas)
% SIMULADOR ASOCIADO: sim2_oscilogramaMotor.m
% IMAGEN DEL SISTEMA: OscilogramaMotor.png
%
% ENUNCIADO:
%   Un motor eléctrico de peso W = 500 N se encuentra montado sobre un soporte.
%   Se registra su movimiento libre en un oscilograma con los siguientes datos:
%     - Picos sucesivos en t = [0, 0.2, 0.4, 0.6] s
%     - Amplitudes correspondientes x = [8, 4, 2, 1] mm
%   Determinar:
%     a) Tipo de amortiguamiento (régimen y razón zeta).
%     b) Constante de rigidez k del soporte.
%     c) Coeficiente de amortiguamiento c.
%     d) Frecuencia amortiguada wd y frecuencia natural wn.
% =========================================================================

clear; clc; close all;

% 0. Rutas hacia VM y Motor
subfolderActual = fileparts(mfilename('fullpath'));
addpath(fullfile(subfolderActual, '..'));       % Contiene VM.m
addpath(fullfile(subfolderActual, '..', '..')); % Contiene Motor.m

fprintf('=========================================================================\n');
fprintf('  CASO: Oscilograma del Motor Eléctrico (Tarea 2 - Prob 2)               \n');
fprintf('=========================================================================\n');

%% 1. Datos experimentales del oscilograma
g2    = 9.81;            % [m/s^2]
W2    = 500;             % Peso [N]
m2    = W2 / g2;         % Masa [kg]
x1_2  = 8.00e-3;         % Amplitud pico 1 [m] (8 mm en t = 0)
x2_2  = 4.00e-3;         % Amplitud pico 2 [m] (4 mm en t = 0.2 s)
n2    = 1;               % Un ciclo entre picos consecutivos
taud2 = 0.200;           % Período amortiguado [s]

%% 2. Despeje inverso utilizando VM y Motor
[eqs2, S2] = VM.ecSubA();
datos2 = struct('m', m2, 'x1', x1_2, 'x2', x2_2, 'n', n2, 'taud', taud2, ...
                'x0', x1_2, 'v0', 0);
R2 = Motor.despejar(eqs2, S2, datos2, 'libres', {'t'});

z2  = double(R2.z);
k2  = double(R2.k);
c2  = double(R2.c);
wd2 = double(R2.wd);
wn2 = double(R2.wn);

x2_sym = simplify(R2.x);
x2_fun = matlabFunction(x2_sym, 'Vars', S2.t);

fprintf('Resultados del análisis inverso:\n');
fprintf('   a) Régimen:               Sub-amortiguado (zeta = %.4f < 1)\n', z2);
fprintf('   b) Constante de rigidez:  k  = %.2f N/m (%.2f kN/m) (clave: ~50800 N/m)\n', k2, k2/1e3);
fprintf('   c) Coef. amortiguamiento: c  = %.2f N*s/m (clave: 353.3 N*s/m)\n', c2);
fprintf('   d) Frec. amortiguada:     wd = %.4f rad/s (f = %.2f Hz)\n', wd2, wd2/(2*pi));
fprintf('      Frec. natural:         wn = %.4f rad/s\n\n', wn2);

%% 3. Gráfica integrada con el esquema
fig = figure('Name', 'Oscilograma del Motor - Tarea 2', 'Color', 'w', 'Position', [120, 100, 1100, 500]);

% Panel izquierdo: Esquema físico
imgFile = fullfile(subfolderActual, 'OscilogramaMotor.png');
if exist(imgFile, 'file')
    subplot(1, 2, 1);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico del Motor y Soporte', 'FontSize', 11, 'FontWeight', 'bold');
end

% Panel derecho: Reconstrucción del oscilograma
subplot(1, 2, 2);
t_picos = [0, 0.2, 0.4, 0.6];
x_picos = [8, 4, 2, 1]; % [mm]
t_plot = linspace(0, 0.8, 600);

plot(t_plot, x2_fun(t_plot)*1e3, 'LineWidth', 1.8, 'Color', [0.00 0.45 0.74]); hold on;
env_sup = (x1_2 * exp(-z2 * wn2 * t_plot)) * 1e3;
plot(t_plot, env_sup, 'k--', 'LineWidth', 1.2);
plot(t_plot, -env_sup, 'k--', 'LineWidth', 1.2);
plot(t_picos, x_picos, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

grid on;
title('Oscilograma Ajustado y Envolvente Teórica');
xlabel('Tiempo t [s]'); ylabel('Desplazamiento x [mm]');
legend('Curva x(t)', 'Envolvente \pm X e^{-\zeta \omega_n t}', 'Picos medidos', 'Location', 'northeast');
