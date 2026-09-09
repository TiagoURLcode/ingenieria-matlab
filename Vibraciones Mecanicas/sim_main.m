function sim_main(modo)
% SIM_MAIN - menu de los simuladores de la Tarea 2, vibraciones amortiguadas.
%
% USO:
%   sim_main             % abre el menu
%   sim_main('exportar') % corre el modo exportar de los ocho, sin menu
%
% Cada fila abre un simulador distinto. Se pueden tener varios abiertos a la
% vez: cada uno vive en su propia figura con su propio timer, y cerrar el
% menu no los cierra.
%
% QUE HACE CADA BOTON
%   Abrir     lanza el simulador en modo interactivo
%   Exportar  corre su modo 'exportar': render fijo con los valores del
%             enunciado, mas GIF y PNG en ./figs/, sin abrir ventana
%
% ESTE ARCHIVO NO CALCULA NADA. Es un lanzador: no toca VM.m, no evalua
% ninguna ecuacion y no conoce ningun valor de los problemas. Toda la
% fisica vive en VM.m y cada simulador la pide desde ahi.

    if nargin < 1, modo = ''; end

    % ---------------------------------------------------------------------
    % CATALOGO. Una fila por problema:
    %   {funcion, numero, titulo corto, que se ve en la animacion}
    % El orden es el del enunciado, no el de dificultad.
    % ---------------------------------------------------------------------
    S = {
      'sim1_impactoPlastico',  '1', 'Impacto plastico',      'dos bloques que quedan unidos'
      'sim2_oscilogramaMotor', '2', 'Oscilograma del motor', 'ajuste contra los picos leidos'
      'sim3_vagonTope',        '3', 'Vagon contra el tope',  'vagon que comprime el conjunto'
      'sim4_canonRetroceso',   '4', 'Retroceso del canon',   'canon que vuelve a bateria'
      'sim5_barraRigida',      '5', 'Barra rigida sobre A',  'barra que pivota, B y D'
      'sim6_resortesParalelo', '6', 'Dos resortes paralelo', 'masa sobre ruedas'
      'sim7_serieParalelo',    '7', 'Serie y paralelo',      'nodo entre los dos resortes'
      'sim8_dosResortes',      '8', 'Un resorte por lado',   'masa entre dos resortes'
      };

    if strcmp(modo,'exportar')
        exportarTodos(S);
        return
    end

    % ---------------------------------------------------------------------
    % FIGURA DEL MENU
    % ---------------------------------------------------------------------
    n = size(S,1);
    fig = figure('Name','Tarea 2 - Vibraciones amortiguadas', ...
        'NumberTitle','off','Color','w','MenuBar','none','ToolBar','none', ...
        'Position',[200 150 660 100+58*n]);
    theme(fig,'light');   % fuerza tema claro; si no, con MATLAB en modo
                          % oscuro los paneles salen negros

    uicontrol('Parent',fig,'Style','text', ...
        'String','Tarea 2 - Vibraciones libres amortiguadas', ...
        'Units','normalized','Position',[0.03 0.92 0.94 0.06], ...
        'FontSize',13,'FontWeight','bold','BackgroundColor','w', ...
        'HorizontalAlignment','left');

    uicontrol('Parent',fig,'Style','text', ...
        'String',['Toda la fisica sale de VM.m. Los valores de referencia ' ...
                  'solo aparecen con el boton Revelar de cada simulador.'], ...
        'Units','normalized','Position',[0.03 0.875 0.94 0.045], ...
        'FontSize',9,'BackgroundColor','w','ForegroundColor',[0.40 0.40 0.40], ...
        'HorizontalAlignment','left');

    % Una fila por simulador. El alto de fila se reparte en el espacio que
    % queda debajo del encabezado y encima del pie.
    y0 = 0.845;   % borde superior de la primera fila [normalizado]
    hf = 0.083;   % alto de cada fila
    for i = 1:n
        y = y0 - i*hf;

        uicontrol('Parent',fig,'Style','text','String',S{i,2}, ...
            'Units','normalized','Position',[0.03 y 0.05 0.055], ...
            'FontSize',14,'FontWeight','bold','BackgroundColor','w', ...
            'ForegroundColor',[0.00 0.30 0.65]);

        uicontrol('Parent',fig,'Style','text','String',S{i,3}, ...
            'Units','normalized','Position',[0.09 y+0.012 0.30 0.045], ...
            'FontSize',10,'FontWeight','bold','BackgroundColor','w', ...
            'HorizontalAlignment','left');

        uicontrol('Parent',fig,'Style','text','String',S{i,4}, ...
            'Units','normalized','Position',[0.40 y+0.012 0.32 0.045], ...
            'FontSize',9,'BackgroundColor','w', ...
            'ForegroundColor',[0.45 0.45 0.45],'HorizontalAlignment','left');

        % Los callbacks capturan S{i,1} por VALOR: cada boton se queda con
        % SU nombre de funcion. Sin la captura, los ocho terminarian
        % llamando al ultimo del bucle.
        uicontrol('Parent',fig,'Style','pushbutton','String','Abrir', ...
            'Units','normalized','Position',[0.74 y+0.008 0.10 0.055], ...
            'FontWeight','bold','Callback',@(~,~) lanzar(S{i,1},''));

        uicontrol('Parent',fig,'Style','pushbutton','String','Exportar', ...
            'Units','normalized','Position',[0.855 y+0.008 0.115 0.055], ...
            'Callback',@(~,~) lanzar(S{i,1},'exportar'));
    end

    hEstado = uicontrol('Parent',fig,'Style','text','String','', ...
        'Units','normalized','Position',[0.03 0.035 0.66 0.045], ...
        'FontSize',9,'BackgroundColor','w','HorizontalAlignment','left');

    uicontrol('Parent',fig,'Style','pushbutton','String','Exportar todos', ...
        'Units','normalized','Position',[0.71 0.03 0.26 0.055], ...
        'Callback',@(~,~) exportarTodosGUI());

    % =====================================================================
    % FUNCIONES ANIDADAS. Ven fig y hEstado sin pasarlos.
    % =====================================================================

    function lanzar(fn, arg)
        % fn : nombre de la funcion del simulador
        % arg: '' para interactivo, 'exportar' para el render fijo
        %
        % El try/catch es para que un simulador roto no se lleve puesto el
        % menu: el error se muestra en la barra de estado y los otros siete
        % siguen a mano.
        estado(sprintf('Abriendo %s ...', fn));
        try
            if isempty(arg), feval(fn); else, feval(fn, arg); end
            if isempty(arg)
                estado(sprintf('%s abierto.', fn));
            else
                estado(sprintf('%s exportado a ./figs/', fn));
            end
        catch err
            estado(sprintf('ERROR en %s: %s', fn, err.message));
        end
    end

    function exportarTodosGUI()
        % Corre el modo exportar de los ocho, uno por uno, informando por
        % la barra de estado. No abre ninguna ventana.
        fallos = 0;
        for j = 1:n
            estado(sprintf('Exportando %d de %d: %s ...', j, n, S{j,1}));
            drawnow
            try
                feval(S{j,1}, 'exportar');
            catch
                fallos = fallos + 1;
            end
        end
        if fallos == 0
            estado(sprintf('Listo: %d simuladores exportados a ./figs/', n));
        else
            estado(sprintf('Terminado con %d fallos de %d.', fallos, n));
        end
    end

    function estado(txt)
        % Escribe en la barra de estado, si el menu sigue vivo.
        if isvalid(hEstado), set(hEstado,'String',txt); drawnow limitrate, end
    end
end

% =========================================================================
% FUNCION LOCAL (no anidada: no ve las variables de arriba)
% =========================================================================

function exportarTodos(S)
    % Modo 'exportar' sin menu, para correr por lote:
    %   matlab -batch "sim_main('exportar')"
    % Devuelve un resumen por consola y no abre ninguna ventana interactiva.
    n = size(S,1);
    fallos = {};
    for j = 1:n
        try
            feval(S{j,1}, 'exportar');
        catch err
            fallos{end+1} = sprintf('%s: %s', S{j,1}, err.message); %#ok<AGROW>
        end
    end
    fprintf('\n--- sim_main: %d de %d exportados ---\n', n-numel(fallos), n);
    for j = 1:numel(fallos)
        fprintf('  FALLO %s\n', fallos{j});
    end
end
