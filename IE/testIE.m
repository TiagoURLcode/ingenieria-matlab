% testIE — suite de regresión de IE.m. Correr con: testIE
% Cada línea imprime true/false. Todo debe dar true.
mu0 = 4*pi*1e-7;
ok = @(n,c) fprintf('%-34s %s\n', n, string(c));
tol = @(a,b) abs(a-b) <= 1e-9*max(1,abs(b));

%% 1 pol2rec vectorizada
X = IE.pol2rec([8; 12], [-30; 45]);
ok('pol2rec vectorial', numel(X)==2 && tol(abs(X(1)),8) && tol(abs(X(2)),12) ...
    && tol(rad2deg(angle(X(1))),-30) && tol(rad2deg(angle(X(2))),45));

%% 2 parZ
ok('parZ([10 10]) == 5', tol(IE.parZ([10 10]), 5));
ok('parZ complejo', tol(IE.parZ([10; 1j*10]), (10*1j*10)/(10+1j*10)));
ok('parZ orientacion fila/col', tol(IE.parZ([10 20 30]), IE.parZ([10;20;30])));

%% 3 f2l / l2f direccion correcta
ok('f2l(220) == 381.05', tol(IE.f2l(220), 220*sqrt(3)));
ok('l2f(380) == 219.4',  tol(IE.l2f(380), 380/sqrt(3)));
ok('l2f(f2l(x)) == x',   tol(IE.l2f(IE.f2l(127)), 127));

%% 4 fasores: coherencia interna E_AB = E_AN - E_BN
M = IE.fasores(220);
fas = IE.pol2rec(M(1:3,1), M(1:3,2));
lin = IE.pol2rec(M(4:6,1), M(4:6,2));
ok('fasores AB = AN-BN', tol(abs(lin(1)-(fas(1)-fas(2))), 0));
ok('fasores BC = BN-CN', tol(abs(lin(2)-(fas(2)-fas(3))), 0));
ok('fasores CA = CN-AN', tol(abs(lin(3)-(fas(3)-fas(1))), 0));
ok('fasores suma fases = 0', abs(sum(fas)) < 1e-12);
ok('fasores AB adelanta 30', tol(mod(M(4,2)-M(1,2),360), 30));
ok('fasores pico = rms*sqrt2', tol(M(1,3), 220*sqrt(2)));
Mr = IE.fasores(220, 15);
ok('fasores con ang0', tol(Mr(1,2),15) && tol(Mr(4,2),45));

%% 5 divisores
Z = [10; 20; 30];
ok('divV suma = V', tol(sum(IE.divV(120, Z)), 120));
ok('divI suma = I', tol(sum(IE.divI(6, Z)), 6));
ok('divI inverso a Z', all(tol(IE.divI(6,[10;10]), [3;3])));

%% 6 potencias elemento a elemento
V = [100; 100; 100];
I = [1; 1j*1; -1j*1];            % resistiva, capacitiva, inductiva
T = IE.potencias(V, I);
ok('potencias tipo x elemento', numel(T.tipo)==3);
ok('potencias unitario',   T.tipo(1)=="unitario");
ok('potencias adelantado', T.tipo(2)=="adelantado");
ok('potencias atrasado',   T.tipo(3)=="atrasado");
ok('potencias Stot', tol(T.Stot, sum(V.*conj(I))));
Te = IE.potencias(100, IE.pol2rec(5,-30));
ok('potencias FP 30deg', tol(Te.FP, cosd(30)) && Te.tipo=="atrasado");

%% 7 ecuacionesB / datosB
d = struct('mu',5000,'len',0.3,'N',200,'A',1e-3,'I',2);
Fi = double(IE.datosB(d, 'Fi'));
Rref = 0.3/(5000*mu0*1e-3);
ok('datosB Fi vs reluctancia', tol(Fi, 200*2/Rref));
H = double(IE.datosB(d, 'H'));
ok('datosB H = NI/len', tol(H, 200*2/0.3));
B = double(IE.datosB(d, 'B'));
ok('datosB B = mu*mu0*H', tol(B, 5000*mu0*H));
ok('datosB B = Fi/A', tol(B, Fi/1e-3));
Iv = double(IE.datosB(struct('mu',5000,'len',0.3,'N',200,'A',1e-3,'Fi',Fi), 'I'));
ok('datosB despeja I (inverso)', tol(Iv, 2));
vv = double(IE.datosB(struct('N',200,'dFi',0.5), 'v'));
ok('datosB Faraday v = N*dFi', tol(vv, 100));
try
    IE.datosB(struct('pepe',1), 'I'); ok('datosB campo invalido', false);
catch ME
    ok('datosB campo invalido', strcmp(ME.identifier,'IE:campoDesconocido'));
end

