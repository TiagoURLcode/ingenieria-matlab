function simLineal(modo)
%SIMLINEAL Simulador interactivo de la maquina lineal de cd.
%   simLineal              abre la interfaz
%   simLineal('exportar')  dibuja los presets a PNG, sin ventana
%
% No contiene fisica: todo sale de IE.ecLineal a traves de IE.lineal y
% IE.trayLineal. Este archivo solo dibuja y conecta controles.
%
% El contenido didactico va en los paneles de la interfaz, no en estos
% comentarios.
%
% MODO 'exportar': la interfaz interactiva no se puede instanciar bajo
% matlab -batch, asi que la verificacion headless pasa por aca.

    if nargin < 1, modo = 'interactivo'; end
    switch lower(modo)
        case 'interactivo', construir();
        case 'exportar',    exportar();
        otherwise
            error('IE:modo', 'Modo "%s": usa interactivo o exportar.', modo);
    end
end

%% ======================================================================
%  PRESETS
%% ======================================================================
function [E, expl] = preset(n)
% Datos del ejemplo 1-10 de Chapman como base de los cinco casos.
E = struct('VB',120, 'R',0.3, 'B',0.1, 'l',10, 'm',10, ...
    'Fcarga',0, 'Rarr',0, 'tarr',Inf, 'v0',0);
switch n
    case 1
        expl = ['ARRANQUE EN VACIO. Con la barra quieta eind = 0 y la ' ...
            'corriente es VB/R = 400 A, el pico de arranque. A medida ' ...
            'que la barra acelera eind crece, la corriente cae y la ' ...
            'barra se estabiliza donde eind = VB, a 120 m/s, con ' ...
            'corriente cero.'];
    case 2
        E.Fcarga = 30;
        expl = ['MOTOR CARGADO. La carga se opone al movimiento. La ' ...
            'barra se frena, eind baja y la corriente sube EN EL MISMO ' ...
            'sentido hasta que B*l*i iguala la carga: 30 A, 111 m/s. ' ...
            'No se invierte nada. La bateria entrega potencia.'];
    case 3
        E.Fcarga = -30;
        expl = ['GENERADOR. La carga empuja A FAVOR del movimiento y ' ...
            'lleva la barra por encima de la velocidad de vacio. Ahi ' ...
            'eind = 129 V supera a VB = 120 V, la corriente SE ' ...
            'INVIERTE y la maquina entrega potencia a la bateria.'];
    case 4
        E.Fcarga = 600;  E.v0 = 120;
        expl = ['FRENADO. La barra viene a 120 m/s y se le aplica una ' ...
            'fuerza que la empuja en sentido contrario. La barra frena, ' ...
            'se detiene y arranca al reves. Con v negativa eind cambia ' ...
            'de signo, se SUMA a VB en vez de restar, y la corriente se ' ...
            'dispara por encima del pico de arranque. Todo eso se ' ...
            'disipa en R.'];
    case 6
        E.Rarr = 1.2;  E.tarr = 35;
        expl = ['RESISTENCIA DE ARRANQUE. La misma corrida en vacio, ' ...
            'pero con 1.2 ohm en serie. El pico cae de 400 A a 80 A: ' ...
            'la punteada es la misma corrida SIN la resistencia. ' ...
            'CUANDO se la quita es lo que decide si sirve. Con Rarr la ' ...
            'constante de tiempo es 15 s; sacandola a los 35 s la barra ' ...
            'ya va a 103 m/s, eind ya vale 103 V y la corriente apenas ' ...
            'sube a 57 A. Sacandola a los 3 s, con la barra todavia a ' ...
            '22 m/s, el pico vuelve a 320 A y la resistencia no sirvio ' ...
            'de nada. Movete el control de tiempo y miralo.'];
    case 5
        E.B = -0.1;
        expl = ['INVERSION DEL CAMPO. Con B al reves se invierten a la ' ...
            'vez eind y la fuerza, asi que la barra arranca para el ' ...
            'otro lado y llega a -120 m/s. La magnitud no cambia. ' ...
            'Invertir la polaridad de VB hace exactamente lo mismo.'];
    otherwise
        error('IE:preset', 'Preset %d: hay seis.', n);
