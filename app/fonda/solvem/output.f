      subroutine output(idatf,imapf,imnetf,imnetf2,key,mode,version)
c     mode = 1: verbose
c     mode = 2: terse
c
c     velocity arrays 
c        vx, vy, vz :  priori velocity in geocentric frame (nsit)
c        ve, vn, vu :  priori velocity in geodetic frame (nsit)
c        slnvx, slnvy, slnvz : total velocity in geocentric frame (gdsit)
c        slnve, slnvn, slnvu : total velocity in geodetic frame (gdsit)
c     covariances
c        cova : for slnve,slnvn,slnvu (m/yr)
c
c     Modified by DUONG Chi Cong 970423 to output full cova

      implicit real*8(a-h,o-z)
      include 'solvem.fti'

      character*16 version
      integer idatf,imapf,key,mode,i,j,igd,ilive,id,im,id1,im1,i1,i2
      character*2 sp
      real*8 tp(12),tmp(9),coef(6),coef2(6),cjac1(9),cjac2(9)
      real*8 tmp2(9),dtj(9),errlim,hlim,vlim
      integer iid(6),id2,im2,imnetf,imnetf2,id0,im0, fct2
      integer maxsit1,nsit1,k1,iii,jjj,kk1
      character*1 sym1,sym2,sym3
      logical goodsit,fop

c DUONG Chi Cong 970423
      parameter(maxsit1=maxsit*3)
      real*8 ss(maxsit1)
      real*8 sss(maxsit1)
      real*8 x1(maxsit1),y1(maxsit1),z1(maxsit1)
      real*8 x2(maxsit1),y2(maxsit1),z2(maxsit1)

c     from m to mm
ckf   but perform this scaling only on output of imnetf file (coord file)
cmk   leave as m/yr if iomode(18) set
c     Assign error limits for checking quality of results
      if (iomode(18).eq.1) then
         inquire (imnetf,opened=fop)
         if (fop) then                       
            write (imnetf,'(a)'),'* Velocity Units are m/yr'
            write (imnetf,'(a2)'),'* ' 
            write (imnetf2,'(a)'),'* Velocity Units are m/yr'
            write (imnetf2,'(a2)'),'* '
         endif
         fct2 = 1.0d0
         errlim = 1.0d2
         hlim = 5.0d3
         vlim = 20.0d3
      else
         inquire (imnetf,opened=fop)
         if (fop) then                       
            write (imnetf,'(a)'),'* Velocity Units are mm/yr'
            write (imnetf,'(a2)'),'* '
            write (imnetf2,'(a)'),'* Velocity Units are mm/yr'
            write (imnetf2,'(a2)'),'* '
         endif
        
         fct2 = 1.0d3
         errlim = 0.1d0
         hlim = 5.0d0
         vlim = 20.0d0
      endif
      
      fct = 1.0d3

      sp = '  '
      small = 1.0d-10
c
c     write header
      if (mode.eq.1) then
         if (iomode(7).ne.0) call wthead(imapf,key,1,2,version)
         if (iomode(6).ne.0) call wthead(idatf,key,2,2,version)
      endif
c
c     Write the velocity units at the header of the mapping file
      if (iomode(18).gt.0) then
          write (imapf,'(a27)') '* Velocity and Error in m/yr'
          write (imapf,'(a2)'),'* '
      else
          write (imapf,'(a28)') '* Velocity and Error in mm/yr'
          write (imapf,'(a2)'),'* '
      endif

      if (iomode(6).gt.0) write (idatf,90) 'site','parameter',
     .   'apriori','adjust','sigma','final'
      if (iomode(12).gt.0) then
         write (imnetf,'(a1,24x,a42,/,a1,2x,a4,4x,a9,6x,a8,8x,a9,
     .   8x,a6,8x,a1,2(7x,a1),4x,a5,3(6x,a2))') 
     .   '*','modified site coordinate and velocity list',
     .   '*','site','full-name','latitude','longitude','height',
     .   'u','v','w','epoch','Sn','Se','Su'
         
         write (imnetf2,'(a1,24x,a42,/,a1,2x,a4,4x,a9,6x,a8,8x,a9,
     .   8x,a6,8x,a1,2(7x,a1),4x,a5,3(6x,a2))') 
     .   '*','modified site coordinate and velocity list',
     .   '*','site','full-name','latitude','longitude','height',
     .   'u','v','w','epoch','Sn','Se','Su'
      endif

c
c============================================================
c     get geodetic velocity covariance matrix
c============================================================
      call geovcv(1)
