function [params] = params_hopper_1D_model
% params parametrs

%
%
% Parameters based on robot described in:
% [1] Remy, C. David, Keith Buffinton, and Roland Siegwart. 
%     "Comparison of cost functions for electrically driven 
%      running robots." Robotics and Automation (ICRA), 2012 
%      IEEE International Conference on. IEEE, 2012.
%
%---- ENVIRONMENT
g = 9.81;       % Gravity [m/s^2]

params.g = g;
params.mu = 0.7; %0.6 - 0.851

%---- GEOMETRY
l0 = 0.4;       %[m]

% Link length
params.l0 = l0;
params.l2 = 0.25*l0;
params.l3 = 0.25*l0;
params.rfoot = 0.05*l0;

%---- MASS
m0 = 5;         % [kg]
params.m1 = 0.85*m0;
params.m2 = 0.1*m0;
params.ml = 1*m0;

%---- MOMENT OF INERTIA
params.I1 = 0.5*m0*l0^2;
params.I2 = 0.002*m0*l0^2;
params.I3 = 0.002*m0*l0^2;

%---- Other
k = 10*m0*g/l0;
bc = 2*sqrt(k*m0);
zeta = 0.2;
params.k = k;
params.b = zeta*bc; 
params.zetal = zeta;
params.kalpha = 5*m0*g*l0;
params.zetaalpha = 0.2;

end

