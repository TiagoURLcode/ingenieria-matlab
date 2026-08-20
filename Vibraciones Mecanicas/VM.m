classdef VM
% =========================================================================
% VM.m - Funciones de apoyo para Vibraciones Mecanicas
%
% USO: se llaman con el prefijo de la clase, desde cualquier script:
%   k  = VM.datosKR(200e9, 0.01, 2);
%   wn = double(VM.omega('k',k, 'm',5).wn);
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

        %% ================================================================
        %  FRECUENCIA NATURAL - nomenclatura comun a los tres modelos
        %    wn   frecuencia natural circular                    [rad/s]
        %    tau  periodo natural, 2*pi/wn                       [s]
        %    f    frecuencia natural, 1/tau                      [Hz]
        %
        %  Los tres comparten wn, tau y f; lo que cambia es DE DONDE sale
        %  wn. Van en sistemas SEPARADOS a proposito: juntarlos en uno solo
        %  ataria relaciones que no existen, porque la wn de un masa-resorte
        %  no vale sqrt(g/l) ni la de un pendulo depende de k.
        %
        %  Los tres son de VIBRACION LIBRE NO AMORTIGUADA. Con
        %  amortiguamiento esta wn sigue siendo la de referencia, pero la
        %  que se mide es wd = sqrt(1-z^2)*wn; ver VM.ecSubA.
        %  Los dos pendulos valen solo para ANGULOS CHICOS, donde
        %  sin(theta) ~ theta. Con amplitud grande el periodo crece y estas
        %  formulas se quedan cortas.
        %% ================================================================

        function [eqs, S] = ecOmega()
            % SISTEMA - masa-resorte traslacional.   m*x'' + k*x = 0
            %   k  rigidez EQUIVALENTE del sistema   [N/m]
            %   m  masa que oscila                   [kg]
            nom = {'k','m','wn','tau','f'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            k = S.k; m = S.m; wn = S.wn; tau = S.tau; f = S.f;

            % sym(pi) y NO pi pelado: ver la nota larga en VM.ecSubA.
            dpi = sym(pi);

            eqs = [ wn  == sqrt(k/m)
                    tau == 2*dpi/wn
                    f   == 1/tau ];

            % k es la rigidez EQUIVALENTE, no la de un resorte suelto. Si hay
            % varios, se combinan antes con VM.datosSerieR o
            % VM.datosParalelos; si es una barra a traccion, con VM.datosKR.
            % Esa combinacion no es parte del sistema: entra como dato ya
            % resuelto.
        end

        function [eqs, S] = ecOmegaPS()
            % SISTEMA - pendulo SIMPLE (masa puntual, hilo sin masa).
            %   g  aceleracion de la gravedad        [m/s^2]
            %   l  longitud del hilo                 [m]
            nom = {'g','l','wn','tau','f'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            g = S.g; l = S.l; wn = S.wn; tau = S.tau; f = S.f;

            dpi = sym(pi);

            eqs = [ wn  == sqrt(g/l)
                    tau == 2*dpi/wn
                    f   == 1/tau ];

            % NO APARECE LA MASA, y no es un olvido: al plantear la ecuacion
            % de momentos, la m del peso y la m de la inercia son la misma y
            % se cancelan. Dos pendulos de igual largo y distinta masa
            % oscilan al mismo ritmo. Por eso el pendulo sirve para medir g:
            % es lo unico ademas de l que queda en la formula.
        end

        function [eqs, S] = ecOmegaPF()
            % SISTEMA - pendulo FISICO o compuesto (cuerpo rigido que pivota
            % sobre un eje). Io*theta'' + m*g*l*theta = 0 para angulos chicos.
            %   m    masa total del cuerpo                   [kg]
            %   g    aceleracion de la gravedad              [m/s^2]
            %   l    distancia del pivote al CENTRO DE MASA  [m]
            %   Icm  inercia respecto al CENTRO DE MASA      [kg*m^2]
            %   Io   inercia respecto al PIVOTE              [kg*m^2]
            %   leq  largo del pendulo simple equivalente    [m]
            nom = {'m','g','l','Icm','Io','leq','wn','tau','f'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            m = S.m; g = S.g; l = S.l; Icm = S.Icm; Io = S.Io;
            leq = S.leq; wn = S.wn; tau = S.tau; f = S.f;

            dpi = sym(pi);

            eqs = [ Io  == Icm + m*l^2        % teorema de Steiner
                    wn  == sqrt(m*g*l/Io)
                    leq == Io/(m*l)
                    wn  == sqrt(g/leq)        % redundante, ver abajo
                    tau == 2*dpi/wn
                    f   == 1/tau ];

            % STEINER (ejes paralelos): Io == Icm + m*l^2.
            %   Las tablas dan Icm, la inercia respecto al centro de masa,
            %   pero el cuerpo NO gira ahi: gira en el pivote. El termino
            %   m*l^2 es lo que hay que sumarle por correr el eje una
            %   distancia l. Confundir Icm con Io es el error tipico, y no
            %   avisa: da una wn mas alta de la real.
            %
            % PENDULO SIMPLE EQUIVALENTE: leq == Io/(m*l).
            %   Es el largo que tendria que tener un pendulo simple para
            %   oscilar igual que este cuerpo. Con el, wn == sqrt(g/leq)
            %   queda identica a la del pendulo simple: por eso esa ecuacion
            %   es REDUNDANTE con las dos primeras y esta a proposito.
            %   Sirve de dos maneras: deja entrar por leq cuando no conoces
            %   la inercia, y hace de control si los datos no cierran.
        end

        function res = omega(varargin)
            % DESPEJE - frecuencia natural, masa-resorte traslacional.
            % Datos en pares nombre-valor o struct; devuelve TODO lo que se
            % pueda despejar. Anda en cualquier direccion.
            %   r = VM.omega('k',100, 'm',4);   double(r.wn)   -> 5 rad/s
            %   r = VM.omega('wn',5, 'm',4);    double(r.k)    -> 100 N/m
            d = VM.datos(varargin);
            [eqs, S] = VM.ecOmega();
            res = VM.despejar(eqs, S, d);
        end

        function res = omegaPS(varargin)
            % DESPEJE - frecuencia natural, pendulo simple.
            %   r = VM.omegaPS('g',9.81, 'l',1);   double(r.tau)
            %   r = VM.omegaPS('l',1, 'tau',2);    double(r.g)   % mide g
            d = VM.datos(varargin);
            [eqs, S] = VM.ecOmegaPS();
            res = VM.despejar(eqs, S, d);
        end

        function res = omegaPF(varargin)
            % DESPEJE - frecuencia natural, pendulo fisico.
            % Le podes dar Icm y que calcule Io por Steiner, o darle Io
            % directo si ya lo tenes.
            %   r = VM.omegaPF('m',2, 'g',9.81, 'l',0.5, 'Icm',0.5);
            %   r = VM.omegaPF('m',2, 'g',9.81, 'l',0.5, 'Io',1);
            d = VM.datos(varargin);
            [eqs, S] = VM.ecOmegaPF();
            res = VM.despejar(eqs, S, d);
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

        %% ================================================================
        %  VIBRACION LIBRE AMORTIGUADA - nomenclatura comun
        %    m     masa                                          [kg]
        %    c     coeficiente de amortiguamiento                [N*s/m]
        %    k     rigidez                                       [N/m]
        %    ccr   amortiguamiento critico, ccr = sqrt(4*k*m)    [N*s/m]
        %    z     relacion de amortiguamiento, zeta = c/ccr     [-]
        %    wn    frecuencia natural NO amortiguada             [rad/s]
        %    wd    frecuencia amortiguada (solo sub)             [rad/s]
        %    taud  periodo amortiguado, 2*pi/wd                  [s]
        %    delta decremento logaritmico                        [-]
        %    x1,x2 dos amplitudes SEGUIDAS medidas               [m]
        %    x0    posicion inicial x(0)                         [m]
        %    v0    velocidad inicial xpunto(0)                   [m/s]
        %    C1,C2 constantes de la solucion                     [m] o [-]
        %    X     amplitud inicial de la envolvente (solo sub)  [m]
        %    s1,s2 raices de la ecuacion caracteristica          [1/s]
        %
        %  Ecuacion de partida:  m*x'' + c*x' + k*x = 0
        %  El tipo lo decide c contra ccr:
        %    c < ccr  -> SUB-amortiguado   (z < 1) -> oscila y decae
        %    c = ccr  -> critico           (z = 1) -> no esta en este archivo
        %    c > ccr  -> SOBRE-amortiguado (z > 1) -> vuelve sin oscilar
        %% ================================================================

        function [eqs, S] = ecSubA()
            % SISTEMA - vibracion libre SUB-amortiguada (z < 1).
            % No resuelve: entrega las ecuaciones y el diccionario.
            % SALIDAS:
            %   eqs : vector simbolico con las relaciones, sin resolver
            %   S   : struct-diccionario. S.wn es el SIMBOLO wn, no un valor.
            %         Hay que devolverlo: cada sym() crea objetos nuevos, asi
            %         que una wn declarada afuera NO es la de adentro de eqs.

            % sym() y NO syms: dentro de un metodo, syms falla si el nombre
            % choca con una funcion del path.
            nom = {'m','c','k','ccr','z','wn','wd','taud','delta', ...
                   'x1','x2','x0','v0','C1','C2','X'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            m = S.m; c = S.c; k = S.k; ccr = S.ccr; z = S.z;
            wn = S.wn; wd = S.wd; taud = S.taud; delta = S.delta;
            x1 = S.x1; x2 = S.x2; x0 = S.x0; v0 = S.v0;
            C1 = S.C1; C2 = S.C2; X = S.X;

            % PI SIMBOLICO, NO EL pi DE MATLAB. Escrito como pi pelado, la
            % expresion (2*pi)^2 se evalua primero en doble precision y
            % entra al simbolico congelada como la fraccion binaria exacta
            % de ese double (2778046668940015/70368744177664), en vez de
            % 4*pi^2. Mezclado con el pi simbolico que aparece por otro
            % lado, la identidad entre las dos formas del decremento deja de
            % ser DEMOSTRABLE, isAlways la da por falsa y despejar aborta con
            % datosContradictorios sobre datos perfectamente buenos.
            % Probado: pasa exactamente eso.
            dpi = sym(pi);

            % == (doble igual) construye una ECUACION, no una comparacion.
            eqs = [ wn    == sqrt(k/m)
                    ccr   == sqrt(4*k*m)
                    ccr   == 2*m*wn              % redundante, ver abajo
                    z     == c/ccr
                    wd    == sqrt(1 - z^2)*wn
                    taud  == 2*dpi/wd
                    delta == z*wn*taud
                    z     == delta/sqrt((2*dpi)^2 + delta^2)
                    delta == log(x1/x2)          % dos picos consecutivos
                    C1    == x0
                    C2    == (v0 + z*wn*x0)/wd
                    X     == sqrt(C1^2 + C2^2) ];

            % ccr == 2*m*wn es REDUNDANTE con las dos primeras, y esta a
            % proposito: permite entrar por wn cuando no te dieron k, y de
            % paso hace de control (si los datos no cierran entre si,
            % despejar aborta en vez de devolver un numero mentiroso).
            %
            % delta == log(x1/x2) es la via experimental: medis dos picos
            % seguidos del oscilograma y de ahi sale todo lo demas hacia
            % atras, hasta c. log() en MATLAB es logaritmo NATURAL.
            %
            % LAS DOS FORMAS DEL DECREMENTO, Y POR QUE ESTAN LAS DOS.
            % Son la misma relacion despejada al reves, y cada una habilita
            % una direccion:
            %   delta == z*wn*taud                    va de z hacia delta
            %   z     == delta/sqrt((2*pi)^2+delta^2) va de delta hacia z
            % Con una sola, el despeje se TRABA en la direccion contraria:
            % probado. Entrando por x1 y x2 quedan z, wd y taud repartidas
            % en tres ecuaciones con dos incognitas cada una, y la
            % sustitucion hacia adelante no puede empezar por ninguna.
            % Con las dos, la que sobra en cada corrida queda de CONTROL: si
            % los datos no cierran, despejar aborta.
            % Cada una es EXPLICITA en la variable que estrena, asi que solve
            % devuelve una sola raiz. La forma implicita
            % delta == 2*pi*z/sqrt(1-z^2) daria las dos, la positiva y la
            % negativa, y el motor se quedaria con la primera que salga.
            %
            % X es la amplitud de la envolvente en t=0. La envolvente vale
            % X*exp(-z*wn*t) y es la curva que toca los picos por arriba;
            % NO es la posicion. La posicion es
            %   x(t) = exp(-z*wn*t)*(C1*cos(wd*t) + C2*sin(wd*t))
            % y no esta como ecuacion del sistema porque depende de t: meter
            % t adentro dejaria a despejar contando t como una incognita mas
            % y se trabaria. Para la curva usa VM.xSubA.
        end

        function [eqs, S] = ecSobreA()
            % SISTEMA - vibracion libre SOBRE-amortiguada (z > 1).
            % No oscila: las dos raices son reales y negativas, asi que el
            % movimiento es suma de dos exponenciales que decaen.
            % SALIDAS: iguales que ecSubA.

            nom = {'m','c','k','ccr','z','wn','s1','s2','x0','v0','C1','C2'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            m = S.m; c = S.c; k = S.k; ccr = S.ccr; z = S.z; wn = S.wn;
            s1 = S.s1; s2 = S.s2; x0 = S.x0; v0 = S.v0;
            C1 = S.C1; C2 = S.C2;

            eqs = [ wn == sqrt(k/m)
                    ccr == sqrt(4*k*m)
                    ccr == 2*m*wn                % redundante, igual que en sub
                    z   == c/ccr
                    s1  == (-z + sqrt(z^2 - 1))*wn
                    s2  == (-z - sqrt(z^2 - 1))*wn
                    C1  == ( x0*wn*(z + sqrt(z^2 - 1)) + v0)/(2*wn*sqrt(z^2 - 1))
                    C2  == (-x0*wn*(z - sqrt(z^2 - 1)) - v0)/(2*wn*sqrt(z^2 - 1)) ];

            % LAS DOS RAICES SON NEGATIVAS y distintas. s1 es la MENOS
            % negativa, asi que su exponencial es la que decae mas despacio:
            % pasado el arranque, x(t) ~ C1*exp(s1*t) y s1 manda solo.
            %
            % Aca NO hay wd, ni taud, ni delta, ni X: todos suponen
            % oscilacion, y este caso no oscila. Si te pidieron el decremento
            % logaritmico de un sistema sobre-amortiguado, el enunciado esta
            % mal o el sistema es sub-amortiguado.
            %
            % sqrt(z^2 - 1) se anula con z = 1: ahi el sistema es CRITICO,
            % las dos raices se juntan en -wn y C1 y C2 se van a infinito
            % porque dividen por ese radical. El critico tiene su propia
            % solucion, x(t) = (C1 + C2*t)*exp(-wn*t), y no esta en este
            % archivo.
            %
            % x(t) = C1*exp(s1*t) + C2*exp(s2*t) no esta como ecuacion por lo
            % mismo que en sub: depende de t. Para la curva usa VM.xSobreA.
        end

        function [eqs, S] = ecTorA()
            % SISTEMA - vibracion libre amortiguada TORSIONAL.
            % Es el mismo problema que el traslacional con otro vestuario:
            %   m -> Jo     c -> ct     k -> kt     x -> theta
            % Ecuacion de partida:  Jo*theta'' + ct*theta' + kt*theta = 0
            %
            % NOMENCLATURA (SI):
            %   Jo   momento de inercia de masa respecto al eje  [kg*m^2]
            %   ct   coef. de amortiguamiento torsional          [N*m*s/rad]
            %   kt   rigidez torsional                           [N*m/rad]
            %   ctc  amortiguamiento critico torsional           [N*m*s/rad]
            %   z    relacion de amortiguamiento, zeta = ct/ctc  [-]
            %   wn   frecuencia natural NO amortiguada           [rad/s]
            %   wd   frecuencia amortiguada                      [rad/s]
            %
            % SALIDAS: iguales que ecSubA.

            nom = {'Jo','ct','kt','ctc','z','wn','wd'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            Jo = S.Jo; ct = S.ct; kt = S.kt; ctc = S.ctc;
            z = S.z; wn = S.wn; wd = S.wd;

            eqs = [ wn  == sqrt(kt/Jo)
                    ctc == 2*sqrt(kt*Jo)
                    ctc == 2*Jo*wn               % redundante, ver abajo
                    z   == ct/ctc
                    wd  == sqrt(1 - z^2)*wn ];

            % LAS TRES FORMAS DE zeta DE LA LAMINA son una sola ecuacion mas
            % la definicion de ctc:
            %   zeta = ct/ctc = ct/(2*Jo*wn) = ct/(2*sqrt(kt*Jo))
            % Las dos ultimas salen de reemplazar ctc por cada una de sus dos
            % expresiones, asi que no hacen falta como ecuaciones aparte: el
            % despeje las recorre igual.
            %
            % ctc == 2*Jo*wn es REDUNDANTE con las dos primeras y esta a
            % proposito, igual que en ecSubA: deja entrar por wn
            % cuando no te dieron kt, y hace de control si los datos no
            % cierran entre si.
            %
            % EL TIPO LO DECIDE ct CONTRA ctc, igual que en el traslacional:
            % ct < ctc sub-amortiguado, ct = ctc critico, ct > ctc sobre.
            % wd SOLO tiene sentido con z < 1; con z > 1 el radical se vuelve
            % imaginario y lo que corresponde son las dos raices reales, como
            % en ecSobreA pero con Jo, ct y kt.

        end

        function res = torA(varargin)
            % DESPEJE - vibracion libre amortiguada TORSIONAL.
            % Misma forma de llamada que VM.subA:
            %   r = VM.torA('Jo',2, 'kt',800, 'ct',8);
            %   double(r.wd)
            % Devuelve un struct con TODO lo que los datos permitan despejar.
            % Funciona en cualquier direccion: dados wn y Jo saca kt, dados
            % z y ctc saca ct.
            d = VM.datos(varargin);
            [eqs, S] = VM.ecTorA();
            res = VM.despejar(eqs, S, d);
        end

        function res = subA(varargin)
            % DESPEJE - vibracion libre SUB-amortiguada.
            % Los argumentos son los datos, en pares nombre-valor o struct:
            %   r = VM.subA('m',1, 'k',100, 'c',2, 'x0',0.1, 'v0',0);
            %   r = VM.subA(d)                       % d = struct(...)
            %   double(r.wd)
            % Devuelve un struct con TODO lo que los datos permitan despejar.
            % No se pide una incognita: elegis del struct. Si un campo no
            % esta, es que los datos no alcanzaban para determinarlo.
            % Funciona en cualquier direccion: dados x1 y x2 saca delta, de
            % ahi z, y con m y k tambien c.
            d = VM.datos(varargin);
            [eqs, S] = VM.ecSubA();
            res = VM.despejar(eqs, S, d);
        end

        function res = sobreA(varargin)
            % DESPEJE - vibracion libre SOBRE-amortiguada.
            % Misma forma de llamada que VM.subA:
            %   r = VM.sobreA('m',1, 'k',100, 'c',30, 'x0',0.1, 'v0',0);
            %   double(r.s1)
            d = VM.datos(varargin);
            [eqs, S] = VM.ecSobreA();
            res = VM.despejar(eqs, S, d);
        end

        function s = datos(args)
            % Traduce los argumentos de entrada a un struct de datos.
            % Acepta {structDeDatos} o {'nombre',valor, 'nombre',valor, ...}.
            n = numel(args);

            if n == 1 && isstruct(args{1})
                s = args{1};
                return
            end
            if n == 0 || mod(n,2) ~= 0
                error('VM:parInvalido', ...
                    ['Se esperaban pares nombre-valor (cantidad par de ' ...
                     'argumentos) o un struct. Llegaron %d.'], n);
            end

            % Impares = nombres, pares = valores. 1:2:end recorre 1,3,5...
            % Se indexa con () y no con {}: el resultado sigue siendo cell.
            nombres = args(1:2:end);
            valores = args(2:2:end);

            if ~all(cellfun(@(c) ischar(c) || isstring(c), nombres))
                error('VM:parInvalido', ...
                    ['Los argumentos impares tienen que ser nombres. ' ...
                     'Ej: VM.subA(''m'',1, ''k'',100, ''c'',2)']);
            end

            s = cell2struct(valores(:), cellstr(string(nombres(:))), 1);
        end

        function res = despejar(eqs, S, d)
            % MOTOR de despeje. Lo usan subA y sobreA.
            % ENTRADAS:
            %   eqs : sistema simbolico (de VM.ecSubA, ...)
            %   S   : diccionario de simbolos del MISMO sistema
            %   d   : struct con SOLO lo que conoces, en cualquier orden
            % SALIDA:
            %   res : struct con TODAS las variables que quedaron
            %         determinadas. Para numero: double(res.wd).
            %
            % NO SE PIDE UNA INCOGNITA: la sustitucion hacia adelante
            % determina todo lo que los datos permitan en la misma pasada,
            % asi que pedir una sola escondia el resto.
            %
            % POR QUE NO ES UN solve() PELADO: solve(eqs,x) exige que TODAS
            % las ecuaciones se satisfagan eligiendo unicamente x. Como el
            % sistema tiene incognitas intermedias (wn, ccr, z...), cualquier
            % ecuacion que no contenga x lo vuelve insatisfacible y solve
            % devuelve VACIO aunque los datos alcancen de sobra.
            % Aca se hace SUSTITUCION HACIA ADELANTE, que es el metodo a
            % mano: se busca una ecuacion con una sola incognita, se despeja,
            % se propaga, y se repite.
            %
            % ES EL MISMO MOTOR QUE MM.despejar E IE.despejar, COPIADO A
            % PROPOSITO: cada carpeta tiene que funcionar sola. Precio: un
            % bug aca hay que arreglarlo en los tres archivos.

            campos = fieldnames(d);

            for k = 1:numel(campos)
                if ~isfield(S, campos{k})
                    error('VM:campoDesconocido', ...
                        ['"%s" no es una variable de este modelo. ' ...
                         'Validas: %s'], campos{k}, strjoin(fieldnames(S)', ', '));
                end
                % S.(campos{k}) = el SIMBOLO ; d.(campos{k}) = el VALOR.
                % subs reemplaza en TODAS las ecuaciones de una vez; el loop
                % es necesario porque subs no recorre structs.
                eqs = subs(eqs, S.(campos{k}), d.(campos{k}));
            end

            % --- sustitucion hacia adelante ------------------------------
            res    = struct();
            cambio = true;
            while cambio
                cambio = false;
                for k = 1:numel(eqs)
                    libres = symvar(eqs(k));

                    % Sin incognitas libres, la ecuacion ya es un veredicto.
                    % subs NO la colapsa a false: la deja como "999 == 100",
                    % asi que hay que preguntarle a isAlways.
                    if isempty(libres)
                        if ~isAlways(eqs(k), 'Unknown', 'false')
                            error('VM:datosContradictorios', ...
                                ['Los datos violan la ecuacion %d del ' ...
                                 'modelo: %s'], k, char(eqs(k)));
                        end
                        continue
                    end
                    if numel(libres) ~= 1, continue; end

                    sol = solve(eqs(k), libres);
                    if isempty(sol), continue; end
                    if numel(sol) > 1
                        % Varias raices: se toma la primera y se avisa. Pasa
                        % con los radicales (z, wn) cuando entras al reves.
                        warning('VM:variasSoluciones', ...
                            '%s tiene %d soluciones; se toma la primera.', ...
                            char(libres), numel(sol));
                    end
                    res.(char(libres)) = sol(1);
                    eqs    = subs(eqs, libres, sol(1));   % propaga a todas
                    cambio = true;
                end
            end
        end

    end
end
