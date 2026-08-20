%RN = MM.axial( ...
    ... % -- fuerza y sección ---------------------------------------------
    ... 'P',     ,   % fuerza interna normal (+ tensión / - compresión)  [N]
    ... 'A',     ,   % área de la sección transversal                    [m^2]
    ... 'sig',   ,   % esfuerzo normal, sigma = P/A                      [Pa]
    ... % -- deformación longitudinal --------------------------------------
    ... 'L',     ,   % longitud original sin deformar                    [m]
    ... 'delta', ,   % elongación (+) o acortamiento (-) total           [m]
    ... 'eps',   ,   % deformación unitaria, epsilon = delta/L           [-]
    ... % -- material ------------------------------------------------------
    ... 'E',     ,   % módulo de elasticidad (Young)                     [Pa]
    ... 'nu',    ,   % relación de Poisson, se tabula POSITIVA           [-]
    ... % -- rigidez -------------------------------------------------------
    ... 'k',     ,   % rigidez de la BARRA, k = P/delta = E*A/L          [N/m]
    ... % -- deformación lateral (sección CIRCULAR) ------------------------
    ... 'epsp',  ,   % deformación unitaria lateral, epsilon'            [-]
    ... 'dia',   ,   % diámetro original de la sección                   [m]
    ... 'ddia',  ,   % cambio de diámetro, (-) si se achica              [m]
 %   );

% Campos de salida, en este orden fijo. Los que no se determinaron NO
% existen: preguntá con isfield antes de usarlos, o mirá RN sin ; para
% ver qué salió.
% RN.P  RN.A  RN.sig  RN.eps  RN.E  RN.L  RN.delta  RN.k  RN.nu
% RN.epsp  RN.dia  RN.ddia
%% tarea_345.m — Problema 1

clear       % borra las variables del Workspace (arranca limpio)
clc         % limpia el texto de la Command Window
close all   % cierra las figuras abiertas de corridas anteriores

%% == Datos de la tabla ================================================
% sig : esfuerzo aplicado a la probeta, en megapascales [MPa].
% eps : deformación unitaria, adimensional [mm/mm]. OJO: `eps` también es


sig1 = [ 8.0  17.5  25.6  31.1  39.8  44.0  48.2  53.9  58.1  62.0 ];  % [MPa]
eps1 = [0.0032 0.0073 0.0111 0.0129 0.0163 0.0184 0.0209 0.0260 0.0331 0.0429];


sigFractura = 62.1;   % [MPa]

%% == Gráfica ==========================================================
% figure abre una ventana nueva; si no la abrís, plot dibuja encima de la
% figura anterior. 'Color','w' pone el fondo de la VENTANA en blanco
% ('w' = white; también 'k' negro, 'r' rojo, o un RGB tipo [0.9 0.9 0.9]).
figure(Theme="light")

% plot(x, y, ...) : el primer vector va al eje horizontal y el segundo al
% vertical. Acá eps es x y sig es y, porque la curva del ensayo se grafica
% esfuerzo EN FUNCIÓN DE la deformación.
%   '-o'              estilo: '-' línea continua uniendo los puntos,
%                     'o' un círculo en cada punto medido. Si querés solo
%                     los puntos sueltos, poné 'o'; solo la línea, '-'.
%   'LineWidth',1.5   grosor de la línea en puntos (el default es 0.5).
%   'MarkerSize',5    diámetro del círculo en puntos.
%   'MarkerFaceColor','w'  relleno del círculo. En blanco quedan huecos y
%                     se distingue el dato medido de la línea que los une.
plot(eps1, sig1, '-o', 'LineWidth',1.5, 'MarkerSize',5, 'MarkerFaceColor','w')

grid on     % dibuja la cuadrícula, para leer valores a ojo

%% == Resultados =======================================================
% Límite de proporcionalidad: hasta el punto 7 la curva se ve recta.
% Es una LECTURA de la gráfica, por eso el índice va en una variable.
kProp   = 7;
sigProp1 = sig1(kProp);   % [MPa]

