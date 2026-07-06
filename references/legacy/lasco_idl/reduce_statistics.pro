pro reduce_statistics,img,hdr
;+
; NAME:
;
;	REDUCE_STATISTICS
;
; PURPOSE:
;
;	This procedure generates image statistics for the level 0.5 processing.
;
; CATEGORY:
;
;	LASCO REDUCTION
;
; CALLING SEQUENCE:
;
;	REDUCE_STATISTICS, Img, Hdr
;
; INPUTS:
;
;	Img:	The 2D image to compute statistics on.
;
;	Hdr:	A FITS header
;
; OUTPUTS:
;
;	Hdr:	The FITS header will have additional keywords added.
;
; PROCEDURE:
;	Generates the following statistical quantities:
;	   minimum value not equal to 0 
;	   maximum value not equal to saturated (16383)
;	   number of zero pixels
;	   percentage of saturated pixels
;	   percentile values for 1%, 10%, 25%, 75%, 90%, 95%, 98% 99%
;	   mean of image
;	   standard deviation of image
;
;
; MODIFICATION HISTORY:
; 	Written by:	RA Howard, NRL, 20 Mar 1996
;	Version 2  RAH, 19 Apr 1996   Made low a long word
;	V3  RAH, 18 Jul 1997   Added check for data type for maximum
;
;       @(#)reduce_statistics.pro	1.7 11/02/15 LASCO IDL LIBRARY
;
;-
;
wmn = WHERE (img NE 0,n)
IF (n LT 1)    THEN RETURN
s = SIZE(img)
mn = MIN ( img( wmn ), MAX = mx )
;print,'DATAMIN = ',mn
fxaddpar,hdr,'DATAMIN',float(mn)
nsat = 0
mxval = 16383L
IF (s(s(0)+1) EQ 3)   THEN mxval=mxval*4
IF (mx GT 16383)  THEN BEGIN
   IF (mx EQ (mxval*(mx/mxval))) THEN BEGIN
      w = WHERE ( img NE 'ffff'xl )
      mx = MAX ( img ( w ) )
      nsat = 1-n_elements(w)/float(n_elements(img))
   ENDIF
ENDIF ELSE BEGIN
    IF (mx EQ 16383) THEN BEGIN
      w = WHERE ( img NE 16383 ,nw )
      IF (nw EQ 0)  THEN nsat=1 ELSE BEGIN
         mx = MAX ( img( W ) )
         nsat = 1-n_elements(w)/float(n_elements(img))
      ENDELSE
    ENDIF
ENDELSE
FXADDPAR,hdr,'DATAMAX',float(mx)
FXADDPAR,hdr,'DATAZER',s(4)-n
FXADDPAR,hdr,'DATASAT',nsat
;print,'DATAMAX = ',mx
;print,'DATASAT = ',nsat
w = WHERE ( (img NE 0) AND (img NE 16383) AND (img NE 'ffff'xl) ,nw)
IF (nw lt 4) THEN RETURN ELSE sig = STDEV (img(w),mn)
FXADDPAR,hdr,'DATAAVG',mn
FXADDPAR,hdr,'DATASIG',sig
;print,'DATAAVG = ',mn
;print,'DATASIG = ',sig
h = HISTOGRAM (img(w),min=0)
nh = n_elements(h)
tot = 0
limits = [0.01,0.10,0.25,0.75,0.90,0.95,0.98,0.99]
nl = N_ELEMENTS (limits)
nw = N_ELEMENTS (w)
low = 0L
FOR i=0,nl-1 DO BEGIN
    tile = limits(i)*nw
    IF (low LT nh) THEN REPEAT BEGIN
       tot = tot+h(low)
       low = low+1
    ENDREP UNTIL ( (tot GT tile) OR (low EQ nh) )
    s = 'DATAP'+string(limits(i)*100,format="(i2.2)")
;    PRINT,s+' = ',low-1
    FXADDPAR,hdr,s,low-1
    
ENDFOR
RETURN
END