c
      ilive = 0
      do 20 igd = 1,gdsit
         i = itoj(igd)
         do 25 j = 1,3
            tp(j) = 0.0d0
            tp(j+3) = 0.0d0
            iid(j) = (i-1)*6+j
            id = map(iid(j))
            iid(j+3) = id
            if (id.gt.0) then
               do i1 = 1,j
                  i2 = j*(j-1)/2+i1
                  tmp(i2) = anorm(id*(id+1)/2-j+i1)
               enddo
               tp(j) = bnorm(id)
               ctmp = tmp(j*(j+1)/2)
               if (ctmp.gt.small) then
                  tp(j+3) = dsqrt(ctmp)
               else
                  tp(j+3) = 0.0d0
               endif
            else
               do i1 = 1,j
                  i2 = j*(j-1)/2+i1
                  tmp(i2) = 0.0d0
               enddo
            endif
 25      continue

         x1(i) = x(i)+tp(1)
         y1(i) = y(i)+tp(2)
         z1(i) = z(i)+tp(3)
         call geoxyz(radius,finv,tx,ty,tz,a1,a2,a3,
     .              x1(i),y1(i),z1(i),2,hght)
         arad = a3
         call getjac(a2,a1,a3,cjac1,5)
         call atwa(3,3,cjac1,tmp,cjac2,coef,1)
         do i1 = 1,3
            b1 = cjac2(i1*(i1+1)/2)
            if (b1.gt.small) then
               coef(i1) = dsqrt(b1)
               id = map(iid(i1)+3)
               do i2 = 1,3
                  if (id.gt.0) then
                     tmp2((i1-1)*3+i2) = anorm(id*(id+1)/2-3-i2+i1)
                  else
                     tmp2((i1-1)*3+i2) = 0.0d0
                  endif
               enddo
            else
               coef(i1) = 0.0d0
               tmp2((i1-1)*3+1) = 0.0d0
               tmp2((i1-1)*3+2) = 0.0d0
               tmp2((i1-1)*3+3) = 0.0d0
            endif
         enddo
         call axb(3,3,3,cjac1,tmp2,tmp,1,0)
         call axb(3,3,3,tmp,cjac1,cjac2,1,2)
c  
c===============================================================
c Output File - coordinates at reference time (not de-correlated)
c===============================================================
         if (iomode(6).gt.0) then
            call setlbl(3,i,1)
c           output geocentric coordinate
            if (iid(4).gt.0) then
               write(idatf,40) label(1),x(i),tp(1),tp(4),x1(i)
            else
               write(idatf,50) label(1),x(i)
            endif
            if (iid(5).gt.0) then
               write(idatf,40) label(2),y(i),tp(2),tp(5),y1(i)
            else
               write(idatf,50) label(2),y(i)
            endif
            if (iid(6).gt.0) then
               write(idatf,40) label(3),z(i),tp(3),tp(6),z1(i)
            else
               write(idatf,50) label(3),z(i)
            endif

c           output geodetic coordinate
            call sph_ca(slat(i),slon(i),tp(1),tp(2),tp(3),
     .         b1,b2,b3,2)
            b1 = b1
            b2 = b2
            b3 = b3
            call rtodms(slat(i),id,im,sec,1)
            call rtodms(a1,id1,im1,sec1,1)
            sym3 = ' '
            if (slat(i).lt.0.0d0) sym3 = '-'

c           if lat not fixed then output
            if (iid(4).gt.0) then
               write (idatf,60) label(4),sym3,iabs(id),iabs(im),
     .         dabs(sec),b2,coef(2),sym3,iabs(id1),iabs(im1),dabs(sec1)
            else
               write (idatf,60) label(4),sym3,iabs(id),iabs(im),
     .         dabs(sec)
            endif

            sym3 = ' '
            if (slon(i).gt.pi) then
                  slon(i)=2*pi-slon(i)
                  a2=2*pi-a2
                  sym3 = '-'
            end if 
            call rtodms(slon(i),id0,im0,sec0,1)
            call rtodms(a2,id2,im2,sec2,1)

