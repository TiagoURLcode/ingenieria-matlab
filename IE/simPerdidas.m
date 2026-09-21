function varargout = simPerdidas(modo)
%SIMPERDIDAS Perdidas y rendimiento de un transformador, desde los ensayos.
%   simPerdidas              abre la interfaz
%   simPerdidas('exportar')  dibuja los casos a PNG, sin ventana
%   [c,i] = simPerdidas('texto')  devuelve el texto de los dos paneles,
%                            que es la parte de la interfaz que si se
%                            puede verificar sin pantalla
%
% No contiene fisica: todo sale de IE.perdidas, que parte de los ensayos de
% vacio y cortocircuito. Este archivo dibuja, explica y deja cambiar el
% modelo de perdida para que se vea cuanto cambia el resultado.
%
% LO QUE LOS ENSAYOS NO PUEDEN DAR: el ensayo de vacio y el de
% cortocircuito determinan Req y Xeq AGREGADAS, no R1 y R2 por separado.
% Para dibujar el circuito exacto hay que SUPONER un reparto, y lo normal
% es mitad y mitad. El simulador lo muestra, pero avisa que es un supuesto
% y no una medicion.

    if nargin < 1, modo = 'interactivo'; end
    switch lower(modo)
        case 'interactivo', construir();
        case 'exportar',    exportar();
        case 'texto',       [varargout{1:max(nargout,1)}] = textoPaneles();
        otherwise
            error('IE:modo', 'Modo "%s": usa interactivo o exportar.', modo);
    end
end

%% ======================================================================
%  DATOS Y CALCULO
%% ======================================================================
function d = datosBase()
% Ensayos de un transformador de 15 kVA, 2400/240 V.
d = struct('Poc',80, 'Voc',240, 'Ioc',1.2, ...
    'Psc',300, 'Vsc',120, 'Isc',6.25, ...
    'Snom',15e3, 'V',2400, 'FP',0.85, 'x',1, 'a',10, ...
    ...  % Constantes del material: valores de EJEMPLO, no del curso.
    ...  % Va SOLO kh: con kh se calcula Ph y Pe sale por RESTA contra la
    ...  % Pfe medida, asi que las dos suman el total. Dando tambien ke y
    ...  % esp, IE.perdidas calcula las dos por formula y dejan de sumar.
    'kh',0.49, 'f',60, 'Bmax',1.4, 'nst',1.6);
end

function [r, avisos] = calcular(d, opc)
% opc.nucleo : 'ensayo'   -> Pfe = Poc, sin separar
%              'separado' -> Pfe = Poc, y se parte en Ph (de kh) y Pe (resta)
% opc.padd   : perdidas adicionales en W (0 = desactivadas)
%
% EL ENSAYO DE VACIO NO SE PUEDE SACAR. Rc = Voc^2/Poc y Xm salen de ahi,
% asi que Poc siempre va. Las constantes del material no reemplazan la
% medicion: solo permiten SEPARAR la Pfe medida en sus dos mecanismos.
avisos = {};
dd = d;
if strcmp(opc.nucleo, 'ensayo')
    dd = rmfield(dd, {'kh','f','Bmax','nst'});
end
dd.Padd = opc.padd;
r = IE.perdidas(dd);

if strcmp(opc.nucleo,'separado') && isfield(r,'Ph') && isfield(r,'Pe')
    avisos{end+1} = sprintf(['Separacion: Ph = kh*f*Bmax^n = %.1f W de ' ...
        'histeresis, y Pe = Pfe - Ph = %.1f W de Foucault. kh es un ' ...
        'valor de ejemplo, no un dato del curso: cambialo por el de tu ' ...
        'material.'], r.Ph, r.Pe);
end
end

function T = barrido(d, opc)
% Rendimiento contra fraccion de carga. Sirve para ubicar el maximo y
% comprobar que ahi las perdidas fijas igualan a las variables.
xs = linspace(0.05, 1.3, 60);
eta = nan(size(xs));  pcu = nan(size(xs));  pfij = nan(size(xs));
for k = 1:numel(xs)
    dk = d;  dk.x = xs(k);
    rk = calcular(dk, opc);
    eta(k)  = rk.etapct;
    pcu(k)  = rk.Pcu;
    pfij(k) = rk.Pfe + rk.Padd;
