addpath(genpath('/work/oct8/share/octave/8.4.0/m'));
addpath('/work/shim');
addpath('/work/fetch/root/usr/share/sdpa/mex');
addpath('/work/fetch/root/usr/lib/sdpa/mex');
addpath('/work/src/920/Matlab/Src');
addpath('/work/src/920/Matlab/Drivers');
load /work/src/920/Matlab/Drivers/examples/example1.mat
whos
pars.free = 0; pars.eps = 1.0e-05; pars.minDegree = 4; pars.objSW = 1; pars.noisyFac = 0;
[xMatrix, info] = SFSDPplus(sDim, noOfSensors, noOfAnchors, xMatrix0, distanceMatrix0, pars);
