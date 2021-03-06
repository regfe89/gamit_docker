 
*     This include file is the main control part of the GLOBK
*     common.  This part of the common is available in the root
*     of GLFOR and GLBAK (the forward and back filter programs).
*     The second part of the common is globk_markov.ftni and
*     is available only in the roots of the filter program.  This
*     procedure is used to gain space in the filter sections of
*     code.
*
*                                     09:16 PM TUE., 21 Jul., 1987

* MOD TAH 950106: Extended pmu_est variable to allow specification
*     of individual components that were or were not estimated.
*    (Changed variable from logical to bit mapped integer)

* MOD TAH 960905: Added new command to set the maxiumum chi**2 increment
*     allowed during the solutions. New command MAX_CHII.

* MOD TAH 961127: Added new command for:
*     (a) max_prefit_error (replaces hard wired value)
*     (b) translation converted to offset and rate in XYZ
*     (c) scale and rate allowed as new parameter type
*     (d) glorg prt option and command file name allowed so that
*         glorg can be run inside globk.
*     (e) Allowed use_num command to set number of times a site
*         needs to be used.
*     Number of commands increased to accommadate these additional 
*     parameters.
* MOD TAH 961220: Added new command for:
*     (a) Not allowing a direct copy of the covariance matrix.
*         (For some applications we do not want to allow this
*          feature in the cases of large rotations in the solution).

* MOD TAH 961223: Added version information

