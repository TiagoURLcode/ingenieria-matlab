% Analisis de un mecanismo de 4 barras segun el criterio de Grashof.
%
% Cada eslabon se define como [longitud, bancada, opuesto]:
%   longitud -> valor positivo
%   bancada  -> 1 si ese eslabon es la bancada (solo uno puede serlo)
%   opuesto  -> 1 si ese eslabon es el opuesto al mas corto (solo uno)

%s = [ 2, 0, 0];   % eslabon mas corto
%l = [7, 1,  0];   % eslabon mas largo
%p = [5, 0, 1];   % eslabon medio
%q = [ 6, 0, 0];   % eslabon medio

s = [17.39, 0, 0];
l = [91.8, 1,  0];
p = [88.08, 0, 0];
q = [31.13, 0, 1];
[grashof, clase, tipo] = eslabones(s, l, p, q);
[muMax, muMin] = AnguloTransmision(s, l, p, q);
[muMaxE, muMinE] = ExtremosTransmision(s, l, p, q);
function [grashof, clase, tipo] = eslabones(s, l, p, q)
    % grashof -> true si s+l <= p+q (clases I y II)
    % clase   -> 1: Grashof, 2: cambio de punto, 3: no Grashof (triple balancin)
    % tipo    -> string con la inversion; "no aplica" si no es Grashof

    tipo = "no aplica";   % valor por defecto: garantiza que siempre se asigne

    L       = [s(1) l(1) p(1) q(1)];
    bancada = [s(2) l(2) p(2) q(2)]
    opuesto = [s(3) l(3) p(3) q(3)]

    izquierdo = s(1) + l(1)
    derecho = p(1) + q(1)
    


    % -- Validacion de los datos de entrada --
    if any(L <= 0)
        error('Todas las longitudes deben ser positivas.');
    end
    if s(1) ~= min(L)
        error('El primer argumento debe ser el eslabon mas corto.');
    end
    if l(1) ~= max(L)
        error('El segundo argumento debe ser el eslabon mas largo.');
    end
    if ~all(ismember([bancada opuesto], [0 1]))
        error('Las marcas de bancada y opuesto solo pueden valer 0 o 1.');
    end
    if s(3) == 1
        error('El eslabon mas corto no puede ser opuesto de si mismo.');
    end
    if sum(bancada) ~= 1
        error('Debe haber exactamente un eslabon marcado como bancada.');
    end
    if sum(opuesto) ~= 1
        error('Debe haber exactamente un eslabon marcado como opuesto.');
    end

    % -- Criterio de Grashof: s + l <= p + q --
    if (s(1) + l(1)) < (p(1) + q(1))
        grashof = true;
        clase   = 1;
        fprintf('Clase I: Grashof\n');

    elseif (s(1) + l(1)) == (p(1) + q(1))
        % Caso limite: cumple Grashof, pero pasa por posiciones colineales
        grashof = true;
        clase   = 2;
        fprintf('Clase II: Grashof de cambio de punto\n');

    else
        grashof = false;
        clase   = 3;
        fprintf('Clase III: no Grashof, triple balancin\n');
    end

    % -- Inversion segun cual eslabon sea la bancada --
    if grashof
        if s(2) == 1 %si el pequeño es bancada
            tipo = "doble-manivela";
        elseif isequal(find(bancada), find(opuesto)) %si es bancada y manivela
            tipo = "doble-balancin";    % la bancada es el opuesto al mas corto
      
        else
            tipo = "manivela-balancin"; % la bancada es adyacente al mas corto
        end
        fprintf('Inversion: %s\n', tipo);

    end
   
end

%inicial = [c1 d1] posicion inicial de eslabon
%final = [c2 d2]

%function [s, l, p, q] = rotopolo(inicial, final)
  

%end

