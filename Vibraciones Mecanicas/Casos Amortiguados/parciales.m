%% parciales.m - Problemas de parcial de Vibraciones Mecanicas
% =========================================================================
% 1) Polea escalonada con dos masas, resorte y amortiguador (vibracion
%    libre amortiguada, coordenada angular).
% 2) Motor sobre cuatro resortes con desbalance rotatorio (vibracion
%    forzada no amortiguada, unidades lb-in-s).
% 3) Masa en la punta de una columna tubular de aluminio (vibracion
%    forzada desde el reposo + decremento logaritmico). Falta Dext.
% 4) Palanca acodada con dos bloques, dos resortes y amortiguador
%    (vibracion libre amortiguada, sistema equivalente en x).
% 5) Bloque con dos resortes en paralelo y zeta dado (vibracion libre
%    amortiguada, sin c: se entra por zeta).
% =========================================================================

%% PROBLEMA 1 - Polea escalonada con dos masas, resorte y amortiguador
% =========================================================================
% ENUNCIADO (parcial):
%   Polea escalonada que gira alrededor de su centro O, con momento de
%   inercia de masa Jo = 0.3 kg*m^2. Radio exterior 30 cm, radio interior
%   10 cm.
%   - Del radio EXTERIOR (30 cm) cuelga un bloque de 5 kg y, debajo del
%     bloque, un resorte de 3.2e4 N/m hasta el piso.
%   - Del radio INTERIOR (10 cm) cuelga un bloque de 40 kg y, debajo del
%     bloque, un amortiguador de 150 N*s/m hasta el piso.
%   Condiciones iniciales: theta(0) = 0, thetapunto(0) = 2.5 rad/s.
%
%   Determinar: a) rigidez del sistema, b) amortiguamiento del sistema,
%   c) tipo de amortiguamiento, d) posicion a los 0.5 s, e) velocidad a
%   los 0.5 s.
% =========================================================================
%
% RAZONAMIENTO
%
% 1) UN SOLO GRADO DE LIBERTAD.
%    Los cables no resbalan sobre la polea, asi que todo el sistema queda
%    descrito por UN angulo, theta. Si la polea gira theta:
%       el bloque de 5 kg  (y el resorte)      recorre  R*theta
%       el bloque de 40 kg (y el amortiguador) recorre  r*theta
%    Las velocidades son R*thetapunto y r*thetapunto.
%
% 2) COORDENADA ELEGIDA: theta.
%    Las condiciones iniciales vienen en rad y rad/s, asi que la coordenada
%    natural es theta y el sistema equivalente es TORSIONAL:
%       Jeq*theta'' + ceq*theta' + keq*theta = 0
%    Esa ecuacion es la misma m*x'' + c*x' + k*x = 0 con otro vestuario
%    (ver VM.ecTorA), y por eso se puede resolver con VM.amortA pasandole
%    Jeq como 'm', keq como 'k' y ceq como 'c'.
%
% 3) DE DONDE SALEN Jeq, keq Y ceq (metodo de energias).
%    Energia cinetica:
%       T = 1/2*Jo*thetapunto^2 + 1/2*m1*(R*thetapunto)^2
%                               + 1/2*m2*(r*thetapunto)^2
%         = 1/2*(Jo + m1*R^2 + m2*r^2)*thetapunto^2   ->  Jeq
%    Energia potencial elastica (el resorte se deforma R*theta):
%       V = 1/2*k*(R*theta)^2 = 1/2*(k*R^2)*theta^2   ->  keq = k*R^2
%    Disipacion del amortiguador (se deforma a r*thetapunto):
%       D = 1/2*c*(r*thetapunto)^2 = 1/2*(c*r^2)*thetapunto^2 -> ceq = c*r^2
%    El radio entra AL CUADRADO en los tres casos: es el mismo factor que
%    aparece al pasar fuerza a momento y desplazamiento a angulo.
%
% 4) LA GRAVEDAD NO APARECE.
%    Los pesos producen momentos constantes respecto a O. Si theta se mide
%    desde la POSICION DE EQUILIBRIO ESTATICO, la deformacion inicial del
%    resorte ya equilibra esos momentos y ambos terminos se cancelan de la
%    ecuacion de movimiento. Queda vibracion libre pura. Por eso no hace
%    falta g y por eso theta(0) = 0 significa "en el equilibrio estatico",
%    no "resorte sin deformar".
%
% 5) UNIDADES: LA CASILLA PIDE N/m Y EN theta SALE N*m/rad.
%    Trabajando en theta, keq sale en N*m/rad y ceq en N*m*s/rad, que NO
%    son N/m ni N*s/m. Para que el numero salga en N/m hay que REFERIR el
%    sistema al desplazamiento lineal de un bloque, y ahi aparece la
%    pregunta: a cual de los dos.
%
%    Referir a un bloque es dividir por su radio al cuadrado, porque
%    x = radio*theta:
%       meq = Jeq/radio^2      keq_lin = keq/radio^2      ceq_lin = ceq/radio^2
%    Da esto:
%       al bloque de 5 kg  (R = 0.3): k = 32000 N/m,  c = 16.67 N*s/m
%       al bloque de 40 kg (r = 0.1): k = 288000 N/m, c = 150 N*s/m
%    En cada caso UNO de los dos numeros coincide con el dato del
%    enunciado, y no es casualidad: el elemento que vive en la coordenada
%    de referencia entra sin factor. El resorte esta en R y el
%    amortiguador en r.
%
%    QUE NO CAMBIA NUNCA: wn, z, wd y el tipo de amortiguamiento son los
%    mismos en las tres lecturas (50.0435 rad/s y z = 0.013032). Elegir
%    coordenada solo reescala k, c, m, x y v. Si dos respuestas difieren
%    en wn, el error es de geometria, no de unidades.
%
%    CUAL PONER. La figura marca theta (no una x), y las condiciones
%    iniciales vienen en rad y rad/s: la coordenada del problema es theta
%    y la respuesta coherente es 2880 y 1.5. La etiqueta N/m de la casilla
%    parece plantilla reutilizada del problema de la palanca, donde la
%    figura si marca una x y ahi N/m es correcto. Si la catedra igual
%    quiere N/m, hay que decir a que bloque se refiere; la salida imprime
%    las tres.
% =========================================================================

