function simTrifasico(modo)
%SIMTRIFASICO Conexiones trifasicas de transformadores: fasores y numeros.
%   simTrifasico              abre la interfaz
%   simTrifasico('exportar')  dibuja las seis conexiones a PNG, sin ventana
%
% Cubre las seis que resuelve TT.m: Y-Y, D-D, Y-D, D-Y, Y-Z y D-Z. Delta
% abierta, Scott y autotransformador quedan pendientes.
%
% No contiene fisica: los numeros y los angulos salen de TT.m, que a su vez
% despeja con Motor. Este archivo dibuja y explica.
%
% LO QUE ESTE MODELO NO HACE: TT.m resuelve el sistema EQUILIBRADO. El
% comportamiento con carga desequilibrada necesita componentes simetricas,
% que no estan en el modelo, asi que aca no se simula: el panel dice que
% pasa con el neutro y por que, pero no hay numeros de desequilibrio.

    if nargin < 1, modo = 'interactivo'; end
    switch lower(modo)
        case 'interactivo', construir();
        case 'exportar',    exportar();
        otherwise
            error('IE:modo', 'Modo "%s": usa interactivo o exportar.', modo);
    end
end

%% ======================================================================
%  CATALOGO DE CONEXIONES
%% ======================================================================
function C = conexiones()
C = struct('nombre',{},'metodo',{},'cP',{},'cS',{},'neutro',{},'notas',{});
C(1) = struct('nombre','Y-Y  estrella - estrella', 'metodo','YY', ...
    'cP','Y', 'cS','Y', 'neutro','en los dos lados', 'notas', { { ...
    'VENTAJA: hay neutro de los dos lados, y con el dos niveles de tension,'
    '  entre lineas y entre linea y neutro.'
    'VENTAJA: cada devanado ve V_L/raiz(3), asi que necesita menos'
    '  aislamiento que uno en delta a la misma tension de linea.'
    'DESVENTAJA: con carga desequilibrada las tensiones de fase se'
    '  desequilibran bastante.'
    'DESVENTAJA: sin el neutro bien puesto a tierra el punto neutro se'
    '  vuelve inestable y se desplaza.'
    'DESVENTAJA: no hay ninguna delta que atrape las armonicas de tercer'
    '  orden, asi que se van a la red.'
    'USO: poco comun sola, justamente por las dos ultimas.'} });
C(2) = struct('nombre','D-D  delta - delta', 'metodo','DD', ...
    'cP','D', 'cS','D', 'neutro','no hay, de ningun lado', 'notas', { { ...
    'VENTAJA: maneja bien cargas trifasicas de corriente alta.'
    'VENTAJA: las dos deltas encierran las armonicas de tercer orden y no'
    '  las dejan volver a la red.'
    'VENTAJA: si falla una unidad puede seguir en delta abierta.'
    'DESVENTAJA: no hay neutro, asi que no sirve para cargas entre fase y'
    '  neutro.'
    'DESVENTAJA: cada devanado soporta la tension de linea entera.'
    'USO: industria, donde la carga es trifasica y no hace falta neutro.'} });
C(3) = struct('nombre','Y-D  estrella - delta', 'metodo','YD', ...
    'cP','Y', 'cS','D', 'neutro','solo en el primario', 'notas', { { ...
    'DESFASE: el secundario atrasa 30 grados. No es un defecto, pero'
    '  impide poner en paralelo con un banco de otro grupo.'
    'ARMONICAS: la DELTA es la que atrapa las corrientes de tercer'
    '  armonico y las hace circular. En esta conexion la delta es el'
    '  SECUNDARIO, no el primario: es el error que traen las preguntas'
    '  t4p09 y t4p10 del cuestionario.'
    'DESVENTAJA: el devanado en delta se calienta de mas porque por el'
    '  circulan esas corrientes.'
    'USO: bajar de alta a media tension al principio de la distribucion.'} });
C(4) = struct('nombre','D-Y  delta - estrella', 'metodo','DY', ...
    'cP','D', 'cS','Y', 'neutro','solo en el secundario', 'notas', { { ...
    'DESFASE: el secundario adelanta 30 grados.'
    'VENTAJA: el neutro queda del lado de BAJA, que es donde se necesita'
    '  para alimentar cargas monofasicas entre fase y neutro.'
    'VENTAJA: la delta del primario atrapa las armonicas de tercer orden.'
    'VENTAJA: el neutro del secundario es estable y da retorno a las'
    '  corrientes de desequilibrio.'
    'USO: el transformador de distribucion tipico, de media a baja'
    '  tension. Es la conexion mas comun para llegar al usuario.'} });
