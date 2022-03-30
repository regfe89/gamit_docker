 
*---------------------------------------------------------------------
*                                                     CONST_PARAM.FTNI
*     This include file gives all of the constants which are used
*     in the Kalman filter processing software.
*
*     T.Herring                   12:41 PM  TUE., 13  JAN., 1987
*     Modified by R. King to move SV frequency info to libraries/includes/freq_def.h  
*     and kf/ctogobs/ctogobs_com.h
*---------------------------------------------------------------------
 
 
*   earth_flat  - Earth's flattening
*   earth_rad   - Equatorial radius of the Earth (m) -- Also the
*               - semi-major-axis of the ellipsoid.
*   earth_to_moon   - Mass ratio of earth and moom
*   g_earth     - Gravitional acceleration at the equator (m/s**2)
*   GM_moon     - GM for moon
*   GM_sun      - GM for sun
*   GM_earth    - GM for Earth 
*   G_univ      - Gravitional constant
*   pi          - PI
*   rad_to_deg  - Conversion from radians to degs.
*   rad_to_mas  - Conversion from radians to milliarcsecs.
*   sec_per_day - Number of seconds in 24 hours
*   vel_light   - speed of light in m/s
*   vel_light_km - speed of light in km/s
*   DJ2000      - Julian date of J2000
*   sec360      - number of seconds in 360 degreees.
*   solar_to_sidereal   - Conversion from solar days to sidereal
*                       - days (at J2000)

      real*8 earth_flat, earth_rad, earth_to_moon, g_earth, 
     .    GM_earth, GM_moon, GM_sun, G_univ,
     .    pi, rad_to_deg, rad_to_mas, sec_per_day,
     .    vel_light, vel_light_km, DJ2000, sec360, solar_to_sidereal
 
*     Values for the parameters
 
C     parameter ( earth_flat    = 0.003352891869D0     )
*                                                        ! m
C     parameter ( earth_rad     = 6378145.D0           )

* WGS-84 parameters for the elliposoid (a and 1/f)
      parameter ( earth_rad     = 6378137.D0           )
      parameter ( earth_flat    = 1.d0/298.257222101d0 )

      parameter ( earth_to_moon = 81.30065918D0        )
*                                                        ! m/sec**2
      parameter ( g_earth       =  9.780318458D0       )
*                                                        ! m**3/sec**2
      parameter ( GM_moon       = 0.49027975D+13       )
*                                                        ! m**3/sec**2
      parameter ( GM_sun        = 0.132712499D+21      )
*                                                        ! m**3/sec**2
* IERS Value 3.986004418d+14; solve value 3.9860346D+14
*     parameter ( GM_earth      = 3.986004418d+14      )
*                                                        ! m**2/(kg sec**2)
* IERS 2010 value from gamit/arc/egm08:
      parameter ( GM_earth      = 3.986004415d+14      )
*                                                        ! m**2/(kg sec**2) 
      parameter ( G_univ        = 0.66732D-10          )
      parameter ( pi            = 3.1415926535897932D0 )
      parameter ( sec_per_day   = 86400.D0             )
*                                                        ! m/s
      parameter ( sec360            = 1296000.d0       )
      parameter ( vel_light     = 299792458.D0         )    
      parameter ( vel_light_km  = 299792.458D0         )

*                                                        ! Julian days
      parameter ( DJ2000        = 2451545.d0           )

      parameter ( solar_to_sidereal = 1.002737909d0 )

*     Computed quantities
 
      parameter ( rad_to_deg    = 180.d0   /pi         )
      parameter ( rad_to_mas    = 648000.d3/pi         )


