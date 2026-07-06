function reduce_level_05,file_name,fits_name,source, DB_ONLY=db_only
;+
; NAME:
;		REDUCE_LEVEL_05
;
; PURPOSE:
;		Perform the Level 0.5 Processing
;
; CATEGORY:
;		REDUCTION
;
; CALLING SEQUENCE:
;		Result = REDUCE_LEVEL_05 (File_name,Fits_name,Source)
;
; INPUTS:
;		File_name = Name of file to process in the 
;				            format YYMMDD_HHMMSS.img
;		Source    = parameter indicating file source
;
; OPTIONAL INPUTS:
;		Fits_name = If DB_ONLY is set, then use this file to create 
;				a database update file
;	
; KEYWORD PARAMETERS:
;	DB_ONLY		If set, then only create database update file from 
;			input fits_name
;
; OUTPUTS:
; 		Fits_name = Name of FITS file created
;   		Result = 0 do process to level 1
;			 1 don't process to level 1
;
; OPTIONAL OUTPUTS:
;		None
;
; COMMON BLOCKS:
;		DBMS
;
; PROCEDURE:
;
;   processes a compressed LEB image created by DDIS to level 0.5
;   the image is assumed to be located in the current directory
;   level 0.5 consists of 
;           decompression
;           remove readout port effect
;           rotate image to put solar north at top of image
;           make FITS file
;	    generate DBMS update records
;           make gif file for lastimg_cx
;
;   The level 0.5 image file is named according to the standard name 
;   convention in the subdirectory tree:  
;              $IMAGES/level_05/date/tel
;   Note: if dark, cal lamp or continuous image then put in 
;              $IMAGES/misc/tel/[dark,lamp,cont]/date
;         if header from Ground to Peripheral LP then put in 
;              $IMAGES/misc/leb/gnd/date
;
; MODIFICATION HISTORY:
; 	WRITTEN    RA Howard, 3 October 1995
;   Version 1      rah    3 Oct 95    Initial release
;           2      rah    6 Nov 95    Add log output
;           3      rah   15 Nov 95    Modified log output
;           4      rah   11 Dec 95    Changed call to write_last_image to be 
;                                     fits header
;           5      rah   15 Dec 95    Changed call to rectify to be fits header
;           6      rah   11 Jan 96    Changed rectify to include solar north
;           7      rah   12 Jan 96    Added call to rectify P1, P2 coords
;           8      rah   17 Jan 96    Corrected handling of read_leb_image 
;                                     image read error
;           9      rah   29 Mar 96    Rearranged reduce_img_hdr to be after 
;				      changing to date directory to be able to
;				      write img hdr also to date directory.
;				      Changed browse image to be 128 x 128
;				      Changed browse name to form from fits
;                                     Added call to REDUCE_STATISTICS
;                                     Added call to fill up DBMS IMG_STATS
;          10      rah   03 Apr 96    Added DBMS update of leb_img_hdr & _ip
;                                     Added non-hdr parameters to leb_img_hdr
;          11      rah   10 Apr 96    Only compute stats if image found
;          12      rah   15 Apr 96    Added call to REDUCE_REFCOORD
;          13      sep   04 Jun 96    Added compression_str to img_leb_hdr table
;                                     Corrected insertions into img_ip table
;          14      sep   28 Jun 96    Added chmod 640 on .fts files
;          15      sep   17 Jul 96    Modified for new LEB hdr (obev145+)
;                                     added version and fp_order to DB updates.
;          16      sep   02 Oct 96    added proc_time, p1row, p1col, p2row, p2col to DB updates.
;          17      rah   21 Oct 96    added fits_hdr in call to make_browse
;	   18	   nbr   11 Mar 97    print FITS_filename and directory 
;	   19	   rah   23 Mar 97    moved REDUCE_REFCOORD and REDUCE_STATISTIC
;                                     to always process, not just if DISPLAY
;                                     Also, added call to CHECK_OBESUMERROR
;          20      sep   13 Jun 97    Modified for new LEB hdr (obev203+)
;          21      aee   27 Jun 97    Added unique_os field to img_leb_hdr
;          22      rah   18 Jul 97    Check for image summing/differencing
;          23      sep   14 Apr 98    Modified diskpath entry to use $IMAGES (always /net/corona/cplex..)
;          24      rah   12 Jun 98    Add monexp and dark calcs
;	   25      nbr   31 Jul 98    Change diskpath to use $DSKPATH
;	   26	   nbr   22 Oct 98    Use LASCO_FITSHDR2STRUCT, not FITSHDR2STRUCT
;	   27	   nbr   09 Mar 99    Set a.dateorig='NULL' for img_leb_hdr table
;	   28	   nbr   12 Apr 99    Set chmod to 644 on .fts files
;	nbr	29 Aug 00 - Change to SCCS version for ver; Use $LAST_IMG as location
;			    of link directory if different from $IMAGES
;          30      aee   21 Nov 00    Subtract lpulse from exp3 (and therefore from exptime)
;                                     for cal lamp images on and after july 28, 1997.
;	nbr	22 Jan 01 - Add door_cls output directory
;	nbr 	30 Nov 01 - Add DB_ONLY option
;	nbr	11 Dec 01 - Fix ss variable definition
;	nbr	 1 Feb 02 - Add /SH to SPAWN calls
;	jake	030721	added CROTA[12] keywords to EIT images
;					(these keywords are added to LASCO in REDUCE_REFCOORD)
;	jake	030804	replaced GET_SOHO_ROLL with GET_CROTA
;       Karl Battams   2 Nov 2005 - Add swap_if_little_endian keyword for opening binary data files
;       Karl Battams   Dec26,2007 - Made some changes to test sql db script generating. Sorry if I break stuff...
;   	N.Rich, 2009-09-29  Stop doing db_insert; ludb=ludb2
;   	N.Rich, 2010-02-24  DATE in fits_hdr matches database; do delete img_leb_hdr if delflag
;   	N.Rich, 2010-03-27  Delete img_leb_hdr from database if source >1                                     
;   	N.Rich, 2010-08-23  Generate yymmdd link in $LAST_IMG/level_05; use /NOSHELL for spawn
;   	N.Rich, 2010-10-01  Fix a.diskpath
;
; SCCS variables for IDL use: 
version=  '@(#)reduce_level_05.pro	1.38 02/15/12' ; LASCO IDL LIBRARY
;
;
;-
;
common dbms,ludb,lulog, delflag
common sqlbdms,ludb2
common total_exp,tot_exp
COMMON reduce_history, cmnver, prev_a, prev_hdr, zblocks0

