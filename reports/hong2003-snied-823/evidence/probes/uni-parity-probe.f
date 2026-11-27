      PROGRAM PAR
      INTEGER I, N
      DOUBLE PRECISION UNI, U
      EXTERNAL UNI
      DO 10 I = 1, 1200
          U = UNI()
          N = INT(U*1000.0)
          WRITE (*,'(I5,1X,I4,1X,I1,1X,E25.17)') I, N, MOD(N,2), U
   10 CONTINUE
      STOP
      END
