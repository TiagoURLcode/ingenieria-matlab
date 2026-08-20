%% demoB_param.m — B, H y Fi en función de la corriente
clear; clc

[eqs, S] = IE.ecuacionesB();

% Datos fijos: se SUSTITUYEN dentro de las ecuaciones, no se apilan.
% Apilarlas como (N == 500) le pide a solve que las cumpla por sí solas,
% y como no contienen incógnitas el sistema sale vacío -> sol.B = [].
eqs_num = subs(eqs(1:3), [S.N, S.len, S.mu, S.A], [500, 0.25, 200, 1e-4]);

% Solo la parte magnetostática: eqs(4) mete dFi y v, que no dependen de I.
% I no aparece ni en los datos ni en las incógnitas -> queda independiente.
sol = solve(eqs_num, [S.H, S.B, S.Fi]);

assert(~isempty(sol.B), 'solve devolvió vacío: revisa datos e incógnitas')

H_I  = simplify(sol.H)
B_I  = simplify(sol.B);
Fi_I = simplify(sol.Fi);

disp('H(I)  ='), pretty(H_I)
disp('B(I)  ='), pretty(B_I)
disp('Fi(I) ='), pretty(Fi_I)

% Evaluar en puntos concretos sin volver a resolver
Ipts = [1 2 3 5];
Bpts = double(subs(B_I, S.I, Ipts));
fprintf('I = %.1f A  ->  B = %.4f T\n', [Ipts; Bpts])

% Graficar
Bfun  = matlabFunction(B_I, 'Vars', S.I);
Ivals = linspace(0, 5, 200);
plot(Ivals, Bfun(Ivals), 'LineWidth', 1.4)
xlabel('I [A]'); ylabel('B [T]'); grid on
title('Densidad de flujo vs corriente')