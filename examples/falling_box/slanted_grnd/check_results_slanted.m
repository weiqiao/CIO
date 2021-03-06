% PURPOSE: Analyze results
%
% FILENAME: check_results.m
% AUTHOR:   Roberto Shu
% LAST EDIT: 
%------------------- Instructions ---------------------------

%% ----------------------------------------------------------
%   INITIALIZE WORKSPACE
% -----------------------------------------------------------
% Clear workspace
clc; clear; close all;

% Add paths
addpath('../');
addpath('../../../');
addpath('../../../methods');
addpath('solutions');
addpath('autogenFncs');
addpath('wrapperFncs');
addpath('helperFncs');

%% ----------------------------------------------------------
%   LOAD RESULTS
% -----------------------------------------------------------
data = load('fallingBox_slanted_soln16.mat');
soln = data.soln;

OCP.model.params = params_fallingBox_model;
OCP.model.dynamics = @(t,x,u,lambda)fallingBox_slantedDyn_wrap(t,x,lambda,OCP.model.params);
OCP.compCst = @(Phi,Gamma,t,x,u,lambda)fallingBox_compCst(Phi,Gamma,t,x,u,lambda,OCP.model.params);

%% ----------------------------------------------------------
%   CHECK CONSTRAINT SATISFACTION
% -----------------------------------------------

t = soln.grid.time;
x = soln.grid.state;
u = soln.grid.control;
lambda = soln.grid.lambda;

fallingBox_plotResults2(t,x,lambda)

% Kinematics
[cntc_pts] = fallingBox_slantedKin_wrap(t,x,OCP.model.params);

nCntcPts = size(lambda,1)/2;
figure
idx = 1:2:2*nCntcPts;
for i = 1:nCntcPts
    % X - position
    subplot(nCntcPts,2,idx(i))
    plot(t,cntc_pts(idx(i),:))
    xlabel('Time [sec]')
    ylabel('Pos [m]')
    if i == 1
        title('X-postion co-ordinate')
    end
    % Y - position
    subplot(nCntcPts,2,idx(i)+1)
    plot(t,cntc_pts(idx(i)+1,:))
    xlabel('Time [sec]')
    ylabel('Pos [m]')
    if i == 1
        title('Y-postion co-ordinate')
    end
end

% Forward dynamics
[f, Phi, Psi] = OCP.model.dynamics(t,x,u,lambda(2,:));
figure
plot(t,Phi,'*-')
xlabel('Time [sec]')
ylabel('\Phi(q) [m]');
title('\Phi(q) function value')

% Forward dynamics
[f, Phi, Psi] = OCP.model.dynamics(t,x,u,lambda(2,:));
figure
plot(t,Phi,'*-')
xlabel('Time [sec]')
ylabel('\Phi(q) [m]');
title('\Phi(q) function value')

% Defects
dt = (t(end)-t(1))/(length(t)-1);
defects = euler_mod(dt,x,f);
defectsVec = reshape(defects,numel(defects),1);

figure
plot(1:length(defectsVec),defectsVec,'*-');
ylabel('Magnitude')
title('Dynamics Defects');

% Complementary constraints 
[c_comp, ceq_comp] = OCP.compCst(Phi,Psi,t,x,u,lambda);

nt = length(t);
ceq_lambda = zeros(nt,1);
ceq_slip = zeros(nt,1);
for i = 1:nt
    ceq_lambda(i) = Phi(:,i)'*lambda(2,i);
    ceq_slip(i) = Psi(:,i)'*lambda(1,i);
end

% S.T. positive normal forces
figure
plot(t,ceq_lambda,'*-')
xlabel('Time [sec]')
ylabel('\Phi(q)\lambda_y');
title('\Phi(q)\lambda_y = 0, Lambda equality constraint')

% S.T. No-slip condition
figure
plot(t,ceq_slip,'*-')
xlabel('Time [sec]')
ylabel('\Psi \lambda ');
title('Slip equality constraint')

% S.T. Nonlinear Constraints
figure
subplot(2,1,1)
plot(1:length(ceq_comp),ceq_comp,'*-')
xlabel('Index')
ylabel('Constraint value')
title('Complementary equalities Constraints, ceq(x) = 0')

subplot(2,1,2)
plot(1:length(c_comp),c_comp,'o-')
xlabel('Index')
ylabel('Constraint value')
title('Complementary inequality Constraints, c(x) \leq 0')