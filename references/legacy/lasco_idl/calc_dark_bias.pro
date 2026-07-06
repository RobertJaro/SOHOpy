pro calc_dark_bias,Files,h
;+
; NAME:
;	CALC_DARK_BIAS
;
; PURPOSE:
;	This procedure calculates minimum, mean, average and std dev of dark images
;
; CATEGORY:
;	LASCO REDUCE
;
; CALLING SEQUENCE:
;	CALC_DARK_BIAS,Files
;
; INPUTS:
;	Files:	If optional parameter, h, not present: String array of the file names to process
;		If optional parameter, h, is present: image data array
;
; OPTIONAL INPUTS:
;	H:	Lasco header structure corresponding to image data in Files
;
; OUTPUTS:
;	Write information to file in $NRL_LIB/lasco/data/bias
;
; PROCEDURE:
;	Cacluates the average, standeard deviation, minimum (non-zero) value and the median
;	value.  Also gets the current value for the offset bias.  Then appends the information
;	to the file dark_bias_cX.dat, where X is the telescope number.
;
; EXAMPLE:
;	For only one parameter, the input parameter is a list of files
;
;		f = wlister()
;		CALC_DARK_BIAS,f
;
;	For two parameters, pass the image and the header:
;		a = LASCO_READFITS(f,h)
;		CALC_DARK_BIAS,a,h
;
; MODIFICATION HISTORY:
; 	Written by:	RA Howard, 6/12/98
;       Karl Battams   2 Nov 2005 - Add swap_if_little_endian keyword for opening binary data files
;	Russ Howard	26 Oct 2016 - Use resistant mean to obtain the dark statistics.
;
;	@(#)calc_dark_bias.pro	1.2 11/02/05 LASCO IDL LIBRARY
;-

np = N_PARAMS()
IF (np EQ 1)  THEN nf = N_ELEMENTS(files) ELSE nf=1
GET_LUN,lu
FOR i=0,nf-1 DO BEGIN
    IF (np EQ 1)  THEN a = LASCO_READFITS(files(i),h) ELSE a=files
    IF (a(0) NE -1)  THEN BEGIN
       tel = STRLOWCASE(h.detector)
       OPENW,lu,GETENV('NRL_LIB')+'/lasco/data/bias/dark_bias_'+tel+'.dat',/append,/swap_if_little_endian
       w = WHERE (a NE 0)

       ;
       ;	use the resistant_mean with a sigma_cut of 10 (points more than sigma_cut away are rejected)
       ;
       b = MEDIAN(a(w))
       sig = STDEV(a(w),mn)
       curve = OFFSET_BIAS(h)
       hist = HISTOGRAM(a(w),min=0)
       ww = WHERE(hist EQ MAX(hist))
       RESISTANT_MEAN,a(w),10,mean,sigmean,numrej
       ;PRINT,h.filename,h.date_obs,h.detector,h.readport,mn,sig,b,ww(0),curve,h.exptime, $
       PRINT,h.filename,h.date_obs,h.detector,h.readport,mean,sigmean,b,numrej,curve,h.exptime,  $
              format='(a12,2x,a10,2x,a2,2x,a1,f8.1,f8.3,3f8.1,f8.2)'
       ;PRINTF,lu,h.filename,h.date_obs,h.detector,h.readport,mn,sig,b,ww(0),curve,h.exptime, $
       PRINTF,lu,h.filename,h.date_obs,h.detector,h.readport,mean,sigmean,b,numrej,curve,h.exptime,  $
              format='(a12,2x,a10,2x,a2,2x,a1,f8.1,f8.3,3f8.1,f8.2)'
       CLOSE,lu
    ENDIF
ENDFOR
FREE_LUN,lu
RETURN
END
