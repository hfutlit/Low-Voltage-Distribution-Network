% Data Source and more Training Material 
% https://sites.google.com/view/luisfochoa/research-tools
% Editor: SYT
% Date: 2023.08.20
clear;
clc;
close all;
%Set DSS working path
FilePath = 'C:\Users\SYT\Desktop\Tutorial-DERHostingCapacity-2-TimeSeries_LV-main\';
%DSS COM Interface
DSSObj = actxserver('OpenDSSEngine.DSS');
% Start up the Solver
if ~DSSObj.Start(0)
    disp('Unable to start the OpenDSS Engine')
    return
end
% Set up the Text, Circuit, and Solution Interfaces
% global DSSText DSSCircuit DSSSolution
DSSText = DSSObj.Text;
DSSCircuit = DSSObj.ActiveCircuit;
DSSSolution = DSSCircuit.Solution;
% Set the DSS Files Path
DSSDataPath = ['Set DataPath = ',FilePath];
DSSText.command = DSSDataPath;
DSSText.Command = 'Clear';
DSSText.Command = 'Set DefaultBaseFrequency=50';
DSSText.Command = 'New circuit.LVcircuit basekv=10.5 pu=1.00 angle=0 frequency=50 phases=3';
DSSText.command = 'Edit Vsource.Source BasekV=10.5 pu=1 ISC3=3000  ISC1=1500'; % Defines source voltage (grid connection)
DSSText.Command = 'Redirect LVcircuit-transformers.txt';
DSSText.Command = 'Redirect LVcircuit-linecodes.txt';
DSSText.Command = 'Redirect LVcircuit-lines.txt';
DSSText.Command = 'Redirect LVcircuit-servicelines.txt';
DSSText.Command = 'Redirect LVcircuit-loads.txt';
DSSText.Command = 'Set VoltageBases = [11.0, 0.400]';
DSSText.Command = 'calcvoltagebases';
DSSText.command = 'batchedit Load..* kW=2';%批量修改负荷额定功率

% Importing data in npy format. Need the readNPY toolbox in GitHub
houseData30minutes = readNPY('Residential load data 30-min resolution.npy');
PVData30minutes = readNPY('Residential PV data 30-min resolution.npy');
% PVWinter = readNPY('Residential_PV_profiles_Winter.npy');
% PVSummer = readNPY('Residential_PV_profiles_Summer.npy');
% PVSpring = readNPY('Residential_PV_profiles_Spring.npy');
% PVAutumn = readNPY('Residential_PV_profiles_Autumn.npy');

%LoadShspe Initialization
[NumProfiles, ~, Tsolts] = size(houseData30minutes);
LoadsName = DSSCircuit.Loads.AllNames;
NumLoads = numel(LoadsName);
ActivePowewr = zeros(1, Tsolts);
ReactivePower = ActivePowewr.*tan(acos(0.95));
for k = 1 : NumLoads
    LoadshapeName = ['LoadShape_', num2str(k)];
    str_2 = ['New LoadShape.',LoadshapeName, ' npts=48 interval=0.5'];
    str_2 = [str_2, ' Pmult=[', sprintf('%0.5f ',ActivePowewr), ']'];
    str_2 = [str_2, ' Qmult=[', sprintf('%0.5f ',ReactivePower), '] UseActual=false'];
    DSSText.Command = str_2;
    DSSCircuit.SetActiveElement(['load.',LoadsName{k}]);
    DSSCircuit.ActiveElement.Properties('daily').Val = LoadshapeName;
end

for k = 1 : NumLoads
    LoadshapeName = ['PVShape_', num2str(k)];
    str_2 = ['New LoadShape.',LoadshapeName, ' npts=48 interval=0.5'];
    str_2 = [str_2, ' Pmult=[', sprintf('%0.5f ',ActivePowewr), ']'];
    str_2 = [str_2, ' Qmult=[', sprintf('%0.5f ',ReactivePower), '] UseActual=True'];
    DSSText.Command = str_2;

    PVName = ['PV_', num2str(k)];
    DSSCircuit.SetActiveElement(LoadsName{k});
    bus_name = DSSCircuit.ActiveCktElement.BusNames;
    str_2 = ['New PVSystem.',PVName, ' phases=1 irradiance=1 %cutin=0.1' ...
        ' %cutout=0.1 vmaxpu=1.5 vminpu=0.5 kva=5 Pmpp=5 bus1=',bus_name{1}, ' pf=1 kv=0.22'];
    str_2 = [str_2, ' daily=', LoadshapeName];
    DSSText.Command = str_2;
