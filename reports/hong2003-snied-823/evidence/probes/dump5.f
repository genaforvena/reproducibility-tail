      PROGRAM DUMP5
      DOUBLE PRECISION UNI, U
      EXTERNAL UNI
      INTEGER I
      DO 10 I = 1,400
          U = UNI()
          WRITE (*,FMT="(I5,1X,E25.17,1X,I5)") I, U, INT(U*1000.0D0)
   10 CONTINUE
      STOP
      END
