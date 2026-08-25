%proporciones
Cemento = .15;
Agua = .18;
Fino = .28;
Grueso = .31;
Mat = [Cemento, Agua, Fino, Grueso];

%masas experimentales [g]
m_c = 100;
m_H2O = 100; %no cambiar
m_F = 100;
m_G = 100;
MasasX = [m_c, m_H2O, m_F, m_G];

%Arquimides(volumen) [cm^3]
V_c = 31.75;
V_H2O = 100; %no cambiar
V_F = 37.74;
V_G = 37.04;
V_X = [V_c, V_H2O, V_F, V_G];

%Densidades[p = m/V]
for i = 1:4
    p(i) = MasasX(i)/V_X(i);
end


%Volumen de ensayo 1plg a 2.54cm -  Vcilindro = pi*d2*h/4
V_cil = (3*2.54)^2*(6*2.54)*pi/4; % [cm^3]

%bachada
n = 3;

%Volumenes requeridos
for j = 1:4
    V_req(j) = n*V_cil*Mat(j); % V[cm^3]
    M_req(j) = V_req(j)*(p(j)); % Masa [g]
end

%Datos para la tabla
Materiales = {'Cemento', 'Agua', 'Agregado Fino', 'Agregado Grueso'};

%Prints con tabla formateada y conversiones a m^3, kg y kg/m^3
fprintf('\n========================================================================\n');
fprintf('| %-16s | %-14s | %-12s | %-16s |\n', ...
    'Material', 'Volumen (m^3)', 'Masa (kg)', 'Densidad (kg/m^3)');
fprintf('========================================================================\n');

for k = 1:4
    fprintf('| %-16s | %14.6f | %12.4f | %16.1f |\n', ...
        Materiales{k}, ...
        V_req(k) / 1e6, ...   % cm^3 -> m^3 (divide entre 1,000,000)
        M_req(k) / 1000, ...  % g -> kg     (divide entre 1,000)
        p(k) * 1000);         % g/cm^3 -> kg/m^3 (multiplica por 1,000)
end
fprintf('========================================================================\n\n');
