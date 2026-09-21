function guiaIE(accion)
%GUIAIE Lanzador de la guia de estudio de Electrica II.
%
%   guiaIE            abre el menu
%   guiaIE('listar')  imprime que componentes hay y cuales faltan
%
% Cada componente corre tambien por separado: simLineal y quizIE no
% necesitan pasar por aca.

    if nargin < 1, accion = 'abrir'; end
    switch lower(accion)
        case 'abrir',  abrirUI();
        case 'listar', listar();
        otherwise
            error('IE:accion', 'Accion "%s": usa abrir o listar.', accion);
    end
end

function C = componentes()
% Cada fila: nombre visible, comando, y si esta construido.
C = { ...
    'Maquina lineal de cd',      'simLineal',  true,  ...
        'Barra sobre rieles: arranque, motor, generador, frenado.'
    'Quiz de teoria',            'quizIE',     true,  ...
        '72 preguntas de transformadores, con repaso de las falladas.'
    'Conexiones trifasicas',     'simTrifasico', true, ...
        'Fasores y desfase de Y-Y, D-D, Y-D, D-Y, Y-Z y D-Z.'
    'Perdidas en transformador', 'simPerdidas', true, ...
        'Circuito equivalente, balance de perdidas y rendimiento maximo.'
    };
end

function listar()
C = componentes();
fprintf('\nGuia de estudio de Electrica II\n');
fprintf('-------------------------------------------------------------\n');
for k = 1:size(C,1)
    if C{k,3}, estado = 'listo    '; else, estado = 'pendiente'; end
    fprintf('  [%s]  %-28s %s\n', estado, C{k,1}, C{k,2});
    fprintf('                 %s\n', C{k,4});
end
fprintf('-------------------------------------------------------------\n');
end

function abrirUI()
C = componentes();
n = size(C,1);
f = figure('Name','Guia de estudio - Electrica II', 'Color','w', ...
    'Position',[200 220 560 120+90*n], 'NumberTitle','off', 'MenuBar','none');

uicontrol('Parent',f, 'Style','text', 'String', ...
    'Guia de estudio - Ingenieria Electrica II', ...
    'BackgroundColor','w', 'ForegroundColor','k', 'FontSize',13, ...
    'FontWeight','bold', 'Units','normalized', ...
    'Position',[0.05 0.88 0.90 0.08]);

for k = 1:n
    y = 0.84 - k*(0.80/n);
    b = uicontrol('Parent',f, 'Style','pushbutton', 'String',C{k,1}, ...
        'BackgroundColor',[0.90 0.92 0.98], 'ForegroundColor','k', ...
        'FontSize',10, 'Units','normalized', ...
        'Position',[0.05 y 0.42 0.09], 'Callback',@(~,~) lanzar(C{k,2}));
    if ~C{k,3}
        set(b, 'Enable','off', 'BackgroundColor',[0.93 0.93 0.93]);
    end
    uicontrol('Parent',f, 'Style','text', 'String',C{k,4}, ...
        'BackgroundColor','w', 'ForegroundColor',[0.25 0.25 0.25], ...
        'FontSize',8, 'HorizontalAlignment','left', 'Units','normalized', ...
        'Position',[0.49 y-0.005 0.47 0.09]);
end
end

function lanzar(cmd)
try
    feval(cmd);
catch ME
    errordlg(ME.message, 'No se pudo abrir');
end
end