clear; clc;

% 0. Rutas hacia VM y Motor
cargarVM();

%% 1. Datos (SI base)
Jo = 0.3;        % inercia de masa de la polea respecto a O [kg*m^2]
R  = 0.30;       % radio exterior [m]  (30 cm)
r  = 0.10;       % radio interior [m]  (10 cm)
m1 = 5;          % bloque colgado del radio exterior [kg]
m2 = 40;         % bloque colgado del radio interior [kg]
k  = 3.2e4;      % rigidez del resorte [N/m]
c  = 150;        % coef. de amortiguamiento [N*s/m]

th0 = 0;         % theta(0) [rad]
w0  = 2.5;       % thetapunto(0) [rad/s]
t1  = 0.5;       % instante pedido [s]

%% 2. Sistema equivalente de un grado de libertad (coordenada theta)
Jeq = Jo + m1*R^2 + m2*r^2;   % inercia equivalente  [kg*m^2]
keq = k*R^2;                  % rigidez equivalente  [N*m/rad]
ceq = c*r^2;                  % amortiguamiento eq.  [N*m*s/rad]

%% 3. Despeje con VM (analogia torsional: m->Jeq, k->keq, c->ceq, x->theta)
% VM.amortA clasifica solo (VM.clasifA) y llama al sistema que corresponde;
% no hay que decidir de antemano si es sub, critico o sobre.
% 'x0' y 'v0' son theta(0) y thetapunto(0). Sin 't' numerico, res.x vuelve
% como EXPRESION simbolica en t, lista para derivar.
[res, regimen] = VM.amortA('m',Jeq, 'k',keq, 'c',ceq, 'x0',th0, 'v0',w0);

wn  = double(res.wn);          % frecuencia natural no amortiguada [rad/s]
ccr = double(res.ccr);         % amortiguamiento critico [N*m*s/rad]
z   = double(res.z);           % relacion de amortiguamiento zeta [-]
wd  = double(res.wd);          % frecuencia amortiguada [rad/s]

t        = sym('t');                   % el mismo simbolo que usa VM.ecSubA
theta_t  = res.x;                      % theta(t)        [rad]
omega_t  = diff(theta_t, t);           % thetapunto(t)   [rad/s]

theta1 = double(subs(theta_t, t, t1)); % theta(0.5 s)      [rad]
omega1 = double(subs(omega_t, t, t1)); % thetapunto(0.5 s) [rad/s]

%% 4. Resultados
fprintf('=========================================================================\n');
fprintf('  POLEA ESCALONADA CON DOS MASAS, RESORTE Y AMORTIGUADOR\n');
fprintf('=========================================================================\n');
fprintf('Sistema equivalente en theta:\n');
fprintf('   Jeq = Jo + m1*R^2 + m2*r^2 = %.4f kg*m^2\n', Jeq);
fprintf('a) keq = k*R^2              = %.1f N*m/rad\n', keq);
fprintf('b) ceq = c*r^2              = %.2f N*m*s/rad\n', ceq);
fprintf('\n');
fprintf('   wn  = sqrt(keq/Jeq)      = %.4f rad/s\n', wn);
fprintf('   ccr = 2*Jeq*wn           = %.4f N*m*s/rad\n', ccr);
fprintf('   z   = ceq/ccr            = %.6f\n', z);
fprintf('c) Regimen: %s-amortiguado (z < 1)\n', regimen);
fprintf('   wd  = sqrt(1-z^2)*wn     = %.4f rad/s\n', wd);
fprintf('\n');
fprintf('   theta(t) = %s\n', char(vpa(theta_t, 5)));
fprintf('\n');
fprintf('d) theta(%.1f s)      = %.6f rad\n', t1, theta1);
fprintf('e) thetapunto(%.1f s) = %.4f rad/s\n', t1, omega1);
fprintf('\n');
fprintf('   SI LA CASILLA PIDE N/m: hay que referir el sistema a un bloque\n');
fprintf('   (dividir por el radio al cuadrado; wn y z no cambian).\n');
fprintf('     bloque 5 kg  (x = R*theta, R = %.2f m):\n', R);
fprintf('       k = %8.1f N/m   c = %7.2f N*s/m   m = %8.3f kg\n', ...
    keq/R^2, ceq/R^2, Jeq/R^2);
