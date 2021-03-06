      SUBROUTINE iau_FK524 ( R2000, D2000,
     :                       DR2000, DD2000, P2000, V2000,
     :                       R1950, D1950,
     :                       DR1950, DD1950, P1950, V1950 )
*+
*  - - - - - - - - - -
*   i a u _ F K 5 2 4
*  - - - - - - - - - -
*
*  Convert J2000.0 FK5 star catalog data to B1950.0 FK4.
*
*  This routine is part of the International Astronomical Union's
*  SOFA (Standards of Fundamental Astronomy) software collection.
*
*  Status:  support routine.
*
*  Given:  (all J2000.0, FK5)
*     R2000,D2000      d     J2000.0 RA,Dec (rad)
*     DR2000,DD2000    d     J2000.0 proper motions (rad/Jul.yr)
*     P2000            d     parallax (arcsec)
*     V2000            d     radial velocity (km/s, +ve = moving away)
*
*  Returned:  (all B1950.0, FK4)
*     R1950,D1950      d     B1950.0 RA,Dec (rad)
*     DR1950,DD1950    d     B1950.0 proper motions (rad/trop.yr)
*     P1950            d     parallax (arcsec)
*     V1950            d     radial velocity (km/s, +ve = moving away)
*
*  Notes:
*
*  1) The proper motions in RA are dRA/dt rather than cos(Dec)*dRA/dt,
*     and are per year rather than per century.
*
*  2) The conversion is somewhat complicated, for several reasons:
*
*     . Change of standard epoch from J2000.0 to B1950.0.
*
*     . An intermediate transition date of 1984 January 1.0 TT.
*
*     . A change of precession model.
*
*     . Change of time unit for proper motion (Julian to tropical).
*
*     . FK4 positions include the E-terms of aberration, to simplify the
*       hand computation of annual aberration.  FK5 positions assume a
*       rigorous aberration computation based on the Earth's barycentric
*       velocity.
*
*     . The E-terms also affect proper motions, and in particular cause
*       objects at large distances to exhibit fictitious proper motions.
*
*     The algorithm is based on Smith et al. (1989) and Yallop et al.
*     (1989), which presented a matrix method due to Standish (1982) as
*     developed by Aoki et al. (1983), using Kinoshita's development of
*     Andoyer's post-Newcomb precession.  The numerical constants from
*     Seidelmann (1992) are used canonically.
*
*  4) In the FK4 catalog the proper motions of stars within 10 degrees
*     of the poles do not embody differential E-terms effects and
*     should, strictly speaking, be handled in a different manner from
*     stars outside these regions.  However, given the general lack of
*     homogeneity of the star data available for routine astrometry, the
*     difficulties of handling positions that may have been determined
*     from astrometric fields spanning the polar and non-polar regions,
*     the likelihood that the differential E-terms effect was not taken
*     into account when allowing for proper motion in past astrometry,
*     and the undesirability of a discontinuity in the algorithm, the
*     decision has been made in this SOFA algorithm to include the
*     effects of differential E-terms on the proper motions for all
*     stars, whether polar or not.  At epoch J2000.0, and measuring "on
*     the sky" rather than in terms of RA change, the errors resulting
*     from this simplification are less than 1 milliarcsecond in
*     position and 1 milliarcsecond per century in proper motion.
*
*  Called:
*     iau_ANP      normalize angle into range 0 to 2pi
*     iau_PDP      scalar product of two p-vectors
*     iau_PM       modulus of p-vector
*     iau_PMP      p-vector minus p-vector
*     iau_PPP      p-vector pluus p-vector
*     iau_PV2S     pv-vector to spherical coordinates
*     iau_S2PV     spherical coordinates to pv-vector
*     iau_SXP      multiply p-vector by scalar
*
*  References:
*
*     Aoki, S. et al., 1983, "Conversion matrix of epoch B1950.0
*     FK4-based positions of stars to epoch J2000.0 positions in
*     accordance with the new IAU resolutions".  Astron.Astrophys.
*     128, 263-267.
*
*     Seidelmann, P.K. (ed), 1992, "Explanatory Supplement to the
*     Astronomical Almanac", ISBN 0-935702-68-7.
*
*     Smith, C.A. et al., 1989, "The transformation of astrometric
*     catalog systems to the equinox J2000.0".  Astron.J. 97, 265.
*
*     Standish, E.M., 1982, "Conversion of positions and proper motions
*     from B1950.0 to the IAU system at J2000.0".  Astron.Astrophys.,
*     115, 1, 20-22.
*
*     Yallop, B.D. et al., 1989, "Transformation of mean star places
*     from FK4 B1950.0 to FK5 J2000.0 using matrices in 6-space".
*     Astron.J. 97, 274.
*
*  This revision:   2018 January 11
*
*  SOFA release 2019-07-22
*
*  Copyright (C) 2019 IAU SOFA Board.  See notes at end.
*
*-----------------------------------------------------------------------

      IMPLICIT NONE

      DOUBLE PRECISION R2000, D2000, DR2000, DD2000, P2000, V2000,
     :                 R1950, D1950, DR1950, DD1950, P1950, V1950

