function test_render_all_v2()
    configs = {'DD', 'YY', 'YD', 'DY'};
    for i = 1:numel(configs)
        cfg = configs{i};
        fig = figure('Visible','off','Position',[100 100 1150 680],'Color','w');
        
        % Configurar defaults de texto
        set(fig, 'DefaultTextColor', 'k');
        set(fig, 'DefaultAxesXColor', 'k');
        set(fig, 'DefaultAxesYColor', 'k');
        
        % Área de diagrama (izquierda)
        ax = axes(fig, 'Position', [0.02 0.04 0.64 0.92]);
        hold(ax, 'on'); axis(ax, 'equal'); axis(ax, 'off');
        xlim(ax, [-1.2, 13.2]); ylim(ax, [-0.5, 12.5]);
        
        % Área de fórmulas (derecha)
        ax_form = axes(fig, 'Position', [0.68 0.04 0.30 0.92]);
        hold(ax_form, 'on'); axis(ax_form, 'off');
        xlim(ax_form, [0 10]); ylim(ax_form, [0 12]);
        
        render_schematic_v2(ax, cfg);
        render_formulas_v2(ax_form, cfg);
        
        exportgraphics(fig, sprintf('test_%s_v2.png', cfg), 'Resolution', 200, 'BackgroundColor', 'w');
        close(fig);
    end
    disp('All rendered v2 successfully');
end