c           if long not fixed then output
            if (iid(5).gt.0) then
               write (idatf,60) label(5),sym3,iabs(id0),iabs(im0),
     .         dabs(sec0),b1,coef(1),sym3,iabs(id2),iabs(im2),dabs(sec2)
               write (idatf,70) label(6),srad(i),b3,coef(3),a3
            else
               write (idatf,60) label(5),sym3,iabs(id0),iabs(im0),
     .         dabs(sec0)
               write (idatf,70) label(6),srad(i)
            endif

         endif

         call setlbl(3,i,2)
         tp(1) = solutn(igd*3-2)
         tp(2) = solutn(igd*3-1)
         tp(3) = solutn(igd*3)

         v1 = vx(i)+tp(1)
         v2 = vy(i)+tp(2)
         v3 = vz(i)+tp(3)
         call sph_ca(a1,a2,v1,v2,v3,u1,u2,u3,2)
c
         do 80 j = 1,3
            iid(j) = iid(j)+3
            i1 = map((i-1)*6+3+j)
            if (i1.gt.0) then
               cv = anorm(i1*(i1+1)/2)
            else
               cv = 0.0d0
            endif
            if (cv.gt.small) then
               tp(j+3) = dsqrt(cv)
            else
               tp(j+3) = 0.0d0
            endif
 80      continue

c        copy velocity solutions
         slnvx(igd) = v1
         slnvy(igd) = v2
         slnvz(igd) = v3
         slnve(igd) = u1 
         slnvn(igd) = u2 
         slnvu(igd) = u3 
         write(idatf,40)
     .      label(1),fct*vx(i),fct*(v1-vx(i)),fct*tp(4),v1*fct
         write(idatf,40)
     .      label(2),fct*vy(i),fct*(v2-vy(i)),fct*tp(5),v2*fct
         write(idatf,40)
     .      label(3),fct*vz(i),fct*(v3-vz(i)),fct*tp(6),v3*fct
         call sph_ca(slat(i),slon(i),tp(1),tp(2),tp(3),
     .      a1,a2,a3,2)

c        find correct column/row in covariance matrix
c        extract the appropriate errors
         i1 = igd*3-2
         cover = cova(i1*(i1+1)/2)
         if (cover.gt.small) then
            er1 = dsqrt(cover)
            dtj(4) = 1.0d0/cover
            dtj(1) = -cjac2(1)*dtj(4)
         else
            er1 = 0.0d0
            dtj(4) = 0.0d0
            dtj(1) = 0.0d0
         endif

         i1 = igd*3-1
         cover = cova(i1*(i1+1)/2)
         if (cover.gt.small) then
            er2 = dsqrt(cover)
            dtj(5) = 1.0d0/cover
            dtj(2) = -cjac2(5)*dtj(5)
         else
            er2 = 0.0d0
            dtj(5) = 0.0d0
            dtj(2) = 0.0d0
         endif

         i1 = igd*3
         cover = cova(i1*(i1+1)/2)
         if (cover.gt.small) then
            er3 = dsqrt(cover)
            dtj(6) = 1.0d0/cover
            dtj(3) = -cjac2(9)*dtj(6)
         else
            er3 = 0.0d0
            dtj(6) = 0.0d0
            dtj(3) = 0.0d0
         endif

         write(idatf,40) label(4),ve(i)*fct,fct*a1,fct*er1,u1*fct
         write(idatf,40) label(5),vn(i)*fct,fct*a2,fct*er2,u2*fct
         write(idatf,40) label(6),vu(i)*fct,fct*a3,fct*er3,u3*fct
         write (idatf,'(3x)')

c===========================================================
c        output 2-D velocity to mapping file
c        Output units are degrees, mm/yr for vel & error
c         need to change to m/yr if iomode(18)=1 
c         is set in the driver file 
c        Print adjusted coordinates (not decorrelated though)
c===========================================================
         if (iomode(7).eq.1) then
            if (comode.le.2) then
               call geoxyz(radius,finv,tx,ty,tz,a1,a2,a3,
     .                     x1(i),y1(i),z1(i),2,hght)

               if (a2.gt.pi) a2=-(2*pi-a2)
               alat = a1*rtod
               alon = a2*rtod 
               if (er1.ne.0.0d0.and.er2.ne.0.0d0) then
                  i1 = igd*3-1
                  i2 = i1*(i1+1)/2-1
                  rho = cova(i2)/er1/er2
               else
                  rho = 0.0d0
               endif

               write (imapf,10) 
     .         alon,alat,u1*fct2,u2*fct2,er1*fct2,er2*fct2,
     .         rho,sname(i)(1:8)
            else
               write (imapf,10) 
     .         x1(i),y1(i),v1*fct2,v2*fct2,er1*fct2,er2*fct2,rho,
     .         sname(i)(1:8)
            endif
 10         format (1x,2f11.5,4f9.3,f9.4,2x,a8)
         endif

