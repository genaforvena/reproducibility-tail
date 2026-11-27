C     Written for this rerun (not in the archive). The archive's VAX NCPJOB calls the system routine ETIME
C     (EXTERNAL ETIME). gfortran provides no external ETIME symbol, so the link fails. This shim supplies the
C     same function from CPU_TIME. It only feeds NCPJOB, the CPU-time limit check, not the numerical method.
      REAL FUNCTION ETIME(TARRAY)
      REAL TARRAY(2), T
      CALL CPU_TIME(T)
      TARRAY(1) = T
      TARRAY(2) = 0.0
      ETIME = T
      RETURN
      END
