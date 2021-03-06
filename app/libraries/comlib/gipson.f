      subroutine gipson(rjd,corx,cory,cort) 

      implicit none

c     This subroutine implements the gipson model for diurnal/subdiurnal
c     tides. 
c     Input variables:
c           rjd -- Either MJD or JD for evaluating contributions
c
c     Output variables:
c           corx, cory -- Corrections to X and Y pole [sec. of arc]
c           cort       -- Correction to UT [sec. of time]
c
c     coded by Lei Wang at MIT (2015)

      real*8 rjd
      real*8 corx, cory, cort

c      epoch      - Julian date (jd passed in unless the JD appears to 
c                   be an MJD in which case it is converted to JD, 
c                   i.e. 2 400 000.5d0 added) 
c     fund_arg(6) - Values of the 5 Brown's arguments (i.e.
c                   l,l',F,D,Omega) and gst+pi(rads)
c     arg         - Angular argument for the correction (rads)
      real*8 epoch, fund_arg(6), arg
      

c     Define the parameters of the model 
c     num_sdc_ut1 = number of UT1 entries in data stateent
c     num_sdc_xy  = number of xy pole entries in data statement
      integer*4 num_sdc_ut1 
      integer*4 num_sdc_xy
      parameter( num_sdc_ut1 = 70 )
      parameter( num_sdc_xy  = 100)

