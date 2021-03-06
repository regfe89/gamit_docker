*      Declarations for mstinf program  

* This version for mstinf2 (new format March 2002)
* Constructed for new format by rwk from tah original

* PARAMETERS
* max_str        -- Maximum number of records allowed in station.info
* max_stf        -- Maximum number of files than can be merged
*  The following three limited to 1 in current version:
* max_rxf        -- Maximum number of RINEX files than can be merged   
* max_igf       -- Maximum number of IGS log files than can be merged
* max_sxf       -- Maximum number of SINEX files than can be merged
* max_log       -- Maximum number of entires in an IGS site log file or
*                    for a single site in a GIPSY stacov file
* max_comments   -- Maximum number of comments that can be saved
* max_site       -- Maximum number of stations allowed    
* max_snx_site   -- Maximum number of sites on an IGS log file

      integer*4 max_str, max_stf, max_rxf, max_igf, max_sxf
     .        , max_comments, max_site, max_snx_site, max_log

      parameter ( max_str = 70000 )
      parameter ( max_stf = 100 )
      parameter ( max_rxf = 10 )   
      parameter ( max_igf = 100 )  
      parameter ( max_sxf = 10  )
      parameter ( max_comments   = 5000 )
      parameter ( max_site = 30000 ) 
      parameter ( max_snx_site = 1000 )
      parameter ( max_log = 1000 ) 

* DECLARATIONS
* num_str    -- number of records allowed in station.info
* num_stf    -- number of files that can be merged
* num_rxf    -- number of RINEX files that can be merged 
* num_igf    ---number of IGS log files that can be merged 
* num_sxf    ---number of SINEX files that can be merged
* num_comments -- Number of comments in station.info
* num_ref    -- Number of entries in reference station.info
* num_site   -- Number of sites in station.info
* num_use    -- Number of sites to use from the reference station.info
* num_rsi    -- Number of sites in the reference station.info that
*               were not used because they were not included. 

      integer*4 num_str, num_stf, num_rxf, num_igf, num_sxf
     .        , num_comments, num_ref, num_site, num_use, num_rsi