;ver = 'V24 12 Jun 98'
ver = strmid(version,4,strlen(version))
GET_UTC,dte,/ecs
PRINTF,lulog,'Procedure reduce_level_05 started at '+dte
PRINTF,lulog,'Version   = '+ver
PRINTF,lulog,'Input Parameter #1, file_name = '+file_name
PRINTF,lulog,'Input Parameter #3, source    = '+STRTRIM(STRING(source),2)
status=0		; process further unless find otherwise
opt=STRUPCASE(GETENV('REDUCE_OPTS'))
CASE source OF
     0:  s='3'
     1:  s='1'
     2:  s='2'
     ELSE: s='t'
ENDCASE

max_hdr_size = 100	; max number of bytes in header
;
;   Get environment variable for $IMAGES if set, else set to $HOME
;   Check for / at the end of the string
;
fitsdir = GETENV_slash ('IMAGES')
IF fitsdir EQ '' THEN fitsdir = GETENV_slash ( 'HOME' )
lastimg = GETENV_SLASH('LAST_IMG')

;
;  Check if header only
;
IF (DATATYPE(tot_exp) EQ 'UND') THEN tot_exp=0.0
PRINTF,lulog,'Processing file '+file_name
OPENR,lutemp,file_name,/get_lun,/swap_if_little_endian
sz = FSTAT(lutemp)
sz = sz.size
CLOSE,lutemp
FREE_LUN,lutemp
IF (sz LT 200)  THEN BEGIN
   a=READ_LEB_IMAGE (file_name,hdr,/noimg)
   hdr_only = 1
   ss='Only found a header'
   tot_exp = tot_exp+hdr.exptime
