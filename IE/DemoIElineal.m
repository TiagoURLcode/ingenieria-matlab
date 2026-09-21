%% DemoIElineal.m - Ejemplo 1-10 de Chapman resuelto con IE.lineal
% =========================================================================
% ENUNCIADO: maquina lineal de cd con bateria de 120 V, resistencia interna
% de 0.3 ohm, campo de 0.1 T dirigido hacia el interior de la pagina y
% barra de 10 m. Incisos a) hasta e) del libro.
%
% CONVENCION DE SIGNOS, que es lo unico que hay que traducir del libro:
%   El libro dice el sentido de la fuerza con palabras ("30 N dirigida
%   hacia la derecha") y despues aclara si la corriente sube o baja por la
%   barra. Aca el sentido va en el SIGNO de Fcarga:
%       Fcarga > 0  fuerza que se OPONE al movimiento  -> motor
%       Fcarga < 0  fuerza que va A FAVOR              -> generador
%   Por eso el inciso b) del libro, que es el generador, entra como
%   Fcarga = -30 y devuelve i negativa. La magnitud es la misma que la del
%   libro; el signo dice hacia donde.
% =========================================================================

clear; clc

d = struct('VB',120, 'R',0.3, 'B',0.1, 'l',10, 'm',10);

fprintf('=========================================================\n');
fprintf('  EJEMPLO 1-10 DE CHAPMAN con IE.lineal\n');
fprintf('  VB = %g V   R = %g ohm   B = %g T   l = %g m\n', ...
    d.VB, d.R, d.B, d.l);
fprintf('=========================================================\n');

%% a) Corriente maxima de arranque y velocidad de vacio
da = d;  da.Fcarga = 0;
ra = IE.lineal(da);
fprintf('\na) arranque y vacio\n');
fprintf('   i de arranque (v = 0, eind = 0) = %.1f A      [libro: 400 A]\n', ...
    double(ra.iarr));
fprintf('   velocidad de vacio              = %.1f m/s    [libro: 120 m/s]\n', ...
    double(ra.vvacio));

%% b) Fuerza de 30 N a favor del movimiento -> GENERADOR
db = d;  db.Fcarga = -30;
rb = IE.lineal(db);
fprintf('\nb) 30 N hacia la derecha (a favor): Fcarga = -30 N\n');
fprintf('   corriente      = %+.1f A     [libro: 30 A hacia arriba]\n', ...
    double(rb.i));
fprintf('   eind           = %.1f V     [libro: 129 V]\n', double(rb.eind));
fprintf('   velocidad      = %.1f m/s   [libro: 129 m/s]\n', double(rb.v));
fprintf('   la barra entrega %.0f W, la bateria absorbe %.0f W,\n', ...
    abs(double(rb.Pmec)), abs(double(rb.Pbat)));
fprintf('   y la diferencia, %.0f W, se pierde en R.\n', double(rb.PR));
fprintf('   Pbat = %+.0f W: signo negativo = la bateria RECIBE -> GENERADOR\n', ...
    double(rb.Pbat));

%% c) Fuerza de 30 N opuesta al movimiento -> MOTOR
dc = d;  dc.Fcarga = 30;
rc = IE.lineal(dc);
fprintf('\nc) 30 N hacia la izquierda (opuesta): Fcarga = +30 N\n');
fprintf('   corriente      = %+.1f A     [libro: 30 A hacia abajo]\n', ...
    double(rc.i));
fprintf('   eind           = %.1f V     [libro: 111 V]\n', double(rc.eind));
fprintf('   velocidad      = %.1f m/s   [libro: 111 m/s]\n', double(rc.v));
fprintf('   Pbat = %+.0f W: signo positivo = la bateria ENTREGA -> MOTOR\n', ...
    double(rc.Pbat));

%% d) Velocidad contra fuerza aplicada, de 0 a 50 N
Fv = 0:10:50;
vv = zeros(size(Fv));
for k = 1:numel(Fv)
    dk = d;  dk.Fcarga = Fv(k);
    vv(k) = double(IE.lineal(dk).v);
end
fprintf('\nd) velocidad contra fuerza aplicada\n');
fprintf('   F = %2.0f N  ->  v = %6.1f m/s\n', [Fv; vv]);

figure('Name','Ejemplo 1-10 de Chapman','Color','w');
plot(Fv, vv, 'o-', 'LineWidth', 1.4); grid on
xlabel('Fuerza aplicada [N]'); ylabel('Velocidad [m/s]');
title('Velocidad de la barra contra fuerza aplicada');

%% e) El campo decae de 0.1 a 0.08 T, en vacio
de = d;  de.Fcarga = 0;  de.B = 0.08;
re = IE.lineal(de);
fprintf('\ne) el campo cae de %g T a %g T, en vacio\n', d.B, de.B);
fprintf('   la barra pasa de %.0f m/s a %.0f m/s   [libro: 150 m/s]\n', ...
    double(ra.v), double(re.v));
fprintf('   Debilitar el campo ACELERA la maquina, igual que en un motor\n');
fprintf('   de cd real: hace falta mas velocidad para que eind alcance VB.\n');

%% Transitorio del arranque, que el libro no calcula
dt = d;  dt.Fcarga = 30;  dt.tf = 12*d.m*d.R/(d.B*d.l)^2;
[tt, vvt, iit] = IE.trayLineal(dt);
fprintf('\nTransitorio hasta el inciso c), que el libro no resuelve:\n');
fprintf('   v(final) = %.2f m/s, i(final) = %.2f A, contra %.1f y %.1f\n', ...
    vvt(end), iit(end), double(rc.v), double(rc.i));

figure('Name','Arranque de la maquina lineal','Color','w');
subplot(2,1,1); plot(tt, vvt, 'LineWidth', 1.4); grid on
ylabel('v [m/s]'); title('Arranque con 30 N de carga');
subplot(2,1,2); plot(tt, iit, 'LineWidth', 1.4); grid on
xlabel('t [s]'); ylabel('i [A]');
