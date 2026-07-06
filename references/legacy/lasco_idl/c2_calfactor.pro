function c2_calfactor,Header,NOSUM=nosum
;+
;NAME:
;	C2_CALFACTOR
;
;PURPOSE:
;	This function returns the calibration factor for a given C2 image
;
;CATEGORY:
;	REDUCE
;
;CALLING SEQUENCE:
;	result = C2_CALFACTOR(Header)
;
;INPUT:	
;	Header:	image header, either fits or lasco structure
;
; Keywords:
;	NOSUM	If set, do not correct for summing
;
;OUTPUT:
;	Image calibration factor in (B/Bsun)/(DN/pixel-second)
;
;PROCEDURE:
;
;	Same as C3_CALFACTOR.pro
;	the output is automatically scaled for pixel summing
;
; MODIFICATION HISTORY:
;	Written Clarence Korendyke, NRL
;       Added C2/C3 Orange ratio as c2c3match - DW 07/09/99
;
;	NBR Nov  7 2001 - Change Version to use SCCS version; change header HISTORY
;	NBR Mar 11 2003 - Add /NOSUM
;       KB/RAH Aug 29,2005  - Add new orcl calfactor of 0.06047 and removed fudge factor
;       9/20/05  RAH     Add time variable calibration coefficient for orange
;       3/22/2007  Karl B  - Fix typo (changed "red" to "deeprd"
;
; SCCS variables for IDL and Header use
; 
ver= '@(#)c2_calfactor.pro	1.9, 03/22/07' ;NRL LASCO IDL LIBRARY
;
;
;-
;
;version='V1'
version = STRMID(ver,4,strlen(ver))
hdr = header
IF (DATATYPE(hdr) NE 'STC')  THEN hdr=LASCO_FITSHDR2STRUCT(hdr)
dte=STR2UTC(hdr.date_obs)
mjd=dte.mjd
;
;
;retrieve filter and polarizer position from the header
;
filter = STRUPCASE(STRCOMPRESS(hdr.filter,/remove_all))
polarizer = STRUPCASE(STRCOMPRESS(hdr.POLAR,/remove_all))
;
;set calibration factor for the various filters and polarizers
; polarizers have same factor (1.0)
;
CASE filter OF
  'ORANGE': 	BEGIN 
;                   cal_factor=0.06047
                   cal_factor=4.60403e-07*mjd+0.0374116
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE polarizer OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref
                     '-60DEG':	cal_factor=polref
                     'nd':	cal_factor=polref
                     ELSE:		cal_factor=cal_factor*1.
                   ENDCASE
                END
  'BLUE':	BEGIN 
                   cal_factor=0.1033
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE polarizer OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref
                     '-60DEG':	cal_factor=polref
                     'nd':	cal_factor=polref
                     ELSE:		cal_factor=cal_factor*1.
                   ENDCASE
                END
  'DEEPRD':	BEGIN
                   cal_factor=0.1033
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE STRUPCASE(polarizer) OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref
                     '-60DEG':	cal_factor=polref
                     'nd':	cal_factor=polref
		     ELSE:		cal_factor=0.
                   ENDCASE
                END
  'HALPHA':	BEGIN
                   cal_factor=0.01055		; wrong
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE polarizer OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref
                     '-60DEG':	cal_factor=polref
                     'nd':	cal_factor=polref
                     ELSE:		cal_factor=cal_factor*1.
                   ENDCASE
                END
  'LENS':	BEGIN
                   cal_factor=0.01055		; wrong
                   polref=cal_factor/.25256		; absolute value of +60
                   CASE polarizer OF
                     'CLEAR':	cal_factor=cal_factor*1.
                     '+60DEG':	cal_factor=polref
                     '0DEG':	cal_factor=polref
                     '-60DEG':	cal_factor=polref
                     'nd':	cal_factor=polref
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
;
ENDIF
;PRINT,'C2_CALFACTOR version = V2'
;IF (cal_factor EQ 0) THEN PRINT,'invalid filter and polarizer position'
;print,'filter position =  ',filter
;print,'polarizer position =  ',polarizer
;PRINT,'cal_factor =',cal_factor
;PRINT,'units of (10^-10B/Bsun)/(DN/pixel-second)'
;
;

; Ratio of C2/C3 in Orange filter
;c2c3match = (7.5575/2.86) ; using correct calfact negates the need for this fudge factor
;cal_factor = cal_factor*1.e-10*c2c3match
cal_factor = cal_factor*1.e-10

IF (DATATYPE(header) NE 'STC')  $
   THEN FXADDPAR,header,'HISTORY',' '+strcompress(version)+': '+strcompress(TRIM(STRING(cal_factor)))

RETURN, cal_factor
END

