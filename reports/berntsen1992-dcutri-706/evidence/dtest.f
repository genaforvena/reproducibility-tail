C ---- extracted from listing lines 72-424: D1MACH
      DOUBLE PRECISION FUNCTION D1MACH(I)
C
C  DOUBLE-PRECISION MACHINE CONSTANTS
C
C  D1MACH( 1) = B**(EMIN-1), THE SMALLEST POSITIVE MAGNITUDE.
C
C  D1MACH( 2) = B**EMAX*(1 - B**(-T)), THE LARGEST MAGNITUDE.
C
C  D1MACH( 3) = B**(-T), THE SMALLEST RELATIVE SPACING.
C
C  D1MACH( 4) = B**(1-T), THE LARGEST RELATIVE SPACING.
C
C  D1MACH( 5) = LOG10(B)
C
C  TO ALTER THIS FUNCTION FOR A PARTICULAR ENVIRONMENT,
C  THE DESIRED SET OF DATA STATEMENTS SHOULD BE ACTIVATED BY
C  REMOVING THE C FROM COLUMN 1.
C  ON RARE MACHINES A STATIC STATEMENT MAY NEED TO BE ADDED.
C  (BUT PROBABLY MORE SYSTEMS PROHIBIT IT THAN REQUIRE IT.)
C
C  FOR IEEE-ARITHMETIC MACHINES (BINARY STANDARD), ONE OF THE FIRST
C  TWO SETS OF CONSTANTS BELOW SHOULD BE APPROPRIATE.
C
C  WHERE POSSIBLE, DECIMAL, OCTAL OR HEXADECIMAL CONSTANTS ARE USED
C  TO SPECIFY THE CONSTANTS EXACTLY.  SOMETIMES THIS REQUIRES USING
C  EQUIVALENT INTEGER ARRAYS.  IF YOUR COMPILER USES HALF-WORD
C  INTEGERS BY DEFAULT (SOMETIMES CALLED INTEGER*2), YOU MAY NEED TO
C  CHANGE INTEGER TO INTEGER*4 OR OTHERWISE INSTRUCT YOUR COMPILER
C  TO USE FULL-WORD INTEGERS IN THE NEXT 5 DECLARATIONS.
C
      INTEGER SMALL(4)
      INTEGER LARGE(4)
      INTEGER RIGHT(4)
      INTEGER DIVER(4)
      INTEGER LOG10(4)
      INTEGER SC
C
      DOUBLE PRECISION DMACH(5)
C
      EQUIVALENCE (DMACH(1),SMALL(1))
      EQUIVALENCE (DMACH(2),LARGE(1))
      EQUIVALENCE (DMACH(3),RIGHT(1))
      EQUIVALENCE (DMACH(4),DIVER(1))
      EQUIVALENCE (DMACH(5),LOG10(1))
C
C     MACHINE CONSTANTS FOR IEEE ARITHMETIC MACHINES, SUCH AS THE AT&T
C     3B SERIES AND MOTOROLA 68000 BASED MACHINES (E.G. SUN 3 AND AT&T
C     PC 7300), IN WHICH THE MOST SIGNIFICANT BYTE IS STORED FIRST.
C     
       DATA SMALL(1),SMALL(2) /    1048576,          0 /
       DATA LARGE(1),LARGE(2) / 2146435071,         -1 /
       DATA RIGHT(1),RIGHT(2) / 1017118720,          0 /
       DATA DIVER(1),DIVER(2) / 1018167296,          0 /
       DATA LOG10(1),LOG10(2) / 1070810131, 1352628735 /, SC/987/
