C     Reimplemented stand-ins for the NAG Library routines that TOMS 775
C     (src.f, Src/Dp) calls and that the archive does not ship. Written
C     from each routine's documented call semantics (BLAS-style for the
C     F06 matrix routines), not tuned to any output value.
C     Positive increments only (every call in src.f uses 1 or 2).
C     Still missing after this file: C05AZF (zero finder, src.f:853)
C     and DTIME (timing, driver.f). See the report's note.

      DOUBLE PRECISION FUNCTION X01AAF(X)
C     Returns pi.
      DOUBLE PRECISION X
      X01AAF = 4.D0*ATAN(1.D0)
      RETURN
      END

      DOUBLE PRECISION FUNCTION X02AJF(X)
C     Machine precision, assumed 2**-53 for IEEE double (not checked
C     against the NAG value).
      DOUBLE PRECISION X
      X02AJF = 1.1102230246251565D-16
      RETURN
      END

      INTEGER FUNCTION P01ABF(IFO,IFAIL,SRNAME,NREC,REC)
C     Error reporter: prints the message lines and returns IFAIL.
      INTEGER IFO,IFAIL,NREC,I
      CHARACTER*(*) SRNAME
      CHARACTER*(*) REC(*)
C     Like NAG, nothing is reported when IFAIL is 0. The authors' callers
C     (src.f:699, src.f:3632) reach this with NREC and REC unset on the
C     IFAIL=0 path, so REC is only printed for IFAIL nonzero and NREC 1..2.
      IF (IFAIL.NE.0 .AND. NREC.GE.1 .AND. NREC.LE.2) THEN
          WRITE (6,FMT=*) 'NAG shim error in ',SRNAME,' IFAIL=',IFAIL
          DO 10 I = 1,NREC
              WRITE (6,FMT=*) REC(I)
   10     CONTINUE
      END IF
      P01ABF = IFAIL
      RETURN
      END

      SUBROUTINE F06YAF(TRANSA,TRANSB,M,N,K,ALPHA,A,LDA,B,LDB,BETA,C,
     &                  LDC)
C     C := ALPHA*op(A)*op(B) + BETA*C   (general matrix multiply).
      CHARACTER TRANSA,TRANSB
      INTEGER M,N,K,LDA,LDB,LDC
      DOUBLE PRECISION ALPHA,BETA
      DOUBLE PRECISION A(LDA,*),B(LDB,*),C(LDC,*)
      LOGICAL TA,TB
      INTEGER I,J,L
      DOUBLE PRECISION S,AV,BV
      TA = TRANSA.EQ.'T' .OR. TRANSA.EQ.'t' .OR. TRANSA.EQ.'C' .OR.
     &     TRANSA.EQ.'c'
      TB = TRANSB.EQ.'T' .OR. TRANSB.EQ.'t' .OR. TRANSB.EQ.'C' .OR.
     &     TRANSB.EQ.'c'
      DO 30 J = 1,N
          DO 20 I = 1,M
              S = 0.D0
              DO 10 L = 1,K
                  IF (TA) THEN
                      AV = A(L,I)
                  ELSE
                      AV = A(I,L)
                  END IF
                  IF (TB) THEN
                      BV = B(J,L)
                  ELSE
                      BV = B(L,J)
                  END IF
                  S = S + AV*BV
   10         CONTINUE
              IF (BETA.EQ.0.D0) THEN
                  C(I,J) = ALPHA*S
              ELSE
                  C(I,J) = ALPHA*S + BETA*C(I,J)
              END IF
   20     CONTINUE
   30 CONTINUE
      RETURN
      END

      SUBROUTINE F06PAF(TRANS,M,N,ALPHA,A,LDA,X,INCX,BETA,Y,INCY)
