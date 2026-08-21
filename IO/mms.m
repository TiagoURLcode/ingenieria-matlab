%% mms.m — Ejemplo resuelto del modelo M/M/s
% Usa los tres métodos de la familia M/M/s de IO.m:
%   IO.mms        medidas de desempeño (L, Lq, W, Wq, P0, rho)
%   IO.mmsPn      probabilidad de que haya n clientes, y de que haya más de n
%   IO.mmsEspera  probabilidad de esperar más de un tiempo t
%
% EJEMPLO: una oficina con 3 ventanillas de atención en paralelo y UNA sola
% fila. Llegan 12 personas por hora y cada ventanilla tarda 10 minutos en
% promedio por persona.
clear; clc

%% 1. Datos
% TODO EN HORAS. lambda, mu y los tiempos t tienen que compartir unidad; la
% conversión se hace acá, una sola vez, con el dato del enunciado al lado.
lambda = 12;        % tasa de llegadas [personas/h]   (12 por hora)
mu     = 6;         % tasa de servicio DE UNA ventanilla [personas/h]
                    %   (1/mu = 10 min = 1/6 h  ->  mu = 6 por hora)
s      = 3;         % ventanillas en paralelo [-]

%% 2. Medidas de desempeño
% IO.mms imprime el reporte solo; con 'Verbose', false devuelve el struct
% sin imprimir nada.
sol = IO.mms(lambda, mu, s);

% Los tiempos salen en HORAS porque lambda y mu entraron por hora. Para
% leerlos en minutos se escala en el fprintf: eso es presentación, no cálculo.
fprintf('\n  W  = %.2f min en el sistema\n', sol.W*60);
fprintf('  Wq = %.2f min en la fila\n', sol.Wq*60);

%% 3. Cuántas personas hay en el sistema
% n es un VECTOR: IO.mmsPn devuelve un valor por cada estado pedido.
%   Pn      = probabilidad de que haya EXACTAMENTE n personas
%   PmayorN = probabilidad de que haya MÁS de n personas
% "En el sistema" incluye a las que están siendo atendidas, no solo a las
% que hacen fila.
n = 0:6;
[Pn, PmayorN] = IO.mmsPn(lambda, mu, s, n);

fprintf('\n   n      Pn       P(N > n)\n');
for i = 1:numel(n)
    fprintf('  %2d    %6.4f     %6.4f\n', n(i), Pn(i), PmayorN(i));
end

% Con s = 3 ventanillas, P(N > 3) es la probabilidad de que alguien esté
% haciendo fila: hay más personas que ventanillas.
fprintf('\n  P(alguien haciendo fila) = P(N > %d) = %.4f\n', s, PmayorN(s+1));

%% 4. Probabilidad de esperar más de un tiempo dado
% Las dos responden preguntas distintas:
%   PWq = P(Wq > t) : tiempo en la FILA, antes de que lo empiecen a atender
%   PW  = P(W  > t) : tiempo TOTAL, fila más atención
t = 5/60;           % umbral [h]  (5 min)
[PW, PWq] = IO.mmsEspera(lambda, mu, s, t);

fprintf('\n  P(esperar en fila mas de %.0f min)  = %.4f\n', t*60, PWq);
fprintf('  P(estar adentro mas de %.0f min)   = %.4f\n', t*60, PW);

% t también acepta un vector, para armar la curva de un solo tiro.
tt = (0:5:30)/60;   % 0, 5, 10, ... 30 min, en horas
[~, PWqv] = IO.mmsEspera(lambda, mu, s, tt);

fprintf('\n   t [min]   P(Wq > t)\n');
for i = 1:numel(tt)
    fprintf('   %5.0f      %6.4f\n', tt(i)*60, PWqv(i));
end