c===========================================================
c        Update apriori coordinate file
c===========================================================
         if (iomode(12).eq.1) then

            if (comode.ge.3) then
               goto 20
            endif

            goodsit = .true.

c           Test for unreliable coordinate estimate
            if (coef(1).gt.hlim.or.coef(2).gt.hlim.or.
     .         coef(3).gt.vlim) then
               goodsit = .false.
               print*,'output: Possible unreliable coord estimate ! '
               id1 = id 
               im1 = im
               sec1 = sec
               id2 = id0
               im2 = im0
               sec2 = sec0
               arad = srad(i)
               delta_t = 0.0d0
               goto 35
            endif

            if (iid(4).le.0.or.iid(5).le.0) then
               delta_t = 0.0d0
               goodsit = .false.

               if (comode.eq.1) then   
                  call sphxyz(alat,alon,arad,x(i),y(i),z(i),2)
                  call rtodms(alat,id1,im1,sec1,1)
                  call rtodms(alon,id2,im2,sec2,1)

               else
                  id1 = id 
                  im1 = im
                  sec1 = sec
                  id2 = id0
                  im2 = im0
                  sec2 = sec0
                  arad = srad(i)
               endif

               goto 35
            endif


c
c           Uncorrelated coordinates
c

c           calculate delta_t to get uncorrelated coordinate
            delta_t = 0.0d0
            cff = 0.0d0

            do i1 = 1,3
               cff = cff+dtj(i1)
               delta_t = delta_t+dtj(i1+3)
            enddo

c            
            if (dabs(delta_t).gt.0.0d0) then
               delta_t = cff/delta_t

               if (tp(4).gt.errlim.or.tp(5).gt.errlim.or.
     .         tp(6).gt.errlim) then
                  v1 = 0.0d0
                  v2 = 0.0d0
                  v3 = 0.0d0
               endif   

               x2(i) = x1(i)+v1*delta_t
               y2(i) = y1(i)+v2*delta_t
               z2(i) = z1(i)+v3*delta_t

               if (dtj(4).gt.0.0d0) then
                temp = coef(1)**2+(delta_t-2.0d0*dtj(1))*delta_t/dtj(4)
                  if (temp.le.1.0d-8) then
                     coef2(1) = 0.0d0
                  else 
                     if (temp.ge.1.0d4) then
                        coef2(1) = 99.9999d0
                     else
                        coef2(1) = dsqrt(temp)
                     endif
                  endif
               endif

               if (dtj(5).gt.0.0d0) then
                temp = coef(2)**2+(delta_t-2.0d0*dtj(2))*delta_t/dtj(5)
                  if (temp.le.1.0d-8) then
                     coef2(2) = 0.0d0
                  else 
                     if (temp.ge.1.0d4) then
                        coef2(2) = 99.9999d0
                     else
                        coef2(2) = dsqrt(temp)
                     endif
                  endif
               endif

               if (dtj(6).gt.0.0d0) then
                temp = coef(3)**2+(delta_t-2.0d0*dtj(3))*delta_t/dtj(6)
                  if (temp.le.1.0d-8) then
                     coef2(3) = 0.0d0
                  else
                     if (temp.ge.1.0d4) then
                        coef2(3) = 99.9999d0
                     else
                        coef2(3) = dsqrt(temp)
                     endif
                  endif
               endif
            else
               delta_t = 0.0d0
            endif

            if (comode.eq.1) then
               call sphxyz(alat,alon,arad,x2(i),y2(i),z2(i),2)
            else
               call geoxyz
     .            (radius,finv,tx,ty,tz,alat,alon,arad,
     .             x2(i),y2(i),z2(i),2,he)
            endif

            sym2 = 'E'
            if (alon.gt.pi) then
               alon=2*pi-alon
               sym2 = 'W'
            end if

            call rtodms(alat,id1,im1,sec1,1)
            call rtodms(alon,id2,im2,sec2,1)
 35         sym1 = 'N'
            if (slat(i).lt.0.0d0) sym1 = 'S'
            
c           1.Skipping velocity output if error is large
c           values for mm/yr and m/yr output are at the top 
c           of this file 
c           2. Scale velocity to m/yr if necessary
            if (er1.gt.errlim.or.er2.gt.errlim.or.er3.gt.errlim) then
               if (.not.goodsit) goto 20
               u1 = ve(i)*fct2
               u2 = vn(i)*fct2
               u3 = vu(i)*fct2
            endif

            write (imnetf,30)
     .      sname(i),fullnm(i),sym1,iabs(id1),iabs(im1),dabs(sec1),
     .      sym2,iabs(id2),iabs(im2),dabs(sec2),arad,
     .      u1,u2,u3,rtime+delta_t,coef2(2),coef2(1),coef2(3)