end
end

function txt = leyes()
txt = {
    'FARADAY, de donde sale eind'
    '  La barra barre area entre los rieles, el flujo encerrado cambia'
    '  y aparece una tension inducida. eind = (v x B).l = B*l*v: crece'
    '  con la velocidad, y con nada mas.'
    ''
    'LORENTZ, de donde sale la fuerza'
    '  Sobre los portadores que circulan por la barra dentro del campo'
    '  aparece F = i*(l x B) = B*l*i. Es la fuerza que mueve la barra,'
    '  y depende de la corriente, no de la velocidad.'
    ''
    'LENZ, por que eind se OPONE'
    '  La tension inducida se opone al cambio que la genero, asi que'
    '  entra restando: i = (VB - eind)/R. Esa resta es lo unico que'
    '  limita la corriente. Con la barra quieta eind = 0 y la corriente'
    '  es VB/R entera: el pico de arranque. La resistencia de arranque'
    '  tapa ese hueco mientras eind es baja, y despues sobra.'
    ''
    'BALANCE'
    '  Pbat = PR + Pmec. La conversion electromecanica no pierde nada:'
    '  eind*i = F*v siempre. Toda la perdida esta en R.'
    };
end

%% ======================================================================
%  SIMULACION
%% ======================================================================
function P = simular(E)
% Corre el caso y, aparte, el MISMO caso sin resistencia de arranque,
% para poder superponerlos.
d = rmfield(E, 'v0');  d.v0 = E.v0;
if ~isfield(d,'tf') || isempty(d.tf)
    Bl = E.B*E.l;
    d.tf = 6*E.m*max(abs(E.R + E.Rarr), eps)/Bl^2;
end
[P.t, P.v, P.i, P.F, P.n] = IE.trayLineal(d);

dsin = d;  dsin.Rarr = 0;  dsin.tarr = Inf;
[~, P.vSin, P.iSin] = IE.trayLineal(dsin);

P.x    = cumtrapz(P.t, P.v);            % posicion de la barra [m]
P.eind = E.B*E.l*P.v;
P.Pbat = E.VB*P.i;
P.PR   = P.i.^2 .* P.n.Rv;
P.Pmec = P.F .* P.v;
P.Pconv= P.eind .* P.i;
P.errBal  = max(abs(P.Pbat - P.PR - P.Pmec));
P.errConv = max(abs(P.Pconv - P.Pmec));

e = E;  e = rmfield(e, {'Rarr','tarr','v0'});
if isfield(e,'tf'), e = rmfield(e,'tf'); end
P.ss = IE.lineal(e);
end

%% ======================================================================
%  TEMA CLARO
%% ======================================================================
function ejeClaro(ax)
% Con el tema oscuro de MATLAB los ejes NO heredan el 'Color','w' de la
% figura, y ni el titulo ni las etiquetas ni los text() heredan el negro.
% Hay que fijarlos objeto por objeto o salen gris sobre blanco.
set(ax, 'Color','w', 'XColor','k', 'YColor','k', 'GridColor',[0.8 0.8 0.8]);
set([ax.Title ax.XLabel ax.YLabel], 'Color','k');
end

function legClaro(lg)
set(lg, 'Color','w', 'TextColor','k', 'EdgeColor',[0.75 0.75 0.75]);
end

%% ======================================================================
%  DIBUJO DEL ESQUEMA
%% ======================================================================
function h = esquemaCrear(ax, E)
% Rieles, campo y barra. Handles persistentes: despues solo se mueven.
cla(ax); hold(ax,'on');
ejeClaro(ax);  set(ax, 'Box','on');
L = E.l;
xlim(ax, [-0.15*L, 1.35*L]);  ylim(ax, [-0.35*L, 1.25*L]);
axis(ax, 'equal');  ax.XTick = [];  ax.YTick = [];