fprintf('       x(%.1f s) = %+.6f m (%+.3f mm)   v(%.1f s) = %+.4f m/s\n', ...
    t1, R*theta1, R*theta1*1e3, t1, R*omega1);
fprintf('     bloque 40 kg (x = r*theta, r = %.2f m):\n', r);
fprintf('       k = %8.1f N/m   c = %7.2f N*s/m   m = %8.3f kg\n', ...
    keq/r^2, ceq/r^2, Jeq/r^2);
fprintf('       x(%.1f s) = %+.6f m (%+.3f mm)   v(%.1f s) = %+.4f m/s\n', ...
    t1, r*theta1, r*theta1*1e3, t1, r*omega1);
fprintf('=========================================================================\n');

%% PROBLEMA 2 - Motor sobre cuatro resortes con desbalance rotatorio
% =========================================================================
% ENUNCIADO (parcial):
%   Un motor de 350 lb descansa sobre 4 resortes de 750 lb/in. El eje del
%   motor tiene un desbalance de 1 oz a 6 in del eje de rotacion. La
%   vibracion solo puede ocurrir verticalmente. Determinar:
%     a) la frecuencia a la que el sistema entra en resonancia;
%     b) la amplitud si el motor gira a 1200 rpm.
% =========================================================================
%
% RAZONAMIENTO
%
% 1) UNIDADES: lb-in-s, NO SI.
%    El enunciado viene en libras y pulgadas, asi que se trabaja en ese
%    sistema y no se convierte. Lo que no se negocia es que el sistema sea
%    COHERENTE: con k en lb/in, la masa tiene que ir en lb*s^2/in, y para
%    eso g = 386.4 in/s^2 (que son los 32.2 ft/s^2 de siempre, por 12).
%    Usar 32.2 con pulgadas da una wn 3.46 veces mas chica y no salta
%    ningun error.
%    1 oz = 1/16 lb. Es un PESO, no una masa: tambien se divide por g.
%
% 2) LOS CUATRO RESORTES ESTAN EN PARALELO.
%    Los cuatro sostienen el mismo motor y se deforman lo mismo cuando el
%    motor baja, asi que las rigideces se suman: keq = 4*750 = 3000 lb/in.
%    En serie (uno colgado del otro) habria dado 187.5 lb/in.
%
% 3) LA RESONANCIA NO DEPENDE DEL DESBALANCE.
%    Resonancia es que la frecuencia de EXCITACION (el giro del eje)
%    coincida con la frecuencia NATURAL del sistema. wn sale solo de keq y
%    de la masa que vibra, wn = sqrt(keq/M): el desbalance fija cuanta
%    fuerza mete, no donde esta el pico. Por eso a) se contesta con
%    VM.omega y nada mas.
%
% 4) EL DESBALANCE ROTATORIO NO ES UNA FUERZA CONSTANTE.
%    La masa desbalanceada gira con el eje, asi que su aceleracion
%    centripeta genera una fuerza que rota con ella. La componente
%    VERTICAL, que es la unica que el montaje deja actuar, vale:
%       F(t) = mDes*e*w^2*sin(w*t)      ->   F0 = mDes*e*w^2
%    F0 crece con el CUADRADO de la velocidad de giro: al doble de rpm,
%    cuatro veces la fuerza.
%
% 5) AMPLITUD EN REGIMEN PERMANENTE, SIN AMORTIGUAMIENTO.
%    El enunciado no da amortiguador, asi que c = 0 y la respuesta
%    permanente es
%       X = (F0/keq) / (1 - rf^2)        con  rf = w/wn
%    F0/keq es la deflexion que daria esa misma fuerza aplicada despacio
%    (deflexion estatica) y el factor 1/(1-rf^2) es la amplificacion
%    dinamica. Sin amortiguamiento X no tiene parte imaginaria: el signo
%    es toda la informacion de fase que hay.
%       rf < 1 (por debajo de resonancia) -> X > 0, el motor se mueve EN
%               FASE con el desbalance
%       rf = 1 -> division por cero, la amplitud crece sin limite
%       rf > 1 (por arriba)               -> X < 0, se mueve en CONTRAFASE,
%               desfasado 180 grados. El tamano de la vibracion es |X|
%    Aca rf = 2.18 > 1, asi que X sale negativa y eso es fisica, no un
%    error de cuenta.
% =========================================================================

%% 1. Datos (sistema lb-in-s)
g    = 386.4;     % aceleracion de la gravedad [in/s^2]  (32.2 ft/s^2)
Wmot = 350;       % peso del motor [lb]
kRes = 750;       % rigidez de CADA resorte [lb/in]
nRes = 4;         % cantidad de resortes [-]
Wdes = 1/16;      % peso del desbalance [lb]  (1 oz)
e    = 6;         % distancia del desbalance al eje de giro [in]
rpm  = 1200;      % velocidad de giro del motor [rpm]

%% 2. Masas y rigidez equivalente
Mmot = Wmot/g;                          % masa del motor [lb*s^2/in]
mDes = Wdes/g;                          % masa desbalanceada [lb*s^2/in]
kTot = VM.datosParalelos(kRes*ones(1,nRes));   % resortes en paralelo [lb/in]

