      subroutine gmf (dmjd,dlat,dlon,dhgt,zd,gmfh,gmfw)

C     This subroutine determines the Global Mapping Functions GMF
C     Reference: Boehm, J., A.E. Niell, H. Schuh: "Global Mapping Functions (GMF):
c     A new empirical mapping function based on numerical weather model data"
C     Geophys. Res. Lett., 33, L07304, doi:10.1029/2005GL025546, 2006.
C
C     input data
C     ----------
C     dmjd: modified julian date
C     dlat: latitude in radians
C     dlon: longitude in radians
C     dhgt: height in m
C     zd:   zenith distance in radians
C
C     output data
C     -----------
C     gmfh: hydrostatic mapping function
C     gmfw: wet mapping function
C
C     Johannes Boehm, 2005 August 30
C
c PT050831: remove implicit declarations and declare all the variables
      implicit none

      integer i,j,k,m,n,ir
      real*8 dfac(20),P(10,10),aP(55),bP(55)
     .      ,ah_mean(55),bh_mean(55),ah_amp(55),bh_amp(55)
     .      ,aw_mean(55),bw_mean(55),aw_amp(55),bw_amp(55)
     .      ,doy,dmjd,dlat,dlon,dhgt,zd,gmfh,gmfw,pi,t,sum
     .      ,bh,c0h,phh,c11h,c10h,ch,ahm,aha,ah,sine,beta
     .      ,gamma,topcon,a_ht,b_ht,c_ht,hs_km,ht_corr_coef
     .      ,ht_corr,aw,bw,cw,awm,awa
  
      pi = 3.1415926359d0

