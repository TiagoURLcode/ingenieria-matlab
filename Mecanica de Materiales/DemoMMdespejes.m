%% DemoMMdespejes.m — deformación axial elástica de punta a punta
%  Cuatro cosas: despeje directo, despeje inverso (diseño), barra
%  escalonada con desplazamientos acumulados, y paramétrico + gráfica.
%  Todo en N, m, Pa.
clear; clc

E   = 200e9;      % acero, módulo de elasticidad        [Pa]
sigY = 250e6;     % esfuerzo de fluencia                [Pa]

%% == 1. DIRECTO: cuánto se estira ====================================
% Barra de 2 m, 300 mm^2, tirada con 20 kN.
d = struct('P',20e3, 'L',2, 'E',E, 'A',300e-6);

r = MM.axial(d);          % resuelve TODO lo que se pueda, numérico
fprintf('--- 1. Barra uniforme ---\n');
fprintf('  sig   = %8.2f MPa\n', r.sig/1e6);
fprintf('  eps   = %8.2f microstrain\n', r.eps*1e6);
fprintf('  delta = %8.4f mm\n', r.delta*1e3);
fprintf('  k     = %8.2f MN/m\n', r.k/1e6);

% Control: el modelo es elástico y solo vale abajo de la fluencia.
assert(abs(r.sig) < sigY, 'La barra fluye: delta = P*L/(E*A) ya no vale.')

%% == 2. INVERSO: qué área necesito ====================================
% Mismo problema al revés — el enunciado típico de diseño: la barra no
% puede estirarse más de 0.5 mm. No hay que reordenar nada a mano, se
% pide la otra variable y listo.
Areq = double(MM.datosAxial('P',20e3, 'L',2, 'E',E, 'delta',0.5e-3, 'A'));
fprintf('\n--- 2. Diseño por rigidez ---\n');
fprintf('  A minima para delta <= 0.5 mm : %.2f mm^2\n', Areq*1e6);
fprintf('  diametro equivalente          : %.2f mm\n', sqrt(4*Areq/pi)*1e3);

% Y el otro criterio, el de resistencia, con esfuerzo permisible F.S. = 2:
Ares = double(MM.datosAxial('P',20e3, 'sig',sigY/2, 'A'));
fprintf('  A minima por resistencia      : %.2f mm^2\n', Ares*1e6);
% Gana el criterio más exigente, es decir el que pide MÁS área.
criterios = ["rigidez", "resistencia"];
fprintf('  MANDA: %s (A = %.2f mm^2)\n', ...
        criterios(1 + (Ares > Areq)), max(Areq,Ares)*1e6);

%% == 3. ESCALONADA: barra con tres tramos =============================
% A---1---B---2---C---3---D , empotrada en A. Las fuerzas internas N ya
% vienen del DCL (cortar y sumar): eso NO lo hace el código.
tramos = { struct('N', 40e3, 'L',0.8, 'E',E, 'dia',0.030)   % tracción
           struct('N', 40e3, 'L',0.6, 'E',E, 'dia',0.020)   % más fino
           struct('N',-15e3, 'L',0.5, 'E',E, 'dia',0.020) };% comprimido

re = MM.escalonada(tramos, sigY);

fprintf('\n--- 3. Barra escalonada ---\n');
fprintf('  %-6s %10s %10s %10s %8s\n', 'tramo','sig[MPa]','d[mm]','acum[mm]','frac');
for i = 1:numel(tramos)
    fprintf('  %-6d %10.2f %10.4f %10.4f %8.2f\n', ...
        i, re.sig(i)/1e6, re.dt(i)*1e3, re.acum(i)*1e3, re.frac(i));
end
fprintf('  delta TOTAL del extremo D = %.4f mm\n', re.delta*1e3);
% acum es la respuesta a "cuánto se movió el punto C": re.acum(2).
fprintf('  el punto C se movio       = %.4f mm\n', re.acum(2)*1e3);

%% == 4. PARAMÉTRICO: delta en función de la carga =====================
% Igual que en el demo de IE: se sustituyen los datos FIJOS dentro de las
% ecuaciones y se deja libre la variable de interés. Apilar (E == 200e9)
% como una ecuación más le pediría a solve que la cumpla por sí sola.
[eqs, S] = MM.ecuacionesAxial();
eqs_num  = subs(eqs, [S.L, S.E, S.A], [2, E, 300e-6]);

% Solo las ecuaciones de deformación: k mete P/delta y no aporta acá.
sol = solve(eqs_num(1:4), [S.sig, S.eps, S.delta]);
assert(~isempty(sol.delta), 'solve devolvió vacío: revisá datos e incógnitas')

delta_P = simplify(sol.delta);
sig_P   = simplify(sol.sig);
disp('delta(P) ='), pretty(delta_P)

% Evaluar en puntos concretos sin volver a resolver
Ppts = (10:10:50)*1e3;
dpts = double(subs(delta_P, S.P, Ppts));
fprintf('\n--- 4. Parametrico ---\n');
fprintf('  P = %5.1f kN  ->  delta = %.4f mm\n', [Ppts/1e3; dpts*1e3]);

% Carga a la que la barra empieza a fluir: el modelo deja de valer ahí.
Pfluye = double(solve(sig_P == sigY, S.P));
fprintf('  fluye en P = %.1f kN\n', Pfluye/1e3);

% Graficar, marcando dónde se termina la validez del modelo lineal
dfun  = matlabFunction(delta_P, 'Vars', S.P);
Pvals = linspace(0, 1.4*Pfluye, 200);
plot(Pvals/1e3, dfun(Pvals)*1e3, 'LineWidth', 1.4); hold on
xline(Pfluye/1e3, '--r', 'fluencia', 'LineWidth', 1.2);
area([Pfluye Pvals(end)]/1e3, [1 1]*max(dfun(Pvals))*1e3, ...
     'FaceColor','r', 'FaceAlpha',0.08, 'EdgeColor','none');
xlabel('P [kN]'); ylabel('\delta [mm]'); grid on
title('Deformación axial vs carga (zona roja: el modelo elástico ya no vale)')
legend('\delta = PL/EA', 'Location','northwest'); hold off
