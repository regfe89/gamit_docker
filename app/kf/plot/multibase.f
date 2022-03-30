      program multibase

*** take off from multiplot
*** M.Burc Oral 
**  Cleaned ncar stuff [v1.mutibase.f]  Oral 930615 
**  added select -s option  Oral 930619 
**  added file name option -name Oral
**  added residual option -r Oral
**  added day/year date format -d -y Oral 930911
**  Added sigma limit on output.  Values given are max_nesig and
**        max_usig for north 
**  Added -model values output for files generated by enfit. tah. 990506. 
**  Changed default output from ymdhm to day-of-year.  King 030728
*     Program to read a values file and create SELECTED baselines'  components
*
*     Runstring:
*     Multibase <values_file>  <-s baseline_file>  <-residual/-model> <-name root>   <-day or -year>
*
*     <root>        is the root for the baseline files and the meta
*                   file.

      integer*4 max_data
 
      parameter ( max_data = 9999 )
 
*   num_data        - Number of data read
*   used_data       - Actual number of data left after editing
*   i,j,k           - Loop control
*   ierr            - IOSTAT error
*   outlu           - Output lu.
*   start           - start number
*   skip            - number to skip each time
*   trimlen         - Returns length of string
*   len_buffer       - Length of buffer read from file
*   indx            - Index for readline


      integer*4 num_data, used_data, i,j,ierr, outlu,
     .    start, skip, date(5), trimlen, edit_flag(max_data),
     .    len_buffer, indx
 
 
*   epoch(max_data) - Epochs of data points
*   length(max_data)- Length read from values file
*   sigma(max_data) - Sigmas of data read from file
*                   - runstring)
*   nom_length      - Nominal length to remove from values
*   ref_length      - Reference length removed from all values
*   ref_epoch       - Reference epoch removed from all values
*   value           - value read from file
*   sig             - Sigma read from file
*   mean            - Mean length from file
*   nrms            - NRMS scatter
*   mean_epoch      - Mean epoch from file
*   slope           - Slope in mm/yr read-- converted to m/day
*   min_length      - minimum length
*   max_length      - maximim length
*   avlength        - Median length for min and max length

*   max_signe       - Maximum NE sigma to output
*   max_sigu        - Maximum U sigma to output
*   vread           - Value read from file in case we have trouble
*                     reading model values (only generated by enfit).
 
      real*8 sectag, jd, epoch(max_data), length(max_data),
     .    sigma(max_data), 
     .    nom_length, ref_epoch, value, sig, mean, nrms,
     .    mean_epoch, slope, min_length, max_length, avlength,
     .    max_signe, max_sigu, vread
 
*       eof         - Indicates end of file
      logical eof
 
*   cdum            - Dummy character
      character*4 cdum
 
*   values_file     - Name of values file
*   baseline_file     - Name of baseline file
*   plot_data       - Name of plot data file
*   root            - Root of the files to be generated for the
*                   - plot data files, and the meta file.
 
      character*128 values_file, baseline_file, plot_data,root
 
*             title - Title of plots
      character*132 title
 
*             baseline  - Name of baseline
*             buffer    - Buffer for reading values into
 
      character*80 baseline
      character*128 buffer

* create_base
      character*80 create_base(9999,2)
* date type 
      character*1 date_type

      integer*4  n_create_base
      integer*4  iflag
* save_indx  -- Saved value of position in string in case we need to
*               create model from observations and residuals

      integer*4 save_indx


*     plot_residual   -r option in the command line 
*     and not the total value
* plot_model   -m option in command line (exclusive of -r)

      logical plot_residual, plot_model
 
      common / data_block / epoch, length, sigma, edit_flag
 
 
***** Start, decode runstring

      baseline_file(1:1) = ' '
      call get_runstring(outlu, values_file,baseline_file,plot_residual,
     >     plot_model, root , date_type, max_signe, max_sigu )

