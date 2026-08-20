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

fprintf('\n===============================\n');
if fallas == 0
    fprintf('TODAS LAS PRUEBAS PASARON\n');
else
    fprintf('%d PRUEBA(S) FALLARON\n', fallas);
end
