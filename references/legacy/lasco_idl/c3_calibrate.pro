FUNCTION c3_calibrate, img0, header, NO_UPDATE=no_update, NO_CALFAC=no_calfac, $
	NO_VIG=no_vig, FUZZY=fuzzy, NO_MASK=no_mask, NEW=new
;+
; NAME:
;	C3_CALIBRATE
;
; PURPOSE:
;	This function calibrates a C3 image to mean solar brightness units
;
; CATEGORY:
;	REDUCE
;
; CALLING SEQUENCE:
;	Result = C3_CALIBRATE(Img,Header)
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
;	NO_VIG	Do not apply vignetting correction or pylon mask (set = 1.)
;	NO_MASK Do not apply pylon/occulter mask to vig correction
;	FUZZY	Interpolate gaps with fuzzy logic procedure
;	NEW	Force read of calib arrays
;	NO_UPDATE	Do not use log files and force read of calib arrays
;	NO_CALFAC	Do not apply calibration factor (set = 1d)
;
; COMMON BLOCKS:
;	C3_CAL_IMG, DBMS
;
; RESTRICTIONS:
;	Only handles clear polarizer except for H-alpha
;
; PROCEDURE:
;	The routine reads in the vignetting and a mask array from the
;	$LASCO_DATA/calib directory.  To obtain the calibration
;	factors, it calls the C3_CALFACTOR procedure.
;
; MODIFICATION HISTORY:
; 	Written by:	RA Howard, 4/96
;       V1  rah Apr 04 96 First version.
;       V2  aee Sep 30 97 Added exposure factor and header updates.
;       V3  rah Oct 31 97 Call to READ_EXP_FACTOR changed to GET_EXP_FACTOR
;       V4  rah Nov 07 97 reference to FILEORIG changed to use DATE_OBS
;       V5  dw  Sep 10 98 Added more polariz id flags beside PB
;       V6  dab Nov 25 98 Added SWAP_ENDIAN for OSF operating systems
;       V7  dw  Feb 10 99 Changed from IMG_SUM_2x2 to rebin for summed images
;       V8  av  Mar 17 99 Added SL ramp correction
;       V9  dw  Mar 28 99 changed SL ramp correction to ramp_fn(0)
;       V9a rh  Apr  9 99 changed ramp to ramp_full in common
;       V10 aee Apr 09 99 Added no_update keyword (used in image_profiles).
;       V11 dw  Apr 09 99 Added no_calfac keyword (apply summing and vignetting only)
;	nbr Jul 12 2000 - Change version init, header update
;	nbr Jul 27 2000 - Apply ramp before vignetting correction 
;	nbr Aug  4 2000 - CD to calib directory instead of using full path; 
;			edit HISTORY in header
;	nbr Aug  7 2000 - Change call to GET_EXP_FACTOR
;	nbr Oct  2 2000 - Add FUZZY, NO_VIG keywords
;	nbr Oct 25 2000 - Use READFITS to read vig and mask arrays
;	nbr Jan 18 2000 - Change vig to vig_full in common block
;	nbr Jan 24 2001 - Add bkg, mask_blocks to common block
;	nbr Nov  6 2001 - Subtract ramp AFTER vignetting correction and add better 
;			documentation; different order; do not apply
;			mask to ramp
;       av  Nov 20 2001 - Input image is now returned unchanged.
;	nbr Jun 25 2002 - Update get_cal_name argument
;	nbr Jul  5 2002 - Change bkg used for fuzzy_image
;	nbr Mar 10 2003 - Add functionality for sub-fields and non-PB summed images;
;			  define mask even if NO_MASK is set; only one vig and one mask
;	nbr Apr 10 2003 - Change bkg and order of operations around fuzzy_image
;	nbr Aug 20 2003 - Name vig and mask files explicitly
;	nbr Sep  8 2003 - Comment changes, use A.Thernisien vignetting
;	nbr Nov  5 2003 - Use inverted A.Thernisien vignetting        
;	nbr Nov  6 2003 - Use expanded A.Thernisien vignetting       
;	nbr Nov  7 2003 - Fix mask application 
;	nbr Jan  2 2004 - Update mask
;       nbr Apr  2 2004 - Remove comment about fuzzy_image; new mask
;	nbr Apr  8 2004 - New mask
;   K.Battams 6/22/2005 - Another new A.Thernisien vignetting function...
;                         This time there are two for pre- and post- interruption.
;   K.Battams 7/28/2005 - New vig function (previous function shifted half-pixel left)
;                       - New C3 cl mask (very slightly larger)
;   K.Battams 9/30/2005 - Add a blank space before each HISTORY entry.
;   
;
; Variables for SCCS and FITS header 
;
ver= '@(#)c3_calibrate.pro	1.54, 07/14/16' ; NRL LASCO IDL LIBRARY
;
;      
;-

