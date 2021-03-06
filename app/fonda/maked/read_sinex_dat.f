      subroutine read_sinex_dat(ifil1,ifil2,line,np)
c
c
c     1. read sinex file and create FONDA file
c         this is only the data part of the construction
c         see read_sinex_net.f for the net part  
c        Calls a number of routines from the GLOBK kf/htoglb directory
c        copied into this dir since fonda is not yet linked with GAMIT/GLOBK


      implicit real*8(a-h,o-z)
      include 'maked.fti'
      include '../includes/kalman_param.h'
      include '../includes/htoglb_comm.h'
 
      include '../includes/glb_hdr_def.h'
      include '../includes/sln_def.h'

* PASSED VARIABLES
 
*   ifil1       - Input SINEX unit
*   ifil2       - Output FONDA unit
*   np          - number of parameters 


      integer*4    ifil1,ifil2,np

*   line        - line read from file

      character*(*)  line


 
* LOCAL VARIABLES
 
*   
*   ierr        - IOSTAT error
*   icov_parm, isol_parm    - Pointers to starts of covariance
*               - matrix and solution vector.
*   num_in_file - number of parameters in file
*   ifile       - counter for sub output files
*   filetot     - total number of input subfiles
*   i,j,        - loop counter
*   osubunit    - unit of out subfiles
*   isubunit    - unit of in subfiles
*   n1, n2      - string place holders
*   lift_arg    - integer function
*   nblen       - integer function
*   len         - length of string
*   maxfile     - maximun number of input files
*   ifil3       - unit of site list
*   ilst        - number of sites in site list
*   junkpar, junk_lst   - unwanted site counter and list
*   match_name  - integer function

 
      integer*4 ierr, len,
     .    num_in_file, ifile, filetot, i, j, osubunit, isubunit,
     .    n1, n2, lift_arg, nblen, maxfile, ifil3, ilst

      integer junk_par,junk_lst(maxsit), k1, match_name

*
*   vma_data(1) - Array to hold the covariance
*           - matrix and solution vector. (Matrix is contained
*           - as a full square matrix)
*           - Declare as only 1, set with malloc later.
 
      integer*4 vma_data(1)


      common / vma_area / vma_data

*   icov_parm, isol_parm    - Pointers to starts of covariance
*               - matrix and solution vector.
*   icov_copy, ibwork, izwork -- Pointers for doing

      integer*4 icov_parm, isol_parm, icov_copy, ibwork, izwork

c    200 maximum files
      parameter (maxfile=200)

*   finished        - Indicates that this q file is completed
 
      logical finished
 
*   note        - fonda header info 
*   fmt1, fmt2    -  header strings
*   subhfl      - string containing subfile 
*   insub       - input subfile string 
*   st_list     - list of sites read in from site list file

 
      character*30 note
      character*6  fmt1,fmt2
      character*64 subhfl, insub(maxfile)
      character*4  st_list(maxsit),tail,stnm1


*  cov_parm     - covariance matrix from sinex file
*  vel_cov      - covariance matrix of velocities



*     real*8  cov_parm(maxsit*3,maxsit*3)
      real*8  vel_cov(maxsit*3,maxsit*3)

c-------------------------------------------------------------------
c     Set up memory management 
c       - set up usr_vma_space to suit your machine memory size
c-------------------------------------------------------------------
c     usr_vma_space = max_vma_space

c     Machine size in Mb
      usr_vma_space = 80

*     Convert mbytes to I*4 words
      usr_vma_space = usr_vma_space*(1024.)**2/4

      write(*,90) usr_vma_space*4/(1024.)**2
 90   format(' Allocating ',F8.3,' Mbytes for run')
      call htog_mem( vma_data, usr_vma_space, istart_vma )

c-------------------------------------------------------------------
c     Procedure is to run in turn
c      0.Read in_list file and get SINEX files one by one, looping over 1-4
c      1.preread sinex file 
c      2.read SINEX file
c      3.reformat parameters
c      4.write out FONDA file
c-------------------------------------------------------------------


c----------------------------------------------------------------
c     Step 0. Read in_list and get SINEX files one at a time
c----------------------------------------------------------------

c   read input list file

