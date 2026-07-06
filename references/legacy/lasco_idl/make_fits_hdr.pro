function make_fits_hdr,h,img
;+
; NAME:				MAKE_FITS_HDR
;
; PURPOSE:			Generate a FITS header for Level 0.5 images
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		Result = MAKE_FITS_HDR (h,img)
;
; INPUTS:			H   = Header structure
;				Img = Image
;
; OUTPUTS:			Result = FITS header
;
; PROCEDURE:			Makes calls to FXADDPAR
;
; MODIFICATION HISTORY:		Written RA Howard, NRL, 31 Oct 1995
;   Version 2  rah 16 Nov 1995   Converted filter/polarizer/lp_num/readport
;   Version 3  rah 11 Dec 1995   Corrected tag name of polarizer & eit/detector
;   Version 4  rah 18 Jan 1996   Corrected exposure time to be entire exp & 
;                                added subsection times
;   Version 5  rah 15 Feb 1996   Corrected DATE-OBS/TIME-OBS
;   Version 6  rah 22 Feb 1996   Corrected FP WL Keywords to be 8 characters
;   Version 7  rah 18 Mar 1996   Added KW for LEB summing, and corrected exptime
;   Version 8  rah 19 Mar 1996   Corrected exposure time for dark and continuous images
;   Version 9  rah 27 Mar 1996   Corrected lp_num structure tag
;   Version 10 rah 03 Apr 1996   Modified exposure mid point names
;   Version 11 rah 05 Apr 1996   Compute exposure time in real
;   Version 12 sep 17 Jul 1996   Modified to work with new LEB header (obev145+)
;                                units on exp[1,2,3], version, order
;   Version 13 rah 22 Jul 1996   Increased WAVELENG to double precision
;   Version 14 rah 01 Aug 1996   Modified exptime calc for new OBE version
;                                Increased FP_WL* to double precision
;   Version 15 sep 18 Jun 1997   Changed call for new OFFSET_BIAS()
;   Version 16 rah 18 Jul 1997   BITPIX set to reflect the image data type
;
; @(#)make_fits_hdr.pro	1.10 07/24/97 :NRL Solar Physics
;
;-
;
ver='V15 18 Jun 1997'
fxaddpar,fits,'SIMPLE','T'
s = SIZE(img)
CASE s(s(0)+1) OF
  0:  bpix=16
  1:  bpix=8
  2:  bpix=16
  3:  bpix=32
  4:  bpix=32
  5:  bpix=64
  else: bpix=16
ENDCASE
fxaddpar,fits,'BITPIX',bpix
fxaddpar,fits,'NAXIS',s(0)
if (s(0) gt 0) then begin
   fxaddpar,fits,'NAXIS1',s(1)
   fxaddpar,fits,'NAXIS2',s(2)
endif else begin
   fxaddpar,fits,'NAXIS1',0
   fxaddpar,fits,'NAXIS2',0
endelse
fxaddpar,fits,'FILENAME',h.filename
fxaddpar,fits,'FILEORIG',h.fileorig
fxaddpar,fits,'DATE',h.date_mod
fxaddpar,fits,'DATE-OBS',strmid(h.date_obs,0,10)
fxaddpar,fits,'TIME-OBS',strmid(h.date_obs,11,12)
fxaddpar,fits,'P1COL',h.p1col
fxaddpar,fits,'P1ROW',h.p1row
fxaddpar,fits,'P2COL',h.p2col
fxaddpar,fits,'P2ROW',h.p2row
fxaddpar,fits,'VERSION',h.version
;
;  17 Jan 96:  The total exposure time is the sum of the following
;		Long pulse after open shutter command
;		Exposure delay which is the h.exp_dur now in header keyword 
;			'EXP0'
;		The round trip time to send the shutter close command, h.exp3,
;			less the long pulse.  
;
exptime = h.exp_dur/32.
IF (h.version GE 1) THEN exp123units = 2048. ELSE exp123units = 32.
IF ((h.lp_num NE 5) AND (h.lp_num NE 7)) THEN exptime=exptime+h.exp3/exp123units
;
;  19 Mar 96:	Correct for the 32 second jump in the absolute time,
;		allowing for the temporary work around
;  01 Aug 96:   Don't correct for obe header verison > 1
;
IF (h.version EQ 0) THEN $
   IF ( abs(h.exp_dur-h.exp_cmd) GT 3 ) THEN exptime = exptime - 32.
fxaddpar,fits,'EXPTIME',exptime
fxaddpar,fits,'EXP0',h.exp_dur/32.
fxaddpar,fits,'EXPCMD',h.exp_cmd/32.
fxaddpar,fits,'EXP1',h.exp1/exp123units
fxaddpar,fits,'EXP2',h.exp2/exp123units
fxaddpar,fits,'EXP3',h.exp3/exp123units
fxaddpar,fits,'TELESCOP','SOHO'
if (h.camera eq 3) then begin
   fxaddpar,fits,'INSTRUME','EIT'  
   fxaddpar,fits,'DETECTOR','EIT' 
endif else begin
   fxaddpar,fits,'INSTRUME','LASCO'
   fxaddpar,fits,'DETECTOR',string(h.camera+1,format='(1hC,i1)')
endelse
t=fxpar(fits,'DETECTOR')
fxaddpar,fits,'READPORT',cnvrt_port(h.readport)
fxaddpar,fits,'SUMROW',h.sumrow
fxaddpar,fits,'SUMCOL',h.sumcol
fxaddpar,fits,'LEBXSUM',h.lebxsum
fxaddpar,fits,'LEBYSUM',h.lebysum
fxaddpar,fits,'SHUTTR',h.shutter
fxaddpar,fits,'LAMP',h.lamp
fxaddpar,fits,'FILTER',cnvrt_filter(h.camera,h.filter)
if (h.camera eq 3) then fxaddpar,fits,'SECTOR',cnvrt_polar(h.camera,h.polar) $
                   else fxaddpar,fits,'POLAR',cnvrt_polar(h.camera,h.polar)
fxaddpar,fits,'LP_NUM',cnvrt_lp (h.lp_num)
fxaddpar,fits,'OS_NUM',h.os_num
fxaddpar,fits,'IMGCTR',h.image_ctr
fxaddpar,fits,'IMGSEQ',h.seq_num
fxaddpar,fits,'COMPRSSN',cnvrt_ip(h)
IF (h.hcomp_sf NE 0) THEN fxaddpar,fits,'HCOMP_SF',h.hcomp_sf
if (h.camera eq 0) then begin
   fxaddpar,fits,'FP_WL_UP',double(h.fp_wl_upl)
   fxaddpar,fits,'FP_WL_CM',double(h.fp_wl_cmd)
   fxaddpar,fits,'WAVELENG',double(h.fp_wl_upl)
   fxaddpar,fits,'FP_ORDER',h.fp_order
   fxaddpar,fits,'M1_PZ1',h.m1_pz1
   fxaddpar,fits,'M1_PZ2',h.m1_pz2
   fxaddpar,fits,'M1_PZ3',h.m1_pz3
endif
mjd = str2utc(h.date_obs)
;  removed mjuldate kw to split mid time into day and time KW
mid_time = mjd.time/1000.+exptime*0.5
mid_date = mjd.mjd
if (mid_time gt 86400.)   THEN BEGIN
   mid_time = mid_time-86400.
   mid_date = mid_date+1
ENDIF
fxaddpar,fits,'MID_DATE',mid_date
fxaddpar,fits,'MID_TIME',mid_time
fxaddpar,fits,'PLATESCL',subtense(h.camera)
fxaddpar,fits,'OFFSET',offset_bias(fits)
fxaddpar,fits,'IMAGE_CTR',h.image_ctr
fxaddpar,fits,'SEQ_NUM',h.seq_num
fxaddpar,fits,'OBT_TIME',utc2tai(h.date_obs)
fxaddpar,fits,'HISTORY',ver+' MAKE_FITS_HDR'
return,fits
end
