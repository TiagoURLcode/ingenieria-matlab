% testSp — suite de regresión de sp.m. Correr con: testSp
% Cada línea imprime true/false. Todo debe dar true.
%
% NOTA SOBRE Motor.probar: no se usa acá. Esa función asume que cada
% variable del sistema se puede recuperar quitándola de un juego de datos
% completo, y eso vale para una MALLA (VM, FV, MM, IE), no para los sisXXX
% de esta clase: son una CADENA de un solo sentido, de las longitudes y t2
% hacia los ángulos de salida (ver la nota en sp.datosSis). Pedirle a
% Motor.probar que recupere 'a' desde los ángulos de salida fallaría, y eso
% NO sería un bug: es la limitación documentada del planteo en cadena. Por
% eso este archivo verifica con asserts directos, como testMM.m y testIE.m.

ok  = @(n,c) fprintf('%-42s %s\n', n, string(c));
tol = @(a,b) abs(a-b) <= 1e-6*max(1,abs(b));

%% ===== 1. sisAC vs sisL4V: mismo mecanismo, mismas dos raices =========
%  Regresion del bug de deg2rad: sisAC aplicaba deg2rad a t2 pese a que
%  toda la clase trabaja en radianes. Se corrigio quitando esa conversion;
%  este test evita que vuelva.
mecs = { [0.040 0.120 0.080 0.100 pi/4], ...
         [2 7 9 6 pi/6], ...
         [5 8 6 8 2.1] };

for i = 1:numel(mecs)
    m = mecs{i};
    a=m(1); b=m(2); c=m(3); d=m(4); t2=m(5);
    rAC  = sp.datosSis('AC',  'a',a,'b',b,'c',c,'d',d,'t2',t2);
    rL4V = sp.datosSis('L4V', 'a',a,'b',b,'c',c,'d',d,'t2',t2);

    % sisAC no nombra cual raiz es abierta y cual cruzada (a diferencia de
    % sisL4V); se comparan los CONJUNTOS de t41 y t42, no raiz por raiz.
    tAC  = sort(mod([double(rAC.t41)  double(rAC.t42)],  2*pi));
    tL4V = sort(mod([double(rL4V.t41) double(rL4V.t42)], 2*pi));
    ok(sprintf('sisAC == sisL4V, mecanismo %d', i), ...
        all(tol(tAC, tL4V)));
end

%% ===== 2. sisL4V: el lazo vectorial cierra en las dos ramas ===========
a=0.040; b=0.120; c=0.080; d=0.100; t2=pi/4;
r = sp.datosSis('L4V', 'a',a,'b',b,'c',c,'d',d,'t2',t2);
t3 = double([r.t31 r.t32]); t4 = double([r.t41 r.t42]);
cx = a*cos(t2) + b*cos(t3) - c*cos(t4) - d;
cy = a*sin(t2) + b*sin(t3) - c*sin(t4);
ok('sisL4V cierra en x, las dos ramas', all(abs(cx) < 1e-9));
ok('sisL4V cierra en y, las dos ramas', all(abs(cy) < 1e-9));

%% ===== 3. sisMC: la corredera reproduce el lazo ========================
a=0.03; b=0.09; c=0.01; t2=1.0;
r = sp.datosSis('MC', 'a',a,'b',b,'c',c,'t2',t2);
t31 = double(r.t31); t32 = double(r.t32); d1 = double(r.d1); d2 = double(r.d2);
ok('sisMC lazo y, abierta',  tol(a*sin(t2) - b*sin(t31) - c, 0));
ok('sisMC lazo y, cruzada',  tol(a*sin(t2) - b*sin(t32) - c, 0));
ok('sisMC lazo x, abierta',  tol(a*cos(t2) - b*cos(t31) - d1, 0));
ok('sisMC lazo x, cruzada',  tol(a*cos(t2) - b*cos(t32) - d2, 0));

%% ===== 4. sisCM: al menos una rama reproduce d con cada t2 =============
%  sp.sisCM avisa que la rama correcta de t3 puede ser la otra (sin el
%  +pi); acá solo se pide que t2 (el que SI resuelve el sistema sin
%  ambiguedad de rama) cierre el lazo: distancia de A=(a*cos t2,a*sin t2)
%  al punto de la corredera B=(d,c) tiene que valer b, el acoplador.
%  a,b,c,d elegidos para que el mecanismo SI ensamble: r=hypot(d,c) y b
%  tienen que solaparse con [|a-r|, a+r], si no las raices salen COMPLEJAS
%  (ver la nota de sp.m sobre discriminante negativo) y double() les tira
%  la parte imaginaria sin avisar — probado, es la trampa de este test.
a=0.03; d=0.05; c=0.01; b=0.05;
r = sp.datosSis('CM', 'a',a,'b',b,'c',c,'d',d);
t21 = double(r.t21); t22 = double(r.t22);
cierra = @(t2) isreal(t2) && tol(hypot(a*cos(t2)-d, a*sin(t2)-c), b);
ok('sisCM: t21 cierra el circulo del acoplador', cierra(t21));
ok('sisCM: t22 cierra el circulo del acoplador', cierra(t22));