% Rieles
plot(ax, [-0.15*L 1.35*L], [0 0], 'k-', 'LineWidth', 2);
plot(ax, [-0.15*L 1.35*L], [L L], 'k-', 'LineWidth', 2);
% Bateria a la izquierda
plot(ax, [-0.15*L -0.15*L], [0 L], 'k-', 'LineWidth', 1.2);
text(ax, -0.14*L, 0.5*L, 'VB', 'FontWeight','bold', 'Color',[0 0 0.7]);

% Marcas del campo: x entrando, o saliendo
[gx, gy] = meshgrid(linspace(0.05*L, 1.3*L, 7), linspace(0.12*L, 0.88*L, 3));
h.campo = plot(ax, gx(:), gy(:), 'x', 'Color',[0.45 0.45 0.45], ...
    'MarkerSize', 7, 'LineWidth', 1.1);
h.campoTxt = text(ax, 0.62*L, 1.12*L, '', 'HorizontalAlignment','center', ...
    'Color',[0.25 0.25 0.25], 'FontSize', 9);
title(ax, 'Esquema', 'Color','k');

% Barra y vectores. quiver con AutoScale off: el largo lo fija el dato.
h.barra = plot(ax, [0 0], [0 L], '-', 'Color',[0 0.35 0.8], 'LineWidth', 4);
h.vF = quiver(ax, 0, 0.5*L, 0, 0, 0, 'Color',[0.85 0.1 0.1], ...
    'LineWidth', 2, 'MaxHeadSize', 0.6);
h.vV = quiver(ax, 0, 0.82*L, 0, 0, 0, 'Color',[0 0.55 0.2], ...
    'LineWidth', 2, 'MaxHeadSize', 0.6);
h.vI = quiver(ax, 0, 0.18*L, 0, 0, 0, 'Color',[0.9 0.5 0], ...
    'LineWidth', 2, 'MaxHeadSize', 0.6);
h.tF = text(ax, 0, 0.5*L,  '', 'Color',[0.85 0.1 0.1], 'FontSize', 9);
h.tV = text(ax, 0, 0.82*L, '', 'Color',[0 0.55 0.2],  'FontSize', 9);
h.tI = text(ax, 0, 0.18*L, '', 'Color',[0.9 0.5 0],   'FontSize', 9);
h.tE = text(ax, 0, -0.18*L, '', 'FontSize', 9, 'FontWeight','bold', ...
    'Color','k');
h.ax = ax;  h.L = L;
hold(ax,'off');
end

function esquemaActualizar(h, E, P, k)
% Mueve la barra y reescala los vectores al instante k.
L = h.L;
% La barra recorre cientos de metros y el cuadro mide ~1.3*l. Se dibuja la
% posicion RELATIVA al recorrido de la corrida, no en metros absolutos:
% recortarla contra el borde la dejaba clavada ahi.
xr = P.x - min(P.x);
if max(xr) > eps, frac = xr(k)/max(xr); else, frac = 0; end
xb = 0.08*L + 1.12*L*frac;
set(h.barra, 'XData', [xb xb], 'YData', [0 L]);

if E.B >= 0
    set(h.campo, 'Marker','o', 'MarkerSize',5);
    set(h.campoTxt, 'String', 'B saliendo del plano');
else
    set(h.campo, 'Marker','x', 'MarkerSize',7);
    set(h.campoTxt, 'String', 'B entrando al plano');
end

% Escalas: cada vector se normaliza contra su propio maximo de la corrida
esc = @(u, umax) 0.42*L*u/max(umax, eps);
sF = esc(P.F(k), max(abs(P.F)));
sV = esc(P.v(k), max(abs(P.v)));
sI = esc(P.i(k), max(abs(P.i)));
set(h.vF, 'XData', xb, 'YData', 0.5*L,  'UData', sF, 'VData', 0);
set(h.vV, 'XData', xb, 'YData', 0.82*L, 'UData', sV, 'VData', 0);
% La corriente va POR la barra: vertical, no horizontal
set(h.vI, 'XData', xb, 'YData', 0.18*L, 'UData', 0, 'VData', sI);

set(h.tF, 'Position', [xb + sign0(sF)*0.06*L, 0.56*L], ...
    'String', sprintf('F = %.1f N', P.F(k)));
