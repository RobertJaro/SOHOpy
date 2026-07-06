FUNCTION MISS_BLOCKS, Img, Hdr
;
;  Finds misssing block numbers
;+
; NAME:
;	MISS_BLOCKS
;
; PURPOSE:
;	This function returns a list of the missing telemetry block numbers.
;
; CATEGORY:
;	REDUCE
;
; CALLING SEQUENCE:
;	Result = MISS_BLOCKS (Img, Hdr)
;
; INPUTS:
;	Img:	The image to be processed
;	Hdr:	The fits header of the image
;
; OUTPUTS:
;	The function result is a long word array of the absolute block numbers
;	that are missing.  If no blocks are missing, the result is -1.
;
; PROCEDURE:
;	The input image is rebinned to a 32 x 32 array and then teh IDL where 
;	function is used to identify the locations where the super pixels are
;	zero.
;
; MODIFICATION HISTORY:
; 	Written by:	RA Howard, 4 Oct 1995
;
;	@(#)miss_blocks.pro	1.1 10/05/96 LASCO IDL LIBRARY
;-
sz = SIZE (img)
nx = sz(1)
ny = sz(2)
;
;   get x values
;
x1 = FXPAR (hdr,'R1COL')
x2 = FXPAR (hdr,'R2COL')
dx = x2-x1+1			; number of columns
nxblock = dx/32
colsum = FXPAR (hdr, 'COLSUM')
IF (colsum EQ 0) THEN colsum=1
colsum = colsum * FXPAR (hdr, 'LEBXSUM')
nxpixblk = 32/colsum
start_xblock = (x1-20)/32
;
;   Get y values
;
y1 = FXPAR (hdr,'R1ROW')
y2 = FXPAR (hdr,'R2ROW')
dy = y2-y1+1			; number of rows
nyblock = dy/32
rowsum = FXPAR (hdr, 'ROWSUM')
IF (rowsum EQ 0) THEN rowsum=1
rowsum = rowsum * FXPAR (hdr, 'LEBYSUM')
nypixblk = 32/rowsum
start_yblock = (y1-1)/32
;
;
;
blk_img = FIX ( REBIN (img,nxpixblk,nypixblk) )
w = WHERE (blk_img EQ 0,nw)
IF (nw GT 0) THEN BEGIN
   row = w/32
   col = w-32*row
   row = row+start_yblock
   col = col+start_xblock
   w = row*32+col
ENDIF
RETURN,w
END
