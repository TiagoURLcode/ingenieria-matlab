%% Práctica 02 - El Transformador
clear; clc; close all;

% ---------- FORZAR ESTILO CLARO (fondo blanco, texto negro) ----------
set(groot, 'defaultFigureColor',        'w');
set(groot, 'defaultAxesColor',          'w');
set(groot, 'defaultAxesXColor',         'k');
set(groot, 'defaultAxesYColor',         'k');
set(groot, 'defaultAxesGridColor',      [0.15 0.15 0.15]);
set(groot, 'defaultTextColor',          'k');
set(groot, 'defaultLegendTextColor',    'k');
set(groot, 'defaultLegendColor',        'w');
set(groot, 'defaultLegendEdgeColor',    'k');


% ---------------- DATOS ----------------
ensayo    = (1:6)';
espiras   = {'1200/600','1200/300','600/300','300/600','300/1200','600/1200'};
relacion  = [2; 4; 2; 0.5; 0.25; 0.5];
corriente = [20.55; 20.55; 68.80; 369; 369; 59.9];   % mA
Vp        = [45; 45; 45; 40.6; 40.6; 40.6];          % V  <-- verificar ensayo 6
Vs_teo    = Vp ./ relacion;
Vs_real   = [22.0; 10.9; 22.0; 77.2; 154.6; 78.6];   % V

esReductor = relacion > 1;

% ---------------- CÁLCULOS ----------------
error_abs = Vs_real - Vs_teo;
error_rel = 100 * error_abs ./ Vs_teo;

T = table(ensayo, espiras(:), relacion, corriente, Vp, Vs_teo, Vs_real, ...
    error_abs, error_rel, ...
    'VariableNames', {'Ensayo','Espiras','Relacion','Corriente_mA', ...
                      'Vp_V','Vs_teorico_V','Vs_real_V','Error_abs_V','Error_rel_pct'});
disp(T);

fprintf('\nError relativo medio (reductor): %.2f %%\n', mean(error_rel(esReductor)));
fprintf('Error relativo medio (elevador): %.2f %%\n', mean(error_rel(~esReductor)));

% ---------------- FIGURA 1: Vs teórico vs Vs real ----------------
f1 = figure('Position',[100 100 640 560]);
ax1 = axes(f1); hold(ax1,'on'); grid(ax1,'on'); box(ax1,'on');

lim = [0 175];
plot(ax1, lim, lim, 'k--', 'LineWidth', 1.2);

scatter(ax1, Vs_teo(esReductor),  Vs_real(esReductor),  90, 'o', ...
    'MarkerFaceColor',[0.10 0.35 0.70], 'MarkerEdgeColor','k');
scatter(ax1, Vs_teo(~esReductor), Vs_real(~esReductor), 90, 's', ...
    'MarkerFaceColor',[0.85 0.33 0.10], 'MarkerEdgeColor','k');

% Desplazamientos manuales por ensayo [dx dy] para evitar solapamiento
offset = [  4  -7;    % E1
            4  -7;    % E2
            4   5;    % E3  (desplazado arriba: coincide con E1)
            5  -8;    % E4
            5  -8;    % E5
            5   6];   % E6  (desplazado arriba: cercano a E4)

for k = 1:numel(ensayo)
    text(ax1, Vs_teo(k)+offset(k,1), Vs_real(k)+offset(k,2), ...
        sprintf('E%d (%s): %.2f%%', ensayo(k), espiras{k}, error_rel(k)), ...
        'FontSize', 8, 'Color', 'k');
end

xlabel(ax1,'V_s teórico (V)','FontSize',12,'Color','k');
ylabel(ax1,'V_s real medido (V)','FontSize',12,'Color','k');
title(ax1,'Comparación entre voltaje secundario teórico y medido', ...
    'FontSize',13,'Color','k');
legend(ax1, {'Modelo ideal (V_s real = V_s teórico)', ...
             'Configuración reductora','Configuración elevadora'}, ...
    'Location','northwest','TextColor','k','Color','w','EdgeColor','k');
axis(ax1,'equal'); xlim(ax1,lim); ylim(ax1,lim);

% ---------------- FIGURA 2: error relativo por ensayo ----------------
f2 = figure('Position',[760 100 640 420]);
ax2 = axes(f2);
b = bar(ax2, ensayo, error_rel, 0.55, 'FaceColor','flat', 'EdgeColor','k');
for k = 1:numel(ensayo)
    if esReductor(k), b.CData(k,:) = [0.10 0.35 0.70];
    else,             b.CData(k,:) = [0.85 0.33 0.10];
    end
end
grid(ax2,'on'); box(ax2,'on');
xlabel(ax2,'Ensayo','FontSize',12,'Color','k');
ylabel(ax2,'Error relativo (%)','FontSize',12,'Color','k');
title(ax2,'Desviación porcentual respecto al modelo ideal','FontSize',13,'Color','k');
xticks(ax2, ensayo); xticklabels(ax2, espiras); xtickangle(ax2, 30);

for k = 1:numel(ensayo)
    text(ax2, k, error_rel(k)-0.3, sprintf('%.2f%%',error_rel(k)), ...
        'HorizontalAlignment','center','FontSize',9,'Color','k');
end
ylim(ax2, [min(error_rel)-1.2, 0.5]);

% ---------------- EXPORTAR CON FONDO BLANCO ----------------
exportgraphics(f1,'fig_vs_teorico_vs_real.png','Resolution',300,'BackgroundColor','white');
exportgraphics(f2,'fig_error_relativo.png','Resolution',300,'BackgroundColor','white');