x  = eps1(1:kProp).';     % .' transpone: x\y necesita vectores columna
y  = sig1(1:kProp).';
E1 = x\y;                 % [MPa]

% Fluencia por el método del 0.2 % de offset.
% d es la distancia vertical entre la curva medida y la recta de offset:
% positiva mientras la curva va por arriba, negativa cuando ya la cruzó.
d = sig1 - E1*(eps1 - 0.002);

% find(d < 0, 1) da el primer punto que ya cruzó la recta. El cruce quedó
% entre ese y el anterior, así que me guardo los dos índices juntos.
k = find(d < 0, 1) + [-1 0];

% interp1(x, y, xq) interpola y en el punto xq. Acá la "x" es d y busco
% dónde vale 0, o sea dónde la curva toca la recta de offset. Con solo dos
% puntos la interpolación es la lineal de siempre, sin hacer la cuenta a mano.
sigY1 = interp1(d(k), sig1(k), 0);   % [MPa]
epsY1 = interp1(d(k), eps1(k), 0);

% dof : fracción de la deformación total que fue PLÁSTICA.

dof = (eps1(end) - eps1(kProp)) / eps1(end);

if dof > 0.05
    fprintf('Material DUCTIL  (deformacion plastica = %.0f %% del total)\n', dof*10);
else
    fprintf('Material FRAGIL  (deformacion plastica = %.0f %% del total)\n', dof*10);
end


fprintf('E1         = %.0f MPa = %.2f GPa\n', E1, E1/1000)
fprintf('sigma_prop = %.1f MPa\n', sigProp1)
fprintf('sigma_Y    = %.1f MPa  (offset 0.2%%, en eps = %.4f)\n', sigY1, epsY1)
fprintf('sigma_frac = %.1f MPa\n', sigFractura)

% En las etiquetas, \epsilon y \sigma son códigos TeX: MATLAB los convierte
% en las letras griegas ε y σ al dibujar.
xlabel('Deformación unitaria \epsilon  [mm/mm]')
ylabel('Esfuerzo \sigma  [MPa]')
title('Problema 1.4-6 — Curva esfuerzo-deformación unitaria')



%% == Problema 2 — Datos del enunciado ================================
% Unidades base del SI: longitudes en metros [m] y esfuerzos en pascales
% [Pa]. 1 MPa = 1e6 Pa, 1 GPa = 1e9 Pa, 1 mm = 1e-3 m.

L2     = 2.0;      % longitud original de la barra [m]
E2     = 200e9;    % módulo de elasticidad [Pa]   (200 GPa)
sigY2  = 250e6;    % esfuerzo de fluencia [Pa]    (250 MPa)
delta2 = 6.5e-3;   % alargamiento al que se carga la barra [m]  (6.5 mm)

epsT2 = delta2/L2 - sigY2/E2;   % [m/m] (adimensional)

% %.6f imprime 6 decimales; con %.4f se perderían cifras porque el valor
% es del orden de 1e-3. El \n al final corta el renglón.
fprintf('Problema 2: epsilon total = %.6f\n', epsT2)

%% == Problema 3 — Datos del enunciado =================================


L3     = 9;        % longitud de la barra [in]
dia3   = 0.225;    % diámetro de la sección circular [in]
delta3 = 0.0195;   % alargamiento medido bajo la carga P [in]

% Monel (66% Ni, 33% Cu), tabla I-2 del apéndice I.
E3  = 25e6;        % módulo de elasticidad [psi]  (25 000 ksi)
nu3 = 0.32;        % relación de Poisson [-]

% MM.seccion traduce la geometría a área: con 'dia' hace pi*dia^2/4.
A3 = MM.seccion('dia', dia3);   % [in^2]

