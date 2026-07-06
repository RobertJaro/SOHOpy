pro reduce_level_1,fits_name0, hout, b, REM_CR=rem_cr, NO_VIG=no_vig, PIPELINE=pipeline, $
	RESET=reset, NO_MASK=no_mask,SAVEDIR=savedir, NOFITS=nofits,_EXTRA=_extra, NOWARP=nowarp, $
	NOSTAT=nostat, NOTIMECORRECTION=notimecorrection, NOROLL_CORRECTION=noroll_correction, $
	NOSCALE=noscale, REPROCESS=reprocess,NOIMG=noimg, HDRIN=hdrin, OUTFILE=outfile
;+
; NAME:
;	REDUCE_LEVEL_1
;
; PURPOSE:
;	This procedure performs the standard pipeline processing to 
;	take the level 0.5 image to Level 1. 
;   *** Note: This procedure is now designed to operate without
;	any calling procedure. Simply input a level_05 FITS
;	filename with path and it will do the rest.
;	- NBR, 8/4/00
;
; CATEGORY:
;	LASCO REDUCTION
;
; CALLING SEQUENCE:
;	REDUCE_LEVEL_1, Fits_name
;
; INPUTS:
;	Fits_name = Name of FITS file to process, including path
;   	    	    -or-
;   	    	    INTARR image to process; requires INHDR= to be set.
;
; OPTIONAL INPUTS:
;	$RED_L1_PATH, $REDUCE_OPTS: environment variable for pipeline processing
;	
; KEYWORD PARAMETERS:
;  /REM_CR	Perform cosmic ray removal algorithm - THIS OPTION IS NOT RECOMMENDED because it 
;		doesn't work very well
;  /NO_VIG	Do not apply vignetting correction
;  /PIPELINE	Process for pipeline (saves in pipeline directory, creates database entry)
;  /RESET	Read in calibration images (vignetting, mask, ramp, etc.) from file instead
;		of using what is stored in the common block
;  SAVEDIR = 'pathname'		Directory to save output in. Default is current directory.
;   /NOFITS 	Do not save FITS file
;   /NOWARP 	Do not do optical distortion correction (!!! CAUTION !!! Only evident in COMMENT keyword !!! )
;   /NOSTAT 	Do not run reduce_statistics2 and fill in DATAP* keyword values.
;   /NOROLL_CORRECT   	Do not correct for the angle between ecliptic and solar equator. Default is to rotate
;   	    	    	images so solar north is up. Relevant only for images after 2010/10/30. The 180 deg 
;   	    	    	keyhole roll is always corrected.   
;   /NOSCALE	Do not scale result to type Integer for C3 or type Float for C2 before saving; implies /NOSTAT	    	    
;   /REPROCESS	Delete rows in database; use if reprocessing what is already in database.
;   /NOIMG  	Only do header pointing/time keyword update; implies /NOFITS
;   HDRIN=  	LASCO header structure to go with Input array
;   OUTFILE=	Returns filename of saved fits file with path.
;
; OUTPUTS:
;   Default:
;	Writes FITS file in current directory or SAVEDIR (or $FITS_OUT if PIPELINE set)
;	Writes ./reduce_level_1.log (or unique log file if PIPELINE set)
;	Description of keywords in FITS header are at 
;		http://lasco-www.nrl.navy.mil/level_1/level_1_keywords.html
;
; OPTIONAL OUTPUTS:
;	hout	LASCO FITS header structure level-1 image
;   	b   	DBLARR	Unscaled calibrated image
;
; COMMON BLOCKS:
;	DBMS, REDUCE_HISTORY
;
; RESTRICTIONS:
;	Must have LASCO IDL Library
;	Must have environment $LASCO_DATA defined
;	The REM_CR option is not currently supported outside of NRL
;  ***  Current versions of calibration files only tested for images observed before July 1998!!! ***
;   	Polarization processing or background removal is Level 2
;
; PROCEDURE:
;
;   Level 1 consists of calibrating for 
;           dark current
;           flat field
;           stray light 
;           distortion  
;           vignetting  
;           photometry (physical units)
;	    corrected time and position
;
;
; MODIFICATION HISTORY:
;		Written	 RA Howard, NRL
;   Version 1	rah  3 Oct 1995    Initial release
;           2   rah 15 Nov 1995    Modified log output
;           3   rah 21 Oct 1996    Added fits_hdr to make_browse
;           4   aee 23 Oct 1997    Added fits name error handling and camera 
;                                  case statement and modified the code to
;                                  use C3_CALIBRATE instead of photocal. Also
;                                  introduced environment variable 
;                                  REDUCE_L1_OPTS which must contain 'DBMS'
;                                  in order to create a DB file. Set negative
;                                  image intensity values to zeros. Also adds
;                                  image info to the img_hdr.txt file. Also
;                                  added stray light and distortion correction.
;	   	nbr  5 Oct 1998	   changed output directory; no database entry
;	    5   nbr  1 Mar 1999    Added header updates from GET_IMG_LEB_HDR_UPDATES;
;				   added IMG_LEB_HDR for .db files; open .db file
;	nbr  4 Aug 2000 - Update version recording; reconstruct FITS header for Level 1;
;			  compute roll, suncenter, time corrections
;	nbr  7 Aug 2000 - Edit HISTORY fields
;	nbr 26 Oct 2000 - Edit call to C3_CALIBRATE
;	nbr 14 Nov 2000 - Add header field N_MISSING, REM_CR keyword
;	nbr 12 Jan 2001 - Apply mask after warp
;	nbr 25 Jan 2001 - Add bkg, mask_blocks, zblocks0 to common block; add MISSLIST to header
;	nbr 15 Feb 2001 - Add C2
;	nbr 15 May 2001 - Change SOLAR_R to R_SUN in hdr
;	nbr 31 May 2001 - Change $ANCIL_DATA to $LASCO_DATA
;	nbr  8 Nov 2001 - Modify for use outside of pipeline; remove c3_cal_img COMMON block
;	nbr  3 Dec 2001 - Make paths compatible with Windows SSW for GSV
;	nbr 17 Dec 2001 - Make paths compatible with Windows SSW for GSV
;	nbr 24 Jun 2002 - Use RED_L1_PATH for pipeline savedir and for log and db files;
;			  use yyyymmdd for output dir
;	nbr  5 Jul 2002 - Change comment for CROTA; reinsert READPORT in header because is 
;			  used in offset_bias.pro
;	nbr 17 Sep 2002 - Use BSCALE and BZERO to save images as integers; 
;			  add BLANK keyword; use .txt instead of .sav for c3[2]nullblocks
;	nbr  9 Jan 2003 - mask_flag=0 for debugging
;	nbr 14 Mar 2003 - Reinsert COMMON c3_cal_img for mask; don't get mask in this program;
;			  add fixwrap for summed images; convert only C3 Clear to type integer;
;			  use adjust_hdr_tcr() for time, roll, suncenter
;	nbr  9 Apr 2003 - reduce_img_hdr DAY_ONLY if not pipeline
;	nbr 14 Apr 2003 - Modify to do monthly images.
;	nbr 16 May 2003 - Modify keyword comments
;	nbr 11 Sep 2003 - Change img_leb_hdr db update
;	04.04.01, nbr - Use best available values post-interruption and note in header;
;                obsolete TIME-OBS; rotate inverted images
;       04.04.08, nbr - Update for bkg images
;       05.07.25, nbr - Update/fix C3 mask implementation
;       05/07/28 KarlB - Change output directory structure
;       Aug 1,05  KB  - Another minor change to output dir
;       Sep21,05 KarlB - Routine now skips files that don't exist as LZ data
;       Sep30,05 KarlB - Change format of 'DATE'
;       Oct03,05 KarlB - Add "LEVEL = 1.0" to fits header
;                      - Remove "tab" spaces from HISTORY comments
;       May09,05 KBattams - Add savedir k/w (which appeared to be missing)
;                       - made some mods to how filenames of rolled monthly images are formed
;       Jun22,06 KB/RCC - reduce_img_hdr now only called during pipeline processing
;       Nov15,07 Karl B -- got rid of that stupid #$!%*@ "!delimeter" that only works on every other machine...
;   	Jun 4,10, nbr - Update database script for mysql; correct BLANK value for signed INT
;   	Oct27,10, nbr - Fix CUNIT and CTYPE in FITS header output
;   	Dec13,10, nbr - Add /NOWARP and /NOSTAT
;   	Dec20,10, nbr - Add /NOTIMECORRECTION
;   	Dec27,10, nbr - Fix CROTA/ rectify for Bogart mission
;   	Jun17,11, nbr - Add '3' as acceptable source and treat as Quicklook; put subfield in full field image
;   	Jul26,11, nbr - Do roll correction by default and add /NOROLL_CORRECTION; also make sure file is put into correct 
;   	    	    	day directory according to corrected time. 
;   	Jul28,11, nbr - Fix C2 scaling error in mask section (* raw FITS image); add filter to skip Dark images;
;   	    	    	add /NOSCALE keyword
;   	Jul29,11, nbr - Do not do rot() if LT 1 deg.
;   	Aug04,11, nbr - Add /REPROCESS for database
;   	Nov01,11, nbr - Change sign of CROTA in header to match SSW/WCS convention
;   	Sep21,12, nbr - Implement /NOIMG option
;   	Nov16,12, nbr - Implement optional image array input and HDRIN=
;
version= '@(#)reduce_level_1.pro	1.68, 07/31/18' ; LASCO IDL LIBRARY
;
;-

