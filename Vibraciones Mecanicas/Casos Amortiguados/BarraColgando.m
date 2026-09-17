%% BarraColgando.m - Barra con Resorte y Amortiguador a 0.5L del Punto A
% =========================================================================
% ENUNCIADO EXACTO (Segundo Examen Parcial, Problema 2):
%   "Para el siguiente sistema, teniendo un resorte de constante k de
%   2.50 kN/m actúa a 0.5L de distancia del punto A. Un amortiguador de
%   constante c de 100 N-m/s actúa a 0.5L a distancia del punto A. El peso
%   de la barra es de 5.50 kN y 5.32 m de longitud. Notar que tanto el
%   resorte y el amortiguador actúan verticalmente, la barra es uniforme y
%   se suelta del reposo, tomando en cuenta la deflexión inicial del
%   sistema."
%
% FIGURA:
%   25° marcado entre la línea vertical y la barra, en el extremo superior.
%   20° marcado respecto a la horizontal, en la parte inferior.
%   La figura no marca el punto A.
% =========================================================================

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

g = 9.81;
m_sub  = 5500/g;
k = 2500;
c = 100;
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

%% Esquema Físico del Sistema
imgFile = fullfile(subfolderActual, 'BarraColgando.png');
if exist(imgFile, 'file')
    fig = figure('Name', 'Esquema Físico - Barra Colgando', 'Color', 'w', 'Position', [100, 100, 650, 650]);
    image(imread(imgFile));
    axis image off;
    title('Esquema Físico de la Barra Inclinada', 'FontSize', 12, 'FontWeight', 'bold');
end