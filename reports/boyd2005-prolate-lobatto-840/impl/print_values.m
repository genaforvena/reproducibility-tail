% print_values.m (our code, written from the registered claim; not part of the authors' tree)
% Calls the authors' TP_LobptswtsPERT for N=6, c=5 and prints the two registered values.
% Run from the Drivers directory after TP_Lobptsts_MAIN has been run, with the authors' Src on the path.
[xprol,wprol]=TP_LobptswtsPERT(6,5);
printf('VALUE xprol(2), N=6, c=5 %.10f\n', xprol(2));
printf('VALUE wprol(3), N=6, c=5 %.10f\n', wprol(3));
