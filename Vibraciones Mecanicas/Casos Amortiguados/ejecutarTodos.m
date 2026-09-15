function ejecutarTodos()
%% EJECUTARTODOS Ejecuta todos los casos amortiguados en esta carpeta
% =========================================================================
% Corre secuencialmente los 9 scripts de Casos Amortiguados:
%   - ResorteMasaY.m (Segundo Parcial 2025)
%   - ImpactoPlastico.m (Tarea 2 - Prob 1)
%   - OscilogramaMotor.m (Tarea 2 - Prob 2)
%   - VagonTope.m (Tarea 2 - Prob 3)
%   - CanonRetroceso.m (Tarea 2 - Prob 4)
%   - BarraRigida.m (Tarea 2 - Prob 5)
%   - ResortesParalelo.m (Tarea 2 - Prob 6)
%   - SerieParalelo.m (Tarea 2 - Prob 7)
%   - DosResortes.m (Tarea 2 - Prob 8)
% =========================================================================

    subfolderActual = fileparts(mfilename('fullpath'));
    addpath(subfolderActual);
    cargarVM();

    archivos = {
        'ResorteMasaY.m'
        'ImpactoPlastico.m'
        'OscilogramaMotor.m'
        'VagonTope.m'
        'CanonRetroceso.m'
        'BarraRigida.m'
        'ResortesParalelo.m'
        'SerieParalelo.m'
        'DosResortes.m'
    };

    fprintf('=========================================================================\n');
    fprintf('          EJECUTOR DE CASOS AMORTIGUADOS (VIBRACIONES MECÁNICAS)         \n');
    fprintf('=========================================================================\n');

    for k = 1:numel(archivos)
        ruta = fullfile(subfolderActual, archivos{k});
        fprintf('\n>>> [%d/%d] Ejecutando %s...\n', k, numel(archivos), archivos{k});
        try
            evalin('base', sprintf('run(''%s'');', ruta));
            fprintf('>>> [OK] %s completado.\n', archivos{k});
        catch ME
            fprintf('>>> [ERROR] en %s: %s\n', archivos{k}, ME.message);
        end
    end

    fprintf('\n=========================================================================\n');
    fprintf('           TODOS LOS CASOS AMORTIGUADOS HAN SIDO EJECUTADOS              \n');
    fprintf('=========================================================================\n');
end
