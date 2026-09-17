% Ensayo a tensión (práctica 6) — esfuerzos de los cuatro materiales.
% Sistema de unidades in-lb-psi (coherente; no se convierte a SI).

materiales = {'Aluminio', 'A-709', 'A-1045', 'A-1018 CR'};
series     = {'\sigma fluencia', '\sigma último', '\sigma ruptura'};

% Esfuerzos [psi]. Fila = material, columna = fluencia | último | ruptura.
% Los valores marcados con ~ en la tabla son lecturas aproximadas.
sigma = [ 52000,  59726,  46000      % Aluminio   (~52,000 y ~46,000)
          38700,  63016,  36700      % A-709      (~38,700 y ~36,700)
          85000, 117968,  92000      % A-1045     (~85,000 y ~92,000)
          91000,  95239,  70000];    % A-1018 CR  (~91,000 y ~70,000)

% Paleta: un color fijo por serie (identidad), no por magnitud.
colores = [0.165 0.471 0.839         % azul   — fluencia
           0.922 0.408 0.204         % naranja — último
           0.106 0.686 0.478];       % verde  — ruptura

figure('Color', 'w');                       % fondo claro
b = bar(sigma/1e3, 'grouped');              % psi -> ksi (solo presentación)

for k = 1:numel(b)
    b(k).FaceColor = colores(k,:);
    b(k).EdgeColor = 'none';
    % XEndPoints/YEndPoints: centro y punta de cada barra de la serie k;
    % con eso se coloca la etiqueta de valor justo encima de la barra.
    text(b(k).XEndPoints, b(k).YEndPoints, compose('%.0f', b(k).YEndPoints), ...
        'HorizontalAlignment', 'center', ...   % centrada sobre la barra
        'VerticalAlignment',   'bottom',  ...  % apoyada en la punta
        'FontSize', 8, 'Color', [0.32 0.32 0.31]);
end

set(gca, ...
    'Color',      'w',     ...              % fondo del área de datos, claro
    'XTickLabel', materiales, ...
    'TickDir',    'out',   ...              % marcas hacia afuera del área de datos
    'Box',        'off',   ...              % sin marco: menos tinta que no es dato
    'YGrid',      'on',    ...              % rejilla solo en el eje de magnitud
    'GridColor',  [0.88 0.88 0.85], ...     % rejilla discreta, detrás de las barras
    'GridAlpha',  1, ...
    'XColor', [0.54 0.53 0.50], 'YColor', [0.54 0.53 0.50]);

ylabel('Esfuerzo [ksi]');
ylim([0 130]);                              % holgura para las etiquetas de valor
title('Ensayo a tensión: esfuerzos por material', 'Color', 'k');
legend(series, 'Location', 'northwest', 'Box', 'off', 'TextColor', 'k');