set(h.tV, 'Position', [xb + sign0(sV)*0.06*L, 0.88*L], ...
    'String', sprintf('v = %.1f m/s', P.v(k)));
set(h.tI, 'Position', [xb + 0.04*L, 0.30*L], ...
    'String', sprintf('i = %.1f A', P.i(k)));
set(h.tE, 'Position', [-0.10*L, -0.22*L], 'String', ...
    sprintf('eind = %.1f V   (VB = %.0f V)   Pbat = %.0f W', ...
    P.eind(k), E.VB, P.Pbat(k)));
end

function s = sign0(u)
s = sign(u);  if s == 0, s = 1; end
end

%% ======================================================================
%  CURVAS
%% ======================================================================
function curvas(axV, axI, axP, E, P)
cla(axV); hold(axV,'on');
plot(axV, P.t, P.v, 'LineWidth', 1.5, 'Color',[0 0.35 0.8]);
yline(axV, double(P.ss.v), '--', 'estacionario', 'Color',[0.4 0.4 0.4], ...
    'LabelHorizontalAlignment','left');
grid(axV,'on'); ylabel(axV,'v [m/s]'); title(axV,'Velocidad');
ejeClaro(axV);  hold(axV,'off');

cla(axI); hold(axI,'on');
if E.Rarr > 0
    plot(axI, P.t, P.iSin, ':', 'LineWidth', 1.3, 'Color',[0.75 0.4 0.4]);
end
plot(axI, P.t, P.i, 'LineWidth', 1.5, 'Color',[0.9 0.5 0]);
[pk, kp] = max(abs(P.i));
plot(axI, P.t(kp), P.i(kp), 'kv', 'MarkerFaceColor','k', 'MarkerSize', 6);
% La etiqueta del pico se corre hacia adentro, y si el pico cae en el
% tramo final se pone a la IZQUIERDA o se sale del cuadro.
dt = max(P.t) - min(P.t);
if P.t(kp) > 0.65*max(P.t)
    text(axI, P.t(kp) - 0.04*dt, P.i(kp), sprintf('pico %.0f A ', pk), ...
        'FontSize', 8, 'Color','k', 'HorizontalAlignment','right', ...
        'VerticalAlignment','top');
else
    text(axI, P.t(kp) + 0.04*dt, P.i(kp), sprintf(' pico %.0f A', pk), ...
        'FontSize', 8, 'Color','k', 'VerticalAlignment','top');
end
if E.Rarr > 0
    legClaro(legend(axI, {'sin Rarr','con Rarr','pico'}, 'Location','best'));
end
grid(axI,'on'); ylabel(axI,'i [A]'); title(axI,'Corriente');
ejeClaro(axI);  hold(axI,'off');

cla(axP); hold(axP,'on');
plot(axP, P.t, P.Pbat, 'LineWidth', 1.4, 'Color',[0 0 0.7]);
plot(axP, P.t, P.PR,   'LineWidth', 1.4, 'Color',[0.85 0.1 0.1]);
plot(axP, P.t, P.Pmec, 'LineWidth', 1.4, 'Color',[0 0.55 0.2]);
legClaro(legend(axP, {'bateria','en R','mecanica'}, 'Location','northeast'));
grid(axP,'on'); xlabel(axP,'t [s]'); ylabel(axP,'P [W]');
title(axP, sprintf(['Balance   (Pbat-PR-Pmec: %.1e W,   ' ...
    'eind*i-F*v: %.1e W)'], P.errBal, P.errConv));
ejeClaro(axP);  hold(axP,'off');
end

%% ======================================================================
%  INTERFAZ
%% ======================================================================
function construir()
[E, expl] = preset(1);
P = simular(E);

f = figure('Name','Maquina lineal de cd','Color','w', ...
    'Position',[80 60 1240 780], 'NumberTitle','off');

axEsq = axes('Parent',f, 'Position',[0.27 0.56 0.45 0.40]);
axV   = axes('Parent',f, 'Position',[0.77 0.78 0.21 0.18]);
axI   = axes('Parent',f, 'Position',[0.77 0.55 0.21 0.18]);
axP   = axes('Parent',f, 'Position',[0.27 0.33 0.71 0.17]);

pC = uipanel('Parent',f, 'Title','Controles', 'BackgroundColor','w', ...
    'ForegroundColor','k', 'Position',[0.01 0.33 0.24 0.63]);
pE = uipanel('Parent',f, 'Title','Que ley actua', 'BackgroundColor','w', ...
    'ForegroundColor','k', 'Position',[0.01 0.01 0.98 0.30]);

txtExpl = uicontrol('Parent',pE, 'Style','edit', 'Max',2, 'Min',0, ...
    'Enable','inactive', 'HorizontalAlignment','left', ...
    'BackgroundColor','w', 'ForegroundColor','k', 'FontName','monospaced', ...
    'FontSize',9, 'Units','normalized', 'Position',[0.01 0.02 0.98 0.94], ...
    'String',[{expl}; {''}; leyes()]);

S = struct('E',E, 'P',P, 'f',f, 'axEsq',axEsq, 'axV',axV, 'axI',axI, ...
    'axP',axP, 'txt',txtExpl, 'h',[], 'tmr',[]);
S.h = esquemaCrear(axEsq, E);
guidata(f, S);

y = 0.93;  dy = 0.088;
mkPopup(pC, y, 'Preset', {'1 arranque en vacio','2 motor cargado', ...
    '3 generador','4 frenado','5 campo invertido', ...
    '6 resistencia de arranque'}, @cbPreset);
y = y - dy;
mkSlider(pC, y, 'VB [V]',      -240,  240, E.VB,     'VB');      y = y - dy;
mkSlider(pC, y, 'R [ohm]',      0.05,   3, E.R,      'R');       y = y - dy;
mkSlider(pC, y, 'B [T]',       -0.5,  0.5, E.B,      'B');       y = y - dy;
mkSlider(pC, y, 'l [m]',          1,   20, E.l,      'l');       y = y - dy;
mkSlider(pC, y, 'm [kg]',         1,   50, E.m,      'm');       y = y - dy;
mkSlider(pC, y, 'Fcarga [N]',  -600,  600, E.Fcarga, 'Fcarga');  y = y - dy;
mkSlider(pC, y, 'Rarr [ohm]',     0,    5, E.Rarr,   'Rarr');    y = y - dy;
mkSlider(pC, y, 'quitar Rarr en t [s]', 0, 60, 30,   'tarr');    y = y - dy;

uicontrol('Parent',pC, 'Style','pushbutton', 'String','Animar', ...
    'Units','normalized', 'Position',[0.08 y 0.38 0.06], ...
    'BackgroundColor',[0.92 0.92 0.92], 'ForegroundColor','k', ...
    'Callback',@cbAnimar);
uicontrol('Parent',pC, 'Style','pushbutton', 'String','Parar', ...
    'Units','normalized', 'Position',[0.52 y 0.38 0.06], ...
    'BackgroundColor',[0.92 0.92 0.92], 'ForegroundColor','k', ...
    'Callback',@cbParar);

refrescar(f);
end

function mkSlider(p, y, etiq, lo, hi, val, campo)
uicontrol('Parent',p, 'Style','text', 'String',etiq, ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'HorizontalAlignment','left', 'Units','normalized', ...
    'Position',[0.05 y+0.035 0.60 0.035]);
h = uicontrol('Parent',p, 'Style','text', 'String',num2str(val,'%.4g'), ...
    'BackgroundColor','w', 'ForegroundColor',[0 0 0.7], ...
    'HorizontalAlignment','right', 'Units','normalized', ...
    'Position',[0.62 y+0.035 0.33 0.035]);
uicontrol('Parent',p, 'Style','slider', 'Min',lo, 'Max',hi, 'Value',val, ...
    'Units','normalized', 'Position',[0.05 y 0.90 0.032], ...
    'BackgroundColor',[0.95 0.95 0.95], ...
    'Callback',@(s,~) cbSlider(s, campo, h));
end

