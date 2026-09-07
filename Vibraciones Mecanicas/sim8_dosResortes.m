function sim8_dosResortes(modo)
% SIM8_DOSRESORTES - simulador interactivo del problema 8 de Tarea 2.
%
% Caja sobre ruedas con un resorte de cada lado y un amortiguador arriba.
% Anima el cuerpo, dibuja x(t) con su envolvente y deja barrer los
% parametros en vivo.
%
% USO:
%   sim8_dosResortes             % modo interactivo
%   sim8_dosResortes('exportar') % render fijo + GIF en ./figs/
%
% POR QUE LOS RESORTES ESTAN EN PARALELO Y NO EN SERIE. El enunciado dice
% que los DOS estan sin estirar en x = 0, o sea que los dos van de pared a
% masa. Cuando la masa se corre x, los dos se deforman x: misma
% deformacion -> PARALELO -> las rigideces se SUMAN. Estar uno a cada lado
% no los pone en serie; lo que decide es si comparten la deformacion
% (paralelo) o se la reparten (serie).
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica es de VM.m:
%   VM.datosParalelos  suma k1 y k2 en la rigidez equivalente
%   VM.clasifA         de (m, keq, c) saca la zeta del enunciado
%   VM.trayA           entrega x(t), v(t) y los escalares del caso
%   VM.subA            valores de referencia del panel de comprobacion
%   VM.genA            traduce TU wn y TU z a k y c, para superponer tu curva
% Aca no se escribe ni una formula de vibraciones: si un numero hace falta,
% se le pide a VM.
%
% CON EL SLIDER DE ZETA POR ENCIMA DE 1 EL SISTEMA DEJA DE OSCILAR, y ahi
% VM.trayA devuelve NaN en num.wd, num.X y num.env: sin oscilacion no hay
% frecuencia amortiguada ni envolvente que apriete los picos, porque no
% hay picos. El panel esconde la envolvente en vez de dibujar NaN.
%
% LA ANIMACION ES DECORATIVA. El dibujo respeta la posicion de la masa
% (esa sale de VM.trayA), pero las longitudes de los resortes y del
% amortiguador son geometria de dibujo, no deformaciones a escala.
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
        'k1', 40,   ...   % rigidez del resorte 1              [N/m]
        'k2', 20,   ...   % rigidez del resorte 2              [N/m]
        'c',  5,    ...   % coeficiente de amortiguamiento     [N*s/m]
        'm',  0.4,  ...   % masa                               [kg]
        'z',  NaN,  ...   % relacion de amortiguamiento [-] (sale abajo)
        'x0', 0.050,...   % posicion inicial x(0) [m]  (50.0 mm)
        'v0', 0);         % velocidad inicial xpunto(0)        [m/s]

    % Rigidez equivalente del enunciado. El argumento de VM.datosParalelos
    % es un VECTOR con las constantes; devuelve la suma, que es la rigidez
    % que "siente" la masa.
    kEnun = VM.datosParalelos([D.k1 D.k2]);    % rigidez equivalente [N/m]

    % zeta del enunciado. La saca VM.clasifA, que es calculo NUMERICO
    % directo (no simbolico, no lento). Sus cuatro salidas son:
    %   regimen ('sub'|'critico'|'sobre'), wn [rad/s], ccr [N*s/m], z [-]
    % Aca solo interesa la cuarta; las otras tres se descartan con ~.
    [~, ~, ~, D.z] = VM.clasifA('m',D.m, 'k',kEnun, 'c',D.c);

    P = D;   % parametros VIVOS, los que mueven los sliders

    % Rangos de los sliders: [minimo maximo] de cada parametro. z llega
    % hasta 2 a proposito, para cruzar los tres regimenes y no solo afinar
    % alrededor del valor del enunciado. c NO tiene slider: el
    % amortiguamiento se explora por zeta, que es un solo control y ademas
    % es lo que decide el regimen. El c del enunciado entra una sola vez,
    % arriba, para fijar la zeta de partida.
    R = struct( ...
        'k1', [1 200], 'k2', [1 200], 'm', [0.05 2], ...
        'z',  [0 2],   'x0', [-0.1 0.1], 'v0', [-1 1]);

    NOM = {'k1','k2','m','z','x0','v0'};              % orden de los sliders
    UNI = {'N/m','N/m','kg','-','m','m/s'};           % unidad de cada uno

    % VENTANA DE TIEMPO del grafico. Se fija UNA vez y no se recalcula: si
    % siguiera a z, el eje se reescalaria solo y todas las curvas se verian
    % iguales. Se toma la mas larga entre dos ventanas que elige VM sola:
    %   - la del caso del ENUNCIADO (sub-amortiguado: 4 periodos amortiguados)
    %   - la del MISMO sistema sin amortiguar (z = 0: 4 periodos naturales)
    % Asi la ventana aguanta tanto el caso de la hoja como los extremos del
    % slider sin dejar la curva cortada ni media hoja vacia.
    [tt0, xx0] = modelo(D);
    D0 = D; D0.z = 0;              % copia sin amortiguar, solo para medir
    tt0s = modelo(D0);
    TF   = max(tt0(end), tt0s(end));   % tiempo final del grafico       [s]
    XREF = max(abs(xx0));              % amplitud de referencia         [m]

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
    MAG  = {'keq','ccr','wn','z','wd'};
    MAGU = {'N/m','N*s/m','rad/s','-','rad/s'};
    % Etiquetas en ASCII pelado: uicontrol NO interpreta TeX, asi que un
    % '\zeta' aca se ve literal como barra-zeta. El TeX solo vale en
    % title, xlabel y demas texto de los EJES.
    MAGL = {'k_eq','c_cr','wn','z','wd'};

    % ---------------------------------------------------------------------
    % FIGURA Y EJES
    % ---------------------------------------------------------------------
    tmr = [];   % handle del timer; se declara ANTES de la figura porque
                % cerrar() puede correr antes de que se lo asigne

    fig = figure('Name','Problema 8 - dos resortes en paralelo, uno a cada lado', ...
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
    XC0 = 5.0;    % centro del bloque en reposo, en unidades de dibujo
    BW  = 2.0;    % ancho del bloque
    BH  = 1.4;    % alto del bloque
    YB  = -0.7;   % altura de la base del bloque
    XPD = 9.7;    % cara interior de la pared derecha

    % suelo y paredes (fijos, se dibujan una sola vez)
    plot(axAnim,[0 10],[-1.0 -1.0],'k-','LineWidth',2);
    patch('Parent',axAnim,'XData',[0 0.3 0.3 0],'YData',[-1 -1 2.4 2.4], ...
        'FaceColor',[0.85 0.82 0.75],'EdgeColor','k');
    patch('Parent',axAnim,'XData',[XPD 10 10 XPD],'YData',[-1 -1 2.4 2.4], ...
        'FaceColor',[0.85 0.82 0.75],'EdgeColor','k');

    % resortes: uno de cada lado, los dos de pared a masa. En PARALELO,
    % aunque esten enfrentados: los dos se deforman lo mismo que la masa,
    % por eso keq = k1 + k2.
    hResI = plot(axAnim,nan,nan,'-','Color',[0.20 0.45 0.70],'LineWidth',1.8);
    hResD = plot(axAnim,nan,nan,'-','Color',[0.10 0.60 0.45],'LineWidth',1.8);

    % amortiguador ARRIBA: montante que sube del techo del bloque, vastago
    % horizontal y cilindro anclado a la pared derecha
    hMont = plot(axAnim,nan,nan,'k-','LineWidth',2.5);
    hAmoV = plot(axAnim,nan,nan,'k-','LineWidth',2.5);
    hAmoC = patch('Parent',axAnim,'XData',nan,'YData',nan, ...
        'FaceColor',[0.80 0.88 0.95],'EdgeColor','k','LineWidth',1.2);

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
    % carteles fijos
    text(axAnim, 1.6, 0.75,'k1','HorizontalAlignment','center', ...
        'Color',[0.20 0.45 0.70],'FontSize',9);
    text(axAnim, 8.4, 0.75,'k2','HorizontalAlignment','center', ...
        'Color',[0.10 0.60 0.45],'FontSize',9);
    text(axAnim, 8.9, 2.10,'c','HorizontalAlignment','center', ...
        'Color','k','FontSize',9);

    % --- eje de la respuesta temporal ------------------------------------
    hold(axResp,'on'); grid(axResp,'on');
    hEnvS = plot(axResp,nan,nan,'r--','LineWidth',1,'Tag','envSup', ...
        'DisplayName','Envolvente');
    hEnvI = plot(axResp,nan,nan,'r--','LineWidth',1,'Tag','envInf', ...
        'HandleVisibility','off');
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
        'FontSize',12,'FontWeight','bold','BackgroundColor','w', ...
        'Tag','regimen');

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
            'Tag',['sli_' NOM{i}], ...
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
        % Se pide tf = TF para que la curva cubra la ventana entera: sin
        % eso, al subir zeta VM elegiria una ventana mas corta y quedaria
        % medio eje vacio.
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
        % Un frame: mueve el bloque y el marcador. Solo set(), nada de
        % replot. Si la figura ya no esta, no hace nada.
        if ~isvalid(fig) || isempty(TT), return, end
        idx = idx + 4;
        if idx > numel(TT), idx = 1; end

        xc = XC0 + ESC*XX(idx);                 % centro del bloque [dibujo]
        xc = min(max(xc, 2.6), 6.6);            % tope: que no atraviese muros
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

        set(hBloq,'XData',[iz de de iz],'YData',[YB YB YB+BH YB+BH]);
        set(hRue1,'XData',xc-0.6,'YData',YB-0.15);
        set(hRue2,'XData',xc+0.6,'YData',YB-0.15);

        % resorte de cada lado, los dos de pared a masa
        [xa, ya] = zigzag(0.3, iz,  0.0, 9, 0.22);   % k1: pared izq -> masa
        [xb, yb] = zigzag(de,  XPD, 0.0, 9, 0.22);   % k2: masa -> pared der
        set(hResI,'XData',xa,'YData',ya);
        set(hResD,'XData',xb,'YData',yb);

        % amortiguador arriba: montante vertical desde el techo del bloque,
        % vastago horizontal y cilindro anclado a la pared derecha
        xm = xc + 0.6;                                    % pie del montante
        set(hMont,'XData',[xm xm],'YData',[YB+BH 1.65]);
        set(hAmoV,'XData',[xm 8.7],'YData',[1.65 1.65]);
        set(hAmoC,'XData',[8.1 XPD XPD 8.1],'YData',[1.40 1.40 1.90 1.90]);
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
        jwn = strcmp(MAG,'wn');  jz = strcmp(MAG,'z');
        if ~isnan(v(jwn)) && ~isnan(v(jz))
            try
                % VM traduce TU wn y TU z a k y c; no se despeja aca.
                g = VM.genA('m',P.m, 'wn',v(jwn), 'z',v(jz));
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
                    if alto, s = 'tu resorte equivalente es mas duro';
                    else,    s = 'tu resorte equivalente es mas blando'; end
                case 'ccr'
                    if alto, s = 'tu sistema pediria mas amortiguador para no oscilar';
                    else,    s = 'tu sistema pediria menos amortiguador para no oscilar'; end
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
        % para pegar en el LaTeX de la entrega. Sin tf: se deja que VM
        % elija la ventana del caso del enunciado, que es la mas ajustada.
        if ~exist('figs','dir'), mkdir('figs'); end
        [t,x,~,n] = modelo(D);

        f = figure('Color','w','Position',[100 100 900 420],'Visible','off');
        theme(f,'light');
        ax = axes('Parent',f); hold(ax,'on'); grid(ax,'on');
        if ~isnan(n.X)   % con los valores del enunciado si hay envolvente
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
        title(ax,sprintf('Problema 8 - caso %s (\\zeta = %.3f)', ...
            n.regimen, n.z),'Color','k');

        gif = fullfile('figs','sim8.gif');
        if exist(gif,'file'), delete(gif); end
        % exportgraphics con 'Append' arma el GIF animado cuadro a cuadro.
        for i = 1:20:numel(t)
            set(hm,'XData',t(i),'YData',x(i));
            exportgraphics(ax, gif, 'Append', i > 1);
        end
        exportgraphics(ax, fullfile('figs','sim8.png'), 'Resolution',150);
        close(f);
        fprintf('Escrito: %s\n', gif);
        fprintf('Escrito: %s\n', fullfile('figs','sim8.png'));
    end
