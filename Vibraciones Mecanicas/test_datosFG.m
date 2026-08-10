% Pruebas de VM.datosFG con w = 4 rad/s, X = 0.1 m

w = 4;
X = 0.1;

disp('=== CASO 1: x0 = 0 (equilibrio) -> seno, amplitud es B ===');
[x, v, a, A, B] = VM.datosFG(w, 0, X);
fprintf('t=0     x=%.4f  A=%.4f  B=%.4f   (x debe dar 0)\n', x, A, B);
[x, ~, ~] = VM.datosFG(w, pi/(2*w), X);
fprintf('t=T/4   x=%.4f                    (x debe dar X=%.2f)\n', x, X);
fprintf('v_max=%.4f   a_max=%.4f\n', v, a);

disp(' ');
disp('=== CASO 2: x0 ~= 0 (extremo) -> coseno, amplitud es A ===');
[x, v, a, A, B] = VM.datosFG(w, 0, X, X);
fprintf('t=0     x=%.4f  A=%.4f  B=%.4f   (x debe dar X=%.2f)\n', x, A, B, X);
[x, ~, ~] = VM.datosFG(w, pi/(2*w), X, X);
fprintf('t=T/4   x=%.4f                    (x debe dar 0)\n', x);
fprintf('v_max=%.4f   a_max=%.4f\n', v, a);

disp(' ');
disp('=== v_max y a_max son iguales en ambos casos ===');
[~, v1, a1] = VM.datosFG(w, 0, X);
[~, v2, a2] = VM.datosFG(w, 0, X, X);
fprintf('caso1: v=%.4f a=%.4f | caso2: v=%.4f a=%.4f\n', v1, a1, v2, a2);
