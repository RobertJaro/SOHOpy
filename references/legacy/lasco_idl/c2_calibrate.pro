
FUNCTION c2_calibrate,img0,header, NO_UPDATE=no_update, NO_CALFAC=no_calfac, NEW=new
;+
; NAME:
;	C2_CALIBRATE
;
; PURPOSE:
;	This function calibrates a C2 image to mean solar brightness units
;
; CATEGORY:
;	REDUCE
;
; CALLING SEQUENCE:
;	Result = C2_CALIBRATE(Img,Header)
;
; INPUTS:
;	Img:	A 2-D image array in units of DN
;	Header:	An image header (FITS or LASCO header structure)
;
; OUTPUTS:
;	The calibrated image is returned.  The units are mean solar 
;	brightness. The header is also modified.
;
; KEYWORDS:
;	NEW	Force read of calib arrays
;	NO_UPDATE	Do not use log files and force read of calib arrays
;	NO_CALFAC	Do not apply calibration factor (set = 1d)
;
; COMMON BLOCKS:
;	C2_CAL_IMG, DBMS
;
; RESTRICTIONS:
;	Only handles clear polarizer except for H-alpha
;	Must have LASCO IDL Library
;	Must have environment $LASCO_DATA defined
;
; PROCEDURE:
;	The routine reads in the vignetting and a mask array from the
;	$LASCO_DATA/calib directory.  To obtain the calibration
;	factors, it calls the C2_CALFACTOR procedure.
;
; MODIFICATION HISTORY:
; 	Written by: Ed Esfandiari  April 08, 1999	
;       V1  aee  Apr 08, 99 First version (based on c3_calibrate). 
;       V2  dw   Sep 18, 99 Added no_calfac keyword (apply summing and vignetting only)
;       V3  aee  Apr 25, 00 Removed !Version.os eq 'OSF' statement. It is not needed since
;                           C2 vignetting is a .fts file which is machine independent.
;	nbr Nov  7 2001 - Add-ons for reduce_level_1: add HISTORY comments in header; use 
;			$LASCO_DATA; use SCCS version
;	nbr Jun 25 2002 - Update get_cal_name argument
;	nbr Mar 10 2003 - Add functionality for non-PB summed images
;	nbr May 14 2003 - Remove errant stop
;	nbr Aug 20 2003 - Name vig file explicitly
;     K.Battams 9/20/05 - New vig function (final release!)
;     K.Battams 9/30/05 - Add a blank space before each HISTORY entry.
;       Oct03,05 KarlB  - Remove "tab" spaces from HISTORY comments
;
;
; Variables for SCCS and FITS header 
;
ver= '@(#)c2_calibrate.pro	1.14, 07/14/16' ;NRL LASCO IDL LIBRARY
;
;      
;-

COMMON c2_cal_img, vig_full, vig_fn, msk_fn, ramp_fn, ramp_full, dte_vig
COMMON dbms, ludb,lulog,delf

img=img0
;version = 'C2_CALIBRATE:  Version 1, April 08, 1999'
version = strcompress(STRMID(ver,4,strlen(ver)))
szlog = SIZE(lulog)
hdr = header
IF (DATATYPE(hdr) NE 'STC')  THEN hdr=LASCO_FITSHDR2STRUCT(hdr)
IF (hdr.detector NE 'C2')  THEN BEGIN
   PRINT,'ERROR:  c2_calibrate - Wrong telescope '+hdr.detector
   RETURN,0
END
;
;  c2_calfactor returns a factor in units of MSB/(DN/pixel-sec)
;
valid= GET_EXP_FACTOR(header,expfac,bias)	
; ** Returns modified header, exposure correction factor, and dark current offset
hdr.EXPTIME= hdr.EXPTIME*expfac
hdr.offset = bias
calfac = c2_calfactor(header)
if keyword_set (no_calfac) then calfac = 1.0d      ; Added 18 Sep 1999 - DW
;factor = calfac/hdr.EXPTIME
help,calfac
;
;  Check to see if vignetting function already read in
;  If it hasn't, then read it and the mask in
;
sz = SIZE(vig_full)

IF (sz(0) EQ 0 or KEYWORD_SET(no_update)) or keyword_set(NEW) THEN BEGIN

   sd = getenv ('LASCO_DATA')+'/calib/'
   CD,sd,CURRENT=cur_dir
   dte = STR2UTC(hdr.date_obs)
   yymmdd = UTC2YYMMDD(dte)

