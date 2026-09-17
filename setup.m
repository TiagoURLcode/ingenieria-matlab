function setup()
% setup — pone la raiz del repo en el path de MATLAB, en forma PERMANENTE.
% Correr UNA vez, parado en esta carpeta:
%   >> setup
%
% Hace falta porque Motor.m vive en la raiz y las cinco clases (VM, sp, IE,
% FV, MM) lo llaman sin prefijo de ruta. Sin esto, cada una tendria que
% agregar la raiz a mano en cada sesion.
%
% QUE HACE: agrega la carpeta de este archivo al path con savepath, asi
% queda para todas las sesiones futuras, no solo la actual. No agrega
% subcarpetas (no hace falta: cada materia se corre parada en su propia
% carpeta, y MATLAB ya busca en el directorio actual antes que en el path).
%
% SI savepath FALLA (permisos sobre pathdef.m): agrega esta linea a tu
% startup.m, con la ruta de ESTA carpeta:
%   addpath('/home/Tiago/Documentos/MATLAB');

raiz = fileparts(mfilename('fullpath'));
addpath(raiz);

ok = savepath();
if ok == 0
    fprintf('Listo: %s quedo en el path para todas las sesiones.\n', raiz);
else
    warning('setup:noPersistio', ...
        ['No se pudo guardar el path (savepath fallo, revisa permisos). ' ...
         'Agrega esta linea a tu startup.m:\n  addpath(''%s'');'], raiz);
end
end