C
C     MACHINE CONSTANTS FOR IEEE ARITHMETIC MACHINES AND 8087-BASED
C     MICROS, SUCH AS THE IBM PC AND AT&T 6300, IN WHICH THE LEAST
C     SIGNIFICANT BYTE IS STORED FIRST.
C
C      DATA SMALL(1),SMALL(2) /          0,    1048576 /
C      DATA LARGE(1),LARGE(2) /         -1, 2146435071 /
C      DATA RIGHT(1),RIGHT(2) /          0, 1017118720 /
C      DATA DIVER(1),DIVER(2) /          0, 1018167296 /
C      DATA LOG10(1),LOG10(2) / 1352628735, 1070810131 /, SC/987/
C
C     MACHINE CONSTANTS FOR AMDAHL MACHINES.
C
C      DATA SMALL(1),SMALL(2) /    1048576,          0 /
C      DATA LARGE(1),LARGE(2) / 2147483647,         -1 /
C      DATA RIGHT(1),RIGHT(2) /  856686592,          0 /
C      DATA DIVER(1),DIVER(2) /  873463808,          0 /
C      DATA LOG10(1),LOG10(2) / 1091781651, 1352628735 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 1700 SYSTEM.
C
C      DATA SMALL(1) / ZC00800000 /
C      DATA SMALL(2) / Z000000000 /
C
C      DATA LARGE(1) / ZDFFFFFFFF /
C      DATA LARGE(2) / ZFFFFFFFFF /
C
C      DATA RIGHT(1) / ZCC5800000 /
C      DATA RIGHT(2) / Z000000000 /
C
C      DATA DIVER(1) / ZCC6800000 /
C      DATA DIVER(2) / Z000000000 /
C
C      DATA LOG10(1) / ZD00E730E7 /
C      DATA LOG10(2) / ZC77800DC0 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 5700 SYSTEM.
C
C      DATA SMALL(1) / O1771000000000000 /
C      DATA SMALL(2) / O0000000000000000 /
C
C      DATA LARGE(1) / O0777777777777777 /
C      DATA LARGE(2) / O0007777777777777 /
C
C      DATA RIGHT(1) / O1461000000000000 /
C      DATA RIGHT(2) / O0000000000000000 /
C
C      DATA DIVER(1) / O1451000000000000 /
C      DATA DIVER(2) / O0000000000000000 /
C
C      DATA LOG10(1) / O1157163034761674 /
C      DATA LOG10(2) / O0006677466732724 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE BURROUGHS 6700/7700 SYSTEMS.
C
C      DATA SMALL(1) / O1771000000000000 /
C      DATA SMALL(2) / O7770000000000000 /
C
C      DATA LARGE(1) / O0777777777777777 /
C      DATA LARGE(2) / O7777777777777777 /
C
C      DATA RIGHT(1) / O1461000000000000 /
C      DATA RIGHT(2) / O0000000000000000 /
C
C      DATA DIVER(1) / O1451000000000000 /
C      DATA DIVER(2) / O0000000000000000 /
C
C      DATA LOG10(1) / O1157163034761674 /
C      DATA LOG10(2) / O0006677466732724 /, SC/987/
C
C     MACHINE CONSTANTS FOR FTN4 ON THE CDC 6000/7000 SERIES.
C
C      DATA SMALL(1) / 00564000000000000000B /
C      DATA SMALL(2) / 00000000000000000000B /
C
C      DATA LARGE(1) / 37757777777777777777B /
C      DATA LARGE(2) / 37157777777777777774B /
C
C      DATA RIGHT(1) / 15624000000000000000B /
C      DATA RIGHT(2) / 00000000000000000000B /
C
C      DATA DIVER(1) / 15634000000000000000B /
C      DATA DIVER(2) / 00000000000000000000B /
C
C      DATA LOG10(1) / 17164642023241175717B /
C      DATA LOG10(2) / 16367571421742254654B /, SC/987/
C
C     MACHINE CONSTANTS FOR FTN5 ON THE CDC 6000/7000 SERIES.
C
C      DATA SMALL(1) / O"00564000000000000000" /
C      DATA SMALL(2) / O"00000000000000000000" /
C
C      DATA LARGE(1) / O"37757777777777777777" /
C      DATA LARGE(2) / O"37157777777777777774" /
C
C      DATA RIGHT(1) / O"15624000000000000000" /
C      DATA RIGHT(2) / O"00000000000000000000" /
C
C      DATA DIVER(1) / O"15634000000000000000" /
C      DATA DIVER(2) / O"00000000000000000000" /
C
C      DATA LOG10(1) / O"17164642023241175717" /
C      DATA LOG10(2) / O"16367571421742254654" /, SC/987/
C
C     MACHINE CONSTANTS FOR CONVEX C-1
C
C      DATA SMALL(1),SMALL(2) / '00100000'X, '00000000'X /
C      DATA LARGE(1),LARGE(2) / '7FFFFFFF'X, 'FFFFFFFF'X /
C      DATA RIGHT(1),RIGHT(2) / '3CC00000'X, '00000000'X /
C      DATA DIVER(1),DIVER(2) / '3CD00000'X, '00000000'X /
C      DATA LOG10(1),LOG10(2) / '3FF34413'X, '509F79FF'X /, SC/987/
C
C     MACHINE CONSTANTS FOR THE CRAY 1, XMP, 2, AND 3.
C
C      DATA SMALL(1) / 201354000000000000000B /
C      DATA SMALL(2) / 000000000000000000000B /
C
C      DATA LARGE(1) / 577767777777777777777B /
C      DATA LARGE(2) / 000007777777777777776B /
C
C      DATA RIGHT(1) / 376434000000000000000B /
C      DATA RIGHT(2) / 000000000000000000000B /
C
C      DATA DIVER(1) / 376444000000000000000B /
C      DATA DIVER(2) / 000000000000000000000B /
C
C      DATA LOG10(1) / 377774642023241175717B /
C      DATA LOG10(2) / 000007571421742254654B /, SC/987/
C
C     MACHINE CONSTANTS FOR THE DATA GENERAL ECLIPSE S/200
C
C     NOTE - IT MAY BE APPROPRIATE TO INCLUDE THE FOLLOWING LINE -
C     STATIC DMACH(5)
C
C      DATA SMALL/20K,3*0/,LARGE/77777K,3*177777K/
C      DATA RIGHT/31420K,3*0/,DIVER/32020K,3*0/
C      DATA LOG10/40423K,42023K,50237K,74776K/, SC/987/
C
C     MACHINE CONSTANTS FOR THE HARRIS SLASH 6 AND SLASH 7
C
C      DATA SMALL(1),SMALL(2) / '20000000, '00000201 /
C      DATA LARGE(1),LARGE(2) / '37777777, '37777577 /
C      DATA RIGHT(1),RIGHT(2) / '20000000, '00000333 /
C      DATA DIVER(1),DIVER(2) / '20000000, '00000334 /
C      DATA LOG10(1),LOG10(2) / '23210115, '10237777 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE HONEYWELL DPS 8/70 SERIES.
C
C      DATA SMALL(1),SMALL(2) / O402400000000, O000000000000 /
C      DATA LARGE(1),LARGE(2) / O376777777777, O777777777777 /
C      DATA RIGHT(1),RIGHT(2) / O604400000000, O000000000000 /
C      DATA DIVER(1),DIVER(2) / O606400000000, O000000000000 /
C      DATA LOG10(1),LOG10(2) / O776464202324, O117571775714 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE IBM 360/370 SERIES,
C     THE XEROX SIGMA 5/7/9 AND THE SEL SYSTEMS 85/86.
C
C      DATA SMALL(1),SMALL(2) / Z00100000, Z00000000 /
C      DATA LARGE(1),LARGE(2) / Z7FFFFFFF, ZFFFFFFFF /
C      DATA RIGHT(1),RIGHT(2) / Z33100000, Z00000000 /
C      DATA DIVER(1),DIVER(2) / Z34100000, Z00000000 /
C      DATA LOG10(1),LOG10(2) / Z41134413, Z509F79FF /, SC/987/
C
C     MACHINE CONSTANTS FOR THE INTERDATA 8/32
C     WITH THE UNIX SYSTEM FORTRAN 77 COMPILER.
C
C     FOR THE INTERDATA FORTRAN VII COMPILER REPLACE
C     THE Z'S SPECIFYING HEX CONSTANTS WITH Y'S.
C
C      DATA SMALL(1),SMALL(2) / Z'00100000', Z'00000000' /
C      DATA LARGE(1),LARGE(2) / Z'7EFFFFFF', Z'FFFFFFFF' /
C      DATA RIGHT(1),RIGHT(2) / Z'33100000', Z'00000000' /
C      DATA DIVER(1),DIVER(2) / Z'34100000', Z'00000000' /
C      DATA LOG10(1),LOG10(2) / Z'41134413', Z'509F79FF' /, SC/987/
C
C     MACHINE CONSTANTS FOR THE PDP-10 (KA PROCESSOR).
C
C      DATA SMALL(1),SMALL(2) / "033400000000, "000000000000 /
C      DATA LARGE(1),LARGE(2) / "377777777777, "344777777777 /
C      DATA RIGHT(1),RIGHT(2) / "113400000000, "000000000000 /
C      DATA DIVER(1),DIVER(2) / "114400000000, "000000000000 /
C      DATA LOG10(1),LOG10(2) / "177464202324, "144117571776 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE PDP-10 (KI PROCESSOR).
C
C      DATA SMALL(1),SMALL(2) / "000400000000, "000000000000 /
C      DATA LARGE(1),LARGE(2) / "377777777777, "377777777777 /
C      DATA RIGHT(1),RIGHT(2) / "103400000000, "000000000000 /
C      DATA DIVER(1),DIVER(2) / "104400000000, "000000000000 /
C      DATA LOG10(1),LOG10(2) / "177464202324, "047674776746 /, SC/987/
C
C     MACHINE CONSTANTS FOR PDP-11 FORTRANS SUPPORTING
C     32-BIT INTEGERS (EXPRESSED IN INTEGER AND OCTAL).
C
C      DATA SMALL(1),SMALL(2) /    8388608,           0 /
C      DATA LARGE(1),LARGE(2) / 2147483647,          -1 /
C      DATA RIGHT(1),RIGHT(2) /  612368384,           0 /
C      DATA DIVER(1),DIVER(2) /  620756992,           0 /
C      DATA LOG10(1),LOG10(2) / 1067065498, -2063872008 /, SC/987/
C
C      DATA SMALL(1),SMALL(2) / O00040000000, O00000000000 /
C      DATA LARGE(1),LARGE(2) / O17777777777, O37777777777 /
C      DATA RIGHT(1),RIGHT(2) / O04440000000, O00000000000 /
C      DATA DIVER(1),DIVER(2) / O04500000000, O00000000000 /
C      DATA LOG10(1),LOG10(2) / O07746420232, O20476747770 /, SC/987/
C
C     MACHINE CONSTANTS FOR PDP-11 FORTRANS SUPPORTING
C     16-BIT INTEGERS (EXPRESSED IN INTEGER AND OCTAL).
C
C      DATA SMALL(1),SMALL(2) /    128,      0 /
C      DATA SMALL(3),SMALL(4) /      0,      0 /
C
C      DATA LARGE(1),LARGE(2) /  32767,     -1 /
C      DATA LARGE(3),LARGE(4) /     -1,     -1 /
C
C      DATA RIGHT(1),RIGHT(2) /   9344,      0 /
C      DATA RIGHT(3),RIGHT(4) /      0,      0 /
C
C      DATA DIVER(1),DIVER(2) /   9472,      0 /
C      DATA DIVER(3),DIVER(4) /      0,      0 /
C
C      DATA LOG10(1),LOG10(2) /  16282,   8346 /
C      DATA LOG10(3),LOG10(4) / -31493, -12296 /, SC/987/
C
C      DATA SMALL(1),SMALL(2) / O000200, O000000 /
C      DATA SMALL(3),SMALL(4) / O000000, O000000 /
C
C      DATA LARGE(1),LARGE(2) / O077777, O177777 /
C      DATA LARGE(3),LARGE(4) / O177777, O177777 /
C
C      DATA RIGHT(1),RIGHT(2) / O022200, O000000 /
C      DATA RIGHT(3),RIGHT(4) / O000000, O000000 /
C
C      DATA DIVER(1),DIVER(2) / O022400, O000000 /
C      DATA DIVER(3),DIVER(4) / O000000, O000000 /
C
C      DATA LOG10(1),LOG10(2) / O037632, O020232 /
C      DATA LOG10(3),LOG10(4) / O102373, O147770 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE PRIME 50 SERIES SYSTEMS
C     WITH 32-BIT INTEGERS AND 64V MODE INSTRUCTIONS,
C     SUPPLIED BY IGOR BRAY.
C
C      DATA SMALL(1),SMALL(2) / :10000000000, :00000100001 /
C      DATA LARGE(1),LARGE(2) / :17777777777, :37777677775 /
C      DATA RIGHT(1),RIGHT(2) / :10000000000, :00000000122 /
C      DATA DIVER(1),DIVER(2) / :10000000000, :00000000123 /
C      DATA LOG10(1),LOG10(2) / :11504046501, :07674600177 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE SEQUENT BALANCE 8000
C
C      DATA SMALL(1),SMALL(2) / $00000000,  $00100000 /
C      DATA LARGE(1),LARGE(2) / $FFFFFFFF,  $7FEFFFFF /
C      DATA RIGHT(1),RIGHT(2) / $00000000,  $3CA00000 /
C      DATA DIVER(1),DIVER(2) / $00000000,  $3CB00000 /
C      DATA LOG10(1),LOG10(2) / $509F79FF,  $3FD34413 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE UNIVAC 1100 SERIES.
C
C      DATA SMALL(1),SMALL(2) / O000040000000, O000000000000 /
C      DATA LARGE(1),LARGE(2) / O377777777777, O777777777777 /
C      DATA RIGHT(1),RIGHT(2) / O170540000000, O000000000000 /
C      DATA DIVER(1),DIVER(2) / O170640000000, O000000000000 /
C      DATA LOG10(1),LOG10(2) / O177746420232, O411757177572 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE VAX UNIX F77 COMPILER
C
C      DATA SMALL(1),SMALL(2) /        128,           0 /
C      DATA LARGE(1),LARGE(2) /     -32769,          -1 /
C      DATA RIGHT(1),RIGHT(2) /       9344,           0 /
C      DATA DIVER(1),DIVER(2) /       9472,           0 /
C      DATA LOG10(1),LOG10(2) /  546979738,  -805796613 /, SC/987/
C
C     MACHINE CONSTANTS FOR THE VAX-11 WITH
C     FORTRAN IV-PLUS COMPILER
C
C      DATA SMALL(1),SMALL(2) / Z00000080, Z00000000 /
C      DATA LARGE(1),LARGE(2) / ZFFFF7FFF, ZFFFFFFFF /
C      DATA RIGHT(1),RIGHT(2) / Z00002480, Z00000000 /
C      DATA DIVER(1),DIVER(2) / Z00002500, Z00000000 /
C      DATA LOG10(1),LOG10(2) / Z209A3F9A, ZCFF884FB /, SC/987/
C
C     MACHINE CONSTANTS FOR VAX/VMS VERSION 2.2
C
C      DATA SMALL(1),SMALL(2) /       '80'X,        '0'X /
C      DATA LARGE(1),LARGE(2) / 'FFFF7FFF'X, 'FFFFFFFF'X /
C      DATA RIGHT(1),RIGHT(2) /     '2480'X,        '0'X /
C      DATA DIVER(1),DIVER(2) /     '2500'X,        '0'X /
C      DATA LOG10(1),LOG10(2) / '209A3F9A'X, 'CFF884FB'X /, SC/987/
C
C  ***  ISSUE STOP 779 IF ALL DATA STATEMENTS ARE COMMENTED...
      IF (SC .NE. 987) STOP 779
      IF (I .LT. 1  .OR.  I .GT. 5) GOTO 999
      D1MACH = DMACH(I)
      RETURN
  999 WRITE(*,1999) I
 1999 FORMAT(' D1MACH - I OUT OF BOUNDS',I10)
      STOP
      END
C ---- extracted from listing lines 426-609: DCHTRI
      SUBROUTINE DCHTRI(NUMFUN,MDIV,VER,NUMTRI,MINPTS,MAXPTS,EPSABS,
     +                  EPSREL,LENVER,NW,RESTAR,MAXSUB,MINSUB,IFAIL)