c     get input file name list
      ierr = 0
      filetot = 0

      read (ifil1,'(a)',iostat=ierr) insub(1)

      if (ierr.ne.0) print*,'No input files in the in_list'

      do while (ierr.eq.0)

             filetot = filetot+1

             len = nblen(insub(filetot))

c   get another input SINEX file if one exists
             read (ifil1,'(a)',iostat=ierr) insub(filetot+1)

      end do



c==================================================================
c   start big loop for each sinex file

       do ifile=1,filetot+1

c   open subfile for reading as SINEX


c         initialise variables

           np = 0
           icov_parm = 0
           isol_parm = 0
 
           num_in_file = 0
           finished = .false.

           qnum_site = 0
           qnum_comb = 0
           do i=1,maxsit
               qparn_sites(1,i)=0
               qparn_sites(2,i)=0
               qparn_sites(3,i)=0
               site_pos(1,i)=0
               site_pos(2,i)=0
               site_pos(3,i)=0
           end do


           isubunit=22

           junk_par = 0
       
           do i=1,maxsit
              junk_lst(i) = 0
           end do


c   open sinex file

           open (isubunit,file=insub(ifile),status='unknown',err=999)

c        screen display to avoid sleep
           print*,'   Processing  <<<  ',insub(ifile)(1:len)
 
     

c-----------------------------------------------------------------
c     Step 1. Pre read sinex file to get parameters
c-----------------------------------------------------------------

c     This is a cut-and-paste from TAH code in htog_ut.f

c     Check to see if this is a sinex file

          read(isubunit,'(a)', iostat=ierr) line
*
          if( index(line,'%=SNX').gt.0 ) then
              call preread_snx( isubunit, line, np, ierr, sepoch ) 
              
              num_in_file = 1
          else
              write(*,'(a)'), 'SINEX file not in correct format'
          end if

*     Memory check
          icov_parm = istart_vma
          isol_parm = icov_parm + 2*np*np
          icov_copy = isol_parm + 2*np
          ibwork    = icov_copy + 2*np + 2*np*np + 2*np*np
          izwork    = ibwork    + 2*np

          if( izwork+2*np-istart_vma.gt.usr_vma_space ) then
              write(*,95) (izwork+2*np-istart_vma)*4/1024.**2
 95           format('**DISASTER** ',f8.2,' Mbytes needed for run.')
          end if

          write(*,'(a)') 'Finished doing pre-read of SINEX file...'


c------------------------------------------------------------------
c     Step 2. read sinex file
c------------------------------------------------------------------

c     This is a cut-and-paste from TAH code make_snx.f
         
c         call fullread(isubunit,ifil2,cov_parm,line,np)
          call fullread(isubunit,ifil2,vma_data(icov_parm),
     .                  vma_data(isol_parm),line,np)


          write(*,'(a)') 'Finished reading of SINEX file...'

c------------------------------------------------------------------
c     Step 3. find sites that we do want
c------------------------------------------------------------------

c     get all explicitely designed site names
      ilst = 0
      tail = '_GPS'
      if (site_list(1:1).ne.'*') then
         junk_par = 0
         ifil3 = 10
         open (ifil3,file=site_list,status='old',err=999)

c    check all site names to see if a match
            
         do 10 i = 1,1000
            read (ifil3,'(a)',end=10) stnm1
            j = lift_arg(stnm1,st_list(i),1)
            ilst = ilst+1

c    check if site is in list (match first 4 chars only)
            if (ilst.gt.0) then
               k1 = match_name(qnum_sites,4,qsite_names,st_list(i))
               if (k1.gt.0) then
c    wanted site    
                  junk_par = junk_par+1
                  junk_lst(junk_par) = k1
               endif
            endif

 10      continue

         close (ifil3)

c   copy cov_parm and site list with only the included sites

      else
c    all sites to be output
         junk_par = qnum_sites
         do j = 1,qnum_sites
             junk_lst(j) = j
         end do

      endif

c   copy cov_parm and site list with only the included sites
      call red_param(vma_data(icov_parm),vel_cov,junk_par,junk_lst,np)



c------------------------------------------------------------------
c     Step 4.  write out FONDA files
c------------------------------------------------------------------

c     two files to write out
c       1. file containing subfile list
c       2. actual observation file


c
c File 1
c

          if (ifile.eq.1) then
