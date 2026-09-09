function sim3_vagonTope(modo)
% SIM3_VAGONTOPE - simulador interactivo del problema 3 de Tarea 2.
%
% Vagon de ferrocarril que llega a un tope. El tope son DOS resortes de k/2
% y UN amortiguador c, los tres en PARALELO entre el vagon y la pared: los
% tres sufren la misma deformacion, asi que las rigideces se suman.
% Anima el vagon, dibuja x(t) con su envolvente y deja barrer los
% parametros en vivo.
%
% USO:
%   sim3_vagonTope             % modo interactivo
%   sim3_vagonTope('exportar') % render fijo + GIF en ./figs/
%
% CONVENCION DE SIGNOS. t = 0 es el instante del CONTACTO con el tope, asi
% que x(0) = 0. El sentido positivo de x es HACIA LA PARED, o sea x > 0 es
% COMPRESION del tope. Por eso la velocidad de llegada entra como v0 > 0.
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica es de VM.m:
%   VM.datosParalelos  suma los dos resortes de k/2 en la rigidez equivalente
%   VM.clasifA         da la zeta que corresponde al c del enunciado
%   VM.trayA           entrega x(t), v(t) y los escalares del caso
%   VM.subA            valores de referencia del panel de comprobacion
%   VM.genA            traduce TU wn y TU zeta a k y c, para superponer tu curva
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
    %
    % El enunciado da c, no zeta. La zeta que le corresponde la calcula
    % VM.clasifA (cuarta salida), no una division escrita aca.
    % ---------------------------------------------------------------------
    kUno = 40e3;    % rigidez de CADA resorte del tope [N/m]  (k/2 = 40.0 N/mm)
    mVag = 2000;    % masa del vagon                   [kg]
    cTop = 20e3;    % amortiguamiento del tope         [N*s/m]  (20.0 N*s/mm)

    % keq del enunciado, solo para pedirle la zeta a VM.clasifA
    kEnu = VM.datosParalelos([kUno kUno]);          % rigidez equivalente [N/m]
    [~, ~, ~, zEnu] = VM.clasifA('m',mVag, 'k',kEnu, 'c',cTop);   % zeta [-]

    D = struct( ...
        'k1', kUno, ...   % rigidez del resorte 1 del tope     [N/m]
        'k2', kUno, ...   % rigidez del resorte 2 del tope     [N/m]
        'm',  mVag, ...   % masa del vagon                     [kg]
        'z',  zEnu, ...   % relacion de amortiguamiento        [-]
        'x0', 0,    ...   % compresion inicial x(0)            [m]
        'v0', 10);        % velocidad de llegada xpunto(0)     [m/s]

    P = D;   % parametros VIVOS, los que mueven los sliders

    % Rangos de los sliders: [minimo maximo] de cada parametro. z llega
    % hasta 2 a proposito, para cruzar los tres regimenes y no solo afinar
    % alrededor del valor del enunciado. v0 no baja de 0 porque un vagon que
    % se aleja del tope no toca el tope: ese caso no es este modelo.
    R = struct( ...
        'k1', [5e3 2e5], 'k2', [5e3 2e5], 'm', [500 6000], ...
        'z',  [0 2],     'x0', [-0.5 0.5], 'v0', [0 25]);

    NOM = {'k1','k2','m','z','x0','v0'};              % orden de los sliders
    UNI = {'N/m','N/m','kg','-','m','m/s'};           % unidad de cada uno

    % tf del eje de tiempo: se fija UNA vez y no se recalcula. Si tf siguiera
    % a z, al mover el slider el eje se reescalaria solo y todas las curvas
    % se verian iguales. Se toma la MAS LARGA de las tres ventanas que
    % propone VM.trayA por su cuenta (la del enunciado y las de los dos
    % extremos del slider de z) para que el transitorio entre entero en
    % cualquier posicion del slider.
    TF        = ventana(D, R.z(1), R.z(2));   % tiempo final del grafico [s]
    [~, xx0]  = modelo(D, TF);
    XREF      = max(abs(xx0));                % amplitud de referencia [m]

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
    MAG  = {'keq','c','wn','z','wd','xmax','tmax'};
    MAGU = {'N/m','N*s/m','rad/s','-','rad/s','m','s'};
    % Etiquetas en ASCII pelado: uicontrol NO interpreta TeX, asi que un
    % '\zeta' aca se ve literal como barra-zeta. El TeX solo vale en
    % title, xlabel y demas texto de los EJES.
    MAGL = {'k_eq','c','wn','z','wd','x_max','t_max'};

    % ---------------------------------------------------------------------
    % FIGURA Y EJES
    % ---------------------------------------------------------------------
    tmr = [];   % handle del timer; se declara ANTES de la figura porque
                % cerrar() puede correr antes de que se lo asigne

    fig = figure('Name','Problema 3 - vagon contra el tope', ...
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
    title(axAnim,'Animacion: el vagon comprime el tope','Color','k');

    % ESC: cuantas unidades de dibujo vale un metro. Se fija con la
    % amplitud del enunciado para que el vagon recorra ~1.2 unidades.
    ESC = 1.2/max(XREF, eps);
    XC0 = 6.0;   % centro del vagon en el instante del contacto [dibujo]
    BW  = 2.6;   % ancho del vagon  [dibujo]
    BH  = 1.4;   % alto del vagon   [dibujo]

    % --- escenario fijo: se dibuja UNA vez, fuera de todo callback -------
    plot(axAnim,[0 10],[-1.05 -1.05],'k-','LineWidth',2.5);   % riel
    plot(axAnim,[0 10],[-1.30 -1.30],'-','Color',[0.55 0.45 0.35], ...
        'LineWidth',6);                                       % balasto
    % pared del tope, a la derecha
    patch('Parent',axAnim,'XData',[9.4 10 10 9.4],'YData',[-1.05 -1.05 2.4 2.4], ...
        'FaceColor',[0.85 0.82 0.75],'EdgeColor','k','LineWidth',1.2);

    % resortes del tope: los DOS van del vagon a la pared, asi que sufren la
    % MISMA deformacion. Eso es estar en paralelo, y por eso keq = k1 + k2.
    hRes1 = plot(axAnim,nan,nan,'-','Color',[0.20 0.45 0.70],'LineWidth',1.8);
    hRes2 = plot(axAnim,nan,nan,'-','Color',[0.20 0.45 0.70],'LineWidth',1.8);

    % amortiguador: cilindro fijo a la pared + vastago que sale del vagon.
    % Va en paralelo con los resortes, entre los mismos dos puntos.
    hAmoC = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.80 0.88 0.95],'EdgeColor','k','LineWidth',1.2);
    hAmoV = plot(axAnim,nan,nan,'k-','LineWidth',2.5);

    % vagon y ruedas
    hVag  = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.55 0.78 0.92],'EdgeColor','k','LineWidth',1.5);
    hRue  = gobjects(1,4);
    for i = 1:4
        hRue(i) = plot(axAnim,nan,nan,'o','MarkerSize',10, ...
            'MarkerFaceColor',[0.15 0.55 0.80],'MarkerEdgeColor','k');
    end

    % marca del contacto, para ver contra que se mide x
    plot(axAnim,[XC0 XC0],[-1.05 -0.25],'k:','LineWidth',1);
    text(axAnim, XC0, -1.65,'x = 0 (contacto)', ...
        'HorizontalAlignment','center','Color','k');

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
    xlabel(axResp,'t [s]'); ylabel(axResp,'x(t) [m]   (+ = compresion)');
    title(axResp,'Compresion del tope x(t)','Color','k');
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
        y = 0.87 - (i-1)*0.116;
        uicontrol('Parent',panC,'Style','text', ...
            'String',sprintf('%s [%s]',MAGL{i},MAGU{i}), ...
            'Units','normalized','Position',[0.02 y 0.24 0.085], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',10);
        hEd(i) = uicontrol('Parent',panC,'Style','edit','String','', ...
            'Units','normalized','Position',[0.27 y 0.20 0.095], ...
            'BackgroundColor','w','FontSize',10);
        hRev(i) = uicontrol('Parent',panC,'Style','pushbutton', ...
            'String','Revelar','Units','normalized', ...
            'Position',[0.49 y 0.16 0.095],'FontSize',9, ...
            'Callback',@(~,~) revelar(i));
    end

    hFeed = uicontrol('Parent',panC,'Style','text','String','', ...
        'Units','normalized','Position',[0.67 0.15 0.31 0.80], ...
        'HorizontalAlignment','left','BackgroundColor',[0.97 0.97 0.97], ...
        'FontSize',9);

    uicontrol('Parent',panC,'Style','pushbutton','String','Comprobar', ...
        'Units','normalized','Position',[0.02 0.02 0.28 0.10], ...
        'FontWeight','bold','Callback',@(~,~) comprobar());
    uicontrol('Parent',panC,'Style','pushbutton','String','Ocultar mi curva', ...
        'Units','normalized','Position',[0.33 0.02 0.30 0.10], ...
        'Callback',@(~,~) set(hMia,'Visible','off'));

    % ---------------------------------------------------------------------
    % ARRANQUE
    % ---------------------------------------------------------------------
    TT = []; XX = []; VV = []; NUM = [];   % ultima trayectoria calculada
    idx = 1;                               % frame actual de la animacion
    refrescar();

    % El timer avanza el marcador y el vagon. 'drop' descarta el tick si el
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
        [TT, XX, VV, NUM] = modelo(P, TF);   % VV queda para el marcador

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
        % Un frame: mueve el vagon y el marcador. Solo set(), nada de
        % replot. Si la figura ya no esta, no hace nada.
        if ~isvalid(fig) || isempty(TT), return, end
        idx = idx + 4;
        if idx > numel(TT), idx = 1; end

        % x > 0 comprime, o sea el vagon avanza HACIA la pared (a la derecha).
        % OJO con el tramo x < 0: el modelo es LINEAL y ahi el tope "tira"
        % del vagon como si estuviera atornillado. Un tope real solo empuja,
        % asi que el vagon se separaria en x = 0 y seguiria de largo. La
        % primera compresion, que es la que importa, cae entera en x > 0.
        xc = XC0 + ESC*XX(idx);                 % centro del vagon [dibujo]
        xc = min(max(xc, 2.0), 7.6);            % tope: que no atraviese muros
        dibujarVagon(xc);

        set(hPto, 'XData',TT(idx),'YData',XX(idx));
        yl = get(axResp,'YLim');
        set(hVert,'XData',[TT(idx) TT(idx)],'YData',yl);
        drawnow limitrate
    end

    function dibujarVagon(xc)
        % xc: centro del vagon en unidades de DIBUJO.
        iz = xc - BW/2;   % cara izquierda
        de = xc + BW/2;   % cara derecha (la que empuja el tope)

        set(hVag,'XData',[iz de de iz], ...
                 'YData',[-0.60 -0.60 -0.60+BH -0.60+BH]);
        for w = 1:4
            set(hRue(w),'XData',xc + (w-2.5)*0.65,'YData',-0.85);
        end

        % los dos resortes, arriba y abajo del amortiguador
        [xa,ya] = zigzag(de, 9.4, 0.62, 9, 0.20);
        set(hRes1,'XData',xa,'YData',ya);
        [xb,yb] = zigzag(de, 9.4, -0.18, 9, 0.20);
        set(hRes2,'XData',xb,'YData',yb);

        % amortiguador: cilindro pegado a la pared, vastago que lo sigue
        set(hAmoC,'XData',[8.6 9.4 9.4 8.6],'YData',[0.05 0.05 0.45 0.45]);
        set(hAmoV,'XData',[de 9.0],'YData',[0.25 0.25]);
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
                    if alto, s = 'tu tope es mas duro';
                    else,    s = 'tu tope es mas blando'; end
                case 'c'
                    if alto, s = 'tu amortiguador frena mas';
                    else,    s = 'tu amortiguador frena menos'; end
                case 'xmax'
                    if alto, s = 'tu vagon se hunde mas en el tope';
                    else,    s = 'tu vagon se hunde menos en el tope'; end
                case 'tmax'
                    if alto, s = 'tu vagon tarda mas en llegar al fondo';
                    else,    s = 'tu vagon tarda menos en llegar al fondo'; end
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
        [t,x,~,n] = modelo(D, TF);

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
        xlabel(ax,'t [s]'); ylabel(ax,'x(t) [m]   (+ = compresion)');
        legend(ax,'show','Location','northeast');
        set(ax,'Color','w','XColor','k','YColor','k', ...
            'GridColor',[0.5 0.5 0.5],'GridAlpha',1,'XLim',[0 t(end)]);
        title(ax,sprintf('Problema 3 - caso %s (\\zeta = %.3f)', ...
            n.regimen, n.z),'Color','k');

        gif = fullfile('figs','sim3.gif');
        if exist(gif,'file'), delete(gif); end
        % exportgraphics con 'Append' arma el GIF animado cuadro a cuadro.
        % nf es el indice del CUADRO; no se llama f porque f ya es el
        % handle de la figura de exportacion.
        for nf = 1:20:numel(t)
            set(hm,'XData',t(nf),'YData',x(nf));
            exportgraphics(ax, gif, 'Append', nf > 1);
        end
        exportgraphics(ax, fullfile('figs','sim3.png'), 'Resolution',150);
        close(f);
        fprintf('Escrito: %s\n', gif);
        fprintf('Escrito: %s\n', fullfile('figs','sim3.png'));
    end
end

% =========================================================================
% FUNCIONES LOCALES (no anidadas: no ven las variables de arriba)
% =========================================================================

function [t, x, v, num] = modelo(p, tf)
    % Traduce los parametros del problema a una llamada a VM.
    %   p  : struct con k1, k2, m, z, x0, v0
    %   tf : tiempo final del muestreo [s]. Si no se pasa, lo elige VM.trayA
    % Los dos resortes del tope van del vagon a la pared, asi que sufren la
    % MISMA deformacion: estan en PARALELO y las rigideces se suman.
    keq = VM.datosParalelos([p.k1 p.k2]);   % rigidez equivalente [N/m]
    if nargin < 2 || isempty(tf)
        [t, x, v, num] = VM.trayA('m',p.m, 'k',keq, 'z',p.z, ...
            'x0',p.x0, 'v0',p.v0, 'npts',600);
    else
        [t, x, v, num] = VM.trayA('m',p.m, 'k',keq, 'z',p.z, ...
            'x0',p.x0, 'v0',p.v0, 'tf',tf, 'npts',600);
    end
end

function tf = ventana(p, zmin, zmax)
    % Tiempo final FIJO del grafico [s]. VM.trayA ya elige una ventana
    % razonable cuando no le pasas tf (4 periodos amortiguados si oscila,
    % 6/wn si no). Aca se le pregunta TRES veces -- en el valor del
    % enunciado y en los dos extremos del slider de z -- y se toma la mas
    % larga, para que ninguna posicion del slider quede cortada.
    t0 = modelo(p);
    t1 = modelo(setz(p, zmin));
    t2 = modelo(setz(p, zmax));
    tf = max([t0(end) t1(end) t2(end)]);
end

function p = setz(p, z)
    % Copia de p con otra zeta. Se usa para preguntarle a VM.trayA cuanto
    % dura el transitorio en los extremos del slider.
    p.z = z;
end

function r = referencia(p)
    % Valores de referencia del panel de comprobacion, todos de VM.
    % Se calcula UNA vez con los valores del enunciado.
    keq = VM.datosParalelos([p.k1 p.k2]);   % rigidez equivalente [N/m]
    s   = VM.subA('m',p.m, 'k',keq, 'z',p.z, 'x0',p.x0, 'v0',p.v0);

    % xmax y tmax NO salen de una formula escrita aca: se LEEN de la propia
    % trayectoria que devuelve VM.trayA, muestreada fino. VM no expone el
    % instante del pico, asi que se busca el maximo entre los numeros que
    % VM ya calculo. x > 0 es compresion, por eso max(x) y no max(abs(x)).
    [t, x] = VM.trayA('m',p.m, 'k',keq, 'z',p.z, ...
        'x0',p.x0, 'v0',p.v0, 'npts',200001);
    [xm, i] = max(x);

    r = struct('keq', keq,           ...   % rigidez equivalente [N/m]
        'c',    double(s.c),         ...   % amortiguamiento     [N*s/m]
        'wn',   double(s.wn),        ...   % frec. natural       [rad/s]
        'z',    p.z,                 ...   % relacion de amort.  [-]
        'wd',   double(s.wd),        ...   % frec. amortiguada   [rad/s]
        'xmax', xm,                  ...   % compresion maxima   [m]
        'tmax', t(i));                     % instante del maximo [s]
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