end
T = struct('x',xs, 'eta',eta, 'pcu',pcu, 'pfij',pfij);
end

%% ======================================================================
%  ELEMENTOS DEL CIRCUITO
%% ======================================================================
function E = elementos()
% Cada elemento del circuito con su sigla, para poder resaltarlo, y la
% explicacion de que representa y de que depende.
E = struct('sigla',{},'nombre',{},'texto',{});
E(1) = struct('sigla','R1', 'nombre','R1  resistencia del primario', ...
  'texto',['PERDIDA EN EL COBRE del devanado primario. Depende de la ' ...
   'CARGA: crece con el cuadrado de la corriente. Se disipa como calor ' ...
   'en el propio conductor. Los ensayos NO la separan de R2: lo que se ' ...
   'mide es Req = R1 + a^2*R2.']);
E(2) = struct('sigla','X1', 'nombre','X1  dispersion del primario', ...
  'texto',['NO ES UNA PERDIDA. Es el flujo que se escapa y no enlaza al ' ...
   'otro devanado. No disipa potencia activa: lo que produce es CAIDA ' ...
   'DE TENSION, y por eso pesa en la regulacion y no en el rendimiento.']);
E(3) = struct('sigla','R2', 'nombre','R2  resistencia del secundario', ...
  'texto',['Igual que R1 pero del otro devanado. Referida al primario se ' ...
   'multiplica por a^2. Tambien depende de la carga.']);
E(4) = struct('sigla','X2', 'nombre','X2  dispersion del secundario', ...
  'texto','Igual que X1, del lado secundario. Tampoco es perdida.');
E(5) = struct('sigla','Rc', 'nombre','Rc  perdidas del nucleo', ...
  'texto',['PERDIDA EN EL HIERRO: histeresis mas corrientes de Foucault. ' ...
   'Depende de la TENSION y de la frecuencia, NO de la carga: con el ' ...
   'transformador energizado y en vacio ya se esta perdiendo. Se disipa ' ...
   'en el nucleo. La mide el ensayo de VACIO.']);
E(6) = struct('sigla','Xm', 'nombre','Xm  magnetizacion', ...
  'texto',['NO ES UNA PERDIDA. Es la corriente que hace falta para ' ...
   'establecer el flujo en el nucleo. Es reactiva: va y vuelve.']);
end

function txt = explicarElemento(k)
E = elementos();
txt = [{upper(E(k).nombre)}; {''}; textwrap({E(k).texto}, 76)];
end

%% ======================================================================
%  DIBUJO
%% ======================================================================
function ejeClaro(ax)
set(ax, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.85 0.85 0.85]);
set([ax.Title ax.XLabel ax.YLabel], 'Color','k');
end

function caja(ax, x, y, w, h, etiq, val, col, lw)
% Elemento en SERIE sobre el conductor: rectangulo relleno de blanco que
% tapa el cable, que es como se dibuja a mano.
rectangle('Parent',ax, 'Position',[x-w/2, y-h/2, w, h], ...
    'FaceColor','w', 'EdgeColor',col, 'LineWidth',lw);
text(ax, x, y+h/2+0.18, sprintf('%s = %.4g', etiq, val), ...
    'HorizontalAlignment','center', 'Color',col, 'FontSize',9);
end

function circuito(ax, r, modo, sel, a)
% Circuito equivalente, en los cuatro modelos que se usan en clase.
%
%   'sinRamaP'  Vp/a - Reqp - Xeqp - Vs        SIN rama de excitacion,
%               referido al PRIMARIO. Es el de Kosow p.566 y el que pide
%               la catedra.
%                   Reqp = Rp + a^2*Rs        Xeqp = Xp + a^2*Xs
%   'sinRamaS'  el mismo, referido al SECUNDARIO. Las impedancias del
%               primario se dividen por a^2 en vez de multiplicar las del
%               secundario:
%                   Reqs = Rp/a^2 + Rs        Xeqs = Xp/a^2 + Xs
%               Es el MISMO circuito visto desde el otro lado: Reqs =
%               Reqp/a^2. No es otro modelo, es otra referencia.
%   'conRama'   aproximado CON la rama, corrida a la entrada.
%   'exacto'    la rama va entre los dos devanados, con R1/X1 y R2/X2.
%
% LO QUE YA USA EL MODELO SIN RAMA: la regulacion que devuelve
% IE.perdidas se calcula con Vp/a = Vs + (Req + j*Xeq)*Is, o sea con el
% circuito SIN rama. La rama solo entra en el rendimiento, como la
% perdida fija Pfe. Por eso elegir entre estos cuatro cambia el dibujo y
% las etiquetas, no los numeros.
cla(ax); hold(ax,'on'); set(ax,'Color','w'); axis(ax,'off');
yT = 1;  yB = 0;  xF = 13;
E = elementos();
sig = '';  if sel > 0, sig = E(sel).sigla; end