COMMON c3_cal_img,vig_full,mask,vig_fn,msk_fn, ramp_fn, ramp_full, dte_vig, dte_msk, $
 dte_ramp,bkg_full, hb,mask_blocks,mask_full
COMMON dbms, ludb,lulog,delf

img=img0
;version = 'C3_CALIBRATE:  Version 10, Apr 09, 1999'
version = strcompress(STRMID(ver,4,strlen(ver)))
szlog = SIZE(lulog)
hdr = header
IF (DATATYPE(hdr) NE 'STC')  THEN hdr=LASCO_FITSHDR2STRUCT(hdr)
IF (hdr.detector NE 'C3')  THEN BEGIN
   PRINT,'ERROR:  c3_calibrate - Wrong telescope '+hdr.detector
   RETURN,0
END
;
;  C3_CALFACTOR returns a factor in units of MSB/(DN/pixel-sec).
;
valid= GET_EXP_FACTOR(header,expfac,bias)	
; ** Returns modified header, exposure correction factor, and dark current offset
hdr.EXPTIME= hdr.EXPTIME*expfac
hdr.offset = bias
if keyword_set (no_calfac) then calfac = 1.0d	$; Added 18 Sep 1999 - DW
  ELSE calfac = C3_CALFACTOR(header)		; Returns modified header
;factor = calfac/hdr.EXPTIME
help,calfac
;
;  To speed things up, check to see if vignetting correction already read in.
;  If it hasn't, then load vignetting correction, ramp, mask and C3min.
;
sz = SIZE(vig_full)
;stop
IF datatype(vig_full) EQ 'UND' OR $
   datatype(mask_full) EQ 'UND' OR $
   datatype(ramp_full) EQ 'UND' OR $
   datatype(bkg_full) EQ 'UND' OR $
   KEYWORD_SET(no_update) OR $
   keyword_set(NEW)  THEN BEGIN
   sd = getenv ('LASCO_DATA')+'/calib/'
   CD,sd,CURRENT=cur_dir
   dte = STR2UTC(hdr.date_obs)
   yymmdd = UTC2YYMMDD(dte)
   
   mjd = dte.mjd
   
   ; =====  This is the C3 vig fn "history"... =========
   ;vig_fn= get_cal_name('C3_cl*vig*.dat',yymmdd)
   ; currently only one vignetting correction - nbr, 3/13/03
   ;vig_fn= get_cal_name('C3_'+abbrv_filpol(hdr.filter)+'*vig*.dat',yymmdd)
   ;vig_fn='/data3/stars/pros/C3clearvig_001211.fts'
   ;vig_fn='/data3/stars/pros/C3clearvig_001024.fts'
   ;vig_fn='$NRL_LIB/lasco/reduce/las_c3/C3_clearvig_las.fts'
   ;vig_fn='C3_cl_vig_951201_v02.dat'
   ;vig_fn = 'C3clearvig_nrl.fts'
   ;vig_fn = 'c3vig_20030829.fts'
   ;vig_fn = 'c3vig_20030829inv.fts'
   ;vig_fn = 'c3vig_20031106.fts'		; 2003.11.06, nbr
   
   ; We now have two C3 vig functions so we have to test the date to
   ; see if it's pre- or post- SOHO's "vacation".  I chose mjd just for convenience.
   ; An mjd value of 51000 corresponds to ~ July 6th, 1998  (51000 is a nice round number...)  
   ; KB  6/22/2005
  IF (mjd LT 51000) THEN vig_fn = 'c3vig_preint_final.fts' ELSE vig_fn = 'c3vig_postint_final.fts'     ; KB July 13, 2005

  if(vig_fn ne '') then begin 
     ;vig = fltarr(1024,1024)
     ;mask = vig
     dte_vig = FILE_DATE_MOD(vig_fn,/DATE_ONLY)
     ;OPENR,lucal,vig_fn,/GET_LUN
     ;READU,lucal,vig
     print,'Using ',vig_fn
     vig_full = READFITS(vig_fn)