c   output header

              note = '{network site number          '
              write (ifil2,50) junk_par,note
              write (ifil2,'(a8)') 
     .                (qsite_names(junk_lst(j))(1:4)//'_GPS',
     .                j=1,junk_par)
              note = '{sub-hfile number            '

              write (ifil2,50) filetot,note

          endif

c   generate subfile name for this SINEX file

          call blank(fmt1)
          call blank(fmt2)
          call blank(subhfl)
          write(fmt2,'(i3)') ifile
          n2 = lift_arg(fmt2,fmt1,1)
          n1 = nblen(outfil)
          subhfl(1:n1+n2+1) = outfil(1:n1) // '_' // fmt1(1:n2)

c   write subfile filename to output file
          
          write (ifil2,'(a)') subhfl(1:n1+n2+1) 
          

c
c File 2
c

c   write sub files
          osubunit=23
          open(osubunit,file=subhfl,status='unknown',err=999)
          call write_sub(osubunit,vma_data(icov_parm),vel_cov,
     .          junk_par, junk_lst,np)
         
c   close output subfile
          close (osubunit)
c   close SINEX file
          close (isubunit)

      end do



 50   format (i5,25x,a30)


999   continue

      end

c-----------------------------------------------------------------
CTITLE htog_mem

      subroutine htog_mem( vma_data, usr_vma_space, istart_vma )
c-----------------------------------------------------------------
cmk   Cut and paste this routine from htoglb.f in ./kf

*     Routine to assign the memory for the htoglb  run.
 
* PASSED variables

*   vma_data(1)     - Location in memory where we
*                   - start the addressing from
*   usr_vma_space   - Number of I*4 words to allocate


      integer*4 vma_data(1), usr_vma_space

* Local Variables

*   vma_bytes       - Numner of bytes needed for this
*                   - run.
*   addressof       - Returns the address of a variable
*   vma_start       - Start of the vma_data array.
*   mallocg          - Assigns memory
*   memloc          - Address that starts a big enough area
*                   - of memory

cmk   integer*4 vma_bytes, addressof, vma_start, mallocg, memloc,
cmk  .          istart_vma
      integer*4 vma_bytes, loc, vma_start, malloc, memloc,
     .          istart_vma


*     Allocate the memory for the run
      vma_bytes = usr_vma_space*4

c     replace below with the code - should run under most systems
c      see ~/gg/gamit/comlib/mallocg*      
*     memloc = mallocg(vma_bytes)
      memloc = malloc(vma_bytes) 

      if( memloc.le.0 ) then
          write(*,120) vma_bytes/(1024.0**2)
 120      format('*** DISASTER *** Not enough memory.  Try a larger',
     .                ' computer ',F10.2,' Mbytes needed')
          stop 'HTOGLB: Not enough memory'
      end if

***** See where we should start
cmk   replace below with the code - should run under most systems
c      see ~/gg/gamit/comlib/addressof.f 
c     vma_start =  addressof(vma_data)
      vma_start =  loc( vma_data )
      istart_vma = (memloc-vma_start)/4 + 1

****  Thats all
      return
      end

c==================================================================
      subroutine red_param(cov_parm,vel_cova,site_cnt,site_lst,np)
c==================================================================


*   Reduce the number of parameters in the vcv to match the site_lst

      implicit real*8(a-h,o-z)
      include 'maked.fti'
      include '../includes/kalman_param.h'
      include '../includes/htoglb_comm.h'
 
      include '../includes/glb_hdr_def.h'
      include '../includes/sln_def.h'


* PASSED VARIABLES

*   cov_parm    -  covariance matrix
*   site_cnt    -  number of sites desired
*   site_lst    -  list of desired site paramater No.
*   np          -  number of parameters in solution
*   vel_cova    - covariance matrix for velocities


      integer*4   np,site_cnt,site_lst(maxsit)

      real*8      cov_parm(np,np)
      real*8      vel_cova(maxsit*3,maxsit*3)                


* LOCAL VARIABLES

*    temp_cov, temp_cov2   - temporary covariance matrix
*    vel_cov1, vel_cov2     - temporary covariance matrix for velocities

      real*8      temp_cov(np*(np+1)/2),temp_cov2(site_cnt*3,site_cnt*3)
      real*8      vel_cov2(site_cnt*3,site_cnt*3)

