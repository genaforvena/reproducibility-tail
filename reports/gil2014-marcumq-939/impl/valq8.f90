! Value driver for the Gil, Segura, Temme 2014 claim (Algorithm 939).
! The shipped testmarq.f90 prints only relative errors (testQP.dat), not the
! Marcum-Q value itself. This driver calls the authors' public routine
! MarcumQ::marcum unchanged at the claimed point mu = 8, x = 13, y = 15 and
! prints the Q value. It is new code written for this rerun (basis: patched).
  PROGRAM valq8
  USE MarcumQ
  USE Someconstants
  IMPLICIT NONE
  REAL(r8) mu, x, y, p, q
  INTEGER ierr
  CHARACTER(len=32) str
  mu = 8.0_r8
  x  = 13.0_r8
  y  = 15.0_r8
  ierr = 0
  CALL marcum(mu, x, y, p, q, ierr)
  WRITE(str,'(ES25.16)') q
  WRITE(*,'(A,I0)') 'IERR ', ierr
  WRITE(*,'(A)') 'VALUE Q_mu8_x13_y15 ' // TRIM(ADJUSTL(str))
  END PROGRAM valq8
