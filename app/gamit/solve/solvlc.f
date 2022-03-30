Copyright (c) Massachusetts Institute of Technology,1986. All rights reserved.
c
      subroutine solvlc(x,nded,rnew,zeroad)
c
      implicit none

      include '../includes/dimpar.h'
      include 'solve.h' 
      include 'parameters.h'
  
      logical zeroad

      integer nb12,ianew,nded,ilive,k0,k1,k2,ia1,ia2,il21,i

      real*8 x(maxprm),rnew,fac,sm
c
C      STATEMENT OF PROBLEM:
C   GIVEN A COEFFICIENT MATRIX A
C   A RIGHT HAND VECTOR B
C   NUMBER OF VARIABLES ntpart
C   A VECTOR WHICH FLAGS FIXED OR FREE PARAMS (FREE)
C
C     WE WISH TO
C   A. SOLVE FOR THE FREE PARAMS FOR FIXED VALUES OF THE
C      FIXED PARAMS
C
C   B.   CALCULATE CHI2 FOR VALUES OF THE FIXED PARAMS,
C        CHI2 BEING MINIMIZED W.R.T FREE PARAMS
C        (NOT NECESSARILY IN THAT ORDER)
C
C    THE EQUATIONS CAN BE WRITTEN SIMPLY IN <BRA|KET> NOTATION
C
C      IF:
C      |X>	IS THE PARAMTER VECTOR
C      |B>	IS THE R.H.S	VECTOR
C       A	IS THE COEFFICIENT MATRIX
C      R2SUM	 IS THE WEIGHTED SUM OF THE SQUARED RESIDUALS
C
C  WE USE THE SUBSCRIPT 1 TO MARK THE SUBSPACE
C     OF THE FREE PARAMTERS, 2 FOR THE FIXED
C
C       THUS WE WRITE |X>=|X1>*|X2>    WHERE * IS TENSOR PRODUCT
C       LIKEWISE    |B>=|B1>*|B2>
C
C WHILE A IS BROKEN DOWN:
C
C     I  A11       | A12 I
C     I            |     I
C A = I............|.....I
C     I  A21       | A22 I
C
C     THE ONLY MATRIX WHICH HAS TO BE INVERTED IS A11
C
C THE SOLUTIONS:
C
C LET |B1'> = |B1>-A12|X2>
C
C  THEN |X1> = INVERSE(A11)|B1'> = INV(A11)|B1> - INV(A11)A12|X2>
C
C AND CHI2 = R2SUM - 2*<B2|X2> + <X2|A22|X2> - <X1|A11|X1>
C          = R2SUM - 2<B|X> + <X|A|X>
C
C        IF WE WISH TO SOLVE FOR |X1> FIRST
C
C AND CHI2 = R2SUM - 2*<B2|X2> + <X2|A22|X2> - <B1'|INV(A11)|B1'>
C
C       IF WE DON'T
C
C    THE FUNCTION OF SOLVE1 IS TO FORM THE MATRIX A11 AND INVERT
C
C    THE FUCTION OF SOLVE2 IS TO SOLVE FOR |X1> AND CHI2
C    FOR THE PARTICULAR VALUES OF |X2> WITH WHICH
C    SOLVE2 IS CALLED
C   dec 23,1983  add solve 3. see below
C---------------------------------------------------------------------------
C  DEC 23 1983
C   SOLVE1 AND SOLVE2 are a nice pair of programs.
C   However, they are not optimal for bias searching, that is,
C   for calculating chi2 for changes in values of fixed parameters
C   where the parameters are the same each time but their values
C   change.
C   To speed up this process we are going to rewrite the equations to
C   precalculate as much as possible.
C
C   The fixed parameters are |x2>
C   from above:
C   AND CHI2 = R2SUM - 2*<B2|X2> + <X2|A22|X2> - <B1'|INV(A11)|B1'>
C      |B1'> = |B1>-A12|X2>
C
C      CHI2 = R2SUM - 2*<B2|X2> + <X2|A22|X2>
C            -<X2|A21 inv(A11) A12 |X2> - <B1|inv(A11)|B1>
C            +2 * <B1|inv(A11) A12|X2>
C
C   If we write:
C      RNEW = R2SUM - <B1|inv(A11)|B1>
C      |BNEW> =(|B2> - A21 inv(A11) |B1> )
C      ANEW =	A22 - A21 inv(A11) A12
C      remember that on entry to SOLVE2 the vector b
C      actually contains inv(A11)|B1>
C      a is inv(A11)
C      and that A21 is the transpose of A12
C
C      CHI2 then = RNEW + <X2|ANEW|X2> - 2.* <BNEW|X2>
C
C       |X1> =    inv(A11)|B1> -inv(A11)A12|X2>
C
C at present I don't see the need for precalculating inv(A11)A12
C because I don't see a need for calculating |X1> repeatedly.
C
C ANEW can be stored in the A11 array after A11.
C BNEW can be stored in the same place after ANEW
C
C All the precalculation is done in SOLVE2
C
C SOLVE3 will now solve for chi2 and/or |X1> in the fastest way possible
C
C The new Solve3 has a parameter Ifast. If Ifast is positive
C everything will be skipped down to the CHI2 calculation.
C If it is negative, only the parame will be solved for.
C
C If this parameter is placed in common/FASTX2/ the calling
C sequences will not have to be changed. The scheme will recquire
C That solve2 remains in core but speed calls for that anyway.
C
C---------------------------------------------------------------------------
C
C---- In most cases, we calculate X1 without any priori adjustment value
c---- on X2.  In these cases, we do not need to calculate ANEW and BNEW.
C---- It will save a lot of CPU time.              DND 880902
C----    If X2 = 0 , then
C----          |X1> = inv(A11)|B1>
C----          CHI2 = RNEW
C---- We get all results in SOLVE2.(When X2 = 0)
C---- In LC mode, we don't need to calculate ANEW and BNEW either.
C---- If L2-L1 biases are derived from L1, L2 separate mode and all
C---- priori adjustment values of other dead parameters are zero, the
C---- theoretical deduction shows ANEW=0 and BNEW=0.
C---- In this case,
C----        CHI2 = RNEW
C----        |X1(initial)> = inv(A11)|B1>
C----        |X1(final,non-bias)> = |X1(initial,non-bias)>
C----        |L1(final,bias)> = |L1(initial,bias)> + g/(1-g)(L2-L1)
C----                                              DND 880904
C
c* This now set from fL1, fL2 in gethed.f from c-file and stored in solve.h
c      DATA GEAR/0.779220779220779D+00/
C  1/(77/60-1)
      FAC = GEAR/(1.0D0-GEAR)
