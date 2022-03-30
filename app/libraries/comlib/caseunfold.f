
CTITLE 'caseunfold'
 
      subroutine caseunfold( string )
 
      implicit none

 
*     Routine to convert a string to lower case.
 
*         i     - Loop counter
*   len_string  - used length of string
*   trimlen     - returns string length
 
      integer*4 i, len_string, trimlen
 
*             string    - Used portion of string
 
      character*(*) string
 
***** Get length of string
      len_string = trimlen(string)
 
*     Now loop and convert
      do i = 1, len_string
          if( string(i:i).ge.'A' .and. string(i:i).le.'Z') then
              string(i:i) = CHAR( ICHAR(string(i:i))+32 )
          end if
      end do
 
****  Thats all
      return
      end
 
