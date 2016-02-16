% PURPOSE: Performance a contact invariant optimization of a 3 link 
%          inverted pendulum model of a bipedal robot
% FILENAME: MAIN.m
% AUTHOR:   Roberto Shu
% LAST EDIT: 
%------------------- Instructions ---------------------------

%% ----------------------------------------------------------
%   INITIALIZE WORKSPACE
% -----------------------------------------------------------
% Clear workspace
clc; clear; close all;

% Add paths
addpath(genpath('../../'));
%% ----------------------------------------------------------
%   MODEL PROPERTIES
%   Intialize your dynamic model parameter values and dyanmics
% -----------------------------------------------------------
OCP.model.params = params_fallingBox_model;
OCP.model.dynamics = @(t,x,u,lambda)fallingBox_dynamics(t,x,lambda,OCP.model.params);

%% ----------------------------------------------------------
%   DEFINE OCP PROBLEM PROPERTIES
% -----------------------------------------------------------

% COST/OBJECTIVE FUNCTIONS
% ------------------------
% e.g.
%   Step cost: OCP.pathCostFnc = @(t,x,u)model_pathcostFnc(t,x,u, OCP.model.params);
%   Terminal cost: OCP.bndCostFnc = @(t,x,u)model_bndcostFnc(t,x,u, OCP.model.params);
OCP.pathCostFnc = [];
OCP.bndCostFnc = @(t,x,u)fallingBox_costFnc(t,x,u,OCP.model.params);;

% INITIAL GUESS
% ------------------------
% Set the type of initial guess:
%   linear: Just define a intial and final state and OptCtrlSolver will
%           make a linear interpolation between the two points
%   custom: The user provides a custom initial guess "shape". 
%           NOTE: custom initial guess has to be descritized with the same
%           size than OCP.options.nGrid
options.IGtype = 'linear';

% Load initial guess
data = load('fallingBox_data.mat');


% Time span
% size: 1x65
t0 = 0;
tF = 2.5;
%OCP.ig.time = [t0,tF];
OCP.ig.time = data.Tsol';

% State 
% x0, xF:   state vector [q;dq] => [2*n X 1] column vector
%   [y; l; dy; dl];
% size: 4x65
OCP.ig.state = data.Xsol;

% Control
% size: 1x65
OCP.ig.control = zeros(1,65);

% Contact forces
% For a given contact point i, the contact force is
%   lambda_i = [lambdaX_i;lambdaZ_i]
% expressed in a frame with X tangent and Z normal to 
% the contact surface.
% If there are m contact points then 
%   lambda = [m x 2]
% size: 2x65
OCP.ig.lambda = [zeros(2,55), 50*ones(2,10)];


% CONSTRAINTS & BOUNDARIES
% ------------------------
 
%----- Nonlinear constraints
% e.g.
% Path:
%   OCP.pathCst = @(t,x,u)pathCst(z);
% Boundary: 
%   OCP.bndCst = @(t0,x0,u0,tF,xF,uF)bndCst(z);
% Complementary:
%   OCP.compCst = @(t0,x0,u0,tF,xF,uF)compCst(z);
OCP.pathCst = [];
%OCP.bndCst = @(t,x,u)fallingBox_bndCst(t,x,u,OCP.model.params);
OCP.bndCst = [];
OCP.compCst = @(Phi,Gamma,t,x,u,lambda)fallingBox_compCst(Phi,Gamma,t,x,u,lambda,OCP.model.params);


%----- Linear constraints
% You can let time to be free by not setting any bounds on the final time
OCP.bounds.initTime.lb = t0;
OCP.bounds.initTime.ub = t0;
OCP.bounds.finalTime.lb = tF;
OCP.bounds.finalTime.ub = tF;

% State:
%   [x; y; dx; dy];
%  
OCP.bounds.state.lb = [-10; -50; -inf(2,1)]; 
OCP.bounds.state.ub = [10; 50; inf(2,1)];
OCP.bounds.initState.lb = [0; -50; 0;0];
OCP.bounds.initState.ub = [0; 40; 0;0];
OCP.bounds.finalState.lb = [-10; -50; -inf(2,1)];
OCP.bounds.finalState.ub = [20; 50; inf(2,1)];

