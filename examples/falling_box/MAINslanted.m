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

% Define folder names
subFolderName = 'slanted_grnd';
solnFolderName = fullfile(subFolderName,'solutions');

% Add paths
addpath('../../');
addpath('../../methods');
addpath(solnFolderName );
addpath(subFolderName);
addpath(fullfile(subFolderName,'autogenFncs'));
addpath(fullfile(subFolderName,'wrapperFncs'));
addpath(fullfile(subFolderName,'helperFncs'));
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
%data = load('fallingBox_slanted_soln1.mat');
data = load('fallingBox_IG.mat');
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
OCP.ig.control = data.control;

% Contact forces
% For a given contact point i, the contact force is
%   lambda_i = [lambdaX_i;lambdaY_i]
% expressed in a frame with X tangent and Y normal to 
% the contact surface.
% If there are m contact points then 
%   lambda = [2m x nt]

%lambdaX = [data.lambda(1,:);data.lambda(1,:);data.lambda(1,:)];
lambdaX = data.lambda(1,:);

%lambdaY = [data.lambda(2,:);data.lambda(2,:);data.lambda(2,:)];
lambdaY = data.lambda(2,:);

OCP.ig.lambda = [lambdaX;lambdaY];
%OCP.ig.lambda = data.lambda;

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
OCP.compCst = @(Phi,Gamma,t,x,u,lambda)fallingBox_compCst(Phi,Gamma,t,x,u,lambda,OCP.model.params);

%----- Linear constraints
% You can let time to be free by not setting any bounds on the final time
OCP.bounds.initTime.lb = t0;
OCP.bounds.initTime.ub = t0;
OCP.bounds.finalTime.lb = tF;
OCP.bounds.finalTime.ub = tF;

% State:
OCP.bounds.state.lb = [-10; -50; -2*pi*0; -inf(3,1)]; 
OCP.bounds.state.ub = [10; 50; 2*pi*0; inf(3,1)];
OCP.bounds.initState.lb = [0; -50; 0; 0; 0;0];
OCP.bounds.initState.ub = [0; 40; 0; 0; 0;0];
OCP.bounds.finalState.lb = [-10; -50; -2*pi*0; -inf(3,1)];
OCP.bounds.finalState.ub = [10; 50; 2*pi*0; inf(3,1)];

% Control:
%%TODO
% Change so they are set from model parametes
maxTau = 500;
OCP.bounds.control.lb = -inf(1,1); 
OCP.bounds.control.ub = inf(1,1);

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

% Fmincon options:
% for a full list of options refer to :
%   http://www.mathworks.com/help/optim/ug/fmincon.html#inputarg_options
fminOpt = optimoptions('fmincon','Display','iter','Algorithm','sqp','MaxIter',3e3,'MaxFunEvals',1e4,'TolFun',1e-6);

%--- Interation 1
options(1).method = 'euler_back';
options(1).nGrid = 20;
options(1).fminOpt = fminOpt;
options(1).fminOpt.TolCon = 0.01;

% %--- Interation 2
% options(2).method = 'euler_mod';
% options(2).nGrid = 50;
% options(2).fminOpt = fminOpt;
% options(2).fminOpt.MaxFunEvals = 5e4;

% %--- Interation 3
%options(3).method = 'euler_mod';
%options(3).nGrid = 50;
%options(3).fminOpt = fminOpt;
%options(3).fminOpt.MaxFunEvals = 5e6;

% Display initial guess
%displayIGnBnds(OCP.ig,OCP.bounds,options(1).nGrid);
%% ----------------------------------------------------------
%   SOLVE NLP PROBLEM
% -----------------------------------------------------------
soln(length(options)) = struct('info',[],'grid',[],'interp',[],'guess',[],'time',[]);
for iter = 1:size(options,2)
    fprintf('--------- Optimization Pass No.: %d ---------\n',iter)
    % Set options to pass to solver
    OCP.options = options(iter);
    
    % Solve Optimal control problem
    tic;
    soln(iter) = OptCtrlSolver(OCP);
    time = toc;
    
    % save time of optimization
    soln(iter).time = time;
    
    % Update initial condition
    OCP.ig = soln(iter).grid;
end

t = soln(end).grid.time;
z = soln(end).grid.state;
u = soln(end).grid.control;
lambda = soln(end).grid.lambda;
guess = soln(end).guess;

% Save results
% fileName = 'fallingBox_slanted_soln';
% overWrite = 1;
% Notes = 'Phi(x,y,theta), 1 contact point';
% saveResults(solnFolderName, fileName, overWrite, soln,OCP,Notes)
%% ----------------------------------------------------------
%   PLOT RESULTS
% -----------------------------------------------------------

% Plot results
fallingBox_plotResults(t,z,lambda)

% Animate the results:
% A.plotFunc = @(t,z)( drawModel(t,z,dyn) );
% A.speed = 0.25;
% A.figNum = 101;
% animate(t,z,A)

%%% TODO
% Draw a stop-action animation:
