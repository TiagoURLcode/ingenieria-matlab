%% DosResortes.m - Masa entre Dos Resortes Opuestos
% =========================================================================
% REFERENCIA: Tarea 2 - Problema 8 (Vibraciones Libres Amortiguadas)
% SIMULADOR ASOCIADO: sim8_dosResortes.m
% IMAGEN DEL SISTEMA: DosResortes.png
%
% ENUNCIADO:
%   Un bloque de masa m = 0.4 kg se encuentra colocado entre dos resortes
%   opuestos con k1 = 40 N/m y k2 = 20 N/m, ambos indeformados en x = 0.
%   El sistema cuenta con un amortiguador c = 5 N*s/m.
%   Parte desde el reposo (v0 = 0) con un desplazamiento inicial x0 = 50.0 mm.
%   Determinar:
%     a) La función analítica de posición x(t).
%     b) La función analítica de velocidad v(t).
% =========================================================================

clear; clc; close all;

% 0. Rutas hacia VM y Motor
subfolderActual = fileparts(mfilename('fullpath'));
addpath(fullfile(subfolderActual, '..'));       % Contiene VM.m
addpath(fullfile(subfolderActual, '..', '..')); % Contiene Motor.m

fprintf('=========================================================================\n');
fprintf('  CASO: Masa entre Dos Resortes Opuestos (Tarea 2 - Prob 8)              \n');
fprintf('=========================================================================\n');

%% 1. Parámetros del problema
m8   = 0.4;                           % Masa [kg]
keq8 = VM.datosParalelos([40, 20]);   % Deformación solidaria -> paralelo: 40 + 20 = 60 N/m
c8   = 5;                             % Amortiguador [N*s/m]
x0_8 = 0.050;                         % 50 mm = 0.050 m
v0_8 = 0;                             % Reposo

%% 2. Clasificación y resolución con VM y Motor
[reg8, wn8, ccr8, z8] = VM.clasifA('m', m8, 'k', keq8, 'c', c8);
[eqs8, S8] = VM.ecSubA();
datos8 = struct('m', m8, 'k', keq8, 'c', c8, 'x0', x0_8, 'v0', v0_8);
R8 = Motor.despejar(eqs8, S8, datos8, 'libres', {'t'});

x8_sym = simplify(R8.x);
v8_sym = simplify(diff(x8_sym, S8.t));

%% 3. matlabFunction
x8_fun = matlabFunction(x8_sym, 'Vars', S8.t);
v8_fun = matlabFunction(v8_sym, 'Vars', S8.t);

fprintf('Resultados:\n');
fprintf('   Régimen:            %s (zeta = %.4f < 1)\n', reg8, z8);
fprintf('   Frec. natural:      wn = %.4f rad/s\n', wn8);
fprintf('   Frec. amortiguada:  wd = %.4f rad/s\n', double(R8.wd));
fprintf('   Amort. crítico:     ccr = %.4f N*s/m\n', ccr8);
fprintf('   Período amort.:     taud = %.4f s\n\n', double(R8.taud));

fprintf('Ecuaciones de movimiento:\n');
fprintf('   a) Ecuación de posición x(t):\n');
fprintf('      x(t) = %s\n', char(vpa(x8_sym, 5)));
fprintf('   b) Ecuación de velocidad v(t):\n');
fprintf('      v(t) = %s\n\n', char(vpa(v8_sym, 5)));

%% 4. Gráfica integrada con el esquema
fig = figure('Name', 'Dos Resortes Opuestos - Tarea 2', 'Color', 'w', 'Position', [100, 100, 1100, 520]);

% Panel izquierdo: Esquema físico
imgFile = fullfile(subfolderActual, 'DosResortes.png');
if exist(imgFile, 'file')
    subplot(2, 2, [1 3]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico (Dos Resortes Opuestos)', 'FontSize', 11, 'FontWeight', 'bold');
end

% Panel derecho superior: x(t) y envolvente
t_vec = linspace(0, 1.5, 600);
env_val = (double(R8.X) * exp(-z8 * wn8 * t_vec)) * 1e3;

subplot(2, 2, 2);
plot(t_vec, x8_fun(t_vec)*1e3, 'LineWidth', 1.8, 'Color', [0.00 0.45 0.74]); hold on;
plot(t_vec, env_val, 'k--', 'LineWidth', 1.2);
plot(t_vec, -env_val, 'k--', 'LineWidth', 1.2);
yline(0, 'k:');
grid on; ylabel('x(t) [mm]');
title('Oscilación Amortiguada y Envolvente');
legend('x(t)', 'Envolvente \pm X e^{-\zeta \omega_n t}', 'Location', 'northeast');

% Panel derecho inferior: v(t)
subplot(2, 2, 4);
plot(t_vec, v8_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]);
yline(0, 'k:');
grid on; xlabel('Tiempo t [s]'); ylabel('v(t) [m/s]');
title('Velocidad v(t)');
