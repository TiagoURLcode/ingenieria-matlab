%% VagonTope.m - Vagón de Ferrocarril contra Tope Amortiguado
% =========================================================================
% REFERENCIA: Tarea 2 - Problema 3 (Vibraciones Libres Amortiguadas)
% SIMULADOR ASOCIADO: sim3_vagonTope.m
% IMAGEN DEL SISTEMA: VagonTope.png
%
% ENUNCIADO:
%   Un vagón de ferrocarril de masa m = 2000 kg que viaja a una velocidad
%   v0 = 10.0 m/s choca contra un tope amortiguado.
%   El tope posee una rigidez equivalente k = 80.0 N/mm (80,000 N/m)
%   y un amortiguamiento c = 20.0 N*s/mm (20,000 N*s/m).
%   Determinar:
%     a) La compresión máxima del tope (x_max).
%     b) El tiempo necesario para alcanzar dicha compresión máxima (t_max).
% =========================================================================

clear; clc; close all;

% 0. Rutas hacia VM y Motor
subfolderActual = fileparts(mfilename('fullpath'));
addpath(fullfile(subfolderActual, '..'));       % Contiene VM.m
addpath(fullfile(subfolderActual, '..', '..')); % Contiene Motor.m

fprintf('=========================================================================\n');
fprintf('  CASO: Vagón de Ferrocarril contra Tope Amortiguado (Tarea 2 - Prob 3)  \n');
fprintf('=========================================================================\n');

%% 1. Parámetros en unidades SI
m3   = 2000;             % Masa del vagón [kg]
v0_3 = 10.0;             % Velocidad de impacto [m/s]
x0_3 = 0;                % Compresión inicial [m]
keq3 = 80.0 * 1e3;       % 80 N/mm = 80,000 N/m
c3   = 20.0 * 1e3;       % 20 N*s/mm = 20,000 N*s/m

%% 2. Clasificación y resolución simbólica
[reg3, wn3, ccr3, z3] = VM.clasifA('m', m3, 'k', keq3, 'c', c3);
[eqs3, S3] = VM.ecSubA();
datos3 = struct('m', m3, 'k', keq3, 'c', c3, 'x0', x0_3, 'v0', v0_3);
R3 = Motor.despejar(eqs3, S3, datos3, 'libres', {'t'});

x3_sym = simplify(R3.x);
v3_sym = simplify(diff(x3_sym, S3.t));

%% 3. Funciones numéricas con matlabFunction
x3_fun = matlabFunction(x3_sym, 'Vars', S3.t);
v3_fun = matlabFunction(v3_sym, 'Vars', S3.t);

%% 4. Compresión máxima y tiempo
wd3    = double(R3.wd);
t_max3 = double(atan(wd3 / (z3 * wn3)) / wd3);
x_max3 = x3_fun(t_max3);

fprintf('Resultados:\n');
fprintf('   Régimen:              %s (zeta = %.4f < 1)\n', reg3, z3);
fprintf('   Frecuencia natural:   wn = %.4f rad/s\n', wn3);
fprintf('   Frec. amortiguada:    wd = %.4f rad/s\n', wd3);
fprintf('   Amortiguamiento crit: ccr = %.2f N*s/m\n', ccr3);
fprintf('   Tiempo de compresión: t_max = %.5f s (clave/sim3: 0.17018 s)\n', t_max3);
fprintf('   Compresión máxima:    x_max = %.5f m (%.2f mm) (clave/sim3: 0.67523 m)\n\n', ...
    x_max3, x_max3 * 1e3);

fprintf('Ecuaciones de movimiento:\n');
fprintf('   x(t) = %s\n', char(vpa(x3_sym, 5)));
fprintf('   v(t) = %s\n\n', char(vpa(v3_sym, 5)));

%% 5. Gráfica integrada con el esquema
fig = figure('Name', 'Vagón contra Tope - Tarea 2', 'Color', 'w', 'Position', [100, 100, 1100, 520]);

% Panel izquierdo: Esquema físico
imgFile = fullfile(subfolderActual, 'VagonTope.png');
if exist(imgFile, 'file')
    subplot(2, 2, [1 3]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico del Tope Amortiguador', 'FontSize', 11, 'FontWeight', 'bold');
end

% Panel derecho superior: Compresión x(t)
t_span = linspace(0, 0.8, 500);
subplot(2, 2, 2);
plot(t_span, x3_fun(t_span), 'LineWidth', 1.8, 'Color', [0.00 0.45 0.74]); hold on;
plot(t_max3, x_max3, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
grid on; ylabel('Compresión x(t) [m]');
title('Compresión del Tope x(t)');
legend('x(t)', sprintf('x_{max} = %.4f m', x_max3), 'Location', 'northeast');

% Panel derecho inferior: Velocidad v(t)
subplot(2, 2, 4);
plot(t_span, v3_fun(t_span), 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]); hold on;
plot(t_max3, 0, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
yline(0, 'k--');
grid on; xlabel('Tiempo t [s]'); ylabel('Velocidad v(t) [m/s]');
title('Velocidad del Vagón v(t)');
legend('v(t)', 'v = 0', 'Location', 'northeast');
