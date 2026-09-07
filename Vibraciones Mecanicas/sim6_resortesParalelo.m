function sim6_resortesParalelo(modo)
% SIM6_RESORTESPARALELO - simulador interactivo del problema 6 de Tarea 2.
%
% Masa sobre ruedas, dos resortes en PARALELO contra la pared izquierda y un
% amortiguador contra la derecha. Anima el cuerpo, dibuja x(t) con su
% envolvente y deja barrer los parametros en vivo.
%
% USO:
%   sim6_resortesParalelo             % modo interactivo
%   sim6_resortesParalelo('exportar') % render fijo + GIF en ./figs/
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica es de VM.m:
%   VM.datosParalelos  combina k1 y k2 en la rigidez equivalente
%   VM.trayA           entrega x(t), v(t) y los escalares del caso
%   VM.genA            traduce TU wn y TU z a k y c, para superponer tu curva
%   VM.subA            valores de referencia del panel de comprobacion
% Aca no se escribe ni una formula de vibraciones: si un numero hace falta,
% se le pide a VM.
%
% LOS VALORES DE REFERENCIA NO SE IMPRIMEN. Viven en variables de las
% funciones anidadas, asi que no quedan en el workspace ni salen por
% consola. La unica via para verlos es el boton "Revelar" de cada magnitud.

    if nargin < 1, modo = ''; end

    % ---------------------------------------------------------------------
    % DEFAULTS DEL ENUNCIADO. Esta struct NO se sobrescribe nunca: es a
    % donde vuelve el boton "Restaurar". Los sliders trabajan sobre P, que
    % es una copia.
    % ---------------------------------------------------------------------
    D = struct( ...
        'k1', 20,   ...   % rigidez del resorte 1              [N/m]
        'k2', 30,   ...   % rigidez del resorte 2              [N/m]
        'm',  0.2,  ...   % masa                               [kg]
        'z',  0.25, ...   % relacion de amortiguamiento        [-]
        'x0', 0,    ...   % posicion inicial x(0)              [m]
        'v0', 4);         % velocidad inicial xpunto(0)        [m/s]

    P = D;   % parametros VIVOS, los que mueven los sliders

    % Rangos de los sliders: [minimo maximo] de cada parametro. z llega
    % hasta 2 a proposito, para cruzar los tres regimenes y no solo afinar
    % alrededor del 0.25 del enunciado.
    R = struct( ...
        'k1', [1 100], 'k2', [1 100], 'm', [0.02 2], ...
        'z',  [0 2],   'x0', [-0.3 0.3], 'v0', [-8 8]);

    NOM = {'k1','k2','m','z','x0','v0'};              % orden de los sliders
    UNI = {'N/m','N/m','kg','-','m','m/s'};           % unidad de cada uno

    % tf del eje de tiempo: se fija UNA vez con los valores del enunciado y
    % no se recalcula. Asi, al mover z, el decaimiento cambia contra una
    % ventana temporal fija y se puede comparar; si tf siguiera a z, el eje
    % se reescalaria solo y todas las curvas se verian iguales.
    [tt0, xx0] = modelo(D);
    TF   = tt0(end);            % tiempo final del grafico            [s]
    XREF = max(abs(xx0));       % amplitud de referencia para la escala [m]

    if strcmp(modo, 'exportar')
        exportar();
        return
    end

    % ---------------------------------------------------------------------
    % REFERENCIA. Se calcula una vez, con los valores del ENUNCIADO, y
    % queda encerrada en esta funcion. No se imprime.
    % ---------------------------------------------------------------------
    REF = referencia(D);

    % magnitudes que el panel de comprobacion pide, en orden
    MAG  = {'keq','c','wn','z','wd'};
    MAGU = {'N/m','N*s/m','rad/s','-','rad/s'};
    % Etiquetas en ASCII pelado: uicontrol NO interpreta TeX, asi que un
    % '\zeta' aca se ve literal como barra-zeta. El TeX solo vale en
    % title, xlabel y demas texto de los EJES.
    MAGL = {'k_eq','c','wn','z','wd'};

    % ---------------------------------------------------------------------
    % FIGURA Y EJES
    % ---------------------------------------------------------------------
    tmr = [];   % handle del timer; se declara ANTES de la figura porque
                % cerrar() puede correr antes de que se lo asigne

    fig = figure('Name','Problema 6 - dos resortes en paralelo', ...
        'NumberTitle','off', 'Color','w', ...
        'Position',[60 60 1450 840], 'CloseRequestFcn',@cerrar);
    theme(fig,'light');   % fuerza tema claro: si no, con MATLAB en oscuro
                          % el area de los ejes sale negra (ver VM.graficarA)

    axAnim = axes('Parent',fig, 'Position',[0.04 0.47 0.42 0.49]);
    axResp = axes('Parent',fig, 'Position',[0.55 0.47 0.42 0.49]);

    % --- eje de la animacion ---------------------------------------------
    % Unidades de DIBUJO, no metros: la posicion fisica se mapea con ESC.
    axis(axAnim, [0 10 -2.6 2.6]);
    axis(axAnim, 'off');
    hold(axAnim,'on');
    title(axAnim,'Animacion','Color','k');

    % ESC: cuantas unidades de dibujo vale un metro. Se fija con la
    % amplitud del enunciado para que el bloque recorra ~1.2 unidades.
    ESC = 1.2/max(XREF, eps);
    XC0 = 4.6;   % centro del bloque en reposo, en unidades de dibujo
    BW  = 2.0;   % ancho del bloque
    BH  = 1.5;   % alto del bloque

    % suelo y paredes (fijos, se dibujan una sola vez)
    plot(axAnim,[0 10],[-1.0 -1.0],'k-','LineWidth',2);
    patch('Parent',axAnim,'XData',[0 0.3 0.3 0],'YData',[-1 -1 2.4 2.4], ...
        'FaceColor',[0.85 0.82 0.75],'EdgeColor','k');
    patch('Parent',axAnim,'XData',[9.7 10 10 9.7],'YData',[-1 -1 2.4 2.4], ...
        'FaceColor',[0.85 0.82 0.75],'EdgeColor','k');

    % resortes (dos, en paralelo: los dos van de la pared al bloque y por
    % eso sufren la MISMA deformacion; por eso keq = k1 + k2)
    hRes1 = plot(axAnim,nan,nan,'-','Color',[0.20 0.45 0.70],'LineWidth',1.8);
    hRes2 = plot(axAnim,nan,nan,'-','Color',[0.20 0.45 0.70],'LineWidth',1.8);

    % amortiguador: cilindro fijo a la pared derecha + vastago desde el bloque
    hAmoC = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.80 0.88 0.95],'EdgeColor','k','LineWidth',1.2);
    hAmoV = plot(axAnim,nan,nan,'k-','LineWidth',2.5);

    % bloque y ruedas
    hBloq = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.55 0.78 0.92],'EdgeColor','k','LineWidth',1.5);
    hRue1 = plot(axAnim,nan,nan,'o','MarkerSize',9, ...
        'MarkerFaceColor',[0.15 0.55 0.80],'MarkerEdgeColor','k');
    hRue2 = plot(axAnim,nan,nan,'o','MarkerSize',9, ...
        'MarkerFaceColor',[0.15 0.55 0.80],'MarkerEdgeColor','k');

    % marca del equilibrio, para ver contra que se mide x
    plot(axAnim,[XC0 XC0],[-1.0 -0.2],'k:','LineWidth',1);
    text(axAnim, XC0, -1.35,'x = 0','HorizontalAlignment','center','Color','k');

    % --- eje de la respuesta temporal ------------------------------------
    hold(axResp,'on'); grid(axResp,'on');
    hEnvS = plot(axResp,nan,nan,'r--','LineWidth',1,'DisplayName','Envolvente');
    hEnvI = plot(axResp,nan,nan,'r--','LineWidth',1,'HandleVisibility','off');
    hCurv = plot(axResp,nan,nan,'-','Color',[0 0.30 0.65], ...
        'LineWidth',1.8,'DisplayName','x(t) de referencia');
    hMia  = plot(axResp,nan,nan,'--','Color',[0.85 0.33 0.10], ...
        'LineWidth',1.8,'DisplayName','tu solucion','Visible','off');
    hVert = plot(axResp,[nan nan],[nan nan],'-','Color',[0.6 0.6 0.6], ...
        'HandleVisibility','off');   % marcador vertical, fuera de la leyenda
    hPto  = plot(axResp,nan,nan,'o','MarkerSize',9, ...
        'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k', ...
        'HandleVisibility','off');
    xlabel(axResp,'t [s]'); ylabel(axResp,'x(t) [m]');
    legend(axResp,'show','Location','northeast');
    set(axResp,'XLim',[0 TF],'Color','w','XColor','k','YColor','k', ...
        'GridColor',[0.5 0.5 0.5],'GridAlpha',1);

    % ---------------------------------------------------------------------
    % PANEL DE EXPLORACION
    % ---------------------------------------------------------------------
    panE = uipanel('Parent',fig,'Title','Exploracion', ...
        'FontWeight','bold','BackgroundColor','w', ...
        'Position',[0.04 0.03 0.42 0.40]);

    hRegim = uicontrol('Parent',panE,'Style','text','String','', ...
        'Units','normalized','Position',[0.02 0.85 0.96 0.12], ...
        'FontSize',12,'FontWeight','bold','BackgroundColor','w');

    hSli = gobjects(1,numel(NOM));   % handles de los sliders
    hLab = gobjects(1,numel(NOM));   % handles de las etiquetas
    for i = 1:numel(NOM)
        y = 0.72 - (i-1)*0.115;
        hLab(i) = uicontrol('Parent',panE,'Style','text', ...
            'Units','normalized','Position',[0.02 y 0.40 0.09], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',10);
        % Callback: la funcion recibe el handle del slider que la disparo;
        % el 'i' capturado dice CUAL parametro es.
        hSli(i) = uicontrol('Parent',panE,'Style','slider', ...
            'Units','normalized','Position',[0.44 y+0.01 0.54 0.07], ...
            'Min',R.(NOM{i})(1),'Max',R.(NOM{i})(2),'Value',D.(NOM{i}), ...
            'Callback',@(s,~) moverSlider(i,get(s,'Value')));
    end

    uicontrol('Parent',panE,'Style','pushbutton','String','Restaurar', ...
        'Units','normalized','Position',[0.02 0.02 0.30 0.10], ...
        'FontWeight','bold','Callback',@(~,~) restaurar());

    % ---------------------------------------------------------------------
    % PANEL DE COMPROBACION
    % ---------------------------------------------------------------------
    panC = uipanel('Parent',fig,'Title','Comprobar mi solucion', ...
        'FontWeight','bold','BackgroundColor','w', ...
        'Position',[0.55 0.03 0.42 0.40]);

    hEd  = gobjects(1,numel(MAG));   % campos donde escribis TUS valores
    hRev = gobjects(1,numel(MAG));   % un boton "Revelar" por magnitud
    for i = 1:numel(MAG)
        y = 0.80 - (i-1)*0.135;
        uicontrol('Parent',panC,'Style','text', ...
            'String',sprintf('%s [%s]',MAGL{i},MAGU{i}), ...
            'Units','normalized','Position',[0.02 y 0.22 0.10], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',10);
        hEd(i) = uicontrol('Parent',panC,'Style','edit','String','', ...
            'Units','normalized','Position',[0.25 y 0.22 0.11], ...
            'BackgroundColor','w','FontSize',10);
        hRev(i) = uicontrol('Parent',panC,'Style','pushbutton', ...
            'String','Revelar','Units','normalized', ...
            'Position',[0.49 y 0.17 0.11],'FontSize',9, ...
            'Callback',@(~,~) revelar(i));
    end

    hFeed = uicontrol('Parent',panC,'Style','text','String','', ...
        'Units','normalized','Position',[0.68 0.16 0.30 0.75], ...
        'HorizontalAlignment','left','BackgroundColor',[0.97 0.97 0.97], ...
        'FontSize',9);

    uicontrol('Parent',panC,'Style','pushbutton','String','Comprobar', ...
        'Units','normalized','Position',[0.02 0.02 0.28 0.11], ...
        'FontWeight','bold','Callback',@(~,~) comprobar());
    uicontrol('Parent',panC,'Style','pushbutton','String','Ocultar mi curva', ...
        'Units','normalized','Position',[0.33 0.02 0.30 0.11], ...
        'Callback',@(~,~) set(hMia,'Visible','off'));

    % ---------------------------------------------------------------------
    % ARRANQUE
    % ---------------------------------------------------------------------
    TT = []; XX = []; VV = []; NUM = [];   % ultima trayectoria calculada
    idx = 1;                               % frame actual de la animacion
    refrescar();

    % El timer avanza el marcador y el bloque. 'drop' descarta el tick si el
    % anterior no termino, asi no se encola trabajo cuando la maquina va
    % lenta. Se para y se destruye al cerrar la figura.
    tmr = timer('ExecutionMode','fixedRate','Period',0.04, ...
        'BusyMode','drop','TimerFcn',@(~,~) paso());
    start(tmr);

    % =====================================================================
    % FUNCIONES ANIDADAS. Ven P, D, REF y los handles sin pasarlos.
    % =====================================================================

    function moverSlider(i, val)
        % i: indice del parametro en NOM. val: valor nuevo del slider.
        P.(NOM{i}) = val;
        refrescar();
    end

    function restaurar()
        % Vuelve a los valores del enunciado. D nunca se toco, asi que
        % siempre esta ahi para volver.
        P = D;
        for j = 1:numel(NOM)
            set(hSli(j),'Value',D.(NOM{j}));
        end
        set(hMia,'Visible','off');
        set(hFeed,'String','');
        refrescar();
    end

    function refrescar()
        % Recalcula con VM y ACTUALIZA los handles que ya existen. No se
        % vuelve a graficar desde cero ni se abre figura nueva: solo set().
        [TT, XX, VV, NUM] = modelo(P);   % VV queda disponible para el marcador

        set(hCurv,'XData',TT,'YData',XX);

        if isnan(NUM.X)   % no oscila: no hay envolvente que dibujar
            set([hEnvS hEnvI],'Visible','off');
        else
            set(hEnvS,'XData',TT,'YData', NUM.env,'Visible','on');
            set(hEnvI,'XData',TT,'YData',-NUM.env,'Visible','on');
        end

        % limites verticales con 10% de aire; el max() evita el caso plano
        a = max([abs(XX), abs(XREF)*1e-3]);
        set(axResp,'YLim',[-1.1 1.1]*a);

        % etiqueta del regimen, con el color marcando el cruce de z = 1.
        % La tolerancia del 0.5% para el critico la pone VM.clasifA, que es
        % de donde sale NUM.regimen: aca no se vuelve a decidir.
        switch NUM.regimen
            case 'sub',     col = [0.00 0.30 0.65]; txt = 'SUB-amortiguado';
            case 'critico', col = [0.85 0.33 0.10]; txt = 'CRITICO';
            case 'sobre',   col = [0.10 0.50 0.20]; txt = 'SOBRE-amortiguado';
        end
        set(hRegim,'String', ...
            sprintf('%s      zeta = %.4f   (zeta - 1 = %+.4f)', ...
                    txt, NUM.z, NUM.z - 1), ...
            'ForegroundColor',col);

        % etiquetas de los sliders: valor actual y, entre parentesis, el
        % del enunciado
        for j = 1:numel(NOM)
            set(hLab(j),'String', sprintf('%s = %.4g %s   (%.4g)', ...
                NOM{j}, P.(NOM{j}), UNI{j}, D.(NOM{j})));
        end

        idx = 1;   % la animacion vuelve al principio
    end

    function paso()
        % Un frame: mueve el bloque y el marcador. Solo set(), nada de
        % replot. Si la figura ya no esta, no hace nada.
        if ~isvalid(fig) || isempty(TT), return, end
        idx = idx + 4;
        if idx > numel(TT), idx = 1; end

        xc = XC0 + ESC*XX(idx);                 % centro del bloque [dibujo]
        xc = min(max(xc, 2.2), 7.2);            % tope: que no atraviese muros
        dibujarCuerpo(xc);

        set(hPto, 'XData',TT(idx),'YData',XX(idx));
        yl = get(axResp,'YLim');
        set(hVert,'XData',[TT(idx) TT(idx)],'YData',yl);
        drawnow limitrate
    end

    function dibujarCuerpo(xc)
        % xc: centro del bloque en unidades de DIBUJO.
        iz = xc - BW/2;   % cara izquierda
        de = xc + BW/2;   % cara derecha

        set(hBloq,'XData',[iz de de iz],'YData',[-0.7 -0.7 -0.7+BH -0.7+BH]);
        set(hRue1,'XData',xc-0.6,'YData',-0.85);
        set(hRue2,'XData',xc+0.6,'YData',-0.85);

        [xa,ya] = zigzag(0.3, iz, 0.45, 9, 0.22);
        set(hRes1,'XData',xa,'YData',ya);
        [xb,yb] = zigzag(0.3, iz, -0.30, 9, 0.22);
        set(hRes2,'XData',xb,'YData',yb);

        % amortiguador: cilindro pegado a la pared, vastago que lo sigue
        set(hAmoC,'XData',[8.3 9.7 9.7 8.3],'YData',[-0.05 -0.05 0.55 0.55]);
        set(hAmoV,'XData',[de 8.9],'YData',[0.25 0.25]);
    end

    function comprobar()
        % Lee TUS valores, superpone TU curva y da la pista de primer nivel.
        % NO dice el valor correcto: solo que magnitud discrepa y hacia
        % donde. El valor sale por el boton "Revelar", nunca solo.
        v = nan(1,numel(MAG));
        for j = 1:numel(MAG)
            s = str2double(get(hEd(j),'String'));
            if ~isnan(s), v(j) = s; end
        end

        msg = {};

        % --- tu curva, si diste wn y z --------------------------------
        iwn = strcmp(MAG,'wn');  iz = strcmp(MAG,'z');
        if ~isnan(v(iwn)) && ~isnan(v(iz))
            try
                % VM traduce TU wn y TU z a k y c; no se despeja aca.
                g = VM.genA('m',P.m, 'wn',v(iwn), 'z',v(iz));
                [t2,x2] = VM.trayA('m',P.m,'k',double(g.k),'c',double(g.c), ...
                    'x0',P.x0,'v0',P.v0,'tf',TF,'npts',600);
                set(hMia,'XData',t2,'YData',x2,'Visible','on');
                msg{end+1} = 'Tu curva esta superpuesta en naranja.';
            catch
                msg{end+1} = 'Con esos wn y z no se puede armar la curva.';
            end
        else
            msg{end+1} = 'Escribi wn y z para superponer tu curva.';
        end

        % --- pistas de direccion, una por magnitud --------------------
        for j = 1:numel(MAG)
            if isnan(v(j)), continue, end
            r = REF.(MAG{j});
            if abs(v(j)-r) <= 5e-3*max(abs(r),eps)
                msg{end+1} = sprintf('%s: coincide.', MAGL{j}); %#ok<AGROW>
                continue
            end
            alto = v(j) > r;
            switch MAG{j}
                case 'z'
                    if alto, s = 'tu decaimiento es mas rapido';
                    else,    s = 'tu decaimiento es mas lento'; end
                case {'wn','wd'}
                    if alto, s = 'tu periodo es menor';
                    else,    s = 'tu periodo es mayor'; end
                case 'keq'
                    if alto, s = 'tu resorte es mas duro';
                    else,    s = 'tu resorte es mas blando'; end
                case 'c'
                    if alto, s = 'tu amortiguador frena mas';
                    else,    s = 'tu amortiguador frena menos'; end
            end
            msg{end+1} = sprintf('%s: %s.', MAGL{j}, s); %#ok<AGROW>
        end

        set(hFeed,'String',msg);
    end

    function revelar(j)
        % Muestra UNA magnitud, y solo cuando la pediste.
        set(hFeed,'String', sprintf('%s = %.6g %s', ...
            MAGL{j}, REF.(MAG{j}), MAGU{j}));
    end

    function cerrar(~,~)
        % El timer sobrevive a la figura si no se lo para: hay que hacerlo
        % a mano o queda corriendo en segundo plano.
        if ~isempty(tmr) && isvalid(tmr)
            stop(tmr); delete(tmr);
        end
        delete(fig);
    end

    % =====================================================================
    % MODO EXPORTAR
    % =====================================================================
    function exportar()
        % Render fijo con los valores del enunciado, sin sliders, y un GIF
        % para pegar en el LaTeX de la entrega.
        if ~exist('figs','dir'), mkdir('figs'); end
        [t,x,~,n] = modelo(D);

        f = figure('Color','w','Position',[100 100 900 420],'Visible','off');
        theme(f,'light');
        ax = axes('Parent',f); hold(ax,'on'); grid(ax,'on');
        if ~isnan(n.X)
            plot(ax,t, n.env,'r--','LineWidth',1,'DisplayName','Envolvente');
            plot(ax,t,-n.env,'r--','LineWidth',1,'HandleVisibility','off');
        end
        plot(ax,t,x,'-','Color',[0 0.30 0.65],'LineWidth',1.8, ...
            'DisplayName','x(t)');
        hm = plot(ax,t(1),x(1),'o','MarkerSize',9, ...
            'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k', ...
            'HandleVisibility','off');
        xlabel(ax,'t [s]'); ylabel(ax,'x(t) [m]');
        legend(ax,'show','Location','northeast');
        set(ax,'Color','w','XColor','k','YColor','k', ...
            'GridColor',[0.5 0.5 0.5],'GridAlpha',1,'XLim',[0 t(end)]);
        title(ax,sprintf('Problema 6 - caso %s (\\zeta = %.3f)', ...
            n.regimen, n.z),'Color','k');

        gif = fullfile('figs','sim6.gif');
        if exist(gif,'file'), delete(gif); end
        % exportgraphics con 'Append' arma el GIF animado cuadro a cuadro.
        for i = 1:20:numel(t)
            set(hm,'XData',t(i),'YData',x(i));
            exportgraphics(ax, gif, 'Append', i > 1);
        end
        exportgraphics(ax, fullfile('figs','sim6.png'), 'Resolution',150);
        close(f);
        fprintf('Escrito: %s\n', gif);
        fprintf('Escrito: %s\n', fullfile('figs','sim6.png'));
    end
end

% =========================================================================
% FUNCIONES LOCALES (no anidadas: no ven las variables de arriba)
% =========================================================================

function [t, x, v, num] = modelo(p)
    % Traduce los parametros del problema a una llamada a VM.
    % p: struct con k1, k2, m, z, x0, v0.
    % Los dos resortes van de la pared al bloque, asi que sufren la MISMA
    % deformacion: estan en PARALELO y las rigideces se suman.
    keq = VM.datosParalelos([p.k1 p.k2]);   % rigidez equivalente [N/m]
    [t, x, v, num] = VM.trayA('m',p.m, 'k',keq, 'z',p.z, ...
        'x0',p.x0, 'v0',p.v0, 'npts',600);
end

function r = referencia(p)
    % Valores de referencia del panel de comprobacion, todos de VM.
    % Se calcula UNA vez con los valores del enunciado.
    keq = VM.datosParalelos([p.k1 p.k2]);
    s   = VM.subA('m',p.m, 'k',keq, 'z',p.z, 'x0',p.x0, 'v0',p.v0);
    r = struct('keq',keq, ...
        'c',  double(s.c),  ...
        'wn', double(s.wn), ...
        'z',  p.z,          ...
        'wd', double(s.wd));
end

function [xs, ys] = zigzag(xa, xb, y, nv, amp)
    % Polilinea en zigzag para dibujar un resorte.
    %   xa, xb : extremos horizontales [unidades de dibujo]
    %   y      : altura del eje del resorte
    %   nv     : cantidad de vueltas (dientes)
    %   amp    : media altura del diente
    % Los dos primeros y los dos ultimos puntos son tramos rectos, para que
    % el resorte se vea anclado y no arranque en diagonal.
    n  = 2*nv;
    xr = linspace(xa+0.15, xb-0.15, n);
    yr = y + amp*(-1).^(1:n);
    xs = [xa, xa+0.15, xr, xb-0.15, xb];
    ys = [y,  y,       yr, y,       y ];
end
