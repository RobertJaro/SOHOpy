;+
; PROJET:
;	SOHO - LASCO
;
; NAME:
;	READ_ZONE
;
; PURPOSE:
;	Gets the missing zone surrounding a given list of missing blocks
;
; PROCEDURE:
;	Gets the missing zone (array of pixel) surrounding a given list of
;	missing blocks
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
;	zone = 	read_zone (image, list_miss_blocks [,zone_width, zone_height])
;
; INPUTS:
;	image				the image containing the zone to read
;	list_miss_blocks		a list of missing blocks (or 1 block)
;					that the missing zone will surround
; KEYWORD INPUT:
;	rebindex : rebin index (see fuzzy_image.pro)
;
; OUTPUTS:
;	zone				the zone surrounding these blocks
;
; Optional OUTPUTS:
;	zone_width, zone_height 	the dimentions of the zone, in pixels
;
; MODIFICATION HISTORY:
;	Written by J.MORE, September 1996
;	Add of rebindex keyword on 28/01/2000 by A.Thernisien
;-


function  read_zone, image, list_miss_blocks, $ 
                     zone_width, zone_height,rebindex=rebindex

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
zone_width  = zone_right - zone_left + 1
zone_height = zone_top - zone_bottom + 1


zone = image(zone_left:zone_right, zone_bottom:zone_top)


return,  zone
end