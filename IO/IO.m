classdef IO
    % IO — Caja de herramientas de Investigación de Operaciones.
    %      Todos los métodos son estáticos: se llaman IO.nombre(...).
    %
    % CONVENCIONES DE LA CLASE
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

    end
end
