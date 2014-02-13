;+
; HERE RESTS THE ONE SENTENCE ROUTINE DESCRIPTION
;
; :Params:
;    bounds : in, required, type="lonarr(ndims, 3)"
;       bounds 
;
; :Keywords:
;    start : out, optional, type=lonarr(ndims)
;       input for start argument to H5S_SELECT_HYPERSLAB
;    count : out, optional, type=lonarr(ndims)
;       input for count argument to H5S_SELECT_HYPERSLAB
;    block : out, optional, type=lonarr(ndims)
;       input for block keyword to H5S_SELECT_HYPERSLAB
;    stride : out, optional, type=lonarr(ndims)
;       input for stride keyword to H5S_SELECT_HYPERSLAB
;-
pro MVN_KP_3D_MAVEN_MODEL, x,y,z,polylist, scale,cow=cow,install_directory


  if keyword_set(cow) then begin
    filename = filepath('cow10.sav', subdir=['examples','data'])
  endif else begin
    filename = install_directory+'maven_model.sav'  
  endelse
  restore,filename=filename

  x = x * scale
  y = y * scale
  z = z * scale




END