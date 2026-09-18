% Prueba funcional de todas las funciones de VM.m
% Cada caso compara contra un valor calculado a mano.

tol = 1e-9;
fallas = 0;

    function ok = verificar(nombre, obtenido, esperado, tol)
        ok = abs(obtenido - esperado) <= tol*max(1, abs(esperado));
        if ok
            fprintf('  OK   %-16s = %.6g\n', nombre, obtenido);
        else
            fprintf('  FALLA %-15s = %.6g   (esperado %.6g)\n', nombre, obtenido, esperado);
        end
    end

fprintf('=== RIGIDEZ EQUIVALENTE ===\n');
fallas = fallas + ~verificar('datosSerieR',  VM.datosSerieR([2 3]),   1.2,      tol);
fallas = fallas + ~verificar('  (escalar)',  VM.datosSerieR(5),       5,        tol);
fallas = fallas + ~verificar('datosParalelos', VM.datosParalelos([2 3]), 5,     tol);
fallas = fallas + ~verificar('datosKR',      VM.datosKR(200e9,0.01,2), 1e9,     tol);

fprintf('=== MATERIAL ===\n');
fallas = fallas + ~verificar('datosE',       VM.datosE(1000,2,0.01,0.001), 2e8, tol);
tau = VM.datosT(100, 0.05, 1e-6);
fallas = fallas + ~verificar('datosT',       tau,                     5e6,      tol);
gam = VM.datosV(0.05, 0.1, 2);
fallas = fallas + ~verificar('datosV',       gam,                     0.0025,   tol);
fallas = fallas + ~verificar('datosG',       VM.datosG(tau, gam),     2e9,      tol);

fprintf('=== FRECUENCIAS NATURALES ===\n');
fallas = fallas + ~verificar('omega wn',     double(VM.omega('k',100,'m',4).wn),        5, tol);
fallas = fallas + ~verificar('omega inverso k', double(VM.omega('wn',5,'m',4).k),     100, tol);
fallas = fallas + ~verificar('omegaPS wn',   double(VM.omegaPS('g',9.81,'l',1).wn), sqrt(9.81), tol);
fallas = fallas + ~verificar('omegaPF wn',   double(VM.omegaPF('m',2,'g',9.81,'l',0.5,'Io',1).wn), sqrt(9.81), tol);
fallas = fallas + ~verificar('omegaPF Steiner Io', double(VM.omegaPF('m',2,'g',9.81,'l',0.5,'Icm',0.5).Io), 1, tol);
fallas = fallas + ~verificar('omegaPF leq',  double(VM.omegaPF('m',2,'g',9.81,'l',0.5,'Io',1).leq),      1, tol);
fallas = fallas + ~verificar('datosKP',      VM.datosKP(1e-6,80e9,2), 40000,    tol);

fprintf('=== RIGIDECES ESPECIALES ===\n');
fallas = fallas + ~verificar('datosDE',      VM.datosDE(10,9.81,pi/6,0.1,0.2), 1226.25, 1e-6);
[kd, ym] = VM.datosDmax(1000, 200e9, 1e-6, 2);
fallas = fallas + ~verificar('datosDmax k',  kd,                      75000,    tol);
fallas = fallas + ~verificar('datosDmax Ymax', ym,                    1/75,     tol);

fprintf('=== ECUACION GENERAL ===\n');
[x1,v1,a1,A1,B1] = VM.datosFG(4, 0, 0.1);
fallas = fallas + ~verificar('seno x(0)',    x1,   0,     tol);
fallas = fallas + ~verificar('seno B',       B1,   0.1,   tol);
fallas = fallas + ~verificar('seno A',       A1,   0,     tol);
[x2,~,~,A2,B2] = VM.datosFG(4, 0, 0.1, 0.1);
fallas = fallas + ~verificar('coseno x(0)',  x2,   0.1,   tol);
fallas = fallas + ~verificar('coseno A',     A2,   0.1,   tol);
fallas = fallas + ~verificar('coseno B',     B2,   0,     tol);
fallas = fallas + ~verificar('v_max',        v1,   0.4,   tol);
fallas = fallas + ~verificar('a_max',        a1,   1.6,   tol);