%angulo de transmision
function [maximo, minimo] = AnguloTransmision(s, l, p, q)
    L       = [s(1) l(1) p(1) q(1)];
    bancada = [s(2) l(2) p(2) q(2)];
    opuesto = [s(3) l(3) p(3) q(3)];
    triangulo = [l(2) p(2) q(3); l(3) p(2) q(3)];
    adyacente = find(~bancada & ~opuesto & (L ~= L(1))); %encuentra los que "no son ni bancada ni opuesto"==true y si L es no igual a el pequeño = true 

    %h1=h2 ley de cosenos
   
    maximo = rad2deg(acos((L(adyacente)^2+L(find(opuesto))^2-(L(find(bancada))+L(1))^2)/(2*L(adyacente)*L(find(opuesto)))))
    minimo = rad2deg(acos((L(adyacente)^2+L(find(opuesto))^2-(L(find(bancada))-L(1))^2)/(2*L(adyacente)*L(find(opuesto)))))
    fprintf('Angulo de transmision: %.2f a %.2f grados.\n', ...
        min(maximo,minimo), max(maximo,minimo));
    if min(maximo,minimo) < 40
        fprintf('Advertencia: mu < 40 grados, mala transmision.\n');
    end
  
    
end
    

% Angulos de transmision extremos de un cuadrilatero articulado.
%
% mu es el angulo que forman el acoplador y el eslabon de salida. Sus valores
% extremos aparecen cuando la manivela queda colineal con la bancada, en dos
% posiciones:
%   plegada   -> la manivela se superpone a la bancada, diagonal = d - a
%   extendida -> la manivela apunta al otro lado,       diagonal = d + a
% donde d es la bancada y a la manivela (aqui, el eslabon mas corto).
%
% Circuito abierto y cruzado dan el mismo mu: el acoplador y la salida forman
% con la diagonal dos triangulos congruentes (uno es el reflejo del otro
% respecto de la diagonal), asi que la ley de cosenos devuelve el mismo angulo.
% Por eso basta un solo par de extremos para las dos configuraciones.
function [muMax, muMin] = ExtremosTransmision(s, l, p, q)
    L       = [s(1) l(1) p(1) q(1)];   % longitudes de los cuatro eslabones
    bancada = [s(2) l(2) p(2) q(2)];   % 1 en el eslabon fijo
    opuesto = [s(3) l(3) p(3) q(3)];   % 1 en el eslabon opuesto al mas corto

    if sum(bancada) ~= 1
        error('Debe haber exactamente un eslabon marcado como bancada.');
    end
    if s(2) == 1
        error('Si el mas corto es la bancada hay dos manivelas: los datos no dicen cual es la entrada.');
    end
    if opuesto(bancada == 1) == 1
        error('La bancada es opuesta al mas corto: el mas corto es el acoplador y no hay manivela que gire.');
    end

    d = L(bancada == 1);               % bancada
    a = L(1);                          % manivela: el eslabon mas corto

    % Los dos eslabones que quedan (acoplador y salida) cierran el triangulo
    % con la diagonal. La ley de cosenos es simetrica en los dos, asi que no
    % hace falta distinguir cual es cual.
    triangulo = setdiff(1:4, [find(bancada) 1]);
    b = L(triangulo(1));
    c = L(triangulo(2));

    muPlegada   = anguloAgudo(b, c, d - a);
    muExtendida = anguloAgudo(b, c, d + a);

    muMax = max(muPlegada, muExtendida);
    muMin = min(muPlegada, muExtendida);

    fprintf('Angulo de transmision: minimo %.2f, maximo %.2f grados.\n', muMin, muMax);
    fprintf('  posicion plegada   (diagonal %.2f): %.2f grados\n', d - a, muPlegada);
    fprintf('  posicion extendida (diagonal %.2f): %.2f grados\n', d + a, muExtendida);
    if muMin < 40
        fprintf('Advertencia: mu < 40 grados, mala transmision.\n');
    end
end

% Angulo entre los lados b y c del triangulo que cierra la diagonal, por ley
% de cosenos. mu se define agudo, asi que se toma el suplemento si pasa de 90.
function mu = anguloAgudo(b, c, diagonal)
    arg = (b^2 + c^2 - diagonal^2)/(2*b*c);
    if abs(arg) > 1
        error('Posicion colineal inalcanzable: con esa manivela el mecanismo no es Grashof.');
    end
    mu = rad2deg(acos(arg));
    if mu > 90
        mu = 180 - mu;
    end
end
