pro REDUCE_IMAGE,file_name,source
;+
; NAME:				REDUCE_IMAGE
;
; PURPOSE:			Perform the pipeline processing for one file
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		REDUCE_IMAGE,File_name,Source
;
; INPUTS:			File_name = Name of DDIS file to be processed
;				Source    = 0 for R/T processed at GSFC
;					    1 for R/T processed at NRL
;					    2 for Level 0/PB processed at NRL
;
; OUTPUTS:			None
;
; OPTIONAL OUTPUTS:		None
;
; COMMON BLOCKS:		DBMS
;
; SIDE EFFECTS:			Moves DDIS file, Creates FITS file
;
; PROCEDURE: 			Processes a new image created by DDIS and 
;				detected by the CRON job moves the image to a 
;				new directory for permanent storage.  Log 
;				entries are written.
;
; MODIFICATION HISTORY:		Written, RA Howard, NRL, 13 Oct 1995
;   Version 1
;           2      RAH    15 Nov 1995    Modified log output
;           3      RAH    14 Dec 1995    Corrected condition to call to reduce_level_1
;           4  Karl Battams Dec31,2007  Add temporary MySql stuff. Please contact me if this breaks anything!
;                                       karl.battams@nrl.navy.mil
;   	    5	N.Rich, 2009/09/29  Stop doing db_insert; ludb=ludb2
;
;       @(#)reduce_image.pro	1.3 09/29/09 LASCO IDL LIBRARY
;
;-
;
common dbms,ludb,lulog
common sqlbdms,ludb2
ver = 'V5'
get_utc,dtestart,/ecs		; get current date/time in UTC format
printf,lulog,'Procedure reduce_image started at '+dtestart
printf,lulog,'Procedure version = '+ver
printf,lulog,'Input Parameter #1:  file_name = '+file_name
printf,lulog,'Input Parameter #2:  source    = '+strtrim(string(source),2) 
status = 0
opt=strupcase(getenv('REDUCE_OPTS'))
printf,lulog,'Processing options = '+opt
if (strpos(opt,'TRANSFER') ge 0) then $
   status = reduce_transfer(file_name,source)
if (status eq 0) then begin
;
;   Invoke the reduction procedures to process to Level 0.5 and Level 1
;
   if (strpos(opt,'LEVEL_05') ge 0) then $
      status=reduce_level_05(file_name,fits_name,source)
   if ((status eq 0) and (strpos(opt,'LEVEL_1') ge 0)) then $
      reduce_level_1,fits_name
endif
if (strpos(opt,'DBMS') ge 0) then begin
;
;   Update db table:  LOG_SESSION
;
   get_utc,dteend,/ecs		; get current date/time in UTC format
   printf,lulog,'Updating DBMS table = log_session'
   a=get_db_struct('lasco','log_session')
   a.date_start=dtestart
   a.date_end=dteend
   a.log_file_name=file_name+'.log'
   ;db_insert,a   
   
   ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
     lubk=ludb      ; make a copy of ludb
     ludb=ludb2     ; point to the sql db file
     sql_db_insert,a
     ludb=lubk      ; revert to proper ludb
 ; ************ END  KB TEMP EDITS FOR SQL TESTING *****************  

endif				; end of update DBMS processing
get_utc,dte,/ecs		; get current date/time in UTC format
printf,lulog,'Procedure reduce_image ended at '+dte
for i=0,5 do printf,lulog
return
end
