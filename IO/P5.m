%% P5 — Tres problemas de PL resueltos con solver.m
clear; clc

%% ==================================================================
%  PROBLEMA 1 — Perrera Heavenly Houd Kennels (mezcla de alimento)
%  Variables: onzas diarias de cada producto en grano
%    x1 = onzas de A,  x2 = onzas de B,  x3 = onzas de C
%  Costo: $/libra dividido entre 16 onzas -> $/onza
%  Min  U = 0.45/16*x1 + 0.38/16*x2 + 0.27/16*x3
%% ==================================================================
c1 = [0.45 0.38 0.27] / 16;

A1 = [0.62 0.55 0.36;      % proteínas (oz)
      0.05 0.10 0.20;      % carbohidratos (oz)
      0.03 0.02 0.01];     % grasas (oz)
b1 = [8; 1; 0.5];
sentido1 = {'>=', '>=', '<='};

sol1 = solver(c1, A1, b1, sentido1, 'min', ...
    'Nombres', {'A_oz','B_oz','C_oz'}, ...
    'EtiquetasRest', {'Proteina','Carbohid','Grasa'});

fprintf('\nP1: A = %.4f oz, B = %.4f oz, C = %.4f oz -> costo min = $%.4f\n', ...
    sol1.xOpt(1), sol1.xOpt(2), sol1.xOpt(3), sol1.valorOpt);

%% ==================================================================
%  PROBLEMA 2 — McNaughton Inc. (mezcla de salsas)
%  Variables: litros de cada ingrediente en cada salsa
%    x1 = A en Spicy Diablo   x2 = B en Spicy Diablo
%    x3 = A en Red Baron      x4 = B en Red Baron
%  Ganancia neta = precio de venta - costo del ingrediente
%    Spicy con A: 3.35 - 1.60 = 1.75      Spicy con B: 3.35 - 2.59 = 0.76
%    Red   con A: 2.85 - 1.60 = 1.25      Red   con B: 2.85 - 2.59 = 0.26
%  Max U = 1.75*x1 + 0.76*x2 + 1.25*x3 + 0.26*x4
%% ==================================================================
c2 = [3.35-1.60, 3.35-2.59, 2.85-1.60, 2.85-2.59];

A2 = [0.75 -0.25  0     0;      % A >= 25% de Spicy    -> 0.75x1 - 0.25x2 >= 0
     -0.50  0.50  0     0;      % B >= 50% de Spicy    -> -0.5x1 + 0.5x2 >= 0
      0     0     0.25 -0.75;   % A <= 75% de Red      -> 0.25x3 - 0.75x4 <= 0
      1     0     1     0;      % compra máxima de A
      0     1     0     1];     % compra máxima de B
b2 = [0; 0; 0; 40; 30];
sentido2 = {'>=', '>=', '<=', '<=', '<='};

sol2 = solver(c2, A2, b2, sentido2, 'max', ...
    'Nombres', {'A_Spicy','B_Spicy','A_Red','B_Red'}, ...
    'EtiquetasRest', {'%A Spicy','%B Spicy','%A Red','Compra A','Compra B'});

fprintf('\nP2: Spicy = %.2f L, Red Baron = %.2f L -> ganancia max = $%.2f\n', ...
    sol2.xOpt(1)+sol2.xOpt(2), sol2.xOpt(3)+sol2.xOpt(4), sol2.valorOpt);

%% ==================================================================
%  PROBLEMA 3 — Cuatro granjas, tres cultivos
%  Variables: hectáreas del cultivo j en la granja i (12 variables)
%    x = [x1A x1B x1C  x2A x2B x2C  x3A x3B x3C  x4A x4B x4C]
%  Max U = 500*(A) + 200*(B) + 300*(C)
%% ==================================================================
hect  = [500 900 300 700];        % hectáreas útiles por granja
horas = [1700 3000 900 2200];     % horas de trabajo por granja
maxH  = [700 800 300];            % hectáreas máximas por cultivo
hpH   = [2 4 3];                  % horas por hectárea de cada cultivo
gan   = [500 200 300];            % ganancia por hectárea de cada cultivo

c3 = repmat(gan, 1, 4);

nombres3 = {};
for i = 1:4
    for j = 'ABC', nombres3{end+1} = sprintf('x%d%s', i, j); end %#ok<SAGROW>
end

I4 = eye(4);

% Política: mismo PORCENTAJE de hectáreas plantadas en todas las granjas
%   (x1A+x1B+x1C)/500 = (x2A+x2B+x2C)/900 = (x3..)/300 = (x4..)/700
prop = zeros(3, 12);
for k = 1:3
    prop(k, 1:3)             =  1/hect(1);
    prop(k, 3*k+1 : 3*k+3)   = -1/hect(k+1);
end
A3 = [kron(I4, [1 1 1]);      % hectáreas disponibles por granja
      kron(I4, hpH);          % horas disponibles por granja
      repmat(eye(3), 1, 4);   % hectáreas máximas por cultivo
      prop];                  % carga de trabajo uniforme
b3 = [hect'; horas'; maxH'; zeros(3,1)];
sentido3 = [repmat({'<='}, 11, 1); repmat({'='}, 3, 1)];

etiq3 = {'Ha G1','Ha G2','Ha G3','Ha G4', ...
         'Hr G1','Hr G2','Hr G3','Hr G4', ...
         'Max A','Max B','Max C', 'Prop 1-2','Prop 1-3','Prop 1-4'};

sol3 = solver(c3, A3, b3, sentido3, 'max', ...
    'Nombres', nombres3, 'EtiquetasRest', etiq3);
% sol3 = solver(c3, A3, b3, sentido3, 'max', 'Nombres', nombres3, ...
%     'EtiquetasRest', etiq3, 'Enteras', 'todas');   % hectáreas ENTERAS

fprintf('\nP3: hectáreas por granja (filas) y cultivo (columnas A B C)\n');
disp(reshape(sol3.xOpt, 3, 4)');
fprintf('P3: ganancia max = $%.2f\n', sol3.valorOpt);
