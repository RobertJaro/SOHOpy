function get_cal_stray,tel_num,date,obs_mode,stray
;+
; NAME:
;	GET_CAL_STRAY
;
; PURPOSE:
;	This function obtains the stray light data structure applicable to 
;	the current date and telescope configuration
;
; CATEGORY:
;	REDUCTION
;
; CALLING SEQUENCE:
;	GET_CAL_STRAY, Tel_num, Date, Obs_mode
;
; INPUTS:
;	Tel_num 	Telescope number [0=C1,.., 3=EIT]
;	Date 		Date of the image (format = DATE-OBS)
;	Dbs_mode 	Telescope configuration
;
; OUTPUTS:
;	Stray 		Stray Light calibration structure
;	Function Result The status of the query is returned as the 
;			function result: 0 if cal file was not found
;			and 1 if it was found.
;
; COMMON BLOCKS:
;	DBMS, ludb, lulog
;
; SIDE EFFECTS:
;	An entry is written to the log file if lulog in the common block is
;	defined.
;
; PROCEDURE:
;	GET_CAL_STRUCTURE is called to obtain the name of the appropriate
;	calibration file.  Then the file (an IDL save set) is restored.
;
; MODIFICATION HISTORY:
;     Written	RA Howard, NRL, 4 October 1995
;
;       @(#)get_cal_stray.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
;
common dbms,ludb,lulog
if (get_cal_struct ('stray',tel_num,date,obs_mode,file) eq 0) then begin
   return,0 
endif else begin
   restore,file
   s = size(lulog)
   if ((s(0) eq 0) and (s(1) eq 0))  then log=0 else log=1
   if (log eq 1) then begin
      printf,lulog,'Stray Light file: ',file
      printf,lulog,'Version:          ', stray.version
      printf,lulog,'Create Date:      ', stray.dtecreate
      printf,lulog,'Start Date:       ', stray.dtestart
      printf,lulog,'End Date:         ', stray.dteend
   endif
   print,'Stray Light file: ',file
   print,'Version:          ', stray.version
   print,'Create Date:      ', stray.dtecreate
   print,'Start Date:       ', stray.dtestart
   print,'End Date:         ', stray.dteend
   return,1
endelse
end