;  Note: vig_fn should already be inverted (1.0/vig) and maximum mask set (i.e.
;        100). Unlike C3, We use readfits to read it (i.e. inv_vigc2_512506.fts)
;        So, C2_bl_vig_960611_v01.dat should point to inv_vigc2_512506.fts, for
;        example.

   ;vig_fn= get_cal_name('C2_'+abbrv_filpol(hdr.filter)+'*vig*.dat',yymmdd)
  ; vig_fn = 'inv_vigc2_512506.fts'
   vig_fn = 'c2vig_final.fts'  ; K.Battams 9/20/05 -- this vig_fn is already inverted and is for pre and post interrupt
   if(vig_fn ne '') then begin 
     dte_vig = FILE_DATE_MOD(vig_fn,/DATE_ONLY)
     print,'Using ',vig_fn
     vig = READFITS(vig_fn,hvig)
;     if !Version.os eq 'OSF' then vig = swap_endian(vig)
     IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       printf,lulog,'Used '+vig_fn

;    	Apply mask to vignetting correction.
;	(set negative values to 0.0 and set values > 100.0 to 100.0)

     vig_full= vig  
     low= where(vig_full lt 0.0,cnt)
     if(cnt gt 0) then vig_full(low)= 0.0 
     high= where(vig_full gt 100.0,cnt)
     if(cnt gt 0) then vig_full(high)= 100.0

   endif else begin
     print,'ERROR: c2_calibrate - No '+sd+'C2_bl*vig*.dat file'
     IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       printf,lulog,'ERROR: c2_calibrate - No '+sd+'C2_bl*vig*.dat file'
     return,0
   endelse
   CD,cur_dir

ENDIF

IF (hdr.r1col NE 20) OR (hdr.r1row NE 1) OR $
   (hdr.r2col NE 1043) OR (hdr.r2row NE 1024) THEN BEGIN
   x1=hdr.r1col-20
   x2=hdr.r2col-20
   y1=hdr.r1row-1
   y2=hdr.r2row-1
   vig =  vig_full(x1:x2,y1:y2)
ENDIF ELSE vig = vig_full

vig_size = size(vig)

   ; value of lebsummed = 4(v + b)
   ; correctedval = (val/4) - b = (val - b*4)/4
   ; value of chipsummed = 4v + b
   ; correctedval = (val - b)/4 
   ;
   ; val is corrected in calfac
   ; bias is *4 in offset_bias.pro, if appropriate

summsg = 'F'
summing = (hdr.sumcol>1)*(hdr.sumrow>1)
IF (summing GT 1)  THEN BEGIN 
   FOR i=1,summing,4 DO BEGIN
      vig=rebin(vig,vig_size(1)/2,vig_size(2)/2)
      IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       	printf,lulog,'Corrected for binning due to onchip summing.'
      summsg = 'Values corrected for onchip summing.'
      print,summsg
   ENDFOR 
ENDIF 
summing = (hdr.lebxsum)*(hdr.lebysum)
IF (summing GT 1)  THEN BEGIN 
   FOR i=1,summing,4 DO BEGIN 
      vig=rebin(vig,vig_size(1)/2,vig_size(2)/2)
      IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       	printf,lulog,'Corrected for binning due to lebsumming.'
      summsg = 'Values corrected for LEB summing.'
      print,summsg
   ENDFOR 
ENDIF 

IF (not KEYWORD_SET(no_update))  THEN $
  IF (DATATYPE(header) NE 'STC')  THEN BEGIN
    FXADDPAR,header,'HISTORY',' '+strcompress(version)
    FXADDPAR,header,'HISTORY',' '+strcompress(vig_fn)+', '+strcompress(dte_vig)
    ;FXADDPAR,header,'HISTORY',msk_fn
    IF (valid LT 0) then FXADDPAR,header,'HISTORY',' WARNING: No exposure correction found.' $
    ;FXADDPAR,header,'CALFAC',calfac,'Conversion from DN to MSB'
    ;FXADDPAR,header,'EXPFAC',expfac,'Exposure time correction factor'
    ELSE FXADDPAR,header,'EXPTIME',hdr.EXPTIME,' Corrected exposure time (seconds)'
    ;FXADDPAR,header,'OFFSET',bias,'Corrected CCD offset bias'
    IF summsg NE 'F' THEN FXADDPAR,header,'HISTORY',' '+strcompress(summsg)
  ENDIF 

;
;  Check to see if the image is a PB image created from level 0.5
;  images and if so, then don't subtract the offset bias
;
IF (hdr.polar EQ 'PB' or $
    hdr.polar EQ 'TI' or $
    hdr.polar EQ 'UP' or $
    hdr.polar EQ 'JY' or $
    hdr.polar EQ 'JZ' or $
    hdr.polar EQ 'Qs' or $
    hdr.polar EQ 'Us' or $
    hdr.polar EQ 'Qt' or $
    hdr.polar EQ 'Qt' or $
    hdr.polar EQ 'Jr' or $
    hdr.polar EQ 'Jt' )  THEN BEGIN

	img = img/hdr.exptime
	img = img*calfac
	img = img*vig
	RETURN,img

ENDIF ELSE BEGIN

        img = (img-bias)*calfac/hdr.exptime
	img = img*vig
 	RETURN,img
ENDELSE

END



