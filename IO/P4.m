%   Max U = 30*x1 + 20*x2 + 25*x3
c1 = [2 3];
c2 = [2 4 3];
c3 = [3 4 5];

%% 4. Restricciones 1
A1 = [-3 1;
    4 2;
    4 -1;
    -1 2;
    1 0
    0 1];
b1 = [1;
    20;
    10;
    5;
    0;
    0];
sentido1 = {'<=', '<=', '<=', '<=', '>=', '>='};

%% 5-9. Resolver e interpretar
sol1 = solver(c1, A1, b1, sentido1, 'max');

fprintf('\nx1 = %.2f, x2 = %.2f -> U max = %.2f\n', ...
    sol1.xOpt(1), sol1.xOpt(2), sol1.valorOpt);

%% 4. Restricciones 2
A2 = [1 3 2;
    1 1 1;
    3 5 3;
    1 0 0;
    0 1 0
    0 0 1];
b2 = [30;
    24;
    60;
    0;
    0;
    0];
sentido2 = {'<=', '<=', '<=', '>=', '>=', '>='};

%% 5-9. Resolver e interpretar
sol2 = solver(c2, A2, b2, sentido2, 'max', 'Enteras', 'todas');   % variables ENTERAS
% sol2 = solver(c2, A2, b2, sentido2, 'max');                     % variables CONTINUAS (default)

fprintf('\nx1 = %.2f, x2 = %.2f, x3 = %.2f -> U max = %.2f\n', ...
    sol2.xOpt(1), sol2.xOpt(2), sol2.xOpt(3), sol2.valorOpt);

%% 4. Restricciones 3
A3 = [3 1 5;
    1 4 1;
    2 0 2;
    1 0 0;
    0 1 0
    0 0 1];
b3 = [150;
    120;
    105;
    0;
    0;
    0];
sentido3 = {'<=', '<=', '<=', '>=', '>=', '>='};

%% 5-9. Resolver e interpretar
sol3 = solver(c3, A3, b3, sentido3, 'max', 'Enteras', 'todas');   % variables ENTERAS
% sol2 = solver(c2, A2, b2, sentido2, 'max');                     % variables CONTINUAS (default)

fprintf('\nx1 = %.2f, x2 = %.2f, x3 = %.2f -> U max = %.2f\n', ...
    sol3.xOpt(1), sol3.xOpt(2), sol3.xOpt(3), sol3.valorOpt);