;     if !Version.os eq 'OSF' then vig_full = swap_endian(vig_full)
;     ** Not necessary, using FITS files.
     IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       printf,lulog,'Used '+vig_fn+', last mod '+dte_vig
     ;CLOSE,lucal
     ;FREE_LUN,lucal
   endif else begin
     print,'ERROR: c3_calibrate - No '+sd+'C3_cl*vig*.dat file'
     IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       printf,lulog,'ERROR: c3_calibrate - No '+sd+'C3_cl*vig*.dat file'
     return,0
   endelse 

;   IF NOT(keyword_set(NO_MASK)) THEN BEGIN
   ;msk_fn= get_cal_name('C3_cl*msk*.dat',yymmdd)
   ;msk_fn='C3_cl_msk_951201_v04.fts'
   ;msk_fn='C3_cl_msk_951201_v05.fts'		; 2003.11.06, nbr
   ;msk_fn='C3_cl_msk_951201_v06.fts'		; 2004.01.02, nbr
   ;msk_fn='C3_cl_msk_951201_v07.fts'		; 2004.04.02, nbr
   ;msk_fn='C3_cl_msk_951201_v08.fts'           ; 2004.04.08, nbr
   
    msk_fn='c3_cl_mask_lvl1.fts'        ; KB July 28, 2005
  IF (msk_fn ne '') then begin
     dte_msk = FILE_DATE_MOD(msk_fn,/DATE_ONLY)
     ;OPENR,lucal,msk_fn,/GET_LUN
     ;READU,lucal,mask
     print,'Using ',msk_fn
     mask_full = READFITS(msk_fn)
     IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       printf,lulog,'Used '+msk_fn+', last mod '+dte_msk
     ;CLOSE,lucal
     ;FREE_LUN,lucal
   ENDIF else begin
     print,'ERROR: c3_calibrate - No '+sd+'C3_cl*msk*.dat file'
     IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       printf,lulog,'ERROR: c3_calibrate - No '+sd+'C3_cl*msk*.dat file'
     return,0
   ENDELSE
;   ENDIF
   
   ramp_fn = FINDFILE('C3ramp.fts')
   ramp_fn = ramp_fn(0)
   if(ramp_fn ne '') then begin
      dte_ramp = FILE_DATE_MOD(ramp_fn,/DATE_ONLY)
      print,'Using ',ramp_fn
      ramp_full = READFITS(ramp_fn)
      ;ramp_full(WHERE(mask EQ 0)) = 0 		; Include mask in ramp
	; ** DO NOT include mask on ramp - nbr, 11/8/01 **
   endif else begin
     print,'ERROR: c3_calibrate - No '+sd+'C3ramp.fts'
     IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       printf,lulog,'ERROR: c3_calibrate - No '+sd+'C3ramp.fts file'
     return,0
   ENDELSE

   ; ** This is for FUZZY_IMAGE below
   bkg_full = LASCO_READFITS('3m_clcl_all.fts',hb)
   bkg_full = 0.8*bkg_full/hb.exptime ; so that tempim has no zeros
   ; **

   CD,cur_dir
ENDIF
;IF keyword_set(NO_MASK) THEN vig=vig_full ELSE vig = vig_full*FLOAT(mask_full)
vig=vig_full
IF keyword_set(NO_VIG) THEN vig=replicate(1d,1024,1024) 

IF ((hdr.r1col NE 20) OR (hdr.r1row NE 1) OR $
   (hdr.r2col NE 1043) OR (hdr.r2row NE 1024)) and hdr.r2col NE 0 THEN BEGIN
   x1=hdr.r1col-20
   x2=hdr.r2col-20
   y1=hdr.r1row-1
   y2=hdr.r2row-1
   vig  = vig(x1:x2,y1:y2)
   ramp = ramp_full(x1:x2,y1:y2)
   bkg  = bkg_full(x1:x2,y1:y2)
   mask = mask_full(x1:x2,y1:y2)
ENDIF ELSE BEGIN
   ramp = ramp_full
   bkg  = bkg_full
   mask = mask_full
