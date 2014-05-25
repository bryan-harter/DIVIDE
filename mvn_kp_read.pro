;+
; 
; :Description:
; Read local Maven KP data files into memory. Capable of reading both in situ KP data files
; and IUVS KP data files. Capable of reading in either CDF or ASCII formated data files.   
;
; :Params:
;    time : in, required, type="lonarr(2)"
;       A time parameter that maybe of any type (string, float, or int) 
;    insitu_output : out, required, type=lonarr(ndims)
;       required named structure for the output INSITU kp data
;    iuvs_output: out, required, type=lonarr(ndims)
;       required named structure for the output IUVS kp data
;       
; :Keywords:
;    kp_criteria : in, optional, type=lonarr(ndims)
;       optional named search criteria structure (set by MAVEN_KP_PARAM_SET)
;    duration : in, optional, type=integer
;       optional length of time to return data, in seconds, only used if input time is a single value
;    update_prefs: in, optional, type=boolean
;       option to use dialog boxes and re-define your data paths in preferences.txt
;    lpw: in, optional, type=boolean
;       optional keyword that will return all of the LPW data 
;    static: in, optional, type=boolean
;       optional keyword that will return all of the STATIC data 
;    swia: in, optional, type=boolean
;       optional keyword that will return all of the SWIA data 
;    swea: in, optional, type=boolean
;       optional keyword that will return all of the SWEA data 
;    mag: in, optional, type=boolean
;       optional keyword that will return all of the MAG data 
;    sep: in, optional, type=boolean
;       optional keyword that will return all of the SEP data 
;    ngims: in, optional, type=boolean
;       optional keyword that will return all of the NGIMS data 
;    iuvs_all: in, optional, type=boolean
;       optional keyword to return all IUVS KP data, regardless of observation type
;    insitu_all: in, optional, type=boolean
;       optional keyword that will return all of the INSITU data, regardless of observation type
;    insitu_only: in, optional, type=boolean
;       optinal keyword to specify that you only want to read in insitu data (ignore IUVS)
;    iuvs_periapse:  in, optional, type=boolean
;       optional keyword that will return all of the IUVS PERIAPSE limb scan data 
;    iuvs_apoapse: in, optional, type=boolean
;       optional keyword that will return all of the IUVS APOAPSE data 
;    iuvs_coronaEchellehigh: in, optional, type=boolean
;       optional keyword that will return all of the IUVS Corona Echelle high altitude data 
;    iuvs_coronaEchelledisk: in, optional, type=boolean
;       optional keyword that will return all of the IUVS Corona Echelle disk data 
;    iuvs_coronaEchelleLimb: in, optional, type=boolean
;       optional keyword that will return all of the IUVS Corona Echelle limb data 
;    iuvs_coronaLoreslimb: in, optional, type=boolean
;       optional keyword that will return all of the iuvs corona LoREs on limb data 
;    iuvs_coronaLoreshigh: in, optional, type=boolean
;       optional keyword that will return all of the IUVS Corona LoRes high altitude data 
;    iuvs_coronaLoresdisk: in, optional, type=boolean
;       optional keyword that will return all of the IUVS Corona LoRes disk data 
;    iuvs_stellarocc: in, optional, type=boolean
;       optional keyword that will return all of the IUVS Stellar Occulatation data 
;    inbound: in, optional, type=boolean
;       optional keyword that will return all of the data from the inbound leg of an orbit
;    outbound: in, optional, type=boolean
;       optional keyword that will return all of the data from the outbound leg of an orbit
;
;;    Need to update
;;
;    download_new: in, optional, type=boolean
;       optional keyword to instruct IDL to query the SDC server to look for any new files to download
;       over the input timerange.
;    debug: in, optional, type=boolean
;       optional keyword to execute in "debug" mode. On errors, IDL will halt in place so the user can
;       have a chance to see what's going on. By default this will not occur, instead error handlers
;       are setup and errors will return to main.   
;       
;-

