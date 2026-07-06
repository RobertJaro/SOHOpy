;+
; PROJEcT:
;       SOHO - LASCO
;
; NAME:
;       READ_BLOCK
;
; PURPOSE:
;       returns the block (array of pixel) at column i and row j
;
; CATEGORY:
;       Missing Blocks
;
; CALLING SEQUENCE:
;       block = read_block (image, i, j)
;
; INPUTS:
;       image           the image where to read the block onto
;       i, j            the column i and the row j of the block
;                       (i and j ranges from 0 to 31)
;
; KEYWORD PARAMETERS:
;       SIDE            the side of the square blocks (default is 32 pixels)
;
; OUTPUTS:
;       The function returns the corresponding block, a 32 x 32 integer array
;
; MODIFICATION HISTORY:
;       written by J.More, September 1996
;-


function  read_block, image, i, j, SIDE=side

;   side of a square block
if not(keyword_set(side)) then  side = 32

;   reading of the block
block = image[side*i:side*(i+1)-1, side*j:side*(j+1)-1]


return,  block
end


