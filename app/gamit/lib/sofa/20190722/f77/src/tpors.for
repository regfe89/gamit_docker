      SUBROUTINE iau_TPORS ( XI, ETA, A, B, A01, B01, A02, B02, N )
*
*  - - - - - - - - - -
*   i a u _ T P O R S
*  - - - - - - - - - -
*
*  In the tangent plane projection, given the rectangular coordinates
*  of a star and its spherical coordinates, determine the spherical
*  coordinates of the tangent point.
*
*  This routine is part of the International Astronomical Union's
*  SOFA (Standards of Fundamental Astronomy) software collection.
*
*  Status:  support routine.
*
*  Given:
*     XI,ETA    d       rectangular coordinates of star image (Note 2)
*     A,B       d       star's spherical coordinates (Note 3)
*
*  Returned:
*     A01,B01   d       tangent point's spherical coordinates, Soln. 1
*     A02,B02   d       tangent point's spherical coordinates, Soln. 2
*     N         i       number of solutions:
*                         0 = no solutions returned (Note 5)
*                         1 = only the first solution is useful (Note 6)
*                         2 = both solutions are useful (Note 6)
*
*  Notes:
*
*  1) The tangent plane projection is also called the "gnomonic
*     projection" and the "central projection".
*
*  2) The eta axis points due north in the adopted coordinate system.
*     If the spherical coordinates are observed (RA,Dec), the tangent
*     plane coordinates (xi,eta) are conventionally called the "standard
*     coordinates".  If the spherical coordinates are with respect to a
*     right-handed triad, (xi,eta) are also right-handed.  The units of
*     (xi,eta) are, effectively, radians at the tangent point.
*
*  3) All angular arguments are in radians.
*
*  4) The angles A01 and A02 are returned in the range 0-2pi.  The
*     angles B01 and B02 are returned in the range +/-pi, but in the
*     usual, non-pole-crossing, case, the range is +/-pi/2.
*
*  5) Cases where there is no solution can arise only near the poles.
*     For example, it is clearly impossible for a star at the pole
*     itself to have a non-zero xi value, and hence it is meaningless
*     to ask where the tangent point would have to be to bring about
*     this combination of xi and dec.
*
*  6) Also near the poles, cases can arise where there are two useful
*     solutions.  The returned value N indicates whether the second of
*     the two solutions returned is useful;  N=1 indicates only one
*     useful solution, the usual case.
*
*  7) The basis of the algorithm is to solve the spherical triangle PSC,
*     where P is the north celestial pole, S is the star and C is the
*     tangent point.  The spherical coordinates of the tangent point are
*     [a0,b0];  writing rho^2 = (xi^2+eta^2) and r^2 = (1+rho^2), side c
*     is then (pi/2-b), side p is sqrt(xi^2+eta^2) and side s (to be
*     found) is (pi/2-b0).  Angle C is given by sin(C) = xi/rho and
*     cos(C) = eta/rho.  Angle P (to be found) is the longitude
*     difference between star and tangent point (a-a0).
*
*  8) This routine is a member of the following set:
*
*         spherical       vector       solve for
*
*         iau_TPXES      iau_TPXEV      xi,eta
*         iau_TPSTS      iau_TPSTV       star
*       > iau_TPORS <    iau_TPORV      origin
*
*  Called:
*     iau_ANP      normalize angle into range 0 to 2pi
*
*  References:
*
*     Calabretta M.R. & Greisen, E.W., 2002, "Representations of
*     celestial coordinates in FITS", Astron.Astrophys. 395, 1077
*
*     Green, R.M., "Spherical Astronomy", Cambridge University Press,
*     1987, Chapter 13.
*
*  This revision:   2018 January 2
*
*  SOFA release 2019-07-22
*
*  Copyright (C) 2019 IAU SOFA Board.  See notes at end.
*
*-----------------------------------------------------------------------

      IMPLICIT NONE

      DOUBLE PRECISION XI, ETA, A, B, A01, B01, A02, B02
      INTEGER N

      DOUBLE PRECISION XI2, R, SB, CB, RSB, RCB, W2, W, S, C

      DOUBLE PRECISION iau_ANP

* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      XI2 = XI*XI
      R = SQRT(1D0+XI2+ETA*ETA)
      SB = SIN(B)
      CB = COS(B)
      RSB = R*SB
      RCB = R*CB
      W2 = RCB*RCB - XI2
      IF ( W2 .GE. 0D0 ) THEN
         W = SQRT(W2)
         S = RSB - ETA*W
         C = RSB*ETA + W
         IF ( XI .EQ. 0D0 .AND. W .EQ. 0D0 ) W = 1D0
         A01 = iau_ANP(A - ATAN2(XI,W))
         B01 = ATAN2(S,C)
         W = -W
         S = RSB - ETA*W
         C = RSB*ETA + W
         A02 = iau_ANP(A - ATAN2(XI,W))
         B02 = ATAN2(S,C)
         IF ( ABS(RSB) .LT. 1D0 ) THEN
            N = 1
         ELSE
            N = 2
         END IF
      ELSE
         N = 0
      END IF

*  Finished.

*+----------------------------------------------------------------------
*
*  Copyright (C) 2019
*  Standards Of Fundamental Astronomy Board
*  of the International Astronomical Union.
*
*  =====================
*  SOFA Software License
*  =====================
*
*  NOTICE TO USER:
*
*  BY USING THIS SOFTWARE YOU ACCEPT THE FOLLOWING SIX TERMS AND
*  CONDITIONS WHICH APPLY TO ITS USE.
*
*  1. The Software is owned by the IAU SOFA Board ("SOFA").
*
*  2. Permission is granted to anyone to use the SOFA software for any
*     purpose, including commercial applications, free of charge and
*     without payment of royalties, subject to the conditions and
*     restrictions listed below.
*
*  3. You (the user) may copy and distribute SOFA source code to others,
*     and use and adapt its code and algorithms in your own software,
*     on a world-wide, royalty-free basis.  That portion of your
*     distribution that does not consist of intact and unchanged copies
*     of SOFA source code files is a "derived work" that must comply
*     with the following requirements:
*
*     a) Your work shall be marked or carry a statement that it
*        (i) uses routines and computations derived by you from
*        software provided by SOFA under license to you; and
*        (ii) does not itself constitute software provided by and/or
*        endorsed by SOFA.
*
*     b) The source code of your derived work must contain descriptions
*        of how the derived work is based upon, contains and/or differs
*        from the original SOFA software.
*
*     c) The names of all routines in your derived work shall not
*        include the prefix "iau" or "sofa" or trivial modifications
*        thereof such as changes of case.
*
*     d) The origin of the SOFA components of your derived work must
*        not be misrepresented;  you must not claim that you wrote the
*        original software, nor file a patent application for SOFA
*        software or algorithms embedded in the SOFA software.
*
*     e) These requirements must be reproduced intact in any source
*        distribution and shall apply to anyone to whom you have
*        granted a further right to modify the source code of your
*        derived work.
*
*     Note that, as originally distributed, the SOFA software is
*     intended to be a definitive implementation of the IAU standards,
*     and consequently third-party modifications are discouraged.  All
*     variations, no matter how minor, must be explicitly marked as
*     such, as explained above.
*
*  4. You shall not cause the SOFA software to be brought into
*     disrepute, either by misuse, or use for inappropriate tasks, or
*     by inappropriate modification.
*
*  5. The SOFA software is provided "as is" and SOFA makes no warranty
*     as to its use or performance.   SOFA does not and cannot warrant
*     the performance or results which the user may obtain by using the
*     SOFA software.  SOFA makes no warranties, express or implied, as
*     to non-infringement of third party rights, merchantability, or
*     fitness for any particular purpose.  In no event will SOFA be
*     liable to the user for any consequential, incidental, or special
*     damages, including any lost profits or lost savings, even if a
*     SOFA representative has been advised of such damages, or for any
*     claim by any third party.
*
*  6. The provision of any version of the SOFA software under the terms
*     and conditions specified herein does not imply that future
*     versions will also be made available under the same terms and
*     conditions.
*
*  In any published work or commercial product which uses the SOFA
*  software directly, acknowledgement (see www.iausofa.org) is
*  appreciated.
*
*  Correspondence concerning SOFA software should be addressed as
*  follows:
*
*      By email:  sofa@ukho.gov.uk
*      By post:   IAU SOFA Center
*                 HM Nautical Almanac Office
*                 UK Hydrographic Office
*                 Admiralty Way, Taunton
*                 Somerset, TA1 2DN
*                 United Kingdom
*
*-----------------------------------------------------------------------

      END