%% 3. a) Frecuencia de resonancia
% VM.omega despeja el masa-resorte: de k y m saca wn, el periodo tau y la
% frecuencia f en Hz. Los rpm salen de f*60.
rOm  = VM.omega('k',kTot, 'm',Mmot);
wn   = double(rOm.wn);                  % frecuencia natural [rad/s]
fn   = double(rOm.f);                   % frecuencia natural [Hz]
rpmn = fn*60;                           % misma frecuencia [rpm]

%% 4. b) Amplitud a 1200 rpm
w   = rpm*2*pi/60;          % frecuencia de excitacion [rad/s]
rf  = w/wn;                 % relacion de frecuencias [-]
F0  = mDes*e*w^2;           % amplitud de la fuerza del desbalance [lb]
Xst = F0/kTot;              % deflexion estatica equivalente [in]
X   = Xst/(1 - rf^2);       % amplitud en regimen permanente [in]

%% 5. Resultados
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('  MOTOR CON DESBALANCE ROTATORIO SOBRE CUATRO RESORTES\n');
fprintf('=========================================================================\n');
fprintf('   M    = W/g                 = %.5f lb*s^2/in\n', Mmot);
fprintf('   keq  = 4 resortes paralelo = %.0f lb/in\n', kTot);
fprintf('   mDes = (1/16 lb)/g         = %.3e lb*s^2/in\n', mDes);
fprintf('\n');
fprintf('a) wn = sqrt(keq/M)           = %.2f rad/s\n', wn);
fprintf('                              = %.2f Hz = %.1f rpm\n', fn, rpmn);
fprintf('\n');
fprintf('   w a 1200 rpm               = %.2f rad/s\n', w);
fprintf('   rf = w/wn                  = %.4f  (> 1: por arriba de resonancia)\n', rf);
fprintf('   F0 = mDes*e*w^2            = %.2f lb\n', F0);
fprintf('   Xst = F0/keq               = %.6f in\n', Xst);
fprintf('b) X  = Xst/(1-rf^2)          = %.6f in   (|X| = %.6f in = %.3e ft)\n', ...
    X, abs(X), abs(X)/12);
fprintf('=========================================================================\n');

%% PROBLEMA 3 - Masa en la punta de una columna tubular de aluminio
% =========================================================================
% ENUNCIADO (parcial):
%   Una masa de 5.00 kg se coloca en la punta de una columna con area
%   transversal tubular y 1.25 m de altura. Una fuerza armonica actua en la
%   punta, horizontal: F(t) = 30*cos(75.4*t) N. La amplitud maxima que se
%   desea bajo estas condiciones es de 0.01 m. El sistema parte del reposo.
%   Determinar:
%     a) el espesor del tubo de aluminio para resistir las condiciones
%        dadas [mm];
%     b) el amortiguamiento para que la amplitud maxima se reduzca un 30%
%        luego de 7 oscilaciones [N*s/m].
%
% FALTA UN DATO: el enunciado no da el DIAMETRO EXTERIOR del tubo. Sin el,
% el espesor no tiene respuesta unica: el mismo momento de inercia I se
% consigue con un tubo ancho y fino o con uno angosto y grueso. Todo lo
% demas (k, wn, I y el amortiguamiento de b) sale igual y esta resuelto.
% Cargar Dext mas abajo y el espesor sale solo.
% =========================================================================
%
% RAZONAMIENTO
%
% 1) EL MODELO: VOLADIZO CON MASA EN LA PUNTA.
%    La columna esta empotrada en la base y libre arriba, y la fuerza es
%    HORIZONTAL, asi que la columna trabaja a FLEXION, no a compresion. La
%    rigidez que ve la masa es la de una viga en voladizo cargada en el
%    extremo:
%       k = 3*E*I/L^3
%    La masa de la columna se desprecia frente a los 5 kg de la punta, asi
%    que queda un sistema de 1 GDL: m*x'' + k*x = F0*cos(w*t).
%
% 2) LA EXCITACION SE LEE DE LA PROPIA FUERZA.
%    F(t) = 30*cos(75.4*t)  ->  F0 = 30 N,  w = 75.4 rad/s.
%    w NO es dato a elegir: viene impuesta por quien excita el sistema. Lo
%    unico que el diseno puede mover es k (o sea, el espesor).
%
% 3) "PARTE DEL REPOSO" DUPLICA EL PICO.
%    Sin amortiguamiento y arrancando de x(0) = 0, xpunto(0) = 0, la
%    solucion completa es permanente + transitorio:
%       x(t) = X*(cos(w*t) - cos(wn*t))        con  X = F0/(k - m*w^2)
%    Las dos cosenoides tienen la misma amplitud X y frecuencias distintas:
%    baten entre si y, cuando se ponen en contrafase, se suman. El pico del
%    movimiento es 2*|X|, no |X|. Por eso el enunciado aclara que parte del
%    reposo: si solo pidiera la amplitud permanente, el dato sobraria.
%    En un sistema real el transitorio se apaga por el amortiguamiento y
%    queda solo |X|; el 2 es la condicion de arranque, la mas exigente.
%
% 4) LA CONDICION DE DISENO DA DOS RAICES.
%       2*|F0/(k - m*w^2)| = Amax   ->   |k - m*w^2| = 2*F0/Amax
%    m*w^2 = 28426 N/m es la rigidez que pondria al sistema JUSTO en
%    resonancia. La condicion se cumple alejandose de ese valor 6000 N/m
%    para cualquiera de los dos lados:
%       k = m*w^2 + 2*F0/Amax = 34426 N/m  ->  wn > w, tubo RIGIDO
%       k = m*w^2 - 2*F0/Amax = 22426 N/m  ->  wn < w, tubo FLEXIBLE
%    Entre esas dos la amplitud se pasa de 0.01 m. Se toma la RIGIDA: es la
%    que pide MAS I (mas espesor, mas material), y el enunciado pide el
%    espesor "para resistir las condiciones dadas" - un tubo mas grueso es
%    la lectura conservadora. La flexible (22425.8 N/m, wn < w) tambien
%    cumple la amplitud y queda anotada en la salida por si el criterio de
%    la catedra fuera el opuesto.
%
% 5) DEL k AL ESPESOR.
%       I = k*L^3/(3*E)                          momento de inercia de area
%       I = pi*(Dext^4 - Dint^4)/64              seccion tubular
%       Dint = (Dext^4 - 64*I/pi)^(1/4)          se despeja el hueco
%       t = (Dext - Dint)/2                      espesor de pared
%    La segunda ecuacion tiene DOS incognitas (Dext y Dint): por eso hace
%    falta el diametro exterior. Ojo con el resultado: si 64*I/pi supera
%    Dext^4, Dint sale imaginario y significa que ni un tubo MACIZO de ese
%    diametro alcanza; hay que agrandar Dext.
%
% 6) PARTE b) ES DECREMENTO LOGARITMICO, NO RESPUESTA FORZADA.
%    "Que la amplitud se reduzca un 30% luego de 7 oscilaciones" habla de
%    como DECAE la vibracion libre: x2 = 0.7*x1 con n = 7 ciclos entre una
%    y otra. Eso es delta = (1/n)*ln(x1/x2), y de delta sale zeta y de zeta
%    sale c. Es la via experimental de VM.ecSubA, y se entra con x1 = 1 y
%    x2 = 0.7 porque lo que importa es la RELACION, no los valores.
%    La k que se usa es la del inciso a): el amortiguador se le agrega a
%    ESA columna.
% =========================================================================

