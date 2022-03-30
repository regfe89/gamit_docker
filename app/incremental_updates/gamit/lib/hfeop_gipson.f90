module hfeop_gipson
! Hold tidal information.
!  Maximum tides is 200.
!  So far the model with the largest is JPL which has ~160
! History
! 2017Nov22 JMGipson. Original version
! 2019Oct09 Two bugs found and fixed by Michael Gerstl. Rotines hfcalc_gmst and hfcalc_nut_arg.
!           Effect is ~1.0 uas in PM, ~0.01 us in UT1
! 2020May09 Modified to specificially implement the Gipson VLBI model (see below). Removed the
!           file reading code.  Derived from https://ivscc.gsfc.nasa.gov/hfeop_wg/software/hfeop_xyu_mod.f
!           Changed num/max_tide to num/max_gips to avoid conflict with hfeop_deasi.  
!           Data file from: (Libration terms in UT1 and Polar motion included in apriori and so
!           as with the Desai and Sibios model need to be applied in GAMIT.          
!           https://ivscc.gsfc.nasa.gov/hfeop_wg/models/2017a_astro_lib_xyu.txt
!           Gipson, J and L. Hesslow. A new model of HF-EOP variation derived from 35 years of VLBI. 
!              Geophys. Res. Abstracts, 17, 2015. EGU2015-14756.
      
! Data statement created from 2017a_astro_lib_xyu.txt
! 
      integer , parameter :: max_gips=70 
      integer num_gips             ! number we find  
      integer*2 itide_arg(6,max_gips)    ! tidal arguments. GST+pi followed by nutation. 
      character*8 ctide(max_gips) 
      character*8 cdoodson(max_gips)    
      real*8 tide_period(max_gips)       ! period 
      real*8 tide_coef(2,4,max_gips)     ! Coefficients of model in order: (sin,cosine)x(X,Y,UT1,LOD)x Max_tide  
! 
      data num_gips / 70 /  
! 
      data (ctide(mi),(itide_arg(mj,mi),mj=1,6),cdoodson(mi), tide_period(mi), ((tide_coef(mj,mk,mi),mj=1,2),mk=1,4),mi=1,70) / &
      "-       ",  1, -1,  0, -2, -2, -2, "117.655", 1.2113600,   0.28,   1.27,  -1.27,   0.28,   0.18,  -0.17,  -0.88,  -0.93, &
      "-       ",  1, -2,  0, -2,  0, -1, "125.745", 1.1671300,   0.83,   2.04,  -2.04,   0.83,   0.36,  -0.17,  -0.92,  -1.94, &
      "2Q1     ",  1, -2,  0, -2,  0, -2, "125.755", 1.1669300,  -0.08,   6.16,  -6.16,  -0.08,   1.02,  -0.02,  -0.11,  -5.49, &
      "-       ",  1,  0,  0, -2, -2, -1, "127.545", 1.1605500,  -0.61,  -0.71,   0.71,  -0.61,   0.01,  -0.21,  -1.14,  -0.05, &
      "Sigma1  ",  1,  0,  0, -2, -2, -2, "127.555", 1.1603500,  -1.76,   3.34,  -3.34,  -1.76,   1.09,  -0.10,  -0.54,  -5.90, &
      "-       ",  1, -1,  0, -2,  0, -1, "135.645", 1.1197000,   2.46,   3.04,  -3.04,   2.46,   0.90,  -0.44,  -2.47,  -5.05, &
      "Q1      ",  1, -1,  0, -2,  0, -2, "135.655", 1.1195100,   7.74,  30.19, -30.19,   7.74,   5.05,  -2.68, -15.04, -28.34, &
      "-       ",  1,  1,  0, -2, -2, -1, "137.445", 1.1136400,   0.58,  -0.07,   0.07,   0.58,   0.05,  -0.09,  -0.51,  -0.28, &
      "Rho1    ",  1,  1,  0, -2, -2, -2, "137.455", 1.1134600,   1.78,   2.89,  -2.89,   1.78,   0.94,  -0.55,  -3.10,  -5.30, &
      "-       ",  1,  0,  0, -2,  0,  0, "145.535", 1.0761500,   3.21,  -2.41,   2.41,   3.21,   0.02,   0.14,   0.82,  -0.12, &
      "-       ",  1,  0,  0, -2,  0, -1, "145.545", 1.0759800,  11.23,  24.87, -24.87,  11.23,   3.32,  -2.65, -15.47, -19.39, &
      "O1      ",  1,  0,  0, -2,  0, -2, "145.555", 1.0758100,  57.57, 134.33,-134.33,  57.57,  17.42, -13.17, -76.92,-101.74, &
      "-       ",  1, -2,  0,  0,  0,  0, "145.755", 1.0750900,  -3.04,   0.64,  -0.64,  -3.04,  -0.07,   0.01,   0.06,   0.41, &
      "Tau1    ",  1,  0,  0,  0, -2,  0, "147.555", 1.0695100,  -3.00,  -0.13,   0.13,  -3.00,  -0.08,   0.02,   0.12,   0.47, &
      "-       ",  1, -1,  0, -2,  2, -2, "153.655", 1.0406100,  -0.46,  -0.76,   0.76,  -0.46,  -0.03,   0.06,   0.36,   0.18, &
      "-       ",  1,  1,  0, -2,  0, -1, "155.445", 1.0355400,   2.49,  -3.76,   3.76,   2.49,   0.01,   0.08,   0.49,  -0.06, &
      "-       ",  1,  1,  0, -2,  0, -2, "155.455", 1.0353800,   0.79,  -0.53,   0.53,   0.79,  -0.56,   0.28,   1.70,   3.40, &
      "M1      ",  1, -1,  0,  0,  0,  0, "155.655", 1.0347200,  -6.86, -10.14,  10.14,  -6.86,  -0.98,   0.48,   2.91,   5.95, &
      "-       ",  1, -1,  0,  0,  0, -1, "155.665", 1.0345600,  -0.21,  -1.45,   1.45,  -0.21,  -0.23,   0.11,   0.67,   1.40, &
      "Chi1    ",  1,  1,  0,  0, -2,  0, "157.455", 1.0295400,  -3.29,  -3.30,   3.30,  -3.29,  -0.03,   0.00,   0.00,   0.18, &
      "Pi1     ",  1,  0, -1, -2,  2, -2, "162.556", 1.0055100,   4.07,  -2.68,   2.68,   4.07,   0.40,  -0.19,  -1.19,  -2.50, &
      "-       ",  1,  0,  0, -2,  2, -1, "163.545", 1.0028900,  -0.08,  -1.56,   1.56,  -0.08,  -0.03,   0.02,   0.13,   0.19, &
      "P1      ",  1,  0,  0, -2,  2, -2, "163.555", 1.0027500,  29.03,  47.40, -47.40,  29.03,   5.47,  -3.45, -21.62, -34.27, &
      "S1      ",  1,  0, -1,  0,  0,  0, "164.556", 1.0000000,   8.43,   3.93,  -3.93,   8.43,  -1.10,  -0.09,  -0.57,   6.91, &
      "-       ",  1,  0,  0,  0,  0,  1, "165.545", 0.9974200,  -0.81,   6.37,  -6.37,  -0.81,   0.45,  -0.42,  -2.65,  -2.83, &
      "K1      ",  1,  0,  0,  0,  0,  0, "165.555", 0.9972700,-101.38,-154.13, 154.13,-101.38, -17.16,   9.07,  57.14, 108.11, &
      "-       ",  1,  0,  0,  0,  0, -1, "165.565", 0.9971200,  -9.14, -21.37,  21.37,  -9.14,  -1.84,   1.12,   7.06,  11.59, &
      "-       ",  1,  0,  0,  0,  0, -2, "165.575", 0.9969800,   7.88,  -6.61,   6.61,   7.88,  -0.16,   0.06,   0.38,   1.01, &
      "Psi1    ",  1,  0,  1,  0,  0,  0, "166.554", 0.9945500,  -0.07,  -3.29,   3.29,  -0.07,  -0.06,   0.14,   0.88,   0.38, &
      "Phi1    ",  1,  0,  0,  2, -2,  2, "167.555", 0.9918500,   2.70,  -3.88,   3.88,   2.70,  -0.08,   0.04,   0.25,   0.51, &
      "Theta1  ",  1, -1,  0,  0,  2,  0, "173.655", 0.9669600,   1.11,  -1.73,   1.73,   1.11,  -0.04,   0.00,   0.00,   0.26, &
      "J1      ",  1,  1,  0,  0,  0,  0, "175.455", 0.9624400,  -5.53,  -7.25,   7.25,  -5.53,  -1.03,   0.58,   3.79,   6.72, &
      "-       ",  1,  1,  0,  0,  0, -1, "175.465", 0.9623000,  -0.96,  -0.33,   0.33,  -0.96,  -0.28,  -0.03,  -0.20,   1.83, &
      "SO1     ",  1,  0,  0,  0,  2,  0, "183.555", 0.9341700,  -2.63,   0.30,  -0.30,  -2.63,  -0.21,   0.28,   1.88,   1.41, &
      "-       ",  1,  2,  0,  0,  0,  0, "185.355", 0.9299500,  -0.76,   1.33,  -1.33,  -0.76,  -0.27,   0.02,   0.14,   1.82, &
      "OO1     ",  1,  0,  0,  2,  0,  2, "185.555", 0.9294200,  -5.06,  -5.62,   5.62,  -5.06,  -0.59,   0.64,   4.33,   3.99, &
      "-       ",  1,  0,  0,  2,  0,  1, "185.565", 0.9292900,  -2.11,  -0.97,   0.97,  -2.11,  -0.54,   0.35,   2.37,   3.65, &
      "-       ",  1,  0,  0,  2,  0,  0, "185.575", 0.9291700,   0.60,  -1.81,   1.81,   0.60,  -0.09,   0.07,   0.47,   0.61, &
      "Upsilon1",  1,  1,  0,  2,  0,  2, "195.455", 0.8990900,  -3.38,   0.94,  -0.94,  -3.38,  -0.00,  -0.07,  -0.49,   0.00, &
      "-       ",  1,  1,  0,  2,  0,  1, "195.465", 0.8989700,  -2.55,   1.20,  -1.20,  -2.55,   0.10,   0.04,   0.28,  -0.70, &
      "-       ",  2, -3,  0, -2,  0, -2, "225.855", 0.5484300,  -4.00,  -1.24,  -1.60,   5.46,  -0.04,   0.00,   0.00,   0.46, &
      "Epsilon2",  2, -1,  0, -2, -2, -2, "227.655", 0.5469700,  -3.51,  -2.43,   0.05,   3.41,  -0.02,  -0.14,  -1.61,   0.23, &
      "2N2     ",  2, -2,  0, -2,  0, -2, "235.755", 0.5377200,  -7.84,  -1.39,   3.07,   3.64,  -0.87,  -0.46,  -5.37,  10.17, &
      "Mu2     ",  2,  0,  0, -2, -2, -2, "237.555", 0.5363200, -13.08,  -3.71,  -2.21,   7.66,  -0.73,  -0.65,  -7.61,   8.55, &
      "-       ",  2,  0,  1, -2, -2, -2, "238.554", 0.5355400,  -4.69,   1.53,   2.27,   5.55,  -0.00,   0.05,   0.59,   0.00, &
      "-       ",  2, -1, -1, -2,  0, -2, "244.656", 0.5281900,   1.92,  -1.51,  -0.57,  -1.24,   0.11,  -0.16,  -1.90,  -1.31, &
      "-       ",  2, -1,  0, -2,  0, -1, "245.645", 0.5274700,   1.78,   2.48,   2.66,  -0.72,   0.14,  -0.05,  -0.60,  -1.67, &
      "N2      ",  2, -1,  0, -2,  0, -2, "245.655", 0.5274300, -53.17,  -7.90,  12.08,  29.07,  -3.75,  -1.71, -20.37,  44.67, &
      "-       ",  2, -1,  1, -2,  0, -2, "246.654", 0.5266700,   0.54,   0.42,  -2.82,   0.72,  -0.14,  -0.14,  -1.67,   1.67, &
      "Nu2     ",  2,  1,  0, -2, -2, -2, "247.455", 0.5260800,  -8.02,  -2.36,   1.56,   6.62,  -0.66,  -0.34,  -4.06,   7.88, &
      "-       ",  2,  1,  1, -2, -2, -2, "248.454", 0.5253300,  -3.25,   1.73,  -1.23,   0.19,  -0.04,  -0.05,  -0.60,   0.48, &
      "-       ",  2, -2,  0, -2,  2, -2, "253.755", 0.5188300,   2.79,   0.19,   1.89,  -3.43,  -0.09,   0.03,   0.36,   1.09, &
      "-       ",  2,  0, -1, -2,  0, -2, "254.556", 0.5182600,  -0.94,   2.01,   3.49,  -1.86,   0.07,  -0.19,  -2.30,  -0.85, &
      "-       ",  2,  0,  0, -2,  0, -1, "255.545", 0.5175600,  10.68,   2.47,  -6.79,  -8.32,   0.69,   0.29,   3.52,  -8.38, &
      "M2      ",  2,  0,  0, -2,  0, -2, "255.555", 0.5175300,-326.70, -15.62,  49.66, 186.98, -16.61,  -8.52,-103.44, 201.66, &
      "-       ",  2,  0,  1, -2,  0, -2, "256.554", 0.5167900,  -2.46,  -0.49,  -3.37,  -0.14,  -0.01,   0.03,   0.36,   0.12, &
      "Lambda2 ",  2, -1,  0, -2,  2, -2, "263.655", 0.5092400,  -0.89,  -0.62,   1.96,  -1.03,   0.12,   0.07,   0.86,  -1.48, &
      "L2      ",  2,  1,  0, -2,  0, -2, "265.455", 0.5079800,   8.23,   1.46,   1.80,  -1.13,   0.37,   0.35,   4.33,  -4.58, &
      "-       ",  2, -1,  0,  0,  0,  0, "265.655", 0.5078200,  -5.81,   4.25,   2.61,   2.25,   0.08,  -0.20,  -2.47,  -0.99, &
      "-       ",  2, -1,  0,  0,  0, -1, "265.665", 0.5077900,  -0.66,   0.95,   1.03,   1.60,  -0.10,   0.12,   1.48,   1.24, &
      "T2      ",  2,  0, -1, -2,  2, -2, "272.556", 0.5006900,  -6.80,   2.96,   3.86,   2.36,  -0.56,  -0.18,  -2.26,   7.03, &
      "S2      ",  2,  0,  0, -2,  2, -2, "273.555", 0.5000000,-138.99,  74.31,  73.81,  90.71,  -8.27,   0.00,   0.00, 103.92, &
      "R2      ",  2,  0,  1, -2,  2, -2, "274.554", 0.4993200,   0.64,   0.60,   0.28,  -1.32,   0.16,   0.02,   0.25,  -2.01, &
      "-       ",  2,  0,  0,  0,  0,  1, "275.545", 0.4986700,   3.24,   2.06, -12.44,  -3.22,  -0.61,   0.38,   4.79,   7.69, &
      "K2      ",  2,  0,  0,  0,  0,  0, "275.555", 0.4986300, -37.46,  12.86,  13.10,  14.34,  -2.50,   0.10,   1.26,  31.50, &
      "-       ",  2,  0,  0,  0,  0, -1, "275.565", 0.4986000, -10.60,   0.63,   5.33,   9.54,  -0.83,   0.17,   2.14,  10.46, &
      "-       ",  2,  0,  0,  0,  0, -2, "275.575", 0.4985600,  -2.16,  -0.29,   3.77,   4.80,  -0.51,  -0.01,  -0.13,   6.43, &
      "Eta2    ",  2,  1,  0,  0,  0,  0, "285.455", 0.4897700,   0.02,   1.49,   1.03,   1.00,  -0.08,   0.02,   0.26,   1.03, &
      "-       ",  2,  1,  0,  0,  0, -1, "285.465", 0.4897400,   2.08,  -1.54,  -2.10,   1.22,  -0.07,   0.08,   1.03,   0.90, &
      "-       ",  2,  0,  0,  2,  0,  2, "295.555", 0.4810700,  -2.40,   1.28,   0.78,  -1.18,   0.05,   0.04,   0.52,  -0.65  /
! 
 


Contains
!***********************************************************************************
      SUBROUTINE calc_hf_gip_xyu(RMJD_TT,Delta_T,EOP)   
      IMPLICIT NONE                           
!     Routine to compute diurnal and semi-diurnal HF-EOP when model is in IERS format.
!     
! Passed. 
       real*8 RMJD_TT     !modified julian day TT 
       real*8 Delta_T     !TT-RMJD
 
! returned
      real*8    EOP(4,2)     !X,Y, UT1, LOD and their derivatives        
! Function      
 
! Local                        
      integer   itide     !loop counter over tides.
      integer   jeop  !loop counter over EOP
 
! arg,argd -- argument, argument_dot.
      real*8  arg,argd, fund_arg(6,2)
      real*8  dotarg            ! Function Compute tidal argument angle
      logical knew_order                  !if true, then GMST+pi is first arguement. if false, then last. 
      data knew_order/.true./
      
!
!**** Get the fundamental arguments at this epoch
!
      call hftide_angles(RMJD_TT, Delta_T, knew_order, fund_arg)
    
      EOP=0.d0
!     Now loop over the tidal contribution.  
      do itide = 1, num_gips
!         Get the argument and the time_derivative. 
          arg=dotarg(itide_arg(1,itide), fund_arg(1,1))
!         arg = mod(arg, 2.d0*pi)
          argd=dotarg(itide_arg(1,itide), fund_arg(1,2))      
!          write(*,*) tide_coef(1:2,1:3,itide) 
          !stop
          do jeop=1,4
             EOP(jeop,1)=eop(jeop,1)+sin(arg)*tide_coef(1,jeop,itide)+cos(arg)*tide_coef(2,jeop,itide)
             EOP(jeop,2)=eop(jeop,2)+argd*(cos(arg)*tide_coef(1,jeop,itide)-sin(arg)*tide_coef(2,jeop,itide))
          end do           
      end do      
        
!**** That is all.
      return
      end subroutine calc_hf_gip_xyu
End module 


