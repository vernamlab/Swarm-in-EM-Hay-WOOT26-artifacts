clc
close all
clear all
load("ascadf.mat")
confidence1 = confidence;
confidence2 = confidence_;
acc1 = acc;
load("ascadr.mat")
confidence3 = confidence;
confidence4 = confidence_;
acc2 = acc;




% Example: replace these with your real variables
X = {confidence1, confidence2, confidence3, confidence4};
ACC = {acc1, acc1, acc2, acc2};
titles = {'ASCAD-f','Calibrated ASCAD-f ','ASCAD-r','Calibrated ASCAD-r'};

figure('Units','pixels','Position',[100 100 1400 700])

t = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

for i = 1:4
    nexttile
    x = X{i};

    histogram(x, 20, 'BinLimits', [0 0.05]);
    hold on;

    mu = mean(x);
    x_choice = ACC{i};

    xline(mu, 'r--', 'LineWidth', 2, ...
        'LabelVerticalAlignment','middle', ...
        'Label',"Avg. confidence");

    xline(x_choice, 'k--', 'LineWidth', 2, ...
        'LabelVerticalAlignment','middle', ...
        'Label',"Accuracy");

    % Y-axis formatting
    ymax = ylim;
    yticks(linspace(0, ymax(2), 4));
    yticklabels(["0","10","20","30"]);

    xlabel('Confidence');
    ylabel('% of samples');
    title(titles{i})

    grid on;
    box on;
    hold off;
end

% Save as one PNG
exportgraphics(gcf,'confidence_4plots.png','Resolution',300)
