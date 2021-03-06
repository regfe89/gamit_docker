      subroutine rdgrid(luin,sitcod,a,b,npar,nrow,valtime,valtab
     .                      ,grdvmf1 )

c  subroutine to read a file generated by GRDTAB that contains
c  parameter values for each site at certain time intervals.
c  The purpose of this routine is to simply read them into an
c  array that can be interpolated in the time domain to the
c  exact time of the observations.
c
c  P. Tregoning
c  12 January 2004.
c
c  INPUT: 
c     luin    :  input file unit number (assumed to be open)
c    sitcod   :  4-char site code
c    a,b      :  dimensions of arrays in calling program
c     npar    :  number of parameters to read per node
c
c  OUTPUT:
c     valtime :  array of tabulated times (in decimal doy)
c     valtab  :  array of parameter values 
c     nrow   :  number of table entries for the site
c    grdvmf1  : logical flag to indicate whether vmf1 coeficients
c               were derived from the grid or from the discrete list

      implicit none

      integer luin,a,b,npar,nrow,i,ioerr
      character line*100,sitcod*4,upperc*4,afmt*20,c1*1
      real*8 valtime(b),valtab(a,b)
      logical found,vmf1,grdvmf1

c PT060601: the VMF1 file has an additional column that indicates
c           whether the coefficients have been interpolated from
c           the global grid (hence need a height correction to
c           be applied when used from atmdel) or whether they have
c           come directly from the discrete list file (hence need
c           no correction). We therefore now need different read
c           formats for atmdisp and vmf1

      if(grdvmf1)then
        print*,'in rdgrid for a vmf1 read'
        vmf1 = .true.
        write(afmt,'(a,i2,a)') '(f7.2,',npar,'f15.8,3x,a1)'
      else
        vmf1 = .false.
c  read in all the values for the site
        write(afmt,'(a,i2,a)') '(f7.2,',npar,'f15.8      )'
      endif

c      print*,'format statement = ',afmt,',npar = ',npar

      found = .false.
      do while (.not.found)
        read(luin,'(a)',iostat=ioerr) line
c        print*,line
c        print*,line(5:(npar*15+10))
         if(ioerr.ne.0) call report_stat('FATAL','MODEL','setup'
     .    ,' ','Error while reading global grid file'
     .    ,ioerr)

c for the VMF, it is possible that there is no site entry. In this
c case, we will read "END" but 'found' will still be false
         if(line(1:3).eq.'END'.and..not.found)then
           nrow = 0
           return
         endif

         if( upperc(line(1:4)).eq.upperc(sitcod)) then
           found = .true.
c  read the decimal_day time tag and the three displacement values
           nrow = 1
           if(vmf1)read(line(5:(npar*15+20)),fmt=afmt)
     .                 ,valtime(nrow),(valtab(i,nrow),i=1,npar),c1
           if(.not.vmf1) read(line(5:(npar*15+10)),fmt=afmt)
     .                 ,valtime(nrow) ,(valtab(i,nrow),i=1,npar)

c  set the logical variable whether values hvae come from a grid for VMF1
           if(vmf1)then
c              print*,' c1 = ',c1
              grdvmf1 = .true.
           else
c              print*,'vmf1 from discrete list'
              grdvmf1 = .false.
           endif
c  continue reading until all values have been read
           do while (line(1:4).eq.upperc(sitcod))
c          print*,line
             read(luin,'(a)',iostat=ioerr) line
             if(line(1:4).eq.upperc(sitcod).and.ioerr.eq.0
     .          .and.line(1:3).ne.'END')then
               nrow = nrow + 1
               read(line(5:(npar*15+10)),fmt=afmt)valtime(nrow)
     .             ,(valtab(i,nrow),i=1,npar)
c      print*,(valtab(i,nrow),i=1,npar)
             endif
           enddo
         endif
      enddo

c'est tout
      return
      end

