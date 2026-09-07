function sim1_impactoPlastico(modo)
% SIM1_IMPACTOPLASTICO - simulador interactivo del problema 1 de Tarea 2.
%
% Un bloque cae sobre otro que descansa sobre un resorte y un amortiguador.
% El impacto es PLASTICO: quedan unidos y vibran juntos.
%
% USO:
%   sim1_impactoPlastico             % modo interactivo
%   sim1_impactoPlastico('exportar') % render fijo + GIF en ./figs/
%
% POR QUE ESTE SIMULADOR TE PIDE DATOS EN VEZ DE CALCULARLOS.
% La vibracion arranca donde termina el impacto, y de ahi salen tres cosas:
% la masa que vibra, la posicion inicial y la velocidad inicial. Esas tres
% NO estan en VM.m, y no es un olvido: son exactamente lo que el problema
% te pide obtener. Si el simulador las calculara, te sacaria el ejercicio.
% Por eso van como CAMPOS DE ENTRADA: las calculas vos, las escribis, y el
% simulador te muestra que vibracion producen. Hasta que no las escribas,
% no hay curva que dibujar y te lo dice.
%
% Los datos del enunciado (masas y altura de caida) se muestran arriba como
% referencia, pero NO entran al modelo: entran a traves de tu resultado.
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica de vibraciones es de VM.m:
%   VM.trayA   entrega x(t), v(t), la envolvente y los escalares del caso
%   VM.genA    traduce el zeta del slider a c, y tu wn y tu zeta a k y c
%   VM.subA    valores de referencia del panel de comprobacion
% Aca no se escribe ni una formula de vibraciones.

    if nargin < 1, modo = ''; end

    % ---------------------------------------------------------------------
    % DATOS DEL ENUNCIADO. No se sobrescriben nunca: es a donde vuelve el
    % boton "Restaurar".
    % ---------------------------------------------------------------------
    D = struct( ...
        'k',  1500, ...   % rigidez del resorte                  [N/m]
        'c',  230,  ...   % coeficiente de amortiguamiento       [N*s/m]
        'z',  NaN);       % zeta: NO es dato, sale de k, c y meq

    % Datos del impacto, SOLO para mostrar y para dibujar la escena. No
    % entran al modelo de la vibracion.
    DAT = struct( ...
        'm1', 4.00, ...   % masa que cae                         [kg]
        'm2', 9.00, ...   % masa que recibe el impacto           [kg]
        'h',  0.800);     % altura de caida [m]  (800 mm)

    P = D;                 % parametros vivos del modelo
    MIO = struct('meq',NaN, 'x0',NaN, 'v0',NaN);   % lo que escribis vos

    R = struct('k',[100 5000], 'c',[0 800], 'z',[0 2]);
    NOM = {'k','c','z'};
    UNI = {'N/m','N*s/m','-'};

    if strcmp(modo,'exportar')
        exportar();
        return
    end

    % ---------------------------------------------------------------------
    % FIGURA
    % ---------------------------------------------------------------------
    tmr = [];   % handle del timer; declarado antes de la figura porque
                % cerrar() puede correr antes de que se lo asigne

    fig = figure('Name','Problema 1 - impacto plastico', ...
        'NumberTitle','off','Color','w', ...
        'Position',[60 60 1450 840],'CloseRequestFcn',@cerrar);
    theme(fig,'light');   % fuerza tema claro (ver VM.graficarA)

    axAnim = axes('Parent',fig,'Position',[0.04 0.47 0.42 0.49]);
    axResp = axes('Parent',fig,'Position',[0.55 0.47 0.42 0.49]);

    % --- escena ----------------------------------------------------------
    % Unidades de DIBUJO, no metros. La posicion fisica se mapea con ESC,
    % que se fija la primera vez que hay curva.
    axis(axAnim,[0 10 -1 11]); axis(axAnim,'off'); hold(axAnim,'on');
    title(axAnim,'Escena','Color','k');

    YB  = 2.2;    % altura del bloque receptor en reposo [dibujo]
    ESC = 1;      % se recalcula cuando hay trayectoria

    plot(axAnim,[1 9],[0 0],'k-','LineWidth',2);            % piso
    % resorte y amortiguador, del piso al bloque
    hRes = plot(axAnim,nan,nan,'-','Color',[0.20 0.45 0.70],'LineWidth',1.8);
    hAmo = plot(axAnim,nan,nan,'k-','LineWidth',2.5);
    hAmC = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.80 0.88 0.95],'EdgeColor','k');

    % bloque receptor y bloque que cayo, ya unidos (impacto plastico)
    hB2 = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.55 0.78 0.92],'EdgeColor','k','LineWidth',1.5);
    hB1 = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.95 0.75 0.45],'EdgeColor','k','LineWidth',1.5);

    % Fantasma: donde estaba el bloque que cae ANTES de soltarse. Es una
    % marca de la escena, no una simulacion de la caida: animar la caida
    % seria mostrarte de donde sale v0, que es parte de lo que tenes que
    % resolver.
    plot(axAnim,[3.4 6.6 6.6 3.4 3.4], YB+1.0+DAT.h*3+[0 0 0.8 0.8 0], ...
        'k--','LineWidth',1);
    text(axAnim,6.9, YB+1.4+DAT.h*3, sprintf('m_1 = %.2f kg', DAT.m1), ...
        'Color','k','FontSize',9);
    annotation(fig,'doublearrow',[0.115 0.115],[0.80 0.905]);
    text(axAnim,2.6, YB+1.0+DAT.h*1.6, sprintf('h = %.0f mm',DAT.h*1e3), ...
        'Color','k','FontSize',9,'HorizontalAlignment','right');
    text(axAnim,6.9, YB+0.4, sprintf('m_2 = %.2f kg', DAT.m2), ...
        'Color','k','FontSize',9);

    hAviso = text(axAnim,5,8.6,'', 'Color',[0.75 0.20 0.10], ...
        'FontSize',11,'FontWeight','bold','HorizontalAlignment','center');

    % --- respuesta temporal ----------------------------------------------
    hold(axResp,'on'); grid(axResp,'on');
    hEnvS = plot(axResp,nan,nan,'r--','LineWidth',1,'DisplayName','Envolvente');
    hEnvI = plot(axResp,nan,nan,'r--','LineWidth',1,'HandleVisibility','off');
    hCurv = plot(axResp,nan,nan,'-','Color',[0 0.30 0.65],'LineWidth',1.8, ...
        'DisplayName','x(t)');
    hVert = plot(axResp,[nan nan],[nan nan],'-','Color',[0.6 0.6 0.6], ...
        'HandleVisibility','off');
    hPto  = plot(axResp,nan,nan,'o','MarkerSize',9, ...
        'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k', ...
        'HandleVisibility','off');
    xlabel(axResp,'t [s]'); ylabel(axResp,'x(t) [m]');
    legend(axResp,'show','Location','northeast');
    set(axResp,'Color','w','XColor','k','YColor','k', ...
        'GridColor',[0.5 0.5 0.5],'GridAlpha',1);

    % ---------------------------------------------------------------------
    % PANEL DE EXPLORACION
    % ---------------------------------------------------------------------
    panE = uipanel('Parent',fig,'Title','Exploracion', ...
        'FontWeight','bold','BackgroundColor','w','Position',[0.04 0.03 0.42 0.40]);

    hRegim = uicontrol('Parent',panE,'Style','text','String','', ...
        'Units','normalized','Position',[0.02 0.84 0.96 0.13], ...
        'FontSize',12,'FontWeight','bold','BackgroundColor','w');

    hSli = gobjects(1,numel(NOM));
    hLab = gobjects(1,numel(NOM));
    for i = 1:numel(NOM)
        y = 0.66 - (i-1)*0.16;
        hLab(i) = uicontrol('Parent',panE,'Style','text', ...
            'Units','normalized','Position',[0.02 y 0.40 0.11], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',10);
        hSli(i) = uicontrol('Parent',panE,'Style','slider', ...
            'Units','normalized','Position',[0.44 y+0.02 0.54 0.08], ...
            'Min',R.(NOM{i})(1),'Max',R.(NOM{i})(2), ...
            'Value',max(R.(NOM{i})(1),min(R.(NOM{i})(2), valInicial(i))), ...
            'Callback',@(s,~) moverSlider(i,get(s,'Value')));
    end

    uicontrol('Parent',panE,'Style','pushbutton','String','Restaurar', ...
        'Units','normalized','Position',[0.02 0.02 0.30 0.12], ...
        'FontWeight','bold','Callback',@(~,~) restaurar());

    % ---------------------------------------------------------------------
    % PANEL DE TU SOLUCION DEL IMPACTO
    % ---------------------------------------------------------------------
    panC = uipanel('Parent',fig,'Title', ...
        'Tu solucion del impacto  ->  arranque de la vibracion', ...
        'FontWeight','bold','BackgroundColor','w','Position',[0.55 0.03 0.42 0.40]);

    ENT  = {'meq','x0','v0'};
    ENTU = {'kg','m','m/s'};
    ENTT = {'masa que vibra tras el impacto', ...
            'posicion inicial x(0)', ...
            'velocidad inicial xpunto(0)'};

    hEd = gobjects(1,numel(ENT));
    for i = 1:numel(ENT)
        y = 0.76 - (i-1)*0.15;
        uicontrol('Parent',panC,'Style','text', ...
            'String',sprintf('%s [%s]',ENT{i},ENTU{i}), ...
            'Units','normalized','Position',[0.02 y 0.16 0.10], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',10);
        hEd(i) = uicontrol('Parent',panC,'Style','edit','String','', ...
            'Units','normalized','Position',[0.19 y 0.16 0.12], ...
            'BackgroundColor','w','FontSize',10, ...
            'Callback',@(~,~) leerEntradas());
        uicontrol('Parent',panC,'Style','text','String',ENTT{i}, ...
            'Units','normalized','Position',[0.37 y 0.61 0.10], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',9, ...
            'ForegroundColor',[0.35 0.35 0.35]);
    end

    hFeed = uicontrol('Parent',panC,'Style','text','String','', ...
        'Units','normalized','Position',[0.02 0.16 0.96 0.28], ...
        'HorizontalAlignment','left','BackgroundColor',[0.97 0.97 0.97], ...
        'FontSize',9);

    uicontrol('Parent',panC,'Style','pushbutton','String','Aplicar', ...
        'Units','normalized','Position',[0.02 0.02 0.24 0.12], ...
        'FontWeight','bold','Callback',@(~,~) leerEntradas());
    uicontrol('Parent',panC,'Style','pushbutton','String','Limpiar', ...
        'Units','normalized','Position',[0.29 0.02 0.24 0.12], ...
        'Callback',@(~,~) limpiar());

    % ---------------------------------------------------------------------
    % ARRANQUE
    % ---------------------------------------------------------------------
    TT = []; XX = []; NUM = [];   % ultima trayectoria; vacias hasta que
    idx = 1;                      % escribas meq y v0
    refrescar();

    tmr = timer('ExecutionMode','fixedRate','Period',0.04, ...
        'BusyMode','drop','TimerFcn',@(~,~) paso());
    start(tmr);

    % =====================================================================
    % FUNCIONES ANIDADAS
    % =====================================================================

    function v = valInicial(i)
        % Valor con que arranca cada slider. zeta no es dato del enunciado:
        % sale de k, c y meq, asi que hasta que no haya meq no tiene valor.
        switch NOM{i}
            case 'z', v = 0.5;
            otherwise, v = D.(NOM{i});
        end
    end

    function moverSlider(i, val)
        if strcmp(NOM{i},'z')
            % El slider de zeta MANDA sobre c: se le pide a VM el c que
            % corresponde, en vez de calcularlo aca.
            if ~isnan(MIO.meq)
                g = VM.genA('m',MIO.meq, 'k',P.k, 'z',val);
                P.c = double(g.c);
                set(hSli(strcmp(NOM,'c')),'Value', ...
                    max(R.c(1),min(R.c(2),P.c)));
            end
            P.z = val;
        else
            P.(NOM{i}) = val;
        end
        refrescar();
    end

    function leerEntradas()
        % Lee los tres campos. Un campo vacio o no numerico queda en NaN.
        for j = 1:numel(ENT)
            s = str2double(get(hEd(j),'String'));
            MIO.(ENT{j}) = s;   % str2double ya devuelve NaN si no es numero
        end
        refrescar();
    end

    function limpiar()
        set(hEd,'String','');
        MIO = struct('meq',NaN,'x0',NaN,'v0',NaN);
        refrescar();
    end

    function restaurar()
        % Vuelve a k y c del enunciado. NO toca tus tres valores: esos son
        % tuyos, no del enunciado.
        P.k = D.k; P.c = D.c;
        set(hSli(strcmp(NOM,'k')),'Value',D.k);
        set(hSli(strcmp(NOM,'c')),'Value',D.c);
        refrescar();
    end

    function listo = hayDatos()
        % meq tiene que ser positiva y v0 o x0 distinta de cero: con las dos
        % en cero el sistema se queda quieto y no hay nada que mirar.
        listo = ~isnan(MIO.meq) && MIO.meq > 0 && ...
                ~isnan(MIO.x0) && ~isnan(MIO.v0) && ...
                (MIO.x0 ~= 0 || MIO.v0 ~= 0);
    end

    function refrescar()
        % Actualiza etiquetas siempre; la curva solo si ya hay datos.
        for j = 1:numel(NOM)
            if strcmp(NOM{j},'z')
                set(hLab(j),'String',sprintf('zeta = %.4g   (de k, c y meq)', ...
                    get(hSli(j),'Value')));
            else
                set(hLab(j),'String',sprintf('%s = %.5g %s   (%.5g)', ...
                    NOM{j}, P.(NOM{j}), UNI{j}, D.(NOM{j})));
            end
        end

        if ~hayDatos()
            TT = []; XX = []; NUM = [];
            set([hCurv hEnvS hEnvI hPto hVert],'Visible','off');
            set(hRegim,'String', ...
                'Escribi meq, x0 y v0 para ver la vibracion', ...
                'ForegroundColor',[0.45 0.45 0.45]);
            set(hAviso,'String', ...
                sprintf(['Falta tu resultado del impacto.\n' ...
                         'El simulador no lo calcula: es lo que pide el problema.']));
            dibujarEscena(0);
            return
        end
        set(hAviso,'String','');
        set([hCurv hEnvS hEnvI hPto hVert],'Visible','on');

        [TT, XX, ~, NUM] = VM.trayA('m',MIO.meq, 'k',P.k, 'c',P.c, ...
            'x0',MIO.x0, 'v0',MIO.v0, 'npts',600);

        set(hCurv,'XData',TT,'YData',XX);
        if isnan(NUM.X)
            set([hEnvS hEnvI],'Visible','off');
        else
            set(hEnvS,'XData',TT,'YData', NUM.env,'Visible','on');
            set(hEnvI,'XData',TT,'YData',-NUM.env,'Visible','on');
        end

        a = max([abs(XX), eps]);
        set(axResp,'XLim',[0 TT(end)],'YLim',[-1.15 1.15]*a);
        ESC = 1.6/a;   % escala de dibujo: la amplitud ocupa 1.6 unidades

        set(hSli(strcmp(NOM,'z')),'Value',max(0,min(2,NUM.z)));
        switch NUM.regimen
            case 'sub',     col = [0.00 0.30 0.65]; txt = 'SUB-amortiguado';
            case 'critico', col = [0.85 0.33 0.10]; txt = 'CRITICO';
            case 'sobre',   col = [0.10 0.50 0.20]; txt = 'SOBRE-amortiguado';
        end
        set(hRegim,'String',sprintf('%s      zeta = %.4f   (zeta - 1 = %+.4f)', ...
            txt, NUM.z, NUM.z-1),'ForegroundColor',col);

        idx = 1;
    end

    function paso()
        if ~isvalid(fig), return, end
        if isempty(TT), return, end
        idx = idx + 4;
        if idx > numel(TT), idx = 1; end
        dibujarEscena(XX(idx));
        set(hPto,'XData',TT(idx),'YData',XX(idx));
        set(hVert,'XData',[TT(idx) TT(idx)],'YData',get(axResp,'YLim'));
        drawnow limitrate
    end

    function dibujarEscena(x)
        % x: posicion fisica [m]. Se dibuja hacia ABAJO positiva, que es el
        % sentido en que el bloque comprime el resorte.
        yb = YB - ESC*x;                    % base del bloque receptor
        yb = max(min(yb, YB+1.8), 0.6);     % topes de dibujo

        set(hB2,'XData',[3.4 6.6 6.6 3.4],'YData',yb+[0 0 1.0 1.0]);
        set(hB1,'XData',[3.8 6.2 6.2 3.8],'YData',yb+1.0+[0 0 0.8 0.8]);

        [xs,ys] = zigzagV(3.9, 0, yb, 8, 0.30);
        set(hRes,'XData',xs,'YData',ys);
        set(hAmC,'XData',[5.7 6.5 6.5 5.7],'YData',[0 0 0.9 0.9]);
        set(hAmo,'XData',[6.1 6.1],'YData',[0.45 yb]);
    end

    function cerrar(~,~)
        if ~isempty(tmr) && isvalid(tmr), stop(tmr); delete(tmr); end
        delete(fig);
    end

    % =====================================================================
    % MODO EXPORTAR
    % =====================================================================
    function exportar()
        % Sin tu resultado del impacto no hay nada que exportar: el modo
        % exportar usa k y c del enunciado y condiciones NORMALIZADAS
        % (x0 = 0, v0 = 1 m/s, meq = 1 kg) para mostrar la FORMA de la
        % respuesta, no los numeros del problema.
        if ~exist('figs','dir'), mkdir('figs'); end
        [t,x,~,n] = VM.trayA('m',1,'k',D.k,'c',D.c,'x0',0,'v0',1,'npts',600);

        f = figure('Color','w','Position',[100 100 900 420],'Visible','off');
        theme(f,'light');
        ax = axes('Parent',f); hold(ax,'on'); grid(ax,'on');
        if ~isnan(n.X)
            plot(ax,t, n.env,'r--','LineWidth',1,'DisplayName','Envolvente');
            plot(ax,t,-n.env,'r--','LineWidth',1,'HandleVisibility','off');
        end
        plot(ax,t,x,'-','Color',[0 0.30 0.65],'LineWidth',1.8,'DisplayName','x(t)');
        hm = plot(ax,t(1),x(1),'o','MarkerSize',9, ...
            'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k', ...
            'HandleVisibility','off');
        xlabel(ax,'t [s]'); ylabel(ax,'x(t) [m]');
        legend(ax,'show','Location','northeast');
        set(ax,'Color','w','XColor','k','YColor','k', ...
            'GridColor',[0.5 0.5 0.5],'GridAlpha',1,'XLim',[0 t(end)]);
        title(ax,sprintf(['Problema 1 - forma de la respuesta, ' ...
            'condiciones normalizadas (\\zeta = %.3f)'], n.z),'Color','k');

        gif = fullfile('figs','sim1.gif');
        if exist(gif,'file'), delete(gif); end
        for i = 1:20:numel(t)
            set(hm,'XData',t(i),'YData',x(i));
            exportgraphics(ax, gif, 'Append', i > 1);
        end
        exportgraphics(ax, fullfile('figs','sim1.png'),'Resolution',150);
        close(f);
        fprintf('Escrito: %s\n', gif);
        fprintf('Escrito: %s\n', fullfile('figs','sim1.png'));
    end
end

% =========================================================================
% FUNCION LOCAL
% =========================================================================

function [xs, ys] = zigzagV(x, ya, yb, nv, amp)
    % Resorte VERTICAL en zigzag, para dibujar.
    %   x       : abscisa del eje del resorte [unidades de dibujo]
    %   ya, yb  : extremos vertical inferior y superior
    %   nv      : cantidad de dientes
    %   amp     : media anchura del diente
    % Los tramos rectos de las puntas hacen que se vea anclado.
    n  = 2*nv;
    yr = linspace(ya+0.15, yb-0.15, n);
    xr = x + amp*(-1).^(1:n);
    ys = [ya, ya+0.15, yr, yb-0.15, yb];
    xs = [x,  x,       xr, x,       x ];
end
