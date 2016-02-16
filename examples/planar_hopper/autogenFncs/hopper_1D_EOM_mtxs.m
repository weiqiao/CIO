function [D_mtx,C_mtx,G_vec,B_mtx,u_vec,Phi_vec,J_mtx,F] = hopper_1D_EOM_mtxs(y,l,ul,dy,dl,dul,taul,l0,k,b,m1,m2,ml,g)
%HOPPER_1D_EOM_MTXS
%    [D_MTX,C_MTX,G_VEC,B_MTX,U_VEC,PHI_VEC,J_MTX,F] = HOPPER_1D_EOM_MTXS(Y,L,UL,DY,DL,DUL,TAUL,L0,K,B,M1,M2,ML,G)

%    This function was generated by the Symbolic Math Toolbox version 6.3.
%    29-Jan-2016 02:24:22

D_mtx = reshape([m1,0.0,0.0,0.0,m2,0.0,0.0,0.0,ml],[3,3]);
if nargout > 1
    C_mtx = reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[3,3]);
end
if nargout > 2
    G_vec = [g.*(m1+m2);-g.*m2;0.0];
end
if nargout > 3
    B_mtx = reshape([0.0,1.0,0.0,0.0,0.0,1.0],[3,2]);
end
if nargout > 4
    t2 = dl-dul;
    t3 = -l+l0+ul;
    t4 = k.*t3;
    t5 = t4-b.*t2;
    u_vec = [t5;taul];
end
if nargout > 5
    Phi_vec = -l+y;
end
if nargout > 6
    J_mtx = [1.0,-1.0,0.0];
end
if nargout > 7
    F = t5;
end