C***BEGIN PROLOGUE DCHTRI
C***REFER TO DCUTRI
C***PURPOSE  DCHTRI checks the validity of the
C            input parameters to DCUTRI.
C***DESCRIPTION
C            DCHTRI computes MAXSUB, MINSUB and IFAIL as
C            functions of the input parameters to DCUTRI,
C            and checks the validity of the input parameters to DCUTRI.
C
C   ON ENTRY
C
C     NUMFUN Integer.
C            Number of components of the integral.
C     MDIV   Integer.
C            MDIV is the number of triangles that are divided in
C            each subdivision step in DADTRI.
C            MDIV is chosen default to 1.
C            For efficient execution on parallel computers
C            with NPROC processors MDIV should be set equal to
C            the smallest integer such that MOD(4*MDIV,NPROC) = 0.
C     VER    Real array of dimension (2,3,LENVER).
C            VER(1,K,L) and VER(2,K,L) are the x and y coordinates
C            respectively of vertex K in triangle L.
C            On entry VER(*,*,L) must contain the vertices of the
C            NUMTRI user specified triangles for L = 1,2,...,NUMTRI.
C     NUMTRI Integer.
C            The number of triangles.
C     MINPTS Integer.
C            Minimum number of function evaluations.
C     MAXPTS Integer.
C            Maximum number of function evaluations.
C            The number of function evaluations over each subregion
C            is 37.
C            MAXPTS >= 37*NUMTRI and MAXPTS >= MINPTS
C
C     EPSABS Real.
C            Requested absolute error.
C     EPSREL Real.
C            Requested relative error.
C     LENVER Integer.
C            Defines the length of the array VER.
C
C            We let
C            MAXSUB denote the maximum allowed number of subregions
C            for the given values of MAXPTS.
C            MAXSUB = 3*((MAXPTS-37*NUMTRI)/(4*37)) + NUMTRI
C            LENVER should then be greater or equal to MAXSUB.
C
C     NW     Integer.
C            Defines the length of the working array WORK.
C
C            We let
C            MAXSUB denote the maximum allowed number of subregions
C            for the given values of MAXPTS.
C            MAXSUB = 3*((MAXPTS-37*NUMTRI)/(4*37)) + NUMTRI
C            NW should then be greater or equal to
C            MAXSUB*(2*NUMFUN+1) + MAX(32*MDIV,8*NUMTRI)*NUMFUN + 1
C
C     RESTAR Integer.
C            If RESTAR = 0, this is the first attempt to compute
C            the integral.
C            If RESTAR = 1,
C            then we restart a previous attempt.
C            In this case the only parameters for DCUTRI that may
C            be changed (with respect to the previous call of DCUTRI)
C            are MINPTS, MAXPTS, EPSABS, EPSREL and RESTAR.
C
C
C   ON RETURN
C
C     MAXSUB Integer.
C            The maximum allowed number of subregions for the
C            given values of MAXPTS.
C     MINSUB Integer.
C            The minimum allowed number of subregions for the given
C            values of MINPTS.
C     IFAIL  Integer.
C            IFAIL = 0 for normal exit.
C            IFAIL = 2 if NUMFUN is less than 1.
C            IFAIL = 3 if area of one of the initially given
C                      triangles is zero.
C            IFAIL = 4 if MAXPTS is less than 37*NUMTRI.
C            IFAIL = 5 if MAXPTS is less than MINPTS.
C            IFAIL = 6 if EPSABS <= 0 and EPSREL <= 0.
C            IFAIL = 7 if LENVER is less than MAXSUB.
C            IFAIL = 8 if NW is less than MAXSUB*(2*NUMFUN+1) +
C                      NUMFUN*MAX(32*MDIV,8*NUMTRI) + 1.
C            IFAIL = 9 if illegal RESTAR.
C
C***ROUTINES CALLED-NONE
C***END PROLOGUE DCHTRI
C
C   Global variables.
C
      INTEGER NUMFUN,MDIV,NUMTRI,MINPTS,MAXPTS,NW,MAXSUB,MINSUB,RESTAR,
     +        LENVER,IFAIL
      DOUBLE PRECISION VER(2,3,NUMTRI),EPSABS,EPSREL
C
C   Local variables.
C
      INTEGER LIMIT,J
      DOUBLE PRECISION AREA
C
C***FIRST EXECUTABLE STATEMENT DCHTRI
C
      IFAIL = 0
C
C   We compute MAXSUB and MINSUB.
C
      MAXSUB = 3* ((MAXPTS-37*NUMTRI)/ (4*37)) + NUMTRI
      MINSUB = 3* ((MINPTS-37*NUMTRI)/ (4*37)) + NUMTRI
      IF (MOD((MINPTS-37*NUMTRI),4*37).GT.0) THEN
          MINSUB = MINSUB + 3
      END IF
      MINSUB = MAX(NUMTRI,MINSUB)
C
C   Check on positive NUMFUN.
C
      IF (NUMFUN.LT.1) THEN
          IFAIL = 2
          RETURN
      END IF
C
C   Check on legal area of the region of integration.
C
      DO 10 J = 1,NUMTRI
          AREA = ABS(VER(1,1,J)*VER(2,2,J)-VER(1,2,J)*VER(2,1,J)-
     +           VER(1,1,J)*VER(2,3,J)+VER(1,3,J)*VER(2,1,J)+
     +           VER(1,2,J)*VER(2,3,J)-VER(1,3,J)*VER(2,2,J))*0.5
          IF (AREA.EQ.0) THEN
              IFAIL = 3
              RETURN
          END IF
   10 CONTINUE
C
C   Check on MAXPTS >= 37*NUMTRI.
C
      IF (MAXPTS.LT.37*NUMTRI) THEN
          IFAIL = 4
          RETURN
      END IF
C
C   Check on MAXPTS >= MINPTS.
C
      IF (MAXPTS.LT.MINPTS) THEN
          IFAIL = 5
          RETURN
      END IF
C
C   Check on legal accuracy requests.
C
      IF (EPSABS.LE.0 .AND. EPSREL.LE.0) THEN
          IFAIL = 6
          RETURN
      END IF
C
C   Check on big enough LENVER.
C
      IF (LENVER.LT.MAXSUB) THEN
          IFAIL = 7
          RETURN
      END IF
C
C   Check on big enough NW.
C
      LIMIT = MAXSUB* (2*NUMFUN+1) + MAX(32*MDIV,8*NUMTRI)*NUMFUN + 1
      IF (NW.LT.LIMIT) THEN
          IFAIL = 8
          RETURN
      END IF
C
C    Check on legal RESTAR.
C
      IF (RESTAR.NE.0 .AND. RESTAR.NE.1) THEN
          IFAIL = 9
          RETURN
      END IF
      RETURN
C
C***END DCHTRI
C
      END
C ---- extracted from listing lines 610-1005: DCUTRI
      SUBROUTINE DCUTRI(FUNSUB,NUMFUN,VER,NUMTRI,MINPTS,MAXPTS,EPSABS,
     +                 EPSREL,LENVER,NW,RESTAR,RESULT,ABSERR,NEVAL,
     +                 IFAIL,WORK,IWORK)