function render_schematic_v2(ax, cfg)
    % Colores
    col_pri = [0.05, 0.30, 0.72];   % Azul primario
    col_sec = [0.85, 0.20, 0.08];   % Rojo/Naranja secundario
    col_wire = [0.15, 0.15, 0.15];  % Gris oscuro líneas
    col_core = [0.40, 0.40, 0.40];  % Gris núcleo
    col_node = [0.10, 0.10, 0.10];  % Nodos
    
    % Posiciones X de las 3 columnas/fases
    x_coils = [3.2, 6.7, 10.2];
    
    % Líneas de alimentación superiores (Primario: A, B, C)
    % Bus A: y = 11.5, Bus B: y = 10.8, Bus C: y = 10.1
    y_bus_pri = [11.5, 10.8, 10.1];
    labels_pri = {'A', 'B', 'C'};
    
    for k = 1:3
        plot(ax, [0.5, 12.2], [y_bus_pri(k), y_bus_pri(k)], 'Color', col_wire, 'LineWidth', 1.8);
        plot(ax, 0.5, y_bus_pri(k), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_wire, 'MarkerSize', 7, 'LineWidth', 1.8);
        text(ax, 0.1, y_bus_pri(k), labels_pri{k}, 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k', 'HorizontalAlignment', 'right');
    end
    
    % Líneas de salida inferiores (Secundario: a, b, c)
    % Bus a: y = 2.1, Bus b: y = 1.4, Bus c: y = 0.7
    y_bus_sec = [2.1, 1.4, 0.7];
    labels_sec = {'a', 'b', 'c'};
    
    for k = 1:3
        plot(ax, [0.5, 12.2], [y_bus_sec(k), y_bus_sec(k)], 'Color', col_wire, 'LineWidth', 1.8);
        plot(ax, 12.2, y_bus_sec(k), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_wire, 'MarkerSize', 7, 'LineWidth', 1.8);
        text(ax, 12.6, y_bus_sec(k), labels_sec{k}, 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k', 'HorizontalAlignment', 'left');
    end
    
    % Dibujar bobinas y núcleo magnético
    for k = 1:3
        xc = x_coils(k);
        
        % Núcleo laminado (2 barras horizontales entre primario y secundario)
        plot(ax, [xc-0.9, xc+0.9], [6.3, 6.3], 'Color', col_core, 'LineWidth', 2.5);
        plot(ax, [xc-0.9, xc+0.9], [5.9, 5.9], 'Color', col_core, 'LineWidth', 2.5);
        
        % Bobina Primaria (y = 7.3 a 9.3)
        draw_inductor(ax, xc, 9.3, 7.3, 4, 0.45, col_pri);
        % Punto polaridad primario (arriba a la izquierda)
        plot(ax, xc - 0.55, 9.2, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
        text(ax, xc + 0.65, 8.3, sprintf('N_{P%d}', k), 'FontSize', 12, 'Color', col_pri, 'FontWeight', 'bold');
        
        % Bobina Secundaria (y = 4.9 a 2.9)
        draw_inductor(ax, xc, 4.9, 2.9, 4, 0.45, col_sec);
        % Punto polaridad secundario (arriba a la izquierda)
        plot(ax, xc - 0.55, 4.8, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
        text(ax, xc + 0.65, 3.9, sprintf('N_{S%d}', k), 'FontSize', 12, 'Color', col_sec, 'FontWeight', 'bold');
    end
    
    % Conexiones PRIMARIO
    pri_type = cfg(1);
    if pri_type == 'D' % Delta Primario
        % Bobina 1: Top -> Bus A, Bot -> Bus B
        draw_wire_node(ax, [x_coils(1), x_coils(1)], [9.3, y_bus_pri(1)], col_pri);
        draw_delta_link(ax, x_coils(1), 7.3, y_bus_pri(2), x_coils(1)+0.7, col_pri);
        
        % Bobina 2: Top -> Bus B, Bot -> Bus C
        draw_wire_node(ax, [x_coils(2), x_coils(2)], [9.3, y_bus_pri(2)], col_pri);
        draw_delta_link(ax, x_coils(2), 7.3, y_bus_pri(3), x_coils(2)+0.7, col_pri);
        
        % Bobina 3: Top -> Bus C, Bot -> Bus A
        draw_wire_node(ax, [x_coils(3), x_coils(3)], [9.3, y_bus_pri(3)], col_pri);
        draw_delta_link(ax, x_coils(3), 7.3, y_bus_pri(1), x_coils(3)+0.7, col_pri);
        
    else % Estrella Primario (Y)
        % Tops -> Buses A, B, C
        draw_wire_node(ax, [x_coils(1), x_coils(1)], [9.3, y_bus_pri(1)], col_pri);
        draw_wire_node(ax, [x_coils(2), x_coils(2)], [9.3, y_bus_pri(2)], col_pri);
        draw_wire_node(ax, [x_coils(3), x_coils(3)], [9.3, y_bus_pri(3)], col_pri);
        
        % Bots -> Neutro común N
        y_neutro_p = 6.9;
        plot(ax, [x_coils(1), x_coils(3)], [y_neutro_p, y_neutro_p], 'Color', col_pri, 'LineWidth', 1.8);
        for k = 1:3
            plot(ax, [x_coils(k), x_coils(k)], [7.3, y_neutro_p], 'Color', col_pri, 'LineWidth', 1.8);
            plot(ax, x_coils(k), y_neutro_p, 'o', 'MarkerFaceColor', col_node, 'MarkerEdgeColor', col_pri, 'MarkerSize', 5);
        end
        % Terminal neutro
        plot(ax, [x_coils(1), x_coils(1)-1.4], [y_neutro_p, y_neutro_p], 'Color', col_pri, 'LineWidth', 1.5, 'LineStyle', '--');
        plot(ax, x_coils(1)-1.4, y_neutro_p, 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_wire, 'MarkerSize', 7, 'LineWidth', 1.5);
        text(ax, x_coils(1)-1.6, y_neutro_p, 'N', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', 'HorizontalAlignment', 'right');
    end
    
    % Conexiones SECUNDARIO
    sec_type = cfg(2);
    if sec_type == 'D' % Delta Secundario
        % Bobina 1: Top -> Bus a, Bot -> Bus b
        draw_wire_node(ax, [x_coils(1), x_coils(1)], [4.9, y_bus_sec(1)], col_sec);
        draw_delta_link(ax, x_coils(1), 2.9, y_bus_sec(2), x_coils(1)+0.7, col_sec);
        
        % Bobina 2: Top -> Bus b, Bot -> Bus c
        draw_wire_node(ax, [x_coils(2), x_coils(2)], [4.9, y_bus_sec(2)], col_sec);
        draw_delta_link(ax, x_coils(2), 2.9, y_bus_sec(3), x_coils(2)+0.7, col_sec);
        
        % Bobina 3: Top -> Bus c, Bot -> Bus a
        draw_wire_node(ax, [x_coils(3), x_coils(3)], [4.9, y_bus_sec(3)], col_sec);
        draw_delta_link(ax, x_coils(3), 2.9, y_bus_sec(1), x_coils(3)+0.7, col_sec);
        
    else % Estrella Secundario (Y)
        % Tops -> Buses a, b, c
        draw_wire_node(ax, [x_coils(1), x_coils(1)], [4.9, y_bus_sec(1)], col_sec);
        draw_wire_node(ax, [x_coils(2), x_coils(2)], [4.9, y_bus_sec(2)], col_sec);
        draw_wire_node(ax, [x_coils(3), x_coils(3)], [4.9, y_bus_sec(3)], col_sec);
        
        % Bots -> Neutro común n
        y_neutro_s = 5.3;
        plot(ax, [x_coils(1), x_coils(3)], [y_neutro_s, y_neutro_s], 'Color', col_sec, 'LineWidth', 1.8);
        for k = 1:3
            plot(ax, [x_coils(k), x_coils(k)], [4.9, y_neutro_s], 'Color', col_sec, 'LineWidth', 1.8);
            plot(ax, x_coils(k), y_neutro_s, 'o', 'MarkerFaceColor', col_node, 'MarkerEdgeColor', col_sec, 'MarkerSize', 5);
        end
        % Terminal neutro
        plot(ax, [x_coils(3), x_coils(3)+1.4], [y_neutro_s, y_neutro_s], 'Color', col_sec, 'LineWidth', 1.5, 'LineStyle', '--');
        plot(ax, x_coils(3)+1.4, y_neutro_s, 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_wire, 'MarkerSize', 7, 'LineWidth', 1.5);
        text(ax, x_coils(3)+1.6, y_neutro_s, 'n', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', 'HorizontalAlignment', 'left');
    end
    
    % Indicadores de voltaje
    % V_LP
    draw_volt_dimension(ax, 1.2, y_bus_pri(1), y_bus_pri(2), 'V_{LP}', 'left');
    % V_phiP
    draw_volt_dimension(ax, x_coils(1)-0.85, 9.3, 7.3, 'V_{\phi P}', 'left');
    
    % V_LS
    draw_volt_dimension(ax, 11.5, y_bus_sec(1), y_bus_sec(2), 'V_{LS}', 'right');
    % V_phiS
    draw_volt_dimension(ax, x_coils(1)-0.85, 4.9, 2.9, 'V_{\phi S}', 'left');
end

function draw_inductor(ax, xc, y_top, y_bot, n_turns, w, col)
    h = y_top - y_bot;
    step = h / n_turns;
    for k = 1:n_turns
        yt1 = y_top - (k-1)*step;
        yt2 = y_top - k*step;
        theta = linspace(-pi/2, pi/2, 40);
        yc = (yt1 + yt2)/2;
        r = step/2;
        x_arc = xc + w * cos(theta);
        y_arc = yc + r * sin(theta);
        plot(ax, x_arc, y_arc, 'Color', col, 'LineWidth', 2.2);
    end
end

function draw_wire_node(ax, x, y, col)
    plot(ax, x, y, 'Color', col, 'LineWidth', 1.8);
    plot(ax, x(2), y(2), 'o', 'MarkerFaceColor', [0.1 0.1 0.1], 'MarkerEdgeColor', col, 'MarkerSize', 5);
end

function draw_delta_link(ax, xc, y_start, y_dest, x_route, col)
    plot(ax, [xc, x_route, x_route], [y_start, y_start, y_dest], 'Color', col, 'LineWidth', 1.8);
    plot(ax, x_route, y_dest, 'o', 'MarkerFaceColor', [0.1 0.1 0.1], 'MarkerEdgeColor', col, 'MarkerSize', 5);
end

function draw_volt_dimension(ax, x, y1, y2, lbl, side)
    plot(ax, [x, x], [y1, y2], 'Color', [0.2 0.2 0.2], 'LineWidth', 1.2);
    plot(ax, [x-0.18, x+0.18], [y1, y1], 'Color', [0.2 0.2 0.2], 'LineWidth', 1.2);
    plot(ax, [x-0.18, x+0.18], [y2, y2], 'Color', [0.2 0.2 0.2], 'LineWidth', 1.2);
    ym = (y1 + y2)/2;
    if strcmp(side, 'left')
        text(ax, x - 0.25, ym, lbl, 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', 'HorizontalAlignment', 'right');
    else
        text(ax, x + 0.25, ym, lbl, 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k', 'HorizontalAlignment', 'left');
    end
end

function render_formulas_v2(ax, cfg)
    % Marco de fórmulas
    rectangle(ax, 'Position', [0.5, 0.5, 9.0, 11.2], 'FaceColor', [0.98, 0.99, 1.0], ...
              'EdgeColor', [0.15, 0.35, 0.75], 'LineWidth', 2.0, 'Curvature', 0.04);
    
    switch cfg
        case 'DD'
            header = '$$\mathbf{\Delta - \Delta}$$';
            eqs = {
                '$$V_{LP} = V_{\phi P}$$'
                '$$V_{LS} = V_{\phi S}$$'
                '$$\frac{V_{LP}}{V_{LS}} = \frac{V_{\phi P}}{V_{\phi S}} = a$$'
                '$$a = \frac{N_P}{N_S} = \frac{V_{\phi P}}{V_{\phi S}}$$'
            };
        case 'YY'
            header = '$$\mathbf{Y - Y}$$';
            eqs = {
                '$$V_{\phi P} = \frac{V_{LP}}{\sqrt{3}} \quad \Rightarrow \quad V_{LP} = \sqrt{3}\,V_{\phi P}$$'
                '$$V_{\phi S} = \frac{V_{LS}}{\sqrt{3}} \quad \Rightarrow \quad V_{LS} = \sqrt{3}\,V_{\phi S}$$'
                '$$\frac{V_{LP}}{V_{LS}} = \frac{\sqrt{3}\,V_{\phi P}}{\sqrt{3}\,V_{\phi S}} = a$$'
                '$$a = \frac{N_P}{N_S} = \frac{V_{\phi P}}{V_{\phi S}}$$'
            };
        case 'YD'
            header = '$$\mathbf{Y - \Delta}$$';
            eqs = {
                '$$V_{LP} = \sqrt{3}\,V_{\phi P}$$'
                '$$V_{LS} = V_{\phi S}$$'
                '$$\frac{V_{LP}}{V_{LS}} = \frac{\sqrt{3}\,V_{\phi P}}{V_{\phi S}} = \sqrt{3}\,a$$'
                '$$a = \frac{N_P}{N_S} = \frac{V_{\phi P}}{V_{\phi S}}$$'
            };
        case 'DY'
            header = '$$\mathbf{\Delta - Y}$$';
            eqs = {
                '$$V_{LP} = V_{\phi P}$$'
                '$$V_{LS} = \sqrt{3}\,V_{\phi S}$$'
                '$$\frac{V_{LP}}{V_{LS}} = \frac{V_{\phi P}}{\sqrt{3}\,V_{\phi S}} = \frac{a}{\sqrt{3}}$$'
                '$$a = \frac{N_P}{N_S} = \frac{V_{\phi P}}{V_{\phi S}}$$'
            };
    end
    
    % Título
    text(ax, 5.0, 10.5, header, 'Interpreter', 'latex', 'FontSize', 22, ...
         'HorizontalAlignment', 'center', 'Color', [0.1, 0.25, 0.6]);
    
    % Separador
    plot(ax, [1.5, 8.5], [9.7, 9.7], 'Color', [0.7, 0.8, 0.9], 'LineWidth', 1.5);
    
    % Fórmulas distribuidas
    y_positions = linspace(8.5, 2.0, numel(eqs));
    for k = 1:numel(eqs)
        text(ax, 5.0, y_positions(k), eqs{k}, 'Interpreter', 'latex', 'FontSize', 15, ...
             'HorizontalAlignment', 'center', 'Color', 'k');
    end
end
