% testSolver — suite de regresión de solver.m. Correr con: testSolver
% Cada línea imprime true/false. Todo debe dar true.
% solver.m vive en la raíz de MATLAB (userpath), así que se ve desde cualquier
% carpeta. La carpeta IO se agrega acá solo para contrastar contra IO.pl2var.
addpath(fullfile(fileparts(mfilename('fullpath')), 'IO'));
hayIO = exist('IO','class') == 8;
ok  = @(n,c) fprintf('%-40s %s\n', n, string(c));
tol = @(a,b) abs(a-b) <= 1e-6*max(1,abs(b));
V   = {'Verbose', false};

%% 1 mesas y sillas: mismo resultado que IO.pl2var, pero por simplex
c = [50 80];  A = [1 2; 1 1];  b = [120; 90];
s = solver(c, A, b, {'<=','<='}, 'max', V{:});
ok('mesas/sillas estado optimo', strcmp(s.estado,'optimo'));
ok('mesas/sillas x = (60,30)',   all(tol(s.xOpt, [60 30])));
ok('mesas/sillas U = 5400',      tol(s.valorOpt, 5400));
ok('mesas/sillas ambas activas', all(s.activas));
ok('mesas/sillas holguras = 0',  all(tol(s.holguras, [0;0])));
ok('mesas/sillas precios (30,20)', all(tol(s.precioSombra, [30;20])));
ok('mesas/sillas costos reduc 0',  all(tol(s.costoReducido, [0 0])));

% coincide con el método gráfico de IO.pl2var
if hayIO
    g = IO.pl2var(c, A, b, {'<=','<='}, 'max', 'Graficar', false);
    ok('coincide con IO.pl2var (max)', all(tol(s.xOpt, g.xOpt)) && tol(s.valorOpt, g.valorOpt));
end

%% 2 mezcla de materias primas (IOprogralineal): minimización con >=
c2 = [30 20];  A2 = [2 1; 1 3];  b2 = [60; 75];
s2 = solver(c2, A2, b2, '>=', 'min', V{:});
ok('mezcla x = (21,18)',   all(tol(s2.xOpt, [21 18])));
ok('mezcla U = 990',       tol(s2.valorOpt, 990));
ok('mezcla precios (14,2)', all(tol(s2.precioSombra, [14;2])));
if hayIO
    g2 = IO.pl2var(c2, A2, b2, {'>=','>='}, 'min', 'Graficar', false);
    ok('coincide con IO.pl2var (min)', all(tol(s2.xOpt, g2.xOpt)) && tol(s2.valorOpt, g2.valorOpt));
end

%% 3 el precio sombra es de verdad dz/db (control por diferencias finitas)
d = 1e-4;
for i = 1:2
    bp = b;  bp(i) = bp(i) + d;
    sp = solver(c, A, bp, {'<=','<='}, 'max', V{:});
    ok(sprintf('precio sombra R%d = dU/db (max)',i), ...
        tol((sp.valorOpt - s.valorOpt)/d, s.precioSombra(i)));
    bp = b2;  bp(i) = bp(i) + d;
    sp = solver(c2, A2, bp, '>=', 'min', V{:});
    ok(sprintf('precio sombra R%d = dU/db (min)',i), ...
        tol((sp.valorOpt - s2.valorOpt)/d, s2.precioSombra(i)));
end

