%% ResorteMasaY.m - Análisis de Regímenes Amortiguados Variando la Masa M
% =========================================================================
% ENUNCIADO EXACTO (Segundo Examen Parcial):
%   "Para un sistema amortiguado, siendo M= 3,000 Kg, k= 5.00 kN/m y
%   c=1.20 kN-m/s. Realice las variaciones para que el sistema cambie de
%   sub-amortiguado a críticamente amortiguado y de críticamente amortiguado
%   a sobre-amortiguado. Realice las gráficas que se solicitan para las
%   tres situaciones. El sistema parte del reposo, tomando en cuenta la
%   deflexión inicial del resorte."
%
% =========================================================================
% ¿POR QUÉ NO SE CONSIDERA EL AMORTIGUADOR EN LA DEFLEXIÓN INICIAL / ESTÁTICA?
% =========================================================================
% 1. Dependencia exclusiva de la velocidad:
%    La fuerza de un amortiguador viscoso es puramente dinámica y disipativa:
%       F_c = c * v = c * dy/dt
%    No depende de la posición (y), sino de la velocidad relativa (v).
%
% 2. Condición estática (equilibrio antes de soltar):
%    En la posición de equilibrio estático o en reposo, la velocidad es nula:
%       v = 0  ==>  F_c = c * 0 = 0
%    El amortiguador NO ofrece ninguna resistencia estática ni sostiene peso.
%    Por tanto, la sumatoria de fuerzas en equilibrio estático es:
%       Sigma F_y = M*g - k*delta_st = 0  ==>  delta_st = x0 = (M*g) / k
%
% 3. En el instante inicial (t = 0):
%    Como el enunciado indica que "parte del reposo" (v(0) = v0 = 0), en t = 0:
%       F_c(0) = c * v0 = c * 0 = 0
%    El amortiguador comienza a actuar únicamente después de que el sistema
%    adquiere velocidad (t > 0).
%
% 4. Cancelación en la ecuación de movimiento dinámico:
%    Al medir la coordenada y(t) desde la posición de equilibrio estático:
%       Sigma F_y = M*g - k*(y + delta_st) - c*(dy/dt) = M*(d^2y/dt^2)
%    Como k*delta_st = M*g, el peso se cancela idénticamente con la fuerza
%    estática del resorte:
%       M*y'' + c*y' + k*y = 0
% =========================================================================
% ¿QUÉ HACE matlabFunction Y POR QUÉ SE UTILIZA?
% =========================================================================
% 1. ¿Qué es?
%    matlabFunction es una función del Symbolic Math Toolbox que toma una
%    expresión analítica simbólica (creada con sym, solve, diff, etc.) y la
%    transforma en un "function handle" numérico ejecutable de MATLAB
%    (por ejemplo, @(t) ... o @(t, m) ...).
%
% 2. ¿Por qué NO usar double(x_sym)?
%    Si una expresión simbólica todavía contiene variables libres (como 't'),
%    la llamada double(x_sym) falla con un error porque MATLAB no puede
%    convertir una fórmula con incógnitas en un número flotante.
%
% 3. ¿Por qué NO usar subs(x_sym, S.t, t_vector)?
%    La función subs es interpretada simbólicamente, es extremadamente lenta
%    y no está optimizada para evaluar cientos o miles de puntos en una gráfica.
%
% 4. ¿Qué ventaja da matlabFunction?
%    - Compila la expresión analítica a código numérico vectorizado puro
%      (usando operadores elemento a elemento: .*, ./, .^, exp, cos, sin).
%    - Permite evaluar instantáneamente vectores enteros de tiempo:
%         t = linspace(0, 2, 1000);
%         x = x_fun(t);   % Se calcula en microsegundos
%    - Se puede utilizar directamente con funciones gráficas (plot), métodos
%      de integración numérica (ode45, integral) y optimizadores.
%    - Con el argumento 'Vars', permite definir con precisión cuáles son las
%      variables de entrada de la función (ej. 'Vars', S.t).
% =========================================================================

clear; clc; close all;

%% 0. GESTIÓN DE RUTAS (Funciones para llamar a VM y Motor desde este subfolder)
subfolderActual = fileparts(mfilename('fullpath'));
dirVM   = fullfile(subfolderActual, '..');        % Carpeta 'Vibraciones Mecanicas' (VM.m)
dirRepo = fullfile(subfolderActual, '..', '..');  % Raíz del repositorio (Motor.m)

if isempty(which('VM'))
    addpath(dirVM);
end
if isempty(which('Motor'))
    addpath(dirRepo);
end

