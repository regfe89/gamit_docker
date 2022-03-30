
ctitle writd8
 
      subroutine writd8(dcb,ierr,ibuf, numr, recnum)

      implicit none

* Added TAH 190531: Version where numr (number of words to wrote
*     is I*8 to handle >32767 parameters in solutions.
 
*     Routine to emulate the HP 1000 writd subroutine.
*     The input are:
*     DCB - DCB buffer as defined in FmpOpen
*     ierr - error return:
*         0 -- all OK
*         -1 -- EOF reached, lenread returns 0
*         -2 -- File not open
*     ibuf- integer*4 array for return
*     numr - number of I*4 words to read
*     lenread - actual number of words read
*     recnum  - number of record to read. 0 for next record
 
*   dcb(16)     - DCB buffer
*   ierr        - Fmp error
*   ibuf(*)     - Buffer for read
*   recnum      - Record number to read
 
      integer*4 dcb(16), ierr, ibuf(*), recnum

*   numr        - Number of words (I*8) to write
*   i8          - integer*8 I counter

      integer*8 numr, i8 

      data i8 / 1 /
 
*     LOCAL VARIABLE
 
*   actrecn     - actual record number to write
*   i,j         - counter for writing records
*   numw        - number of records to write at this time
*   err_test    - Records any error during writing
 
      integer*4 actrecn, i, j, numw, err_test
 
****  MAke sure file is open
      if( dcb(1).lt.700 ) then
          ierr = -2
          return
      end if

****  See if the file is read only
      if( dcb(4).ne.0 ) then
          ierr = -8
      end if
 
****  Get record to read
      if( recnum.eq.0 ) then
          actrecn = dcb(3) + 1
      else
          actrecn = recnum
      end if
 
****  Now do the read
      err_test = 0
      if( dcb(5).le.2 ) then
* MOD TAH 190531: No change needed because numw will still fit
          numw = (numr-1)/dcb(2) + 1
          do j = 1, numw
             write(dcb(1), iostat=ierr, rec=actrecn+j-1 ) 
     .              (ibuf((j-I8)*dcb(2)+i),i=1,dcb(2))
             err_test = max(err_test, abs(ierr))
          end do
          actrecn = actrecn + numw - 1
      else
* MOD TAH 190531: Make loop variable i*8 as well 
          write(dcb(1), iostat=ierr ) (ibuf(i8),i8=1,numr)
          err_test = max(err_test, abs(ierr))
      end if
 
*                             ! Update DCB
      ierr = err_test
      if ( ierr.eq.0 ) then
          dcb(3) = actrecn 
      else if ( ierr.gt.0 ) then
          ierr = -ierr
      end if

****  Thats all
      return
      end
