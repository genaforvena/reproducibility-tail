addpath(genpath('/work/oct8/share/octave/8.4.0/m'));
addpath('/work/fetch/root/usr/share/sdpa/mex');
addpath('/work/fetch/root/usr/lib/sdpa/mex');
A = 1; b = 1; c = 1; K.s = 1;
[x, y, info] = sedumiwrap(sparse(A), b, c, K, [], []);
disp(x); disp(y);
