%% VerificarTarea4.m — verificación de los problemas 1, 2 y 4 con MM.m
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

%% ========================= PROBLEMA 4 ===============================
% Datos del enunciado
np4  = 4;        % pasadores en la unión B                        [-]
dp4  = 0.011;    % diámetro del pasador                           [m]  (11 mm)
dAB  = 0.041;    % diámetro EXTERIOR del tubo AB                  [m]  (41 mm)
dBC  = 0.028;    % diámetro EXTERIOR del tubo BC                  [m]  (28 mm)
tAB  = 0.0065;   % espesor de pared del tubo AB                   [m]  (6.5 mm)
tBC  = 0.0075;   % espesor de pared del tubo BC                   [m]  (7.5 mm)
sigY = 200e6;    % fluencia en tensión del acero                  [Pa] (200 MPa)
sigU = 340e6;    % último en tensión del acero                    [Pa] (340 MPa)
tauY = 80e6;     % fluencia en cortante del pasador               [Pa] (80 MPa)
tauU = 140e6;    % último en cortante del pasador                 [Pa] (140 MPa)
sbY  = 260e6;    % fluencia en soporte pasador-tubo               [Pa] (260 MPa)
sbU  = 450e6;    % último en soporte pasador-tubo                 [Pa] (450 MPa)
FSY  = 3.5;      % factor de seguridad respecto a la fluencia     [-]
FSU  = 4.5;      % factor de seguridad respecto al último         [-]

% Áreas de la hoja: A = Aext - Aint = (pi/4)*(d^2 - (d-2t)^2).
% MM.seccion con 'dia' y 'hueco' es esa misma resta; el hueco es d - 2t.
AAB = MM.seccion('dia',dAB, 'hueco',dAB - 2*tAB);   % pared del tubo AB [m^2]
ABC = MM.seccion('dia',dBC, 'hueco',dBC - 2*tBC);   % pared del tubo BC [m^2]
Ap  = MM.seccion('dia',dp4);                        % sección del pasador, un plano de corte [m^2]

% Los dos criterios hacen la MISMA cuenta y solo cambian el par
% (esfuerzo de falla, FS): de ahí el for de dos vueltas.
crit = ["fluencia" "ultimo"];
FS4  = [FSY  FSU];    % factor de seguridad de cada criterio           [-]
sigF = [sigY sigU];   % falla en tensión de los tubos                  [Pa]
tauF = [tauY tauU];   % falla en cortante del pasador                  [Pa]
sbF  = [sbY  sbU];    % falla en soporte entre pasadores y tubos       [Pa]

modos = ["tension AB"; "tension BC"; "cortante pasadores"; ...
         "soporte en AB"; "soporte en BC"];
P4 = zeros(numel(modos), numel(crit));   % P permisible de cada modo y criterio [N]

for k = 1:numel(crit)
    % MM.seguridad (35)(36)(37): permisible = falla/FS. 'sfalla'->'sperm'
    % para esfuerzo normal, 'tfalla'->'tperm' para cortante. El soporte es
    % un esfuerzo normal, así que entra por 'sfalla'.
    sperm  = MM.seguridad('sfalla',sigF(k), 'FS',FS4(k)).sperm;   % [Pa]
    tperm  = MM.seguridad('tfalla',tauF(k), 'FS',FS4(k)).tperm;   % [Pa]
    sbperm = MM.seguridad('sfalla',sbF(k),  'FS',FS4(k)).sperm;   % [Pa]

    % a) Tensión en los tubos: sig = P/A. MM.axial con 'sig' permisible y
    %    'A' devuelve r.P, la carga que lleva ese tubo justo al permisible.
    %    Toda la P pasa por cada tubo, así que son dos cuentas separadas.
    P4(1,k) = MM.axial('sig',sperm, 'A',AAB).P;
    P4(2,k) = MM.axial('sig',sperm, 'A',ABC).P;

    % b) Cortante en los pasadores: 4 pasadores en corte doble = 8 planos.
    %    MM.cortante: 'n' planos de corte, 'A' la sección de UN plano,
    %    'tau' el permisible. Reparte V = F/8, que es la (P/4)/2 de la
    %    hoja -> r.F es la P total de la unión.
    P4(3,k) = MM.cortante('tau',tperm, 'n',2*np4, 'A',Ap).F;

    % c) Soporte (aplastamiento): sig = (P/8)/(dp*t). Cada pasador lleva
    %    P/4, pero cruza DOS paredes de cada tubo y las dos apoyan en
    %    paralelo: a cada pared le toca P/8.
    %    MM.apoyo: 'sigb' permisible, 't' espesor de pared, 'd' diámetro
    %    del pasador; Ab = t*d es el área proyectada de UNA pared y r.P la
    %    fuerza sobre esa pared. La P total son 2*np4 paredes.
    P4(4,k) = 2*np4 * MM.apoyo('sigb',sbperm, 't',tAB, 'd',dp4).P;
    P4(5,k) = 2*np4 * MM.apoyo('sigb',sbperm, 't',tBC, 'd',dp4).P;
end

Pmodo = min(P4, [], 2);          % cada modo lo limita su criterio más exigente [N]

% Cada inciso se queda con el valor MÁS BAJO de sus modos: el primero que
% falla es el que manda. inciso(i) dice a qué inciso pertenece el modo i.
inciso  = [1 1 2 3 3];
incisos = ["a) tension en los tubos"; "b) cortante en los pasadores"; ...
           "c) soporte pasador-tubo"];
Pinc  = zeros(numel(incisos),1);        % P permisible de cada inciso [N]
manda = strings(numel(incisos),1);      % modo que lo limita          [-]
for j = 1:numel(incisos)
    idx = find(inciso == j);            % modos que entran en este inciso
    % min con dos salidas: el valor y la posición DENTRO de idx, por eso
    % el nombre sale como idx(k) y no como k.
    [Pinc(j), k] = min(Pmodo(idx));
    manda(j) = modos(idx(k));
end

% El valor de control es el más bajo de los tres incisos.
[Pctrl, jCtrl] = min(Pinc);      % [N]

fprintf('\n--- Problema 4 ---\n');
fprintf('  %-22s %11s %11s %11s\n', 'modo de falla', crit(1), crit(2), 'manda');
for i = 1:numel(modos)
    fprintf('  %-22s %8.2f kN %8.2f kN %8.2f kN\n', modos(i), ...
        P4(i,1)/1e3, P4(i,2)/1e3, Pmodo(i)/1e3);
end
fprintf('\n');
for j = 1:numel(incisos)
    fprintf('  %-30s %8.2f kN   (%s)\n', incisos(j), Pinc(j)/1e3, manda(j));
end
fprintf('  P de control = %.2f kN, la limita: %s\n', Pctrl/1e3, incisos(jCtrl));