COMMON dbms, ludb,lulog, delflag
COMMON reduce_history, cmnver, prev_a, prev_hdr, zblocks0
COMMON c3_cal_img,vig_full,mask,vig_fn,msk_fn, ramp_fn, ramp_full, dte_vig, $
dte_msk, dte_ramp,bkg_full, hb, mask_blocks,mask_full

ver = strmid(version,4,strlen(version))

; if datatype(!delimiter) NE 'UND' THEN dlm = !delimiter ELSE dlm = get_delim()  ; KB edit, Nov,2007
dlm = get_delim()
IF keyword_set(NOIMG) THEN noimg=1 ELSE noimg=0
IF noimg THEN nofits=1

not_found=0  ; this is just a flag for if the LZ fits file is not found
IF datatype(fits_name0) NE 'STR' THEN BEGIN
    IF ~keyword_set(HDRIN) THEN BEGIN
    	message,'With array input, must set HDRIN=',/info
	goto,done
    ENDIF
    a=fits_name0
    hdr=hdrin
    fits_name=hdr.filename
ENDIF ELSE BEGIN
    fits_name=fits_name0
    IF not file_exist(fits_name) THEN BEGIN  ; this prevents crashes from non-existant LZ files.
	not_found = 1
	message,'FILE NOT FOUND: ',/info
	help,fits_name
	PRINT,' Skipping it...'
	goto,done
    ENDIF
    print,'Reading ',fits_name
    a = lasco_readfits (fits_name,hdr)
