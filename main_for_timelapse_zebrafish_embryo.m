% Pre-processes and 3D reconstruciton demo with DAO (for time-lapse data)
% The Code is created based on the method described in the following paper 
%   [1]  ZHI LU etc,
%        "A practical guide to scanning light-field microscopy with digital adaptive optics"
%        Nature Protocols, 2022 
%   [2]  JIAMIN WU, ZHI LU and DONG JIANG etc,
%        Iterative tomography with digital adaptive optics permits hour-long intravital observation of 3D subcellular dynamics at millisecond scale
%        Cell, 2021. 
% 
%    Contact: ZHI LU (luz18@mails.tsinghua.edu.cn)
%    Date  : 10/01/2021

clear;

addpath('./Solver/');
addpath('./Util/');

% Preparameters
GPUcompute=1; %% GPU accelerator (on/off)
filepath='Data'; %% the filepath of raw scanning light field data, download from Google Drive (xxxx)!!!!!!
Nnum=13; %% the number of sensor pixels after each microlens/ the number of angles in one dimension
maxIter=1; %% the maximum iteration number of single frame
time_weight_index=0.9; %% timeweighted coefficient, ranging from 0 to 1

minFrame=0; %% the started frame
maxFrame=80; %% the end frame
Fstep=1; %% the spacing between adjacent frames


% Auto-registration pixel realignment
RawDir='Data';
[realignFolder,Nshift] = Auto_realignment(RawDir, Nnum);%% the sampling points of a single scanning period

% PSF
load('PSF/Calibrated_psf_M69.3_NA1.4_zmin-10u_zmax10u.mat');
weight=squeeze(sum(sum(sum(psf,1),2),5))./sum(psf(:));
weight=weight-min(weight(:));
weight=weight./max(weight(:)).*0.8;
for u=1:Nnum
    for v=1:Nnum
        if (u-round(Nnum/2))^2+(v-round(Nnum/2))^2>(round(Nnum/3))^2 
            weight(u,v)=0;
        end
    end
end

Fcount=minFrame;
for frame = [minFrame: Fstep: maxFrame, maxFrame: -Fstep: minFrame] %% time-loop
    
    % Load spatial angular components
    WDF=zeros(183,183,Nnum,Nnum);
    for u=1:Nnum
        for v=1:Nnum
            tmp=single(imread(['Data_realign/embryo_3x3_300.0ms_Full_Hardware_LaserCount1_200404214338__0/realign/test_No',num2str(frame),'.tif'],(u-1)*Nnum+v));
            WDF(:,:,u,v)=tmp(202:202+182,226:226+182); %% content-aware FOV
        end
    end
    % Time-weighted
    index_map=imread([num2str(Nshift),'x3.conf.sk.png']);
    index1=zeros(1,Nshift*Nshift);
    index2=zeros(1,Nshift*Nshift);
    for i=1:Nshift*Nshift
        [index1(i),index2(i)]=find(index_map==i-1);
    end
    WDF=time_weighted(WDF,time_weight_index,index1,index2,Nshift,Nnum,frame);
    

    % Initialization
    WDF=imresize(WDF,[size(WDF,1)*Nnum/Nshift,size(WDF,2)*Nnum/Nshift]);
    if frame==minFrame && Fcount==minFrame
        Xguess=ones(size(WDF,1),size(WDF,2),size(psf,5));
        Xguess=Xguess./sum(Xguess(:)).*sum(WDF(:))./(size(WDF,3)*size(WDF,4));
    else
        % replace the uniform initial value with the reconstructed result of the previous frame
        Xguess=0.5 .* (Xguess+ones(size(Xguess)).*sum(Xguess(:))./numel(Xguess)); 
    end
    
    if Fcount==minFrame || Fcount==minFrame+Fstep
        DAO = 0; %% DAO off, when just <=2 frame were deconvolved in time-loop
    else
        DAO = 1; %% DAO on, after 2 frames were deconvolved in time-loop
    end
    Nb=1;      %% Number of blocks for multi-site AO in one dimension
    
    % 3D deconvolution with DAO
    tic;
    Xguess = deconvRL_TimeSeries(maxIter, Xguess,WDF, psf,weight,DAO,Nb,GPUcompute);
    ttime = toc;
    disp(['  Frame = ' num2str(frame) , ' took ', num2str(ttime), ' secs']);    
    
    % save high-resolution reconstructed volume
    mkdir('Data_Recon3D/20200404_zebrafish_embryo');
    if Fcount<=maxFrame
        % no need to save the middle results of time-loop algorithm
%         imwriteTFSK(single(gather(Xguess(26:end-25,26:end-25,11:end-10))),['Data_Recon3D/20200404_zebrafish_embryo/Frame',num2str(frame),'.tif']);   %% crop volume edge and save it
    else
        imwriteTFSK(single(gather(Xguess(26:end-25,26:end-25,11:end-10))),['Data_Recon3D/20200404_zebrafish_embryo/Timeloop_Frame',num2str(frame),'.tif']);  %% crop volume edge and save it
    end
    Fcount=Fcount+Fstep;
end