C***BEGIN PROLOGUE DCUTRI
C***DATE WRITTEN   891023   (YYMMDD)
C***REVISION DATE  910214   (YYMMDD)
C***CATEGORY NO. H2B2A1/H2B2A2
C***KEYWORDS QUADRATURE, TWO DIMENSIONAL, ADAPTIVE, CUBATURE
C***AUTHOR
C
C            Jarle Berntsen, Institute of Marine Research,
C            Nordnesparken 2, Postboks 1870,
C            N-5024 Bergen-Nordnes, Norway
C            Phone..  47-5-238461
C            Email..  jarleb@imr.no
C
C            Terje O. Espelid, Department of Informatics,
C            University of Bergen, Thormohlens gt. 55,
C            N-5008 Bergen, Norway
C            Phone..  47-5-544180
C            Email..  terje@eik.ii.uib.no
C
C***PURPOSE  To compute the two-dimensional integral over a region
C            consisting of NUMTRI triangles.
C***DESCRIPTION
C
C            The routine calculates an approximation to a given
C            vector of definite integrals
C
C            I  I (F ,F ,...,F )     DX(2)DX(1),
C                   1  2      NUMFUN
C
C            where the region of integration is a selection of
C            NUMTRI triangles and
C            where F = F (X(1),X(2)), J = 1,2,...,NUMFUN.
C                   J   J
C
C
C            A globally adaptive strategy is applied in order to
C            compute approximations RESULT(K)
C            hopefully satisfying for each component of I the following
C            claim for accuracy:
C            ABS(I(K)-RESULT(K)).LE.MAX(EPSABS,EPSREL*ABS(I(K)))
C
C            DCUTRI is a driver for the integration routine
C            DADTRI.
C
C            DADTRI repeatedly
C            subdivides the triangles with greatest estimated  errors
C            and estimates the integrals and the
C            errors over the new subtriangles
C            until either the error request
C            is met or MAXPTS function evaluations have been used.
C
C            A 37 point integration rule
C            with all evaluation points inside the triangle
C            is applied. The rule has polynomial degree 13.
C
C            If the values of the input parameters EPSABS
C            or EPSREL are selected great enough,
C            an integration rule is applied over each triangle and
C            the results are added up to give the approximations
C            RESULT(K). No further subdivision
C            of the triangles will then be applied.
C  
C            When DCUTRI computes estimates to a vector of
C            integrals, all components of the vector are given
C            the same treatment. That is, I(F ) and I(F ) for
C                                            J         K
C            J not equal to K, are estimated with the same
C            subdivision of the region of integration.
C            For integrals with enough similarity, we may save
C            time by applying DCUTRI to all integrands in one call.
C            For integrals that varies continuously as functions of
C            some parameter, the estimates produced by DCUTRI will
C            also vary continuously when the same subdivision is
C            applied to all components. This will generally not be
C            the case when the different components are given
C            separate treatment.
C
C            On the other hand this feature should be used with
C            caution when the different components of the integrals
C            require clearly different subdivisions.
C
C   ON ENTRY
C
C     FUNSUB Externally declared subroutine for computing
C            all components of the integrand at the given
C            evaluation point.
C            It must have parameters (X,NUMFUN,FUNVLS)
C            Input parameters:
C              X(1)   The x-coordinate of the evaluation point.
C              X(2)   The y-coordinate of the evaluation point.
C              NUMFUN Integer that defines the number of
C                     components of I.
C            Output parameter:
C              FUNVLS Real array of dimension NUMFUN
C                     that defines NUMFUN components of the integrand.
C
C     NUMFUN Integer.
C            Number of components of the integral.
C     VER    Real array of dimension (2,3,LENVER).
C            VER(1,K,L) and VER(2,K,L) are the x and y coordinates
C            respectively of vertex K in triangle L.
C            On entry VER(*,*,L) must contain the vertices of the
C            NUMTRI user specified triangles for L = 1,2,...,NUMTRI.
C            VER may be changed on exit.
C
C     NUMTRI Integer.
C            The number of triangles.
C     MINPTS Integer.
C            Minimum number of function evaluations.
C     MAXPTS Integer.
C            Maximum number of function evaluations.
C            The number of function evaluations over each subregion
C            is 37.
C
C            MAXPTS >= 37*NUMTRI and MAXPTS >= MINPTS
C
C     EPSABS Real.
C            Requested absolute error.
C     EPSREL Real.
C            Requested relative error.
C     LENVER Integer.
C            Defines the length of the array VER.
C
C            We let
C            MAXSUB denote the maximum allowed number of subregions
C            for the given value of MAXPTS.
C            MAXSUB = 3*((MAXPTS-37*NUMTRI)/(4*37)) + NUMTRI
C            LENVER should be greater or equal to MAXSUB.
C
C     NW     Integer.
C            Defines the length of the working array WORK.
C
C            If LENVER is chosen correctly as a function of MAXPTS 
C            and NUMTRI and NW is selected to be greater or equal to 
C            LENVER*(2*NUMFUN+1) + MAX(32*MDIV,8*NUMTRI)*NUMFUN + 1 ,
C            then the size of the working storage will be great enough. 
C            MDIV is the number of triangles that are divided in
C            each subdivision step.
C            MDIV is default set internally in DCUTRI equal to 1.
C            For efficient execution on parallel computers
C            with NPROC processors MDIV should be set equal to
C            the smallest integer such that MOD(4*MDIV,NPROC) = 0.
C
C     RESTAR Integer.
C            If RESTAR = 0, this is the first attempt to compute
C            the integral.
C            If RESTAR = 1,
C            then we restart a previous attempt.
C            In this case the only parameters for DCUTRI that may
C            be changed (with respect to the previous call of DCUTRI)
C            are MINPTS, MAXPTS, EPSABS, EPSREL and RESTAR.
C            Note: If MAXPTS was too small in the previous call,
C            then we get a second chance to continue the computations
C            with MAXPTS increased.
C            LENVER can not be changed, therefore the new value of MAXPTS
C            should not be chosen greater than the value of LENVER
C            allows us to do.
C     WORK   Real array of dimension NW.
C            Used as working storage.
C     IWORK  Integer array of dimension LENVER + MDIV.
C            Used as working storage.
C
C   ON RETURN
C
C     RESULT Real array of dimension NUMFUN.
C            Approximations to all components of the integral.
C     ABSERR Real array of dimension NUMFUN.
C            Estimates of absolute errors.
C     NEVAL  Integer.
C            Number of function evaluations used by DCUTRI.
C     IFAIL  Integer.
C            IFAIL = 0 for normal exit.
C
C              ABSERR(K) <=  EPSABS or
C              ABSERR(K) <=  ABS(RESULT(K))*EPSREL with MAXPTS or less
C              function evaluations for all values of K,
C              1 <= K <= NUMFUN .
C
C            IFAIL = 1 if MAXPTS was too small for DCUTRI
C              to obtain the required accuracy. In this case DCUTRI
C              returns values of RESULT with estimated absolute
C              errors ABSERR.
C            IFAIL = 2 if NUMFUN is less than 1.
C            IFAIL = 3 if area of one of the initially given
C                      triangles is zero.
C            IFAIL = 4 if MAXPTS is less than 37*NUMTRI.
C            IFAIL = 5 if MAXPTS is less than MINPTS.
C            IFAIL = 6 if EPSABS <= 0 and EPSREL <= 0.
C            IFAIL = 7 if LENVER is less than MAXSUB.
C            IFAIL = 8 if NW is less than MAXSUB*(2*NUMFUN+1) +
C                      NUMFUN*MAX(32*MDIV,8*NUMTRI) + 1.
C            IFAIL = 9 if unlegal RESTAR.
C     VER    Real array of dimension (2,3,LENVER).
C            On exit VER
C            contains the vertices of the triangles used to produce
C            the approximations to the integrals.
C     WORK   Real array of dimension NW.
C            Used as working storage.
C            WORK(NW) = NSUB, the number of subregions in the data
C            structure.
C            Let WRKSUB=(NW-1-NUMFUN*MAX(32*MDIV,8*NUMTRI))/
C                        (2*NUMFUN+1).
C            WORK(1),...,WORK(NUMFUN*WRKSUB) contain
C              the estimated components of the integrals over the
C              subregions.
C            WORK(NUMFUN*WRKSUB+1),...,WORK(2*NUMFUN*WRKSUB) contain
C              the estimated errors over the subregions.
C            WORK(2*NUMFUN*WRKSUB+1),...,WORK(2*NUMFUN*
C              WRKSUB+WRKSUB) contain the greatest errors
C              in each subregion.
C            WORK((2*NUMFUN+1)*WRKSUB),...,WORK(NW - 1) is used as
C              temporary storage in DADTRI.
C     IWORK  Integer array of dimension LENVER + MDIV.
C            Used as working storage.  
C            
C           SAMPLE PROGRAM
C   The following program will approximate the integral of
C                     exp(x*x+y*y)
C   over the triangle (0.,0.),(2.,0.),(0.,2.) and print out the
C   values of the estimated integral, the estimated error, the number
C   of function evaluations, and IFAIL.
C     PROGRAM DTEST1
C     INTEGER NUMFUN,NW,MDIV,MINPTS,LENVER,NUMTRI
C     PARAMETER (NUMFUN=1,MDIV=1,NUMTRI=1,MINPTS=37)
C     PARAMETER ( LENVER = 100 )
C
C   We need to choose LENVER  such that:
C   LENVER >= 3*((MAXPTS-37*NUMTRI)/(4*37)) + NUMTRI
C   This simply means that we have enough space to achieve MAXPTS
C   function evaluations. By choosing LENVER bigger than
C   this lower bound we may later change MAXPTS and RESTAR and restart
C   the computations from the point where the last run stopped.
C   The reason for stopping may have been that MAXPTS was too small
C   to achieve the requested error.
C          With our choice LENVER = 100 any value of MAXPTS
C   between 37 and 5068 will be accepted by the code. Choosing
C   MAXPTS = 2000 allows us to restart with a greater value
C   if necessary.
C
C     PARAMETER (NW = LENVER*(2*NUMFUN+1) +
C    +                MAX(32*MDIV,8*NUMTRI)*NUMFUN + 1)
C     DOUBLE PRECISION VER(2,3,LENVER),RESULT(NUMFUN),
C    +                 ABSERR(NUMFUN),WORK(NW),EPSABS,EPSREL
C     INTEGER RESTAR,NEVAL,IFAIL,MDIV,IWORK(LENVER+MDIV),MAXPTS
C     EXTERNAL F
C     VER(1,1,1) = 0.D0
C     VER(1,2,1) = 2.D0
C     VER(1,3,1) = 0.D0
C     VER(2,1,1) = 0.D0
C     VER(2,2,1) = 0.D0
C     VER(2,3,1) = 2.D0
C     EPSABS = 0.D0
C     EPSREL = 1.D-5
C     RESTAR = 0
C     MAXPTS = 2000
C     CALL DCUTRI(F,NUMFUN,VER,NUMTRI,MINPTS,MAXPTS,EPSABS,
C    +            EPSREL,LENVER,NW,RESTAR,RESULT,ABSERR,NEVAL,
C    +            IFAIL,WORK,IWORK)
C     WRITE(*,*)'RESULT=',RESULT(1)
C     WRITE(*,*)'ERROR =',ABSERR(1)
C     WRITE(*,*)'NEVAL =',NEVAL
C     WRITE(*,*)'IFAIL =',IFAIL
C     END
C     SUBROUTINE F(X,NUMFUN,FUNVLS)
C     INTEGER NUMFUN
C     DOUBLE PRECISION X(2),FUNVLS(NUMFUN)
C     FUNVLS(1) = EXP(X(1)*X(1)+X(2)*X(2))
C     RETURN
C     END
C
C   Output produced on a SUN SPARC station 1.
C
C       RESULT=   11.181284417019
C       ERROR =    4.7009048669038D-06
C       NEVAL =  185
C       IFAIL =  0
C
C
C***LONG DESCRIPTION
C
C   The information for each triangle is contained in the
C   data structures VER, WORK and IWORK.
C   VER contains the coordinates of the triangles.
C   When passed on to DADTRI, WORK is split into four
C   arrays VALUES, ERRORS, GREATE and WORK2.
C   VALUES contains the estimated values of the integrals.
C   ERRORS contains the estimated errors.
C   GREATE contains the greatest estimated error for each triangle.
C   The data structures for the triangles are in DADTRI organized
C   as a heap, and the size of GREATE(I) defines the position of
C   triangle I in the heap. The heap is maintained by the program
C   DTRTRI and we use a partially ordered list of pointers, saved
C   in IWORK. When passed on to DADTRI, IWORK is split into two
C   arrays LIST and VACANT. LIST is a partially ordered list
C   such that GREATE(LIST(1)) is the maximum error estimate for 
C   all sub-triangles in our datastructure. VACANT is a work space
C   needed in the updating process of the list.
C
C   The subroutine DADTRI is written for efficient execution on shared
C   memory parallel computer. On a computer with NPROC processors we will
C   in each subdivision step divide MDIV triangles, where MDIV is
C   chosen such that MOD(4*MDIV,NPROC) = 0, in totally 4*MDIV new triangles.
C   Each processor will then compute estimates of the integrals and errors
C   over 4*MDIV/NPROC triangles in each subdivision step.
C   The subroutine for estimating the integral and the error over
C   each subregion, DRLTRI, uses WORK2 as a work array.
C   We must make sure that each processor writes its results to
C   separate parts of the memory, and therefore the sizes of WORK and
C   WORK2 are functions of MDIV.
C   In order to achieve parallel processing of triangles, compiler
C   directives should be placed in front of the DO 20 and the DO 200
C   loops in DADTRI on machines like Alliant and CRAY.
C
C***REFERENCES
C   J.Berntsen and T.O.Espelid, An Algorithm for Adaptive 
C   Cubature Over a Collection of Triangles, to be published.
C
C***ROUTINES CALLED DCHTRI,DADTRI
C***END PROLOGUE DCUTRI
C
C   Parameters
C
C   MDIV   Integer.
C          MDIV is the number of triangles that are divided in
C          each subdivision step in DADTRI.
C          MDIV is chosen default to 1.
C          For efficient execution on parallel computers
C          with NPROC processors MDIV should be set equal to
C          the smallest integer such that MOD(4*MDIV,NPROC) = 0.
      INTEGER MDIV
      PARAMETER (MDIV=1)
