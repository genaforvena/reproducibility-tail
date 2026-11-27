% findstr shim: MATLAB findstr (not in Octave 10); the longer string is searched in the shorter
function idx = findstr(s, t)
  if length(s) < length(t), [s, t] = deal(t, s); end
  idx = strfind(s, t);
end