%% 1. PARÁMETROS BASE DEL PROBLEMA
g = 9.81;    % Aceleración de la gravedad [m/s^2]
k = 5000;    % Rigidez del resorte: 5.00 kN/m = 5000 N/m
c = 1200;    % Coeficiente de amortiguamiento: 1.20 kN*s/m = 1200 N*s/m

fprintf('=========================================================================\n');
fprintf('           RESORTE-MASA-AMORTIGUADOR: ANÁLISIS VARIANDO LA MASA M        \n');
fprintf('=========================================================================\n');
fprintf('Datos base: k = %.2f N/m, c = %.2f N*s/m\n\n', k, c);

% Cálculo analítico de la masa crítica:
%   ccr = 2*sqrt(k*M) = c  ==>  M_crit = c^2 / (4*k)
M_crit_teorica = c^2 / (4 * k);

fprintf('--- DEDUCCIÓN DE LA MASA CRÍTICA ---\n');
fprintf('   Amortiguamiento crítico: ccr = 2*sqrt(k*M) = c\n');
fprintf('   M_crit = c^2 / (4*k) = (%g)^2 / (4 * %g) = %.2f kg\n\n', c, k, M_crit_teorica);
fprintf('Criterio de clasificación según la masa M:\n');
fprintf('   * M < %.0f kg  ==>  c > ccr (zeta > 1) : SOBREAMORTIGUADO (ej. M = 3 kg)\n', M_crit_teorica);
fprintf('   * M = %.0f kg  ==>  c = ccr (zeta = 1) : CRÍTICAMENTE AMORTIGUADO\n', M_crit_teorica);
fprintf('   * M > %.0f kg  ==>  c < ccr (zeta < 1) : SUB-AMORTIGUADO  (ej. M = 100 kg)\n\n', M_crit_teorica);

%% =========================================================================
%% CASO 1: SOBREAMORTIGUADO (M = 3 kg - Valor original del problema)
%% =========================================================================
m_sobre  = 3;                    % Masa en kg
x0_sobre = m_sobre * g / k;      % Deflexión estática del resorte [m]
v0_sobre = 0;                    % Reposo [m/s]

[reg1, wn1, ccr1, z1] = VM.clasifA('m', m_sobre, 'k', k, 'c', c);
[eqs1, S1] = VM.ecSobreA();
d1 = struct('m', m_sobre, 'c', c, 'k', k, 'x0', x0_sobre, 'v0', v0_sobre);
R1 = Motor.despejar(eqs1, S1, d1, 'libres', {'t'});
resNum1 = Motor.numerico(R1, d1, S1);

% Ecuaciones analíticas simbólicas
x1_sym = simplify(R1.x);
v1_sym = simplify(diff(x1_sym, S1.t));
a1_sym = simplify(diff(v1_sym, S1.t));

% Conversión a funciones numéricas ejecutables vectorizadas con matlabFunction
x1_fun = matlabFunction(x1_sym, 'Vars', S1.t);
v1_fun = matlabFunction(v1_sym, 'Vars', S1.t);
a1_fun = matlabFunction(a1_sym, 'Vars', S1.t);

fprintf('-------------------------------------------------------------------------\n');
fprintf('1) CASO SOBREAMORTIGUADO: M = %.1f kg\n', m_sobre);
fprintf('-------------------------------------------------------------------------\n');
fprintf('   Régimen:            %s (zeta = %.4f > 1)\n', reg1, z1);
fprintf('   Frec. natural:      wn = %.4f rad/s\n', wn1);
fprintf('   Amort. crítico:     ccr = %.4f N*s/m\n', ccr1);
fprintf('   Deflexión estática: x0 = %.6f m (%.4f mm)\n', x0_sobre, x0_sobre * 1000);
fprintf('   Raíces s1, s2:      s1 = %.4f s^-1, s2 = %.4f s^-1\n', resNum1.s1, resNum1.s2);
fprintf('   Ecuación x(t):      x(t) = %s\n', char(vpa(x1_sym, 5)));
fprintf('   Ecuación v(t):      v(t) = %s\n', char(vpa(v1_sym, 5)));
fprintf('   Ecuación a(t):      a(t) = %s\n\n', char(vpa(a1_sym, 5)));

%% =========================================================================
%% CASO 2: CRÍTICAMENTE AMORTIGUADO (M = 72 kg)
%% =========================================================================
m_crit  = 72;                    % Masa crítica en kg
x0_crit = m_crit * g / k;        % Deflexión estática del resorte [m]
v0_crit = 0;                     % Reposo [m/s]

[reg2, wn2, ccr2, z2] = VM.clasifA('m', m_crit, 'k', k, 'c', c);
[eqs2, S2] = VM.ecCritA();
% Se pasan m, k, x0, v0 (c = ccr = 1200 N*s/m exacto por definición crítica)
d2 = struct('m', m_crit, 'k', k, 'x0', x0_crit, 'v0', v0_crit);
R2 = Motor.despejar(eqs2, S2, d2, 'libres', {'t'});
resNum2 = Motor.numerico(R2, d2, S2);

