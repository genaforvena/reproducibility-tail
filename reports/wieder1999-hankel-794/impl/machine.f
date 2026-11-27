C     Machine constants for the TOMS 794 driver (rerun wrapper, not part of the authors' archive).
C     The archive's Doc/PackingList says SrcLibs: port, but the archive does not ship the PORT
C     library, so D1MACH and I1MACH are missing at link time (see evidence/original-attempt-link.log).
C     These are the IEEE 754 double-precision values that the PORT library documents for IEEE
C     machines, written from that description. They are fixed before any run and are not tuned
C     to the shipped value.
C
C     D1MACH(1) smallest positive normalized, D1MACH(2) largest finite,
C     D1MACH(3) 2**-53 (unit roundoff), D1MACH(4) 2**-52 (machine epsilon), D1MACH(5) log10(2).
C     I1MACH(1) standard input unit, I1MACH(2) standard output unit, I1MACH(3) punch unit,
C     I1MACH(4) standard error unit.
C
      DOUBLE PRECISION FUNCTION D1MACH(I)
      INTEGER I
      IF (I.EQ.1) THEN
         D1MACH = 2.2250738585072014D-308
      ELSE IF (I.EQ.2) THEN
         D1MACH = 1.7976931348623157D+308
      ELSE IF (I.EQ.3) THEN
         D1MACH = 1.1102230246251565D-16
      ELSE IF (I.EQ.4) THEN
         D1MACH = 2.2204460492503131D-16
      ELSE IF (I.EQ.5) THEN
         D1MACH = 0.30102999566398119521D0
      ELSE
         STOP 'D1MACH: I OUT OF BOUNDS'
      END IF
      RETURN
      END

      INTEGER FUNCTION I1MACH(I)
      INTEGER I
      IF (I.EQ.1) THEN
         I1MACH = 5
      ELSE IF (I.EQ.2) THEN
         I1MACH = 6
      ELSE IF (I.EQ.3) THEN
         I1MACH = 6
      ELSE IF (I.EQ.4) THEN
         I1MACH = 0
      ELSE
         STOP 'I1MACH: I OUT OF BOUNDS'
      END IF
      RETURN
      END