***** Open up the values file, baseline_file
 
      open(100, file=values_file, iostat=ierr, status='old')
      call report_error('IOSTAT',ierr,'open',values_file,1,'multibase')

 
***** select a subset of baselines 
      if ( baseline_file(1:1)  .ne. ' ' ) then
        call  read_basefile(baseline_file,n_create_base, create_base)
      else
        print *,"select ALL"
*****   OR select ALL 
        n_create_base = 1
        create_base(1,1)(1:4) = '****'
        create_base(1,2)(1:4) = '****'
      endif

      write(*,150) max_signe, max_sigu
 150  format('Limiting output sigmas to ',F8.4,' m Horizontal and ',
     .       F8.4,' m height') 
 
****  Now start looping through the values file
      sectag = 0
      start = 0
      skip = 0
      eof = .false.
      do while ( .not.eof )
*****     Start getting the data
          read(100,'(a)',iostat=ierr) title
          if( title(1:11).eq.'VALUES_FILE') then
              read(100,'(a)',iostat=ierr) title
          end if

          if( trimlen(title).eq.0 ) then
              title = '*  SOLUTION OF UNKNOWN TYPE'
          end if
*                                         ! No more data
          if( ierr.ne.0 ) then
              eof = .true.
*                                         ! Still data in file
          else
              read(100,'(a)', iostat=ierr) baseline
              call create_baseline(n_create_base,create_base,baseline
     >             ,iflag)

*                                         ! Skip a line
              read(100,'(a)') buffer
              if ( iflag .gt. 0 ) then 
*             open the output data file
              call open_plot_data( 202, baseline, root, plot_data )
              end if 
*****         Now start reading values
              do j = 1, start-1
*                                         ! Skip to start place
                  read(100,'(a)') buffer
              end do
 
*****         Now start reading
              len_buffer = 1
*                                         ! Counter for num_data
              i = 0
              do while ( len_buffer.gt.0 )
                  read(100,'(a)',iostat=ierr) buffer


                  len_buffer = trimlen(buffer)
*                                                 ! Values here
                  if( len_buffer.gt.0 .and.
     .               buffer(1:1).eq.' '   ) then
                      i = i + 1
                      indx = 1
                      call multiread(buffer,indx,'I4', ierr, date,
     .                                cdum,5)
                      call ymdhms_to_jd(date, sectag,jd)
                      call read_line(buffer, indx, 'R8', ierr,
     .                               value, cdum)
                      call read_line(buffer, indx, 'R8', ierr,
     .                               sig, cdum)
*                     See if we are ploting residuals. If we
*                     are get the next two values.
                      save_indx = indx
                      if( plot_residual ) then
                         call read_line(buffer, indx, 'R8', ierr,
     .                                  value, cdum)
                         call read_line(buffer, indx, 'R8', ierr,
     .                                  sig, cdum)
                      end if
                      if( plot_model ) then
                         call getword(buffer, cdum, indx)
                         call getword(buffer, cdum, indx)
                         call read_line(buffer, indx, 'R8', ierr,
     .                                  vread, cdum)
                         if( ierr.ne.0 ) then
*                           Error reading model, create model from
*                           Obs and residual.
                            indx = save_indx
                            call read_line(buffer, indx, 'R8', ierr,
     .                                  vread, cdum)
                            value = value - vread
                         else
                            value = vread
                            call read_line(buffer, indx, 'R8', ierr,
     .                                  sig, cdum)
                         end if
                      end if
                            
                          


*                     Save reference values if first point: DONT NEED
*                     TO DO YET
                      epoch(i) = jd
                      length(i) = value
                      sigma(i) = sig
 
*                     Delete any Weird dates
                      if( date(1).lt.70 ) then
                          i = i - 1
                      end if
