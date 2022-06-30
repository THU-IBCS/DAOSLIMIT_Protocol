function calcu_phase = intercircle(calcu_dephase,maxIte) % 2D discrete intergration using the iterative method
%% Input:
% @calcu_dephase: the 2D differential of the phase 
% @maxIte: the maximum iteration times
%% Ouput: 
% calcu_phase: 2D phase calculated by intergration
%
%   [1]  ZHI LU etc,
%        "A practical guide to scanning light-field microscopy with digital adaptive optics"
%        Nature Protocols, 2022

% Contact: ZHI LU (luz18@mails.tsinghua.edu.cn)
% Date  : 07/24/2021

[rr,cc,~] = size(calcu_dephase);
ddx = 1/rr;
ddy = 1/cc;
dfx=squeeze(calcu_dephase(:,:,1));
dfy=squeeze(calcu_dephase(:,:,2));
ra = (rr-1)/2;
[X,Y]=meshgrid([-ra:ra],[-ra:ra]);
dfx( (X.^2+Y.^2)>(ra)^2 )=0;
dfy( (X.^2+Y.^2)>(ra)^2 )=0;
mask = X.^2+Y.^2<=(ra^2); % maxmium frequency range

calcu_phase=zeros(size(calcu_dephase,1),size(calcu_dephase,2));
centerX = (rr+1)/2;
centerY = (rr+1)/2;

Nnum=rr;
for u=1:Nnum
    for v=1:Nnum % for different spatial angular components, respectively 
        if(mask(u,v)==0)
            continue;
        end
        record = 0;
        count = 0;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%% 2D Integration %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for i = 1:maxIte
            step = zeros(1,u+v-2);
            sr = v-1;
            sd = u-1;
            cs=randperm(length(step));
            step(cs(1:sr)) = 1;
            r2 = 0;
            rr = 1;
            cc = 1;
            for ids = 1:length(step)
                if(step(ids)==1)
                    r2 = r2+dfy(rr,cc)*ddy;
                    cc = cc+1;
                else
                    r2 = r2+dfx(rr,cc)*ddx;
                    rr = rr+1;
                end
                
            end
            record = record+r2;
        end
        calcu_phase(u,v) = record/(maxIte);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
       
        
    end
end
calcu_phase( (X.^2+Y.^2)>ra^2 )=0;
end

