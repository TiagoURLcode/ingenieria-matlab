classdef FV
    % =========================================================================
    % FV.m - Sistemas de ecuaciones del formulario oficial de Fisica 5
    %
    % USO: se llaman con el prefijo de la clase, desde cualquier script:
    %   r = FV.rel('v', 0.8*2.998e8, 'mo', 2);      double(r.gam)
    %   r = FV.fe('lam', 400e-9, 'fi', 3.2e-19);    double(r.Vo)
    %   r = FV.bohr('n', 3);                        double(r.rn)
    % Escribiendo "FV." + Tab se autocompleta la lista de funciones.
    %
    % CADA TEMA ES UN SISTEMA APARTE, a proposito. Juntarlos en uno solo
    % ataria relaciones que no existen: la lambda de De Broglie de un
    % electron y la lambda del foton de Compton se llaman igual y no son lo
    % mismo. El precio es que tenes que elegir el sistema; la ventaja es que
    % ninguno te devuelve un numero que no corresponde.
    %
    % SIEMPRE HAY UN PAR: ecXxx entrega el sistema SIN resolver (para leerlo
    % o para graficar con el), y xxx lo resuelve con los datos que le pases.
    %
    % Los sistemas andan EN CUALQUIER DIRECCION: le das lo que tenes y
    % devuelve todo lo que quede determinado. No se pide una incognita.
    %
    % UNIDADES: SI base en TODO el archivo.
    %   longitud [m]    energia [J]     masa [kg]      carga [C]
    %   tiempo   [s]    velocidad [m/s] frecuencia [Hz] campo B [T]
    %   momentum [kg*m/s]               potencial [V]
    % El formulario trabaja en eV a cada rato. Los eV NO entran al sistema:
    % se convierten antes con FV.eV2J y se leen despues con FV.J2eV.
    %
    % ANGULOS: RADIANES. cos() y sin() de MATLAB piden radianes. Si el
    % enunciado te da grados, pasalos con deg2rad(60) al entrar y con
    % rad2deg() al leer.
    %
    % VELOCIDADES: en m/s, no en fracciones de c. "0.8c" se escribe
    % 0.8*double(FV.ctes().c). Poner 0.8 pelado da resultados sin sentido y
    % no salta ningun error.
    % =========================================================================

    methods(Static)

        function C = ctes()
            % CONSTANTES del formulario, en SIMBOLICO EXACTO.
            % Se devuelven como sym y no como double para que las ecuaciones
            % que las comparten cierren de forma exacta (ver la nota sobre
            % constantes redondeadas en FV.ecBohr).
            % Para el numero suelto:  double(FV.ctes().h)
            %
            % c y eps0 NO ESTAN en el formulario, y hacen falta: sin c no hay
            % relatividad y sin eps0 no hay Bohr. Van los valores estandar.
            C.c    = sym(299792458);        % velocidad de la luz [m/s]
            C.h    = sym(663)/sym(10)^36;   % Planck [J*s]        (6.63e-34)
            C.hbar = sym(1055)/sym(10)^37;  % h barra [J*s]       (1.055e-34)
            C.me   = sym(911)/sym(10)^33;   % masa electron [kg]  (9.11e-31)
            C.mp   = sym(167)/sym(10)^29;   % masa proton [kg]    (1.67e-27)
            C.qe   = sym(16)/sym(10)^20;    % carga elemental [C] (1.6e-19)
            C.eV   = sym(16)/sym(10)^20;    % 1 eV en joules [J]  (1.6e-19)
            C.R    = sym(1097)*sym(10)^4;   % Rydberg [1/m]       (1.097e7)
            C.eps0 = sym(885)/sym(10)^14;   % permitividad [F/m]  (8.85e-12)

            % POR QUE FRACCIONES DE ENTEROS Y NO sym('6.63e-34'). Escrito
            % asi, MATLAB guarda un simbolico de COMA FLOTANTE: la aritmetica
            % que sigue arrastra redondeo, las identidades que deberian
            % cerrar exacto quedan con un residuo de 1e-51, isAlways las da
            % por falsas y despejar aborta con datos perfectamente buenos.
            % Probado: pasa exactamente eso en FV.ecCompton.
            % Como razon de enteros, todo el sistema trabaja en racionales
            % exactos y las identidades se demuestran.

            % SIGNO DE qe. El formulario lo escribe qe = -1.6e-19 C, que es
            % la carga del ELECTRON. Aca se guarda la MAGNITUD, positiva,
            % porque todas las formulas donde qe entra solo (Kmax = e*Vo,
            % p = sqrt(2*m*qe*Vab), e*Vac = h*c/lam_min) piden el valor
            % absoluto: con el signo negativo darian raiz de un numero
            % negativo o una energia negativa. Donde entra al cuadrado o a la
            % cuarta (Bohr) el signo no cambia nada.
        end

        function J = eV2J(eV)
            % ELECTRONVOLTS -> JOULES. 1 eV = 1.6e-19 J.
            % ENTRADA:
            %   eV : energia en electronvolts [eV]
            % SALIDA:
            %   J  : la misma energia en joules [J]
            J = eV*1.6e-19;
        end

        function eV = J2eV(J)
            % JOULES -> ELECTRONVOLTS. Es la inversa de FV.eV2J.
            % ENTRADA:
            %   J  : energia en joules [J]
            % SALIDA:
            %   eV : la misma energia en electronvolts [eV]
            eV = J/1.6e-19;
        end

        %% ================================================================
        %  RELATIVIDAD
        %
        %  Todo cuelga de un solo numero, gamma:
        %     gam = 1/sqrt(1 - v^2/c^2)  >= 1 siempre
        %  Con v = 0 vale 1 y no pasa nada (ahi la relatividad se apaga y
        %  quedan las formulas de siempre). Cuando v se acerca a c, gam se
        %  dispara.
        %
        %  LO QUE LLEVA SUBINDICE CERO ES LO PROPIO, y es lo que mas se
        %  confunde:
        %    mo  masa en reposo, medida por quien viaja CON el objeto
        %    Lo  longitud propia, medida por quien esta en reposo respecto
        %        del objeto
        %    to  tiempo propio, entre dos eventos que ocurren en el MISMO
        %        lugar del marco que los mide
        %  El tiempo se DILATA (t = gam*to, sale mas grande) y la longitud se
        %  CONTRAE (L = Lo/gam, sale mas chica). Mismo gamma, direcciones
        %  opuestas: multiplica en uno y divide en el otro. Poner los dos
        %  para el mismo lado es el error clasico y no avisa.
        %% ================================================================

        function [eqs, S] = ecRel()
            % SISTEMA - dilatacion, contraccion, masa, momentum y energia.
            % Formulas (5) a (12) del formulario.
            % No resuelve: entrega las ecuaciones y el diccionario.
            % SALIDAS:
            %   eqs : vector simbolico con las relaciones, sin resolver
            %   S   : struct-diccionario. S.gam es el SIMBOLO gam, no un
            %         valor. Hay que devolverlo: cada sym() crea objetos
            %         nuevos, asi que una gam declarada afuera NO es la de
            %         adentro de eqs.
            %
            % VARIABLES:
            %   v    velocidad relativa entre los marcos      [m/s]
            %   gam  factor de Lorentz, adimensional          [-]
            %   mo   masa en reposo                           [kg]
            %   m    masa relativista, la que mide el otro    [kg]
            %   Lo   longitud propia                          [m]
            %   L    longitud contraida                       [m]
            %   to   tiempo propio                            [s]
            %   t    tiempo dilatado                          [s]
            %   p    momentum relativista                     [kg*m/s]
            %   K    energia cinetica                         [J]
            %   ET   energia total                            [J]
            %   E0   energia en reposo                        [J]

            % sym() y NO syms: dentro de un metodo, syms falla si el nombre
            % choca con una funcion del path.
            nom = {'v','gam','mo','m','Lo','L','to','t','p','K','ET','E0'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            v = S.v; gam = S.gam; mo = S.mo; m = S.m; Lo = S.Lo; L = S.L;
            to = S.to; t = S.t; p = S.p; K = S.K; ET = S.ET; E0 = S.E0;

            c = FV.ctes().c;

            % == (doble igual) construye una ECUACION, no una comparacion.
            eqs = [ gam  == 1/sqrt(1 - v^2/c^2)
                m    == gam*mo                    % (6)
                L    == Lo/gam                    % (5)
                t    == gam*to                    % (7)
                p    == m*v                       % (8)
                E0   == mo*c^2                    % (12)
                ET   == m*c^2                     % (10)
                ET   == K + E0                    % (9) y (10)
                ET   == sqrt(E0^2 + (p*c)^2) ];   % (11)

            % LA (11) VA CON RAIZ Y NO AL CUADRADO. Escrita ET^2 == ...,
            % entrar por p la vuelve una ecuacion de segundo grado en ET y
            % el motor agarra la raiz NEGATIVA, que despues arrastra masa y
            % velocidad negativas hasta hacer abortar el sistema. Probado.
            % Con la raiz explicita, ET sale positiva de una.
            %
            % LA ULTIMA ES REDUNDANTE, y esta a proposito. Sale de las otras
            % (probado: la identidad cierra exacto para cualquier v), asi que
            % cuando entras por v no aporta nada y queda de CONTROL: si los
            % datos no cierran entre si, FV.despejar aborta en vez de
            % devolver un numero mentiroso.
            % Lo que si habilita es la entrada SIN v: con mo y p conocidos,
            % ET sale de esta sola. Es el camino tipico de los problemas de
            % particulas, donde te dan el momentum y no la velocidad.
            %
            % SI ENTRAS POR gam, v SALE CON SIGNO. La ecuacion de gamma tiene
            % dos raices, +v y -v, porque v entra al cuadrado. El motor toma
            % la primera y avisa con un warning. Tomale el valor absoluto.
            %
            % K NO ES (1/2)*m*v^2. Esa formula es el limite de v << c. Aca K
            % es ET - E0, que es lo que dice la formula (9). Usar la clasica
            % a velocidades relativistas da de menos, y cada vez mas de menos
            % conforme v se acerca a c.
        end

        function [eqs, S] = ecLorentz()
            % SISTEMA - transformacion de coordenadas entre marcos.
            % Formulas (1) y (2) del formulario.
            %
            % VARIABLES:
            %   x    posicion del evento en el marco S        [m]
            %   t    instante del evento en el marco S        [s]
            %   xp   posicion en el marco S' (x prima)        [m]
            %   tp   instante en el marco S' (t prima)        [s]
            %   v    velocidad de S' respecto de S            [m/s]
            %   gam  factor de Lorentz                        [-]
            %
            % La prima se escribe p (xp, tp): MATLAB no admite x' como
            % nombre de variable.

            nom = {'x','t','xp','tp','v','gam'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            x = S.x; t = S.t; xp = S.xp; tp = S.tp; v = S.v; gam = S.gam;

            c = FV.ctes().c;

            eqs = [ gam == 1/sqrt(1 - v^2/c^2)
                xp  == gam*(x - v*t)              % (1)
                x   == gam*(xp + v*tp) ];         % (2)

            % LAS DOS ECUACIONES JUNTAS DAN tp, aunque el formulario no traiga
            % la formula del tiempo. (1) te da xp desde x y t; metiendo ese xp
            % en (2), la unica incognita que queda es tp y el motor la despeja
            % sola. El resultado es exactamente tp = gam*(t - v*x/c^2), que es
            % la transformacion que falta. Verificado.
            % Por eso las dos estan aunque sean una la inversa de la otra:
            % separadas no alcanzan, juntas cierran el juego completo.
            %
            % v ES LA VELOCIDAD DEL MARCO, no la de una particula. Para
            % componer velocidades de particulas, FV.velo.
        end

        function [eqs, S] = ecVelo()
            % SISTEMA - suma relativista de velocidades.
            % Formulas (3) y (4) del formulario.
            %
            % VARIABLES:
            %   vx   velocidad de la particula medida en S    [m/s]
            %   vxp  velocidad de la misma particula en S'    [m/s]
            %   u    velocidad de S' respecto de S            [m/s]

            nom = {'vx','vxp','u'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            vx = S.vx; vxp = S.vxp; u = S.u;

            c = FV.ctes().c;

            eqs = [ vxp == (vx - u)/(1 - u*vx/c^2)        % (3)
                vx  == (vxp + u)/(1 + u*vxp/c^2) ];       % (4)

            % LA SEGUNDA ES LA INVERSA DE LA PRIMERA, y queda de CONTROL. El
            % motor puede despejar cualquiera de las tres variables desde (3)
            % sola, asi que (4) nunca hace falta para avanzar; lo que hace es
            % verificar. La identidad cierra exacto (probado), asi que si
            % aborta con datosContradictorios el problema son tus datos.
            %
            % POR QUE NO SE SUMAN Y YA. Con u = vx = 0.9c, la suma clasica
            % daria 1.8c. El denominador es el que impide pasarse de c: por
            % mas que sumes, el resultado siempre queda abajo.
            % A velocidades chicas el termino u*vx/c^2 es despreciable y la
            % formula se vuelve la resta de toda la vida.
        end

        function res = rel(varargin)
            % DESPEJE - relatividad: dilatacion, contraccion, masa, energia.
            % Datos en pares nombre-valor o struct; devuelve TODO lo que se
            % pueda despejar.
            %   r = FV.rel('v',0.8*2.998e8, 'mo',2);   double(r.ET)
            %   r = FV.rel('to',1, 'v',0.6*2.998e8);   double(r.t)
            %   r = FV.rel('mo',9.11e-31, 'p',5e-22);  double(r.ET)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecRel();
            res = FV.despejar(eqs, S, d);
        end

        function res = lorentz(varargin)
            % DESPEJE - transformacion de coordenadas entre marcos.
            %   r = FV.lorentz('x',100, 't',2e-7, 'v',0.6*2.998e8);
            %   double(r.xp), double(r.tp)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecLorentz();
            res = FV.despejar(eqs, S, d);
        end

        function res = velo(varargin)
            % DESPEJE - suma relativista de velocidades.
            %   r = FV.velo('vx',0.9*2.998e8, 'u',0.9*2.998e8); double(r.vxp)
            %   r = FV.velo('vxp',0.5*2.998e8, 'u',0.5*2.998e8); double(r.vx)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecVelo();
            res = FV.despejar(eqs, S, d);
        end

        %% ================================================================
        %  FOTONES Y ONDAS
        %
        %  El foton no tiene masa en reposo, asi que la formula (11) de
        %  relatividad se le cae el termino mo*c^2 y queda E = p*c. De ahi
        %  sale todo lo demas.
        %
        %  Nomenclatura comun a los sistemas de esta seccion:
        %    E    energia del foton                          [J]
        %    nu   frecuencia del foton                       [Hz]
        %    lam  longitud de onda del foton                 [m]
        %    p    momentum del foton                         [kg*m/s]
        %  Las tres primeras son la MISMA informacion escrita de tres
        %  maneras: sabiendo una, salen las otras dos.
        %
        %  EL FORMULARIO USA phi PARA DOS COSAS DISTINTAS:
        %    en (14) es la FUNCION TRABAJO del metal, una energia [J]
        %    en (17) es el ANGULO de dispersion del foton     [rad]
        %  Aca las dos se llaman fi, pero viven en sistemas separados
        %  (FV.ecFE y FV.ecCompton), asi que no se pisan. Fijate en cual
        %  estas parado antes de pasar el dato.
        %% ================================================================

        function [eqs, S] = ecFoton()
            % SISTEMA - energia y momentum de un foton.
            % Formulas (13) y (15) del formulario.
            % Es el sistema mas chico y el que mas se usa: convierte entre
            % energia, frecuencia, longitud de onda y momentum.
            %
            % VARIABLES:
            %   E    energia del foton                        [J]
            %   nu   frecuencia                               [Hz]
            %   lam  longitud de onda                         [m]
            %   p    momentum                                 [kg*m/s]

            nom = {'E','nu','lam','p'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            E = S.E; nu = S.nu; lam = S.lam; p = S.p;

            C = FV.ctes(); c = C.c; h = C.h;

            eqs = [ E   == h*nu                   % (13)
                E   == h*c/lam                    % (13)
                E   == p*c                        % (13)
                p   == h/lam ];                   % (15)

            % LAS CUATRO SON LA MISMA RELACION mirada de distintos lados, y
            % estan las cuatro para que puedas entrar por donde te den el
            % dato. Cualquier par de ellas implica lam*nu == c.
            % La cuarta es redundante con la segunda y la tercera, y cierra
            % exacto: queda de control.
            %
            % SI ENTRAS POR DOS DATOS A LA VEZ (lam y nu, por ejemplo), el
            % sistema los VERIFICA. Si no cumplen lam*nu = c, aborta con
            % datosContradictorios. Es lo que queres: significa que uno de
            % los dos esta mal copiado.
        end

        function [eqs, S] = ecFE()
            % SISTEMA - efecto fotoelectrico.
            % Formulas (13), (14) y (19) del formulario.
            %
            % VARIABLES:
            %   E     energia del foton incidente             [J]
            %   nu    frecuencia del foton incidente          [Hz]
            %   lam   longitud de onda incidente              [m]
            %   Kmax  energia cinetica maxima del electron    [J]
            %   Vo    potencial de frenado                    [V]
            %   fi    funcion trabajo del metal               [J]
            %   nu0   frecuencia umbral del metal             [Hz]
            %   lam0  longitud de onda umbral (la MAXIMA)     [m]

            nom = {'E','nu','lam','Kmax','Vo','fi','nu0','lam0'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            E = S.E; nu = S.nu; lam = S.lam; Kmax = S.Kmax; Vo = S.Vo;
            fi = S.fi; nu0 = S.nu0; lam0 = S.lam0;

            C = FV.ctes(); c = C.c; h = C.h; qe = C.qe;

            eqs = [ E    == h*nu                  % (13)
                E    == h*c/lam                   % (13)
                Kmax == E - fi                    % (14)
                Kmax == qe*Vo                     % (14)
                fi   == h*nu0                     % (14)
                fi   == h*c/lam0 ];               % (19)

            % lam0 ES UN MAXIMO, NO UN MINIMO. Es la formula (19) del
            % formulario, lam_max = h*c/E_min, con E_min = fi: por debajo de
            % esa energia el foton no arranca ningun electron. Como lambda va
            % al reves de la energia, la energia MINIMA es la longitud de
            % onda MAXIMA. Luz mas larga que lam0 no produce efecto por mas
            % intensa que sea, y esa es toda la gracia del experimento.
            %
            % Vo EN VOLTS, Kmax EN JOULES. La formula Kmax = e*Vo tiene la
            % carga adentro: si le pasas Vo = 1.5 V, Kmax sale
            % 2.4e-19 J. En eV el numero coincide con Vo (1.5 eV), y por eso
            % los enunciados los mezclan. Para leerlo asi: FV.J2eV(Kmax).
            %
            % SI Kmax SALE NEGATIVO el foton no tenia energia suficiente: no
            % hay emision. El sistema no lo sabe y te devuelve el numero
            % igual. Fijate el signo antes de reportar nada.
            %
            % LA INTENSIDAD NO ESTA EN NINGUNA DE ESTAS ECUACIONES, y es a
            % proposito: mas intensidad son mas fotones, no fotones mas
            % energicos. Cambia CUANTOS electrones salen, no con cuanta
            % energia.
        end

        function [eqs, S] = ecCompton()
            % SISTEMA - dispersion de Compton.
            % Formulas (17), (18) y (24) del formulario, mas las del foton.
            %
            % VARIABLES:
            %   lam   longitud de onda del foton INCIDENTE    [m]
            %   lamp  longitud de onda del foton DISPERSADO   [m]
            %   fi    angulo de dispersion del FOTON          [rad]
            %   E     energia del foton incidente             [J]
            %   Ep    energia del foton dispersado            [J]
            %   Ke    energia cinetica del electron           [J]
            %   p     momentum del foton incidente            [kg*m/s]
            %   pp    momentum del foton dispersado           [kg*m/s]
            %   th    angulo de retroceso del ELECTRON        [rad]
            %   v     velocidad del electron                  [m/s]

            nom = {'lam','lamp','fi','E','Ep','Ke','p','pp','th','v'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            lam = S.lam; lamp = S.lamp; fi = S.fi; E = S.E; Ep = S.Ep;
            Ke = S.Ke; p = S.p; pp = S.pp; th = S.th; v = S.v;

            C = FV.ctes(); c = C.c; h = C.h; me = C.me;

            eqs = [ lamp - lam == (h/(me*c))*(1 - cos(fi))    % (17)
                E   == h*c/lam                                % (13)
                Ep  == h*c/lamp                               % (13)
                Ke  == E - Ep                                 % (18)
                p   == h/lam                                  % (15)
                pp  == h/lamp                                 % (15)
                sin(th) == h*sin(fi)*sqrt(1 - v^2/c^2)/(lamp*me*v) ]; % (24)

            % h/(me*c) ES LA LONGITUD DE ONDA DE COMPTON, 2.43e-12 m. Es un
            % corrimiento FIJO en lambda, no un porcentaje: el mismo para
            % rayos X que para luz visible. Por eso el efecto solo se nota
            % con rayos X, donde lambda ya es de ese orden; en luz visible
            % (500e-9 m) el corrimiento es cinco ordenes mas chico y se
            % pierde.
            %
            % EL CORRIMIENTO SIEMPRE ES POSITIVO: lamp >= lam. El foton
            % entrega energia al electron, y menos energia es mas lambda.
            % Con fi = 0 (sin desviarse) no pasa nada; con fi = pi (rebote de
            % frente) el corrimiento es maximo, 2*h/(me*c).
            % fi EN RADIANES: deg2rad(60), no 60.
            %
            % SI ENTRAS POR EL CORRIMIENTO PARA SACAR fi, la ecuacion tiene
            % dos soluciones (+fi y -fi, porque el coseno es par). El motor
            % toma la primera y avisa. Tomale el valor absoluto.
            %
            % LA (20), p_electron = p - p', NO ESTA ACA. Es una resta de
            % VECTORES, no de numeros: el foton dispersado sale a fi del eje
            % y el electron a -th, asi que restar los modulos da cualquier
            % cosa. Para el electron usa Ke, que es escalar y sale de la (18).
            % La (24) es la que te da su angulo th, y necesita v.
        end

        function [eqs, S] = ecRX()
            % SISTEMA - tubo de rayos X, limite de longitud de onda corta.
            % Formula (16) del formulario.
            %
            % VARIABLES:
            %   Vac     tension de aceleracion del tubo       [V]
            %   Emax    energia del foton mas energetico      [J]
            %   lammin  longitud de onda MINIMA emitida       [m]
            %   numax   frecuencia maxima emitida             [Hz]

            nom = {'Vac','Emax','lammin','numax'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            Vac = S.Vac; Emax = S.Emax; lammin = S.lammin; numax = S.numax;

            C = FV.ctes(); c = C.c; h = C.h; qe = C.qe;

            eqs = [ Emax == qe*Vac                % (16)
                Emax == h*c/lammin                % (16)
                Emax == h*numax ];                % (13)

            % ES EL CASO EXTREMO, no el tipico. lammin corresponde al
            % electron que entrega TODA su energia cinetica en un solo
            % choque. La mayoria pierde la energia de a pedazos y produce
            % fotones mas blandos, que es el fondo continuo del espectro.
            % Por eso el espectro tiene un corte neto a la izquierda: mas
            % corto que lammin no hay nada, y ese corte no depende del
            % material del blanco, solo de Vac.
            %
            % ES EL FOTOELECTRICO AL REVES: alla un foton entra y sale un
            % electron; aca entra un electron y sale un foton. La ecuacion es
            % casi la misma con los papeles cambiados.
        end

        function [eqs, S] = ecPares()
            % SISTEMA - produccion de pares.
            % Formula (21) del formulario.
            %
            % VARIABLES:
            %   E    energia del foton incidente              [J]
            %   nu   frecuencia del foton                     [Hz]
            %   lam  longitud de onda del foton               [m]
            %   mom  masa en reposo de la particula negativa  [kg]
            %   mop  masa en reposo de la particula positiva  [kg]
            %   Eu   energia umbral, (mom+mop)*c^2            [J]
            %   Km   energia cinetica de la negativa          [J]
            %   Kp   energia cinetica de la positiva          [J]

            nom = {'E','nu','lam','mom','mop','Eu','Km','Kp'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            E = S.E; nu = S.nu; lam = S.lam; mom = S.mom; mop = S.mop;
            Eu = S.Eu; Km = S.Km; Kp = S.Kp;

            C = FV.ctes(); c = C.c; h = C.h;

            eqs = [ E  == h*nu                    % (13)
                E  == h*c/lam                     % (13)
                Eu == (mom + mop)*c^2
                E  == Eu + Km + Kp ];             % (21)

            % PARA EL PAR ELECTRON-POSITRON las dos masas valen lo mismo:
            % mom = mop = FV.ctes().me, y el umbral queda 2*me*c^2 =
            % 1.64e-13 J = 1.02 MeV. Van como simbolos y no clavadas para que
            % sirva con otros pares.
            %
            % SI E < Eu NO PASA NADA. El foton no puede crear el par por mas
            % que le sobre intensidad: le falta energia. El sistema no lo
            % chequea y te devuelve Km + Kp negativo, que es la senal de que
            % estas debajo del umbral.
            %
            % Km Y Kp NO SALEN POR SEPARADO de este sistema: la ecuacion (21)
            % solo da la SUMA. Para partirla hace falta el reparto que diga
            % el enunciado (casi siempre "se reparten por igual", Km = Kp).
            % Si le pasas uno de los dos, el sistema te devuelve el otro.
        end

        function [eqs, S] = ecMagB()
            % SISTEMA - particula cargada relativista en un campo magnetico.
            % Formulas (22) y (23) del formulario.
            %
            % VARIABLES:
            %   q    carga de la particula, MAGNITUD          [C]
            %   mo   masa en reposo                           [kg]
            %   v    velocidad                                [m/s]
            %   gam  factor de Lorentz                        [-]
            %   B    campo magnetico                          [T]
            %   r    radio de la trayectoria circular         [m]
            %   p    momentum relativista                     [kg*m/s]
            %   E    energia total de la particula            [J]

            nom = {'q','mo','v','gam','B','r','p','E'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            q = S.q; mo = S.mo; v = S.v; gam = S.gam; B = S.B; r = S.r;
            p = S.p; E = S.E;

            c = FV.ctes().c;

            eqs = [ p   == mo*gam*v               % (22)
                gam == 1/sqrt(1 - v^2/c^2)
                p   == q*B*r                      % (22)
                E   == sqrt((mo*c^2)^2 + (p*c)^2)  % (23)
                E   == gam*mo*c^2 ];

            % q Y mo VAN COMO DATOS, no clavados. La formula (22) del
            % formulario escribe qe porque el caso tipico es un electron,
            % pero el mismo sistema vale para un proton o un ion. Para el
            % electron: q = 1.6e-19, mo = 9.11e-31. Para el proton:
            % q = 1.6e-19, mo = 1.67e-27. Ambos salen de FV.ctes().
            % q va en MAGNITUD, positiva: el signo solo decide para que lado
            % gira, y el radio es el mismo.
            %
            % LA (23) ES LA (11) DE RELATIVIDAD con p = q*B*r metido adentro.
            % Por eso esta escrita con p y no con q*B*r: asi el sistema la
            % puede usar aunque no conozcas B ni r.
            %
            % EL ORDEN DE LAS DOS PRIMERAS IMPORTA, y no es cosmetico.
            % p == mo*gam*v es LINEAL en v y da una sola raiz; la de gamma
            % tiene v al cuadrado y da dos. Con la de gamma primero, apenas
            % gam queda determinada el motor saca v de ahi, agarra la raiz
            % NEGATIVA y el sistema aborta contra la otra ecuacion. Probado.
            % Puesta la lineal adelante, v sale positiva y la de gamma queda
            % de control.
            %
            % LA ULTIMA ES REDUNDANTE Y HACE FALTA IGUAL. Sin ella, entrando
            % por q, B, r y mo el despeje se TRABA: p y E salen, pero gam y v
            % quedan repartidas en dos ecuaciones con dos incognitas cada una
            % y la sustitucion hacia adelante no puede empezar por ninguna.
            % Probado. E == gam*mo*c^2 es EXPLICITA en gam, asi que la
            % destraba: gam sale de E, y con gam sale v.
            %
            % LAS DOS FORMAS DE p SON UN CONTROL, no una redundancia formal:
            % mo*gam*v es cinematica y q*B*r es la medicion en el laboratorio.
            % Que coincidan es fisica, no algebra. Si le pasas los seis datos
            % y no cierran, el sistema aborta, y hace bien.
        end

        function res = foton(varargin)
            % DESPEJE - energia, frecuencia, lambda y momentum de un foton.
            %   r = FV.foton('lam',500e-9);   double(r.E)
            %   r = FV.foton('E',FV.eV2J(2)); double(r.lam)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecFoton();
            res = FV.despejar(eqs, S, d);
        end

        function res = fe(varargin)
            % DESPEJE - efecto fotoelectrico.
            %   r = FV.fe('lam',400e-9, 'fi',FV.eV2J(2.3));  double(r.Vo)
            %   r = FV.fe('lam0',550e-9, 'lam',300e-9);      FV.J2eV(double(r.Kmax))
            d = FV.datos(varargin);
            [eqs, S] = FV.ecFE();
            res = FV.despejar(eqs, S, d);
        end

        function res = compton(varargin)
            % DESPEJE - dispersion de Compton.
            %   r = FV.compton('lam',0.05e-9, 'fi',deg2rad(60));
            %   double(r.lamp), FV.J2eV(double(r.Ke))
            d = FV.datos(varargin);
            [eqs, S] = FV.ecCompton();
            res = FV.despejar(eqs, S, d);
        end

        function res = rx(varargin)
            % DESPEJE - tubo de rayos X.
            %   r = FV.rx('Vac',35e3);        double(r.lammin)
            %   r = FV.rx('lammin',0.05e-9);  double(r.Vac)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecRX();
            res = FV.despejar(eqs, S, d);
        end

        function res = pares(varargin)
            % DESPEJE - produccion de pares.
            %   me = double(FV.ctes().me);
            %   r  = FV.pares('mom',me, 'mop',me, 'lam',1e-12); double(r.Eu)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecPares();
            res = FV.despejar(eqs, S, d);
        end

        function res = magB(varargin)
            % DESPEJE - particula cargada relativista en campo magnetico.
            %   r = FV.magB('q',1.6e-19, 'B',0.5, 'r',0.1, 'mo',9.11e-31);
            %   double(r.E)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecMagB();
            res = FV.despejar(eqs, S, d);
        end

        %% ================================================================
        %  DUALIDAD ONDA-PARTICULA
        %
        %  La seccion anterior le puso momentum a una onda; esta le pone
        %  longitud de onda a una particula. Es la misma relacion, lam = h/p,
        %  leida al reves.
        %
        %  POR QUE NO SE VE. Para una pelota de 0.1 kg a 10 m/s, lam sale
        %  6.6e-34 m: treinta ordenes de magnitud abajo de cualquier rendija
        %  que puedas construir. Para un electron a 1e6 m/s sale 7e-10 m, del
        %  tamano de un atomo, y ahi si difracta contra un cristal.
        %% ================================================================

        function [eqs, S] = ecBroglie()
            % SISTEMA - longitud de onda de De Broglie.
            % Formulas (7) a (10) de la seccion Dualidad.
            % NO RELATIVISTA: vale mientras v sea chica frente a c.
            %
            % VARIABLES:
            %   lam  longitud de onda de De Broglie           [m]
            %   m    masa de la particula                     [kg]
            %   v    velocidad                                [m/s]
            %   p    momentum                                 [kg*m/s]
            %   K    energia cinetica                         [J]
            %   q    carga de la particula, MAGNITUD          [C]
            %   Vab  diferencia de potencial que la acelera   [V]

            nom = {'lam','m','v','p','K','q','Vab'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            lam = S.lam; m = S.m; v = S.v; p = S.p; K = S.K; q = S.q;
            Vab = S.Vab;

            h = FV.ctes().h;

            eqs = [ p   == m*v
                lam == h/p                        % (7)
                K   == p^2/(2*m)                  % (8)
                p   == sqrt(2*m*q*Vab) ];         % (9)

            % LA (10) NO ESTA PORQUE YA ESTA. lam = h/sqrt(2*m*qe*Vab) es la
            % (7) con la (9) metida adentro: el sistema la arma solo cuando
            % le pasas m, q y Vab.
            %
            % K = p^2/(2*m) ES LA CLASICA, la misma (1/2)*m*v^2 escrita con
            % momentum. Por eso este sistema NO sirve a velocidades
            % relativistas: ahi K es ET - E0 (FV.ecRel) y lam = h/p sigue
            % valiendo pero con el p relativista, que no es m*v.
            % Regla practica: si v pasa de 0.1*c, cambiate a FV.ecRel para el
            % momentum y usa lam = h/p a mano.
            %
            % Vab ACELERA, NO FRENA. Aca la particula GANA K = q*Vab (sale de
            % combinar las dos ultimas). Es el mismo producto que en el
            % potencial de frenado del fotoelectrico, con el signo al reves.
            %
            % PARA UN ION DE CARGA MULTIPLE, q es la carga total: un ion 2+
            % lleva q = 2*1.6e-19, no 1.6e-19.
        end

        function [eqs, S] = ecIncert()
            % SISTEMA - principio de incertidumbre de Heisenberg.
            % Formulas (2), (3) y (4) de la seccion Dualidad.
            %
            % VARIABLES:
            %   dx  incertidumbre en la posicion              [m]
            %   dp  incertidumbre en el momentum              [kg*m/s]
            %   dt  incertidumbre en el tiempo (vida media)   [s]
            %   dE  incertidumbre en la energia               [J]

            nom = {'dx','dp','dt','dE'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            dx = S.dx; dp = S.dp; dt = S.dt; dE = S.dE;

            hbar = FV.ctes().hbar;

            eqs = [ dx*dp == hbar/2                % (2)
                dt*dE == hbar/2 ];                 % (4)

            % EL FORMULARIO ESCRIBE >=, ACA HAY =. La desigualdad no se puede
            % despejar: dx*dp >= hbar/2 admite infinitos valores. Lo que
            % resuelve este sistema es el CASO LIMITE, la incertidumbre
            % MINIMA, que es justo lo que piden los problemas ("la minima
            % incertidumbre en la velocidad", "el ancho minimo de la linea").
            % Cualquier medicion real da igual o MAS que esto: el numero que
            % sale es una cota inferior, no una prediccion.
            %
            % LAS DOS ECUACIONES NO SE TOCAN. No comparten ninguna variable,
            % asi que estan juntas por tema, no porque se relacionen: podes
            % pasarle solo dx, o solo dt, y el resto queda sin determinar.
            %
            % hbar CONTRA h/(2*pi). El formulario lista hbar = 1.055e-34 y
            % ademas dice hbar = h/(2*pi), que con su propio h = 6.63e-34 da
            % 1.055197e-34. Difieren 0.019%, invisible en cualquier respuesta.
            % Aca se usa el valor listado.
            %
            % dp NO ES p. Es cuanto puede VARIAR el momentum, no su valor. El
            % enunciado suele darte "la velocidad se conoce con un 1% de
            % error": eso es dv = 0.01*v, y de ahi dp = m*dv.
        end

        function [eqs, S] = ecRendija()
            % SISTEMA - difraccion por una rendija de ancho a.
            % Formulas (1), (5) y (6) de la seccion Dualidad.
            %
            % VARIABLES:
            %   lam  longitud de onda                         [m]
            %   a    ancho de la rendija                      [m]
            %   th1  angulo del primer minimo, APROXIMADO     [rad]
            %   th   angulo del primer minimo, EXACTO         [rad]
            %   ym   posicion del minimo m-esimo en la pantalla [m]
            %   X    distancia de la rendija a la pantalla    [m]
            %   m    orden del minimo, 1, 2, 3...             [-]

            nom = {'lam','a','th1','th','ym','X','m'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            lam = S.lam; a = S.a; th1 = S.th1; th = S.th; ym = S.ym;
            X = S.X; m = S.m;

            eqs = [ th1 == lam/a                  % (1)
                sin(th) == lam/a                  % (6)
                ym  == X*m*lam/a ];               % (5)

            % th1 Y th SON EL MISMO ANGULO CALCULADO DE DOS FORMAS, y por eso
            % son dos variables distintas. La (1) es la aproximacion de
            % angulo chico (sin(x) ~ x, en RADIANES); la (6) es exacta.
            % Compararlas te dice si la aproximacion sirve: con lam/a = 0.1
            % difieren 0.17%, con lam/a = 0.5 ya difieren 8%.
            % Si lam/a > 1 no hay minimo y la (6) devuelve un asin complejo:
            % no es un bug, es que la rendija es mas angosta que la onda.
            %
            % EL WARNING DE "th tiene 2 soluciones" ES ESPERADO. Despejar
            % th de un seno da dos angulos, th y pi-th, y los dos son
            % soluciones legitimas de la ecuacion. El motor toma el primero,
            % que es el chico, que es el que corresponde. No lo ignores en
            % otros sistemas, pero aca es normal.
            %
            % m ES EL ORDEN DEL MINIMO, no una masa. En esta seccion no hay
            % masas; el formulario usa m en la (5) y se respeta.
            %
            % ym MIDE DESDE EL CENTRO de la pantalla, y tambien es de angulo
            % chico: sale de ym = X*tan(th) ~ X*sin(th) = X*m*lam/a. Con X
            % grande frente a ym, que es el caso normal, la aproximacion
            % aguanta.
            %
            % ESTO ES UNA RENDIJA, NO UNA RED. Los minimos van con lam/a; los
            % maximos de una red van con d*sin(th) = n*lam, que es
            % FV.ecRed. Estan separadas a proposito: usar una por la otra da
            % un numero perfectamente creible y equivocado.
        end

        function [eqs, S] = ecRed()
            % SISTEMA - red de difraccion (maximos de interferencia).
            % Formula (11) de la seccion Dualidad.
            %
            % VARIABLES:
            %   d    separacion entre rendijas o entre planos [m]
            %   th   angulo del maximo de orden n             [rad]
            %   n    orden del maximo, 1, 2, 3...             [-]
            %   lam  longitud de onda                         [m]

            nom = {'d','th','n','lam'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            d = S.d; th = S.th; n = S.n; lam = S.lam;

            eqs = d*sin(th) == n*lam;             % (11)

            % UNA SOLA ECUACION, y va en sistema aparte igual. Meterla con la
            % rendija compartiendo th ataria dos experimentos distintos: la
            % red da MAXIMOS donde la rendija da MINIMOS.
            %
            % SI DESPEJAS th SALTA EL WARNING de dos soluciones: el seno da
            % th y pi-th. El motor toma el chico, que es el que va.
            %
            % d SE DA CASI SIEMPRE COMO LINEAS POR MILIMETRO. Con 600
            % lineas/mm, d = 1e-3/600 = 1.667e-6 m. La conversion va antes de
            % entrar, no adentro del sistema.
            %
            % ES TAMBIEN LA LEY DE BRAGG en la forma que trae el formulario,
            % con d la separacion entre planos del cristal. Ahi es donde se
            % usa para difractar electrones y comprobar De Broglie: medis th,
            % sacas lam, y la comparas con h/p.
            %
            % n TIENE TECHO: sin(th) <= 1 obliga a n <= d/lam. Si pedis un
            % orden mas alto, th sale complejo. Es fisica, no un error.
        end

        function res = broglie(varargin)
            % DESPEJE - longitud de onda de De Broglie.
            %   r = FV.broglie('m',9.11e-31, 'v',1e6);              double(r.lam)
            %   r = FV.broglie('m',9.11e-31, 'q',1.6e-19, 'Vab',100); double(r.lam)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecBroglie();
            res = FV.despejar(eqs, S, d);
        end

        function res = incert(varargin)
            % DESPEJE - incertidumbre minima de Heisenberg.
            %   r = FV.incert('dx',1e-10);   double(r.dp)
            %   r = FV.incert('dt',1e-8);    FV.J2eV(double(r.dE))
            d = FV.datos(varargin);
            [eqs, S] = FV.ecIncert();
            res = FV.despejar(eqs, S, d);
        end

        function res = rendija(varargin)
            % DESPEJE - difraccion por una rendija.
            %   r = FV.rendija('lam',500e-9, 'a',0.1e-3);  rad2deg(double(r.th))
            %   r = FV.rendija('lam',500e-9, 'a',0.1e-3, 'X',2, 'm',1); double(r.ym)
            d = FV.datos(varargin);
            [eqs, S] = FV.ecRendija();
            res = FV.despejar(eqs, S, d);
        end

        function res = red(varargin)
            % DESPEJE - red de difraccion o ley de Bragg.
            %   r = FV.red('d',1e-3/600, 'n',1, 'lam',589e-9); rad2deg(double(r.th))
            d = FV.datos(varargin);
            [eqs, S] = FV.ecRed();
            res = FV.despejar(eqs, S, d);
        end

        %% ================================================================
        %  MODELO ATOMICO DE BOHR
        %
        %  Vale para el HIDROGENO y para iones de un solo electron. Con dos
        %  electrones o mas, estas formulas no sirven.
        %
        %  Van dos sistemas separados y no uno:
        %    FV.ecBohr   una orbita sola: radio, velocidad, energias del
        %                nivel n
        %    FV.ecBohrT  una TRANSICION entre dos niveles y el foton que sale
        %  Juntarlos obligaria a que En signifique dos cosas a la vez (la
        %  energia del nivel y la del nivel inicial de un salto).
        %
        %  LAS CONSTANTES DEL FORMULARIO ESTAN REDONDEADAS, Y SE NOTA ACA.
        %  Este tema combina h, me, qe, eps0 y R en la misma expresion, y los
        %  redondeos no se cancelan entre si. Con los valores del formulario:
        %    eps0*h^2/(pi*me*qe^2) = 5.3096e-11 m, contra el 5.29e-11 m que
        %    cita la formula (14): 0.37% de diferencia
        %    me*qe^4/(eps0^2*8*h^2) = 2.1677e-18 J = 13.548 eV, contra
        %    h*c*R = 2.1804e-18 J = 13.628 eV de la formula (18): 0.59%
        %  Por eso los sistemas usan SOLO las formas algebraicas y no los
        %  numeros citados: entre ellas cierran exacto y el motor no aborta.
        %  Si tu profe pide 13.6 eV o 5.29e-11 m, usa esos numeros a mano; la
        %  diferencia con lo que sale de aca es de decimas de porciento.
        %% ================================================================

        function [eqs, S] = ecBohr()
            % SISTEMA - una orbita del modelo de Bohr.
            % Formulas (13) a (18) del formulario.
            %
            % VARIABLES:
            %   Z   numero atomico del nucleo               [-]
            %   n   numero cuantico principal, 1, 2, 3...     [-]
            %   rn  radio de la orbita n                      [m]
            %   vn  velocidad del electron en la orbita n     [m/s]
            %   Ln  momento angular de la orbita n            [J*s]
            %   Kn  energia cinetica del electron             [J]
            %   Un  energia potencial electrostatica          [J]
            %   En  energia total del nivel n                 [J]

            nom = {'Z','n','rn','vn','Ln','Kn','Un','En'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            Z = S.Z; n = S.n; rn = S.rn; vn = S.vn; Ln = S.Ln;
            Kn = S.Kn; Un = S.Un; En = S.En;

            C = FV.ctes(); h = C.h; me = C.me; qe = C.qe; eps0 = C.eps0;

            % sym(pi) y NO pi pelado: con pi doble, la expresion se congela
            % como la fraccion binaria de ese double y las identidades entre
            % rn, Ln y Un dejan de ser DEMOSTRABLES. isAlways las da por
            % falsas y despejar aborta con datos perfectamente buenos.
            dpi = sym(pi);

            eqs = [ rn == eps0*n^2*h^2/(dpi*me*qe^2*Z)    % (14) con Z
                vn == Z*qe^2/(eps0*2*n*h)                 % (15) con Z
                Ln == me*vn*rn                            % (13)
                Ln == n*h/(2*dpi)                         % (13), hbar = h/2pi
                Kn == me*vn^2/2                           % (16)
                Kn == me*Z^2*qe^4/(eps0^2*8*n^2*h^2)      % (16) con Z
                Un == -Z*qe^2/(4*dpi*eps0*rn)             % (17) con Z
                Un == -me*Z^2*qe^4/(eps0^2*4*n^2*h^2)     % (17) con Z
                En == Kn + Un
                En == -me*Z^2*qe^4/(eps0^2*8*n^2*h^2) ];  % (18) con Z

            % Z NO ESTA EN EL FORMULARIO. Es una extension. El formulario
            % escribe el modelo para el hidrogeno, que es Z = 1; con la carga
            % del nucleo puesta como Z*qe, las mismas formulas valen para
            % cualquier ion de UN SOLO electron: Z=1 hidrogeno, Z=2 He+,
            % Z=3 Li2+. Con dos electrones o mas NO SIRVE: la repulsion entre
            % ellos no esta en ninguna de estas ecuaciones, y el error no es
            % chico ni avisa.
            %
            % LAS ENERGIAS VAN CON Z^2 Y LOS RADIOS CON 1/Z. El He+ tiene el
            % cuadruple de energia de ligadura y la mitad de radio que el
            % hidrogeno. La velocidad va con Z: el electron del He+ orbita al
            % doble de rapido.
            %
            % Ln NO DEPENDE DE Z, y no es casualidad: en me*vn*rn la Z de vn
            % se cancela contra la de rn, exactamente. Por eso Ln == n*h/(2pi)
            % sigue valiendo igual, y sirve de control de que la Z entro bien
            % en las dos.
            %
            % LAS FORMAS REPETIDAS SON A PROPOSITO, y cierran EXACTO entre si
            % (verificado): las constantes se cancelan algebraicamente, asi
            % que el redondeo no las separa. Cada par habilita una direccion
            % distinta:
            %   Ln == me*vn*rn        va de la orbita hacia Ln
            %   Ln == n*h/(2*dpi)     deja entrar por Ln para sacar n
            %   Kn, Un, En cerradas   dejan entrar por una energia sin
            %                         conocer vn ni rn
            % La que sobra en cada corrida queda de CONTROL: si los datos no
            % cierran, despejar aborta en vez de mentir.
            %
            % SI ENTRAS POR UNA ENERGIA O POR rn, n SALE CON SIGNO. Esas
            % ecuaciones tienen n al cuadrado, asi que hay dos raices; el
            % motor toma la primera y avisa con un warning. Tomale el valor
            % absoluto: n es un entero positivo.
            %
            % En ES NEGATIVA Y ESO ESTA BIEN. El cero de energia es el
            % electron libre y quieto, infinitamente lejos. Estar ligado al
            % nucleo es estar por debajo de ese cero. |En| es la energia de
            % IONIZACION desde el nivel n: lo que hay que darle para
            % arrancarlo.
            %
            % En = Kn + Un CON Un = -2*Kn. La energia potencial pesa el doble
            % que la cinetica y con signo opuesto, por eso el total queda
            % negativo y vale exactamente -Kn. Es el teorema del virial, y
            % sirve de chequeo mental rapido.
            %
            % rn CRECE COMO n^2 Y vn CAE COMO 1/n. Las orbitas de arriba son
            % mucho mas grandes y mucho mas lentas: r5 es 25 veces r1.
        end

        function [eqs, S] = ecBohrT()
            % SISTEMA - transicion entre dos niveles y el foton emitido.
            % Formulas (12) y (18) del formulario.
            %
            % VARIABLES:
            %   Z    numero atomico del nucleo                [-]
            %   ni   nivel INICIAL, el de arriba              [-]
            %   nf   nivel FINAL, el de abajo                 [-]
            %   Ei   energia del nivel inicial                [J]
            %   Ef   energia del nivel final                  [J]
            %   E    energia del foton emitido                [J]
            %   lam  longitud de onda del foton               [m]
            %   nu   frecuencia del foton                     [Hz]

            nom = {'Z','ni','nf','Ei','Ef','E','lam','nu'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                nom', 1);
            Z = S.Z; ni = S.ni; nf = S.nf; Ei = S.Ei; Ef = S.Ef;
            E = S.E; lam = S.lam; nu = S.nu;

            C = FV.ctes(); c = C.c; h = C.h; me = C.me; qe = C.qe;
            eps0 = C.eps0;

            eqs = [ Ei == -me*Z^2*qe^4/(eps0^2*8*ni^2*h^2)   % (18) con Z
                Ef == -me*Z^2*qe^4/(eps0^2*8*nf^2*h^2)       % (18) con Z
                E  == Ei - Ef                            % (12)
                E  == h*c/lam                            % (12)
                E  == h*nu ];                            % (13)

            % Z ES EL MISMO DE FV.ecBohr, con las mismas limitaciones: solo
            % iones de un electron. Como las dos energias van con Z^2, el
            % salto entero escala con Z^2 y la longitud de onda con 1/Z^2:
            % la misma transicion 2->1 que en hidrogeno cae en el ultravioleta
            % lejano, en He+ cae cuatro veces mas corta.
            %
            % EMISION: ni > nf, y E sale POSITIVA. El electron cae y el atomo
            % suelta un foton.
            % ABSORCION: si le pasas ni < nf, E sale negativa. No es un error
            % del sistema: es la senal de que invertiste los niveles. El
            % modulo es la energia del foton que hay que ABSORBER para hacer
            % ese salto.
            %
            % Ei > Ef AUNQUE LAS DOS SEAN NEGATIVAS. En = -X/n^2 con X > 0:
            % cuanto mas grande n, menos negativa la energia. El nivel 3
            % (-1.5 eV) esta ARRIBA del nivel 1 (-13.5 eV). Comparar por
            % modulo en vez de por signo es el error tipico y da la
            % transicion al reves.
            %
            % LA SERIE LA DECIDE nf: nf = 1 es Lyman (ultravioleta), nf = 2
            % es Balmer (la unica visible), nf = 3 es Paschen (infrarrojo).
            %
            % IONIZAR ES ni -> infinito. El sistema no admite infinito; para
            % eso usa En de FV.ecBohr con el nivel de partida y toma |En|.
        end

        function res = bohr(varargin)
            % DESPEJE - una orbita del modelo de Bohr.
            %   r = FV.bohr('n',3,'Z',1);     double(r.rn), FV.J2eV(double(r.En))
            %   r = FV.bohr('n',1,'Z',2);     % He+, cuatro veces mas ligado
            %   r = FV.bohr('En',FV.eV2J(-3.4),'Z',1);  abs(double(r.n))
            d = FV.datos(varargin);
            d = FV.zPorDefecto(d);
            [eqs, S] = FV.ecBohr();
            res = FV.despejar(eqs, S, d);
        end

        function res = bohrT(varargin)
            % DESPEJE - transicion entre niveles y foton emitido.
            %   r = FV.bohrT('ni',3, 'nf',2, 'Z',1);   double(r.lam)
            %   r = FV.bohrT('nf',2, 'lam',656e-9, 'Z',1);  abs(double(r.ni))
            d = FV.datos(varargin);
            d = FV.zPorDefecto(d);
            [eqs, S] = FV.ecBohrT();
            res = FV.despejar(eqs, S, d);
        end

        %% ================================================================
        %  MOTOR
        %  Lo que traduce los datos y resuelve. No es fisica: es el mismo
        %  par datos/despejar de VM.m, MM.m e IE.m.
        %% ================================================================

        function d = zPorDefecto(d)
            % Pone Z = 1 cuando no lo pasaste. Z = 1 es el hidrogeno, que es
            % el unico caso que trae el formulario, asi que el caso comun
            % sigue entrando corto: FV.bohr('n',3) sigue significando lo
            % mismo que antes de que Z existiera.
            % Se pone ACA y no como valor por defecto adentro del sistema
            % porque las ecuaciones no tienen valores por defecto: son
            % relaciones. El default es una decision de la interfaz.
            if ~isfield(d, 'Z'), d.Z = 1; end
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
                error('FV:parInvalido', ...
                    ['Se esperaban pares nombre-valor (cantidad par de ' ...
                    'argumentos) o un struct. Llegaron %d.'], n);
            end

            % Impares = nombres, pares = valores. 1:2:end recorre 1,3,5...
            % Se indexa con () y no con {}: el resultado sigue siendo cell.
            nombres = args(1:2:end);
            valores = args(2:2:end);

            if ~all(cellfun(@(c) ischar(c) || isstring(c), nombres))
                error('FV:parInvalido', ...
                    ['Los argumentos impares tienen que ser nombres. ' ...
                    'Ej: FV.fe(''lam'',400e-9, ''fi'',3.2e-19)']);
            end

            s = cell2struct(valores(:), cellstr(string(nombres(:))), 1);
        end

        function res = despejar(eqs, S, d)
            % MOTOR de despeje. Lo usan todos los wrappers de esta clase.
            % ENTRADAS:
            %   eqs : sistema simbolico (de FV.ecRel, FV.ecFE, ...)
            %   S   : diccionario de simbolos del MISMO sistema
            %   d   : struct con SOLO lo que conoces, en cualquier orden
            % SALIDA:
            %   res : struct con TODAS las variables que quedaron
            %         determinadas. Para numero: double(res.lam).
            %
            % NO SE PIDE UNA INCOGNITA: la sustitucion hacia adelante
            % determina todo lo que los datos permitan en la misma pasada,
            % asi que pedir una sola escondia el resto.
            %
            % POR QUE NO ES UN solve() PELADO: solve(eqs,x) exige que TODAS
            % las ecuaciones se satisfagan eligiendo unicamente x. Como los
            % sistemas tienen incognitas intermedias (gam, E, p...), cualquier
            % ecuacion que no contenga x lo vuelve insatisfacible y solve
            % devuelve VACIO aunque los datos alcancen de sobra.
            % Aca se hace SUSTITUCION HACIA ADELANTE, que es el metodo a
            % mano: se busca una ecuacion con una sola incognita, se despeja,
            % se propaga, y se repite.
            %
            % ES EL MISMO MOTOR QUE VM.despejar, MM.despejar E IE.despejar,
            % COPIADO A PROPOSITO: cada carpeta tiene que funcionar sola.
            % Precio: un bug aca hay que arreglarlo en los cuatro archivos.

            campos = fieldnames(d);

            for k = 1:numel(campos)
                if ~isfield(S, campos{k})
                    error('FV:campoDesconocido', ...
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
                            error('FV:datosContradictorios', ...
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
                        % con los radicales y los cuadrados (v en gamma, n en
                        % Bohr) cuando entras al reves.
                        warning('FV:variasSoluciones', ...
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
