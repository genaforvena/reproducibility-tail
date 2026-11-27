      PROGRAM DUMP3
      DOUBLE PRECISION UNI
      EXTERNAL UNI
      INTEGER I
      DO 10 I = 1,6
          WRITE (*,FMT=*) I, UNI(), INT(UNI()*1000.0)
   10 CONTINUE
      STOP
      END