%% 1. Datos
mCol = 5;             % masa en la punta [kg]
Lcol = 1.25;          % altura de la columna [m]
Ecol = 70e9;          % modulo de elasticidad del aluminio [Pa]  (70 GPa)
F0   = 30;            % amplitud de la fuerza armonica [N]
wExc = 75.4;          % frecuencia de la excitacion [rad/s]
Amax = 0.01;          % amplitud maxima admisible [m]
nOsc = 7;             % oscilaciones en las que decae [-]
red  = 0.30;          % reduccion de amplitud pedida [-]  (30%)

Dext = NaN;           % diametro exterior del tubo [m] - NO ESTA EN EL
% ENUNCIADO. Cargalo y el espesor se calcula solo.

factorPico = 2;       % 2: pico del transitorio (parte del reposo)
% 1: solo amplitud permanente

%% 2. a) Rigidez y momento de inercia de area necesarios
Xadm  = Amax/factorPico;              % amplitud permanente admisible [m]
kRes0 = mCol*wExc^2;                  % k que daria resonancia exacta [N/m]
kReq  = kRes0 + F0/Xadm;              % raiz RIGIDA (wn > w) [N/m]
kFlex = kRes0 - F0/Xadm;              % raiz flexible, se descarta [N/m]

Ireq  = kReq*Lcol^3/(3*Ecol);         % momento de inercia de area [m^4]

rOm3 = VM.omega('k',kReq, 'm',mCol);  % de k y m salen wn, tau y f
wn3  = double(rOm3.wn);               % frecuencia natural [rad/s]
rf3  = wExc/wn3;                      % relacion de frecuencias [-]

%% 3. b) Amortiguamiento por decremento logaritmico
% VM.subA entra por x1, x2 y n: saca delta, de ahi zeta, y con m y k saca c.
% x1 = 1 y x2 = 1-0.30 porque solo cuenta el cociente entre amplitudes.
res3  = VM.subA('m',mCol, 'k',kReq, 'x1',1, 'x2',1-red, 'n',nOsc);
delta = double(res3.delta);           % decremento logaritmico [-]
z3    = double(res3.z);               % relacion de amortiguamiento [-]
ccr3  = double(res3.ccr);             % amortiguamiento critico [N*s/m]
c3    = double(res3.c);               % amortiguamiento pedido [N*s/m]