c     sdc_ut1_arg(6,num_sdc_ut1): Argument(Browns+(gst+pi)) for ut1.
c                                 Same ordering as IAU nutation series
c                                 (l,l',F,D,OM)
c     sdc_xy_arg(6,num_sdc_xy)  : Arguments for xy pole (as above
      integer*4 sdc_ut1_arg(6,num_sdc_ut1), sdc_xy_arg(6,num_sdc_xy)

c     sdc_ut1_val(2,num_sdc_ut1): Values for coseine and sines for ut1
c     sdc_xy_val(2,num_sdc_xy)  : Values for coseine and sines for xy
      real*8 sdc_ut1_val(2,num_sdc_ut1), sdc_xy_val(2,num_sdc_xy) 

c     local variables
      integer*4 i
      
      data(sdc_ut1_arg(1,i), sdc_ut1_arg(2,i), sdc_ut1_arg(3,i),
     .     sdc_ut1_arg(4,i), sdc_ut1_arg(5,i), sdc_ut1_arg(6,i),
     .     sdc_ut1_val(1,i), sdc_ut1_val(2,i), i=1,num_sdc_ut1  ) /
     .  1,  0,  2,  2,  2, -1,     -0.16,     -0.21,
     .  2,  0,  2,  0,  1, -1,     -0.05,     -0.19,
     .  2,  0,  2,  0,  2, -1,      0.01,     -1.13,
     .  0,  0,  2,  2,  1, -1,     -0.16,     -0.25,
     .  0,  0,  2,  2,  2, -1,     -0.16,     -0.99,
     .  1,  0,  2,  0,  1, -1,     -0.58,     -0.90,
     .  1,  0,  2,  0,  2, -1,     -2.64,     -5.16,
     . -1,  0,  2,  2,  1, -1,     -0.10,      0.00,
     . -1,  0,  2,  2,  2, -1,     -0.69,     -0.88,
     .  0,  0,  2,  0,  0, -1,      0.07,      0.02,
     .  0,  0,  2,  0,  1, -1,     -2.63,     -3.30,
     .  0,  0,  2,  0,  2, -1,    -13.22,    -17.54,
     .  2,  0,  0,  0,  0, -1,      0.10,     -0.02,
     .  0,  0,  0,  2,  0, -1,      0.17,     -0.14,
     .  1,  0,  2, -2,  2, -1,      0.19,      0.11,
     . -1,  0,  2,  0,  1, -1,     -0.02,      0.16,
     . -1,  0,  2,  0,  2, -1,      0.39,      0.42,
     .  1,  0,  0,  0,  0, -1,      0.58,      0.98,
     .  1,  0,  0,  0,  1, -1,      0.08,      0.20,
     . -1,  0,  0,  2,  0, -1,      0.10,      0.06,
     .  0,  1,  2, -2,  2, -1,     -0.16,     -0.26,
     .  0,  0,  2, -2,  1, -1,     -0.09,      0.08,
     .  0,  0,  2, -2,  2, -1,     -3.49,     -5.44,
     .  0,  1,  0,  0,  0, -1,      0.13,      1.30,
     .  0,  0,  0,  0, -1, -1,     -0.42,     -0.53,
     .  0,  0,  0,  0,  0, -1,      9.30,     17.45,
     .  0,  0,  0,  0,  1, -1,      1.15,      2.04,
     .  0,  0,  0,  0,  2, -1,      0.20,     -0.06,
     .  0, -1,  0,  0,  0, -1,     -0.03,      0.10,
     .  0,  0, -2,  2, -2, -1,      0.09,      0.13,
     .  1,  0,  0, -2,  0, -1,     -0.04,      0.14,
     . -1,  0,  0,  0,  0, -1,      0.66,      1.10,
     . -1,  0,  0,  0,  1, -1,     -0.10,      0.24,
     .  0,  0,  0, -2,  0, -1,      0.32,      0.20,
     . -2,  0,  0,  0,  0, -1,      0.14,      0.32,
     .  0,  0, -2,  0, -2, -1,      0.50,      0.59,
     .  0,  0, -2,  0, -1, -1,      0.51,      0.46,
     .  0,  0, -2,  0,  0, -1,     -0.01,      0.17,
     . -1,  0, -2,  0, -2, -1,      0.05,     -0.02,
     . -1,  0, -2,  0, -1, -1,      0.11,     -0.06,
     .  3,  0,  2,  0,  2, -2,      0.01,      0.07,
     .  1,  0,  2,  2,  2, -2,     -0.18,     -0.09,
     .  2,  0,  2,  0,  2, -2,     -0.32,      0.75,
     .  0,  0,  2,  2,  2, -2,     -0.76,      0.68,
     .  0, -1,  2,  2,  2, -2,     -0.03,      0.00,
     .  1,  1,  2,  0,  2, -2,     -0.03,     -0.04,
     .  1,  0,  2,  0,  1, -2,      0.03,     -0.06,
     .  1,  0,  2,  0,  2, -2,     -1.67,      3.76,
     .  1, -1,  2,  0,  2, -2,     -0.03,      0.08,
     . -1,  0,  2,  2,  2, -2,     -0.27,      0.64,
     . -1, -1,  2,  2,  2, -2,     -0.16,     -0.03,
     .  2,  0,  2, -2,  2, -2,      0.06,      0.01,
     .  0,  1,  2,  0,  2, -2,     -0.12,      0.08,
     .  0,  0,  2,  0,  1, -2,      0.28,     -0.57,
     .  0,  0,  2,  0,  2, -2,     -8.49,     16.71,
     .  0, -1,  2,  0,  2, -2,      0.10,     -0.01,
     .  1,  0,  2, -2,  2, -2,      0.11,     -0.06,
     . -1,  0,  2,  0,  2, -2,      0.30,     -0.39,
     .  1,  0,  0,  0,  0, -2,     -0.06,      0.02,
     .  1,  0,  0,  0,  1, -2,      0.01,      0.15,
     .  0,  1,  2, -2,  2, -2,     -0.01,      0.43,
     .  0,  0,  2, -2,  2, -2,     -0.10,      8.31,
     .  0, -1,  2, -2,  2, -2,      0.07,     -0.09,
     .  0,  0,  0,  0, -1, -2,      0.14,     -0.06,
     .  0,  0,  0,  0,  0, -2,      0.08,      2.72,
     .  0,  0,  0,  0,  1, -2,     -0.03,      0.76,
     .  0,  0,  0,  0,  2, -2,      0.21,      0.21,
     . -1,  0,  0,  0,  0, -2,     -0.08,      0.04,
     . -1,  0,  0,  0,  1, -2,      0.02,      0.03,
     .  0,  0, -2,  0, -2, -2,      0.10,     -0.02/

      data(sdc_xy_arg(1,i), sdc_xy_arg(2,i), sdc_xy_arg(3,i),
     .     sdc_xy_arg(4,i), sdc_xy_arg(5,i), sdc_xy_arg(6,i),
     .     sdc_xy_val(1,i), sdc_xy_val(2,i), i=1,num_sdc_xy  ) /
     . -1,  0, -2, -2, -2,  1,     -0.74,      0.23,
     . -2,  0, -2,  0, -1,  1,     -6.22,     -2.37,
     . -2,  0, -2,  0, -2,  1,     -5.12,      1.09,
     .  0,  0, -2, -2, -1,  1,      0.95,      2.18,
     .  0,  0, -2, -2, -2,  1,     -5.52,      1.84,
     . -1,  0, -2,  0, -1,  1,     -4.87,      2.04,
     . -1,  0, -2,  0, -2,  1,    -29.80,      7.15,
     .  1,  0, -2, -2, -1,  1,     -0.78,     -1.48,
     .  1,  0, -2, -2, -2,  1,     -4.50,      2.14,
     .  0,  0, -2,  0,  0,  1,      0.83,      1.06,
     .  0,  0, -2,  0, -1,  1,    -25.71,     11.28,
     .  0,  0, -2,  0, -2,  1,   -132.45,     55.96,
     . -2,  0,  0,  0,  0,  1,      1.79,     -4.19,
     .  0,  0,  0, -2,  0,  1,     -0.97,     -0.63,
     . -1,  0, -2,  2, -2,  1,     -1.49,     -0.27,
     .  1,  0, -2,  0, -1,  1,      1.04,      3.75,
     .  1,  0, -2,  0, -2,  1,      2.12,     -1.55,
     . -1,  0,  0,  0,  0,  1,      6.95,     -7.31,
     . -1,  0,  0,  0, -1,  1,      1.91,     -0.48,
     .  1,  0,  0, -2,  0,  1,      2.42,     -1.05,
     .  0, -1, -2,  2, -2,  1,     -1.03,      3.78,
     .  0,  0, -2,  2, -1,  1,     -1.68,     -0.42,
     .  0,  0, -2,  2, -2,  1,    -48.25,     28.74,
     .  0, -1,  0,  0,  0,  1,      0.98,      9.96,
     .  0,  0,  0,  0,  1,  1,     -5.47,      0.68,
     .  0,  0,  0,  0,  0,  1,    156.07,   -100.45,
     .  0,  0,  0,  0, -1,  1,     20.46,    -10.17,
     .  0,  0,  0,  0, -2,  1,      1.78,      1.47,
     .  0,  1,  0,  0,  0,  1,      0.55,     -2.14,
     .  0,  0,  2, -2,  2,  1,      4.12,      1.92,
     . -1,  0,  0,  2,  0,  1,      2.13,     -0.38,
     .  1,  0,  0,  0,  0,  1,      8.44,     -4.49,
     .  1,  0,  0,  0, -1,  1,      0.66,      0.64,
     .  0,  0,  0,  2,  0,  1,      0.72,     -4.98,
     .  2,  0,  0,  0,  0,  1,      1.65,      1.26,
     .  0,  0,  2,  0,  2,  1,      3.86,     -6.01,
     .  0,  0,  2,  0,  1,  1,      3.37,     -3.48,
     .  0,  0,  2,  0,  0,  1,      1.10,      2.85,
     .  1,  0,  2,  0,  2,  1,     -0.23,     -2.95,
     .  1,  0,  2,  0,  1,  1,      1.18,     -1.87,
     . -3,  0, -2,  0, -2,  2,     -1.20,      1.00,
     . -1,  0, -2, -2, -2,  2,      0.15,      0.12,
     . -2,  0, -2,  0, -2,  2,      3.51,      0.02,
     .  0,  0, -2, -2, -2,  2,      1.74,     -2.43,
     .  0,  1, -2, -2, -2,  2,      0.54,      0.03,
     . -1, -1, -2,  0, -2,  2,      0.12,      0.42,
     . -1,  0, -2,  0, -1,  2,      0.09,      1.25,
     . -1,  0, -2,  0, -2,  2,      9.45,    -13.12,
     . -1,  1, -2,  0, -2,  2,     -0.82,     -0.30,
     .  1,  0, -2, -2, -2,  2,      2.33,     -0.51,
     .  1,  1, -2, -2, -2,  2,     -1.78,     -0.05,
     . -2,  0, -2,  2, -2,  2,      1.08,     -0.35,
     .  0, -1, -2,  0, -2,  2,      0.43,      1.46,
     .  0,  0, -2,  0, -1,  2,     -4.38,      5.76,
     .  0,  0, -2,  0, -2,  2,     32.01,    -72.64,
     .  0,  1, -2,  0, -2,  2,     -2.91,      0.03,
     . -1,  0, -2,  2, -2,  2,      1.69,     -0.20,
     .  1,  0, -2,  0, -2,  2,     -0.23,      2.39,
     . -1,  0,  0,  0,  0,  2,     -1.16,     -0.15,
     . -1,  0,  0,  0, -1,  2,      0.91,     -0.21,
     .  0, -1, -2,  2, -2,  2,      2.87,     -3.84,
     .  0,  0, -2,  2, -2,  2,     -2.05,    -23.55,
     .  0,  1, -2,  2, -2,  2,     -0.53,     -1.00,
     .  0,  0,  0,  0,  1,  2,     -3.33,      1.12,
     .  0,  0,  0,  0,  0,  2,      1.48,    -15.67,
     .  0,  0,  0,  0, -1,  2,      3.34,     -1.35,
     .  0,  0,  0,  0, -2,  2,      2.73,      0.71,
     .  1,  0,  0,  0,  0,  2,      0.63,     -0.53,
     .  1,  0,  0,  0, -1,  2,     -0.09,      1.43,
     .  0,  0,  2,  0,  2,  2,      0.74,      0.24,
     .  3,  0,  2,  0,  2, -2,      2.38,      4.26,
     .  1,  0,  2,  2,  2, -2,     -0.16,      4.49,
     .  2,  0,  2,  0,  2, -2,     -0.57,      7.49,
     .  0,  0,  2,  2,  2, -2,      2.34,      7.55,
     .  0, -1,  2,  2,  2, -2,     -3.66,      3.03,
     .  1,  1,  2,  0,  2, -2,      1.41,     -0.89,
     .  1,  0,  2,  0,  1, -2,     -2.50,     -0.09,
     .  1,  0,  2,  0,  2, -2,     -0.45,     40.56,
     .  1, -1,  2,  0,  2, -2,      2.08,     -0.52,
     . -1,  0,  2,  2,  2, -2,     -0.77,      9.48,
     . -1, -1,  2,  2,  2, -2,     -1.02,     -0.92,
     .  2,  0,  2, -2,  2, -2,     -0.18,     -2.78,
     .  0,  1,  2,  0,  2, -2,     -0.07,      1.89,
     .  0,  0,  2,  0,  1, -2,      3.17,     -6.54,
     .  0,  0,  2,  0,  2, -2,    -16.98,    251.60,
     .  0, -1,  2,  0,  2, -2,      1.72,      1.95,
     .  1,  0,  2, -2,  2, -2,      0.19,      0.72,
     . -1,  0,  2,  0,  2, -2,      0.79,     -5.43,
     .  1,  0,  0,  0,  0, -2,     -1.66,      3.56,
     .  1,  0,  0,  0,  1, -2,     -0.49,     -0.16,
     .  0,  1,  2, -2,  2, -2,     -2.85,      5.10,
     .  0,  0,  2, -2,  2, -2,    -70.00,    113.01,
     .  0, -1,  2, -2,  2, -2,     -0.91,      0.24,
     .  0,  0,  0,  0, -1, -2,      3.43,      0.49,
     .  0,  0,  0,  0,  0, -2,    -14.50,     21.91,
     .  0,  0,  0,  0,  1, -2,     -7.69,      8.07,
     .  0,  0,  0,  0,  2, -2,     -0.43,      2.62,
     . -1,  0,  0,  0,  0, -2,     -2.37,      1.54,
     . -1,  0,  0,  0,  1, -2,      2.30,     -0.39,
     .  0,  0, -2,  0, -2, -2,     -0.80,      1.09 /

c     Check to make sure user passed jd and NOT mjd.
      if( rjd .lt. 2 000 000.0d0 ) then
          epoch = rjd +  2 400 000.5d0
      else 
          epoch = rjd
      endif

c     Get the fundamental arguments at this epoch
      call tide_angles( epoch, fund_arg )

c     Clear the contributions
      corx = 0.d0
      cory = 0.d0
      cort = 0.d0

c     Now loop over the UT1 contributions
      do i = 1, num_sdc_ut1
c         Get the argument
          call sdc_arg( sdc_ut1_arg(1,i), fund_arg, arg, 6 )

c         Increement the change to UT1
          cort = cort + sdc_ut1_val(1,i)*cos(arg)
     .                + sdc_ut1_val(2,i)*sin(arg)
      enddo

c     Now do polar motion
      do i = 1, num_sdc_xy
c         Get the argument
          call sdc_arg( sdc_xy_arg(1,i), fund_arg, arg, 6)

c         Increment the change to the X anf Y positions
          corx = corx  - sdc_xy_val(1,i)* cos(arg)
     .                 + sdc_xy_val(2,i)* sin(arg)
          cory = cory  + sdc_xy_val(1,i)* sin(arg)
     .                 + sdc_xy_val(2,i)* cos(arg)
      enddo 

c     Convert ut1 from "micro-sec. of time" to "sec. of time"
c     Convert x, y from "micro-sec. of arc" to "sec. of arc"" 
      cort = cort * 1.d-6
      corx = corx * 1.d-6
      cory = cory * 1.d-6

c     That is all
      return

      end