ENDELSE
 
camera= strupcase(strtrim(hdr.detector,2))

IF datatype(prev_hdr) NE 'UND' THEN BEGIN
	IF prev_hdr.filter NE hdr.filter THEN reset=1
	IF prev_hdr.detector NE hdr.detector THEN reset=1
ENDIF
IF keyword_set(RESET) THEN new=1 $	; Read in vig, mask, and ramp file each time
	ELSE new = 0
IF keyword_set(NO_MASK) THEN mask_flag=0 ELSE mask_flag=1	; If set, apply mask
mask_blocks=0	; Reset in FUZZY_IMAGE.PRO via TOO_MANY keyword, called by C3_CALIBRATE
;toomanyinzone=0

xsumming = (hdr.sumcol>1)*(hdr.lebxsum>1)
ysumming = (hdr.sumrow>1)*(hdr.lebysum>1)
summing = xsumming*ysumming
IF  summing GT 1 and ~noimg THEN a = fixwrap(a)
; If image is summed, fix integer wrapping
IF summing GT 1 THEN dofull=0 ELSE dofull=1

; Quick fix to do subfield images. Will put it in full frame, but do not change any values
; except header R values, and sun center and roll.

IF hdr.r2col-hdr.r1col+hdr.r2row-hdr.r1row-1023-1023 NE 0 THEN a= reduce_std_size(a,hdr,full=dofull)

fname=hdr.filename
source = strmid(fname,1,1)
if (source EQ 'm') THEN fname = fits_name
dot = strpos(fname,'.')
root = strmid(fname,0,dot)
yymmdd=strmid(hdr.date_obs,2,2)+strmid(hdr.date_obs,5,2)+strmid(hdr.date_obs,8,2)

if(source eq '1') then STRPUT,root,'4',1
if(source eq '2') then STRPUT,root,'5',1
if(source eq '3') then STRPUT,root,'4',1
if(source EQ 'm' or source EQ 'd') THEN BEGIN	; for doing monthly images
;stop
	if (strmid(root,2,1) EQ 'r') THEN root = strmid(root,0,3)+'1'+strmid(root,3,13) $
        ELSE root = strmid(root,0,2)+'1'+strmid(root,2,12) 
	yymmdd = 'monthly'
        hdr.r1col=20
        hdr.r2col=1043
        hdr.r1row=1
        hdr.r2row=1024
ENDIF
;strput,root,'t'
outname=root+'.fts'


IF keyword_set(PIPELINE) THEN BEGIN
    	;dbdir=getenv('REDUCE_DB')
	outdir=getenv_slash('FITS_OUT')
	IF outdir EQ '' THEN message,'You must exit IDL and source l1.env.'	

   	logpath = getenv_slash ('REDUCE_LOG')
   	logfile = logpath+'log/red_'+yymmdd+'_'+root+'.log'
	appnd = 0
	opt = strupcase (getenv('REDUCE_OPTS'))
	;opt='none'

ENDIF ELSE BEGIN
	logfile = 'reduce_level_1.log'
	appnd = 1
	print,"NOTE: Appending log file reduce_level_1.log!!!!"
        print
ENDELSE

caldir = getenv_slash('LASCO_DATA')+'calib'
;printf,lulog,'Output directory = '+sd
;print,'Output directory = '+sd

print,'Opening ',logfile
openw,lulog,logfile,/GET_LUN,APPEND=appnd
imgsumline=fname+' '+hdr.date_obs+'t'+hdr.time_obs+' '+hdr.filter+' '+strcompress(hdr.polar,/remove)

get_utc,today,/ecs
printf,lulog,'Procedure reduce_level_1.pro,v'+ver+' started at '+today
printf,lulog,'Input = '+fits_name
if(source ne '1' and source ne '2' and source NE 'm' and source NE 'd' and source NE '3') $
then begin
  print,'ERROR: reduce_level_1 - Invalid FITS source ('+fname+')' 
  print,'                                              ^'
  print,'Terminating reduce_level_1.'
  print
  printf,lulog,'ERROR: reduce_level_1 - Invalid FITS source ('+fname+')'
  printf,lulog,'                                              ^'
  printf,lulog,'Terminating reduce_level_1.'
  goto, done 
end
IF ~noimg THEN help,a
IF ~noimg THEN maxmin,a
if(a(0) eq -1) or n_elements(a) LT 128.*128 then begin
  msg=imgsumline+' ERROR: zero image'
  print,msg
  print,'Skipping image.'
  wait,2
  printf,lulog,msg
  printf,lulog,'Skipping image.'
  goto, done
end
;IF hdr.datap99 LT 100 and source NE 'm' and ~noimg THEN BEGIN
IF (0) THEN BEGIN
    msg=imgsumline+' ERROR: DATAP99='+trim(hdr.datap99)
    print,msg
    print,'Skipping image'
    wait,2
    printf,lulog,msg
    printf,lulog,'Skipping image.'
    goto, done
end
print,imgsumline
printf,lulog,imgsumline