C
C   Global variables.
C
      EXTERNAL FUNSUB
      INTEGER NUMFUN,NUMTRI,MINPTS,MAXPTS,LENVER,NW,RESTAR,NEVAL,IFAIL,
     +        IWORK(LENVER+MDIV)
      DOUBLE PRECISION VER(2,3,LENVER),EPSABS,EPSREL,RESULT(NUMFUN),
     +                 ABSERR(NUMFUN),WORK(NW)
C
C   Local variables.
C
C   MAXSUB Integer.
C          The maximum allowed number of subregions
C          for the given values of MAXPTS.
C   MINSUB Integer.
C          The minimum allowed number of subregions for the given
C          values of MINPTS.
C   WRKSUB Integer.
C          Determines the length of the main work arrays.
C
      INTEGER MAXSUB,MINSUB,NSUB,LENW
      INTEGER WRKSUB,I1,I2,I3,I4
C
C***FIRST EXECUTABLE STATEMENT DCUTRI
C
C   Compute MAXSUB and MINSUB,
C   and check the input parameters.
C
      CALL DCHTRI(NUMFUN,MDIV,VER,NUMTRI,MINPTS,MAXPTS,EPSABS,EPSREL,
     +            LENVER,NW,RESTAR,MAXSUB,MINSUB,IFAIL)
      WRKSUB = (NW-1-NUMFUN*MAX(32*MDIV,8*NUMTRI))/ (2*NUMFUN+1)
      IF (IFAIL.NE.0) THEN
          RETURN
      END IF
C
C   Split up the work space.
C
      I1 = 1
      I2 = I1 + WRKSUB*NUMFUN
      I3 = I2 + WRKSUB*NUMFUN
      I4 = I3 + WRKSUB
C
C   On restart runs the number of subregions from the
C   previous call is assigned to NSUB.
C
      IF (RESTAR.EQ.1) THEN
          NSUB = WORK(NW)
      END IF
C
C   Compute the size of the temporary work space needed in DADTRI.
C
      LENW = MAX(32*MDIV,8*NUMTRI)*NUMFUN
      CALL DADTRI(NUMFUN,MDIV,VER,NUMTRI,MINSUB,MAXSUB,FUNSUB,EPSABS,
     +            EPSREL,LENVER,RESTAR,LENW,RESULT,ABSERR,NEVAL,NSUB,
     +            IFAIL,WORK(I1),WORK(I2),WORK(I3),WORK(I4),
     +            IWORK(1),IWORK(1+LENVER))
      WORK(NW) = NSUB
      RETURN
C
C***END DCUTRI
C
      END
C ---- extracted from listing lines 1008-1360: DRLTRI
      SUBROUTINE DRLTRI(VER,NUMFUN,FUNSUB,NULL,BASVAL,RGNERR,GREATE)
C***BEGIN PROLOGUE DRLTRI
C***REFER TO DCUTRI
C***PURPOSE  To compute basic integration rule values and
C            corresponding error estimates.
C***DESCRIPTION DRLTRI computes basic integration rule values
C            for a vector of integrands over a triangular region.
C            DRLTRI also computes estimates for the errors by
C            using several null rule approximations.
C   ON ENTRY
C
C   VER    Real array of dimension (2,3).
C          The coordinates of the vertices of the triangle.
C   NUMFUN Integer.
C          Number of components of the vector integrand.
C   FUNSUB Externally declared subroutine for computing
C            all components of the integrand at the given
C            evaluation point.
C            It must have parameters (X,NUMFUN,FUNVLS)
C            Input parameters:
C              X(1)      The x-coordinate of the evaluation point.
C              X(2)      The y-coordinate of the evaluation point.
C              NUMFUN Integer that defines the number of
C                     components of I.
C            Output parameter:
C              FUNVLS Real array of dimension NUMFUN
C                     that defines NUMFUN components of the integrand.
C
C   NULL   Real array of dimension (NUMFUN,8).
C          A work array.
C
C   ON RETURN
C
C   BASVAL Real array of dimension NUMFUN.
C          The values for the basic rule for each component
C          of the integrand.
C   RGNERR Real array of dimension NUMFUN.
C          The error estimates for each component of the integrand.
C   GREATE Real.
C          The greatest error component of the integrand.
C
C***REFERENCES Berntsen,J. and Espelid,T.O., Degree 13 Symmetric
C              Quadrature Rules for the Triangle, Reports in 
C              Informatics 44, Dept. of Informatics, University of
C              Bergen, 1990.
C***ROUTINES CALLED D1MACH,FUNSUB
C***END PROLOGUE DRLTRI
C
C   Global variables.
C
      EXTERNAL FUNSUB
      INTEGER NUMFUN
      DOUBLE PRECISION VER(2,3),BASVAL(NUMFUN),RGNERR(NUMFUN),
     +                 NULL(NUMFUN,8),GREATE,NOISE,D1MACH,TRES
C
C   Local variables.
C
C   WTLENG The number of weights of the integration rule.
C   G      Real array of dimension (2,WTLENG).
C          The homogeneous coordinates for the generators of
C          the evaluation points.
C          The integration rule is using symmetric evaluation
C          points and has the structure (1,6,3). That is,
C          1 point of multiplicity 1,
C          6 sets of points of multiplicity 3 and
C          3 sets of points of multiplicity 6.
C          This gives totally 37 evaluation points.
C          In order to reduce the number of loops in DRLTRI,
C          the 3 loops for the sets of multiplicity 6 are split
C          into 6 loops and added to the loops for the sets of
C          multiplicity 3.
C          The number of weights we have to give with
C          this splitting is WTLENG = 13.
C
C   W      Real array of dimension (9,WTLENG).
C          The weights of the basic rule and the null rules.
C          W(1,1),...,W(1,WTLENG) are weights for the basic rule.
C          W(I,1),...,W(I,WTLENG) for I>1 are null rule weights.
C
      INTEGER WTLENG
      PARAMETER (WTLENG=13)
      DOUBLE PRECISION AREA,X(2,3),Z1,Z2,Z3,R1,R2,R3,R,DEG7,DEG5,DEG3,
     +                 DEG1,G(2,13),W(9,13)
      INTEGER I,J,K,L
C
C  The abscissas are given in homogeneous coordinates.
C
      DATA (G(1,I),I=1,13)/0.333333333333333333333333333333D0,
     +     0.950275662924105565450352089520D0,
     +     0.171614914923835347556304795551D0,
     +     0.539412243677190440263092985511D0,
     +     0.772160036676532561750285570113D0,
     +     0.009085399949835353883572964740D0,
     +     0.062277290305886993497083640527D0,
     +     0.022076289653624405142446876931D0,
     +     0.018620522802520968955913511549D0,
     +     0.096506481292159228736516560903D0,
     +     0.851306504174348550389457672223D0,
     +     0.689441970728591295496647976487D0,
     +     0.635867859433872768286976979827D0/
      DATA (G(2,I),I=1,13)/0.333333333333333333333333333333D0,
     +     0.024862168537947217274823955239D0,
     +     0.414192542538082326221847602214D0,
     +     0.230293878161404779868453507244D0,
     +     0.113919981661733719124857214943D0,
     +     0.495457300025082323058213517632D0,
     +     0.468861354847056503251458179727D0,
     +     0.851306504174348550389457672223D0,
     +     0.689441970728591295496647976487D0,
     +     0.635867859433872768286976979827D0,
     +     0.022076289653624405142446876931D0,
     +     0.018620522802520968955913511549D0,
     +     0.096506481292159228736516560903D0/
C
C   Weights of the degree 13 quadrature rule.
C
      DATA (W(1,I),I=1,13)/0.051739766065744133555179145422D0,
     +     0.008007799555564801597804123460D0,
     +     0.046868898981821644823226732071D0,
     +     0.046590940183976487960361770070D0,
     +     0.031016943313796381407646220131D0,
     +     0.010791612736631273623178240136D0,
     +     0.032195534242431618819414482205D0,
     +     0.015445834210701583817692900053D0,
     +     0.017822989923178661888748319485D0,
     +     0.037038683681384627918546472190D0,
     +     0.015445834210701583817692900053D0,
     +     0.017822989923178661888748319485D0,
     +     0.037038683681384627918546472190D0/
C
C   Weights of the first null rule of degree 7.
C
      DATA (W(2,I),I=1,13)/-0.077738051051462052051304462750D0,
     +     0.001640389740236881582083124927D0,
     +     0.078124083459915167386776552733D0,
     +     -0.030706528522391137165581298102D0,
     +     0.010246307817678312345028512621D0,
     +     0.012586300774453821540476193059D0,
     +     -0.043630506151410607808929481439D0,
     +     -0.004567055157220063810223671248D0,
     +     0.003393373439889186878847613140D0,
     +     0.000000000000000000000000000000D0,
     +     -0.004567055157220063810223671248D0,
     +     0.003393373439889186878847613140D0,
     +     0.000000000000000000000000000000D0/