%% 4. Resultados
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('  MASA EN LA PUNTA DE UNA COLUMNA TUBULAR DE ALUMINIO\n');
fprintf('=========================================================================\n');
fprintf('   k de resonancia (m*w^2)    = %.1f N/m\n', kRes0);
fprintf('   amplitud permanente adm.   = %.4f m  (pico/%.0f)\n', Xadm, factorPico);
fprintf('a) k necesaria (raiz rigida)  = %.1f N/m\n', kReq);
fprintf('   (la raiz flexible, %.1f N/m, tambien cumple pero deja wn < w)\n', kFlex);
fprintf('   wn = sqrt(k/m)             = %.2f rad/s   (w/wn = %.4f)\n', wn3, rf3);
fprintf('   I = k*L^3/(3*E)            = %.4e m^4 = %.2f cm^4\n', Ireq, Ireq*1e8);
if isnan(Dext)
    fprintf('   espesor: FALTA Dext, el diametro exterior del tubo.\n');
    fprintf('            Con Dext: Dint = (Dext^4 - 64*I/pi)^(1/4), t = (Dext-Dint)/2\n');
else
    arg = Dext^4 - 64*Ireq/pi;
    if arg <= 0
        fprintf('   espesor: con Dext = %.1f mm no alcanza ni un tubo macizo.\n', Dext*1e3);
    else
        Dint = arg^(1/4);                 % diametro interior [m]
        esp  = (Dext - Dint)/2;           % espesor de pared [m]
        fprintf('   Dext = %.2f mm -> Dint = %.2f mm\n', Dext*1e3, Dint*1e3);
        fprintf('   espesor t = (Dext-Dint)/2  = %.3f mm\n', esp*1e3);
    end
end
fprintf('\n');
fprintf('   delta = (1/n)*ln(x1/x2)    = %.6f   (n = %d, x2/x1 = %.2f)\n', ...
    delta, nOsc, 1-red);
fprintf('   z     = delta/sqrt(4pi^2+delta^2) = %.6f\n', z3);
fprintf('   ccr   = 2*sqrt(k*m)        = %.2f N*s/m\n', ccr3);
fprintf('b) c     = z*ccr              = %.4f N*s/m\n', c3);
fprintf('=========================================================================\n');

%% PROBLEMA 4 - Palanca acodada con dos bloques, dos resortes y amortiguador
% =========================================================================
% ENUNCIADO (parcial):
%   Un bloque de 2 kg apoya sobre una superficie horizontal, unido a la
%   pared por un resorte de 3000 N/m y un amortiguador de 200 N*s/m. Del
%   bloque sale un cable horizontal hasta el extremo de una palanca acodada
%   (en L) que pivota en su codo: brazo vertical de 0.3 m (donde llega el
%   cable del bloque de 2 kg) y brazo horizontal de 0.2 m, de cuyo extremo
%   cuelga por cable un bloque de 9 kg. Debajo del bloque de 9 kg hay un
%   resorte de 9000 N/m al piso. Una fuerza de 50 N se aplica al bloque de
%   9 kg y se suelta. La coordenada x es la del bloque de 2 kg.
%   Determinar: a) rigidez del sistema, b) amortiguamiento del sistema,
%   c) tipo de amortiguamiento, d) posicion a los 0.5 s [mm],
%   e) velocidad a los 0.5 s [mm/s].
% =========================================================================
%
% RAZONAMIENTO
%
% 1) UN SOLO GRADO DE LIBERTAD, ATADO POR LA PALANCA.
%    Los dos cables son inextensibles y la palanca es rigida (y sin masa,
%    porque el enunciado no le da inercia). Si la palanca gira un angulo
%    chico phi, el extremo del brazo vertical se mueve a*phi en horizontal
%    y el del brazo horizontal b*phi en vertical:
%       x = a*phi      (bloque de 2 kg)
%       y = b*phi      (bloque de 9 kg)     ->     y = (b/a)*x
%    Con a = 0.3 y b = 0.2, el bloque de 9 kg se mueve 2/3 de lo que se
%    mueve el de 2 kg. Ese cociente b/a es la RELACION DE TRANSMISION de la
%    palanca y es el unico numero de geometria que entra en el problema.
%
% 2) SISTEMA EQUIVALENTE EN x (metodo de energias).
%    Todo se expresa en x y en xpunto usando y = (b/a)*x:
%       T = 1/2*mA*xp^2 + 1/2*mB*((b/a)*xp)^2  ->  meq = mA + mB*(b/a)^2
%       V = 1/2*kA*x^2  + 1/2*kB*((b/a)*x)^2   ->  keq = kA + kB*(b/a)^2
%       D = 1/2*cA*xp^2                        ->  ceq = cA
%    El amortiguador esta directo en x, asi que entra sin factor. El
%    resorte y la masa del lado de 9 kg entran con (b/a)^2 = 4/9: la
%    palanca los "achica" vistos desde x. Sale meq*x'' + ceq*x' + keq*x = 0,
%    el mismo sistema que VM.amortA resuelve con m, c y k.
%
% 3) "SE APLICA Y SE SUELTA" SON LAS CONDICIONES INICIALES.
%    La fuerza de 50 N se aplica DESPACIO, el sistema se acomoda en un
%    nuevo equilibrio, y recien ahi se suelta. Eso da:
%       v0 = 0            (se suelta desde el reposo)
%       x0 = deflexion estatica que produce la fuerza
%    La fuerza actua sobre el bloque de 9 kg, en y, no en x. Para pasarla a
%    la coordenada x se usa trabajo virtual: F*dy = F*(b/a)*dx, asi que la
%    fuerza GENERALIZADA en x es Q = F*(b/a), y x0 = Q/keq.
%    Signo: los 50 N empujan al bloque de 9 kg hacia ABAJO, el brazo
%    horizontal baja, la palanca gira, el brazo vertical se va hacia la
%    derecha y tira del bloque de 2 kg en +x (el sentido de la flecha x del
%    dibujo). Por eso x0 sale positivo.
%
% 4) LA GRAVEDAD NO APARECE.
%    Igual que en el problema 1: el peso del bloque de 9 kg ya esta
%    equilibrado por los resortes en la posicion de referencia, y x se mide
%    desde ahi. El unico "empujon" es la fuerza de 50 N, y entra como x0.
%
% 5) POR QUE d) Y e) DAN PRACTICAMENTE CERO.
%    La envolvente decae como exp(-z*wn*t), y z*wn = ceq/(2*meq) = 16.7 1/s.
%    A los 0.5 s eso es exp(-8.3) = 2.4e-4: queda el 0.02% de la amplitud
%    inicial de 4.8 mm. No es un error de cuenta; es que el sistema esta
%    bastante amortiguado (z = 0.49) y 0.5 s son 8 constantes de tiempo.
% =========================================================================

