classdef VM
% =========================================================================
% VM.m - Funciones de apoyo para Vibraciones Mecanicas
%
% USO: se llaman con el prefijo de la clase, desde cualquier script:
%   k  = VM.datosKR(200e9, 0.01, 2);
%   wn = VM.datosOmega(k, 5);
% Escribiendo "VM." + Tab se autocompleta la lista de funciones.
%
% Convencion de unidades usada en todo el archivo (SI):
%   k   [N/m]      constante de rigidez (resorte lineal)
%   kt  [N*m/rad]  constante de rigidez torsional
%   m   [kg]       masa
%   E   [Pa=N/m^2] modulo de elasticidad (Young)
%   G   [Pa]       modulo de rigidez al cortante
%   A   [m^2]      area de la seccion transversal
%   l,L [m]        longitud
%   I,Jo[kg*m^2]   momento de inercia de masa / [m^4] momento polar de area
%   g   [m/s^2]    aceleracion de la gravedad (9.81)
%   omega [rad/s]  frecuencia natural circular
% =========================================================================

    methods(Static)

        function[serieR] = datosSerieR(k)
            % RESORTES EN SERIE -> rigidez equivalente
            % ENTRADA:
            %   k      : vector con las constantes de cada resorte [N/m]
            % SALIDA:
            %   serieR : rigidez equivalente del conjunto en serie [N/m]
            %            keq = 1 / sum(1/ki)   (siempre menor que el resorte mas blando)
            serieR = 1/sum(1./k);
        end

        function[paraleloR] = datosParalelos(k)
            % RESORTES EN PARALELO -> rigidez equivalente
            % ENTRADA:
            %   k         : vector con las constantes de cada resorte [N/m]
            % SALIDA:
            %   paraleloR : rigidez equivalente del conjunto en paralelo [N/m]
            %               keq = sum(ki)   (todos sufren la misma deformacion)
            paraleloR = sum(k);
        end

        function[KRigido] = datosKR(E, A, l)
            % RIGIDEZ AXIAL DE UNA BARRA / CUERPO RIGIDO A TRACCION-COMPRESION
            % ENTRADAS:
            %   E       : modulo de elasticidad del material [Pa]
            %   A       : area de la seccion transversal [m^2]
            %   l       : longitud libre de la barra [m]
            % SALIDA:
            %   KRigido : rigidez axial equivalente k = E*A/l [N/m]
            KRigido = E*A/l;
        end


        function[Elasticidad] = datosE(P,L,A,cambioL)
            % MODULO DE ELASTICIDAD A PARTIR DE UN ENSAYO DE TRACCION
            % ENTRADAS:
            %   P           : carga axial aplicada [N]
            %   L           : longitud inicial de la probeta [m]
            %   A           : area de la seccion transversal [m^2]
            %   cambioL     : alargamiento medido, delta L [m]
            % SALIDA:
            %   Elasticidad : modulo de Young E = (P*L)/(A*deltaL) [Pa]
            %                 equivale a E = esfuerzo/deformacion = sigma/epsilon
            Elasticidad = P*L/(A*cambioL);
        end

        function[omega] = datosOmega(k, m)
            % FRECUENCIA NATURAL - SISTEMA MASA-RESORTE (traslacional)
            % ENTRADAS:
            %   k     : rigidez equivalente del sistema [N/m]
            %   m     : masa que oscila [kg]
            % SALIDA:
            %   omega : frecuencia natural circular wn = sqrt(k/m) [rad/s]
            omega = sqrt(k/m);
        end

        function[omegaPS] = datosOmegaPS(g, l)
            % FRECUENCIA NATURAL - PENDULO SIMPLE (masa puntual, hilo sin masa)
            % ENTRADAS:
            %   g       : aceleracion de la gravedad [m/s^2]
            %   l       : longitud del hilo [m]
            % SALIDA:
            %   omegaPS : wn = sqrt(g/l) [rad/s]. No depende de la masa.
            %             Valido solo para angulos pequenos (sin(t) ~ t).
            omegaPS = sqrt(g/l);
        end

        function[omegaPF] = datosOmegaPF(m, g, l, I)
            % FRECUENCIA NATURAL - PENDULO FISICO / COMPUESTO (cuerpo rigido)
            % ENTRADAS:
            %   m       : masa total del cuerpo [kg]
            %   g       : aceleracion de la gravedad [m/s^2]
            %   l       : distancia del pivote al centro de masa [m]
            %   I       : momento de inercia de masa respecto al pivote, Io [kg*m^2]
            % SALIDA:
            %   omegaPF : wn = sqrt(m*g*l/Io) [rad/s]
            %             Io se obtiene con Steiner: Io = Icm + m*l^2
            omegaPF = sqrt(m*g*l/I);
        end

        function[Torsion] = datosT(M, R, Jo)
            % ESFUERZO CORTANTE POR TORSION en un eje circular
            % ENTRADAS:
            %   M       : momento torsor aplicado [N*m]
            %   R       : radio donde se evalua el esfuerzo (max en la superficie) [m]
            %   Jo      : momento polar de inercia del area, Jo = pi*d^4/32 [m^4]
            % SALIDA:
            %   Torsion : esfuerzo cortante tau = M*R/Jo [Pa]
            Torsion = M*R/Jo;
        end

        function[Deflexion] = datosV(R, teta, L)
            % DEFORMACION ANGULAR POR CORTANTE (distorsion) en un eje a torsion
            % ENTRADAS:
            %   R         : radio del eje [m]
            %   teta      : angulo de giro total del eje [rad]
            %   L         : longitud del eje [m]
            % SALIDA:
            %   Deflexion : deformacion unitaria cortante gamma = R*teta/L [adimensional]
            Deflexion = R*teta/L;
        end

        function[RigidezG] = datosG(Torsion, Deflexion)
            % MODULO DE RIGIDEZ AL CORTANTE (ley de Hooke en cortante)
            % ENTRADAS:
            %   Torsion   : esfuerzo cortante tau [Pa]  (salida de datosT)
            %   Deflexion : deformacion cortante gamma [adim] (salida de datosV)
            % SALIDA:
            %   RigidezG  : modulo G = tau/gamma [Pa]
            RigidezG = Torsion/Deflexion;
        end

        function[KPendulo] = datosKP(Jo, G, l)
            % RIGIDEZ TORSIONAL DE UN EJE (resorte de torsion)
            % ENTRADAS:
            %   Jo       : momento polar de inercia del area de la seccion [m^4]
            %   G        : modulo de rigidez al cortante del material [Pa]
            %   l        : longitud del eje [m]
            % SALIDA:
            %   KPendulo : rigidez torsional kt = Jo*G/l [N*m/rad]
            %             Con ella: wn = sqrt(kt/Io) para el pendulo de torsion.
            KPendulo = Jo*G/l;
        end

        function[DeflexionE] = datosDE(M, g, alfa, Teta, R)
            % RIGIDEZ EQUIVALENTE DE UN CUERPO SOBRE PLANO INCLINADO / APOYO EN 2 PUNTOS
            % ENTRADAS:
            %   M          : masa del cuerpo [kg]
            %   g          : aceleracion de la gravedad [m/s^2]
            %   alfa       : angulo de inclinacion del plano [rad]
            %   Teta       : giro angular del cuerpo [rad]
            %   R          : radio o brazo de palanca [m]
            % SALIDA:
            %   DeflexionE : rigidez equivalente keq = M*g*sin(alfa)/(2*R*Teta)
            %                Componente del peso a lo largo del plano repartida
            %                entre los dos puntos de apoyo, dividida por el
            %                desplazamiento R*Teta.
            DeflexionE = M*g*sin(alfa)/(2*R*Teta);
        end

        function[KDeflexion, Ymax] = datosDmax(P, E, I, L)
            % VIGA EN VOLADIZO (empotrada-libre) CON CARGA PUNTUAL EN EL EXTREMO
            % Sirve para tratar la viga como resorte equivalente: k = P/Ymax.
            % ENTRADAS:
            %   P          : carga puntual aplicada en el extremo libre [N]
            %   E          : modulo de elasticidad del material [Pa]
            %   I          : momento de inercia de area de la seccion [m^4]
            %                (rectangulo: I = b*h^3/12 ; circulo: I = pi*d^4/64)
            %   L          : longitud del voladizo [m]
            % SALIDAS:
            %   KDeflexion : rigidez equivalente de la viga, k = 3*E*I/L^3 [N/m]
            %                Siempre positiva (depende solo de geometria y material).
            %                Con esta k: wn = sqrt(k/m) del sistema viga-masa.
            %   Ymax       : deflexion maxima en el extremo libre,
            %                Ymax = P*L^3/(3*E*I) [m], en magnitud.
            %                Se escribe negativa (Ymax = -P*L^3/(3*E*I)) cuando se
            %                usa el convenio de ejes con "y" positivo hacia arriba,
            %                ya que la viga se flexiona hacia abajo. Si P se toma
            %                negativa (carga hacia abajo), Ymax sale negativa sola.
            KDeflexion = 3*E*I/L^3;
            Ymax = P*L^3/(3*E*I);
        end

        function[x_t, v_max, a_max, A, B] = datosFG(omega, t, X, x0)
            % ECUACION GENERAL DEL MOVIMIENTO ARMONICO SIMPLE
            %
            % ENTRADAS:
            %   omega : frecuencia natural [rad/s]
            %   t     : instante a evaluar [s]
            %   X     : amplitud del movimiento [m]
            %   x0    : posicion inicial, solo para elegir el caso (opcional).
            %           Por defecto 0. Solo importa si vale 0 o no.
            % SALIDAS:
            %   x_t   : posicion en el instante t [m]
            %   v_max : velocidad maxima [m/s]
            %   a_max : aceleracion maxima [m/s^2]
            %   A     : constante del coseno
            %   B     : constante del seno
            %
            % LOS DOS CASOS (x(0) = A, porque cos(0)=1 y sin(0)=0):
            %   x0 == 0 -> arranca en el equilibrio -> A = 0, B = X
            %              x(t) = X*sin(w*t)   la amplitud es B
            %   x0 ~= 0 -> arranca en el extremo    -> A = X, B = 0
            %              x(t) = X*cos(w*t)   la amplitud es A
            %
            % v_max y a_max son iguales en los dos casos: dependen solo de X y w.
            %
             %
            %   x(t) = A*cos(w*t) + B*sin(w*t)          posicion
            %   v(t) = -A*w*sin(w*t) + B*w*cos(w*t)     velocidad  (1a derivada)
            %   a(t) = -A*w^2*cos(w*t) - B*w^2*sin(w*t) aceleracion (2a derivada)
            %   a(t) = -w^2 * x(t)
            %
            %   X     = sqrt(A^2 + B^2)                 amplitud
            %   v_max = X*w                             (ocurre al pasar por x=0)
            %   a_max = X*w^2 = v_max*w                 (ocurre en los extremos, x=X)
            %
            % Forma equivalente:  x(t) = X*sin(w*t + fi)   con  tan(fi) = A/B
            %
            % ---------------------------------------------------------------------
            % DESPEJES POR VARIABLE (un case por bloque)
            % ---------------------------------------------------------------------
            %
            % CASE x_t  -> posicion en el instante t
            %   x_t = A*cos(w*t) + B*sin(w*t)      requiere t como entrada
            %   x_t = X*sin(w*t + fi)
            %   x_t = -a_t/w^2                     si se conoce la aceleracion instantanea
            %
            % CASE v_max -> velocidad maxima
            %   v_max = w*X = w*sqrt(A^2 + B^2)
            %   v_max = a_max/w
            %   v_max = sqrt(a_max*X)
            %
            % CASE a_max -> aceleracion maxima
            %   a_max = w^2*X = w^2*sqrt(A^2 + B^2)
            %   a_max = v_max*w
            %   a_max = v_max^2/X
            %
            % CASE A -> constante del coseno
            %   A = (x_t - B*sin(w*t))/cos(w*t)    requiere t; indefinido si cos(w*t)=0
            %   A = x_0                            posicion inicial (evaluar en t=0)
            %   A = sqrt(X^2 - B^2)                signo segun el cuadrante
            %   A = sqrt((v_max/w)^2 - B^2)
            %   A = X*sin(fi)
            %
            % CASE B -> constante del seno
            %   B = (x_t - A*cos(w*t))/sin(w*t)    requiere t; indefinido si sin(w*t)=0
            %   B = v_0/w                          velocidad inicial sobre omega
            %   B = sqrt(X^2 - A^2)                signo segun el cuadrante
            %   B = sqrt((v_max/w)^2 - A^2)
            %   B = X*cos(fi)
            %
            % CASE omega -> frecuencia natural
            %   w = a_max/v_max                    el mas directo si se tienen ambos
            %   w = v_max/X = v_max/sqrt(A^2 + B^2)
            %   w = sqrt(a_max/X)
            %   w = sqrt(-a_t/x_t)                 a_t y x_t tienen signo opuesto
            %   w = sqrt(k/m)                      desde las propiedades del sistema
            %   w = 2*pi/T = 2*pi*f
            %   NO se puede despejar de x_t = A*cos(w*t)+B*sin(w*t) en forma cerrada:
            %   es una ecuacion trascendental -> resolver con fzero.
            %
            % CASE X -> amplitud
            %   X = sqrt(A^2 + B^2)
            %   X = v_max/w
            %   X = a_max/w^2
            %   X = v_max^2/a_max                  no necesita omega
            %   X = sqrt(x_0^2 + (v_0/w)^2)
            %
            % CASE fi -> angulo de fase
            %   fi = atan2(A, B)                   para la forma X*sin(w*t + fi)
            %   fi = asin(A/X) = acos(B/X)
            %
            % CASE t -> instante
            %   Trascendental en todos los casos -> fzero sobre x(t) - x_objetivo.
            %   Caso particular, tiempo hasta el primer maximo: t = (pi/2 - fi)/w
            %
            % CASE T, f -> periodo y frecuencia
            %   T = 2*pi/w        f = 1/T = w/(2*pi)
            %   w = 2*pi/T        T = 1/f
            %
            % ---------------------------------------------------------------------
            % Los despejes de arriba son referencia para resolver a mano. La funcion
            % solo implementa el camino directo: de (omega, t, X) a las salidas.
            % ---------------------------------------------------------------------

            % ---------------------------------------------------------------------
            % IMPLEMENTACION
            % ---------------------------------------------------------------------

            if nargin < 4, x0 = 0; end   % por defecto: arranca en el equilibrio

            if x0 == 0
                % CASO 1: x(0) = 0 -> arranca en el equilibrio -> seno puro
                A = 0;
                B = X;
            else
                % CASO 2: x(0) ~= 0 -> arranca en el extremo -> coseno puro
                A = X;
                B = 0;
            end

            x_t   = A*cos(omega*t) + B*sin(omega*t);
            v_max = X*omega;
            a_max = X*omega^2;
        end

    end
end