x2_sym = simplify(R2.x);
v2_sym = simplify(diff(x2_sym, S2.t));
a2_sym = simplify(diff(v2_sym, S2.t));

% Conversión a matlabFunction
x2_fun = matlabFunction(x2_sym, 'Vars', S2.t);
v2_fun = matlabFunction(v2_sym, 'Vars', S2.t);
a2_fun = matlabFunction(a2_sym, 'Vars', S2.t);

fprintf('-------------------------------------------------------------------------\n');
fprintf('2) CASO CRÍTICAMENTE AMORTIGUADO: M = %.1f kg\n', m_crit);
fprintf('-------------------------------------------------------------------------\n');
fprintf('   Régimen:            %s (zeta = %.4f = 1)\n', reg2, z2);
fprintf('   Frec. natural:      wn = %.4f rad/s\n', wn2);
fprintf('   Amort. crítico:     ccr = %.4f N*s/m\n', ccr2);
fprintf('   Deflexión estática: x0 = %.6f m (%.4f mm)\n', x0_crit, x0_crit * 1000);
fprintf('   Constantes:         C1 = %.6f m, C2 = %.6f m/s\n', resNum2.C1, resNum2.C2);
fprintf('   Ecuación x(t):      x(t) = %s\n', char(vpa(x2_sym, 5)));
fprintf('   Ecuación v(t):      v(t) = %s\n', char(vpa(v2_sym, 5)));
fprintf('   Ecuación a(t):      a(t) = %s\n\n', char(vpa(a2_sym, 5)));

%% =========================================================================
%% CASO 3: SUB-AMORTIGUADO (M = 100 kg - Seleccionado)
%% =========================================================================
m_sub  = 100;                    % Masa en kg
x0_sub = m_sub * g / k;          % Deflexión estática del resorte [m]
v0_sub = 0;                      % Reposo [m/s]

[reg3, wn3, ccr3, z3] = VM.clasifA('m', m_sub, 'k', k, 'c', c);
[eqs3, S3] = VM.ecSubA();
d3 = struct('m', m_sub, 'k', k, 'c', c, 'x0', x0_sub, 'v0', v0_sub);
R3 = Motor.despejar(eqs3, S3, d3, 'libres', {'t'});
resNum3 = Motor.numerico(R3, d3, S3);

x3_sym = simplify(R3.x);
v3_sym = simplify(diff(x3_sym, S3.t));
a3_sym = simplify(diff(v3_sym, S3.t));

% Conversión a matlabFunction
x3_fun = matlabFunction(x3_sym, 'Vars', S3.t);
v3_fun = matlabFunction(v3_sym, 'Vars', S3.t);
a3_fun = matlabFunction(a3_sym, 'Vars', S3.t);

fprintf('-------------------------------------------------------------------------\n');
fprintf('3) CASO SUB-AMORTIGUADO: M = %.1f kg\n', m_sub);
fprintf('-------------------------------------------------------------------------\n');
fprintf('   Régimen:            %s (zeta = %.4f < 1)\n', reg3, z3);
fprintf('   Frec. natural:      wn = %.4f rad/s\n', wn3);
fprintf('   Frec. amortiguada:  wd = %.4f rad/s\n', double(R3.wd));
fprintf('   Amort. crítico:     ccr = %.4f N*s/m\n', ccr3);
fprintf('   Deflexión estática: x0 = %.6f m (%.4f mm)\n', x0_sub, x0_sub * 1000);
fprintf('   Periodo amort.:     taud = %.4f s\n', double(R3.taud));
fprintf('   Ecuación x(t):      x(t) = %s\n', char(vpa(x3_sym, 5)));
fprintf('   Ecuación v(t):      v(t) = %s\n', char(vpa(v3_sym, 5)));
fprintf('   Ecuación a(t):      a(t) = %s\n\n', char(vpa(a3_sym, 5)));

%% =========================================================================
%% GRÁFICAS DE LAS TRES SITUACIONES
%% =========================================================================

% Vector de tiempo común para evaluación numérica vectorizada (gracias a matlabFunction)
t_vec = linspace(0, 1.5, 1000);