C
C   Weights of the second null rule of degree 7.
C
      DATA (W(3,I),I=1,13)/-0.064293709240668260928898888457D0,
     +     0.003134665264639380635175608661D0,
     +     0.007822550509742830478456728602D0,
     +     0.048653051907689492781049400973D0,
     +     0.032883327334384971735434067029D0,
     +     -0.017019508374229390108580829589D0,
     +     0.025973557893399824586684707198D0,
     +     -0.010716753326806275930657622320D0,
     +     0.018315629578968063765722278290D0,
     +     -0.047607080313197299401024682666D0,
     +     -0.010716753326806275930657622320D0,
     +     0.018315629578968063765722278290D0,
     +     -0.047607080313197299401024682666D0/
C
C   Weights of the first degree 5 null rule.
C
C
      DATA (W(4,I),I=1,13)/0.021363205584741860993131879186D0,
     +     0.022716410154120323440432428315D0,
     +     -0.026366191271182090678117381002D0,
     +     0.029627021479068212693155637482D0,
     +     0.004782834546596399307634111034D0,
     +     0.004178667433984132052378990240D0,
     +     -0.065398996748953861618846710897D0,
     +     -0.033589813176131630980793760168D0,
     +     0.033018320112481615757912576257D0,
     +     0.012241086002709814125707333127D0,
     +     -0.033589813176131630980793760168D0,
     +     0.033018320112481615757912576257D0,
     +     0.012241086002709814125707333127D0/
C
C   Weights of the second degree 5 null rule.
C
      DATA (W(5,I),I=1,13)/-0.046058756832790538620830792345D0,
     +     0.005284159186732627192774759959D0,
     +     0.009325799301158899112648198129D0,
     +     -0.006101110360950124560783393745D0,
     +     -0.056223328794664871336486737231D0,
     +     -0.062516479198185693171971930698D0,
     +     0.022428226812039547178810743269D0,
     +     -0.000026014926110604563130107142D0,
     +     0.032882099937471182365626663487D0,
     +     0.018721740987705986426812755881D0,
     +     -0.000026014926110604563130107142D0,
     +     0.032882099937471182365626663487D0,
     +     0.018721740987705986426812755881D0/
C
C   Weights of first degree 3 null rule.
C
      DATA (W(6,I),I=1,13)/0.080867117677405246540283712799D0,
     +     -0.033915806661511608094988607349D0,
     +     0.014813362053697845461526433401D0,
     +     0.001442315416337389214102507204D0,
     +     -0.024309696484708683486455879210D0,
     +     -0.005135085639122398522835391664D0,
     +     -0.034649417896235909885490654650D0,
     +     0.035748423431577326597742956780D0,
     +     0.024548155266816447583155562333D0,
     +     -0.032897267038856299280541675107D0,
     +     0.035748423431577326597742956780D0,
     +     0.024548155266816447583155562333D0,
     +     -0.032897267038856299280541675107D0/
C
C   Weights of second degree 3 null rule.
C
      DATA (W(7,I),I=1,13)/-0.038457863913548248582247346193D0,
     +     -0.055143631258696406147982448269D0,
     +     -0.021536994314510083845999131455D0,
     +     0.001547467894857008228010564582D0,
     +     0.057409361764652373776043522086D0,
     +     -0.040636938884669694118908764512D0,
     +     -0.020801144746964801777584428369D0,
     +     0.019490770404993674256256421103D0,
     +     0.002606109985826399625043764771D0,
     +     0.023893703367437102825618048130D0,
     +     0.019490770404993674256256421103D0,
     +     0.002606109985826399625043764771D0,
     +     0.023893703367437102825618048130D0/
C
C   Weights of first degree 1 null rule.
C
      DATA (W(8,I),I=1,13)/0.074839568911184074117081012527D0,
     +     -0.004270103034833742737299816615D0,
     +     0.049352639555084484177095781183D0,
     +     0.048832124609719176627453278550D0,
     +     0.001042698696559292759051590242D0,
     +     -0.044445273029113458906055765365D0,
     +     -0.004670751812662861209726508477D0,
     +     -0.015613390485814379318605247424D0,
     +     -0.030581651696100000521074498679D0,
     +     0.010801113204340588798240297593D0,
     +     -0.015613390485814379318605247424D0,
     +     -0.030581651696100000521074498679D0,
     +     0.010801113204340588798240297593D0/
C
C   Weights of second degree 1 null rule.
C
      DATA (W(9,I),I=1,13)/0.009373028261842556370231264134D0,
     +     -0.074249368848508554545399978725D0,
     +     0.014709707700258308001897299938D0,
     +     0.009538502545163567494354463302D0,
     +     -0.014268362488069444905870465047D0,
     +     0.040126396495352694403045023109D0,
     +     0.028737181842214741174950928350D0,
     +     -0.031618075834734607275229608099D0,
     +     0.016879961075872039084307382161D0,
     +     0.010878914758683152984395046434D0,
     +     -0.031618075834734607275229608099D0,
     +     0.016879961075872039084307382161D0,
     +     0.010878914758683152984395046434D0/
C
C***FIRST EXECUTABLE STATEMENT DRLTRI
C
      TRES = 50*D1MACH(4)
C
C  Compute area of triangle.
C
      AREA = ABS(VER(1,1)*VER(2,2)-VER(1,2)*VER(2,1)-VER(1,1)*VER(2,3)+
     +       VER(1,3)*VER(2,1)+VER(1,2)*VER(2,3)-VER(1,3)*VER(2,2))/2
C
C   Compute contributions from the center of the triangle.
C
      X(1,1) = (VER(1,1)+VER(1,2)+VER(1,3))/3
      X(2,1) = (VER(2,1)+VER(2,2)+VER(2,3))/3
      CALL FUNSUB(X,NUMFUN,RGNERR)
      DO 20 J = 1,NUMFUN
          BASVAL(J) = W(1,1)*RGNERR(J)
          DO 10 K = 1,8
              NULL(J,K) = W(K+1,1)*RGNERR(J)
   10     CONTINUE
   20 CONTINUE
C
C   Compute the contributions from the points with
C   multiplicity 3.
C
      DO 100 I = 2,WTLENG
          Z1 = G(1,I)
          Z2 = G(2,I)
          Z3 = 1 - Z1 - Z2
          X(1,1) = Z1*VER(1,1) + Z2*VER(1,2) + Z3*VER(1,3)
          X(2,1) = Z1*VER(2,1) + Z2*VER(2,2) + Z3*VER(2,3)
          X(1,2) = Z2*VER(1,1) + Z3*VER(1,2) + Z1*VER(1,3)
          X(2,2) = Z2*VER(2,1) + Z3*VER(2,2) + Z1*VER(2,3)
          X(1,3) = Z3*VER(1,1) + Z1*VER(1,2) + Z2*VER(1,3)
          X(2,3) = Z3*VER(2,1) + Z1*VER(2,2) + Z2*VER(2,3)
          DO 90 L = 1,3
              CALL FUNSUB(X(1,L),NUMFUN,RGNERR)
              DO 80 J = 1,NUMFUN
                  BASVAL(J) = BASVAL(J) + W(1,I)*RGNERR(J)
                  DO 70 K = 1,8
                      NULL(J,K) = NULL(J,K) + W(K+1,I)*RGNERR(J)
   70             CONTINUE
   80         CONTINUE
   90     CONTINUE
  100 CONTINUE
C
C    Compute the errors.
C
      GREATE = 0
      DO 130 J = 1,NUMFUN
          DEG7 = AREA*SQRT(NULL(J,1)**2+NULL(J,2)**2)
          DEG5 = AREA*SQRT(NULL(J,3)**2+NULL(J,4)**2)
          DEG3 = AREA*SQRT(NULL(J,5)**2+NULL(J,6)**2)
          DEG1 = AREA*SQRT(NULL(J,7)**2+NULL(J,8)**2)
          IF (DEG5.NE.0) THEN
              R1 = DEG7/DEG5
          ELSE
              R1 = 1
          END IF
          IF (DEG3.NE.0) THEN
              R2 = DEG5/DEG3
          ELSE
              R2 = 1
          END IF
          IF (DEG1.NE.0) THEN
              R3 = DEG3/DEG1
          ELSE
              R3 = 1
          END IF
          R = MAX(R1,R2,R3)
          IF (R.GE.1) THEN
              RGNERR(J) = 10*MAX(DEG1,DEG3,DEG5,DEG7)
          ELSE IF (R.GE.0.5D0) THEN
              RGNERR(J) = 10*R*DEG7
          ELSE
              RGNERR(J) = 40* (R**3)*DEG7
          END IF
          BASVAL(J) = AREA*BASVAL(J)
          NOISE = ABS(BASVAL(J))*TRES
C The following 6 statements added as the result of authors remark
C
C    The following statement is included to set the error to the noise
C    level if the two error estimates, assumed to be the best, are both 
C    below or on the noise level
C
          IF ((DEG7.LE.NOISE).AND.(DEG5.LE.NOISE)) RGNERR(J)=NOISE
          RGNERR(J) = MAX(NOISE,RGNERR(J))
          IF (RGNERR(J).GT.GREATE) THEN
              GREATE = RGNERR(J)
          END IF
  130 CONTINUE
C
C***END DRLTRI
C
      END
C ---- extracted from listing lines 1367-1408: DTEST1
      PROGRAM DTEST1  
      INTEGER NUMFUN,NW,MDIV,MINPTS,LENVER,NUMTRI
      PARAMETER (NUMFUN=1,MDIV=1,NUMTRI=1,MINPTS=37)
      PARAMETER ( LENVER = 100 )