; ** Begin FITS Header re-creation **
;
dte=today
today_dte = strmid(dte,0,4)+'-'+strmid(dte,5,2)+'-'+strmid(dte,8,2)+'T'+strmid(dte,11,12)
FXHMAKE,fits_hdr,a
fxaddpar,fits_hdr,'DATE',    today_dte
; some old values needed for procedures
fxaddpar,fits_hdr,'FILENAME',hdr.filename
fxaddpar,fits_hdr,'FILEORIG',hdr.fileorig
fxaddpar,fits_hdr,'DATE-OBS',hdr.date_obs 
fxaddpar,fits_hdr,'TIME-OBS',hdr.time_obs,'WARNING: Original (Uncorrected)'
fxaddpar,fits_hdr,'EXPTIME', hdr.exptime
fxaddpar,fits_hdr,'TELESCOP',hdr.telescop
fxaddpar,fits_hdr,'INSTRUME',hdr.instrume
fxaddpar,fits_hdr,'DETECTOR',hdr.detector
fxaddpar,fits_hdr,'READPORT',hdr.readport
fxaddpar,fits_hdr,'SUMROW',  hdr.sumrow
fxaddpar,fits_hdr,'SUMCOL',  hdr.sumcol
fxaddpar,fits_hdr,'LEBXSUM', hdr.lebxsum
fxaddpar,fits_hdr,'LEBYSUM', hdr.lebysum
fxaddpar,fits_hdr,'FILTER',  hdr.filter
fxaddpar,fits_hdr,'POLAR',   hdr.polar
fxaddpar,fits_hdr,'COMPRSSN',hdr.comprssn
; ++ required for get_exp_factor.pro
fxaddpar,fits_hdr,'MID_DATE',hdr.mid_date,'WARNING: Original (Uncorrected)'
fxaddpar,fits_hdr,'MID_TIME',hdr.mid_time,'WARNING: Original (Uncorrected)'
; ++
fxaddpar,fits_hdr,'R1COL',   hdr.r1col
fxaddpar,fits_hdr,'R1ROW',   hdr.r1row
fxaddpar,fits_hdr,'R2COL',   hdr.r2col
fxaddpar,fits_hdr,'R2ROW',   hdr.r2row
fxaddpar,fits_hdr,'LEVEL', '1.0'
histlen=1
cmntlen=1
inc = 0
WHILE histlen GT 0 DO BEGIN
	histlen = strlen(hdr.history[inc])
	IF histlen GT 2 and strpos(hdr.history[inc],'bias') LT 0 THEN $		; different bias used in level 1
		fxaddpar,fits_hdr,'HISTORY', ' '+strcompress(hdr.history[inc])
	inc = inc+1
ENDWHILE
inc = 0
WHILE cmntlen GT 0 DO BEGIN
	cmntlen = strlen(hdr.comment[inc])
	IF cmntlen gt 0 then fxaddpar,fits_hdr,'COMMENT', ' '+hdr.comment[inc]
	inc = inc+1
ENDWHILE

s = ver+",'"+fname+"','"+outname+"'"
fxaddpar,fits_hdr,'HISTORY', ' '+strcompress(s)

IF keyword_set(REM_CR) and DATATYPE(prev_a) NE 'UND' THEN BEGIN
   print,' *** The REM_CR option is not currently supported. Continuing. ***
   print
   ;a1 = REMOVE_CR(prev_a, prev_hdr, a, hdr, N_CR=n_cr)
   ;fxaddpar,fits_hdr,'N_COSRAY',n_cr,' No. of pixels removed in CR scrub'
   ;fxaddpar,fits_hdr,'HISTORY',cmnver
ENDIF ELSE a1 = a
prev_a = a
b = a
prev_hdr = hdr

if noimg THEN goto, hdr_only

case camera of
; *************************
  'C1': begin
; *************************
         print,'WARNING: reduce_level_1 - C1 is not implemented yet.'
         print,'Terminating reduce_level_1.'
         printf,lulog,'WARNING: reduce_level_1 - C1 is not implemented yet.'
         printf,lulog,'Terminating reduce_level_1.'
         goto, done 
        end
; *************************
  'C2': begin
; *************************
  ;Apply vignetting, ramp, scale factor, exp. time correction, bias:
	 
         get_utc,dte,/ecs
         printf,lulog,'Procedure c2_calibrate started at '+dte
         b= C2_CALIBRATE(a1,fits_hdr,NEW=new)

; 	; HISTORY added to header in c2_calibrate
         get_utc,dte,/ecs
         printf,lulog,'Procedure c2_calibrate completed at '+dte
         bsize= size(b)
         if(bsize(0) eq 0) then begin
           print,'ERROR: Procedure c2_calibrate returned 0'
           print,'Terminating reduce_level_1.'
           printf,lulog,'ERROR: Procedure c2_calibrate returned 0'
           printf,lulog,'Terminating reduce_level_1.'
           goto, done
         end
;stop
    	IF keyword_set(NOWARP) THEN BEGIN
	    fxaddpar,fits_hdr,'COMMENT','/NOWARP applied'
	    printf,lulog,'/NOWARP applied'
	ENDIF ELSE BEGIN
  ;Apply distortion:
    	    get_utc,dte,/ecs
    	    printf,lulog,'Procedure c2_warp started at '+dte
    	    b= c2_warp(b,fits_hdr)		
    	    FXADDPAR,fits_hdr,'HISTORY',' '+strcompress(cmnver)
;  		; Add distortion correction version here from common block
    	    get_utc,dte,/ecs
    	    printf,lulog,'Procedure c2_warp completed at '+dte
	ENDELSE
  ;
  ; Apply mask:
  ;
	; ** For C2, simply use missing blocks as the mask.
