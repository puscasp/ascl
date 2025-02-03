extern long ascl_array_sum(long* adr, long len);
extern long ascl_add(long x0, long x1);
extern long ascl_max_rowsum(long** A, long m, long n);
extern long ascl_max_colsum(long** A, long m, long n);
extern void ascl_ut(double** A, long m, long n);
extern void ascl_bkwd(double** A, long m, long n, double* b, double* x );
extern void ascl_rref(double** A, long m, long n, double* b, double* x );
extern long ascl_test();
extern void ascl_matrix_mul(double** A, double** B, double ** C, long m, long n, long p);

extern double ascl_secant(double (*f)(double), int maxiterations, double x0, double x1, double tol);