function mkPopup(p, y, etiq, items, cb)
uicontrol('Parent',p, 'Style','text', 'String',etiq, ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'HorizontalAlignment','left', 'Units','normalized', ...
    'Position',[0.05 y+0.035 0.90 0.035]);
uicontrol('Parent',p, 'Style','popupmenu', 'String',items, ...
    'BackgroundColor','w', 'ForegroundColor','k', ...
    'Units','normalized', 'Position',[0.05 y 0.90 0.035], 'Callback',cb);
end

function cbSlider(src, campo, hTxt)
f = ancestor(src,'figure');  S = guidata(f);
S.E.(campo) = src.Value;
if strcmp(campo,'tarr') && src.Value >= src.Max - eps
    S.E.tarr = Inf;
end
set(hTxt, 'String', num2str(src.Value,'%.4g'));
guidata(f, S);
refrescar(f);
end

function cbPreset(src, ~)
f = ancestor(src,'figure');  S = guidata(f);
[S.E, expl] = preset(src.Value);
set(S.txt, 'String', [{expl}; {''}; leyes()]);
guidata(f, S);
refrescar(f);
end

function refrescar(f)
S = guidata(f);
try
    S.P = simular(S.E);
catch ME
    title(S.axP, ['No se pudo simular: ' ME.message]);  return
end
S.h = esquemaCrear(S.axEsq, S.E);
esquemaActualizar(S.h, S.E, S.P, 1);
curvas(S.axV, S.axI, S.axP, S.E, S.P);
guidata(f, S);
end

function cbAnimar(src, ~)
f = ancestor(src,'figure');  S = guidata(f);
cbParar(src);
S.tmr = timer('ExecutionMode','fixedSpacing', 'Period',0.04, ...
    'TasksToExecute', 60, 'TimerFcn', @(t,~) paso(f, t));
guidata(f, S);
start(S.tmr);
end

function paso(f, t)
if ~isvalid(f), stop(t); delete(t); return, end
S = guidata(f);
k = 1 + round((t.TasksExecuted/t.TasksToExecute)*(numel(S.P.t)-1));
esquemaActualizar(S.h, S.E, S.P, min(k, numel(S.P.t)));
drawnow limitrate
end

function cbParar(src, ~)
f = ancestor(src,'figure');  S = guidata(f);
if ~isempty(S.tmr) && isvalid(S.tmr)
    stop(S.tmr);  delete(S.tmr);  S.tmr = [];  guidata(f, S);
end
end

%% ======================================================================
%  EXPORTAR: la via de verificacion headless
%% ======================================================================
function exportar()
carpeta = fileparts(mfilename('fullpath'));
for n = 1:6
    [E, expl] = preset(n);
    P = simular(E);
    f = figure('Visible','off', 'Color','w', 'Position',[0 0 1100 720]);
    axEsq = axes('Parent',f, 'Position',[0.06 0.60 0.55 0.36]);
    axV   = axes('Parent',f, 'Position',[0.70 0.78 0.27 0.18]);
    axI   = axes('Parent',f, 'Position',[0.70 0.55 0.27 0.18]);
    axP   = axes('Parent',f, 'Position',[0.06 0.28 0.91 0.20]);
    h = esquemaCrear(axEsq, E);
    kMed = round(numel(P.t)/6);
    esquemaActualizar(h, E, P, max(kMed,1));
    curvas(axV, axI, axP, E, P);
    annotation(f, 'textbox', [0.06 0.05 0.91 0.13], 'String', expl, ...
        'EdgeColor',[0.8 0.8 0.8], 'BackgroundColor','w', ...
        'Color','k', 'FontSize', 10, 'FitBoxToText','off', ...
        'VerticalAlignment','top');
    dest = fullfile(carpeta, sprintf('simLineal_preset%d.png', n));
    exportgraphics(f, dest, 'Resolution', 110);
    close(f);
    fprintf('preset %d: pico |i| = %7.1f A, v final = %8.2f m/s, %s\n', ...
        n, max(abs(P.i)), P.v(end), dest);
    fprintf('   balance Pbat-PR-Pmec = %.2e W, eind*i-F*v = %.2e W\n', ...
        P.errBal, P.errConv);
end
end
