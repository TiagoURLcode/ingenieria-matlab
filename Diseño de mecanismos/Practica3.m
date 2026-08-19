%% Practica3.m — datos de la practica y comprobacion del problema 1
%  Problema 1: metodo grafico (se resuelve a mano, en papel).
%  Problema 2: metodo algebraico / lazo vectorial.
%  Acá se cargan los datos de los DOS problemas, y se resuelve por lazo
%  vectorial la PRIMERA fila del problema 1, para tener contra qué
%  comparar el trazado a mano.
clear; clc

% UNIDADES: las longitudes van en CENTIMETROS, como el enunciado.
%   No se pasan a metros a propósito. En el análisis de posición de un
%   cuatro barras las cuatro longitudes entran siempre como razones o
%   sumas entre sí (d/a, d/c, a^2-b^2+c^2+d^2, ...) y la salida son
%   ÁNGULOS, que no tienen unidad. Mientras las cuatro estén en la misma
%   unidad el resultado es idéntico. Lo que no se negocia es la
%   coherencia, no que sea métrico.
%   Los ángulos sí se pasan a radianes: cos y sin de MATLAB trabajan en rad.

%% == Datos del enunciado ==============================================
% Columnas:  t2[deg]   a     b     c    d        longitudes en cm

% Problema 1 — metodo grafico
P1 = [  45   2   4.5   7   9
        60   2   3.5   7   9
       120   2   4.0   6   8 ];

% Problema 2 — metodo algebraico (lazo vectorial)
P2 = [  30   4   9    14  18
        45   4   7    14  18
       250   4   8    12  16 ];

%% == Problema 1, fila 1: resuelto por lazo vectorial ==================
% Solo la primera fila. Es la que sirve para verificar el grafico.
fila = P1(1,:);

t2 = deg2rad(fila(1));   % angulo de entrada           [rad]
a  = fila(2);            % manivela,  eslabon 2        [cm]
b  = fila(3);            % acoplador, eslabon 3        [cm]
c  = fila(4);            % balancin,  eslabon 4        [cm]
d  = fila(5);            % bancada,   eslabon 1        [cm]

% CONTROL DE ARMADO: para que la cadena cierre, la distancia de la junta A
% al pivote O4 tiene que quedar entre |b-c| y b+c. Si no, el mecanismo no
% se ensambla en ese angulo y las raices salen complejas.
AO4 = hypot(d - a*cos(t2), a*sin(t2));   % hypot(x,y) = sqrt(x^2+y^2)
assert(AO4 >= abs(b-c) && AO4 <= b+c, ...
    'No se ensambla en t2 = %.0f deg: AO4 = %.3f cm fuera de [%.3f, %.3f].', ...
    fila(1), AO4, abs(b-c), b+c);

r = sp.datosSis('L4B', 'a',a, 'b',b, 'c',c, 'd',d, 't2',t2);

% Fila 1 = ABIERTA (radical negativo), fila 2 = CRUZADA (radical positivo).
t3 = double([r.t31; r.t32]);   % acoplador [rad]
t4 = double([r.t41; r.t42]);   % balancin  [rad]

% mod(...,360) para leerlos de 0 a 360, que es como el enunciado escribe
% los angulos (250 grados en vez de -110). 2*atan devuelve de -180 a 180.
g3 = mod(rad2deg(t3), 360);
g4 = mod(rad2deg(t4), 360);

fprintf('Problema 1, fila 1 — lazo vectorial\n');
fprintf('  t2 = %.0f deg   a = %.1f   b = %.1f   c = %.1f   d = %.1f  [cm]\n\n', fila);
fprintf('  %-10s %12s %12s\n', 'config', 't3[deg]', 't4[deg]');
fprintf('  %-10s %12.2f %12.2f\n', 'abierta', g3(1), g4(1));
fprintf('  %-10s %12.2f %12.2f\n', 'cruzada', g3(2), g4(2));

% CONTROL: el lazo tiene que cerrar en las dos configuraciones.
%   a*cos(t2) + b*cos(t3) - c*cos(t4) - d = 0
%   a*sin(t2) + b*sin(t3) - c*sin(t4)     = 0
cx = a*cos(t2) + b*cos(t3) - c*cos(t4) - d;
cy = a*sin(t2) + b*sin(t3) - c*sin(t4);
assert(all(abs([cx; cy]) < 1e-9), 'El lazo no cierra.');
fprintf('\n  lazo cerrado en las dos configuraciones (residuo < 1e-9)\n');