* allsite_indx(max_site) -- index which points to order of ordered sites
* site_start(max_site) -- Start of each site in the indexed list for the
*               station.info entries
* site_indx(max_str)  -- List which points from the sorted site names to
*               station.info entries (i.e., starts as 1 2 3 ... n and
*               after sorting gives the order needed to alphabetical site
*               list.  This is further sorted to put the time in order
*               within a station.
* newflag(max_str) -- Flag (T or F) indicating whether the entry has been 
*               added this run, from a second station.info, RINEX, IGS, or SINEX 
*              (used to determine if a check on changed values is necessary)

      integer*4 allsite_indx(max_site), site_start(max_site),
     .          site_indx(max_str)
      logical   newflag(max_str)

* max_slant -- Maximum height above which heights in rinex files will be
*              be taken to be slant heights

      real*4 max_slant



* allow_overwrite  -- Logical set true if we allow the station.info file
*                     to be overwritten
* copy_comments    -- Logical set true with -c option to copy comments into 
*                     merged file  
* nosort -- Logical set true if the added sites are to be appended at the end

      logical allow_overwrite,copy_comments,nosort

* replace_entry - Control to determine whether new entries from RINEX, IGS, or SINEX are added
*                 Allowed values are 'none', 'all ', or 'diff'

      character*4 replace_entry

* rx_open - If true, treat new RINEX entries as open-ended 

      logical rx_open

* nowrite --- Logical set true if duplicate or overridden entries are to be omitted entirely
*             in the output station.info.  Default is to write them with a '-' in column 1 indicating comment
               
      logical nowrite

* dup_tol -- Tolerance in years (input seconds converted) to decide if two start times represent duplicate entries
           
      real*8 dup_tol          

* snx_site -- Site requested from a SINEX file (if omitted, convert all sites)

      character*4 snx_site

* write_apr -- If true, write the coordinates from the IGS log or SINEX file to 'mstinf.apr'

      logical write_apr     

* no_gaps -- If true, don't allow gaps in the entries: set the stop time
*            of the last entry to the start time of the next entry.  Used
*            only for IGS logs (also for GIPSY sta_rcvr and sta_svec entries
*            but they don't have stop times so no gaps should occur). A
*           warning is issued since this might result in incorrect meta-data.

      logical no_gaps

* site_names(max_site) -- 4-character codes for tracking sites
* use_names(max_site) -- names of site to use from the reference
*          station.info.  (These sites are not used from merged
*          station.info) The latest character is used to indicate
*          that we found a station in the reference station.info
* rsi_names(max_site) -- Names of the stations found in the reference
*          station.info that should not be used in the merged files

      character*4 site_names(max_site), rsi_names(max_site)

      character*4 use_names(max_site)

* ref_stinf  -- Reference station.info file
* upd_stinf(max_stf) -- Station.info files to be merged   
* rx_file(max_rxf)   -- Rinex files to be merged (limited to 1 in current version) 
* ig_file(max_igf)   -- IGS log files to be merged (limited to 1 in current version)
* sx_file(max_sxf)   -- SINEX files to be merged (limited to 1 in current version)
* sr_file(max_stf)   -- GIPSY sta_rcvr file be merged              | Both of these should
* sa_file(max_stf)   -- GIPSY sta_svec (antenna) file to be merged | be present

* out_stinf  -- Output station.info file
* stinf_com(max_comments) -- Comments from station.info files
* ref_nlist - Number of items in reference file  (used for output)
* ref_item_list - List of items in reference file (used for output)
* ref_colum  -- Column names from the reference station,info file
* apr_file -- Optional output apr file (hard-wired to 'mstinf.apr')  
* uapr    --  Unit number for apr file 

           
      integer*4 ref_nlist,uapr
      character*6 ref_item_list(20) 
      character*128 ref_stinf, upd_stinf(max_stf), rx_file(max_rxf)
     .            , out_stinf, ig_file(max_igf), sx_file(max_sxf)
     .            , apr_file, sr_file, sa_file
      character*132 stinf_com(max_comments)
                     
      common / stinf_common / dup_tol,num_str,num_stf,num_rxf,num_igf
     .      ,  num_sxf, num_comments,  num_ref,  num_site
     .      ,  num_use, num_rsi, allsite_indx, site_start, site_indx
     .      ,  newflag,  max_slant, ref_nlist, allow_overwrite
     .      ,  replace_entry,  copy_comments,  nosort, nowrite
     .      ,  write_apr, site_names,  rsi_names, use_names
     .      ,  ref_stinf, upd_stinf, rx_file, ig_file, sx_file 
     .      ,  sr_file, sa_file, out_stinf, stinf_com,  ref_item_list
     .      , snx_site,  apr_file,  uapr, rx_open, no_gaps

*------------------------------------------------------------------------
* STATION.INFO Entries
* -------------------- 
* sitcod(max_str) - Station code (4-char)
* trkcod(max_str) - Site occupation code for kinematic (4-char)
* sname(max_str)  -  Full site name (16-char)
* dUNE(3,max_str) - Antenna offset (UNE)
* dAntAZ(max_str) - Antenna aligment from True N (deg)
* rcvcod(max_str) - GAMIT receiver code (6-char)  
* rctype(max_str) - RINEX (IGS) receiver name  
* rcvrsn(max_str) - Receiver serial number    
* swver(max_str)  - GAMIT firmware version (decimal)
* rcvers(max_str) - RINEX firmware version (alphameric)
* antcod(max_str) - GAMIT antenna code  (6-char)    
* anttyp(max_str) - RINEX (IGS) antenna name (15-char)  
* radome(max_str) - IGS radome name, last 5 characters of antenna field  
* antsn(max_str)  - Antenna serial number (alphameric)
* htcod(max_str)  - GAMIT height code (5-char)
* istart(5,max_str) - Start time (yr doy hr min sec)
* istop(5,max_str)  - Stop time  (yr doy hr min sec)
* sn(max_str),    - Session number
* comment(max_str) - Comment at end of line (optional) 

      character*4 sitcod(max_str), trkcod(max_str)
      character*16 sname(max_str)
      real*8 dUNE(3,max_str)
      real*8 dAntAZ(max_str)  ! Antenna aligment from True N (deg).
      character*6 rcvcod(max_str), antcod(max_str)
      character*5 htcod(max_str), radome(max_str) 
      character*20 rctype(max_str), antsn(max_str), rcvers(max_str) 
      character*15 anttyp(max_str) 
* MOD TAH 200213: Changed from  character*10 to character*20 to be consistent
*     with rdstnfo call.
      character*20 rcvrsn(max_str)
      real*4 swver(max_str) 
      integer*4 istart(5,max_str),istop(5,max_str), sn(max_str)
* MOD TAH 200317: Made length consistent with GAMIT length of 36 (was 132)
      character*36 comment(max_str) 

      common / stinf_recs / dUNE, dAntAZ, swver, istart, istop, sn, 
     .     sitcod, trkcod, sname, rcvcod, rctype, rcvrsn, rcvers,
     .     antcod, anttyp, antsn, radome, htcod, comment
 

*------------------------------------------------------------------------
* DEBUG ENTRIES 
      logical dump_log   ! Set true to -debug option and write the log
                         ! file as it is read (to catch bad date lines)

      common / DUMP / dump_log