C     reference day is 28 January
C     this is taken from Niell (1996) to be consistent
      doy = dmjd  - 44239.d0 + 1 - 28

      data (ah_mean(i),i=1,55)/
     .+1.2517d+02, +8.503d-01, +6.936d-02, -6.760d+00, +1.771d-01,
     . +1.130d-02, +5.963d-01, +1.808d-02, +2.801d-03, -1.414d-03,
     . -1.212d+00, +9.300d-02, +3.683d-03, +1.095d-03, +4.671d-05,
     . +3.959d-01, -3.867d-02, +5.413d-03, -5.289d-04, +3.229d-04,
     . +2.067d-05, +3.000d-01, +2.031d-02, +5.900d-03, +4.573d-04,
     . -7.619d-05, +2.327d-06, +3.845d-06, +1.182d-01, +1.158d-02,
     . +5.445d-03, +6.219d-05, +4.204d-06, -2.093d-06, +1.540d-07,
     . -4.280d-08, -4.751d-01, -3.490d-02, +1.758d-03, +4.019d-04,
     . -2.799d-06, -1.287d-06, +5.468d-07, +7.580d-08, -6.300d-09,
     . -1.160d-01, +8.301d-03, +8.771d-04, +9.955d-05, -1.718d-06,
     . -2.012d-06, +1.170d-08, +1.790d-08, -1.300d-09, +1.000d-10/

      data (bh_mean(i),i=1,55)/
     . +0.000d+00, +0.000d+00, +3.249d-02, +0.000d+00, +3.324d-02,
     . +1.850d-02, +0.000d+00, -1.115d-01, +2.519d-02, +4.923d-03,
     . +0.000d+00, +2.737d-02, +1.595d-02, -7.332d-04, +1.933d-04,
     . +0.000d+00, -4.796d-02, +6.381d-03, -1.599d-04, -3.685d-04,
     . +1.815d-05, +0.000d+00, +7.033d-02, +2.426d-03, -1.111d-03,
     . -1.357d-04, -7.828d-06, +2.547d-06, +0.000d+00, +5.779d-03,
     . +3.133d-03, -5.312d-04, -2.028d-05, +2.323d-07, -9.100d-08,
     . -1.650d-08, +0.000d+00, +3.688d-02, -8.638d-04, -8.514d-05,
     . -2.828d-05, +5.403d-07, +4.390d-07, +1.350d-08, +1.800d-09,
     . +0.000d+00, -2.736d-02, -2.977d-04, +8.113d-05, +2.329d-07,
     . +8.451d-07, +4.490d-08, -8.100d-09, -1.500d-09, +2.000d-10/
       
      data (ah_amp(i),i=1,55)/
     . -2.738d-01, -2.837d+00, +1.298d-02, -3.588d-01, +2.413d-02,
     . +3.427d-02, -7.624d-01, +7.272d-02, +2.160d-02, -3.385d-03,
     . +4.424d-01, +3.722d-02, +2.195d-02, -1.503d-03, +2.426d-04,
     . +3.013d-01, +5.762d-02, +1.019d-02, -4.476d-04, +6.790d-05,
     . +3.227d-05, +3.123d-01, -3.535d-02, +4.840d-03, +3.025d-06,
     . -4.363d-05, +2.854d-07, -1.286d-06, -6.725d-01, -3.730d-02,
     . +8.964d-04, +1.399d-04, -3.990d-06, +7.431d-06, -2.796d-07,
     . -1.601d-07, +4.068d-02, -1.352d-02, +7.282d-04, +9.594d-05,
     . +2.070d-06, -9.620d-08, -2.742d-07, -6.370d-08, -6.300d-09,
     . +8.625d-02, -5.971d-03, +4.705d-04, +2.335d-05, +4.226d-06,
     . +2.475d-07, -8.850d-08, -3.600d-08, -2.900d-09, +0.000d+00/
       
      data (bh_amp(i),i=1,55)/
     . +0.000d+00, +0.000d+00, -1.136d-01, +0.000d+00, -1.868d-01,
     . -1.399d-02, +0.000d+00, -1.043d-01, +1.175d-02, -2.240d-03,
     . +0.000d+00, -3.222d-02, +1.333d-02, -2.647d-03, -2.316d-05,
     . +0.000d+00, +5.339d-02, +1.107d-02, -3.116d-03, -1.079d-04,
     . -1.299d-05, +0.000d+00, +4.861d-03, +8.891d-03, -6.448d-04,
     . -1.279d-05, +6.358d-06, -1.417d-07, +0.000d+00, +3.041d-02,
     . +1.150d-03, -8.743d-04, -2.781d-05, +6.367d-07, -1.140d-08,
     . -4.200d-08, +0.000d+00, -2.982d-02, -3.000d-03, +1.394d-05,
     . -3.290d-05, -1.705d-07, +7.440d-08, +2.720d-08, -6.600d-09,
     . +0.000d+00, +1.236d-02, -9.981d-04, -3.792d-05, -1.355d-05,
     . +1.162d-06, -1.789d-07, +1.470d-08, -2.400d-09, -4.000d-10/
       
      data (aw_mean(i),i=1,55)/
     . +5.640d+01, +1.555d+00, -1.011d+00, -3.975d+00, +3.171d-02,
     . +1.065d-01, +6.175d-01, +1.376d-01, +4.229d-02, +3.028d-03,
     . +1.688d+00, -1.692d-01, +5.478d-02, +2.473d-02, +6.059d-04,
     . +2.278d+00, +6.614d-03, -3.505d-04, -6.697d-03, +8.402d-04,
     . +7.033d-04, -3.236d+00, +2.184d-01, -4.611d-02, -1.613d-02,
     . -1.604d-03, +5.420d-05, +7.922d-05, -2.711d-01, -4.406d-01,
     . -3.376d-02, -2.801d-03, -4.090d-04, -2.056d-05, +6.894d-06,
     . +2.317d-06, +1.941d+00, -2.562d-01, +1.598d-02, +5.449d-03,
     . +3.544d-04, +1.148d-05, +7.503d-06, -5.667d-07, -3.660d-08,
     . +8.683d-01, -5.931d-02, -1.864d-03, -1.277d-04, +2.029d-04,
     . +1.269d-05, +1.629d-06, +9.660d-08, -1.015d-07, -5.000d-10/
       
      data (bw_mean(i),i=1,55)/
     . +0.000d+00, +0.000d+00, +2.592d-01, +0.000d+00, +2.974d-02,
     . -5.471d-01, +0.000d+00, -5.926d-01, -1.030d-01, -1.567d-02,
     . +0.000d+00, +1.710d-01, +9.025d-02, +2.689d-02, +2.243d-03,
     . +0.000d+00, +3.439d-01, +2.402d-02, +5.410d-03, +1.601d-03,
     . +9.669d-05, +0.000d+00, +9.502d-02, -3.063d-02, -1.055d-03,
     . -1.067d-04, -1.130d-04, +2.124d-05, +0.000d+00, -3.129d-01,
     . +8.463d-03, +2.253d-04, +7.413d-05, -9.376d-05, -1.606d-06,
     . +2.060d-06, +0.000d+00, +2.739d-01, +1.167d-03, -2.246d-05,
     . -1.287d-04, -2.438d-05, -7.561d-07, +1.158d-06, +4.950d-08,
     . +0.000d+00, -1.344d-01, +5.342d-03, +3.775d-04, -6.756d-05,
     . -1.686d-06, -1.184d-06, +2.768d-07, +2.730d-08, +5.700d-09/
       
      data (aw_amp(i),i=1,55)/
     . +1.023d-01, -2.695d+00, +3.417d-01, -1.405d-01, +3.175d-01,
     . +2.116d-01, +3.536d+00, -1.505d-01, -1.660d-02, +2.967d-02,
     . +3.819d-01, -1.695d-01, -7.444d-02, +7.409d-03, -6.262d-03,
     . -1.836d+00, -1.759d-02, -6.256d-02, -2.371d-03, +7.947d-04,
     . +1.501d-04, -8.603d-01, -1.360d-01, -3.629d-02, -3.706d-03,
     . -2.976d-04, +1.857d-05, +3.021d-05, +2.248d+00, -1.178d-01,
     . +1.255d-02, +1.134d-03, -2.161d-04, -5.817d-06, +8.836d-07,
     . -1.769d-07, +7.313d-01, -1.188d-01, +1.145d-02, +1.011d-03,
     . +1.083d-04, +2.570d-06, -2.140d-06, -5.710d-08, +2.000d-08,
     . -1.632d+00, -6.948d-03, -3.893d-03, +8.592d-04, +7.577d-05,
     . +4.539d-06, -3.852d-07, -2.213d-07, -1.370d-08, +5.800d-09/
       
      data (bw_amp(i),i=1,55)/
     . +0.000d+00, +0.000d+00, -8.865d-02, +0.000d+00, -4.309d-01,
     . +6.340d-02, +0.000d+00, +1.162d-01, +6.176d-02, -4.234d-03,
     . +0.000d+00, +2.530d-01, +4.017d-02, -6.204d-03, +4.977d-03,
     . +0.000d+00, -1.737d-01, -5.638d-03, +1.488d-04, +4.857d-04,
     . -1.809d-04, +0.000d+00, -1.514d-01, -1.685d-02, +5.333d-03,
     . -7.611d-05, +2.394d-05, +8.195d-06, +0.000d+00, +9.326d-02,
     . -1.275d-02, -3.071d-04, +5.374d-05, -3.391d-05, -7.436d-06,
     . +6.747d-07, +0.000d+00, -8.637d-02, -3.807d-03, -6.833d-04,
     . -3.861d-05, -2.268d-05, +1.454d-06, +3.860d-07, -1.068d-07,
     . +0.000d+00, -2.658d-02, -1.947d-03, +7.131d-04, -3.506d-05,
     . +1.885d-07, +5.792d-07, +3.990d-08, +2.000d-08, -5.700d-09/

