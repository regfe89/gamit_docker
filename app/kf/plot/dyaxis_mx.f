CTITLE    ...................................................................
 
      subroutine dyaxis_mx

      implicit none
c
c     Routine to draw an y axis at x max
c
c Include files
c -------------
*                          ! the parameter file
      include 'plot_param.h'
c
*                          ! the common block
      include 'plot_com.h'
c
c Local variables
c ---------------
c tic_space  -- the spacing between the tics
c label_mult -- the multiple of the tic spacing for label
c label -- the lable to written on axis
c
      real*4 tic_space
 
c
      integer*4 label_mult
 
c
      character*80 label
 
c
c tick_len  -- the length of a tic in world coordinates
c indx  -- index to type of quanity being increment with time axes
c intv  -- the increment for time axes in units of indx
c comjd   -- a computed julian date based on value of idate
c idate   -- the date to be put on axes at label marks
c labform -- the format for labels (used with type 1 data)
c tic_num -- tic number counter
c idep -- the depth of the labels
c
      real*4 tic_len, majtl
 
c
      real*8 comjd
 
c
      integer*4 idate(6), indx, intv, tic_num, idep
 
c
      character*10 labform
 
c
c Functions
c ---------
c Trimlen  -- HP utility
c
      integer*4 trimlen, iterm
 
      real*4 tic, first_tic
 
c
c.... set up for axis drawing
      iterm = 6
c
      call axis_setup(charsz_x, 0.0, x_size_mm, tic_len)
*                     ! Reset label offsets
      call swh( 0, 0)
c
c.... Get the axis information from the buffer
      call axis_cmd(buffer, tic_space, label_mult, label)
c
c.... see if we need to compute spacing
*                                  ! yes we do
      if( tic_space.lt.0. ) then
         call com_space(scale_size(3), scale_size(4), tic_space)
      end if
c
***** Set the line feed values (so that labels will drop down)
      lfc(1) =  0.0
*                    ! Place "above" the label (as for dxaxis_mx)
      lfc(2) =  1.0
 
*     Set orientation and justification of plot
      call scj( 1.0, 0.0, 0.0, 0.5)
 
*     Rotate into correct frame
      call rotor
 
c.... Get the format for the labels if this is type 1
*                                 ! get format
      if( y_field(1).eq.1 ) then
         call format_label(scale_size(3),scale_size(4), ref_valy,
     .   labform)
      end if
c
c.... If this is a time axis convert to appropriate units
      if( y_field(1).eq.0 ) then
         call time_space(tic_space, indx, intv)
      end if
c
c.... Draw the axis
      call draw_axis(scale_size(2),scale_size(3), scale_size(2),
     .   scale_size(4))
c
c.... Now put on tic marks
*                                     ! ok put tick marks
      if( tic_space.ne.0.0 ) then
c
c....    get location of first tic mark
*                                     ! time tic mark
         if( y_field(1).eq.0 ) then
            call first_tic0(scale_size(3),ref_valy, first_tic, idate,
     .         intv, indx, tax_data)
*                                     ! normal data tic
         else
            call first_tic1(scale_size(3),ref_valy,tic_space, first_tic)
         end if
c
c
c....    Now loop over axis putting in tics
         tic = first_tic
         tic_num = 0
         idep = 0
         do while (tic.le. scale_size(4))
c
*           see if we are at a major tic.  If so increase length.
            if( label_mult.gt.0 .and.
     .          mod((tic_num-0),label_mult).eq.0 ) then
                majtl = 1.5
            else
                majtl = 1.0
            end if
 
            call draw_tic(scale_size(2), tic, -majtl*tic_len, 0.,
     .                            (majtl+1.1)*tic_len, 0. )
 
            tic_num = tic_num + 1
c
c....       See if we need label
            if( label_mult.gt.0 ) then
               if( mod((tic_num-1),label_mult).eq.0 ) then
c
                  if( y_field(1).eq.0 ) then
                     call label_ax0(idate, indx, lf, tic_num,
     .                  idep)
                  else
                     call label_ax1(labform,tic, ref_valy, idep)
                  end if
               end if
            end if
c
c....       Do the next tic
*                                       ! time axis
            if( y_field(1).eq.0 ) then
               call inc_cax(idate,intv,indx,tax_data, comjd)
               tic = comjd - ref_valy
*                                       ! normal data
            else
C              tic = tic + tic_space
               tic = first_tic + tic_num*tic_space
            end if
c
         end do
      end if
c
c.... see if we need an axis title
*                                    ! put on axis description
      if( trimlen(label).ne.0 ) then
 
         lfc(1) = 1.2*sign_x
         lfc(2) = 0.0
 
*                                ! Use the current orientation of the labels
         call comlf( lfc, lf )
         call label_axis( scale_size(2),
     .      (scale_size(3)+scale_size(4))/2.0,  3, label)
 
      end if
 
      return
      end
 