C(5) = struct('nombre','Y-Z  estrella - zig-zag', 'metodo','YZ', ...
    'cP','Y', 'cS','Z', 'neutro','en los dos, y el del zig-zag es firme', ...
    'notas', { { ...
    'COMO ES: cada fase del secundario se parte en dos medias bobinas'
    '  puestas en COLUMNAS DISTINTAS y conectadas en oposicion.'
    'POR QUE: las dos mitades estan a 120 grados, asi que se suman a'
    '  raiz(3) veces una mitad, no a 2 veces. Rinden el 86.6 por ciento.'
    'PRECIO: hace falta 15.5 por ciento mas de vueltas para la misma'
    '  tension. Es el costo de la conexion.'
    'A CAMBIO: neutro firme y camino para las corrientes de secuencia'
    '  cero, incluso sin neutro del otro lado.'
    'USO: crear un neutro artificial que sirva de tierra, y puesta a'
    '  tierra de sistemas en delta.'} });
C(6) = struct('nombre','D-Z  delta - zig-zag', 'metodo','DZ', ...
    'cP','D', 'cS','Z', 'neutro','solo en el secundario, firme', ...
    'notas', { { ...
    'DIFERENCIA CON Y-Z: unicamente la conexion del PRIMARIO. El'
    '  secundario es el mismo zig-zag. Eso es lo que pregunta el'
    '  cuestionario del curso.'
    'DESFASE: cero. La delta no mete los 30 grados de la estrella, y se'
    '  cancelan con los -30 internos del zig-zag.'
    'MISMO PRECIO: 15.5 por ciento mas de cobre que una estrella comun.'
    'USO: igual que Y-Z, cuando el primario ya viene en delta.'} });
end

%% ======================================================================
%  CALCULO
%% ======================================================================
function P = calcular(ic, d)
C = conexiones();  c = C(ic);
r = TT.(c.metodo)(d);
P.c = c;
P.r = r;
num = @(x) double(x);
P.VphiP = num(r.V_phiP);  P.VLP = num(r.V_LP);
P.VphiS = num(r.V_phiS);  P.VLS = num(r.V_LS);
P.aVphiP = num(r.ang_VphiP);  P.aVLP = num(r.ang_VLP);
P.aVphiS = num(r.ang_VphiS);  P.aVLS = num(r.ang_VLS);
P.desf = num(r.desf);
P.a    = num(r.a);
if isfield(r,'I_LP'), P.ILP = num(r.I_LP); P.IphiP = num(r.I_phiP);
    P.ILS = num(r.I_LS); P.IphiS = num(r.I_phiS);
else, P.ILP = NaN; P.IphiP = NaN; P.ILS = NaN; P.IphiS = NaN;
end
% Vueltas relativas: cuantas necesita el secundario contra una estrella
% comun para la misma relacion de tension. Sale de TT, no escrito a mano.
dN = d;  dN.N_P = 1000;
P.NsEsta = num(TT.(c.metodo)(dN).N_S);
P.NsRef  = num(TT.YY(dN).N_S);
end

%% ======================================================================
%  DIBUJO
%% ======================================================================
function ejeClaro(ax)
set(ax, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.85 0.85 0.85]);
set([ax.Title ax.XLabel ax.YLabel], 'Color','k');
end

function fasores(ax, P)
% Fasores de fase y de linea de los dos lados, normalizados para que
% entren los dos en el mismo cuadro.
cla(ax); hold(ax,'on'); ejeClaro(ax);
escP = 1/max(P.VLP, eps);
escS = 1/max(P.VLS, eps);

flecha(ax, P.VphiP*escP, P.aVphiP, [0 0 0.75], 1.8, 'Vfase P', true);
flecha(ax, P.VLP*escP,  P.aVLP,   [0.4 0.6 1.0], 1.2, 'Vlinea P', false);
flecha(ax, P.VphiS*escS, P.aVphiS, [0.8 0.1 0.1], 1.8, 'Vfase S', true);
flecha(ax, P.VLS*escS,  P.aVLS,   [1.0 0.55 0.4], 1.2, 'Vlinea S', false);

% Arco del desfase entre lineas
if abs(P.desf) > 1e-9
    th = linspace(min(P.aVLP,P.aVLS), max(P.aVLP,P.aVLS), 40)*pi/180;
    ha = plot(ax, 0.42*cos(th), 0.42*sin(th), 'k--', 'LineWidth', 1);
    % Fuera de la leyenda: es una anotacion, no una serie.
    set(get(get(ha,'Annotation'),'LegendInformation'), ...
        'IconDisplayStyle','off');
    tm = mean(th);
    text(ax, 0.47*cos(tm), 0.47*sin(tm), sprintf('%+.0f deg', P.desf), ...
        'Color','k', 'FontWeight','bold', 'FontSize', 10);