%% 8 faradayB analisis temporal
syms t
dm = struct('N',200,'A',1e-3,'len',0.3,'mu',5000);
[v_t, Fi_t, L] = IE.faradayB(dm, 2*sin(377*t));
ok('faradayB L', tol(double(L), 5000*mu0*200^2*1e-3/0.3));
ok('faradayB v = L dI/dt', isAlways(simplify(v_t - L*diff(2*sin(377*t),t))==0));
ok('faradayB v no es cero', ~isequal(simplify(v_t), sym(0)));
ok('faradayB Fi = B*A', tol(double(subs(Fi_t,t,pi/(2*377))), ...
    5000*mu0*200*1e-3*2/0.3));

%% 9 reluctSeg con dA proporcional
s = struct('len',0.3,'A',1e-3,'mu',5000,'g',1e-3,'dA',0.10);
Rn = (0.3-1e-3)/(5000*mu0*1e-3);
Rg = 1e-3/(mu0*1e-3*1.10);
ok('reluctSeg dA proporcional', tol(IE.reluctSeg(s), Rn+Rg));
s0 = struct('len',0.3,'A',1e-3,'mu',5000);
ok('reluctSeg sin gap', tol(IE.reluctSeg(s0), 0.3/(5000*mu0*1e-3)));
try
    IE.reluctSeg(struct('len',1e-3,'A',1e-3,'mu',5000,'g',0.3));
    ok('reluctSeg gap>len', false);
catch ME
    ok('reluctSeg gap>len', strcmp(ME.identifier,'IE:gapMayorQueTramo'));
end

%% 10 ecuacionesSeg coherente con reluctSeg
ds = struct('len',0.3,'A',1e-3,'mu',5000,'g',1e-3,'dA',0.10);
[Rsv, resS] = IE.datosSeg(ds, 'Rs');
ok('datosSeg Rs == reluctSeg', tol(double(Rsv), IE.reluctSeg(s)));
ok('datosSeg Rn+Rg == Rs', tol(double(resS.Rn+resS.Rg), double(Rsv)));
Bg = double(IE.datosSeg(setfield(ds,'Fi',1e-3), 'Bg'));
ok('datosSeg Bg = Fi/(A(1+dA))', tol(Bg, 1e-3/(1e-3*1.10)));
Bh = double(IE.datosSeg(setfield(ds,'Fi',1e-3), 'B'));
ok('datosSeg B > Bg (fringing)', Bh > Bg);
try
    IE.datosB(struct('N',200), 'pepe'); ok('despejar inc invalida', false);
catch ME
    ok('despejar inc invalida', strcmp(ME.identifier,'IE:campoDesconocido'));
end
[~, resB] = IE.datosB(struct('mu',5000,'len',0.3,'N',200,'A',1e-3,'I',2), 'Fi');
ok('despejar devuelve intermedias', isfield(resB,'H') && isfield(resB,'B'));
try
    IE.datosB(struct('N',200,'dFi',0.5,'v',999), 'B'); ok('contradiccion', false);
catch ME
    ok('contradiccion detectada', strcmp(ME.identifier,'IE:datosContradictorios'));
end

%% 11 reluctSeg: geometria a*b, fringing calculado, multiplicidad n
sab = struct('len',0.3,'mu',5000,'a',0.02,'b',0.05,'g',1e-3);
[Rab, dab] = IE.reluctSeg(sab);
ok('reluctSeg A = a*b', tol(dab.A, 0.02*0.05));
ok('reluctSeg fringing (a+g)(b+g)', tol(dab.Agap, (0.02+1e-3)*(0.05+1e-3)));
ok('reluctSeg dA calculado', tol(dab.dA, dab.Agap/dab.A - 1));
sab2 = sab; sab2.dA = 0;
[~, dab2] = IE.reluctSeg(sab2);
ok('reluctSeg dA explicito manda', tol(dab2.Agap, dab2.A));
sn = s; sn.n = 3;
ok('reluctSeg n multiplica', tol(IE.reluctSeg(sn), 3*IE.reluctSeg(s)));
try
    IE.reluctSeg(struct('len',0.3,'A',1e-3,'mu',4*pi*1e-7));
    ok('reluctSeg mu absoluta', false);
catch ME
    ok('reluctSeg rechaza mu absoluta', strcmp(ME.identifier,'IE:muRelativa'));
end
try
    IE.reluctSeg(struct('len',0.3,'mu',5000,'a',0.02,'b',0.05,'A',9e-9));
    ok('reluctSeg A vs a*b', false);
catch ME
    ok('reluctSeg detecta A vs a*b', strcmp(ME.identifier,'IE:areaInconsistente'));
end

%% 12 fluxO: nucleo cerrado en serie
r = IE.fluxO({s0,s0,s0,s0}, 100, 1);
ok('fluxO Rt serie', tol(r.Rt, 4*IE.reluctSeg(s0)));
ok('fluxO Fi = fmm/Rt', tol(r.Fi, 100/r.Rt));
ok('fluxO L = N^2/Rt', tol(r.L, 100^2/r.Rt));
ok('fluxO L = N*Fi/I', tol(r.L, 100*r.Fi/1));
ok('fluxO Ampere: sum(caida)=fmm', tol(sum(r.caida), r.fmm));
ok('fluxO frac suma 1', tol(sum(r.frac), 1));
ok('fluxO B = Fi/A', all(tol(r.B, r.Fi/1e-3)));
ok('fluxO sin gap -> Bg NaN', all(isnan(r.Bg)));
ok('fluxO sin gap -> F = 0', r.Ftot == 0);
ok('fluxO cell == struct array', ...
    tol(r.Rt, IE.fluxO(repmat(s0,1,4),100,1).Rt));
