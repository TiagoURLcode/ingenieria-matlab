% -- Problema 1 --
f = 3 %Hz
mu_s = .4 %coeficiente de friccion estatica
omega = 2 * pi * f; % Angular frequency
% t = 0 momento en que la velocidad es maxima
%F_max=m*a -> N = mg -> F_max = N*m_s -> ma = m*g*m_s -> a = g*m_s
g = 9.81; % Acceleration due to gravity (m/s^2)
a = g * mu_s; % Calculate acceleration
Amp = abs(-a/omega^2) %Amplitud en SI(metros)
Amp_US = Amp*39.37 %Amplitud en S. US(plg)
fprintf('Amplitud maxima: %.2f mm\n', Amp*1000); %.2f decimal con 3 cifras
fprintf('Amplitud maxima: %.4f in\n', Amp_US); %\n salto de linea

%--Problema 2 --
m_2=75/386.4 %lbs2/in
Amp_2=2 %plg

%- Datos Sistema 1-
k_2a=90 %lb/in resorte sobre masa
k_2b=45 %la/in valor de cada resorte debajo de masa
%- Datos Sistema 2-
k_2c=90 %lb/in valor de cada resorte sobre masa

%- Resolucion sistema 1-
k_e21=k_2a+2*k_2b %R1S||R2||R3)
omega21=sqrt(k_e21/m_2) %omega=sqrt(k/m)
f21=omega21/(2*pi) %frecuencia
T21=1/f21 %periodo
v21= Amp_2*omega21 %velocidad maxima in/s
a21= omega21^2*Amp_2 %aceleracion maxima in/s2
%-- Resolucion _sistema 2--
k_e22 = 1/(2/k_2c); % Resorte sobre masa R1SR2
omega22 = sqrt(k_e22/m_2); % omega=sqrt(k/m) para sistema 2
f22 = omega22/(2*pi); % frecuencia para sistema 2
T22 = 1/f22; % periodo para sistema 2
v22= Amp_2*omega22 %velocidad maxima
a22= omega22^2*Amp_2 %aceleracion maxima

fprintf('Sistema 1: \n Frecuencia: %.2f s^-1 Periodo: %.2f s Velocidad maxima %.2f in/s Aceleracion maxima %.2f in/s^2 \n', f21, T21, v21, a21);
fprintf('Sistema 2: \n Frecuencia: %.2f s^-1 Periodo: %.2f s Velocidad maxima %.2f in/s Aceleracion maxima %.2f in/s^2 \n', f22, T22, v22, a22);

%Problema 3
m3_a= 3 %kg
m3_b= 3 %kg
T3_1 = 0.8 %Periodo en primera condicion  [s]
T3_2 = 0.7 %Periodo en segunda condicion [s]

omega31 = 2*pi/T3_1 %T = 2*pi/omega -> omega = 2*pi/T - omega primera condicion
omega32 = 2*pi/T3_2 %omega segunda condicion

syms m_t
syms m3_c
syms k3 %omega = sqrt(k/m) | 
m_t_1 = m3_a+m3_b+m3_c
m_t_2 = m3_b+m3_c
eq31 = k3 == omega31^2 * m_t_1; %== equivalente, se usa para ecuaciones
eq32 = k3 == omega32^2 * m_t_2;
%k3 = k3
S = solve([eq31, eq32], [k3, m3_c]) %solve despeja una ecuacion y la variable pedida solve(eq, x)
omega33=sqrt(S.k3/S.m3_c) %al querer ver que resulto de un despeje, se llama la nueva variable y se especifica luego del "."
T3_3=2*pi/omega33
fprintf('k3 = %.2f N/m\n', double(S.k3)); %double convierte fracciones numeros reales
fprintf('m3_c = %.2f kg\n', double(S.m3_c));
fprintf('T3_3 = %.2f s\n', double(T3_3)); %T3_3 es un periodo -> segundos

%Problema 4

L4 = 10*12 %in
E4 = 29*10^6 %lb/in2
I4=12.4 %in4
k4=3*E4*I4/L4^3
omega4=sqrt(k4/(520/386.4)) %rad/s
f4=omega4/(2*pi) %f=omega/(2*pi) frecuencia en Hz (2*pi/omega seria el periodo)
fprintf('k4 = %.2f lb/in\n', k4) %sistema ingles -> lb/in
fprintf('f4 = %.2f s^-1\n', f4)
