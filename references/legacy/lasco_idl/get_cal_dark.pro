function get_cal_dark,tel_num,date,obs_mode,dark
;+
; NAME:
;	GET_CAL_DARK
;
; PURPOSE:
;	This function obtains the dark field calibration structure
;	applicable to the current date and telescope configuration
;
; CATEGORY:
;	REDUCTION
;
; CALLING SEQUENCE:
;	GET_CAL_DARK, Tel_num, Date, Obs_mode, Dark
;
; INPUTS:
;	Tel_num 	The telescope number [0=C1,.., 3=EIT]
;	Date 		The date of the image (format = DATE-OBS)
;	Obs_mode 	The telescope configuration (DBMS parameter)
;
; OUTPUTS:
;	Dark		The dark image calibration data structure
;       Function result Gives the status of the search: 
;	   		0 if the calibration file could not be found.
;			1 if successful 
;
; COMMON BLOCKS
;       DBMS, ludb,lulog
;
; SIDE EFFECTS
;       An entry is written into a log file if the unit number exists
;
; MODIFICATION HISTORY:
;     Written	RA Howard, NRL, 4 October 1995
;
;       @(#)get_cal_dark.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
common dbms,ludb,lulog
if (get_cal_struct ('dark',tel_num,date,obs_mode,file) eq 0) then begin
   return,0 
endif else begin
   restore,file
   s=size(lulog)
   if ((s(0) eq 0) and (s(1) eq 0)) then log=0 else log=1
   print,'Dark Image file: ',file
   print,'Version:         ', dark.version
   print,'Create Date:     ', dark.dtecreate
   print,'Start Date:      ', dark.dtestart
   print,'End Date:        ', dark.dteend
   if (log eq 1) then begin
      printf,lulog,'Dark Image file: ',file
      printf,lulog,'Version:         ', dark.version
      printf,lulog,'Create Date:     ', dark.dtecreate
      printf,lulog,'Start Date:      ', dark.dtestart
      printf,lulog,'End Date:        ', dark.dteend
   endif
   return,1
endelse
end

