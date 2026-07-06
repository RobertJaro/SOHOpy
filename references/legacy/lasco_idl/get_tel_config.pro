function get_tel_config,tel_num,fits_hdr
;+
; NAME:				GET_TEL_CONFIG
;
; PURPOSE:			Computes the telescope configuration number,
;				given the telescope, the telescope mechanism 
;				configuration, and the camera configuration in 
;				the header
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		Result = GET_TEL_CONFIG(Tel_num,Fits_hdr)
;
; INPUTS:			Tel_num = Telescope number (0..3)
;				Fits_hdr = String containing the FITS header
;
; OUTPUTS:			Result = Configuration number
;
; MODIFICATION HISTORY: 	WRITTEN RA Howard NRL 
;				Version 1   RAH 20 Oct 1995  Initial Release
;     				Version 2   RAH 6 Nov 1995  compute number 
;						rather than use DBMS
;
;       @(#)get_tel_config.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
;
ver = 'V2    6 Nov 1995'
filt     = fxpar (fits_hdr,'FILTER')
polar    = fxpar (fits_hdr,'POLAR')
sumcol   = fxpar (fits_hdr,'SUMCOL')
sumrow   = fxpar (fits_hdr,'SUMROW')
lamp     = fxpar (fits_hdr,'LAMP')
readport = fxpar (fits_hdr,'READPORT')
nclears  = fxpar (fits_hdr,'NCLEARS')
clrmode  = fxpar (fits_hdr,'CLRMODE')
;
;   Compute the telescope mode.  There are 150 total possibilities
;
tel_mode = filt + 5*polar + 25*door + 50*lamp
;
;   Compute the camera mode.  There are 150 total possibilities
;   Limit the summing to up to 4 and then everything beyond 4 is set to 5
;
case readport of
'A':    port=0
'B':    port=1
'C':    port=2
'D':    port=3
endcase
cam_mode = (sumcol<5) + 6*(sumrow<5) + 36*readport + 144*clrmode
;
;  Compute the Image Processing Mode
;
ip_mode=0
return,tel_mode+200*cam_mode+300*ip_mode
end