C     parameter t
      t = dsin(dlat)

C     degree n and order m
      n = 9
      m = 9

C determine n!  (faktorielle)  moved by 1
      dfac(1) = 1
      do i = 1,(2*n + 1)
        dfac(i+1) = dfac(i)*i
      end do

C     determine Legendre functions (Heiskanen and Moritz, Physical Geodesy, 1967, eq. 1-62)
      do i = 0,n
        do j = 0,min(i,m)
          ir = int((i - j)/2)
          sum = 0
          do k = 0,ir
            sum = sum + (-1)**k*dfac(2*i - 2*k + 1)/dfac(k + 1)/
     .       dfac(i - k + 1)/dfac(i - j - 2*k + 1)*t**(i - j - 2*k)
          end do
C         Legendre functions moved by 1
          P(i + 1,j + 1) = 1.d0/2**i*dsqrt((1 - t**2)**(j))*sum
        end do
      end do

C     spherical harmonics
      i = 0
      do n = 0,9
        do m = 0,n
          i = i + 1
          aP(i) = P(n+1,m+1)*dcos(m*dlon)
          bP(i) = P(n+1,m+1)*dsin(m*dlon)
        end do
      end do

C     hydrostatic
      bh = 0.0029
      c0h = 0.062
      if (dlat.lt.0) then ! southern hemisphere
        phh  = pi
        c11h = 0.007
        c10h = 0.002
      else                ! northern hemisphere
        phh  = 0
        c11h = 0.005
        c10h = 0.001
      end if
      ch = c0h + ((dcos(doy/365.25d0*2*pi + phh)+1)*c11h/2 + c10h)*
     .           (1-dcos(dlat))

      ahm = 0.d0
      aha = 0.d0
      do i = 1,55
        ahm = ahm + (ah_mean(i)*aP(i) + bh_mean(i)*bP(i))*1d-5
        aha = aha + (ah_amp(i) *aP(i) + bh_amp(i) *bP(i))*1d-5
      end do
      ah  = ahm + aha*dcos(doy/365.25d0*2.d0*pi)

      sine   = dsin(pi/2 - zd)
      beta   = bh/( sine + ch  )
      gamma  = ah/( sine + beta)
      topcon = (1.d0 + ah/(1.d0 + bh/(1.d0 + ch)))
      gmfh   = topcon/(sine+gamma)
