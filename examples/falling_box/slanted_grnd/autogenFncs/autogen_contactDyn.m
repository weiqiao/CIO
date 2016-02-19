function [Phi,Psi,J] = autogen_contactDyn(x,y,th,dx,dy,dth,w,h,m,I,g,a,c)
%AUTOGEN_CONTACTDYN
%    [PHI,PSI,J] = AUTOGEN_CONTACTDYN(X,Y,TH,DX,DY,DTH,W,H,M,I,G,A,C)

%    This function was generated by the Symbolic Math Toolbox version 6.3.
%    18-Feb-2016 17:31:13

Phi = h.*(-1.0./2.0)+y;
if nargout > 1
    Psi = dy;
end
if nargout > 2
    J = [0.0,1.0,0.0];
end