*
* MOD TAH 980409: See if sigma is OK
                      if( iflag.eq.1 .and. max_signe.gt.0 ) then
                          if( sig.gt. max_signe ) i = i -1
                      end if
                      if( iflag.eq.2 .and. max_sigu .gt.0 ) then
                          if( sig.gt. max_sigu  ) i = i -1
                      end if
                      
                  end if
 
*****             Now skip line (if need)
                  j = skip
                  do while ( j.gt.0 .and. len_buffer.gt.0 )
                      j = j - 1
                      read(100,'(a)') buffer
                      len_buffer = trimlen(buffer)
                  end do
*                                 ! Reading the values from the file
              end do
 
*****         Save number of data
              num_data = i
 
*****         Now get the mean, and the NRMS
              read(100,'(a)') buffer
              if( buffer(1:6).ne.'Offset' ) then
                  indx = 6
                  call read_line(buffer,indx,'R8',ierr, mean, cdum)
                  indx = 68
                  call read_line(buffer, indx,'R8', ierr,nrms, cdum)
 
*****             Get slope and mean epoch
                  read(100,'(a)') buffer
                  indx = 6
                  call read_line(buffer,indx,'R8', ierr, slope, cdum)
              else
                  indx = 7
                  call read_line(buffer,indx,'R8',ierr, mean, cdum)
                  indx = index(buffer,'NRMS') + 4
                  call read_line(buffer, indx,'R8', ierr,nrms, cdum)
 
*****             Get slope and mean epoch
                  read(100,'(a)') buffer
                  indx = 17
                  call read_line(buffer,indx,'R8', ierr, slope, cdum)
              end if

 
*             Check size of slope (aviods problems with small amount
*             of data)
              if( abs(slope).gt. 200 ) then
                  slope = 0
              end if
 
*                                              ! Convert mm/yr to m/day
              slope = slope/365.d0/1000.d0
              if( buffer(1:6).ne.'Offset' ) then
                  indx = 71
                  call read_line(buffer,indx,'R8', ierr, mean_epoch,
     .                       cdum)
              else
                  mean_epoch = 1999.0
              end if

*             If we plotinmg resiuduals, set mean and slope to zero
              if( plot_residual ) then
                  mean = 0.d0
                  slope = 0.0d0
              end if
 
****          Convert mean_epoch to refernce jd
              date(1) = mean_epoch
              date(2) = 1
              date(3) = (mean_epoch-date(1))*365.d0
              date(4) = 0
              date(5) = 0
              call ymdhms_to_jd( date, sectag, ref_epoch)
 
*****         Skip a line
              read(100,'(a)', iostat=ierr) buffer
              if( ierr.ne.0 ) eof = .true.
*****         Now start setting up the plot and data file
              min_length = 1.d20
              max_length = -1.d20
              used_data = 0
 
              do i = 1, num_data
 
*                 Get estimated length

                  edit_flag(i) = 0
                  min_length = min(min_length, length(i))
                  max_length = max(max_length, length(i))

                  used_data = used_data + 1
              end do


*****         Get the nominal length
              nom_length = aint(mean/10)*10.d0
              avlength = (max_length+min_length)/2

* MOD TAH 080208: This code does not seem to need.  Only add if line is
*             short
              len_buffer = trimlen(baseline)
              if( len_buffer .lt. 30 ) then
                 write(baseline(len_buffer+1:), 300) avlength
  300            format(' +',f14.3,' m')
              endif
 
              if ( iflag .gt. 0 ) then 
*****             Now output the data file
                  if( used_data.gt.1 ) then
                      call write_data(epoch, length, sigma, edit_flag,
     .                    num_data, nom_length, title, 
     .                    baseline,date_type)
                      close(202)
                  end if 
 
*                ! Any data to plot
               end if

*                ! No eof yet
          end if

      end do
 
***** Thats all
      close(100)
      close(200)
      close(201)
 
 
***** That all
      end
 
 
CTITLE GET_RUNSTRING
 
      subroutine get_runstring(outlu, values_file,baseline_file,
     &     plot_residual, plot_model, root, date_type, 
     .     max_signe, max_sigu )
 
