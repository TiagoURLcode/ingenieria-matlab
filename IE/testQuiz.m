classdef testQuiz < matlab.unittest.TestCase
    % TESTQUIZ Motor del quiz. Solo toca las funciones PURAS (elegir,
    % registrar) y el banco; nada de disco, para no pisar el historial
    % real de quizIE_estado.mat.
    %   runtests('testQuiz')

    properties
        B
        E0
    end

    methods (TestMethodSetup)
        function preparar(tc)
            tc.B  = bancoIE();
            tc.E0 = struct('aciertos', struct(), 'errores', struct(), ...
                'vistas', 0);
        end
    end

    methods (Test)

        function bancoCompleto(tc)
            tc.verifyEqual(numel(tc.B), 72);
            tc.verifyEqual(numel(quizIE('temas')), 6);
        end

        function filtraPorTema(tc)
            for r = 1:20
                k = quizIE('elegir', tc.B, tc.E0, 'Autotransformador', ...
                    'aleatorio', 0);
                tc.verifyEqual(tc.B(k).tema, 'Autotransformador');
            end
        end

        function noRepiteLaAnterior(tc)
            previo = 7;
            for r = 1:30
                k = quizIE('elegir', tc.B, tc.E0, 'todos', 'aleatorio', previo);
                tc.verifyNotEqual(k, previo);
            end
        end

        function temaInexistenteAvisa(tc)
            tc.verifyError(@() quizIE('elegir', tc.B, tc.E0, 'Turbinas', ...
                'aleatorio', 0), 'IE:sinPreguntas');
        end

        function registrarCuentaBienAciertoYError(tc)
            E = quizIE('registrar', tc.E0, 't1p01', true);
            E = quizIE('registrar', E,     't1p01', true);
            E = quizIE('registrar', E,     't1p02', false);
            tc.verifyEqual(E.aciertos.t1p01, 2);
            tc.verifyEqual(E.errores.t1p02, 1);
            tc.verifyFalse(isfield(E.errores, 't1p01'));
            tc.verifyEqual(E.vistas, 3);
        end

        function modoFalladasSoloTraeLasFalladas(tc)
            % Con dos preguntas falladas, el modo de repaso no puede
            % devolver ninguna otra.
            E = quizIE('registrar', tc.E0, 't3p05', false);
            E = quizIE('registrar', E,     't6p09', false);
            for r = 1:30
                k = quizIE('elegir', tc.B, E, 'todos', 'falladas', 0);
                tc.verifyTrue(ismember(tc.B(k).id, {'t3p05','t6p09'}), ...
                    sprintf('devolvio %s, que no estaba fallada', tc.B(k).id));
            end
        end

        function modoFalladasSinFallosCaeEnAleatorio(tc)
            % Sin errores registrados el repaso no puede quedarse mudo:
            % devuelve una pregunta cualquiera en vez de fallar.
            k = quizIE('elegir', tc.B, tc.E0, 'todos', 'falladas', 0);
            tc.verifyGreaterThanOrEqual(k, 1);
            tc.verifyLessThanOrEqual(k, numel(tc.B));
        end

        function lasBanderasTraenAdvertencia(tc)
            % La regla de autoridad: la pregunta con bandera conserva la
            % respuesta del cuestionario como correcta Y trae el texto de
            % la advertencia. Si una bandera quedara sin texto, el quiz
            % calificaria mal sin avisar por que.
            m = find([tc.B.bandera]);
            tc.verifyNotEmpty(m);
            for j = m
                tc.verifyGreaterThanOrEqual(tc.B(j).correcta, 1);
                tc.verifyLessThanOrEqual(tc.B(j).correcta, 4);
                tc.verifyNotEmpty(strtrim(tc.B(j).advertencia));
            end
        end

        function lasNoMarcadasNoTraenAdvertencia(tc)
            sinB = find(~[tc.B.bandera]);
            for j = sinB(1:10:end)
                tc.verifyEmpty(strtrim(tc.B(j).advertencia));
            end
        end

    end
end
