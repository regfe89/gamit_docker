      integer*4 function cor( ia, ib )

      implicit none

*	  Common 'or' replacement to be used on sun and hp.
      integer*4 ia, ib

      cor = or(ia,ib)

      return
      end

