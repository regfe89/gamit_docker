Copyright (c) Massachusetts Institute of Technology,1986. All rights reserved.
      SUBROUTINE SPHXYZ(ALAT,ALONG,RADIUS,X,Y,Z,IFLAG)
C
C     IFLAG=1: CONVERTS GEOCENTRIC COORDINATES TO CARTESIAN COORDINATES
C     IFLAG=2: CONVERTS CARTESIAN CCORDINATES TO GEOCENTRIC COORDINATES

      implicit none
                                                                      
      integer*4 iflag

      real*8 twopi,alat,along,radius,x,y,z,sinlat,coslat,sinlon,coslon
     .     , sqr

      TWOPI=8.D0*DATAN(1.D0)
      IF(IFLAG.EQ.2) GO TO 10
      SINLAT=DSIN(ALAT)
      COSLAT=DCOS(ALAT)
      SINLON=DSIN(ALONG)
      COSLON=DCOS(ALONG)
C
      X=RADIUS*COSLAT*COSLON
      Y=RADIUS*COSLAT*SINLON
      Z=RADIUS*SINLAT
      GO TO 20
C
   10 CONTINUE
      ALONG=DATAN2(Y,X)
      IF(ALONG.LT.0.D0) ALONG=ALONG+TWOPI
      SQR=DSQRT(X*X+Y*Y)
      ALAT=DATAN2(Z,SQR)
      RADIUS=DSQRT(X*X+Y*Y+Z*Z)
   20 CONTINUE
C
      RETURN
      END
