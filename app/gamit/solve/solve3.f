Copyright (c) Massachusetts Institute of Technology,1986. All rights reserved.

      subroutine SOLVE3( X,NDED,RNEW,IFAST)

      implicit none

      include '../includes/dimpar.h'
      include 'solve.h'
      include 'parameters.h'
           
      integer nb12,indx,ianew,ind,ipos,nded,ifast
     .      , ilive,jl,kd,ix1,ix2,i,j,k

      real*8 x(maxprm),dtemp,dtemp1,rnew,sm
C
C
C STATEMENT FUNCTION TO COMPUTE POSITIONS IN A SYMMETRIC MATRIX
C STORED ID DIAGANOL FORM
       IPOS(I,J)=MIN0(I,J) + MAX0(I,J)*(MAX0(I,J)-1)/2
C
C
C      STATEMENT OF PROBLEM:
C       GIVEN A COEFFICIENT MATRIX A
C       A RIGHT HAND VECTOR B
C       NUMBER OF VARIABLES ntpart
C       A VECTOR WHICH FLAGS FIXED OR FREE PARAMS (FREE)
C
C     WE WISH TO
C      A. SOLVE FOR THE FREE PARAMS FOR FIXED VALUES OF THE
C         FIXED PARAMS
C
C      B.   CALCULATE CHI2 FOR VALUES OF THE FIXED PARAMS,
C           CHI2 BEING MINIMIZED W.R.T FREE PARAMS
C           (NOT NECESSARILY IN THAT ORDER)
C
C
C
C    THE EQUATIONS CAN BE WRITTEN SIMPLY IN <BRA|KET> NOTATION
C
C
C      IF:
C       |X> IS THE PARAMTER VECTOR
C       |B> IS THE R.H.S	VECTOR
C        A  IS THE COEFFICIENT MATRIX
C       R2SUM IS THE WEIGHTED SUM OF THE SQUARED RESIDUALS
C
C
C  WE USE THE SUBSCRIPT 1 TO MARK THE SUBSPACE
C       OF THE FREE PARAMTERS, 2 FOR THE FIXED
C
C        THUS WE WRITE |X>=|X1>*|X2>    WHERE * IS TENSOR PRODUCT
C  LIKEWISE    |B>=|B1>*|B2>
C
C  WHILE A IS BROKEN DOWN:
C
C
C     I  A11       | A12 I
C     I            |     I
C A = I............|.....I
C     I  A21       | A22 I
C
C
C     THE ONLY MATRIX WHICH HAS TO BE INVERTED IS A11
C
C  THE SOLUTIONS:
C
C LET |B1'> = |B1>-A12|X2>
C
C  THEN |X1> = INVERSE(A11)|B1'> = INV(A11)|B1> - INV(A11)A12|X2>
C
C  AND CHI2 = R2SUM - 2*<B2|X2> + <X2|A22|X2> - <X1|A11|X1>
C           = R2SUM - 2<B|X> + <X|A|X>
C
C       IF WE WISH TO SOLVE FOR |X1> FIRST
C
C AND CHI2 = R2SUM - 2*<B2|X2> + <X2|A22|X2> - <B1'|INV(A11)|B1'>
C
C      IF WE DON'T
C
C
C    THE FUNCTION OF SOLVE1 IS TO FORM THE MATRIX A11 AND INVERT
C
C    THE FUCTION OF SOLVE2 IS TO SOLVE FOR |X1> AND CHI2
C    FOR THE PARTICULAR VALUES OF |X2> WITH WHICH
C    SOLVE2 IS CALLED
C    dec 23,1983  add solve 3. see below
C---------------------------------------------------------------------------
C DEC 23 1983
C SOLVE1 AND SOLVE2 are a nice pair of programs.
C However, they are not optimal for bias searching, that is,
C for calculating chi2 for changes in values of fixed parameters
C where the parameters are the same each time but their values
C change.
C To speed up this process we are going to rewrite the equations to
C precalculate as much as possible.
C
C The fixed parameters are |x2>
C from above:
C AND CHI2 = R2SUM - 2*<B2|X2> + <X2|A22|X2> - <B1'|INV(A11)|B1'>
C    |B1'> = |B1>-A12|X2>
C
C CHI2 = R2SUM - 2*<B2|X2> + <X2|A22|X2>
C              -<X2|A21 inv(A11) A12 |X2> - <B1|inv(A11)|B1>
C              +2 * <B1|inv(A11) A12|X2>
C
C If we write:
C  RNEW = R2SUM - <B1|inv(A11)|B1>
C  |BNEW> =(|B2> - A21 inv(A11) |B1> )
C  ANEW = A22 - A21 inv(A11) A12
C  remember that on entry to SOLVE2 the vector b
C  actually contains inv(A11)|B1>
C  a is inv(A11)
C  and that A21 is the transpose of A12
C
C  CHI2 then = RNEW + <X2|ANEW|X2> - 2<BNEW|X2>
C
C  |X1> =	    inv(A11)|B1> -inv(A11)A12|X2>
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
C If it is negative, only the parameters will be solved for.
C
C---------------------------------------------------------------------------
C
C   THE ROUTINES WORK IF ALL FREE = 1 OR ALL FREE = 0
C
CD     WRITE(6,444)
CD 444 FORMAT(' IN SOLVE3')
C  SKIP PARAMETER ESTIMATE
      IF(IFAST.GT.0) GO TO 1000
