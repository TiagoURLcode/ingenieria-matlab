function sim3_nRendijas(modo)
% SIM3_NRENDIJAS - Simulador de difraccion e interferencia de N rendijas
%                  con emisores arbitrarios y control de coherencia.
%
% Tres paneles interactivos y sincronizados:
%   Arriba izquierda: LA RENDIJA, vista frontal y a escala en micrometros [um].
%                     Barrera opaca con N aberturas de ancho a separadas d,
%                     mas emisores extra ubicados entre ellas en colores vivos.
%   Arriba derecha:   EL PATRON, curva de intensidad I(y) en milimetros [mm].
%                     Linea llena: patron total I(y) de FV.patronEmisores.
%                     Linea punteada: envolvente de una sola rendija.
%                     Marcas verticales: maximos principales con su orden n.
%   Abajo completo:   LA PANTALLA, foto real del experimento en el laboratorio
%                     con franjas luminosas pintadas mediante imagesc (hot).
%
% PANELES DE CONTROL INFERIORES:
%   1. BARRERA Y MODO: modo coherente / incoherente, sliders para N, a, d,
%      lam, X, y boton Restaurar.
%   2. EMISORES EXTRA (PESTANIAS): uitabgroup con 4 pestanias para configurar
%      hasta 4 emisores intermedios con ancho propio, amplitud, fase inicial
%      y longitud de onda independiente.
%   3. LECTURA NUMERICA Y VISIBILIDAD: datos del arreglo, separacion Dy,
%      ordenes faltantes y visibilidad V = (Imax - Imin)/(Imax + Imin).
%
% TRES CONCEPTOS FUNDAMENTALES QUE ENSENA ESTE SIMULADOR:
%   1. COHERENTE VS INCOHERENTE: en modo coherente se suman las AMPLITUDES
%      complejas E de cada fuente y se toma |E|^2, produciendo interferencia
%      constructiva y destructiva con franjas finas de alta visibilidad (V ~ 1).
%      En modo incoherente se suman directamente las INTENSIDADES: no hay
%      interferencia cruzada y la visibilidad colapsa (V ~ 0).
%   2. N = 2 ES LA DOBLE RENDIJA CLASICA. Al aumentar N, los maximos
%      principales se AFINAN notablemente (su ancho angular disminuye como
%      1/N) y aparecen N-2 maximos secundarios entre cada par de principales.
%   3. ORDENES FALTANTES: cuando la relacion d/a es un numero entero, el
%      maximo principal de interferencia de orden m = d/a coincide con el
%      cero de difraccion de la envolvente y DESAPARECE (I = env*itf = 0*1 = 0).
%
% USO:
%   sim3_nRendijas             % modo interactivo con sliders y panel
%   sim3_nRendijas('exportar') % genera figs/sim3_nRendijas.png sin ventana
%
% DE DONDE SALEN LOS NUMEROS:
%   FV.patronEmisores  calculo numerico vectorizado para arreglo arbitrario
%   FV.red             posicion angular simbolica d*sin(th)=n*lam (memoizada)

    if nargin < 1, modo = ''; end

    % ---------------------------------------------------------------------
    % DEFAULTS (D). Esta struct NO se sobrescribe: es el estado original al
    % que regresa el boton "Restaurar".
    % ---------------------------------------------------------------------
    D = struct( ...
        'N',      2, ...          % cantidad de rendijas de la barrera    [-]
        'a',      20e-6, ...      % ancho de cada rendija                 [m]  (20 um)
        'd',      100e-6, ...     % separacion entre centros              [m]  (100 um)
        'lam',    550e-9, ...     % longitud de onda de la barrera        [m]  (550 nm, verde)
        'X',      2.00, ...       % distancia a la pantalla               [m]
        'modo',   'coherente', ...% modo de iluminacion: 'coherente' o 'incoherente'
        'Nextra', 0, ...          % cantidad de emisores extra activos    [-]  (0 a 4)
        'extra',  struct( ...     % configuracion de hasta 4 emisores extra
            'entre', {1, 1, 1, 1}, ...                 % intervalo de rendijas (1 a N-1)
            't',     {0.5, 0.5, 0.5, 0.5}, ...         % fraccion entre rendijas (0 a 1)
            'a',     {15e-6, 15e-6, 15e-6, 15e-6}, ... % ancho abertura [m] (15 um)
            'A',     {1.0, 1.0, 1.0, 1.0}, ...         % amplitud relativa [-]
            'fase',  {0.0, 0.0, 0.0, 0.0}, ...         % fase inicial [rad]
            'lam',   {550e-9, 550e-9, 550e-9, 550e-9}));% longitud de onda propia [m]

    P = D;                        % parametros VIVOS, modificados por los controles

    % Rangos [minimo maximo] de los parametros de la barrera
    R = struct( ...
        'N',   [2 20], ...           % cantidad de rendijas (entero)
        'a',   [10e-6 100e-6], ...   % ancho de cada rendija [m]
        'd',   [20e-6 400e-6], ...   % separacion entre centros [m]
        'lam', [400e-9 700e-9], ...   % espectro visible [m]
        'X',   [0.5 5.0]);           % distancia a la pantalla [m]

    % Pasos de los sliders de la barrera [clic-flecha, clic-barra]
    pasos = struct( ...
        'N',   [1/18 1/18], ...                % 18 pasos enteros (2 a 20)
        'a',   [1e-6/90e-6 5e-6/90e-6], ...    % paso de 1 um (10 a 100 um)
        'd',   [5e-6/380e-6 20e-6/380e-6], ... % paso de 5 um (20 a 400 um)
        'lam', [5e-9/300e-9 25e-9/300e-9], ... % paso de 5 nm (400 a 700 nm)
        'X',   [0.05/4.5 0.25/4.5]);           % paso de 0.05 m (0.5 a 5 m)

    campos = {'N', 'a', 'd', 'lam', 'X'};

    % ---------------------------------------------------------------------
    % CACHE. FV.red resuelve simbolico (~30 ms). Se memoiza con containers.Map.
    % ---------------------------------------------------------------------
    cacheRed = containers.Map('KeyType','char','ValueType','any');
    MAX_ORD = 15;

    % Rango espacial fijo de la pantalla en milimetros [mm]
    yLim_mm = 70.0;
    N_pts = 3001;
    N_filas_img = 35;
    y_mm = linspace(-yLim_mm, yLim_mm, N_pts);
    y_m  = y_mm * 1e-3; % conversion a metros [m] para calculo en SI base

    % Pre-poblado de cache para valores por defecto
    for nIni = 1:MAX_ORD
        if nIni * D.lam < D.d
            resolverThRed(D.d, nIni, D.lam);
        end
    end

    if strcmpi(modo, 'exportar')
        exportar();
        return;
    end

    % ---------------------------------------------------------------------
    % INTERFAZ GRAFICA INTERACTIVA
    % Todo en ASCII pelado: sin tildes ni enies para evitar basura visual.
    % ---------------------------------------------------------------------
    fig = figure('Name','Difraccion e Interferencia de N Rendijas y Emisores', ...
        'NumberTitle','off', 'Color','w', ...
        'Position',[50 30 1280 820]);

    % Panel 1: La rendija (arriba izquierda)
    axRendija = axes('Parent',fig, 'Position',[0.05 0.58 0.42 0.35]);

    % Panel 2: El patron (arriba derecha)
    axPatron = axes('Parent',fig, 'Position',[0.53 0.58 0.43 0.35]);

    % Panel 3: La pantalla (medio, ancho completo)
    axPantalla = axes('Parent',fig, 'Position',[0.05 0.43 0.91 0.09]);

    % --- Panel Inferior 1: Controles de Barrera y Modo (izquierda) ---
    panBarrera = uipanel('Parent',fig, 'Title','Barrera y Modo de Iluminacion', ...
        'Units','normalized', 'Position',[0.05 0.03 0.26 0.36], ...
        'BackgroundColor','w', 'ForegroundColor','k');

    % Control de Modo: Coherente / Incoherente
    uicontrol('Parent',panBarrera, 'Style','text', ...
        'Units','normalized', 'Position',[0.04 0.91 0.92 0.05], ...
        'HorizontalAlignment','left', 'BackgroundColor','w', 'ForegroundColor','k', ...
        'FontWeight','bold', 'FontSize',8.5, ...
        'String','Modo de iluminacion:');

    hPopModo = uicontrol('Parent',panBarrera, 'Style','popupmenu', ...
        'Units','normalized', 'Position',[0.04 0.83 0.92 0.07], ...
        'String',{'Coherente (suma amplitudes E)', 'Incoherente (suma intensidades I)'}, ...
        'Value',1, 'BackgroundColor','w', 'ForegroundColor','k', ...
        'Tag','popModo', ...
        'Callback', @(src,~) cambiarModo(get(src,'Value')));

    % Sliders de la barrera (N, a, d, lam, X)
    hLab = gobjects(1, 5);
    hSli = gobjects(1, 5);
    ySlots = [0.69, 0.55, 0.41, 0.27, 0.13];

    for iSli = 1:5
        c = campos{iSli};
        rg = R.(c);
        hLab(iSli) = uicontrol('Parent',panBarrera, 'Style','text', ...
            'Units','normalized', 'Position',[0.04 ySlots(iSli)+0.06 0.92 0.05], ...
            'HorizontalAlignment','left', ...
            'BackgroundColor','w', 'ForegroundColor','k', ...
            'FontWeight','bold', 'FontSize',8);

        hSli(iSli) = uicontrol('Parent',panBarrera, 'Style','slider', ...
            'Units','normalized', 'Position',[0.04 ySlots(iSli) 0.92 0.05], ...
            'Min',rg(1), 'Max',rg(2), 'Value',P.(c), ...
            'BackgroundColor',[0.94 0.94 0.94], ...
            'SliderStep',pasos.(c), ...
            'Tag',['sli_' c], ...
            'Callback', @(src,~) moverSlider(iSli, get(src,'Value')));
    end

    % Boton Restaurar al pie de panBarrera
    uicontrol('Parent',panBarrera, 'Style','pushbutton', 'String','Restaurar', ...
        'Units','normalized', 'Position',[0.20 0.01 0.60 0.08], ...
        'BackgroundColor','w', 'ForegroundColor','k', ...
        'FontWeight','bold', 'FontSize',8.5, ...
        'Callback', @(~,~) restaurar());

    % --- Panel Inferior 2: Emisores Extra en Pestanias (centro) ---
    panExtra = uipanel('Parent',fig, 'Title','Emisores Extra en el Tabique', ...
        'Units','normalized', 'Position',[0.32 0.03 0.43 0.36], ...
        'BackgroundColor','w', 'ForegroundColor','k');

    uicontrol('Parent',panExtra, 'Style','text', ...
        'Units','normalized', 'Position',[0.03 0.89 0.48 0.08], ...
        'HorizontalAlignment','left', 'BackgroundColor','w', 'ForegroundColor','k', ...
        'FontWeight','bold', 'FontSize',8.5, ...
        'String','Emisores extra activos:');

    hPopNextra = uicontrol('Parent',panExtra, 'Style','popupmenu', ...
        'Units','normalized', 'Position',[0.52 0.89 0.45 0.08], ...
        'String',{'0 (sin emisores extra)', '1 emisor extra', '2 emisores extra', ...
                  '3 emisores extra', '4 emisores extra'}, ...
        'Value',P.Nextra + 1, 'BackgroundColor','w', 'ForegroundColor','k', ...
        'Tag','popNextra', ...
        'Callback', @(src,~) cambiarNextra(get(src,'Value') - 1));

    % Grupo de pestanias (uitabgroup) con fondo blanco forzado
    tabGroup = uitabgroup('Parent',panExtra, 'Units','normalized', ...
        'Position',[0.03 0.02 0.94 0.84]);

    hPopEntre = gobjects(1, 4);
    hLabT     = gobjects(1, 4);  hSliT     = gobjects(1, 4);
    hLabA     = gobjects(1, 4);  hSliA     = gobjects(1, 4);
    hLabAmp   = gobjects(1, 4);  hSliAmp   = gobjects(1, 4);
    hLabFase  = gobjects(1, 4);  hSliFase  = gobjects(1, 4);
    hLabLam   = gobjects(1, 4);  hSliLam   = gobjects(1, 4);

    opcionesEntreIni = arrayfun(@(k) sprintf('Entre rendija %d y %d', k, k+1), ...
        1:(P.N-1), 'UniformOutput', false);

    for iTab = 1:4
        tabObj = uitab('Parent',tabGroup, 'Title',sprintf('Emisor %d', iTab), ...
            'BackgroundColor','w', 'ForegroundColor','k');

        % Columna Izquierda de la pestania: Ubicacion, fraccion t, ancho a
        uicontrol('Parent',tabObj, 'Style','text', ...
            'Units','normalized', 'Position',[0.03 0.82 0.45 0.12], ...
            'HorizontalAlignment','left', 'BackgroundColor','w', 'ForegroundColor','k', ...
            'FontWeight','bold', 'FontSize',7.5, 'String','Entre rendijas:');

        hPopEntre(iTab) = uicontrol('Parent',tabObj, 'Style','popupmenu', ...
            'Units','normalized', 'Position',[0.03 0.68 0.45 0.13], ...
            'String',opcionesEntreIni, 'Value',P.extra(iTab).entre, ...
            'BackgroundColor','w', 'ForegroundColor','k', ...
            'Callback', @(src,~) cambiarEntre(iTab, get(src,'Value')));

        hLabT(iTab) = uicontrol('Parent',tabObj, 'Style','text', ...
            'Units','normalized', 'Position',[0.03 0.48 0.45 0.12], ...
            'HorizontalAlignment','left', 'BackgroundColor','w', 'ForegroundColor','k', ...
            'FontWeight','bold', 'FontSize',7.5);

        hSliT(iTab) = uicontrol('Parent',tabObj, 'Style','slider', ...
            'Units','normalized', 'Position',[0.03 0.35 0.45 0.12], ...
            'Min',0.0, 'Max',1.0, 'Value',P.extra(iTab).t, ...
            'BackgroundColor',[0.94 0.94 0.94], 'SliderStep',[0.02 0.10], ...
            'Callback', @(src,~) moverSliExtra(iTab, 't', get(src,'Value')));

        hLabA(iTab) = uicontrol('Parent',tabObj, 'Style','text', ...
            'Units','normalized', 'Position',[0.03 0.17 0.45 0.12], ...
            'HorizontalAlignment','left', 'BackgroundColor','w', 'ForegroundColor','k', ...
            'FontWeight','bold', 'FontSize',7.5);

        hSliA(iTab) = uicontrol('Parent',tabObj, 'Style','slider', ...
            'Units','normalized', 'Position',[0.03 0.04 0.45 0.12], ...
            'Min',5e-6, 'Max',50e-6, 'Value',P.extra(iTab).a, ...
            'BackgroundColor',[0.94 0.94 0.94], 'SliderStep',[1/45 5/45], ...
            'Callback', @(src,~) moverSliExtra(iTab, 'a', get(src,'Value')));

        % Columna Derecha de la pestania: Amplitud A, fase inicial, longitud de onda lam
        hLabAmp(iTab) = uicontrol('Parent',tabObj, 'Style','text', ...
            'Units','normalized', 'Position',[0.52 0.82 0.45 0.12], ...
            'HorizontalAlignment','left', 'BackgroundColor','w', 'ForegroundColor','k', ...
            'FontWeight','bold', 'FontSize',7.5);

        hSliAmp(iTab) = uicontrol('Parent',tabObj, 'Style','slider', ...
            'Units','normalized', 'Position',[0.52 0.68 0.45 0.12], ...
            'Min',0.1, 'Max',2.0, 'Value',P.extra(iTab).A, ...
            'BackgroundColor',[0.94 0.94 0.94], 'SliderStep',[0.05/1.9 0.2/1.9], ...
            'Callback', @(src,~) moverSliExtra(iTab, 'A', get(src,'Value')));

        hLabFase(iTab) = uicontrol('Parent',tabObj, 'Style','text', ...
            'Units','normalized', 'Position',[0.52 0.48 0.45 0.12], ...
            'HorizontalAlignment','left', 'BackgroundColor','w', 'ForegroundColor','k', ...
            'FontWeight','bold', 'FontSize',7.5);

        hSliFase(iTab) = uicontrol('Parent',tabObj, 'Style','slider', ...
            'Units','normalized', 'Position',[0.52 0.35 0.45 0.12], ...
            'Min',0.0, 'Max',2*pi, 'Value',P.extra(iTab).fase, ...
            'BackgroundColor',[0.94 0.94 0.94], 'SliderStep',[0.1/(2*pi) 0.5/(2*pi)], ...
            'Callback', @(src,~) moverSliExtra(iTab, 'fase', get(src,'Value')));

        hLabLam(iTab) = uicontrol('Parent',tabObj, 'Style','text', ...
            'Units','normalized', 'Position',[0.52 0.17 0.45 0.12], ...
            'HorizontalAlignment','left', 'BackgroundColor','w', 'ForegroundColor','k', ...
            'FontWeight','bold', 'FontSize',7.5);

        hSliLam(iTab) = uicontrol('Parent',tabObj, 'Style','slider', ...
            'Units','normalized', 'Position',[0.52 0.04 0.45 0.12], ...
            'Min',400e-9, 'Max',700e-9, 'Value',P.extra(iTab).lam, ...
            'BackgroundColor',[0.94 0.94 0.94], 'SliderStep',[5/300 25/300], ...
            'Callback', @(src,~) moverSliExtra(iTab, 'lam', get(src,'Value')));
    end

    % --- Panel Inferior 3: Lectura Numerica y Visibilidad (derecha) ---
    panInfo = uipanel('Parent',fig, 'Title','Lectura y Visibilidad', ...
        'Units','normalized', 'Position',[0.76 0.03 0.20 0.36], ...
        'BackgroundColor','w', 'ForegroundColor','k');

    hLabTxtInfo = uicontrol('Parent',panInfo, 'Style','text', ...
        'Units','normalized', 'Position',[0.03 0.02 0.94 0.96], ...
        'HorizontalAlignment','left', ...
        'BackgroundColor','w', 'ForegroundColor','k', ...
        'FontName','FixedWidth', 'FontSize',7.5);

    % ---------------------------------------------------------------------
    % CREACION UNICA DE OBJETOS GRAFICOS (HANDLES PERSISTENTES EN STRUCT h)
    % Cero llamadas a cla() en callbacks para panel 2 y panel 3.
    % ---------------------------------------------------------------------
    h = struct();

    % --- Panel 2: Curva de intensidad I(y), envolvente y marcas ---
    hold(axPatron, 'on');
    grid(axPatron, 'on');
    xlim(axPatron, [-yLim_mm, yLim_mm]);
    ylim(axPatron, [0 1.25]);
    xlabel(axPatron, 'y [mm] (posicion en la pantalla)', 'Color',[0.15 0.15 0.15]);
    ylabel(axPatron, 'Intensidad relativa I/I_0 [-]', 'Color',[0.15 0.15 0.15]);
    estiloEje(axPatron);

    % Linea para marcas verticales de maximos principales
    h.lineasMax = plot(axPatron, NaN, NaN, ':', 'Color',[0.50 0.50 0.50], ...
        'LineWidth',1.0);

    % Pre-asignacion de objetos text para ordenes -MAX_ORD a +MAX_ORD
    numMarcas = 2 * MAX_ORD + 1;
    h.txtMarcas = gobjects(1, numMarcas);
    for km = 1:numMarcas
        h.txtMarcas(km) = text(0, 0, '', 'Parent',axPatron, ...
            'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
            'FontSize',7.5, 'Color',[0.20 0.20 0.20], 'Visible','off');
    end

    % Curva principal de intensidad y envolvente de difraccion
    h.curva = plot(axPatron, y_mm, zeros(size(y_mm)), '-', ...
        'Color',[0.10 0.35 0.85], 'LineWidth',1.4);
    h.envolvente = plot(axPatron, y_mm, zeros(size(y_mm)), '--', ...
        'Color',[0.85 0.25 0.15], 'LineWidth',1.3);

    h.leyenda = legend(axPatron, [h.curva, h.envolvente], ...
        {'I(y) (patron total)', 'Envolvente (1 rendija)'}, ...
        'Location','northeast', 'Color','none', 'Box','off', ...
        'TextColor',[0.15 0.15 0.15], 'FontSize',8);

    % --- Panel 3: La pantalla como se ve con imagesc ---
    I_ini = zeros(1, N_pts);
    h.img = imagesc(axPantalla, 'XData',[-yLim_mm yLim_mm], 'YData',[-1 1], ...
        'CData',repmat(I_ini, [N_filas_img 1]));
    colormap(axPantalla, 'hot');
    clim(axPantalla, [0 1]);
    xlim(axPantalla, [-yLim_mm, yLim_mm]);
    ylim(axPantalla, [-1 1]);
    set(axPantalla, 'YTick',[]);
    xlabel(axPantalla, 'y [mm] (distribucion espacial de luz en la pantalla)', ...
        'Color',[0.15 0.15 0.15]);
    title(axPantalla, ...
        'Foto de la pantalla: franjas de interferencia moduladas por la difraccion', ...
        'Color',[0.15 0.15 0.15], 'FontSize',9);
    estiloEje(axPantalla);

    % Paleta de colores distintivos para emisores extra
    coloresExtra = [ ...
        0.95 0.20 0.85; ... % magenta (Emisor 1)
        0.10 0.80 0.95; ... % cian    (Emisor 2)
        0.95 0.55 0.10; ... % naranja (Emisor 3)
        0.90 0.85 0.15];    % amarillo(Emisor 4)

    % Variables para manejo de la rendija (Panel 1)
    lastN = -1;
    lastNextra = -1;
    hRend = struct();

    % Sincronizacion inicial
    refrescar();

    % =====================================================================
    %  CALLBACKS DE CONTROL
    % =====================================================================

    function cambiarModo(val)
        if val == 1
            P.modo = 'coherente';
        else
            P.modo = 'incoherente';
        end
        refrescar();
    end

    function cambiarNextra(val)
        P.Nextra = val;
        refrescar();
    end

    function cambiarEntre(iTab, val)
        P.extra(iTab).entre = val;
        refrescar();
    end

    function moverSliExtra(iTab, param, val)
        switch param
            case 't'
                P.extra(iTab).t = round(val * 100) / 100;
                set(hSliT(iTab), 'Value', P.extra(iTab).t);
            case 'a'
                P.extra(iTab).a = round(val * 1e6) * 1e-6;
                set(hSliA(iTab), 'Value', P.extra(iTab).a);
            case 'A'
                P.extra(iTab).A = round(val * 20) / 20;
                set(hSliAmp(iTab), 'Value', P.extra(iTab).A);
            case 'fase'
                P.extra(iTab).fase = round(val * 100) / 100;
                set(hSliFase(iTab), 'Value', P.extra(iTab).fase);
            case 'lam'
                P.extra(iTab).lam = round(val * 1e9 / 5) * 5 * 1e-9;
                set(hSliLam(iTab), 'Value', P.extra(iTab).lam);
        end
        refrescar();
    end

    function moverSlider(idx, val)
        switch idx
            case 1  % N: cantidad de rendijas de barrera (entero)
                P.N = round(val);
                set(hSli(1), 'Value', P.N);

                % Actualizar opciones del popup de intervalos en las pestanias
                opciones = arrayfun(@(k) sprintf('Entre rendija %d y %d', k, k+1), ...
                    1:(P.N-1), 'UniformOutput', false);
                for kPop = 1:4
                    P.extra(kPop).entre = min(P.extra(kPop).entre, P.N - 1);
                    set(hPopEntre(kPop), 'String', opciones, 'Value', P.extra(kPop).entre);
                end

            case 2  % a: ancho de cada rendija [m]
                P.a = round(val * 1e6) * 1e-6;
                % FORZAR d > a SIEMPRE: rendijas solapadas no existen fisicamente
                if P.a >= P.d
                    P.d = min(R.d(2), P.a + 2e-6);
                    if P.a >= P.d
                        P.a = P.d - 2e-6;
                    end
                    set(hSli(3), 'Value', P.d);
                end
                set(hSli(2), 'Value', P.a);

            case 3  % d: separacion entre centros [m]
                P.d = round(val * 1e6 / 2) * 2 * 1e-6;
                % FORZAR d > a SIEMPRE: si el usuario cruza sliders, empuja al otro
                if P.d <= P.a
                    P.a = max(R.a(1), P.d - 2e-6);
                    if P.d <= P.a
                        P.d = P.a + 2e-6;
                    end
                    set(hSli(2), 'Value', P.a);
                end
                set(hSli(3), 'Value', P.d);

            case 4  % lam: longitud de onda [m]
                P.lam = round(val * 1e9 / 5) * 5 * 1e-9;
                set(hSli(4), 'Value', P.lam);

            case 5  % X: distancia a la pantalla [m]
                P.X = round(val * 20) / 20;
                set(hSli(5), 'Value', P.X);
        end
        refrescar();
    end

    function restaurar()
        P = D;
        for ks = 1:5
            set(hSli(ks), 'Value', P.(campos{ks}));
        end
        set(hPopModo, 'Value', 1);
        set(hPopNextra, 'Value', 1);

        opciones = arrayfun(@(k) sprintf('Entre rendija %d y %d', k, k+1), ...
            1:(P.N-1), 'UniformOutput', false);
        for kRes = 1:4
            set(hPopEntre(kRes), 'String', opciones, 'Value', P.extra(kRes).entre);
            set(hSliT(kRes), 'Value', P.extra(kRes).t);
            set(hSliA(kRes), 'Value', P.extra(kRes).a);
            set(hSliAmp(kRes), 'Value', P.extra(kRes).A);
            set(hSliFase(kRes), 'Value', P.extra(kRes).fase);
            set(hSliLam(kRes), 'Value', P.extra(kRes).lam);
        end
        refrescar();
    end

    % =====================================================================
    %  REFRESCAR: actualizacion veloz de graficos con handles existentes
    % =====================================================================

    function refrescar()
        % 1. Actualizar rotulos de sliders principales
        set(hLab(1), 'String', sprintf('N = %d rendijas', P.N));
        set(hLab(2), 'String', sprintf('a = %.1f um (ancho)', P.a * 1e6));
        set(hLab(3), 'String', sprintf('d = %.1f um (separacion)', P.d * 1e6));
        set(hLab(4), 'String', sprintf('lam = %d nm (longitud)', round(P.lam * 1e9)));
        set(hLab(5), 'String', sprintf('X = %.2f m (pantalla)', P.X));

        % Actualizar rotulos de pestanias extra
        for kEt = 1:4
            set(hLabT(kEt), 'String', ...
                sprintf('Posicion t = %.2f', P.extra(kEt).t));
            set(hLabA(kEt), 'String', ...
                sprintf('Ancho a = %.1f um', P.extra(kEt).a * 1e6));
            set(hLabAmp(kEt), 'String', ...
                sprintf('Amplitud A = %.2f', P.extra(kEt).A));
            set(hLabFase(kEt), 'String', ...
                sprintf('Fase = %.2f rad', P.extra(kEt).fase));
            set(hLabLam(kEt), 'String', ...
                sprintf('lam = %d nm', round(P.extra(kEt).lam * 1e9)));
        end

        % 2. Construir arreglo completo de emisores: primero las N rendijas,
        % luego los Nextra emisores intermedios.
        emTotal = repmat(struct('x',0,'a',0,'A',0,'fase',0,'lam',0), ...
            1, P.N + P.Nextra);

        % Las N rendijas de la barrera (en fase = 0, onda plana normal)
        for j = 1:P.N
            emTotal(j).x    = (j - (P.N + 1)/2) * P.d;
            emTotal(j).a    = P.a;
            emTotal(j).A    = 1.0;
            emTotal(j).fase = 0.0;
            emTotal(j).lam  = P.lam;
        end

        % Emisores extra: posicion x = x_k + t*d entre rendija k y k+1
        for kExt = 1:P.Nextra
            k_rend = min(P.extra(kExt).entre, P.N - 1);
            x_k = (k_rend - (P.N + 1)/2) * P.d;
            idx = P.N + kExt;
            emTotal(idx).x    = x_k + P.extra(kExt).t * P.d;
            emTotal(idx).a    = P.extra(kExt).a;
            emTotal(idx).A    = P.extra(kExt).A;
            emTotal(idx).fase = P.extra(kExt).fase;
            emTotal(idx).lam  = P.extra(kExt).lam;
        end

        % 3. Calculo de angulos y patron numerico
        th_vec = atan(y_m / P.X);
        [I_calc, ~] = FV.patronEmisores(emTotal, P.X, th_vec, P.modo);

        % Envolvente de una sola rendija de la barrera (referencia teorica)
        be_vec = pi * P.a * sin(th_vec) / P.lam;
        env_calc = (sin(be_vec) ./ be_vec).^2;
        env_calc(abs(be_vec) < 1e-12) = 1;

        % 4. Actualizar curvas en Panel 2 (cero cla())
        set(h.curva, 'XData', y_mm, 'YData', I_calc);
        set(h.envolvente, 'XData', y_mm, 'YData', env_calc);

        colLam = lam2rgb(P.lam);
        set(h.curva, 'Color', colLam * 0.85);

        % Marcas de maximos principales (FV.red de la red base de separacion d)
        n_max_fis = floor(P.d / P.lam);
        rel_da = P.d / P.a;
        esEntero = abs(rel_da - round(rel_da)) < 0.05;
        mFaltante = round(rel_da);

        xLines = nan(1, 3 * numMarcas);
        yLines = nan(1, 3 * numMarcas);
        idxLine = 1;
        txtIdx = 1;

        for ord = -MAX_ORD:MAX_ORD
            if abs(ord) > n_max_fis
                set(h.txtMarcas(txtIdx), 'Visible','off');
                txtIdx = txtIdx + 1;
                continue;
            end

            th_ord = resolverThRed(P.d, abs(ord), P.lam);
            y_ord_mm = sign(ord) * P.X * tan(th_ord) * 1e3;

            if abs(y_ord_mm) <= yLim_mm
                xLines(idxLine)   = y_ord_mm;
                yLines(idxLine)   = 0;
                xLines(idxLine+1) = y_ord_mm;
                yLines(idxLine+1) = 1.05;
                idxLine = idxLine + 3;

                if ord == 0
                    strOrd = 'n=0';
                elseif esEntero && mod(abs(ord), mFaltante) == 0
                    strOrd = sprintf('n=%d\n(falta)', ord);
                else
                    strOrd = sprintf('n=%d', ord);
                end

                set(h.txtMarcas(txtIdx), 'Position',[y_ord_mm, 1.06, 0], ...
                    'String',strOrd, 'Visible','on');
            else
                set(h.txtMarcas(txtIdx), 'Visible','off');
            end
            txtIdx = txtIdx + 1;
        end

        set(h.lineasMax, 'XData', xLines, 'YData', yLines);

        title(axPatron, ...
            sprintf('Patron I(y) [%s] (N = %d, extras = %d)', ...
            upper(P.modo), P.N, P.Nextra), 'Color',[0.15 0.15 0.15]);

        % 5. Actualizar imagen en Panel 3 (cero cla())
        set(h.img, 'XData', y_mm, 'CData', repmat(I_calc, [N_filas_img 1]));

        % 6. Actualizar Panel 1: La Rendija con emisores extra
        actualizarRendija();

        % 7. Calculo de Visibilidad en zona central y lectura numerica
        Dy_mm = (P.X * P.lam / P.d) * 1e3;
        n_sec = P.N - 2;

        % Zona central: intervalo entre el pico central y el primer minimo
        zonaCen = abs(y_mm) <= max(0.6 * Dy_mm, 4.0);
        I_cen = I_calc(zonaCen);
        Imax_c = max(I_cen);
        Imin_c = min(I_cen);
        if (Imax_c + Imin_c) > 1e-12
            visib = (Imax_c - Imin_c) / (Imax_c + Imin_c);
        else
            visib = 0;
        end

        if esEntero
            txtFalt = sprintf('m=%d', mFaltante);
        else
            txtFalt = 'Ninguno';
        end

        strInfo = sprintf([ ...
            'LECTURA Y VISIBILIDAD\n' ...
            '-----------------------\n' ...
            'Modo     : %s\n' ...
            'Barrera  : N = %d\n' ...
            'Extras   : %d\n' ...
            'Total    : %d fuentes\n' ...
            'Visib. V : %.1f %%\n' ...
            '-----------------------\n' ...
            'a barrera: %.1f um\n' ...
            'd centros: %.1f um\n' ...
            'lam      : %d nm\n' ...
            'X pant.  : %.2f m\n' ...
            'd/a      : %.2f\n' ...
            'Dy max.  : %.2f mm\n' ...
            'Max. sec.: %d\n' ...
            'Faltante : %s\n' ...
            '-----------------------\n' ...
            '* Coherente: suma E.\n' ...
            '* Incoher.: suma I\n' ...
            '  (V colapsa ~ 0).\n' ...
            '* Extra: x=x_k+t*d'], ...
            upper(P.modo), P.N, P.Nextra, P.N + P.Nextra, visib * 100, ...
            P.a*1e6, P.d*1e6, round(P.lam*1e9), P.X, rel_da, Dy_mm, ...
            n_sec, txtFalt);

        set(hLabTxtInfo, 'String', strInfo);
    end

    % =====================================================================
    %  PANEL 1: LA RENDIJA A ESCALA (VISTA FRONTAL)
    % =====================================================================

    function actualizarRendija()
        colLam = lam2rgb(P.lam);
        H_slit = 260; % altura rendija [um]
        H_barr = 380; % altura barrera [um]

        % Centros de las N aberturas de la barrera en micrometros [um]
        xc = ((1:P.N) - (P.N + 1) / 2) * P.d * 1e6;
        W_total = ((P.N - 1) * P.d + P.a) * 1e6;
        W_barr = max(1.5 * W_total, 2.5 * P.d * 1e6);
        x_lim = max(W_barr / 2 * 1.15, 60);

        if P.N ~= lastN || P.Nextra ~= lastNextra
            % EXCEPCION PERMITIDA: solo aqui se borra y rehace porque
            % cambia la cantidad fisica de aberturas N o emisores extra.
            cla(axRendija);
            hold(axRendija, 'on');

            % Barrera opaca oscura
            hRend.barrier = rectangle('Parent',axRendija, ...
                'Position',[-W_barr/2, -H_barr/2, W_barr, H_barr], ...
                'FaceColor',[0.22 0.24 0.28], 'EdgeColor',[0.10 0.10 0.10], ...
                'LineWidth',1.0);

            % Aberturas luminosas de la barrera (verde / color de P.lam)
            hRend.slits = gobjects(1, P.N);
            for kr = 1:P.N
                hRend.slits(kr) = rectangle('Parent',axRendija, ...
                    'Position',[xc(kr) - (P.a*1e6)/2, -H_slit/2, P.a*1e6, H_slit], ...
                    'FaceColor',colLam, 'EdgeColor','none');
            end

            % Emisores extra activos en colores distintivos
            hRend.extraRect = gobjects(1, P.Nextra);
            hRend.extraTxt  = gobjects(1, P.Nextra);
            for kx = 1:P.Nextra
                k_r = min(P.extra(kx).entre, P.N - 1);
                x_kr = (k_r - (P.N + 1)/2) * P.d * 1e6;
                x_extra = x_kr + P.extra(kx).t * P.d * 1e6;
                w_extra = P.extra(kx).a * 1e6;

                hRend.extraRect(kx) = rectangle('Parent',axRendija, ...
                    'Position',[x_extra - w_extra/2, -H_slit/2, w_extra, H_slit], ...
                    'FaceColor',coloresExtra(kx,:), 'EdgeColor',[1 1 1], ...
                    'LineWidth',0.8);

                hRend.extraTxt(kx) = text(x_extra, H_slit/2 + 18, sprintf('E%d', kx), ...
                    'Parent',axRendija, 'HorizontalAlignment','center', ...
                    'Color',coloresExtra(kx,:), 'FontSize',8, 'FontWeight','bold');
            end

            % Cota de separacion entre centros d (entre aberturas 1 y 2)
            hRend.lineaD = plot(axRendija, [xc(1) xc(2)], [H_slit/2 + 35, H_slit/2 + 35], ...
                '|-', 'Color',[0.85 0.20 0.15], 'LineWidth',1.2);
            hRend.txtD = text(mean(xc(1:2)), H_slit/2 + 55, sprintf('d = %.1f um', P.d*1e6), ...
                'Parent',axRendija, 'HorizontalAlignment','center', ...
                'Color',[0.85 0.20 0.15], 'FontSize',8, 'FontWeight','bold');

            % Cota de ancho a (en abertura 1)
            x1_a = xc(1) - (P.a*1e6)/2;
            x2_a = xc(1) + (P.a*1e6)/2;
            hRend.lineaA = plot(axRendija, [x1_a x2_a], [-H_slit/2 - 25, -H_slit/2 - 25], ...
                '|-', 'Color',[0.15 0.45 0.85], 'LineWidth',1.2);
            hRend.txtA = text(xc(1), -H_slit/2 - 45, sprintf('a = %.1f um', P.a*1e6), ...
                'Parent',axRendija, 'HorizontalAlignment','center', ...
                'Color',[0.15 0.45 0.85], 'FontSize',8, 'FontWeight','bold');

            lastN = P.N;
            lastNextra = P.Nextra;
        else
            % N y Nextra no cambiaron: actualizar propiedades directamente
            set(hRend.barrier, 'Position',[-W_barr/2, -H_barr/2, W_barr, H_barr]);
            for kr = 1:P.N
                set(hRend.slits(kr), ...
                    'Position',[xc(kr) - (P.a*1e6)/2, -H_slit/2, P.a*1e6, H_slit], ...
                    'FaceColor',colLam);
            end
            for kx = 1:P.Nextra
                k_r = min(P.extra(kx).entre, P.N - 1);
                x_kr = (k_r - (P.N + 1)/2) * P.d * 1e6;
                x_extra = x_kr + P.extra(kx).t * P.d * 1e6;
                w_extra = P.extra(kx).a * 1e6;

                set(hRend.extraRect(kx), ...
                    'Position',[x_extra - w_extra/2, -H_slit/2, w_extra, H_slit]);
                set(hRend.extraTxt(kx), 'Position',[x_extra, H_slit/2 + 18, 0]);
            end

            set(hRend.lineaD, 'XData',[xc(1) xc(2)], 'YData',[H_slit/2 + 35, H_slit/2 + 35]);
            set(hRend.txtD, 'Position',[mean(xc(1:2)), H_slit/2 + 55, 0], ...
                'String',sprintf('d = %.1f um', P.d*1e6));

            x1_a = xc(1) - (P.a*1e6)/2;
            x2_a = xc(1) + (P.a*1e6)/2;
            set(hRend.lineaA, 'XData',[x1_a x2_a], 'YData',[-H_slit/2 - 25, -H_slit/2 - 25]);
            set(hRend.txtA, 'Position',[xc(1), -H_slit/2 - 45, 0], ...
                'String',sprintf('a = %.1f um', P.a*1e6));
        end

        xlim(axRendija, [-x_lim, x_lim]);
        ylim(axRendija, [-H_barr/2 - 65, H_barr/2 + 75]);
        xlabel(axRendija, 'x [um] (vista frontal de la barrera)', ...
            'Color',[0.15 0.15 0.15]);
        ylabel(axRendija, 'y [um]', 'Color',[0.15 0.15 0.15]);
        title(axRendija, ...
            sprintf('Barrera: N = %d  |  Extras = %d  |  a = %.1f um  |  d = %.1f um', ...
            P.N, P.Nextra, P.a*1e6, P.d*1e6), 'Color',[0.15 0.15 0.15]);
        estiloEje(axRendija);
    end

    % =====================================================================
    %  MEMOIZACION DE FV.red (RESUELVE SIMBOLICO UNA VEZ POR PARAMETRO)
    % =====================================================================

    function th = resolverThRed(d_val, n_val, lam_val)
        if n_val == 0
            th = 0;
            return;
        end
        if n_val * lam_val >= d_val
            th = NaN;
            return;
        end

        clave = sprintf('%.5e_%.5e_%d', d_val, lam_val, n_val);
        if cacheRed.isKey(clave)
            th = cacheRed(clave);
        else
            wst = warning('off', 'all');
            r = FV.red('d', d_val, 'n', n_val, 'lam', lam_val);
            warning(wst);
            th = double(r.th);
            cacheRed(clave) = th;
        end
    end

    % =====================================================================
    %  ESTILO DE EJE: proteccion integral contra tema oscuro de MATLAB
    % =====================================================================

    function estiloEje(ax)
        set(ax, 'Color','w', ...
            'XColor',[0.15 0.15 0.15], 'YColor',[0.15 0.15 0.15], ...
            'GridColor',[0.70 0.70 0.70], 'GridAlpha',0.7);
        ax.Title.Color = [0.15 0.15 0.15];
        ax.XLabel.Color = [0.15 0.15 0.15];
        ax.YLabel.Color = [0.15 0.15 0.15];
    end

    % =====================================================================
    %  CONVERSOR FISICO: longitud de onda a color RGB aproximado
    % =====================================================================

    function rgb = lam2rgb(lam_m)
        w = lam_m * 1e9; % [nm]
        if w < 380 || w > 780
            rgb = [0.8 0.8 0.8];
            return;
        end
        if w >= 380 && w < 440
            r = -(w - 440) / (440 - 380); g = 0.0; b = 1.0;
        elseif w >= 440 && w < 490
            r = 0.0; g = (w - 440) / (490 - 440); b = 1.0;
        elseif w >= 490 && w < 510
            r = 0.0; g = 1.0; b = -(w - 510) / (510 - 490);
        elseif w >= 510 && w < 580
            r = (w - 510) / (580 - 510); g = 1.0; b = 0.0;
        elseif w >= 580 && w < 645
            r = 1.0; g = -(w - 645) / (645 - 580); b = 0.0;
        else
            r = 1.0; g = 0.0; b = 0.0;
        end
        if w < 420
            f = 0.3 + 0.7 * (w - 380) / (420 - 380);
        elseif w > 700
            f = 0.3 + 0.7 * (780 - w) / (780 - 700);
        else
            f = 1.0;
        end
        rgb = [r g b] * f;
    end

    % =====================================================================
    %  MODO EXPORTAR: render estatico en figs/sim3_nRendijas.png sin ventana
    % =====================================================================

    function exportar()
        if ~isfolder('figs'), mkdir('figs'); end

        figExp = figure('Color','w', 'Position',[80 60 1240 800], ...
            'Visible','off');

        % Panel 1: La Rendija (arriba izquierda)
        axRend = axes('Parent',figExp, 'Position',[0.06 0.54 0.40 0.38]);
        colL = lam2rgb(P.lam);
        H_slit = 260; H_barr = 380;
        xc_exp = ((1:P.N) - (P.N + 1) / 2) * P.d * 1e6;
        W_tot_exp = ((P.N - 1) * P.d + P.a) * 1e6;
        W_b_exp = max(1.5 * W_tot_exp, 2.5 * P.d * 1e6);
        xlim_exp = max(W_b_exp / 2 * 1.15, 60);

        hold(axRend, 'on');
        rectangle('Parent',axRend, 'Position',[-W_b_exp/2, -H_barr/2, W_b_exp, H_barr], ...
            'FaceColor',[0.22 0.24 0.28], 'EdgeColor',[0.10 0.10 0.10], 'LineWidth',1.0);
        for kSlit = 1:P.N
            rectangle('Parent',axRend, ...
                'Position',[xc_exp(kSlit) - (P.a*1e6)/2, -H_slit/2, P.a*1e6, H_slit], ...
                'FaceColor',colL, 'EdgeColor','none');
        end
        plot(axRend, [xc_exp(1) xc_exp(2)], [H_slit/2 + 25, H_slit/2 + 25], ...
            '|-', 'Color',[0.85 0.20 0.15], 'LineWidth',1.2);
        text(mean(xc_exp(1:2)), H_slit/2 + 45, sprintf('d = %.1f um', P.d*1e6), ...
            'Parent',axRend, 'HorizontalAlignment','center', ...
            'Color',[0.85 0.20 0.15], 'FontSize',8, 'FontWeight','bold');

        x1_a = xc_exp(1) - (P.a*1e6)/2;
        x2_a = xc_exp(1) + (P.a*1e6)/2;
        plot(axRend, [x1_a x2_a], [-H_slit/2 - 25, -H_slit/2 - 25], ...
            '|-', 'Color',[0.15 0.45 0.85], 'LineWidth',1.2);
        text(xc_exp(1), -H_slit/2 - 45, sprintf('a = %.1f um', P.a*1e6), ...
            'Parent',axRend, 'HorizontalAlignment','center', ...
            'Color',[0.15 0.45 0.85], 'FontSize',8, 'FontWeight','bold');

        xlim(axRend, [-xlim_exp, xlim_exp]);
        ylim(axRend, [-H_barr/2 - 65, H_barr/2 + 65]);
        xlabel(axRend, 'x [um] (vista frontal de la barrera)', 'Color',[0.15 0.15 0.15]);
        ylabel(axRend, 'y [um]', 'Color',[0.15 0.15 0.15]);
        title(axRend, ...
            sprintf('Barrera: N = %d rendijas  |  a = %.1f um  |  d = %.1f um', ...
            P.N, P.a*1e6, P.d*1e6), 'Color',[0.15 0.15 0.15]);
        estiloEje(axRend);

        % Panel 2: El Patron (arriba derecha)
        axPatr = axes('Parent',figExp, 'Position',[0.52 0.54 0.42 0.38]);
        hold(axPatr, 'on'); grid(axPatr, 'on');

        th_exp = atan(y_m / P.X);

        % Arreglo de emisores de la barrera para exportacion
        emExp = repmat(struct('x',0,'a',0,'A',0,'fase',0,'lam',0), 1, P.N);
        for jExp = 1:P.N
            emExp(jExp).x    = (jExp - (P.N + 1)/2) * P.d;
            emExp(jExp).a    = P.a;
            emExp(jExp).A    = 1.0;
            emExp(jExp).fase = 0.0;
            emExp(jExp).lam  = P.lam;
        end

        [I_exp, ~] = FV.patronEmisores(emExp, P.X, th_exp, P.modo);
        be_exp = pi * P.a * sin(th_exp) / P.lam;
        env_exp = (sin(be_exp) ./ be_exp).^2;
        env_exp(abs(be_exp) < 1e-12) = 1;

        n_max_f = floor(P.d / P.lam);
        rel_da_exp = P.d / P.a;
        esInt_exp = abs(rel_da_exp - round(rel_da_exp)) < 0.05;
        mFalt_exp = round(rel_da_exp);

        for ord = -MAX_ORD:MAX_ORD
            if abs(ord) > n_max_f, continue; end
            th_o = resolverThRed(P.d, abs(ord), P.lam);
            y_o_mm = sign(ord) * P.X * tan(th_o) * 1e3;
            if abs(y_o_mm) <= yLim_mm
                plot(axPatr, [y_o_mm y_o_mm], [0 1.05], ':', ...
                    'Color',[0.50 0.50 0.50], 'LineWidth',1.0);
                if ord == 0
                    sOrd = 'n=0';
                elseif esInt_exp && mod(abs(ord), mFalt_exp) == 0
                    sOrd = sprintf('n=%d\n(falta)', ord);
                else
                    sOrd = sprintf('n=%d', ord);
                end
                text(y_o_mm, 1.06, sOrd, 'Parent',axPatr, ...
                    'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
                    'FontSize',7.5, 'Color',[0.20 0.20 0.20]);
            end
        end

        pCurva = plot(axPatr, y_mm, I_exp, '-', 'Color',colL*0.85, 'LineWidth',1.4);
        pEnvol = plot(axPatr, y_mm, env_exp, '--', 'Color',[0.85 0.25 0.15], 'LineWidth',1.3);
        legend(axPatr, [pCurva, pEnvol], {'I(y) (patron total)', 'Envolvente (1 rendija)'}, ...
            'Location','northeast', 'Color','none', 'Box','off', ...
            'TextColor',[0.15 0.15 0.15], 'FontSize',8);

        xlim(axPatr, [-yLim_mm, yLim_mm]);
        ylim(axPatr, [0 1.25]);
        xlabel(axPatr, 'y [mm] (posicion en la pantalla)', 'Color',[0.15 0.15 0.15]);
        ylabel(axPatr, 'Intensidad relativa I/I_0 [-]', 'Color',[0.15 0.15 0.15]);
        title(axPatr, ...
            sprintf('Patron I(y) [%s] (N = %d, d/a = %.2f)', ...
            upper(P.modo), P.N, rel_da_exp), 'Color',[0.15 0.15 0.15]);
        estiloEje(axPatr);

        % Panel 3: La Pantalla (medio, ancho completo)
        axPant = axes('Parent',figExp, 'Position',[0.06 0.35 0.88 0.11]);
        imagesc(axPant, 'XData',[-yLim_mm yLim_mm], 'YData',[-1 1], ...
            'CData',repmat(I_exp, [N_filas_img 1]));
        colormap(axPant, 'hot');
        clim(axPant, [0 1]);
        xlim(axPant, [-yLim_mm, yLim_mm]);
        ylim(axPant, [-1 1]);
        set(axPant, 'YTick',[]);
        xlabel(axPant, 'y [mm] en la pantalla', 'Color',[0.15 0.15 0.15]);
        title(axPant, ...
            'Foto de la pantalla: franjas de interferencia moduladas por la difraccion', ...
            'Color',[0.15 0.15 0.15], 'FontSize',9);
        estiloEje(axPant);

        % Panel Inferior: Lectura numerica y teoria (en axes para exportgraphics limpio)
        axInf = axes('Parent',figExp, 'Position',[0.06 0.04 0.88 0.26]);
        axis(axInf, 'off');
        xlim(axInf, [0 1]);
        ylim(axInf, [0 1]);

        Dy_mm_exp = (P.X * P.lam / P.d) * 1e3;
        n_sec_exp = P.N - 2;

        zonaCen_exp = abs(y_mm) <= max(0.6 * Dy_mm_exp, 4.0);
        I_cen_exp = I_exp(zonaCen_exp);
        visib_exp = (max(I_cen_exp) - min(I_cen_exp)) / ...
                    max(max(I_cen_exp) + min(I_cen_exp), 1e-12);

        if esInt_exp
            txtF_exp = sprintf('SI: m = %d (y multiplos)', mFalt_exp);
        else
            txtF_exp = 'Ninguno (d/a no es entero)';
        end

        strIzq = sprintf([ ...
            'PARAMETROS DEL SISTEMA\n' ...
            '-------------------------------------------\n' ...
            'Modo de iluminacion         : %s\n' ...
            'Cantidad de rendijas (N)    : %d\n' ...
            'Emisores extra              : %d\n' ...
            'Ancho de cada rendija (a)   : %.1f um\n' ...
            'Separacion entre centros (d): %.1f um\n' ...
            'Longitud de onda (lam)      : %d nm\n' ...
            'Distancia a pantalla (X)    : %.2f m\n' ...
            'Relacion d/a                : %.2f'], ...
            upper(P.modo), P.N, P.Nextra, P.a*1e6, P.d*1e6, ...
            round(P.lam*1e9), P.X, rel_da_exp);

        strDer = sprintf([ ...
            'MEDIDAS Y CONCEPTOS FISICOS\n' ...
            '-------------------------------------------------------------\n' ...
            'Visibilidad de franjas (V)  : %.1f %%\n' ...
            'Separacion maximos Dy       : %.2f mm\n' ...
            'Maximos secundarios (N - 2) : %d entre cada par principal\n' ...
            'Ordenes faltantes           : %s\n' ...
            '* Coherente: suma amplitudes E y luego |E|^2.\n' ...
            '* Incoherente: suma intensidades, las franjas colapsan (V ~ 0).\n' ...
            '* Emisores extra permiten modelar arreglos no uniformes.'], ...
            visib_exp * 100, Dy_mm_exp, n_sec_exp, txtF_exp);

        text(0.01, 0.50, strIzq, 'Parent',axInf, ...
            'VerticalAlignment','middle', 'HorizontalAlignment','left', ...
            'BackgroundColor','w', 'EdgeColor',[0.70 0.70 0.70], ...
            'FontSize',8.5, 'FontName','FixedWidth', 'Color',[0.15 0.15 0.15], ...
            'Margin',6);

        text(0.50, 0.50, strDer, 'Parent',axInf, ...
            'VerticalAlignment','middle', 'HorizontalAlignment','left', ...
            'BackgroundColor','w', 'EdgeColor',[0.70 0.70 0.70], ...
            'FontSize',8.5, 'FontName','FixedWidth', 'Color',[0.15 0.15 0.15], ...
            'Margin',6);

        exportgraphics(figExp, fullfile('figs','sim3_nRendijas.png'), ...
            'Resolution',150);
        close(figExp);
    end
end
