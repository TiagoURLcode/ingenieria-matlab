function sim1_saltoOrbital(modo)
% SIM1_SALTOORBITAL - simulador del salto entre orbitas de Bohr.
%
% Tres paneles sobre el mismo atomo:
%   izquierda  el atomo dibujado, con el electron saltando y el foton que sale
%   derecha    los niveles de energia En, con la flecha del salto activo
%   abajo      todos los saltos posibles desde la orbita elegida, cada
%              barra apilada por los tramos de un nivel que la componen
%
% USO:
%   sim1_saltoOrbital             % modo interactivo
%   sim1_saltoOrbital('exportar') % render fijo en ./figs/, sin abrir ventana
%
% DE DONDE SALEN LOS NUMEROS. Toda la fisica es de FV.m:
%   FV.bohr    radio, velocidad y energias de cada nivel n
%   FV.bohrT   el salto entre dos niveles: deltaE y la lambda del foton
%   FV.J2eV    joules a electronvolts, solo para MOSTRAR
% Aca no se escribe ni una formula del modelo de Bohr. La unica aritmetica
% de este archivo es de dibujo: radios en pantalla, angulos, posiciones.
%
% VALIDEZ. El modelo de Bohr vale para atomos de UN SOLO electron. El slider
% de N dibuja mas electrones porque ayuda a ver el llenado por capas, pero
% las energias siguen siendo las de un electron: con N > 1 el panel avisa en
% rojo. No es un detalle menor, es la diferencia entre un numero y un numero
% equivocado.

    if nargin < 1, modo = ''; end

    % ---------------------------------------------------------------------
    % DEFAULTS. Esta struct NO se sobrescribe nunca: es a donde vuelve el
    % boton "Restaurar". Los sliders trabajan sobre P, que es una copia.
    % ---------------------------------------------------------------------
    D = struct( ...
        'Z',  1, ...   % numero atomico del nucleo            [-]
        'N',  1, ...   % electrones dibujados                 [-]
        'ni', 3, ...   % nivel inicial del salto, el de arriba [-]
        'nf', 2);      % nivel final del salto, el de abajo    [-]

    P = D;   % parametros VIVOS, los que mueven los sliders

    % Rangos [minimo maximo] de cada slider. NMAX es el tope de niveles que
    % se calculan y dibujan: mas arriba de 8 las orbitas se amontonan y las
    % energias ya casi no cambian (En va como 1/n^2).
    NMAX = 8;
    R = struct( ...
        'Z',  [1 10], ...
        'N',  [1 20], ...
        'ni', [1 NMAX], ...
        'nf', [1 NMAX]);

    % ---------------------------------------------------------------------
    % CACHE. FV.bohr tarda unos 46 ms por llamada y FV.bohrT unos 55 ms:
    % son despejes simbolicos, no cuentas. Un slider dispara su callback
    % decenas de veces mientras lo arrastras, asi que llamar a FV ahi adentro
    % congela la ventana.
    % Por eso: se calcula UNA vez por cada Z, se guarda como double, y los
    % sliders de N, ni y nf solo leen del cache. Solo mover Z puede disparar
    % un calculo, y solo la primera vez para ese Z.
    % containers.Map con KeyType char: la clave es num2str(Z).
    % ---------------------------------------------------------------------
    cacheNiv = containers.Map('KeyType','char','ValueType','any');
    cacheSal = containers.Map('KeyType','char','ValueType','any');

    if strcmpi(modo, 'exportar'), exportar(); return; end

    % ---------------------------------------------------------------------
    % FIGURA. Etiquetas en ASCII pelado: uicontrol NO interpreta TeX ni
    % acentos, y un texto con tilde sale como basura en pantalla.
    % ---------------------------------------------------------------------
    fig = figure('Name','Salto orbital - modelo de Bohr', ...
        'NumberTitle','off', 'Color','w', ...
        'Position',[80 60 1180 740]);

    % Position = [izquierda abajo ancho alto] en fraccion de la figura.
    axAtomo = axes('Parent',fig, 'Position',[0.04 0.45 0.40 0.50]);
    axNiv   = axes('Parent',fig, 'Position',[0.55 0.45 0.42 0.50]);
    axCasc  = axes('Parent',fig, 'Position',[0.07 0.09 0.60 0.27]);

    % BackgroundColor y ForegroundColor explicitos: con el tema oscuro de
    % MATLAB el panel sale negro con letras negras y no se lee nada. Los
    % uicontrol no heredan el 'Color','w' de la figura.
    panC = uipanel('Parent',fig, 'Title','Controles', ...
        'BackgroundColor','w', 'ForegroundColor','k', ...
        'Units','normalized', 'Position',[0.72 0.04 0.26 0.33]);

    % Un slider por parametro, con su etiqueta arriba mostrando el valor.
    campos = {'Z','N','ni','nf'};
    textos = {'Z  (numero atomico)', 'N  (electrones dibujados)', ...
              'ni (nivel inicial)',  'nf (nivel final)'};
    hLab = gobjects(1,numel(campos));
    hSli = gobjects(1,numel(campos));
    for i = 1:numel(campos)
        y = 0.80 - (i-1)*0.19;
        hLab(i) = uicontrol('Parent',panC, 'Style','text', ...
            'Units','normalized', 'Position',[0.06 y 0.88 0.07], ...
            'HorizontalAlignment','left', ...
            'BackgroundColor','w', 'ForegroundColor','k', ...
            'String',textos{i});
        rg = R.(campos{i});
        % SliderStep en fraccion del recorrido. Con paso = 1/(max-min) cada
        % clic en la flecha avanza exactamente un entero.
        paso = 1/(rg(2)-rg(1));
        hSli(i) = uicontrol('Parent',panC, 'Style','slider', ...
            'Units','normalized', 'Position',[0.06 y-0.07 0.88 0.06], ...
            'Min',rg(1), 'Max',rg(2), 'Value',P.(campos{i}), ...
            'BackgroundColor',[0.94 0.94 0.94], ...
            'SliderStep',[paso paso], ...
            'Callback', @(src,~) moverSlider(i, get(src,'Value')));
    end

    uicontrol('Parent',panC, 'Style','pushbutton', 'String','Restaurar', ...
        'Units','normalized', 'Position',[0.06 0.03 0.42 0.11], ...
        'BackgroundColor','w', 'ForegroundColor','k', ...
        'Callback', @(~,~) restaurar());
    uicontrol('Parent',panC, 'Style','pushbutton', 'String','Reproducir', ...
        'Units','normalized', 'Position',[0.52 0.03 0.42 0.11], ...
        'BackgroundColor','w', 'ForegroundColor','k', ...
        'Callback', @(~,~) animarSalto());

    refrescar();

    % =====================================================================
    %  CALLBACKS
    % =====================================================================

    function moverSlider(i, val)
        % Los sliders de MATLAB devuelven double continuo. Todos estos
        % parametros son enteros, asi que se redondea y se devuelve el
        % slider al valor redondeado para que la perilla no quede a mitad
        % de camino de un valor que no existe.
        c = campos{i};
        P.(c) = round(val);
        set(hSli(i), 'Value', P.(c));

        % LO UNICO QUE SE EXIGE ES QUE SEAN DISTINTOS. Antes se forzaba
        % ni > nf, dando por sentado que el salto siempre emitia. No es
        % cierto: con nf > ni el atomo ABSORBE, y desde n = 1 eso es lo
        % unico que puede hacer. Por eso ni ahora llega hasta 1.
        if P.ni == P.nf
            if strcmp(c,'ni')
                P.nf = P.nf + 1;
                if P.nf > R.nf(2), P.nf = P.ni - 1; end
            else
                P.ni = P.ni + 1;
                if P.ni > R.ni(2), P.ni = P.nf - 1; end
            end
            set(hSli(3), 'Value', P.ni);
            set(hSli(4), 'Value', P.nf);
        end
        refrescar();
    end

    function restaurar()
        P = D;
        for k = 1:numel(campos), set(hSli(k), 'Value', P.(campos{k})); end
        refrescar();
    end

    function refrescar()
        for k = 1:numel(campos)
            set(hLab(k), 'String', sprintf('%s = %d', textos{k}, P.(campos{k})));
        end
        niv = nivelesDe(P.Z);
        dibujarAtomo(niv, []);
        dibujarNiveles(niv);
        dibujarSaltos();
        drawnow;
    end

    % =====================================================================
    %  DATOS: todo lo que sale de FV.m pasa por aca y queda cacheado
    % =====================================================================

    function niv = nivelesDe(Z)
        % Radios, velocidades y energias de los NMAX niveles, para este Z.
        % Devuelve doubles: guardar sym en el cache haria que cada lectura
        % posterior pague otra conversion.
        clave = num2str(Z);
        if isKey(cacheNiv, clave), niv = cacheNiv(clave); return; end

        niv.rn = zeros(1,NMAX);   % radio de cada orbita        [m]
        niv.vn = zeros(1,NMAX);   % velocidad del electron      [m/s]
        niv.En = zeros(1,NMAX);   % energia total del nivel     [J]
        for n = 1:NMAX
            r = FV.bohr('n',n, 'Z',Z);
            niv.rn(n) = double(r.rn);
            niv.vn(n) = double(r.vn);
            niv.En(n) = double(r.En);
        end
        cacheNiv(clave) = niv;
    end

    function s = saltoDe(Z, ni, nf)
        % Un salto ni -> nf: energia del foton [J] y su longitud de onda [m].
        % Sale de FV.bohrT, que es la formula (12) del formulario.
        clave = sprintf('%d_%d_%d', Z, ni, nf);
        if isKey(cacheSal, clave), s = cacheSal(clave); return; end

        t = FV.bohrT('ni',ni, 'nf',nf, 'Z',Z);
        s.E   = double(t.E);      % energia del foton emitido   [J]
        s.lam = double(t.lam);    % longitud de onda            [m]
        cacheSal(clave) = s;
    end

    % =====================================================================
    %  DIBUJO
    % =====================================================================

    function [rd, rnuc] = escalaDibujo(niv)
        % RADIOS A ESCALA REAL. Se dibuja rn/r1 tal cual sale de FV.bohr,
        % asi que la orbita n queda a n^2 veces la primera: 1, 4, 9, 16, 25,
        % 36, 49, 64. Eso es lo que dice el modelo y por eso se ve amontonado
        % adentro y vacio afuera. No es un defecto del dibujo: el atomo ES
        % asi. La orbita 8 encierra 64 veces el radio de la 1.
        rd = niv.rn / niv.rn(1);

        % EL NUCLEO NO ESTA A ESCALA, y no puede estarlo: mide del orden de
        % 1e-15 m contra 5e-11 m de la primera orbita, cinco ordenes menos.
        % A escala seria un punto invisible. Se dibuja como un 2% de la
        % orbita externa, creciendo con Z^(1/3) que es como crece un nucleo
        % real (su volumen va con el numero de nucleones).
        rnuc = rd(NMAX) * 0.02 * (1 + 0.6*(P.Z/R.Z(2))^(1/3));
    end

    function cap = capacidad(n)
        % Capacidad de la capa n segun el llenado 2*n^2: 2, 8, 18, 32...
        cap = 2*n.^2;
    end

    function dibujarAtomo(niv, salto)
        % salto vacio dibuja el atomo quieto. Con salto = [r ang] dibuja el
        % electron que viaja en esa posicion intermedia.
        cla(axAtomo); hold(axAtomo,'on'); axis(axAtomo,'equal','off');
        [rd, rnuc] = escalaDibujo(niv);
        lim = rd(NMAX)*1.12;
        xlim(axAtomo,[-lim lim]); ylim(axAtomo,[-lim lim*1.18]);

        th = linspace(0, 2*pi, 200);   % 200 puntos alcanzan para una curva lisa

        % Orbitas, de afuera hacia adentro para que las etiquetas no tapen
        for n = NMAX:-1:1
            gris = [0.82 0.82 0.82];
            if n == P.ni || n == P.nf, gris = [0.55 0.55 0.55]; end
            plot(axAtomo, rd(n)*cos(th), rd(n)*sin(th), '-', ...
                'Color',gris, 'LineWidth',0.8);
            % La etiqueta va sobre la circunferencia, no en el eje x, para
            % que las de n chico no se pisen ahora que estan a escala.
            text(rd(n)*cos(1.05), rd(n)*sin(1.05), sprintf('%d', n), ...
                'Parent',axAtomo, 'FontSize',8, 'Color',[0.45 0.45 0.45], ...
                'BackgroundColor','w', 'Margin',0.5);
        end

        % Nucleo
        fill(axAtomo, rnuc*cos(th), rnuc*sin(th), [0.85 0.25 0.20], ...
            'EdgeColor','none');
        text(0, -rnuc-lim*0.045, sprintf('Z = %d', P.Z), 'Parent',axAtomo, ...
            'HorizontalAlignment','center', 'FontSize',9, ...
            'Color',[0.15 0.15 0.15]);

        % Electrones repartidos por capas segun 2*n^2, de adentro hacia afuera
        quedan = P.N;
        for n = 1:NMAX
            if quedan <= 0, break; end
            aca = min(quedan, capacidad(n));
            % Angulos parejos sobre la circunferencia. El +0.4*n desfasa cada
            % capa para que los electrones no queden todos alineados.
            ang = linspace(0, 2*pi, aca+1) + 0.4*n;
            ang(end) = [];
            plot(axAtomo, rd(n)*cos(ang), rd(n)*sin(ang), 'o', ...
                'MarkerSize',5, 'MarkerFaceColor',[0.15 0.35 0.75], ...
                'MarkerEdgeColor','none');
            quedan = quedan - aca;
        end

        % El electron que salta, si estamos animando
        if ~isempty(salto)
            plot(axAtomo, salto(1)*cos(salto(2)), salto(1)*sin(salto(2)), 'o', ...
                'MarkerSize',9, 'MarkerFaceColor',[0.95 0.65 0.10], ...
                'MarkerEdgeColor','k', 'LineWidth',0.6);
        end

        titulo = sprintf('Atomo: %d electron(es), salto %d -> %d', ...
            P.N, P.ni, P.nf);
        title(axAtomo, titulo, 'FontWeight','normal');
        set(axAtomo,'Color','w'); axAtomo.Title.Color = [0.15 0.15 0.15];

        % AVISO DE VALIDEZ. Sin esto el panel muestra energias que no
        % corresponden y nada lo dice.
        if P.N > 1
            text(0, lim*1.08, 'N>1: las energias valen solo para 1 electron', ...
                'Parent',axAtomo, 'HorizontalAlignment','center', ...
                'Color',[0.80 0.10 0.10], 'FontWeight','bold', 'FontSize',9);
        end
    end

    function dibujarFoton(niv, ang)
        % El foton emitido: una onda corta que sale del atomo hacia afuera,
        % en la direccion en que quedo el electron. El largo de onda del
        % DIBUJO no es la lambda real (que es 1e-7 m contra 1e-10 m de la
        % orbita): es decorativo y esta a proposito.
        % Los desplazamientos van en FRACCION del radio externo, no en
        % unidades fijas: con las orbitas a escala rd llega a 64, y un
        % offset de 0.18 quedaria invisible.
        [rd, ~] = escalaDibujo(niv);
        esc = rd(NMAX);
        r0 = rd(P.nf) + esc*0.04;
        r1 = esc*1.05;
        t  = linspace(0, 1, 120);
        rr = r0 + (r1-r0)*t;
        oo = esc*0.025*sin(2*pi*6*t);     % 6 ciclos a lo largo del rayo
        xx = rr*cos(ang) - oo*sin(ang);   % desplazamiento perpendicular
        yy = rr*sin(ang) + oo*cos(ang);
        plot(axAtomo, xx, yy, '-', 'Color',[0.95 0.65 0.10], 'LineWidth',1.4);
    end

    function animarSalto()
        % El electron cae de la orbita ni a la nf y despues sale el foton.
        niv = nivelesDe(P.Z);
        [rd, ~] = escalaDibujo(niv);
        ang0 = 0.6;                       % angulo donde arranca el salto [rad]
        pasos = 26;
        % SI ABSORBE, EL FOTON LLEGA ANTES. El orden importa para leer la
        % animacion: el foton entra y recien entonces el electron sube.
        % Emitiendo es al reves, primero cae y despues sale el foton.
        sube = P.nf > P.ni;
        if sube
            dibujarAtomo(niv, [rd(P.ni) ang0]);
            dibujarFoton(niv, ang0+1.5);
            drawnow; pause(0.35);
        end

        for k = 0:pasos
            f = k/pasos;
            r = rd(P.ni) + (rd(P.nf)-rd(P.ni))*f;   % radio interpolado
            a = ang0 + 1.5*f;                        % y va girando mientras salta
            dibujarAtomo(niv, [r a]);
            dibujarNiveles(niv);
            % drawnow limitrate descarta cuadros si no llega: la animacion
            % no se atrasa aunque la maquina este ocupada.
            drawnow limitrate;
        end
        dibujarAtomo(niv, [rd(P.nf) ang0+1.5]);
        if ~sube, dibujarFoton(niv, ang0+1.5); end
        drawnow;
    end

    function estiloEje(ax)
        % MATLAB puede arrancar con tema OSCURO, y entonces los ejes salen
        % con fondo negro aunque la figura sea blanca. Se fuerza el claro a
        % mano en vez de confiar en el tema: asi el PNG exportado se ve igual
        % en cualquier maquina.
        set(ax, 'Color','w', ...
            'XColor',[0.15 0.15 0.15], 'YColor',[0.15 0.15 0.15], ...
            'GridColor',[0.70 0.70 0.70], 'GridAlpha',0.7);
        ax.Title.Color = [0.15 0.15 0.15];
    end

    function dibujarNiveles(niv)
        cla(axNiv); hold(axNiv,'on'); grid(axNiv,'on');
        EeV = FV.J2eV(niv.En);            % a eV solo para mostrar
        rango = abs(min(EeV));

        % LOS NIVELES ALTOS CONVERGEN, y eso es fisica real: En va como
        % 1/n^2, asi que de n=5 para arriba quedan a decimas de eV entre si.
        % En un eje lineal de energia sus rotulos se pisan si o si. En vez de
        % deformar el eje, se rotula inline solo lo que entra, y los que
        % quedan apretados van juntos en un bloque aparte. La linea de cada
        % nivel SIEMPRE se dibuja: lo que se agrupa es el texto, no el dato.
        apretados = {};
        yUlt = -Inf;
        for n = 1:NMAX
            grueso = 1.0; col = [0.55 0.55 0.55];
            if n == P.ni || n == P.nf, grueso = 2.0; col = [0.10 0.10 0.10]; end
            plot(axNiv, [0.05 0.40], [EeV(n) EeV(n)], '-', ...
                'Color',col, 'LineWidth',grueso);
            rot = sprintf('n=%d  %.3f eV', n, EeV(n));
            if EeV(n) - yUlt >= 0.045*rango
                text(0.43, EeV(n), rot, 'Parent',axNiv, 'FontSize',8, ...
                    'VerticalAlignment','middle', 'Color',[0.15 0.15 0.15]);
                yUlt = EeV(n);
            else
                apretados{end+1} = rot;                          %#ok<AGROW>
            end
        end
        if ~isempty(apretados)
            text(0.80, -0.06*rango, strjoin(apretados, newline), ...
                'Parent',axNiv, 'FontSize',8, 'VerticalAlignment','top', ...
                'Color',[0.35 0.35 0.35]);
        end

        % Cero de energia: el electron libre y quieto, infinitamente lejos.
        % Todo lo ligado esta por debajo, y por eso En es negativa.
        plot(axNiv, [0.02 0.98], [0 0], ':', 'Color',[0.3 0.3 0.3]);
        text(0.08, 0, 'E = 0  (electron libre)', 'Parent',axNiv, ...
            'FontSize',8, 'VerticalAlignment','bottom', 'Color',[0.3 0.3 0.3]);

        % Flecha del salto, de ni a nf. La punta va abajo si el electron
        % cae y arriba si sube. Se dibuja con plot y un marcador triangular
        % en vez de annotation, que trabaja en coordenadas de figura y no
        % de ejes.
        x = 0.225;
        if P.nf < P.ni
            punta = 'v'; tipo = 'emite'; col = [0.70 0.20 0.10];
        else
            punta = '^'; tipo = 'absorbe'; col = [0.10 0.35 0.65];
        end
        plot(axNiv, [x x], [EeV(P.ni) EeV(P.nf)], '-', ...
            'Color',col, 'LineWidth',1.8);
        plot(axNiv, x, EeV(P.nf), punta, 'MarkerSize',8, ...
            'MarkerFaceColor',col, 'MarkerEdgeColor','none');

        % FV.bohrT devuelve energia NEGATIVA cuando nf esta arriba de ni:
        % es la senal de que el salto absorbe en vez de emitir. Para
        % mostrar se toma el modulo y la palabra lo aclara.
        s = saltoDe(P.Z, P.ni, P.nf);
        text(x+0.02, (EeV(P.ni)+EeV(P.nf))/2, ...
            sprintf('%s\n%.3f eV\n%.1f nm', tipo, ...
                abs(FV.J2eV(s.E)), abs(s.lam)*1e9), ...
            'Parent',axNiv, 'FontSize',8, 'Color',col);

        xlim(axNiv,[0 1.42]); set(axNiv,'XTick',[]);
        ylim(axNiv,[min(EeV)*1.08, abs(min(EeV))*0.10]);
        ylabel(axNiv,'energia del nivel [eV]');
        title(axNiv, sprintf('Niveles de energia, Z = %d', P.Z), ...
            'FontWeight','normal');
        estiloEje(axNiv);
    end

    function dibujarSaltos()
        % TODOS los saltos posibles desde la orbita elegida ni. Una barra
        % por destino, y cada barra APILADA por los tramos de un nivel que
        % hay que recorrer para llegar. La altura total es la energia del
        % salto directo, y los segmentos muestran de que se compone.
        % Todo en eV, positivo: es el modulo de la energia en juego.
        cla(axCasc); hold(axCasc,'on'); grid(axCasc,'on');

        destinos = setdiff(1:NMAX, P.ni);

        % ENERGIA DE CADA TRAMO DE UN NIVEL. tramo(k) es lo que separa el
        % nivel k del k+1: lo que se libera bajando, o lo que hay que darle
        % para subir. Son NMAX-1 llamadas a FV por cada Z, y de ahi sale
        % cualquier salto por suma. Pedirle a FV cada salto por separado
        % serian 56 llamadas en vez de 7.
        tramo = zeros(1, NMAX-1);
        for k = 1:NMAX-1
            st = saltoDe(P.Z, k+1, k);
            tramo(k) = FV.J2eV(st.E);          % positivo: bajar libera
        end

        % M(k,j) = j-esimo tramo del camino hacia destinos(k). Filas = una
        % barra por destino, columnas = los tramos que se apilan. Las filas
        % cortas quedan en cero, que en un bar apilado no dibuja nada.
        M = zeros(numel(destinos), NMAX-1);
        for k = 1:numel(destinos)
            n = destinos(k);
            if n < P.ni
                idx = (P.ni-1):-1:n;           % emision: va bajando
            else
                idx = P.ni:(n-1);              % absorcion: va subiendo
            end
            M(k, 1:numel(idx)) = tramo(idx);
        end
        total = sum(M, 2)';                    % altura de cada barra [eV]

        hb = bar(axCasc, 1:numel(destinos), M, 0.62, 'stacked', ...
            'EdgeColor',[1 1 1], 'LineWidth',0.6);
        % Degrade de claro a oscuro por tramo: el de abajo es el primer
        % paso desde ni, y cada uno mas oscuro es un nivel mas lejos.
        for j = 1:numel(hb)
            f = (j-1)/max(1, numel(hb)-1);
            set(hb(j), 'FaceColor', [0.72 0.82 0.93]*(1-f) + [0.13 0.32 0.60]*f);
        end

        % CONTROL: la punta de cada pila tiene que caer sobre el salto
        % DIRECTO ni -> n que devuelve FV.bohrT. Si un rombo no toca su
        % barra, la suma de tramos y el salto directo no coinciden.
        directo = zeros(1, numel(destinos));
        for k = 1:numel(destinos)
            sd = saltoDe(P.Z, P.ni, destinos(k));
            directo(k) = abs(FV.J2eV(sd.E));   % absorcion da negativo
        end
        plot(axCasc, 1:numel(destinos), directo, 'd', 'MarkerSize',5, ...
            'MarkerFaceColor',[0.90 0.35 0.05], 'MarkerEdgeColor','none');

        % Separador entre los que emiten (destino abajo de ni) y los que
        % absorben (destino arriba). Con ni = 1 o ni = NMAX no hay ninguno
        % de un lado y la linea no se dibuja.
        nEmite = sum(destinos < P.ni);
        if nEmite > 0 && nEmite < numel(destinos)
            plot(axCasc, (nEmite+0.5)*[1 1], [0 max(total)*1.32], ':', ...
                'Color',[0.35 0.35 0.35], 'LineWidth',1.0);
        end
        if nEmite > 0
            text(nEmite/2 + 0.5, max(total)*1.22, 'EMITE (baja)', ...
                'Parent',axCasc, 'HorizontalAlignment','center', ...
                'FontSize',8, 'Color',[0.70 0.20 0.10]);
        end
        if nEmite < numel(destinos)
            text((nEmite + numel(destinos))/2 + 0.5, max(total)*1.22, ...
                'ABSORBE (sube)', 'Parent',axCasc, ...
                'HorizontalAlignment','center', 'FontSize',8, ...
                'Color',[0.10 0.35 0.65]);
        end

        % Lambda del foton de cada salto, arriba de su barra
        for k = 1:numel(destinos)
            sd = saltoDe(P.Z, P.ni, destinos(k));
            text(k, total(k), sprintf('%.0f nm', abs(sd.lam)*1e9), ...
                'Parent',axCasc, 'HorizontalAlignment','center', ...
                'VerticalAlignment','bottom', 'FontSize',7.5, ...
                'Color',[0.25 0.25 0.25]);
        end

        etiq = arrayfun(@(n) sprintf('%d>%d', P.ni, n), destinos, ...
            'UniformOutput', false);
        set(axCasc, 'XTick',1:numel(destinos), 'XTickLabel',etiq);
        xlim(axCasc,[0.4 numel(destinos)+0.6]);
        ylim(axCasc,[0 max(total)*1.34]);
        ylabel(axCasc,'energia [eV]');
        title(axCasc, sprintf(['Saltos desde n = %d: cada barra apilada ' ...
            'por tramos, el rombo es el salto directo'], P.ni), ...
            'FontWeight','normal');
        estiloEje(axCasc);
    end

    % =====================================================================
    %  EXPORTAR - render fijo con los valores por defecto, sin ventana.
    %  Es tambien la via de verificar el simulador sin interfaz grafica.
    % =====================================================================

    function exportar()
        if ~isfolder('figs'), mkdir('figs'); end

        % 'Visible','off' arma la figura en memoria y no la muestra.
        % fig y los tres ejes son las MISMAS variables que usa el modo
        % interactivo: al ser funciones anidadas, las comparten. Por eso
        % dibujarAtomo y companiia escriben en estos ejes sin recibirlos.
        fig = figure('Color','w', 'Position',[100 100 1180 740], ...
            'Visible','off');
        axAtomo = axes('Parent',fig, 'Position',[0.04 0.45 0.40 0.50]);
        axNiv   = axes('Parent',fig, 'Position',[0.55 0.45 0.42 0.50]);
        axCasc  = axes('Parent',fig, 'Position',[0.07 0.09 0.60 0.27]);

        % El electron se dibuja YA CAIDO en nf, que es el instante que
        % corresponde al foton que sale. Dibujarlo en su capa de llenado
        % contradiria el titulo, que anuncia el salto.
        niv = nivelesDe(P.Z);
        [rd, ~] = escalaDibujo(niv);
        dibujarAtomo(niv, [rd(P.nf) 2.1]);
        dibujarFoton(niv, 2.1);
        dibujarNiveles(niv);
        dibujarSaltos();

        exportgraphics(fig, fullfile('figs','sim1_saltoOrbital.png'), ...
            'Resolution',150);
        close(fig);
    end
end
