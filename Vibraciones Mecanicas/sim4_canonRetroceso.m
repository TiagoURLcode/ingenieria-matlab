function sim4_canonRetroceso(modo)
% SIM4_CANONRETROCESO - simulador interactivo del problema 4 de Tarea 2.
%
% Mecanismo de retroceso del canon de un tanque: un resorte recuperador y un
% amortiguador entre el canon y la cuna. El enunciado dice que el sistema es
% CRITICO, y esa es justamente la condicion de la que sale la rigidez.
%
% USO:
%   sim4_canonRetroceso             % modo interactivo
%   sim4_canonRetroceso('exportar') % render fijo + GIF en ./figs/
%
% UNIDADES IMPERIALES, COHERENTES. Se trabaja en lb - ft - slug - s:
%   peso   [lb]        g [ft/s^2]      masa  [slug] = peso/g
%   k      [lb/ft]     c [lb*s/ft]     wn    [rad/s]
% NO se convierte a SI. Lo que no se negocia es que el sistema sea
% COHERENTE, no que sea metrico: mezclar lb con kg da un numero mudo que no
% dispara ningun error. VM.m no sabe en que unidades esta trabajando -- solo
% hace algebra -- asi que funciona igual mientras el juego cierre entre si.
%
% CONVENCION DE SIGNOS Y CONDICIONES INICIALES. El cronometro se pone en
% cero en el RETROCESO MAXIMO, no en el disparo. En ese instante el canon
% esta lo mas atras que va a estar y, por ser el punto de retorno, su
% velocidad es cero:
%   x0 = retroceso maximo (aca normalizado a 1 ft, y con slider propio)
%   v0 = 0
% El sentido positivo de x es HACIA ATRAS: x > 0 es retroceso.
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica es de VM.m:
%   VM.critA    de m y c saca la K que hace CRITICO al sistema. Motor.despejar
%               va hacia atras: la ecuacion c == ccr fija ccr, ccr == 2*m*wn
%               fija wn, y wn == sqrt(k/m) fija k
%   VM.trayA    entrega x(t), v(t) y los escalares del caso
%   VM.clasifA  da la zeta que corresponde a un c contra su ccr
%   VM.genA     traduce TU wn y TU zeta a k y c, para superponer tu curva
% Aca no se escribe ni una formula de vibraciones: si un numero hace falta,
% se le pide a VM. La unica cuenta escrita a mano es masa = peso/g, que es
% una conversion de unidades, no una formula de vibraciones.
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
        'W',  1500, ...   % peso del canon en retroceso        [lb]
        'g',  32.2, ...   % aceleracion de la gravedad         [ft/s^2]
        'c',  1100, ...   % amortiguamiento del recuperador    [lb*s/ft]
        'z',  1,    ...   % relacion de amortiguamiento        [-]  (critico)
        'x0', 1,    ...   % retroceso maximo x(0)              [ft]  (normalizado)
        'v0', 0);         % velocidad en el retroceso maximo   [ft/s]

    P = D;   % parametros VIVOS, los que mueven los sliders

    % Rangos de los sliders: [minimo maximo] de cada parametro. z llega
    % hasta 2 a proposito, para cruzar los tres regimenes: con z < 1 el
    % canon se pasa de la posicion de bateria y vuelve oscilando, que es
    % justo lo que el mecanismo tiene que evitar.
    R = struct( ...
        'W',  [500 5000], 'c',  [200 3000], 'z', [0 2], ...
        'x0', [0.1 4],    'v0', [-10 10]);

    % g NO tiene slider: es una constante, no un parametro del mecanismo.
    NOM = {'W','c','z','x0','v0'};                    % orden de los sliders
    UNI = {'lb','lb*s/ft','-','ft','ft/s'};           % unidad de cada uno

    % tf del eje de tiempo: se fija UNA vez y no se recalcula. Si tf siguiera
    % a z, al mover el slider el eje se reescalaria solo y todas las curvas
    % se verian iguales. Se toma la MAS LARGA de las tres ventanas que
    % propone VM.trayA por su cuenta (la del enunciado y las de los dos
    % extremos del slider de z) para que el transitorio entre entero en
    % cualquier posicion del slider. Efecto secundario buscado: con los
    % valores del enunciado la curva llega a cero mucho antes del borde
    % derecho, y ese vacio ES el resultado -- el critico ya termino mientras
    % el caso sub-amortiguado sigue oscilando.
    TF       = ventana(D, R.z(1), R.z(2));   % tiempo final del grafico [s]
    [~, xx0] = modelo(D, TF);
    XREF     = max(abs(xx0));                % amplitud de referencia [ft]

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
    MAG  = {'m','ccr','wn','z','k'};
    MAGU = {'slug','lb*s/ft','rad/s','-','lb/ft'};
    % Etiquetas en ASCII pelado: uicontrol NO interpreta TeX, asi que un
    % '\zeta' aca se ve literal como barra-zeta. El TeX solo vale en
    % title, xlabel y demas texto de los EJES.
    MAGL = {'m','c_cr','wn','z','K'};

    % ---------------------------------------------------------------------
    % FIGURA Y EJES
    % ---------------------------------------------------------------------
    tmr = [];   % handle del timer; se declara ANTES de la figura porque
                % cerrar() puede correr antes de que se lo asigne

    fig = figure('Name','Problema 4 - retroceso del canon', ...
        'NumberTitle','off', 'Color','w', ...
        'Position',[60 60 1450 840], 'CloseRequestFcn',@cerrar);
    theme(fig,'light');   % fuerza tema claro: si no, con MATLAB en oscuro
                          % el area de los ejes sale negra (ver VM.graficarA)

    axAnim = axes('Parent',fig, 'Position',[0.04 0.47 0.42 0.49]);
    axResp = axes('Parent',fig, 'Position',[0.55 0.47 0.42 0.49]);

    % --- eje de la animacion ---------------------------------------------
    % Unidades de DIBUJO, no pies: la posicion fisica se mapea con ESC.
    % La animacion es DECORATIVA: el canon se mueve en linea recta y nada
    % mas. Lo que hay que mirar es la curva de la derecha.
    axis(axAnim, [0 10 -2.6 2.6]);
    axis(axAnim, 'off');
    hold(axAnim,'on');
    title(axAnim,'Animacion: el canon vuelve a bateria','Color','k');

    % ESC: cuantas unidades de dibujo vale un pie. Se fija con la amplitud
    % del enunciado para que el canon recorra ~1.2 unidades.
    ESC = 1.2/max(XREF, eps);
    XB0 = 3.4;   % cola del canon en BATERIA (x = 0), en unidades de dibujo
    LC  = 5.2;   % largo del tubo   [dibujo]
    RC  = 0.26;  % medio calibre    [dibujo]

    % --- escenario fijo: se dibuja UNA vez, fuera de todo callback -------
    % casco del tanque, estatico
    patch('Parent',axAnim,'XData',[0.2 4.6 4.2 0.6],'YData',[-2.3 -2.3 -1.2 -1.2], ...
        'FaceColor',[0.45 0.50 0.40],'EdgeColor','k','LineWidth',1.2);
    for w = 1:4
        plot(axAnim, 0.9+0.95*(w-1), -2.3,'o','MarkerSize',12, ...
            'MarkerFaceColor',[0.30 0.33 0.28],'MarkerEdgeColor','k');
    end
    % cuna: es la pieza FIJA contra la que trabajan el resorte y el
    % amortiguador. El tubo desliza dentro de ella.
    patch('Parent',axAnim,'XData',[0.3 1.7 1.7 0.3],'YData',[-1.2 -1.2 1.2 1.2], ...
        'FaceColor',[0.45 0.50 0.40],'EdgeColor','k','LineWidth',1.2);

    % resorte recuperador: de la cuna a la cola del tubo
    hRes = plot(axAnim,nan,nan,'-','Color',[0.20 0.45 0.70],'LineWidth',1.8);

    % amortiguador: el CILINDRO va atornillado a la cuna, asi que no se
    % mueve nunca y entra en el escenario fijo, sin handle. Lo unico que se
    % anima es el VASTAGO, que sale de la cola del tubo.
    patch('Parent',axAnim,'XData',[1.7 2.6 2.6 1.7], ...
        'YData',[-0.85 -0.85 -0.35 -0.35], ...
        'FaceColor',[0.80 0.88 0.95],'EdgeColor','k','LineWidth',1.2);
    hAmoV = plot(axAnim,nan,nan,'k-','LineWidth',2.5);

    % tubo y freno de boca
    hTubo = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.55 0.60 0.50],'EdgeColor','k','LineWidth',1.5);
    hBoca = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.35 0.40 0.32],'EdgeColor','k','LineWidth',1.2);

    % marca de la posicion de bateria, para ver contra que se mide x
    plot(axAnim,[XB0 XB0],[0.35 1.5],'k:','LineWidth',1);
    text(axAnim, XB0, 1.8,'x = 0 (bateria)', ...
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
    xlabel(axResp,'t [s]'); ylabel(axResp,'x(t) [ft]   (+ = retroceso)');
    title(axResp,'Retroceso x(t) desde el retroceso maximo','Color','k');
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
        y = 0.70 - (i-1)*0.125;
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

    % Nota fija: W y c mandan sobre la K del mecanismo, z manda sobre el
    % amortiguador real. Sin esto el slider de z parece contradecir al de c.
    uicontrol('Parent',panE,'Style','text','BackgroundColor','w', ...
        'Units','normalized','Position',[0.35 0.01 0.63 0.13], ...
        'HorizontalAlignment','left','FontSize',8, ...
        'String',['W y c fijan la K del mecanismo (condicion critica). ' ...
                  'El slider de zeta cambia el amortiguador REAL contra ' ...
                  'esa K, para ver los tres regimenes.']);

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

    % El timer avanza el marcador y el canon. 'drop' descarta el tick si el
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
        % Un frame: mueve el canon y el marcador. Solo set(), nada de
        % replot. Si la figura ya no esta, no hace nada.
        if ~isvalid(fig) || isempty(TT), return, end
        idx = idx + 4;
        if idx > numel(TT), idx = 1; end

        % x > 0 es retroceso, o sea el tubo se va HACIA ATRAS (a la izquierda)
        xb = XB0 - ESC*XX(idx);                 % cola del tubo [dibujo]
        xb = min(max(xb, 2.2), 5.5);            % tope: que no entre en la cuna
        dibujarCanon(xb);

        set(hPto, 'XData',TT(idx),'YData',XX(idx));
        yl = get(axResp,'YLim');
        set(hVert,'XData',[TT(idx) TT(idx)],'YData',yl);
        drawnow limitrate
    end

    function dibujarCanon(xb)
        % xb: cola del tubo en unidades de DIBUJO. El tubo se mueve entero,
        % en linea recta: la animacion no pretende mas que eso.
        bo = xb + LC;   % boca del tubo

        set(hTubo,'XData',[xb bo bo xb],'YData',[-RC -RC RC RC]);
        set(hBoca,'XData',[bo bo+0.35 bo+0.35 bo], ...
                  'YData',[-0.40 -0.40 0.40 0.40]);

        % resorte recuperador, de la cuna a la cola del tubo
        [xs,ys] = zigzag(1.7, xb, 0.60, 9, 0.20);
        set(hRes,'XData',xs,'YData',ys);

        % vastago del amortiguador, del cilindro a la cola del tubo
        set(hAmoV,'XData',[2.1 xb],'YData',[-0.60 -0.60]);
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

        % --- tu curva, si diste m y wn (y z; si no, se toma la del panel) ---
        iwn = strcmp(MAG,'wn');  iz = strcmp(MAG,'z');  im = strcmp(MAG,'m');
        zMia = v(iz);
        if isnan(zMia), zMia = P.z; end          % sin z tuya, la del slider
        mMia = v(im);
        if isnan(mMia), mMia = P.W/P.g; end      % sin m tuya, la del slider
        if ~isnan(v(iwn))
            try
                % VM traduce TU wn y TU z a k y c; no se despeja aca.
                % gen y no g: g ya es la gravedad en este archivo
                gen = VM.genA('m',mMia, 'wn',v(iwn), 'z',zMia);
                [t2,x2] = VM.trayA('m',mMia,'k',double(gen.k),'c',double(gen.c), ...
                    'x0',P.x0,'v0',P.v0,'tf',TF,'npts',600);
                set(hMia,'XData',t2,'YData',x2,'Visible','on');
                msg{end+1} = 'Tu curva esta superpuesta en naranja.';
            catch
                msg{end+1} = 'Con esa wn no se puede armar la curva.';
            end
        else
            msg{end+1} = 'Escribi wn para superponer tu curva.';
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
                case 'm'
                    if alto, s = 'tu canon pesa mas';
                    else,    s = 'tu canon pesa menos'; end
                case 'z'
                    if alto, s = 'tu decaimiento es mas rapido';
                    else,    s = 'tu decaimiento es mas lento'; end
                case 'wn'
                    if alto, s = 'tu retorno a bateria es mas rapido';
                    else,    s = 'tu retorno a bateria es mas lento'; end
                case 'k'
                    if alto, s = 'tu recuperador es mas duro';
                    else,    s = 'tu recuperador es mas blando'; end
                case 'ccr'
                    if alto, s = 'tu amortiguador critico frena mas';
                    else,    s = 'tu amortiguador critico frena menos'; end
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
        xlabel(ax,'t [s]'); ylabel(ax,'x(t) [ft]   (+ = retroceso)');
        legend(ax,'show','Location','northeast');
        set(ax,'Color','w','XColor','k','YColor','k', ...
            'GridColor',[0.5 0.5 0.5],'GridAlpha',1,'XLim',[0 t(end)]);
        title(ax,sprintf('Problema 4 - caso %s (\\zeta = %.3f)', ...
            n.regimen, n.z),'Color','k');

        gif = fullfile('figs','sim4.gif');
        if exist(gif,'file'), delete(gif); end
        % exportgraphics con 'Append' arma el GIF animado cuadro a cuadro.
        % nf es el indice del CUADRO; no se llama f porque f ya es el handle
        % de la figura de exportacion.
        for nf = 1:20:numel(t)
            set(hm,'XData',t(nf),'YData',x(nf));
            exportgraphics(ax, gif, 'Append', nf > 1);
        end
        exportgraphics(ax, fullfile('figs','sim4.png'), 'Resolution',150);
        close(f);
        fprintf('Escrito: %s\n', gif);
        fprintf('Escrito: %s\n', fullfile('figs','sim4.png'));
    end
end

% =========================================================================
% FUNCIONES LOCALES (no anidadas: no ven las variables de arriba)
% =========================================================================

function [t, x, v, num] = modelo(p, tf)
    % Traduce los parametros del problema a una llamada a VM.
    %   p  : struct con W, g, c, z, x0, v0
    %   tf : tiempo final del muestreo [s]. Si no se pasa, lo elige VM.trayA
    m = p.W/p.g;                       % masa [slug] = peso [lb] / g [ft/s^2]
    k = rigidez(m, p.c);               % K del mecanismo [lb/ft], via VM.critA

    if nargin < 2 || isempty(tf)
        [t, x, v, num] = VM.trayA('m',m, 'k',k, 'z',p.z, ...
            'x0',p.x0, 'v0',p.v0, 'npts',600);
    else
        [t, x, v, num] = VM.trayA('m',m, 'k',k, 'z',p.z, ...
            'x0',p.x0, 'v0',p.v0, 'tf',tf, 'npts',600);
    end
end

function k = rigidez(m, c)
    % K DEL MECANISMO, sacada de la CONDICION CRITICA del enunciado.
    %   m : masa del canon en retroceso [slug]
    %   c : amortiguamiento             [lb*s/ft]
    %   k : rigidez del recuperador     [lb/ft]
    % VM.critA no "calcula k": resuelve el sistema de VM.ecCritA con lo que
    % le des, y Motor.despejar sustituye hacia adelante en el orden que los
    % datos permitan. Con m y c entra por c == ccr (la definicion del caso
    % critico) y sale por wn == sqrt(k/m). Eso es ir HACIA ATRAS: de la
    % condicion al parametro que la cumple.
    r = VM.critA('m',m, 'c',c);   % struct simbolico: trae ccr, wn y k
    k = double(r.k);              % a numero: VM devuelve simbolico
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
    m = p.W/p.g;                       % masa [slug] = peso [lb] / g [ft/s^2]
    s = VM.critA('m',m, 'c',p.c);      % de la condicion critica salen k, wn, ccr

    % z contra el c del enunciado: la da VM.clasifA (cuarta salida), no una
    % division escrita aca. Con la K de arriba tiene que dar 1: eso ES la
    % comprobacion de que el sistema es critico.
    [~, ~, ~, z] = VM.clasifA('m',m, 'k',double(s.k), 'c',p.c);

    r = struct('m', m,             ...   % masa                [slug]
        'ccr', double(s.ccr),      ...   % amortiguamiento critico [lb*s/ft]
        'wn',  double(s.wn),       ...   % frecuencia natural  [rad/s]
        'z',   z,                  ...   % relacion de amort.  [-]
        'k',   double(s.k));             % rigidez del recuperador [lb/ft]
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