* curr_glb_com_ver - Current version of common file
* MOD TAH 981020: Changed version from 412 to 500 for new globk with
*      multiple polar motion/ut1 parameters and satellite antenna 
*      offsets.
* MOD TAH 991110: Changed version to 502 to reflect the inclusion of
*      non-secular position parameters (offsets, exponentials, periodic
*      and logarithmic) and the introduction of site downweighting
* MOD TAH 000902: Changed version to 503 to reflect the inclusion of
*      the site sigma downweigthing feature.
* MOD TAH 010526: Changed version to 504 because of increased max_rn
* MOD TAH 010916: Changed version to 505 because of increaded number 
*      of sites (max_glb_sites)
* MOD TAH 020603: Could have changed version to 506 but left as 505
*      since uni_wght added to end of common
* MOD TAH 030603: Added log estimate to post-earthquake model.  Version
*      changed to 506. Added decimation factors, command option, and
*      output global file option.
* MOD TAH 040220: Fixed problem with wild cards in mar_neu, added SMAR reporting
*      of RW process. Fixed some bugs with satellite antenna offsets.
* MOD TAH 040703: Increased version to 507 with the addition of atmospheric
*      delay parameters
* MOD TAH 040801: Increased version to 508 with changes to integer*8 to support
*      64-bit memory allocation
* MOD TAH 050524: Added del_scratch (invoked with DEL_SCRA command) to
*      delete com_file, sol_file and srt_file at end of run.  (Useful for
*      parallel runs where these files are given .gdl names).
* MOD TAH 050622: Added Model names cspeopmod, cetidemod,
*      cotidemod, coatmlmod, catmtdmod, chydromod and gload_mod (bit mapped)
*      Not major rearrangements so version can be left at 508.
* MOD TAH 060502: Increased dimensions for stations and parameters 509 new version
* MOD TAH 090930: Increased max_eq, and added multiple earthquake files. Make 510 version
* MOD TAH 101015: Increaded gant_mod to 16 characters to allow full name (was C*4) and
*                 increased qrecv_ty (htoglb_comm) and grecv_ty (globk_cntl.h) to C*20
*                 Makes 511 version.
* MOD TAH 120714: Loading models to be applied or removed.  1-word used. 
*      Small change so version not changed.  Added at end.
* MOD TAH 130716: Added mar_scale white noise term (mar_scale(2)-> mar_scale(3)
* MOD TAH 131106: Increased max_rn to 655536 and made version 513 of com_file
* MOD TAH 140809: Increased max_glb_parn/mar; added apr_val_site sigma
* MOD TAH 161128: Increased max_rn and max_ss. (version 514 to 515).
* MOD TAH 190610: Implemented new ECOMC coding (version 515 to 516, only warning for
*                 515 versions since only satellite rad model effected).

       integer*4 curr_glb_com_ver
       parameter ( curr_glb_com_ver = 516 )
 
*   glb_com_default - Default name for the GLOBK common file
*   glb_sort_default- Default name for the file containing the
*                   - time sorted list of experiments to be
*                   - processed.
*   glb_sol_default - Default name for the temporary file in which
*                   - GLOBK stores the covariance matrix and solution
*                   - vector.  Similar to the SOLFILE in SOLVK.
 
      character*(*) glb_com_default, glb_sort_default, glb_sol_default
 
      parameter ( glb_com_default  = 'GLBCOM.BIN' )
      parameter ( glb_sort_default = 'GLBSOR.BIN' )
      parameter ( glb_sol_default  = 'GLBSOL.BIN' )
 
 
*   glb_com_dcb(16) - DCB buffer for the common file
*   glb_control     - First word of the control block
*   gnum_control_sec- Number of blocks in the control section
*   gnum_markov_sec - Number of blocks in the markov section
*   gnum_ema_sec    - Number of blocks in the ema section
*   grec_markov_sec - First record of the markov section
*   grec_ema_sec    - First record of the ema section
 
      integer*4 glb_com_dcb(16), glb_control, gnum_control_sec,
     .    gnum_markov_sec, gnum_ema_sec, grec_markov_sec, grec_ema_sec
     
*   glb_com_ver     - Version of the globk common file.  (Updated
*                     eachtime the commonfile is changed.
*   glb_out_opt     - Output global file options.  Bits turned on to
*                     no output certain parameters:
*                     1 - Site position and velocity
*                     2 - EOP parameters
*                     3 - Orbit parameters

      integer*4 glb_com_ver, glb_out_opt

 
*   compute_glb_res - Indicates that we should compute the postfit
*                   - residuals to the input parameters during a
*                   - back solution
*   glb_con_read    - Indicates the the first block of the control
*                   - section has been read
 
      logical compute_glb_res, glb_con_read
 
*   glb_com_file    - Name of the GLOBK common file.
*   glb_prt_file    - Name of the printy output file (may be 6)
*   glb_log_file    - Name of the log file for output (may be 6)
*   nut_inp_file    - Name of the nutation series input file
*   plan_inp_file   - Name of the Planetary series input file
*   pmu_inp_file    - Name of the polar motion ut1 direct access input file
*   sd_inp_file     - Name of the semi-diurnal rotation file.
*   eq_inp_file(max_eq_files)  - Name of the file with the list of 
*                     earthquakes and site re-names in it.
*   glr_cmd_file    - Name of glorg_command file (involves running glorg)
*   glb_org_file    - Name of glorg output file (if not specified then
*                     the print file name is modified by replacing extent
*                     org).
*   glr_sol_file    - Name of solution file to written in glorg.  Default
*                     if blank (no output)

      character*128 glb_com_file, glb_prt_file, glb_log_file,
     .              eq_inp_file(max_eqfiles)
      character*128 nut_inp_file, plan_inp_file, pmu_inp_file,
     .              sd_inp_file,  glr_cmd_file,  glb_org_file,
     .              glr_sol_file
 
*   crt_unit    - User's Lu number
*   cnum_used   - Gives the number of parameters actually used
*               - from the current solution (The other non-estimated
*               - parameters are compressed from solution)
*   gnum_sites  - Number of sites in this global
*   gnum_soln_recs  - Number of soln records which were used in this
*                   - solution.  Count includes any combination records.
*   gnum_comb       - Number of combined solution records in this analysis.
*   gnum_sources    - Number of sources in this solution
*   gnum_svs        - Number of SVS in this solution 
*   gpar_codes(max_glb_parn)    - Gives the codes for the parameters
*               - read from the current solution
*   ind_mar(max_glb_mar) - Indicates which parameters are
*               - markov in this solution
*   indx_pnt(max_glb_parn)  - Gives number of partial derivatives
*               - for the global parameters for each of the local
*               - parameters in the current solution
*   log_unit    - Log device (Puts out one line summary per
*               - experiment)
*   max_glb_deriv   - Maximum number of global parameters which
*               - a local parametercan depend on (computed for
*               - each local solution)
*   num_glb_mar - Actual number of markov global parameters
*   num_glb_parn- Number of global parameters being estimated
*   num_glb_sol - Number of experiments to be included in this
*               - global solution.
*   num_expt    - Number of experiments in this solution
*   num_trans_col   - Number of parameters with used in state
*               - transissions.
*   num_trans_row   - Number of parameters affected by state
*               - transissions.
*   prt_unit    - Print device
*   trans_col(max_trans_col)   - Gives the parameters
*               - numbers of those parameters in the state
*               - transition matrix.  These are used mainly for the
*               - updating the seasonal terms for the wobble,
*               - UT1 and nutations
*   trans_row(3, max_trans_row)  - Gives the row number for each of the
*               - lines in trans_col, start position in trans_col and
*               - the number of values to be used from trans_col
*   num_mar_svs - Number of parameters which have time dependent
*                 markov statistics being applied for this experiment.
*   parn_mar_svs(max_svs_elem*max_glb_svs) - Parameter numbers of the orbital elements
*                 that were read from svs_mar_file.
*   type_svs_elem - Bit mapped word which tells the type of satellite orbital
*                 elements available
*   times_used(max_glb_sites)   - Variable that keeps counter of the
*                 number of times a site has been used.  Used to remove
*                 site names that are not used due to renaming and 
*                 earthquakes.  Should be cleared before the start
*                 of calls to rw_names_block.
*   gapr_updated(max_glb_site_wrds) - Bit mapped word to indicates that
*                 the site coordinates for a given site have been 
*                 updated.  Used as a check and to automatically 
*                 update rename sites and earthquake sites.
*   rn_name_changed(max_glb_site_wrds) - Bit mapped word that has bit
*                 set when the name is changed when global read.  Used
*                 so that any position change is applied to only 
*                 sites with name changes
*   bak_out_site(max_glb_site_wrds) - Bit mapped word that sets which
*                 sites will be written to bak file.  The array is a 
*                 combination of user defined and defaults values.
*                 If a CLEAR is used in selecting sites these will be
*                 the only sites output.
*   decnum  -- Decimation number (1-process every experiment, 2-every second
*              and so on)
*   decoff  -- Offset for decimation (1-start at first, 2 start at second etc).
 
      integer*4 crt_unit, cnum_used, gnum_sites, gnum_soln_recs,
     .    gnum_comb, gnum_sources, gnum_svs, 
     .    gpar_codes(max_glb_parn), ind_mar(max_glb_mar),
     .    indx_pnt(max_glb_parn), log_unit, max_glb_deriv, num_glb_mar,
     .    num_glb_parn, num_glb_sol, num_expt, num_trans_col,
     .    num_trans_row, prt_unit, trans_col(max_trans_col),
     .    trans_row(3, max_trans_row), num_mar_svs, 
     .    parn_mar_svs(max_svs_elem*max_glb_svs),  type_svs_elem,
     .    times_used(max_glb_sites),
     .    gapr_updated(max_glb_site_wrds), 
     .    rn_name_changed(max_glb_site_wrds),
     .    bak_out_site(max_glb_site_wrds), decnum, decoff

* Added for full dynamic memory

*   most_cparn_num - Largest number of local parameters encountered
*                    (used to set the size of memory needed)

      integer*4 most_cparn_num
 
*   gdelete_count(max_edit_types)  - Sum of all of the delete_counts
*               - for this solution
*   gnum_obs    - Total number of observations in this solution
*   istart_vma      - Address at the start of ema_data array
*   icov_sav_parm   - Start of matrix cov_sav_parm
*   isol_sav_parm   - Start of array  sol_sav_parm
*   ijmat           - Start of matrix jmat
*   icov_parm       - Start of matrix cov_parm
*   isol_parm       - Start of array  sol_parm
*   irow_copy       - Start of array row_copy (used for transissions)
*   ipart_pnt       - Start of matrix part_pnt
*   ia_part         - Start of matrix a_part
*   itemp_gain      - Start of matrix temp_gain
*   ikgain          - Start of matrix kgain
*   icov_obs        - Start of matrix cov_obs
*   isol_obs        - Start of matrix sol_obs
 
      integer*4 gdelete_count(max_edit_types), gnum_obs
      integer*4 dum4  ! Dummy 4-bytes to get integer*8 alligned
      integer*8 istart_vma, icov_sav_parm,
     .    isol_sav_parm, ijmat, icov_parm, isol_parm, irow_copy,
     .    ipart_pnt, ia_part, itemp_gain, ikgain, icov_obs, isol_obs
     
* MOD TAH 950824: New variables to support the GAMIT new orbital 
*     elements, SINEX file generation.

*    ns_by_sol(max_glb_sol)  -  Number of stations in each of the solutions
*                 in the binary hfiles.  This list is for all experiments
*                 even those that have been combined into a single
*                 global file.  This array is set by glinit.
*    gnum_off_diag  -  Number of off-diagonal elements need to write
*                 apriori constraint matrix (these are for NEU constraints).

      integer*4   ns_by_sol(max_glb_sol), gnum_off_diag

* MOD TAH 030607: Added command option.  Commands with string at beginning
*     of lines will be execuated (option passed in runstring).

      character*16 comopt_old
      character*256 comopt  ! Allowed + structure in comopt 
                            ! (i.e., OPT1+OPT2+OPT3)


*-----------------------------------------
* Earthquake and re-name variables
*-----------------------------------------
*   num_eq          - Number of earthquakes
*   num_eqfiles     - Number of earthquake files
*   num_renames     - Number of site renames

      integer*4 num_eq, num_eqfiles, num_renames

*   eq_pos(3,max_eq) - Cartesian position of each earthquake (m)
*   eq_rad(max_eq)   - Radius of influence of each earthquake (m)
*   eq_depth(max_eq) - Depth of Earthquake (used to scale the spatial
*                      dependent part of co-, pre- and post-seismic
*                      process noise (m).
*   eq_epoch(max_eq) - Epoch of each earthquake (Julian date)
*   eq_dur(2,max_eq) - Duration before and after earthquake for markov
*                      processes to be applied (only used if eq_mar_pre
*                      and eq_mar_post values set).  

*   eq_apr_coseismic(6,max_eq) - Apriori sigma of coseismic displacement
*                      in North, East and Up (m), and spatial dependent
*                      apriori sigma (NEU) (m at epicenter and formed
*                      as (d/l)**2 where l is distance and d is depth
*   eq_mar_pre(6,max_eq)       - Markov process noise to be applied before
*                      earthquake (m**2/yr for NEU) and spatial dependent
*                      value (m**2/yr for NEU scaled in the same fashion
*                      as the cosesimic function)
*   eq_mar_post(6,max_eq)      - Markov process noise to be applied after
*                      earthquake (m**2/yr for NEU) and spatial dependent
*                      value (m**2/yr for NEU scaled in the same fashion
*                      as the cosesimic function)
*   eq_log_sig(6,max_eq)  -- Apriori sigma on log estimates (m) constant 
*                      term (NEU) and (D/R)**2 dependent terms 
*   eq_log_tau(max_eq)    -- Time constant for log estimates (days)

      real*8 eq_pos(3,max_eq), eq_rad(max_eq), eq_depth(max_eq),
     .       eq_epoch(max_eq), eq_dur(2,max_eq), 
     .       eq_apr_coseismic(6,max_eq), eq_mar_pre(6,max_eq),
     .       eq_mar_post(6,max_eq), eq_log_sig(6,max_eq),
     .       eq_log_tau(max_eq)

* Site renaming arrays
*   rn_times(2, max_rn) - Epochs over which rename should occur (start and
*                      stop Julian dates)
*   rn_dpos(3, max_rn)  - dX,dY,dZ postion change for renamed site (added
*                      to the estimate (m)).

      real*8 rn_times(2, max_rn), rn_dpos(3, max_rn)

* Logicals
*   eq_co_applied(max_eq) - Set true when the cosemic process noise model
*                      applied for a given earthquake.
*   eq_rename(max_eq)       - Set true for each earthquake that will have
*                      the sites ranamed
*   eq_reset  -- Set true to reset extent back to _GPS

      logical eq_co_applied(max_eq), eq_rename(max_eq), eq_reset

* Character arrays

*   eq_codes(max_eq) - Two letter codes for each Earthquake (saved in a
*                      character*8 array for 32Bit manipulation)
*   rn_codes(2,max_rn) - Old and new station names.
*   rn_types(max_rn)   - Type of position change (XYZ/NEU)
* MOD TAH 971112:
*   rn_hfiles(max_rn)  - String to checked to see if glb_inp_file contains
*                        this string.  Restricted to 16 characters.

      character*8 eq_codes(max_eq), rn_codes(2,max_rn), rn_types(max_rn)
      character*16 rn_hfiles(max_rn)

*   num_apr_files   - Number of apriori coordinates files given.

      integer*4 num_apr_files

*---------------------------------------------------------
* New  variables for reference frames:

*   ggpst_utc  -  Time difference between GPST and UTC 
*   gcons_type -  Type of constraint used in this globk run. 
*                 Based on station constraints.  0--tight constraints;
*                 1--signficant constraint; 2--loose
*   gsys_type      - Type of system type used: Bit mapped
*                    1 -- VLBI
*                    2 -- GPS
*                    3 -- SLR
*   ggamit_mod -  Models used in GAMIT analysis.  Combination of
*                 E-tides (upper 16 bits) and E-Rot flags.  Mapping
*                 same as gamit:
*                 BIT Meaning
*                  1  Diurnal/Semidiurnal Pole
*                  2  Diurnal/Semidiurnal UT1
*                  3  Ray model used (IERS2003)
*                  4  IERS2010 model used 
*                 ...   
*                                                                                  GAMIT BIT                    
*                 17  Earth tides                                                          1
*                 18  Frequency dependence corrections                                     2
*                 19  Pole-tide                                                            3
*                 20  Ocean-loading corrections                                            4
*                 21  Mean Pole position removed from Pole tide                            5
*                     (MOD TAH 030131 to be consistent with IERS). 
*                 22  S1/S2 atm load "tide" applied                                        6
*                 23  IERS2010 Mean pole model used                                        7
*                 24  Ocean pole tide model applied: Applied to IERS96 mean pole           8
*                 25  Ocean pole tide model applied: Applied to IERS10 mean pole (150213)  9
* MOD TAH 200218: IERS20 mean-pole (now secular pole)
*                 26  IERS2020 Mean pole model used (200218)                              10
*                 27  Ocean pole tide model applied: Applied to IERS20 mean pole (200218) 11

      integer*4 ggpst_utc, gcons_type, gsys_type, ggamit_mod
      
*   ggframe    -  Frame used in gamit.
*   ggprec     -  Precesion constant system used in gamit
*   ggsrpmod   -  Solar radiation pressure model used in gamit
*   ggtime     -  Time system used in gamit
*   ggnut      - Nutation model used (Added 080103)
*   gggrav     - Gravity field
*   ggeradmod  - Earth-radiation model (Added 140327) 
*   ggantradmod  - Antenna-radiation mode (Added 140327) 
*   ggionsrc   - Source of ionospheric delay; if not NONE then 2nd order
*               ioncorrection has been applied (140403)
*   ggmagfield - Magnet field model used with 2nd order correction (140403)

*   ggdryzen   - Dry Zenith delay model (140403)
*   ggwetzen   - Wet Zenith delay model (140403)
*   ggdrymap   - Dry Mapping function (140403)
*   ggwetmap   - Wet Mapptng function (140403)


      character*8 ggframe, ggprec, ggsrpmod, ggtime, ggnut, gggrav,
     .            ggeradmod, ggantradmod, ggionsrc, ggmagfield

      character*4 ggdryzen, ggwetzen, ggdrymap, ggwetmap
       
       
*   glb_bak_soln    - Indicates that a bak solution is to be run
*   glb_glb_tides   - Indicates global tide estimates should be made
*                   - (only for h,l,lag.  Later may be replaced with
*                   - tide groupings of sites)
*   nut_ang_est     - Indicates if nutation angles or series compoents
*                   - have been estimated
*   pmu_est         - Indicates that PMU parameters have been estimated
*                     Changed to but mapped integer:  Allignment is
*                     1 - X wobble, 2 - Y wobble, 3 - UT1, 
*                     4 - Xrate,    5 - Y rate,   6 - UT1 rate.
*   tran_est        - Indicates transaltions estimated.  Mapping of
*                     value by bits is:
*                     1 - X;    2 - Y ;   3 - Z;
*                     4 - Xdot, 5 - Ydot; 6 - Zdot
* MOD TAH 030615: Bits also used to indicate that LOG functions have
*                     been estimated
*                     16 - N Log, 17 - Elog, 18 - U log
*   rot_est         - Indicates that rotations are estimated: Mapping
*                     of bits is:
*                     1 - Xrot;     2 - Yrot ;    3 - Zrot;
*                     4 - Xrot dot, 5 - Yrot dot; 6 - Zrot dot
*   scale_est       - Indicates that scale has been estimated.
*                     1 - Scale; 2 - Scale rate of change.
*   clear_bo_site   - Set true if defaults for outputs are not be invoked.
*   make_svs_file   - Set true if we are to make the svs file as we go.
 
      logical glb_bak_soln, glb_glb_tides, nut_ang_est, 
     .        clear_bo_site, make_svs_file

      integer*4 pmu_est, tran_est, scale_est, rot_est
 
*   cov_mar(max_glb_mar)    - Markov variances for each of the
*               - markov elements in the solution
*   cov_mar_svs(max_svs_elem*max_glb_svs) - Time dependenent markov statistis read
*                 from svs_mar_file.
*   cov_mar_neu(3,3,max_glb_sites) - Covariance matrix for the neu 
*                 markov process. (Only for RANDOM walk, not itegrated
*                 random walk).
*   cov_apr(max_glb_parn)   - Variances of the apriori estimates
*               - of each of the parameters
*   trans_coeff(max_trans_col) - Coefficients for the
*               - state transition matrix for each parameter
*               - pointed to in the transition array. 1.d0 is
*               - added to the coefficient if trans_col equal
*               - trans_row.
*   sum_chi     - Sum of  the chi**2 values for the solution
*   sum_chi_num - Number of values incremented in sum_chi
 
*   sum_loc_chi     - Increment to chi_squared for current solution
*   sum_post_chi    - Sum of chisquared for postfit solutions
*   sum_post_chi_num- NUmber fo values incremented in sum_post_chi
 
      real*4 cov_mar(max_glb_mar), cov_apr(max_glb_parn),
     .    cov_mar_svs(max_svs_elem*max_glb_svs), 
     .    cov_mar_neu(3,3,max_glb_sites),
     .    trans_coeff(max_trans_col), sum_chi, sum_chi_num,
     .    sum_loc_chi, sum_post_chi, sum_post_chi_num

*   max_chi_inc  - sets the maximum chi**2 increment allowed.
*   max_prefit_diff - Maximum allowable difference in prefit
*                  residuals before parameter is removed.
*   max_eop_rot  -  Maximum rotation allowed before removed apriori
*                   from the solutions (mas)
*   fillr4       -  Real*4 filler
      real*4  max_chi_inc, max_prefit_diff, max_eop_rot, fillr4 
      
*   deltat      - Time difference between current experiment and
*               - previous one (years)
*   deltaephem  - Change in time bewteen SVS ephemerides. (years)
 
      real*8 deltat, deltaephem

*   gexpt_title - Analysis title.  To be saved as a descriptor

      character*32 gexpt_title

*-----------------------------------------------------------------
*   no_direct_copy - Logical set true if we are not to allow
*     a direct copy of the input covaraince matrix.  (Aviods
*     problems when there are large rotations in the solution)

      logical  no_direct_copy

*-----------------------------------------------------------------
*   rn_used(max_rn_wrd) -- Bits set on to show that rename used
*   eq_used(max_eq_wrd) -- Bits set on to show that eq_used.

      integer*4 rn_used(max_rn_wrd), eq_used(max_eq_wrd)

* MOD TAH 980519: Added logical rad_reset to see if radiation
*     parameters should be reset at each each arc.

      logical rad_reset 

* MOD TAH 990226: Added logical old_irw to indicate that the
*     old IRW model should be used.  Default in 5.02 globk
*     is the new model
      logical old_irw

* MOD TAH 981020: New entries added to support extended orbit modeling
*     and multi-epoch pmu estimation. 

* num_mul_pmu  -- Block size of multiple pmu parameters (ie. number
*     of entries simultaneously estimated
* 
* mul_pmu_opt  -- Options for multi-pmu estimation
*     Bit  Meaning
*       1  Treat each set of values independent (apriori sigmas are 
*          applied, independently, to all values).  If not set, the
*          aprioris are applied to the first epoch and then the
*          correlated process noise are applied to other values.  IND option
*       2  If set then actual start epoch passed for multi-pmu estimates
*       3  Start_mul_pmu contains the number of days to offset from the
*          GPS week of the first experiment.
*       4  Ignore UT1 values in input files (NOUT option)
*       5  WARN user on non-included values (WARN option)
*       6  Propagate the mul_pmu_epochs if the current experiment falls
*          outside of range (PROP option)
* 
*      31  Set when ever we need to write out the mul_pmu values in
*          bak file.
*      32  Non-user option: Set each time the mul_pmu tabular points
*          are updated.
* mul_pmu_site(max_glb_site_wrds,max_mul_pmu) -- Bit mapped words
*     that record number of sites used for mul_pmu estimate
* mul_pmu_fidu(max_glb_site_wrds,max_mul_pmu) -- Bit mapped words
*     that record number of fiducial sites used for mul_pmu estimate
* mul_pmu_svs(max_mul_pmu) -- Satellites used for mul_pmu estimates

      integer*4 num_mul_pmu, mul_pmu_opt,
     .          mul_pmu_site(max_glb_site_wrds,max_mul_pmu),
     .          mul_pmu_fidu(max_glb_site_wrds,max_mul_pmu),
     .          mul_pmu_svs(max_mul_pmu)

* start_mul_pmu -- Start epoch of the multiple pmu values
* spacing_mul_pmu -- Spacing (days) of the multiday pmu values

      real*8 start_mul_pmu, spacing_mul_pmu

* Pole-tide application entries
* ptide_opt  -- Options for pole tide.
*     Bit   Meaning
*       1   Apply tide if not already applied.  ptide_hfs contains
*           sub-string names for hfiles where it is not clear if
*           pole tide has been applied 
* MOD TAH 140405: Added ocean pole tide options (set with +-opt
*       2   Apply ocean pole tide
* MOD TAH 200220: Make remove SE pole-tide an option as well
*       3   Remove Solid earth pole tide if applied.and we know status
*       4   Remove ocean pole tide if applied.
*       ...
* MOD TAH 200717: Added REP option
*      16   Report the changes in positions.
*
* num_ptide_hfs -- Number of entries in list of hfiles for pole tide

      integer*4 ptide_opt, num_ptide_hfs

* ptide_hfs(max_ptide_hfs) -- String that must appear hfile name if
*           pole tide is to be applied and it is not clear that it has
*           not been applied.  If no names are given, pole tide applied
*           to all hfiles.

      character*16 ptide_hfs(max_ptide_hfs)

* Tolerance parameters
* tol_mul_pmu  -- Tolerance (days) for match between epochs of estimated
*           multi-day polar motion and values in hfiles.  Should be kept
*           small because there is no changeing of apriori's currently
* tol_svs_eph  -- Tolerance on match to satellite orbit ephemeris epochs

      real*8 tol_mul_pmu, tol_svs_eph

* Entries for non-secular position changes
*-----------------------------------------
* num_nonsec -- Number of non-secular terms
* param_nonsec(2,max_nonsec) -- Gives the site number (1) and the
*     type of non-secular term.  The type defined are:
*     1 -- Offset and Rate change (applied after reference epoch)
*     2 -- Periodic (cosine and sine terms)
*     3 -- Exponential (exp(-t/tau))
*     4 -- Logarithmic (ln(1+t/tau))
*    >5    Not defined.

      integer*4 num_nonsec, param_nonsec(2,max_nonsec)

* Entries for sig_neu commands (ability to add noise to covariance
* matrix
* num_ss  -- Number of downweight entries (specified by site and
*     time-range

      integer*4 num_ss

* ss_times(2,max_ss) -- Start and stop Julian dates for the 
*     additional sigma to be added
      real*8 ss_times(2,max_ss)

* ss_sig(3,max_ss) -- Sigmas to be add to the NEU components (m)

      real*4 ss_sig(3,max_ss)

* ss_hfiles(max_ss) -- Codes for strings that must apper in hfile name
* ss_codes(max_ss)  -- Site codes for site sigma (may be beginning of
*     name (all strings match with this being), or if @<string> is
*     used, end of name must match 

      character*16 ss_hfiles(max_ss)
      character*8  ss_codes(max_ss)

* uni_wght  -- Logical set true by default to weight stations by number
*     of times a site is used.  Only applied when span of data is 1 day.
* del_scratch -- Set true to delelte com, sol and srt files are ends of 
*     runs.

      logical uni_wght, del_scratch
* 
*-----------------------------------------------------------------
* New variables added TAH 050622: For model name copy
*
* gload_mod -- Model bits for loading models used

       integer*4 gload_mod

* gspeopmod -- Name of short period eop model          
* getidemod -- Name of earth tide model
* gotidemod -- Name of ocean tide model
* goatmlmod -- Name of atmospheric load model
* gatmtdmod -- Name of atmospheric tidal loading model
* ghydromod -- Name of hydroloading model.

      character*8 gspeopmod ,getidemod, gotidemod, goatmlmod, 
     .            gatmtdmod, ghydromod

* 
* appload_mod -- Bit mapped with loading models to be applied
*      Bits are:
*       1  -- Load model status specified by user.  Bit is set when
*             the APP_MODL command is used.  If command not used 
*             load status is left unchanged from input files.
*       2  -- Atm long period load
*       3  -- Hydrographic load
      integer*4 appload_mod

*-----------------------------------------------------------------
* MOD TAH 080724
* New variables added for name of reference frame.  Value is obtained
*   for +REFERENCE_FRAME <string> is apr files.  The last frame found
*   is the one output
      character*16 reference_frame

*------------------------------------------------------------------
* MOD TAH 180402: Added new use_PRN logical to use PRN names.
*    imitial default is true
      logical use_prnn 
 
*   last_glb_control   - Last word used to compute how large
*               - the common block is
*   glb_control_dummy(127)  - padding to ensure that we do over
*               - write any thing.
 
 
      integer*4 last_glb_control, glb_control_dummy(127)
 
*-----------------------------------------------------------------
*     Common Declaration
 
      common / glb_control_block / glb_com_dcb, glb_control,
     .    gnum_control_sec, gnum_markov_sec, gnum_ema_sec,
     .    grec_markov_sec, grec_ema_sec, 
     .    glb_com_ver, glb_out_opt,
     .    compute_glb_res, glb_con_read,
     .    glb_com_file, glb_prt_file, glb_log_file, eq_inp_file,
     .    nut_inp_file, plan_inp_file, pmu_inp_file, sd_inp_file,
     .    glr_cmd_file, glb_org_file, glr_sol_file,
     .    crt_unit, cnum_used, gnum_sites,
     .    gnum_soln_recs, gnum_comb, gnum_sources, gnum_svs, 
     .    gpar_codes, ind_mar, indx_pnt,
     .    log_unit, max_glb_deriv, num_glb_mar, num_glb_parn,
     .    num_glb_sol, num_expt, num_trans_col, num_trans_row,
     .    prt_unit, trans_col, trans_row, gdelete_count, gnum_obs,
     .    num_mar_svs, parn_mar_svs,  type_svs_elem, ns_by_sol,
     .    gnum_off_diag,
     .    icov_sav_parm, isol_sav_parm, ijmat, icov_parm, isol_parm,
     .    irow_copy, ipart_pnt, ia_part, itemp_gain, ikgain, icov_obs,
     .    isol_obs,  
     .    glb_bak_soln, glb_glb_tides, nut_ang_est, 
     .    pmu_est, tran_est, scale_est, rot_est,
     .    cov_mar, cov_apr, cov_mar_svs, cov_mar_neu,
     .    trans_coeff, sum_chi, sum_chi_num,
     .    sum_loc_chi, sum_post_chi, sum_post_chi_num, 
     .    max_chi_inc, max_prefit_diff, max_eop_rot, fillr4,
     .    deltat, deltaephem,
     .    eq_pos, eq_rad, eq_depth, eq_epoch, eq_dur, 
     .    eq_apr_coseismic, eq_mar_pre, eq_mar_post, 
     .    eq_log_sig, eq_log_tau, 
     .    rn_times, rn_dpos, ss_times, spacing_mul_pmu, 
     .    start_mul_pmu,  tol_mul_pmu, tol_svs_eph,
                       
     .    num_eq, num_eqfiles, num_renames, eq_co_applied,
     .    eq_rename, eq_reset, most_cparn_num, times_used,
     .    gapr_updated,rn_name_changed, bak_out_site, 
     .    decoff, decnum, clear_bo_site, 
     .    make_svs_file,num_apr_files, istart_vma, 
     .    ggpst_utc, gcons_type, gsys_type, ggamit_mod,
     .    ptide_opt, num_ptide_hfs, 
     .    mul_pmu_opt, num_mul_pmu,
     .    mul_pmu_site,  mul_pmu_fidu, mul_pmu_svs,
     .    num_nonsec, param_nonsec, num_ss, ss_sig,

     .    eq_codes, rn_codes, rn_types,
     .    ggframe, ggprec, ggsrpmod, ggtime,
     .    gexpt_title, ptide_hfs,

     .    no_direct_copy, rn_used, eq_used, rn_hfiles,
     .    rad_reset, old_irw, ss_hfiles, ss_codes, uni_wght,

     .    comopt_old, del_scratch, gload_mod,
     .    gspeopmod ,getidemod, gotidemod, goatmlmod, 
     .    gatmtdmod, ghydromod, ggnut, gggrav, 
     .    reference_frame,comopt, appload_mod, 
     .    ggeradmod, ggantradmod, ggionsrc, ggmagfield, 
     .    ggdryzen, ggwetzen, ggdrymap, ggwetmap,
     .    use_prnn,  

     .    last_glb_control, glb_control_dummy

 
*-----------------------------------------------------------------
* NOTE: This part of the common block is not written to disk.
*
*     Include file to define the station information to be included
*     in version 1.0 global files.

*     gdata_st  - Start JD for the data in this solution for this
*                  site.  This nee
*     gdata_en  - End JD for the data in this solution.

*     grecv_st  - Start JD for the receiver characteristics (not
*                  the data spanned in this solution)
*     grecv_en  - End JD for  receiver characteristics
*     gante_st  - Start JD for the antenna characteristics (not
*                  the data spanned in this solution) 
*     gante_en  - End JD for antenna characteristics

      real*8 gdata_st(max_glb_sites), gdata_en(max_glb_sites),
     .       grecv_st(max_glb_sites), grecv_en(max_glb_sites), 
     .       gante_st(max_glb_sites), gante_en(max_glb_sites)
 
*      garp_ecc(3) - Single station eccentricity of the
*           - antenna with respect ground mark
*           - (NEU m)
*     gL1a_ecc(3)  - L1 phase center to ARP (NEU m).
*     gL2a_ecc(3)  - L2 phase center to ARP (NEU m).
*     gelev_cut    - Elevation cutoff angle (rads)

 
      real*4 garp_ecc(3,max_glb_sites), gL1a_ecc(3,max_glb_sites), 
     .       gL2a_ecc(3,max_glb_sites), gelev_cut(max_glb_sites)

* MOD TAH 202005: Added antenna azimuth
      real*4 gantdaz(max_glb_sites) ! Antenna aligment from True N (deg). 
                      

*         gnum_zen - Number of zenith delay parameters
 
      integer*4 gnum_zen(max_glb_sites)
 
*           gant_mod   - Antenna model used for this station
* MOD TAH 101015: Increased length of C*16 (was C*4)
 
      character*16 gant_mod(max_glb_sites)
 
*           gcode  - 8 character code name for station.  This
*           - needs to match the gsite_names array.
*   gante_sn   - Antenna serial number (----- if not known)
*   grecv_sn   - Serial number for the receiver (----- if
*           - not known)
 
      character*8 gcode(max_glb_sites), gante_sn(max_glb_sites), 
     .            grecv_sn(max_glb_sites)
 
*   grecv_ty   - Type of receiver (increased to C*20 in Ver 5.11)
*   gante_ty   - Antenna type
*   grecv_fw   - Firm ware version for the receiver.
      character*20 grecv_ty(max_glb_sites) 
      character*16 gante_ty(max_glb_sites), 
     .             grecv_fw(max_glb_sites)
*   gradome_ty - Type of radome
      character*4 gradome_ty(max_glb_sites)
     
* MOD TAH 980519: Added dchi_save to save the Prefit chi**2 change
*     so that it can be written to the srt_file.
* MOD TAH 190620: Added for_chi_save and bak_chi_save for use
*     when glsave writes GLX files during back solution. 

      real*4 dchi_save, for_chi_save, bak_chi_save

* MOD TAH 050622: Added load contributions for sites
*   gatmload(3) -- Average daily load applied at this site (NEU mm)
*   ghydload(3) -- Average hydrographic load (NEU mm)

       real*4 gatmload(3,max_glb_sites),  ghydload(3,max_glb_sites)
 

*------------------------------------------------------------------------
*  Entries needed to support multiple pmu entries.  These values are
*  not written to disk (only needed locally with in each of the major
*  program blocks in globk

*  cnum_mul_pmu(2,3) -- Number of multi-pmu values in the current
*     h-file being read
*  cmul_pmu_ep(2*3*max_mul_pmu) -- The epochs of the pmu values read from
*     the hfile
*  cmul_pmu_apr(2,3,max_mul_pmu) -- Values for apriori values of multi-day
*     polar motion values

      real*8 cmul_pmu_ep(2*3*max_mul_pmu), cmul_pmu_apr(2,3,max_mul_pmu)
      integer*4 cnum_mul_pmu(2,3) 

      common / glb_mul / cmul_pmu_ep, cmul_pmu_apr,
     .      cnum_mul_pmu
 
*-------------------------------------------------------------------------
 
      common / gsinf_com / gdata_st, gdata_en, grecv_st, grecv_en, 
     .       gante_st, gante_en,
     .       garp_ecc, gL1a_ecc, gL2a_ecc, gantdaz, gelev_cut,
     .       gnum_zen, gant_mod, gcode, gante_sn, grecv_sn,
     .       grecv_ty, gante_ty, grecv_fw, gradome_ty,
     .       gatmload, ghydload
     
      common / dchi_com / dchi_save, for_chi_save, bak_chi_save

*--------------------------------------------------------------------------
* num_nonsec_types -- Number of non-secular types
      integer*4 num_nonsec_types

      parameter ( num_nonsec_types = 4 )

* cont_nonsec(3,max_glb_sites) -- Contributions of the non-secular
*     terms at the epoch output

      real*8 cont_nonsec(3,max_glb_sites)

* nonsec_types(num_nonsec_types) -- Names of the non secular types
      character*8 nonsec_types(num_nonsec_types)

      common / gnosec_def / cont_nonsec, nonsec_types
      
*-----------------------------------------------------------------------
* MOD TAH 050622: Added block for satellite information
*
      integer*4 gsvi_prn(max_glb_svs)    ! PRNs of saved entries
     .,         gsvi_svn(max_glb_svs)    ! SV number
     .,         gsvi_block(max_glb_svs)  ! Block number

      real*8 gsvi_antpos(3,2,max_glb_svs)  ! Antenna positions read from input files
      real*8 gsvi_launch(max_glb_svs)      ! Launch date for satellite
      character*16 gsvi_antmod(max_glb_svs)  ! Antenna model for each satellite (SINEX
                                         ! only need 10 charcaters in name)
      character*4 gsvi_ocode(max_glb_svs)  ! Codes for satellites. 
                                         ! 1/2 Frequencues; A/R and E/F

      common / gsvinf_com / gsvi_prn, gsvi_svn, gsvi_block
     .,      gsvi_antpos, gsvi_launch, gsvi_antmod, gsvi_ocode

*------------------------------------------------------------------------
* MOD TAH 190624: Added saved MJD for wild_date command use
* MOD TAH 190624: Added wild_mjd as mid-point MJD for use in
*     wild_date
      real*8 wild_mjd   ! Mid-point MJD for wild_date 

      common / wild / wild_mjd


*------------------------------------------------------------------------
* MOD TAH 20020: Added mean/secular pole name.  (Information is encoded
*     into gamit_mod variables. This name is used for convenience
      character*8 mean_pole_def  ! Definition on mean/secular pole.
                ! Values IERS96, IERS10, IERS20.
      logical ptd_updated  ! Set true when pole-tide updated and ggamit_mod
                ! should be changed

      common / MP_Def / ptd_updated, mean_pole_def


