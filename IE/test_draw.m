% Test drawing inductor and connections
figure('Visible','off','Color','w');
ax = axes; hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');

% Function to draw coil
draw_coil = @(x0, y0, h, n_turns, w, col) ...
    arrayfun(@(k) plot(x0 + w*sin(linspace(0, pi, 30)), ...
                       linspace(y0 - (k-1)*h/n_turns, y0 - k*h/n_turns, 30), ...
                       'Color', col, 'LineWidth', 2), 1:n_turns);

draw_coil(0, 5, 4, 4, 0.4, [0 0.2 0.7]);
title('Test');
saveas(gcf, 'test_fig.png');
disp('Done');