fprintf('=== CASOS AMORTIGUADOS: REGRESION ===\n');
% Cada script de la carpeta Casos Amortiguados/ es un caso. Se corre entero
% (sin tocarlo) y TODOS los escalares que deja en su workspace se comparan
% contra test_VM_referencia.txt, que se capturo corriendo los mismos
% scripts con el VM.m ANTERIOR a la migracion a Motor.m. Si algo cambia
% un numero, la linea del caso lo dice.
carpeta  = fileparts(mfilename('fullpath'));          % Vibraciones Mecanicas/
ref      = leerReferencia(fullfile(carpeta, 'test_VM_referencia.txt'));
nomCasos = unique(ref(:,1), 'stable');                % un caso por script
ws = struct();                                        % ws.(caso): workspace del script
for i = 1:numel(nomCasos)
    ws.(nomCasos{i}) = cargarCaso(fullfile(carpeta, 'Casos Amortiguados', [nomCasos{i} '.m']));
    filas = find(strcmp(ref(:,1), nomCasos{i}));
    distintos = 0;
    for j = filas'
        [ok, texto] = compararValor(ws.(nomCasos{i}), ref{j,2}, ref{j,3}, tol);
        if ~ok
            distintos = distintos + 1;
            fprintf('        %s.%s: %s\n', nomCasos{i}, ref{j,2}, texto);
        end
    end
    fallas = fallas + ~verificar(sprintf('%s (%d)', nomCasos{i}, numel(filas)), distintos, 0, tol);
end
% Un script nuevo en la carpeta no tiene referencia: se avisa, no se inventa.
scripts = dir(fullfile(carpeta, 'Casos Amortiguados', '*.m'));
sinRef  = setdiff(erase({scripts.name}, '.m'), [nomCasos; {'cargarVM'; 'ejecutarTodos'}]);
if ~isempty(sinRef)
    fprintf('  AVISO sin referencia: %s\n', strjoin(sinRef, ', '));
end

fprintf('=== CASOS AMORTIGUADOS: ATAJOS DE VM CONTRA CADA CASO ===\n');
% Los scripts usan VM.ecSubA + Motor.despejar a mano. Aca los atajos
% (VM.amortA, VM.subA, VM.critA, VM.graficarA) reciben los MISMOS datos del
% caso y tienen que dar lo mismo que el script. Asi un error en un atajo
% salta contra un resultado que ya se controlo en la seccion anterior.
ts = sym('t');   % el t de los sistemas: dos simbolos con el mismo nombre son el mismo

I = ws.ImpactoPlastico;
[r, reg] = VM.amortA('m',I.m_eq1, 'k',I.k1, 'c',I.c1, 'x0',I.x0_1, 'v0',I.v0_1);
fallas = fallas + ~verificar('Impacto regimen',  double(strcmp(reg, I.reg1)), 1, tol);
fallas = fallas + ~verificar('Impacto wd',       double(r.wd), I.wd1, tol);
fallas = fallas + ~verificar('Impacto x(t_pico)', double(subs(r.x, ts, I.t_pico1)), I.x_max1, tol);
fallas = fallas + ~verificar('Impacto graficarA', errorCurva(I, 'x1_fun', ...
    'm',I.m_eq1, 'k',I.k1, 'c',I.c1, 'x0',I.x0_1, 'v0',I.v0_1), 0, tol);

V = ws.VagonTope;
r = VM.amortA('m',V.m3, 'k',V.keq3, 'c',V.c3, 'x0',V.x0_3, 'v0',V.v0_3);
fallas = fallas + ~verificar('Vagon wd',         double(r.wd), V.wd3, tol);
fallas = fallas + ~verificar('Vagon x(t_max)',   double(subs(r.x, ts, V.t_max3)), V.x_max3, tol);

O = ws.OscilogramaMotor;
r = VM.subA(O.datos2);                  % despeje hacia atras desde los picos
fallas = fallas + ~verificar('Oscilograma k',    double(r.k), O.k2, tol);
fallas = fallas + ~verificar('Oscilograma c',    double(r.c), O.c2, tol);
fallas = fallas + ~verificar('Oscilograma z',    double(r.z), O.z2, tol);

