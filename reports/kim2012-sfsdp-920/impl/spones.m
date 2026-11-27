function B = spones(S)
% Compatibility shim: MATLAB builtin spones(S), which the conda-forge Octave 10.3
% build does not provide. Returns a sparse matrix of the size of S with a 1 at
% every nonzero position of S and 0 elsewhere (MATLAB semantics).
[i, j] = find(S);
B = sparse(i, j, ones(size(i)), size(S, 1), size(S, 2));
end
