function varargout = quizIE(accion, varargin)
%QUIZIE Motor de quiz sobre el banco de IE/bancoIE.m.
%
%   quizIE                    abre la interfaz
%   quizIE('consola', n)      n preguntas por la ventana de comandos
%   quizIE('estado')          devuelve el historial acumulado
%   quizIE('resumen')         tabla de aciertos y errores por tema
%   quizIE('reiniciar')       borra el historial
%   quizIE('temas')           lista de temas del banco
%
% El historial vive en quizIE_estado.mat, al lado de este archivo, y
% sobrevive entre sesiones. No se versiona: es progreso personal.
%
% SEPARACION: el motor (elegir, registrar, resumen, persistencia) son
% funciones puras que no dibujan nada, asi que se pueden probar sin
% pantalla. La interfaz es una capa encima. Ver testQuiz.m.
%
% PREGUNTAS CON BANDERA: el banco marca las respuestas del cuestionario
% que son tecnicamente discutibles. El quiz las califica como BUENAS,
% porque es lo que espera el examen, y muestra la advertencia con lo que
% dice la teoria. Esa es la regla de autoridad: en el quiz manda el
% cuestionario, en los simuladores manda la fisica.

    if nargin < 1, accion = 'abrir'; end
    switch lower(accion)
        case 'abrir',     abrirUI();
        case 'consola',   consola(varargin{:});
        case 'estado',    varargout{1} = cargarEstado();
        case 'resumen',   varargout{1} = resumen();
        case 'reiniciar', reiniciar();  fprintf('Historial borrado.\n');
        case 'temas',     varargout{1} = temas();
        case 'elegir',    varargout{1} = elegir(varargin{:});
        case 'registrar', varargout{1} = registrar(varargin{:});
        otherwise
            error('IE:accion', 'Accion "%s" desconocida.', accion);
    end
end

%% ======================================================================
%  PERSISTENCIA
%% ======================================================================
function r = rutaEstado()
r = fullfile(fileparts(mfilename('fullpath')), 'quizIE_estado.mat');
end

function E = cargarEstado()
r = rutaEstado();
if exist(r, 'file')
    d = load(r, 'E');
    E = d.E;
else
    E = struct('aciertos', struct(), 'errores', struct(), 'vistas', 0);
end
end

function guardarEstado(E)
save(rutaEstado(), 'E');
end

function reiniciar()
r = rutaEstado();
if exist(r, 'file'), delete(r); end
end

function E = registrar(E, id, ok)
% Suma un intento al contador que corresponda. Funcion pura sobre E.
campo = 'errores';
if ok, campo = 'aciertos'; end
if isfield(E.(campo), id)
    E.(campo).(id) = E.(campo).(id) + 1;
else
    E.(campo).(id) = 1;
end
E.vistas = E.vistas + 1;
end

%% ======================================================================
%  SELECCION
%% ======================================================================
function t = temas()
B = bancoIE();
t = unique({B.tema});
end

function k = elegir(B, E, tema, modo, previo)
% Devuelve el indice de la proxima pregunta.
%   tema  : nombre exacto del tema, o 'todos'
%   modo  : 'aleatorio' o 'falladas'
%   previo: indice de la anterior, para no repetirla seguida
if nargin < 5, previo = 0; end
cand = 1:numel(B);
if ~strcmpi(tema, 'todos')
    cand = cand(strcmp({B(cand).tema}, tema));
end
if isempty(cand)
    error('IE:sinPreguntas', 'Ninguna pregunta del tema "%s".', tema);
end

if strcmpi(modo, 'falladas')
    % Solo las que tienen algun error registrado, con peso proporcional a
    % cuantas veces se fallaron. Si no hay ninguna, se avisa cayendo al
    % modo aleatorio.
    fall = cand(arrayfun(@(j) isfield(E.errores, B(j).id) && ...
        E.errores.(B(j).id) > 0, cand));
    if ~isempty(fall)
        peso = arrayfun(@(j) E.errores.(B(j).id), fall);
        k = fall(find(rand*sum(peso) <= cumsum(peso), 1));
        return
    end
end

if numel(cand) > 1
    cand = cand(cand ~= previo);       % no repetir la anterior seguida
