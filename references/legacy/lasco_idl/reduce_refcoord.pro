pro REDUCE_REFCOORD, hdr, level
;
;+
; NAME:
;	REDUCE_REFCOORD
;
; PURPOSE:
;	Converts coordinate system to the standard coordinate system
;	using the FITS keyword notation
;
; CATEGORY:
;	LASCO DATA REDUCTION
;
; CALLING SEQUENCE:
;	REDUCE_REFCOORD, Hdr, Level
;
; INPUTS:
;	Hdr:	FITS header
;	Level:	String indicating level to define coordinate system:
;			'0.5', '1.0', '2.0'
;
; SIDE EFFECTS:
;	Keywords are added to the FITS header, where n=1,2:
;		CRPIXn, CRVALn, CROTAn, CDELTn, CTYPEn, CUNITn
;
; PROCEDURE:
;	The 12 FITS keywords are computed for each of the processing
;	levels and added to the header.  The keywords for one level
;	do not require that the keywords for the preceeding level are 
;	present.
;
; SUBROUTINE CALLS:
;	FXPAR, FXADDPAR, GET_SUN_CENTER, GET_SEC_PIXEL
;
; MODIFICATION HISTORY:
;       RA Howard, NRL, 14 April 1996
;	Vers 1   14 Apr 1996, Initial Release
;	     2   23 May 1997, All levels use solar coords
;			030710 jake	added lines to account for nominal_roll_attitude
;			030716 jake	using get_soho_roll instead of get_crota
;			030804 jake replaced GET_SOHO_ROLL with GET_CROTA
;   	100915 nbr - Fix CRPIX (+1)
;   	101108 nbr - Use roll from get_sun_center.pro and include source in FITS as comment
;   	    	     (incorporates new get_sc_point.pro)
;   	130705 nbr - Set CROTA1 default value before calling get_sun_center()
;   	160511 nbr - Set RECTIFY = FALSE if rolled
;
;	@(#)reduce_refcoord.pro	1.12 12/05/16 LASCO IDL LIBRARY
;
;-
;
dateobs = FXPAR ( hdr, 'DATE-OBS' );	jake 030710
timeobs = FXPAR ( hdr, 'TIME-OBS' );	jake 030710
nx = FXPAR (hdr,'SUMCOL')
ny = FXPAR (hdr,'SUMROW')
IF (nx EQ 0)  THEN nx=1
IF (ny EQ 0)  THEN ny=1
nx = nx * FXPAR(hdr,'LEBXSUM')
ny = ny * FXPAR(hdr,'LEBYSUM')
crpix1 = FXPAR(hdr,'R1COL')-19
crpix2 = FXPAR(hdr,'R1ROW')
ctype1 = 'SOLAR-X'
ctype2 = 'SOLAR-Y'
crota1 = 0.;	jake 030710
crota2 = 0.;	jake 030710
source=''
;crota1 = get_crota ( dateobs + ' ' + timeobs )		;	jake 030804
orientation = get_crota ( dateobs + ' ' + timeobs )		;	jake 030804
lev = level

lev='2.0'			 ;  always use level 2

IF (lev EQ '1')  THEN lev='1.0'
IF (lev EQ '2')  THEN lev='2.0'
IF (lev EQ '3')  THEN lev='3.0'
CASE lev OF
'0.5':	BEGIN
           cdelt1 = FLOAT (nx)
           cdelt2 = FLOAT (ny)
           crval1 = ( crpix1 - 513 ) + 0.5 * cdelt1
           crval2 = ( crpix2 - 513 ) + 0.5 * cdelt2
           ;crota1 = 0.;	jake 030710
           ;crota2 = 0.;	jake 030710
           cunit1 = 'PIXEL'
           cunit2 = 'PIXEL'
        END
'1.0':  BEGIN
           cdelt1 = nx * .021
           cdelt2 = ny * .021
           crval1 = ( crpix1 - 513 ) * .021 + 0.5 * cdelt1
           crval2 = ( crpix2 - 513 ) * .021 + 0.5 * cdelt2
           ;crota1 = 0.;	jake 030710
           ;crota2 = 0.;	jake 030710
           cunit1 = 'MM'
           cunit2 = 'MM'
        END
'2.0':  BEGIN
           h = hdr		; save current header
    	    FXADDPAR,h,'CROTA1',0.0,'default'
           sunc = GET_SUN_CENTER(h, source, /NOCHECK, ROLL=crota, /degrees)
	   ; returns best-available values for center and roll
           arcs = GET_SEC_PIXEL(h)		; corrects for summing
           cdelt1 = arcs
           cdelt2 = arcs
           crpix1 = sunc.xcen+1
           crpix2 = sunc.ycen+1
           crval1 = 0.
           crval2 = 0.
           ;crota1 = 0.;	jake 030710
           ;crota2 = 0.;	jake 030710
           cunit1 = 'ARCSEC'
           cunit2 = 'ARCSEC'
        END
'3.0':  BEGIN
        END
ELSE:   BEGIN
           PRINT,'%REDUCE_REFCOORD, Level not recognized = ',level
           RETURN
        END
ENDCASE
FXADDPAR,hdr,'CRPIX1',crpix1,source
FXADDPAR,hdr,'CRPIX2',crpix2
FXADDPAR,hdr,'CRVAL1',crval1
FXADDPAR,hdr,'CRVAL2',crval2
FXADDPAR,hdr,'CROTA1',crota,source
FXADDPAR,hdr,'CROTA2',crota
FXADDPAR,hdr,'CTYPE1',ctype1
FXADDPAR,hdr,'CTYPE2',ctype2
FXADDPAR,hdr,'CUNIT1',cunit1
FXADDPAR,hdr,'CUNIT2',cunit2
FXADDPAR,hdr,'CDELT1',cdelt1
FXADDPAR,hdr,'CDELT2',cdelt2
IF (orientation EQ 180) THEN fxaddpar,hdr,'RECTIFY','FALSE'
RETURN
END
