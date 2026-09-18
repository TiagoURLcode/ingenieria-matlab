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

%% 5. Esquema Físico del Sistema
imgFile = fullfile(subfolderActual, 'DosResortes.png');
if exist(imgFile, 'file')
    fig = figure('Name', 'Esquema Físico - Dos Resortes Opuestos', 'Color', 'w', 'Position', [100, 100, 650, 650]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico (Dos Resortes Opuestos)', 'FontSize', 12, 'FontWeight', 'bold');
end
