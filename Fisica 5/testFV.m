% testFV - suite de regresion de FV.m. Correr con: testFV
% Cada linea imprime true/false. Todo debe dar true.
%
% Los valores esperados se calculan ACA, a mano, con las mismas constantes
% del formulario y en SI base. Asi un error de signo o de factor en FV.m
% salta aunque el numero "se vea creible".
ok = @(n,c) fprintf('%-46s %s\n', n, string(c));

% Comparacion RELATIVA. No sirve max(1,|b|) como en testMM: aca los valores
% son del orden de 1e-19 o 1e-34, y contra 1 cualquier cosa daria true.
%   a : lo que devuelve FV (sym o double)
%   b : el valor esperado, calculado a mano [double, distinto de cero]
tol = @(a,b) abs(double(a) - b) <= 1e-9*abs(b);

% Las direcciones inversas (v desde gam, n desde En...) tienen dos raices y
% el motor avisa. Aca se apaga el aviso para que la salida quede limpia; el
% valor igual se controla.
wEstado = warning('off', 'FV:variasSoluciones');

% Constantes del formulario, en double [SI]. Tienen que ser las MISMAS que
% FV.ctes(): si alguien cambia una alla, este test lo delata.
c    = 299792458;    % velocidad de la luz      [m/s]
h    = 6.63e-34;     % Planck                   [J*s]
hbar = 1.055e-34;    % h barra                  [J*s]
me   = 9.11e-31;     % masa del electron        [kg]
qe   = 1.6e-19;      % carga elemental          [C]
eps0 = 8.85e-12;     % permitividad del vacio   [F/m]

%% 0 constantes y conversiones
C = FV.ctes();
ok('ctes: c, h, hbar', tol(C.c,c) && tol(C.h,h) && tol(C.hbar,hbar));
ok('ctes: me, qe, eps0', tol(C.me,me) && tol(C.qe,qe) && tol(C.eps0,eps0));
ok('eV2J y J2eV son inversas', tol(FV.J2eV(FV.eV2J(13.6)), 13.6));

%% 1 ecRel: relatividad
v0 = 0.8*c;  mo0 = 2;             % v [m/s], masa en reposo [kg]
g0 = 1/sqrt(1 - 0.8^2);           % 5/3
r = FV.rel('v',v0, 'mo',mo0);
ok('rel: gam = 1/sqrt(1-v^2/c^2)', tol(r.gam, g0));
ok('rel: m = gam*mo', tol(r.m, g0*mo0));
ok('rel: p = m*v', tol(r.p, g0*mo0*v0));
ok('rel: K = ET - E0', tol(r.K, (g0-1)*mo0*c^2));
ok('rel: dilatacion t = gam*to', tol(FV.rel('to',1, 'v',0.6*c).t, 1.25));
ok('rel: contraccion L = Lo/gam', tol(FV.rel('Lo',1, 'v',0.6*c).L, 0.8));
% Entrada SIN v: el camino de las particulas (dan mo y p)
p0 = 5e-22;                       % momentum [kg*m/s]
ok('rel: ET desde mo y p (11)', ...
    tol(FV.rel('mo',me, 'p',p0).ET, sqrt((me*c^2)^2 + (p0*c)^2)));
% Inversa documentada: v desde gam (dos raices, +v y -v)
ok('rel: |v| desde gam', tol(abs(double(FV.rel('gam',1.25, 'mo',1).v)), 0.6*c));

%% 2 ecLorentz: transformacion de coordenadas
x0 = 100; t0 = 2e-7; u0 = 0.6*c;  % [m], [s], [m/s]
r = FV.lorentz('x',x0, 't',t0, 'v',u0);
ok('lorentz: xp = gam*(x - v*t)', tol(r.xp, 1.25*(x0 - u0*t0)));
ok('lorentz: tp = gam*(t - v*x/c^2)', tol(r.tp, 1.25*(t0 - u0*x0/c^2)));

%% 3 ecVelo: suma relativista de velocidades
ok('velo: vx desde vxp y u', ...
    tol(FV.velo('vxp',0.5*c, 'u',0.5*c).vx, c/1.25));
