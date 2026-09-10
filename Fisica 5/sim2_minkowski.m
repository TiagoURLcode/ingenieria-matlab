function sim2_minkowski(modo)
% SIM2_MINKOWSKI - simulador del diagrama de espacio-tiempo de Minkowski.
%
% Visualizacion interactiva de la cinematica relativista y la transformacion
% de Lorentz en un unico plano espacio-tiempo:
%   Eje horizontal:  posicion x [m] en el marco de referencia S
%   Eje vertical:    tiempo escalado ct [m] en el marco S (c = 299792458 m/s)
%
% POR QUE ct Y NO t:
%   Al multiplicar el tiempo t [s] por la velocidad de la luz c [m/s], la
%   coordenada vertical ct adquiere unidades de longitud [m], poniendo al
%   espacio y al tiempo en pie de igualdad. Ademas, la trayectoria de un pulso
%   de luz cumple x = c*t (hacia la derecha) o x = -c*t (hacia la izquierda),
%   lo que en el plano (x, ct) equivale a ct = x y ct = -x: rectas con
%   pendiente 1 y -1, es decir, a 45 GRADOS EXACTOS. Cualquier particula con
%   masa viaja a v < c, por lo que su linea de universo siempre tiene una
%   pendiente mayor a 1 respecto al eje horizontal (mas empinada que 45 deg).
%
% USO:
%   sim2_minkowski             % modo interactivo con sliders y botones
%   sim2_minkowski('exportar') % genera figs/sim2_minkowski.png sin ventana
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica se delega a FV.m:
%   c = double(FV.ctes().c);              % velocidad de la luz [m/s]
%   r = FV.rel('v', beta*c, 'Lo', Lo);    % factor gamma y longitud contraida L
%   e = FV.lorentz('x',xA, 't',tA, 'v',v);% transformacion de coordenadas
%
% PENDIENTES DE LOS EJES PRIMADOS:
%   Salen directamente de la transformacion de Lorentz:
%     x'  = gam * (x - v*t) = gam * (x - beta*ct)
%     ct' = gam * (ct - beta*x)
%   El eje ct' es la linea de universo del origen de S' (x' = 0):
%     x' = 0  =>  x - beta*ct = 0  =>  ct = (1/beta)*x  (pendiente 1/beta)
%   El eje x' es la linea de simultaneidad de S' (t' = 0, ct' = 0):
%     ct' = 0 =>  ct - beta*x = 0  =>  ct = beta*x      (pendiente beta)
%   Conforme beta -> 1, ambas pendientes convergen a 1, cerrandose sobre
%   el cono de luz a 45 grados como una tijera.
%
% TRAMPA DE UNIDADES:
%   FV.lorentz recibe t en SEGUNDOS [s]. Al entrar: t = ct / c.
%   Al salir: la coordenada temporal primada en metros es ct' = double(e.tp)*c.

    if nargin < 1, modo = ''; end

    % ---------------------------------------------------------------------
    % CONSTANTES FISICAS. Salen exactas de FV.ctes()
    % ---------------------------------------------------------------------
    c = double(FV.ctes().c);              % velocidad de la luz [m/s]

    % ---------------------------------------------------------------------
    % DEFAULTS. Esta struct NO se modifica: es la referencia de "Restaurar".
    % ---------------------------------------------------------------------
    D = struct( ...
        'beta', 0.60, ...   % velocidad relativa beta = v/c [-]
        'Lo',   2.00);      % longitud propia de la barra [m]

    P = D;                  % parametros VIVOS, modificados por los sliders

    % Rangos [minimo maximo] de los parametros interactivos
    R = struct( ...
        'beta', [-0.95 0.95], ... % limite seguro antes de la divergencia en c
        'Lo',   [0.50  5.00]);    % longitud propia de la barra [m]

    % Coordenadas fijas de dos eventos A y B en el marco S [m]
    % Se eligen con separacion de tipo espacio para evidenciar la relatividad
    % de la simultaneidad y el cambio de orden temporal segun el observador.
    xA  = 1.00; ctA = 2.00;   % Evento A en S: posicion 1 m, tiempo 2/c s
    xB  = 4.00; ctB = 3.00;   % Evento B en S: posicion 4 m, tiempo 3/c s

    % ---------------------------------------------------------------------
    % CACHE. FV.rel y FV.lorentz resuelven ecuaciones simbolicas (~25 ms).
    % Un slider dispara llamadas continuas al arrastrarse. Se memoizan los
    % resultados en un containers.Map indexado por beta y Lo redondeados.
    % ---------------------------------------------------------------------
    cacheRel = containers.Map('KeyType','char','ValueType','any');

    % Variable compartida para el eje principal
    axMink = gobjects(1);

    if strcmpi(modo, 'exportar')
        exportar();
        return;
    end

    % ---------------------------------------------------------------------
    % INTERFAZ GRAFICA (MODO INTERACTIVO)
    % Solo caracteres ASCII pelados: sin tildes ni enies para evitar basura.
    % ---------------------------------------------------------------------
    fig = figure('Name','Diagrama de Minkowski - Relatividad Especial', ...
        'NumberTitle','off', 'Color','w', ...
        'Position',[80 60 1180 740]);

    % Eje principal grande para el diagrama espacio-tiempo
    axMink = axes('Parent',fig, 'Position',[0.06 0.08 0.66 0.85]);

    % Panel lateral de controles
    panC = uipanel('Parent',fig, 'Title','Controles', ...
        'Units','normalized', 'Position',[0.75 0.08 0.22 0.32], ...
        'BackgroundColor','w');

    % Panel lateral informativo con sintesis teorica para estudio
    panInfo = uipanel('Parent',fig, 'Title','Guia de Minkowski', ...
        'Units','normalized', 'Position',[0.75 0.44 0.22 0.49], ...
        'BackgroundColor','w');

    txtGuia = sprintf([ ...
        'CONCEPTOS CLAVE:\n\n' ...
        '* Eje horizontal: x [m]\n' ...
        '* Eje vertical: ct [m]\n' ...
        '  (c = 299792458 m/s)\n\n' ...
        '* Cono de luz a 45 deg exactos\n' ...
        '  rectas ct = x  y  ct = -x\n\n' ...
        '* Eje ct'' (origen de S'', x''=0):\n' ...
        '  recta ct = x/beta, pend. 1/beta\n\n' ...
        '* Eje x'' (simultaneidad S'', ct''=0):\n' ...
        '  recta ct = beta*x, pend. beta\n\n' ...
        '* Al crecer |beta| -> 1, ct'' y x''\n' ...
        '  se cierran hacia el cono de luz.\n\n' ...
        '* Barra: reposo en S (ancho Lo).\n' ...
        '  S'' la mide simultanea sobre x'':\n' ...
        '  segmento contraido L = Lo/gam.']);

    uicontrol('Parent',panInfo, 'Style','text', ...
        'Units','normalized', 'Position',[0.05 0.05 0.90 0.90], ...
        'HorizontalAlignment','left', 'BackgroundColor','w', ...
        'ForegroundColor',[0.15 0.15 0.15], 'FontSize',8.5, ...
        'String',txtGuia);

    % Sliders: beta = v/c y Lo
    textos = {'beta = v/c', 'Lo (longitud propia barra)'};
    hLab = gobjects(1, 2);
    hSli = gobjects(1, 2);

    % Slider 1: beta
    hLab(1) = uicontrol('Parent',panC, 'Style','text', ...
        'Units','normalized', 'Position',[0.06 0.78 0.88 0.12], ...
        'HorizontalAlignment','left', 'BackgroundColor','w', ...
        'ForegroundColor',[0.15 0.15 0.15], 'String',textos{1});
    rgBeta = R.beta;
    pasoBeta = 0.01 / (rgBeta(2) - rgBeta(1)); % paso fino 0.01
    hSli(1) = uicontrol('Parent',panC, 'Style','slider', ...
        'Units','normalized', 'Position',[0.06 0.64 0.88 0.12], ...
        'Min',rgBeta(1), 'Max',rgBeta(2), 'Value',P.beta, ...
        'SliderStep',[pasoBeta pasoBeta*5], ...
        'Callback', @(src,~) moverSlider('beta', get(src,'Value')));

    % Slider 2: Lo
    hLab(2) = uicontrol('Parent',panC, 'Style','text', ...
        'Units','normalized', 'Position',[0.06 0.44 0.88 0.12], ...
        'HorizontalAlignment','left', 'BackgroundColor','w', ...
        'ForegroundColor',[0.15 0.15 0.15], 'String',textos{2});
    rgLo = R.Lo;
    pasoLo = 0.10 / (rgLo(2) - rgLo(1)); % paso fino 0.10 m
    hSli(2) = uicontrol('Parent',panC, 'Style','slider', ...
        'Units','normalized', 'Position',[0.06 0.30 0.88 0.12], ...
        'Min',rgLo(1), 'Max',rgLo(2), 'Value',P.Lo, ...
        'SliderStep',[pasoLo pasoLo*5], ...
        'Callback', @(src,~) moverSlider('Lo', get(src,'Value')));

    % Boton Restaurar
    uicontrol('Parent',panC, 'Style','pushbutton', 'String','Restaurar', ...
        'Units','normalized', 'Position',[0.06 0.06 0.88 0.18], ...
        'Callback', @(~,~) restaurar());

    refrescar();

    % =====================================================================
    %  CALLBACKS
    % =====================================================================

    function moverSlider(campo, val)
        switch campo
            case 'beta'
                % Redondeo a 2 decimales para paso exacto de 0.01
                P.beta = round(val * 100) / 100;
                set(hSli(1), 'Value', P.beta);
            case 'Lo'
                % Redondeo a 2 decimales para paso exacto de 0.05 / 0.10 m
                P.Lo = round(val * 20) / 20;
                set(hSli(2), 'Value', P.Lo);
        end
        refrescar();
    end

    function restaurar()
        P = D;
        set(hSli(1), 'Value', P.beta);
        set(hSli(2), 'Value', P.Lo);
        refrescar();
    end

    function refrescar()
        set(hLab(1), 'String', sprintf('beta = v/c : %+.2f', P.beta));
        set(hLab(2), 'String', sprintf('Lo (propia): %.2f m', P.Lo));
        dat = datosRelativistas(P.beta, P.Lo);
        dibujarMinkowski(dat);
        drawnow;
    end

    % =====================================================================
    %  DATOS: todo lo que involucra formulas relativistas pasa por FV.m
    % =====================================================================

    function d = datosRelativistas(beta, Lo)
        % Clave de memoizacion por beta y Lo redondeados
        clave = sprintf('%.2f_%.2f', beta, Lo);
        if isKey(cacheRel, clave)
            d = cacheRel(clave);
            return;
        end

        % 1. Factor gamma y longitud contraida L desde FV.rel
        %    r devuelve r.gam y r.L como sym; se convierten con double().
        r = FV.rel('v', beta*c, 'Lo', Lo);
        d.gam = double(r.gam);   % factor de Lorentz [-]
        d.L   = double(r.L);     % longitud contraida medida en S' [m]

        % 2. Transformacion de Lorentz para eventos A y B
        %    FV.lorentz opera con t en SEGUNDOS.
        %    Al entrar: t = ct / c.
        %    Al salir: ct' = c * tp.
        %    NOTA: Si beta == 0, los marcos coinciden y tp desaparece del
        %    despeje simbolico (0*tp = 0); se asignan los valores de S.
        tA_seg = ctA / c;
        eA = FV.lorentz('x', xA, 't', tA_seg, 'v', beta*c);
        if isfield(eA, 'xp')
            d.xpA = double(eA.xp);
        else
            d.xpA = xA;
        end
        if isfield(eA, 'tp')
            d.ctpA = double(eA.tp) * c;
        else
            d.ctpA = ctA;
        end

        tB_seg = ctB / c;
        eB = FV.lorentz('x', xB, 't', tB_seg, 'v', beta*c);
        if isfield(eB, 'xp')
            d.xpB = double(eB.xp);
        else
            d.xpB = xB;
        end
        if isfield(eB, 'tp')
            d.ctpB = double(eB.tp) * c;
        else
            d.ctpB = ctB;
        end

        cacheRel(clave) = d;
    end

    % =====================================================================
    %  ESTILO DE EJE: proteccion contra tema oscuro
    % =====================================================================

    function estiloEje(ax)
        % MATLAB puede arrancar en tema OSCURO y pintar axes con fondo negro.
        % Se fuerza fondo blanco y textos oscuros de forma explicita.
        set(ax, 'Color','w', ...
            'XColor',[0.15 0.15 0.15], 'YColor',[0.15 0.15 0.15], ...
            'GridColor',[0.70 0.70 0.70], 'GridAlpha',0.7);
        ax.Title.Color = [0.15 0.15 0.15];
    end

    % =====================================================================
    %  DIBUJO DEL DIAGRAMA DE MINKOWSKI
    % =====================================================================

    function dibujarMinkowski(dat)
        cla(axMink);
        hold(axMink, 'on');
        grid(axMink, 'on');

        % Escala cuadrada para que el cono de luz este a 45 grados exactos
        lim = 6.0;   % limite de visualizacion [-lim, lim] en metros [m]
        axis(axMink, 'equal');
        xlim(axMink, [-lim lim]);
        ylim(axMink, [-lim lim]);

        % -----------------------------------------------------------------
        % 1. EJES DE S: horizontal ct=0 y vertical x=0 en gris
        % -----------------------------------------------------------------
        plot(axMink, [-lim lim], [0 0], '-', 'Color',[0.55 0.55 0.55], ...
            'LineWidth',1.2);
        plot(axMink, [0 0], [-lim lim], '-', 'Color',[0.55 0.55 0.55], ...
            'LineWidth',1.2);
        text(lim*0.93, -0.32, 'x [m]', 'Parent',axMink, ...
            'Color',[0.40 0.40 0.40], 'FontSize',9);
        text(0.18, lim*0.94, 'ct [m]', 'Parent',axMink, ...
            'Color',[0.40 0.40 0.40], 'FontSize',9);

        % -----------------------------------------------------------------
        % 2. CONO DE LUZ: ct = x  y  ct = -x (punteadas, rotuladas "luz")
        %    Representa la velocidad limite c. Todo evento causal respecto
        %    al origen cae dentro de este cono.
        % -----------------------------------------------------------------
        plot(axMink, [-lim lim], [-lim lim], ':', ...
            'Color',[0.85 0.55 0.10], 'LineWidth',1.4);
        plot(axMink, [-lim lim], [lim -lim], ':', ...
            'Color',[0.85 0.55 0.10], 'LineWidth',1.4);
        text(lim*0.82, lim*0.82 + 0.28, 'luz', 'Parent',axMink, ...
            'Color',[0.85 0.55 0.10], 'FontSize',9, 'FontWeight','bold');
        text(lim*0.82, -lim*0.82 - 0.35, 'luz', 'Parent',axMink, ...
            'Color',[0.85 0.55 0.10], 'FontSize',9, 'FontWeight','bold', ...
            'HorizontalAlignment','center');

        % -----------------------------------------------------------------
        % 5. GRILLA PRIMADA: 4 lineas paralelas a x' y 4 paralelas a ct'
        %    Muestra la deformacion de la malla espacio-tiempo por boost.
        %    x' = cte  =>  x = beta*ct + x'/gam  (paralelas a ct')
        %    ct' = cte =>  ct = beta*x + ct'/gam (paralelas a x')
        % -----------------------------------------------------------------
        gridVals = [-4 -2 2 4];   % desplazamientos primados en metros [m]
        for k = 1:numel(gridVals)
            val = gridVals(k);
            % Linea de coordenada x' constante (paralela a ct')
            xG = P.beta * [-lim lim] + (val / dat.gam);
            plot(axMink, xG, [-lim lim], ':', ...
                'Color',[0.72 0.78 0.90], 'LineWidth',0.9);

            % Linea de coordenada ct' constante (paralela a x')
            ctG = P.beta * [-lim lim] + (val / dat.gam);
            plot(axMink, [-lim lim], ctG, ':', ...
                'Color',[0.72 0.78 0.90], 'LineWidth',0.9);
        end

        % -----------------------------------------------------------------
        % 3. EJE ct': recta ct = x/beta, pendiente 1/beta
        %    Es la linea de universo del origen de S' (x' = 0 => x = beta*ct).
        %    Con beta = 0 se vuelve la vertical x = 0 sin dividir por cero.
        % -----------------------------------------------------------------
        plot(axMink, P.beta*[-lim lim], [-lim lim], '-', ...
            'Color',[0.10 0.40 0.85], 'LineWidth',2.0);

        % -----------------------------------------------------------------
        % 4. EJE x': recta ct = beta*x, pendiente beta
        %    Es la recta de simultaneidad de S' (ct' = 0 => ct = beta*x).
        % -----------------------------------------------------------------
        plot(axMink, [-lim lim], P.beta*[-lim lim], '-', ...
            'Color',[0.10 0.40 0.85], 'LineWidth',2.0);

        % Rotulacion de las pendientes en pantalla
        if P.beta ~= 0
            strPendCt = sprintf('%.2f', 1 / P.beta);
        else
            strPendCt = 'Inf';
        end
        strPendX = sprintf('%.2f', P.beta);

        % Ubicacion dinamica de etiquetas de ejes primados para evitar solapes
        posCtX = P.beta * lim * 0.85 + 0.15;
        posCtY = lim * 0.85;
        text(posCtX, posCtY, sprintf('ct'' (m = %s)', strPendCt), ...
            'Parent',axMink, 'Color',[0.10 0.40 0.85], ...
            'FontWeight','bold', 'FontSize',9);

        posX_X = lim * 0.78;
        posX_Y = P.beta * lim * 0.78 - 0.32;
        text(posX_X, posX_Y, sprintf('x'' (m = %s)', strPendX), ...
            'Parent',axMink, 'Color',[0.10 0.40 0.85], ...
            'FontWeight','bold', 'FontSize',9);

        % -----------------------------------------------------------------
        % 6. LA BARRA: lineas de universo verticales en reposo en S
        %    x = 0  y  x = Lo.
        %    S' mide la longitud simultaneamente sobre su propio eje x'
        %    (ct' = 0 => ct = beta*x). El segmento resultante sobre x' tiene
        %    longitud contraida L = Lo/gam.
        % -----------------------------------------------------------------
        plot(axMink, [0 0], [-lim lim], '--', ...
            'Color',[0.75 0.20 0.20], 'LineWidth',1.1);
        plot(axMink, [P.Lo P.Lo], [-lim lim], '--', ...
            'Color',[0.75 0.20 0.20], 'LineWidth',1.1);
        text(P.Lo + 0.12, -lim*0.85, sprintf('x = Lo = %.2f m', P.Lo), ...
            'Parent',axMink, 'Color',[0.75 0.20 0.20], 'FontSize',8);

        % Segmento de longitud contraida L medido por S' (sobre el eje x')
        plot(axMink, [0 P.Lo], [0 P.beta*P.Lo], '-', ...
            'Color',[0.85 0.15 0.10], 'LineWidth',3.2);
        plot(axMink, [0 P.Lo], [0 P.beta*P.Lo], 'o', 'MarkerSize',5.5, ...
            'MarkerFaceColor',[0.85 0.15 0.10], 'MarkerEdgeColor','none');
        text(P.Lo*0.5, P.beta*P.Lo*0.5 + 0.35, ...
            sprintf('L = %.2f m (en S'')', dat.L), ...
            'Parent',axMink, 'Color',[0.85 0.15 0.10], ...
            'FontWeight','bold', 'FontSize',8.5);

        % Segmento de longitud propia Lo medido por S (sobre el eje x, ct = 0)
        plot(axMink, [0 P.Lo], [0 0], '-', ...
            'Color',[0.20 0.60 0.20], 'LineWidth',2.2);
        text(P.Lo*0.5, -0.42, sprintf('Lo = %.2f m (en S)', P.Lo), ...
            'Parent',axMink, 'Color',[0.20 0.60 0.20], ...
            'FontWeight','bold', 'FontSize',8, ...
            'HorizontalAlignment','center');

        % -----------------------------------------------------------------
        % 7. DOS EVENTOS A Y B: puntos marcados con coordenadas en S y S'
        %    Se grafican en las coordenadas reales de S (xA, ctA) y (xB, ctB).
        %    En S:  ctA = 2 < ctB = 3  (A ocurre antes que B).
        %    Con beta = 0.6: ct'A = 1.75 > ct'B = 0.75 (B ocurre antes que A).
        %    Evidencia directa de la relatividad de la simultaneidad.
        % -----------------------------------------------------------------
        plot(axMink, xA, ctA, 'o', 'MarkerSize',7.5, ...
            'MarkerFaceColor',[0.15 0.70 0.30], 'MarkerEdgeColor','k', ...
            'LineWidth',0.8);
        text(xA + 0.15, ctA + 0.15, 'A', 'Parent',axMink, ...
            'Color',[0.10 0.55 0.20], 'FontWeight','bold', 'FontSize',9.5);

        plot(axMink, xB, ctB, 's', 'MarkerSize',7.5, ...
            'MarkerFaceColor',[0.65 0.20 0.75], 'MarkerEdgeColor','k', ...
            'LineWidth',0.8);
        text(xB + 0.15, ctB + 0.15, 'B', 'Parent',axMink, ...
            'Color',[0.50 0.15 0.60], 'FontWeight','bold', 'FontSize',9.5);

        % Tarjeta de texto de coordenadas de los eventos A y B
        txtEv = sprintf([ ...
            'EVENTOS ESPACIO-TIEMPO\n' ...
            '-----------------------------\n' ...
            'Evento A:\n' ...
            '  S : x = %4.2f m,  ct = %4.2f m\n' ...
            '  S'': x''= %4.2f m, ct''= %4.2f m\n\n' ...
            'Evento B:\n' ...
            '  S : x = %4.2f m,  ct = %4.2f m\n' ...
            '  S'': x''= %4.2f m, ct''= %4.2f m'], ...
            xA, ctA, dat.xpA, dat.ctpA, xB, ctB, dat.xpB, dat.ctpB);

        text(-lim*0.93, -lim*0.35, txtEv, 'Parent',axMink, ...
            'VerticalAlignment','top', 'BackgroundColor','w', ...
            'EdgeColor',[0.70 0.70 0.70], 'FontSize',8, ...
            'FontName','FixedWidth', 'Color',[0.15 0.15 0.15], 'Margin',4);

        % -----------------------------------------------------------------
        % 8. PANEL DE TEXTO CON PARAMETROS RELATIVISTAS
        %    beta, gamma, pendientes de ct' y x', Lo, L y % de contraccion.
        % -----------------------------------------------------------------
        pctContr = (1 - dat.L / P.Lo) * 100;
        txtPar = sprintf([ ...
            'PARAMETROS RELATIVISTAS\n' ...
            '-----------------------------\n' ...
            'beta = v/c      : %+.2f\n' ...
            'gamma (Lorentz) : %.3f\n' ...
            'Pendiente ct''   : %s\n' ...
            'Pendiente x''    : %s\n' ...
            'Lo (propia)     : %.2f m\n' ...
            'L  (contraida)  : %.2f m\n' ...
            'Contraccion     : %.1f %%'], ...
            P.beta, dat.gam, strPendCt, strPendX, P.Lo, dat.L, pctContr);

        text(-lim*0.93, lim*0.95, txtPar, 'Parent',axMink, ...
            'VerticalAlignment','top', 'BackgroundColor','w', ...
            'EdgeColor',[0.70 0.70 0.70], 'FontSize',8, ...
            'FontName','FixedWidth', 'Color',[0.15 0.15 0.15], 'Margin',4);

        title(axMink, ...
            sprintf('Diagrama de Minkowski (beta = %+.2f, Lo = %.2f m)', ...
            P.beta, P.Lo), 'FontWeight','normal');
        estiloEje(axMink);
    end

    % =====================================================================
    %  EXPORTAR - render fijo en figs/sim2_minkowski.png sin ventana.
    %  Sin panel de controles, utilizando los valores por defecto D.
    % =====================================================================

    function exportar()
        if ~isfolder('figs'), mkdir('figs'); end

        figExp = figure('Color','w', 'Position',[100 100 1180 740], ...
            'Visible','off');
        axMink = axes('Parent',figExp, 'Position',[0.08 0.08 0.84 0.85]);

        datExp = datosRelativistas(P.beta, P.Lo);
        dibujarMinkowski(datExp);

        exportgraphics(figExp, fullfile('figs','sim2_minkowski.png'), ...
            'Resolution',150);
        close(figExp);
    end
end