end
PVSystemsName = DSSCircuit.PVSystems.AllNames;
NumPVSystems = numel(PVSystemsName);
NumTransformers = DSSCircuit.Transformers.Count;
TransformersName = cellstr(DSSCircuit.Transformers.AllNames);
%Set the Simulation Days
start_day = 21;
total_days = 1;

power_factor = 0.9+(0.98-0.9).*rand(NumLoads, Tsolts, total_days);% Power factors of loads
penetration = 50; %PV pentration
NumtempPVs = round(NumLoads .* (penetration / 100));%PV Number

Voltagepu = zeros(NumLoads, total_days*Tsolts);
for DayIdx = start_day : (start_day + total_days - 1)
    fprintf('This is day: %d \n', DayIdx);
    rng(100);
    %Set the loadshape for Loads and PV systems
    for k = 1 : NumLoads
        ProfileIdx = randi(NumProfiles);
        ActivePowewr = houseData30minutes(ProfileIdx, DayIdx, :);
        ActivePowewr = reshape(ActivePowewr, 1, size(ActivePowewr, 3));
        ReactivePower = ActivePowewr .* power_factor(k, :, DayIdx-start_day+1);
        LoadshapeName = ['LoadShape_', num2str(k)];
        str_2 = ['Edit LoadShape.', LoadshapeName];
        str_2 = [str_2, ' Pmult=[', sprintf('%0.5f ',ActivePowewr), ']'];
        str_2 = [str_2, ' Qmult=[', sprintf('%0.5f ',ReactivePower), ']'];
        DSSText.Command = str_2;
    end
    PVindx = randperm(NumLoads, NumtempPVs);
    for k = 1 : NumLoads
        NumCurve = size(PVData30minutes, 1);
        if NumCurve == 1
            if find(PVindx == k)
                ActivePowewr = PVData30minutes;
            else
                ActivePowewr = zeros(1, Tsolts);
            end
        else
            if find(PVindx == k)
                ActivePowewr =  PVData30minutes(DayIdx, :);
            else
                ActivePowewr = zeros(1, Tsolts);
            end
        end
        LoadshapeName = ['PVShape_', num2str(k)];
        str_2 = ['Edit LoadShape.', LoadshapeName];
        str_2 = [str_2, ' Pmult=[', sprintf('%0.5f ',ActivePowewr), ']'];
        DSSText.Command = str_2;
    end
    %Set the simulation mode
    DSSText.Command = 'Set Mode=daily  number=1 stepsize=30m';

    TransformerActivePower = zeros(NumTransformers, Tsolts);
    TransformerReactivePower = zeros(NumTransformers, Tsolts);
    for t = 1 : Tsolts
        DSSSolution.Solve();
        if DSSSolution.Converged
            % Obtain P, Q and V of loads, in Table format
            [Pt, Qt, Vt] = PQVTable(DSSCircuit, 'Load.', NumLoads, LoadsName);
            if t == 1
                PLoads = Pt;
                PLoads.Properties.VariableNames{4} = 'T1';
                QLoads = Qt;
                QLoads.Properties.VariableNames{4} = 'T1';
                VLoads = Vt;
                VLoads.Properties.VariableNames{4} = 'T1';
            else
                temp = ['T',num2str(t)];
                PLoads.Pn = Pt.Ptemp;
                PLoads.Properties.VariableNames{t+3} = temp;
                QLoads.Pn = Qt.Qtemp;
                QLoads.Properties.VariableNames{t+3} = temp;
                VLoads.Vn = Vt.Vtemp;
                VLoads.Properties.VariableNames{t+3} = temp;
            end
            % Obtain P, Q and V of PVs, in Table format
            Namestemp = PVSystemsName(PVindx);
            [Pt, Qt, Vt] = PQVTable(DSSCircuit, 'PVSystem.', NumPVSystems, PVSystemsName);
            if t == 1
                PPVs = Pt;
                PPVs.Properties.VariableNames{4} = 'T1';
                QPVs = Qt;
                QPVs.Properties.VariableNames{4} = 'T1';
                VPVs = Vt;
                VPVs.Properties.VariableNames{4} = 'T1';
            else
                temp = ['T',num2str(t)];
                PPVs.Pn = Pt.Ptemp;
                PPVs.Properties.VariableNames{t+3} = temp;
                QPVs.Pn = Qt.Qtemp;
                QPVs.Properties.VariableNames{t+3} = temp;
                VPVs.Vn = Vt.Vtemp;
                VPVs.Properties.VariableNames{t+3} = temp;
            end

            for count = 1 : NumTransformers
                DSSCircuit.SetActiveElement(['Transformer.',TransformersName{count}]);    % Sets transformer to active element
                TransformerActivePower(count, t) = DSSCircuit.ActiveCktElement.TotalPowers(1);% Stores all transformer powers at each time step
                TransformerReactivePower(count, t) = DSSCircuit.ActiveCktElement.TotalPowers(2);% Stores all transformer powers at each time step
            end
        else
            error('non-convergent\n');
        end
    end
    %Plot Figure
    Datatemp = table2array(VLoads(:,4:end))./220;
    temp1 = (DayIdx - 1)*Tsolts+1;
    temp2 = DayIdx*Tsolts;
    Voltagepu(:,temp1:temp2) = Datatemp;

    figure
    Fig3D(Datatemp);view(0,0);
    TitleText = sprintf('This is day: %d \n', DayIdx);
    title({'Phase Voltage of Loads (pu)'; TitleText});
    xlabel('Hour');
    ylabel('Load #');
    zlabel('Voltage (pu)')

    Datatemp = table2array(PLoads(:,4:end));
    figure
    Fig3D(Datatemp);
    title({'Active Power', 'at all LoadNodes'})
    xlabel('Hour')
    ylabel('Load #')
    zlabel('Active Power (kW)')

    Datatemp = table2array(PPVs(:,4:end));
    figure
    Fig3D(Datatemp);
    title({'Active Power', 'at all PVNodes'})
    xlabel('Hour')
    ylabel('PVNode #')
    zlabel('Active Power (kW)')

    ActiveLoadPowers = table2array(PLoads(:, 4:end));
    PVInjectedPowers = table2array(PPVs(:, 4:end));
    AggregetedActiveLoadPowers = sum(ActiveLoadPowers, 1);
    AggregatedActivePVPowers = sum(PVInjectedPowers, 1);
    AggregatedActiveTransformerPower = sum(TransformerActivePower, 1);
    figure
    plot((1:Tsolts)/2, AggregetedActiveLoadPowers, 'LineWidth', 1, 'color', [0.2 0.8 1]);
    hold on
    plot((1:Tsolts)/2, AggregatedActivePVPowers, 'LineWidth', 1, 'color', [0 .8 0]);
    plot((1:Tsolts)/2, AggregatedActiveTransformerPower, 'LineWidth', 1, 'color',[1 .5 1]);
    InSet = get(gca, 'TightInset');
    set(gca, 'Position', [InSet(1)+0.08,InSet(2)+0.05, 1-InSet(1)-InSet(3)-0.14, 1-InSet(2)-InSet(4)-0.13]);
    set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
    grid on;
    grid minor;
    ylabel('Active Power (kW)','fontweight','bold','FontSize',8)
    xlabel('Hour','fontweight','bold','FontSize',8)
    xlim([0 Tsolts/2])
    title('Aggregated PV, Load, Transformer','FontSize',8)
    legend({'Loads', 'PV', 'Transformer'},'location','southwest','AutoUpdate','off','NumColumns',2)
end
% Fig3D(Voltagepu, 365);
% view(0,0);