! Stand-in for the PORT library routine i1mach, which driver2.f90 calls as i1mach(2) for its
! output unit. PORT is not in the archive (Doc/PackingList: DriverLib port). Written by rerun from
! the driver's use only: unit 2 is the standard output unit, 6 on the usual Fortran systems.
! Other selectors are not used by driver2.f90 and return 0 here.
INTEGER FUNCTION i1mach(i)
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: i
    IF (i == 2) THEN
        i1mach = 6
    ELSE
        i1mach = 0
    END IF
END FUNCTION i1mach
