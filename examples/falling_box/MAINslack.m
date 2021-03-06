% PURPOSE: Performance a contact invariant optimization of a box
%          with 3 contact points falling on a slope
% FILENAME: MAIN.m
% AUTHOR:   Roberto Shu
% LAST EDIT: 2/16/16
%------------------- Instructions ---------------------------

%% ----------------------------------------------------------
%   INITIALIZE WORKSPACE
% -----------------------------------------------------------
% Clear workspace
clc; clear; close all;

% Add paths
addpath(genpath('../../..'));
addpath('solutions');
addpath('autogenFncs');
addpath('wrapperFncs');
addpath('helperFncs');
%% ----------------------------------------------------------
%   MODEL PROPERTIES
%   Intialize your dynamic model parameter values and dyanmics
% -----------------------------------------------------------
OCP.model.params = params_fallingBox_model;
OCP.model.dynamics = @(t,x,u,lambda)fallingBox_slantedDyn_wrap(t,x,lambda,OCP.model.params);

%% ----------------------------------------------------------
%   DEFINE OCP PROBLEM PROPERTIES
% -----------------------------------------------------------

% COST/OBJECTIVE FUNCTIONS
% ------------------------
% e.g.
%   Step cost: OCP.pathCostFnc = @(t,x,u)model_StepCostFnc(t,x,u, OCP.model.params);
%   Terminal cost: OCP.bndCostFnc = @(t,x,u)model_TerminalcostFnc(t,x,u, OCP.model.params);
OCP.pathCostFnc = [];
OCP.bndCostFnc = @(t,x,u)fallingBox_costFnc(t,x,u,OCP.model.params);

% INITIAL GUESS
% ------------------------

% Load initial guess
data = load('fallingBox_slanted_soln1.mat');
data = data.soln.grid;

% Time span
t0 = 0;
tF = 2.5;
%OCP.ig.time = [t0,tF];
OCP.ig.time = data.time;

% State 
% x0, xF:   state vector [q;dq] => [2*n X 1] column vector
%   [x; y; th; dx; dy; dth];
OCP.ig.state = [ zeros(1,size(data.state,2));...
                data.state(2,:);...
                zeros(2,size(data.state,2));...
                data.state(4,:);...
                zeros(1,size(data.state,2))];
%OCP.ig.state = data.state;

% Control input
OCP.ig.control = zeros(1,size(data.state,2));

% Contact forces
% For a given contact point i, the contact force is
%   lambda_i = [lambdaX_i;lambdaY_i]
% expressed in a frame with X tangent and Y normal to 
% the contact surface.
% If there are m contact points then 
%   lambda = [2m x nt]

lambdaXp = zeros(1,size(data.state,2));
lambdaXn = zeros(1,size(data.state,2));

lambdaY = data.lambda(4,:);

OCP.ig.lambda = [lambdaXp;lambdaXn;lambdaY];
%OCP.ig.lambda = data.lambda;

% Slack varaibles
OCP.ig.slacks = zeros(1,size(data.state,2));

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
OCP.bndCst = [];
OCP.compCst = @(Phi,Gamma,t,x,u,lambda,slacks)fallingBox_compCst_wSlacks(Phi,Gamma,t,x,u,lambda,slacks,OCP.model.params);


%----- Linear constraints
% You can let time to be free by not setting any bounds on the final time
OCP.bounds.initTime.lb = t0;
OCP.bounds.initTime.ub = t0;
OCP.bounds.finalTime.lb = tF;
OCP.bounds.finalTime.ub = tF;

% State:
OCP.bounds.state.lb = [-10; -50; -2*pi; -inf(3,1)]; 
OCP.bounds.state.ub = [10; 50; 2*pi; inf(3,1)];
OCP.bounds.initState.lb = [0; 2; 0; 0; 0;0];
OCP.bounds.initState.ub = [0; 5; 0; 0; 0;0];
OCP.bounds.finalState.lb = [-10; -50; -2*pi; -inf(3,1)];
OCP.bounds.finalState.ub = [10; 50; 2*pi; inf(3,1)];

% Control:
%%TODO
% Change so they are set from model parametes
maxTau = 500;
OCP.bounds.control.lb = -inf(1,1); 
OCP.bounds.control.ub = inf(1,1);

% Contact forces:
OCP.bounds.lambda.lb = -inf(3,1);
OCP.bounds.lambda.ub = inf(3,1);

% Slack variable gamma:
OCP.bounds.slacks.lb = -inf(1,1);
OCP.bounds.slacks.ub = inf(1,1);

%% ----------------------------------------------------------
%   SOLVER OPTIONS
% -----------------------------------------------------------
%%% TODO
% add capability for other methods
%method = 'euler';
method = 'euler_mod';
% method = 'trapezoidal';
% method = 'hermiteSimpson';
fminOpt = optimoptions('fmincon','Display','iter','Algorithm','sqp','MaxIter',1e4,'MaxFunEvals',1e6,'TolFun',1e-6);
%--- Interation 1
options(1).method = 'euler_mod';
options(1).nGrid = 20;
options(1).fminOpt = fminOpt;

%--- Interation 2
% options(2).method = 'euler_mod';
% options(2).nGrid = 25;
% options(2).fminOpt = fminOpt;

%--- Interation 3
%options(3).method = 'euler_mod';
%options(3).nGrid = 50;
%options(3).fminOpt = fminOpt;

% For a full list of options refer to :
%   http://www.mathworks.com/help/optim/ug/fmincon.html#inputarg_options
%%% TODO setting options here is not working need to see why

% Display initial guess
displayIGnBnds(OCP.ig,OCP.bounds,options(1).nGrid);
%% ----------------------------------------------------------
%   SOLVE NLP PROBLEM
% -----------------------------------------------------------

for iter = 1:size(options,2)
    fprintf('--------- Optimization Pass No.: %d ---------',iter)
    % Set options to pass to solver
    OCP.options = options(iter);
    
    % Solve Optimal control problem
    tic;
    soln = OptCtrlSolver_wSlacks(OCP);
    time = toc;
    
    % save time of optimization
    soln.time = time;
    
    % Update initial condition
    OCP.ig = soln.grid;
end

t = soln(end).grid.time;
z = soln(end).grid.state;
u = soln(end).grid.control;
lambda = soln(end).grid.lambda;
guess = soln(end).guess;

Notes = 'With augmented Phi function to include theta';
save('solutions/fallingBox_slanted_soln7.mat','soln','OCP','Notes')
%% ----------------------------------------------------------
%   PLOT RESULTS
% -----------------------------------------------------------

% Plot results
fallingBox_plotResults2(t,z,lambda)

% Animate the results:
% A.plotFunc = @(t,z)( drawModel(t,z,dyn) );
% A.speed = 0.25;
% A.figNum = 101;
% animate(t,z,A)

%%% TODO
% Draw a stop-action animation:
