function z = SH(c,data) % Zernike polynomial generation
%% Input:
% @c: Zernike index
% @data: 2D meshgrid
%% Ouput: 
% z: zernike polynomial
%
%   [1]  ZHI LU etc,
%        "A practical guide to scanning light-field microscopy with digital adaptive optics"
%        submitted to Nature Protocols, 2021

% Contact: ZHI LU (luz18@mails.tsinghua.edu.cn)
% Date  : 07/24/2021

x=data(1,:);
y=data(2,:);
[X,Y]=meshgrid(x,y);
[theta,r]=cart2pol(X,Y); % polar coordinates
idx=r<=1;
zz=zeros(size(X));

b = c(1:4);
a = c(5:end);

zz(idx)=b(1)*zernfun(0,0,r(idx),theta(idx))+b(2)*zernfun(1,1,r(idx),theta(idx))+b(3)*zernfun(1,-1,r(idx),theta(idx))+b(4)*zernfun(2,0,r(idx),theta(idx))+...
a(1)*zernfun(2,2,r(idx),theta(idx))+a(2)*zernfun(2,-2,r(idx),theta(idx))+a(3)*zernfun(3,1,r(idx),theta(idx))+...
a(4)*zernfun(3,-1,r(idx),theta(idx))+a(5)*zernfun(3,3,r(idx),theta(idx))+a(6)*zernfun(3,-3,r(idx),theta(idx))+...
a(7)*zernfun(4,0,r(idx),theta(idx))+a(8)*zernfun(4,2,r(idx),theta(idx))+a(9)*zernfun(4,-2,r(idx),theta(idx))+...
a(10)*zernfun(4,4,r(idx),theta(idx))+a(11)*zernfun(4,-4,r(idx),theta(idx))+a(12)*zernfun(5,1,r(idx),theta(idx))+...
a(13)*zernfun(5,-1,r(idx),theta(idx))+a(14)*zernfun(5,3,r(idx),theta(idx))+a(15)*zernfun(5,-3,r(idx),theta(idx))+...
a(16)*zernfun(5,5,r(idx),theta(idx))+a(17)*zernfun(5,-5,r(idx),theta(idx));


z=zz;