% == Problema 3 — Despeje de epsilon prima ============================
% Los datos van en pares nombre-valor, en cualquier orden. axial no lleva
% incógnita: despeja hacia adelante TODO lo que se pueda y devuelve un
% struct con los campos que quedaron determinados, ya numéricos.
% El camino que recorre solo: eps = delta/L, epsp = -nu*eps, ddia = epsp*dia.
% Lo que no se pudo determinar no aparece como campo.
R3 = MM.axial('L',L3, 'delta',delta3, 'E',E3, ...
              'A',A3, 'nu',nu3, 'dia',dia3);

r31 = R3.ddia;   % cambio de diámetro [in], negativo = se achica
r32 = R3.P;      % carga axial [lb]

% %.3e usa notación científica (-1.560e-04). Con %f el diámetro saldría
% 0.000156 y se pierde de vista el orden de magnitud.
fprintf('\n--- Problema 3 ---\n');
fprintf('ddia = %.3e in   (el diametro DISMINUYE)\n', r31);
fprintf('P    = %.1f lb\n', r32);


%% == Problema 4 — Datos del enunciado =================================
% Ensayo de tensión en probeta de bronce. T

dia4   = 0.010;      % diámetro de la probeta [m]      (10 mm)
L4     = 0.050;      % longitud calibrada [m]          (50 mm)
P4     = 20e3;       % carga de tensión aplicada [N]   (20 kN)
delta4 = 0.122e-3;   % aumento entre marcas de calibración [m]  (0.122 mm)
ddia4  = -8.30e-6;   % cambio de diámetro [m]          (-0.00830 mm)


A4 = MM.seccion('dia', dia4);   % [m^2] — sin área no hay sig, y sin sig no hay E

R4 = MM.axial('L',L4, 'P',P4, 'delta',delta4, 'A',A4, 'dia',dia4, 'ddia',ddia4);

R4a = R4.E;    % módulo de elasticidad [Pa]
R4b = R4.nu;   % relación de Poisson [-]

% El /1e9 es solo para MOSTRAR: la cuenta se hizo en Pa. Escalar en el
% fprintf no toca el valor guardado en R4a.
fprintf('\n--- Problema 4 ---\n');
fprintf('E  = %.4e Pa = %.1f GPa\n', R4a, R4a/1e9);
fprintf('nu = %.4f\n', R4b);

%% == Problema 5 — Barra con orificio lateral ==========================
% Unidades imperiales (in, psi, lb): así viene el enunciado y el sistema
% queda coherente. La sección NETA es un círculo de diámetro d al que se
% le quitó una franja central de ancho d/5 — el caso "círculo con núcleo
% removido" del apéndice E:
%     A = 2*r^2*(alpha - sin(alpha)*cos(alpha)),  alpha = acos(a/r)
% con r = d/2 y a = (d/5)/2 = d/10 (media anchura de la franja).

% syms declara la variable simbólica. 'positive' no es adorno: le avisa a
% simplify que d5 > 0 y así puede sacar d5 de una raíz sin poner abs().
syms d5 positive

r5     = d5/2;          % radio de la barra [in]
a5     = d5/10;         % media anchura de la franja removida [in]
alpha5 = acos(a5/r5);   % semiángulo del arco que sobrevive [rad] = acos(1/5)
A5     = simplify(2*r5^2*(alpha5 - sin(alpha5)*cos(alpha5)));   % [in^2]

%% -- a) Fórmula de la carga permisible --------------------------------

[eqs5, S5] = MM.ecAxial();
P_d5 = simplify(solve(subs(eqs5(1), S5.A, A5), S5.P));   % [lb]


d5b       = 1.75;    % diámetro de la barra [in]
sigPerm5b = 12e3;    % esfuerzo permisible [psi]  (12 ksi)

P5b = double(subs(P_d5, [d5, S5.sig], [d5b, sigPerm5b]));   % [lb]

% char() pasa la expresión simbólica a texto para poder imprimirla con %s.
% vpa(...,6) la muestra con los coeficientes en decimal en vez de acos(1/5).
fprintf('\n--- Problema 5 ---\n');
fprintf('A(d)  = %s in^2\n', char(vpa(A5, 6)));
fprintf('Pperm = %s lb\n', char(vpa(P_d5, 6)));
fprintf('con d = %.2f in y sig = %.0f psi:  Pperm = %.0f lb = %.2f kip\n', ...
        d5b, sigPerm5b, P5b, P5b/1e3);