*     Routine to decode the runstring
 
*   outlu           - Output lu.
*   rcpar           - Read runstring
*   len_run         - Length of runstring
 
      integer*4  outlu,  rcpar,len_run
      
*   max_signe, max_sigu -- Sigma limits in ne and U

      real*8 max_signe, max_sigu
 
*   jd              - jd of data
*   epoch(1)        - Epochs of data points
*   length(1)       - Length read from values file
*   sigma(1)        - Sigmas of data read from file
*   nom_length      - Nominal length to remove from values
*   root            - Root of the file names

 
*   values_file     - Name of values file
*   edit_file       - Name of edit file
 

*     plot_residual   -r option in the command line 
*     and not the total value
*     plot_model      -m option to plot model values

      logical plot_residual, plot_model

      character*(*) values_file, root
      character*(*) baseline_file
      integer*4 iargc, l_command,i , jerr
      character*16 ioption, runstr 

* date type 
      character*1 date_type

***** Start decoding
      outlu = 6
      
* name of the values_file
      len_run = rcpar(1,values_file)
      if( len_run.le.0 )  then
        call help_multibase
        call exit_multibase
      endif
* get options 
      l_command = iargc()
c      write(*,*) "l_command:",l_command

******DEFAULTS ************************************************************
      baseline_file(1:1) = ' '
      root = 'mb_'
      date_type = 'd'
* turn OFF residual plotting 
      plot_residual = .false.
      plot_model    = .false.
      
      max_signe = 0.d0
      max_sigu  = 0.d0
***************************************************************************

      if (  l_command .eq. 1 ) return 
      do i= 2, l_command 
* check out the command line entry: select baselines 
        len_run = rcpar(i,ioption)
        if ( ioption .eq. "-s" .and. i+1. le.  l_command  ) then 
          len_run = rcpar(i+1,baseline_file)
        endif
        len_run = rcpar(i,ioption)
        if ( ioption .eq. "-n" .and. i+1. le.  l_command  ) then 
          len_run = rcpar(i+1,root)
        endif
* check out the command line entry: plot residuals 
        len_run = rcpar(i,ioption)
        if ( ioption(1:2) .eq. "-r" ) then 
          plot_residual = .true.
          plot_model    = .false.
        endif
* check out the command line entry: plot model 
        len_run = rcpar(i,ioption)
        if ( ioption(1:3) .eq. "-m " ) then 
          plot_model = .true.
          plot_residual = .false.
        endif
* check out the command line entry: day format
        len_run = rcpar(i,ioption)
        if ( ioption(1:2) .eq. "-d" ) then 
          date_type = 'd'
        endif
* check out the command line entry: year format
        len_run = rcpar(i,ioption)
        if ( ioption(1:2) .eq. "-y" ) then 
          date_type = 'y'
        endif     
* check out the command line entry: calender format (y m d h m)
        len_run = rcpar(i,ioption)
        if ( ioption(1:2) .eq. "-c" ) then 
          date_type = 'c'
        endif

        
* check to see of sigma limits passed
        if( ioption(1:10).eq. '-max_signe' ) then
           len_run = rcpar(i+1, runstr)
           read(runstr,*,iostat=jerr ) max_signe 
           if( len_run.eq.0 .or. jerr.ne.0 ) max_signe = 0.d0
        end if
        if( ioption(1: 9).eq. '-max_sigu' ) then
           len_run = rcpar(i+1, runstr)
           read(runstr,*,iostat=jerr ) max_sigu 
           if( len_run.eq.0 .or. jerr.ne.0 ) max_sigu = 0.d0
        end if
       
      enddo


***** Thats all
      return
      end