%% 4 tres variables, una no conviene usarla -> costo reducido no nulo
c3 = [30 20 5];  A3 = [2 1 1; 1 3 1];  b3 = [100; 90];
s3 = solver(c3, A3, b3, '<=', 'max', V{:});
ok('3 var: x3 no se usa',        tol(s3.xOpt(3), 0));
ok('3 var: costo reduc x3 < 0',  s3.costoReducido(3) < -1e-6);
ok('3 var: costos reduc basicas 0', all(tol(s3.costoReducido(1:2), [0 0])));
ok('3 var: factible',            all(A3*s3.xOpt' <= b3 + 1e-9));
% el costo reducido dice cuánto empeora U si se fuerza una unidad de x3
sf = solver(c3, A3, b3, '<=', 'max', 'lb', [0 0 1], V{:});
ok('3 var: forzar x3=1 cuesta el costo reducido', ...
    tol(sf.valorOpt - s3.valorOpt, s3.costoReducido(3)));

%% 5 restricciones de igualdad y mezcla de sentidos
c4 = [4 3 2];
A4 = [1 1 1; 2 1 0; 0 1 3];
b4 = [10; 8; 6];
s4 = solver(c4, A4, b4, {'=','<=','>='}, 'max', V{:});
ok('igualdad se cumple exacta', tol(A4(1,:)*s4.xOpt', 10));
ok('<= se cumple',              A4(2,:)*s4.xOpt' <= 8 + 1e-9);
ok('>= se cumple',              A4(3,:)*s4.xOpt' >= 6 - 1e-9);
ok('holgura de la igualdad = 0', tol(s4.holguras(1), 0));

%% 6 sin solución factible y sin cota
si = solver([1 1], [1 0; 1 0], [1; 2], {'<=','>='}, 'max', V{:});
ok('infactible detectado',  strcmp(si.estado,'infactible'));
ok('infactible da NaN',     all(isnan(si.xOpt)));
su = solver([1 1], [1 -1], 0, '<=', 'max', V{:});
ok('no acotado detectado',  strcmp(su.estado,'noAcotado'));

%% 7 variables enteras: mochila binaria
valor = [60 100 120];  peso = [10 20 30];
sm = solver(valor, peso, 50, '<=', 'max', 'Binarias', 'todas', V{:});
ok('mochila x = (0,1,1)', all(tol(sm.xOpt, [0 1 1])));
ok('mochila U = 220',     tol(sm.valorOpt, 220));
ok('mochila peso <= 50',  peso*sm.xOpt' <= 50 + 1e-9);
ok('mochila sin sensibilidad', all(isnan(sm.precioSombra)));

% entera pura: el óptimo entero nunca supera al de la relajación
ce = [5 4];  Ae = [6 4; 1 2];  be = [24; 6];
sr = solver(ce, Ae, be, '<=', 'max', V{:});
se = solver(ce, Ae, be, '<=', 'max', 'Enteras', 'todas', V{:});
ok('entera <= relajacion',   se.valorOpt <= sr.valorOpt + 1e-9);
ok('entera da enteros',      all(tol(se.xOpt, round(se.xOpt))));
ok('entera factible',        all(Ae*se.xOpt' <= be + 1e-9));
ok('entera U = 20 en (4,0)',  tol(se.valorOpt, 20) && all(tol(se.xOpt,[4 0])));

%% 8 cotas: lb, ub y variable libre
sb = solver([1 1], [1 1], 10, '<=', 'max', 'lb', [2 3], 'ub', [4 8], V{:});
ok('respeta lb',        all(sb.xOpt >= [2 3] - 1e-9));
ok('respeta ub',        all(sb.xOpt <= [4 8] + 1e-9));
ok('cotas: U = 10',     tol(sb.valorOpt, 10));
sl = solver([1 -1], [1 1], 4, '=', 'min', 'lb', [-Inf -Inf], 'ub', [10 10], V{:});
ok('variable libre: x2 = 10', tol(sl.xOpt(2), 10));
ok('variable libre: x1 = -6', tol(sl.xOpt(1), -6));
ok('variable libre: U = -16',  tol(sl.valorOpt, -16));

%% 9 "Valor de:" de Excel — objetivo igual a un número dado
sv = solver([1 1], [1 1], 10, '<=', 7, V{:});
ok('valor de 7: alcanzado',  tol(sv.valorOpt, 7));
ok('valor de 7: factible',   sum(sv.xOpt) <= 10 + 1e-9);
svi = solver([1 1], [1 1], 10, '<=', 25, V{:});
ok('valor de 25: infactible', strcmp(svi.estado,'infactible'));

%% 10 filas redundantes y degeneración: no debe romper ni colgarse
Ad = [1 1; 2 2; 1 0];      % la fila 2 es la 1 multiplicada por 2
sd = solver([1 1], Ad, [10; 20; 4], '<=', 'max', V{:});
ok('redundante: U = 10',   tol(sd.valorOpt, 10));
ok('redundante: factible', all(Ad*sd.xOpt' <= [10;20;4] + 1e-9));

%% 11 b negativo del lado derecho (obliga a dar vuelta la fila)
sn = solver([1 1], [-1 -1; 1 0], [-5; 8], {'<=','<='}, 'min', V{:});
ok('b negativo: suma = 5',  tol(sum(sn.xOpt), 5));
ok('b negativo: U = 5',     tol(sn.valorOpt, 5));

%% 12 sin restricciones (solo cotas)
s0 = solver([2 3], [], [], '<=', 'max', 'ub', [5 5], V{:});
ok('sin restricciones: x = (5,5)', all(tol(s0.xOpt, [5 5])));
ok('sin restricciones: U = 25',    tol(s0.valorOpt, 25));

%% 13 sentido escrito de varias formas y errores de entrada
sa = solver([1 1], [1 1], 5, '<', 'max', V{:});
ok('acepta "<" como "<="', tol(sa.valorOpt, 5));
err = @(f) ~isempty(regexp(evalErr(f), '^solver:', 'once'));
ok('error de dimension',   err(@() solver([1 1], [1 1 1], 5, '<=', 'max', V{:})));
ok('error de sentido',     err(@() solver([1 1], [1 1], 5, '!=', 'max', V{:})));
ok('error de cotas',       err(@() solver([1 1], [1 1], 5, '<=', 'max', 'lb', [3 3], 'ub', [1 1], V{:})));

%% 14 contraste contra linprog, si el Optimization Toolbox está instalado
if exist('linprog','file') == 2
    opt = optimoptions('linprog','Display','none');
    xl  = linprog(-c, A, b, [], [], zeros(2,1), [], opt);
    ok('coincide con linprog', all(tol(s.xOpt(:), xl)));
else
    fprintf('%-40s %s\n', 'linprog no instalado (se omite)', "-");
end

function msg = evalErr(f)
% Devuelve el identificador del error que tira f, o '' si no tira ninguno.
try
    f();  msg = '';
catch e
    msg = e.identifier;
end
end
