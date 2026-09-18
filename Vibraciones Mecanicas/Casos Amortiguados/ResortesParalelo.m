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

%% 4. Esquema Físico del Sistema
imgFile = fullfile(subfolderActual, 'ResortesParalelo.png');
if exist(imgFile, 'file')
    fig = figure('Name', 'Esquema Físico - Resortes en Paralelo', 'Color', 'w', 'Position', [100, 100, 650, 650]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico (Resortes en Paralelo)', 'FontSize', 12, 'FontWeight', 'bold');
end