plot(ax, [0 xF], [yT yT], 'k-', 'LineWidth',1.3);
plot(ax, [0 xF], [yB yB], 'k-', 'LineWidth',1.3);
plot(ax, [0 0],  [yB yT], 'k-', 'LineWidth',1.3);
plot(ax, [xF xF],[yB yT], 'k-', 'LineWidth',1.3);

izq = 'Vp';  der = 'aVs';  xs = [];  pie = '';
switch modo
    case 'sinRamaP'
        ser = {'Req', r.Req, 5.0; 'Xeq', r.Xeq, 8.0};
        izq = 'Vp';  der = 'aVs';     % todo llevado al lado primario
        tit = 'SIN rama de excitacion, referido al PRIMARIO';
        pie = sprintf(['Reqp = Rp + a^2*Rs = %.4g ohm     ' ...
            'Xeqp = Xp + a^2*Xs = %.4g ohm     (a = %g)'], ...
            r.Req, r.Xeq, a);
    case 'sinRamaS'
        ser = {'Req', r.Req/a^2, 5.0; 'Xeq', r.Xeq/a^2, 8.0};
        izq = 'Vp/a';  der = 'Vs';    % todo llevado al lado secundario
        tit = 'SIN rama de excitacion, referido al SECUNDARIO';
        pie = sprintf(['Reqs = Rp/a^2 + Rs = %.4g ohm     ' ...
            'Xeqs = Xp/a^2 + Xs = %.4g ohm     ' ...
            'es Reqp/a^2, el mismo circuito del otro lado'], ...
            r.Req/a^2, r.Xeq/a^2);
    case 'conRama'
        ser = {'Req', r.Req, 7.0; 'Xeq', r.Xeq, 10.0};
        xs  = 2.2;
        tit = ['APROXIMADO con rama: la excitacion se corre a la ENTRADA ' ...
            'y las impedancias se suman'];
    case 'exacto'
        ser = {'R1', r.Req/2, 2.0; 'X1', r.Xeq/2, 4.0; ...
               'R2', r.Req/2, 9.0; 'X2', r.Xeq/2, 11.0};
        xs  = 6.0;
        tit = ['EXACTO: la rama va ENTRE los dos devanados   (R1 y R2 ' ...
            'repartidos mitad y mitad: los ensayos no los separan)'];
end
text(ax, -0.35, 0.5, izq, 'Color','k', 'FontWeight','bold', ...
    'HorizontalAlignment','right');
text(ax, xF+0.35, 0.5, der, 'Color','k', 'FontWeight','bold');

if ~isempty(xs)
    for j = 1:2
        xb = xs + 1.5*(j-1);
        plot(ax, [xb xb], [yB yT], 'k-', 'LineWidth',1.1);
        if j == 1, et = 'Rc'; v = r.Rc; else, et = 'Xm'; v = r.Xm; end
        c = [0 0 0];  lw = 1.3;
        if strcmpi(et, sig), c = [0.85 0.1 0.1]; lw = 2.4; end
        rectangle('Parent',ax, 'Position',[xb-0.22, 0.34, 0.44, 0.32], ...
            'FaceColor','w', 'EdgeColor',c, 'LineWidth',lw);
        text(ax, xb, 0.18, sprintf('%s = %.4g', et, v), ...
            'HorizontalAlignment','center', 'Color',c, 'FontSize',9);
    end
end

