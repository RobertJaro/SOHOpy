function std_int_scale,img,hdr
;+
; NAME:
;
;	STD_INT_SCALE
;
; PURPOSE:
;
;	Scale the intensities of the input image into DN/sec, accounting for
;	the bias in case of summing.
;
; CATEGORY:
;
;	LASCO REDUCTION
;
; CALLING SEQUENCE:
;
;	Result = STD_INT_SCALE(Img,Hdr)
;
; INPUTS:
;
;	Img = Input Image array.
;	Hdr = FITS header
;
; KEYWORDS:
;	None
;
; OUTPUTS:
;	The function returns a floating point image.
;
; PROCEDURE:
;	The input header is examined to extract the on-chip and off-chip
;	summing parameters, and the exposure time.  The appropriate bias
;	value is subtracted off the image and then the resultant is 
;	divided by the exposure time.
;
; MODIFICATION HISTORY:
;	Written, RA Howard, NRL, 22 October 1996
;
;       @(#)std_int_scale.pro	1.1 10/22/96     LASCO IDL LIBRARY
;
;-
;
;  Get the bias and adjust for leb summing
;
bias = OFFSET_BIAS(hdr)
lebsum = FXPAR(hdr,'LEBXSUM')*FXPAR(hdr,'LEBYSUM')
bias = bias*lebsum
;
;  Adjust the pixel values for on/off chip summing
;
ccdsum = (FXPAR(hdr,'COLSUM')>1)*(FXPAR(hdr,'ROWSUM')>1)
sum = FLOAT(lebsum*ccdsum) 
expt = FXPAR(hdr,'EXPTIME')
RETURN, (img-bias)/ (sum * expt)
END
