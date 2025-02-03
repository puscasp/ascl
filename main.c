#include <stdio.h>
#include <math.h>
#include "ascl.h"

void matrixtest()
{
    
    double r1[] = {1.0,2.0,2.0};
    double r2[] = {4.0,5.0,6.0};
    double r3[] = {9.0,8.0,7.0};

    double* A[] = {r1, r2,r3};

        for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf("%f ", A[i][j]);
        }
        printf("\n");
    }
    
    double b[] = {1.0,2.0,3.0};
    double x[] = {0.0,0.0,0.0};

    ascl_rref(A,3,3,b,x);

    printf("\n\n\n");
        for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf("%f ", A[i][j]);
        }
        printf("\n");
    }
    printf("\n\nb\n");


    for (int i = 0; i < 3; i++) {
        printf("%f ", x[i]);
    }
    printf("\nhehe\n");

}

void secanttest(){

    double f(double x){
        
    return 5 -(x * x) ;
    }

    double y = ascl_secant(f,2000,1.0,3.0, 0.00000001);

    printf("%.17g\n", y);

}

void multtest() {
    double r1_A[] = {1.0, 2.0};
    double r2_A[] = {3.0, 4.0};
    double r3_A[] = {5.0, 6.0};

    // Combine rows into matrix A
    double* A[] = {r1_A, r2_A, r3_A};

    // Define rows for matrix B (2x3)
    double r1_B[] = {7.0, 8.0, 9.0};
    double r2_B[] = {10.0, 11.0, 12.0};

    // Combine rows into matrix B
    double* B[] = {r1_B, r2_B};

    // Define rows for matrix C (3x3)
    double r1_C[] = {0.0, 0.0, 0.0};
    double r2_C[] = {0.0, 0.0, 0.0};
    double r3_C[] = {0.0, 0.0, 0.0};

    // Combine rows into matrix C
    double* C[] = {r1_C, r2_C, r3_C};
    ascl_matrix_mul(A,B,C,3,2,3);

        for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf("%f ", C[i][j]);
        }
        printf("\n");
    }
    printf("\n\nb\n");


}



void main() {
 matrixtest();

}