ENDELSE

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
      ramp=rebin(ramp,vig_size(1)/2,vig_size(2)/2)
      mask=rebin(mask,vig_size(1)/2,vig_size(2)/2)
      bkg=rebin(bkg,vig_size(1)/2,vig_size(2)/2)
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
      ramp=rebin(ramp,vig_size(1)/2,vig_size(2)/2)
      mask=rebin(mask,vig_size(1)/2,vig_size(2)/2)
      bkg=rebin(bkg,vig_size(1)/2,vig_size(2)/2)
      IF (szlog(0) NE 0 and (not KEYWORD_SET(no_update)) )   THEN $
       	printf,lulog,'Corrected for binning due to lebsumming.'
      summsg = 'Values corrected for LEB summing.'
      print,summsg
   ENDFOR 
ENDIF 

IF (not KEYWORD_SET(no_update))  THEN $
IF (DATATYPE(header) NE 'STC')  THEN BEGIN
    	FXADDPAR,header,'HISTORY',' '+strcompress(version)
    	IF keyword_set(NO_VIG) THEN $
    	FXADDPAR,header,'HISTORY',' No vignetting correction applied' ELSE $
	FXADDPAR,header,'HISTORY',' '+strcompress(vig_fn)+', '+strcompress(dte_vig)
    	IF NOT(keyword_set(NO_MASK)) THEN FXADDPAR,header,'HISTORY',strcompress(msk_fn)+', '+strcompress(dte_msk)
    	FXADDPAR,header,'HISTORY',' '+strcompress(ramp_fn)+', '+strcompress(dte_ramp)
    	IF (valid LT 0) THEN FXADDPAR,header,'HISTORY',' WARNING: No exposure correction found.' $
	; values added in subpros
    	;FXADDPAR,header,'CALFAC',calfac,' Conversion from DN to MSB'
    	;FXADDPAR,header,'EXPFAC',expfac,' Exposure time correction factor'
    	;FXADDPAR,header,'OFFSET',bias,' Corrected CCD offset bias'
    	ELSE FXADDPAR,header,'EXPTIME',hdr.EXPTIME,' (Seconds) Corrected'
    	IF summsg NE 'F' THEN FXADDPAR,header,'HISTORY',strcompress(summsg)
ENDIF 

IF hdr.fileorig EQ 0 THEN BEGIN  ; monthly image
	img = img0/hdr.exptime
	img = img*calfac*vig - ramp
	IF NOT(keyword_set(NO_MASK)) THEN img=img*mask
	RETURN,img

ENDIF     ;

;  No info on ramp function for colored filters
;  Better to leave it alone and subtract nothing until we know more
;  11/5/99 - DW

if (hdr.FILTER ne 'Clear') then ramp = 0

;  Check to see if the image is a PB image created from level 0.5
;  images and if so, then don't subtract the offset bias or ramp
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
    hdr.polar EQ 'Jt')  THEN BEGIN

	img = img0/hdr.exptime
	img = img*calfac*vig
	IF NOT(keyword_set(NO_MASK)) THEN img=img*mask
	RETURN,img

ENDIF ELSE BEGIN
	zz = WHERE(img0 LE 0, nzz)		; zz is for FUZZY_IMAGE

        img = (img0-bias)/hdr.exptime
        ;img = img0
	; We must subtract bias and normalize to exptime here because of 
	; cases where exptime is small.

	; ** This part is ONLY for filling missing blocks
	IF 	keyword_set(FUZZY) 	AND $
		hdr.filter EQ 'Clear' 	AND $
		nzz GT 1000 		THEN BEGIN
	   tempim = (img - bkg)>0
	   tempim = FUZZY_IMAGE(tempim,hdr=header, TOO_MANY=mask_blocks)
	   newimg = bkg + tempim 
	   img[zz] = newimg[zz]
	   ;; now correct for changing bias, if necessary
	   ;tzz = where(tempim EQ 0,ntzz)
	   ;IF ntzz GT 0 THEN img[tzz]=img[tzz]+((bias-320)>0)/hb.exptime
	   IF mask_blocks GT 100 THEN $
	   FXADDPAR,header,'HISTORY',' GT 100 missing blocks in zone--missing blocks not replaced.' 
	ENDIF
	; **
	img = img*vig*calfac - ramp
	; ** According to A. Vourlidas, ramp is not vignetted. (2001.11.06)
	IF NOT(keyword_set(NO_MASK)) THEN img=img*mask
 	RETURN,img
ENDELSE

END

