%% SerieParalelo.m - Resortes en Serie y Amortiguadores en Paralelo
% =========================================================================
% REFERENCIA: Tarea 2 - Problema 7 (Vibraciones Libres Amortiguadas)
% SIMULADOR ASOCIADO: sim7_serieParalelo.m
% IMAGEN DEL SISTEMA: SerieParalelo.png
%
% ENUNCIADO:
%   Un cuerpo de masa m = 0.4 kg se suelta desde el reposo con x0 = 25.0 mm (v0 = 0).
%   El sistema está conectado a:
%     - Dos resortes en serie: k1 = 2930 N/m, k2 = 1760 N/m
%     - Dos amortiguadores en paralelo: c1 = 37 N*s/m, c2 = 37 N*s/m
%   Determinar:
%     a) El tiempo para alcanzar el máximo desplazamiento.
%     b) El desplazamiento máximo alcanzado (x_max).
%     c) La velocidad a los 0.05 s de iniciado el movimiento.
% =========================================================================

clear; clc; close all;

% 0. Rutas hacia VM y Motor
subfolderActual = fileparts(mfilename('fullpath'));
addpath(fullfile(subfolderActual, '..'));       % Contiene VM.m
addpath(fullfile(subfolderActual, '..', '..')); % Contiene Motor.m

fprintf('=========================================================================\n');
fprintf('  CASO: Resortes en Serie y Amortiguadores en Paralelo (Tarea 2 - 7)     \n');
fprintf('=========================================================================\n');

%% 1. Parámetros y combinaciones equivalentes
m7   = 0.4;                               % Masa [kg]
keq7 = VM.datosSerieR([2930, 1760]);       % Serie: (2930*1760)/(2930+1760) = 1099.53 N/m
ceq7 = VM.datosParalelos([37, 37]);       % Paralelo: 37 + 37 = 74 N*s/m
x0_7 = 0.025;                             % 25 mm = 0.025 m
v0_7 = 0;                                 % Reposo

%% 2. Clasificación y resolución sobreamortiguada
[reg7, wn7, ccr7, z7] = VM.clasifA('m', m7, 'k', keq7, 'c', ceq7);
[eqs7, S7] = VM.ecSobreA();
datos7 = struct('m', m7, 'k', keq7, 'c', ceq7, 'x0', x0_7, 'v0', v0_7);
R7 = Motor.despejar(eqs7, S7, datos7, 'libres', {'t'});
resNum7 = Motor.numerico(R7, datos7, S7);

x7_sym = simplify(R7.x);
v7_sym = simplify(diff(x7_sym, S7.t));

%% 3. matlabFunction
x7_fun = matlabFunction(x7_sym, 'Vars', S7.t);
v7_fun = matlabFunction(v7_sym, 'Vars', S7.t);

t_eval = 0.05;
v7_005 = v7_fun(t_eval);

fprintf('Resultados:\n');
fprintf('   Régimen:                 %s (zeta = %.4f > 1)\n', reg7, z7);
fprintf('   Frecuencia natural:      wn = %.4f rad/s\n', wn7);
fprintf('   Raíces características:  s1 = %.4f s^-1, s2 = %.4f s^-1\n', ...
    resNum7.s1, resNum7.s2);
fprintf('   a) Tiempo para max despl: t = 0.0000 s (al soltarse del reposo en x0, decae monotónicamente)\n');
fprintf('      (Nota: en clave manuscrita indicaron 0.013 s por lectura de gráfica)\n');
fprintf('   b) Desplazamiento máximo: x_max = %.4f m (25.0 mm)\n', x0_7);
fprintf('   c) Velocidad en t = 0.05s: v = %.4f m/s (clave: -0.20 m/s)\n\n', v7_005);

fprintf('Ecuaciones de movimiento:\n');
fprintf('   x(t) = %s\n', char(vpa(x7_sym, 5)));
fprintf('   v(t) = %s\n\n', char(vpa(v7_sym, 5)));

%% 4. Esquema Físico del Sistema
imgFile = fullfile(subfolderActual, 'SerieParalelo.png');
if exist(imgFile, 'file')
    fig = figure('Name', 'Esquema Físico - Serie y Paralelo', 'Color', 'w', 'Position', [100, 100, 650, 650]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico (Serie y Paralelo)', 'FontSize', 12, 'FontWeight', 'bold');
end
