;+
; NAME:
;	REDUCE_DAILY
;
; PURPOSE:
;	This procedure performs the reduction tasks that are done on a daily basis.
;
; CATEGORY:
;	LASCO REDUCE
;
; CALLING SEQUENCE:
;	REDUCE_DAILY
;
; INPUTS:
;	None
;
; OPTIONAL INPUTS:
;	STDate:	A string in the format YYMMDD that defines the starting date to be processed.
;		If not present, the routine looks at the dates in daily.dat
;	ENDATE:	A string in the format YYMMDD that defines the ending date to be processed.
;		If not present, then only one date is processed
;	
; KEYWORD PARAMETERS:
;	/NOEXP	Do not do exposure correction factors, default for LZ.
;	/LZ:	If present the level 0 data are to be processed.  The default is
;		to process the quick look data.
;	/NOMED:	Do not do daily median images
;   	/NOMON: Do not do make_all_months.pro
;	/NO_C3:	Do not do C3 daily medians
;
; PROCEDURE:
;	This procedure calls the routines to do the following tasks:
;
;		check the monexp file for duplicates
;		generate the daily median image
;		generate PB and %P images
;
;	All 4 telescopes are processed.
;
; EXAMPLE:
;	To process the quick look files for June 1, 1998:
;
;		REDUCE_DAILY,'980601'
;
;	To process the level 0 files for June 1, 1998:
;
;		REDUCE_DAILY,'980601',/lz
;
; MODIFICATION HISTORY:
; 	Written by:	RA Howard, NRL, 6/19/98
;	NB Rich	 6/23/98	Comment out make-movie calls
;	NB Rich 11/06/98 	Add DO_POLARIZE
;	NB Rich 07/07/99	Fixed typo with 'endate'
;	NB Rich    12/99	Add NOMED keyword
;	NB Rich	   01/00	Add NO_C3 keyword
;       D  Wang 12 Jul 00       Added /VIG,/PTF to DO_POLARIZ call
;	NB Rich 11 Jan 01	Fix call to open weekly.dat
;	NB Rich 13 Apr 01 	Add NOREBIN to calls to MK_DAILY_MED
;	NB Rich 31 Jan 02	Add /SH to spawn calls
;	jake	030716		removing old commented out code
;						fixing indentations
;       K Battams 051021        Add ,/swap_if_little_endian keyword to OPEN calls
;   	NBRich  16Jun09     	Added catchupcmap (in $NRL_LIB/secchi/idl/nrlgen)
;   	NBRich	26Jan11     	Add compute_monexp_factors
;	NBRich	27Jun12		Option to skip compute_monexp_factors
;	NBRich  13Jul12		Implement _EXTRA
;   	NBRich  27Jul12     	Do not LOADCT so works without X
;   	NBRich	 8Mar13     	Implement  /NOPOL
;   	NBRich	 1Apr13     	Move Carrmap update and prompt for db to be done and do make_all_months
;
;	%W% %H%: LASCO IDL LIBRARY
;-
;