for k = 1:size(ser,1)
    c = [0 0 0];  lw = 1.3;
    if strcmpi(ser{k,1}, sig), c = [0.85 0.1 0.1]; lw = 2.4; end
    caja(ax, ser{k,3}, yT, 1.1, 0.34, ser{k,1}, ser{k,2}, c, lw);
end

if ~isempty(pie)
    text(ax, xF/2, -0.35, pie, 'HorizontalAlignment','center', ...
        'Color',[0.25 0.25 0.25], 'FontSize',8.5);
end
title(ax, tit, 'Color','k', 'FontSize',8.5);
xlim(ax, [-1.2 xF+1.4]);  ylim(ax, [-0.75 1.75]);
hold(ax,'off');
end

function barras(ax, r)
cla(ax); hold(ax,'on'); ejeClaro(ax);
if isfield(r,'Ph') && isfield(r,'Pe') && ~isnan(r.Ph)
    v = [r.Pcu, r.Ph, r.Pe, r.Padd];
    et = {'cobre','histeresis','Foucault','adicionales'};
else
    v = [r.Pcu, r.Pfe, r.Padd];
    et = {'cobre','nucleo','adicionales'};
end
paleta = [0.85 0.35 0.1; 0.2 0.4 0.8; 0.3 0.6 0.9; 0.5 0.5 0.5];
b = bar(ax, v, 'FaceColor','flat');
b.CData = paleta(1:numel(v), :);
set(ax, 'XTick',1:numel(v), 'XTickLabel',et);
ylabel(ax, 'W');
title(ax, sprintf('Perdidas: %.1f W en total', r.Pperd));
ylim(ax, [0 1.25*max(v)]);   % aire para que las etiquetas no toquen el titulo
for k = 1:numel(v)
    text(ax, k, v(k), sprintf('%.1f', v(k)), 'Color','k', 'FontSize',8, ...
        'HorizontalAlignment','center', 'VerticalAlignment','bottom');
end
grid(ax,'on');  hold(ax,'off');
end

function curvaEta(ax, T, r)
cla(ax); hold(ax,'on'); ejeClaro(ax);
plot(ax, T.x, T.eta, 'LineWidth',1.6, 'Color',[0 0.45 0.2]);
[~, k] = max(T.eta);
plot(ax, T.x(k), T.eta(k), 'kv', 'MarkerFaceColor','k');
xline(ax, r.xopt, '--', sprintf('xopt = %.3f', r.xopt), 'Color',[0.4 0.4 0.4]);
grid(ax,'on');  xlabel(ax,'fraccion de carga x');  ylabel(ax,'rendimiento [%]');
title(ax, sprintf('Maximo %.3f%% en x = %.3f', T.eta(k), T.x(k)));
hold(ax,'off');
end

function curvaCruce(ax, T, r)
% La comprobacion: el maximo cae donde la perdida variable alcanza a la fija.
%
% OJO CON LAS ADICIONALES. IE.perdidas las suma a Pperd como una
% CONSTANTE, asi que aca cuentan del lado de las fijas y por eso mueven
% xopt. Pero su propia tabla las clasifica como variables, que es lo que
% dice la fisica: nacen del flujo de dispersion y crecen con la corriente.
% Las dos cosas no pueden ser ciertas a la vez. Mientras el modelo las
% trate como constantes, esta grafica las dibuja donde el modelo las pone.
cla(ax); hold(ax,'on'); ejeClaro(ax);
plot(ax, T.x, T.pcu,  'LineWidth',1.5, 'Color',[0.85 0.35 0.1]);
plot(ax, T.x, T.pfij, 'LineWidth',1.5, 'Color',[0.2 0.4 0.8]);
xline(ax, r.xopt, '--', 'Color',[0.4 0.4 0.4]);
legend(ax, {'variables: cobre','fijas: nucleo + adicionales'}, ...
    'Location','northwest', 'Color','w', 'TextColor','k', ...
    'EdgeColor',[0.8 0.8 0.8]);
grid(ax,'on');  xlabel(ax,'fraccion de carga x');  ylabel(ax,'W');
pcuOpt = r.PcuNom*r.xopt^2;
title(ax, sprintf('En xopt: variables %.1f W, fijas %.1f W', ...
    pcuOpt, r.Pfe + r.Padd));