CTITLE HELP_MULTIBASE 
      subroutine help_multibase

       write(6,600) 
 600  format(" MULTIBASE HELP "//,
     >     "This is a take off from multiplot to create input for GMT"/
     >     " multibase  <values_file>  <-s file>  <-r/-m>",
     >     "   <-name root>    <-d>  <-y> <-c> <-max_sig..>"//
     >     " reads a Values file  and ",
     >     " creates mb_site1_site2.dat# Change mb_ with -name "/
     >     " while selecting site/baseline combinations"/
     >     "         A GMT plotter will be added, later. "//
     >     "# ->     1 : N-S    2 : E-W    3 : U-D    4 : Length "//
     >   "Numbering is relatively easier for shell oriented GMT plots"//
     >     "these files are input to "/
     >     "                        sh_baseline"//
     >     "-s : turn ON option for  selected site/baseline "/
     >     "     combination-regardless of order.. case-independent"/
     >     "     FILE format[1 site : all combinations].",
     >     " First column is comment column and should be blank."/
     >     "     SITE1"/
     >     "     SITE3     SITE2"/ 
     >     "     SITE7          "/ 
     >     "-r : turn ON option for  residuals to be selected", //,
     >     "-m : turn ON option for  model to be selected", //,
     >     "-d(ay) -y(ear) -c(alender) selects output format"/
     >     "   default is day-of-year (-d)",//,
     >     "-max_signe [limit] limits output to results with sigmas",
     >     " less than [limit] (m)",/,
     >     "-max_sigu  [limit] limits output based in height sigma",//
     >     "USE  sh_baseline for GMT plots ", //,
     >     "(example) sh_baseline -xt -x 87 93 -anot 1 ",
     >     "-frame 1 -n 4 -f mb*" )
     
***** Thats all
      return
      end
CTITLE EXIT_MULTIBASE
      subroutine exit_multibase
          Stop ' MULTI_BASE stop: Incorrect runstring'
***** Thats all
      end

 
CTITLE WRITE_DATA
 
      subroutine write_data(epoch, length, sigma, edit_flag,
     .                      num_data, nom_length, title, baseline,
     >                      date_type)
 
 
*     Routine to write out the data file for plot
 
*   num_data        - Number of data read
*   i,j,k           - Loop control
*   date(5)         - ymdhm read from file or elsewhere
*   trimlen         - Returns length of string
*   edit_flag(1)    - Edit flags for data
*   len_buffer      - Length of buffer read from file
 
      integer*4 num_data, i, date(5), trimlen, edit_flag(*)
 
*   sectag          - Seconds tag
*   jd              - jd of data
*   epoch(1)        - Epochs of data points
*   length(1)       - Length read from values file
*   sigma(1)        - Sigmas of data read from file
*   value           - value read from file
*   nom_length      - Nominal length (m)
 
      real*8 sectag, jd, epoch(*), length(*), sigma(*), value,
     .    nom_length
 
*             title - Title of plot
*   baseline        - Name of baseline
 
 
      character*(*) title, baseline

* date type 
      character*1 date_type
      
