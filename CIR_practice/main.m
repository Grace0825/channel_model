clc
clear

frequency = '2873_GHz';
scenario = 'outdoor';
N=100; % N users
K_dB = 5; % 5~15

string = ['load Results_',frequency,'_',scenario,'_',num2str(N),'_CIRs'];
eval(string);

allAOA = [];
allPower = [];
indexLOS = [];




% fetch CIR data
for i = 1:N
    string = ['CIR(', num2str(i), ') = ', 'CIR_Struct.CIR_', num2str(i), ';'];
    eval(string);
    allAOA = [allAOA; CIR(i).AOAs];
    allPower = [allPower; CIR(i).pathPowers];
    if strcmp(CIR(i).environment, 'LOS')
        indexLOS = [indexLOS, i];
    end
    numTx = CIR(i).NumOfTxElements;
    numRx = CIR(i).NumOfRxElements;
    for j=1:length(CIR(i).H)
        H = CIR(i).H(j);
    end
end

% Simulation
Tx_power = 1;
noise_power = 0.001; % sigma^2
H = zeros(numTx, N);
for i=1:N
    H(:,i) = CIR(i).H{1}; % 25 LOS users' first path CIR
end
U = dftmtx(numRx); % DFT matrix
s = (randn(N,1) + 1i*randn(N,1))/sqrt(2); % symbol vertor

% Precoding Matrix
for i=1:N
    F_MF = H; % Matched filter
    F_ZF = H/(ctranspose(H)*H); % Zero-forcing 
    eta = noise_power*numRx/Tx_power; % Regulization factor pf wiener filter
    F_WF = (H*ctranspose(H)+eta*eye(numRx))\H; % Wiener filter

    alpha_MF = sqrt(Tx_power/trace(F_MF*ctranspose(F_MF)));
    alpha_ZF = sqrt(Tx_power/trace(F_ZF*ctranspose(F_ZF)));
    alpha_WF = sqrt(Tx_power/trace(F_WF*ctranspose(F_WF)));

    G_MF = alpha_MF * F_MF;
    G_ZF = alpha_ZF * F_ZF;
    G_WF = alpha_WF * F_WF;

    r = ctranspose(U)*H + noise_power*(randn(numTx,1)+1i*randn(numTx,1))/sqrt(2);
    
    H_b = ctranspose(U)*H;
    conj(H_b).*H_b;
end







%%%%%%%%% generate Rician Fading channel matrix
for i=1:1
    L = length(CIR(indexLOS(i)).pathDelays);
    A = Ric_channel_matrix(numTx, numRx, K_dB, L);
end




% %%%%%%%%%% plot AoA distribution
% AOARange = 0:0.01:360;
% AOAGraph = zeros(1, 36001);
% AOApdf = zeros(1, 36001);
% 
% for i = 1:length(allAOA)
%     pos          = find(AOARange>=allAOA(i)); 
% %     AOAIndex = round(AOARange(pos(1)));
%     AOAIndex = ((AOARange(pos(1))-allAOA(i))*(pos(1)-1) + ... % interpolation
%                 (allAOA(i)-AOARange(pos(1)-1))*(pos(1))) / ...
%                 (AOARange(pos(1))-AOARange(pos(1)-1));
%     AOAIndex = round(AOAIndex);
%     AOAGraph(AOAIndex) = AOAGraph(AOAIndex) + 1;
% end
% 
% sum = 0;
% for i = 1:length(AOARange)
%     sum = sum + AOAGraph(i);
%     if ~mod(AOARange(i), 1)
%         AOApdf(i) = sum/length(allAOA);
%         sum=0;
%     end
% end
% 
% 
% figure(1)
% plot(AOARange, AOApdf)
% xlabel('AOA(deg)');
% ylabel('number');
% 
