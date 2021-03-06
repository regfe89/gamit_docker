 
      program multipltsl
 
*     This program allows the user to plot all of the markov elements
*     plot fit residuals in a SOLVK back solution file.  The runstring
*     for the program is:
*     % multipltsl bak_file <num> <element scales> <element scales> ..
*     where <num> is the number of plots per page (default is 6)
*     where <element scale> is of the form of the element title from
*         pltsl eg. clk_off, atm_off del_resid elev, and scales are
*         to be used.  If the scales are entered as zero for PLTSL will
*         use its defaults scales.
*
      include 'plot_param.h'
      include 'plot_com.h'
      include 'pltsl_com.h'
 
* VARAIBLES
 
*   len_run     - Length of runstring
*   rcpar       - Function to read runstring
*   id          - Dummy value passed to read_file (normally
*               - would contain the data)
*   irun        - The runstring number cuurently being processed
*   irow, icol  - Current row and column
*   page        - Current page number.
*   ierr,jerr   - IOSTAT error flags
*   type        - Type of element to be plotted:
*               - 0 -- Does not depend on site
*               - 1 -- depends on one station
*               - 2 -- depends on two stations
*   i,j         - Loop counters
*   date(5)     - Current date
*   ifive(5)    - Dummy needed for fmprunprogram
*   offset_unit - Pointer to unit 100 (not really used)
*   trimlen     - Returns length of string
*   num_per_page - Number of plots [er page
*   mxr, mxc    - Maximum rows and cols per page.
*   decimaltoint - Convert string to integer value
 
      integer*4 len_run, rcpar, id, irun, irow, icol, page, ierr,jerr,
     .    type, i,j, date(5), ifive, offset_unit, trimlen, num_per_page,
     .    mxr, mxc, decimaltoint
 
*   smin, smax  - Scales passed by user.
 
      real*4 smin, smax
 
*   sec         - Seconds tag for time now
 
 
      real*8 sec
 
*   element     - Name of element to be output.
*   cnum_per_page - number of plots per page read from runstring
 
      character*8 element, cnum_per_page
 
*   cmin, cmax  - Character versions of scales read from run
*               - string
 
      character*20 cmin, cmax
 
*   cdate       - Date and time that this run was made
 
      character*32 cdate
 
 
      character*32 pltsl_con

      character*128 run_line, runname
 
*   header_only - Indicates that read_file should only read
*               - the header records
 
      logical header_only
 
      data pltsl_con / 'multi_con.plt' /
 
****  Initialize some values
 
      header_only = .true.

*     Generate the run time
      call systime(date, sec)
      write(cdate,100) date
 100  format('Run: ',i4,'/',i2,'/',i2,1x,i2,':',i2)
 
 
****  Get the name of the bakfile from the runstring
 
      len_run = rcpar(1, input_file )
      if( len_run.le.0 ) then
          write(*,150)
 150      format('MULTIPLTSL: Incomlete runstring.',/,
     .           'Runstring:',/,
     .           '% multipltsl [bak_file] num <Element scale> ....',/,
     .           'where bak_file is the name of SOLVK back',
     .           ' solution file,',/,
     '           '      <num> is the number of plots per page,',/,
     .           '      and <element scale> is the element to be',
     .           ' plotted along with its',/,
     .           '           scale (min and max).  If both scale',
     .           ' values are the same then',/,
     .           '           the defaults PLTSL scales are used.')
          stop 'MULTIPLTSL: Incomlete runstring.'
      end if

*     Get the number of plots per paage 
      len_run = rcpar(2, cnum_per_page )
      if( len_run.gt.0 ) then
          num_per_page = decimaltoint( cnum_per_page, ierr)
      end if
      if( len_run.eq.0 .or. ierr.ne.0 ) then 
          num_per_page = 6
      end if

*     Set the max rows and columns
      mxc = 2
      if( num_per_page.gt.9 ) then
          mxc = 3
      end if
      if( num_per_page.eq.1 ) then
          mxc = 1
      end if
      mxr = num_per_page/mxc

      irow = mxr
      icol = mxc
      page = 0

 
*     Try to open the back file and get header information
      call read_file( id, header_only )
 
****  Open the pltsl control file
      open(200,file=pltsl_con, iostat=ierr, status='unknown')
      call report_error('IOSTAT',ierr,'open',pltsl_con,1,
     .    'Multipltsl')
 
*     Write out the start information
 
      write(200,200) cdate(1:trimlen(cdate)),
     .        input_file(1:trimlen(input_file))
  200 format('*',/,
     .    '* PLTSL control file generated by MULTIPLTSL on ',a,/,
     .    ' File ',a)
 
****  Now loop over the runstring building the pltsl control file.
      irun = 2
      do while ( len_run.gt.0 )
          irun = irun + 1
          len_run = rcpar(irun, element)
          call casefold(element)
 
          if( len_run.gt.0 ) then
              irun = irun + 1
              len_run = rcpar(irun, cmin)
          end if
          if( len_run.gt.0 ) then
              irun = irun + 1
              len_run = rcpar(irun, cmax)
          end if
 
*         If we are still decoding run string get the read the scale
*         values
          if( len_run.gt.0 ) then
              read(cmin,*, iostat=ierr ) smin
              call report_error('IOSTAT', ierr, 'reading',cmin,0,
     .            'Mulitpltsl/cmin')
              read(cmax,*, iostat=jerr ) smax
              call report_error('IOSTAT', jerr, 'reading',cmax,0,
     .            'Mulitpltsl/cmax')
          end if
 
*         See if we should continue
          if( ierr.eq.0 .and. jerr.eq.0 .and. len_run.gt.0 ) then
 
*             Get the type of the element i.e., it is by station,
*             baseline or no site.
              call get_eltype( element, type )
 
*             Now see the type we have
              if( type.eq.0 ) then
                  call write_control(200, element,' ',' ', smin, smax,
     .                irow, icol, page, input_file, cdate, mxr, mxc)
*                                             ! Site dependent
              else if ( type.eq.1 )   then
                  do i = 1, num_site
                      call write_control(200, element, site_names(i),
     .                   ' ', smin, smax, irow, icol, page,
     .                   input_file, cdate, mxr, mxc)
                  end do
*                                         ! Baseline dependent
              else if ( type.eq.2 ) then
                  do i = 1, num_site - 1
                      do j = i+1, num_site
                          call write_control(200, element,
     .                        site_names(i), site_names(j),
     .                        smin, smax, irow, icol,
     .                        page, input_file, cdate,mxr,mxc)
                      end do
                  end do
              end if
*                         ! Len_run>0 and no error decoding scales
          end if
*                         ! Looping over the input file.
      end do
 
****  Finished with all the inputs
*     close the control file
      close(200)
*     This generate the metafile
      run_line = 'pltsl ' // pltsl_con 
      call fmprunprogram( run_line, ifive, runname, 1, 6, offset_unit)
 
*     Now the user should print the file.
      end
 
CTITLE GET_ELTYPE
 
      subroutine get_eltype ( element, type )
 
*     Routine to decide the type of element that element is:  Currently
*     not all possible types are checked.  Type is returned -1 if it
*     can be found.
 
* PARAMETERS
 
*   num_poss        - Number of possibel element types
 
      integer*4 num_poss
 
      parameter ( num_poss = 15 )
 
* PASSED VARIABLES
 
*   type        - Type of element
 
      integer*4 type
 
*   element     - Element name read from runstring
 
      character*(*) element
 
* LOCAL VARIABLES
 
*   poss_types(num_poss)    - Types associated with each of
*               - possible elements
*   iel         - Pointer to type of element
 
      integer*4 poss_types(num_poss), iel
 
*   poss_els(num_poss)  - Possibel element types.
 
      character*8 poss_els(num_poss)
 
*   copy_element    - Copy of element for passing to get_cmd
 
 
      character*40 copy_element
 
      data poss_els /
     .    'CLK_OFFS'
     .,   'CLK_RATE'
     .,   'ATM_OFFS'
     .,   'ATM_RATE'
     .,   'NS_AZATM'
     .,   'EW_AZATM'
     .,   'N_SITE  '
     .,   'E_SITE  '
     .,   'U_SITE  '
     .,   'X-POLE  '
     .,   'Y-POLE  '
     .,   'UT1-AT  '
     .,   'ELEV_ANG'
     .,   'DEL_RES '
     .,   'RATE_RES'  /
 
      data poss_types / 1, 1, 1, 1, 1, 1, 1, 1, 1,0, 0, 0, 1, 2 ,2 /
 
****  see if can find the element
 
      copy_element = element
 
      call get_cmd(copy_element, poss_els, num_poss, iel)
 
      if( iel.gt.0 ) then
          type = poss_types(iel)
      else
          type = -1
          write(*,100) element
 100      format('GET_ELTYPE: Unable to find element ',a,/,
     .           ' Ignoring this entry')
      end if
 
****  Thats all
      return
      end
 
CTITLE WRITE_CONTROL
 
      subroutine write_control(unit, element, name1, name2, smin, smax,
     .        irow, icol, page, file, cdate, mxr, mxc )
 
*     Routine to write the control file for PLTSL for the current
*     element being output.  The row and columns are incremented and
*     the header is written if need be.
 
* PASSED VARIABLES
 
*   unit        - Unit number for output
*   irow, icol  - Current row and columns numbers
*   page        - Current page number
*   mxr, mxc    - Number of rows and columns of plots
 
      integer*4 unit, irow, icol, page, mxr, mxc
 
*   smin, smax  - Min and max values (if both are zero, then
*               - PLTSL defaults scales will be used)
 
      real*4 smin, smax
 
*   element     - NAme of quanitity to be plotted.
*   name1, name2    - Addition names to be output
*   file        - name of the bak file
*   cdate       - Current time encoded as character string
 
      character*(*) element, name1, name2, file, cdate
 
****  Increment row and col and see if we need to start a new page
 
      call advance_rc( unit, irow, icol, page, file, cdate, mxr, mxc )
 
***** Tell user whats is going on
 
      write(*,50) element, name1, name2, irow, icol, page
  50  format(' Processing ',a,1x,a,1x,a,' Row ',i2,' Col',i2,
     .    ' Page ',i3)
 
*     Now write out the plot control sequence
 
      write(unit, 100) element, name1, name2
 100  format(' y_field ',a,1x,a,1x,a,/,
     .       ' read')
 
      if( smax-smin.gt. 1.d-4 ) then
          write( unit, 120) smin, smax
 120      format(' y_scale ', 2(f15.4,1x))
      end if
 
*     See about error bars and point type
*                                         ! Use point -1 and errorbars
      if( element(1:3).ne.'CLK' ) then
          write(unit,140)
 140      format(' Point -1',/,
     .        ' errbars 1')
      else
          write(unit,150)
 150      format(' Point 1',/,
     .        ' errbars 0')
      end if
 
*     Now write out the drawing and axes
      write(unit,160)
 160  format(' draw',/,
     .        ' axes',/,
     .        ' fit 0',/,
     .        ' pdraw')
 
*     To put labels on the plot, reset the scales so that we know
*     where we are
      write(unit, 200)
 200  format(' y_scale 0 1 ',/,
     .       ' label 0.05 0.03 1 0 \\p2',/,
     .       ' label 0.05 0.08 1 0 \\p3')
 
****  Thats all, we are now ready for next plot
      return
      end
 