hold(ax,'off');
end

function txt = aislamientos()
txt = {
 'DONDE SE VA EL CALOR DE ESTAS PERDIDAS'
 ''
 'ACEITE MINERAL. Aisla y evacua muy bien el calor por conveccion, asi'
 '  que admite mas perdida por unidad de volumen. Es inflamable y'
 '  contamina si se derrama.'
 'ESTER NATURAL. Capacidad termica parecida, biodegradable y con punto'
 '  de inflamacion mas alto. Mas caro y mas viscoso en frio.'
 'GAS SF6. No es inflamable y ocupa menos espacio, pero evacua peor que'
 '  un liquido, asi que limita la perdida admisible. Su paradoja: es un'
 '  gas de efecto invernadero muy potente.'
 'SECO (epoxi, VPI). Enfria con AIRE, que es el peor de los cuatro'
 '  evacuando calor: el mismo nucleo tolera menos perdida y el equipo'
 '  sale mas grande para la misma potencia. A cambio no hay incendio ni'
 '  derrame, y por eso va en hospitales y edificios.'
 ''
 'La cadena es: mas perdidas -> mas calor -> mas exigencia al aislante.'
 'Elegir el aislante fija cuanta perdida se puede tolerar, no al reves.'
 };
end

function lin = tablaTexto(T)
% El catalogo en texto plano. disp() sobre una table mete marcado
% <strong> en la salida capturada con evalc, que despues se ve crudo en
% un uicontrol: hay que armar las filas a mano.
lin = {sprintf('%-16s %8s %8s %-10s %-24s %-14s', ...
    'PERDIDA','W','% TOTAL','CATEGORIA','DEPENDE DE','LA MIDE')};
lin{end+1} = repmat('-', 1, 84);
for k = 1:height(T)
    lin{end+1} = sprintf('%-16s %8.1f %8.1f %-10s %-24s %-14s', ...
        char(T.Perdida(k)), T.W(k), T.PctDelTotal(k), ...
        char(T.Categoria(k)), char(T.Depende(k)), char(T.Ensayo(k))); %#ok<AGROW>
end
% COLUMNA, no fila: lin{end+1} crece a lo ancho y quien la concatena con
% otras lineas en vertical se rompe. Paso obligatorio, no cosmetico.
lin = lin(:);
end

function [cat, inf] = panelesTexto(r, avisos, sel)
% Arma el contenido de los dos paneles de texto. Vive aparte de refrescar
% para que se pueda verificar sin pantalla: simPerdidas('texto') llama
% justo a esto, y testPerdidas lo comprueba. El bug que motivo esta
% separacion fue una concatenacion fila/columna que ni el modo exportar
% ni las suites tocaban, porque solo existia dentro de la interfaz.
cat = [{sprintf(['rendimiento %.3f %%   perdidas %.1f W   ' ...
    'regulacion %.2f %%'], r.etapct, r.Pperd, r.RV)}; {''}; ...
    tablaTexto(r.tabla)];
if ~isempty(avisos)
    cat = [{['[!] ' avisos{1}]}; {''}; cat];
end
if sel > 0
    inf = [explicarElemento(sel); {''}; aislamientos()];
else
    inf = aislamientos();
end
end

%% ======================================================================
%  INTERFAZ
%% ======================================================================
function construir()
d = datosBase();
opc = struct('nucleo','ensayo', 'padd',0, 'modo','sinRamaP', 'sel',0);

f = figure('Name','Perdidas y rendimiento','Color','w', ...
    'Position',[70 60 1260 760], 'NumberTitle','off');
axC = axes('Parent',f, 'Position',[0.25 0.72 0.50 0.24]);
axB = axes('Parent',f, 'Position',[0.80 0.72 0.18 0.22]);
axE = axes('Parent',f, 'Position',[0.30 0.40 0.30 0.24]);
axX = axes('Parent',f, 'Position',[0.68 0.40 0.30 0.24]);

pD = uipanel('Parent',f, 'Title','Ensayos y carga', 'BackgroundColor','w', ...
    'ForegroundColor','k', 'Position',[0.01 0.40 0.22 0.56]);
