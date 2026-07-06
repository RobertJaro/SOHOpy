pro reduce_img_hdr,hdr, DAY_ONLY=day_only
;+
; NAME:
;	REDUCE_IMG_HDR
;
; PURPOSE:
;	This procedure appends information from the current image header to 
;	the header files in $LAST_IMG and in the current image directory.
;
; CATEGORY:
;	REDUCTION
;
; CALLING SEQUENCE:
;	REDUCE_IMG_HDR, Hdr
;
; INPUTS:
;	Hdr = FITS header
;
; OPTIONAL INPUTS:
;	None
;	
; KEYWORD PARAMETERS:
;	DAY_ONLY	Only update current directory
;
; OUTPUTS:
;	None
;
; OPTIONAL OUTPUTS:
;	None
;
; MODIFICATION HISTORY:
;	Written, RA Howard, NRL
;   VERSION 1  rah 16 Dec 1995
;           2  rah 28 Dec 1995  Changed environment variable to LAST_IMG
;           3  rah 29 Mar 1996  Write info to date directory also
;           4  rah  4 Apr 1996  Modify filt/polar filed to be A6 from A5
;           5  rah 26 Aug 1996  Added FP WL and OS Num to listing
;	    6  nbr  6 Mar 1997  Write info to catalogs/daily directory
;	    7  sep  3 Sep 1997  Write info to catalogs/daily_combined directory
;           8  aee 21 Oct 1997  If level 1 or 2 image, write img_hdr.txt info 
;                               only to the date directory.
;	nbr 29 Aug 2000	- Write catalog files to $LAST_IMG instead of $IMAGES;
;			  Add DAY_ONLY keyword
;	nbr 11 Oct 2000 - Write img_hdr.txt file in $IMAGES also if NE $LAST_IMG
;	nbr  9 Apr 2003 - Modify for level 1 processing
;	nbr 25 Aug 2003 - imghdr changes
;       k.battams 6/03/2005 -- get correct format for Level-1 img_hdr's
;
; SCCS variables for IDL use
; 
; @(#)reduce_img_hdr.pro	1.13 09/08/03 :NRL LASCO IDL LIBRARY
;
;
;-
;
fn     = FXPAR (hdr,'FILENAME')
lvlnum = fix(strmid(fn,1,1))

if (lvlnum NE 5) then begin
    date   = FXPAR (hdr,'DATE-OBS')
    time   = STRMID(FXPAR (hdr,'TIME-OBS'),0,8)
endif else begin   ; KB added this next bit
    date1=FXPAR (hdr,'DATE-OBS')
    date=strmid(date1, 0, 4)+'/'+strmid(date1, 5,2)+'/'+strmid(date1, 8,2)
    time=strmid(date1,11, 8)    
endelse    
    
sz     = SIZE(date)
IF (sz(1) ne 7) THEN BEGIN
   date   = FXPAR (hdr,'DATE_OBS')
   time   = STRMID(FXPAR (hdr,'TIME_OBS'),0,8)
ENDIF
tel    = STRTRIM(FXPAR (hdr,'DETECTOR'),2)
exptime = STRTRIM (FXPAR (hdr,'EXPTIME'),2)
naxis1 = FXPAR(hdr,'NAXIS1')
naxis2 = FXPAR(hdr,'NAXIS2')
;stop
IF lvlnum LT 4 THEN BEGIN
	p1col  = FXPAR(hdr,'P1COL')
	p1row  = FXPAR(hdr,'P1ROW')
	lp_num = FXPAR(hdr,'LP_NUM')
	fp_wl =  FXPAR(hdr,'FP_WL_UP')
	os_num = FXPAR(hdr,'OS_NUM')
ENDIF ELSE BEGIN
	p1col  = FXPAR(hdr,'R1COL')
	p1row  = FXPAR(hdr,'R1ROW')
	lp_num = trim(FXPAR(hdr,'COMPRSSN'))
	fp_wl =  FXPAR(hdr,'CROTA')
	os_num = FXPAR(hdr,'NMISSING')
ENDELSE
filt   = FXPAR(hdr,'FILTER')
if (tel eq 'EIT') then pol = FXPAR(hdr,'SECTOR') $
                  else pol = FXPAR(hdr,'POLAR')

OPENW,lu,'img_hdr.txt',/get_lun,/append
PRINTF,lu,fn,    date,  time, tel,exptime,naxis1,naxis2,p1col,p1row,filt, pol,  lp_num,fp_wl,os_num, $
 format='(a12,2x,a12,2x,a8,2x,a3, f8.1,   4i7,2x,                   a6,2x,a6,2x,a8,    f11.4,i6)'
close,lu

IF keyword_set(DAY_ONLY) THEN BEGIN
 	FREE_LUN,lu  
 	return  
ENDIF

;stop
IF lvlnum LT 4 THEN imghdr = GETENV_SLASH('LAST_IMG')  $
	ELSE imghdr = GETENV_SLASH('RED_L1_PATH')	; nbr, 8/25/03
help,imghdr
OPENW,lu,imghdr+'img_hdr.txt',/append
PRINTF,lu,fn,date,time,tel,exptime,naxis1,naxis2,p1col,p1row,filt,pol,lp_num, $
       fp_wl,os_num,  $
       format='(a12,2x,a12,2x,a8,2x,a3,f8.1,4i7,2x,a6,2x,a6,2x,a8,f11.4,i6)'
CLOSE,lu

imghdr2 = GETENV_SLASH('IMAGES')  ; level 0.5 images.
IF imghdr2 NE imghdr and lvlnum LT 4 THEN BEGIN		; nbr, 8/25/03
   print,'Appending second img_hdr.txt in ',imghdr2
   OPENW,lu,imghdr2+'img_hdr.txt',/append
   PRINTF,lu,fn,date,time,tel,exptime,naxis1,naxis2,p1col,p1row,filt,pol,lp_num, $
       fp_wl,os_num,  $
       format='(a12,2x,a12,2x,a8,2x,a3,f8.1,4i7,2x,a6,2x,a6,2x,a8,f11.4,i6)'
   CLOSE,lu
ENDIF

; write img_hdr.txt files in catalogs directory

rtdir = imghdr
parts=STR_SEP(rtdir,'/')
IF lvlnum EQ 2 THEN srce = '_lz_05.txt' ELSE $
IF lvlnum EQ 1 THEN srce = '_ql_05.txt' ELSE $
IF lvlnum EQ 5 or lvlnum EQ 6 THEN srce = '_lz_1.txt' ELSE $
	BEGIN
		help,lvlnum
		message,'Not writing catalogs.',/inform
		free_lun,lu
		return
	ENDELSE
utctime=str2utc(date+' '+time)
daydir=utc2yymmdd(utctime)
OPENW,lu,rtdir+'catalogs/daily/'+STRTRIM(STRLOWCASE(tel))+'_'+daydir+srce,/append
PRINTF,lu,fn,date,time,tel,exptime,naxis1,naxis2,p1col,p1row,filt,pol,lp_num, $
       fp_wl,os_num,  $
       format='(a12,2x,a12,2x,a8,2x,a3,f8.1,4i7,2x,a6,2x,a6,2x,a8,f11.4,i6)'
CLOSE,lu
FREE_LUN,lu

; write combined (c1,c2,c3,eit) img_hdr.txt files in catalogs directory
OPENW,lu,rtdir+'catalogs/daily_combined/'+daydir+srce,/append
PRINTF,lu,fn,date,time,tel,exptime,naxis1,naxis2,p1col,p1row,filt,pol,lp_num, $
       fp_wl,os_num,  $
       format='(a12,2x,a12,2x,a8,2x,a3,f8.1,4i7,2x,a6,2x,a6,2x,a8,f11.4,i6)'
CLOSE,lu
FREE_LUN,lu

END
