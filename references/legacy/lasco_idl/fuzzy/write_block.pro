;+
; PROJET:
;	SOHO - LASCO
;
; NAME:
;	WRITE_BLOCK
;
; PURPOSE:
;	sets the block at column i and row j
;
; PROCEDURE:
;	sets the block (array of pixels) at column i and row j to a given
;	array of values, or to a given constant value
;
; CATEGORY:
;	Missing Blocks
;
; CALLING SEQUENCE:
;	write_block, image, i, j, block
;
; INPUTS:
;	image		the image where to write the block
;			(image is both an input and a output)
;	i, j		the column i and the row j of the block to change
;			(i and j ranges from 0 to 31)
;	block		the block (dim : size x size) to overwrite; it can be :
;			_ a integer array
;			_ a scalar value, which leads to a constant array
;
; KEYWORD PARAMETERS:
;	SIDE		the side of the square blocks (default is 32 pixels)
;
; OUTPUTS:
;	The block (i,j) on image is overwritted
;	(image is both an input and a output)
;
; MODIFICATION HISTORY:
;	written by J.More, September 1996
;-




pro  write_block, image, i, j, block, SIDE=side

;   side of a square block
if not(keyword_set(side)) then  side = 32


;   writting of the block
;   if block is a scalar, block will be a  side x side  constant array 
image[side*i:side*(i+1)-1, side*j:side*(j+1)-1] = block


return
end
