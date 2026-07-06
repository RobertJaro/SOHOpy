;+
; NAME:
;	GRAD_ZONE
;
; PURPOSE:
;	Returns the main gradient orientation of a zone containing MB
;
; CATEGORY:
;	Missing Blocks
;
; CALLING SEQUENCE:
;	angle = grad_zone (image, list_miss_blocks)
;
; INPUTS:
;	image			the image containing missing blocks
;	list_miss_blocks	the missing blocks defining the zone
;
; KEYWORD INPUT:
;	rebindex : rebin index (see fuzzy_image.pro)
;
; OUTPUTS:
;	The angle of the gradient vector
;
; MODIFICATION HISTORY:
;	Written by J. More, November 1996
;	Add of rebindex keyword on 28/01/2000 by A.Thernisien
;-


function  grad_zone, image, list_miss_blocks,rebindex=rebindex

;   zone surrounding the missing blocks
zone = read_zone (image, list_miss_blocks,rebindex=rebindex)
zone = median(zone, 7) * (zone ne 0)



;   side of the blocks
side = 32

;   dimensions in pixels
s = size(zone)
nx = s(1)
ny = s(2)

;   dimensions in blocks (number of columns and rows of blocks)
ni = nx/side
nj = ny/side

; -----------------------------------------------------------------------------


;   corresponding sub-means (there are nsub x nsub submeans per blocks)
nsub=4
zone = rebin(zone, ni*nsub, nj*nsub)


; -----------------------------------------------------------------------------


;   sobel masks
sx = [ [-1, 0, 1], [-2, 0, 2], [-1, 0, 1] ]
sy = [ [-1,-2,-1], [ 0, 0, 0], [ 1, 2, 1] ]

s = total(abs(sx))

;   computes the x and y gradient on all sub-means
cx = convol(zone, sx, s)
cy = convol(zone, sy, s)


; -----------------------------------------------------------------------------


;   1-pixel deep border (outermost pixels of the non-zero part of zone)
zone1 = zone ne 0
border1 = (sobel(zone1) ne 0)*zone1

;   2-pixel deep border (1 pixel deeper than border1)
zone2 = zone1*(1-border1)
border2 = (sobel(zone2) ne 0)*zone2


;   gets the x and y gradient on this border
gx = total(cx*border2)
gy = total(cy*border2)

;   now gets the x and y absolute gradient
agx = total(abs(cx*border2))
if gx lt 0 then agx = -agx
agy = total(abs(cy*border2))
if gy lt 0 then agy = -agy

;   deduces the gradient orientation
if gy ne 0 $
   then angle = (atan(gy, gx)+2*!pi) mod (2*!pi) $
   else angle = 0

; -----------------------------------------------------------------------------


return, angle
end

