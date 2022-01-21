function zern_index = estimate_aberration(ideal_psf,experimental_psf,Nnum) % zernike index estimation of system aberration
%% Input:
% @ideal_psf: the maximum iteration number 
% @experimental_psf: the estimated volume
% @Nnum: number of virtual pixels
%% Ouput: 
% zern_index: zernike index estimation of system aberration
%
%   [1]  ZHI LU etc,
%        "A practical guide to scanning light-field microscopy with digital adaptive optics"
%        submitted to Nature Protocols, 2021

% Contact: ZHI LU (luz18@mails.tsinghua.edu.cn)
% Date  : 07/24/2021

ideal_psf=padarray(ideal_psf,[(size(experimental_psf,1)-size(ideal_psf,1))/2, (size(experimental_psf,2)-size(ideal_psf,2))/2]);
shift_kernel=zeros(Nnum,Nnum,2);
for u=1:Nnum
    for v=1:Nnum
        if (u-round(Nnum/2))^2+(u-round(Nnum/2))^2<=36
        corr_map=normxcorr2(ideal_psf(:,:,u,v),experimental_psf(:,:,u,v)); % 2D correlation in the differernt spatial angular compnontes, respectively
        [testa,testb]=find(corr_map==max(corr_map(:)));
        shift_kernel(u,v,1)=testa-size(ideal_psf,1);
        shift_kernel(u,v,2)=testb-size(ideal_psf,2);
        end
    end
end

Nnum = 13;
[Sx,Sy]=meshgrid([-fix(Nnum/2):fix(Nnum/2)],[-fix(Nnum/2):fix(Nnum/2)]);
mask = (Sx.^2+Sy.^2)<=6^2; % maxmium frequency range
shift_kernel(:,:,1) = shift_kernel(:,:,1).*mask;
shift_kernel(:,:,2) = shift_kernel(:,:,2).*mask;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Integrating into wavefronts %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
waveShape = shift_kernel;
waveShape(abs(waveShape)>=50) = 0;
[Nnum,~] = size(waveShape);
r_actual = 9.5;
expand = 5;
waveShape_expand = zeros(expand*Nnum,expand*Nnum,2);
for idu = 1:Nnum
    for idv = 1:Nnum
        waveShape_expand((idu-1)*expand+1:idu*expand,(idv-1)*expand+1:idv*expand,1) = waveShape(idu,idv,1);
        waveShape_expand((idu-1)*expand+1:idu*expand,(idv-1)*expand+1:idv*expand,2) = waveShape(idu,idv,2);
    end
end
[xx,yy] = meshgrid(-(expand*size(waveShape,1)-1)/2:(expand*size(waveShape,1)-1)/2,...
    -(expand*size(waveShape,1)-1)/2:(expand*size(waveShape,1)-1)/2);
mask = xx.^2+yy.^2<=((expand*r_actual/2).^2);
waveShape_expand = waveShape_expand.*mask;
waveShape_expand = waveShape_expand((end+1)/2-round(expand*r_actual/2):(end+1)/2+round(expand*r_actual/2),...
    (end+1)/2-round(expand*r_actual/2):(end+1)/2+round(expand*r_actual/2),:);

ps = 100;

[x1,y1] = meshgrid(1:size(waveShape_expand,1),1:size(waveShape_expand,2));
[x2,y2] = meshgrid(linspace(1,size(waveShape_expand,1),ps),linspace(1,size(waveShape_expand,1),ps));

calcu_dephase = zeros(ps,ps,2);
calcu_dephase(:,:,1)  = interp2(x1,y1,waveShape_expand(:,:,1),x2,y2,'nearest');
calcu_dephase(:,:,2)  = interp2(x1,y1,waveShape_expand(:,:,2),x2,y2,'nearest');

maxIte = 1000;
calcu_phase = intercircle(calcu_dephase,maxIte);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Zernike index fitting %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[rr,cc] = size(calcu_phase);
ra = (rr-1)/2;
[xx,yy]=meshgrid([-ra:ra],[-ra:ra]);
mask = xx.^2+yy.^2<=(ra^2);
calcu_phase_k = -5.83*calcu_phase.*mask;

x=linspace(-1,1,size(calcu_phase_k,1));
y=linspace(-1,1,size(calcu_phase_k,2));
xy=[x;y];
zern_index=lsqcurvefit('SH',zeros(1,21),xy,calcu_phase_k);
zern_index(1:4)=0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