ENDIF ELSE BEGIN
   a=READ_LEB_IMAGE (file_name,hdr)
   siz=size(a)
   IF (siz(0) EQ 0)  THEN BEGIN
      ss='Found a header.  Error Reading in image'
      hdr_only = 1
      hdr.comp_bpx = 0
      hdr.comp_cf = 0
   ENDIF ELSE BEGIN
      ss='Found a header and image'
      hdr_only = 0
      npix = where(a gt 0)		; non-zero pixels
      bits_per_pix = 8.*float(sz)/n_elements(npix)
      print,'bits per pixel = ',bits_per_pix
      print,'compression factor = ',16./bits_per_pix
      hdr.comp_bpx = bits_per_pix
      hdr.comp_cf = 16./bits_per_pix
      check_sum_diff,a,hdr,tot_exp
      tot_exp = 0
   ENDELSE
ENDELSE

CASE hdr.camera OF
   0:  BEGIN & tel='1' & telescope=0 & END
   1:  BEGIN & tel='2' & telescope=1 & END
   2:  BEGIN & tel='3' & telescope=2 & END
   3:  BEGIN & tel='4' & telescope=3 & END
ELSE:  BEGIN & tel='z' & telescope=4 & END
ENDCASE
PRINTF,lulog,ss+' for telescope = C'+tel
strs = STRING(source,format='(i1)')
PRINTF,lulog,'Source    = '+strs

IF NOT(keyword_set(DB_ONLY)) THEN BEGIN
;
;   generate standard file name:  tsNNNNNN.ext
;   where t = telescope type
;         s = source
;    NNNNNN = image number 
;
;   first get the next number for the file name of this source/telescope
;
file_num = GET_NEW_FILE_NUMBER (tel,source)          ;standard naming convention
file_num = STRING(file_num,format='(i6.6)')     ;convert to 6 char string 
                                                ;with leading zeroes
PRINTF,lulog,'File_num = '+file_num
;
;    Make Standard File Name for FITS file
;
fits_root = STRTRIM(tel,2)+STRTRIM(s,2)+STRTRIM(STRING(file_num),2)
IF (tel EQ 'z') THEN fits_name=fits_root+'.raw' ELSE fits_name=fits_root+'.fts'
ENDIF 	; DB_ONLY not set

  PRINTF,lulog,'FITS file name = '+fits_name
  PRINT,'FITS file name = '+fits_name
hdr.fileorig = file_name
hdr.filename = fits_name
sver = ver+",'"+file_name+"','"+fits_name+"',"
sver = sver+STRTRIM(STRING(source),2)
;
;
; For cal lamps taken on and after July 28, 1997, subtract the long pulse from 
; exp3. It is mistakenly added to the exp3 by the flight software. This has to be
; done before to the call to MAKE_FITS_HDR since MAKE_FITS_HDR uses the exp3 to 
; generate the exptime.
;
IF (hdr.lp_num EQ 17 AND hdr.date_obs GE '1997/07/28 00/00/00.000') THEN BEGIN 
  hdr.exp3= hdr.exp3 - (hdr.lpulse/10.0)*2048.0 ;lpulse is in 1/10 sec but exp3 is in 1/2048 sec.
  PRINTF,lulog,'Removed lpulse from exp3 for cal lamp image '+hdr.filename
  PRINT,'Removed lpulse from exp3 for cal lamp image '+hdr.filename
ENDIF
;
;
;   Now make FITS header
;
fits_hdr = MAKE_FITS_HDR(hdr,a)

IF (tel NE 'z') THEN BEGIN
;
;   Add rectified coordinates R1 and R2 to the FITS header 
;   Set them equal to P1 and P2, by setting the effective port to 'E'
;
  REDUCE_RECTIFY_P1P2,'E',fits_hdr
;
;  Add date to subdirectory
;
  dte = hdr.date_obs
;
; format of DATE_OBS is YYYY/MM/DD HH/MM/SS.MMM
; put into the format YYMMDD
;
  datesd = STRMID(dte,2,2)+STRMID(dte,5,2)+STRMID(dte,8,2)
  PRINTF,lulog,'Date subdirectory: = '+datesd
  PRINT,'Date subdirectory: = '+datesd