c ---------------------------------------------------------------
c           output same as above, but at reference epoch
c --------------------------------------------------------------

            if (comode.eq.1) then
               call sphxyz(alat,alon,arad,x1(i),y1(i),z1(i),2)
            else
               call geoxyz
     .            (radius,finv,tx,ty,tz,alat,alon,arad,
     .             x1(i),y1(i),z1(i),2,he)
            endif

            sym2 = 'E'
            if (alon.gt.pi) then
               alon=2*pi-alon
               sym2 = 'W'
            end if

            call rtodms(alat,id1,im1,sec1,1)
            call rtodms(alon,id2,im2,sec2,1)
            sym1 = 'N'
            if (slat(i).lt.0.0d0) sym1 = 'S'

c           1.Skipping velocity output if error is large
c           values for mm/yr and m/yr output are at the top
c           of this file
c           2. Scale velocity to m/yr if necessary
            if (er1.gt.errlim.or.er2.gt.errlim.or.er3.gt.errlim) then
               if (.not.goodsit) goto 20
               u1 = ve(i)*fct2
               u2 = vn(i)*fct2
               u3 = vu(i)*fct2
            endif

            write (imnetf2,30)
     .      sname(i),fullnm(i),sym1,iabs(id1),iabs(im1),dabs(sec1),
     .      sym2,iabs(id2),iabs(im2),dabs(sec2),arad,
     .      u1,u2,u3,rtime,coef(2),coef(1),coef(3)
            
         endif

 20   continue

c=============================================================
c Output Full VCV to map file
c 
c Gilbert April 29, 1997 
c output full covariance matrix for velocities (m/yr)**2.d0
c=============================================================
      if (iomode(7).eq.1) then
        if (comode.le.2) then
          write(imapf,'(2x)')
          write(imapf,400)
c
 400  format(1x,'Full covariance matrix for velocities [m/yr]**2')
c
          nsit1=nsit*3
          do 200 i = 1,nsit1
            do 201 j = 1,i
              k1 = j+(i-1)*i/2
              ss(j) = cova(k1)
 201        continue
              write(imapf,'(2x)')
c             write(imapf,'(6(1x,1pe13.6))') (ss(j),j=1,i)
              write(imapf,'(6(1x,1pe15.8))') (ss(j),j=1,i)
 200      continue
        endif
c
c Gilbert FERHAT April 24,1997
c output full covariance matrxi for XYZ XYZ dot + auxiliary parameters
c
        write(imapf,'(2x)')
        write(imapf,500)
 500  format(1x,'Full covariance matrix for XYZ+XYZdot[m or m/yr]**2')
          do 27 iii = 1,nlive
            do 26 jjj = 1,iii
              kk1 = jjj+(iii-1)*iii/2
              sss(jjj) = anorm(kk1)
  26         continue
             write(imapf,'(2x)')
             write(imapf,'(6(1x,1pe13.6))') (sss(jjj),jjj=1,iii)
  27       continue
      endif
c  
      if (mode.eq.2) goto 100
c

 90   format (3x,a4,5x,a9,12x,a6,11x,a6,5x,a7,9x,a5)
 40   format (1x,a24,3x,f14.5,2x,f13.6,1x,f10.3,3x,f14.5)
 41   format (1x,a24,3x,f14.5,2x,f13.6,1x,f15.8,3x,f14.5)
 50   format (1x,a24,3x,f14.5,2x,f13.6)
 60   format (1x,a24,1x,a1,2i3,f9.5,2x,f13.6,1x,f10.3,1x,a1,2i3,f9.5)
 70   format (1x,a24,1x,f16.5,2x,f13.6,1x,f10.3,3x,f14.5)
c30   format (1x,a8,14x,a1,2(i2,1x),f8.5,1x,
c    .        a1,i3,1x,i2,1x,f8.5,f13.4,3f8.4,f9.3,3f8.4)
 30   format (1x,a8,1x,a12,1x,a1,2(i2,1x),f8.5,1x,
     .        a1,i3,1x,i2,1x,f8.5,f13.4,2f8.2,f7.3,f9.3,3f8.4)
c
 100  continue
      return
      end

