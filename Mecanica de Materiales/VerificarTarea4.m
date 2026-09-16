%% VerificarTarea4.m — verificación de los problemas 1 y 2 con MM.m
%  Solo funciones de MM. Todo en N, m, Pa; los mm y kN solo en fprintf.
%  Correr parado en esta carpeta (Motor.m tiene que estar en el path:
%  setup.m de la raíz, una vez).
clear; clc

tolHoja = 0.01;   % la hoja redondea a 3-4 cifras: se acepta 1 % de diferencia

%% ========================= PROBLEMA 1 ===============================
% Datos de la hoja
dp       = 0.010;   % diámetro del perno                          [m]  (10 mm)
z        = 0.015;   % espesor de la placa                         [m]  (15 mm)
x2       = 0.020;   % ancho de placa a cada lado del agujero      [m]  (20 mm)
y        = 0.020;   % distancia del agujero al borde de la placa  [m]  (20 mm)
tauPerno = 80e6;    % cortante permisible del perno               [Pa] (80 MPa)
sigPlaca = 50e6;    % esfuerzo de tensión permisible de la placa  [Pa] (50 MPa)
sigApl   = 80e6;    % esfuerzo de aplastamiento permisible        [Pa] (80 MPa)
tauPlaca = 30e6;    % cortante permisible de la placa             [Pa] (30 MPa)
% x1 = 0.05 m (ancho total) no entra en ninguna cuenta de la hoja.

% Cada criterio despeja la P que lleva ese elemento justo a su permisible.

% 1) Perno, cortante doble:  tau = P / (2*(pi/4)*dp^2)
%    MM.seccion('dia',dp) -> área de UN plano de corte, pi*dp^2/4   [m^2]
%    MM.cortante: 'tau' permisible, 'n' planos de corte, 'A' de un plano.
%    r.F es la carga total que transmite la unión, o sea P.
rPerno = MM.cortante('tau',tauPerno, 'n',2, 'A',MM.seccion('dia',dp));

% 2) Placa, tensión:  sig = (P/2) / (x2*z)
%    MM.seccion('a',x2,'b',z) -> área de un lado del agujero        [m^2]
%    MM.axial: 'sig' permisible y 'A' -> r.P es la fuerza de ESE lado.
%    Por el DCL de la hoja cada lado lleva P/2, así que P es el doble.
rTension = MM.axial('sig',sigPlaca, 'A',MM.seccion('a',x2, 'b',z));
PTension = 2*rTension.P;

% 3) Aplastamiento:  sig = P / (dp*z)
%    MM.apoyo: 'sigb' permisible, 't' espesor de la placa, 'd' diámetro
%    del perno. Ab = t*d es el área proyectada -> r.P
rApl = MM.apoyo('sigb',sigApl, 't',z, 'd',dp);

% 4) Placa, cortante:  tau = (P/2) / (y*z)
%    Dos planos de corte de y por z. Con 'n',2 MM.cortante reparte
%    V = F/2, que es el P/2 de la hoja -> r.F es P.
rCorte = MM.cortante('tau',tauPlaca, 'n',2, 'A',MM.seccion('a',y, 'b',z));

% Comparación contra lo anotado
nombres = ["perno, cortante doble"; "placa, tension"; ...
           "aplastamiento"; "placa, cortante"];
Pcalc = [rPerno.F; PTension; rApl.P; rCorte.F];   % calculadas con MM [N]
Phoja = [12.57e3; 30.0e3; 12e3; 18e3];            % anotadas en la hoja [N]

fprintf('--- Problema 1 ---\n');
fprintf('  %-24s %12s %12s\n', 'criterio', 'MM [kN]', 'hoja [kN]');
for i = 1:numel(Pcalc)
    coincide = abs(Pcalc(i) - Phoja(i)) <= tolHoja*abs(Phoja(i));
    fprintf('  %-24s %12.2f %12.2f   %s\n', nombres(i), Pcalc(i)/1e3, ...
        Phoja(i)/1e3, string(coincide));
end

% La marcada en la hoja (12 kN) tiene que ser la menor de las cuatro.
[Pmin, iMin] = min(Pcalc);
fprintf('  P maxima = %.2f kN, la limita: %s\n', Pmin/1e3, nombres(iMin));

%% ========================= PROBLEMA 2 ===============================
% Datos del enunciado
P2    = 20e3;    % carga que cuelga de la barra                [N]  (20 kN)
dAguj = 0.040;   % diámetro del agujero                        [m]  (40 mm)
sigB  = 60e6;    % esfuerzo normal permisible de la barra      [Pa] (60 MPa)
tauD  = 35e6;    % esfuerzo cortante permisible del disco      [Pa] (35 MPa)

% Barra:  sig = P / ((pi/4)*d1^2)
%    MM.axial: 'P' y 'sig' permisible -> r.A, área mínima de la barra
rBarra = MM.axial('P',P2, 'sig',sigB);
%    MM.diseno trae (40) d = sqrt(4*A/pi). El nombre dice perno, pero la
%    fórmula es solo el área del círculo al revés: vale para cualquier
%    sección circular maciza. Se le pasa el área de la barra en 'Aperno'.
d1 = MM.diseno('Aperno',rBarra.A).dperno;

% Disco:  tau = P / (2*pi*(dAguj/2)*t)
%    El disco se corta por un cilindro de diámetro dAguj y alto t: un solo
%    plano de corte. MM.cortante: 'F', 'n',1 y 'tau' permisible -> r.A
rDisco = MM.cortante('F',P2, 'n',1, 'tau',tauD);
%    Desenrollado, ese cilindro es un rectángulo de lados 2*pi*(dAguj/2) y
%    t. MM.apoyo trae (22) Ab = t*d, el área de un rectángulo: con
%    d = 2*pi*(dAguj/2) despeja t. Acá no hay aplastamiento; se usa solo
%    esa geometría.
t = MM.apoyo('Ab',rDisco.A, 'd',2*pi*(dAguj/2)).t;

% Vuelta atrás: con d1 y t, las ecuaciones de la hoja tienen que dar
% justo los permisibles.
sigVuelta = MM.axial('P',P2, 'A',MM.seccion('dia',d1)).sig;
tauVuelta = MM.cortante('F',P2, 'n',1, ...
    'A',MM.seccion('a',2*pi*(dAguj/2), 'b',t)).tau;

fprintf('\n--- Problema 2 ---\n');
fprintf('  d1 minimo = %.2f mm   ->  sig = %.2f MPa (permisible %.0f)\n', ...
    d1*1e3, sigVuelta/1e6, sigB/1e6);
fprintf('  t minimo  = %.2f mm   ->  tau = %.2f MPa (permisible %.0f)\n', ...
    t*1e3, tauVuelta/1e6, tauD/1e6);