end
axis(ax, 'equal');  xlim(ax, [-1.3 1.3]);  ylim(ax, [-1.3 1.3]);
grid(ax,'on');
title(ax, sprintf('Fasores   (desfase %+.0f grados)', P.desf));
legend(ax, 'Location','southoutside', 'NumColumns',4, 'Color','w', ...
    'TextColor','k', 'EdgeColor',[0.8 0.8 0.8]);
hold(ax,'off');
end

function flecha(ax, m, ang, col, lw, etiq, conFases)
% Dibuja la fase A y, si se pide, las otras dos a -120 y +120.
a = ang*pi/180;
q = quiver(ax, 0, 0, m*cos(a), m*sin(a), 0, 'Color',col, 'LineWidth',lw, ...
    'MaxHeadSize', 0.35, 'DisplayName', etiq);
if conFases
    for dd = [-120 120]
        b = (ang+dd)*pi/180;
        h = quiver(ax, 0, 0, m*cos(b), m*sin(b), 0, 'Color',col, ...
            'LineWidth',lw*0.7, 'MaxHeadSize', 0.35);
        set(get(get(h,'Annotation'),'LegendInformation'), ...
            'IconDisplayStyle','off');
    end
end
set(q, 'Tag', etiq);
end

function glifo(ax, P)
% Simbolo de cada lado: Y, triangulo o zigzag.
cla(ax); hold(ax,'on');
set(ax, 'Color','w');  axis(ax, 'off');
dibujarLado(ax, 0.0, P.c.cP, 'PRIMARIO');
dibujarLado(ax, 1.0, P.c.cS, 'SECUNDARIO');
text(ax, 0.5, -0.42, sprintf('relacion por fase a = %.4g', P.a), ...
    'HorizontalAlignment','center', 'Color','k', 'FontWeight','bold');
axis(ax,'equal');  xlim(ax, [-0.35 1.35]);  ylim(ax, [-0.55 0.55]);
title(ax, P.c.nombre, 'Color','k', 'Visible','on');
hold(ax,'off');
end

function dibujarLado(ax, x0, c, etiq)
k = 0.22;
switch c
    case 'Y'
        for a = [90 210 330]
            plot(ax, x0+[0 k*cosd(a)], [0 k*sind(a)], 'k-', 'LineWidth',2);
        end
    case 'D'
        a = [90 210 330 90];
        plot(ax, x0+k*cosd(a), k*sind(a), 'k-', 'LineWidth',2);
    case 'Z'
        for a = [90 210 330]
            p1 = [x0 + 0.45*k*cosd(a),          0.45*k*sind(a)];
            p2 = [x0 + 0.75*k*cosd(a-35),  0.75*k*sind(a-35)];
            p3 = [x0 + k*cosd(a),               k*sind(a)];
            plot(ax, [x0 p1(1) p2(1) p3(1)], [0 p1(2) p2(2) p3(2)], ...
                'k-', 'LineWidth',2);
        end
end
text(ax, x0, -0.33, etiq, 'HorizontalAlignment','center', ...
    'Color',[0.3 0.3 0.3], 'FontSize', 8);
end

function txt = numeros(P)
pen = 100*(P.NsEsta/P.NsRef - 1);
txt = {
    sprintf('Neutro: %s', P.c.neutro)
    ''
    sprintf('PRIMARIO   Vfase = %10.2f V   Vlinea = %10.2f V', P.VphiP, P.VLP)
    sprintf('           Ifase = %10.2f A   Ilinea = %10.2f A', P.IphiP, P.ILP)
    sprintf('SECUNDARIO Vfase = %10.2f V   Vlinea = %10.2f V', P.VphiS, P.VLS)
    sprintf('           Ifase = %10.2f A   Ilinea = %10.2f A', P.IphiS, P.ILS)
    ''
    sprintf('Desfase primario-secundario: %+.0f grados', P.desf)
    sprintf(['Vueltas del secundario para la misma relacion: %.1f ' ...
    'contra %.1f de una Y-Y'], P.NsEsta, P.NsRef)
    sprintf('   es decir %+.1f por ciento de cobre', pen)
    };
end

%% ======================================================================
%  INTERFAZ
%% ======================================================================
function construir()
d = struct('V_LP',13800, 'a',10, 'S',300e3, 'theta',30);
f = figure('Name','Conexiones trifasicas','Color','w', ...
    'Position',[90 80 1180 720], 'NumberTitle','off');

axG = axes('Parent',f, 'Position',[0.05 0.66 0.26 0.30]);
axF = axes('Parent',f, 'Position',[0.37 0.42 0.32 0.54]);

pC = uipanel('Parent',f, 'Title','Datos', 'BackgroundColor','w', ...
    'ForegroundColor','k', 'Position',[0.02 0.40 0.32 0.24]);
pN = uipanel('Parent',f, 'Title','Numeros', 'BackgroundColor','w', ...
    'ForegroundColor','k', 'Position',[0.72 0.42 0.26 0.54]);