;	sz = size(mask)
;	IF (sz(0) EQ 0 or keyword_set(RESET)) THEN BEGIN
;	   CD,caldir,CURRENT=cur_dir
;	   msk_fn= get_cal_name('C3_cl*msk*.dat',yymmdd)
;	   IF msk_fn ne '' THEN BEGIN
;	     dte_msk = FILE_DATE_MOD(msk_fn,/DATE_ONLY)
;	     print,'Using ',msk_fn
;	     mask = READFITS(msk_fn)
;	       printf,lulog,'Used '+msk_fn+', last mod '+dte_msk
;	   ENDIF ELSE BEGIN
;	     print,'ERROR: c3_calibrate - No '+'C3_cl*msk*.dat file'
;	     IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
;	       printf,lulog,'ERROR: c3_calibrate - No '+sd+'C3_cl*msk*.dat file'
;	     mask_flag=0
;	   ENDELSE
;	   CD, cur_dir
;  	ENDIF
;
	IF datatype(zblocks0) EQ 'UND' or keyword_set(RESET) THEN BEGIN
	   ;CD,caldir,CURRENT=cur_dir
  	   ; Retrieve nominally missing blocks
	   ;restore, 'c2nullblocks.sav'
	   c2zs = ''
	   openr,luz,concat_dir(caldir,'c2nullblocks.txt'),/get_lun
	   readf,luz,c2zs
	   close,luz
	   free_lun,luz
	   zblocks0 = fix(str_sep(c2zs, ' '))
	   ;CD, cur_dir
	ENDIF
	; NOTE: Nominally missing blocks are not masked as of ?. -nbr

	   zz = WHERE(a LE 0)
	   ;maskall = mask
          ; stop
           lnsz = size(zz)
	   maskall = dblarr(hdr.naxis1,hdr.naxis2)
           if lnsz[2] GT 1 THEN BEGIN
    	    	;stop
    	    	maskall[*] =1d
	    	maskall[zz] = 0d
           ENDIF ELSE mask_flag=0
	   spx = REBIN(a,hdr.naxis1/32,hdr.naxis2/32)
		; ** Superpixel original image
	   zblocks = WHERE(spx LE 0,nzblocks)
	   ;IF nzblocks LT n_elements(zblocks0) THEN Stop
	   	; ** Some images have no masked blocks
	   IF nzblocks GT 0 THEN BEGIN
		IF summing GT 1 THEN nmissing = nzblocks-8 ELSE BEGIN
			zblocksn = DIFF(zblocks,zblocks0,blocks_missing) 
	   		IF blocks_missing THEN nmissing = n_elements(zblocksn) ELSE nmissing = 0
		ENDELSE
	   ENDIF ELSE nmissing = 0
	   IF nmissing GT 17 THEN BEGIN
	      			; Mask all missing blocks for C2.
				; Up to 17 missing blocks will  
				; be listed in a single string header field.
		missing_string = 'More than 17 blocks missing'
	   ENDIF ELSE IF nmissing EQ 0 THEN missing_string = 'None' $
	   ELSE IF summing GT 2 THEN missing_string = 'Not computed for summed images.' $
	   ELSE missing_string = nums2string(zblocksn)
	   
	IF nmissing GT 0 THEN BEGIN
	   maskall = c2_warp(maskall,fits_hdr)
	   b = b*maskall
	   FXADDPAR,fits_hdr,'HISTORY',' Masked missing blocks only' 
	ENDIF


        end
; *************************
  'C3': begin
; *************************

  ;Apply vignetting, ramp, scale factor, exp. time correction, bias:
	 
         get_utc,dte,/ecs
         printf,lulog,'Procedure c3_calibrate started at '+dte
         b= C3_CALIBRATE(a1,fits_hdr,/FUZZY,/NO_MASK,NEW=new,NO_VIG=no_vig)

	; HISTORY added to header in c3_calibrate
         get_utc,dte,/ecs
         printf,lulog,'Procedure c3_calibrate completed at '+dte
         bsize= size(b)
         if(bsize(0) eq 0) then begin
           print,'ERROR: Procedure c3_calibrate returned 0'
           print,'Terminating reduce_level_1.'
           printf,lulog,'ERROR: Procedure c3_calibrate returned 0'
           printf,lulog,'Terminating reduce_level_1.'
           goto, done
         end

    	IF keyword_set(NOWARP) THEN BEGIN
	    fxaddpar,fits_hdr,'COMMENT','/NOWARP applied'
	    printf,lulog,'/NOWARP applied'
	    bn=b
	ENDIF ELSE BEGIN
  ; Apply distortion:
         get_utc,dte,/ecs
         printf,lulog,'Procedure c3_warp started at '+dte
         bn= c3_warp(b,fits_hdr)		
	 ;b=c3_warp(b,fits_hdr,/REVERSE)
	 FXADDPAR,fits_hdr,'HISTORY',' '+strcompress(cmnver)
  		; Add distortion correction version here from common block
         get_utc,dte,/ecs
         printf,lulog,'Procedure c3_warp completed at '+dte
    	ENDELSE
	
	 xnorm = 518.0		; IDL coordinates
	 ynorm = 531.5		; nbr, 27Jul00
  ;
  ; Apply mask:
  ;
	; Loaded mask in c3_calibrate.pro
	; 	
	
;	IF datatype(zblocks0) EQ 'UND' or keyword_set(RESET) THEN BEGIN
;	   CD,caldir,CURRENT=cur_dir
;  	   ; Retrieve nominally missing blocks; includes seven blocks in center
;	   ;restore, 'c3nullblocks.sav'
;	   c3zs = ''
;	   openr,luz,'c3nullblocks.txt',/get_lun
;	   readf,luz, c3zs
;	   close,luz
;	   free_lun,luz
;	   zblocks0 = fix(str_sep(c3zs,' '))
;	   CD, cur_dir
;	ENDIF
;
	   zz = WHERE(a LE 0)
	   ;maskall = mask
	   maskall=bytarr(hdr.naxis1,hdr.naxis2)
	   maskall[*]=1
