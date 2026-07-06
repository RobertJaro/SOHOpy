function c3_calfactor,Header, NOSUM=nosum
;+
;NAME:
;	C3_CALFACTOR
;
;PURPOSE:
;	This function returns the calibration factor for a given C3 image
;
;CATEGORY:
;	REDUCE
;
;CALLING SEQUENCE:
;	result = C3_CALFACTOR(Header)
;
;INPUT:	
;	Header:	image header, either fits or lasco structure
;
;Keywords:
;	NOSUM	If set, do not correct for summing
;
;OUTPUT:
;	Image calibration factor in (B/Bsun)/(DN/pixel-second)
;
;PROCEDURE:
;
;  The document describes the C3 calibration factors from "Photometric Calibration 
;  of the LASCO-C3 Coronagraph Using Stars" (Thernisien et al 2006). Previous values
;  were derived from the laboratory images taken in April 1994.
;  The calibration factor is in 10^-10 (B/Bsun)/(DN/pixel-second).
;  The units of the image to be multiplied need to be DN/pixel-second.
;  The calibration factor is then scaled appropriately for pixel summation.
;
;  Additional work will be required to remove a number of other factors.
;  The calibration factor numbers need the port amplifier
;  effect removed; color effects removed (IR filter affected greatly) and a
;  number of other corrections.  The photometric effect of pixel summation will
;  have to be examined.
;
;  filter	polarizer	calibration factor
;  			        (10^-10B/Bsun)/(DN/pixel-second)

;				Thernisien 2006	(Preflight)
;  clear	clear		0.00609		(0.00503)		
;  blue		clear		0.0975		(0.1033)
;  orange	clear		0.0297		(0.0286)
;  deep red	clear		0.0259		(0.01937)
;  infrared	clear		0.0887		(0.1055)  
;  clear 	Halpha		na		(1.541)
;
;  These were evaluated with the flat field response set to 1.0 at 20Rsun
;  altitude.  Areas of the field inside and outside 20Rsun will be somewhat
;  effected by the flat field calibration (+/- 10-15%).
;
;	the output is automatically scaled for pixel summing
;
; MODIFICATION HISTORY:
;	Written Clarence Korendyke, NRL
;	V1	3/15/96	CMK	raw calibration factors computed with tabulated exposure durations
;	V2	3/17/96	CMK	calibration factor corrected for exp cmd and exp duration and exp2
;	V3	6/13/98	RAH	modified to allow polarizer coeffs to be different for each filter
;				updated coeffs for latest values, obtained from calibration window
;				ratios with door closed
;	7/19/00 NBR	Change Version to use SCCS version; change header HISTORY
;	1/19/01 NBR	Change clear-clear factor to match above comments
;	3/11/03 NBR	Add /NOSUM
;       6/8/05  RAH     Add time variable calibration coefficient
;       6/22/05 Karl B  Small bug fix.
;       11/01/05 RAH/KB Modify calfactor for C3 clear (subtract 50000 from mjd)
;   	12/11/06, NBR	Change color filter values to match Thernisien paper. Clear value unchanged.
;
; SCCS variables for IDL use
; 
ver= '@(#)c3_calfactor.pro	1.17 11/06/12' ;LASCO IDL LIBRARY
;-
;
version = STRMID(ver,4,strlen(ver))
hdr = header
IF (DATATYPE(hdr) NE 'STC')  THEN hdr=LASCO_FITSHDR2STRUCT(hdr)
dte=STR2UTC(hdr.date_obs)
mjd=dte.mjd
;
;retrieve filter and polarizer position from the header
;
filter = STRUPCASE(STRCOMPRESS(hdr.filter,/remove_all))
polarizer = STRUPCASE(STRCOMPRESS(hdr.POLAR,/remove_all))
;
;set calibration factor for the various filters
;
CASE filter OF
  'ORANGE': 	BEGIN 
                   cal_factor=0.0297	;0.0286
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE polarizer OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref*.9648
                     '-60DEG':	cal_factor=polref*1.0798
                     ELSE:		cal_factor=cal_factor*1.
                   ENDCASE
                END
  'BLUE':	BEGIN 
                   cal_factor=0.0975	;0.1033
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE polarizer OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref*0.9734
                     '-60DEG':	cal_factor=polref*1.0613
                     ELSE:		cal_factor=cal_factor*1.
                   ENDCASE
                END
  'CLEAR':	BEGIN
                   ;cal_factor=0.0053
                   ;cal_factor=0.00503
;
;   cal_factor for the clear has been determined (Thernisien et al,
;   2005) to be a function of year according to the form y=mx+b
;   where x is the Modified Julian Date (JD- 2450000.5).  The cal
;   factor is in units of 1.e-10 MSB.
;
                   cal_factor=7.43e-8*(mjd-50000)+5.96e-3

                   polref=cal_factor/.25256		; absolute value of +60
                   CASE STRUPCASE(polarizer) OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref*0.9832
                     '-60DEG':	cal_factor=polref*1.0235
		     'H_ALPHA':	cal_factor=1.541
		     ELSE:		cal_factor=0.
                   ENDCASE
                END
  'DEEPRD':	BEGIN
                   cal_factor=0.0259	;0.01937
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE polarizer OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref*.9983
                     '-60DEG':	cal_factor=polref*1.0300
                     ELSE:		cal_factor=cal_factor*1.
                   ENDCASE
                END
  'IR':		BEGIN
                   cal_factor=0.0887	;0.1055
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE polarizer OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref*.9833
                     '-60DEG':	cal_factor=polref*1.0288
                     ELSE:		cal_factor=cal_factor*1.
                   ENDCASE
                END
  ELSE:		cal_factor=0.
ENDCASE

IF NOT(keyword_set(NOSUM)) THEN BEGIN
	;
	;correct calibration factor for pixel summation
	;
	IF (hdr.sumcol GT 0)  THEN cal_factor=cal_factor/hdr.sumcol
	IF (hdr.sumrow GT 0)  THEN cal_factor=cal_factor/hdr.sumrow
	IF (hdr.lebxsum GT 1)  THEN cal_factor=cal_factor/hdr.lebxsum
	IF (hdr.lebysum GT 1)  THEN cal_factor=cal_factor/hdr.lebysum
ENDIF
;
;PRINT,'C3_CALFACTOR version = V2'
;IF (cal_factor EQ 0) THEN PRINT,'invalid filter and polarizer position'
;print,'filter position =  ',filter
;print,'polarizer position =  ',polarizer
;PRINT,'cal_factor =',cal_factor
;PRINT,'units of (10^-10B/Bsun)/(DN/pixel-second)'
;
;
cal_factor = cal_factor*1.e-10
IF (DATATYPE(header) NE 'STC')  $
   THEN FXADDPAR,header,'HISTORY',' '+strcompress(version)+': '+strcompress(TRIM(STRING(cal_factor)))
RETURN, cal_factor
END

