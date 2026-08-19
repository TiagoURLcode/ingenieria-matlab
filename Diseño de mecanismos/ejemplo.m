%% ejemplo.m — cómo sacar las incógnitas de sp, ya resueltas
%  Dos usos del MISMO llamado, sobre un mecanismo de cuatro barras:
%    1. POSICIÓN: datos numéricos. Las dos ramas quedan en VECTORES.
%    2. VELOCIDAD: se le pasa t2 = w*t en vez de un número, y lo que sale
%       ya es función del tiempo. omega y alpha salen con diff.
%  Longitudes en m, ángulos en rad. Correr parado en esta carpeta.
clear; clc

a = 0.040;    % manivela,  eslabón 2   [m]   (40 mm)
b = 0.120;    % acoplador, eslabón 3   [m]  (120 mm)
c = 0.080;    % balancín,  eslabón 4   [m]   (80 mm)
d = 0.100;    % bancada,   eslabón 1   [m]  (100 mm)

%% == 1. POSICIÓN: las dos ramas en vectores ===========================
t2 = pi/4;    % ángulo de entrada [rad]

% datosSis('L4B', datos...) devuelve un struct con TODAS las variables del
% sistema resueltas: los ángulos de salida y también las intermedias
% (K1...K5, A...F). No se pide una incógnita — la cadena las resuelve
% todas en una pasada, así que pedir una sería tirar el resto.
r = sp.datosSis('L4B', 'a',a, 'b',b, 'c',c, 'd',d, 't2',t2);

% double() baja el simbólico a número. Cada ángulo viene duplicado porque
% el mecanismo tiene dos ensambles posibles; apilarlos deja un vector:
%   fila 1 = ABIERTA   (radical negativo)
%   fila 2 = CRUZADA   (radical positivo)
t3 = double([r.t31; r.t32]);   % acoplador, los dos ensambles [rad]
t4 = double([r.t41; r.t42]);   % balancín,  los dos ensambles [rad]

fprintf('--- 1. Posición, t2 = %.1f deg ---\n', rad2deg(t2));
fprintf('  %-8s %10s %10s\n', 'rama', 't3[deg]', 't4[deg]');
fprintf('  %-8s %10.2f %10.2f\n', 'abierta', rad2deg(t3(1)), rad2deg(t4(1)));
fprintf('  %-8s %10.2f %10.2f\n', 'cruzada', rad2deg(t3(2)), rad2deg(t4(2)));

% CONTROL: el lazo tiene que cerrar en las DOS ramas.
%   a*cos(t2) + b*cos(t3) - c*cos(t4) - d = 0    (componente x)
%   a*sin(t2) + b*sin(t3) - c*sin(t4)     = 0    (componente y)
% t3 y t4 son vectores columna, así que la cuenta sale para las dos ramas
% de una sola vez y cx, cy también son columnas de dos.
cx = a*cos(t2) + b*cos(t3) - c*cos(t4) - d;
cy = a*sin(t2) + b*sin(t3) - c*sin(t4);
assert(all(abs([cx; cy]) < 1e-9), ...
    'El lazo no cierra: revisá longitudes o el par de ramas.')

%% == 2. VELOCIDAD: el mismo llamado, con t2 simbólico =================
% Acá está la gracia: a t2 se le pasa w*t en lugar de un número. datosSis
% no distingue — sustituye lo que le den. Lo que vuelve ya no es un ángulo
% sino t3(t) y t4(t), y derivar respecto de t da omega y alpha directo,
% con el factor w incluido: no hay regla de la cadena que aplicar a mano.
%
% Esto funciona porque resolver() solo hace subs sobre una cadena ordenada.
% Un motor que busque ecuaciones con una sola incógnita libre se trabaría:
% con t2 = w*t, cada ecuación arrastra t y w además de su propia incógnita.
syms w t

rt = sp.datosSis('L4B', 'a',a, 'b',b, 'c',c, 'd',d, 't2',w*t);

% Rama abierta. Quedan como expresiones simbólicas en t y w.
t3t = rt.t31;
t4t = rt.t41;

% diff(expr, t) una vez -> velocidad. Dos veces -> aceleración.
w3 = diff(t3t, t);      % velocidad angular del acoplador   [rad/s]
w4 = diff(t4t, t);      % velocidad angular del balancín    [rad/s]
a3 = diff(t3t, t, 2);   % aceleración angular del acoplador [rad/s^2]
a4 = diff(t4t, t, 2);   % aceleración angular del balancín  [rad/s^2]

% Evaluar sin volver a resolver: se sustituyen w y t y listo.
w2  = 10;               % velocidad de la manivela, CONSTANTE [rad/s]
tEv = t2/w2;            % instante en que la manivela pasa por t2 [s]

% Función anónima para no repetir el subs en cada línea. @(expr) declara
% que expr es el argumento; w, t, w2 y tEv se toman del workspace.
ev = @(expr) double(subs(expr, [w t], [w2 tEv]));

fprintf('\n--- 2. Velocidad, w2 = %.1f rad/s constante, rama abierta ---\n', w2);
fprintf('  t3 = %8.2f deg      t4 = %8.2f deg\n',   rad2deg(ev(t3t)), rad2deg(ev(t4t)));
fprintf('  w3 = %8.4f rad/s    w4 = %8.4f rad/s\n',  ev(w3), ev(w4));
fprintf('  a3 = %8.4f rad/s2   a4 = %8.4f rad/s2\n', ev(a3), ev(a4));

% CONTROL 1: en t = tEv la manivela está justo en t2, así que el ángulo
% tiene que ser el mismo que dio el ejemplo 1 por la vía numérica.
assert(abs(ev(t3t) - t3(1)) < 1e-9, 'Las dos vías no coinciden en t3.')

% CONTROL 2: contra la fórmula cerrada de la velocidad del acoplador,
%   w3 = a*w2*sen(t4 - t2) / (b*sen(t3 - t4))
w3ref = a*w2*sin(ev(t4t) - t2) / (b*sin(ev(t3t) - ev(t4t)));
assert(abs(ev(w3) - w3ref) < 1e-9, 'w3 no coincide con la fórmula cerrada.')

% OJO CON LA ACELERACIÓN
%   t2 = w*t es LINEAL en t, o sea que la manivela gira a velocidad
%   constante y alpha2 = 0. Aun así a3 y a4 salen distintos de cero: la
%   salida acelera aunque la entrada gire parejo. Esa es la fuente de
%   vibración de todo mecanismo de cuatro barras, y es la razón por la
%   que no alcanza con mirar velocidades.
