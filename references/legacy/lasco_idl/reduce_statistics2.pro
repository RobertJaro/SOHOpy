pro reduce_statistics2,img,hdr,SATMAX=satmax, SATMIN=satmin
;+
; NAME:
;
;	REDUCE_STATISTICS2
;
; PURPOSE:
;
;	This procedure generates image statistics for the level 1 processing.
;
; CATEGORY:
;
;	LASCO REDUCTION, modified
;
; CALLING SEQUENCE:
;
;	REDUCE_STATISTICS2, Img, Hdr
;
; INPUTS:
;
;	Img:	The 2D image to compute statistics on.
;
;	Hdr:	A FITS header
;
; KEYWORDS:
;
;	SATMAX	set equal to value to be considered saturated (upper cutoff)
;	SATMIN	sat equal to value to be considered minimum cutoff
;
; OUTPUTS:
;
;	Hdr:	The FITS header will have additional keywords added.
;
; PROCEDURE:
;	Generates the following statistical quantities:
;	   minimum value not equal to 0 
;	   maximum value not equal to saturated (input value or max of image)
;	   number of zero pixels
;	   percentage of saturated pixels
;	   percentile values for 1%, 10%, 25%, 75%, 90%, 95%, 98% 99%
;	   mean of image
;	   standard deviation of image
;
;
; MODIFICATION HISTORY:
; 	Written by:	NB Rich, NRL -- Copied from REDUCE_STATISTICS.PRO by RA Howard
;	NBR, 1 Sep 1998	 Make generic, change name, add sat input 
;	NBR, 19 Jan 2001 - Change value of DATASAT keyword in output
;	NBR, 29 Aug 2002 - Add SATMAX keyword in input and change handling of this value; 
;			add SATMIN; add NDATASAT, DSATMIN, NDSATMIN in output
;	NBR, 11 Mar 2003 - Do percentiles before truncation if SATMAX set
;   	???,  5 Oct 2005 - Check for odd image
;
;       08/31/09 @(#)reduce_statistics2.pro	1.4 LASCO IDL LIBRARY
;
;-
;
;wmn = WHERE (img NE 0,n)
;stop
IF (max(img) GE 0.1) THEN BEGIN
PRINT,'Odd image encountered... using the following:'
PRINT,'img(where(img gt 0.00005)) = 0.00005'
img(where(img gt 0.00005)) = 0.00005
ENDIF

wmn = WHERE (img GT 0,n)
IF (n LT 1)    THEN RETURN
s = SIZE(img)
mn = MIN ( img( wmn ), MAX = mx )
medyen = MEDIAN(img(wmn))
;IF medyen / 1000 LT 1 	THEN bscale = 1000.
;IF medyen / 100 LT 1 	THEN bscale = 10000.
;IF medyen / 10 LT 1 	THEN bscale = 100000.
bscale=1d
help,medyen

IF medyen GT 0 THEN WHILE medyen*bscale LT 1000 DO bscale=bscale*10
help,bscale
   
;print,'DATAMIN = ',mn
fxaddpar,hdr,'DATAMIN',float(mn),' Minimum Value Not Equal to Zero before BSCALE'
nsat = 0
IF keyword_set(SATMAX) THEN mxval = satmax ELSE mxval=mx
IF keyword_set(SATMIN) THEN mnval = satmin ELSE mnval=mn
;IF (s(s(0)+1) EQ 3)   THEN mxval=mxval*4 ; for 16 bit integer only

wltmx = WHERE( img lt mxval, nltmx)
nsat = s[4]-nltmx
IF mx EQ mxval THEN dmx = MAX(img[wltmx]) ELSE dmx=mx
wltmn = WHERE( img LT mnval and img NE 0, nsatmin)
   
FXADDPAR,hdr,'DATAMAX',float(dmx),' Maximum Value before BSCALE'
IF s(0) GT 1 THEN zeros = s(4)-n ELSE zeros = s(3)-n
FXADDPAR,hdr,'DATAZER',zeros,	' Number of Zero Pixels'
fxaddpar,hdr,'DATASAT',nsat,	' Number of Saturated Pixels'
print,'DATASAT =',nsat
FXADDPAR,hdr,'DSATVAL',mxval, 	' Value used as saturated'
fxaddpar,hdr,'DSATMIN',mnval,	' Minimum value in scaled image'
fxaddpar,hdr,'NSATMIN',nsatmin,	' Number of pixels cut off on lower end'
;print,'DATAMAX = ',mx
;print,'DATASAT = ',nsat
;w = WHERE ( (img NE 0) AND (img NE 16383) AND (img NE 'ffff'xl) ,nw)
;w = WHERE ( (img GT 0) AND (img LT mxval) ,nw)
w = where (img GT 0, nw)
IF (nw lt 1) THEN RETURN ELSE sig = STDEV (img(w),men)
FXADDPAR,hdr,'DATAAVG',men,   ' Mean of Image before BSCALE'
FXADDPAR,hdr,'DATASIG',sig,   ' Standard Deviation of Image before BSCALE'
;stop
;print,'DATAAVG = ',mn
;print,'DATASIG = ',sig
temparr = long(img[w]*bscale)
;stop
h = HISTOGRAM (temparr,min=0)
nh = n_elements(h)
tot = 0
limits = [0.01,0.10,0.25,0.5,0.75,0.90,0.95,0.98,0.99]
nl = N_ELEMENTS (limits)
nw = N_ELEMENTS (w)
low = 0d

FOR i=0,nl-1 DO BEGIN
    tile = limits[i]*nw
    IF (low LT nh) THEN REPEAT BEGIN
       tot = tot+h(low)
       low = low+1
    ENDREP UNTIL ( (tot GT tile) OR (low EQ nh) )
    s = 'DATAP'+string(limits[i]*100,format="(i2.2)")
    PRINT,s+' = ',float(low-1)/bscale
    FXADDPAR,hdr,s,float(low-1)/bscale, ' Percentile Value'
ENDFOR
;stop
RETURN
END
