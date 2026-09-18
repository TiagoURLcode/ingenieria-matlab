classdef MF
    % MF — Caja de herramientas de Mecánica de Fluidos.
    %      Todos los métodos son estáticos: se llaman MF.nombre(...).
    %      Cubre Formulario_Final_Mott.pdf (Mott, 7.a ed.), capítulos 1 a 9
    %      y 16. El número entre paréntesis es el del formulario.
    %
    % ÍNDICE POR CAPÍTULO
    %   1. Naturaleza de los fluidos
    %      (1.5) (1.6) (1.7)   MF.fluido      rho, gam, sg, W, p
    %      (1.8)               MF.tension     tensión superficial y capilaridad
    %   2. Viscosidad
    %      (2.2) (2.3)         MF.viscosidad  tau, mu, nu
    %      (2.7)               MF.esfera      caída de esfera y ley de Stokes
    %      (2.8)               MF.laminar     el viscosímetro capilar ES
    %                                         Hagen-Poiseuille despejada en mu
    %   3. Presión
    %      (3.2) (3.3) (3.6)   MF.columna     pabs, pman, dp = gam*dh, barómetro
    %      (3.5)               MF.manometro   recorrido de un tubo en U
    %      (3.5)               MF.diferencial pA - pB = (gamm - gamf)*h
    %   4. Fuerzas debidas a fluidos estáticos
    %      (4.2) a (4.5)       MF.plana       FR y centro de presión
    %      (4.4)               MF.inercia     Ic y A de las tres secciones
    %      (4.6)               MF.curva       FH, FV, resultante
    %      (4.7)               MF.presa
    %   5. Flotabilidad y estabilidad
    %      (5.2)               MF.flotacion   cuerpo que flota libre
    %      (5.3)               MF.sumergido   peso aparente, sg por pesaje
    %      (5.5) (5.6)         MF.estabilidad MB, MG, par de restauración
    %   6. Flujo y Bernoulli
    %      (6.2) (6.3)         MF.caudal      Q, mdot, Wdot
    %      (6.4)               MF.continuidad
    %      (6.5)               MF.bernoulli   MF.energia con hA = hR = hL = 0
    %      (6.6)               MF.torricelli
    %      (6.7)               MF.pitot
    %      (6.8)               MF.venturi
    %   7. Ecuación general de la energía
    %      (7.2)               MF.energia
    %      (7.3)               MF.bomba
    %      (7.4)               MF.motorh
    %      (7.5)               MF.eficiencia
    %   8. Reynolds y perfiles
    %      (8.2) (8.3)         MF.reynolds    + MF.regimen, que clasifica
    %      (8.4) (8.5)         MF.laminar     + MF.perfilLaminar
    %      (8.6)               MF.hidraulico  + MF.dhidraulico
    %   9. Pérdidas por fricción
    %      (9.2)               MF.darcy       + MF.friccion, que da f
    %  16. Fuerzas sobre objetos
    %      (16.5) a (16.7)     MF.impulso
    %   Datos de tabla
    %                          MF.ctes        agua, aire, mercurio, g, patm
    %                          MF.conv        factores a SI (Tabla K.1)
    %
    %   Cada sistema tiene dos caras: MF.ecXxx declara las ecuaciones sin
    %   resolver, y el atajo MF.xxx('dato',valor, ...) las resuelve y
    %   devuelve un struct numérico con todo lo que los datos permiten.
    %
    % CONVENCIONES DE TODA LA CLASE
    %   - SISTEMA COHERENTE. No hay conversión de unidades adentro. Se entra
    %     en SI base: m, kg, s, N, Pa, m^3/s. El formulario trabaja en kPa,
    %     L/min, ft y psi a cada rato: eso se convierte EN LA ASIGNACIÓN,
    %     con MF.conv y el valor del enunciado al lado.
    %   - ÁNGULOS en RADIANES (theta). deg2rad para entrar, rad2deg para leer.
    %   - PRESIONES MANOMÉTRICAS salvo aviso. pabs solo aparece en MF.columna.
    %   - gam es el PESO específico [N/m^3] y rho la DENSIDAD [kg/m^3]. Las
    %     dos aparecen en casi todos los sistemas atadas por gam = rho*g: es
    %     una ecuación redundante puesta a propósito, para poder entrar por
    %     cualquiera de las dos y para que el sistema aborte si no cierran.
    %   - CUIDADO CON v Y V. MATLAB distingue mayúsculas: v es velocidad
    %     [m/s] y V es volumen [m^3]. Es el error de tipeo más caro de este
    %     archivo, y no da error: da un número.
    %   - h ES TRES COSAS distintas según el sistema: profundidad (cap. 3 y
    %     4), altura de columna (3.5) y cabeza de energía en metros (cap. 7
    %     y 9). Por eso los sistemas están separados: juntarlos ataría una h
    %     con otra que no es la misma.
    %
    % MOTOR DE DESPEJE
    %   El que resuelve es Motor.despejar (Motor.m, en la raíz del repo): es
    %   el mismo motor que usan VM, FV, IE, sp y MM, no una copia. Para que
    %   MATLAB lo encuentre parado en esta carpeta, correr UNA vez setup.m
    %   (raíz).
    %
    % AGREGADO QUE NO ESTÁ EN EL FORMULARIO, y por qué
    %   1. MF.ctes y MF.conv. El formulario los da como texto suelto; acá
    %      son datos para no volver a tipear 9.81 ni 6894.76.
    %   2. MF.inercia. Las tres Ic están sueltas en (4.4); juntarlas en un
    %      selector evita elegir la fórmula equivocada, y de paso devuelve
    %      el área A de la misma sección, que es el otro dato que pide FR.
    %   3. MF.manometro. El recorrido "bajar suma, subir resta" es un
    %      procedimiento, no una ecuación: no hay sistema que despejar.
    %   4. MF.friccion. Colebrook-White es IMPLÍCITA y Motor.despejar
    %      sustituye hacia adelante: no la puede resolver. Va por fzero.
    %   5. MF.perfilLaminar. v(r) es una función de r, no una ecuación
    %      algebraica más del sistema.
    %   6. MF.dhidraulico. Los atajos de rectángulo y anular de (8.6).
    %   7. MF.regimen. La tabla de (8.3) es una clasificación.
    %   8. gam == rho*g y A == pi*D^2/4 metidas como ecuaciones redundantes
    %      dentro de varios sistemas, para poder entrar por el diámetro o
    %      por la densidad sin hacer la cuenta aparte.
    %   9. Wap == W - Fb en MF.sumergido. El formulario solo da la forma
    %      cerrada Wap = Vo*(gamo - gamf); con las dos, el sistema controla.
    %
    % LO QUE NO ESTÁ, y por qué
    %   - El formulario dice "Caps. 1-8, 16 y 17" pero su cuerpo llega hasta
    %     9.2 (Darcy-Weisbach) y del 17 no trae nada. Acá está lo que el
    %     cuerpo trae. Si el 17 entra al final, se agrega con otra ecXXX.
    %   - Newtoniano, pseudoplástico, dilatante y Bingham (2.4), variación
    %     de mu con T (2.6), paradoja hidrostática (3.4), medidores de
    %     presión (3.7) y estabilidad de cuerpos sumergidos (5.4) son texto:
    %     no hay nada que calcular.
    %   - Los criterios MG > 0 y NR < 2000 son comparaciones, no despejes.
    %     MF.estabilidad y MF.reynolds devuelven el número; la decisión es
    %     tuya, o la hace MF.regimen.
    %   - Pérdidas por accesorios (K*v^2/2g, cap. 10 de Mott) no están en el
    %     formulario.
    %
    % SIN VERIFICAR TODAVÍA: ningún sistema pasó por Motor.probar ni corrió
    % bajo matlab -batch.

    methods(Static)

        %% ===================================================================
        %  PROPIEDADES DEL FLUIDO — (1.5) (1.6) (1.7)
        %    m      masa                                        [kg]
        %    V      volumen                                     [m^3]
        %    W      peso                                        [N]
        %    rho    densidad, masa por unidad de volumen        [kg/m^3]
        %    gam    peso específico, peso por unidad de volumen [N/m^3]
        %    g      aceleración de la gravedad, 9.81            [m/s^2]
        %    sg     gravedad específica, referida al agua       [-]
        %    rhow   densidad del agua de referencia, 1000       [kg/m^3]
        %    gamw   peso específico del agua, 9810              [N/m^3]
        %    p      presión                                     [Pa]
        %    F      fuerza normal a la superficie               [N]
        %    A      área sobre la que actúa                     [m^2]
        %
        %  sg es ADIMENSIONAL y se mide contra el agua a 4 °C. Un aceite con
        %  sg = 0.88 tiene rho = 880 kg/m^3. Si el enunciado da sg, entrá con
        %  sg y rhow: el sistema saca rho y gam solo.
        %
        %  EJEMPLO
        %    c = MF.ctes();
        %    r = MF.fluido('sg',0.88, 'rhow',c.agua4.rho, 'g',c.g);   r.gam
        %% ===================================================================
        function [eqs, S] = ecFluido()
            S = Motor.simbolos({'m','V','W','rho','gam','g','sg','rhow', ...
                                'gamw','p','F','A'});
            m = S.m; V = S.V; W = S.W; rho = S.rho; gam = S.gam; g = S.g;
            sg = S.sg; rhow = S.rhow; gamw = S.gamw; p = S.p; F = S.F; A = S.A;

            eqs = [ rho  == m/V                 % (1.5)
                    gam  == W/V                 % (1.5)
                    gam  == rho*g               % (1.5)
                    W    == m*g                 % (1.6)
                    sg   == rho/rhow            % (1.5)
                    sg   == gam/gamw            % (1.5)
                    gamw == rhow*g              % (1.5) ata las dos referencias
                    p    == F/A ];              % (1.7)
        end

        function r = fluido(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecFluido, varargin, ...
                {'m','V','rho','gam','sg','rhow','gamw','A'});
        end

        %% ===================================================================
        %  TENSIÓN SUPERFICIAL Y CAPILARIDAD — (1.8)
        %    sig    tensión superficial                         [N/m]
        %    F      fuerza a lo largo de la línea de contacto   [N]
        %    L      longitud de esa línea                       [m]
        %    h      altura que sube el líquido en el tubo       [m]
        %    theta  ángulo de contacto, desde la pared          [rad]
        %    gam    peso específico del líquido                 [N/m^3]
        %    D      diámetro interior del tubo                  [m]
        %
        %  h sale POSITIVA si el líquido moja (theta < pi/2, agua-vidrio) y
        %  NEGATIVA si no moja (theta > pi/2, mercurio-vidrio): el mercurio
        %  baja en el capilar. El signo lo pone cos(theta), no hay que
        %  forzarlo.
        %
        %  EJEMPLO
        %    r = MF.tension('sig',0.0728, 'theta',0, 'gam',9790, 'D',0.001);
        %% ===================================================================
        function [eqs, S] = ecTension()
            S = Motor.simbolos({'sig','F','L','h','theta','gam','D'});
            sig = S.sig; F = S.F; L = S.L; h = S.h;
            theta = S.theta; gam = S.gam; D = S.D;

            eqs = [ sig == F/L                          % (1.8)
                    h   == 4*sig*cos(theta)/(gam*D) ];  % (1.8)
        end

        function r = tension(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecTension, varargin, {'L','gam','D'});
        end

        %% ===================================================================
        %  VISCOSIDAD — (2.2) (2.3)
        %    tau    esfuerzo cortante en el fluido              [Pa]
        %    mu     viscosidad dinámica                         [Pa*s]
        %    dvdy   gradiente de velocidad                      [1/s]
        %    v      velocidad de la placa móvil                 [m/s]
        %    y      separación entre placas                     [m]
        %    F      fuerza para arrastrar la placa              [N]
        %    A      área de la placa en contacto                [m^2]
        %    nu     viscosidad cinemática                       [m^2/s]
        %    rho    densidad del fluido                         [kg/m^3]
        %
        %  dvdy == v/y vale solo con PERFIL LINEAL, que es lo que hay entre
        %  dos placas paralelas con separación chica. En un tubo el perfil es
        %  parabólico y esa igualdad no corre: ahí va MF.laminar.
        %
        %  1 poise = 0.1 Pa*s, 1 cP = 1e-3 Pa*s, 1 stoke = 1e-4 m^2/s. Las
        %  conversiones están en MF.conv.
        %
        %  EJEMPLO
        %    r = MF.viscosidad('mu',0.1, 'v',0.5, 'y',0.002, 'A',0.05);  r.F
        %% ===================================================================
        function [eqs, S] = ecViscosidad()
            S = Motor.simbolos({'tau','mu','dvdy','v','y','F','A','nu','rho'});
            tau = S.tau; mu = S.mu; dvdy = S.dvdy; v = S.v; y = S.y;
            F = S.F; A = S.A; nu = S.nu; rho = S.rho;

            eqs = [ tau  == mu*dvdy             % (2.2)
                    dvdy == v/y                 % (2.2) perfil lineal
                    F    == tau*A               % (2.2)
                    F    == mu*A*v/y            % (2.2) (redundante)
                    nu   == mu/rho ];           % (2.3)
        end

        function r = viscosidad(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecViscosidad, varargin, ...
                {'mu','v','y','A','nu','rho'});
        end

        %% ===================================================================
        %  CAÍDA DE ESFERA Y LEY DE STOKES — (2.7)
        %    mu     viscosidad dinámica del fluido              [Pa*s]
        %    gams   peso específico de la esfera                [N/m^3]
        %    gamf   peso específico del fluido                  [N/m^3]
        %    D      diámetro de la esfera                       [m]
        %    R      radio de la esfera                          [m]
        %    v      velocidad TERMINAL de caída                 [m/s]
        %    Fd     fuerza de arrastre                          [N]
        %
        %  Las dos fórmulas son la misma. A velocidad terminal el peso menos
        %  el empuje iguala al arrastre:
        %      (pi*D^3/6)*(gams - gamf) = 6*pi*(D/2)*mu*v
        %  y al despejar mu sale (gams - gamf)*D^2/(18*v). Están las dos
        %  porque así se entra por donde venga el dato, y si no cierran, el
        %  sistema aborta.
        %
        %  Vale solo en RÉGIMEN LAMINAR alrededor de la esfera (NR < 1). Con
        %  una esfera grande o un fluido poco viscoso el resultado es basura
        %  y el sistema no lo puede saber.
        %
        %  EJEMPLO
        %    r = MF.esfera('gams',77000, 'gamf',9790, 'D',0.0016, 'v',0.05);
        %% ===================================================================
        function [eqs, S] = ecEsfera()
            S = Motor.simbolos({'mu','gams','gamf','D','R','v','Fd'});
            mu = S.mu; gams = S.gams; gamf = S.gamf;
            D = S.D; R = S.R; v = S.v; Fd = S.Fd;

            eqs = [ mu == (gams - gamf)*D^2/(18*v)      % (2.7)
                    Fd == 6*pi*R*mu*v                   % (2.7) Stokes
                    D  == 2*R
                    Fd == pi*D^3/6*(gams - gamf) ];     % equilibrio terminal
        end

        function r = esfera(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecEsfera, varargin, {'mu','D','R','v'});
        end

        %% ===================================================================
        %  PRESIÓN Y COLUMNA DE LÍQUIDO — (3.2) (3.3) (3.6)
        %    pabs   presión absoluta                            [Pa]
        %    patm   presión atmosférica, 101325 al nivel del mar[Pa]
        %    pman   presión manométrica (la que mide el manómetro) [Pa]
        %    dp     diferencia de presión entre dos puntos      [Pa]
        %    gam    peso específico del líquido                 [N/m^3]
        %    rho    densidad del líquido                        [kg/m^3]
        %    g      gravedad                                    [m/s^2]
        %    dh     diferencia de PROFUNDIDAD entre esos puntos [m]
        %
        %  dp == gam*dh vale solo dentro de un MISMO fluido CONTINUO y en
        %  reposo. Cruzar una interfase aceite-agua corta la cuenta: ahí
        %  empieza otro tramo, y eso lo arma MF.manometro.
        %
        %  EL BARÓMETRO ES ESTE MISMO SISTEMA: patm = gamHg*h es dp = gam*dh
        %  con pman = 0 arriba de la columna. No hace falta otra función:
        %    MF.columna('gam',133000, 'dh',0.760).dp  ->  101 kPa
        %
        %  EJEMPLO
        %    r = MF.columna('gam',9790, 'dh',3);            r.dp
        %    r = MF.columna('pman',200e3, 'patm',101325);   r.pabs
        %% ===================================================================
        function [eqs, S] = ecColumna()
            S = Motor.simbolos({'pabs','patm','pman','dp','gam','rho','g','dh'});
            pabs = S.pabs; patm = S.patm; pman = S.pman; dp = S.dp;
            gam = S.gam; rho = S.rho; g = S.g; dh = S.dh;

            eqs = [ pabs == patm + pman         % (3.2)
                    dp   == gam*dh              % (3.3)
                    gam  == rho*g               % (1.5)
                    dp   == rho*g*dh ];         % (3.3) (redundante)
        end

        function r = columna(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecColumna, varargin, {'gam','rho','dh'});
        end

        %% ===================================================================
        %  MANÓMETRO DIFERENCIAL — (3.5)
        %    pA     presión en el punto A                       [Pa]
        %    pB     presión en el punto B                       [Pa]
        %    gamm   peso específico del líquido MANOMÉTRICO     [N/m^3]
        %    gamf   peso específico del fluido de la tubería    [N/m^3]
        %    h      desnivel leído en el manómetro              [m]
        %
        %  Vale con los dos puntos AL MISMO NIVEL y una sola U cargada con un
        %  solo líquido manométrico. Si el arreglo tiene más columnas o los
        %  puntos están a distinta altura, no sirve la forma cerrada: hay que
        %  recorrer el tubo con MF.manometro.
        %
        %  EJEMPLO
        %    r = MF.diferencial('gamm',133000, 'gamf',9790, 'h',0.150);
        %% ===================================================================
        function [eqs, S] = ecDiferencial()
            S = Motor.simbolos({'pA','pB','gamm','gamf','h'});
            pA = S.pA; pB = S.pB; gamm = S.gamm; gamf = S.gamf; h = S.h;

            eqs = pA - pB == (gamm - gamf)*h;   % (3.5)
        end

        function r = diferencial(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecDiferencial, varargin, {'gamm','gamf'});
        end

        %% ===================================================================
        %  manometro — RECORRIDO DE UN TUBO EN U. (3.5)
        %  No es un sistema de ecuaciones: es la suma de columnas, tramo por
        %  tramo, que es lo que se hace a mano. Por eso es una función común
        %  y no un ecXxx.
        %
        %  Entradas:
        %    p0     : presión conocida en el punto de arranque    [Pa]
        %    tramos : matriz de N filas por 2 columnas, [gam dh].
        %             gam : peso específico del fluido del tramo  [N/m^3]
        %             dh  : desnivel recorrido en ESE tramo       [m]
        %                   POSITIVO si el recorrido BAJA,
        %                   NEGATIVO si SUBE.
        %             El orden de las filas ES el orden del recorrido, desde
        %             el punto de p0 hasta el punto que se busca.
        %
        %  Salida:
        %    p  : presión en el punto final                       [Pa]
        %
        %  La regla "bajar suma, subir resta" del formulario está metida en
        %  el SIGNO de dh, no en la fórmula. Así una sola suma cubre
        %  cualquier cantidad de columnas y de fluidos.
        %
        %  EJEMPLO — de A, bajar 0.3 m de agua, subir 0.15 m de mercurio:
        %    p = MF.manometro(pA, [9790 0.30; 133000 -0.15]);
        %% ===================================================================
        function p = manometro(p0, tramos)
            if size(tramos,2) ~= 2
                error('MF:tramosInvalidos', ...
                    'tramos tiene que ser una matriz de N filas por 2: [gam dh].');
            end
            p = p0 + sum(tramos(:,1) .* tramos(:,2));
        end

        %% ===================================================================
        %  SUPERFICIE PLANA SUMERGIDA — (4.2) a (4.5)
        %    FR     fuerza resultante sobre la superficie       [N]
        %    gam    peso específico del fluido                  [N/m^3]
        %    hbar   profundidad VERTICAL hasta el centroide     [m]
        %    A      área de la superficie                       [m^2]
        %    h1     profundidad del borde superior              [m]
        %    h2     profundidad del borde inferior              [m]
        %    theta  ángulo de la superficie con la horizontal   [rad]
        %    Lbar   distancia INCLINADA hasta el centroide      [m]
        %    Lp     distancia INCLINADA hasta el centro de presión [m]
        %    Ic     momento de inercia centroidal del área      [m^4]
        %    p      presión uniforme (gas en recipiente)        [Pa]
        %
        %  hbar == (h1 + h2)/2 vale cuando el centroide queda a media
        %  profundidad: rectángulo, círculo, cualquier figura simétrica
        %  respecto de su eje horizontal medio. Con un triángulo NO vale:
        %  ahí hbar se calcula aparte y h1, h2 se dejan sin pasar.
        %
        %  SUPERFICIE VERTICAL: theta = pi/2, sin(theta) = 1 y Lbar = hbar.
        %  SUPERFICIE HORIZONTAL (gas, 4.2): la presión es uniforme, FR = p*A,
        %  y el centro de presión es el centroide.
        %
        %  El centro de presión SIEMPRE queda más abajo que el centroide,
        %  porque Ic/(Lbar*A) es positivo. Si te da más arriba, el error está
        %  en Lbar.
        %
        %  Ic sale de MF.inercia, que devuelve también el A de esa figura.
        %
        %  EJEMPLO
        %    [Ic, A] = MF.inercia('rectangulo', 'b',2, 'H',1.5);
        %    r = MF.plana('gam',9790, 'h1',1, 'h2',2.5, 'A',A, ...
        %                 'Ic',Ic, 'theta',pi/2);        r.FR, r.Lp
        %% ===================================================================
        function [eqs, S] = ecPlana()
            S = Motor.simbolos({'FR','gam','hbar','A','h1','h2','theta', ...
                                'Lbar','Lp','Ic','p'});
            FR = S.FR; gam = S.gam; hbar = S.hbar; A = S.A;
            h1 = S.h1; h2 = S.h2; theta = S.theta;
            Lbar = S.Lbar; Lp = S.Lp; Ic = S.Ic; p = S.p;

            eqs = [ FR   == gam*hbar*A          % (4.3)
                    hbar == (h1 + h2)/2         % (4.3) centroide a media prof.
                    p    == gam*hbar            % presión en el centroide
                    FR   == p*A                 % (4.2) (redundante)
                    Lbar == hbar/sin(theta)     % (4.4)
                    Lp   == Lbar + Ic/(Lbar*A) ];  % (4.4)
        end

        function r = plana(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecPlana, varargin, ...
                {'gam','hbar','A','Lbar','Lp','Ic'});
        end

        %% ===================================================================
        %  inercia — Ic Y ÁREA DE LAS TRES SECCIONES DE (4.4).
        %  Es para MF.plana lo que MM.seccion es para MM.axial.
        %
        %  El primer argumento es la FORMA, y va explícito: rectángulo y
        %  triángulo se describen con los mismos dos datos (b, H) y dan Ic
        %  distinto, así que no hay forma de adivinarla.
        %
        %    MF.inercia('rectangulo', 'b',2, 'H',1.5)   Ic = b*H^3/12
        %    MF.inercia('circulo',    'D',0.8)          Ic = pi*D^4/64
        %    MF.inercia('triangulo',  'b',2, 'H',1.5)   Ic = b*H^3/36
        %
        %  H es la dimensión EN EL PLANO DE LA SUPERFICIE, medida en el
        %  sentido en que crece la profundidad, y b la transversal. En una
        %  compuerta inclinada, H es el largo sobre el plano inclinado, no la
        %  altura vertical.
        %
        %  Salidas:
        %    Ic : momento de inercia centroidal   [m^4]
        %    A  : área de esa misma figura        [m^2]
        %% ===================================================================
        function [Ic, A] = inercia(forma, varargin)
            s = Motor.datos(varargin, 'MF');
            switch lower(string(forma))
                case "rectangulo"
                    MF.exigir(s, {'b','H'}, 'rectangulo');
                    Ic = s.b*s.H^3/12;      A = s.b*s.H;
                case "circulo"
                    MF.exigir(s, {'D'}, 'circulo');
                    Ic = pi*s.D^4/64;       A = pi*s.D^2/4;
                case "triangulo"
                    MF.exigir(s, {'b','H'}, 'triangulo');
                    Ic = s.b*s.H^3/36;      A = s.b*s.H/2;
                otherwise
                    error('MF:formaInvalida', ...
                        'Forma "%s": se acepta rectangulo, circulo o triangulo.', ...
                        string(forma));
            end
        end

        %% ===================================================================
        %  SUPERFICIE CURVA — (4.6)
        %    FH     componente horizontal de la fuerza          [N]
        %    FV     componente vertical de la fuerza            [N]
        %    FR     resultante                                  [N]
        %    theta  ángulo de la resultante con la horizontal   [rad]
        %    gam    peso específico del fluido                  [N/m^3]
        %    hc     profundidad al centroide de la PROYECCIÓN   [m]
        %    Av     área de la proyección VERTICAL de la curva  [m^2]
        %    V      volumen de fluido, real o imaginario, encima[m^3]
        %
        %  LAS DOS COMPONENTES SE CALCULAN SOBRE COSAS DISTINTAS:
        %    FH usa la SOMBRA de la superficie sobre un plano vertical, y de
        %       ahí sale igual que en MF.plana.
        %    FV usa el VOLUMEN de fluido que la superficie tiene encima. Si
        %       el fluido está abajo, ese volumen es IMAGINARIO (el que
        %       habría) y FV apunta hacia arriba.
        %
        %  OJO CON EL NOMBRE: acá FV es la componente vertical de la fuerza.
        %  En el repo, FV es además la clase de Física 5. Adentro de esta
        %  función las variables locales se llaman Fh y Fv justamente para no
        %  taparla.
        %
        %  EJEMPLO
        %    r = MF.curva('gam',9790, 'hc',1.5, 'Av',2, 'V',0.9);  r.FR
        %% ===================================================================
        function [eqs, S] = ecCurva()
            S = Motor.simbolos({'FH','FV','FR','theta','gam','hc','Av','V'});
            Fh = S.FH; Fv = S.FV; FR = S.FR; theta = S.theta;
            gam = S.gam; hc = S.hc; Av = S.Av; V = S.V;

            eqs = [ Fh    == gam*hc*Av          % (4.6)
                    Fv    == gam*V              % (4.6)
                    FR    == sqrt(Fh^2 + Fv^2)  % (4.6)
                    theta == atan(Fv/Fh) ];     % (4.6)
        end

        function r = curva(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecCurva, varargin, ...
                {'FH','FV','FR','gam','hc','Av','V'});
        end

        %% ===================================================================
        %  PRESA VERTICAL — (4.7)
        %    FR     fuerza resultante del agua sobre la presa   [N]
        %    gam    peso específico del agua                    [N/m^3]
        %    h      profundidad total del agua                  [m]
        %    b      ancho de la presa                           [m]
        %    M      momento de vuelco respecto de la base       [N*m]
        %
        %  Es MF.plana con la superficie desde h1 = 0 hasta h2 = h: hbar =
        %  h/2 y A = h*b dan FR = gam*h^2*b/2. Está aparte porque el brazo
        %  del momento se mide desde LA BASE (h/3) y no desde la superficie
        %  libre, y mezclarlo con Lp es el error clásico.
        %
        %  EJEMPLO
        %    r = MF.presa('gam',9790, 'h',6, 'b',10);   r.FR, r.M
        %% ===================================================================
        function [eqs, S] = ecPresa()
            S = Motor.simbolos({'FR','gam','h','b','M'});
            FR = S.FR; gam = S.gam; h = S.h; b = S.b; M = S.M;

            eqs = [ FR == gam*h^2*b/2           % (4.7)
                    M  == FR*h/3 ];             % (4.7)
        end

        function r = presa(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecPresa, varargin, {'gam','h','b'});
        end

        %% ===================================================================
        %  FLOTACIÓN — (5.2)
        %    Fb     empuje (fuerza de flotación)                [N]
        %    gamf   peso específico del FLUIDO                  [N/m^3]
        %    Vd     volumen DESPLAZADO (la parte sumergida)     [m^3]
        %    gamo   peso específico del OBJETO                  [N/m^3]
        %    Vo     volumen TOTAL del objeto                    [m^3]
        %    W      peso del objeto                             [N]
        %
        %  Este sistema es el del cuerpo que FLOTA LIBRE: el empuje iguala al
        %  peso, y de ahí Vd/Vo = gamo/gamf, la fracción sumergida. Un cuerpo
        %  sostenido por un cable o apoyado en el fondo NO cumple esto: ese
        %  va en MF.sumergido.
        %
        %  EJEMPLO
        %    r = MF.flotacion('gamo',7000, 'gamf',9790, 'Vo',0.02);   r.Vd
        %% ===================================================================
        function [eqs, S] = ecFlotacion()
            S = Motor.simbolos({'Fb','gamf','Vd','gamo','Vo','W'});
            Fb = S.Fb; gamf = S.gamf; Vd = S.Vd;
            gamo = S.gamo; Vo = S.Vo; W = S.W;

            eqs = [ Fb == gamf*Vd               % (5.2)
                    W  == gamo*Vo               % (5.2)
                    Fb == W                     % (5.2) equilibrio en flotación
                    Vd/Vo == gamo/gamf ];       % (5.2) (redundante)
        end

        function r = flotacion(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecFlotacion, varargin, ...
                {'Fb','gamf','Vd','gamo','Vo','W'});
        end

        %% ===================================================================
        %  CUERPO SUMERGIDO — (5.3)
        %    Fb      empuje                                      [N]
        %    gamf    peso específico del fluido                  [N/m^3]
        %    gamo    peso específico del objeto                  [N/m^3]
        %    Vo      volumen total del objeto, todo sumergido    [m^3]
        %    W       peso real del objeto                        [N]
        %    Wap     peso aparente (lo que marca la balanza)     [N]
        %    Waire   peso pesado en aire                         [N]
        %    Wagua   peso pesado sumergido en AGUA               [N]
        %    sg      gravedad específica del objeto              [-]
        %
        %  Acá el cuerpo está TODO sumergido: Vd = Vo. Wap es lo que sostiene
        %  el cable, y es negativo si el cuerpo tiende a subir.
        %
        %  La fórmula de sg por pesaje supone que el líquido es AGUA. Con
        %  otro líquido no vale tal cual: hay que usar Wap = Vo*(gamo - gamf).
        %
        %  EJEMPLO
        %    r = MF.sumergido('Waire',15.6, 'Wagua',12.9);   r.sg
        %% ===================================================================
        function [eqs, S] = ecSumergido()
            S = Motor.simbolos({'Fb','gamf','gamo','Vo','W','Wap', ...
                                'Waire','Wagua','sg'});
            Fb = S.Fb; gamf = S.gamf; gamo = S.gamo; Vo = S.Vo;
            W = S.W; Wap = S.Wap; Waire = S.Waire; Wagua = S.Wagua; sg = S.sg;

            eqs = [ Fb    == gamf*Vo                    % (5.2) con Vd = Vo
                    W     == gamo*Vo                    % (5.3)
                    Wap   == W - Fb                     % (5.3) equilibrio
                    Wap   == Vo*(gamo - gamf)           % (5.3) (redundante)
                    W     == Waire                      % pesar en aire da W
                    Wagua == Wap                        % pesar sumergido da Wap
                    sg    == Waire/(Waire - Wagua) ];   % (5.3) solo en agua
        end

        function r = sumergido(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecSumergido, varargin, ...
                {'Fb','gamf','gamo','Vo','W','Waire','sg'});
        end

        %% ===================================================================
        %  ESTABILIDAD DE UN CUERPO FLOTANTE — (5.5) (5.6)
        %    MB     altura del metacentro sobre el centro de flotación [m]
        %    Iw     segundo momento de área de la LÍNEA DE FLOTACIÓN   [m^4]
        %    Vd     volumen desplazado                                 [m^3]
        %    GB     distancia del centro de gravedad al de flotación   [m]
        %    MG     altura metacéntrica                                [m]
        %    W      peso del cuerpo                                    [N]
        %    theta  ángulo de escora                                   [rad]
        %    Mrest  par de restauración                                [N*m]
        %
        %  MG > 0 estable, MG = 0 neutro, MG < 0 inestable. La comparación es
        %  tuya: el sistema devuelve el número.
        %
        %  GB es POSITIVA con G encima de B, que es el caso normal de un
        %  barco. Con G debajo de B el cuerpo es estable siempre y el
        %  metacentro no hace falta.
        %
        %  Iw ES EL DE LA HUELLA EN EL AGUA, no el de la sección sumergida.
        %  Para un casco rectangular de largo L y manga b, el eje de volteo
        %  es el longitudinal y Iw = L*b^3/12. Con MF.inercia sale igual pero
        %  con los nombres cruzados, porque ahí la base es L y la altura b:
        %      Iw = MF.inercia('rectangulo', 'b',L, 'H',b);
        %  Es fácil equivocarse: el b^3 va con la MANGA, la dimensión que se
        %  inclina.
        %
        %  EJEMPLO
        %    Iw = MF.inercia('rectangulo', 'b',3, 'H',1.2);
        %    r = MF.estabilidad('Iw',Iw, 'Vd',0.9, 'GB',0.2);   r.MG
        %% ===================================================================
        function [eqs, S] = ecEstabilidad()
            S = Motor.simbolos({'MB','Iw','Vd','GB','MG','W','theta','Mrest'});
            MB = S.MB; Iw = S.Iw; Vd = S.Vd; GB = S.GB;
            MG = S.MG; W = S.W; theta = S.theta; Mrest = S.Mrest;

            eqs = [ MB    == Iw/Vd                      % (5.5)
                    MG    == MB - GB                    % (5.5)
                    Mrest == W*MG*sin(theta) ];         % (5.6)
        end

        function r = estabilidad(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecEstabilidad, varargin, {'Iw','Vd','W'});
        end

        %% ===================================================================
        %  CAUDAL — (6.2) (6.3)
        %    Q      caudal volumétrico                          [m^3/s]
        %    A      área de la sección de paso                  [m^2]
        %    D      diámetro interior, si la sección es circular[m]
        %    v      velocidad promedio                          [m/s]
        %    mdot   caudal másico                               [kg/s]
        %    Wdot   caudal en peso                              [N/s]
        %    rho    densidad                                    [kg/m^3]
        %    gam    peso específico                             [N/m^3]
        %    g      gravedad                                    [m/s^2]
        %
        %  v es la velocidad PROMEDIO de la sección, no la del centro. En
        %  flujo laminar la del centro es el doble (ver MF.laminar).
        %
        %  A == pi*D^2/4 supone sección CIRCULAR LLENA. Con otra sección,
        %  pasá A y no pases D.
        %
        %  1 gal/min = 3.785 L/min y 1 m^3/s = 35.31 ft^3/s: MF.conv.
        %
        %  EJEMPLO
        %    r = MF.caudal('D',0.05, 'v',2.5, 'rho',998);   r.Q, r.mdot
        %% ===================================================================
        function [eqs, S] = ecCaudal()
            S = Motor.simbolos({'Q','A','D','v','mdot','Wdot','rho','gam','g'});
            Q = S.Q; A = S.A; D = S.D; v = S.v;
            mdot = S.mdot; Wdot = S.Wdot; rho = S.rho; gam = S.gam; g = S.g;

            eqs = [ Q    == A*v                 % (6.2)
                    A    == pi*D^2/4            % sección circular
                    mdot == rho*Q               % (6.3)
                    Wdot == gam*Q               % (6.3)
                    gam  == rho*g ];            % (1.5)
        end

        function r = caudal(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecCaudal, varargin, ...
                {'Q','A','D','v','mdot','Wdot','rho','gam'});
        end

        %% ===================================================================
        %  CONTINUIDAD — (6.4)
        %    Q      caudal, el MISMO en las dos secciones       [m^3/s]
        %    A1 A2  áreas de las secciones 1 y 2                [m^2]
        %    D1 D2  diámetros de las secciones 1 y 2            [m]
        %    v1 v2  velocidades promedio                        [m/s]
        %
        %  Vale para flujo INCOMPRESIBLE y permanente. Lo que se conserva es
        %  el caudal volumétrico; en un gas comprimible se conserva el másico
        %  y esta forma no corre.
        %
        %  v2 == v1*(D1/D2)^2 es la misma ecuación con las áreas circulares
        %  ya reemplazadas. Está de más a propósito: deja entrar por los
        %  diámetros sin calcular áreas.
        %
        %  EJEMPLO
        %    r = MF.continuidad('D1',0.05, 'v1',2, 'D2',0.025);   r.v2
        %% ===================================================================
        function [eqs, S] = ecContinuidad()
            S = Motor.simbolos({'Q','A1','A2','D1','D2','v1','v2'});
            Q = S.Q; A1 = S.A1; A2 = S.A2;
            D1 = S.D1; D2 = S.D2; v1 = S.v1; v2 = S.v2;

            eqs = [ A1*v1 == A2*v2              % (6.4)
                    A1    == pi*D1^2/4
                    A2    == pi*D2^2/4
                    v2    == v1*(D1/D2)^2       % (6.4) (redundante)
                    Q     == A1*v1
                    Q     == A2*v2 ];
        end

        function r = continuidad(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecContinuidad, varargin, ...
                {'Q','A1','A2','D1','D2','v1','v2'});
        end

        %% ===================================================================
        %  ECUACIÓN GENERAL DE LA ENERGÍA — (7.2), y Bernoulli (6.5)
        %    p1 p2  presiones en los puntos 1 y 2               [Pa]
        %    z1 z2  elevaciones respecto de una referencia      [m]
        %    v1 v2  velocidades promedio                        [m/s]
        %    gam    peso específico del fluido                  [N/m^3]
        %    g      gravedad                                    [m/s^2]
        %    hA     cabeza AÑADIDA por una bomba                [m]
        %    hR     cabeza REMOVIDA por un motor o turbina      [m]
        %    hL     cabeza PERDIDA por fricción y accesorios    [m]
        %
        %  TODOS LOS TÉRMINOS SON METROS DE COLUMNA DEL MISMO FLUIDO. p/gam
        %  es la cabeza de presión, z la de elevación y v^2/(2g) la de
        %  velocidad. Sumar un p en Pa acá es el error más caro del capítulo.
        %
        %  ES UNA SOLA ECUACIÓN: hay que dar todo menos una incógnita.
        %
        %  EL SENTIDO 1 -> 2 IMPORTA. hA y hL se restan en el sentido del
        %  flujo; si numerás al revés, cambian de signo.
        %
        %  MF.bernoulli es este mismo sistema con hA = hR = hL = 0, o sea
        %  flujo ideal sin máquinas. No hay dos sistemas: hay uno y un atajo.
        %
        %  EJEMPLO
        %    r = MF.bernoulli('p1',0, 'z1',5, 'v1',0, 'z2',0, 'v2',3, ...
        %                     'gam',9790, 'g',9.81);      r.p2
        %% ===================================================================
        function [eqs, S] = ecEnergia()
            S = Motor.simbolos({'p1','z1','v1','p2','z2','v2','gam','g', ...
                                'hA','hR','hL'});
            p1 = S.p1; z1 = S.z1; v1 = S.v1;
            p2 = S.p2; z2 = S.z2; v2 = S.v2;
            gam = S.gam; g = S.g; hA = S.hA; hR = S.hR; hL = S.hL;

            eqs = p1/gam + z1 + v1^2/(2*g) + hA - hR - hL == ...
                  p2/gam + z2 + v2^2/(2*g);     % (7.2)
        end

        function r = energia(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecEnergia, varargin, {'gam','g'});
        end

        function r = bernoulli(varargin)
            % ATAJO de (6.5): la general sin máquinas ni pérdidas.
            r = MF.resolver(@MF.ecEnergia, ...
                [varargin, {'hA',0, 'hR',0, 'hL',0}], {'gam','g'});
        end

        %% ===================================================================
        %  TORRICELLI — (6.6)
        %    v      velocidad de salida por el orificio         [m/s]
        %    g      gravedad                                    [m/s^2]
        %    h      altura de líquido SOBRE el orificio         [m]
        %
        %  Es Bernoulli entre la superficie libre y el chorro: las dos a
        %  presión atmosférica, y la superficie bajando tan despacio que v1 =
        %  0. Vale mientras el tanque sea mucho más ancho que el orificio.
        %
        %  EJEMPLO
        %    r = MF.torricelli('h',2.5, 'g',9.81);   r.v
        %% ===================================================================
        function [eqs, S] = ecTorricelli()
            S = Motor.simbolos({'v','g','h'});
            v = S.v; g = S.g; h = S.h;

            eqs = v == sqrt(2*g*h);             % (6.6)
        end

        function r = torricelli(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecTorricelli, varargin, {'v','g','h'});
        end

        %% ===================================================================
        %  TUBO DE PITOT — (6.7)
        %    v      velocidad local del flujo                   [m/s]
        %    ps     presión de ESTANCAMIENTO (la del pico)      [Pa]
        %    p      presión estática de la corriente            [Pa]
        %    rho    densidad del fluido                         [kg/m^3]
        %    gam    peso específico del fluido                  [N/m^3]
        %    g      gravedad                                    [m/s^2]
        %    dh     desnivel leído en el manómetro del Pitot    [m]
        %
        %  Las dos formas son la misma: ps - p = gam*dh convierte la
        %  diferencia de presión en altura de columna. Cuál usar depende de
        %  si el instrumento da presión o da altura.
        %
        %  El Pitot mide la velocidad LOCAL donde está el pico, no la
        %  promedio de la sección.
        %
        %  EJEMPLO
        %    r = MF.pitot('dh',0.125, 'g',9.81);   r.v
        %% ===================================================================
        function [eqs, S] = ecPitot()
            S = Motor.simbolos({'v','ps','p','rho','gam','g','dh'});
            v = S.v; ps = S.ps; p = S.p;
            rho = S.rho; gam = S.gam; g = S.g; dh = S.dh;

            eqs = [ v      == sqrt(2*(ps - p)/rho)      % (6.7)
                    v      == sqrt(2*g*dh)              % (6.7)
                    ps - p == gam*dh                    % une las dos formas
                    gam    == rho*g ];                  % (1.5)
        end

        function r = pitot(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecPitot, varargin, {'v','rho','gam','g','dh'});
        end

        %% ===================================================================
        %  VENTURI HORIZONTAL — (6.8)
        %    Q      caudal                                      [m^3/s]
        %    A1     área de la sección de entrada               [m^2]
        %    A2     área de la GARGANTA                         [m^2]
        %    D1 D2  diámetros de esas secciones                 [m]
        %    p1 p2  presiones en esas secciones                 [Pa]
        %    gam    peso específico del fluido                  [N/m^3]
        %    g      gravedad                                    [m/s^2]
        %
        %  Es Bernoulli más continuidad, con z1 = z2 porque el medidor está
        %  HORIZONTAL. Si el Venturi está inclinado hay que volver a
        %  MF.energia con los z.
        %
        %  El término 1 - (A2/A1)^2 es el que corrige por la velocidad de
        %  entrada. Si la garganta es mucho más chica, tiende a 1 y queda
        %  Torricelli.
        %
        %  EJEMPLO
        %    r = MF.venturi('D1',0.1, 'D2',0.05, 'p1',180e3, 'p2',150e3, ...
        %                   'gam',9790, 'g',9.81);      r.Q
        %% ===================================================================
        function [eqs, S] = ecVenturi()
            S = Motor.simbolos({'Q','A1','A2','D1','D2','p1','p2','gam','g'});
            Q = S.Q; A1 = S.A1; A2 = S.A2; D1 = S.D1; D2 = S.D2;
            p1 = S.p1; p2 = S.p2; gam = S.gam; g = S.g;

            eqs = [ Q  == A2*sqrt( 2*g*(p1 - p2)/gam / (1 - (A2/A1)^2) )  % (6.8)
                    A1 == pi*D1^2/4
                    A2 == pi*D2^2/4 ];
        end

        function r = venturi(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecVenturi, varargin, ...
                {'Q','A1','A2','D1','D2','gam','g'});
        end

        %% ===================================================================
        %  POTENCIA DE UNA BOMBA — (7.3)
        %    PA     potencia ENTREGADA AL FLUIDO                [W]
        %    hA     cabeza añadida por la bomba                 [m]
        %    gam    peso específico del fluido                  [N/m^3]
        %    Q      caudal                                      [m^3/s]
        %    eM     eficiencia mecánica de la bomba             [-]
        %    PI     potencia que entra a la bomba, del motor    [W]
        %
        %  eM = PA/PI es menor que 1: entra más de lo que sale.
        %
        %  ESTÁ SEPARADA DE MF.motorh A PROPÓSITO. El formulario llama eM a
        %  la eficiencia de la bomba en (7.3) y a la del motor hidráulico en
        %  (7.4), y son dos números distintos. En un solo sistema quedarían
        %  atadas y daría cualquier cosa.
        %
        %  1 HP = 745.7 W: MF.conv.
        %
        %  EJEMPLO
        %    r = MF.bomba('hA',25, 'gam',9790, 'Q',0.012, 'eM',0.75);  r.PI
        %% ===================================================================
        function [eqs, S] = ecBomba()
            S = Motor.simbolos({'PA','hA','gam','Q','eM','PI'});
            PA = S.PA; hA = S.hA; gam = S.gam; Q = S.Q; eM = S.eM; PI = S.PI;

            eqs = [ PA == hA*gam*Q              % (7.3)
                    eM == PA/PI ];              % (7.3)
        end

        function r = bomba(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecBomba, varargin, {'gam','Q','eM'});
        end

        %% ===================================================================
        %  POTENCIA DE UN MOTOR HIDRÁULICO O TURBINA — (7.4)
        %    PR     potencia que el FLUIDO ENTREGA a la máquina [W]
        %    hR     cabeza removida por la máquina              [m]
        %    gam    peso específico del fluido                  [N/m^3]
        %    Q      caudal                                      [m^3/s]
        %    eM     eficiencia mecánica de la máquina           [-]
        %    PO     potencia de SALIDA en el eje                [W]
        %
        %  Acá la eficiencia va al revés que en la bomba: PO = eM*PR, o sea
        %  sale menos de lo que el fluido entrega. Mismo nombre eM, sentido
        %  opuesto; por eso son dos sistemas.
        %
        %  EJEMPLO
        %    r = MF.motorh('hR',18, 'gam',9790, 'Q',0.03, 'eM',0.82);  r.PO
        %% ===================================================================
        function [eqs, S] = ecMotorH()
            S = Motor.simbolos({'PR','hR','gam','Q','eM','PO'});
            PR = S.PR; hR = S.hR; gam = S.gam; Q = S.Q; eM = S.eM; PO = S.PO;

            eqs = [ PR == hR*gam*Q              % (7.4)
                    PO == eM*PR ];              % (7.4)
        end

        function r = motorh(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecMotorH, varargin, {'gam','Q','eM'});
        end

        %% ===================================================================
        %  EFICIENCIA DEL SISTEMA — (7.5)
        %    etot    eficiencia total de la instalación         [-]
        %    emotor  eficiencia del motor eléctrico             [-]
        %    ebomba  eficiencia de la bomba                     [-]
        %    etub    eficiencia de la tubería                   [-]
        %
        %  Las eficiencias en cadena se MULTIPLICAN, no se promedian. Tres
        %  etapas de 0.9 dan 0.73, no 0.9.
        %
        %  EJEMPLO
        %    r = MF.eficiencia('emotor',0.9, 'ebomba',0.75, 'etub',0.95);
        %% ===================================================================
        function [eqs, S] = ecEficiencia()
            S = Motor.simbolos({'etot','emotor','ebomba','etub'});
            etot = S.etot; emotor = S.emotor; ebomba = S.ebomba; etub = S.etub;

            eqs = etot == emotor*ebomba*etub;   % (7.5)
        end

        function r = eficiencia(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecEficiencia, varargin, ...
                {'etot','emotor','ebomba','etub'});
        end

        %% ===================================================================
        %  NÚMERO DE REYNOLDS — (8.2)
        %    NR     número de Reynolds                          [-]
        %    v      velocidad promedio                          [m/s]
        %    D      diámetro interior del tubo                  [m]
        %    nu     viscosidad cinemática                       [m^2/s]
        %    mu     viscosidad dinámica                         [Pa*s]
        %    rho    densidad                                    [kg/m^3]
        %
        %  NR es ADIMENSIONAL: si te da con unidades, algún dato entró en la
        %  escala equivocada. Es el control de unidades más barato del curso.
        %
        %  EN SECCIÓN NO CIRCULAR, D es el diámetro hidráulico Dh de (8.6),
        %  no una medida del contorno. Ver MF.hidraulico.
        %
        %  EJEMPLO
        %    r = MF.reynolds('v',2.5, 'D',0.05, 'nu',1.004e-6);   r.NR
        %    MF.regimen(r.NR)
        %% ===================================================================
        function [eqs, S] = ecReynolds()
            S = Motor.simbolos({'NR','v','D','nu','mu','rho'});
            NR = S.NR; v = S.v; D = S.D; nu = S.nu; mu = S.mu; rho = S.rho;

            eqs = [ NR == v*D/nu                % (8.2)
                    NR == v*D*rho/mu            % (8.2)
                    nu == mu/rho ];             % (2.3)
        end

        function r = reynolds(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecReynolds, varargin, ...
                {'NR','v','D','nu','mu','rho'});
        end

        %% ===================================================================
        %  regimen — CLASIFICA EL FLUJO SEGÚN NR. (8.3)
        %  Es una comparación, no un despeje, y por eso no es un sistema.
        %
        %    NR < 2000            laminar
        %    2000 <= NR <= 4000   transicion
        %    NR > 4000            turbulento
        %
        %  LA ZONA DE TRANSICIÓN NO SE CALCULA. Ahí el flujo cambia de
        %  régimen solo y ninguna de las dos fórmulas de f es confiable: el
        %  diseño se corre fuera de esa franja, no se resuelve dentro.
        %% ===================================================================
        function txt = regimen(NR)
            if NR < 2000
                txt = "laminar";
            elseif NR <= 4000
                txt = "transicion";
            else
                txt = "turbulento";
            end
        end

        %% ===================================================================
        %  FLUJO LAMINAR EN TUBO — (8.4), y el viscosímetro capilar (2.8)
        %    Q      caudal                                      [m^3/s]
        %    D      diámetro interior del tubo                  [m]
        %    A      área de la sección                          [m^2]
        %    dp     caída de presión en la longitud L           [Pa]
        %    mu     viscosidad dinámica                         [Pa*s]
        %    L      longitud del tramo                          [m]
        %    hL     pérdida de cabeza en ese tramo              [m]
        %    gam    peso específico                             [N/m^3]
        %    vprom  velocidad promedio de la sección            [m/s]
        %    vmax   velocidad en el eje del tubo                [m/s]
        %
        %  ES EL MISMO HAGEN-POISEUILLE DE (2.8): el viscosímetro capilar
        %  mide Q y dp y despeja mu con esta misma ecuación. No hay una
        %  función aparte para eso; se entra con Q, dp, L y D y sale mu.
        %
        %  vmax == 2*vprom es exclusivo del perfil parabólico, o sea del
        %  flujo laminar. En turbulento el perfil es casi plano y vprom es
        %  cerca de 0.8*vmax (8.5): esa relación NO está en el sistema
        %  porque es aproximada.
        %
        %  dp == gam*hL es la misma pérdida contada en Pa y en metros. Con
        %  las dos, el sistema controla que los datos cierren.
        %
        %  SOLO VALE CON NR < 2000. El sistema no lo verifica: calculá NR
        %  con MF.reynolds antes de creerle.
        %
        %  EJEMPLO
        %    r = MF.laminar('D',0.01, 'mu',0.26, 'L',5, 'vprom',0.4, ...
        %                   'gam',8800);         r.hL, r.Q
        %% ===================================================================
        function [eqs, S] = ecLaminar()
            S = Motor.simbolos({'Q','D','A','dp','mu','L','hL','gam', ...
                                'vprom','vmax'});
            Q = S.Q; D = S.D; A = S.A; dp = S.dp; mu = S.mu; L = S.L;
            hL = S.hL; gam = S.gam; vprom = S.vprom; vmax = S.vmax;

            eqs = [ Q    == pi*D^4/(128*mu) * dp/L      % (8.4)
                    hL   == 32*mu*L*vprom/(gam*D^2)     % (8.4)
                    dp   == gam*hL                      % (8.4) (redundante)
                    Q    == A*vprom                     % (6.2)
                    A    == pi*D^2/4
                    vmax == 2*vprom ];                  % (8.4)
        end

        function r = laminar(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecLaminar, varargin, ...
                {'Q','D','A','mu','L','gam','vprom','vmax'});
        end

        %% ===================================================================
        %  perfilLaminar — PERFIL PARABÓLICO DE VELOCIDAD. (8.4)
        %  v(r) = vmax*(1 - (r/R)^2)
        %  Es una función de r, no una ecuación algebraica más: por eso está
        %  aparte del sistema. Sirve para graficar el perfil.
        %
        %  Entradas:
        %    vmax : velocidad en el eje, 2*vprom          [m/s]
        %    R    : radio interior del tubo               [m]
        %    r    : posición radial, escalar o vector     [m]
        %  Salida:
        %    v    : velocidad a esa posición              [m/s]
        %
        %  En r = R da 0: es la condición de NO DESLIZAMIENTO, el fluido
        %  pegado a la pared no se mueve.
        %% ===================================================================
        function v = perfilLaminar(vmax, R, r)
            v = vmax .* (1 - (r./R).^2);
        end

        %% ===================================================================
        %  DIÁMETRO HIDRÁULICO — (8.6)
        %    Dh     diámetro hidráulico                         [m]
        %    A      área de la sección de FLUJO                 [m^2]
        %    Pm     perímetro MOJADO                            [m]
        %
        %  Es el reemplazo de D en NR y en Darcy-Weisbach cuando la sección
        %  no es circular.
        %
        %  EL PERÍMETRO MOJADO NO ES EL PERÍMETRO DE LA SECCIÓN: es solo la
        %  parte en contacto con el fluido. En un canal abierto, la
        %  superficie libre no cuenta.
        %
        %  Los atajos de rectángulo y anular están en MF.dhidraulico.
        %
        %  EJEMPLO
        %    r = MF.hidraulico('A',0.02, 'Pm',0.6);   r.Dh
        %% ===================================================================
        function [eqs, S] = ecHidraulico()
            S = Motor.simbolos({'Dh','A','Pm'});
            Dh = S.Dh; A = S.A; Pm = S.Pm;

            eqs = Dh == 4*A/Pm;                 % (8.6)
        end

        function r = hidraulico(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecHidraulico, varargin, {'Dh','A','Pm'});
        end

        %% ===================================================================
        %  dhidraulico — Dh DE LAS SECCIONES DE (8.6), con A y Pm.
        %
        %    MF.dhidraulico('circulo',    'D',0.05)              Dh = D
        %    MF.dhidraulico('rectangulo', 'b',0.3, 'h',0.1)      Dh = 2bh/(b+h)
        %    MF.dhidraulico('anular',     'Do',0.08, 'Di',0.05)  Dh = Do - Di
        %
        %  Las tres son 4*A/Pm resuelta para esa geometría, con el conducto
        %  LLENO. Un canal parcialmente lleno no entra acá: ahí hay que armar
        %  A y Pm a mano y usar MF.hidraulico.
        %
        %  Salidas:
        %    Dh : diámetro hidráulico     [m]
        %    A  : área de flujo           [m^2]
        %    Pm : perímetro mojado        [m]
        %% ===================================================================
        function [Dh, A, Pm] = dhidraulico(forma, varargin)
            s = Motor.datos(varargin, 'MF');
            switch lower(string(forma))
                case "circulo"
                    MF.exigir(s, {'D'}, 'circulo');
                    A = pi*s.D^2/4;     Pm = pi*s.D;
                case "rectangulo"
                    MF.exigir(s, {'b','h'}, 'rectangulo');
                    A = s.b*s.h;        Pm = 2*(s.b + s.h);
                case "anular"
                    MF.exigir(s, {'Do','Di'}, 'anular');
                    A = pi*(s.Do^2 - s.Di^2)/4;     Pm = pi*(s.Do + s.Di);
                otherwise
                    error('MF:formaInvalida', ...
                        'Forma "%s": se acepta circulo, rectangulo o anular.', ...
                        string(forma));
            end
            Dh = 4*A/Pm;
        end

        %% ===================================================================
        %  DARCY-WEISBACH — (9.2)
        %    hL     pérdida de cabeza por fricción              [m]
        %    f      factor de fricción                          [-]
        %    L      longitud del tramo recto                    [m]
        %    D      diámetro interior (o Dh)                    [m]
        %    v      velocidad promedio                          [m/s]
        %    g      gravedad                                    [m/s^2]
        %
        %  Sirve en laminar Y en turbulento: lo que cambia es de dónde sale
        %  f, y eso lo da MF.friccion. Por eso f es un dato del sistema y no
        %  una ecuación adentro: meter f = 64/NR acá ataría todo el sistema
        %  al régimen laminar.
        %
        %  Cubre solo el TRAMO RECTO. Codos, válvulas y cambios de sección
        %  son pérdidas menores (cap. 10 de Mott) y no están en el
        %  formulario.
        %
        %  EJEMPLO
        %    f = MF.friccion(1.5e5, 0.00015/0.05);
        %    r = MF.darcy('f',f, 'L',30, 'D',0.05, 'v',2.5, 'g',9.81);  r.hL
        %% ===================================================================
        function [eqs, S] = ecDarcy()
            S = Motor.simbolos({'hL','f','L','D','v','g'});
            hL = S.hL; f = S.f; L = S.L; D = S.D; v = S.v; g = S.g;

            eqs = hL == f*(L/D)*v^2/(2*g);      % (9.2)
        end

        function r = darcy(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecDarcy, varargin, {'hL','f','L','D','v','g'});
        end

        %% ===================================================================
        %  friccion — FACTOR DE FRICCIÓN f. (9.2)
        %  No es un sistema: Colebrook-White es IMPLÍCITA (f aparece en los
        %  dos lados) y Motor.despejar sustituye hacia adelante, así que no
        %  la puede resolver. Va por fzero.
        %
        %  Entradas:
        %    NR     : número de Reynolds                          [-]
        %    epsD   : rugosidad RELATIVA, eps/D (adimensional)     [-]
        %             Opcional; por defecto 0, tubo liso.
        %    metodo : 'laminar', 'swamee' o 'colebrook'. Opcional:
        %             sin él elige laminar con NR < 2000 y Swamee-Jain
        %             arriba de 2000.
        %  Salidas:
        %    f   : factor de fricción            [-]
        %    met : el método que terminó usando
        %
        %  eps ES LA RUGOSIDAD ABSOLUTA DEL MATERIAL, en metros, y epsD la
        %  divide por el diámetro. Acero comercial: eps = 4.6e-5 m. PVC:
        %  3.0e-7 m. La tabla no está en el formulario.
        %
        %  EL log DEL FORMULARIO ES log10, no natural. En MATLAB, log(x) es
        %  el natural: hay que escribir log10. Es el error que da un f
        %  parecido pero mal, y no salta.
        %
        %  Swamee-Jain vale con 1e-6 <= epsD <= 1e-2 y 5000 <= NR <= 1e8.
        %  Fuera de esa ventana, Colebrook.
        %% ===================================================================
        function [f, met] = friccion(NR, epsD, metodo)
            if nargin < 2 || isempty(epsD),  epsD = 0;  end
            if nargin < 3 || isempty(metodo)
                if NR < 2000, metodo = 'laminar'; else, metodo = 'swamee'; end
            end
            met = string(lower(metodo));
            switch met
                case "laminar"
                    f = 64/NR;                                  % (9.2)
                case "swamee"
                    f = 0.25/(log10(epsD/3.7 + 5.74/NR^0.9))^2;  % (9.2)
                case "colebrook"
                    % Semilla: Swamee-Jain, que ya cae cerca. fzero sin
                    % intervalo arranca de ahí y busca el cambio de signo.
                    f0 = 0.25/(log10(epsD/3.7 + 5.74/NR^0.9))^2;
                    ec = @(x) 1/sqrt(x) + ...
                        2*log10(epsD/3.7 + 2.51/(NR*sqrt(x)));  % (9.2)
                    f = fzero(ec, f0);
                otherwise
                    error('MF:metodoInvalido', ...
                        'Metodo "%s": se acepta laminar, swamee o colebrook.', met);
            end
        end

        %% ===================================================================
        %  FUERZA SOBRE UN OBJETO — (16.5) a (16.7)
        %    Fx Fy Fz    fuerza sobre EL FLUIDO, por componente  [N]
        %    rho         densidad del fluido                     [kg/m^3]
        %    Q           caudal                                  [m^3/s]
        %    v1x v1y v1z velocidad de ENTRADA, por componente    [m/s]
        %    v2x v2y v2z velocidad de SALIDA, por componente     [m/s]
        %    FR          módulo de la resultante                 [N]
        %
        %  LO QUE SALE ES LA FUERZA SOBRE EL FLUIDO. La que el fluido hace
        %  sobre el codo, la tobera o el álabe es la REACCIÓN: el mismo
        %  número con el signo cambiado.
        %
        %  LAS VELOCIDADES SON VECTORES. En un codo de 90 grados el módulo no
        %  cambia y aun así hay fuerza, porque cambia la dirección. Poner
        %  v2 - v1 con módulos da cero y es el error típico.
        %
        %  El sistema NO incluye las fuerzas de presión ni el peso (16.8):
        %  Fx, Fy, Fz son la resultante de TODAS las externas. Separar cuánto
        %  pone la presión y cuánto la pared es trabajo de DCL, tuyo.
        %
        %  EJEMPLO — codo de 90 grados, entra en x y sale en y:
        %    r = MF.impulso('rho',998, 'Q',0.03, 'v1x',4, 'v1y',0, ...
        %                   'v2x',0, 'v2y',4, 'v1z',0, 'v2z',0);
        %% ===================================================================
        function [eqs, S] = ecImpulso()
            S = Motor.simbolos({'Fx','Fy','Fz','rho','Q', ...
                                'v1x','v1y','v1z','v2x','v2y','v2z','FR'});
            Fx = S.Fx; Fy = S.Fy; Fz = S.Fz; rho = S.rho; Q = S.Q;
            v1x = S.v1x; v1y = S.v1y; v1z = S.v1z;
            v2x = S.v2x; v2y = S.v2y; v2z = S.v2z; FR = S.FR;

            eqs = [ Fx == rho*Q*(v2x - v1x)             % (16.5)
                    Fy == rho*Q*(v2y - v1y)             % (16.6)
                    Fz == rho*Q*(v2z - v1z)             % (16.7)
                    FR == sqrt(Fx^2 + Fy^2 + Fz^2) ];   % (16.8)
        end

        function r = impulso(varargin)
            % ATAJO: datos en pares nombre-valor -> struct numérico.
            r = MF.resolver(@MF.ecImpulso, varargin, {'rho','Q','FR'});
        end

        %% ===================================================================
        %  ctes — CONSTANTES Y PROPIEDADES DE TABLA, en SI base.
        %  Están acá para no volver a tipearlas y para que el valor sea
        %  siempre el mismo en todos los scripts.
        %
        %    c = MF.ctes();
        %    c.g              9.81        [m/s^2]
        %    c.patm           101325      [Pa]
        %    c.agua4.rho      1000        [kg/m^3]   referencia de sg
        %    c.agua4.gam      9810        [N/m^3]
        %    c.agua20.rho     998         [kg/m^3]
        %    c.agua20.gam     9790        [N/m^3]
        %    c.agua20.mu      1.002e-3    [Pa*s]
        %    c.agua20.nu      1.004e-6    [m^2/s]
        %    c.aire20.rho     1.204       [kg/m^3]
        %    c.aire20.mu      1.81e-5     [Pa*s]
        %    c.aire20.nu      1.51e-5     [m^2/s]
        %    c.mercurio.rho   13550       [kg/m^3]
        %    c.mercurio.sg    13.55       [-]
        %    c.mercurio.gam   132926      [N/m^3]
        %
        %  EL AGUA TIENE DOS ENTRADAS a propósito. sg se define contra el
        %  agua a 4 grados (1000 kg/m^3), pero los problemas trabajan a 20
        %  grados (998). Usar la de 4 para calcular un peso es un error del
        %  0.2 %, y usar la de 20 para sg, también. Cada una en su lugar.
        %% ===================================================================
        function c = ctes()
            c.g    = 9.81;
            c.patm = 101325;

            c.agua4.rho  = 1000;        c.agua4.gam  = 1000*9.81;
            c.agua20.rho = 998;         c.agua20.gam = 9790;
            c.agua20.mu  = 1.002e-3;    c.agua20.nu  = 1.004e-6;
            c.aire20.rho = 1.204;
            c.aire20.mu  = 1.81e-5;     c.aire20.nu  = 1.51e-5;
            c.mercurio.rho = 13550;     c.mercurio.sg = 13.55;
            c.mercurio.gam = 13550*9.81;
        end

        %% ===================================================================
        %  conv — FACTORES DE CONVERSIÓN A SI BASE (Tabla K.1).
        %  MULTIPLICAR el valor del enunciado por el factor:
        %      L = 40*k.in;      % longitud [m]   (40 in)
        %      p = 14.7*k.psi;   % presión [Pa]   (14.7 psi)
        %      Q = 250*k.gpm;    % caudal [m^3/s] (250 gal/min)
        %
        %  La conversión va EN LA ASIGNACIÓN, con el valor original al lado
        %  en el comentario. Adentro de los sistemas no hay conversiones: si
        %  entra un dato en psi, sale basura y no salta ningún error.
        %
        %    k = MF.conv();
        %    longitud  k.ft k.in k.mi          -> m
        %    masa      k.slug k.lbm            -> kg
        %    fuerza    k.lbf k.kip             -> N
        %    área      k.ft2 k.in2             -> m^2
        %    volumen   k.ft3 k.gal k.L         -> m^3
        %    caudal    k.cfs k.gpm k.Lmin      -> m^3/s
        %    densidad  k.slugft3               -> kg/m^3
        %    presión   k.atm k.bar k.psi k.mmHg k.inH2O -> Pa
        %    potencia  k.HP k.kW              -> W
        %    viscosidad k.poise k.cP k.stoke  -> Pa*s y m^2/s
        %% ===================================================================
        function k = conv()
            k.ft = 0.3048;      k.in = 0.0254;      k.mi = 1609.0;
            k.slug = 14.59;     k.lbm = 0.4536;
            k.lbf = 4.448;      k.kip = 4448;
            k.ft2 = 0.0929;     k.in2 = 645.2e-6;
            k.ft3 = 28.32e-3;   k.gal = 3.785e-3;   k.L = 1e-3;
            k.cfs = 28.32e-3;   k.gpm = 3.785e-3/60;    k.Lmin = 1e-3/60;
            k.slugft3 = 515.4;
            k.atm = 101325;     k.bar = 1e5;        k.psi = 6894.76;
            k.mmHg = 101325/760;    k.inH2O = 249.1;
            k.HP = 745.7;       k.kW = 1000;
            k.poise = 0.1;      k.cP = 1e-3;        k.stoke = 1e-4;
        end
    end

    methods(Static, Access = private)

        function r = resolver(ecFun, args, positivos)
            % Lo que hacen todos los atajos, escrito una vez. Es el mismo
            % patrón de MM.resolver.
            %   ecFun     : handle al sistema, @MF.ecCaudal
            %   args      : el varargin del atajo, sin desarmar
            %   positivos : variables que son positivas por física, para
            %               filtrar raíces cuando solve devuelve varias
            % Motor.numerico usa el orden del diccionario S en la salida.
            d = Motor.datos(args, 'MF');
            [eqs, S] = ecFun();
            res = Motor.despejar(eqs, S, d, 'prefijo','MF', 'positivos',positivos);
            r = Motor.numerico(res, d, S);
        end

        function exigir(s, campos, forma)
            % Controla que estén los datos que esa geometría necesita.
            falta = campos(~isfield(s, campos));
            if ~isempty(falta)
                error('MF:faltaDato', ...
                    'La forma "%s" necesita: %s.', forma, strjoin(falta, ', '));
            end
        end
    end
end