C
C  DO PARAMETER ESTIMATE
C
C  |X1> =    inv(A11)|B1> -inv(A11)A12|X2>
C
C**CALCULATE START OF A12 ARRAY
      NB12=NLIVE*(NLIVE+1)/2 + NDED*(NDED+1)/2
      ILIVE=0
      DO 200 I=1,ntpart
         IF(FREE(I).EQ.0) GO TO 200
         ILIVE=ILIVE+1
         X(I)=b(ILIVE)
         JL=0
C
         DO 150 J=1,ntpart
            IF(FREE(J).EQ.0) GO TO 150
            JL=JL+1
            DTEMP=0.0D0
            KD=0
            DO 140 K=1,ntpart
               IF(FREE(K).NE.0) GO TO 140
               KD=KD+1
               INDX=NB12+NLIVE*(KD-1)+JL
               DTEMP=DTEMP+a(INDX)*X(K)
140         CONTINUE
            X(I)=X(I)-a(IPOS(ILIVE,JL))*DTEMP
150      CONTINUE
200   CONTINUE
C
C---------------------------------------------------------
      IF(IFAST.LT.0) RETURN
1000  CONTINUE
C
C CALCULATE CHI2
C CHI2 = RNEW + <X2|ANEW|X2> - 2<BNEW|X2>
C
      CHI2=RNEW
C
      IANEW=NLIVE*(NLIVE+1)/2
C
      IX1=0
      DTEMP1=0.0D0
      SM=1.D-30
C
      DO 1100 I=1,ntpart
         IF(FREE(I).NE.0) GO TO 1100
         IX1=IX1+1
         IF(DABS(X(I)).LT.SM) GO TO 1100
         DTEMP1=DTEMP1+X(I)*b(NLIVE+IX1)
         IX2=0
C
         DO 1050 J=1,I
            IF(FREE(J).NE.0) GO TO 1050
            IX2=IX2+1
            IF(DABS(X(J)).LT.SM) GO TO 1050
            IND=IX2+IX1*(IX1-1)/2+IANEW
            DTEMP=X(I)*a(IND)*X(J)
            IF(J.LT.I) DTEMP=DTEMP+DTEMP
            CHI2=CHI2+DTEMP
1050     CONTINUE
1100  CONTINUE
C
      CHI2=CHI2-2.D0*DTEMP1
C
      RETURN
      END