%% 1. Datos (SI base)
mA = 2;           % bloque horizontal [kg]
mB = 9;           % bloque colgado [kg]
kA = 3000;        % resorte del bloque de 2 kg [N/m]
kB = 9000;        % resorte bajo el bloque de 9 kg [N/m]
cA = 200;         % amortiguador del bloque de 2 kg [N*s/m]
a  = 0.3;         % brazo vertical de la palanca, al cable de 2 kg [m]
b  = 0.2;         % brazo horizontal de la palanca, al cable de 9 kg [m]
Fap = 50;         % fuerza aplicada y soltada sobre el bloque de 9 kg [N]
t4  = 0.5;        % instante pedido [s]

%% 2. Sistema equivalente en x
nba = b/a;                    % relacion de transmision y/x [-]
meq = mA + mB*nba^2;          % masa equivalente [kg]
keq4 = kA + kB*nba^2;         % rigidez equivalente [N/m]
ceq4 = cA;                    % amortiguamiento equivalente [N*s/m]

%% 3. Condiciones iniciales: se aplica y se suelta
Q   = Fap*nba;                % fuerza generalizada en x [N]
x04 = Q/keq4;                 % deflexion estatica = x(0) [m]
v04 = 0;                      % se suelta desde el reposo [m/s]

%% 4. Despeje con VM
[res4, regimen4] = VM.amortA('m',meq, 'k',keq4, 'c',ceq4, 'x0',x04, 'v0',v04);

wn4  = double(res4.wn);       % frecuencia natural [rad/s]
ccr4 = double(res4.ccr);      % amortiguamiento critico [N*s/m]
z4   = double(res4.z);        % relacion de amortiguamiento [-]
wd4  = double(res4.wd);       % frecuencia amortiguada [rad/s]

x4_t = res4.x;                        % x(t) [m], expresion en t
v4_t = diff(x4_t, t);                 % v(t) [m/s]
x41  = double(subs(x4_t, t, t4));     % x(0.5 s) [m]
v41  = double(subs(v4_t, t, t4));     % v(0.5 s) [m/s]

%% 5. Resultados
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('  PALANCA ACODADA CON DOS BLOQUES, DOS RESORTES Y AMORTIGUADOR\n');
fprintf('=========================================================================\n');
fprintf('   b/a = %.4f  ->  (b/a)^2 = %.4f\n', nba, nba^2);
fprintf('   meq = mA + mB*(b/a)^2      = %.4f kg\n', meq);
fprintf('a) keq = kA + kB*(b/a)^2      = %.1f N/m\n', keq4);
fprintf('b) ceq = cA                   = %.1f N*s/m\n', ceq4);
fprintf('\n');
fprintf('   wn  = sqrt(keq/meq)        = %.4f rad/s\n', wn4);
fprintf('   ccr = 2*sqrt(keq*meq)      = %.4f N*s/m\n', ccr4);
fprintf('   z   = ceq/ccr              = %.4f\n', z4);
fprintf('c) Regimen: %s-amortiguado\n', regimen4);
fprintf('   wd  = sqrt(1-z^2)*wn       = %.4f rad/s\n', wd4);
fprintf('\n');
fprintf('   Q  = F*(b/a)               = %.4f N\n', Q);
fprintf('   x0 = Q/keq                 = %.6f m  (%.4f mm)\n', x04, x04*1e3);
fprintf('   x(t) = %s\n', char(vpa(x4_t, 5)));
fprintf('\n');
fprintf('d) x(%.1f s) = %.4e m = %.6f mm\n', t4, x41, x41*1e3);
fprintf('e) v(%.1f s) = %.4e m/s = %.6f mm/s\n', t4, v41, v41*1e3);
fprintf('   (exp(-z*wn*t) a los %.1f s = %.2e: la vibracion ya se apago)\n', ...
    t4, exp(-z4*wn4*t4));
fprintf('=========================================================================\n');