pT = uipanel('Parent',f, 'Title','Catalogo de perdidas', ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'Position',[0.01 0.01 0.47 0.37]);
pX = uipanel('Parent',f, 'Title','Elemento y aislamiento', ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'Position',[0.50 0.01 0.49 0.37]);

S = struct('d',d, 'opc',opc, 'axC',axC, 'axB',axB, 'axE',axE, 'axX',axX);
S.txtTab = uicontrol('Parent',pT, 'Style','edit', 'Max',2, 'Min',0, ...
    'Enable','inactive', 'HorizontalAlignment','left', 'BackgroundColor','w', ...
    'ForegroundColor','k', 'FontName','monospaced', 'FontSize',8, ...
    'Units','normalized', 'Position',[0.01 0.01 0.98 0.98]);
S.txtInf = uicontrol('Parent',pX, 'Style','edit', 'Max',2, 'Min',0, ...
    'Enable','inactive', 'HorizontalAlignment','left', 'BackgroundColor','w', ...
    'ForegroundColor','k', 'FontName','monospaced', 'FontSize',8.5, ...
    'Units','normalized', 'Position',[0.01 0.01 0.98 0.98]);

campos = {'Poc','Poc vacio [W]'; 'Voc','Voc [V]'; 'Ioc','Ioc [A]'; ...
    'Psc','Psc corto [W]'; 'Vsc','Vsc [V]'; 'Isc','Isc [A]'; ...
    'Snom','Snom [VA]'; 'V','V carga [V]'; 'FP','FP'; 'x','x carga'; ...
    'a','relacion a'};
S.ed = struct();
for k = 1:numel(campos(:,1))
    y = 0.95 - 0.062*k;
    uicontrol('Parent',pD, 'Style','text', 'String',campos{k,2}, ...
        'BackgroundColor','w', 'ForegroundColor','k', ...
        'HorizontalAlignment','left', 'Units','normalized', ...
        'Position',[0.04 y 0.56 0.05]);
    S.ed.(campos{k,1}) = uicontrol('Parent',pD, 'Style','edit', ...
        'String',num2str(d.(campos{k,1})), 'BackgroundColor','w', ...
        'ForegroundColor','k', 'Units','normalized', ...
        'Position',[0.60 y 0.36 0.05], 'Callback',@cb);
end
yb = 0.95 - 0.062*11;
S.popNuc = mkPop(pD, yb,      'Modelo del nucleo', ...
    {'Pfe del ensayo','separar histeresis y Foucault'});
S.popCir = mkPop(pD, yb-0.11, 'Circuito', ...
    {'sin rama, ref. primario','sin rama, ref. secundario', ...
     'aproximado con rama','exacto'});
Eel = elementos();
S.popEle = mkPop(pD, yb-0.22, 'Explicar elemento', ...
    [{'(ninguno)'} {Eel.nombre}]);
S.chkAdd = uicontrol('Parent',pD, 'Style','checkbox', ...
    'String','perdidas adicionales (40 W)', 'BackgroundColor','w', ...
    'ForegroundColor','k', 'Units','normalized', ...
    'Position',[0.04 yb-0.28 0.92 0.05], 'Callback',@cb);
guidata(f, S);
refrescar(f);
end

function h = mkPop(p, y, etiq, items)
uicontrol('Parent',p, 'Style','text', 'String',etiq, ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'HorizontalAlignment','left', 'Units','normalized', ...
    'Position',[0.04 y+0.045 0.92 0.045]);
h = uicontrol('Parent',p, 'Style','popupmenu', 'String',items, ...
    'BackgroundColor','w', 'ForegroundColor','k', 'Units','normalized', ...
    'Position',[0.04 y 0.92 0.045], 'Callback',@cb);
end

function cb(src, ~)
f = ancestor(src,'figure');  S = guidata(f);
for c = fieldnames(S.ed)'
    v = str2double(S.ed.(c{1}).String);
    if ~isnan(v), S.d.(c{1}) = v; end