;	** using fuzzy/mb2str instead
;	   spx = REBIN(a,hdr.naxis1/32,hdr.naxis2/32)
;		; ** Superpixel original image
;	   zblocks = WHERE(spx LE 0,nzblocks)
;	   ;IF nzblocks LT n_elements(zblocks0) THEN $
;	   ;	message,' ** Some images have no masked blocks'
;	   IF nzblocks GT 0 THEN BEGIN
;		IF summing GT 1 THEN nmissing = nzblocks-17 ELSE BEGIN
;			zblocksn = DIFF(zblocks,zblocks0,blocks_missing) 
;	   		IF blocks_missing THEN nmissing = n_elements(zblocksn) ELSE nmissing = 0
;		ENDELSE
;	   ENDIF ELSE nmissing = 0
;	   IF spx[16,16] eq 0 THEN nmissing=nmissing-7		; already in c3nullblocks
;		; ** In case inside occulter is masked
;	   nmissing=0
	   mbstrings=1
	   find_miss_blocks,a,fits_hdr,mbstruct, STRMAP=mbstrings
	   nmissing = mbstruct.nbmiss
           help,mask_blocks
	   IF nmissing EQ 0 THEN missing_string = 'None' $
	   ELSE BEGIN
	   	missing_string = mbstrings.mbpos
		fxaddpar,fits_hdr,'COMMENT',' MISSLIST is base-32 rep of missing blocks; use strmap2mb.pro.'
	   	IF mask_blocks GT 0 THEN BEGIN
				; mask_blocks is set to zero in fuzzy_image.pro; if more than 16 blocks
                                ; are missing in a zone or if any missing block is adjacent to an edge,
                                ; then mask_blocks is set to the number missing in the zone. fuzzy_image.pro
                                ; is called in c3_calibrate.pro
                    maskall[zz]=0
                                ; Mask ALL missing blocks if more than 16 blocks
				; are missing IN A ZONE. 16 is used based on analysis
				; of 565 zones of missing block replacements. -nbr,3/10/03
                    ;missing_string = 'More than 17 blocks missing'
                    fxaddpar,fits_hdr,'COMMENT',' Missing blocks masked if GT 16 in a zone OR occurs on an edge.'
                    printf,lulog,trim(string(mask_blocks))+' missing blocks in zone: '+trim(string(nmissing))+' blocks re-masked'
                    print,mask_blocks,' missing blocks in zone: ',nmissing,' blocks re-masked'
	   	ENDIF ELSE IF summing GT 2 THEN missing_string = 'Not computed for summed images.' $
		ELSE 	   FXADDPAR,header,'HISTORY',' Used FUZZY_IMAGE.PRO to replace missing blocks.'
	   ENDELSE
	IF mask_flag THEN BEGIN
	   If keyword_set(NOWARP) THEN maskallw=maskall ELSE maskallw = c3_warp(maskall,fits_hdr)

	   b = bn*float(maskallw*mask)	; mask in common c3_cal_img
	   FXADDPAR,fits_hdr,'HISTORY',' '+strcompress(msk_fn)+' '+strcompress(dte_msk) 
	   ;fxaddpar,fits_hdr,'COMMENT','Inner and outer mask and pylon mask are not warped.'
	ENDIF

	end

  else: begin
         print,'ERROR: reduce_level_1 - Invalid telescope '+ camera
         print,'Terminating reduce_level_1.'
         printf,lulog,'ERROR: reduce_level_1 - Invalid telescope '+ camera
         printf,lulog,'Terminating reduce_level_1.'
         goto, done 
        end
endcase

print,'There are ',trim(string(nmissing)),' missing blocks.'
print

hdr_only:

tcr = adjust_hdr_tcr(fits_hdr,_EXTRA=_extra)

IF tcr.date EQ "" THEN BEGIN
    	print,''
    	message,'WARNING: TIME_DIFF.DAT not up-to-date so center/roll values are estimates!',/info
	wait,1
	r = get_roll_or_xy(hdr,'ROLL',rsrc,/degrees,/median)
	; To correct, rotate image r degrees CCW!
	fxaddpar,fits_hdr,'HISTORY',' ROLL: '+strcompress(rsrc)
	c= get_sun_center(hdr,csrc,/median,FULL=1024)
	cx=c.xcen
	cy=c.ycen
	fxaddpar,fits_hdr,'HISTORY',' '+strcompress(cmnver)+': '+strcompress(csrc)
	cmnt='WARNING: Interim value ' 
	tcmnt='WARNING: Original uncorrected value'
	obstime=hdr.time_obs
	obsdate=hdr.date_obs
ENDIF ELSE BEGIN
	; HISTORY (time file, time orig, position file) added in adjust_hdr_tcr
	r = tcr.roll
	cx = tcr.xpos 
	cy = tcr.ypos
	cmnt="Final Correction "
	tcmnt=cmnt
	obsdate=tcr.date
	obstime=tcr.time
    	IF tcr.date NE hdr.date_obs THEN yymmdd=strmid(obsdate,2,2)+strmid(obsdate,5,2)+strmid(obsdate,8,2)
ENDELSE
; now correct for nominal inverted roll

