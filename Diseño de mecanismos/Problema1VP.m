%% Problema1VP.m — t3, t4, w3, w4 y velocidades de A, B y P
clear; clc

% Columnas: d  a  b  c [cm]   t2[deg]  w2[rad/s]  Rpa[cm]  delta[deg]
P = [ 6   2   7   9   30   10    6   30
    3  10   6   8   45  -15   10   80
    8   5   8   6   75  -50    9  300
    6   8   8   9   25  100    4  300
    4   5   2   5   80   25    9   80 ];

conf = {'abierta', 'cruzada'};
pol  = @(V) [abs(V) mod(rad2deg(angle(V)), 360)];   % [magnitud, angulo deg]

for i = 1:size(P, 1)
    d  = P(i,1);  a = P(i,2);  b = P(i,3);  c = P(i,4);
    t2 = deg2rad(P(i,5));  w2 = P(i,6);  p = P(i,7);  de = deg2rad(P(i,8));

    % a) posicion: fila 1 abierta, fila 2 cruzada
    r  = sp.datosSis('L4V', 'a',a, 'b',b, 'c',c, 'd',d, 't2',t2);
    t3 = double([r.t31 r.t32]);
    t4 = double([r.t41 r.t42]);

    fprintf('Ejercicio %d:  d = %g  a = %g  b = %g  c = %g cm   t2 = %g deg   w2 = %g rad/s   Rpa = %g cm   delta = %g deg\n', ...
        i, P(i,:));
    fprintf('  %-8s %8s %8s %9s %9s %18s %18s %18s\n', 'config', 't3[deg]', 't4[deg]', ...
        'w3[rad/s]', 'w4[rad/s]', 'VA[cm/s @ deg]', 'VB[cm/s @ deg]', 'VP[cm/s @ deg]');

    for j = 1:2
        % c) y d) w3, w4, VA y VB
        v  = sp.datosSis('V4B', 'a',a, 'b',b, 'c',c, 't2',t2, 't3',t3(j), 't4',t4(j), 'w2',w2);
        w3 = double(v.w3);  w4 = double(v.w4);
        VA = double(v.VA);  VB = double(v.VB);

        % e) VP
        vp = sp.datosSis('VP', 'a',a, 'p',p, 't2',t2, 't3',t3(j), 'delta3',de, 'w2',w2, 'w3',w3);
        VP = double(vp.VP);

        fprintf('  %-8s %8.2f %8.2f %9.3f %9.3f %9.2f @ %6.2f %9.2f @ %6.2f %9.2f @ %6.2f\n', ...
            conf{j}, mod(rad2deg(t3(j)), 360), mod(rad2deg(t4(j)), 360), w3, w4, ...
            pol(VA), pol(VB), pol(VP));
    end
    fprintf('\n');
end