%% == Problema 6 — Tubo de aleación de cobre ===========================
% Unidades base del SI: metros, newtons, pascales.

sigY6 = 290e6;    % esfuerzo de fluencia [Pa]   (290 MPa)
P6    = 1500e3;   % carga axial de tensión [N]  (1500 kN)
FS6   = 1.8;      % factor de seguridad contra la fluencia [-]
sigPerm6 = sigY6/FS6;   % [Pa]

% Área MÍNIMA que necesita la sección, de sig = P/A. Es un despeje normal
% del sistema: se entra por sig y P, y sale A.
Areq6 = double(MM.datosAxial('P',P6, 'sig',sigPerm6, 'A'));   % [m^2]

syms d6 positive        % d6 = diámetro EXTERIOR del tubo [m]

t6      = d6/8;         % espesor de la pared [m]
diaInt6 = d6 - 2*t6;    % diámetro interior [m]: se descuenta t de cada lado

A6a = pi*(d6^2 - diaInt6^2)/4;   % [m^2]

% solve devuelve el d que hace que el área disponible iguale a la mínima.
% Con la suposición 'positive' descarta sola la raíz negativa.
d6a = double(solve(A6a == Areq6, d6));   % [m]


A6b = A6a - 2*t6*(d6/10);   % [m^2]
d6b = double(solve(A6b == Areq6, d6));   % [m]

% *1e3 y /1e6 solo para mostrar: la cuenta quedó en m y m^2.
fprintf('\n--- Problema 6 ---\n');
fprintf('sig_perm = %.2f MPa   (%.0f MPa / %.1f)\n', sigPerm6/1e6, sigY6/1e6, FS6);
fprintf('A minima = %.1f mm^2\n', Areq6*1e6);
fprintf('a) sin agujero : d_min = %.4f m = %.1f mm\n', d6a, d6a*1e3);
fprintf('b) con agujero : d_min = %.4f m = %.1f mm\n', d6b, d6b*1e3);

%% == Problema 7 ========================================================
fprintf('\n--- Problema 7 ---\n');
fprintf('a) x = 4*W/(3*k)\n');
fprintf('b) x = W/k\n');

%% == Problema 8 — Datos del enunciado =================================
% Viga rígida horizontal ABCD colgada de dos barras verticales de acero,
% BE y CF. Unidades base del SI: metros, newtons, pascales.
% 1 kN = 1e3 N, 1 GPa = 1e9 Pa, 1 mm^2 = 1e-6 m^2.

% -- Distancias sobre la viga (medidas a lo largo de ABCD) -------------
Lab8 = 1.5;      % tramo A-B [m]  (1.5 m)
Lbc8 = 1.5;      % tramo B-C [m]  (1.5 m)
Lcd8 = 2.1;      % tramo C-D [m]  (2.1 m)

% -- Cargas verticales aplicadas en los extremos de la viga ------------
P18 = 400e3;     % carga vertical en A [N]  (400 kN)
P28 = 360e3;     % carga vertical en D [N]  (360 kN)

% -- Barras verticales de acero ----------------------------------------
E8 = 200e9;      % módulo de elasticidad del acero [Pa]  (200 GPa)

% Longitudes leídas de la figura: CF mide 2.4 m desde la viga hasta F, y
% el apoyo E queda 0.6 m más abajo que F, así que BE = 2.4 + 0.6.
Lbe8 = 3.0;      % longitud de la barra BE [m]  (2.4 m + 0.6 m)
Lcf8 = 2.4;      % longitud de la barra CF [m]  (2.4 m)

Abe8 = 11100e-6; % área de la sección transversal de BE [m^2]  (11 100 mm^2)
Acf8 = 9280e-6;  % área de la sección transversal de CF [m^2]  (9 280 mm^2)