@mvn_kp_download_files
@mvn_kp_file_search
@mvn_kp_insitu_struct_init
@mvn_kp_iuvs_struct_init        ;; FIXME UPDATE ALL OF THESE
@mvn_loop_progress
@mvn_kp_time_bounds
@mvn_kp_insitu_assign
@mvn_kp_iuvs_binary_assign
@mvn_kp_read_iuvs_file
@mvn_kp_iuvs_cdf_read
@mvn_kp_insitu_cdf_read


pro MVN_KP_READ, time, insitu_output, iuvs_output, download_new=download_new, update_prefs=update_prefs, $
                 debug=debug, duration=duration, text_files=text_files, save_files=save_files, $
                 insitu_only=insitu_only, insitu_all=insitu_all, inbound=inbound, outbound=outbound, $
                 lpw=lpw, static=static, swia=swia, swea=swea, mag=mag, sep=sep, ngims=ngims, $    
                 iuvs_all=iuvs_all, iuvs_periapse=iuvs_periapse, iuvs_apoapse=iuvs_apoapse, $
                 iuvs_coronaEchellehigh=iuvs_coronaEchellehigh,iuvs_coronaEchelleDisk=iuvs_coronaEchelleDisk,$
                 iuvs_coronaEchelleLimb=iuvs_coronaEchelleLimb, iuvs_coronaLoresDisk=iuvs_coronaLoresDisk, $
                 iuvs_coronaLoreshigh=iuvs_coronaLoreshigh, iuvs_coronaLoreslimb=iuvs_coronaLoreslimb, $
                 iuvs_stellarocc=iuvs_stellarocc, only_update_prefs=only_update_prefs
                      

  
  overall_start_time = systime(1)
  
  ;IF NOT IN DEBUG, SETUP ERROR HANDLER
  if not keyword_set(debug) then begin
    ;ESTABLISH ERROR HANDLER. WHEN ERRORS OCCUR, THE INDEX OF THE
    ;ERROR IS RETURNED IN THE VARIABLE ERROR_STATUS:
    catch, Error_status
    
    ;THIS STATEMENT BEGINS THE ERROR HANDLER:
    if Error_status ne 0 then begin
      ;HANDLE ERRORS BY RETURNING TO MAIN:
      print, '**ERROR HANDLING - ', !ERROR_STATE.MSG
      print, '**ERROR HANDLING - Cannot proceed. Returning to main'
      Error_status = 0
      catch, /CANCEL
      return
    endif
  endif
  
  
  ;; ------------------------------------------------------------------------------------ ;;
  ;; ---------------------------- Check input options ----------------------------------- ;;
  
  
  ; IF DEBUG SET, CREATE ENVIRONMENT VARIABLE SO ALL PROCEDURES/FUNCTIONS CALLED CAN CHECK FOR IT
  if keyword_set(debug) then begin
    setenv, 'MVNTOOLKIT_DEBUG=TRUE'
  endif

  ;; Read from and/or update preferences file 
  if keyword_set(only_update_prefs) then begin
    MVN_KP_CONFIG_FILE, /update_prefs, insitu_only=insitu_only
    
    ;; Warn user if other parameters supplied
    if keyword_set(time) or keyword_set(insitu) or keyword_set(iuvs) then begin
      print, "Warning. /ONLY_UPDATE_PREFS option supplied, not reading any data." 
      print, "If you want to update the preferences file & read data, use /UPDATE_PREFS instead"
    endif
    
    ;; Only update prefs option, return now. 
    return
  endif else begin

    ;; Read or create preferences file 
    MVN_KP_CONFIG_FILE, insitu_data_dir=kp_insitu_data_directory, iuvs_data_dir=kp_iuvs_data_directory, $
      update_prefs=update_prefs, insitu_only=insitu_only
  endelse
    

  ;SET UP instruments struct WHICH IS USED FOR CREATING DATA STRUCTURE & CONTROLLING WHICH INSTRUMENTS DATA TO READ
  if keyword_set(lpw) or keyword_set(static) or keyword_set(swia) or keyword_set(swea) or keyword_set(mag) or keyword_set(sep) or $
    keyword_set(ngims) or keyword_set(iuvs_all) or keyword_set(iuvs_periapse) or keyword_set(iuvs_apoapse) or $
    keyword_set(iuvs_coronaEchelleDisk) or keyword_set(iuvs_coronaEchelleLimb) or keyword_set(iuvs_coronaEchelleHigh) or keyword_set(iuvs_coronaLoresHigh) or $
    keyword_set(iuvs_coronaloreslimb) or keyword_set(iuvs_coronaloresdisk) or keyword_set(iuvs_stellarocc) or keyword_set(insitu_all) then begin


  ;; Setup instrument struct which is used for creating data structure & controlling which instruments to read
    instruments = CREATE_STRUCT('lpw',      0, 'static',   0, 'swia',     0, $
                                'swea',     0, 'mag',      0, 'sep',      0, $
                                'ngims',    0, 'periapse', 0, 'c_e_disk', 0, $
                                'c_e_limb', 0, 'c_e_high', 0, 'c_l_disk', 0, $
                                'c_l_limb', 0, 'c_l_high', 0, 'apoapse' , 0, 'stellarocc', 0)                            
   
    if keyword_set(lpw)    then begin
      instruments.lpw    = 1 & print,'Returning All LPW Instrument KP Data.'  
    endif
    if keyword_set(static) then begin
      instruments.static = 1 & print,'Returning All STATIC Instrument KP Data.'
    endif
    if keyword_set(swia)   then begin
      instruments.swia   = 1 & print,'Returning All SWIA Instrument KP Data.'
    endif
    if keyword_set(swea)   then begin
      instruments.swea   = 1 & print,'Returning All SWEA Instrument KP Data.'
    endif
    if keyword_set(mag)    then begin
      instruments.mag    = 1 & print,'Returning All MAG Instrument KP Data.'
    endif
    if keyword_set(sep)    then begin
      instruments.sep    = 1 & print,'Returning All SEP Instrument KP Data.'
    endif
    if keyword_set(ngims)  then begin
      instruments.ngims  = 1 & print,'Returning All NGIMS Instrument KP Data.'
    endif
    if keyword_set(inbound) then begin
                               print,'Returning only inbound in situ data'
    endif
    if keyword_set(outbound) then begin
                               print,'Returning only outbound in situ data'
    endif
    
    if keyword_set(iuvs_periapse)          then begin
      instruments.periapse   = 1 & print,'Returning All IUVS Instrument Periapse KP Data.'  
    endif
    if keyword_set(iuvs_apoapse)           then begin
      instruments.apoapse    = 1 & print,'Returning All IUVS Instrument Apoapse KP Data.'
    endif
    if keyword_set(iuvs_coronaEchellehigh) then begin
      instruments.c_e_high   = 1 & print,'Returning All IUVS Instrument Corona Echelle High Altitude KP Data.'
    endif
    if keyword_set(iuvs_coronaEchellelimb) then begin
      instruments.c_e_limb   = 1 & print,'Returning All IUVS Instrument Corona Echelle Limb KP Data.'
    endif
    if keyword_set(iuvs_stellarocc)        then begin
      instruments.stellarocc = 1 & print,'Returning All IUVS Instrument Stellar Occultation KP Data.'
    endif
    if keyword_set(iuvs_coronaLoreshigh)   then begin
      instruments.c_l_high   = 1 & print,'Returning All IUVS Instrument Corona Lores High Altitude KP Data.'
    endif
    if keyword_set(iuvs_coronaLoreslimb)   then begin
      instruments.c_l_limb   = 1 & print,'Returning All IUVS Instrument Corona Lores Limb KP Data.'
    endif
    if keyword_set(iuvs_coronaLoresdisk)   then begin
      instruments.c_l_disk   = 1 & print,'Returning All IUVS Instrument Corona Lores Disk KP Data.'
    endif
    if keyword_set(iuvs_coronaechelledisk) then begin
      instruments.c_e_disk   = 1 & print,'Returning All IUVS Instrument Corona Echelle Disk KP Data.'
    endif
    
    if keyword_set(insitu_all) then begin
      instruments.lpw    = 1
      instruments.static = 1
      instruments.swia   = 1
      instruments.swea   = 1
      instruments.mag    = 1
      instruments.sep    = 1
      instruments.ngims  = 1
      print, 'Returning all INSITU Instrument KP Data.'
    endif
    if keyword_set(iuvs_all) then begin
      instruments.periapse   = 1
      instruments.c_e_disk   = 1
      instruments.c_e_limb   = 1
      instruments.c_e_high   = 1
      instruments.c_l_disk   = 1
      instruments.c_l_limb   = 1
      instruments.c_l_high   = 1
      instruments.apoapse    = 1
      instruments.stellarocc = 1
      print,'Returning All IUVS Instrument KP Data.'
    endif


  endif else begin
    
    ;SET ALL INSTRUMENT FLAGS TO 1 TO CREATE FULL STRUCTURE FOR ALL INSTRUMENT DATA
    instruments = CREATE_STRUCT('lpw',      1, 'static',   1, 'swia',     1, $
                                'swea',     1, 'mag',      1, 'sep',      1, $
                                'ngims',    1, 'periapse', 1, 'c_e_disk', 1, $
                                'c_e_limb', 1, 'c_e_high', 1, 'c_l_disk', 1, $
                                'c_l_limb', 1, 'c_l_high', 1, 'apoapse' , 1, 'stellarocc', 1)   
  endelse
  
  
  ;SET INBOUND/OUTBOUND KEYWORDS IF NEEDED
  io_flag = intarr(2)
  if keyword_set(inbound) eq 1 then begin
    io_flag[0] = 1
    io_flag[1] = 0
  endif
  if keyword_set(outbound) eq 1 then begin
    io_flag[0] = 0
    io_flag[1] = 1
  endif
  if (keyword_set(inbound) eq 0) and (keyword_set(outbound) eq 0) then begin
    io_flag[0] = 1
    io_flag[1] = 1
  endif
    


  ;; ------------------------------------------------------------------------------------ ;;
  ;; ----------------------- Process input time/orbit range  ---------------------------- ;;

  
  ; DEFAULT RETRIEVAL PERIOD TO 1 DAY OR 1 ORBIT
  if keyword_set(duration) eq 0 then begin
    if size(time,/type) eq 7 then duration = 86400
    if size(time,/type) eq 2 then duration = 1
  endif

  ;IF ORBIT(s) SUPPLIED 
  ;;============================
  if size(time, /type) eq 2 then begin
  
    ;; If only one orbit supplied, add duration to first orbit to created end_orbit  
    if n_elements(time) eq 1 then begin
        print,'Retrieving KP data for ',strtrim(string(duration),2),' orbits beginning at orbit #',strtrim(string(time),2)
        begin_orbit = time[0]
        end_orbit = time[0] + duration
    endif else begin
      begin_orbit = time[0]
      end_orbit   = time[1]
    endelse
    
    ;; Use orbit file look up to get time strings for each orbit       -- FIXME check output of this to ensure we found orbits.
    MVN_KP_ORBIT_TIME, begin_orbit, end_orbit, begin_time_string, end_time_string
    
    ;; Create Jul day versions
    mvn_kp_time_split_string, begin_time_string, year=yr, month=mo, day=dy, hour=hr, min=min, sec=sec, /FIX
    begin_time_jul = julday(mo, dy, yr, hr, min, sec)
    mvn_kp_time_split_string, end_time_string, year=yr, month=mo, day=dy, hour=hr, min=min, sec=sec, /FIX
    end_time_jul = julday(mo, dy, yr, hr, min, sec) 
  endif
  
  ;IF TIME STRING(s) SUPPLIED
  ;;============================
  if size(time, /type) eq 7 then begin 
    if n_elements(time) eq 1 then begin 
      ; IF ONE TIME SUPPLIED USE IT AS START. DETERMINE END TIME BASED ON duration (DEFAULT 1 DAY OR USER SUPPLIED)
      begin_time_string = time[0]
      mvn_kp_time_split_string, begin_time_string, year=yr, month=mo, day=dy, hour=hr, min=min, sec=sec, /FIX
      begin_time_jul = julday(mo, dy, yr, hr, min, sec)

      ;; Add seconds onto begin jul date to get end jul date
      end_time_jul = begin_time_jul + (duration/86400.0D)
      end_time_string = MVN_KP_TIME_CREATE_STRING(end_time_jul)
      
    endif else begin
      ;IF THE USER SUPPLIES A 2-VALUE ARRAY OF TIMES, USE THESE AS TIME STRINGS   - FIXME VALIDATE TIMES HERE?
      begin_time_string = time[0]
      end_time_string   = time[1]
      
      ;; Create Jul day versions
      mvn_kp_time_split_string, begin_time_string, year=yr, month=mo, day=dy, hour=hr, min=min, sec=sec, /FIX
      begin_time_jul = julday(mo, dy, yr, hr, min, sec)
      mvn_kp_time_split_string, end_time_string, year=yr, month=mo, day=dy, hour=hr, min=min, sec=sec, /FIX
      end_time_jul = julday(mo, dy, yr, hr, min, sec)
    endelse
  endif
  
  ;IF LONG INTEGER TIME SUPPLIED CONVERT FROM UNIX TIME TO TIME STRING (FIXME: SECONDS?)
  ;;============================
  if size(time,/type) eq 3 then begin
    if n_elements(time) eq 1 then begin
      begin_time_string = time_string(time, format=0)
      end_time_string   = time_string((time+duration), format=0)
    endif else begin
      begin_time_string = time_string(time[0],format=0)
      end_time_string   = time_string(time[1],format=0)
    endelse
    
    ;; Create Jul day versions
    mvn_kp_time_split_string, begin_time_string, year=yr, month=mo, day=dy, hour=hr, min=min, sec=sec, /FIX
    begin_time_jul = julday(mo, dy, yr, hr, min, sec)
    mvn_kp_time_split_string, end_time_string, year=yr, month=mo, day=dy, hour=hr, min=min, sec=sec, /FIX
    end_time_jul = julday(mo, dy, yr, hr, min, sec)
  endif
  
  
  ;; Create structs for both begin/end times containing string versions and jul days
  begin_time_struct = create_struct('string', begin_time_string, 'jul', begin_time_jul)
  end_time_struct   = create_struct('string', end_time_string,   'jul', end_time_jul)


  ;; ------------------------------------------------------------------------------------ ;;
  ;; -------------- Find files which contain data in input time range ------------------- ;;
  ;; -------------- and initialize data structures for holding data --------------------- ;;

  ;; FIXME variable names
  MVN_KP_FILE_SEARCH, begin_time_struct, end_time_struct, target_KP_filenames, kp_insitu_data_directory, iuvs_filenames, $
     kp_iuvs_data_directory, save_files=save_files, text_files=text_files, insitu_only=insitu_only, download_new=download_new
 

  ;CREATE OUTPUT STRUCTURES BASED ON SEARCH PARAMETERS & INITIALIZE ARRAY OF DATA STRUTURES 
  MVN_KP_INSITU_STRUCT_INIT, insitu_record, instruments=instruments
  kp_data_temp = replicate(insitu_record,21600L*n_elements(target_KP_filenames))
    
  if not keyword_set(insitu_only) then begin  
    MVN_KP_IUVS_STRUCT_INIT, iuvs_record, instruments=instruments
    iuvs_data_temp = replicate(iuvs_record, n_elements(iuvs_filenames))
  endif

 
  
  ;; ------------------------------------------------------------------------------------ ;;
  ;; ----------------------- Main read loop: In situ data    ---------------------------- ;;
  
  
  ; FIXME: These variables aren't being used?
  ;VARIABLES TO HOLD THE COUNT OF VARIOUS OBSERVATION TYPES (IE. HIGH VS. LOW ALTITUDE)
  ; high_count = 0
  ; low_count = 0
  if target_kp_filenames[0] ne 'None' then begin
    totalEntries=0L
    start_index=0L
    for file=0,n_elements(target_KP_filenames)-1 do begin
    
      ;UPDATE THE READ STATUS BAR
      MVN_LOOP_PROGRESS,file,0,n_elements(target_KP_filenames)-1,message='In-situ KP File Read Progress'
      
      fileAndPath = kp_insitu_data_directory+target_kp_filenames[file]
      MVN_KP_READ_INSITU_FILE, fileAndPath, kp_data, begin_time=begin_time_struct, end_time=end_time_struct, io_flag=io_flag, $
        instruments=instruments, save_files=save_files, text_files=text_files
        
    
      ;; Ensure what was returned is a structure, (and not int 0 indicating no matches)
      if size(kp_data, /TYPE) eq 8 then begin
        kp_data_temp[start_index:(start_index+n_elements(kp_data)-1)] = kp_data
        start_index += n_elements(kp_data)
        totalEntries += n_elements(kp_data)
      endif
    endfor
    
    
    ;OUTPUT INSITU DATA STRUCTURE
    insitu_output = kp_data_temp[0:totalEntries-1]
    print,'A total of ',strtrim(n_elements(insitu_output),2),' INSITU KP data records were found that met the search criteria.'
    
  endif else begin
    printf,-2, "Warning: No Insitu files found for input timerange."
  endelse
  
  ;; ------------------------------------------------------------------------------------ ;;
  ;; ----------------------- Main read loop: IUVS  data   ------------------------------- ;;
  
  
  ;IF ANY IUVS DATA IS REQUESTED & NOT IN INSITU ONLY MODE
  if not keyword_set(insitu_only) and (instruments.periapse or instruments.c_e_disk or instruments.c_e_limb or instruments.c_e_high or $
                                      instruments.apoapse  or instruments.c_l_disk or instruments.c_l_limb or instruments.c_l_high or $ 
                                      instruments.stellarocc) then begin
    iuvs_index=0
    if iuvs_filenames[0] ne 'None' then begin
    
      ;; Loop through each file
      for file=0,n_elements(iuvs_filenames)-1 do begin
      
        MVN_LOOP_PROGRESS,file,0,n_elements(iuvs_filenames)-1,message='IUVS KP File Read Progress'
        
        fileAndPath = kp_iuvs_data_directory+iuvs_filenames[file]
        MVN_KP_READ_IUVS_FILE, fileAndPath, iuvs_record, begin_time=begin_time_struct, end_time=end_time_struct, $
          instruments=instruments, save_files=save_files, text_files=text_files
          
        ;; If iuvs_record not eq -1 (Indicating some observation within time range) add to temp array
        if size(iuvs_record, /type) eq 8 then begin
          ;; Add single iuvs_record to array of iuvs records
          iuvs_data_temp[iuvs_index] = iuvs_record
          iuvs_index++
        endif
        
      endfor

      ;OUTPUT IUVS DATA STRUCTURE IF ANY IUVS DATA IS REQUESTED
      iuvs_output = iuvs_data_temp[0:iuvs_index-1]
      print,'including ',strtrim(string(iuvs_index),2),' IUVS data records'
      
    endif else begin
      printf, -2, "Warning: No IUVS files found for input timerange"
    endelse
  endif

  
  ;TIME TO RUN ROUTINE 
  overall_end_time = systime(1)
  print,'Your query took ', overall_end_time - overall_start_time,' seconds to complete.'
  
  
  ; UNSET DEBUG ENV VARIABLE
  setenv, 'MVNTOOLKIT_DEBUG='
  
end