*     real*8      vel_cov1(np*(np+1)/2)

*    j,k,nr,p,jj                - loop counters

      integer*4   j,k,nr,p,lsym,h,jj

c   work through columns first
c      qparn_sites(1,sn) = nr

      do j=1,site_cnt
         nr=qparn_sites(1,site_lst(j))
        do k=1,np
           h=3*j-2
            temp_cov(lsym(h,k))=cov_parm(nr,k)
            temp_cov(lsym(h+1,k))=cov_parm(nr+1,k)
            temp_cov(lsym(h+2,k))=cov_parm(nr+2,k)
        end do
      end do

c   now work through rows
      do j=1,site_cnt
        nr=qparn_sites(1,site_lst(j))
        do k=1,(site_cnt*3)
           h=3*j-2
           temp_cov2(k,h)=temp_cov(lsym(k,nr))
           temp_cov2(k,h+1)=temp_cov(lsym(k,nr+1))
           temp_cov2(k,h+2)=temp_cov(lsym(k,nr+2))
        end do
      end do

      do jj=1,np*(np+1)/2
         temp_cov(jj)=0.d0
      end do

c   velocity
      p=1
      do j=1,site_cnt
        nr=qparn_vel(1,site_lst(j))
        if (nr.gt.0) then
           do k=1,np
              h=3*p-2
              temp_cov(lsym(h,k))=cov_parm(nr,k)
              temp_cov(lsym(h+1,k))=cov_parm(nr+1,k)
              temp_cov(lsym(h+2,k))=cov_parm(nr+2,k)
           end do
           p=p+1
        endif
      end do

      p=1
      do j=1,site_cnt
        nr=qparn_vel(1,site_lst(j))
        if (nr.gt.0) then
           do k=1,(site_cnt*3)
              h=3*p-2
              vel_cov2(k,h)=temp_cov(lsym(k,nr))
              vel_cov2(k,h+1)=temp_cov(lsym(k,nr+1))
              vel_cov2(k,h+2)=temp_cov(lsym(k,nr+2))
           end do
        p=p+1
        endif
      end do

c   reassign cov_parm
      do j=1,(site_cnt*3)
         do k=1,(site_cnt*3)
c   this is not rigorous since the old values are not all overwritten
            cov_parm(j,k)=temp_cov2(j,k)
         end do
      end do

c    reassign vel_cov
      do j=1,(site_cnt*3)
         do k=1,(site_cnt*3)
c   this is not rigorous since the old values are not all overwritten
            vel_cova(j,k)=vel_cov2(j,k)
         end do
      end do

 999  continue
   
      end




c===================================================================
      subroutine write_sub(subfile,cov_parm,vel_cov,site_cnt,
     .            site_lst,np)
c==================================================================

      implicit real*8(a-h,o-z)
      include 'maked.fti'
      include '../includes/kalman_param.h'
      include '../includes/htoglb_comm.h'
 
      include '../includes/glb_hdr_def.h'
      include '../includes/sln_def.h'


*  PASSED variables

*     subfile      -  file unit for particular subfile
*     cov_parm     -  sinex covariance matrix
*   np          - number of parameters
*     site_cnt,site_lst   -  number of sites to write out, site numbers
*     vel_cov      - covariance matrix of velocities



      integer*4  subfile, np, site_cnt,site_lst(maxsit)

      real*8     cov_parm(np,np)
      real*8     vel_cov(maxsit*3,maxsit*3)     


*  LOCAL variables  

*    note          -  header string
*    site          -  8 character site name

      character*30 note
      character*8  site
      

*   i,j           - loop counter
*   numvel      - velocity counter
*   itp         - experiment code

      integer      i,j,itp, numvel


*   time1       - solution epoch in dec yrs

      real*8       time1
      


c  write sub files


