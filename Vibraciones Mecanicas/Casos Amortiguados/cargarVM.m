function cargarVM()
% CARGARVM Agrega al path las carpetas necesarias para usar VM y Motor.
%   Esta función permite que cualquier script dentro de este subfolder
%   pueda llamar a las clases VM y Motor sin problemas de ruta.
%
%   Uso:
%       cargarVM();

    subfolderActual = fileparts(mfilename('fullpath'));
    dirVM   = fullfile(subfolderActual, '..');        % Carpeta 'Vibraciones Mecanicas' (VM.m)
    dirRepo = fullfile(subfolderActual, '..', '..');  % Raíz del repositorio (Motor.m)

    if isempty(which('VM'))
        addpath(dirVM);
    end
    if isempty(which('Motor'))
        addpath(dirRepo);
    end
end