end
k = cand(randi(numel(cand)));
end

function T = resumen()
% Tabla por tema: cuantas preguntas hay, cuantos aciertos y errores
% acumulados, y el porcentaje.
B = bancoIE();  E = cargarEstado();
tt = temas();
n = numel(tt);
[preg, ac, er, pct] = deal(zeros(n,1));
for i = 1:n
    idx = find(strcmp({B.tema}, tt{i}));
    preg(i) = numel(idx);
    for j = idx
        if isfield(E.aciertos, B(j).id), ac(i) = ac(i) + E.aciertos.(B(j).id); end
        if isfield(E.errores,  B(j).id), er(i) = er(i) + E.errores.(B(j).id);  end
    end
    if ac(i) + er(i) > 0, pct(i) = 100*ac(i)/(ac(i)+er(i)); end
end
T = table(tt(:), preg, ac, er, pct, 'VariableNames', ...
    {'tema','preguntas','aciertos','errores','porcentaje'});
end

%% ======================================================================
%  MODO CONSOLA
%% ======================================================================
function consola(n, tema, respuestas)
% n preguntas por la ventana de comandos.
%   respuestas : opcional, vector de respuestas ya elegidas. Sirve para
%                probar el flujo sin pantalla ni teclado.
if nargin < 1 || isempty(n),    n = 5;         end
if nargin < 2 || isempty(tema), tema = 'todos'; end
auto = nargin >= 3 && ~isempty(respuestas);

B = bancoIE();  E = cargarEstado();  previo = 0;  bien = 0;
for q = 1:n
    k = elegir(B, E, tema, 'aleatorio', previo);  previo = k;
    fprintf('\n--- %d/%d  [%s | %s] ---\n%s\n', q, n, B(k).id, B(k).tema, ...
        B(k).enunciado);
    for j = 1:numel(B(k).opciones)
        fprintf('  %d) %s\n', j, B(k).opciones{j});
    end
    if auto
        r = respuestas(min(q, numel(respuestas)));
        fprintf('respuesta: %d\n', r);
    else
        r = input('Tu respuesta (1-4): ');
    end
    ok = isscalar(r) && isnumeric(r) && r == B(k).correcta;
    if ok, fprintf('CORRECTO.\n');  bien = bien + 1;
    else,  fprintf('INCORRECTO. La esperada es la %d.\n', B(k).correcta);
    end
    fprintf('%s\n', B(k).explicacion);
    if B(k).bandera
        fprintf('\n  [!] %s\n', B(k).advertencia);
    end
    E = registrar(E, B(k).id, ok);
end
guardarEstado(E);
fprintf('\nResultado: %d de %d.\n', bien, n);
end

%% ======================================================================
%  INTERFAZ
%% ======================================================================
function abrirUI()
B = bancoIE();  E = cargarEstado();

f = figure('Name','Quiz de Electrica II','Color','w', ...
    'Position',[120 100 900 640], 'NumberTitle','off', 'MenuBar','none');

S = struct('B',B, 'E',E, 'k',0, 'previo',0, 'respondida',false, ...
    'tema','todos', 'modo','aleatorio', 'sel',0);

pTop = uipanel('Parent',f, 'BackgroundColor','w', 'BorderType','none', ...
    'Position',[0.02 0.88 0.96 0.11]);
uicontrol('Parent',pTop, 'Style','text', 'String','Tema', ...
    'BackgroundColor','w', 'ForegroundColor','k', 'Units','normalized', ...
    'HorizontalAlignment','left', 'Position',[0 0.55 0.10 0.35]);
S.popTema = uicontrol('Parent',pTop, 'Style','popupmenu', ...
    'String',[{'todos'} temas()], 'BackgroundColor','w', ...
    'ForegroundColor','k', 'Units','normalized', ...
    'Position',[0 0.08 0.34 0.45], 'Callback',@cbTema);
uicontrol('Parent',pTop, 'Style','text', 'String','Modo', ...
    'BackgroundColor','w', 'ForegroundColor','k', 'Units','normalized', ...
    'HorizontalAlignment','left', 'Position',[0.37 0.55 0.10 0.35]);