syms C8 B8

% Suma de momentos alrededor de B, elegido para que B8 no aparezca y C8
% quede sola. Brazos medidos desde B: A está a Lab8 a la izquierda, C a
% Lbc8 a la derecha, D a Lbc8+Lcd8 a la derecha.
P8C = double(solve(Lab8*P18 + Lbc8*C8 - (Lbc8+Lcd8)*P28 == 0, C8));   % [N]

% Suma de fuerzas verticales: las dos barras cargan entre las dos el total.
P8B = double(solve(B8 + P8C - P18 - P28 == 0, B8));                   % [N]

%% -- a) Deformación de cada barra -------------------------------------
% Las barras están DEBAJO de la viga, paradas sobre los apoyos E y F: la
% viga las aplasta. Son columnas en COMPRESIÓN, y la convención de MM es
% tensión (+) / compresión (-), así que la fuerza interna entra con el
% menos. Sin ese signo delta saldría positivo y estaría diciendo que las
% barras se alargan y la viga sube.
R8be = MM.axial('P',-P8B, 'A',Abe8, 'L',Lbe8, 'E',E8);
R8cf = MM.axial('P',-P8C, 'A',Acf8, 'L',Lcf8, 'E',E8);

% Cada barra tiene el extremo de abajo fijo al apoyo, así que el de arriba
% baja exactamente lo que la barra se acorta. dB8 y dC8 son los
% desplazamientos VERTICALES de los puntos B y C, negativos = hacia abajo.
dB8 = R8be.delta;   % desplazamiento vertical de B [m]
dC8 = R8cf.delta;   % desplazamiento vertical de C [m]

giro8 = (dC8 - dB8)/Lbc8;   % pendiente de la viga [rad] 

delta8a = dB8 - Lab8*giro8;   % desplazamiento vertical de A [m]
delta8d = dB8 + (Lbc8+Lcd8)*giro8;   % desplazamiento vertical de D [m]

% El *1e3 y el menos son solo para MOSTRAR: la cuenta quedó en metros y con
% el signo negativo del acortamiento. Se imprime la magnitud y el sentido
% se dice con palabras, que se lee mejor que un "-8.8e-04".
fprintf('\n--- Problema 8 ---\n');
fprintf('Sobre la viga:  B = %.1f kN   C = %.1f kN   (hacia arriba)\n', ...
        P8B/1e3, P8C/1e3);
fprintf('Barra BE: sig = %7.2f MPa   se acorta %.4f mm\n', ...
        R8be.sig/1e6, -R8be.delta*1e3);
fprintf('Barra CF: sig = %7.2f MPa   se acorta %.4f mm\n', ...
        R8cf.sig/1e6, -R8cf.delta*1e3);
fprintf('a) delta_A = %.4f mm  hacia ABAJO\n', -delta8a*1e3);
fprintf('   delta_D = %.4f mm  hacia ABAJO\n', -delta8d*1e3);

%% == Problema 9 — Datos del enunciado =================================
% Barra de cobre rectangular colgada de un pasador que apoyan dos postes
% de acero. La carga P tira de la barra hacia abajo.
% Unidades base del SI: metros, newtons, pascales.
% 1 kN = 1e3 N, 1 GPa = 1e9 Pa, 1 mm^2 = 1e-6 m^2.

% -- Barra de cobre ----------------------------------------------------
Lcu9 = 2.0;        % longitud de la barra [m]
Acu9 = 4800e-6;    % área de la sección transversal [m^2]  (4800 mm^2)
Ecu9 = 120e9;      % módulo de elasticidad del cobre [Pa]  (120 GPa)

% -- Postes de acero (cada uno) ----------------------------------------
n9   = 2;          % cantidad de postes [-]
Lac9 = 0.5;        % altura de cada poste [m]
Aac9 = 4500e-6;    % área de la sección transversal de cada poste [m^2]  (4500 mm^2)
Eac9 = 200e9;      % módulo de elasticidad del acero [Pa]  (200 GPa)

