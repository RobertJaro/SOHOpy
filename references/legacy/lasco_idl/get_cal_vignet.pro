function get_cal_vignet,tel_num,date,obs_mode,vig
;+
; NAME: 			GET_CAL_VIGNET
;
; PURPOSE:			Obtains the appropriate vignetting calibration
;				file for the date and observing mode
;
; CATEGORY: 			REDUCTION
;
; CALLING SEQUENCE: 		Result = GET_CAL_VIGNET
;					    (Tel_num,Date,Obs_mode,Vig)
;
; INPUTS:			Tel_num = Telescope Number (0..3)
;				Date = Date of observation (format = UTC/ECS)
;				Obs_mode = Telescope configuration
;
; OUTPUTS:			Vig = Vignetting calibration structure
;				Result = status of operation 
;					1=success
;					0=failure
;
; COMMON BLOCKS:		DBMS
;
; SIDE EFFECTS:			A log entries are written to unit LULOG
;
; PROCEDURE:			The routine get_cal_struct is called to find
;				the file name for the appropriate date and 
;				configuration, and then the cal structure is 
;				restored.
;
; MODIFICATION HISTORY: 	WRITTEN	     RA Howard, NRL, 4 October 1995
;				Version 1    RAH  Initial Release
;
;       @(#)get_cal_vignet.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
;
common dbms,ludb,lulog
if (get_cal_struct ('vig',tel_num,date,obs_mode,file) eq 0) then begin
   return,0 
endif else begin
   restore,file
   s = size(lulog)
   if ((s(0) eq 0) and (s(1) eq 0))  then log=0 else log=1
   if (log eq 1) then begin
      printf,lulog,'Vignetting file: ',file
      printf,lulog,'Version:         ',vig.version
      printf,lulog,'Create Date:     ',vig.dtecreate
      printf,lulog,'Start Date:      ',vig.dtestart
      printf,lulog,'End Date:        ',vig.dteend
   endif
   print,'Vignetting file: ',file
   print,'Version:         ',vig.version
   print,'Create Date:     ',vig.dtecreate
   print,'Start Date:      ',vig.dtestart
   print,'End Date:        ',vig.dteend
   return,1
endelse
end