;
;   get LP number to check if calibration type image:
;          dark (LP #5), cal lamp (LP #17), continuous (LP #7)
;   or if ground to peripheral (LP #11)
;   or door closed normal image (hdr.door_pos eq 1 and lpnum ne 5,7,17,11) - nbr, 1/22/01
;   if one of these LPs then put in appropriate subdirectory 
;
  lpnum = hdr.lp_num
  PRINTF,lulog,'LEB Program generating image = ',lpnum
  status=1
  teldir=''
  CASE lpnum OF
  5:   sb = 'misc/c'+tel+'/dark/'+datesd
  7:   sb = 'misc/c'+tel+'/cont/'+datesd
  17:  sb = 'misc/c'+tel+'/lamp/'+datesd
  11:  sb = 'misc/leb/gnd/'+datesd		; this should never happen; level_05 should not be called
  ELSE: BEGIN
          status=0
          sb = 'level_05/'+datesd
	  teldir='/c'+tel
          IF (hdr_only EQ 0) THEN BEGIN
             readport=['A','B','C','D']
             PRINTF,lulog,'Rectifying image from readout port '+readport(hdr.readport)+' for telescope '+tel
;
;    Remove readout port effect, also puts solar north "up"
;
             img=REDUCE_RECTIFY (a,fits_hdr)
;             img=SOLAR_NORTH_UP(reduce_rectify (a,fits_hdr),telescope)
          ENDIF
	  IF hdr.door_pos EQ 1 THEN sb = 'misc/door_cls/c'+tel+'/'+datesd	;nbr, 1/22/01
        ENDELSE
  ENDCASE
ENDIF ELSE BEGIN
  sb = STRMID (file_name,0,8)		; take date from process date
  sb = 'level_05/'+sb+'cz'
  status=1
ENDELSE
sd = fitsdir+sb+teldir
linkd = lastimg +'level_05/'+datesd

IF (status EQ 1) THEN img=a

GET_UTC,today,/ecs
; Reset date_mod to match database


IF NOT(keyword_set(DB_ONLY)) THEN BEGIN
;
;   make full subdirectory and change to it
;
    	IF ~FILE_EXIST(sd) THEN BEGIN	
	    PRINTF,lulog,'Making subdirectory '+sd
	    SPAWN,['mkdir','-p',sd] ,/noshell		; make sure IMAGES directory exists
	ENDIF
	PRINTF,lulog,'Changing to subdirectory'
	CD,sd
	;
	;   Write the header to the current list of images $LAST_IMG/img_hdr.txt
	;   as well as current directory.
	;
	REDUCE_IMG_HDR,fits_hdr
	
	; 
	;  Update LINK directory

	IF fitsdir NE lastimg and status EQ 0  THEN BEGIN
    	    IF ~FILE_EXIST(linkd) THEN BEGIN
	    	PRINTF,lulog,'Making link at '+linkd
    	    	spawn,['ln','-s',fitsdir+sb, linkd],/noshell
	    ENDIF
	ENDIF
	;
	;   Now write out level 0.5 image to appropriate subdirectory
	;   as a FITS image
	;   and send updates to database file
	;
	IF (tel NE 'z') THEN BEGIN
	;
	;     write last image only if DISPLAY option is set, an image was found and source is real time
	;
	  IF ( hdr_only EQ 0 ) THEN BEGIN
	     CHECK_OBESUMERROR,a,fits_hdr		; check for OBE LEB summing error
	     REDUCE_STATISTICS,img,fits_hdr

		;;	IF (tel NE '4') THEN REDUCE_REFCOORD, fits_hdr, '0.5'	;	before 030721 (jake)
		;IF (tel NE '4') THEN $										;	after
			REDUCE_REFCOORD, fits_hdr, '0.5' ;$ 	always do refcoord - nbr, 2010/11/8 
		;ELSE BEGIN													;	jake 030721
		;	dateobs = FXPAR ( fits_hdr, 'DATE-OBS' )				;	jake 030721
		;	timeobs = FXPAR ( fits_hdr, 'TIME-OBS' )				;	jake 030721
		;	crota1 = get_crota ( dateobs + ' ' + timeobs )			;	jake 030804
		;	crota2 = get_crota ( dateobs + ' ' + timeobs )			;	jake 030804
		;	FXADDPAR,fits_hdr,'CROTA1',crota1						;	jake 030721
		;	FXADDPAR,fits_hdr,'CROTA2',crota2						;	jake 030721
		;ENDELSE														;	jake 030721

	     IF ( (strpos(opt,'DISPLAY') GE 0) and (source le 1) ) THEN BEGIN
	       WRITE_LAST_IMG,img,fits_hdr
	     ENDIF
	  ENDIF
	;
	;  Update the history with processing
	;  Write out the file and change the access code to all read, x access
	;
	  FXADDPAR,fits_hdr,'HISTORY',s
	  FXADDPAR,fits_hdr,'DATE',today    	    	; match database
	  WRITEFITS,fits_name,img,fits_hdr          	; Write disk FITS file
	  SPAWN, ['chmod','644',fits_name], /noshell
	  IF (telescope EQ 3) THEN status=1 ELSE BEGIN		; don't perform level 1 processing on EIT images
	     IF (lpnum EQ 5)  THEN BEGIN			;  check to see if dark image
		IF (source EQ 2)  THEN BEGIN			; only process LZ at NRL
		   PRINTF,lulog,'Processing dark image statistics'
		   lhdr = LASCO_FITSHDR2STRUCT(fits_hdr)
		   CALC_DARK_BIAS,img,lhdr
		ENDIF
	     ENDIF
	     IF ((STRPOS(sb,'level_05') NE -1) AND (source GE 1))  THEN BEGIN
		PRINTF,lulog,'Processing monexp data'
		MONITOR_EXP_IMG,fits_name
	     ENDIF
	  ENDELSE
	ENDIF ELSE BEGIN
	  SPAWN,['cp',file_name,sb+fits_name], /noSH
	ENDELSE

ENDIF	; NOT (DB_ONLY)

IF (STRPOS(opt,"DBMS") GE 0) THEN BEGIN
;
;  update db table IMG_HISTORY
;
     PRINTF,lulog,'Updating DBMS table = img_history'
     a=GET_DB_STRUCT ('lasco','img_history')
     a.filename=hdr.filename
     a.history = sver
     a.date_mod =today
     ;DB_INSERT,a
; stop  
   ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
     lubk=ludb      ; make a copy of ludb
     ludb=ludb2     ; point to the sql db file
     sql_db_insert,a
     ludb=lubk      ; revert to proper ludb
 ; ************ END  KB TEMP EDITS FOR SQL TESTING *****************  
  ;
;  update db table IMG_FILES
;
     PRINTF,lulog,'Updating DBMS table = img_files'
     a = GET_DB_STRUCT ('lasco','img_files')
     a.filename=hdr.filename
     a.fileorig=hdr.fileorig
     IF (tel EQ 'z') THEN a.filetype=0 ELSE a.filetype=1
     a.source = source
     SPAWN,'pwd',cwd, /noSH
     ;a.diskpath = cwd(0)
     a.diskpath = GETENV('DSKPATH')+'/'+sb+teldir
     a.date_mod = today
     IF (hdr_only EQ 0) THEN BEGIN
        a.bunit = 'DN'
        a.datamax = MAX(img,min=mn)
        a.datamin = mn
        a.hdr_only = 0
     ENDIF ELSE BEGIN
        a.bunit = ''
        a.datamax = 0
        a.datamin = 0
        a.hdr_only = 1
     ENDELSE
     ;DB_INSERT,a 
   ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
     lubk=ludb      ; make a copy of ludb
     ludb=ludb2     ; point to the sql db file
     sql_db_insert,a
     ludb=lubk      ; revert to proper ludb
   ; ************ END  KB TEMP EDITS FOR SQL TESTING *****************  

;
;  update db table IMG_PARENT
;
     IF (tel NE 'z') THEN BEGIN
        PRINTF,lulog,'Updating DBMS table = img_parent'
        a = GET_DB_STRUCT ('lasco','img_parent')
        a.filename=hdr.filename
        a.parent_num=0
        a.parent=fits_name
        a.date_mod = today
        ;DB_INSERT,a 
        ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
        lubk=ludb      ; make a copy of ludb
        ludb=ludb2     ; point to the sql db file
        sql_db_insert,a
        ludb=lubk      ; revert to proper ludb
        ; ************ END  KB TEMP EDITS FOR SQL TESTING *****************  
     ENDIF
;
;  update db table IMG_BROWSE
;
     IF ((tel NE 'z') and (hdr_only EQ 0) ) THEN BEGIN
        PRINTF,lulog,'Updating DBMS table = img_browse'
        a = GET_DB_STRUCT ('lasco','img_browse')
        a.filename=fits_name
        a.browse_img = MAKE_BROWSE (img,fits_hdr,fits_name)
        a.date_mod = today
        ;DB_INSERT,a 
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING *****************  
     ENDIF
;
;  update db table IMG_LEB_HDR
;
      PRINTF,lulog,'Updating DBMS table = img_leb_hdr'
    	;printf,ludb2,'use lasco;'
    	;printf,ludb2,'start transaction;'
	; file should already be initialized
    	IF (delflag) or source GT 1 THEN printf,ludb2,'delete from img_leb_hdr	where date_obs = "'+hdr.date_obs+'";'
    	; will not delete level-1 because date_obs is different for level-1
      a=GET_DB_STRUCT ('lasco','img_leb_hdr')
      a.fileorig         =hdr.fileorig
      a.date_mod         =today
      a.date_obs         =hdr.date_obs
      a.camera           =hdr.camera
      a.readport         =hdr.readport
      a.ccd_side         =hdr.ccd_side
      a.lamp             =hdr.lamp
      a.shutter          =hdr.shutter
      a.filter           =hdr.filter
      a.polar            =hdr.polar
      a.clrmode          =hdr.clrmode
      a.line_sync        =hdr.line_sync
      a.nclears          =hdr.nclears
      a.camera_err       =hdr.camera_err
      a.image_ctr        =hdr.image_ctr
      a.exp_start_time1  =hdr.exp_start_time1
      a.exp_start_time2  =hdr.exp_start_time2
      a.exp_start_time3  =hdr.exp_start_time3
      a.exp_dur          =hdr.exp_dur
      a.exp_cmd          =hdr.exp_cmd
      a.read_time        =hdr.read_time
      a.exp1             =hdr.exp1
      a.exp2             =hdr.exp2
      a.exp3             =hdr.exp3
      a.proc_time        =(hdr.proc_time > 0)
      IF (a.proc_time GE 32767) THEN a.proc_time = 0
      a.lpulse           =hdr.lpulse
      a.p1row            =hdr.p1row
      a.p1col            =hdr.p1col
      a.p2row            =hdr.p2row
      a.p2col            =hdr.p2col
      a.sumrow           =hdr.sumrow
      a.sumcol           =hdr.sumcol
      a.lebxsum		 =hdr.lebxsum
      a.lebysum		 =hdr.lebysum
      a.lp_num           =hdr.lp_num
      a.os_num           =hdr.os_num
      a.seq_num          =hdr.seq_num
      a.num_ip           =hdr.num_ip
      a.send_data        =hdr.send_data
      a.blocks_horz      =hdr.blocks_horz
      a.blocks_vert      =hdr.blocks_vert
      a.blocks_total     =hdr.blocks_total
      a.trans_image      =hdr.trans_image
      a.trans_det        =hdr.trans_det
      a.fp_wl_upl        =hdr.fp_wl_upl
      a.fp_wl_cmd        =hdr.fp_wl_cmd
      a.m1_lid           =hdr.m1_lid
      a.m1_pz1           =hdr.m1_pz1
      a.m1_pz2           =hdr.m1_pz2
      a.m1_pz3           =hdr.m1_pz3
      a.comp_cf          =hdr.comp_cf
      a.comp_bpx         =hdr.comp_bpx
      a.hcomp_sf         =hdr.hcomp_sf
      a.exptime          =FXPAR(fits_hdr,'EXPTIME')
      a.r1col            =FXPAR(fits_hdr,'R1COL')
      a.r2col            =FXPAR(fits_hdr,'R2COL')
      a.r1row            =FXPAR(fits_hdr,'R1ROW')
      a.r2row            =FXPAR(fits_hdr,'R2ROW')
      a.effport          =FXPAR(fits_hdr,'EFFPORT')
      a.naxis1           =FXPAR(fits_hdr,'NAXIS1')
      a.naxis2           =FXPAR(fits_hdr,'NAXIS2')
      a.mid_date         =FXPAR(fits_hdr,'MID_DATE')
      a.mid_time         =FXPAR(fits_hdr,'MID_TIME')
      a.compression_str  =STRTRIM(FXPAR(fits_hdr,'COMPRSSN'),2)
      a.version          =hdr.version
      a.fp_order         =hdr.fp_order
      a.door_pos         =hdr.door_pos
      a.unique_os        =MAKE_UNIQUE_OSNUM(a,0)
      a.dateorig	 ='NULL'
      ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
;
;  update db table IMG_RS_HDR if necessary
;
   tags = TAG_NAMES(hdr)
   IF (TAG_EXIST(hdr, 'RS_P1ROW') EQ 1) THEN BEGIN
      a=GET_DB_STRUCT('lasco','img_rs_hdr')
      atags = TAG_NAMES(a)
      FOR t=2, N_TAGS(a)-1 DO BEGIN
         tt = WHERE(tags EQ atags(t))
         a.(t) = hdr.(tt(0))
      ENDFOR
      a.date_mod         =today
      ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
   ENDIF
;
;  update db table IMG_IIB_HDR if necessary
;
   tags = TAG_NAMES(hdr)
   IF (TAG_EXIST(hdr, 'IIB_X') EQ 1) THEN BEGIN
      a=GET_DB_STRUCT('lasco','img_iib_hdr')
      atags = TAG_NAMES(a)
      FOR t=2, N_TAGS(a)-1 DO BEGIN
         tt = WHERE(tags EQ atags(t))
         a.(t) = hdr.(tt(0))
      ENDFOR
      a.date_mod         =today
      ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
   ENDIF
;
;  update db table IMG_IID_HDR if necessary
;
   tags = TAG_NAMES(hdr)
   IF (TAG_EXIST(hdr, 'IID_X') EQ 1) THEN BEGIN
      a=GET_DB_STRUCT('lasco','IMG_IID_HDR')
      atags = TAG_NAMES(a)
      FOR t=2, N_TAGS(a)-1 DO BEGIN
         tt = WHERE(tags EQ atags(t))
         a.(t) = hdr.(tt(0))
      ENDFOR
      a.date_mod         =today
      ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
   ENDIF
;
;  update db table IMG_ROI_THR_HDR if necessary
;
   tags = TAG_NAMES(hdr)
   IF (TAG_EXIST(hdr, 'ROI_Thrsh') EQ 1) THEN BEGIN
      a=GET_DB_STRUCT('lasco','IMG_ROI_THR_HDR')
      atags = TAG_NAMES(a)
      FOR t=2, N_TAGS(a)-1 DO BEGIN
         tt = WHERE(tags EQ atags(t))
         a.(t) = hdr.(tt(0))
      ENDFOR
      a.date_mod         =today
      ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
   ENDIF
;
;  update db table IMG_SUM_BUFF0_HDR if necessary
;
   tags = TAG_NAMES(hdr)
   IF (TAG_EXIST(hdr, 'S0_CLR') EQ 1) THEN BEGIN
      a=GET_DB_STRUCT('lasco','IMG_SUM_BUFF0_HDR')
      atags = TAG_NAMES(a)
      FOR t=2, N_TAGS(a)-1 DO BEGIN
         tt = WHERE(tags EQ atags(t))
         a.(t) = hdr.(tt(0))
      ENDFOR
      a.date_mod         =today
      ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
   ENDIF
;
;  update db table IMG_SUM_BUFF1_HDR if necessary
;
   tags = TAG_NAMES(hdr)
   IF (TAG_EXIST(hdr, 'S1_CLR') EQ 1) THEN BEGIN
      a=GET_DB_STRUCT('lasco','IMG_SUM_BUFF1_HDR')
      atags = TAG_NAMES(a)
      FOR t=2, N_TAGS(a)-1 DO BEGIN
         tt = WHERE(tags EQ atags(t))
         a.(t) = hdr.(tt(0))
      ENDFOR
      a.date_mod         =today
      ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
   ENDIF
;
;  update db table IMG_TRANSIENT_DET_HDR if necessary
;
   tags = TAG_NAMES(hdr)
   IF (TAG_EXIST(hdr, 'TD_Thrsh') EQ 1) THEN BEGIN
      a=GET_DB_STRUCT('lasco','IMG_TRANSIENT_DET_HDR')
      atags = TAG_NAMES(a)
      FOR t=2, N_TAGS(a)-1 DO BEGIN
         tt = WHERE(tags EQ atags(t))
         a.(t) = hdr.(tt(0))
      ENDFOR
      a.date_mod         =today
      ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
   ENDIF
;
;  update db table IMG_IP
;  each IP step has a separate entry in the db table
;
      PRINTF,lulog,'Updating DBMS table = img_ip'
      a = GET_DB_STRUCT ('lasco','img_ip')
      a.fileorig=file_name
      a.date_mod = today
      if (hdr.num_ip gt 0) THEN for i=0,hdr.num_ip-1 do BEGIN
         a.step_num = i+1
         a.ip_num = hdr.leb_proc(i)
         ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
      ENDFOR
;
;  update db table IMG_STATS
;
      if ((tel NE 'z') and (hdr_only EQ 0) ) THEN BEGIN
         PRINTF,lulog,'Updating DBMS table = img_stats'
         a = GET_DB_STRUCT ('lasco','img_stats')
         a.filename=fits_name
         a.datamax = FXPAR(fits_hdr,'DATAMAX')
         a.datamin = FXPAR(fits_hdr,'DATAMIN')
         a.datazer = FXPAR(fits_hdr,'DATAZER')
         a.datasat = FXPAR(fits_hdr,'DATASAT')
         a.dataavg = FXPAR(fits_hdr,'DATAAVG')
         a.datasig = FXPAR(fits_hdr,'DATASIG')
         a.datap01 = FXPAR(fits_hdr,'DATAPO1')
         a.datap10 = FXPAR(fits_hdr,'DATAP10')
         a.datap25 = FXPAR(fits_hdr,'DATAP25')
         a.datap75 = FXPAR(fits_hdr,'DATAP75')
         a.datap90 = FXPAR(fits_hdr,'DATAP90')
         a.datap95 = FXPAR(fits_hdr,'DATAP95')
         a.datap98 = FXPAR(fits_hdr,'DATAP98')
         a.datap99 = FXPAR(fits_hdr,'DATAP99')
         a.date_mod = today
         ;DB_INSERT,a
     ; ************ START  KB TEMP EDITS FOR SQL TESTING *****************  
       lubk=ludb      ; make a copy of ludb
       ludb=ludb2     ; point to the sql db file
       sql_db_insert,a
       ludb=lubk      ; revert to proper ludb
    ; ************ END  KB TEMP EDITS FOR SQL TESTING ***************** 
      ENDIF
ENDIF 					; processing of DBMS


GET_UTC,dte,/ecs
PRINTF,lulog,'Procedure status return = '+STRTRIM(STRING(status),2)
PRINTF,lulog,'Level 0.5 processing ended at '+dte
FOR i=0,5 do PRINTF,lulog
RETURN,status
error:
PRINTF,lulog,'Error in level 0.5 processing '
IF (strpos(opt,"DBMS") GE 0) THEN BEGIN
;
;  update db table PROC_ERROR
;
;  a = GET_DB_STRUCT ('lasco','proc_error')
;  a.date_mod = today
;  a.filename = file_name
;  DB_INSERT,a
ENDIF			; end of processing for DBMS
GET_UTC,dte,/ecs
PRINTF,lulog,'Procedure status return = 1'
PRINTF,lulog,'Procedure reduce_level_05 ended at '+dte
FOR i=0,5 do PRINTF,lulog
RETURN,1
END