%% FIGURA 0: Esquema Físico del Sistema
imgFile = fullfile(subfolderActual, 'sistema_resorte_masa_y.jpg');
if exist(imgFile, 'file')
    figure('Name', 'Esquema Físico - Resorte Masa Y', 'Color', 'w', 'Position', [50, 150, 600, 600]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico del Sistema Vertical', 'FontSize', 12, 'FontWeight', 'bold');
end

%% FIGURA 1: Comparativa Directa x(t) y Normalizada x(t)/x0
figure('Name', 'Comparativa de Regímenes Variando M', 'Color', 'w', ...
       'Position', [80, 100, 1050, 480]);

% Subplot 1: Respuesta real en metros
subplot(1, 2, 1);
plot(t_vec, x1_fun(t_vec), 'LineWidth', 2, 'Color', [0.85, 0.33, 0.10]); hold on;
plot(t_vec, x2_fun(t_vec), 'LineWidth', 2, 'Color', [0.00, 0.45, 0.74]);
plot(t_vec, x3_fun(t_vec), 'LineWidth', 2, 'Color', [0.47, 0.67, 0.19]);
yline(0, 'k--', 'LineWidth', 1);
grid on;
title('Respuesta Real: Posición x(t)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Tiempo t [s]', 'FontSize', 11);
ylabel('Desplazamiento x(t) [m]', 'FontSize', 11);
legend(sprintf('Sobre (M = %g kg, \\zeta = %.2f)', m_sobre, z1), ...
       sprintf('Crítico (M = %g kg, \\zeta = 1.00)', m_crit), ...
       sprintf('Sub (M = %g kg, \\zeta = %.2f)', m_sub, z3), ...
       'Location', 'northeast');

% Subplot 2: Respuesta normalizada respecto a la deflexión inicial x0
subplot(1, 2, 2);
plot(t_vec, x1_fun(t_vec)/x0_sobre, 'LineWidth', 2, 'Color', [0.85, 0.33, 0.10]); hold on;
plot(t_vec, x2_fun(t_vec)/x0_crit,  'LineWidth', 2, 'Color', [0.00, 0.45, 0.74]);
plot(t_vec, x3_fun(t_vec)/x0_sub,   'LineWidth', 2, 'Color', [0.47, 0.67, 0.19]);
yline(0, 'k--', 'LineWidth', 1);
grid on;
title('Respuesta Normalizada: x(t) / x_0', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Tiempo t [s]', 'FontSize', 11);
ylabel('Amplitud Relativa [adim]', 'FontSize', 11);
legend('Sobre (Retorno lento asintótico)', ...
       'Crítico (Retorno más rápido sin oscilar)', ...
       'Sub (Cruza cero y oscila amortiguándose)', ...
       'Location', 'northeast');

%% FIGURA 2: Detalle Cinemático (x, v, a) para cada Régimen
figure('Name', 'Detalle de Posición, Velocidad y Aceleración', 'Color', 'w', ...
       'Position', [120, 80, 1100, 720]);

% Columna 1: Sobreamortiguado
subplot(3, 3, 1);
plot(t_vec, x1_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]); grid on;
title(sprintf('Sobre (M = %g kg)\nPosición x(t) [m]', m_sobre)); ylabel('x [m]');

subplot(3, 3, 4);
plot(t_vec, v1_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]); grid on;
title('Velocidad v(t) [m/s]'); ylabel('v [m/s]');

subplot(3, 3, 7);
plot(t_vec, a1_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.85 0.33 0.10]); grid on;
title('Aceleración a(t) [m/s²]'); xlabel('Tiempo [s]'); ylabel('a [m/s²]');

% Columna 2: Críticamente Amortiguado
subplot(3, 3, 2);
plot(t_vec, x2_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.00 0.45 0.74]); grid on;
title(sprintf('Crítico (M = %g kg)\nPosición x(t) [m]', m_crit));

subplot(3, 3, 5);
plot(t_vec, v2_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.00 0.45 0.74]); grid on;
title('Velocidad v(t) [m/s]');

subplot(3, 3, 8);
plot(t_vec, a2_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.00 0.45 0.74]); grid on;
title('Aceleración a(t) [m/s²]'); xlabel('Tiempo [s]');

% Columna 3: Sub-amortiguado
subplot(3, 3, 3);
plot(t_vec, x3_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.47 0.67 0.19]); grid on;
title(sprintf('Sub (M = %g kg)\nPosición x(t) [m]', m_sub));

subplot(3, 3, 6);
plot(t_vec, v3_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.47 0.67 0.19]); grid on;
title('Velocidad v(t) [m/s]');

subplot(3, 3, 9);
plot(t_vec, a3_fun(t_vec), 'LineWidth', 1.8, 'Color', [0.47 0.67 0.19]); grid on;
title('Aceleración a(t) [m/s²]'); xlabel('Tiempo [s]');

fprintf('=========================================================================\n');
fprintf('                ANÁLISIS Y GRÁFICAS GENERADAS EXITOSAMENTE               \n');
fprintf('=========================================================================\n');
