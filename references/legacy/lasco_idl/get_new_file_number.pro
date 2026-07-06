function get_new_file_number,tel,source
;+
; NAME:				GET_NEW_FILE_NUMBER
;
; PURPOSE:			Finds the last file number for the given
;				telescope and source and increments it.
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		Result = GET_NEW_FILE_NUMBER(Tel, Source)
;
; INPUTS:			Tel  =  Telescope number (0..3)
;				Source = 0 for GSFC R/T
;					 1 for NRL R/T
;					 2 for NRL Playback
;					 7 for test
;
; OUTPUTS:			Result = Number to be used for file name 
;
; COMMON BLOCKS:		DBMS
;
; PROCEDURE:			An entry is recorded in the processing log
;				when the file number is found.
;
; MODIFICATION HISTORY:		Written	RA Howard, NRL
;				Version 1	Initial Release 31 Oct 1995
;				Version 2  17 Jan 96 Added testing source
;				Version 3  11 Feb 97 SEP Changed num to type LONG
;				29 Aug 2000, nbr - Use $LAST_IMG instead of $IMAGES
;				11 Oct 2000, nbr - Use $IMAGES if source=0
;
;       @(#)get_new_file_number.pro	1.3 01/12/01 ; NRL LASCO IDL LIBRARY
;
;-
;
common dbms,ludb,lulog
ver = 'V1'
IF source EQ 0 THEN dir=getenv('IMAGES') ELSE dir=getenv('LAST_IMG')
dirlen=strlen(dir)
if strmid(dir,dirlen-1,1) ne '/' then dir=dir+'/'
ts = strtrim(tel,2)+strtrim(string(source),2)
file=ts+'_num'
printf,lulog,file
openr,lu,dir+ts+'_num',/get_lun,error=err
if (err ne 0) then begin
   num=1
endif else begin
   readf,lu,num
   close,lu & free_lun,lu
   num=LONG(num)+1
endelse
openw,lu,dir+ts+'_num',/get_lun
num=LONG(num)
printf,lu,num
printf,lulog,'New file number = ',num
close,lu
free_lun,lu
return,num
end
