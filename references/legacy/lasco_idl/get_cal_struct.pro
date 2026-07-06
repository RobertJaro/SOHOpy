function get_cal_struct,type,tel_num,date,obs_mode,filename
;+
; NAME:
;	GET_CAL_STRUCT
;
; PURPOSE:
;	This function is a general purpose function procedure to first 
;	read the date cal file, find the applicable calibration file, and 
;	then return the calibration structure
;
; CATEGORY:
;	REDUCTION
;
; CALLING SEQUENCE:
;	GET_CAL_STRUCT, Type, Tel_num, Date, Obs_mode, Filename
;
; INPUTS:
;	Type       	String containing type of calibration file
;	Tel_num    	Telescope number (0..3)
;	Date       	Date and Time of image to be calibrated (format=UTC/ECS)
;	Obs_mode   	Observing Mode number
;
; OUTPUTS:
;	Filename	Filename of calibration file
;	Function Result	the status of the query
;               	0 = Valid
;               	1 = Invalid
;
; COMMON BLOCKS:
;	DBMS, ludb, lulog
;
; PROCEDURE:
;	The file whose file name is built from the calibration type
;	is opened and read.  The file names are 
;		photo_date_config.txt
;		stray_date_config.txt
;		dark_date_config.txt
;		vig_date_config.txt
;	These files have records in the following format:
;
;	telescope_number, date_start,date_end, configuration, filename
;	where:
;		Telescope_number is the number from 0 to 3 for C1 to EIT
;		Date_start is the starting valid date and time 
;		End_start is the ending valid date and time 
;		Filename is the name of the calibration file
;
; MODIFICATION HISTORY:
;     Written		RA Howard, NRL, 4 October 1995
;
;       @(#)get_cal_struct.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
;
;
common dbms,ludb,lulog
s = size(lulog)
if ((s(0) eq 0) and (s(1) eq 0)) then log=0 else log=1
dte=str2utc(date)
openr,lu,type+'_date_config.txt',/get_lun
repeat begin
   readf,lu,t,dstart,dend,conf,filename
   if ( (t eq tel_num) and (conf eq obs_mode) ) then begin
      ds=str2utc(dstart)
      if ( dte.mjd gt ds.mjd ) then begin
         de = str2utc(dend)
         if ( dte lt de.mjd ) then goto,L1 else begin
         if  (( dte.mjd eq de.mjd) and (dte.time lt de.time)) then goto,L1
         endelse
      endif else begin
         if  (( dte.mjd eq ds.mjd) and (dte.time gt ds.time)) then goto,L1
         de = str2utc(dend)
         if ( dte lt de.mjd ) then goto,L1 else begin
         if  (( dte.mjd eq de.mjd) and (dte.time lt de.time)) then goto,L1
         endelse
      endelse
   endif
endrep until eof(lu)
;
;   error:  current configuration not in date config file
;
free_lun,lu
print,'ERROR: GET_CAL_STRUCT (type='+type+').  Current configuration not found'
if (log eq 1) then begin
printf,lulog,'ERROR: GET_CAL_STRUCT (type='+type+').  Current configuration not found'
endif
return,0
;
L1:
close,lu
free_lun,lu
if (log eq 1) then begin
printf,lulog,'Found calibration structure type='+type
endif
return,1
end
