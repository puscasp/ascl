.global ascl_array_sum
.global ascl_add
.global ascl_max_colsum
.global ascl_max_rowsum
.global ascl_ut
.global ascl_bkwd
.global ascl_test
.global ascl_rref
.global ascl_matrix_mul

.global ascl_secant
.section .text
ascl_test:
    // create a 2x2 matrix, get max colsum, release, return.
    mov x2, #2
    //init row pointers:
    
    sub sp, sp, x2, lsl 4 //free up n*16 bytes of space

    mov x0, sp

    mov x3, xzr //row counter
    test_newrow:
        sub sp, sp, x2, lsl 4 //free up n*16 bytes of space again for the row
        add x4, x0, x3, lsl 3
        mov x5, sp
        str x5, [x4]

        add x3, x3, #1

        cmp x3, x2
        blt test_newrow


    mov x1, #1
    ldr x2, [x0]
    str x1, [x2]

    mov x1, #2
    ldr x2, [x0]
    str x1, [x2, #8]
    
    mov x1, #3
    ldr x2, [x0, #8]
    str x1, [x2]
    
    mov x1, #3
    ldr x2, [x0, #8]
    str x1, [x2, #8]



    mov x1, #2
    mov x2, #2
    
    sub sp, sp, #16
    stp lr, x3, [sp]
        bl ascl_max_rowsum
    ldp lr, x3, [sp]
    add sp, sp, #16


    
    add x3, x3, #1
    lsl x3, x3, #4 //recall we freed up n * (n*16) rows + (n*16) pointer refs ?
    mul x3, x3, x2
    add sp, sp, x3

    ret


/*-------------------------------------------------------------
 UTIL
*/
ascl_add:
    add x0, x0, x1

    ret 

//x0 = data start adr, x1 = length
//registers used: x0-3
ascl_array_sum:
    mov x2, #0 //r2 = 0
    lsl x1, x1, #3 //r1 *= 8 for word size of 8 bytes per elment
    add x1, x0, x1 // x1  = data stop adr

    loop:
        cmp x0,  x1  
        bge exit //if x0 >= x1 break

        ldr x3, [x0] //loads current element into x3 (adr stored in x0)
        add x2, x2, x3
        add x0, x0, #8
        b loop
    exit: 
        mov x0, x2
        ret

//x0 = A (R^m * R^n), x1 = m, x2 = n. Note that A is row major!!
//registers used: x0-8
ascl_max_colsum: //finds 1 operator norm of A (max abs column sum)
    mov x3, xzr //x3 = 0
    mov x4, xzr //max value

    colsumcolumnloop:
        
        mov x5, xzr // row index
        mov x6, xzr //temporary max

        colsumrowloop:
            mov x7, xzr
            mov x8, xzr
            
            //load row in memory
            lsl x8, x5, #3
            add x7, x8, x0
            ldr x7, [x7]

            //load element aij in memory
            lsl x8, x3, #3
            add x7, x8, x7
            ldr x7, [x7]


        
            cmp x7, xzr
            bge colsumad
                neg x7, x7
            colsumad:
            add x6, x6, x7


            add x5, x5, 1

            cmp x5, x1
            blt colsumrowloop

    //compare to previous max
    cmp x4, x6
    bge colsumnoswap
        mov x4, x6
    colsumnoswap:

    //next column
    add x3, x3, #1
    cmp x3, x2
    blt colsumcolumnloop


    mov x0, x4
    ret

//x0 = A (R^m * R^n), x1 = m, x2 = n. Note that A is row major!!
//registers used: x0-9
ascl_max_rowsum: //finds inf operator norm of A (max abs row sum)

    mov x3, xzr //x3 = current max norm

    mov x4, x0 //x4 = row address = i
    mov x9, xzr //x9 = row index

    rowloop: //foreach row

        ldr x5, [x4] //x5 = column address = j 
        mov x6, xzr //x6 = 0: current max sum sum

        mov x8, xzr //x8 = inner row index

        columnloop:

            ldr x7, [x5] //x7 = aij

            //if x7 >= 0 add to x6 otherwise add negate first then add

            cmp x7, xzr
            bge ad
                neg x7, x7
            ad:
            add x6, x6, x7

            add x8, x8, #1 //j += 1
            add x5, x5, #8 //aij = ai(j+1)

            cmp x8, x2
            blt columnloop


        cmp x3, x6 //dont swap if oldmax >= newmax
        bge noswap
            mov x3, x6 //max sum = this sum
        noswap:


    add x9, x9, #1 //j += 1
    add x4, x4, #8 //aij = a(i+1)j
    
    cmp x9, x1
    blt rowloop

    mov x0, x3
    ret
//done  inf norm

//x0 = A (m*n), x1 = At (n*m) x2 = m, x3 = n.
//registers used. x0-6, d0
ascl_transpose:
    mov x4, xzr
    transpose_rowloop:
        mov x5, xzr
        transpose_colloop:
            //have x4, x5 = i,j. Move A[i,j] to At[j,i]
            add x6, x0, x4, lsl 3
            ldr x6, [x6]
            add x6, x6, x5, lsl 3
            ldr d0, [x6]

            add x6, x1, x5, lsl 3
            ldr x6, [x6]
            add x6, x6, x4, lsl 3
            str d0, [x6]

        add x5, x5, #1
        cmp x5, x3
        blt transpose_colloop
    
        //done row, move on

    add x4, x4, #1
    cmp x4, x2
    blt transpose_rowloop

    mov x0, x1 
    ret
//end transpose

//stack allocates an n*m matrix. DOES NOT DEALLOCATE, MAKE SURE YOU DEALLOCATE IN SCOPE USED
//x0 = m, x1 = n
//uses x0..x5
ascl_stalloc:
    //x0, x1, x2
    //x3 = bytespace of rows needed to be allocated. 

    sub sp, sp, x0, lsl 3 //free up m*8 bytes of space
    mov x2, sp
    mov x3, xzr //row counter
    stalloc_newrow:
        sub sp, sp, x1, lsl 3 //free up n*8 bytes of space again for the row
        add x4, x2, x3, lsl 3
        mov x5, sp
        str x5, [x4]

        add x3, x3, #1

        cmp x3, x2
        blt stalloc_newrow

    mov x3, sp
    and x3, x3, -16
    mov sp, x3 //any multiple of 16 will have form ...11111000, so we just and the last 4 digits to hard align. since stack grows downwards, this effectively rounds up.
    mov x0, x2 //returns pointer to m*n array
    ret

//end stalloc




/*----------------------------------------------------------------
 Linear Algebra 

 All matrices defined as a 2d array of rows: i.e double**
*/

//x0 = A, x1 = m, x2 = n, x3 = x (1*n), x4 = b (1*n) because i refuse to use malloc in arm
//registers used: x0-13, d0-4. Fix to only use 0-9
ascl_rref:
    mov x13, xzr //column counter i[0..n) //x5
    rref_columnloop: //start debugging on last loop. i.e, when i = n-1 (x3 = 2)
        //x12 = adr of row i

        mov x5, xzr
        lsl x5, x13, #3
        add x12, x0, x5 
        ldr x12, [x12] //x12 = adr(ri)

        mov x6, x13 //x6 = k: [i+1..m], i.e, which row to reduce below i.
        add x6, x6, #1

        rref_reducerows: //ERROR WITH RETURN TO HERE, IT DONLY DOES ROW BELOW! need it to run twice  
           
            mov x8, x12//USE x8 as internal proxy while looping!!!!
            mov x5, xzr
            lsl x5, x6, #3
            add x5, x0, x5
            ldr x5, [x5] //x5 = adr row k

            lsl x9, x13, #3
            add x5, x9, x5
            add x8, x9, x8


            ldr d0, [x8] // d0 = aii
            ldr d1, [x5] // d1 = aki 


            fdiv d3, d1, d0 //   a*x + b = 0
            fmov d4, #-1.0
            fmul d3, d3, d4// d3 = -b / a //look into xoring sign bit

            mov x7, x13// j = [i..n)

            rref_rowloop:    

                ldr d1, [x8]
                ldr d2, [x5] 

                fmul d1, d1, d3
                fadd d2, d1, d2

                str d2, [x5] //update value in row 2

                add x7, x7, #1
                add x8, x8, #8
                add x5, x5, #8 

                //if j >= n, done adding this row
                cmp x7, x2
                blt rref_rowloop

            //here also make sure to reduce b
            mov x5, xzr
            lsl x5, x6, #3
            add x5, x3, x5 //x5 = bk


            lsl x9, x13, #3
            add x8, x9, x3 //x8 = bi?


            ldr d1, [x8] // d0 = bi
            ldr d2, [x5] // d1 = bk 

            fmul d1, d1, d3
            fadd d2, d1, d2


            str d2, [x5] 
            
            //b reduced!

            //atp entire row has been reduced, time to move on to the next row
            add x6, x6, #1
            
            //done reducing this row if k >= n
            cmp x6, x1
            blt rref_reducerows


        //finished reducing first column, quit if it was the second last row or last column
        
        add x13, x13, #1
        sub x12, x1, #2
        cmp x13, x12 //break if i > (m-2) --> i >= m
        bgt rref_backwards

        sub x12, x2, #0
        cmp x13, x2 //break if i > (n)
        bgt rref_backwards

        b rref_columnloop

    rref_backwards:

    //we now have a almost lower triangular matrix with last two columns full
    //reduce it with something like backwards substitution 

    sub x11, x2, #1
    lsl x11, x11, #3 //x11 = penultimate row id: = n-1.

    mov x12, x4 //x4 = static pointer to start of b (for some reason)


    mov x5, x11 //x5 = k = 8*(n -1).. 8*0 ... index of row in matrix, working up from penultimate to ultimate

        rref_bkwd_row:

        //xk
        add x6, x5, x3 // x6 = adr (x + k)
        ldr d0, [x6] //d0 = xk

        //akk
        add x7, x0, x5 //x7 = adr(L[k])
        ldr x7, [x7] //x7 = adr(L[k][0])
        add x7, x7, x5 //x7 = Adr(L[k][k])
        ldr d1, [x7] //d1 = Lkk

        cmp x5, x11
        beq rref_bkwd_bottom_corner

        mov x8, x5
        add x8, x8, #8 //i =\/


        //loop on i = (k+1 ... n) * 8
        rref_bkwd_previous_results:
            //find A[k,i]
            add x9, x5, x0
            ldr x9, [x9]
            add x9, x9, x8
            ldr d2, [x9] 

            //x[i]

            add x10, x12, x8 
            //sub x10, x10, #8
            ldr d3, [x10] 


            fmul d3, d3, d2
            fsub d0, d0, d3

            add x8, x8, #8


            cmp x8, x11
            ble rref_bkwd_previous_results

        rref_bkwd_bottom_corner:

        fdiv d0, d0, d1

        add x12, x12, x5
        str d0, [x12] //loads bottom corner perfectly :)

        mov x12, x4
        cmp x5, xzr
        sub x5, x5, #8
        bgt rref_bkwd_row


    mov x0, x4
    ret
//end of rref

//x0 = adr(A) (R^m * R^n), x1 = m, x2 = n
//uses x0-x9, d0-d5
ascl_ut:
    mov x3, xzr //column counter i[0..n)
    ut_columnloop: //start debugging on last loop. i.e, when i = n-1 (x3 = 2)
        //x4 = adr of row i

        mov x5, xzr
        lsl x5, x3, #3
        add x4, x0, x5 
        ldr x4, [x4] //x4 = adr(ri)

        mov x6, x3 //x6 = k: [i+1..m], i.e, which row to reduce below i.
        add x6, x6, #1

        ut_reducerows:  
           
            mov x8, x4//USE x8 as internal proxy while looping!!!!
            mov x5, xzr
            lsl x5, x6, #3
            add x5, x0, x5
            ldr x5, [x5] //x5 = adr row i+k


            //starts from second column here! need to shift column here
            
            lsl x9, x3, #3
            add x5, x9, x5
            add x8, x9, x8


            ldr d0, [x8] // d0 = aii
            ldr d1, [x5] // d1 = a(i+1)i 


            fdiv d3, d1, d0 //   a*x + b = 0
            fmov d4, #-1.0
            fmul d3, d3, d4// d3 = -b / a //look into xoring sign bit

            mov x7, x3// j = [i..n)

            ut_rowloop:    

                ldr d1, [x8]
                ldr d2, [x5] 

                fmul d1, d1, d3
                fadd d2, d1, d2

                str d2, [x5] //update value in row 2

                add x7, x7, #1
                add x8, x8, #8
                add x5, x5, #8 

                //if j >= n, done adding this row
                
                cmp x7, x2
                blt ut_rowloop
                

            //atp entire row has been reduced, time to move on to the next row
            add x6, x6, #1
            
            //done reducing this row if k >= n
            cmp x6, x1
            blt ut_reducerows


        //finished reducing first column, quit if it was the second last row or last column
        
        add x3, x3, #1
               

        sub x4, x1, #2
        cmp x3, x4 //break if i > (m-2) --> i >= m
        bgt ut_fin

        sub x4, x2, #0
        cmp x3, x2 //break if i > (n)
        bgt ut_fin

        b ut_columnloop

    ut_fin:

    ret


//end of upper triangular

//x0 = L, x1 = m, x2 = n, x3 = b (1*n), x4 = x (1*n)
//usex x0-x12, d0-d3
ascl_bkwd:
    sub x11, x2, #1
    lsl x11, x11, #3 //x11 = penultimate row id: = n-1.

    mov x12, x4 //x4 = static pointer to start of b (for some reason)


    mov x5, x11 //x5 = k = 8*(n -1).. 8*0 ... index of row in matrix, working up from penultimate to ultimate

        bkwd_row:

        //xk
        add x6, x5, x3 // x6 = adr (x + k)
        ldr d0, [x6] //d0 = xk

        //akk
        add x7, x0, x5 //x7 = adr(L[k])
        ldr x7, [x7] //x7 = adr(L[k][0])
        add x7, x7, x5 //x7 = Adr(L[k][k])
        ldr d1, [x7] //d1 = Lkk

        cmp x5, x11
        beq bkwd_bottom_corner

        mov x8, x5
        add x8, x8, #8 //i =\/


        //loop on i = (k+1 ... n) * 8
        bkwd_previous_results:
            //find A[k,i]
            add x9, x5, x0
            ldr x9, [x9]
            add x9, x9, x8
            ldr d2, [x9] //THIS WORKS! (in row 2)

            //x[i]

            add x10, x12, x8 // WRONG WRONG WRONG WRONG WRONG
            //sub x10, x10, #8
            ldr d3, [x10] // WRONG WRONG WRONG WRONG WRONG
                    //STORE AND READ FROM x12!!!!!!!!!!!!!!!


            fmul d3, d3, d2
            fsub d0, d0, d3

            add x8, x8, #8


            cmp x8, x11
            ble bkwd_previous_results

        bkwd_bottom_corner:

        fdiv d0, d0, d1

        add x12, x12, x5
        str d0, [x12] //loads bottom corner perfectly :)

        mov x12, x4
        cmp x5, xzr
        sub x5, x5, #8
        bgt bkwd_row


    mov x0, x3
    ret
//end of backwards substitution

//Naively computes C = AB, A being m*n, B being n*p, and C being m*p, in O(nmp)
//x0 = A, x1 = B, x2 = C, x3 = m, x4 = n, x5 = p
//uses x0-x9
ascl_matrix_mul:
    //use regs x6 + 
    mov x6, xzr// x6 = i [0..m-1]
    fmov d0, #1.0
    fsub d0, d0, d0
    
    amul_rowloop: //for each row in C
        mov x7, xzr // j [0..p-1]
        
        amul_colloop: //for each column in C
            //calculate C[i,j]
            //C[i,j] = Sum(k:1..n) a[i,k]*b[k,j]
            fsub d0, d0, d0

            mov x8, xzr //k = 0..n-1
            amul_cij:   
                add x9, x0, x6, lsl 3 //x9 = A[i]
                ldr x9, [x9]
                add x9, x9, x8, lsl 3
                ldr d1, [x9] // d1 = a[i][k]

                add x9, x1, x8, lsl 3 //x9 = b[k]
                ldr x9, [x9]
                add x9, x9, x7, lsl 3
                ldr d2, [x9] //d2 = b[k][j]

                fmul d1, d1, d2
                fadd d0, d0, d1
                
                add x8, x8, #1

                cmp x8, x4
                blt amul_cij
            //found c[i,j]
            
            add x9, x2, x6, lsl 3
            ldr x9, [x9] // ?
            add x9, x9, x7, lsl 3
            str d0, [x9] //write c[i,j]

            add x7, x7, #1
            cmp x7, x5
            blt amul_colloop  
        
        //done col loop
        add x6, x6, #1 //exit if i >= m
        cmp x6, x3
        blt amul_rowloop
    //done row loop
    mov x0, x2
    ret
//end of matrix multiplication

//x0 = A, x1 = v, x2 = n
ascl_find_eigenvalue:
    mov x9, sp //reset to this when done!
    mov x6, x0
    mov x7, x1
    mov x8, x2

    mov 
    bl ascl_stalloc

//done eigenvalue finding
//x0 = A (n*n), x1 = n, x2 = v (1*n), x3 = maximum iterations
ascl_power:
    //using matrices for 1) v, 
    mov x10, x0
    mov x11, x1
    mov x12, x2
    mov x13, x3
    

    bl ascl_stalloc

    mov x5, x0 // x5 = matrix v

    mov x0, x10
    mov x1, x11
    mov x2, x12
    mov x3, x13

    mov x6, xzr //x6 = lambda


    mov x7, xzr //x7 = index. temporarily do this without lamnda checking.
    pow_iterate:

        //  bk = Abk

        # calculate the norm
       // bknorm = norm(bk)

        # re normalize the vector
     //   bk = bk / bknorm

/*-------------------------------------------------------------
Calculus

*/

//x0 = f : R --> R, x1 = maxiterations, d0 = x0, d1 = x1, d2 = tol
//uses x0-x3, d0-d9. Uses fp, lr.
ascl_secant:
    mov x3, xzr //d3 = i, iterations done

    //d0 = xn-2, d1 = xn-1
    //d4 = xn-2, d5 = xn-1
    fmov d4, d0
    fmov d5, d1

    secant_iterate:
        //xn  = xn-1 - f(xn-1) * (xn-1 - xn-2) / (f(xn-1) - f(xn-2)) ----GOOD 

        //d1 = f(xn-1) --_GOOOD
        fmov d0, d5
        sub sp, sp, #16
        stp x29, x30, [sp] 
        mov x29, sp   
        
        blr x0
        ldp x29, x30, [sp], #16   
        fmov d3, d0
 
        //d0 = f(xn-2) --GOOOD
        fmov d0, d4
        sub sp, sp, #16
        stp x29, x30, [sp] 
        mov x29, sp   
        
        blr x0
        ldp x29, x30, [sp], #16   
        fmov d1, d3
        //d6 = (f(xn-1) - f(xn-2))
    
        fsub d6, d1, d0
        //d7 = xn
        fsub d7, d5, d4 //xn = xn-1 - xn-2
        fdiv d7, d7, d6 //xn = xn / (f(xn-1) - f(xn-2))
        fmul d7, d7, d1 //xn = xn * f(xn-1)
        fsub d7, d5, d7 //

      
        //maxiteration testing:
        add x3, x3, #1
        cmp x3, x1
        bge secant_done


        //error testing: break if abs(xn - xn-1) <= tol

        fsub d8, d7, d5
        fsub d9, d8, d8 //idiotic, why loading in #0.0 is invalid is beyond me.
        fcmp d8, d9
        bge secant_pos
        fmov d9, #-1.0
        fmul d8, d8, d9
        secant_pos:

        fcmp d8, d2
        ble secant_done

        //update variables: xn-1 --> xn-2, xn --> xn-1, loop
        fmov d4, d5
        fmov d5, d7
        b secant_iterate

    secant_done:

    fmov d0, d7
    ret  
//done secant method