%% ===== 5. sisCI: relacion de angulos y longitud efectiva ===============
a=0.05; c=0.015; d=0.04; t2=0.8; g=pi/3;
r = sp.datosSis('CI', 'a',a,'c',c,'d',d,'t2',t2,'g',g);
t41=double(r.t41); t42=double(r.t42); t31=double(r.t31); t32=double(r.t32);
ok('sisCI: t31 = t41+g (abierta)',   tol(t31, t41+g));
ok('sisCI: t32 = t42+g-pi (cruzada)', tol(t32, t42+g-pi));
ok('sisCI: b1 real', isreal(double(r.b1)));
ok('sisCI: b2 real', isreal(double(r.b2)));

%% ===== 6. sisV4B: el lazo de velocidades cierra ========================
%  VA + VBA == VB es el control que documenta sp.sisV4B; no es una
%  ecuacion del sistema, asi que se verifica aparte.
a=2; b=7; c=9; d=6; t2=pi/6;
rp  = sp.datosSis('L4V', 'a',a,'b',b,'c',c,'d',d,'t2',t2);
vAB = sp.datosSis('V4B', 'a',a,'b',b,'c',c,'t2',t2, ...
        't3',double(rp.t31),'t4',double(rp.t41),'w2',10);
VA = double(vAB.VA); VBA = double(vAB.VBA); VB = double(vAB.VB);
ok('sisV4B: VA + VBA == VB', tol(abs(VA+VBA-VB), 0));

%% ===== 7. sisVP: VP = VA + VPA por construccion ========================
vP = sp.datosSis('VP', 'a',a, 'p',0.05, 't2',t2, 't3',double(rp.t31), ...
        'delta3',pi/6, 'w2',10, 'w3',double(vAB.w3));
ok('sisVP: VP == VA + VPA', ...
    tol(abs(double(vP.VP) - (double(vP.VA)+double(vP.VPA))), 0));

%% ===== 8. t2 simbolico (w*t): regresion del bug de has() ===============
%  Motor.aislar usaba has(), que con las expresiones grandes que deja
%  t2 = w*t en sisL4V (piecewise + abs + radicales) hacia abortar a
%  sym/logical en vez de decidir que el simbolo no aparece. Se corrigio
%  con symvar + comparacion por nombre; este test evita que vuelva.
syms w t
rt = sp.datosSis('L4V', 'a',a, 'b',b, 'c',c, 'd',d, 't2',w*t);
t3fun = matlabFunction(rt.t31, 'Vars', [w t]);
ok('t2 = w*t no rompe sisL4V', isa(rt.t31, 'sym'));
ok('t2 = w*t da un numero al evaluar', ...
    isfinite(t3fun(10, 0.05)));

%% ===== 9. sistema/metodo invalido ======================================
try
    sp.sistema('no-existe');
    ok('metodo invalido: error esperado', false);
catch ME
    ok('metodo invalido: error esperado', ...
        strcmp(ME.identifier, 'sp:metodoInvalido'));
end

%% ===== 10. eslabones y muAT: valores de referencia =====================
%  Mecanismo de las cabeceras de sp.eslabones y sp.muAT: a=40,b=120,c=80,
%  d=100. Grashof clase I, gira solo 'a' -> manivela-balancin.
[g, clase, tipo] = sp.eslabones('a',40,'b',120,'c',80,'d',100);
ok('eslabones: Grashof', g);
ok('eslabones: clase I', clase == 1);
ok('eslabones: manivela-balancin', tipo == "manivela-balancín");

% Referencia INDEPENDIENTE: la formula de la ley de cosenos tal como la
% escribe la cabecera de sp.muAT, calculada aca aparte (no copiando el
% numero impreso por una corrida anterior, que solo tenia 4 decimales).
aa=40; bb=120; cc=80; dd=100;
mu1ref =      acos((bb^2 + cc^2 - (dd - aa)^2)/(2*bb*cc));
mu2ref = pi - acos((bb^2 + cc^2 - (dd + aa)^2)/(2*bb*cc));
[mu1, mu2] = sp.muAT('a',aa,'b',bb,'c',cc,'d',dd);
ok('muAT: mu1 (plegada) vs formula',   tol(mu1, mu1ref));
ok('muAT: mu2 (extendida) vs formula', tol(mu2, mu2ref));

fprintf('=== FIN ===\n');
