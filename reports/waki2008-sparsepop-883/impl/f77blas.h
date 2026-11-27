/* SeDuMi (OCTAVE branch) needs blasint and BLASFUNC from ATLAS f77blas.h; the system libblas uses the name_ suffix. */
#ifndef F77BLAS_SHIM_H
#define F77BLAS_SHIM_H
typedef int blasint;
#define BLASFUNC(x) x##_
double ddot_(const blasint *n, const double *x, const blasint *incx, const double *y, const blasint *incy);
void dcopy_(const blasint *n, const double *x, const blasint *incx, double *y, const blasint *incy);
void dscal_(const blasint *n, const double *alpha, double *x, const blasint *incx);
void daxpy_(const blasint *n, const double *alpha, const double *x, const blasint *incx, double *y, const blasint *incy);
#endif