C
C   We need to choose LENVER  such that:
C   LENVER >= 3*((MAXPTS-37*NUMTRI)/(4*37)) + NUMTRI 
C   This simply means that we have enough space to achieve MAXPTS
C   function evaluations. By choosing LENVER bigger than 
C   this lower bound we may later change MAXPTS and RESTAR and restart
C   the computations from the point where the last run stopped.
C   The reason for stopping may have been that MAXPTS was too small
C   to achieve the requested error.
C          With our choice LENVER = 100 any value of MAXPTS
C   between 37 and 5068 will be accepted by the code. Choosing
C   MAXPTS = 2000 allows us to restart with a greater value
C   if necessary.
C
      PARAMETER (NW = LENVER*(2*NUMFUN+1) +
     +                MAX(32*MDIV,8*NUMTRI)*NUMFUN + 1)
      DOUBLE PRECISION VER(2,3,LENVER),RESULT(NUMFUN),
     +                 ABSERR(NUMFUN),WORK(NW),EPSABS,EPSREL
      INTEGER RESTAR,NEVAL,IFAIL,IWORK(LENVER+MDIV),MAXPTS
      EXTERNAL F
      VER(1,1,1) = 0.D0
      VER(1,2,1) = 2.D0
      VER(1,3,1) = 0.D0
      VER(2,1,1) = 0.D0
      VER(2,2,1) = 0.D0
      VER(2,3,1) = 2.D0
      EPSABS = 0.D0
      EPSREL = 1.D-5
      RESTAR = 0
      MAXPTS = 2000
      CALL DCUTRI(F,NUMFUN,VER,NUMTRI,MINPTS,MAXPTS,EPSABS,
     +            EPSREL,LENVER,NW,RESTAR,RESULT,ABSERR,NEVAL,
     +            IFAIL,WORK,IWORK)
      WRITE(*,*)'RESULT=',RESULT(1)
      WRITE(*,*)'ERROR =',ABSERR(1)
      WRITE(*,*)'NEVAL =',NEVAL
      WRITE(*,*)'IFAIL =',IFAIL
      END
C ---- extracted from listing lines 1409-1414: F
      SUBROUTINE F(X,NUMFUN,FUNVLS)
      INTEGER NUMFUN
      DOUBLE PRECISION X(2),FUNVLS(NUMFUN)
      FUNVLS(1) = EXP(X(1)*X(1)+X(2)*X(2))
      RETURN
      END
C ---- extracted from listing lines 1815-1933: DTRTRI
      SUBROUTINE DTRTRI(DVFLAG,SBRGNS,GREATE,LIST,NEW)
C***BEGIN PROLOGUE DTRTRI
C***REFER TO DCUTRI
C***PURPOSE  DTRTRI maintains a heap of subregions.
C***DESCRIPTION DTRTRI maintains a heap of subregions.
C            The subregions are stored in a partially sorted
C            binary tree, ordered according to the size of the
C            greatest error estimates of each subregion(GREATE).
C            The subregion with greatest error estimate is in the
C            first position of the heap.
C
C   PARAMETERS
C
C     DVFLAG Integer.
C            If DVFLAG = 1, we remove the subregion with
C            greatest error from the heap.
C            If DVFLAG = 2, we insert a new subregion in the heap.
C     SBRGNS Integer.
C            Number of subregions in the heap.
C     GREATE Real array of dimension SBRGNS.
C            Used to store the greatest estimated errors in
C            all subregions.
C     LIST   Integer array of dimension SBRGNS.
C            Used as a partially ordered list of pointers to the
C            different subregions. This list is a heap where the
C            element on top of the list is the subregion with the
C            greatest error estimate.
C     NEW    Integer.
C            Index to the new region to be inserted in the heap.
C***ROUTINES CALLED-NONE
C***END PROLOGUE DTRTRI
C
C   Global variables.
C
      INTEGER DVFLAG,NEW,SBRGNS,LIST(*)
      DOUBLE PRECISION GREATE(*)
C
C   Local variables.
C
C   GREAT  is used as intermediate storage for the greatest error of a
C          subregion.
C   SUBRGN Position of child/parent subregion in the heap.
C   SUBTMP Position of parent/child subregion in the heap.
      INTEGER SUBRGN,SUBTMP
      DOUBLE PRECISION GREAT
C
C***FIRST EXECUTABLE STATEMENT DTRTRI
C
C    If DVFLAG = 1, we will reduce the partial ordered list by the
C    element with greatest estimated error. Thus the element in
C    in the heap with index LIST(1) is vacant and can be used later.
C    Reducing the heap by one element implies that the last element
C    should be re-positioned.
C
      IF (DVFLAG.EQ.1) THEN
          GREAT = GREATE(LIST(SBRGNS))
          SBRGNS = SBRGNS - 1
          SUBRGN = 1
   20     SUBTMP = 2*SUBRGN
          IF (SUBTMP.LE.SBRGNS) THEN
              IF (SUBTMP.NE.SBRGNS) THEN
C
C   Find max. of left and right child.
C
                  IF (GREATE(LIST(SUBTMP)).LT.
     +                GREATE(LIST(SUBTMP+1))) THEN
                      SUBTMP = SUBTMP + 1
                  END IF
              END IF
C
C   Compare max.child with parent.
C   If parent is max., then done.
C
              IF (GREAT.LT.GREATE(LIST(SUBTMP))) THEN
C
C   Move the pointer at position SUBTMP up the heap.
C
                  LIST(SUBRGN) = LIST(SUBTMP)
                  SUBRGN = SUBTMP
                  GO TO 20
              END IF
          END IF
C
C   Update the pointer.
C
          IF (SBRGNS.GT.0) THEN
              LIST(SUBRGN) = LIST(SBRGNS+1)
          END IF
      ELSE IF (DVFLAG.EQ.2) THEN
C
C   If DVFLAG = 2, find the position for the NEW region in the heap.
C
          GREAT = GREATE(NEW)
          SUBRGN = SBRGNS
   40     SUBTMP = SUBRGN/2
          IF (SUBTMP.GE.1) THEN
C
C   Compare max.child with parent.
C   If parent is max, then done.
C
              IF (GREAT.GT.GREATE(LIST(SUBTMP))) THEN
C
C   Move the pointer at position SUBTMP down the heap.
C
                  LIST(SUBRGN) = LIST(SUBTMP)
                  SUBRGN = SUBTMP
                  GO TO 40
              END IF
          END IF
C
C    Set the pointer to the new region in the heap.
C
          LIST(SUBRGN) = NEW
      END IF
C
C***END DTRTRI
C
      RETURN
      END
C ---- extracted from listing lines 1935-2298: DADTRI
      SUBROUTINE DADTRI(NUMFUN,MDIV,VER,NUMTRI,MINSUB,MAXSUB,FUNSUB,
     +                  EPSABS,EPSREL,LENVER,RESTAR,LENW,RESULT,ABSERR,
     +                  NEVAL,NSUB,IFAIL,VALUES,ERRORS,GREATE,WORK2,
     +                  LIST,VACANT)
C***BEGIN PROLOGUE DADTRI
C***REFER TO DCUTRI
C***DESCRIPTION Computation of integrals over triangular
C            regions.
C
C            DADTRI repeatedly
C            subdivides the triangles with greatest estimated  errors
C            and estimates the integrals and the
C            errors over the new subtriangles
C            until either the error request
C            is met or MAXPTS function evaluations have been used.
C
C            A 37 point integration rule
C            with all evaluation points inside the triangle
C            is applied. The rule has polynomial degree 13.
C
C   ON ENTRY
C
C     NUMFUN Integer.
C            Number of components of the integral.
C     MDIV   Integer.
C            MDIV is the number of triangles that are divided in
C            each subdivision step in DADTRI.
C            MDIV is chosen by default to be 1.
C            For efficient execution on parallel computers
C            with NPROC processors MDIV should be set equal to
C            the smallest integer such that MOD(4*MDIV,NPROC) = 0.
C     VER    Real array of dimension (2,3,LENVER).
C            VER(1,K,L) and VER(2,K,L) are the x and y coordinates
C            respectively of vertex K in triangle L.
C            On entry VER(*,*,L) must contain the vertices of the
C            NUMTRI user specified triangles for L = 1,2,...,NUMTRI.
C     NUMTRI Integer.
C            The number of triangles.
C     MINSUB Integer.
C            The minimum allowed number of subregions.
C     MAXSUB Integer.
C            The maximum allowed number of subregions.
C     FUNSUB Externally declared subroutine for computing
C            all components of the integrand at the given
C            evaluation point.
C            It must have parameters (X,NUMFUN,FUNVLS)
C            Input parameters:
C              X(1)      The x-coordinate of the evaluation point.
C              X(2)      The y-coordinate of the evaluation point.
C              NUMFUN Integer that defines the number of
C                     components of I.
C            Output parameter:
C              FUNVLS Real array of dimension NUMFUN
C                     that defines NUMFUN components of the integrand.
C
C     EPSABS Real.
C            Requested absolute error.
C     EPSREL Real.
C            Requested relative error.
C
C     LENVER Integer.
C            Defines the length of the array VER.
C
C            We let
C            MAXSUB denote the maximum allowed number of subregions
C            for the given values of MAXPTS.
C            MAXSUB = 3*((MAXPTS-37*NUMTRI)/(4*37)) + NUMTRI
C            LENVER should then be greater or equal to MAXSUB.
C
C     RESTAR Integer.
C            If RESTAR = 0, this is the first attempt to compute
C            the integral.
C            If RESTAR = 1,
C            then we restart a previous attempt.
C            In this case the only parameters for DCUTRI that may
C            be changed (with respect to the previous call of DCUTRI)
C            are MINPTS, MAXPTS, EPSABS, EPSREL and RESTAR.
C     LENW   Integer.
C            Length of the workspace WORK2.
C   ON RETURN
C
C     RESULT Real array of dimension NUMFUN.
C            Approximations to all components of the integral.
C     ABSERR Real array of dimension NUMFUN.
C            Estimates of absolute errors.
C     NEVAL  Integer.
C            Number of function evaluations used by DCUTRI.
C     NSUB   Integer.
C            The number of triangles in the data structure.
C     IFAIL  Integer.
C            IFAIL = 0 for normal exit.
C
C              ABSERR(K) <=  EPSABS or
C              ABSERR(K) <=  ABS(RESULT(K))*EPSREL with MAXPTS or less
C              function evaluations for all values of K,
C              1 <= K <= NUMFUN .
C
C            IFAIL = 1 if MAXSUB was too small for DADTRI
C              to obtain the required accuracy. In this case DADTRI
C              returns values of RESULT with estimated absolute
C              errors ABSERR.
C     VALUES Real array of dimension (NUMFUN,MAXSUB).
C            The estimated components of the integrals over the
C            subregions.
C     ERRORS Real array of dimension (NUMFUN,MAXSUB).
C            The estimated errors over the subregions.
C     GREATE Real array of dimension MAXSUB.
C            The greatest errors in each subregion.
C     WORK2   Real array of dimension LENW.
C            Work array used in DTRTRI and DRLTRI.
C     LIST   Integer array used in DTRTRI of dimension LENVER.
C            Is a partially sorted list, where LIST(1) is the top
C            element in a heap of subregions.
C     VACANT Integer array of dimension MDIV.
C            Used as intermediate storage of pointers.
C
C***ROUTINES CALLED DTRTRI,DRLTRI
C***END PROLOGUE DADTRI
C
C   Global variables.
C
      EXTERNAL FUNSUB
      INTEGER NUMFUN,MDIV,NUMTRI,MINSUB,MAXSUB,LENW,RESTAR,LENVER,NEVAL,
     +        NSUB,IFAIL,LIST(LENVER),VACANT(MDIV)
      DOUBLE PRECISION VER(2,3,LENVER),EPSABS,EPSREL,RESULT(NUMFUN),
     +                 ABSERR(NUMFUN),VALUES(NUMFUN,MAXSUB),
     +                 ERRORS(NUMFUN,MAXSUB),GREATE(MAXSUB),WORK2(LENW)