*  2Pi
      DOUBLE PRECISION D2PI
      PARAMETER ( D2PI = 6.283185307179586476925287D0 )

*  Radians per year to arcsec per century
      DOUBLE PRECISION PMF
      PARAMETER ( PMF = 100D0*60D0*60D0*360D0/D2PI )

*  Small number to avoid arithmetic problems
      DOUBLE PRECISION TINY
      PARAMETER ( TINY = 1D-30 )

*  Miscellaneous
      DOUBLE PRECISION R, D, UR, UD, PX, RV, PXVF, W, WR, RD
      INTEGER L, K, J, I

*  Vectors, p and pv
      DOUBLE PRECISION R0(3,2), R1(3,2), P1(3), P2(3), P3(3), PV(3,2)

*  Functions
      DOUBLE PRECISION iau_ANP

*
*  CANONICAL CONSTANTS  (Seidelmann 1992)
*

*  Km per sec to AU per tropical century
*  = 86400 * 36524.2198782 / 149597870
      DOUBLE PRECISION VF
      PARAMETER ( VF = 21.095D0 )

*  Constant pv-vector (cf. Seidelmann 3.591-2, vectors A and Adot)
      DOUBLE PRECISION A(3,2)
      DATA A/ -1.62557D-6,  -0.31919D-6, -0.13843D-6,
     :        +1.245D-3,    -1.580D-3,   -0.659D-3 /

*  3x2 matrix of pv-vectors (cf. Seidelmann 3.592-1, matrix M^-1)
      DOUBLE PRECISION EMI(3,2,3,2)
      DATA EMI /
     :   +0.9999256795D0,     +0.0111814828D0,     +0.0048590039D0,
     :   -0.00000242389840D0, -0.00000002710544D0, -0.00000001177742D0,
     :
     :   -0.0111814828D0,     +0.9999374849D0,     -0.0000271771D0,
     :   +0.00000002710544D0, -0.00000242392702D0, +0.00000000006585D0,
     :
     :   -0.0048590040D0,     -0.0000271557D0,     +0.9999881946D0,
     :   +0.00000001177742D0, +0.00000000006585D0, -0.00000242404995D0,
     :
     :   -0.000551D0,         +0.238509D0,         -0.435614D0,
     :   +0.99990432D0,       +0.01118145D0,       +0.00485852D0,
     :
     :   -0.238560D0,         -0.002667D0,         +0.012254D0,
     :   -0.01118145D0,       +0.99991613D0,       -0.00002717D0,
     :
     :   +0.435730D0,         -0.008541D0,         +0.002117D0,
     :   -0.00485852D0,       -0.00002716D0,       +0.99996684D0
     :        /

* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

*  The FK5 data (units radians and arcsec per Julian century).
      R = R2000
      D = D2000
      UR = DR2000*PMF
      UD = DD2000*PMF
      PX = P2000
      RV = V2000

*  Express as a pv-vector.
      PXVF = PX*VF
      W = RV*PXVF
      CALL iau_S2PV ( R, D, 1D0, UR, UD, W, R0 )

*  Convert pv-vector to Bessel-Newcomb system (cf. Seidelmann 3.592-1).
      DO 4 L = 1,2
         DO 3 K=1,3
            W = 0D0
            DO 2 J=1,2
               DO 1 I=1,3
                  W = W + EMI(I,J,K,L)*R0(I,J)
 1             CONTINUE
 2          CONTINUE
            R1(K,L) = W
 3       CONTINUE
 4    CONTINUE

*  Apply E-terms (equivalent to Seidelmann 3.592-3, two iterations).

*  Direction.
      CALL iau_PM ( R1, WR )
      CALL iau_PDP ( R1, A, W )
      CALL iau_SXP ( W, R1, P1 )
      CALL iau_SXP ( WR, A, P2 )
      CALL iau_PMP ( P2, P1, P3 )
      CALL iau_PPP ( R1, P3, P1 )

*  Recompute length.
      CALL iau_PM ( P1, WR )

*  Direction.
      CALL iau_PDP ( R1, A, W )
      CALL iau_SXP ( W, R1, P1 )
      CALL iau_SXP ( WR, A, P2 )
      CALL iau_PMP ( P2, P1, P3 )
      CALL iau_PPP ( R1, P3, PV )

*  Derivative.
      CALL iau_PDP ( R1, A(1,2), W )
      CALL iau_SXP ( W, PV, P1 )
      CALL iau_SXP ( WR, A(1,2), P2 )
      CALL iau_PMP ( P2, P1, P3 )
      CALL iau_PPP ( R1(1,2), P3, PV(1,2) )

*  Revert to catalog form.
      CALL iau_PV2S ( PV, R, D, W, UR, UD, RD )
      IF ( PX.GT.TINY ) THEN
         RV = RD/PXVF
         PX = PX/W
      END IF

*  Return the results.
      R1950 = iau_ANP(R)
      D1950 = D
      DR1950 = UR/PMF
      DD1950 = UD/PMF
      P1950 = PX
      V1950 = RV

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