msg='No roll correction applied.'
IF abs(hdr.crota1) GT 170 and ~noimg THEN BEGIN
	rectify=180 
	cntr=511.5
	x=cx-cntr
	y=cy-cntr
	cx=cntr + x*cos(rectify*!pi/180.) - y*sin(rectify*!pi/180.)
	cy=cntr + x*sin(rectify*!pi/180.) + y*cos(rectify*!pi/180.)
	IF rectify EQ 180 THEN BEGIN
		msg="Image rotated 180 degrees."
		b = ROTATE ( temporary(b) , 2 )
		r=r-180.
	ENDIF	

ENDIF ELSE rectify=0.
xc = (cx - hdr.r1col+20)/xsumming
yc = (cy - hdr.r1row+ 1)/ysumming

;b= ROT(b,-1*r,1,xc,yc,/interp,/PIVOT)		
;crpix_x=xnorm+1
;crpix_y=ynorm+1
;b= ROT(b,0,1,511.5-(xc-xnorm),511.5-(yc-ynorm),cubic=-0.5)	;/interp)
;				; Shift sun center to constant location (no rotation)
;				; (IDL coordinates)
;b= ROT(b,0,1,511.5+(xc-xnorm),511.5+(yc-ynorm),cubic=-0.5)	;/interp)
;				; Shift back for comparison purposes

; ** Don't rotate or shift for now **
;r_hdr = -1*r ; this is contrary to SSW/WCS definition!
r_hdr=r
IF r LT -180 THEN r_hdr=r+360

crpix_x = xc+1		; IDL to FITS coordinates
crpix_y = yc+1

rcmnt=cmnt
IF keyword_set(NOROLL_CORRECTION) or abs(r) LT 1 or noimg THEN BEGIN
ENDIF ELSE BEGIN
    b= ROT(b,-1*r,1,xc,yc,/interp,/PIVOT,MISSING=0)
    r_hdr=0.
    rcmnt=cmnt+': image corrected to solar north'
    msg='Applied rot(image,'+trim(-1*r)+',1,'+trim(xc)+','+trim(yc)+',/interp,/pivot) after rectification.'
    rectify=rectify+r
ENDELSE
;b= FLOAT(b)	

print,msg
printf,lulog,msg
help,rectify
;wait,1
fxaddpar,fits_hdr,'HISTORY',' '+strcompress(msg)
fxaddpar,fits_hdr,'RECTIFY',rectify
; ** Continue adding updated or new values to header. **
;
;sxdelpar,fits_hdr,'READPORT'	; no longer needed in level 1
fxaddpar,fits_hdr,'FILENAME',outname
FXADDPAR,fits_hdr,'CRPIX1',crpix_x,' sun center pixel (X), '+cmnt
FXADDPAR,fits_hdr,'CRPIX2',crpix_y,' sun center pixel (Y), '+cmnt
FXADDPAR,fits_hdr,'COMMENT',' FITS coordinate for center of full image is (512.5,512.5).'
FXADDPAR,fits_hdr,'CROTA' ,r_hdr,rcmnt
FXADDPAR,fits_hdr,'COMMENT', ' Rotate image CROTA degrees CCW to correct.'
FXADDPAR,fits_hdr,'CROTA1',r_hdr,rcmnt
FXADDPAR,fits_hdr,'CROTA2',r_hdr,rcmnt
;FXADDPAR,fits_hdr,'HISTORY',cmnver+', '+trim(string(xc))+', '+trim(string(yc))+', '+trim(string(r))+' Deg'
FXADDPAR,fits_hdr,'CRVAL1',0
FXADDPAR,fits_hdr,'CRVAL2',0
FXADDPAR,fits_hdr,'CTYPE1','HPLN-TAN'
FXADDPAR,fits_hdr,'CTYPE2','HPLT-TAN'
FXADDPAR,fits_hdr,'CUNIT1','arcsec'
FXADDPAR,fits_hdr,'CUNIT2','arcsec'
platescl = GET_SEC_PIXEL(hdr)
;FXADDPAR,fits_hdr,'HISTORY',cmnver
FXADDPAR,fits_hdr,'CDELT1',platescl,' Arcsec/pixel'
FXADDPAR,fits_hdr,'CDELT2',platescl,' Arcsec/pixel'
FXADDPAR,fits_hdr,'XCEN',0+platescl*((hdr.naxis1+1)/2. - crpix_x),' Arcsec'
FXADDPAR,fits_hdr,'YCEN',0+platescl*((hdr.naxis2+1)/2. - crpix_y),' Arcsec'

;updates = get_img_leb_hdr_updates(hdr)
;fxaddpar, fits_hdr, 'DATE-OBS',updates.date_obs,' Corrected.'
;fxaddpar, fits_hdr, 'TIME-OBS',updates.time_obs,' Corrected.'
;FXADDPAR, fits_hdr, 'DATE_OBS',updates.date_obs+' '+updates.time_obs
;fxaddpar, fits_hdr, 'MID_DATE',updates.mid_date,' Corrected.'
;fxaddpar, fits_hdr, 'MID_TIME',updates.mid_time,' Corrected.'
;;fxaddpar, fits_hdr, 'DATEORIG',updates.orig_date	;
;;fxaddpar, fits_hdr, 'TIMEORIG',updates.orig_time	; In HISTORY field
;FXADDPAR,fits_hdr,'HISTORY',cmnver+",'"+updates.orig_date+" "+updates.orig_time+"'"	
;    ; Add adjust_date_obs version here from common block

utcdt=anytim2utc(obsdate+'T'+obstime)
newdt=utc2str(utcdt)	; use dashes instead of slashes
IF keyword_set(NOTIMECORRECTION) THEN BEGIN
    fxaddpar, fits_hdr, 'DATE-OBS',hdr.date_obs+'T'+hdr.time_obs,'WARNING: Original uncorrected value'
    fxaddpar, fits_hdr, 'COMMENT','WARNING: DATE-OBS is original uncorrected value'
