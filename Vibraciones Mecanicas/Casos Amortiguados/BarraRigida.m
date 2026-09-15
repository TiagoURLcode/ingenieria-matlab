%% BarraRigida.m - Barra Rígida Articulada con Resorte y Amortiguador
% =========================================================================
% REFERENCIA: Tarea 2 - Problema 5 (Vibraciones Libres Amortiguadas)
% SIMULADOR ASOCIADO: sim5_barraRigida.m
% IMAGEN DEL SISTEMA: BarraRigida.png
%
% ENUNCIADO:
%   Una barra rígida horizontal homogénea de masa M y longitud l está articulada
%   en su extremo A.
%   En el punto B (a una distancia l/2 de A) se conecta un resorte k al techo.
%   En el extremo D (a una distancia l de A) se conecta un amortiguador c al piso.
%   Determinar:
%     a) La ecuación diferencial de movimiento general para oscilaciones pequeñas.
%     b) El coeficiente de amortiguamiento crítico del sistema (c_cr).
% =========================================================================

clear; clc; close all;

% 0. Rutas hacia VM y Motor
subfolderActual = fileparts(mfilename('fullpath'));
addpath(fullfile(subfolderActual, '..'));       % Contiene VM.m
addpath(fullfile(subfolderActual, '..', '..')); % Contiene Motor.m

fprintf('=========================================================================\n');
fprintf('  CASO: Barra Rígida Articulada con Resorte y Amortiguador (Tarea 2 - 5) \n');
fprintf('=========================================================================\n');

%% 1. Deducción Analítica (Momento respecto al pivote A)
% I_A = (1/3) * M * l^2
% Resorte en l/2:  M_k = -(1/4)*k*l^2 * theta
% Amortiguador en l: M_c = -c*l^2 * theta_punto
% Sumatoria de Momentos:
%   (1/3)*M*l^2 * theta'' + c*l^2 * theta' + (1/4)*k*l^2 * theta = 0
% Dividiendo entre (1/3)*M*l^2:
%   theta'' + (3*c/M)*theta' + (3*k/(4*M))*theta = 0
%
% Frecuencia natural:
%   wn = sqrt(3*k / (4*M))
% Amortiguamiento crítico (zeta = 1):
%   3*c_cr / M = 2*wn = 2*sqrt(3*k / (4*M)) = sqrt(3*k / M)
%   c_cr = sqrt(3*k*M) / 3

fprintf('Resultados analíticos:\n\n');
fprintf('a) Ecuación de movimiento general:\n');
fprintf('   (1/3)*M*l^2 * theta'''' + c*l^2 * theta'' + (1/4)*k*l^2 * theta = 0\n\n');
fprintf('   Forma normalizada estándar:\n');
fprintf('   theta'''' + (3*c/M)*theta'' + (3*k/(4*M))*theta = 0\n\n');

fprintf('b) Coeficiente de amortiguamiento crítico:\n');
fprintf('   c_cr = sqrt(3*k*M) / 3\n');
fprintf('   (En términos rotacionales: C_cr_rot = (1/2)*l^2*sqrt(3*k*M))\n\n');

%% 2. Demostración numérica y gráfica integrada
M_test = 3;      % [kg]
l_test = 0.5;    % [m]
k_test = 300;    % [N/m]

c_cr_test = sqrt(3 * k_test * M_test) / 3;
wn_test   = sqrt(3 * k_test / (4 * M_test));

% Parámetros subamortiguados de ejemplo (zeta = 0.35)
z_test = 0.35;
c_test = z_test * c_cr_test;
wd_test = wn_test * sqrt(1 - z_test^2);

syms t
theta_sym = 0.1 * exp(-z_test*wn_test*t) * (cos(wd_test*t) + (z_test*wn_test/wd_test)*sin(wd_test*t));
theta_fun = matlabFunction(theta_sym, 'Vars', t);

fprintf('Ejemplo numérico con M = %g kg, l = %g m, k = %g N/m:\n', M_test, l_test, k_test);
fprintf('   c_cr calculado = %.4f N*s/m\n', c_cr_test);
fprintf('   wn calculado   = %.4f rad/s\n\n', wn_test);

%% 3. Gráfica integrada con el esquema
fig = figure('Name', 'Barra Rígida Articulada - Tarea 2', 'Color', 'w', 'Position', [100, 100, 1100, 500]);

% Panel izquierdo: Esquema físico
imgFile = fullfile(subfolderActual, 'BarraRigida.png');
if exist(imgFile, 'file')
    subplot(1, 2, 1);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico de la Barra Articulada', 'FontSize', 11, 'FontWeight', 'bold');
end

% Panel derecho: Oscilación rotacional
subplot(1, 2, 2);
t_vec = linspace(0, 2, 500);
plot(t_vec, theta_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.00 0.45 0.74]);
grid on;
title(sprintf('Oscilación Angular \\theta(t) (\\zeta = %.2f, c_{cr} = %.2f N*s/m)', z_test, c_cr_test));
xlabel('Tiempo t [s]'); ylabel('\theta(t) [rad]');