C
      ILIVE = 0
      SM = 1.D-13
      ZEROAD  =  .true.
C
C     START INDEX OF ANEW ARRAY
      IANEW = NLIVE*(NLIVE+1)/2
C     START INDEX OF A12 ARRAY
      NB12 = IANEW+NDED*(NDED+1)/2
CD     WRITE(6,444)
CD 444 FORMAT(' IN SOLVLC')
C
C  do  RNEW = R2SUM - <B1|INV(A11)|B1>
C  here:  b = INV(A11)|B1>, borg = B1
C
      RNEW = R2SUM
      DO 100 I = 1,ntpart
         IF(FREE(I).EQ.0) GO TO 100
         ILIVE = ILIVE+1
         RNEW = RNEW-BORG(I)*b(ILIVE)
100   CONTINUE
C
C---- Check if there is any priori non-zero adjustment value for X2.
      K0 = IDXB(1)
      IF (K0.LT.0) K0 = -K0
      K1 = K0
      DO 120 I = 1,K1-1
         IF (FREE(I).EQ.1) GOTO 120
         IF (DABS(X(I)).GT.SM) THEN
            ZEROAD = .false.
            GOTO 140
         ENDIF
 120  CONTINUE
C---- Check L1 biases 
         k2 = L1BIAS
         IA1 = K1
         IA2 = K1+K2-1
         K1 = K1+K2*2
         DO 132 I = IA1,IA2
            IF (FREE(I).EQ.1) GOTO 132
            IF (DABS(X(I)).GT.SM) THEN
               ZEROAD = .false.
               GOTO 140
            ENDIF
 132     CONTINUE

C---- X2 = 0. We derive results here.
      IF ( ZEROAD ) THEN
         CHI2 = RNEW
         ILIVE = 0
         K1 = K0
         DO 160 I = 1,K1-1
            IF(FREE(I).EQ.0) GO TO 160
            ILIVE = ILIVE+1
            X(I) = b(ILIVE)
 160     CONTINUE
            k2 = L1BIAS
            IA1 = K1
            IA2 = K1+K2-1
            K1 = K1+K2*2
            DO 172 I = IA1,IA2
               IF(FREE(I).EQ.0) GO TO 172
               ILIVE = ILIVE+1
               IL21 = I+K2
               X(I) = b(ILIVE)+FAC*X(IL21)
 172        CONTINUE
         GOTO 601
      ENDIF

C---- X2 1s non-zero. We have to calculate ANEW and BNEW.
 140  CONTINUE
c
c     calculate ANEW, BNEW
c
      call abnew(ntpart,nb12,ianew,x,nded)
c
601   continue
c----------------------------------------------------------------------
      return
      end