pro reduce_daily,stdate,endate,LZ=LZ, NOMED=nomed, NO_C3=no_c3, NOEXP=noexp, NOPOL=nopol, $
	NOMON=nomon, _EXTRA=_extra

	IF KEYWORD_SET(LZ)  THEN BEGIN
		QL=0 
		dir = GETENV('LZ_IMG')
		IF ~keyword_set(NOEXP) THEN BEGIN
    	    		dteb = YYMMDD2UTC(endate)
			dteb.mjd=dteb.mjd+1
			CHECK_MONEXP_DUPS,stdate,utc2yymmdd(dteb)
			compute_monexp_factors,'c2',stdate,endate, _EXTRA=_extra ;,/BATCH
    	    		compute_monexp_factors,'c3',stdate,endate, _EXTRA=_extra ;,/BATCH
		ENDIF
	ENDIF ELSE BEGIN
		QL=1
		dir = GETENV('QL_IMG')
	ENDELSE
	np = N_PARAMS()
	IF (np EQ 0) THEN BEGIN
		OPENR,lu,dir+'/daily.dat',/GET_LUN,/swap_if_little_endian
		s = ''
		nd = 0
		REPEAT BEGIN
			READF,lu,s
			IF (nd EQ 0)  THEN BEGIN
				dates = [s]
				nd = 1
			ENDIF ELSE BEGIN
				dates = [dates,s]
				nd = nd+1
			ENDELSE
		ENDREP UNTIL EOF(lu)
		s = SORT(dates)
		dates = dates(s)
		CLOSE,lu
	ENDIF ELSE BEGIN
		dates = [stdate]
		IF (np EQ 2)  THEN BEGIN
			dtea = YYMMDD2UTC(stdate)
			dteb = YYMMDD2UTC(endate)
			dte = dtea
			FOR i=dtea.mjd+1,dteb.mjd DO BEGIN
				dte.mjd = i
				s=UTC2YYMMDD(dte)
				dates = [dates,s]
			ENDFOR
		ENDIF
	ENDELSE
	nd = N_ELEMENTS(dates)
	GET_LUN,luout
	
	FOR id=0,nd-1 DO BEGIN
		PRINT,'REDUCE_DAILY: Processing '+dates(id)
		IF NOT(keyword_set(NOMED)) THEN BEGIN
			;LOADCT,0
			MK_DAILY_MED,'c2',dates(id),QL=ql,/NOREBIN,_EXTRA=_extra
			IF NOT(keyword_set(NO_C3)) THEN MK_DAILY_MED,'c3',dates(id),QL=ql,/NOREBIN,_EXTRA=_extra
		ENDIF ELSE message,'Skipping MK_DAILY_MED',/info
		IF not (keyword_set(NOPOL)) THEN BEGIN
		OPENU,luout,dir+'/weekly.dat',/append,/swap_if_little_endian
		printF,luout,dates(id)
		CLOSE,luout
		dte = dates(id)
		utc=yymmdd2utc(dte)
		print,'Computing polarization images for ',dte
		poldir = getenv('POLDIR')
		ecsdte = utc2str(utc,/ecs,/date_only)
		dirdate = strmid(ecsdte,0,4)+'_'+strmid(ecsdte,5,2)	;** Ex. '1999_03'
		savedir2 = poldir+'/'+dirdate+'/vig/c2'
		savedir3 = poldir+'/'+dirdate+'/vig/c3'
		dummy = file_exist(savedir2)
		IF ~dummy THEN BEGIN
			spawn, 'mkdir -p '+savedir2, /SH
			spawn, 'mkdir '+savedir3, /SH
		ENDIF
		hdrtxt = dir+'/level_05/'+dte+'/c2/img_hdr.txt'
		openw,tlun,'~/pol_list.txt',/get_lun
		printf,tlun,hdrtxt
		close,tlun
		free_lun,tlun
		cam = 2

		DO_POLARIZ, INDEXLIST='~/pol_list.txt', SAVEPATH=savedir2, CAMERA=cam, $
			/VIG,/PTF, /SAVE_POLARIZ, /SAVE_PERCENT, /AUTO, _EXTRA=_extra
		hdrtxt = dir+'/level_05/'+dte+'/c3/img_hdr.txt'
		openw,tlun,'~/pol_list.txt',/get_lun
		printf,tlun,hdrtxt
		close,tlun
		free_lun,tlun
		cam = 3

		DO_POLARIZ, INDEXLIST='~/pol_list.txt', SAVEPATH=savedir3, CAMERA=cam, $
			/VIG,/PTF,/SAVE_POLARIZ, /SAVE_PERCENT, /AUTO, /FIXC3ZERO, _EXTRA=_extra
    	    	ENDIF ELSE message,'Skipping do_polariz',/info
	ENDFOR
	IF (np EQ 0)  THEN BEGIN
		SPAWN,'/bin/rm '+dir+'/daily.dat', /SH
		FREE_LUN,lu
	ENDIF
	FREE_LUN,luout
	
	IF keyword_set(LZ) and ~keyword_set(NOMON) THEN BEGIN
	    make_all_months,'c2',stdate,endate
	    IF ~keyword_set(NO_C3) THEN make_all_months,'c3',stdate,endate
	ENDIF
;
	;++++ Update Carrington Maps ++++
	;
	utst=yymmdd2utc(dates[0])
	utdbef=utst
	utdbef.mjd=utdbef.mjd-1
	; Assuming current batch is not in database yet, so start with last day of previous batch
	inp=''
	IF keyword_set(LZ) THEN BEGIN
	    utdbef=yymmdd2utc(dates[nd-1])
	    inp=''
	    read,'Hit return when mysql_update_lasco is complete, else s to skip carrington maps.',inp
	    IF inp EQ 's' THEN return
	ENDIF
	catchupcmap,utdbef,_EXTRA=_extra
    	; END update carrington maps
	
	RETURN
END
