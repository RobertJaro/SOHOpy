function make_browse,image,fits_hdr,file_name,maxpix=maxpix,noblob=noblob,nokeep=nokeep,qual=qual,limit=limit
;+
; NAME:
;		MAKE_BROWSE
;
; PURPOSE:
;		Generates a "browse" image from the input image
;
; CATEGORY:
;		REDUCTION
;
; CALLING SEQUENCE:
;		Result = MAKE_BROWSE (Image, File_name)
;
; INPUTS:
;		Image = Input 2D image
;		File_name = String containing the File name 
;
; KEYWORD PARAMETERS:
;		Maxpix = Maximum number of columns or rows of browse image. 
;                        If maxpix of browse image is not defined then set to 
;                        256
;		Noblob = Controls the output
;		Nokeep = Delete the JPEG file
;		Qual   = starting quality indicator (<=100)
;
; OUTPUTS:
;		Result = The JPEG compressed browse image is returned as the 
;			 function result if noblob is not set.  If set the 
;			 output is the browse image without compression
;
; PROCEDURE:
;
;      The browse image is defined to be a byte array not larger than the 
;      optional input parameter or a default size if it is not defined.  The 
;      browse image is compressed using the JPEG algorithm.  The objective is 
;      to create a representation of the full image which is less than 3 kbytes,
;      in order to be able to quickly transfer the information electronically.
;      The browse image can then be used to determine if the full image should 
;      be transferred, which might take much longer to transfer.  The browse 
;      image is not intended to be used for analysis purposes.
;
;      browse = JPEG ( bytscl (congrid(image,maxpix,maxpix)))
;
; MODIFICATION HISTORY:
;	Written  RA Howard, NRL, 4 Oct 1995
;       Version 1
;       Version 2  RAH  2/12/96   Changed order from 1 to 0
;       Version 3  RAH  3/09/96   Write image to specific directory and 
;                                 optionally save.  Scale image using log
;       Version 4  RAH  3/29/96   Changed max size to 2000 bytes, qf=90
;       Version 5  RAH  4/20/96   Removed "w" as second character in name
;       Version 6  RAH  5/15/96   Corrected error if zeros everywhere
;       Version 7  RAH  5/25/96   Use histogram equalization to scale image
;       Version 8  RAH  10/21/96  Subtract background model
;       Version 9  RAH  02/20/97  Correct case of constant image
;	VERSION 10 NBR	02/01/02  Add /SH to SPAWN
;
;       @(#)make_browse.pro	1.8 02/01/02 LASCO IDL LIBRARY
;
;-
;
IF KEYWORD_SET(maxpix)  THEN nb=maxpix ELSE nb=128
s=SIZE(image)
nc=s(1)           ; number of columns
nr=s(2)           ; number of rows
;
;  determine the size of the browse image
;  permit rectangular images
;
IF (nc GT nr) THEN BEGIN
   n1 = nb
   n2 = fix ( LONG(nr) * nb / nc )
   n  = nc
ENDIF ELSE IF (nc LT nr) THEN BEGIN
   n2 = nb
   n1 = fix ( LONG(nc) * nb / nr )
   n  = nr
ENDIF ELSE BEGIN
   n1 = nb
   n2 = nb
   n  = nc
ENDELSE
IF (n le nb)  THEN browse=image ELSE browse=CONGRID(image,n1,n2,/interp)
;
;   Scale the browse image using log scale into bytes
;
wb = WHERE(browse NE 0,nz)		;  check if zero everywhere
IF (nz EQ 0)  THEN minb=0 ELSE minb=MIN(browse(wb))
maxb = MAX(browse,nw)
IF (maxb EQ 16383)  THEN BEGIN
   wmaxb=WHERE(browse NE 16383,nwmaxb)
   IF (nwmaxb GT 0)  THEN maxb=MAX(browse(wmaxb))
ENDIF
;print,minb,maxb
;browse = float(browse)
;browse = BYTSCL ( browse ,min=minb, max=maxb)
IF (maxb NE minb) THEN browse = hist_equal(browse)
;
;  form a file name with "jpg" as the extension 
;  and "w" as the second character
;
name = STRMID(file_name,0,STRLEN(file_name)-3)+'jpg'
;  don't put "w" as the second character
;name = STRMID(name,0,1)+'w'+STRMID(name,2,STRLEN(name))
;
;  write out the JPEG file, then read it back in as
;  a "blob" for sending to the DBMS
;  adjust quality indicator to achieve size of jpeg image less than
;  maxsize (2 kbyte)
;
IF KEYWORD_SET(limit) THEN maxsize=n_elements(browse) ELSE maxsize=2000
IF KEYWORD_SET(Qual) THEN qf = qual ELSE qf = 90
GET_LUN,lu
REPEAT BEGIN
   WRITE_JPEG,name,browse,quality=qf,order=0
   OPENR,lu,name
   stat = fstat (lu)
   CLOSE,lu
   qf= qf*0.9
ENDREP UNTIL (stat.size lt maxsize)

;
;  Read the jpeg compressed image back in to make DBMS blob
;
IF (NOT KEYWORD_SET (noblob)) THEN BEGIN
   OPENR,lu,name
   c=ASSOC(lu,BYTARR(stat.size))
   browse=c(0)
   CLOSE,lu
ENDIF ELSE READ_JPEG,name,browse

IF (KEYWORD_SET(Nokeep)) THEN SPAWN,'/bin/rm '+name, /SH

FREE_LUN,lu
RETURN,browse
END