pI = uipanel('Parent',f, 'Title','Ventajas, desventajas y uso', ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'Position',[0.02 0.02 0.96 0.36]);

S.d = d;  S.ic = 1;  S.axG = axG;  S.axF = axF;
S.txtNum = uicontrol('Parent',pN, 'Style','edit', 'Max',2, 'Min',0, ...
    'Enable','inactive', 'HorizontalAlignment','left', ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'FontName','monospaced', 'FontSize',8.5, 'Units','normalized', ...
    'Position',[0.02 0.02 0.96 0.96]);
S.txtInfo = uicontrol('Parent',pI, 'Style','edit', 'Max',2, 'Min',0, ...
    'Enable','inactive', 'HorizontalAlignment','left', ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'FontName','monospaced', 'FontSize',9, 'Units','normalized', ...
    'Position',[0.01 0.02 0.98 0.96]);

C = conexiones();
uicontrol('Parent',pC, 'Style','text', 'String','Conexion', ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'HorizontalAlignment','left', 'Units','normalized', ...
    'Position',[0.04 0.78 0.5 0.16]);
S.pop = uicontrol('Parent',pC, 'Style','popupmenu', 'String',{C.nombre}, ...
    'BackgroundColor','w', 'ForegroundColor','k', 'Units','normalized', ...
    'Position',[0.04 0.60 0.92 0.18], 'Callback',@cb);
S.ed = struct();
campos = {'V_LP','V linea primario [V]'; 'a','relacion por fase a'; ...
    'S','potencia trifasica [VA]'; 'theta','angulo de carga [deg]'};
for k = 1:4
    y = 0.44 - 0.14*(k-1);
    uicontrol('Parent',pC, 'Style','text', 'String',campos{k,2}, ...
        'BackgroundColor','w', 'ForegroundColor','k', ...
        'HorizontalAlignment','left', 'Units','normalized', ...
        'Position',[0.04 y 0.60 0.12]);
    S.ed.(campos{k,1}) = uicontrol('Parent',pC, 'Style','edit', ...
        'String',num2str(d.(campos{k,1})), 'BackgroundColor','w', ...
        'ForegroundColor','k', 'Units','normalized', ...
        'Position',[0.66 y 0.30 0.12], 'Callback',@cb);
end
guidata(f, S);
refrescar(f);
end

function cb(src, ~)
f = ancestor(src,'figure');  S = guidata(f);
S.ic = S.pop.Value;
for c = {'V_LP','a','S','theta'}
    v = str2double(S.ed.(c{1}).String);
    if ~isnan(v), S.d.(c{1}) = v; end
end
guidata(f, S);
refrescar(f);
end

function refrescar(f)
S = guidata(f);
try
    P = calcular(S.ic, S.d);
catch ME
    set(S.txtNum, 'String', ['No se pudo resolver: ' ME.message]);  return
end
glifo(S.axG, P);
fasores(S.axF, P);
set(S.txtNum,  'String', numeros(P));
set(S.txtInfo, 'String', P.c.notas);
end

%% ======================================================================
%  EXPORTAR
%% ======================================================================
function exportar()
carpeta = fileparts(mfilename('fullpath'));
d = struct('V_LP',13800, 'a',10, 'S',300e3, 'theta',30);
C = conexiones();
for ic = 1:numel(C)
    P = calcular(ic, d);
    f = figure('Visible','off', 'Color','w', 'Position',[0 0 1100 700]);
    axG = axes('Parent',f, 'Position',[0.04 0.56 0.26 0.36]);
    axF = axes('Parent',f, 'Position',[0.34 0.48 0.30 0.48]);
    glifo(axG, P);  fasores(axF, P);
    annotation(f, 'textbox', [0.67 0.50 0.31 0.42], 'String', numeros(P), ...
        'EdgeColor',[0.8 0.8 0.8], 'BackgroundColor','w', 'Color','k', ...
        'FontName','monospaced', 'FontSize',8.5, 'FitBoxToText','off', ...
        'VerticalAlignment','top');
    annotation(f, 'textbox', [0.04 0.06 0.94 0.36], 'String', P.c.notas, ...
        'EdgeColor',[0.8 0.8 0.8], 'BackgroundColor','w', 'Color','k', ...
        'FontName','monospaced', 'FontSize',9, 'FitBoxToText','off', ...
        'VerticalAlignment','top');
    dest = fullfile(carpeta, sprintf('simTrifasico_%s.png', C(ic).metodo));
    exportgraphics(f, dest, 'Resolution', 110);
    close(f);
    fprintf('%-5s desf=%+4.0f  V_LS=%9.2f  N_S=%7.2f (%+5.1f%% cobre)  %s\n', ...
        C(ic).metodo, P.desf, P.VLS, P.NsEsta, ...
        100*(P.NsEsta/P.NsRef - 1), dest);
end
end