C     y := ALPHA*op(A)*x + BETA*y   (general matrix-vector multiply).
      CHARACTER TRANS
      INTEGER M,N,LDA,INCX,INCY
      DOUBLE PRECISION ALPHA,BETA
      DOUBLE PRECISION A(LDA,*),X(*),Y(*)
      LOGICAL NOTR
      INTEGER I,J,LENX,LENY
      DOUBLE PRECISION T
      NOTR = TRANS.EQ.'N' .OR. TRANS.EQ.'n'
      IF (NOTR) THEN
          LENX = N
          LENY = M
      ELSE
          LENX = M
          LENY = N
      END IF
      DO 10 I = 1,LENY
          IF (BETA.EQ.0.D0) THEN
              Y(1+(I-1)*INCY) = 0.D0
          ELSE
              Y(1+(I-1)*INCY) = BETA*Y(1+(I-1)*INCY)
          END IF
   10 CONTINUE
      IF (NOTR) THEN
          DO 30 J = 1,N
              T = ALPHA*X(1+(J-1)*INCX)
              DO 20 I = 1,M
                  Y(1+(I-1)*INCY) = Y(1+(I-1)*INCY) + T*A(I,J)
   20         CONTINUE
   30     CONTINUE
      ELSE
          DO 50 J = 1,N
              T = 0.D0
              DO 40 I = 1,M
                  T = T + A(I,J)*X(1+(I-1)*INCX)
   40         CONTINUE
              Y(1+(J-1)*INCY) = Y(1+(J-1)*INCY) + ALPHA*T
   50     CONTINUE
      END IF
      RETURN
      END

      SUBROUTINE F06QFF(MATRIX,M,N,A,LDA,B,LDB)
C     Copy A to B: MATRIX 'G' whole, 'U' upper triangle, 'L' lower.
      CHARACTER MATRIX
      INTEGER M,N,LDA,LDB,I,J
      DOUBLE PRECISION A(LDA,*),B(LDB,*)
      DO 20 J = 1,N
          DO 10 I = 1,M
              IF (MATRIX.EQ.'G' .OR. (MATRIX.EQ.'U' .AND. I.LE.J) .OR.
     &            (MATRIX.EQ.'L' .AND. I.GE.J)) B(I,J) = A(I,J)
   10     CONTINUE
   20 CONTINUE
      RETURN
      END

      SUBROUTINE F06QHF(MATRIX,M,N,ALPHA,BETA,A,LDA)
C     Set off-diagonal elements of the selected part to ALPHA and the
C     diagonal to BETA.
      CHARACTER MATRIX
      INTEGER M,N,LDA,I,J
      DOUBLE PRECISION ALPHA,BETA,A(LDA,*)
      DO 20 J = 1,N
          DO 10 I = 1,M
              IF (MATRIX.EQ.'G' .OR. (MATRIX.EQ.'U' .AND. I.LE.J) .OR.
     &            (MATRIX.EQ.'L' .AND. I.GE.J)) THEN
                  IF (I.EQ.J) THEN
                      A(I,J) = BETA
                  ELSE
                      A(I,J) = ALPHA
                  END IF
              END IF
   10     CONTINUE
   20 CONTINUE
      RETURN
      END

      REAL FUNCTION DTIME(TARRAY)
C     CPU time since start (user time in TARRAY(1); system time 0).
      REAL TARRAY(2),T1
      CALL CPU_TIME(T1)
      TARRAY(1) = T1
      TARRAY(2) = 0.0
      DTIME = T1
      RETURN
      END

      SUBROUTINE C05AZF(A,B,FA,EPS,ETA,C,IND,IFLAG)
C     Reverse-communication zero finder for the bracket [A,B], used by
C     src.f:853 with the caller's protocol: IND=-1 on the first call,
C     with FA = f(A) and C(1) = f(B). On return with IND=1 the caller
C     evaluates f at A and calls again with FA = f(A). IND=0 means A is
C     the zero. Bisection (robust, slower than Bus-Dekker; the zero is
C     only accurate to EPS in any case).
      INTEGER IND,IFLAG
      DOUBLE PRECISION A,B,FA,EPS,ETA,C(*)
      DOUBLE PRECISION SA,SB,FAS,FBS,XC
      SAVE SA,SB,FAS,FBS,XC
      IFLAG = 0
      IF (IND.EQ.-1) THEN
          SA = A
          SB = B
          FAS = FA
          FBS = C(1)
          IF (FAS*FBS.GT.0.D0) THEN
              IFLAG = 2
              IND = 0
              RETURN
          END IF
      ELSE
          IF (FA.EQ.0.D0) THEN
              A = XC
              IND = 0
              RETURN
          END IF
          IF (FAS*FA.LT.0.D0) THEN
              SB = XC
              FBS = FA
          ELSE
              SA = XC
              FAS = FA
          END IF
          IF (ABS(SB-SA).LE.EPS*MAX(1.D0,ABS(SA))) THEN
              A = 0.5D0*(SA+SB)
              IND = 0
              RETURN
          END IF
      END IF
      XC = 0.5D0*(SA+SB)
      A = XC
      IND = 1
      RETURN
      END
