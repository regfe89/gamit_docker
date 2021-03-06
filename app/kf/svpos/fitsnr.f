
      program fitsnr

      implicit none 
 
*     This program will fit SNR values and estimate corrections
*     to phase data based on the oscillations of the SNR.
 
      include 'fitsnr.h'
      include '../../libraries/includes/const_freq.h'

*   ierr    - IOSTAT error
*   rcpar   - Reads the runstring
*   len_run - Length of the runstring read
*   win     - Lenght of Box-car smoothing window (in epochs)
*   i,j     - Loop counters
 
 
      integer*4 ierr, rcpar, len_run, win, i,j
 
****  Get the name of the input snr file (generated by svsnr)
      len_run = rcpar(1, infile)
      if( len_run.le.0 ) then
          call proper_runstring('fitsnrr','fitsnr.hlp',1)
      end if
 
      open(100,file=infile, status='old', iostat=ierr)
      call report_error('IOSTAT',ierr,'open',infile,1,'FITSNR')
 
****  Tell user what is happen
      write(*,120) infile(1:len_run)
 120  format('* FITSNR: Fitting SNR data in ',a)
 
****  Now read all of the input file
 
      call read_snr(100)
 
      write(*,220) num_epochs, num_sat
 220  format('* ',i5,' epochs of data with ',i3,' satellites found')
 
*     Now fit the elevation angle dependent model to the SNR data
      num_poly_L1 = 4
      num_poly_L2 = 4
      
      call fit_elev
 
*     Clear the phase adjusments
      do i = 1, num_epochs
          do j = 1, num_sat
              phs_l1a(i,j) = 0.0
              phs_L2a(i,j) = 0.0
          end do
      end do
 
*     Now start the scanning loops of smoothing the data in sucessively
*     shorter smoothing windows
 
*     These smmothing windows are likely to change, but see how this goes.
      win = 1024
      
      do while ( win.ge.1 )
 
*         Smooth the data with the current window
          call smooth( win )
 
*         Now compute the phase variations
          call estphs
          if( win.lt.4 ) then
             call out_dphs( win )
          end if
 	  
*         Now copy the residuals to the smoothing back as observations and
*         try again.
          call copyr
 
          win = win/2
         
      end do
 
****  Now write out the final phase correction values
      call out_dphs( win )
 
      end
      
CTITLE COPYR

      subroutine copyr

      implicit none 
      
*     This routine copies the difference bwteen the smooth and
*     observed SNR values back into the observed arrays so that
*     they can be smoothed less tightly.

      include 'fitsnr.h'
      
* LOCAL VARIABLES

*  i,j,k   -  Loop counters

      integer*4 i,j
      
*  kbit    -  Checks the bits in a word

      logical kbit
      
***** Loop doing the smoothing

      do i = 1, num_epochs
         do j = 1, num_sat
            if( kbit(flags(i,j),1) ) then
                gain_L1o(i,j) = 1.d0 + gain_L1o(i,j) - gain_L1s(i,j)
                gain_L2o(i,j) = 1.d0 + gain_L2o(i,j) - gain_L2s(i,j)
            end if
         end do
      end do
      
***** Thats all
      return
      end
      
CTITLE OUT_PHS

      subroutine out_dphs(win)

      implicit none 

