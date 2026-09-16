%% ImpactoPlastico.m - Impacto Plástico y Vibración Amortiguada
% =========================================================================
% REFERENCIA: Tarea 2 - Problema 1 (Vibraciones Libres Amortiguadas)
% SIMULADOR ASOCIADO: sim1_impactoPlastico.m
% IMAGEN DEL SISTEMA: ImpactoPlastico.png
%
% ENUNCIADO:
%   Un bloque de masa m1 = 4.00 kg cae desde una altura h = 800 mm sobre un
%   bloque de masa m2 = 9.00 kg sin rebotar (impacto plástico).
%   El sistema cuenta con un resorte k = 1500 N/m y un amortiguador c = 230 N*s/m.
%   Determinar la distancia que se desplaza cuando la velocidad es cero (x_max)
%   y el tiempo que tarda en alcanzar dicha posición.
%
% NOTA SOBRE matlabFunction:
%   Convierte la expresión simbólica analítica x(t) en una función numérica
%   vectorizada @(t) ..., permitiendo calcular x_max en microsegundos y
%   graficar de forma eficiente.
% =========================================================================

clear; clc; close all;

% 0. Rutas hacia VM y Motor
subfolderActual = fileparts(mfilename('fullpath'));
addpath(fullfile(subfolderActual, '..'));       % Contiene VM.m
addpath(fullfile(subfolderActual, '..', '..')); % Contiene Motor.m

fprintf('=========================================================================\n');
fprintf('  CASO: Impacto Plástico y Vibración Amortiguada (Tarea 2 - Prob 1)      \n');
fprintf('=========================================================================\n');

%% 1. Parámetros
g1   = 9.81;    % [m/s^2]
m1_1 = 4.00;    % Masa que cae [kg]
m1_2 = 9.00;    % Masa receptora [kg]
h1   = 0.800;   % Altura de caída [m]
k1   = 1500;    % Rigidez del resorte [N/m]
c1   = 230;     % Amortiguamiento [N*s/m]

%% 2. Cinemática de caída e impacto plástico
v1_caida = sqrt(2 * g1 * h1);           % Velocidad antes del choque [m/s]
m_eq1    = m1_1 + m1_2;                 % Masa total acoplada [kg]
v0_1     = (m1_1 * v1_caida) / m_eq1;   % Velocidad inicial de vibración [m/s]
x0_1     = 0;                           % Medido desde el contacto inicial [m]

%% 3. Resolución con VM y Motor
[reg1, wn1, ccr1, z1] = VM.clasifA('m', m_eq1, 'k', k1, 'c', c1);
[eqs1, S1] = VM.ecSubA();
datos1 = struct('m', m_eq1, 'k', k1, 'c', c1, 'x0', x0_1, 'v0', v0_1);
R1 = Motor.despejar(eqs1, S1, datos1, 'libres', {'t'});

x1_sym = simplify(R1.x);
v1_sym = simplify(diff(x1_sym, S1.t));

%% 4. matlabFunction
x1_fun = matlabFunction(x1_sym, 'Vars', S1.t);
v1_fun = matlabFunction(v1_sym, 'Vars', S1.t);

%% 5. Instante de velocidad cero y desplazamiento máximo
wd1     = double(R1.wd);
t_pico1 = double(atan(wd1 / (z1 * wn1)) / wd1);
x_max1  = x1_fun(t_pico1);

fprintf('Resultados:\n');
fprintf('   Régimen:            %s (zeta = %.4f < 1)\n', reg1, z1);
fprintf('   Velocidad post-choque: v0 = %.4f m/s\n', v0_1);
fprintf('   Frec. natural:      wn = %.4f rad/s\n', wn1);
fprintf('   Frec. amortiguada:  wd = %.4f rad/s\n', wd1);
fprintf('   Tiempo en v = 0:    t  = %.4f s (clave: 0.099 s)\n', t_pico1);
fprintf('   Desplazamiento max: x  = %.4f m (%.2f mm) (clave: 0.047 m / 47 mm)\n\n', ...
    x_max1, x_max1 * 1e3);

fprintf('Ecuaciones analíticas:\n');
fprintf('   x(t) = %s\n', char(vpa(x1_sym, 5)));
fprintf('   v(t) = %s\n\n', char(vpa(v1_sym, 5)));

%% 6. Esquema Físico del Sistema
imgFile = fullfile(subfolderActual, 'ImpactoPlastico.png');
if exist(imgFile, 'file')
    fig = figure('Name', 'Esquema Físico - Impacto Plástico', 'Color', 'w', 'Position', [100, 100, 650, 650]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico del Impacto Plástico', 'FontSize', 12, 'FontWeight', 'bold');
end
