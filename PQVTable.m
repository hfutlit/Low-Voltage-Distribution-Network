function [P, Q, V] = PQVTable(DSSCircuit, ClassName, Num, Names)
% function: Extracting simulation results and generate Table
% Example：
%   [P, Q, V] = PQTable(DSSCircuit, 'Load.', NumStru.NumLoads, NameStru.LoadsName);
k = 1;
for count = 1 : Num
    DSSCircuit.SetActiveElement([ClassName Names{count}]);
    temp = DSSCircuit.ActiveCktElement.NumPhases;
    if temp == 1
        temp1 = DSSCircuit.ActiveCktElement.BusNames;
        temp1 = strsplit(temp1{1}, '.');
        BusName{k} = temp1{1};
        PhaseNum{k} = temp;
        PhaseGroup{k} = DSSCircuit.ActiveCktElement.NodeOrder(1);
        Ptemp(k) = DSSCircuit.ActiveCktElement.Powers(1);
        Qtemp(k) = DSSCircuit.ActiveCktElement.Powers(2);
        Vtemp(k) = DSSCircuit.ActiveCktElement.VoltagesMagAng(1);
        k = k + 1;
    elseif temp == 3
        temp1 = DSSCircuit.ActiveCktElement.BusNames;
        temp1 = strsplit(temp1{1}, '.');
        for j = 1 : 3
            BusName{k} = temp1{1};
            PhaseNum{k} = temp;
            PhaseGroup{k} = DSSCircuit.ActiveCktElement.NodeOrder(j);
            Ptemp(k) = DSSCircuit.ActiveCktElement.Powers(2*j-1);
            Qtemp(k) = DSSCircuit.ActiveCktElement.Powers(2*j);
            Vtemp(k) = DSSCircuit.ActiveCktElement.VoltagesMagAng(2*j-1);
            k = k + 1;
        end
    end
end
BusName = BusName';
PhaseNum = PhaseNum';
PhaseGroup = PhaseGroup';
Ptemp = Ptemp';
Qtemp = Qtemp';
Vtemp = Vtemp';
P = table(BusName, PhaseNum, PhaseGroup, Ptemp);
Q = table(BusName, PhaseNum, PhaseGroup, Qtemp);
V = table(BusName, PhaseNum, PhaseGroup, Vtemp);