end

% =========================================================================
% FUNCIONES LOCALES (no anidadas: no ven las variables de arriba)
% =========================================================================

function [t, x, v, num] = modelo(p, tf)
    % Traduce los parametros del problema a una llamada a VM.
    % ENTRADAS:
    %   p  : struct con k1, k2, m, z, x0, v0
    %   tf : tiempo final [s], OPCIONAL. Sin el, VM.trayA elige la ventana
    %        sola segun el regimen (4 periodos si oscila, 6/wn si no)
    % Los dos resortes estan sin estirar en x = 0 y los dos van de pared a
    % masa: sufren la MISMA deformacion, asi que estan en PARALELO y las
    % rigideces se suman.
    keq = VM.datosParalelos([p.k1 p.k2]);   % rigidez equivalente [N/m]

    % Argumentos de VM.trayA:
    %   'm'    masa [kg]                'k'   rigidez equivalente [N/m]
    %   'z'    relacion de amortiguamiento [-] (entra por aca el slider;
    %          VM convierte a c internamente)
    %   'x0'   posicion inicial [m]     'v0'  velocidad inicial [m/s]
    %   'npts' puntos de la curva [adim]
    args = {'m',p.m, 'k',keq, 'z',p.z, 'x0',p.x0, 'v0',p.v0, 'npts',600};
    if nargin > 1 && ~isempty(tf)
        args = [args, {'tf',tf}];
    end
    [t, x, v, num] = VM.trayA(args{:});
end

function r = referencia(p)
    % Valores de referencia del panel de comprobacion, todos de VM.
    % Se calcula UNA vez con los valores del enunciado, que caen en el caso
    % SUB-amortiguado: por eso VM.subA, que es el unico de los tres que
    % tiene wd.
    keq = VM.datosParalelos([p.k1 p.k2]);
    s   = VM.subA('m',p.m, 'k',keq, 'z',p.z, 'x0',p.x0, 'v0',p.v0);
    r = struct('keq',keq, ...
        'ccr', double(s.ccr), ...   % amortiguamiento critico   [N*s/m]
        'wn',  double(s.wn),  ...   % frecuencia natural        [rad/s]
        'z',   p.z,           ...   % relacion de amortiguamiento   [-]
        'wd',  double(s.wd));       % frecuencia amortiguada    [rad/s]
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
