;
; Copyright 2017 Regents of the University of Colorado. All Rights Reserved.
; Released under the MIT license.
; This software was developed at the University of Colorado's Laboratory for Atmospheric and Space Physics.
; Verify current version before use at: https://lasp.colorado.edu/maven/sdc/public/pages/software.html

;; Infiles : Input array of files with paths of insitu ascii files to convert to save files
;;
;; Outdir : Output path where created save files should go.



pro mvn_kp_create_insitu_save, infiles, outdir, debug=debug

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
  
  
  for file=0, n_elements(infiles)-1 do begin
  
    base = file_basename(infiles[file])
    base = (strsplit(base, '.', /extract))[0]
    
    ;UPDATE THE READ STATUS BAR
    MVN_KP_LOOP_PROGRESS,file,0,n_elements(infiles)-1,message='In-Situ Save file creation progress'
    
    ;OPEN THE KP DATA FILE
    openr,lun,infiles[file,0],/get_lun
    
    ;; Determine # of data points:
    data_count = 0
    while not eof(lun) do begin
      temp = ''
      readf,lun,temp
      data = strsplit(temp,' ',/extract)
      if data[0] ne '#' then begin
        data_count++
      endif
    endwhile
    free_lun, lun
    

    ;; Create Orbit array for structures to be put into
    orbit_temp = {time_string:'', time: 0.0, orbit:0L, IO_bound:'', data:fltarr(211)}
    orbit = replicate(orbit_temp, data_count)
    
    
    ;OPEN THE KP DATA FILE
    openr,lun,infiles[file,0],/get_lun
    
    ;READ IN A LINE, EXTRACTING THE TIME
    i=0
    while not eof(lun) do begin
      temp = ''
      readf,lun,temp
      data = strsplit(temp,' ',/extract)
      if data[0] ne '#' then begin
      
  
        ;READ IN AND INIT TEMP STRUCTURE OF DATA
        orbit[i].time_string = data[0]
        orbit[i].time = time_double(data[0], tformat='YYYY-MM-DDThh:mm:ss')
        orbit[i].orbit = data[194]
        orbit[i].IO_bound = data[195]

        ;; Disclude data[0], data[194], data[195] - Strings won't go in data arry nicely,
        ;; and we've extracted these three points just above into the top level structure. 
        orbit[i].data[1:193] = data[1:193]
        orbit[i].data[196:210] = data[196:210]

        
        i++
      endif
    endwhile
    
    save,orbit,filename=outdir+path_sep()+base+'.sav'
    orbit=0
    free_lun,lun
  endfor
  
  ; UNSET DEBUG ENV VARIABLE
  setenv, 'MVNTOOLKIT_DEBUG='
  
end

