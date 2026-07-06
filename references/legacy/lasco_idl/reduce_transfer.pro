function reduce_transfer,file_name,source, TEST=test
;+
; NAME:				REDUCE_TRANSFER
;
; PURPOSE:			Peform the transfer of an image file
;				created by DDIS into $LEB_IMG to the 
;				appropriate subdirectory under $LAST_IMG
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:	 	Result = REDUCE_TRANSFER (File_name, Source)
;
; INPUTS:			File_name = Name of DDIS file to transfer
;				Source = parameter giving source of data
;
; OPTIONAL INPUTS:		None
;	
; KEYWORD PARAMETERS:		/TEST	
;
; OUTPUTS: 			Result =  0 process to level 0.5
;               			  1 don't process further
;
; OPTIONAL OUTPUTS:		None
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:			None
;
; PROCEDURE:			
;	The subdirectories under $RAW are:
;	$RAW/YYMMDD if .img file
;	The subdirectories under $IMAGES are not used in the procedure.
;	The subdirectories under $LAST_IMG are:
;       $LAST_IMG/misc/leb/mem/YYMMDD if memory dump
;       $LAST_IMG/misc/leb/gnd/YYMMDD if ground to peripheral header
;   Also enters the appropriate information into the data base
;
; MODIFICATION HISTORY:		Written, RA Howard, NRL
;
;   Version 1	RAH   13 Oct 1995     Initial Release
;           2   RAH   15 Nov 1995     Modified log printouts
;           3   RAH   18 Mar 1996     Added leb summing to DB
;           4   RAH   03 Apr 1996     Moved DBMS update of hdr & ip to 05
;           5   RAH   09 Apr 1996     Check validity of image date
;           6   RAH   29 Oct 1996     Added -f option to mv to force the move
;	    7   NBR   19 May 1997     Use 'RAW' env var to place .img files
;	    8	NBR   24 Dec 1997     Handle 0-length .img files
;	    9   NBR   03 Feb 1999     Change upper bound of validdate to today + 2
;		NBR   29 Aug 2000 - Use $LAST_IMG instead of $IMAGES
;	NBR, 31 Jan 2002 - Add /SH to spawn calls
;         Karl Battams Dec31,2007   Add temporary MySql stuff. Please contact me if this breaks anything!
;                                       karl.battams@nrl.navy.mil
;   	   11	N.Rich, 2009/09/29  Stop doing db_insert; ludb=ludb2
;   	   12	N.Rich, 2010/06/09  Add /TEST keyword
;   	    13	N.Rich, 2011/04/22  Fix oddball directory bug
;
;       @(#)reduce_transfer.pro	1.15 02/15/12 ; NRL LASCO IDL LIBRARY
;-
;
common dbms,ludb,lulog
common sqlbdms,ludb2
ver = 'V12 2010-06-09'
get_utc,dte,/ecs
opt = strupcase(getenv ('REDUCE_OPT'))
printf,lulog,'Procedure reduce_transfer started at '+dte
printf,lulog,'Procedure Version     = '+ver
printf,lulog,'Parameter #1 filename = '+file_name
printf,lulog,'Parameter #2 source   = '+strtrim(string(source),2)
status = 0			; process further, unless told not to
sd = getenv_slash ('LEB_IMG')
cd,sd,CURRENT=lastdir
sdraw = getenv_slash ('LAST_IMG')
rawdir = getenv_slash('RAW')
if sdraw eq '' then sdraw=getenv_slash ('HOME')+'reduce'
bar = strpos (file_name,'_')			; position of underbar
dte = strmid(file_name,0,bar)			; date information only
;
;  Check if memory dump or image file
;
if (strpos(file_name,'mem') gt 1) then begin
   sdraw = sdraw+'leb/mem/'+dte+'/'
   spawn,'mkdir -p '+sdraw, /SH
   spawn,'mv -f ./'+file_name+' '+sdraw, /SH
   cd,sdraw
   printf,lulog,'Processing memory dump '+file_name
;   a = read_mem_dump (file_name)
;
;  update db table MEM_DUMP
;
;   printf,lulog,'Updating table mem_dump '
;   b = get_db_struct ('lasco','mem_dump')
;   b.filename=file_name
;   b.params = a(0:5)
;   db_insert,b
   status = 1  ; don't process further
endif else begin			; must be *.img file
;
;  NOTE:  The header should be read in before renaming to make header 
;         entries correct.
;
;  Read in header only (for speed) and then check if real image header
;  Form appropriate destination subdirectory and then move the file
;
   openr,lu,file_name,/get_lun
   fs = fstat(lu)
   close,lu & free_lun,lu
   if (fs.size eq 58) then begin
      printf,lulog,'Ground to peripheral LP'
      printf,lulog,'Moving file to '+sdraw+'leb/gnd/'+dte+'/'
      sdraw = sdraw+'leb/gnd/'+dte+'/'
      spawn,'mkdir -p '+sdraw, /SH
      status = 1				; don't process further
						; must be image LP
   endif ELSE IF (fs.size EQ 0) THEN BEGIN	;;
	sdraw = './oddballs/'			;; NBR, 12/24/97
      	printf,lulog,'Moving file to '+sdraw	;; file size = 0
	status = 1				;;
   ENDIF else begin
      a = read_leb_image(file_name,hdr,/noimg)
      printf,lulog,'Date Obs = ',hdr.date_obs
      sdraw = rawdir+dte+'/'
      spawn,'mkdir -p '+sdraw, /SH
      printf,lulog,'Imaging LP # = ',hdr.lp_num
      printf,lulog,'Moving file to '+sdraw
      k0 = str2utc('1995/12/01')
      k1 = str2utc(hdr.date_obs)
      get_utc,now
      now.mjd = now.mjd +2			; NBR, 02/03/99
      ;k2 = str2utc('2005/01/01')
      k2 = now
      IF ((k0.mjd GT k1.mjd) OR (k1.mjd GT k2.mjd))  THEN BEGIN
         printf,lulog,'INVALIDDATE:  Date not valid:  Not processing further '
         status = 1				; don't process further
      ENDIF
   endelse
   
   IF keyword_set(TEST) THEN IF file_exist(concat_dir(sdraw,file_name)) THEN return,1 ELSE return,0
    
    cmd='mv -f ./'+file_name+' '+sdraw
    print,cmd
   spawn,cmd, /SH
;
;  Set working directory to the subdirectory where the image is moved to
;  Get today's date in ECS format:  YYYYYMMDD HHMMSS.MMM
;
    print,'cd ',sdraw
   cd,sdraw          ;  
   printf,lulog,'Changing directory to '+sdraw
   dbenv = strupcase(getenv('REDUCE_OPTS'))
   if ( (status eq 0) and (strpos(dbenv,"DBMS") ge 0) ) then begin
      get_utc,today,/ecs
      printf,lulog,'Beginning DBMS processing at '+today
;
;  update db table IMG_HISTORY
;  each history statement has a separate entry in the db table
;
      printf,lulog,'Updating DBMS table = img_history'
      a = get_db_struct ('lasco','img_history')
      a.filename=file_name
      a.date_mod = today
      a.history=ver+"; reduce_transfer,'"+file_name+"',"+string(source,format='(i1)')
      ;db_insert,a
  
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
      lubk=ludb      ; make a copy of ludb
      ludb=ludb2     ; point to the sql db file
      sql_db_insert,a
      ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING *****************  
   endif 					; processing of DBMS
endelse						; processing for *.img file
get_utc,dte,/ecs
printf,lulog,'Procedure reduce_transfer ended at '+dte
for i=0,5 do printf,lulog
return,status
end
