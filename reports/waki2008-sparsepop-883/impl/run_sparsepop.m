% Driver: the authors' sparsePOP.m on the archive's example1.gms, relaxOrder 3, SeDuMi eps 1e-9
% (parameters from Doc/UserManual/sect3.tex). Path entries only: no author file is edited.
addpath("/work/shim");
M = "/work/octave/share/octave/10.3.0/m";
addpath([M "/strings"]);
addpath([M "/general"]);
addpath([M "/elfun"]);
addpath([M "/set"]);
addpath([M "/linear-algebra"]);
addpath([M "/specfun"]);
addpath([M "/sparse"]);
addpath([M "/polynomial"]);
addpath([M "/special-matrix"]);
addpath([M "/time"]);
addpath([M "/io"]);
addpath([M "/miscellaneous"]);
addpath("/work/sedumi-src/sedumi-master");
addpath("/work/pre/883/SparsePOP200");
addpath(genpath("/work/pre/883/SparsePOP200/subPrograms"));
cd /work/run
param.relaxOrder = 3;
param.SeDuMiEpsilon = 1e-9;
[param, SDPobjValue, POP] = sparsePOP("example1.gms", param);
printf("VALUE POP.objValue %.10g\n", POP.objValue);
printf("SDPobjValue %.10g\n", SDPobjValue);