P = ws.ResortesParalelo;
r = VM.subA(P.datos6);                  % entra por z, no por c
fallas = fallas + ~verificar('Paralelo c',       double(r.c), P.c6, tol);
fallas = fallas + ~verificar('Paralelo x(0.1)',  double(subs(r.x, ts, P.t_eval)), P.x6_01, tol);

D = ws.DosResortes;
r = VM.amortA(D.datos8);
fallas = fallas + ~verificar('DosResortes wd',   double(r.wd), double(D.R8.wd), tol);
fallas = fallas + ~verificar('DosResortes taud', double(r.taud), double(D.R8.taud), tol);

Sp = ws.SerieParalelo;
[r, reg] = VM.amortA(Sp.datos7);
fallas = fallas + ~verificar('Serie regimen',    double(strcmp(reg, Sp.reg7)), 1, tol);
fallas = fallas + ~verificar('Serie s1',         double(r.s1), Sp.resNum7.s1, tol);
fallas = fallas + ~verificar('Serie v(0.05)',    double(subs(diff(r.x, ts), ts, Sp.t_eval)), Sp.v7_005, tol);
fallas = fallas + ~verificar('Serie graficarA',  errorCurva(Sp, 'x7_fun', ...
    'm',Sp.m7, 'k',Sp.keq7, 'c',Sp.ceq7, 'x0',Sp.x0_7, 'v0',Sp.v0_7), 0, tol);

C = ws.CanonRetroceso;
r = VM.critA('m',C.m4, 'c',C.c4);       % unidades inglesas: lb, ft, slug
fallas = fallas + ~verificar('Canon k',          double(r.k), C.k4, tol);
fallas = fallas + ~verificar('Canon wn',         double(r.wn), C.wn4, tol);

Y = ws.ResorteMasaY;
r = VM.amortA('m',Y.m_sobre, 'k',Y.k, 'c',Y.c, 'x0',Y.x0_sobre, 'v0',Y.v0_sobre);
fallas = fallas + ~verificar('MasaY sobre s2',   double(r.s2), Y.resNum1.s2, tol);
[r, reg] = VM.amortA('m',Y.m_crit, 'k',Y.k, 'c',Y.c, 'x0',Y.x0_crit, 'v0',Y.v0_crit);
fallas = fallas + ~verificar('MasaY critico',    double(strcmp(reg, Y.reg2)), 1, tol);
fallas = fallas + ~verificar('MasaY crit C2',    double(r.C2), Y.resNum2.C2, tol);
fallas = fallas + ~verificar('MasaY graficarA crit', errorCurva(Y, 'x2_fun', ...
    'm',Y.m_crit, 'k',Y.k, 'c',Y.c, 'x0',Y.x0_crit, 'v0',Y.v0_crit), 0, tol);
r = VM.amortA('m',Y.m_sub, 'k',Y.k, 'c',Y.c, 'x0',Y.x0_sub, 'v0',Y.v0_sub);
fallas = fallas + ~verificar('MasaY sub wd',     double(r.wd), double(Y.R3.wd), tol);

fprintf('=== CASOS AMORTIGUADOS: CLAVES DEL SOLUCIONARIO (informativo) ===\n');
% Las claves que cada script imprime al lado de su resultado. NO suman a
% fallas: son del solucionario, redondeadas, y no todas son confiables.
% Tolerancia = media unidad del ultimo digito que da la clave ("~" = 1%).
claves = {
    'ImpactoPlastico',  'x_max1',   0.047,    0.0005
    'ImpactoPlastico',  't_pico1',  0.099,    0.0005
    'OscilogramaMotor', 'k2',       50800,    508
    'OscilogramaMotor', 'c2',       353.3,    0.05
    'VagonTope',        't_max3',   0.17018,  0.000005
    'VagonTope',        'x_max3',   0.67523,  0.000005
    'CanonRetroceso',   'k4',       6494,     0.5
    'CanonRetroceso',   't_clave',  0.034,    0.0005
    'ResortesParalelo', 'c6',       1.58,     0.005
    'ResortesParalelo', 'x6_01',    0.1758,   0.00005
    'SerieParalelo',    'v7_005',   -0.20,    0.005
};
noCoinciden = 0;
for i = 1:size(claves, 1)
    valor = ws.(claves{i,1}).(claves{i,2});
    coincide = abs(valor - claves{i,3}) <= claves{i,4};
    noCoinciden = noCoinciden + ~coincide;
    fprintf('  %-5s %-28s = %.6g   (clave %g)\n', string(coincide), ...
        [claves{i,1} '.' claves{i,2}], valor, claves{i,3});
end

fprintf('\n===============================\n');
if fallas == 0
    fprintf('TODAS LAS PRUEBAS PASARON\n');
else
    fprintf('%d PRUEBA(S) FALLARON\n', fallas);
end
fprintf('Claves del solucionario que no coinciden: %d (no cuentan como falla)\n', noCoinciden);

%% ---------------------------------------------------------------------
%  Funciones locales de los casos amortiguados
%  ---------------------------------------------------------------------
function ws = cargarCaso(ruta__)
% Corre un script de Casos Amortiguados/ y devuelve su workspace como
% struct. Se corre ADENTRO de una funcion porque cada script empieza con
% clear: asi borra este workspace y no el del test.
% Los nombres llevan __ para no chocar con variables del script. Lo que hay
% que conservar pasa por setappdata(groot,...), que clear no toca.
setappdata(groot, 'testVM_vis', get(groot, 'DefaultFigureVisible'));
setappdata(groot, 'testVM_figs', findall(groot, 'Type', 'figure'));
set(groot, 'DefaultFigureVisible', 'off');     % los scripts grafican: sin ventanas
try
    evalc('run(ruta__)');                      % evalc: se traga lo que imprime el script
catch ME__
    set(groot, 'DefaultFigureVisible', getappdata(groot, 'testVM_vis'));
    rethrow(ME__);
end
nombres__ = who;                               % who: nombres de las variables que dejo el script
ws = struct();
for i__ = 1:numel(nombres__)
    ws.(nombres__{i__}) = eval(nombres__{i__});
end
close(setdiff(findall(groot, 'Type', 'figure'), getappdata(groot, 'testVM_figs')));
set(groot, 'DefaultFigureVisible', getappdata(groot, 'testVM_vis'));
end

function ref = leerReferencia(archivo)
% Lee test_VM_referencia.txt: cell de n x 3 {caso, variable, valorTexto}.
% Las lineas que empiezan con % son comentario.
lineas = strsplit(strtrim(fileread(archivo)), newline);
lineas = lineas(~startsWith(lineas, '%'));
ref = cell(numel(lineas), 3);
for i = 1:numel(lineas)
    ref(i,:) = strsplit(strtrim(lineas{i}), sprintf('\t'));
end
end

function [ok, texto] = compararValor(ws, variable, valorRef, tol)
% Compara una variable del workspace de un caso contra su referencia.
% variable puede ser 'wd1' o un campo de struct, 'R1.wd'.
partes = strsplit(variable, '.');
try
    v = ws.(partes{1});
    if numel(partes) == 2, v = v.(partes{2}); end
catch
    ok = false; texto = 'ya no existe'; return
end
if startsWith(valorRef, '''')                          % texto, ej. 'sub'
    ok = ischar(v) && strcmp(['''' v ''''], valorRef);
    texto = sprintf('%s en vez de %s', mat2str(v), valorRef);
    return
end
esperado = str2double(valorRef);
try
    v = double(v);
catch
    ok = false; texto = 'ya no es numerico'; return
end
ok = abs(v - esperado) <= tol*max(1, abs(esperado));   % mismo criterio que verificar
texto = sprintf('%.17g en vez de %.17g', v, esperado);
end

function err = errorCurva(ws, nombreFun, varargin)
% Dibuja con VM.graficarA y compara la curva x(t) contra la funcion x(t)
% del caso (su matlabFunction) en los mismos tiempos. Devuelve el error
% maximo en [m].
vis = get(groot, 'DefaultFigureVisible');
set(groot, 'DefaultFigureVisible', 'off');     % sin ventana
[fig, ~] = VM.graficarA(varargin{:});
set(groot, 'DefaultFigureVisible', vis);
linea = findobj(fig, 'DisplayName', 'x(t)');   % la curva, no la envolvente
err = max(abs(linea.YData - ws.(nombreFun)(linea.XData)));
close(fig);
end
