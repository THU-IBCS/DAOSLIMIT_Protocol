function [f1,dx1,x1]=fresnel2D(f0,dx0,z,lambda)
%% Robert's code
%% Reference:  Robert Prevede, Young-Gyu Yoon, Maximilian Hoffmann, Nikita Pak.etc. 
%% "Simultaneous whole-animal 3D imaging of neuronal activity using light-field microscopy " 
%% in Nature Methods VOL.11 NO.7|July 2014.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nx = size(f0,1);
Ny = size(f0,2);
k = 2*pi/lambda;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
du = 1./(Nx*dx0);
u = [0:ceil(Nx/2)-1 ceil(-Nx/2):-1]*du; 
dv = 1./(Ny*dx0);
v = [0:ceil(Ny/2)-1 ceil(-Ny/2):-1]*dv; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = exp(-i*2*pi^2*(repmat(u',1,length(v)).^2+repmat(v,length(u),1).^2)*z/k); 
f1 = exp(i*k*z)*ifft2( fft2(f0) .* H ); 
dx1 = dx0;
x1 = [-Nx/2:Nx/2-1]*dx1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%