* MOD TAH 981231: Added feature that doy is from Jan 1 of
*     earliest year of data  
* MOD TAH 010126: Added doy (integer day of year to use in 
*     ymd_to_doy     
      real*8  date_year, min_jd, Jan1_min, day_of_year
      integer*4 doy
      
 
***** Loop over the data writing out non--edited values
 
      write(202,'(a)') title(1:max(1,trimlen(title)))
      write(202,'(a)') baseline(1:trimlen(baseline))
      write(202,'(a)') ' '
      
* MOD TAH 981231: Get the earilest day
      min_jd = 1.d10
      do i = 1, num_data
          if( epoch(i).lt.min_jd .and. epoch(i).gt.0 ) then
              min_jd = epoch(i)
          endif       
      end do
      
*     Now get Jan 1 of this year
      call jd_to_ymdhms( min_jd, date, sectag)
      date(2) = 1
      date(3) = 0
      date(4) = 0
      date(5) = 0
      sectag = 0
      call ymdhms_to_jd( date, sectag, Jan1_min)       
      
****  Now loop
      do i = 1, num_data
        jd = epoch(i)
        call jd_to_ymdhms(jd, date, sectag)
c       date(1) = date(1) - 1900
        if( edit_flag(i).eq.0 ) then
          value = length(i) - nom_length
          
* check the date_type
*** original 
          if (date_type .eq. 'c' ) then
            write(202,100) date, value, sigma(i)
 100        format(i5,4i3,1x,f12.5,1x,f8.5)
            
* date is day or year

          else 
c           day_of_year  =  idoy(date(1),date(2),date(3))
c    >                     + ( date(4) + date(5) / 60. ) / 24.
            call ymd_to_doy(date, doy)
            day_of_year = doy + (date(4)+date(5)/60.d0)/24.d0

* day format 
            if (date_type .eq. 'd' ) then
* MOD TAH 981231: Change day of year to days from Jan 0, first year
              day_of_year = epoch(i) - Jan1_min
                          
              write(202,101) day_of_year, value, sigma(i)
 101          format(f10.3,1x,f12.5,1x,f8.5)
 
*year format
            else   if (date_type .eq. 'y' ) then
*             leap year 
              if (mod(date(1),4) .eq. 0) then
                date_year = date(1) + (day_of_year - 1.)/366. 
              else
                date_year = date(1) + (day_of_year - 1.)/365. 
              endif
              write(202,102) date_year, value, sigma(i)
 102          format(f11.5,1x,f12.5,1x,f8.5)
            endif
          endif 

        end if

      end do
      
***** Thats all
      return
      end
 

CTITLE OPEN_PLOT_DATA
 
      subroutine open_plot_data( unit, baseline, root, plot_data )
 
*     This routine will open the data file in which the baseline lengths
*     for the current baseline wil be saved.  (The name of the data file
*     will be generated from root and baseline

* unit          - Unit number for output
  
      integer*4  unit
 
*   baseline        - Second record from values file group, containd
*               - the baseline
*   root        - Root of the data file name
*   plot_data   - The concatinated name of the data file
 
      character*(*) baseline, root, plot_data
      character*1 file_type
* LOCAL VARIABLES
 
*   indx        - Pointer in string
*   ierr        - IOSTAT error flag
*   trimlen     - Length of string
 
      integer*4 indx, ierr, trimlen
 
*   site1, site2    - Will contain the site names in the baselines
 
      character*8 site1, site2

*   soln            - Solution number read for this solution

      character*4 soln
      character*80 newbase
 
****  Strip of the baseline name
 
      indx = 1
      call getword( baseline, site1, indx )
      call getword( baseline, site2, indx )
*     Now really get site two
      call getword( baseline, site2, indx )

*     Now get the solution number
      call getword( baseline, soln, indx)
      call getword( baseline, soln, indx)
 
*     Now construct file name
*bcsum
*MER2_GPS to YOZG_GPS Solution L
*1234567890123456789012345678901234567890
      if ( baseline(22:29) .eq. "Solution " .and. 
     .     baseline(13:19) .ne. "       "   ) then
*                                                   ! bcsum values file
       
      if (  soln(1:max(1,trimlen(soln))) .eq. "N" ) file_type = "1"
      if (  soln(1:max(1,trimlen(soln))) .eq. "E" ) file_type = "2"
      if (  soln(1:max(1,trimlen(soln))) .eq. "U" ) file_type = "3"
      if (  soln(1:max(1,trimlen(soln))) .eq. "L" ) file_type = "4"
      plot_data = root(1:trimlen(root)) // site1(1:trimlen(site1)) //
     .    '_' // site2(1:trimlen(site2)) // '.dat' // 
     .           file_type(1:1)
*ensum
*YOZG_GPS to N Solution  1
*1234567890123456789012345
      else if (  baseline(15:22) .eq. "Solution " ) then
*                                                    ! ensum values file
      if (  baseline(13:13) .eq. "N" ) file_type = "1"
      if (  baseline(13:13) .eq. "E" ) file_type = "2"
      if (  baseline(13:13) .eq. "U" ) file_type = "3"
      plot_data = root(1:trimlen(root)) // site1(1:trimlen(site1)) //
     .     '.dat' // 
     .           file_type(1:1)
*blavg run from ensum values file
*BLYT_1LA to        N Solution  1
*1234567890123456789012345
      else if ( baseline(22:29) .eq. "Solution " .and. 
     .          baseline(13:19) .eq. "       "   ) then
*                                                    ! ensum values file
          if (  baseline(20:20) .eq. "N" ) file_type = "1"
          if (  baseline(20:20) .eq. "E" ) file_type = "2"
          if (  baseline(20:20) .eq. "U" ) file_type = "3"
          plot_data = root(1:trimlen(root)) // 
     .                site1(1:trimlen(site1)) //
     .                '.dat' //  file_type(1:1)
*         Convert baseline string back to ensum style
          newbase = baseline(1:12) // baseline(20:40)
          baseline = newbase

      else
        write(*,*) "This is not a bcsum/ensum values file. Exiting!"
        stop 'Check values file ....   ***  Error ****'
      endif


      write(*,*) "Created : ", plot_data(1:trimlen(plot_data))
      open(202, file=plot_data, iostat=ierr, status='unknown')
      call report_error('IOSTAT',ierr,'open',plot_data,
     .                   1,'open_plot_data')
 
****  Thats all
      return
      end
 
 
CTITLE  CREATE_BASELINE
      subroutine create_baseline(n_create_base,create_base,baseline,
     >     iflag)
      character*80 baseline

* MOD TAH 980409: Return flag to be 1 for N/E/L or 2 for height.
* create_base
      character*80 create_base(9999,2)
      character*4 b1,b2,p1,p2
      integer*4  n_create_base
      integer*4  iflag
      integer*4  i

**** decoding the val file 
*ANKA_GPS to ISME_GPS Solution E
*IISC_GPS to E Solution  1
*1234567890123456
      iflag = 0 

      do i = 1, n_create_base
        b1 = create_base(i,1)(1:4)
        b2 = create_base(i,2)(1:4)
        p1 = baseline( 1: 4)
        p2 = baseline(13:16) 
        if ( ( b1 .eq. p1     .or. b2 .eq. p1    ) .and. 
     >       ( b1 .eq. p2     .or. b2 .eq. p2    ) ) iflag = iflag + 1 
        if ( ( b1 .eq. p1     .or. b2 .eq. p1    ) .and. 
     >       ( b1 .eq. '****' .or. b2 .eq. '****') ) iflag = iflag + 1 
        if ( ( b1 .eq. '****' .or. b2 .eq. '****') .and. 
     >       ( b1 .eq. p2 .or. b2 .eq. p2 ) )        iflag = iflag + 1 
        if (   b1 .eq. '****' .and. b2 .eq. '****' ) iflag = iflag + 1
        
* MOD TAH 980409: See if horizontal or height
        if( iflag.gt.0 ) then
            if( index(baseline,'Solution U').gt.0 .or.
     .          index(baseline,'U Solution').gt.0   ) then
                iflag = 2
            else
                iflag = 1
            end if
        end if
        
      enddo
c        write(*,'(i5,4("   ",a4))') iflag,baseline(1:4),baseline(13:16)


      return
      end

CTITLE READ_BASEFILE
      subroutine read_basefile(baseline_file,n_create_base, create_base)
*   cval        - Dummy characters for readline
      character*80 cval
*   vals(15)     - Values read from the file
      real*8  vals(15)    
*   baseline_file     - Name of baseline file
      character*128  baseline_file   
      character*80 buffer,create_base(9999,2)
*   trimlen         - Returns length of string
*   len_buffer       - Length of buffer read from file
*   indx            - Index for readline
      integer*4  trimlen, len_buffer,indx
      integer*4  n_create_base
      integer*4 i, ierr
      logical eof 

****** read baseline_file 

      open(300, file=baseline_file, iostat=ierr, status='old')
      call report_error('IOSTAT',ierr,'open',baseline_file,1,
     >     'multibase')

      i = 0
      eof = .false.
      do while ( .not.eof )

***** Now start reading
        if( ierr.ne.0 ) then
          eof = .true.
*                                         ! Still data in file
        else
          
          read(300,'(a)',iostat=ierr) buffer
          len_buffer = trimlen(buffer)

          if( len_buffer.gt.0 .and.buffer(1:1).eq.' ' 
     >         .and. ierr .eq. 0 ) then
            i = i + 1 
            indx = 1
            cval(1:4)='****'
            call read_line(buffer,indx,'CH',ierr,vals, cval)
            call casefold( cval )
            create_base(i,1)(1:trimlen(cval)) = cval
            cval(1:4)='****'
            if ( ierr .ne. -1 )  then
              call read_line(buffer,indx,'CH',ierr,vals, cval)
            endif
            if ( ierr .eq. -1 ) ierr = 0 
            call casefold( cval )
            create_base(i,2)(1:trimlen(cval)) = cval


          endif
        endif
      enddo 
*                                          !while 
      n_create_base = i 

        write(*,'("baseline_file : ",a4)') 
     >       baseline_file(1:trimlen(baseline_file))

        write(*,'(i5,"*  CREATE_BASELINES  ",a4,"--",a4)') 
     >       (i, create_base(i,1), 
     >       create_base(i,2), i=1,n_create_base)

        close(300)
****  Thats all
      return
      end

      SUBROUTINE SUICID(STRING)
      character*(*) string                       
      character*1 letter,lowerc
c     
c     UNIX version
C
C     AS THE NAME IMPLIES!! COME TO THIS SUBROUTINE ON AN ABORT
C     S.A. GOUREVITCH   6/81
c    
c     To get a good trace back, it is necessary to dump core.
C
      write (6,*) string                                         
      write (6,'(a,1x,$)') 'SUICID: Do you want to dump core?' 
      read (5,*) letter

      if (lowerc(letter) .ne. 'n') then
         write (6,*) 'SUICID: Please wait while I dump core...'
         call abort
      else
         stop 'SUICID'
      endif

      END
      character*(*) function lowerc(string)
c
c  Purpose:
c     Return a lower case string the same length as the minimum
c     of the lengths of string and lowerc declared in calling
c     routine.
c
c     Kurt Feigl April 3, 1989
c     Mark Murray June 19, 1989  Generalized       
c
c  Input:
c     string   -  character*(*)
c                 String to be converted to lower case
c                 (unchanged on exit).
c  Output:
c     lowerc   -  character*(*)
c                 Converted string (length minimum of lengths of 
c                 string and lowerc declared in calling routine)
c
c  N.B. This version of the routine is only correct for ASCII code.
c       Installers must modify the routine for other character-codes.
c       For EBCDIC systems the constant IOFF must be changed to +64.
c
c  Functions and Subroutines:
c     FORTRAN  ichar,min,len,lle,lge,char
c

      integer i,ilen,ioff
      character*(*) string
      parameter (ioff = 32) 
      
      ilen = min(len(string),len(lowerc))
      do 10 i=1,ilen
         if (lge(string(i:i),'A') .and. lle(string(i:i),'Z')) then
            lowerc(i:i)=char(ichar(string(i:i))+ioff)
         else
            lowerc(i:i) = string(i:i)
         endif
  10  continue

c     null the rest of lowerc
      do 20 i=ilen+1,len(lowerc)
         lowerc(i:i) = char(0)
  20  continue
                
      return
      end
