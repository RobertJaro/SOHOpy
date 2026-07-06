pro reduce_main,src,auto=auto,reduce_only=reduce_only, REDO=redo
;+
; @(#)reduce_main.pro	1.46 11/04/15 :LASCO IDL LIBRARY
;
; NAME:				REDUCE_MAIN
;
; PURPOSE:			Main program to search for new files created by
;				DDIS to perform pipeline processing on.
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		REDUCE_MAIN, Src
;
; INPUTS:			None
;
; OPTIONAL INPUTS:		Src = 0 for processing R/T files at GSFC
; 				      1 for processing R/T files at NRL
; 				      2 for processing PB files at NRL
;	
; KEYWORD PARAMETERS:		Auto = if set then use closed_img_file
;                                      if not set then use closed_img_file2
;                               reduce_only -- for use by user reduce only. Nobody  
;                                       else should need it
;   	    	    	    	/REDO	Set if reprocessing data
;
; OUTPUTS:			None
;
; OPTIONAL OUTPUTS:		None
;
; COMMON BLOCKS:		DBMS
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:		Written  RA Howard, NRL
;    Version 1   RAH, 6 Nov 1995,    Initial Release
;    Version 2   rah, 15 Nov 1995,   Added closed_img_file flag file
;                                    Modified log printing
;    Version 3   rah, 18 Nov 1995,   Added source as optional parameter
;    Version 4   rah,  7 Dec 1995,   Minor corrections to version
;    Version 5   rah,  4 Jan 1996,   Correction to handling of .mem files
;    Version 6   rah, 15 Jan 1996,   Minor correction to file name and get_lun,luf
;    Version 7   rah, 18 Jan 1996,   Corrected handling of contents of closed_img_file
;				     to correct FP files
;    Version 8   rah, 09 Apr 1996,   Added check of letter extension to filename
;    Version 9   rah, 19 Apr 1996,   More mods to account for letter extension
;    Version 10  rah, 27 Apr 1996,   Added error handling opening closed_img_file
;    Version 11  rah, 08 May 1996,   Added creation of file for update list
;    Version 12  nbr, 08 Apr 1997,   Changed target directories for .log and .db files
;    Version 13  rah, 26 Aug 1997,   Error handling opening closed_img_file
;    Version 14  rah, 27 Sep 1997,   Handling of files created out of time order
;    Version 15  rah, 16 Jan 1998,   Process mem files first before img files
;    Version 16  nbr, 03 Jun 1998,   Remove old .img dirs from previous session
;    Version 17  rah, 19 Oct 1998,   Remove old log files for GSFC processing
;    Version 18  nbr,  4 Jan 1999,   Add row to .db file to remove QL LEB_HDR
;    Version 19  nbr, 20 Oct 1999,   Send message to user if gap between current and last
;					.img files is > 1 hour; add check for good date
;    Version 20  nbr,  4 Apr 2000,   Halt processing of QL for db update at 2AM; move save lastdate.sav
;    Version 21  nbr, 24 Jul 2000,   Add /SH to spawn commands
;    Version 22 nbr , 17 Oct 2001,   Change filename sent in email for db update halt
;    Version 23 nbr,   1 Feb 2002 - Use /noshell keyword for two spawn commands; move chmod updates to end; Add /SH to SPAWN calls
;    Version 23 nbr,   4 Feb 2002 - Move chmod to correct location
;	        jake,	   030813 - changed mail's to /usr/ucb/mail's
;       Karl Battams  14 Oct 2004 - Add reduce_only keyword to specify LASCO_DATA variable
;       Karl Battams   2 Nov 2005 - Add swap_if_little_endian keyword for opening binary data files
;                                 - Tweak spawn commands (change them to /bin/* -- should work fine for most everyone)
;       Karl Battams  18 Nov 2005 - Replace findfile() with file_search()
;       Karl Battams  26 Dec 2006 - Make some temporary changes to create sql db files. Hope this doesn't upset anybody else...
;                                   If it does, contact karl.battams@nrl.navy.mil
;   	nbr, 27 Aug 2009 - Allow to run if lastdate.sav is not present.
;   	nbr, 31 Aug 2009 - Put sccs tag in ver
;   	nbr, 29 Sep 2009 - Cease writing log+'db/red_'+root+'.db'; only write MySql db file
;   	nbr,  6 Jan 2010 - Add /REDO; code to correctly reprocess data
;   	nbr, 23 Feb 2010 - Change mysql delete statements for LZ data
;   	nbr, 24 Feb 2010 - Remove mysql delete statements to reduce_level_05
;   	nbr,  9 Jun 2010 - Skip input filename if it already exists in $RAW
;   	nbr,  6 Feb 2013 - Set TRUE=0 if not /AUTO
;	nbr, 20 Oct 2014 - Use $DB_DIR for db scripts
;	nbr,  4 Nov 2015 - Make ifiles type long
;
;			PLEASE CORRECTLY USE TABS FOR INDENTATION
;			POORLY INDENTED CODE IS HARD TO READ!
;
;
;-
;
common dbms,ludb,lulog, delflag
common sqlbdms,ludb2
ver = '@(#)reduce_main.pro	1.46 11/04/15'
IF keyword_set(AUTO) THEN true=1 ELSE true=0
leb_img = getenv ('LEB_IMG')
earliest_tai=utc2tai(str2utc('1999/01/01'))
log = getenv_slash ('REDUCE_LOG')

delflag=0
IF keyword_set(REDO) THEN BEGIN
    delflag=1	; in sql_db_insert.pro, add delete row for each table
    msg=[   'Before proceeding, the following steps must be completed:', $
    	    '1. remove level_05/YYMMDD', $
    	    '2. remove $RAW/YYMMDD', $
    	    '3. remove lines for YYMMDD from level_05/../img_hdr.txt', $
    	    '4. remove catalogs/daily/*YYMMDD*', $
    	    '5. reset values in *_num to last image of previous day']
    popup_msg,msg,space=1
ENDIF


;
;  main loop to find and process an image file
;
fnclosed='closed_img_file2' ; this file contains name of last-processed 
if keyword_set (auto) then fnclosed='closed_img_file'

if keyword_set(reduce_only) THEN setenv,'LASCO_DATA=/net/cronus/opt/local/idl_nrl_lib/idl/data'  ; KB 041014

rawdir = getenv('RAW')
;IF src EQ 1 OR src EQ 2 THEN BEGIN	;** 6/3/98, NBR
IF src EQ 9 THEN BEGIN	;** 10/16/98, NBR
	IF src EQ 1 THEN rawfile = rawdir+'/QL_RAW.contents' ELSE rawfile = rawdir+'/LZ_RAW.contents'
	spawn,'du -k '+rawdir+'/9* >> '+rawfile,/sh	;** 6/10/98, NBR
	spawn,'ll '+rawdir+'/9* >> '+rawfile,/sh
	print,'Removing '
	spawn,'ls -d '+rawdir+'/9*',/sh
	wait,5
	spawn,'/bin/rm -fr '+rawdir+'/9*',/sh
ENDIF

IF file_exist(leb_img+'/lastdate.sav') THEN restore,leb_img+'/lastdate.sav'

repeat begin				; 1
	cd,leb_img
	;
	;  Find all mem or leb files in $LEB_IMG
	;
	g = file_search('*.mem')		; check for mem files
	sg = size(g)
	files = file_search('*.img*')
	siz = size(files)
	sf  = siz
	if (sg(0) ne 0) then begin
		if (siz(0) eq 0)  then files=g else files=[g,files]
		siz=size(files)
	endif
	IF files(0) EQ '' THEN nfiles = 0 ELSE nfiles = siz(1)       ;** added 980423 SEP
	ifiles = 0L
	;PRINT,nfiles,ifiles,files(0)
	REPEAT BEGIN				; 2
		;
		;  Wait until 'closed_img_file' exists, open it, read the contents (file name)
		;  'closed_img_file' is written by DDIS when it closes an img or mem file.
		;  the contents are the file name that was just closed.  Since the file names
		;  are constructed with the date and time of the file, we know when a file
		;  has been closed by looking at the times and making sure that the img or mem
		;  file is not dated after the time indicated by the name in 'closed_img_file'.
		;
		;  Also, if the last time through the loop, looking for a closed file name,
		;  there were no files to be processed, then just loop until DDIS changes
		;  the name in 'closed_img_file'
		;
		lastfn = ''
		repeat begin				; 3
			cd,leb_img
			get_lun,luf
			repeat begin			; 4
				a=systime()
				hour = strmid(a,11,2)
				; ** Halt processing for QL before database update at 2 AM.
				IF hour GE 1 and hour LT 3 and src EQ 1 THEN BEGIN
					spawn,'whoami',user,/sh
					user=user(0)
					message=user+', source='+TRIM(STRING(src))+': processing stopped at '+filename
					subject='reduce_main stopped'
					openw,tlun,'maildummy',/get_lun
					printf,tlun,message
					close,tlun
					free_lun,tlun
					spawn,'/usr/ucb/mail -s "'+subject+'" '+user+' < maildummy',/sh
					save, last_tai,date_str,filename=leb_img+'/lastdate.sav'
					return
				ENDIF
				; **
				done = 1
				openr,luf,fnclosed,error=err,/swap_if_little_endian
				if (err gt 0) then begin
					print,'Error opening '+fnclosed
					wait,60.
					done = 0
				endif else begin
					ON_IOERROR, BADIO
					fn = ''
					IF (EOF(luf)) THEN BEGIN
						PRINT,'Error reading '+fnclosed
						WAIT,10.
						done = 0
					ENDIF ELSE BEGIN
						readf,luf,fn
						if (strpos(fn,'FP') ne -1) then begin
							nc = strpos(fn,'.')
							fn = strmid (fn,nc-13,14)+'img'
						endif
						close,luf
						if (fn eq lastfn) then begin
							done=0
							IF datatype(last_tai) EQ 'UND' THEN $
							message,'The content of closed_img_file(2) must be the filename of the LAST file to be processed.'
							save, last_tai,date_str,filename=leb_img+'/lastdate.sav'
							spawn,'/usr/bin/chmod a+x '+log+'updates/update_*',/sh
; *********************************************************************************************************************
;	REDUCE_MAIN ends here:
; *********************************************************************************************************************
							IF not keyword_set (auto) then return
; *********************************************************************************************************************
							print,'Filename in '+fnclosed+' same as last so must wait'
							;
							;	Check to see if GSFC processing and if so then remove log files from
							;	dates that were dated at least 4 days ago.
							;
							IF (src EQ 0)  THEN BEGIN
								GET_UTC,dte
								dte.mjd = dte.mjd-4		; Remove 4 days ago
								ymd = UTC2YYMMDD(dte)
								;
								;	First check for red files in $REDUCE_LOG/log
								;	Find the filenames that match our date.
								;	Then delete filenames that are even earlier than our date.
								;	This takes care of any oddballs.
								;
								oldfn = GETENV('REDUCE_LOG')+'/log/red_*.log'
								oldf = file_search(oldfn)
								s = SIZE(oldf)
								IF (s(0) EQ 0)  THEN wait,60. ELSE BEGIN
									fpos = STRPOS(oldf,ymd)		; Do any files match our date?
									wf = WHERE(fpos NE -1,nwf)
									IF (nwf EQ 0)  THEN WAIT,60. ELSE BEGIN
									lastnw = wf(nwf-1)		; Pick up last file that matches
									PRINT,'Removing old log files'
									FOR iwf=0,lastnw DO SPAWN,'/bin/rm '+oldf(iwf), /SH	; Delete all files up to last
										;
										;	Now check for unpk files in $REDUCE_LOG
										;
										oldfn = GETENV('REDUCE_LOG')+'/unpk_*.log'
										oldf = file_search(oldfn)
										s = SIZE(oldf)
										IF (s(0) NE 0)  THEN BEGIN
											fpos = STRPOS(oldf,ymd)
											wf = WHERE(fpos NE -1,nwf)
											IF (nwf NE 0)  THEN BEGIN
												lastnw = wf(nwf-1)
												FOR iwf=0,lastnw DO SPAWN,'/bin/rm '+oldf(iwf), /SH
											ENDIF
										ENDIF
									ENDELSE
								ENDELSE
							ENDIF ELSE wait,60.
						endif
					ENDELSE
				endelse
				GOTO,CONT
BADIO:
				PRINT,'%ERROR: REDUCE_MAIN, IO ERROR, type='+!err_string+' on file '+fnclosed
				WAIT,10.
				done = 0
CONT:
			endrep until (done eq 1)			; 4
			ON_IOERROR, NULL
			free_lun,luf
			lastfn = fn
			;
			;  find the last occurence of the directory path, if any, and extract
			;  only the file name
			;
			slash = str_index (fn,'/')		;  unix only
			s = size(slash)
			if (s(0) ne 0) then slash=slash(s(1)-1)
			fn=strmid(fn,slash+1,strlen(fn))
			date_fn = str2utc(ddistim2ecs(strmid(fn,0,strlen(fn)-4)))
			;
			;  See if the first file in $LEB_IMG to be processed
			;  is earlier than or equal to fn.
			;  We know that findfile will return the earliest file first.  All mem
			;  files will be processed before any img file.
			;  DDIS adds a character A, B, ... to .img if the time is the same as the
			;  preceeding file. (????)
			;
			if (nfiles eq 0) then GOTO, CONT2 $
			else begin
				filename = files(ifiles)
				;
				;  Find the root portion of the file name and form file names
				;
				n = strpos(filename,'.')
				root = strmid (filename,0,n)
				date_str = ddistim2ecs(root)
				date_file = str2utc(date_str)
				cur_tai = utc2tai(date_file)
				ext = STRMID (filename,n+1,n)
				IF (STRUPCASE(STRMID(ext,0,3)) EQ 'MEM')  THEN done=1 ELSE BEGIN
					GET_UTC,dte		; **NBR, moved 11/1/99
					diff = diff2time(date_fn,date_file)
					CASE diff OF
						1:   BEGIN		; first file is later than closed_img_file
								IF (sf(0) EQ 1)  THEN BEGIN	; number of .img files>0
									;
									;  Check to see if first file is a valid date, between 12/1/95 and current
									;  date.  If it is an invalid date then process the image file.  IF it is
									;  a valid date then wait.
									;
									dmjd=date_file.mjd
									IF (dmjd GT 50052) AND (dmjd LE dte.mjd)  $
										THEN done=0 ELSE done=1
								ENDIF ELSE done=0
							END
						0:   BEGIN
								;
								;  root portion agrees with filename, check extensions
								;  first check if filename has extra character and if not must
								;  be done.
								;
								IF ( STRLEN(ext) EQ 3 ) THEN done=1 ELSE BEGIN
									;
									;  filename has extra character so check last character in fn
									;
									fnext = STRMID(fn, STRPOS(fn,'.')+1,n)
									IF ( STRLEN(fnext) EQ 3 ) THEN done=0 ELSE BEGIN
										;
										;  if extension to fn only has 3 characters then not done
										;
										fnchar = STRMID ( fnext, STRLEN (fnext)-1,1)
										fchar = STRMID ( ext, STRLEN (ext)-1,1)
										IF ( fchar LE fnchar ) THEN done=1 ELSE done=0
									ENDELSE
								ENDELSE
							END
					-1:  done=1		; img date is earlier, so process it
				ENDCASE
			ENDELSE
		ENDELSE
		ENDREP UNTIL (done EQ 1)			; 3
		;
		;  OK.  File must be closed, so begin processing
		;
		print,'Processing file: '+filename
		;
		;  Open a log file, and print pertinent information
		;
		lastfn = ''   ;  process anything next time
		logroot = log+'log/red_'+root
		get_utc,dte,/ecs
		openw,lulog,logroot+'.log',/get_lun,/append
		printf,lulog,'Procedure = reduce_main'
		printf,lulog,'Version   = '+ver
		printf,lulog,'Date      = '+dte
		spawn,['/bin/hostname','-f'],host,/noshell
		printf,lulog,'Host      = '+host[0]
		;spawn,['/bin/domainname'],dom,/noshell
		;printf,lulog,'Domain    = '+dom
		;
		;  Assign the source designation: 0=> GSFC R/T
		;  1 => NRL R/T and 2=>NRL replay (either level 0 or quick look)
		;
		if (n_params() eq 0) then begin
			if (dom(0) eq 'nascom.nasa.gov') then source=0 else begin
				if (host(0) eq 'calliope') then source=1 else source=2
			endelse
		endif else source=src
		printf,lulog,'Source    =',source
		;
		;  Get the processing options from environment string
		;
		opt = strupcase(getenv ('REDUCE_OPTS'))
		printf,lulog,'Reduce options = '+opt
		;
		;  now open the file to get the file size
		;
		openr,lu,filename,/get_lun,/swap_if_little_endian
		st=fstat(lu)
		oldsize=st.size
		close,lu
		free_lun,lu
		printf,lulog,'Reducing image file  ='+filename
		printf,lulog,'File size (bytes)    =',oldsize
		
		;  
		;  Make sure file has not already been processed!
		;
		IF (reduce_transfer(filename,source,/TEST)) THEN BEGIN
		    ; file has already been processed
		    msg=filename+' has already been processed; aborting.'
		    print,msg
		    wait,2
		    printf,lulog,msg
		    goto,skipped
		ENDIF
		    
		;
		;  If generating the DBMS update commands, then open a file
		;
		;stop
		if (strpos(opt,'DBMS') ge 0)   then begin
			dbfile = log+'db/red_'+root+'.db'
			;openw,ludb,dbfile,/get_lun
                        
                        sqlfile = getenv_slash('DB_DIR')+'las_'+root+'.db' 
                        openw,ludb2,sqlfile,/get_lun                                        ; *************** KB 12/26/07 ***************
                        ludb=ludb2
			
			IF src EQ 2 THEN BEGIN
				;printf,ludb,'use lasco
				;printf,ludb,'go'
				;obsdate = utc2str(date_file,/ecs,/date_only)
				;printf,ludb,'delete img_leb_hdr from img_files,img_leb_hdr where '
				;printf,ludb,'img_files.fileorig= "'+filename+'" and'
				;printf,ludb,'img_leb_hdr.date_mod = img_files.date_mod and'
				;printf,ludb,'img_leb_hdr.fileorig = img_files.fileorig and source = 1'
				;printf,ludb,'go'
                                ; FOR SQL purposes --->
				;
				; Do this in reduce_level_05.pro because need date_obs
				;
                                ; <--- END SQL stuff
			ENDIF
			printf,lulog,'DB update file = '+dbfile
		endif
		;
		;  Now process the image file after changing default directory to
		;  $IMAGES
		;
		;images = getenv_slash ('IMAGES')
		;cd,images
		;printf,lulog,'Changing to directory ='+images
		for i=0,5 do printf,lulog

		; **NBR, 10/20/99
		IF datatype(last_tai) EQ 'UND' THEN last_tai=earliest_tai
		num_s =cur_tai - last_tai
		now_tai = utc2tai(dte)
		IF cur_tai LT now_tai and cur_tai GT earliest_tai and STRMID(ext,0,3) EQ 'img' THEN BEGIN
			IF num_s GT 60*60 THEN BEGIN		; IF time difference GT 1 hour and .img file
				; then send a message
				minutes=STRING(num_s/60., FORMAT='(I4)')
				spawn,'whoami',user,/sh
				user=user(0)
				message=user+', source='+TRIM(STRING(src))+':'+minutes+' minute gap at '+date_str
				subject=user+TRIM(STRING(src))+':'+minutes+' minute gap'
				openw,tlun,'maildummy',/get_lun
				printf,tlun,message
				close,tlun
				free_lun,tlun
				;spawn,'/usr/ucb/mail -s "'+subject+'" '+user+' < maildummy',/sh
                                spawn,'/bin/mail -s "'+subject+'" '+user+' < maildummy',/sh
			ENDIF
			last_tai=cur_tai
		ENDIF

		reduce_image,filename,source
		if (strpos(opt,'DBMS') ge 0)   then begin
			;close,ludb
                        printf,ludb2,'commit;'
                        close,ludb2  ; *************** KB 12/26/07 *************** 
			get_utc,dte,/date_only,/ecs
			dte = strmid(dte,0,4)+strmid(dte,5,2)+strmid(dte,8,2)
			IF (src eq 2) THEN tt='.final_lst' ELSE tt='.quick_lst'
			;openw,ludb,log+'updates/update_'+dte+tt,/append
			;printf,ludb,'$1 < '+dbfile
			;close,ludb
			;spawn,['/usr/bin/chmod a+x ',log+'updates/update_'+dte+tt],/noshell
			;free_lun,ludb
			free_lun,ludb2  ; *************** KB 12/26/07 *************** 
			if (strpos(opt,'UPDATE') ge 0)   then $
				spawn,'isql '+dbfile    ,/sh
		endif
		get_utc,dte,/ecs
		printf,lulog,'Reduce_main completed at '+dte
		
		skipped:
		close,lulog
		free_lun,lulog
		ifiles = ifiles+1
	ENDREP UNTIL (ifiles GE nfiles)		; 2
help,true
CONT2:
endrep until (true eq 0)			; 1

;return
end