C
C   Local variables.
C
C   SBRGNS is the number of stored subregions.
C   NDIV   The number of subregions to be divided in each main step.
C   POINTR Pointer to the position in the data structure where
C          the new subregions are to be stored.
C   TOP    is a pointer to the top element in the heap of subregions.
C
      INTEGER I,J,K,L
      INTEGER SBRGNS,I1,I2,I3,I4,SIZE
      INTEGER L1
      INTEGER NDIV,POINTR,INDEX,TOP
      DOUBLE PRECISION VEROLD(2,3)
C
C***FIRST EXECUTABLE STATEMENT DADTRI
C
      IF (RESTAR.EQ.1) THEN
          SBRGNS = NSUB
          GO TO 110
      END IF
C
C   Initiate SBRGNS, RESULT, ABSERR and NEVAL.
C
      SBRGNS = 0
      DO 10 J = 1,NUMFUN
          RESULT(J) = 0
          ABSERR(J) = 0
   10 CONTINUE
      NEVAL = 0
C
C   Apply DRLTRI over the NUMTRI triangles.
C   This loop may be run in parallel.
C
      DO 20 I = 1,NUMTRI
          L1 = 1 + (I-1)*8*NUMFUN
          CALL DRLTRI(VER(1,1,I),NUMFUN,FUNSUB,WORK2(L1),VALUES(1,I),
     +                ERRORS(1,I),GREATE(I))
          NEVAL = NEVAL + 37
          SBRGNS = SBRGNS + 1
   20 CONTINUE
C
C   Add the computed values to RESULT and ABSERR.
C
      DO 40 I = 1,NUMTRI
          DO 30 J = 1,NUMFUN
              RESULT(J) = RESULT(J) + VALUES(J,I)
              ABSERR(J) = ABSERR(J) + ERRORS(J,I)
   30     CONTINUE
   40 CONTINUE
C
C   Store results in heap.
C
      DO 50 I = 1,NUMTRI
          INDEX = I
          CALL DTRTRI(2,INDEX,GREATE,LIST,I)
   50 CONTINUE
C
C   We check for termination.
C
      IF (SBRGNS.LT.MINSUB) THEN
          GO TO 110
      END IF
      DO 60 J = 1,NUMFUN
          IF (ABSERR(J).GT.EPSREL*ABS(RESULT(J)) .AND.
     +        ABSERR(J).GT.EPSABS) THEN
              GO TO 110
          END IF
   60 CONTINUE
      IFAIL = 0
      GO TO 499
C
C***End initiation.
C
C***Begin loop while the error is too great,
C   and SBRGNS+3 is less than MAXSUB.
C
  110 IF (SBRGNS+3.LE.MAXSUB) THEN
C
C   If we are allowed to divide further,
C   prepare to apply basic rule over  the triangles produced
C   by dividing the
C   NDIV subtriangles with greatest errors.
C   If MAXSUB and SBRGNS are great enough, NDIV = MDIV.
C
          NDIV = MAXSUB - SBRGNS
          NDIV = MIN(NDIV,MDIV,SBRGNS)
C
C   Divide the NDIV subtriangles in four new subtriangles, and compute
C   integral and error over each.
C   When we pick a triangle to divide in four, then one of the new
C   sub-triangles is stored in the original triangle's position in the
C   datastructure. Thus we get 3*NDIV new elements in the datastructure
C   after the subdivision. The size of the datastructure before the
C   subdivision is stored in the variable SIZE, while SBRGNS is the
C   size of the heap at any time.
C   Hence. 
C
          SIZE = SBRGNS
          DO 150 I = 1,NDIV
              POINTR = SIZE + 3* (NDIV+1-I)
C
C   Adjust RESULT and ABSERR. TOP is a pointer to the top of the heap.
C
              TOP = LIST(1)
              VACANT(I) = TOP
              DO 115 J = 1,NUMFUN
                  RESULT(J) = RESULT(J) - VALUES(J,TOP)
                  ABSERR(J) = ABSERR(J) - ERRORS(J,TOP)
  115         CONTINUE
C
C   Save the vertices.
C
              DO 130 L = 1,2
                  DO 135 K = 1,3
                      VEROLD(L,K) = VER(L,K,TOP)
  135             CONTINUE
  130         CONTINUE
C
C   Adjust the heap.
C
              CALL DTRTRI(1,SBRGNS,GREATE,LIST,K)
C
C   Compute the four new triangles.
C
              I1 = TOP
              I2 = POINTR - 2
              I3 = POINTR - 1
              I4 = POINTR
              VER(1,1,I1) = VEROLD(1,1)
              VER(2,1,I1) = VEROLD(2,1)
              VER(1,2,I1) = (VEROLD(1,1)+VEROLD(1,2))/2
              VER(2,2,I1) = (VEROLD(2,1)+VEROLD(2,2))/2
              VER(1,3,I1) = (VEROLD(1,1)+VEROLD(1,3))/2
              VER(2,3,I1) = (VEROLD(2,1)+VEROLD(2,3))/2
              VER(1,1,I2) = VER(1,2,I1)
              VER(2,1,I2) = VER(2,2,I1)
              VER(1,2,I2) = VEROLD(1,2)
              VER(2,2,I2) = VEROLD(2,2)
              VER(1,3,I2) = (VEROLD(1,2)+VEROLD(1,3))/2
              VER(2,3,I2) = (VEROLD(2,2)+VEROLD(2,3))/2
              VER(1,1,I3) = VER(1,3,I1)
              VER(2,1,I3) = VER(2,3,I1)
              VER(1,2,I3) = VER(1,3,I2)
              VER(2,2,I3) = VER(2,3,I2)
              VER(1,3,I3) = VEROLD(1,3)
              VER(2,3,I3) = VEROLD(2,3)
              VER(1,1,I4) = VER(1,3,I2)
              VER(2,1,I4) = VER(2,3,I2)
              VER(1,2,I4) = VER(1,3,I1)
              VER(2,2,I4) = VER(2,3,I1)
              VER(1,3,I4) = VER(1,2,I1)
              VER(2,3,I4) = VER(2,2,I1)
  150     CONTINUE
C
C   Apply basic rule over 4*NDIV triangles.
C   This loop may be run in parallel.
C
          DO 200 I = 1,4*NDIV
              IF (I.LE.NDIV) THEN
                  INDEX = VACANT(I)
              ELSE
                  INDEX = SBRGNS + I
              END IF
              L1 = 1 + (I-1)*8*NUMFUN
              CALL DRLTRI(VER(1,1,INDEX),NUMFUN,FUNSUB,WORK2(L1),
     +                    VALUES(1,INDEX),ERRORS(1,INDEX),GREATE(INDEX))
  200     CONTINUE
          NEVAL = NEVAL + 4*NDIV*37
C
C   Add new contributions to RESULT and ABSERR.
C
          DO 220 I = 1,4*NDIV
              IF (I.LE.NDIV) THEN
                  INDEX = VACANT(I)
              ELSE
                  INDEX = SBRGNS + I
              END IF
              DO 210 J = 1,NUMFUN
                  RESULT(J) = RESULT(J) + VALUES(J,INDEX)
                  ABSERR(J) = ABSERR(J) + ERRORS(J,INDEX)
  210         CONTINUE
  220     CONTINUE
C
C   Store results in heap.
C
          DO 250 I = 1,4*NDIV
              IF (I.LE.NDIV) THEN
                  INDEX = VACANT(I)
              ELSE
                  INDEX = SBRGNS + I
              END IF
              J = SBRGNS + I
              CALL DTRTRI(2,J,GREATE,LIST,INDEX)
  250     CONTINUE
          SBRGNS = SBRGNS + 4*NDIV
C
C   Check for termination.
C
          IF (SBRGNS.LT.MINSUB) THEN
              GO TO 110
          END IF
          DO 255 J = 1,NUMFUN
              IF (ABSERR(J).GT.EPSREL*ABS(RESULT(J)) .AND.
     +            ABSERR(J).GT.EPSABS) THEN
                  GO TO 110
              END IF
  255     CONTINUE
          IFAIL = 0
C
C   Else we did not succeed with the
C   given value of MAXSUB.
C
      ELSE
          IFAIL = 1
      END IF
C
C   Compute more accurate values of RESULT and ABSERR.
C
 499  CONTINUE
      DO 500 J = 1,NUMFUN
          RESULT(J) = 0
          ABSERR(J) = 0
  500 CONTINUE
      DO 510 I = 1,SBRGNS
          DO 505 J = 1,NUMFUN
              RESULT(J) = RESULT(J) + VALUES(J,I)
              ABSERR(J) = ABSERR(J) + ERRORS(J,I)
  505     CONTINUE
  510 CONTINUE
C
      NSUB = SBRGNS
      RETURN
C
C***END DADTRI
C
      END