% -- a) --------------------------------------------------------------
P9a = 180e3;       % carga de tensión aplicada [N]  (180 kN)

% -- b) --------------------------------------------------------------
deltaMax9 = 1.0e-3;   % desplazamiento máximo admitido [m]  (1.0 mm)

R9cu = MM.axial('P', P9a,'A',Acu9, 'E',  Ecu9, 'L',  Lcu9);
d9cu = double(R9cu.delta)
R9ac = MM.axial('P', P9a/2,'A',Aac9, 'E',  Eac9, 'L',  Lac9);
d9ac = double(R9ac.delta)
R9a = d9cu + d9ac

syms P9b     % carga de tensión, incógnita [N]

[eqs9, S9] = MM.ecAxial();

% eqs9(4) es delta == P*L/(E*A): liga delta con P sin pasar por sig ni eps,
% que son símbolos compartidos entre los dos elementos. Los dos postes van
% como uno solo de área n9*Aac9, con la carga completa.
d9bcu = solve(subs(eqs9(4), [S9.P S9.A S9.E S9.L], ...
                            [P9b Acu9    Ecu9 Lcu9]), S9.delta);   % [m]
d9bac = solve(subs(eqs9(4), [S9.P S9.A S9.E S9.L], ...
                            [P9b n9*Aac9 Eac9 Lac9]), S9.delta);   % [m]

R9b = double(solve(d9bcu + d9bac == deltaMax9, P9b));   % [N]

fprintf('\n--- Problema 9 ---\n');
fprintf('a) delta = %.4f mm\n', R9a*1e3);
fprintf('b) Pmax  = %.1f kN\n', R9b/1e3);

%% == Problema 10 — Datos del enunciado ================================
% Barra de aluminio AD empotrada en A, con tres cargas axiales.
% Unidades imperiales (in, lb, psi): así viene el enunciado y el sistema
% queda coherente. No se convierte a SI.

A10 = 0.40;      % área de la sección transversal [in^2]
E10 = 10.4e6;    % módulo de elasticidad del aluminio [psi]  (10.4e6 psi)

% -- Longitudes de los segmentos ---------------------------------------
a10 = 60;        % segmento A-B [in]
b10 = 24;        % segmento B-C [in]
c10 = 36;        % segmento C-D [in]

% -- Cargas aplicadas, como MAGNITUDES ---------------------------------
% Sentidos leídos de la figura: P1 y P2 tiran hacia la DERECHA (alejándose
% del empotre), P3 tira hacia la IZQUIERDA. Los signos van en el DCL.
P1_10 = 1700;    % carga aplicada en B, hacia la derecha [lb]
P2_10 = 1200;    % carga aplicada en C, hacia la derecha [lb]
P3_10 = 1300;    % carga aplicada en D, hacia la izquierda [lb]
N10cd = -P3_10;
N10bc = N10cd+P2_10;
N10ac = N10bc+P1_10;

% -- c) ----------------------------------------------------------------

t1 = struct('N',N10ac, 'L',a10, 'E',E10, 'A',A10);   % N [lb]  L [in]  E [psi]  A [in^2]
t2 = struct('N',N10bc, 'L',b10, 'E',E10, 'A',A10); %segunda seccion analizada
t3 = struct('L',c10, 'E',E10, 'A',A10, 'N',N10cd); %seccion 3, aca empece


r = MM.escalonada({t1, t2, t3});


fprintf('\n--- Problema 10 ---\n');
fprintf('N por tramo:  AB = %+6.0f lb   BC = %+6.0f lb   CD = %+6.0f lb\n', ...
        N10ac, N10bc, N10cd);
fprintf('deformacion:  AB = %+.5f in   BC = %+.5f in   CD = %+.5f in\n', r.dt);
if r.delta > 0
    fprintf('a) la barra SE ALARGA  %.5f in\n', r.delta);
else
    fprintf('a) la barra SE ACORTA  %.5f in\n', -r.delta);
end
