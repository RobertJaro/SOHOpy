function get_cal_photom,tel_num,date,obs_mode,photo
;+
; NAME:
;	GET_CAL_PHOTOM
;
; PURPOSE:
;	This function obtains the photometric calibration data structure
;	applicable to the current date and telescope configuration
;
; CATEGORY:
;	REDUCTION
;
; CALLING SEQUENCE:
;	GET_CAL_PHOTOM, Tel_num, Date, Obs_mode, Photo
;
; INPUTS:
;	Tel_num 	The telescope number [0=C1,.., 3=EIT]
;	Date		The date of the image (format = DATE-OBS)
;	Obs_mode 	The telescope configuration
;
; OUTPUTS:
;	Photo		The photometric calibration data structure
;	Function Result	Gives the status of the search
;			0 if calibration file not found
;			1 if file found
;
; COMMON BLOCKS:
;	DBMS, ludb, lulog
;
; SIDE EFFECTS:
;	An entry in the processing log is produced if lulog is defined
;
; PROCEDURE:
;	GET_CAL_STRUCT is called to find the appropriate calibration file,
;       which is an IDL save set. Then the data is restored and an entry
;	is made in the processing log.
;
; MODIFICATION HISTORY:
;	Written		RA Howard, NRL, 4 October 1995
;
;       @(#)get_cal_photom.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-

;
common dbms,ludb,lulog
if (get_cal_struct ('photo',tel_num,date,obs_mode,file) eq 0) then begin
   return,0 
endif else begin
   restore,file
   s = size(lulog)
   if ((s(0) eq 0) and (s(1) eq 0)) then log=0 else log=1
   if (log eq 1) then begin
      printf,lulog,'Photmetric file: ',file
      printf,lulog,'Version:         ',photo.version
      printf,lulog,'Create Date:     ',photo.dtecreate
      printf,lulog,'Start Date:      ',photo.dtestart
      printf,lulog,'End Date:        ',photo.dteend
   endif
   print,'Photmetric file: ',file
   print,'Version:         ',photo.version
   print,'Create Date:     ',photo.dtecreate
   print,'Start Date:      ',photo.dtestart
   print,'End Date:        ',photo.dteend
   return,1
endelse
end