ENDIF ELSE BEGIN
    fxaddpar, fits_hdr, 'DATE-OBS',newdt,tcmnt
    FXADDPAR, fits_hdr, 'DATE_OBS',newdt
ENDELSE
fxaddpar, fits_hdr,'TIME-OBS','',' Obsolete'
rsun = get_solar_radius(hdr)	
fxaddpar, fits_hdr, 'RSUN',rsun,' Arcsec'
IF ~noimg THEN BEGIN
    fxaddpar, fits_hdr, 'NMISSING',nmissing,' Number of missing blocks.'
    printf,lulog,'NMISSING = ',string(nmissing)

    FXADDPAR, fits_hdr, 'MISSLIST',missing_string
    FXADDPAR, fits_hdr, 'BUNIT','MSB',' Mean Solar Brightness'

    print,'Maxmin calibrated image:'
    maxmin,b
ENDIF

IF keyword_set(NOSCALE) or noimg THEN bout=b $
ELSE BEGIN
    IF camera EQ 'C3' and hdr.filter EQ 'Clear' THEN BEGIN
	scalemin = 0	;2e-13
	scalemax = 6.5e-9
	IF not keyword_set(NOSTAT) THEN REDUCE_STATISTICS2,b,fits_hdr, SATMAX=scalemax
	;
	;   Convert image to integer type
	;
	datamax=fxpar(fits_hdr,'DATAMAX')
	datamin=fxpar(fits_hdr,'DATAMIN')
	datasat=fxpar(fits_hdr,'DATASAT')
	printf,lulog,'DATASAT ='+string(datasat)+',  DATAMIN='+string(datamin)+',  DATAMAX='+string(datamax)
	bscale = (scalemax-scalemin)/65536
	bzero=bscale*32769
	help,bscale,bzero
	nz=where(b NE 0)
	bout=fltarr(hdr.naxis1,hdr.naxis2)
	bout[nz] = ROUND(((b[nz]<scalemax>scalemin)-bzero)/bscale)
	bout = FIX(bout)
	fxaddpar, fits_hdr,'BSCALE',bscale,'Data value = FITS value x BSCALE + BZERO'
	fxaddpar, fits_hdr,'BZERO',bzero
	fxaddpar, fits_hdr,'BLANK',-32768   ; per FITS standard, BLANK is undefined value in unscaled FITS array
	fxaddpar, fits_hdr,'COMMENT',' Data is scaled between '+trim(string(scalemin))+' and '+trim(string(scalemax))
	fxaddpar, fits_hdr,'COMMENT',' Percentile values are before scaling.'
    ENDIF ELSE BEGIN
        
	IF not keyword_set(NOSTAT) THEN reduce_statistics2,b,fits_hdr
	bout = float(b)
	datamax=fxpar(fits_hdr,'DATAMAX')
	datamin=fxpar(fits_hdr,'DATAMIN')
    ENDELSE
ENDELSE

hout=lasco_fitshdr2struct(fits_hdr)
;wset,2
;plot,b[*,yc]
;wset,1
;tvscl,hist_equal(rebin(b,hdr.naxis1/2,hdr.naxis2/2))

IF keyword_set(NOFITS) THEN goto, done

print,'' 
print,'Maxmin scaled image'
maxmin,bout

linkdir=''
IF keyword_set(PIPELINE) THEN BEGIN
	reddir= GETENV_SLASH('RED_L1_PATH')
	IF outdir NE reddir THEN linkdir=outdir+yymmdd
	sd=outdir+yymmdd+dlm+strlowcase(camera)
ENDIF ELSE BEGIN
	sd = './'   ; save in current working dir by default
ENDELSE
IF keyword_set(SAVEDIR) THEN sd = savedir
;
;   construct appropriate subdirectory
;
IF not file_exist(sd) THEN BEGIN
    ; make sure directory exists
    spawn,['mkdir','-p',sd],/noshell	        
    IF linkdir NE '' THEN $
    IF not file_exist(reddir+yymmdd) THEN $
    	spawn,['ln','-s',linkdir,reddir+yymmdd],/noshell
ENDIF	
    
outfile=concat_dir(sd,outname)

printf,lulog,'Writing FITS file to '+outfile
print,'Writing FITS file to '+outfile
writefits,outfile,bout,fits_hdr       
	;Write disk FITS file (bout is previously rounded)
;IF keyword_set(PIPELINE) THEN test=0 ELSE test=1
;help,test

;
; * * * BEGIN Database update section * * * (only if /PIPELINE and DBMS ge 0)
;

IF keyword_set(PIPELINE) THEN IF (strpos(opt,'DBMS') ge 0) THEN BEGIN
    CD, sd, CURRENT=cur_dir
    IF yymmdd NE 'monthly' THEN reduce_img_hdr,fits_hdr, DAY_ONLY=test
	;Add image info to the img_hdr.txt file
    cd,cur_dir

    update_level1_db,fits_hdr, hdr_orig=hdr, REPROCESS=reprocess
    
endif	$			; end of processing for 'DBMS'
ELSE print,'Not writing database file.'

done:
IF not (not_found) THEN BEGIN 
get_utc,dte,/ecs
printf,lulog,'Procedure reduce_level_1 ended at '+dte
for i=0,5 do printf,lulog
close,lulog
free_lun,lulog
ENDIF
print,''
print,''

return
END