S.popModo = uicontrol('Parent',pTop, 'Style','popupmenu', ...
    'String',{'aleatorio','repasar falladas'}, 'BackgroundColor','w', ...
    'ForegroundColor','k', 'Units','normalized', ...
    'Position',[0.37 0.08 0.24 0.45], 'Callback',@cbModo);
S.txtPunt = uicontrol('Parent',pTop, 'Style','text', 'String','', ...
    'BackgroundColor','w', 'ForegroundColor',[0 0 0.7], ...
    'FontWeight','bold', 'Units','normalized', ...
    'HorizontalAlignment','right', 'Position',[0.63 0.08 0.37 0.45]);

S.txtPreg = uicontrol('Parent',f, 'Style','text', 'String','', ...
    'BackgroundColor','w', 'ForegroundColor','k', 'FontSize',11, ...
    'FontWeight','bold', 'HorizontalAlignment','left', ...
    'Units','normalized', 'Position',[0.02 0.74 0.96 0.13]);

for j = 1:4
    S.btnOpc(j) = uicontrol('Parent',f, 'Style','togglebutton', ...
        'String','', 'BackgroundColor',[0.96 0.96 0.96], ...
        'ForegroundColor','k', 'HorizontalAlignment','left', ...
        'Units','normalized', 'Position',[0.02 0.655-0.075*j 0.96 0.065], ...
        'Callback',@(s,~) cbOpcion(s, j));
end

S.btnResp = uicontrol('Parent',f, 'Style','pushbutton', 'String','Responder', ...
    'BackgroundColor',[0.90 0.92 0.98], 'ForegroundColor','k', ...
    'Units','normalized', 'Position',[0.02 0.29 0.20 0.055], ...
    'Callback',@cbResponder);
S.btnSig = uicontrol('Parent',f, 'Style','pushbutton', 'String','Siguiente', ...
    'BackgroundColor',[0.92 0.92 0.92], 'ForegroundColor','k', ...
    'Units','normalized', 'Position',[0.24 0.29 0.20 0.055], ...
    'Callback',@cbSiguiente);
S.btnSim = uicontrol('Parent',f, 'Style','pushbutton', ...
    'String','Ver en el simulador', 'Enable','off', ...
    'BackgroundColor',[0.92 0.92 0.92], 'ForegroundColor','k', ...
    'Units','normalized', 'Position',[0.46 0.29 0.26 0.055], ...
    'Callback',@cbSimulador);
uicontrol('Parent',f, 'Style','pushbutton', 'String','Resumen', ...
    'BackgroundColor',[0.92 0.92 0.92], 'ForegroundColor','k', ...
    'Units','normalized', 'Position',[0.74 0.29 0.12 0.055], ...
    'Callback',@(~,~) disp(resumen()));
uicontrol('Parent',f, 'Style','pushbutton', 'String','Reiniciar', ...
    'BackgroundColor',[0.98 0.90 0.90], 'ForegroundColor','k', ...
    'Units','normalized', 'Position',[0.87 0.29 0.11 0.055], ...
    'Callback',@cbReiniciar);

S.txtFeed = uicontrol('Parent',f, 'Style','edit', 'Max',2, 'Min',0, ...
    'Enable','inactive', 'String','', 'HorizontalAlignment','left', ...
    'BackgroundColor','w', 'ForegroundColor','k', 'FontSize',9, ...
    'Units','normalized', 'Position',[0.02 0.02 0.96 0.25]);

guidata(f, S);
siguiente(f);
end

function cbTema(src, ~)
f = ancestor(src,'figure');  S = guidata(f);
items = src.String;  S.tema = items{src.Value};
guidata(f, S);  siguiente(f);
end

function cbModo(src, ~)
f = ancestor(src,'figure');  S = guidata(f);
if src.Value == 1, S.modo = 'aleatorio'; else, S.modo = 'falladas'; end
guidata(f, S);  siguiente(f);
end

function cbOpcion(src, j)
f = ancestor(src,'figure');  S = guidata(f);
if S.respondida, src.Value = (j == S.sel); return, end
S.sel = j;
for m = 1:4, S.btnOpc(m).Value = (m == j); end
guidata(f, S);
end

