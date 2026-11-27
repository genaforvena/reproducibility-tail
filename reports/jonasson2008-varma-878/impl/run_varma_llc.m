% The conda Octave build does not put its m-file library on the default path; add it (Octave's own library, not the authors' code).
addpath(genpath('/work/env/share/octave/10.3.0/m'));
% Wrapper around the authors' test_varma_llc loop (compare_with_as311.m), without the as311 column.
% Same RNG seeding and call order as the authors' test: randn('state',1) once, then for each case
% testcase(j) -> varma_sim(A,B,Sig,10) -> varma_llc(X,A,B,Sig,'res'). Prints VALUE lines.
% The authors' Src files are not edited; only the path is set.
addpath('/work/pre/878/Matlab/Src');
addpath('/work/pre/878/Matlab/Tests/test');
ncase = testcase('number');
randn('state', 1);
for j = 1:ncase-2
  [A, B, Sig, name] = testcase(j);
  n = 10;
  X = varma_sim(A, B, Sig, n);
  l = varma_llc(X, A, B, Sig, 'res');
  printf('VALUE varma_llc %s log-likelihood %.9f\n', name, l);
end