ok('velo: vxp desde vx y u', ...
    tol(FV.velo('vx',0.9*c, 'u',0.5*c).vxp, 0.4*c/(1 - 0.45)));

%% 4 ecFoton
lam0 = 500e-9;                    % longitud de onda [m]
r = FV.foton('lam',lam0);
ok('foton: E = h*c/lam', tol(r.E, h*c/lam0));
ok('foton: nu = c/lam', tol(r.nu, c/lam0));
ok('foton: p = h/lam', tol(r.p, h/lam0));
ok('foton: lam desde E', tol(FV.foton('E',FV.eV2J(2)).lam, h*c/(2*1.6e-19)));

%% 5 ecFE: efecto fotoelectrico
lam1 = 400e-9; fi1 = FV.eV2J(2.3); % [m], funcion trabajo [J]
r = FV.fe('lam',lam1, 'fi',fi1);
ok('fe: Kmax = h*c/lam - fi', tol(r.Kmax, h*c/lam1 - fi1));
ok('fe: Vo = Kmax/qe', tol(r.Vo, (h*c/lam1 - fi1)/qe));
ok('fe: lam0 = h*c/fi (umbral)', tol(r.lam0, h*c/fi1));
ok('fe: Kmax desde lam0 y lam', ...
    tol(FV.fe('lam0',550e-9, 'lam',300e-9).Kmax, h*c/300e-9 - h*c/550e-9));

%% 6 ecCompton
lamC = 0.05e-9; fiC = pi/3;       % [m], angulo del foton [rad]
dlam = h/(me*c)*(1 - cos(fiC));   % corrimiento de Compton [m]
r = FV.compton('lam',lamC, 'fi',fiC);
ok('compton: lamp = lam + h/(me*c)*(1-cos fi)', tol(r.lamp, lamC + dlam));
ok('compton: Ke = E - Ep', tol(r.Ke, h*c/lamC - h*c/(lamC + dlam)));
ok('compton: pp = h/lamp', tol(r.pp, h/(lamC + dlam)));
% Inversa documentada: fi desde el corrimiento (dos raices, +fi y -fi)
ok('compton: |fi| desde el corrimiento', ...
    tol(abs(double(FV.compton('lam',lamC, 'lamp',lamC + dlam).fi)), fiC));
% (24): angulo del electron. v es la velocidad del electron [m/s], sacada
% de Ke con la energia relativista: Ke = (gam - 1)*me*c^2.
KeC = h*c/lamC - h*c/(lamC + dlam);
gC  = 1 + KeC/(me*c^2);
vC  = c*sqrt(1 - 1/gC^2);
sTh = h*sin(fiC)*sqrt(1 - vC^2/c^2)/((lamC + dlam)*me*vC);
ok('compton: th desde (24)', ...
    tol(FV.compton('lam',lamC, 'fi',fiC, 'v',vC).th, asin(sTh)));

%% 7 ecRX: tubo de rayos X
r = FV.rx('Vac',35e3);            % tension [V]
ok('rx: Emax = qe*Vac', tol(r.Emax, qe*35e3));
ok('rx: lammin = h*c/(qe*Vac)', tol(r.lammin, h*c/(qe*35e3)));
ok('rx: Vac desde lammin', tol(FV.rx('lammin',0.05e-9).Vac, h*c/(0.05e-9*qe)));

%% 8 ecPares: produccion de pares
lamP = 1e-12;                     % [m]
EP   = h*c/lamP;                  % energia del foton [J]
EuP  = 2*me*c^2;                  % umbral electron-positron [J]
r = FV.pares('mom',me, 'mop',me, 'lam',lamP);
ok('pares: Eu = (mom+mop)*c^2', tol(r.Eu, EuP));
ok('pares: sin reparto, Km no sale', ~isfield(r,'Km') && ~isfield(r,'Kp'));
ok('pares: Kp desde Km', ...
    tol(FV.pares('mom',me, 'mop',me, 'lam',lamP, 'Km',(EP-EuP)/2).Kp, (EP-EuP)/2));

%% 9 ecMagB: particula cargada en campo magnetico
pB = qe*0.5*0.1;                  % p = q*B*r [kg*m/s]
EB = sqrt((me*c^2)^2 + (pB*c)^2); % energia total [J]
gB = EB/(me*c^2);
r = FV.magB('q',qe, 'B',0.5, 'r',0.1, 'mo',me);
ok('magB: E desde q, B, r, mo', tol(r.E, EB));
ok('magB: gam = E/(mo*c^2)', tol(r.gam, gB));
ok('magB: v POSITIVA y correcta', tol(r.v, pB/(me*gB)));
ok('magB: r desde mo, v, q, B', ...
    tol(FV.magB('mo',me, 'v',pB/(me*gB), 'q',qe, 'B',0.5).r, 0.1));

%% 10 ecBroglie
r = FV.broglie('m',me, 'v',1e6);
ok('broglie: lam = h/(m*v)', tol(r.lam, h/(me*1e6)));
ok('broglie: K = p^2/(2*m)', tol(r.K, me*1e12/2));
r = FV.broglie('m',me, 'q',qe, 'Vab',100);
ok('broglie: lam = h/sqrt(2*m*q*Vab)', tol(r.lam, h/sqrt(2*me*qe*100)));
ok('broglie: K = q*Vab', tol(r.K, qe*100));
ok('broglie: v desde lam', tol(FV.broglie('m',me, 'lam',h/(me*1e6)).v, 1e6));

%% 11 ecIncert
ok('incert: dp = hbar/(2*dx)', tol(FV.incert('dx',1e-10).dp, hbar/2e-10));
ok('incert: dE = hbar/(2*dt)', tol(FV.incert('dt',1e-8).dE, hbar/2e-8));
ok('incert: las dos no se tocan', ~isfield(FV.incert('dx',1e-10), 'dE'));

%% 12 ecRendija
r = FV.rendija('lam',500e-9, 'a',0.1e-3, 'X',2, 'm',1);
ok('rendija: th1 = lam/a', tol(r.th1, 5e-3));
% Inversa documentada: th de un seno tiene dos raices (th y pi-th); el
% motor tiene que tomar la chica.
ok('rendija: th es la raiz CHICA', tol(r.th, asin(5e-3)));
ok('rendija: ym = X*m*lam/a', tol(r.ym, 2*5e-3));
ok('rendija: a desde th1', tol(FV.rendija('th1',5e-3, 'lam',500e-9).a, 0.1e-3));

%% 13 ecRed
dR = 1e-3/600;                    % separacion, 600 lineas/mm [m]
ok('red: th es la raiz CHICA', ...
    tol(FV.red('d',dR, 'n',1, 'lam',589e-9).th, asin(589e-9/dR)));
ok('red: lam desde th', ...
    tol(FV.red('d',dR, 'n',1, 'th',asin(589e-9/dR)).lam, 589e-9));

%% 14 ecBohr
% Energia del nivel n para Z [J]: En = -me*Z^2*qe^4/(8*eps0^2*n^2*h^2)
EnB = @(n,Z) -me*Z^2*qe^4/(8*eps0^2*n^2*h^2);
r = FV.bohr('n',3, 'Z',1);
ok('bohr: rn = eps0*n^2*h^2/(pi*me*qe^2*Z)', ...
    tol(r.rn, eps0*9*h^2/(pi*me*qe^2)));
ok('bohr: vn = Z*qe^2/(2*eps0*n*h)', tol(r.vn, qe^2/(2*eps0*3*h)));
ok('bohr: Ln = n*h/(2*pi)', tol(r.Ln, 3*h/(2*pi)));
ok('bohr: En (18)', tol(r.En, EnB(3,1)));
ok('bohr: Un = -2*Kn (virial)', tol(r.Un, -2*double(r.Kn)));
ok('bohr: Z por defecto es 1', tol(FV.bohr('n',3).En, EnB(3,1)));
ok('bohr: He+ con Z = 2, cuatro veces', tol(FV.bohr('n',1, 'Z',2).En, 4*EnB(1,1)));
% Inversa documentada: n desde una energia (n al cuadrado, dos raices)
ok('bohr: |n| desde En', tol(abs(double(FV.bohr('En',EnB(2,1), 'Z',1).n)), 2));

%% 15 ecBohrT
E32 = EnB(3,1) - EnB(2,1);        % foton de 3 -> 2 [J]
r = FV.bohrT('ni',3, 'nf',2, 'Z',1);
ok('bohrT: E = Ei - Ef', tol(r.E, E32));
ok('bohrT: lam = h*c/E', tol(r.lam, h*c/E32));
ok('bohrT: |ni| desde nf y lam', ...
    tol(abs(double(FV.bohrT('nf',2, 'lam',h*c/E32, 'Z',1).ni)), 3));

%% 16 errores
try
    FV.rel('v',0.8*c, 'gam',2); ok('rel contradictorio', false);
catch ME
    ok('detecta datos contradictorios (rel)', ...
        strcmp(ME.identifier,'FV:datosContradictorios'));
end
try
    FV.foton('lam',500e-9, 'nu',1e15); ok('foton contradictorio', false);
catch ME
    ok('detecta lam*nu ~= c (foton)', ...
        strcmp(ME.identifier,'FV:datosContradictorios'));
end
try
    FV.foton('pepe',1); ok('campo invalido', false);
catch ME
    ok('rechaza campo invalido', strcmp(ME.identifier,'FV:campoDesconocido'));
end
try
    FV.fe('lam',400e-9, 'fi'); ok('par incompleto', false);
catch ME
    ok('rechaza par incompleto', strcmp(ME.identifier,'FV:parInvalido'));
end

%% 17 positivos: la raiz fisica, sin aviso
% Estos casos piden algo MAS que el valor absoluto de las secciones de
% arriba: que la variable salga POSITIVA y que el motor no tenga que avisar
% "varias soluciones". Es lo que hace la opcion 'positivos' de
% Motor.despejar en cada atajo. Con el FV.despejar viejo daban false.
% lastwarn registra el aviso aunque este apagado con warning('off').
%   f : handle que corre el despeje y devuelve el struct
%   n : campo que se controla
%   b : valor esperado, POSITIVO
sinAviso = @(f, n, b) positivoSinAviso(f, n, b);
ok('pos: rel v desde gam', sinAviso(@() FV.rel('gam',1.25, 'mo',1), 'v', 0.6*c));
ok('pos: rel v desde mo y ET', ...
    sinAviso(@() FV.rel('mo',me, 'ET',1.25*me*c^2), 'v', 0.6*c));
% Con 'positivos' solo en v (sin p), esta entrada abortaba con
% FV:datosContradictorios: p salia negativa y no cerraba con v positiva.
ok('pos: rel p desde mo y m (no aborta)', ...
    sinAviso(@() FV.rel('mo',me, 'm',1.25*me), 'p', 1.25*me*0.6*c));
ok('pos: compton fi', ...
    sinAviso(@() FV.compton('lam',lamC, 'lamp',lamC + dlam), 'fi', fiC));
ok('pos: magB v desde mo y E', sinAviso(@() FV.magB('mo',me, 'E',EB), 'v', pB/(me*gB)));
ok('pos: magB v desde mo y gam', ...
    sinAviso(@() FV.magB('mo',me, 'gam',gB), 'v', pB/(me*gB)));
ok('pos: bohr n desde En', sinAviso(@() FV.bohr('En',EnB(2,1), 'Z',1), 'n', 2));
ok('pos: bohr n desde rn', ...
    sinAviso(@() FV.bohr('rn',eps0*4*h^2/(pi*me*qe^2), 'Z',1), 'n', 2));
ok('pos: bohrT ni desde nf y lam', ...
    sinAviso(@() FV.bohrT('nf',2, 'lam',h*c/E32, 'Z',1), 'ni', 3));
ok('pos: bohrT nf desde ni y lam', ...
    sinAviso(@() FV.bohrT('ni',3, 'lam',h*c/E32, 'Z',1), 'nf', 2));

warning(wEstado);
disp('=== FIN ===');

function tf = positivoSinAviso(f, n, b)
    % true si f() devuelve el campo n positivo, igual a b, y sin el aviso
    % FV:variasSoluciones.
    lastwarn('');
    r = f();
    [~, id] = lastwarn;
    v = double(r.(n));
    tf = v > 0 && abs(v - b) <= 1e-9*abs(b) && ~strcmp(id, 'FV:variasSoluciones');
end