function siguiente(f)
S = guidata(f);
try
    S.k = elegir(S.B, S.E, S.tema, S.modo, S.previo);
catch ME
    set(S.txtFeed, 'String', ME.message);  return
end
S.previo = S.k;  S.respondida = false;  S.sel = 0;
b = S.B(S.k);
set(S.txtPreg, 'String', sprintf('[%s]  %s', b.tema, b.enunciado));
for j = 1:4
    set(S.btnOpc(j), 'String', ['  ' b.opciones{j}], 'Value',0, ...
        'BackgroundColor',[0.96 0.96 0.96], 'Enable','on');
end
set(S.txtFeed, 'String','');
set(S.btnSim, 'Enable','off');
set(S.txtPunt, 'String', sprintf('respondidas: %d', S.E.vistas));
guidata(f, S);
end

function cbResponder(src, ~)
f = ancestor(src,'figure');  S = guidata(f);
if S.respondida || S.sel == 0, return, end
b = S.B(S.k);
ok = (S.sel == b.correcta);
S.respondida = true;

set(S.btnOpc(b.correcta), 'BackgroundColor',[0.80 0.93 0.80]);
if ~ok
    set(S.btnOpc(S.sel), 'BackgroundColor',[0.96 0.80 0.80]);
end
for j = 1:4, set(S.btnOpc(j), 'Enable','inactive'); end

if ok, cab = 'CORRECTO.'; else, cab = 'INCORRECTO.'; end
lineas = {cab; ''; b.explicacion};
if b.bandera
    lineas = [lineas; {''; ['[!] ' b.advertencia]}];
    set(S.btnSim, 'Enable','on');
end
set(S.txtFeed, 'String', lineas);

S.E = registrar(S.E, b.id, ok);
guardarEstado(S.E);
set(S.txtPunt, 'String', sprintf('respondidas: %d', S.E.vistas));
guidata(f, S);
end

function cbSiguiente(src, ~)
siguiente(ancestor(src,'figure'));
end

function cbReiniciar(src, ~)
% Borra el historial. Pregunta antes: no se puede deshacer y el progreso
% acumulado es lo unico que el quiz guarda entre sesiones.
f = ancestor(src,'figure');  S = guidata(f);
if S.E.vistas == 0
    set(S.txtFeed, 'String', 'No hay progreso que borrar.');  return
end
resp = questdlg(sprintf(['Se van a borrar %d respuestas registradas y ' ...
    'el repaso de las falladas. No se puede deshacer.'], S.E.vistas), ...
    'Reiniciar progreso', 'Borrar', 'Cancelar', 'Cancelar');
if ~strcmp(resp, 'Borrar'), return, end
reiniciar();
S.E = struct('aciertos', struct(), 'errores', struct(), 'vistas', 0);
guidata(f, S);
set(S.txtPunt, 'String', 'respondidas: 0');
set(S.txtFeed, 'String', 'Historial borrado. Empezas de cero.');
siguiente(f);
end

function cbSimulador(src, ~)
% ENLACE QUIZ -> SIMULADOR. La advertencia de una pregunta con bandera
% lleva al simulador que explica el tema bien, que es la separacion que
% pide la guia: en el quiz manda el cuestionario, en el simulador la
% fisica. Si el tema no tiene simulador, se dice en vez de abrir
% cualquier cosa.
f = ancestor(src,'figure');  S = guidata(f);
b = S.B(S.k);
try
    switch b.tema
        case {'Conexiones trifasicas','Otras conexiones'}
            simTrifasico();
            destino = 'simTrifasico';
        otherwise
            destino = '';
    end
catch ME
    set(S.txtFeed, 'String', { ...
        ['No se pudo abrir el simulador: ' ME.message]; ''; b.advertencia});
    return
end
if isempty(destino)
    set(S.txtFeed, 'String', { ...
        ['Tema: ' b.tema]; ''; b.advertencia; ''; ...
        'Todavia no hay un simulador para este tema.'});
else
    set(S.txtFeed, 'String', { ...
        ['Tema: ' b.tema]; ''; b.advertencia; ''; ...
        ['Se abrio ' destino '. Elegi ahi la conexion de la pregunta y ' ...
        'mira el diagrama fasorial y el panel de ventajas.']});
end
end
