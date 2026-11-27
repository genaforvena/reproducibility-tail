% Worked example from Doc/readme.txt section 3, run as written by the authors.
% Harness only: it calls the authors' multroot on the authors' example polynomial and prints one
% "VALUE <name> <number>" line per claimed value (names as in result.json).
% Octave-only environment step: this conda build's default load path lacks its own m-library
% (poly, strjoin undefined; see evidence/original-attempt-octave-nopath.log). Add the library and the
% authors' directories.
addpath(genpath('/work/octave/share/octave/10.3.0/m'));
addpath('/work/tree/Matlab/Src');
addpath('/work/tree/Matlab/Drivers');
f = poly([ones(1,20),2*ones(1,20),3*ones(1,10),4*ones(1,5)]);
z = multroot(f);
disp(z)
% The claim is the same numbers split per root: multiplicity exact (tol 0), root within 1e-9.
for target = [4 3 2 1]
  [dmin, k] = min(abs(z(:,1) - target));
  printf('VALUE mult_root_%d %d\n', target, z(k,2));
  printf('VALUE root_%d %.15g\n', target, z(k,1));
end