*     This routine writes out the adjustments to the phase values
*     (L1 and L2 are found from the SNR, LC and LG are computed 
*     from these.

      include 'fitsnr.h'
      include '../includes/const_param.h'
      include '../../libraries/includes/const_freq.h'    
      integer*4 win
      
* LOCAL VARIABLES

*  i,j,k   -  Loop counters

      integer*4 i,j,date(5), code_type
      
*  dl1, dl2, dlc, dlg - Adjustments to L1, L2, LC and LG
      real*8 dl1, dl2, dlc, dlg, sectag, sod
      
      
*  kbit    -  Checks the bits in a word

      logical kbit
      
***** Loop doing the smoothing

      do i = 1, num_epochs
         call mjd_to_ymdhms( epoch(i), date, sectag)
         sod = date(4)*3600.d0 + date(5)*60.d0 + sectag
         do j = 1, num_sat
            if( kbit(flags(i,j),1) ) then
                dL1 = phs_L1a(i,j)
                dL2 = phs_L2a(i,j)
                dLC = (dL1 - (fL2/fL1)*dL2)/(1-(fL2/fL1)**2)
                dLG = -(dL1-(fL1/fL2)*dL2)/(1.d0-(fL1/fL2)**2)
          
                code_type = 1
                if( kbit(flags(i,j),3) ) code_type = 0
                write(*,120) date, sectag, sod, prn_list(j),
     .                az(i,j)*180/pi, el(i,j)*180/pi,
     .                dL1, dL2, dLC, dLG, code_type, win
 
120             format(1x,i4,4i3,f6.2,1x,f8.2,' PRN ',i2.2,2f9.4,
     .                    4f9.5,1x,i2, ' DPHS ',i4)
                
            end if
         end do
      end do
      
***** Thats all
      return
      end

      
 
CTITLE READ_SNR
 
      subroutine read_snr( unit )

      implicit none 
 
*     Routine to read the SNR file generated by svsnr.
 
      include 'fitsnr.h'
      include '../includes/const_param.h'
 
* PASSED Variables
*         unit      - Unit number
 
      integer*4 unit
 
* LOCAL Variables
 
*   ierr, jerr      - IOSTAT errors.
*   i,j             - Loop counter
*   trimlen         - Length of string
*   chan            - Channel number for the prn read
*   prn             - PRN number
*   date(5)         - Date of measurement
*   code_type       - Indicates if X-correlation (1) or code
*                     correlation (0)

      integer*4 ierr, jerr, i,trimlen, chan, prn, date(5),
     .          code_type
      
*   sectag          - Seconds tage
*   sod             - Seconds of day (not used)
*   jdread          - Julian date computed from read date
*   lastjd          - Last jd read 
*   azread, elread  - Azimith and elevation angles read (degrees)
*   snr1, snr2      - Signal-to-noise ratios read from file

      real*8 sectag, sod, jdread, lastjd, azread, elread, 
     .       snr1, snr2
 
*   line            - Line read from file
 
      character*256 line
 
****  Start reading the file
      num_epochs = 0
      num_sat = 0
      lastjd = 0
      ierr = 0
 
      do while ( ierr.eq.0 )
 
          read(unit,'(a)', iostat=ierr ) line
          if( ierr.eq.0 .and. line(1:1).eq.' ' .and.
*                                             ! Process the line
     .        trimlen(line).gt.0 ) then
 
              read(line,120,iostat=jerr) date, sectag, sod, prn,
     .                azread, elread, snr1, snr2, code_type
 120          format(i5,4i3,F6.1,f10.1,1x,'PRN ',i2.2,1x, 
     .               2f10.3,1x,2f6.1,3x,i2)
 
              call ymdhms_to_mjd( date, sectag, jdread)
 
****          See if the epoch has changed
              if( abs(jdread-lastjd).gt.10.d0/86400.d0 ) then
                  num_epochs = num_epochs + 1
                  lastjd = jdread
                  epoch(num_epochs) = jdread
                  do i = 1, max_sat
                      flags(num_epochs,i) = 0
                  end do
              end if
 
****          Now see what channel the Prn is in
              call get_chan( prn, prn_list, num_sat, chan)
 
****          OK save the values in the appropriate locations
              az(num_epochs,chan) = azread*pi/180.d0
              el(num_epochs,chan) = elread*pi/180.d0
 
              snr_L1o(num_epochs,chan) = snr1
              snr_L2o(num_epochs,chan) = snr2
          
 
*             Set flags bit to show that we have an SNR measurement
*             at this time
              call sbit(flags(num_epochs,chan),1,1)
*             Set L1 bit to show that it is code measurement
              call sbit(flags(num_epochs,chan),2,1)
*             Check to see of code measurement at L2, if it is
*             set bit to show this.  (If not a code measurement then
*             L1 SNR gain will be removed before fiting the L2 gain curve).
              if( code_type.eq.0 ) then
                  call sbit(flags(num_epochs,chan),3,1)
              end if
          end if
      end do
 
****  Thats all
      return
      end
 
CTITLE GET_CHAN
 
      subroutine get_chan( prn, prn_list, num_sat, chan )
 
      implicit none 

*     This routine will return the chan number for a given PRN
*     or add the PRN to the list
 
*   prn     - PRN number to be matched
*   prn_list(*) - List of PRN's already found
*   num_sat     - Number of PRN's already found
*   chan        - The returned channel number
 
      integer*4 prn, prn_list(*), num_sat, chan
 
* LOCAL Variables
 
*         i     - Loop counter
 
      integer*4 i
 
****  See if we ready have
      i = 1
      do while ( prn_list(i).ne.prn .and. i.le.num_sat )
          i = i + 1
      end do
 
      if ( prn_list(i).ne. prn ) then
          num_sat = num_sat + 1
          prn_list(num_sat) = prn
          chan = num_sat
      else
          chan = i
      end if
 
****  Thats all
      return
      end
 
CTITLE FIT_ELEV
 
      subroutine fit_elev
 
      implicit none 

*     This routine will fit a polynomial in sin(elev) to the L1 and
*     L2 SNR values
 
*     The basic L1 model is
*     SNR_L1 = A sin(el) + B sin(el)**2 + ..
*     For L2 (X-correlation) we first remove the L1 SNR model (scale to 1
*     at zenith) and then fit a second set of coefficients to sin(el).  For
*     the L2 code tracking channels an over-all scale factor is estimated.
 
      include 'fitsnr.h'
      include '../includes/const_param.h'
 
* LOCAL Variables
 
*   i,j,k       - Loop counters
*   ipivot(max_poly)    - Pivot elements for inversion
*   date(5)     - Date of measurement
*   code_type   - Code type (set to 0 for X-correlation, 1 for code
*               - correlation)
 
      integer*4 i,j,k, ipivot(max_poly), date(5), code_type
 
*       kbit        - Checks bit status
 
      logical kbit
 
*   se          - Sin(elevation)
*   apart(max_poly)     - Paritial derivatives for estimates
*   scale(max_poly)     - Scale factors for inversion
*   est_snr     - Estimated SNR from polynomial fit
*   est_gain        - est_snr divided by SNR at zenith (to get gain
*               - curves)
*   sectag      - Seconds tag of date
*   sod         - Seconds of day.
 
 
 
      real*8 se, apart(max_poly), scale(max_poly), est_snr, est_gain,
     .    sectag, sod
 
****  Start with the L1 SNR fit.
      call clear_norm(num_poly_L1)
 
*     Now loop over all of the data.
      do i = 1, num_epochs
          do j = 1, num_sat
*                                                 ! SNR good
              if( kbit(flags(i,j),1) ) then
                  se = sin(el(i,j))
                  do k = 1, num_poly_L1
                      apart(k) = se**k
                  end do
 
****              Now increment the normal equations
                  call inc_norm(snr_l1o(i,j), apart, num_poly_L1)
              end if
          end do
      end do
 
****  Now solve the system of equations
      call invert_vis( norm_eq, bvec, scale, ipivot,num_poly_L1,
     .                 max_poly, 1 )     
 
****  OK, Save the gain curve values
      zen_L1 = 0
      do i = 1, num_poly_L1
          gain_poly_L1(i) = bvec(i)
          zen_L1 = zen_L1 + bvec(i)
      end do
      write(*,120) zen_L1, (gain_poly_L1(i),i, i = 1, num_poly_L1)
 120  format('* L1 Zenith SNR: ',F8.2,/,
     .       '* L1 Gain curve: ',10(F8.2,'*sin(el)**',i1,1x))
 
*****  Now compute the observed L1 gains, and set up L2 by removing L1 gain
      do i = 1, num_epochs
          do j = 1, num_sat
*                                                 ! SNR good
              if( kbit(flags(i,j),1) ) then
                  se = sin(el(i,j))
                  est_snr = 0
                  do k = 1, num_poly_L1
                      est_snr = est_snr + gain_poly_L1(k)*se**k
                  end do
 
*                 Get the gain to be applied to L2
                  est_gain = est_snr / zen_L1
 
                  gain_L1o(i,j) = snr_L1o(i,j) / est_snr
 
*                 Now if L2 is X-correlated then remove the L1 gain
                  if( .not.kbit(flags(i,j),3) ) then
                      gain_L2o(i,j) = snr_L2o(i,j) / est_gain
                  else
                      gain_L2o(i,j) = snr_L2o(i,j)
                  end if
              end if
          end do
      end do
 
 
****  Now fit the L2 elevation dependence
      call clear_norm(num_poly_L2)
 
*     Now loop over all of the data.
      do i = 1, num_epochs
          do j = 1, num_sat
*                                                     ! SNR good and
              if( kbit(flags(i,j),1) .and.
     .            .not. kbit(flags(i,j),3) ) then
*                                                 ! Code tracking
                  se = sin(el(i,j))
                  do k = 1, num_poly_L2
                      apart(k) = se**k
                  end do
 
****              Now increment the normal equations
                  call inc_norm(gain_L2o(i,j), apart, num_poly_L2)
              end if
          end do
      end do
 
****  Now solve the system of equations
 
      call invert_vis( norm_eq, bvec, scale, ipivot,num_poly_L2,
     .                 max_poly, 1 )     
 
****  OK, Save the gain curve values
      zen_L2 = 0
      do i = 1, num_poly_L2
          gain_poly_L2(i) = bvec(i)
          zen_L2 = zen_L2 + bvec(i)
      end do
      write(*,220) zen_L2,(gain_poly_L2(i),i, i = 1, num_poly_L2)
 220  format('* L2 Zenith SNR: ',F8.2,/,
     .        '* L2 Gain curve: ',10(F8.2,'*sin(el)**',i1,1x))
 
*****  Now compute the observed L2 gains, and set up L2 by removing L1 gain
      norm_eq(1,1) = 0
      bvec(1) = 0
 
      do i = 1, num_epochs
          do j = 1, num_sat
*                                                 ! SNR good
              if( kbit(flags(i,j),1) ) then
                  se = sin(el(i,j))
                  est_snr = 0
                  do k = 1, num_poly_L1
                      est_snr = est_snr + gain_poly_L2(k)*se**k
                  end do
 
*****             Update gain if X-correlated, otherwize get the scaling
                  gain_L2o(i,j) = gain_L2o(i,j) / est_snr
                  if( kbit(flags(i,j),3) ) then
                      norm_eq(1,1) = norm_eq(1,1) + 1
                      bvec(1) = bvec(1) + gain_L2o(i,j)
                  end if
              end if
          end do
      end do
 
****  Now get the code-tracking L2 scaling
      if( norm_eq(1,1).ne.0.d0 ) then
          L2_code_scale = bvec(1)/norm_eq(1,1)
      else
          L2_code_scale = 1.d0
      end if
 
****  Now scale the remaining L2 code tracking gains.
      do i = 1, num_epochs
          do j = 1, num_sat
              if( kbit(flags(i,j),1) .and.
*                                                 ! SNR good and code tracking
     .            kbit(flags(i,j),3)) then
                  gain_L2o(i,j) = gain_L2o(i,j)/L2_code_scale
              end if
          end do
      end do
 
****   DEBUG: Write out the gain functions
      do i = 1, num_epochs
          call mjd_to_ymdhms( epoch(i), date, sectag)
          sod = date(4)*3600.d0 + date(5)*60.d0 + sectag
          do j = 1, num_sat
              if( kbit(flags(i,j),1) ) then
                  code_type = 1
                  if( kbit(flags(i,j),3) ) code_type = 0
                  write(*,320) date, sectag, sod, prn_list(j),
     .                az(i,j)*180/pi, el(i,j)*180/pi,
     .                gain_L1o(i,j), gain_L2o(i,j), code_type
 
320               format(1x,i4,4i3,f6.2,1x,f8.2,' PRN ',i2.2,2f9.4,
     .                    2f10.5,1x,i2, ' OBS')
              end if
          end do
      end do
 
*     Thats all
      return
      end
 
CTITLE CLEAR_NORM
 
      subroutine clear_norm( ndim )

      implicit none 
 
***   Routine to clear the normal equations
 
      include 'fitsnr.h'
 
* PASSED variables
 
*         ndim  - Dimension to cleared
 
      integer*4 ndim
 
* LOCAL variables
 
*         i,j       - Loop counters
 
      integer*4 i,j
 
****  Loop over the matrix
      do i = 1, ndim
          bvec(i) = 0.0d0
          do j = 1, ndim
              norm_eq(i,j) = 0.0d0
          end do
      end do
 
****  Thats all
      return
      end
 
CTITLE INC_NORM
 
      subroutine inc_norm( omc, apart, ndim )
 
      implicit none 

*     Rouitne to increment the normal equations
 
      include 'fitsnr.h'
 
* PASSED variables
 
*   ndim    - number of parameters being estimated
 
      integer*4 ndim
 
*   omc     - Observed values to fit
*   apart(ndim) - Partial derivatives
 
      real*8 omc, apart(ndim)
 
* LOCAL variables
 
*         i,j       - Loop counters
 
 
      integer*4 i,j
 
****  Loop over the system of equations
      do i = 1, ndim
          bvec(i) = bvec(i) + apart(i)*omc
          do j = 1, ndim
              norm_eq(i,j) = norm_eq(i,j) + apart(i)*apart(j)
          end do
      end do
 
****  Thats all
      return
      end
 
CTITLE SMOOTH
 
      subroutine smooth ( win )

      implicit none 
 
*     Routine to smooth the L1 and L2 observed gain values with a
*     moving box-car window of width win
 
      include 'fitsnr.h'
      include '../includes/const_param.h'
 
* PASSED Variables
 
*         win       - Window size in epochs
 
      integer*4 win
 
* LOCAL Variables
 
*         i,j,k     - Loop counters
*   num_L1, num_L2  - Number of values in moving average
*   date(5)         - Date
*   code_type       - X-correlation or code-correlation
 
      integer*4 i,j,k, num_L1, num_L2, date(5), code_type
 
*   kbit            - Tests bits
*   OK              - Set true if their is data with +-2 epochs of
*                   - epoch being smoothed to. (This will interpolate
*                   - the occasional missing data point).
 
      logical kbit, OK
 
*   sum_L1, sum_L2  - Sum of the values for moving average
*   wght_L1, wght_L2 - Sum of weights for Sinc filtering
*   sinc            - Value of sinc 
*   sectag, sod     - Seconds tags.
*   dwin            - Argument for Sinc function

      real*8 sum_L1, sum_L2, wght_L1, wght_L2, sectag, sod, sinc,
     .       dwin
 
      sum_L1 = 0
      sum_L2 = 0
      wght_L1 = 0
      wght_L2 = 0
      num_L1= 0
      num_L2 = 0 

****  Loop over each of the satellites
      do j = 1, num_sat
 
          do i = 1, num_epochs
 
*****         Check to see if we have data near this epoch
              OK = .false.
              do k = max(1,i-2), min(num_epochs,i+2)
                  if( kbit(flags(k,j),1) ) OK = .true.
              end do
 
              if( OK ) then
 
*                 We have an observations
                  sum_L1 = 0
                  sum_L2 = 0
                  wght_L1 = 0
                  wght_L2 = 0
                  num_L1= 0
                  num_L2 = 0
 
                  do k = max(1, i-win/2), min(num_epochs,i+win/2)
                      if( kbit(flags(k,j),1) ) then
                          dwin = (8*(k-i)/(win+1))*2*pi
                          if( dwin.ne.0 ) then
                              sinc = sin(dwin)/dwin
                          else
                              sinc = 1.d0
                          end if
                          sinc = 1.d0
                          sum_L1 = sum_L1 + gain_L1o(k,j)*sinc
                          wght_L1 = wght_L1 + sinc**2
                          num_L1 = num_L1 + 1
                          sum_L2 = sum_L2 + gain_L2o(k,j)*sinc
                          wght_L2 = wght_L2 + sinc**2
                          num_L2 = num_L2 + 1
                      end if
                  end do
              end if
 
****          OK, if we have data say the smoothed values
              if( num_L1.gt.0 ) then
                  gain_L1s(i,j) = sum_L1/wght_L1
              end if
 
              if( num_L2.gt.0 ) then
                  gain_L2s(i,j) = sum_L2/wght_L2
              end if
          end do
      end do
 
*****  TEST: Write out the smoothed gains
      write(*,310) win
 310  format('* Smoothed gain: Window width ',i4)
      do i = 1, num_epochs
          call mjd_to_ymdhms( epoch(i), date, sectag)
          sod = date(4)*3600.d0 + date(5)*60.d0 + sectag
          do j = 1, num_sat
              if( kbit(flags(i,j),1) ) then
                  code_type = 1
                  if( kbit(flags(i,j),3) ) code_type = 0
C                 write(*,320) date, sectag, sod, prn_list(j),
C    .                az(i,j)*180/pi, el(i,j)*180/pi,
C    .                gain_L1s(i,j), gain_L2s(i,j), code_type, win
 
320               format(1x,i4,4i3,f6.2,1x,f8.2,' PRN ',i2.2,2f9.4,
     .                    2f10.5,1x,i2, ' SMTH ',i4)
              end if
          end do
      end do
 
****  Thats all
      return
      end
 
CTITLE ESTPHS
 
      subroutine estphs

      implicit none 
 
*     This routine uses the smoothed SNR values to obtain estimates of
*     phase errors.  The basic model is to look for increasing or decreasing
*     gain and to use these to get the estimates of the mean signal level
*     and noise amplitude. Values in-between the extremes are estimated from
*     the SNR value at these times.
 
      include 'fitsnr.h'
      include '../includes/const_param.h'

 
* LOCAL VARIABLES
 
*   i,j,k   - Loop counters
*   dir     - +1 if SNR is increasing, and -1 if decreasing
*   ep1     - Starting epoch of current sequence
 
      integer*4 i,j,k, dir, ep1
 
*   kbit    - Check status of bits
*   finished    - Set true when satellite is completed
*   OK      - Set true if there is good data +-2 epochs of where we
*           - are looking.
 
      logical kbit, finished, OK
 
*   g1, g2  - First and last gain values in current sequence
*   go      _ Observed amplitude at epoch
*   gm, amp - Mean gain and the amplitude of the noise.
*   dphs    - Correction to the phase in cycles.
*   cosdphs - Cosine of the phase error
*   deldt   - Sign of elevation angle derivative (+1 when rising)
 
      real*8 g1, g2, go, gm, amp, dphs, cosdphs, deldt
 
***** Loop over each satellite at L1 first
      do j = 1, num_sat
 
*         Work our way up the first SNR value
          i = 1
          do while ( .not.kbit(flags(i,j),1) .and. i.lt.num_epochs )
              i = i + 1
          end do
          if( gain_L1s(i+1,j).gt. gain_L1s(i,j) ) then
              dir = +1
          else
              dir = -1
          end if
 
 
          finished = .true.
          if( i.lt.num_epochs ) finished = .false.
          ep1 = i
          g1 = gain_L1s(ep1,j)
 
          do while ( .not.finished .and. i.lt.num_epochs )
 
****          See if SNR is still going in the same direction
              i = i + 1
              if( i.ge.num_epochs ) finished = .true.
 
*****         Check to see if we have data near this epoch
              OK = .false.
              do k = max(1,i-2), min(num_epochs,i+2)
                  if( kbit(flags(k,j),1) ) OK = .true.
              end do
 
***           Logic not quite correct.  (Misses the end of the sequence if
*             gain does not change direction).
              if( dir*(gain_L1s(i+1,j)-gain_L1s(i,j)).lt.0 
     .           .and. OK) then
 
 
*                 The gain has changed direction.  Get the mean signal
*                 and noise amplitude and compute phase errors.
                  g2 = gain_L1s(i,j)
                  gm = (g1 + g2 )/2
                  amp = abs(g1-g2)/2
 
*                 Now loop correction the phase.  (Loop to point before
*                 i.  We will then start next scan at i.
                  do k = ep1, i-1
                      go = gain_L1s(k,j)
*
*                     get the sign of the elevation angle time derivative                     
                      deldt = -1.d0
                      if( el(k+1,j).gt.el(k,j) ) deldt = 1.d0

*                     Use cosine rule to get the change in phase
                      cosdphs = (go**2+gm**2-amp**2)/(2*go*gm)
                      
                      if( cosdphs.gt.1.d0 ) cosdphs = 1.d0
                      if( cosdphs.lt.-1.d0 ) cosdphs = -1.d0
                      
                      dphs = acos(cosdphs)/(2*pi)
                   
                      phs_L1a(k,j) = phs_L1a(k,j) - dir*dphs*deldt
                  end do
                  ep1 = i
                  g1 = gain_L1s(ep1,j)
                  dir = -dir
              end if
 
****          If value is not OK, then we have hit the end of sequence
*              so search for next start up vallue
              if( .not.OK ) then
                  do while ( .not.kbit(flags(i,j),1) 
     .                       .and. i.lt.num_epochs )
                      i = i + 1
                  end do
                  if( gain_L1s(i+1,j).gt. gain_L1s(i,j) ) then
                      dir = +1
                  else
                      dir = -1
                  end if
                  ep1 = i
              end if
          end do
      end do
 
***** Loop over each satellite at L2 Now
      do j = 1, num_sat
 
*         Work our way up the first SNR value
          i = 1
          do while ( .not.kbit(flags(i,j),1) .and. i.lt.num_epochs )
              i = i + 1
          end do
          if( gain_L2s(i+1,j).gt. gain_L2s(i,j) ) then
              dir = +1
          else
              dir = -1
          end if
 
 
          finished = .true.
          if( i.lt.num_epochs ) finished = .false.
          ep1 = i
          g1 = gain_L2s(ep1,j)
 
          do while ( .not.finished .and. i.lt.num_epochs )
 
****          See if SNR is still going in the same direction
              i = i + 1
              if( i.ge.num_epochs ) finished = .true.
 
*****         Check to see if we have data near this epoch
              OK = .false.
              do k = max(1,i-2), min(num_epochs,i+2)
                  if( kbit(flags(k,j),1) ) OK = .true.
              end do
 
***           Logic not quite correct.  (Misses the end of the sequence if
*             gain does not change direction).
              if( dir*(gain_L2s(i+1,j)-gain_L2s(i,j)).lt.0 
     .           .and. OK) then
 
 
*                 The gain has changed direction.  Get the mean signal
*                 and noise amplitude and compute phase errors.
                  g2 = gain_L2s(i,j)
                  gm = (g1 + g2 )/2
                  amp = abs(g1-g2)/2
 
*                 Now loop correction the phase.  (Loop to point before
*                 i.  We will then start next scan at i.
                  do k = ep1, i-1
                      go = gain_L2s(k,j)
*
*                     get the sign of the elevation angle time derivative                     
                      deldt = -1.d0
                      if( el(k+1,j).gt.el(k,j) ) deldt = 1.d0

*                     Use cosine rule to get the change in phase
                      cosdphs = (go**2+gm**2-amp**2)/(2*go*gm)
                      
                      if( cosdphs.gt.1.d0 ) cosdphs = 1.d0
                      if( cosdphs.lt.-1.d0 ) cosdphs = -1.d0
                      
                      dphs = acos(cosdphs)/(2*pi)
                   
                      phs_L2a(k,j) = phs_L2a(k,j) - dir*dphs*deldt
                  end do
                  ep1 = i
                  g1 = gain_L2s(ep1,j)
                  dir = -dir
              end if
 
****          If value is not OK, then we have hit the end of sequence
*              so search for next start up vallue
              if( .not.OK ) then
                  do while ( .not.kbit(flags(i,j),1) 
     .                       .and. i.lt.num_epochs )
                      i = i + 1
                  end do
                  if( gain_L2s(i+1,j).gt. gain_L2s(i,j) ) then
                      dir = +1
                  else
                      dir = -1
                  end if
                  ep1 = i
              end if
          end do
      end do
 
 
****  Thats all
      return
      end
 
 