%% PROBLEMA 5 - Bloque con dos resortes en paralelo y zeta dado
% =========================================================================
% ENUNCIADO (parcial):
%   El sistema de la figura esta sub-amortiguado, con factor de
%   amortiguamiento zeta = 0.25. Datos: m = 0.2 kg, k1 = 20 N/m,
%   k2 = 30 N/m. Los dos resortes van de la pared al bloque; el
%   amortiguador c va del bloque a la otra pared. Condiciones iniciales:
%   x(0) = 0, xpunto(0) = 4 m/s. Determinar:
%     a) el desplazamiento del bloque en t = 0.10 s [mm];
%     b) la velocidad del bloque en t = 0.15 s [mm/s].
% =========================================================================
%
% RAZONAMIENTO
%
% 1) LOS DOS RESORTES ESTAN EN PARALELO.
%    k1 y k2 salen de la misma pared y llegan al mismo bloque: cuando el
%    bloque se corre x, LOS DOS se deforman x. Las fuerzas se suman y la
%    rigidez equivalente es la suma, keq = k1 + k2 = 50 N/m. Que esten
%    dibujados uno arriba del otro no los pone en serie; en serie estarian
%    encadenados, uno colgado del extremo del otro.
%
% 2) NO HACE FALTA c: ALCANZA CON zeta.
%    El enunciado no da el coeficiente c del amortiguador, da zeta. Y la
%    solucion sub-amortiguada solo depende de zeta y de wn:
%       x(t) = exp(-z*wn*t) * (C1*cos(wd*t) + C2*sin(wd*t))
%       wd   = sqrt(1 - z^2)*wn
%    c sale de yapa como c = z*ccr = z*2*sqrt(keq*m), y VM.subA lo despeja
%    igual, pero no se usa para contestar.
%
% 3) x(0) = 0 MATA EL COSENO.
%    C1 = x0 = 0, y C2 = (v0 + z*wn*x0)/wd = v0/wd. Queda
%       x(t) = (v0/wd) * exp(-z*wn*t) * sin(wd*t)
%    El bloque arranca del equilibrio con un golpe de 4 m/s: sube hasta su
%    primer pico (cerca de t = pi/(2*wd) = 0.10 s, justo el instante que
%    piden en a) y despues decae oscilando.
%
% 4) DOS INSTANTES DISTINTOS.
%    a) pide POSICION en 0.10 s y b) pide VELOCIDAD en 0.15 s. No es el
%    mismo t: v(t) se deriva de x(t) y se evalua en su propio instante.
%    En 0.15 s el bloque ya paso el pico y vuelve hacia el equilibrio, por
%    eso la velocidad sale NEGATIVA.
% =========================================================================

%% 1. Datos (SI base)
m5  = 0.2;        % masa del bloque [kg]
k1  = 20;         % resorte 1 [N/m]
k2  = 30;         % resorte 2 [N/m]
z5  = 0.25;       % factor de amortiguamiento zeta [-]
x05 = 0;          % x(0) [m]
v05 = 4;          % xpunto(0) [m/s]
ta  = 0.10;       % instante para el desplazamiento [s]
tb  = 0.15;       % instante para la velocidad [s]

%% 2. Rigidez equivalente
keq5 = VM.datosParalelos([k1 k2]);    % resortes en paralelo [N/m]

%% 3. Despeje con VM
% VM.amortA acepta z en vez de c: clasifica con z y VM.subA despeja el
% resto (wn, wd, c) a partir de m, k y z. x sale como expresion en t.
[res5, regimen5] = VM.amortA('m',m5, 'k',keq5, 'z',z5, 'x0',x05, 'v0',v05);

wn5  = double(res5.wn);       % frecuencia natural [rad/s]
wd5  = double(res5.wd);       % frecuencia amortiguada [rad/s]
ccr5 = double(res5.ccr);      % amortiguamiento critico [N*s/m]
c5   = double(res5.c);        % coeficiente del amortiguador [N*s/m]

x5_t = res5.x;                        % x(t) [m]
v5_t = diff(x5_t, t);                 % v(t) [m/s]
xa   = double(subs(x5_t, t, ta));     % x(0.10 s) [m]
vb   = double(subs(v5_t, t, tb));     % v(0.15 s) [m/s]

%% 4. Resultados
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('  BLOQUE CON DOS RESORTES EN PARALELO Y ZETA DADO\n');
fprintf('=========================================================================\n');
fprintf('   keq = k1 + k2              = %.1f N/m\n', keq5);
fprintf('   wn  = sqrt(keq/m)          = %.4f rad/s\n', wn5);
fprintf('   wd  = sqrt(1-z^2)*wn       = %.4f rad/s\n', wd5);
fprintf('   ccr = 2*sqrt(keq*m)        = %.4f N*s/m\n', ccr5);
fprintf('   c   = z*ccr                = %.4f N*s/m  (no lo piden)\n', c5);
fprintf('   regimen: %s (z = %.2f)\n', regimen5, z5);
fprintf('   x(t) = %s\n', char(vpa(x5_t, 5)));
fprintf('\n');
fprintf('a) x(%.2f s) = %.6f m   = %.2f mm\n', ta, xa, xa*1e3);
fprintf('b) v(%.2f s) = %.6f m/s = %.1f mm/s\n', tb, vb, vb*1e3);
fprintf('=========================================================================\n');