c  write header

      note = '{network site number          '
      write (subfile,50) site_cnt,note
      write (subfile,'(a8)') 
     .       (qsite_names(site_lst(j))(1:4)//'_GPS',j=1,site_cnt)

c  count number of velocities
      numvel = 0
      do i = 1,site_cnt
         if (qparn_vel(1,site_lst(i)).gt.0) then
            numvel = numvel + 1
         endif
      enddo 

c     experiment number 
      if (numvel.gt.0) then
         iexp = 2
      else 
         iexp = 1
      endif

c     experiment type 33 - cartesian coordinates
      itp = 33
      note = '{experiment number            '
      write (subfile,50) iexp,note
      iexp = 1
      note = '{exp. index, obs. type, number'
      write (subfile,140) iexp,itp,site_cnt,note


c  write data

c  get time of solution - first paramater is ok
      call jd_to_decyrs( qref_ep(1), time1 )

c  write coords estimates


      do i=1,site_cnt   
          j=site_lst(i)

c      add _GPS to the site name
          site = qsite_names(j)(1:4)//'_GPS' 

c      write it out
          write (subfile,170) time1,site_pos(1,j),
     .            site_pos(2,j),site_pos(3,j),site

      end do


c  write coordinate vcv

c  j2 is the number of sites left after site removal
c     write(subfile,110) j2,(temp(k),k=1,j2)
c test
      do i=1,site_cnt*3

          write(subfile,110) i,(cov_parm(i,j),j=1,i)

      end do

      if (numvel.gt.0) then
c     write velocity estimates - experiment code 34

          iexp = 2
          itp = 34
          note = '{exp. index, obs. type, number'
          write (subfile,140) iexp,itp,numvel,note

          do i=1,site_cnt
              j=site_lst(i)

c          add _GPS to the site name
              site = qsite_names(j)(1:4)//'_GPS'

c          test to see if there is a velocity for this site
              if (qparn_vel(1,j).gt.0) then
c          write it out
                  write (subfile,180) time1,site_vel(1,j),
     .                site_vel(2,j),site_vel(3,j),site
              endif
          end do

c      write velocity vcv
          do i=1,numvel*3
                  write(subfile,110) i,(vel_cov(i,j),j=1,i)
          end do

      endif



 50   format (i5,25x,a30)
 110  format (1x,i3,'. ',50(5(1x,d23.16),:,/,6x))
 140  format (3i5,15x,a30)
 160  format (f9.4,2(1x,f23.16,1x),1x,f23.13,2x,a8)
 170  format (f9.4,1x,3(f13.4,1x),2x,a8)
 180  format (f9.4,1x,3(f10.4,1x),2x,a8)


 999  continue

      end


c====================================================================
      subroutine fullread(ifil1,ifil2,cov_parm,sol_parm,line,np)
c====================================================================

c     Reads the SINEX file in detail

      implicit real*8(a-h,o-z)
      include 'maked.fti'
      include '../includes/kalman_param.h'
      include '../includes/htoglb_comm.h'

      include '../includes/glb_hdr_def.h'
      include '../includes/sln_def.h'

* PASSED VARIABLES

*   ifil1       - Input SINEX unit
*   ifil2       - Output FONDA unit
*   line        - line read from file
*   np          - number of parameters


      integer*4    ifil1,ifil2, np

      character*(*) line


* LOCAL VARIABLES

*
*   ierr        - IOSTAT error

      integer*4 ierr

* cov_parm(np,np) - Covarince matrix
* sol_parm(np)    - Solution vector

      real*8 cov_parm(np,np), sol_parm(np)


c     initialise variables

c     do i=1,np
c        do j=1,np
c            cov_parm(i,j)=0.0d0
c        end do
c        sol_parm(i)=0.0d0
c     end do
     
 
      ierr=0

      do while ( ierr.eq.0 )
 
          read(ifil1,'(a)', iostat=ierr ) line
          if( ierr.eq.0 ) then
 
*             File read OK, see what we have.  Look
*             for start of basic blocks
              if( line(1:1).eq.'+' ) then
 
*                 This start of block. Call the main block
*                 decoder
                  call decode_snxb(ifil1, line, np, cov_parm, 
     .              sol_parm)
              else if( line(1:4).eq.'%END' ) then
 
*                 End of sinex file
                  ierr = -1
              end if
          end if
      end do


      end


c====================================================================
      integer function lsym(i,j)
c====================================================================
     
      integer*4 i,j

      if(i-j) 22,24,24
   22 lsym=i+(j*j-j)/2
      goto 36
   24 lsym=j+(i*i-i)/2
   36 return
      end
