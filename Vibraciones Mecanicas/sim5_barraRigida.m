function sim5_barraRigida(modo)
% SIM5_BARRARIGIDA - simulador interactivo del problema 5 de Tarea 2.
%
% Barra rigida horizontal articulada en A (extremo izquierdo). En B, a l/2,
% un resorte k que sube a un techo fijo. En D, a l, un amortiguador c que
% baja a un piso fijo. Anima el giro de la barra, dibuja theta(t) con su
% envolvente y deja barrer el amortiguamiento en vivo.
%
% USO:
%   sim5_barraRigida             % modo interactivo
%   sim5_barraRigida('exportar') % render fijo + GIF en ./figs/
%
% POR QUE ESTE SIMULADOR NO TIENE SLIDERS DE k, c, M NI l. El enunciado no
% da UN SOLO valor numerico: pide la ecuacion de movimiento general y el
% amortiguamiento critico, los dos simbolicos. Inventar un k o un l para
% poner un slider seria fabricar datos que el problema no da.
%
% Lo que si esta definido sin datos es la FORMA de la ecuacion. Cualquier
% sistema de 1 GDL, sea traslacional o rotacional, se normaliza a
%
%       theta'' + a*theta' + b*theta = 0
%
% y esa forma entra a VM como m = 1, c = a, k = b. El 1 no es una masa: es
% la normalizacion que deja el coeficiente de theta'' en la unidad. Los
% sliders mueven los COEFICIENTES REDUCIDOS en la parametrizacion estandar
% (zeta y wn), que es lo unico que el enunciado deja libre.
%
% Pasar de (wn, zeta) a (b, a) lo hace VM.genA, no este script.
%
% QUE HACE Y QUE NO HACE ESTE SIMULADOR. Toma los coeficientes reducidos
% como ENTRADA y muestra el movimiento que producen. NO reduce el sistema:
% no calcula el momento de inercia de la barra, ni los brazos de palanca,
% ni el critico en funcion de k, c, M y l. Eso es exactamente lo que el
% problema pide DERIVAR, y hacerlo aca seria resolverselo a Tiago.
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica es de VM.m:
%   VM.genA    despeja b y a (k y c) a partir de wn y zeta
%   VM.trayA   entrega theta(t), thetapunto(t) y los escalares del caso
%   VM.clasifA decide el regimen; llega por num.regimen, no se reimplementa
% Aca no se escribe ni una formula de vibraciones: si un numero hace falta,
% se le pide a VM.
%
% LOS VALORES DE REFERENCIA NO SE IMPRIMEN. Viven en variables de las
% funciones anidadas, asi que no quedan en el workspace ni salen por
% consola. La unica via para verlos es el boton "Revelar" de cada magnitud.

    if nargin < 1, modo = ''; end

    % ---------------------------------------------------------------------
    % DEFAULTS. Esta struct NO se sobrescribe nunca: es a donde vuelve el
    % boton "Restaurar". Los sliders trabajan sobre P, que es una copia.
    %
    % DECISION DE PRESENTACION, NO DATO INVENTADO. El enunciado no da
    % valores, asi que estos no salen de ningun lado: se eligen para que el
    % simulador arranque donde el problema pregunta.
    %   z  = 1  es el caso que pide la parte b (amortiguamiento critico)
    %   wn = 1  rad/s es la escala neutra: con wn = 1 los numeros de a y b
    %           quedan del orden de la unidad y se leen de un vistazo
    %   th0 y w0 son las condiciones iniciales. El enunciado tampoco las da
    %           y NO tienen slider: no son coeficientes de la ecuacion, solo
    %           deciden con que patada arranca el dibujo. Se fijan aca
    % ---------------------------------------------------------------------
    D = struct( ...
        'z',   1,    ...   % relacion de amortiguamiento           [-]
        'wn',  1,    ...   % frecuencia natural NO amortiguada     [rad/s]
        'th0', 0.05, ...   % angulo inicial theta(0)               [rad]
        'w0',  0);         % velocidad angular inicial thetapunto(0) [rad/s]

    P = D;   % parametros VIVOS, los que mueven los sliders

    % Rangos de los sliders: [minimo maximo]. z llega hasta 2 para cruzar
    % los tres regimenes; wn se mueve un factor 2 a cada lado de 1, que es
    % suficiente para ver que wn cambia la VELOCIDAD del movimiento sin
    % cambiar la FORMA de la curva (eso lo decide z solo).
    R = struct('z', [0 2], 'wn', [0.5 2]);

    NOM = {'z','wn'};            % orden de los sliders (nombres en VM)
    ETI = {'zeta','wn'};         % como se muestran: ASCII, ver mas abajo
    UNI = {'-','rad/s'};         % unidad de cada uno

    % tf del eje de tiempo: se fija UNA vez y no se recalcula. Asi, al mover
    % z o wn, la curva cambia contra una ventana temporal fija y se pueden
    % comparar; si tf siguiera a los parametros, el eje se reescalaria solo
    % y todas las curvas se verian iguales.
    % Se toma el DOBLE del tf que VM elige para los defaults, porque con wn
    % en el extremo bajo del slider (0.5 rad/s) el movimiento es lento y en
    % la ventana corta no entraria ni un ciclo.
    [tt0, th0v] = modelo(D);
    TF   = 2*tt0(end);            % tiempo final del grafico   [s]
    THREF = max(abs(th0v));       % amplitud de referencia     [rad]

    % ---------------------------------------------------------------------
    % GEOMETRIA DEL DIBUJO. TODO en UNIDADES DE DIBUJO, no en metros: el
    % enunciado no da l, asi que no hay metros que dibujar. La barra mide
    % LB unidades y el angulo real se mapea con ESC_ANG, una escala fija
    % elegida al inicio. Es dibujo, no fisica.
    % ---------------------------------------------------------------------
    G = struct( ...
        'XA',    1.4,  ...   % pivote A, coordenada x
        'YA',    0,    ...   % pivote A, coordenada y (barra horizontal)
        'LB',    6.6,  ...   % longitud total de la barra (representa l)
        'HB',    0.13, ...   % SEMI-espesor del rectangulo de la barra
        'YTECHO', 2.85, ...  % cara inferior del techo fijo
        'YPISO', -3.35, ...  % cara superior del piso fijo
        'YPIS0', -2.30, ...  % posicion del piston con la barra sin girar
        'RCIL',  0.35);      % SEMI-ancho del cilindro del amortiguador
    G.XB0 = G.XA + G.LB/2;   % punto B sin girar: a MEDIA longitud
    G.XD0 = G.XA + G.LB;     % punto D sin girar: a la longitud COMPLETA

    % ESC_ANG: cuantos radianes de DIBUJO vale un radian de theta. Se elige
    % para que la amplitud de los defaults llegue a ANG_MAX y no mas: con
    % thetapunto(0) = 0 el maximo de |theta| es siempre theta(0), asi que
    % esta escala vale para todo el barrido de z y de wn sin recalcularse.
    % ANG_MAX se queda en 8 grados por dos razones: el modelo supone angulo
    % pequenio, y con mas grados el extremo D se sale del cuadro.
    ANG_MAX = 8*pi/180;                      % giro maximo dibujado [rad]
    ESC_ANG = ANG_MAX/max(THREF, eps);       % factor de dibujo   [rad/rad]

    if strcmp(modo, 'exportar')
        exportar();
        return
    end

    % ---------------------------------------------------------------------
    % MAGNITUDES DEL PANEL DE COMPROBACION.
    % Lo que Tiago comprueba aca son SUS coeficientes reducidos: los que le
    % quedaron despues de reducir la barra a un solo grado de libertad.
    %   a : coeficiente de theta'   [1/s]
    %   b : coeficiente de theta    [1/s^2]
    % wn y zeta van tambien porque son la otra cara de los mismos dos
    % numeros, y porque son los que arman su curva cuando no escribe a y b.
    %
    % La referencia NO es un valor fijo del enunciado (no hay enunciado con
    % numeros): es la que fijan los sliders en cada momento. Se recalcula en
    % refrescar() y siempre sale de VM.
    % ---------------------------------------------------------------------
    MAG  = {'a','b','wn','z'};
    MAGU = {'1/s','1/s^2','rad/s','-'};
    % Etiquetas en ASCII pelado: uicontrol NO interpreta TeX, asi que un
    % '\theta' aca se ve literal como barra-theta. El TeX solo vale en
    % title, xlabel y demas texto de los EJES.
    MAGL = {'a (coef. de theta pto)','b (coef. de theta)','wn','zeta'};

    REF = struct('a',NaN, 'b',NaN, 'wn',NaN, 'z',NaN);   % la llena refrescar

    % ---------------------------------------------------------------------
    % FIGURA Y EJES
    % ---------------------------------------------------------------------
    tmr = [];   % handle del timer; se declara ANTES de la figura porque
                % cerrar() puede correr antes de que se lo asigne

    fig = figure('Name','Problema 5 - barra rigida articulada', ...
        'NumberTitle','off', 'Color','w', ...
        'Position',[60 60 1450 840], 'CloseRequestFcn',@cerrar);
    theme(fig,'light');   % fuerza tema claro: si no, con MATLAB en oscuro
                          % el area de los ejes sale negra (ver VM.graficarA)

    axAnim = axes('Parent',fig, 'Position',[0.04 0.47 0.42 0.49]);
    axResp = axes('Parent',fig, 'Position',[0.55 0.47 0.42 0.49]);

    % --- eje de la animacion ---------------------------------------------
    H = armarEscena(axAnim, G);   % dibuja lo fijo, devuelve lo que se mueve

    % --- eje de la respuesta temporal ------------------------------------
    hold(axResp,'on'); grid(axResp,'on');
    hEnvS = plot(axResp,nan,nan,'r--','LineWidth',1,'DisplayName','Envolvente');
    hEnvI = plot(axResp,nan,nan,'r--','LineWidth',1,'HandleVisibility','off');
    hCurv = plot(axResp,nan,nan,'-','Color',[0 0.30 0.65], ...
        'LineWidth',1.8,'DisplayName','\theta(t) de referencia');
    hMia  = plot(axResp,nan,nan,'--','Color',[0.85 0.33 0.10], ...
        'LineWidth',1.8,'DisplayName','tu solucion','Visible','off');
    hVert = plot(axResp,[nan nan],[nan nan],'-','Color',[0.6 0.6 0.6], ...
        'HandleVisibility','off');   % marcador vertical, fuera de la leyenda
    hPto  = plot(axResp,nan,nan,'o','MarkerSize',9, ...
        'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k', ...
        'HandleVisibility','off');
    xlabel(axResp,'t [s]'); ylabel(axResp,'\theta(t) [rad]');
    legend(axResp,'show','Location','northeast');
    set(axResp,'XLim',[0 TF],'Color','w','XColor','k','YColor','k', ...
        'GridColor',[0.5 0.5 0.5],'GridAlpha',1);

    % ---------------------------------------------------------------------
    % PANEL DE EXPLORACION
    % ---------------------------------------------------------------------
    panE = uipanel('Parent',fig,'Title','Exploracion', ...
        'FontWeight','bold','BackgroundColor','w', ...
        'Position',[0.04 0.03 0.42 0.40]);

    hRegim = uicontrol('Parent',panE,'Style','text','String','','Tag','regimen', ...
        'Units','normalized','Position',[0.02 0.84 0.96 0.13], ...
        'FontSize',12,'FontWeight','bold','BackgroundColor','w');

    hSli = gobjects(1,numel(NOM));   % handles de los sliders
    hLab = gobjects(1,numel(NOM));   % handles de las etiquetas
    for q = 1:numel(NOM)
        y = 0.64 - (q-1)*0.16;
        hLab(q) = uicontrol('Parent',panE,'Style','text', ...
            'Units','normalized','Position',[0.02 y 0.40 0.10], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',11);
        % Callback: la funcion recibe el handle del slider que la disparo;
        % el 'q' capturado dice CUAL parametro es.
        hSli(q) = uicontrol('Parent',panE,'Style','slider', ...
            'Units','normalized','Position',[0.44 y+0.01 0.54 0.08], ...
            'Tag',['sli_' NOM{q}], ...
            'Min',R.(NOM{q})(1),'Max',R.(NOM{q})(2),'Value',D.(NOM{q}), ...
            'Callback',@(s,~) moverSlider(q,get(s,'Value')));
    end

    uicontrol('Parent',panE,'Style','text','FontSize',9, ...
        'String',['El enunciado no da k, c, M ni l: los sliders mueven los ' ...
                  'coeficientes reducidos. El critico esta en zeta = 1.'], ...
        'Units','normalized','Position',[0.02 0.16 0.96 0.14], ...
        'HorizontalAlignment','left','BackgroundColor','w', ...
        'ForegroundColor',[0.35 0.35 0.35]);

    uicontrol('Parent',panE,'Style','pushbutton','String','Restaurar', ...
        'Tag','btnRestaurar', ...
        'Units','normalized','Position',[0.02 0.02 0.30 0.12], ...
        'FontWeight','bold','Callback',@(~,~) restaurar());

    % ---------------------------------------------------------------------
    % PANEL DE COMPROBACION
    % ---------------------------------------------------------------------
    panC = uipanel('Parent',fig,'Title','Comprobar mis coeficientes reducidos', ...
        'FontWeight','bold','BackgroundColor','w', ...
        'Position',[0.55 0.03 0.42 0.40]);

    uicontrol('Parent',panC,'Style','text','FontSize',10, ...
        'String','Forma normalizada:   theta'''' + a*theta'' + b*theta = 0', ...
        'Units','normalized','Position',[0.02 0.88 0.96 0.10], ...
        'HorizontalAlignment','left','BackgroundColor','w');

    hEd = gobjects(1,numel(MAG));   % campos donde escribis TUS valores
    for q = 1:numel(MAG)
        y = 0.72 - (q-1)*0.155;
        uicontrol('Parent',panC,'Style','text', ...
            'String',sprintf('%s [%s]',MAGL{q},MAGU{q}), ...
            'Units','normalized','Position',[0.02 y 0.34 0.11], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',9);
        hEd(q) = uicontrol('Parent',panC,'Style','edit','String','', ...
            'Tag',['ed_' MAG{q}], ...
            'Units','normalized','Position',[0.37 y 0.17 0.12], ...
            'BackgroundColor','w','FontSize',10);
        % Un boton "Revelar" por magnitud: el valor sale solo si lo pedis,
        % nunca junto con la pista de direccion.
        uicontrol('Parent',panC,'Style','pushbutton', ...
            'String','Revelar','Units','normalized','Tag',['rev_' MAG{q}], ...
            'Position',[0.56 y 0.15 0.12],'FontSize',9, ...
            'Callback',@(~,~) revelar(q));
    end

    hFeed = uicontrol('Parent',panC,'Style','text','String','','Tag','feedback', ...
        'Units','normalized','Position',[0.73 0.16 0.25 0.72], ...
        'HorizontalAlignment','left','BackgroundColor',[0.97 0.97 0.97], ...
        'FontSize',9);

    uicontrol('Parent',panC,'Style','pushbutton','String','Comprobar', ...
        'Tag','btnComprobar', ...
        'Units','normalized','Position',[0.02 0.02 0.28 0.11], ...
        'FontWeight','bold','Callback',@(~,~) comprobar());
    uicontrol('Parent',panC,'Style','pushbutton','String','Ocultar mi curva', ...
        'Tag','btnOcultar', ...
        'Units','normalized','Position',[0.33 0.02 0.30 0.11], ...
        'Callback',@(~,~) set(hMia,'Visible','off'));

    % ---------------------------------------------------------------------
    % ARRANQUE
    % ---------------------------------------------------------------------
    TT = []; TH = []; WW = []; NUM = [];   % ultima trayectoria calculada
    idx = 1;                               % frame actual de la animacion
    refrescar();

    % El timer avanza el marcador y la barra. 'drop' descarta el tick si el
    % anterior no termino, asi no se encola trabajo cuando la maquina va
    % lenta. Se para y se destruye al cerrar la figura.
    tmr = timer('ExecutionMode','fixedRate','Period',0.04, ...
        'BusyMode','drop','TimerFcn',@(~,~) paso());
    start(tmr);

    % =====================================================================
    % FUNCIONES ANIDADAS. Ven P, D, G, REF y los handles sin pasarlos.
    % =====================================================================

    function moverSlider(i, val)
        % i: indice del parametro en NOM. val: valor nuevo del slider.
        P.(NOM{i}) = val;
        refrescar();
    end

    function restaurar()
        % Vuelve a los defaults (zeta = 1, wn = 1). D nunca se toco, asi
        % que siempre esta ahi para volver.
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
        % tf = TF: ventana temporal FIJA, la misma para todos los valores de
        % los sliders. Es lo que hace comparables dos curvas seguidas.
        [TT, TH, WW, NUM, cf] = modelo(P, TF);   % WW queda para el marcador

        set(hCurv,'XData',TT,'YData',TH);

        if isnan(NUM.X)   % no oscila: no hay envolvente que dibujar
            set([hEnvS hEnvI],'Visible','off');
        else
            set(hEnvS,'XData',TT,'YData', NUM.env,'Visible','on');
            set(hEnvI,'XData',TT,'YData',-NUM.env,'Visible','on');
        end

        % limites verticales con 10% de aire; el max() evita el caso plano
        amp = max([abs(TH), abs(THREF)*1e-3]);
        set(axResp,'YLim',[-1.1 1.1]*amp);

        % REFERENCIA DEL PANEL: los coeficientes que VM despejo para los
        % valores actuales de los sliders. a es el coeficiente de theta' y
        % b el de theta, o sea c y k con la masa normalizada a 1.
        REF.a  = cf.c;
        REF.b  = cf.k;
        REF.wn = NUM.wn;   % de VM.trayA, no del slider: hace de control
        REF.z  = NUM.z;

        % etiqueta del regimen, con el color marcando el cruce de z = 1.
        % La tolerancia del 0.5% para el critico la pone VM.clasifA, que es
        % de donde sale NUM.regimen: aca no se vuelve a decidir. El cruce
        % importa mas que en los otros problemas de la serie, porque la
        % parte b del enunciado pregunta justo por el critico.
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
        % default
        for j = 1:numel(NOM)
            set(hLab(j),'String', sprintf('%s = %.4g %s   (%.4g)', ...
                ETI{j}, P.(NOM{j}), UNI{j}, D.(NOM{j})));
        end

        % La animacion vuelve al principio. Se repinta ya mismo, sin esperar
        % al proximo tick del timer, para que el dibujo nunca muestre el
        % angulo de la trayectoria anterior.
        idx = 1;
        pintarEscena(H, G, ESC_ANG*TH(idx));
    end

    function paso()
        % Un frame: gira la barra y mueve el marcador. Solo set(), nada de
        % replot. Si la figura ya no esta, no hace nada.
        if ~isvalid(fig) || isempty(TT), return, end
        idx = idx + 4;
        if idx > numel(TT), idx = 1; end

        pintarEscena(H, G, ESC_ANG*TH(idx));

        set(hPto, 'XData',TT(idx),'YData',TH(idx));
        yl = get(axResp,'YLim');
        set(hVert,'XData',[TT(idx) TT(idx)],'YData',yl);
        drawnow limitrate
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
        ia = strcmp(MAG,'a');   ib  = strcmp(MAG,'b');
        iw = strcmp(MAG,'wn');  izz = strcmp(MAG,'z');

        % --- tu curva -------------------------------------------------
        % Primera opcion: TUS a y b entran directo, porque la forma
        % normalizada ES m = 1, c = a, k = b. Segunda opcion: TUS wn y
        % zeta, que VM.genA traduce a b y a. No se despeja nada aca.
        if ~isnan(v(ia)) && ~isnan(v(ib))
            msg = superponer(v(ib), v(ia), msg);
        elseif ~isnan(v(iw)) && ~isnan(v(izz))
            try
                g = VM.genA('m',1, 'wn',v(iw), 'z',v(izz));
                msg = superponer(double(g.k), double(g.c), msg);
            catch
                msg{end+1} = 'Con esos wn y zeta no se puede armar la curva.';
            end
        else
            msg{end+1} = 'Escribi a y b (o wn y zeta) para ver tu curva.';
        end

        % --- pistas de direccion, una por magnitud --------------------
        for j = 1:numel(MAG)
            if isnan(v(j)), continue, end
            r = REF.(MAG{j});
            if abs(v(j)-r) <= 5e-3*max(abs(r),eps)
                msg{end+1} = sprintf('%s: coincide.', ETIcorta(MAG{j})); %#ok<AGROW>
                continue
            end
            alto = v(j) > r;
            switch MAG{j}
                case 'a'
                    if alto, s = 'tu barra frena mas';
                    else,    s = 'tu barra frena menos'; end
                case 'b'
                    if alto, s = 'tu sistema es mas rigido';
                    else,    s = 'tu sistema es mas blando'; end
                case 'wn'
                    if alto, s = 'tu periodo es menor';
                    else,    s = 'tu periodo es mayor'; end
                case 'z'
                    if alto, s = 'tu decaimiento es mas rapido';
                    else,    s = 'tu decaimiento es mas lento'; end
            end
            msg{end+1} = sprintf('%s: %s.', ETIcorta(MAG{j}), s); %#ok<AGROW>
        end

        set(hFeed,'String',msg);
    end

    function msg = superponer(bb, aa, msg)
        % Dibuja TU curva con TUS coeficientes reducidos.
        %   bb  : tu coeficiente de theta   -> entra a VM como k
        %   aa  : tu coeficiente de theta'  -> entra a VM como c
        %   msg : celda de mensajes del feedback, se devuelve ampliada
        % Las condiciones iniciales son las mismas que las de la curva de
        % referencia: si no, la diferencia entre las dos curvas no seria de
        % los coeficientes sino del arranque.
        try
            [t2,x2] = VM.trayA('m',1, 'k',bb, 'c',aa, ...
                'x0',P.th0, 'v0',P.w0, 'tf',TF, 'npts',600);
            set(hMia,'XData',t2,'YData',x2,'Visible','on');
            msg{end+1} = 'Tu curva esta superpuesta en naranja.';
        catch
            msg{end+1} = 'Con esos coeficientes no se puede armar la curva.';
        end
    end

    function revelar(j)
        % Muestra UNA magnitud, y solo cuando la pediste.
        set(hFeed,'String', sprintf('%s = %.6g %s', ...
            ETIcorta(MAG{j}), REF.(MAG{j}), MAGU{j}));
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
        % Render fijo con los defaults (zeta = 1, el caso critico que pide
        % la parte b), sin sliders, y un GIF para pegar en el LaTeX.
        % El GIF es el de la ANIMACION: es lo que no se puede contar con una
        % curva, porque ahi se ve que D recorre el doble que B.
        if ~exist('figs','dir'), mkdir('figs'); end
        [t,th,~,n] = modelo(D);

        % --- GIF: la barra girando ---------------------------------------
        f1 = figure('Color','w','Position',[100 100 760 620],'Visible','off');
        theme(f1,'light');
        ax1 = axes('Parent',f1,'Position',[0.03 0.03 0.94 0.90]);
        H1  = armarEscena(ax1, G);
        title(ax1,sprintf('Barra rigida - caso %s (\\zeta = %.3f)', ...
            n.regimen, n.z),'Color','k');

        gif = fullfile('figs','sim5.gif');
        if exist(gif,'file'), delete(gif); end
        % exportgraphics con 'Append' arma el GIF animado cuadro a cuadro.
        for fr = 1:20:numel(t)
            pintarEscena(H1, G, ESC_ANG*th(fr));
            exportgraphics(ax1, gif, 'Append', fr > 1);
        end
        close(f1);

        % --- PNG: theta(t) ------------------------------------------------
        f2 = figure('Color','w','Position',[100 100 900 420],'Visible','off');
        theme(f2,'light');
        ax2 = axes('Parent',f2); hold(ax2,'on'); grid(ax2,'on');
        if ~isnan(n.X)
            plot(ax2,t, n.env,'r--','LineWidth',1,'DisplayName','Envolvente');
            plot(ax2,t,-n.env,'r--','LineWidth',1,'HandleVisibility','off');
        end
        plot(ax2,t,th,'-','Color',[0 0.30 0.65],'LineWidth',1.8, ...
            'DisplayName','\theta(t)');
        xlabel(ax2,'t [s]'); ylabel(ax2,'\theta(t) [rad]');
        legend(ax2,'show','Location','northeast');
        set(ax2,'Color','w','XColor','k','YColor','k', ...
            'GridColor',[0.5 0.5 0.5],'GridAlpha',1,'XLim',[0 t(end)]);
        title(ax2,sprintf('Barra rigida - caso %s (\\zeta = %.3f)', ...
            n.regimen, n.z),'Color','k');
        exportgraphics(ax2, fullfile('figs','sim5.png'), 'Resolution',150);
        close(f2);

        fprintf('Escrito: %s\n', gif);
        fprintf('Escrito: %s\n', fullfile('figs','sim5.png'));
    end
end

% =========================================================================
% FUNCIONES LOCALES (no anidadas: no ven las variables de arriba)
% =========================================================================

function [t, th, w, num, cf] = modelo(p, tf)
    % Traduce los coeficientes reducidos a una llamada a VM.
    % ENTRADAS:
    %   p  : struct con z, wn, th0, w0
    %   tf : tiempo final del muestreo [s]. Si no se pasa o llega vacio, lo
    %        elige VM.trayA segun el caso
    % SALIDAS:
    %   t   : tiempos                                  [s]
    %   th  : theta(t)                                 [rad]
    %   w   : thetapunto(t)                            [rad/s]
    %   num : escalares del caso (regimen, wn, z, ...) de VM.trayA
    %   cf  : coeficientes reducidos, cf.k = b y cf.c = a
    %
    % LA MASA ES 1 A PROPOSITO. El sistema esta normalizado a
    % theta'' + a*theta' + b*theta = 0, o sea con el coeficiente de theta''
    % igual a 1. VM habla en m, c, k, asi que la traduccion es
    % m = 1, c = a, k = b. Ese 1 no es un kilogramo: es la normalizacion.
    % Por eso a sale en 1/s y b en 1/s^2, no en N*s/m ni en N/m.
    %
    % VM.genA es quien pasa de (wn, zeta) a (b, a). Aca no se despeja.
    if nargin < 2, tf = []; end

    g  = VM.genA('m',1, 'wn',p.wn, 'z',p.z);
    cf = struct('k', double(g.k), 'c', double(g.c));

    % x0 y v0 de VM son aca theta(0) y thetapunto(0): el modelo es el mismo,
    % solo cambia el vestuario (ver VM.ecTorA, que hace la misma traduccion
    % con Jo, ct y kt).
    if isempty(tf)
        [t, th, w, num] = VM.trayA('m',1, 'k',cf.k, 'c',cf.c, ...
            'x0',p.th0, 'v0',p.w0, 'npts',600);
    else
        [t, th, w, num] = VM.trayA('m',1, 'k',cf.k, 'c',cf.c, ...
            'x0',p.th0, 'v0',p.w0, 'tf',tf, 'npts',600);
    end
end

function H = armarEscena(ax, G)
    % Dibuja TODO lo que no se mueve y devuelve los handles de lo que si.
    % ax : ejes donde dibujar
    % G  : struct de geometria en unidades de DIBUJO
    % SALIDA:
    %   H : struct de handles persistentes. pintarEscena() les cambia
    %       XData/YData y nadie vuelve a llamar a plot()
    hold(ax,'on');
    axis(ax,'off');
    % DataAspectRatio [1 1 1]: sin esto, un giro se ve como una elipse
    % porque un radian horizontal no mide lo mismo que uno vertical.
    set(ax,'XLim',[0 10],'YLim',[-3.75 3.25],'DataAspectRatio',[1 1 1]);

    % --- soportes fijos ---------------------------------------------------
    % El rayado va del lado del MATERIAL: arriba en el techo, abajo en el
    % piso y en el terreno del pivote.
    rayado(ax, G.XB0-1.0, G.XB0+1.0, G.YTECHO,  0.20, 11);   % techo
    rayado(ax, G.XD0-1.1, G.XD0+1.1, G.YPISO,  -0.20, 12);   % piso
    rayado(ax, G.XA -0.7, G.XA +0.7, -0.75,    -0.20,  8);   % terreno de A

    % --- pivote A: triangulo de articulacion ------------------------------
    patch('Parent',ax, ...
        'XData',[G.XA G.XA-0.45 G.XA+0.45], 'YData',[G.YA -0.75 -0.75], ...
        'FaceColor',[0.85 0.82 0.75],'EdgeColor','k','LineWidth',1.2);
    plot(ax, G.XA, G.YA,'o','MarkerSize',8, ...
        'MarkerFaceColor','w','MarkerEdgeColor','k','LineWidth',1.5);

    % --- cilindro del amortiguador: va atornillado al piso, no se mueve ---
    % Se dibuja abierto por arriba, que es el simbolo normal del dashpot: el
    % piston entra y sale por ahi. El alto (2.10) no es decorativo, tiene que
    % cubrir todo el recorrido del piston, que es el mismo que el de D.
    ycil = G.YPISO + 2.10;   % boca del cilindro
    patch('Parent',ax, ...
        'XData',[G.XD0-G.RCIL G.XD0+G.RCIL G.XD0+G.RCIL G.XD0-G.RCIL], ...
        'YData',[G.YPISO G.YPISO ycil ycil], ...
        'FaceColor',[0.88 0.93 0.97],'EdgeColor','none');
    plot(ax,[G.XD0-G.RCIL G.XD0-G.RCIL G.XD0+G.RCIL G.XD0+G.RCIL], ...
            [ycil G.YPISO G.YPISO ycil],'k-','LineWidth',1.5);

    % --- posicion sin girar de la barra ----------------------------------
    % La referencia contra la que se miden los dos desplazamientos. Sin esta
    % linea, las lineas de trazos de B y D no se miden contra nada.
    plot(ax,[G.XA G.XD0+0.55],[G.YA G.YA],':','Color',[0.55 0.55 0.55], ...
        'LineWidth',1);

    % --- cotas l/2 y l/2 --------------------------------------------------
    % Las dos cotas del dibujo del enunciado. Son iguales, y esa igualdad
    % es la que pone a B a la mitad y a D al doble de distancia del pivote.
    yc = -1.55;   % altura de la linea de cota
    for x = [G.XA G.XB0 G.XD0]
        plot(ax,[x x],[yc-0.15 yc+0.15],'-','Color',[0.45 0.45 0.45]);
    end
    plot(ax,[G.XA G.XD0],[yc yc],'-','Color',[0.45 0.45 0.45]);
    text(ax,(G.XA+G.XB0)/2, yc+0.28,'l/2','HorizontalAlignment','center', ...
        'Color',[0.30 0.30 0.30],'FontSize',11);
    text(ax,(G.XB0+G.XD0)/2, yc+0.28,'l/2','HorizontalAlignment','center', ...
        'Color',[0.30 0.30 0.30],'FontSize',11);

    % --- etiquetas de los puntos -----------------------------------------
    text(ax, G.XA-0.60, 0.40,'A','FontSize',13,'FontWeight','bold','Color','k');
    text(ax, G.XB0-0.62, -0.25,'B','FontSize',13,'FontWeight','bold','Color','k');
    text(ax, G.XD0+0.42, -0.25,'D','FontSize',13,'FontWeight','bold','Color','k');
    text(ax, G.XB0+0.35, 1.55,'k','FontSize',12,'Color',[0.20 0.45 0.70]);
    text(ax, G.XD0+0.55, -2.30,'c','FontSize',12,'Color',[0.20 0.45 0.70]);

    % --- handles de lo que se mueve --------------------------------------
    % ORDEN DE CREACION = ORDEN DE DIBUJO. El resorte y el amortiguador van
    % primero, la barra encima, y las lineas de trazos de B y D AL FINAL:
    % son lo que hay que ver, y la barra tiene espesor suficiente para
    % taparlas si se dibujaran antes.
    H.res   = plot(ax,nan,nan,'-','Color',[0.20 0.45 0.70], ...
        'LineWidth',1.8,'Tag','resorte');
    H.vas   = plot(ax,nan,nan,'k-','LineWidth',2.5,'Tag','vastago');
    H.pis   = plot(ax,nan,nan,'k-','LineWidth',4,'Tag','piston');
    H.barra = patch('Parent',ax,'XData',nan,'YData',nan,'Tag','barra', ...
        'FaceColor',[0.55 0.78 0.92],'EdgeColor','k','LineWidth',1.5);
    H.despB = plot(ax,nan,nan,'--','Color',[0.85 0.33 0.10], ...
        'LineWidth',2.2,'Tag','despB');
    H.despD = plot(ax,nan,nan,'--','Color',[0.85 0.33 0.10], ...
        'LineWidth',2.2,'Tag','despD');
    H.mkB   = plot(ax,nan,nan,'o','MarkerSize',8,'Tag','mkB', ...
        'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k');
    H.mkD   = plot(ax,nan,nan,'o','MarkerSize',8,'Tag','mkD', ...
        'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k');

    pintarEscena(H, G, 0);   % estado sin girar, para que no arranque vacio
end

function pintarEscena(H, G, phi)
    % Coloca todo lo movil para un angulo de DIBUJO phi [rad].
    % phi ya viene escalado: NO es theta en radianes fisicos.
    % Solo set(): ni un plot nuevo, ni una figura nueva.

    % --- barra: rectangulo delgado rotado alrededor de A -----------------
    % Las 4 esquinas se escriben en la posicion sin girar y se rotan todas
    % juntas. Rotar el poligono entero, y no cada punto por su cuenta, es
    % lo que mantiene la barra rigida en el dibujo.
    xs = [G.XA G.XA+G.LB G.XA+G.LB G.XA];
    ys = [-G.HB -G.HB G.HB G.HB] + G.YA;
    [bx, by] = rotarSobre(xs, ys, G.XA, G.YA, phi);
    set(H.barra,'XData',bx,'YData',by);

    % --- puntos B y D despues de girar -----------------------------------
    % B esta a l/2 del pivote y D a l. Al girar el MISMO angulo, el
    % desplazamiento vertical de cada uno es proporcional a su distancia a
    % A: por eso D recorre el doble que B. Las lineas de trazos lo miden.
    [xb, yb] = rotarSobre(G.XB0, G.YA, G.XA, G.YA, phi);
    [xd, yd] = rotarSobre(G.XD0, G.YA, G.XA, G.YA, phi);

    set(H.mkB,'XData',xb,'YData',yb);
    set(H.mkD,'XData',xd,'YData',yd);
    set(H.despB,'XData',[xb xb],'YData',[G.YA yb]);
    set(H.despD,'XData',[xd xd],'YData',[G.YA yd]);

    % --- resorte en B: del techo fijo al punto B --------------------------
    % El anclaje de arriba no se mueve, asi que la longitud del resorte
    % cambia con el giro. Eso es la deformacion que produce la fuerza.
    [rx, ry] = zigzagSeg([G.XB0 G.YTECHO], [xb yb], 9, 0.18);
    set(H.res,'XData',rx,'YData',ry);

    % --- amortiguador en D: del punto D al piso fijo ----------------------
    % El cilindro esta fijo al piso; el vastago baja desde D y arrastra el
    % piston, que se corre DENTRO del cilindro. Lo que cambia es cuanto
    % entra el piston, o sea la longitud util del amortiguador.
    ypis = G.YPIS0 + (yd - G.YA);
    set(H.vas,'XData',[xd G.XD0],'YData',[yd ypis]);
    set(H.pis,'XData',[G.XD0-0.30 G.XD0+0.30],'YData',[ypis ypis]);
end

function [xr, yr] = rotarSobre(xp, yp, xa, ya, phi)
    % Rota los puntos (xp,yp) un angulo phi [rad] alrededor de (xa,ya).
    % Signo positivo = antihorario, igual que theta en el diagrama.
    % Es la matriz de rotacion escrita a mano sobre las coordenadas
    % RELATIVAS al pivote; por eso primero se resta (xa,ya) y al final se
    % vuelve a sumar.
    dx = xp - xa;
    dy = yp - ya;
    xr = xa + dx*cos(phi) - dy*sin(phi);
    yr = ya + dx*sin(phi) + dy*cos(phi);
end

function [xs, ys] = zigzagSeg(p1, p2, nv, amp)
    % Polilinea en zigzag entre dos puntos cualesquiera, para dibujar un
    % resorte que no es horizontal ni vertical.
    %   p1, p2 : extremos [x y] en unidades de dibujo
    %   nv     : cantidad de dientes
    %   amp    : media altura del diente, medida PERPENDICULAR al eje
    % Los tramos rectos de 0.18 en cada punta hacen que el resorte se vea
    % anclado y no arranque en diagonal.
    d = p2 - p1;
    L = hypot(d(1), d(2));
    if L < 1e-9, xs = [p1(1) p2(1)]; ys = [p1(2) p2(2)]; return, end
    u = d/L;              % versor a lo largo del resorte
    n = [-u(2) u(1)];     % versor perpendicular

    a = p1 + 0.18*u;      % arranque del zigzag
    b = p2 - 0.18*u;      % final del zigzag
    m = 2*nv;
    s = linspace(0, 1, m);
    dientes = (-1).^(1:m);

    px = a(1) + (b(1)-a(1))*s + amp*dientes*n(1);
    py = a(2) + (b(2)-a(2))*s + amp*dientes*n(2);

    xs = [p1(1), a(1), px, b(1), p2(1)];
    ys = [p1(2), a(2), py, b(2), p2(2)];
end

function rayado(ax, x1, x2, y, alto, n)
    % Apoyo fijo: linea gruesa con rayado a 45 grados.
    %   x1, x2 : extremos de la linea de apoyo
    %   y      : altura de la linea
    %   alto   : largo de cada raya. POSITIVO dibuja el rayado hacia arriba
    %            (techo) y NEGATIVO hacia abajo (piso o terreno). El rayado
    %            va siempre del lado del material
    %   n      : cantidad de rayas
    plot(ax,[x1 x2],[y y],'k-','LineWidth',2);
    xs = linspace(x1, x2-abs(alto), n);
    for i = 1:n
        plot(ax,[xs(i) xs(i)+abs(alto)],[y y+alto],'k-','LineWidth',0.8);
    end
end

function s = ETIcorta(nombre)
    % Nombre corto de cada magnitud para el texto de feedback. ASCII: el
    % uicontrol de texto tampoco interpreta TeX.
    switch nombre
        case 'a',  s = 'a';
        case 'b',  s = 'b';
        case 'wn', s = 'wn';
        case 'z',  s = 'zeta';
        otherwise, s = nombre;
    end
end
