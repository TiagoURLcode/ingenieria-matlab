classdef IO
    % IO — Caja de herramientas de Investigación de Operaciones.
    %      Todos los métodos son estáticos: se llaman IO.nombre(...).
    %
    % CONTENIDO
    %   Programación Lineal   pl2var, graficarPL
    %   Teoría de Colas       mms (M/M/s, y M/M/1 con s=1), mg1 (M/G/1),
    %                         mmsPn (probabilidad de n clientes),
    %                         mmsEspera (probabilidad de esperar mas de t)
    %
    % CONVENCIONES DE PROGRAMACIÓN LINEAL
    %   - Problemas de Programación Lineal con 2 variables (x1, x2).
    %   - Se asume SIEMPRE x1>=0, x2>=0 (no negatividad), además de las
    %     restricciones que el usuario entregue.
    %   - El método principal sigue el procedimiento gráfico clásico visto
    %     en clase:
    %       0. Analizar qué se solicita     (lo hace el usuario, no el código)
    %       1. Tabular datos                (los argumentos c, A, b)
    %       2. Definir variables de decisión
    %       3. Función objetivo
    %       4. Restricciones
    %       5. Graficar
    %       6. Región factible
    %       7. Vértices
    %       8. Evaluación de la función objetivo en los vértices
    %       9. Solución
    %
    % CONVENCIONES DE TEORÍA DE COLAS
    %   - SISTEMA COHERENTE DE TIEMPO. No hay conversión de unidades adentro
    %     de las funciones. lambda, mu y todos los tiempos t van en LA MISMA
    %     unidad; la salida (W, Wq) sale en esa unidad.
    %     Los dos laboratorios mezclan tasas por hora con tiempos de servicio
    %     en minutos, y ahí es donde se pierde el examen. La conversión se
    %     hace UNA vez, en la asignación, dejando el dato del enunciado al
    %     lado:
    %         lambda = 20;        % llegadas [clientes/h]  (20 por hora)
    %         mu     = 1/(1/3);   % servicio [clientes/h]  (1/mu = 20 min = 1/3 h)
    %         t      = 5/60;      % umbral de espera [h]   (5 min)
    %     Trabajar todo en minutos es igual de válido — lo que no se negocia
    %     es que lambda, mu y t compartan unidad.
    %   - ESTADO ESTABLE. Todas las fórmulas son de régimen permanente y
    %     exigen rho < 1. Con rho >= 1 las funciones abortan con el error
    %     IO:sistemaInestable en vez de devolver un número sin sentido.
    %   - DISCIPLINA FIFO, población y cola INFINITAS, llegadas de Poisson.

    methods(Static)

        %% ===================================================================
        %  pl2var — Programación Lineal, 2 variables, método gráfico.
        %
        %    sol = IO.pl2var(c, A, b, sentido, tipo)
        %    sol = IO.pl2var(c, A, b, sentido, tipo, 'Nombres', {'x1','x2'})
        %
        %  ENTRADAS
        %    c        : [c1 c2]  coeficientes de la función objetivo
        %                        U = c1*x1 + c2*x2
        %    A        : matriz m x 2, fila i = coeficientes [a_i1 a_i2]
        %               de la restricción i sobre (x1,x2)
        %    b        : vector m x 1, lado derecho de cada restricción
        %    sentido  : cell m x 1 con '<=', '>=' o '=' para cada fila de A
        %    tipo     : 'max' o 'min'
        %
        %  OPCIONES (par nombre/valor)
        %    'Nombres'  : cell {nombre_x1, nombre_x2}. Default {'x_1','x_2'}
        %    'Graficar' : true/false. Default true
        %    'Titulo'   : título del gráfico. Default 'Método gráfico'
        %
        %  SALIDA (struct sol)
        %    sol.vertices  : [n x 2] vértices de la región factible
        %    sol.valores   : [n x 1] función objetivo evaluada en cada vértice
        %    sol.iOpt      : índice del vértice óptimo dentro de sol.vertices
        %    sol.xOpt      : [x1 x2] óptimos
        %    sol.valorOpt  : valor óptimo de la función objetivo
        %
        %  MÉTODO: se intersecan TODOS los pares de restricciones (incluyendo
        %  x1>=0 y x2>=0), se descartan los puntos que violan alguna
        %  restricción y, de los que quedan (vértices de la región factible),
        %  se evalúa la función objetivo y se elige el mejor.
        %
        %  EJEMPLO — mesas y sillas (pizarrón):
        %    c = [50 80];                 % U = 50 x1 + 80 x2
        %    A = [1 2; 1 1];              % corte, ensamble
        %    b = [120; 90];
        %    sentido = {'<=','<='};
        %    sol = IO.pl2var(c, A, b, sentido, 'max', ...
        %                     'Nombres', {'Mesas','Sillas'});
        %% ===================================================================
        function sol = pl2var(c, A, b, sentido, tipo, varargin)

            p = inputParser;
            addParameter(p, 'Nombres',  {'x_1','x_2'});
            addParameter(p, 'Graficar', true);
            addParameter(p, 'Titulo',   'Método gráfico — Programación Lineal');
            parse(p, varargin{:});
            nombres  = p.Results.Nombres;
            graficar = p.Results.Graficar;
            titulo_  = p.Results.Titulo;

            c = c(:)'; b = b(:);
            tipo = validatestring(tipo, {'max','min'});
            assert(size(A,2)==2, 'A debe tener 2 columnas (x1, x2)');
            assert(size(A,1)==numel(b), 'A y b no tienen el mismo número de filas');
            assert(numel(sentido)==numel(b), 'sentido debe tener una entrada por restricción');

            %% 2-4: variables, función objetivo, restricciones (se listan)
            fprintf('--- Variables de decisión ---\n');
            fprintf('  %s, %s\n', nombres{1}, nombres{2});
            fprintf('--- Función objetivo ---\n');
            fprintf('%s: U = %.4g*%s + %.4g*%s\n', upper(tipo), c(1), nombres{1}, c(2), nombres{2});
            fprintf('--- Restricciones ---\n');
            for i = 1:numel(b)
                fprintf('  %.4g*%s + %.4g*%s %s %.4g\n', ...
                    A(i,1), nombres{1}, A(i,2), nombres{2}, sentido{i}, b(i));
            end
            fprintf('  %s, %s >= 0\n', nombres{1}, nombres{2});

            % Restricciones completas: usuario + no negatividad (x1>=0, x2>=0)
            A_full = [A; 1 0; 0 1];
            b_full = [b; 0; 0];
            s_full = [sentido(:); {'>='}; {'>='}];

            %% 6-7: intersección de cada par de restricciones -> candidatos a vértice
            m = size(A_full,1);
            candidatos = [];
            for i = 1:m-1
                for j = i+1:m
                    Aij = [A_full(i,:); A_full(j,:)];
                    if abs(det(Aij)) > 1e-9
                        pt = Aij \ [b_full(i); b_full(j)];
                        candidatos = [candidatos; pt']; %#ok<AGROW>
                    end
                end
            end

            % Filtrar factibles (cumplen TODAS las restricciones, con tolerancia)
            tol = 1e-7;
            esFactible = true(size(candidatos,1),1);
            for k = 1:size(candidatos,1)
                x = candidatos(k,:)';
                lhs = A_full*x;
                for i = 1:m
                    switch s_full{i}
                        case '<=', ok = lhs(i) <= b_full(i) + tol;
                        case '>=', ok = lhs(i) >= b_full(i) - tol;
                        case '=',  ok = abs(lhs(i)-b_full(i)) <= tol;
                    end
                    if ~ok, esFactible(k) = false; break; end
                end
            end
            vert = candidatos(esFactible,:);
            vert = uniquetol(vert, 1e-6, 'ByRows', true);

            assert(~isempty(vert), 'Región factible vacía: revisa las restricciones');

            %% 8: evaluar función objetivo en cada vértice
            valores = vert*c';

            switch tipo
                case 'max', [valorOpt, iOpt] = max(valores);
                case 'min', [valorOpt, iOpt] = min(valores);
            end
            xOpt = vert(iOpt,:);

            fprintf('\n--- Vértices y función objetivo ---\n');
            fprintf('   %-8s %-8s   U\n', nombres{1}, nombres{2});
            for k = 1:size(vert,1)
                marca = '';
                if k == iOpt, marca = '  <-- óptimo'; end
                fprintf('   %-8.4g %-8.4g   %-10.4g%s\n', vert(k,1), vert(k,2), valores(k), marca);
            end

            %% 9: solución
            fprintf('\n--- Solución ---\n');
            fprintf('%s = %.4g, %s = %.4g -> U %s = %.4g\n', ...
                nombres{1}, xOpt(1), nombres{2}, xOpt(2), tipo, valorOpt);

            sol.vertices = vert;
            sol.valores  = valores;
            sol.iOpt     = iOpt;
            sol.xOpt     = xOpt;
            sol.valorOpt = valorOpt;
            sol.A = A; sol.b = b; sol.sentido = sentido;
            sol.c = c; sol.tipo = tipo; sol.nombres = nombres;

            %% 5: graficar (restricciones, región factible, vértices, óptimo)
            if graficar
                IO.graficarPL(A, b, sentido, vert, xOpt, nombres, titulo_);
            end
        end

        %% ===================================================================
        %  graficarPL — Dibuja restricciones, región factible y vértices.
        %  Uso interno de IO.pl2var, pero puede llamarse aparte.
        %% ===================================================================
        function graficarPL(A, b, sentido, vert, xOpt, nombres, titulo_)

            figure; hold on; grid on; box on

            % Límites del gráfico: un poco más allá del intercepto más grande
            interc1 = b(A(:,1)~=0)./abs(A(A(:,1)~=0,1));
            interc2 = b(A(:,2)~=0)./abs(A(A(:,2)~=0,2));
            lim1 = max([vert(:,1); interc1; 1]) * 1.2;
            lim2 = max([vert(:,2); interc2; 1]) * 1.2;

            % Región factible sombreada (orden angular alrededor del centroide)
            cx = mean(vert(:,1)); cy = mean(vert(:,2));
            ang = atan2(vert(:,2)-cy, vert(:,1)-cx);
            [~, ord] = sort(ang);
            fill(vert(ord,1), vert(ord,2), [0.6 0.85 0.6], ...
                 'FaceAlpha', 0.4, 'EdgeColor', 'none', 'DisplayName', 'Región factible');

            % Rectas de cada restricción
            colores = lines(size(A,1));
            for i = 1:size(A,1)
                a1 = A(i,1); a2 = A(i,2);
                if a2 ~= 0
                    x1v = linspace(0, lim1, 2);
                    x2v = (b(i) - a1*x1v)/a2;
                else
                    x1v = [b(i)/a1, b(i)/a1];
                    x2v = [0, lim2];
                end
                plot(x1v, x2v, 'LineWidth', 1.6, 'Color', colores(i,:), ...
                     'DisplayName', sprintf('%.4g%s+%.4g%s%s%.4g', ...
                     a1, nombres{1}, a2, nombres{2}, sentido{i}, b(i)));
            end

            % Vértices
            plot(vert(:,1), vert(:,2), 'ko', 'MarkerFaceColor','k', 'MarkerSize', 5, ...
                 'DisplayName', 'Vértices');
            for k = 1:size(vert,1)
                text(vert(k,1), vert(k,2), sprintf('  (%.3g, %.3g)', vert(k,1), vert(k,2)), ...
                     'FontSize', 9);
            end

            % Óptimo resaltado
            plot(xOpt(1), xOpt(2), 'p', 'MarkerSize', 14, 'MarkerFaceColor', 'r', ...
                 'MarkerEdgeColor','r', 'DisplayName', 'Óptimo');

            xlim([0 lim1]); ylim([0 lim2]);
            xlabel(nombres{1}); ylabel(nombres{2});
            title(titulo_);
            legend('Location','bestoutside');
        end

        %% ===================================================================
        %  mms — Modelo M/M/s: llegadas de Poisson, tiempos de servicio
        %  EXPONENCIALES, s servidores en paralelo que atienden UNA sola cola.
        %  Con s = 1 es el modelo M/M/1: las fórmulas se reducen solas, no hay
        %  que llamar a otra función.
        %
        %    sol = IO.mms(lambda, mu, s)
        %    sol = IO.mms(lambda, mu, s, 'Verbose', false)
        %
        %  ENTRADAS
        %    lambda : tasa media de LLEGADAS       [clientes/unidad de tiempo]
        %    mu     : tasa media de SERVICIO DE UN SERVIDOR, mu = 1/(tiempo
        %             medio de servicio)           [clientes/unidad de tiempo]
        %    s      : cantidad de servidores en paralelo [-]
        %             lambda y mu van en la MISMA unidad de tiempo: si el
        %             enunciado da "2 llegadas por hora" y "20 minutos de
        %             servicio", mu = 3 por hora, no 1/20.
        %
        %  OPCIONES (par nombre/valor)
        %    'Verbose' : true/false, imprime el reporte. Default true
        %
        %  SALIDA (struct sol)
        %    sol.rho : factor de utilización, rho = lambda/(s*mu) [-]
        %              fracción del tiempo que un servidor está ocupado
        %    sol.r   : intensidad de tráfico, r = lambda/mu [-]
        %              cantidad media de servidores ocupados. OJO: r y rho
        %              solo coinciden si s = 1
        %    sol.P0  : probabilidad de que el sistema esté VACÍO [-]
        %    sol.L   : número medio de clientes EN EL SISTEMA [clientes]
        %    sol.Lq  : número medio de clientes EN LA COLA [clientes]
        %    sol.W   : tiempo medio EN EL SISTEMA (cola + servicio) [tiempo]
        %    sol.Wq  : tiempo medio EN LA COLA [tiempo]
        %
        %  DE DÓNDE SALEN
        %    P0 sale de exigir que todas las probabilidades sumen 1. La suma
        %    de n=0 a s-1 recorre los estados en los que TODAVÍA hay algún
        %    servidor libre; el término suelto de la derecha junta de una vez
        %    todos los estados n >= s, que forman una serie geométrica de
        %    razón rho (por eso hace falta rho < 1: si no, no converge).
        %    Lq sale de la cadena de Markov del modelo. Las otras tres son
        %    la LEY DE LITTLE, que vale para cualquier cola en estado estable:
        %      L = lambda*W       Lq = lambda*Wq       W = Wq + 1/mu
        %    Acá se usan como L = Lq + r y W = L/lambda, que es lo mismo.
        %
        %  EJEMPLO — banco con 2 cajeras, 40 clientes/h, 2 min por cliente:
        %    sol = IO.mms(40, 30, 2);     % mu = 60/2 = 30 clientes/h
        %% ===================================================================
        function sol = mms(lambda, mu, s, varargin)

            p = inputParser;
            addParameter(p, 'Verbose', true);
            parse(p, varargin{:});

            assert(isscalar(lambda) && lambda > 0, 'lambda debe ser un escalar positivo');
            assert(isscalar(mu)     && mu > 0,     'mu debe ser un escalar positivo');
            assert(isscalar(s) && s >= 1 && s == fix(s), 's debe ser un entero >= 1');

            r   = lambda/mu;        % servidores ocupados en promedio
            rho = lambda/(s*mu);    % utilización de CADA servidor

            if rho >= 1
                error('IO:sistemaInestable', ...
                    ['rho = %.4g >= 1: llega más trabajo del que los %d ' ...
                     'servidores pueden despachar, la cola crece sin límite ' ...
                     'y no hay estado estable que calcular. Revisá las ' ...
                     'unidades de lambda y mu antes que el enunciado.'], rho, s);
            end

            % n es un VECTOR 0,1,...,s-1: factorial y .^ trabajan elemento a
            % elemento, así que la sumatoria entra en una línea.
            n  = 0:s-1;
            P0 = 1/( sum(r.^n./factorial(n)) + r^s/(factorial(s)*(1-rho)) );

            % Misma Lq de la plantilla de Excel. La forma equivalente
            % Lq = P0*r^s*rho/(factorial(s)*(1-rho)^2) sale de reemplazar
            % (s*mu-lambda)^2 = s^2*mu^2*(1-rho)^2; se deja la de la
            % plantilla para poder comparar celda contra celda.
            Lq = lambda*mu*r^s*P0/(factorial(s-1)*(s*mu - lambda)^2);
            L  = Lq + r;
            Wq = Lq/lambda;
            W  = L/lambda;

            sol.lambda = lambda; sol.mu = mu; sol.s = s;
            sol.rho = rho; sol.r = r; sol.P0 = P0;
            sol.L = L; sol.Lq = Lq; sol.W = W; sol.Wq = Wq;

            if p.Results.Verbose
                fprintf('--- Modelo M/M/%d ---\n', s);
                fprintf('  lambda = %-10.4g mu = %-10.4g s = %d\n', lambda, mu, s);
                fprintf('  rho    = %-10.4g (utilización de cada servidor)\n', rho);
                fprintf('  P0     = %-10.4g (sistema vacío)\n', P0);
                fprintf('  L      = %-10.4g clientes en el sistema\n', L);
                fprintf('  Lq     = %-10.4g clientes en la cola\n', Lq);
                fprintf('  W      = %-10.4g unidades de tiempo en el sistema\n', W);
                fprintf('  Wq     = %-10.4g unidades de tiempo en la cola\n', Wq);
            end
        end

        %% ===================================================================
        %  mg1 — Modelo M/G/1: llegadas de Poisson, UN servidor, y tiempos de
        %  servicio de distribución GENERAL — cualquiera, con tal de conocer
        %  su media y su desviación estándar. Fórmula de Pollaczek-Khintchine.
        %
        %    sol = IO.mg1(lambda, mu, sigma)
        %    sol = IO.mg1(lambda, mu, sigma, 'Verbose', false)
        %
        %  ENTRADAS
        %    lambda : tasa media de LLEGADAS [clientes/unidad de tiempo]
        %    mu     : tasa media de SERVICIO, mu = 1/(tiempo medio de
        %             servicio) [clientes/unidad de tiempo]
        %    sigma  : DESVIACIÓN ESTÁNDAR del tiempo de servicio, en la misma
        %             unidad de TIEMPO que 1/mu (no una tasa)
        %
        %  SALIDA (struct sol): los mismos campos que IO.mms, con rho = lambda/mu.
        %
        %  LO QUE DICE LA FÓRMULA
        %    Lq = (lambda^2*sigma^2 + rho^2)/(2*(1-rho))
        %    La variabilidad del servicio entra SOLA, en el término
        %    lambda^2*sigma^2: dos sistemas con el mismo tiempo medio de
        %    servicio pero distinta sigma tienen colas distintas. Bajar sigma
        %    baja Lq sin tocar la velocidad promedio del servidor.
        %
        %  DOS CASOS PARTICULARES, útiles de control
        %    sigma = 1/mu -> servicio exponencial: da exactamente M/M/1
        %    sigma = 0    -> servicio DETERMINÍSTICO (M/D/1): Lq se reduce a
        %                    rho^2/(2*(1-rho)), la MITAD de la de M/M/1
        %
        %  EJEMPLO — soporte con 3 solicitudes/h y servicio de media 15 min
        %  con desviación de 5 min (todo en horas):
        %    sol = IO.mg1(3, 4, 5/60);
        %% ===================================================================
        function sol = mg1(lambda, mu, sigma, varargin)

            p = inputParser;
            addParameter(p, 'Verbose', true);
            parse(p, varargin{:});

            assert(isscalar(lambda) && lambda > 0, 'lambda debe ser un escalar positivo');
            assert(isscalar(mu)     && mu > 0,     'mu debe ser un escalar positivo');
            assert(isscalar(sigma)  && sigma >= 0, 'sigma debe ser un escalar >= 0');

            rho = lambda/mu;

            if rho >= 1
                error('IO:sistemaInestable', ...
                    ['rho = %.4g >= 1: el único servidor no da abasto, la ' ...
                     'cola crece sin límite y no hay estado estable que ' ...
                     'calcular. Revisá las unidades de lambda y mu antes ' ...
                     'que el enunciado.'], rho);
            end

            Lq = (lambda^2*sigma^2 + rho^2)/(2*(1 - rho));
            L  = Lq + rho;          % rho = r cuando s = 1
            Wq = Lq/lambda;         % Little
            W  = Wq + 1/mu;         % esperar + ser atendido
            P0 = 1 - rho;           % el servidor está libre

            sol.lambda = lambda; sol.mu = mu; sol.sigma = sigma; sol.s = 1;
            sol.rho = rho; sol.r = rho; sol.P0 = P0;
            sol.L = L; sol.Lq = Lq; sol.W = W; sol.Wq = Wq;

            if p.Results.Verbose
                fprintf('--- Modelo M/G/1 ---\n');
                fprintf('  lambda = %-10.4g mu = %-10.4g sigma = %.4g\n', lambda, mu, sigma);
                fprintf('  rho    = %-10.4g (utilización del servidor)\n', rho);
                fprintf('  P0     = %-10.4g (sistema vacío)\n', P0);
                fprintf('  L      = %-10.4g clientes en el sistema\n', L);
                fprintf('  Lq     = %-10.4g clientes en la cola\n', Lq);
                fprintf('  W      = %-10.4g unidades de tiempo en el sistema\n', W);
                fprintf('  Wq     = %-10.4g unidades de tiempo en la cola\n', Wq);
            end
        end

        %% ===================================================================
        %  mmsPn — Probabilidad de que haya EXACTAMENTE n clientes en el
        %  sistema (Pn) y de que haya MÁS de n (PmayorN), en un M/M/s.
        %
        %    [Pn, PmayorN] = IO.mmsPn(lambda, mu, s, n)
        %
        %  n puede ser un escalar o un VECTOR: la salida tiene la misma forma.
        %  "En el sistema" incluye a los que están siendo atendidos, no solo
        %  a los que hacen cola.
        %
        %  LOS DOS TRAMOS DE LA FÓRMULA
        %    n <= s : Pn = r^n*P0/n!            todavía hay servidores libres
        %    n >  s : Pn = r^n*P0/(s!*s^(n-s))  todos ocupados, los demás
        %                                       hacen cola y el sistema
        %                                       despacha a ritmo constante
        %    En n = s las dos coinciden, así que no hay salto.
        %
        %  PARA QUÉ SIRVE PmayorN: los enunciados piden cosas como "el
        %  porcentaje de tiempo en que hay más de 2 clientes" o "95% del
        %  tiempo no debe haber más de 4 en espera". Eso es P(N > n), que se
        %  calcula como 1 menos la suma de P0 hasta Pn.
        %
        %  EJEMPLO
        %    [Pn, Pmas] = IO.mmsPn(20, 30, 1, 0:2);
        %    Pmas(3)     % P(mas de 2 clientes en la caja)
        %% ===================================================================
        function [Pn, PmayorN] = mmsPn(lambda, mu, s, n)

            % Verbose false: acá interesan r y P0, no el reporte. La
            % validación y el corte por rho >= 1 los hace mms.
            base = IO.mms(lambda, mu, s, 'Verbose', false);
            r = base.r; P0 = base.P0;

            Pn      = zeros(size(n));
            PmayorN = zeros(size(n));

            for i = 1:numel(n)
                ni = n(i);
                assert(ni >= 0 && ni == fix(ni), 'n debe tener enteros >= 0');

                Pn(i) = IO.pnEstado(r, P0, s, ni);

                % P(N > n) = 1 - (P0 + P1 + ... + Pn). Se suma explícito y no
                % con la forma cerrada de la geométrica para que valga igual
                % en los dos tramos de la fórmula.
                acum = 0;
                for j = 0:ni
                    acum = acum + IO.pnEstado(r, P0, s, j);
                end
                PmayorN(i) = 1 - acum;
            end
        end

        %% ===================================================================
        %  mmsEspera — Probabilidad de que un cliente que llega espere MÁS de
        %  t, en un M/M/s. Dos versiones, que responden preguntas distintas:
        %
        %    [PW, PWq] = IO.mmsEspera(lambda, mu, s, t)
        %
        %    PW  = P(W  > t) : tiempo total en el sistema, cola MÁS servicio
        %                      ("...antes de TERMINAR su servicio")
        %    PWq = P(Wq > t) : tiempo en la cola solamente
        %                      ("...antes de INICIAR su servicio")
        %
        %  t va en la misma unidad de tiempo que 1/lambda y 1/mu, y puede ser
        %  un vector.
        %
        %  C DE ERLANG: el factor P0*r^s/(s!*(1-rho)) que aparece en las dos
        %  es la probabilidad de que un cliente que llega encuentre TODOS los
        %  servidores ocupados, o sea de que tenga que hacer cola. Es lo mismo
        %  que 1 - (P0+P1+...+P_{s-1}), que es como lo escribe la plantilla de
        %  Excel; acá se usa la forma cerrada, que da idéntico.
        %
        %  EL CASO s-1-r = 0 es una división 0/0 en la fórmula general: ahí se
        %  usa su límite, que cambia el cociente por mu*t. No es un caso raro,
        %  cae justo cuando r es entero (por ejemplo s = 2 con r = 1).
        %
        %  EJEMPLO — probabilidad de esperar más de 5 min (en horas):
        %    [PW, PWq] = IO.mmsEspera(20, 30, 1, 5/60);
        %% ===================================================================
        function [PW, PWq] = mmsEspera(lambda, mu, s, t)

            base = IO.mms(lambda, mu, s, 'Verbose', false);
            r = base.r; rho = base.rho; P0 = base.P0;

            C = P0*r^s/(factorial(s)*(1 - rho));    % C de Erlang

            PWq = C*exp(-s*mu*(1 - rho)*t);

            d = s - 1 - r;
            if abs(d) < 1e-12
                PW = exp(-mu*t).*(1 + C*mu*t);                      % límite
            else
                PW = exp(-mu*t).*(1 + C*(1 - exp(-mu*t*d))/d);
            end

            % CONTROL con s = 1: la expresión de arriba se reduce a
            % exp(-mu*(1-rho)*t), la fórmula conocida del M/M/1.
        end

        %% ===================================================================
        %  pnEstado — Pn de UN solo estado n. Uso interno de mmsPn y de
        %  cualquier suma acumulada. Se separa para no repetir el corte entre
        %  los dos tramos de la fórmula en dos lugares distintos.
        %
        %  Recibe r y P0 ya calculados (no lambda y mu) para no recalcular P0
        %  en cada término de una sumatoria.
        %% ===================================================================
        function P = pnEstado(r, P0, s, n)
            if n <= s
                P = r^n*P0/factorial(n);
            else
                P = r^n*P0/(factorial(s)*s^(n - s));
            end
        end

    end
end
