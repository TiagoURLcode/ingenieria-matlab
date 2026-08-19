classdef sp
    % sp — Caja de herramientas de análisis algebraico de POSICIONES.
    %      Todos los métodos son estáticos: se llaman sp.nombre(...).
    %      Alcance de esta versión: los cinco sistemas de la presentación
    %      "Análisis algebraico de posiciones de mecanismos".
    %
    % LOS CINCO SISTEMAS
    %   sp.sisAC   análisis de COORDENADAS, cuatro barras
    %   sp.sisL4B  LAZO VECTORIAL, cuatro barras
    %   sp.sisMC   MANIVELA-CORREDERA   (entra la manivela, sale la corredera)
    %   sp.sisCM   CORREDERA-MANIVELA   (entra la corredera, sale la manivela)
    %   sp.sisCI   manivela-corredera INVERTIDO (corredera sobre el eslabón 4)
    % Ninguno resuelve nada: cada uno devuelve [eqs, S], el sistema simbólico
    % y su diccionario de símbolos. El que resuelve es sp.resolver.
    %
    % CONVENCIONES DE TODA LA CLASE
    %   - SISTEMA COHERENTE. No hay conversión de unidades adentro. Las cuatro
    %     longitudes van en la MISMA unidad; cuál sea da igual, porque todas
    %     las ecuaciones son razones o sumas de longitudes. Lo que no se
    %     negocia es no mezclar: a en mm con d en m no da error, da basura.
    %   - ÁNGULOS EN RADIANES, siempre. cos y sin de MATLAB trabajan en rad.
    %     Para entrar en grados: deg2rad(theta). Para leer: rad2deg(theta).
    %   - ÁNGULOS MEDIDOS desde el eje X global (GCS), positivos antihorario,
    %     cada uno en el extremo INICIAL de su vector de posición.
    %   - DOS SOLUCIONES POR SISTEMA. Todos los mecanismos de este análisis
    %     tienen dos ensambles posibles para el mismo ángulo de entrada, y
    %     por eso cada símbolo de salida viene duplicado: t41 y t42, t31 y
    %     t32. No es un error numérico ni una raíz espuria: las dos son
    %     posiciones físicas reales, y cuál corre depende de cómo se armó
    %     el mecanismo. El código NO elige por vos.
    %   - DISCRIMINANTE NEGATIVO = los eslabones no se pueden conectar con
    %     ese ángulo de entrada. La raíz sale compleja conjugada y MATLAB
    %     devuelve un complejo sin quejarse. Si un resultado tiene parte
    %     imaginaria, la respuesta no es "redondeá": es que ese mecanismo no
    %     se ensambla en esa posición.
    %
    % NOMENCLATURA COMÚN (misma unidad de longitud, ángulos en rad)
    %   a     longitud de la manivela, eslabón 2
    %   b     longitud del acoplador, eslabón 3
    %   c     longitud del balancín, eslabón 4. En los mecanismos de
    %         corredera es la EXCENTRICIDAD (offset del eje de deslizamiento)
    %   d     longitud de la bancada, eslabón 1. En sisMC y sisCM es la
    %         POSICIÓN de la corredera, que ahí es variable, no dato fijo
    %   t2    ángulo de entrada theta2                                  [rad]
    %   t3    ángulo del acoplador theta3                               [rad]
    %   t4    ángulo del balancín theta4                                [rad]
    %   g     ángulo gamma entre el eslabón 4 y el eje de deslizamiento [rad]
    %         (solo sisCI)
    %
    % OJO CON LAS MAYÚSCULAS
    %   MATLAB distingue mayúsculas de minúsculas, y las láminas usan las dos
    %   cosas a la vez: b es el ACOPLADOR y B es un COEFICIENTE del sistema
    %   cuadrático; lo mismo c contra C y d contra D. Pasar 'B' donde iba 'b'
    %   no da error, da otro resultado. Se respetó la notación de las láminas
    %   a propósito, porque es la que vas a tener en el parcial.
    %
    % LO QUE NO ESTÁ
    %   Velocidades y aceleraciones como sistema propio. No hacen falta:
    %   pasándole t2 = w*t a datosSis, la salida ya queda en función del
    %   tiempo y se deriva con diff. Ver ejemplo.m.

    methods(Static)

        %% ===================================================================
        %  sisAC — ANÁLISIS DE COORDENADAS, mecanismo de cuatro barras.
        %  Ubica la junta B (acoplador-balancín) por geometría analítica:
        %  B está sobre el círculo de radio b centrado en A y sobre el de
        %  radio c centrado en O4. Igualar los dos círculos deja una
        %  cuadrática en By, y de ahí salen los ángulos.
        %
        %  Entra: a, b, c, d, t2.   Sale: By1/By2, Bx1/Bx2, t31/t32, t41/t42.
        %
        %  Las láminas NO dicen cuál raíz es la abierta y cuál la cruzada en
        %  este método (sí lo dicen en sisL4B). Por eso acá se numeran 1 y 2
        %  y no se les pone nombre: para saber cuál es cuál hay que dibujar
        %  las dos y mirar si los eslabones 3 y 4 se cruzan.
        %
        %  Salidas:
        %    eqs : vector simbólico con el sistema, sin resolver.
        %    S   : struct-diccionario. S.By1 es el SÍMBOLO By1, no un valor.
        %          Es indispensable devolverlo: cada llamada a sym() crea
        %          objetos nuevos, así que una By1 declarada afuera NO es la
        %          misma By1 que está dentro de eqs. Usando S siempre pegan.
        %
        %  EJEMPLO DE USO
        %    r = sp.datosSis('AC', 'a',40,'b',120,'c',80,'d',100,'t2',pi/4);
        %    double(r.t41)
        %% ===================================================================
        function [eqs, S] = sisAC()

            % sym() y NO syms: dentro de un método, syms falla si el nombre
            % choca con una función existente del path. Acá pasa con varios:
            % 'S' y 'T' no molestan, pero 'P' y 'Q' sí tienen usos en MATLAB.
            % sym('P') crea el símbolo igual y nunca colisiona.
            nom = {'a','b','c','d','t2','Ax','Ay','S','P','Q','R','disc', ...
                   'By1','By2','Bx1','Bx2','t31','t32','t41','t42'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            a = S.a; b = S.b; c = S.c; d = S.d; t2 = deg2rad(S.t2);
            Ax = S.Ax; Ay = S.Ay; P = S.P; Q = S.Q; R = S.R; disc = S.disc;
            By1 = S.By1; By2 = S.By2; Bx1 = S.Bx1; Bx2 = S.Bx2;
            t31 = S.t31; t32 = S.t32; t41 = S.t41; t42 = S.t42;

            % Sc y no S: el struct-diccionario ya se llama S, y las láminas
            % también llaman S a un coeficiente. Pisar el struct con el
            % coeficiente rompería todo lo que viene después.
            Sc = S.S;

            % == (doble igual) en contexto simbólico construye una ECUACIÓN,
            % no una comparación lógica. Con = simple sería una asignación.
            eqs = [ Ax   == a*cos(t2)                    % junta A: x
                    Ay   == a*sin(t2)                    % junta A: y
                    Sc   == (a^2 - b^2 + c^2 - d^2)/(2*(Ax - d))
                    P    == Ay^2/(Ax - d)^2 + 1          % coef. cuadrático
                    Q    == 2*Ay*(d - Sc)/(Ax - d)       % coef. lineal
                    R    == (d - Sc)^2 - c^2             % término independiente
                    disc == Q^2 - 4*P*R                  % discriminante
                    By1  == (-Q - sqrt(disc))/(2*P)      % raíz con radical (-)
                    By2  == (-Q + sqrt(disc))/(2*P)      % raíz con radical (+)
                    Bx1  == Sc - Ay*By1/(Ax - d)
                    Bx2  == Sc - Ay*By2/(Ax - d)
                    t31  == atan2(By1 - Ay, Bx1 - Ax)
                    t32  == atan2(By2 - Ay, Bx2 - Ax)
                    t41  == atan2(By1, Bx1 - d)
                    t42  == atan2(By2, Bx2 - d) ];

            % POR QUÉ atan2 Y NO atan
            %   atan(y/x) devuelve solo entre -pi/2 y +pi/2: colapsa los
            %   cuatro cuadrantes en dos. atan2(y, x) recibe el numerador y
            %   el denominador POR SEPARADO, así conserva los dos signos y
            %   devuelve el ángulo entre -pi y +pi, en el cuadrante correcto.
            %   Las láminas escriben tan^-1(...) por costumbre de libro, pero
            %   avisan expresamente que hay que usar el arcotangente de dos
            %   argumentos. Con atan pelado, media vuelta de la manivela sale
            %   con el balancín apuntando al revés.
            %
            % LA CUADRÁTICA EN By
            %   P*By^2 + Q*By + R = 0 sale de restar las ecuaciones de los dos
            %   círculos: la resta elimina los términos cuadráticos y deja Bx
            %   en función lineal de By (esa es la relación Bx == Sc - ...),
            %   y al reemplazarla en un círculo queda todo en By.
            %   Sc es el bloque que se repite en esa cuenta; está aparte para
            %   no escribirlo cuatro veces.
            %
            % DIVISIÓN POR (Ax - d)
            %   Sc, P y Q dividen por Ax - d, que se anula cuando la junta A
            %   queda justo encima de O4 (a*cos(t2) == d). Ahí este método
            %   revienta con Inf o NaN aunque el mecanismo esté perfectamente
            %   armado: es una limitación del planteo en coordenadas, no del
            %   mecanismo. sp.sisL4B no tiene ese problema.
        end

        %% ===================================================================
        %  sisL4B — LAZO VECTORIAL, eslabonamiento de cuatro barras.
        %  Los cuatro eslabones se escriben como vectores de posición que
        %  cierran el lazo: R2 + R3 - R4 - R1 = 0. Separar esa suma en
        %  componentes x e y y eliminar un ángulo por vez deja dos
        %  cuadráticas independientes, una en tan(t4/2) y otra en tan(t3/2).
        %
        %  Entra: a, b, c, d, t2.   Sale: t41/t42 y t31/t32.
        %
        %  Según las láminas: el radical NEGATIVO da la configuración ABIERTA
        %  y el POSITIVO la CRUZADA, en los dos ángulos.
        %  Un mecanismo de Grashof es cruzado si los dos eslabones adyacentes
        %  al más corto se cruzan entre sí, y abierto si no.
        %
        %  Salidas: [eqs, S], igual que sisAC.
        %% ===================================================================
        function [eqs, S] = sisL4B()

            nom = {'a','b','c','d','t2','K1','K2','K3','K4','K5', ...
                   'A','B','C','D','E','F','t31','t32','t41','t42'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            a = S.a; b = S.b; c = S.c; d = S.d; t2 = S.t2;
            K1 = S.K1; K2 = S.K2; K3 = S.K3; K4 = S.K4; K5 = S.K5;
            A = S.A; B = S.B; C = S.C; D = S.D; E = S.E; F = S.F;
            t31 = S.t31; t32 = S.t32; t41 = S.t41; t42 = S.t42;

            eqs = [ K1  == d/a
                    K2  == d/c
                    K3  == (a^2 - b^2 + c^2 + d^2)/(2*a*c)
                    K4  == d/b
                    K5  == (c^2 - d^2 - a^2 - b^2)/(2*a*b)

                    % Cuadrática en tan(t4/2): A*x^2 + B*x + C = 0
                    A   == cos(t2) - K1 - K2*cos(t2) + K3
                    B   == -2*sin(t2)
                    C   == K1 - (K2 + 1)*cos(t2) + K3

                    % Cuadrática en tan(t3/2): D*x^2 + E*x + F = 0
                    D   == cos(t2) - K1 + K4*cos(t2) + K5
                    E   == -2*sin(t2)
                    F   == K1 + (K4 - 1)*cos(t2) + K5

                    t41 == 2*atan((-B - sqrt(B^2 - 4*A*C))/(2*A))   % abierta
                    t42 == 2*atan((-B + sqrt(B^2 - 4*A*C))/(2*A))   % cruzada
                    t31 == 2*atan((-E - sqrt(E^2 - 4*D*F))/(2*D))   % abierta
                    t32 == 2*atan((-E + sqrt(E^2 - 4*D*F))/(2*D)) ];% cruzada

            % LAS CONSTANTES K
            %   K1, K2 y K3 juntan todo lo que NO depende de t2 en la cuenta
            %   de t4; K1, K4 y K5 hacen lo mismo para t3. Se calculan una
            %   sola vez por mecanismo y se reusan en toda la vuelta de la
            %   manivela: por eso están separadas de A...F, que sí cambian
            %   con cada t2. K1 aparece en las dos porque es d/a, la razón
            %   bancada-manivela, común a los dos despejes.
            %
            % POR QUÉ APARECE tan(theta/2) Y NO theta DIRECTO
            %   La ecuación de cierre mezcla cos(t4) y sin(t4), que no se
            %   despejan juntos. La sustitución de medio ángulo
            %   (cos t = (1-x^2)/(1+x^2), sin t = 2x/(1+x^2) con x = tan(t/2))
            %   convierte esa mezcla en un POLINOMIO de segundo grado en x.
            %   Por eso el resultado sale como 2*atan(x): primero se despeja
            %   x, y recién después se vuelve al ángulo.
            %
            % A == 0
            %   Si A se anula la cuadrática degenera en lineal y la fórmula
            %   divide por cero. Es un caso de borde geométrico, no un error
            %   de tipeo: ahí el mecanismo pasa por una posición donde el
            %   planteo de medio ángulo no sirve.
        end

        %% ===================================================================
        %  sisMC — MANIVELA-CORREDERA, impulsado por la MANIVELA.
        %  Misma cadena que el de cuatro barras, pero el eslabón 4 se volvió
        %  una corredera: su ángulo t4 está FIJO (el eje de deslizamiento) y
        %  lo que varía es d, la posición de la corredera. c es la
        %  excentricidad: la distancia del eje de deslizamiento a O2.
        %
        %  Entra: a, b, c, t2.   Sale: t31/t32 y d1/d2.
        %
        %  Este es el único de los cinco que NO genera una cuadrática: la
        %  componente y del lazo despeja t3 directo con un arcoseno.
        %
        %  CUÁL ES CUÁL: calculá d con cada t3. La ABIERTA deja la corredera
        %  del lado extendido; la CRUZADA la manda al lado opuesto de O2.
        %  Por eso d1 y d2 están en el sistema: sin ellas no se distingue.
        %
        %  Salidas: [eqs, S], igual que sisAC.
        %% ===================================================================
        function [eqs, S] = sisMC()

            nom = {'a','b','c','t2','t31','t32','d1','d2'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            a = S.a; b = S.b; c = S.c; t2 = S.t2;
            t31 = S.t31; t32 = S.t32; d1 = S.d1; d2 = S.d2;

            eqs = [ t31 ==  asin((a*sin(t2) - c)/b)          % abierta
                    t32 == -asin((a*sin(t2) - c)/b) + pi     % cruzada
                    d1  == a*cos(t2) - b*cos(t31)            % corredera, abierta
                    d2  == a*cos(t2) - b*cos(t32) ];         % corredera, cruzada

            % DE DÓNDE SALE EL ARCOSENO
            %   La componente y del lazo es a*sin(t2) - b*sin(t3) - c = 0.
            %   Ahí t3 aparece SOLO en un seno, sin coseno que lo acompañe,
            %   así que se despeja de una: sin(t3) = (a*sin(t2) - c)/b.
            %   Eso es lo que hace distinto a este mecanismo: la corredera
            %   fija t4, y con un ángulo menos la ecuación deja de mezclar.
            %
            % LAS DOS RAMAS DEL ARCOSENO
            %   asin devuelve solo entre -pi/2 y +pi/2, pero sin(t) y
            %   sin(pi - t) valen lo mismo: el arcoseno pierde la mitad de las
            %   soluciones. La segunda se recupera a mano con pi - asin(...),
            %   que es lo que dice la segunda ecuación. Las dos son ensambles
            %   físicos reales, no una la buena y otra la falsa.
            %
            % ARGUMENTO FUERA DE [-1, 1]
            %   Si (a*sin(t2) - c)/b se pasa de 1 en valor absoluto, asin
            %   devuelve un COMPLEJO. Significa que con esa excentricidad la
            %   manivela no alcanza a cerrar la cadena en ese ángulo.
        end

        %% ===================================================================
        %  sisCM — CORREDERA-MANIVELA, impulsado por la CORREDERA.
        %  Misma geometría que sisMC, al revés: el dato es d (dónde está la
        %  corredera) y la incógnita es t2 (dónde quedó la manivela). Es el
        %  mecanismo del pistón: cada cilindro de un motor de combustión.
        %
        %  Entra: a, b, c, d.   Sale: t21/t22 y t31/t32.
        %
        %  ATENCIÓN — LO QUE SEPARA EL +- ACÁ NO ES ABIERTA Y CRUZADA.
        %  Las dos raíces son las dos RAMAS DEL MISMO CIRCUITO. El circuito
        %  (abierto o cruzado) queda fijado por el SIGNO DE d que entra; las
        %  ramas se separan en los puntos muertos. Es la diferencia con
        %  sisL4B y hay que tenerla clara.
        %
        %  PUNTOS MUERTOS: las ecuaciones fallan en el punto muerto superior
        %  y en el inferior. Por eso un motor de pistones necesita arranque y
        %  un volante de inercia en el cigüeñal: hace falta momento angular
        %  guardado para cruzar los dos puntos muertos de cada vuelta.
        %
        %  Salidas: [eqs, S], igual que sisAC.
        %% ===================================================================
        function [eqs, S] = sisCM()

            nom = {'a','b','c','d','K1','K2','K3','A','B','C', ...
                   't21','t22','t31','t32'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            a = S.a; b = S.b; c = S.c; d = S.d;
            K1 = S.K1; K2 = S.K2; K3 = S.K3;
            A = S.A; B = S.B; C = S.C;
            t21 = S.t21; t22 = S.t22; t31 = S.t31; t32 = S.t32;

            eqs = [ K1  == a^2 - b^2 + c^2 + d^2
                    K2  == -2*a*c
                    K3  == -2*a*d

                    % Cuadrática en tan(t2/2): A*x^2 + B*x + C = 0
                    A   == K1 - K3
                    B   == 2*K2
                    C   == K1 + K3

                    t21 == 2*atan((-B + sqrt(B^2 - 4*A*C))/(2*A))   % rama 1
                    t22 == 2*atan((-B - sqrt(B^2 - 4*A*C))/(2*A))   % rama 2

                    t31 == asin(-(a*sin(t21) - c)/b) + pi
                    t32 == asin(-(a*sin(t22) - c)/b) + pi ];

            % LAS K DE ACÁ NO SON LAS DE sisL4B
            %   Mismo nombre, otra cosa. En sisL4B las K son razones
            %   adimensionales (d/a, d/c); acá son sumas de longitudes al
            %   cuadrado y tienen unidades. Comparten letra porque las dos
            %   láminas las llaman K, nada más.
            %
            % EL t3 PUEDE NECESITAR LA OTRA RAMA
            %   Las dos últimas ecuaciones usan la forma con + pi, que es la
            %   que traen las láminas. No siempre es la correcta: según el
            %   circuito puede corresponder el arcoseno pelado, sin el + pi.
            %   La verificación es a mano y es una sola cuenta:
            %       d == a*cos(t2) - b*cos(t3)
            %   Probá con el t3 que salió; si no reproduce el d que metiste,
            %   la buena es la otra rama. No está puesta como ecuación del
            %   sistema a propósito: si estuviera, el caso legítimo en que
            %   corresponde la otra rama abortaría con datosContradictorios
            %   en vez de dejarte comparar.
        end

        %% ===================================================================
        %  sisCI — MANIVELA-CORREDERA INVERTIDO.
        %  La corredera no desliza sobre la bancada sino sobre el ESLABÓN 4,
        %  que gira. El eje de deslizamiento forma un ángulo gamma constante
        %  con el eslabón 4. Consecuencia: el acoplador b NO es constante,
        %  es la longitud efectiva que va cambiando; por eso b es SALIDA acá
        %  y no dato de entrada.
        %
        %  Entra: a, c, d, t2, g.   Sale: t41/t42, t31/t32, b1/b2.
        %
        %  Según las láminas: el radical NEGATIVO da la ABIERTA y el POSITIVO
        %  la CRUZADA, y la relación entre ángulos cambia con la
        %  configuración:  abierta t3 = t4 + g;  cruzada t3 = t4 + g - pi.
        %
        %  Pero ojo con el movimiento: la configuración la termina de decidir
        %  el SIGNO DE b, no el signo del radical. Un b negativo es la
        %  corredera del otro lado de la junta.
        %
        %  Salidas: [eqs, S], igual que sisAC.
        %% ===================================================================
        function [eqs, S] = sisCI()

            nom = {'a','c','d','t2','g','P','Q','R','S','T','U', ...
                   't41','t42','t31','t32','b1','b2'};
            S   = cell2struct(cellfun(@sym, nom, 'UniformOutput', false)', ...
                              nom', 1);
            a = S.a; c = S.c; d = S.d; t2 = S.t2; g = S.g;
            P = S.P; Q = S.Q; R = S.R; T = S.T; U = S.U;
            t41 = S.t41; t42 = S.t42; t31 = S.t31; t32 = S.t32;
            b1 = S.b1; b2 = S.b2;

            % Sc y no S, por lo mismo que en sisAC: S ya es el diccionario.
            Sc = S.S;

            eqs = [ P   == a*sin(t2)*sin(g) + (a*cos(t2) - d)*cos(g)
                    Q   == -a*sin(t2)*cos(g) + (a*cos(t2) - d)*sin(g)
                    R   == -c*sin(g)

                    % Cuadrática en tan(t4/2): Sc*x^2 + T*x + U = 0
                    Sc  == R - Q
                    T   == 2*P
                    U   == Q + R

                    t41 == 2*atan((-T - sqrt(T^2 - 4*Sc*U))/(2*Sc))  % abierta
                    t42 == 2*atan((-T + sqrt(T^2 - 4*Sc*U))/(2*Sc))  % cruzada

                    t31 == t41 + g                                   % abierta
                    t32 == t42 + g - pi                              % cruzada

                    b1  == (a*sin(t2) - c*sin(t41))/sin(t31)
                    b2  == (a*sin(t2) - c*sin(t42))/sin(t32) ];

            % POR QUÉ P, Q Y R Y NO LAS K
            %   Son el mismo truco que las K de sisL4B —juntar los bloques que
            %   se repiten— pero acá NO se pueden calcular una sola vez por
            %   mecanismo: dependen de t2, así que se recalculan en cada
            %   posición. Por eso llevan otra letra.
            %
            % gamma == 0
            %   R == -c*sin(g) se anula con gamma nulo, y con él Sc y U. Ahí
            %   la cuadrática degenera. Gamma nulo significa que el eje de
            %   deslizamiento es el propio eslabón 4, o sea que el mecanismo
            %   ya no es el invertido sino otro.
            %
            % b COMO SALIDA
            %   b1 y b2 dividen por sin(t3). Cuando el acoplador queda
            %   horizontal el seno se anula y la longitud efectiva se dispara
            %   a Inf: es la posición donde la corredera se alinea con la
            %   bancada y el mecanismo se traba.
        end

        %% ===================================================================
        %  sistema — Traduce el NOMBRE de un método al sistema que le toca.
        %  Es la pieza que le permite a sp.datosSis servir a los cinco
        %  mecanismos sin escribir una función de despeje para cada uno.
        %
        %    metodo : texto. 'AC', 'L4B', 'MC', 'CM' o 'CI'. Se acepta en
        %             minúscula y también el nombre largo.
        %
        %  Agregar un mecanismo nuevo es tocar un solo lugar: escribir su
        %  sisXXX y sumarle un case acá.
        %% ===================================================================
        function [eqs, S] = sistema(metodo)
            if ~(ischar(metodo) || isstring(metodo))
                error('sp:metodoInvalido', ...
                    'El método se pasa como texto. Ej: sp.sistema(''L4B'')');
            end

            % lower() para que 'l4b' y 'L4B' entren igual; char() porque
            % switch compara distinto contra string de comillas dobles.
            switch lower(char(metodo))
                case {'ac','coordenadas'},      [eqs, S] = sp.sisAC();
                case {'l4b','lazo'},            [eqs, S] = sp.sisL4B();
                case {'mc','manivelacorredera'},[eqs, S] = sp.sisMC();
                case {'cm','correderamanivela'},[eqs, S] = sp.sisCM();
                case {'ci','invertido'},        [eqs, S] = sp.sisCI();
                otherwise
                    error('sp:metodoInvalido', ...
                        ['"%s" no es un método de esta clase. ' ...
                         'Válidos: AC, L4B, MC, CM, CI.'], char(metodo));
            end
        end

        %% ===================================================================
        %  datos — Traduce los argumentos de entrada a un struct de datos.
        %  Es la pieza que le permite a datosSis aceptar las dos formas de
        %  llamada sin repetir el parseo.
        %
        %    args : cell array (el varargin de quien llama). Se acepta
        %           {structDeDatos}  o  {'nombre',valor, 'nombre',valor, ...}
        %
        %  Escribir struct() a mano no agrega información: el nombre del
        %  campo ya va entre comillas. Los pares nombre-valor son la
        %  convención de MATLAB (plot('LineWidth',1.5) es exactamente esto).
        %  El struct NO se elimina porque a veces el dato YA es un struct.
        %% ===================================================================
        function s = datos(args)
            n = numel(args);

            if n == 1 && isstruct(args{1})
                s = args{1};
                return
            end
            if n == 0 || mod(n,2) ~= 0
                error('sp:parInvalido', ...
                    ['Se esperaban pares nombre-valor (cantidad par de ' ...
                     'argumentos) o un struct. Llegaron %d.'], n);
            end

            % Impares = nombres, pares = valores. 'end' dentro de un índice
            % significa "el último", así que 1:2:end recorre 1,3,5...
            % Se indexa con () y no con {}: el resultado sigue siendo cell.
            nombres = args(1:2:end);
            valores = args(2:2:end);

            % cellfun aplica la función a cada celda; con el @(c) de una
            % línea evita escribir un for de tres renglones.
            if ~all(cellfun(@(c) ischar(c) || isstring(c), nombres))
                error('sp:parInvalido', ...
                    ['Los argumentos impares tienen que ser nombres. ' ...
                     'Ej: sp.datosSis(''L4B'', ''a'',40, ''t2'',pi/4)']);
            end

            % cell2struct(valores, nombres, 1): el 1 dice que los campos se
            % arman recorriendo las FILAS del cell de nombres — por eso los
            % (:) que los ponen en columna. cellstr(string(...)) normaliza
            % "t2" (comillas dobles) y 't2' (simples) al mismo tipo.
            s = cell2struct(valores(:), cellstr(string(nombres(:))), 1);
        end

        %% ===================================================================
        %  resolver — Recorre la CADENA y devuelve todas las incógnitas.
        %  Lo usa datosSis.
        %
        %  Entradas:
        %    eqs : sistema simbólico (de cualquier sp.sisXXX)
        %    S   : diccionario de símbolos del MISMO sistema
        %    d   : struct con los datos de entrada
        %
        %  Salida:
        %    sol : struct con TODAS las variables del sistema, resueltas.
        %          sol.t41 y sol.t31, y también las intermedias (K1, A, B...).
        %          Para número: double(sol.t41).
        %
        %  POR QUÉ ALCANZA CON subs Y NO HACE FALTA solve:
        %    Cada renglón de un sisXXX tiene la forma
        %        símboloNuevo == expresión de los símbolos anteriores
        %    y los renglones están escritos en orden de dependencia. Con esa
        %    estructura no hay nada que despejar: el lado derecho YA es la
        %    fórmula. Una sola pasada sustituyendo cada símbolo por su
        %    expresión resuelve la cadena entera.
        %
        %  NO ES UN MOTOR DE DESPEJE, Y NO PRETENDE SERLO.
        %    Va en UNA dirección: de las longitudes y el ángulo de entrada
        %    hacia los ángulos de salida. Si querés la longitud que produce
        %    cierto theta4, esto no sirve.
        %    Un motor de sustitución hacia adelante como MM.despejar tampoco
        %    serviría, y está probado: se frena porque casi toda ecuación
        %    queda con dos o tres símbolos libres. La diferencia es de forma,
        %    no de tamaño. El modelo axial de MM es una MALLA de relaciones
        %    chicas y redundantes, donde se entra por cualquier lado; los
        %    sisXXX son una CADENA de un solo sentido.
        %
        %  VENTAJA SOBRE UN MOTOR DE DESPEJE: los datos pueden ser SIMBÓLICOS.
        %    Pasarle t2 = w*t deja la salida en función del tiempo, lista
        %    para derivar. Un motor que cuente símbolos libres se traba ahí,
        %    porque t y w le parecen incógnitas sin determinar.
        %% ===================================================================
        function sol = resolver(eqs, S, d)

            % fieldnames — devuelve los nombres de los campos del struct como
            % CELL ARRAY de texto: {'a'; 'b'; 't2'; ...}. Permite que la
            % función no sepa de antemano qué datos le van a pasar.
            campos = fieldnames(d);

            for k = 1:numel(campos)
                if ~isfield(S, campos{k})
                    error('sp:campoDesconocido', ...
                        ['"%s" no es una variable de este sistema. ' ...
                         'Válidas: %s'], campos{k}, strjoin(fieldnames(S)', ', '));
                end
                % campos{k}  -> LLAVES porque es cell array; da el texto 'a'.
                % S.(...)    -> acceso DINÁMICO a campo. S.a exige saber el
                %               nombre al escribir el código; S.('a') acepta
                %               el nombre como variable en ejecución.
                %               S.(campos{k}) = el SÍMBOLO
                %               d.(campos{k}) = el VALOR
                % subs reemplaza en TODAS las ecuaciones de una vez. El loop
                % es necesario: subs no recorre structs.
                eqs = subs(eqs, S.(campos{k}), d.(campos{k}));
            end

            % --- una sola pasada por la cadena ----------------------------
            sol = struct();
            for k = 1:numel(eqs)
                % lhs y rhs parten una ecuación simbólica en sus dos lados.
                % En el paso k, lhs(eqs(k)) todavía es el símbolo pelado y
                % rhs(eqs(k)) ya tiene sustituidos todos los anteriores: o
                % sea que ya es la expresión resuelta.
                sol.(char(lhs(eqs(k)))) = rhs(eqs(k));
                eqs = subs(eqs, lhs(eqs(k)), rhs(eqs(k)));   % propaga al resto
            end
        end


        %% ===================================================================
        %  datosSis — Atajo sobre CUALQUIERA de los cinco sistemas.
        %  El PRIMER argumento es el método; el resto son los datos, en pares
        %  nombre-valor o en un struct:
        %
        %    r = sp.datosSis('L4B', 'a',40,'b',120,'c',80,'d',100,'t2',pi/4)
        %    r = sp.datosSis('L4B', dat)            % dat = struct(...)
        %    r = sp.datosSis('CI',  'a',40,'c',30,'d',100,'t2',pi/4,'g',pi/3)
        %
        %  NO se pide una incógnita. La cadena resuelve TODAS las variables de
        %  una sola pasada, así que pedir una sería tirar el resto: elegís
        %  después, del struct que devuelve.
        %    double([r.t41 r.t42])     los dos ensambles del balancín
        %
        %  Los datos no tienen que ser números. Pasando t2 = w*t, con w y t
        %  simbólicos, la salida queda en función del tiempo y se deriva con
        %  diff para sacar velocidades y aceleraciones.
        %% ===================================================================
        function sol = datosSis(metodo, varargin)
            if nargin < 2
                error('sp:parInvalido', ...
                    ['Faltan argumentos: el método y los datos. Ej: ' ...
                     'sp.datosSis(''MC'', ''a'',40, ''b'',120, ''c'',0, ''t2'',pi/4)']);
            end
            d = sp.datos(varargin);

            [eqs, S] = sp.sistema(metodo);
            sol = sp.resolver(eqs, S, d);
        end

    end
end