% Control:
%%TODO
% Change so they are set from model parametes
maxTau = 500;
OCP.bounds.control.lb = 0; 
OCP.bounds.control.ub = maxTau;

% Contact forces:
OCP.bounds.lambda.lb = -inf(2,1);
OCP.bounds.lambda.ub = inf(2,1);

%% ----------------------------------------------------------
%   SOLVER OPTIONS
% -----------------------------------------------------------

%%% TODO
% add capability for other methods
%method = 'euler';
method = 'euler_mod';
% method = 'trapezoidal';
% method = 'hermiteSimpson';

%--- Interation 1
options(1).method = 'euler_mod';
options(1).nGrid = 20;

%--- Interation 2
options(2).method = 'euler_mod';
options(2).nGrid = 65;


% For a full list of options refer to :
%   http://www.mathworks.com/help/optim/ug/fmincon.html#inputarg_options
%%% TODO setting options here is not working need to see why
OCP.options.fminOpt.MaxFunEval = 1e5;

% Display initial guess
%displayIGnBnds(OCP.ig,OCP.bounds,OCP.options(1).nGrid);
%% ----------------------------------------------------------
%   SOLVE NLP PROBLEM
% -----------------------------------------------------------

for iter = 1:size(options,2)
    
    % Set options to pass to solver
    OCP.options = options(iter);
    
    % Solve Optimal control problem
    soln = OptCtrlSolver(OCP);
    
    % Update initial condition
    OCP.ig = soln.grid;
end

tGrid = soln(end).grid.time;
t = linspace(tGrid(1),tGrid(end),100);
z = soln(end).interp.state(t);
u = soln(end).interp.control(t);
tgrid = soln(end).grid.time;
zgrid = soln(end).grid.state;
ugrid = soln(end).grid.control;
lambda = soln(end).grid.lambda;
guess = soln(end).guess;


Notes = 'Revised complementary constraint calculation';
save('fallingBox_soln5.mat','soln','OCP','Notes')
%% ----------------------------------------------------------
%   PLOT RESULTS
% -----------------------------------------------------------
dyn = OCP.model.params;

% Initial guess
figure
subplot(4,1,1)
plot(guess.time,guess.state(2,:))
xlabel('Time [sec]');
ylabel('Pos [m]');

subplot(4,1,2)
plot(guess.time,guess.state(4,:))
xlabel('Time [sec]');
ylabel('Velocity [m/sec]');

subplot(4,1,3)
plot(guess.time,guess.control)
xlabel('Time [sec]');
ylabel('U control input');

subplot(4,1,4)
plot(guess.time,guess.lambda(1,:),guess.time,guess.lambda(2,:))
xlabel('Time [sec]');
ylabel('Lambda');

% Solution 
figure
subplot(3,2,1)
plot(tgrid,zgrid(2,:));
xlabel('Time [sec]');
ylabel('Post [m]');
title('Vertical direction')

subplot(3,2,3)
plot(tgrid,zgrid(4,:));
xlabel('Time [sec]');
ylabel('Vel. [m/sec]');

subplot(3,2,5)
plot(tgrid,lambda(2,:))
xlabel('Time [sec]');
ylabel('Lambda');

subplot(3,2,2)
plot(tgrid,zgrid(1,:));
xlabel('Time [sec]');
ylabel('Pos [m]');
title('Horizontal direction')

subplot(3,2,4)
plot(tgrid,zgrid(3,:));
xlabel('Time [sec]');
ylabel('Vel.[m/sec]');

subplot(3,2,6)
plot(tgrid,lambda(1,:))
xlabel('Time [sec]');
ylabel('Lambda');


% Animate the results:
% A.plotFunc = @(t,z)( drawModel(t,z,dyn) );
% A.speed = 0.25;
% A.figNum = 101;
% animate(t,z,A)

%%% TODO
% Draw a stop-action animation: