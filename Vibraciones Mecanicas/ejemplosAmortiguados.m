%% ejemplosAmortiguados.m - datos de los ejemplos de vibracion amortiguada
%  Solo se cargan los DATOS de cada enunciado como variables, para
%  trabajarlos despues. Ningun ejemplo se resuelve aca.
%
%  UNIDADES: cada bloque va en SI (kg, N, m, s) salvo que se indique lo
%  contrario. Las longitudes que el enunciado da en mm se pasan a m.
clear; clc

%% == Ejemplo en clase - wn, wd, amplitud y x(t) ========================
c1  = 1;      % coeficiente de amortiguamiento            [N*s/m]
M1  = 0.5;    % masa                                      [kg]
K1  = 50;     % rigidez                                   [N/m]
xo1 = 1;      % posicion inicial x(0)                     [m]
vo1 = -5;     % velocidad inicial xpunto(0)               [m/s]

% Sin 't': x(t) queda libre a proposito, para poder graficarla despues con
% VM.graficarA en vez de evaluarla en un solo instante.
% VM.amortA clasifica sola (sub, critico o sobre) y despeja con el sistema
% que corresponde; el segundo argumento de salida dice cual uso.
[E1, caso1] = VM.amortA('m',M1, 'c',c1, 'k',K1, 'x0',xo1, 'v0',vo1);

fprintf('--- Ejemplo en clase ---\n');
fprintf('caso  = %s\n', caso1);
fprintf('wn    = %.4f rad/s\n',  double(E1.wn));
fprintf('ccr   = %.4f N*s/m\n',  double(E1.ccr));
fprintf('z     = %.4f\n',        double(E1.z));
if isfield(E1,'wd'), fprintf('wd    = %.4f rad/s\n', double(E1.wd)); end
if isfield(E1,'X'),  fprintf('X     = %.4f m\n',     double(E1.X));  end

% x NO aparece en E1: con 't' libre, la ecuacion de x(t) queda con dos
% incognitas (x y t) y VM.despejar la saltea a proposito (ver la nota al
% final de VM.ecSubA). Para verla como funcion del tiempo, se grafica:
VM.graficarA('m',M1, 'c',c1, 'k',K1, 'x0',xo1, 'v0',vo1);

%% == Ejemplo - yunque (impacto plastico + vibracion amortiguada) =======
% Un martillo cae sobre un yunque y las dos masas quedan unidas (impacto
% plastico) justo antes de que arranque la vibracion.
Whammer = 1000;     % peso del martillo                        [N]
hcaida  = 2.00;     % altura de caida del martillo             [m]
Kyunque = 5e6;      % rigidez del yunque                       [N/m]
%   el enunciado dice "N-m/s"; para una rigidez la
%   unidad correcta es N/m, se interpreta asi.
cyunque = 10e3;     % coeficiente de amortiguamiento del yunque [N*s/m]
Wyunque = 5000;     % peso del yunque                          [N]
g       = 9.81;     % aceleracion de la gravedad                [m/s^2]

m1=Whammer/g;
m2=Wyunque/g;

%K1=K2
syms v1 v2
V1=solve(m1*g*hcaida==0.5*m1*v1^2,v1);
V1=double(V1);
V1=V1(V1>0);   % dos raices (+-); se descarta la negativa, V1 es una rapidez

%Po = Pf

V2=double(solve(m1*V1 == (m1+m2)*v2,v2))

%% == Ejemplo#3 - canon (retroceso, amortiguamiento critico) ============
% El canon se dispara desde el reposo; el mecanismo de disparo esta
% disenado para volver a la posicion de equilibrio sin oscilar (critico).
xretroceso = 0.40;  % retroceso maximo del canon tras el disparo [m]
mcanon     = 500;   % masa del canon                            [kg]
kcanon     = 10000; % rigidez del sistema de retroceso          [N/m]
xobjetivo  = 0.1;   % posicion pedida en el inciso (c)          [m]

ccr3= sqrt(4*mcanon*kcanon)
omega3=sqrt(kcanon/mcanon)
syms C1 C2 T3 V3
T3calc = double(solve(diff((C2*T3)*exp(1)^(-omega3*T3)== V3,T3)))

%% == Ejemplo#2 - motocicleta (decremento logaritmico) ==================
mmoto  = 200;       % masa de la motocicleta                    [kg]
reduccPorCiclo = 0.25;  % reduccion de amplitud por oscilacion completa
%   [adim, 25%]
x0moto = 250e-3;    % amplitud inicial                          [m] (250 mm)
Tdmoto = 2.00;      % periodo amortiguado                       [s]

%% == Ejemplo#4 - barra + disco + amortiguador (oscilaciones pequenas) ==
% Barra delgada unida a un disco uniforme; el conjunto disco-barra gira
% como un solo cuerpo rigido alrededor del pivote O (centro del disco).
% El amortiguador c actua con un cable tangente a la parte superior del
% disco. Oscilaciones pequenas.
mbarra = 3.00;      % masa de la barra delgada                  [kg]
mdisco = 5.00;      % masa del disco uniforme                   [kg]
cbarra = 9.00;      % coeficiente de amortiguamiento            [N*s/m]
rA     = 100e-3;    % radio del disco hasta la junta A          [m] (100 mm)
%   se asume que el amortiguador actua con el mismo
%   brazo (radio del disco), por ser tangente al borde.
LAB    = 400e-3;    % longitud de la barra, de A a B            [m] (400 mm)
