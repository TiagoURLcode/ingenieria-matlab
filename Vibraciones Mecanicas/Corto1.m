%% Corto1.m - datos del ejercicio de la torre de agua
%  Torre (columna) que sostiene en la punta un tanque de agua. La seccion
%  transversal de la torre es circular hueca. Solo se cargan los DATOS del
%  enunciado; el ejercicio no se resuelve aca.
%
%  UNIDADES: SI base (kg, N, m, s, Pa, Hz).
clear; clc

mtanque = 50000;    % masa del tanque lleno, en la punta        [kg]
Sut     = 300e6;    % resistencia a la tension del acero 1006 (HR) [Pa]  (300 MPa)
E       = 210e9;    % modulo de elasticidad del acero           [Pa]  (210 GPa)
Ltorre  = 8.00;     % longitud de la columna                    [m]

fmin    = 0.01;     % frecuencia permisible, extremo inferior   [Hz]
fmax    = 0.02;     % frecuencia permisible, extremo superior   [Hz]

% Pide: (a) diametro externo permisible [m] y (b) diametro interno
% permisible [m]. Nota del enunciado: la seccion debe resistir el esfuerzo
% axial.

g = 9.81;

fperm = [fmin fmax];
kperm = zeros(1,2);
for i = 1:2
    R = VM.omega('m',mtanque, 'f',fperm(i));
    kperm(i) = double(R.k);
end
Iperm = kperm*Ltorre^3/(3*E);

W = mtanque*g;
A = W/Sut;

syms De Di
for i = 1:2
    sol = solve([Iperm(i) == pi*(De^4 - Di^4)/64, ...
        A       == pi*(De^2 - Di^2)/4], [De Di]);
    d1 = double(sol.De)
    d2 = double(sol.Di)

end


