%% ResortesParalelo.m - Dos Resortes en Paralelo y Amortiguador
% =========================================================================
% REFERENCIA: Tarea 2 - Problema 6 (Vibraciones Libres Amortiguadas)
% SIMULADOR ASOCIADO: sim6_resortesParalelo.m
% IMAGEN DEL SISTEMA: ResortesParalelo.png
%
% ENUNCIADO:
%   Un cuerpo de masa m = 0.2 kg está sujeto a dos resortes en paralelo con
%   k1 = 20 N/m y k2 = 30 N/m. El factor de amortiguamiento es zeta = 0.25.
%   Parte desde el origen x0 = 0 con una velocidad inicial v0 = 4 m/s.
%   Determinar:
%     a) La ecuación de posición x(t).
%     b) La función de velocidad v(t).
%     c) El valor del coeficiente de amortiguamiento c.
%     d) La posición en t = 0.1 s.
% =========================================================================

clear; clc; close all;

% 0. Rutas hacia VM y Motor
subfolderActual = fileparts(mfilename('fullpath'));
addpath(fullfile(subfolderActual, '..'));       % Contiene VM.m
addpath(fullfile(subfolderActual, '..', '..')); % Contiene Motor.m

fprintf('=========================================================================\n');
fprintf('  CASO: Dos Resortes en Paralelo y Amortiguador (Tarea 2 - Prob 6)       \n');
fprintf('=========================================================================\n');

%% 1. Parámetros del problema
m6   = 0.2;                         % Masa [kg]
keq6 = VM.datosParalelos([20, 30]); % Paralelo: 20 + 30 = 50 N/m
z6   = 0.25;                        % Factor zeta
x0_6 = 0;                           % [m]
v0_6 = 4.0;                         % [m/s]

%% 2. Resolución con VM y Motor
[eqs6, S6] = VM.ecSubA();
datos6 = struct('m', m6, 'k', keq6, 'z', z6, 'x0', x0_6, 'v0', v0_6);
R6 = Motor.despejar(eqs6, S6, datos6, 'libres', {'t'});

x6_sym = simplify(R6.x);
v6_sym = simplify(diff(x6_sym, S6.t));
c6     = double(R6.c);

%% 3. matlabFunction
x6_fun = matlabFunction(x6_sym, 'Vars', S6.t);
v6_fun = matlabFunction(v6_sym, 'Vars', S6.t);

t_eval = 0.1;
x6_01  = x6_fun(t_eval);

fprintf('Resultados:\n');
fprintf('   a) Ecuación de posición x(t):\n');
fprintf('      x(t) = %s\n', char(vpa(x6_sym, 5)));
fprintf('   b) Función de velocidad v(t):\n');
fprintf('      v(t) = %s\n', char(vpa(v6_sym, 5)));
fprintf('   c) Coeficiente c:   c = %.4f N*s/m (clave: 1.58 N*s/m)\n', c6);
fprintf('   d) Posición en 0.1s: x(0.1s) = %.4f m (%.2f mm) (clave: 0.1758 m)\n\n', ...
    x6_01, x6_01 * 1e3);

%% 4. Gráfica integrada con el esquema
fig = figure('Name', 'Resortes en Paralelo - Tarea 2', 'Color', 'w', 'Position', [100, 100, 1100, 520]);

% Panel izquierdo: Esquema físico
imgFile = fullfile(subfolderActual, 'ResortesParalelo.png');
if exist(imgFile, 'file')
    subplot(2, 2, [1 3]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico (Resortes en Paralelo)', 'FontSize', 11, 'FontWeight', 'bold');
end

% Panel derecho superior: x(t)
t_vec = linspace(0, 1.2, 500);
subplot(2, 2, 2);
plot(t_vec, x6_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.00 0.45 0.74]); hold on;
plot(t_eval, x6_01, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
grid on; ylabel('x(t) [m]');
title('Posición x(t)');
legend('x(t)', sprintf('x(0.1s) = %.4f m', x6_01), 'Location', 'northeast');

% Panel derecho inferior: v(t)
subplot(2, 2, 4);
plot(t_vec, v6_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]);
grid on; xlabel('Tiempo t [s]'); ylabel('v(t) [m/s]');
title('Velocidad v(t)');