try
    IE.fluxO({}, 100, 1); ok('fluxO sin tramos', false);
catch ME
    ok('fluxO rechaza vacio', strcmp(ME.identifier,'IE:sinTramos'));
end

% fuerza contra formula cerrada: F = Bg^2*Agap/(2*mu0)
rg = IE.fluxO({s0, s}, 500, 2);
ok('fluxO Bg = Fi/Agap', tol(rg.Bg(2), rg.Fi/(1e-3*1.10)));
ok('fluxO F = Bg^2*Ag/(2mu0)', ...
    tol(rg.F(2), rg.Bg(2)^2*(1e-3*1.10)/(2*mu0)));
ok('fluxO F=0 donde no hay gap', rg.F(1) == 0);

% saturacion: fuerzo B alto y espero warning
lastwarn('',''); w = warning('off','IE:saturacion');
IE.fluxO({struct('len',0.3,'A',1e-4,'mu',5000)}, 1000, 5);
[~, id] = lastwarn; warning(w);
ok('fluxO avisa saturacion', strcmp(id,'IE:saturacion'));
lastwarn('',''); w = warning('off','IE:saturacion');
IE.fluxO({struct('len',0.3,'A',1e-4,'mu',5000)}, 1000, 5, 500);
[~, id2] = lastwarn; warning(w);
ok('fluxO Bsat configurable', ~strcmp(id2,'IE:saturacion'));

%% 13 U+I armado a mano: es un O con el gap en n=2
gp = s; gp.n = 2;
rUI = IE.fluxO({s0, s0, s0, s0, gp}, 100, 1);
ok('U+I: 2 gaps en serie', tol(rUI.R(5), 2*IE.reluctSeg(s)));
ok('U+I: Rt = hierro + gaps', tol(rUI.Rt, sum(rUI.R(1:4)) + rUI.R(5)));
ok('U+I: fuerza x2 contactos', ...
    tol(rUI.Ftot, 2*rUI.Bg(5)^2*(1e-3*1.10)/(2*mu0)));
ok('U+I: no muta el gap original', ~isfield(s,'n'));

% las funciones de forma que se fueron
m = methods('IE');
ok('fluxU eliminada', ~any(strcmp(m,'fluxU')));
ok('fluxCuadrado eliminada', ~any(strcmp(m,'fluxCuadrado')));
ok('fluxUI eliminada', ~any(strcmp(m,'fluxUI')));
ok('circuitoMag renombrada', ~any(strcmp(m,'circuitoMag')));
ok('B-H eliminado', ~any(ismember({'material','HdeB','BdeH','fmmSeg', ...
    'interpCurva','geomSeg'}, m)));
ok('API magnetica minima', all(ismember({'reluctSeg','fluxO','fluxE'}, m)));

%% 14 fluxE
[FiE, RtE, rE] = IE.fluxE([1e5 2e5 2e5], 1, 100, 1);
ok('fluxE Rt serie-paralelo', tol(RtE, 1e5 + 1e5));
ok('fluxE ley de nodos', abs(sum(FiE)) < 1e-12);
ok('fluxE reparto igual', tol(FiE(2), FiE(3)) && tol(FiE(2), -FiE(1)/2));
ok('fluxE L numerica', tol(rE.L, 100^2/RtE));
ok('fluxE sin geometria no da B', ~isfield(rE,'B'));
[FiE2, ~, rE2] = IE.fluxE(repmat(s0,1,3), 2, 100, 1);
ok('fluxE acepta structs', abs(sum(FiE2)) < 1e-12 && FiE2(2) > 0);
ok('fluxE con geometria da B', isfield(rE2,'B') && tol(rE2.B(2), FiE2(2)/1e-3));
wE = warning('off','IE:saturacion');
[FiE4, ~, rE4] = IE.fluxE({s0, s, s}, 1, 500, 2);
warning(wE);
ok('fluxE acepta cell', abs(sum(FiE4)) < 1e-12);
ok('fluxE fuerza en gap', tol(rE4.F(2), rE4.Bg(2)^2*(1e-3*1.10)/(2*mu0)));
[FiE3, ~] = IE.fluxE([1e5 2e5 2e5], 1, 100, 1, -1);
ok('fluxE sentido -1', all(tol(FiE3, -FiE)));
try
    IE.fluxE([1e5 2e5], 1, 100, 1); ok('fluxE valida 3 piernas', false);
catch ME
    ok('fluxE valida 3 piernas', strcmp(ME.identifier,'IE:fluxETresPiernas'));
end
try
    IE.fluxE([1e5 2e5 3e5], 7, 100, 1); ok('fluxE valida b', false);
catch ME
    ok('fluxE valida indice b', strcmp(ME.identifier,'IE:fluxEPierna'));
end

disp('=== FIN ===');