end
if S.popNuc.Value == 1, S.opc.nucleo = 'ensayo';
else,                   S.opc.nucleo = 'separado'; end
modos = {'sinRamaP','sinRamaS','conRama','exacto'};
S.opc.modo = modos{S.popCir.Value};
S.opc.sel    = S.popEle.Value - 1;
S.opc.padd   = 40 * S.chkAdd.Value;
guidata(f, S);  refrescar(f);
end

function refrescar(f)
S = guidata(f);
try
    [r, avisos] = calcular(S.d, S.opc);
    T = barrido(S.d, S.opc);
catch ME
    set(S.txtTab, 'String', ['No se pudo calcular: ' ME.message]);  return
end
circuito(S.axC, r, S.opc.modo, S.opc.sel, S.d.a);
barras(S.axB, r);
curvaEta(S.axE, T, r);
curvaCruce(S.axX, T, r);

[cat, inf] = panelesTexto(r, avisos, S.opc.sel);
set(S.txtTab, 'String', cat);
set(S.txtInf, 'String', inf);
end

function [cat, inf] = textoPaneles()
% El mismo armado que hace la interfaz, para los cuatro elementos de
% seleccion y con y sin avisos.
d = datosBase();
opc = struct('nucleo','separado', 'padd',40, 'modo','sinRamaP', 'sel',5);
[r, avisos] = calcular(d, opc);
[cat, inf] = panelesTexto(r, avisos, opc.sel);
end

%% ======================================================================
%  EXPORTAR
%% ======================================================================
function exportar()
carpeta = fileparts(mfilename('fullpath'));
d = datosBase();
casos = { ...
    'sinRamaP', struct('nucleo','ensayo',   'padd',0,  'modo','sinRamaP', 'sel',0)
    'sinRamaS', struct('nucleo','ensayo',   'padd',0,  'modo','sinRamaS', 'sel',0)
    'conRama',  struct('nucleo','ensayo',   'padd',0,  'modo','conRama',  'sel',5)
    'exacto',   struct('nucleo','ensayo',   'padd',0,  'modo','exacto',   'sel',1)
    'separado', struct('nucleo','separado', 'padd',0,  'modo','sinRamaP', 'sel',0)
    'adic',     struct('nucleo','ensayo',   'padd',40, 'modo','sinRamaP', 'sel',0)
    };
for k = 1:size(casos,1)
    opc = casos{k,2};
    [r, avisos] = calcular(d, opc);
    T = barrido(d, opc);
    f = figure('Visible','off','Color','w','Position',[0 0 1150 720]);
    circuito(axes('Parent',f,'Position',[0.05 0.70 0.62 0.26]), r, ...
        opc.modo, opc.sel, d.a);
    barras(axes('Parent',f,'Position',[0.74 0.70 0.23 0.24]), r);
    curvaEta(axes('Parent',f,'Position',[0.07 0.38 0.38 0.24]), T, r);
    curvaCruce(axes('Parent',f,'Position',[0.57 0.38 0.38 0.24]), T, r);
    nomC = opc.modo;
    lin = sprintf(['modelo de nucleo: %s | adicionales: %g W | circuito: %s' ...
        '\nrendimiento %.3f %%   perdidas %.1f W   regulacion %.2f %%' ...
        '\nPfe %.1f W   Pcu %.1f W   xopt %.3f   etamax %.3f %%'], ...
        opc.nucleo, opc.padd, nomC, r.etapct, r.Pperd, ...
        r.RV, r.Pfe, r.Pcu, r.xopt, r.etamax);
    if ~isempty(avisos), lin = [lin newline '[!] ' avisos{1}]; end %#ok<AGROW>
    annotation(f,'textbox',[0.05 0.14 0.90 0.16],'String',lin, ...
        'EdgeColor',[0.8 0.8 0.8],'BackgroundColor','w','Color','k', ...
        'FontName','monospaced','FontSize',9,'FitBoxToText','off', ...
        'VerticalAlignment','top');
    dest = fullfile(carpeta, sprintf('simPerdidas_%s.png', casos{k,1}));
    exportgraphics(f, dest, 'Resolution', 110);  close(f);
    fprintf('%-9s eta=%7.3f%%  Pperd=%6.1f W  Pfe=%6.1f  xopt=%.3f  %s\n', ...
        casos{k,1}, r.etapct, r.Pperd, r.Pfe, r.xopt, dest);
end
end
