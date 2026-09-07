function sim2_oscilogramaMotor(modo)
% SIM2_OSCILOGRAMAMOTOR - simulador interactivo del problema 2 de Tarea 2.
%
% Un motor electrico de 500 N montado sobre un soporte. El dato NO son los
% parametros del sistema: es una GRAFICA, un oscilograma de x(t) en mm
% contra t en segundos. De esa grafica se leen los picos y de ahi sale
% todo hacia atras, por DECREMENTO LOGARITMICO.
%
% USO:
%   sim2_oscilogramaMotor             % modo interactivo
%   sim2_oscilogramaMotor('exportar') % render fijo + PNG y GIF en ./figs/
%
% POR QUE ESTE ES DISTINTO DE LOS DEMAS SIMULADORES. En los otros la
% referencia contra la que comparas es una curva CALCULADA. Aca la
% referencia son LOS PUNTOS LEIDOS DEL OSCILOGRAMA: van dibujados como
% marcadores sueltos y NO se mueven nunca, porque son el dato crudo.
% Encima se superpone la curva que sale de VM con la lectura viva de los
% sliders. Toda la gracia es ver si la curva pasa o no por los picos:
% moves la lectura, la curva se despega de los puntos, y ahi ves cuanto
% cuesta un error de lectura.
%
% Aca no hay animacion de un bloque a proposito: no aportaria nada. Ese
% espacio lo ocupa la vista ampliada de los dos picos que entran al
% decremento, con la envolvente, que es de donde sale el metodo.
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica es de VM.m:
%   VM.subA   despeja hacia atras delta, z, wn, wd, k y c a partir de los
%             picos leidos x1 y x2, los ciclos n entre ellos, el periodo
%             amortiguado taud y la masa m. Es el metodo del decremento
%   VM.trayA  entrega x(t) y la envolvente con esos m, k y c
% Aca no se escribe NI UNA formula de vibraciones. La unica cuenta que no
% sale de VM es masa = peso/g, que es estatica, no vibraciones.
%
% LAS RESPUESTAS NO SE MUESTRAN. El problema pregunta el tipo de
% amortiguamiento, la constante de rigidez, el coeficiente de
% amortiguamiento y la frecuencia amortiguada. O sea que la etiqueta de
% regimen y los valores de k, c y wd SON las respuestas: arrancan OCULTOS
% y cada uno tiene su propio boton "Revelar". Nada de eso se imprime por
% consola ni queda en el workspace, porque vive en variables de funciones
% anidadas que se mueren con la figura.

    if nargin < 1, modo = ''; end

    % ---------------------------------------------------------------------
    % EL OSCILOGRAMA. Los cuatro picos que se leen de la grafica del
    % enunciado. Estos vectores NO los tocan los sliders: son el dato, y
    % son los marcadores sueltos del panel principal.
    % ---------------------------------------------------------------------
    TLEIDO = [0 0.2 0.4 0.6];       % instantes de los picos [s]
    XLEIDO = [8 4 2 1]*1e-3;        % amplitud de cada pico  [m]  (8, 4, 2 y 1 mm)

    % ---------------------------------------------------------------------
    % DEFAULTS DE LA LECTURA. Esta struct NO se sobrescribe nunca: es a
    % donde vuelve el boton "Restaurar". Los sliders trabajan sobre P, que
    % es una copia.
    % ---------------------------------------------------------------------
    D = struct( ...
        'x1',   8e-3, ...   % primer pico leido                   [m]  (8 mm)
        'x2',   4e-3, ...   % segundo pico elegido                [m]  (4 mm)
        'n',    1,    ...   % CICLOS entre x1 y x2                [adim] (picos seguidos)
        'taud', 0.2,  ...   % periodo amortiguado leido           [s]
        'W',    500,  ...   % peso del motor                      [N]
        'z',    0.5);       % zeta de TU curva de tanteo          [adim]

    % OJO CON n. Es la cantidad de CICLOS entre el pico x1 y el pico x2, NO
    % la cantidad de picos. Con picos seguidos (8 mm y 4 mm) n = 1. Si en
    % vez del segundo pico elegis el cuarto (1 mm), entre ellos hay 3
    % ciclos y va n = 3: delta tiene que dar lo MISMO. Ese es justamente el
    % control que ensena el metodo, y por eso n es un slider y no un
    % numero fijo. Ver el comentario largo de VM.ecSubA.

    % z NO es una lectura del oscilograma: es un control de tanteo. Mueve
    % una segunda curva, con el mismo m y el mismo k que salieron de la
    % lectura pero con TU zeta, para barrer los tres regimenes (sub,
    % critico y sobre) y ver como se deforma la respuesta.

    G = 9.81;   % aceleracion de la gravedad [m/s^2]

    P = D;   % lectura VIVA, la que mueven los sliders

    % Rangos de los sliders: [minimo maximo] de cada parametro.
    %   x2 llega mas alto que su valor leido A PROPOSITO, para poder poner
    %   x2 > x1 y ver que pasa cuando la lectura no describe una
    %   oscilacion que decae (ver el aviso del panel).
    %   z llega hasta 2 para cruzar los tres regimenes.
    R = struct( ...
        'x1',   [1e-3 16e-3], ...
        'x2',   [0.5e-3 16e-3], ...
        'n',    [1 4],  ...
        'taud', [0.05 0.60], ...
        'W',    [100 1500], ...
        'z',    [0 2]);

    NOM = {'x1','x2','n','taud','W','z'};                       % orden de los sliders
    UNI = {'mm','mm','ciclos','s','N','-'};                     % unidad que se MUESTRA
    ESC = [1e3, 1e3, 1, 1, 1, 1];                               % factor de PRESENTACION

    % ESC es solo presentacion: el calculo va siempre en unidades SI base
    % (metros), y ESC nada mas convierte a mm para que la etiqueta diga
    % "8 mm" y no "0.008 m". Nunca entra a VM.

    MM = 1e3;   % escala de presentacion de los EJES: metros -> milimetros.
                % El oscilograma del enunciado esta en mm, asi que el eje
                % se dibuja en mm. Todo lo que se calcula sigue en metros.

    % tf del eje de tiempo: se fija UNA vez con la lectura del enunciado y
    % no se recalcula. Asi, al mover la lectura, la curva cambia contra una
    % ventana temporal FIJA y se puede comparar contra los puntos. Si tf
    % siguiera a taud, el eje se reescalaria solo y todas las curvas se
    % verian iguales.
    REF = leerOscilograma(D, G);            % la respuesta, calculada una sola vez
    [tt0, ~, ~] = curva(REF, D, [], 800);   % tf lo elige VM.trayA: 4 periodos amortiguados
    TF = tt0(end);                          % tiempo final del grafico [s]

    if strcmp(modo, 'exportar')
        exportar();
        return
    end

    % magnitudes que el panel de comprobacion pide, en orden. SON las
    % respuestas del problema, por eso cada una tiene su "Revelar".
    MAG  = {'k','c','wd'};
    MAGU = {'N/m','N*s/m','rad/s'};
    % Etiquetas en ASCII pelado: uicontrol NO interpreta TeX, asi que un
    % '\omega_d' aca se veria literal como barra-omega. El TeX solo vale en
    % title, xlabel y demas texto de los EJES.
    MAGL = {'k','c','wd'};

    % ---------------------------------------------------------------------
    % FIGURA Y EJES
    % ---------------------------------------------------------------------
    fig = figure('Name','Problema 2 - oscilograma del motor', ...
        'NumberTitle','off', 'Color','w', 'Position',[60 60 1450 840]);
    theme(fig,'light');   % fuerza tema claro: si no, con MATLAB en oscuro
                          % el area de los ejes sale negra (ver VM.graficarA)

    axPrin = axes('Parent',fig, 'Position',[0.055 0.47 0.40 0.47]);
    axZoom = axes('Parent',fig, 'Position',[0.565 0.47 0.40 0.47]);

    % --- panel principal: el dato y la curva -----------------------------
    hold(axPrin,'on'); grid(axPrin,'on');

    % LOS PUNTOS LEIDOS. Marcadores sueltos ('LineStyle','none'): son
    % medidas, no una curva. Se dibujan UNA vez y no se vuelven a tocar,
    % porque los sliders cambian tu LECTURA, no el oscilograma.
    plot(axPrin, TLEIDO, XLEIDO*MM, 'o', 'LineStyle','none', ...
        'MarkerSize',10, 'MarkerFaceColor',[0.90 0.75 0.10], ...
        'MarkerEdgeColor','k', 'LineWidth',1.2, ...
        'DisplayName','picos leidos (el dato)');

    hEnvS = plot(axPrin,nan,nan,'r--','LineWidth',1,'DisplayName','envolvente');
    hEnvI = plot(axPrin,nan,nan,'r--','LineWidth',1,'HandleVisibility','off');
    hCurv = plot(axPrin,nan,nan,'-','Color',[0 0.30 0.65],'LineWidth',1.8, ...
        'DisplayName','x(t) con la lectura viva');
    hZeta = plot(axPrin,nan,nan,'-','Color',[0.10 0.55 0.25], ...
        'LineWidth',1.4,'DisplayName','x(t) con tu zeta');
    hMia  = plot(axPrin,nan,nan,'--','Color',[0.85 0.33 0.10], ...
        'LineWidth',1.8,'DisplayName','tu solucion','Visible','off');
    xlabel(axPrin,'t [s]'); ylabel(axPrin,'x(t) [mm]');
    title(axPrin,'Oscilograma del motor: dato contra modelo','Color','k');
    legend(axPrin,'show','Location','northeast');
    set(axPrin,'XLim',[0 TF],'Color','w','XColor','k','YColor','k', ...
        'GridColor',[0.5 0.5 0.5],'GridAlpha',1);

    % --- vista ampliada: de aca sale el decremento -----------------------
    hold(axZoom,'on'); grid(axZoom,'on');
    hZeS = plot(axZoom,nan,nan,'r--','LineWidth',1.2,'DisplayName','envolvente');
    hZeI = plot(axZoom,nan,nan,'r--','LineWidth',1.2,'HandleVisibility','off');
    hZc  = plot(axZoom,nan,nan,'-','Color',[0 0.30 0.65],'LineWidth',1.8, ...
        'DisplayName','x(t)');
    hZpt = plot(axZoom, TLEIDO, XLEIDO*MM, 'o','LineStyle','none', ...
        'MarkerSize',9,'MarkerFaceColor',[0.90 0.75 0.10], ...
        'MarkerEdgeColor','k','DisplayName','picos leidos');
    % Las dos amplitudes que entran al decremento, dibujadas como palitos
    % verticales desde el eje: x1 en t = 0 y x2 despues de n ciclos.
    hV1 = plot(axZoom,[nan nan],[nan nan],'-','Color',[0.35 0.35 0.35], ...
        'LineWidth',1.6,'HandleVisibility','off');
    hV2 = plot(axZoom,[nan nan],[nan nan],'-','Color',[0.35 0.35 0.35], ...
        'LineWidth',1.6,'HandleVisibility','off');
    hP12 = plot(axZoom,nan,nan,'s','LineStyle','none','MarkerSize',11, ...
        'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k', ...
        'DisplayName','x_1 y x_2 elegidos');
    xlabel(axZoom,'t [s]'); ylabel(axZoom,'x(t) [mm]');
    title(axZoom,'Vista ampliada: los dos picos del decremento','Color','k');
    legend(axZoom,'show','Location','northeast');
    set(axZoom,'Color','w','XColor','k','YColor','k', ...
        'GridColor',[0.5 0.5 0.5],'GridAlpha',1);

    % ---------------------------------------------------------------------
    % PANEL DE EXPLORACION
    % ---------------------------------------------------------------------
    panE = uipanel('Parent',fig,'Title','Exploracion - lectura del oscilograma', ...
        'FontWeight','bold','BackgroundColor','w', ...
        'Position',[0.04 0.03 0.44 0.40]);

    verRegimen = false;   % la etiqueta de regimen arranca OCULTA: el tipo de
                          % amortiguamiento es una de las respuestas pedidas

    hRegim = uicontrol('Parent',panE,'Style','text','String','', ...
        'Units','normalized','Position',[0.02 0.875 0.62 0.095], ...
        'HorizontalAlignment','left','FontSize',11,'FontWeight','bold', ...
        'BackgroundColor','w');
    uicontrol('Parent',panE,'Style','pushbutton','String','Revelar regimen', ...
        'Units','normalized','Position',[0.66 0.875 0.32 0.10], ...
        'FontSize',9,'Callback',@(~,~) revelarRegimen());

    hSli = gobjects(1,numel(NOM));   % handles de los sliders
    hLab = gobjects(1,numel(NOM));   % handles de las etiquetas
    for i = 1:numel(NOM)
        y = 0.745 - (i-1)*0.113;
        hLab(i) = uicontrol('Parent',panE,'Style','text', ...
            'Units','normalized','Position',[0.02 y 0.40 0.078], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',10);
        % Callback: la funcion recibe el handle del slider que la disparo;
        % el 'i' capturado dice CUAL parametro es.
        hSli(i) = uicontrol('Parent',panE,'Style','slider', ...
            'Units','normalized','Position',[0.44 y+0.008 0.54 0.068], ...
            'Min',R.(NOM{i})(1),'Max',R.(NOM{i})(2),'Value',D.(NOM{i}), ...
            'Callback',@(s,~) moverSlider(i,get(s,'Value')));
    end

    % n son CICLOS: solo tiene sentido en enteros. SliderStep va en
    % fracciones del rango, asi que 1/(max-min) hace que la flecha avance
    % exactamente un ciclo. El redondeo lo hace moverSlider.
    jn = strcmp(NOM,'n');
    set(hSli(jn),'SliderStep',[1 1]/(R.n(2)-R.n(1)));

    % Aviso del caso patologico: lectura que no describe una oscilacion
    % que decae. Arranca vacio.
    hAviso = uicontrol('Parent',panE,'Style','text','String','', ...
        'Units','normalized','Position',[0.02 0.085 0.96 0.075], ...
        'HorizontalAlignment','left','BackgroundColor','w', ...
        'ForegroundColor',[0.75 0.10 0.10],'FontSize',9.5,'FontWeight','bold');

    uicontrol('Parent',panE,'Style','pushbutton','String','Restaurar', ...
        'Units','normalized','Position',[0.02 0.008 0.24 0.070], ...
        'FontWeight','bold','Callback',@(~,~) restaurar());
    uicontrol('Parent',panE,'Style','text', ...
        'String',['El peso NO cambia la curva: z, wn y wd salen solo de ' ...
                  'los picos y de taud. El peso escala k y c.'], ...
        'Units','normalized','Position',[0.28 0.005 0.70 0.072], ...
        'HorizontalAlignment','left','BackgroundColor','w','FontSize',8.5);

    % ---------------------------------------------------------------------
    % PANEL DE COMPROBACION
    % ---------------------------------------------------------------------
    panC = uipanel('Parent',fig,'Title','Comprobar mi solucion', ...
        'FontWeight','bold','BackgroundColor','w', ...
        'Position',[0.52 0.03 0.44 0.40]);

    hEd  = gobjects(1,numel(MAG));   % campos donde escribis TUS valores
    hRev = gobjects(1,numel(MAG));   % un boton "Revelar" por magnitud
    for i = 1:numel(MAG)
        y = 0.78 - (i-1)*0.155;
        uicontrol('Parent',panC,'Style','text', ...
            'String',sprintf('%s [%s]',MAGL{i},MAGU{i}), ...
            'Units','normalized','Position',[0.02 y 0.20 0.10], ...
            'HorizontalAlignment','left','BackgroundColor','w','FontSize',10);
        hEd(i) = uicontrol('Parent',panC,'Style','edit','String','', ...
            'Units','normalized','Position',[0.23 y 0.24 0.115], ...
            'BackgroundColor','w','FontSize',10);
        hRev(i) = uicontrol('Parent',panC,'Style','pushbutton', ...
            'String','Revelar','Units','normalized', ...
            'Position',[0.49 y 0.17 0.115],'FontSize',9, ...
            'Callback',@(~,~) revelar(i));
    end

    hFeed = uicontrol('Parent',panC,'Style','text','String','', ...
        'Units','normalized','Position',[0.68 0.14 0.30 0.78], ...
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
    RV  = REF;    % lectura viva despejada: la que corresponde a P
    OKV = true;   % la lectura viva describe una oscilacion que decae?
    refrescar();

    % =====================================================================
    % FUNCIONES ANIDADAS. Ven P, D, REF, RV y los handles sin pasarlos.
    % =====================================================================

    function moverSlider(i, val)
        % i: indice del parametro en NOM. val: valor nuevo del slider.
        if strcmp(NOM{i},'n')
            val = round(val);              % n son ciclos enteros
            set(hSli(i),'Value',val);      % el pulgar se acomoda al entero
        end
        P.(NOM{i}) = val;

        % z no es una lectura: no cambia el despeje del decremento, solo la
        % curva verde de tanteo. Ahorrarse el subA simbolico (~80 ms) hace
        % que ese slider se sienta instantaneo.
        if strcmp(NOM{i},'z')
            dibujarZeta();
            etiquetas();
        else
            refrescar();
        end
    end

    function restaurar()
        % Vuelve a los valores LEIDOS del oscilograma. D nunca se toco, asi
        % que siempre esta ahi para volver. Tambien vuelve a ocultar el
        % regimen: "restaurar" es volver al estado de arranque completo,
        % respuestas tapadas incluidas.
        P = D;
        for j = 1:numel(NOM)
            set(hSli(j),'Value',D.(NOM{j}));
        end
        verRegimen = false;
        set(hMia,'Visible','off');
        set(hFeed,'String','');
        refrescar();
    end

    function refrescar()
        % Despeja con VM y ACTUALIZA los handles que ya existen. No se
        % vuelve a graficar desde cero ni se abre figura nueva: solo set().
        [RV, OKV, aviso] = leerOscilograma(P, G);
        set(hAviso,'String',aviso);

        if ~OKV
            % Lectura invalida: no hay k ni c, asi que no hay curva. Los
            % puntos leidos SIGUEN ahi, porque son el dato y no dependen de
            % como los leas.
            set([hCurv hEnvS hEnvI hZeta hZc hZeS hZeI hP12], ...
                'XData',nan,'YData',nan);
            set([hV1 hV2],'XData',[nan nan],'YData',[nan nan]);
            set(hRegim,'String','regimen: no aplica','ForegroundColor',[0.75 0.10 0.10]);
            etiquetas();
            return
        end

        % --- curva principal, sobre la ventana temporal FIJA -------------
        [t, x, num] = curva(RV, P, TF, 800);
        set(hCurv,'XData',t,'YData',x*MM);
        set(hEnvS,'XData',t,'YData', num.env*MM);
        set(hEnvI,'XData',t,'YData',-num.env*MM);

        % limites verticales: el maximo entre la curva y los puntos leidos,
        % con 15% de aire. Asi el dato nunca se sale del cuadro.
        a = max([abs(x)*MM, XLEIDO*MM]);
        set(axPrin,'YLim',[-1.15 1.15]*a);

        dibujarZeta();
        dibujarZoom();
        pintarRegimen(num.regimen);
        etiquetas();
    end

    function dibujarZeta()
        % Curva de tanteo: MISMO m y MISMO k que salieron de la lectura,
        % pero con TU zeta. VM.trayA acepta z directo y resuelve los tres
        % regimenes por el mismo camino, asi que el slider cruza z = 1 sin
        % que aca haya que elegir formula.
        if ~OKV, return, end
        [t2, x2] = VM.trayA('m',RV.m, 'k',RV.k, 'z',P.z, ...
            'x0',P.x1, 'v0',0, 'tf',TF, 'npts',800);
        set(hZeta,'XData',t2,'YData',x2*MM);
    end

    function dibujarZoom()
        % Vista ampliada de los DOS PICOS que entran al decremento: el de
        % t = 0 y el que esta n ciclos despues. La ventana sigue a n y a
        % taud para que los dos queden siempre adentro; es tamano de
        % cuadro, no fisica.
        tfz = (P.n + 0.4)*P.taud;                    % ancho de la ventana [s]
        [t, x, num] = curva(RV, P, tfz, 600);

        set(hZc, 'XData',t,'YData',x*MM);
        set(hZeS,'XData',t,'YData', num.env*MM);
        set(hZeI,'XData',t,'YData',-num.env*MM);

        % los dos picos elegidos y sus palitos hasta el eje
        t2 = P.n*P.taud;                             % instante del segundo pico [s]
        set(hP12,'XData',[0 t2],'YData',[P.x1 P.x2]*MM);
        set(hV1,'XData',[0 0],  'YData',[0 P.x1]*MM);
        set(hV2,'XData',[t2 t2],'YData',[0 P.x2]*MM);

        b = max([abs(x)*MM, P.x1*MM, XLEIDO*MM]);
        set(axZoom,'XLim',[0 tfz],'YLim',[-1.15 1.15]*b);

        % los puntos leidos que caen dentro de la ventana
        dentro = TLEIDO <= tfz;
        set(hZpt,'XData',TLEIDO(dentro),'YData',XLEIDO(dentro)*MM);
    end

    function pintarRegimen(reg)
        % El tipo de amortiguamiento ES una de las respuestas: hasta que no
        % apretes "Revelar regimen", aca no dice nada util.
        if ~verRegimen
            set(hRegim,'String','regimen: oculto (es una de las respuestas)', ...
                'ForegroundColor',[0.45 0.45 0.45]);
            return
        end
        switch reg
            case 'sub',     col = [0.00 0.30 0.65]; txt = 'SUB-amortiguado';
            case 'critico', col = [0.85 0.33 0.10]; txt = 'CRITICO';
            case 'sobre',   col = [0.10 0.50 0.20]; txt = 'SOBRE-amortiguado';
            otherwise,      col = [0.45 0.45 0.45]; txt = reg;
        end
        set(hRegim,'String',sprintf('regimen: %s',txt),'ForegroundColor',col);
    end

    function revelarRegimen()
        verRegimen = true;
        if OKV
            % El regimen sale de VM.clasifA a traves de VM.trayA; aca no se
            % vuelve a decidir nada.
            [~,~,num] = curva(RV, P, TF, 200);
            pintarRegimen(num.regimen);
        else
            pintarRegimen('');
        end
    end

    function etiquetas()
        % Valor actual de cada slider y, entre parentesis, el LEIDO del
        % oscilograma. ESC pasa a mm solo para mostrar.
        for j = 1:numel(NOM)
            set(hLab(j),'String', sprintf('%s = %.4g %s   (%.4g)', ...
                NOM{j}, P.(NOM{j})*ESC(j), UNI{j}, D.(NOM{j})*ESC(j)));
        end
    end

    function comprobar()
        % Lee TUS valores, superpone TU curva y da la pista de primer
        % nivel. NO dice el valor correcto: solo que magnitud discrepa y
        % hacia donde. El valor sale por el boton "Revelar", nunca solo.
        v = nan(1,numel(MAG));
        for j = 1:numel(MAG)
            s = str2double(get(hEd(j),'String'));
            if ~isnan(s), v(j) = s; end
        end

        msg = {};

        % --- tu curva, si diste k y c ---------------------------------
        ik = strcmp(MAG,'k');  ic = strcmp(MAG,'c');
        if ~isnan(v(ik)) && ~isnan(v(ic))
            try
                % La masa es la de TU lectura del peso; k y c son TUYOS.
                [t2, x2] = VM.trayA('m',P.W/G, 'k',v(ik), 'c',v(ic), ...
                    'x0',P.x1, 'v0',0, 'tf',TF, 'npts',600);
                set(hMia,'XData',t2,'YData',x2*MM,'Visible','on');
                msg{end+1} = 'Tu curva esta superpuesta en naranja.';
                msg{end+1} = 'Mirala contra los puntos amarillos.';
            catch
                msg{end+1} = 'Con esos k y c no se puede armar la curva.';
            end
        else
            msg{end+1} = 'Escribi k y c para superponer tu curva.';
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
                case 'k'
                    if alto, s = 'tu soporte es mas rigido';
                    else,    s = 'tu soporte es mas blando'; end
                case 'c'
                    if alto, s = 'tu amortiguador frena mas';
                    else,    s = 'tu amortiguador frena menos'; end
                case 'wd'
                    if alto, s = 'tu periodo amortiguado es menor';
                    else,    s = 'tu periodo amortiguado es mayor'; end
            end
            msg{end+1} = sprintf('%s: %s.', MAGL{j}, s); %#ok<AGROW>
        end

        set(hFeed,'String',msg);
    end

    function revelar(j)
        % Muestra UNA respuesta, y solo cuando la pediste. REF salio de la
        % lectura del ENUNCIADO (D), no de donde tengas los sliders.
        set(hFeed,'String', sprintf('%s = %.6g %s   (con la lectura del enunciado)', ...
            MAGL{j}, REF.(MAG{j}), MAGU{j}));
    end

    % =====================================================================
    % MODO EXPORTAR
    % =====================================================================
    function exportar()
        % Render fijo con los valores LEIDOS del oscilograma, sin sliders.
        % Dos paneles: el oscilograma completo y la vista ampliada de los
        % dos picos del decremento.
        if ~exist('figs','dir'), mkdir('figs'); end

        [t, x, num] = curva(REF, D, TF, 800);
        tfz = (D.n + 0.4)*D.taud;                  % ventana de la vista ampliada [s]
        [tz, xz, nz] = curva(REF, D, tfz, 600);

        f = figure('Color','w','Position',[100 100 1200 460],'Visible','off');
        theme(f,'light');
        tl = tiledlayout(f,1,2,'Padding','compact','TileSpacing','compact');

        % --- panel izquierdo: dato contra modelo ------------------------
        a1 = nexttile(tl); hold(a1,'on'); grid(a1,'on');
        plot(a1,t, num.env*MM,'r--','LineWidth',1,'DisplayName','envolvente');
        plot(a1,t,-num.env*MM,'r--','LineWidth',1,'HandleVisibility','off');
        plot(a1,t,x*MM,'-','Color',[0 0.30 0.65],'LineWidth',1.8, ...
            'DisplayName','x(t) del decremento');
        plot(a1,TLEIDO,XLEIDO*MM,'o','LineStyle','none','MarkerSize',10, ...
            'MarkerFaceColor',[0.90 0.75 0.10],'MarkerEdgeColor','k', ...
            'LineWidth',1.2,'DisplayName','picos leidos (el dato)');
        % Marcador del GIF. Arranca invisible para que no tape el primer
        % punto leido en el PNG, que es una imagen fija: se enciende recien
        % cuando empieza el barrido de cuadros.
        hm = plot(a1,t(1),x(1)*MM,'o','MarkerSize',9, ...
            'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k', ...
            'HandleVisibility','off','Visible','off');
        xlabel(a1,'t [s]'); ylabel(a1,'x(t) [mm]');
        title(a1,'Oscilograma del motor: dato contra modelo','Color','k');
        legend(a1,'show','Location','northeast');
        set(a1,'Color','w','XColor','k','YColor','k','XLim',[0 TF], ...
            'GridColor',[0.5 0.5 0.5],'GridAlpha',1, ...
            'YLim',[-1.15 1.15]*max([abs(x)*MM, XLEIDO*MM]));

        % --- panel derecho: de donde sale el decremento -----------------
        a2 = nexttile(tl); hold(a2,'on'); grid(a2,'on');
        plot(a2,tz, nz.env*MM,'r--','LineWidth',1.2,'DisplayName','envolvente');
        plot(a2,tz,-nz.env*MM,'r--','LineWidth',1.2,'HandleVisibility','off');
        plot(a2,tz,xz*MM,'-','Color',[0 0.30 0.65],'LineWidth',1.8, ...
            'DisplayName','x(t)');
        t2 = D.n*D.taud;                            % instante del segundo pico [s]
        plot(a2,[0 0],  [0 D.x1]*MM,'-','Color',[0.35 0.35 0.35], ...
            'LineWidth',1.6,'HandleVisibility','off');
        plot(a2,[t2 t2],[0 D.x2]*MM,'-','Color',[0.35 0.35 0.35], ...
            'LineWidth',1.6,'HandleVisibility','off');
        plot(a2,[0 t2],[D.x1 D.x2]*MM,'s','LineStyle','none','MarkerSize',11, ...
            'MarkerFaceColor',[0.85 0.33 0.10],'MarkerEdgeColor','k', ...
            'DisplayName','x_1 y x_2 elegidos');
        xlabel(a2,'t [s]'); ylabel(a2,'x(t) [mm]');
        title(a2,'Vista ampliada: los dos picos del decremento','Color','k');
        legend(a2,'show','Location','northeast');
        set(a2,'Color','w','XColor','k','YColor','k','XLim',[0 tfz], ...
            'GridColor',[0.5 0.5 0.5],'GridAlpha',1, ...
            'YLim',[-1.15 1.15]*max([abs(xz)*MM, D.x1*MM]));

        png = fullfile('figs','sim2.png');
        exportgraphics(f, png, 'Resolution',150);

        % GIF corto: un marcador recorriendo la curva del panel izquierdo.
        % Aca no hay bloque que animar, asi que el GIF solo sirve para
        % seguir el decaimiento pico a pico.
        gif = fullfile('figs','sim2.gif');
        if exist(gif,'file'), delete(gif); end
        % exportgraphics con 'Append' arma el GIF animado cuadro a cuadro.
        % El contador se llama kf y no i porque exportar() es una funcion
        % ANIDADA: comparte el workspace de la principal, y ahi i ya es el
        % indice de los bucles que arman los sliders.
        set(hm,'Visible','on');
        for kf = 1:25:numel(t)
            set(hm,'XData',t(kf),'YData',x(kf)*MM);
            exportgraphics(a1, gif, 'Append', kf > 1);
        end
        close(f);
        fprintf('Escrito: %s\n', png);
        fprintf('Escrito: %s\n', gif);
    end
end

% =========================================================================
% FUNCIONES LOCALES (no anidadas: no ven las variables de arriba)
% =========================================================================

function [r, ok, aviso] = leerOscilograma(p, g)
    % DESPEJE HACIA ATRAS desde los picos del oscilograma. Toda la fisica
    % la hace VM.subA; aca solo se arma la llamada y se revisa el
    % resultado.
    % ENTRADAS:
    %   p : struct de lectura, con x1, x2, n, taud y W
    %   g : aceleracion de la gravedad [m/s^2]
    % SALIDAS:
    %   r     : struct con m, k, c, wn, wd y z. Todo NaN si la lectura no sirve
    %   ok    : true si la lectura describe una oscilacion que decae
    %   aviso : mensaje para el panel; '' cuando la lectura sirve
    %
    % ARGUMENTOS QUE RECIBE VM.subA:
    %   'x1'   primer pico leido                        [m]
    %   'x2'   segundo pico elegido                     [m]
    %   'n'    CICLOS entre x1 y x2 (no picos)          [adim]
    %   'taud' periodo amortiguado leido del eje t      [s]
    %   'm'    masa del motor                           [kg]
    % Con eso VM.subA sale hacia atras: delta desde los dos picos, z desde
    % delta, wd desde taud, wn desde z y wd, k desde wn y m, y c desde z.

    r = struct('m',NaN,'k',NaN,'c',NaN,'wn',NaN,'wd',NaN,'z',NaN);
    ok = false;
    aviso = '';

    % LA UNICA CUENTA QUE NO ES DE VM. Peso -> masa es estatica (segunda
    % ley), no vibraciones: la division por g es legitima aca.
    r.m = p.W/g;   % masa del motor [kg]

    % VM.despejar avisa con VM:variasSoluciones cuando un radical le da dos
    % raices. En un slider eso llenaria la consola de warnings identicos,
    % asi que se apaga solo durante la llamada. onCleanup lo devuelve como
    % estaba aunque subA aborte.
    ws = warning('off','VM:variasSoluciones');
    limpieza = onCleanup(@() warning(ws));

    try
        s = VM.subA('x1',p.x1, 'x2',p.x2, 'n',p.n, 'taud',p.taud, 'm',r.m);
    catch
        aviso = ['Con esa lectura el sistema no oscila y el decremento ' ...
                 'no aplica.'];
        return
    end

    if ~all(isfield(s, {'k','c','wn','wd','z'}))
        aviso = ['Con esa lectura el sistema no oscila y el decremento ' ...
                 'no aplica.'];
        return
    end

    r.k  = double(s.k);    % rigidez del soporte            [N/m]
    r.c  = double(s.c);    % coeficiente de amortiguamiento [N*s/m]
    r.wn = double(s.wn);   % frecuencia natural             [rad/s]
    r.wd = double(s.wd);   % frecuencia amortiguada         [rad/s]
    r.z  = double(s.z);    % relacion de amortiguamiento    [adim]

    % EL CONTROL. El decremento logaritmico SUPONE que hay oscilacion que
    % decae: los picos tienen que ir bajando (x2 < x1) y z tiene que caer
    % entre 0 y 1. Si pones x2 >= x1, lo que sale es z <= 0 y c <= 0, o sea
    % un amortiguador que en vez de frenar empuja: numeros sin sentido
    % fisico que igual se calculan sin dar error. Por eso el filtro va aca
    % y no se confia en el try/catch.
    if ~isfinite(r.z) || ~isfinite(r.k) || ~isfinite(r.c) || ...
            r.z <= 0 || r.z >= 1 || r.k <= 0 || r.c <= 0
        aviso = ['Con esa lectura el sistema no oscila y el decremento ' ...
                 'no aplica: los picos tienen que decaer (x2 < x1).'];
        return
    end

    ok = true;
end

function [t, x, num] = curva(r, p, tf, npts)
    % x(t) del sistema que salio de la lectura. La fisica es VM.trayA.
    % ENTRADAS:
    %   r    : struct de leerOscilograma, con m, k y c
    %   p    : struct de lectura; de aca sale la condicion inicial
    %   tf   : tiempo final [s]. [] deja que VM.trayA lo elija
    %   npts : cantidad de puntos de la curva [adim]
    %
    % CONDICION INICIAL. El oscilograma arranca JUSTO en un pico, asi que
    %   x0 = x1  (el primer pico leido, en t = 0)
    %   v0 = 0   (en un pico la velocidad es cero: es un maximo de x(t))
    % Por eso los picos siguientes caen exactamente en taud, 2*taud, ... y
    % la curva pasa por los puntos del oscilograma cuando la lectura es
    % correcta.
    %
    % ARGUMENTOS DE VM.trayA:
    %   'm','k','c' : masa [kg], rigidez [N/m] y amortiguamiento [N*s/m]
    %   'x0','v0'   : condiciones iniciales [m] y [m/s]
    %   'tf','npts' : ventana y resolucion del muestreo, no del modelo
    % Devuelve tambien num, con el regimen y la envolvente evaluada en t.
    if isempty(tf)
        [t, x, ~, num] = VM.trayA('m',r.m, 'k',r.k, 'c',r.c, ...
            'x0',p.x1, 'v0',0, 'npts',npts);
    else
        [t, x, ~, num] = VM.trayA('m',r.m, 'k',r.k, 'c',r.c, ...
            'x0',p.x1, 'v0',0, 'tf',tf, 'npts',npts);
    end
end
