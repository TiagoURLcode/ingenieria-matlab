%-- ejercicio 1 Sistema lineal masa-resorte --
m1 = 3/386; %Lbs*in/s^2
k1=2; %lbs/in
v1_max= 90; %in/s
omega1=sqrt(k1/m1);


% a) tiempo requerido para x1=3
x1=3; %in
%formula general x(t)=Acoswt+Bsenwt, x(0)=0, x(t)=Bsen(wt)
%como A=0, v1_max=Amp*w*cos(w*t)-> v(0)=Amp*w 
B1 = v1_max/omega1;
t1 = asin(x1/B1)/omega1;
a1 = -x1*omega1^2;
v1 = B1*omega1*cos(omega1*t1);

fprintf('ejercicio 1\n');
fprintf('a) Tiempo para desplazarse x = %.2f in:\n', x1);
fprintf('   t = %.5f s\n\n', t1);
fprintf('b) En x = %.2f in:\n', x1);
fprintf('   Velocidad     v = %.4f in/s\n', v1);
fprintf('   Aceleracion   a = %.4f in/s^2  \n', a1);


%%% ejercicion 2

r2 = 0.625; %in
rho2 = 490/1728; %lb/in3
r2 = 1.25/2; %in
T2e = 3.8; %s
g_in = 386;
m2 = 4/3*pi*r2^3*rho2/g_in;
omega2e = 2*pi/T2e;
I2=2/5*m2*r2^2;
Kt = omega2e^2*I2;

T2g = 6;
omega2g = 2*pi/T2g;
I2g = Kt/omega2g^2;
fprintf('ejercicio 2\n');
fprintf('a)   Inercia        I  = %.4e lb*in*s^2\n', I2g);


%%% ejercicion 3

syms l3 m3 g3
I3_AB = m3*l3^2/3;
I3_CD = m3*l3^2/12+m3*l3^2;
I3 = I3_AB + I3_CD ;
M3 = m3*g3*(l3/2) + m3*g3*l3;
omega3 = sqrt(M3/I3);
f3     = omega3/(2*pi);
fprintf('ejercicio 3\n');
fprintf('   omega = %s rad/s\n', char(simplify(omega3)));
fprintf('   f     = %s Hz\n', char(simplify(f3)));

%%% ejercicio 4: masa-resorte por energias (cilindro rodante en plano inclinado)
W4  = 15;            % lb
r4  = 4;             % in
k4  = 4.5;           % lb/in
A4  = 0.4;           % in  (desplazamiento inicial desde el equilibrio)
b4  = 14;            % grados (no afecta omega: solo corre el equilibrio)


m4    = W4/g_in;                 % lb*s^2/in
m4_ef = 3/2*m4;                  % T = 3/4*m*v^2 -> masa efectiva
omega4 = sqrt(k4/m4_ef);
T4     = 2*pi/omega4;
v4max  = A4*omega4;

fprintf('\nejercicio 4\n');
fprintf('   Masa efectiva   m_ef = %.6f lb*s^2/in\n', m4_ef);
fprintf('   Frec. natural   w    = %.4f rad/s\n', omega4);
fprintf('a) Periodo        tau   = %.4f s\n', T4);
fprintf('b) Vel. maxima    vmax  = %.4f in/s\n', v4max);


%%% ejercicio 5: volante oscilando como pendulo compuesto desde el punto A
g_ft = 32.2;         % ft/s^2
W5  = 85.0;          % lb
d5  = (14/2)/12;     % ft  (del pivote A al centro de masa = radio)
T5  = 1.26;          % s
m5     = W5/g_ft;                    % slug
omega5 = 2*pi/T5;                    % rad/s
% T = 2*pi*sqrt(I_A/(W*d))  ->  I_A = W*d*T^2/(4*pi^2) = W*d/omega^2
I5_A = W5*d5/omega5^2;               % respecto al punto de suspension A
I5_G = I5_A - m5*d5^2;               % ejes paralelos -> respecto al centro G

fprintf('\nejercicio 5\n');
fprintf('   Inercia en G   I_G   = %.4f slug*ft^2\n', I5_G);

% Ejercicio 6 - Torre de acero con tanque de agua
E6 = 200e9; %elasticidad del acero
A6 = .150^2-.08^2; %metros cuadrados
l6 = 12; %metros
m6 = 2000; %kg, masa del tanque de agua
P6 = m6*9.8; %fuerza de masa (peso)
omega6 = VM.datosOmega(VM.datosKR(E6,A6,l6), m6);
syms def6
cambio6 = double(solve(E6 == VM.datosE(P6,l6,A6,def6), def6));
f6 = omega6/(2*pi);
T6 = 1/f6;
a6 = -cambio6*omega6^2;


fprintf('\nejercicio 6\n');
fprintf('delta = %.4e m = %.4f mm\n\n', cambio6, cambio6*1e3);
fprintf('f       = %.2f Hz\n\n', f6);
fprintf('T = %.5f s = %.2f ms\n\n', T6, T6*1e3);
fprintf('a_max = %.3f m/s^2\n', a6);


% Ejercicio 7 - Brazo robotico pick-and-place (frecuencia natural axial)

W7 = 10;            % lb
g7 = 386.4;         % in/s^2,
m7 = W7/g7;         % lb*s^2/in, masa
l71 = 12;           % in, longitud tramo 1
l72 = 10;           % in, longitud tramo 2
l73 = 8;            % in, longitud tramo 3

E7 = 10e6;         % psi, modulo de elasticidad

D71 = 2;            % in, exterior tramo 1
D72 = 1.5;          % in, exterior tramo 2
D73 = 1;            % in, exterior tramo 3

d71 = 1.75;         % in, diametro interior tramo 1
d72 = 1.25;         % in, interior tramo 2
d73 = 0.75;         % in, interior tramo 3

A71 = pi/4*(D71^2 - d71^2);   % in^2
A72 = pi/4*(D72^2 - d72^2);   % in^2
A73 = pi/4*(D73^2 - d73^2);   % in^2

k71 = VM.datosKR(E7, A71, l71);
k72 = VM.datosKR(E7, A72, l72);
k73 = VM.datosKR(E7, A73, l73);

k7= [k71, k72, k73];
keq7 = VM.datosSerieR(k7);

omega7 = VM.datosOmega(keq7, m7);
f7     = omega7/(2*pi);
T7     = 1/f7;

fprintf('\nejercicio 7\n');
fprintf('f       = %.2f Hz\n', f7);

