%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                      Script: variaSNR                             %%%%
%%%%                                                                   %%%%
%%%%        Script el que se obtiene la eficiencia espectral           %%%%
%%%%       para un sistema de MIMO masivo en funci�n de la SNR media   %%%%
%%%%       del sistema. Se puede utilizar tanto para el enlace uplink  %%%%
%%%%              como para downlink. El n�mero de antenas en BS       %%%%
%%%%            y el n�mero de usuarios permanece constante            %%%%
%%%%                 a lo largo de la simulaci�n.                      %%%%
%%%%                                                                   %%%%
%%%%           En este script se utiliza la normalizaci�n de           %%%%
%%%%           de las matrices de canal para que solo contengan        %%%%
%%%%               los efectos de small scale fading                   %%%%
%%%%                                                                   %%%%
%%%%   El tiempo de ejecuci�n cuando se usa DPC (downlink) es elevado. %%%%
%%%%                  Resultados mostrados en 7.4.1                    %%%%
%%%%                                                                   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear all
clc
addpath('..')

% Iniciaci�n de los parametros
ntx = 10;
nrx = 8;
precision = 5;
iteraciones = 10;
realizaciones = 20;
SNRdB = [-10:5:20];  % Vector de SNRs a barrer
DL = 0; % Si DL = 0; se realiza el analisis sobre el enlace ascendente.



for i = 1:iteraciones
    
    % Generamos los canales para una SNR dada (varias realizaciones donde
    % los usuarios se mantienen en la misma posici�n (large scale fading
    % iguales) pero small scale fading diferentes:
    
    [H_struct,H_iid_struct,x,a] = generaCanalQuadriga(precision,ntx,nrx,realizaciones,1,0,0);
    
    for h = 1 : realizaciones
        H_iid_struct{h} = (randn(ntx,nrx)+1i*randn(ntx,nrx))/sqrt(2);
    end
    
    % Con las realizaciones del canal se va a realizar la normalizaci�n de
    % todas ellas para conseguir que la potencia media de cada usuario en
    % todas ellas sea igual a 1.
    
    [canales_normalizados] = realizaNormalizacion(H_struct);
    [canales_normalizados_iid] = realizaNormalizacion(H_iid_struct);
    
    % Debido al numero tan alto realizaciones se van a coger 5 al azar que
    % seran las utilizadas para obtener la eficiencia espectral;
    
    index = randperm(realizaciones,10);
    
    for k = 1:length(index)
        
        H = canales_normalizados{index(k)};
        H_iid = canales_normalizados_iid{index(k)};
        
        % Seleci�n del enlace que se quiere simular
        if DL == 1 
            [C_mrt(k,:),C_zf(k,:),C_mmse(k,:),C_dpc(k,:)] = sum_rate_DL(H,SNRdB);
            [C_mrt_iid(k,:),C_zf_iid(k,:),C_mmse_iid(k,:),C_dpc_iid(k,:)] = sum_rate_DL(H_iid,SNRdB);
        else
            [C_mrt(k,:),C_zf(k,:),C_mmse(k,:),C_dpc(k,:)] = sum_rate_UL(H,SNRdB);
            [C_mrt_iid(k,:),C_zf_iid(k,:),C_mmse_iid(k,:),C_dpc_iid(k,:)] = sum_rate_UL(H_iid,SNRdB);
        end
    end
    
    % Obtenci�n de la media sobre las k realizaciones
    CMRT(i,:) = mean(C_mrt);
    CZF(i,:) = mean(C_zf);
    CMMSE(i,:) = mean(C_mmse);
    CDPC(i,:) = mean(C_dpc);
    
    CMRT_iid(i,:) = mean(C_mrt_iid);
    CZF_iid(i,:) = mean(C_zf_iid);
    CMMSE_iid(i,:) = mean(C_mmse_iid);
    CDPC_iid(i,:) = mean(C_dpc_iid);
    
    fprintf('Iteraci�n %d de %d\n',i,iteraciones);
    
end

% Valores medios para las diferentes SNRs.
CMRT_media = mean(CMRT);
CZF_media = mean(CZF);
CMMSE_media = mean(CMMSE);
CDPC_media = mean(real(CDPC));

CMRT_media_iid = mean(CMRT_iid);
CZF_media_iid = mean(CZF_iid);
CMMSE_media_iid = mean(CMMSE_iid);
CDPC_media_iid = mean(real(CDPC_iid));

figure
plot(SNRdB,CMRT_media,'o-','LineWidth',1.5)
hold on
plot(SNRdB,CZF_media,'ro-','LineWidth',1.5)
plot(SNRdB,CMMSE_media,'ko-','LineWidth',1.5);
plot(SNRdB,CDPC_media,'o-','Color',[0,1,0.9],'LineWidth',1.5);
plot(SNRdB,CMRT_media_iid,':','LineWidth',1.5)
plot(SNRdB,CZF_media_iid,'r:','LineWidth',1.5)
plot(SNRdB,CMMSE_media_iid,':k','LineWidth',1.5)
plot(SNRdB,CDPC_media_iid,':','Color',[0,1,0.9],'LineWidth',1.5)
grid on;
if DL ==1
    legend('MRT','ZF','MMSE','DPC via IWF');
    str = sprintf('Comparativa de capacidad para %d antenas en TX y %d usuarios downlink',ntx,nrx);
else
    legend('MRC','ZF','MMSE','Sum-rate �ptimo');
    str = sprintf('Comparativa de capacidad para %d antenas en TX y %d usuarios uplink',ntx,nrx);
end
title(str);
xlabel('SNR (dB)')
ylabel('Eficiencia espectral (bits/s/Hz)');

