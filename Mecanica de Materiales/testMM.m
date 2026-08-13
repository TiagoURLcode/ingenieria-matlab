% testMM — suite de regresión de MM.m. Correr con: testMM
% Cada línea imprime true/false. Todo debe dar true.
ok  = @(n,c) fprintf('%-38s %s\n', n, string(c));
tol = @(a,b) abs(a-b) <= 1e-9*max(1,abs(b));

% Caso base: barra de acero, 20 kN, 2 m, A = 300 mm^2. Todo en N-m-Pa.
P0 = 20e3; L0 = 2; E0 = 200e9; A0 = 300e-6;
d0 = P0*L0/(E0*A0);              % 6.6667e-4 m
s0 = P0/A0;                      % 66.667 MPa

%% 1 ecuacionesAxial: estructura del modelo
[eqs, S] = MM.ecuacionesAxial();
ok('ecuacionesAxial da 6 ecuaciones', numel(eqs) == 6);
ok('diccionario completo', all(isfield(S, ...
    {'P','A','sig','eps','E','L','delta','k'})));
ok('S trae simbolos, no valores', isa(S.P,'sym') && isa(S.eps,'sym'));

%% 2 datosAxial: el camino directo
d = struct('P',P0,'L',L0,'E',E0,'A',A0);
ok('delta = P*L/(E*A)', tol(double(MM.datosAxial(d,'delta')), d0));
ok('sig = P/A',         tol(double(MM.datosAxial(d,'sig')),   s0));
ok('eps = sig/E',       tol(double(MM.datosAxial(d,'eps')),   s0/E0));
ok('eps = delta/L',     tol(double(MM.datosAxial(d,'eps')),   d0/L0));
ok('k = E*A/L',         tol(double(MM.datosAxial(d,'k')),     E0*A0/L0));
ok('k = P/delta',       tol(double(MM.datosAxial(d,'k')),     P0/d0));

%% 3 despeje INVERSO: entra por donde venga el enunciado
ok('despeja P desde delta', ...
    tol(double(MM.datosAxial(struct('delta',d0,'L',L0,'E',E0,'A',A0),'P')), P0));
ok('despeja A desde sig', ...
    tol(double(MM.datosAxial(struct('P',P0,'sig',s0),'A')), A0));
ok('despeja E desde delta', ...
    tol(double(MM.datosAxial(struct('P',P0,'L',L0,'delta',d0,'A',A0),'E')), E0));
ok('despeja L desde eps', ...
    tol(double(MM.datosAxial(struct('delta',d0,'eps',d0/L0),'L')), L0));
ok('despeja A desde k', ...
    tol(double(MM.datosAxial(struct('k',E0*A0/L0,'E',E0,'L',L0),'A')), A0));
ok('entra por sig y eps (Hooke solo)', ...
    tol(double(MM.datosAxial(struct('sig',s0,'eps',s0/E0),'E')), E0));

%% 4 despejar devuelve las intermedias gratis
[~, res] = MM.datosAxial(d, 'delta');
ok('res trae intermedias', isfield(res,'sig') && isfield(res,'eps') ...
    && isfield(res,'k'));
ok('res.sig coherente', tol(double(res.sig), s0));

%% 5 compresion: el signo se propaga entero
dc = struct('P',-P0,'L',L0,'E',E0,'A',A0);
ok('compresion: delta < 0', double(MM.datosAxial(dc,'delta')) < 0);
ok('compresion: |delta| igual', tol(abs(double(MM.datosAxial(dc,'delta'))), d0));
ok('compresion: sig < 0', double(MM.datosAxial(dc,'sig')) < 0);

%% 6 axial: resuelve todo de una
r = MM.axial(d);
ok('axial devuelve los 8 campos', numel(fieldnames(r)) == 8);
ok('axial es numerico', isnumeric(r.delta) && isnumeric(r.sig));
ok('axial delta', tol(r.delta, d0));
ok('axial conserva los datos', tol(r.P,P0) && tol(r.A,A0));
r2 = MM.axial(struct('sig',s0,'E',E0));
ok('axial parcial: da eps', isfield(r2,'eps') && tol(r2.eps, s0/E0));
ok('axial parcial: NO inventa delta', ~isfield(r2,'delta'));

%% 7 errores y contradicciones
try
    MM.datosAxial(struct('pepe',1), 'delta'); ok('campo invalido', false);
catch ME
    ok('rechaza campo invalido', strcmp(ME.identifier,'MM:campoDesconocido'));
end
try
    MM.datosAxial(d, 'pepe'); ok('incognita invalida', false);
catch ME
    ok('rechaza incognita invalida', strcmp(ME.identifier,'MM:campoDesconocido'));
end
try
    MM.datosAxial(struct('P',P0,'A',A0,'sig',999e6), 'E');
    ok('contradiccion', false);
catch ME
    ok('detecta datos contradictorios', ...
        strcmp(ME.identifier,'MM:datosContradictorios'));
end
lastwarn('',''); w = warning('off','MM:sinSolucion');
MM.datosAxial(struct('P',P0), 'delta');
[~, id] = lastwarn; warning(w);
ok('avisa si faltan datos', strcmp(id,'MM:sinSolucion'));

%% 8 seccion: las tres geometrias
ok('seccion A directa',   tol(MM.seccion(struct('A',A0)), A0));
ok('seccion circular',    tol(MM.seccion(struct('dia',0.02)), pi*0.02^2/4));
ok('seccion rectangular', tol(MM.seccion(struct('a',0.02,'b',0.015)), 3e-4));
ok('seccion tubo', tol(MM.seccion(struct('dia',0.02,'hueco',0.016)), ...
    pi*(0.02^2-0.016^2)/4));
ok('seccion A y geometria coherentes', ...
    tol(MM.seccion(struct('a',0.02,'b',0.015,'A',3e-4)), 3e-4));
try
    MM.seccion(struct('a',0.02,'b',0.015,'A',300)); ok('A vs geometria', false);
catch ME
    ok('detecta A vs geometria (unidades)', ...
        strcmp(ME.identifier,'MM:areaInconsistente'));
end
try
    MM.seccion(struct('L',1)); ok('falta area', false);
catch ME
    ok('exige area o geometria', strcmp(ME.identifier,'MM:faltaArea'));
end
try
    MM.seccion(struct('dia',0.02,'hueco',0.03)); ok('hueco invalido', false);
catch ME
    ok('rechaza hueco >= dia', strcmp(ME.identifier,'MM:huecoInvalido'));
end

%% 9 escalonada: coherencia con la barra uniforme
t1 = struct('N',P0,'L',L0,'E',E0,'A',A0);
re = MM.escalonada({t1});
ok('escalonada 1 tramo == axial', tol(re.delta, d0));
ok('escalonada sig', tol(re.sig, s0));
ok('escalonada k = E*A/L', tol(re.k, E0*A0/L0));

% partir un tramo en dos mitades no puede cambiar el resultado
th = t1; th.L = L0/2;
re2 = MM.escalonada({th, th});
ok('partir el tramo no cambia delta', tol(re2.delta, d0));
ok('acum es cumsum', tol(re2.acum(1), d0/2) && tol(re2.acum(2), d0));
ok('frac suma 1', tol(sum(re2.frac), 1));

% tramos con distinta seccion y signo
ta = struct('N', 30e3,'L',1.0,'E',E0,'dia',0.02);
tb = struct('N',-10e3,'L',0.5,'E',70e9,'a',0.01,'b',0.02);
rm = MM.escalonada({ta, tb});
dA = 30e3*1.0/(E0*pi*0.02^2/4);
dB = -10e3*0.5/(70e9*2e-4);
ok('mixto: delta = suma con signo', tol(rm.delta, dA+dB));
ok('mixto: tramo 2 se acorta', rm.dt(2) < 0);
ok('mixto: frac en valor absoluto', tol(sum(rm.frac), 1));
ok('mixto: A por geometria', tol(rm.A(1), pi*0.02^2/4) && tol(rm.A(2), 2e-4));
ok('mixto: eps = dt/L', all(tol(rm.eps, rm.dt./[1.0;0.5])));
ok('escalonada cell == struct array', ...
    tol(MM.escalonada(repmat(t1,1,3)).delta, MM.escalonada({t1,t1,t1}).delta));

% fluencia
lastwarn(''); w = warning('off','MM:fluencia');
rf = MM.escalonada({struct('N',100e3,'L',1,'E',E0,'A',1e-4)}, 250e6);
[~, idf] = lastwarn; warning(w);
ok('escalonada avisa fluencia', strcmp(idf,'MM:fluencia') && rf.fluye(1));
ok('sin sigY no controla nada', ~any(MM.escalonada({t1}).fluye));
try
    MM.escalonada({}); ok('escalonada vacia', false);
catch ME
    ok('escalonada rechaza vacio', strcmp(ME.identifier,'MM:sinTramos'));
end
try
    MM.escalonada({struct('L',1,'E',E0,'A',A0)}); ok('falta N', false);
catch ME
    ok('escalonada exige N, L, E', strcmp(ME.identifier,'MM:faltaDato'));
end

%% 10 ahusada
syms x
Lc = 2; dini = 0.04; dfin = 0.02;
Ax = pi*(dini + (dfin-dini)*x/Lc)^2/4;
dl = MM.ahusada(P0, Ax, x, Lc, E0);
% Cerrada para el cono: delta = 4*P*L/(pi*E*d0*d1)
ok('ahusada cono vs formula cerrada', ...
    tol(double(dl), 4*P0*Lc/(pi*E0*dini*dfin)));
% seccion constante: tiene que dar lo mismo que la barra uniforme
w = warning('off','MM:seccionConstante');
dcte = MM.ahusada(P0, A0, x, L0, E0);
warning(w);
ok('ahusada con A cte == uniforme', tol(double(dcte), d0));
lastwarn(''); w = warning('off','MM:seccionConstante');
MM.ahusada(P0, A0, x, L0, E0);
[~, idc] = lastwarn; warning(w);
ok('ahusada avisa si nada varia', strcmp(idc,'MM:seccionConstante'));
% N variable (peso propio: N(x) crece linealmente) -> delta = w*L^2/(2*E*A)
wq = 500;                                  % N/m
dpp = MM.ahusada(wq*x, A0, x, L0, E0);
ok('ahusada con N(x)', tol(double(dpp), wq*L0^2/(2*E0*A0)));
ok('ahusada devuelve el integrando', ...
    isAlways(simplify(MM.ahusada(P0,Ax,x,Lc,E0) - int(P0/(E0*Ax),x,0,Lc)) == 0));
try
    MM.ahusada(P0, Ax, 3, Lc, E0); ok('x no simbolica', false);
catch ME
    ok('ahusada exige x simbolica', strcmp(ME.identifier,'MM:xNoSimbolica'));
end

%% 11 unidades: N-mm-MPa tiene que dar el mismo numero en mm
dmm = double(MM.datosAxial(struct('P',20e3,'L',2000,'E',200e3,'A',300),'delta'));
ok('coherencia N-mm-MPa', tol(dmm, d0*1000));

disp('=== FIN ===');
