function Fig3D(Data, Days)
% function: Plot 3D figure
% Editor: SYT
% Date: 2023.08.01
if nargin == 1
    Days = 1;
end
[NumNodes, Tsolts] = size(Data);
% Sets x and y axis
alpha = Tsolts/(24*Days);
TimeIdx = [(1 : Tsolts)/alpha]';
NodeIdx = [1 : NumNodes]';
% Sets up meshgrid
[x, y] = meshgrid(TimeIdx, NodeIdx);
%3D Surface Plot
% V1_3D_PLOTFigure = figure('Name', 'Phase Voltage at all LoadNodes');
V1_3D_PLOT = surf(x, y, Data, 'EdgeColor', 'none', 'LineWidth', 0.1);
hold on
view(-38,10)%view(0,0)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.08, 1-InSet(1)-InSet(3)-0.09, 1-InSet(2)-InSet(4)-0.25]);
%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
xlim([0 Tsolts/alpha])
ylim([0 NumNodes])