cd      print *,'GMF ahm aha ah sine beta gamma topcon gmfh '
cd     .           , ahm,aha,ah,sine,beta,gamma,topcon,gmfh

C     height correction for hydrostatic mapping function from Niell (1996)
      a_ht = 2.53d-5
      b_ht = 5.49d-3
      c_ht = 1.14d-3
      hs_km  = dhgt/1000.d0
C
      beta   = b_ht/( sine + c_ht )
      gamma  = a_ht/( sine + beta)
      topcon = (1.d0 + a_ht/(1.d0 + b_ht/(1.d0 + c_ht)))
      ht_corr_coef = 1/sine - topcon/(sine + gamma)
      ht_corr      = ht_corr_coef * hs_km
      gmfh         = gmfh + ht_corr      
cd      print *,'GMF ht_corr gmfh ',ht_corr,gmfh

C     wet
      bw = 0.00146
      cw = 0.04391

      awm = 0.d0
      awa = 0.d0
      do i = 1,55
        awm = awm + (aw_mean(i)*aP(i) + bw_mean(i)*bP(i))*1d-5
        awa = awa + (aw_amp(i) *aP(i) + bw_amp(i) *bP(i))*1d-5
      end do
      aw =  awm + awa*dcos(doy/365.25d0*2*pi)

      beta   = bw/( sine + cw )
      gamma  = aw/( sine + beta)
      topcon = (1.d0 + aw/(1.d0 + bw/(1.d0 + cw)))
      gmfw   = topcon/(sine+gamma)
      
      end 
