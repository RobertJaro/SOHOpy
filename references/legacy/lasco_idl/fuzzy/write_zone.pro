;+
; PROJET:
;	SOHO - LASCO
;
; NAME:
;	WRITE_ZONE
;
; PURPOSE:
;	Writes a missing zone
; 
; PROCEDURE:
;	Writes a missing zone (array of pixel) surrounding a given list of
;	missing blocks onto an image
;
;	A missing zone is defined as the smallest rectangle of blocks that
;	surrounds a cluster of missing blocks (likely to be neighbor missing
;	blocks) but has  no missing block on its border (its outermost rows
;	and columns)
;	For example, 1 single block leads to a 3x3 surrounding block zone
;
; CATEGORY:
;	Missing Blocks
;
; CALLING SEQUENCE:
;	write_zone, image, list_miss_blocks, zone 
;
; INPUTS:
;	image			the image where to write the zone onto
;				(image is both an input and an output)
;	list_miss_blocks	a list of missing blocks (or 1 block) defining
;				the missing zone
;	zone			an array of pixels to overwrite onto the image
;
; KEYWORD INPUT:
;	rebindex : rebin index (see fuzzy_image.pro)
;
; OUTPUTS:
;	zone is overwritten onto image
;	(image is both an input and an output)
;
; MODIFICATION HISTORY:
;	Written by J.MORE, October 1996
;	Add of rebindex keyword on 28/01/2000 by A.Thernisien
;
;-




pro  write_zone, image, list_miss_blocks, zone,rebindex=rebindex

;   side of a square block
side = 32

;   extremes columns and rows of the missing zone
i1 = min(list_miss_blocks(0, *)-1 > 0)
i2 = max(list_miss_blocks(0, *)+1 < ((32/rebindex)-1))
j1 = min(list_miss_blocks(1, *)-1 > 0)
j2 = max(list_miss_blocks(1, *)+1 < ((32/rebindex)-1))

;   dimensions of the zone (array of pixels)
zone_left   = side*i1
zone_right  = side*(i2+1)-1
zone_bottom = side*j1
zone_top    = side*(j2+1)-1

image(zone_left:zone_right, zone_bottom:zone_top) = zone


return
end












