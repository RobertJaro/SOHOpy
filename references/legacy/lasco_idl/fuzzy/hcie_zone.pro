;+
;       hcie_zone.pro  contains the following sub-routines :
;
;       _ grad                  designs a image made with parallel lines, all
;				of them perpendicular to a given direction
;       _ multi_interp		perform a multiple 1D interpolation of an image
;				along a set of parallel lines
;       _ multi_smooth		perform a multiple 1D smoothing of an image
;				along a set of parallel lines
;       _ HCIE_ZONE             performs a H.C.I.E. (Hierarchical Compass
;         (=main routine)       Interpolation/Extrapolation), i.e. a low-pass
;                               recovery, on a set of missing block (defining
;				a missing zone)
;-

; *****************************************************************************


;+
; PROJET:
;       SOHO - LASCO
;
; NAME:
;	HCIE_ZONE
;
; PURPOSE:
;       Performs the Hierarchical Compass Interpolation / Extrapolation
;       (H.C.I.E.), which is a low-frequency recovery of a lost block
;
; CATEGORY:
;	Missing Blocks
;
; CALLING SEQUENCE:
;       zone = hcie_zone (image, list_miss_blocks)
;
; INPUTS:
;       image           	the image containing the block to correct
;       list_miss_blocks	the locations of the missing blocks defining
;				the zone
; KEYWORD INPUT:
;	rebindex : rebin index (see fuzzy_image.pro)
;
; OUTPUTS:
;       The corrected zone (array of pixels) is returned
;
; REFERENCE:
;       ( see fuzzy_image.pro )
;
; MODIFICATION HISTORY:
;	from the wonderful Dr. M.BOUT (c) 1996
;       Written by J. MORE, November 1996
;	Add of rebindex keyword on 28/01/2000 by A.Thernisien
;	Modif line 219 on 11/02/2000 by A.T. to avoid crash when there are not enough sample for interpolation
;-


; *****************************************************************************


;+
; NAME:
;       GRAD
;
; PURPOSE:
;       Designs a "gradient map", i.e. a image made with parallel lines, all of
;       them perpendicular to a given gradient direction
;
; CALLING SEQUENCE:
;       g = grad (xsize, ysize, theta)
;
; INPUTS:
;       xsize, ysize    the size of the map image
;       theta           the angle of the gradient vector (versus the (Ox) axis)
;                       expressed in radians; the parallel lines are thus
;                       along the direction theta+pi/2
;
; OUTPUTS:
;       the (xsize) x (ysize) array where the value of each point is equal to
;       the distance beetween the line perpendicular to the gradient that pass
;       through this point and the origin.
;       The origin (just as for the dist function) is located at 1 of the 4
;       corner of the image,  depending on the value of theta :
;       _ for theta in [0, pi/2],      the origin = (0, 0)
;       - for theta in [pi/2, pi],     the origin = (xsize-1, 0)
;       _ for theta in [pi, 3.pi/2],   the origin = (xsize-1, ysize-1)
;       - for theta in [3.pi/2, 2.pi], the origin = (0, ysize-1)
;-




function grad, xsize, ysize, theta

;   sets the theta angle into the interval [0, 2.pi]
t = (theta mod (2*!pi) + (2*!pi) ) mod (2*!pi)


;   abscissa and ordinate matrices
xx = indgen(xsize) # replicate(1, ysize)
yy = replicate(1, xsize) # indgen(ysize)



;   origin of the gradient map
;   depends on the sub-interval theta belongs ([0,pi/2], [pi/2, pi], etc.)
quarter = fix(t / (!pi/2))
case quarter of
      0 : begin   x0 = 0         &   y0 = 0         &   end
      1 : begin   x0 = xsize-1   &   y0 = 0         &   end
      2 : begin   x0 = xsize-1   &   y0 = ysize-1   &   end
      3 : begin   x0 = 0         &   y0 = ysize-1   &   end
      else : begin   x0 = 0   &   y0 = 0   &   end
   endcase

;   mean distance beetween 2 pixels along one of these parallel lines
pix_dist = 1 / cos((!pi/4 - abs(theta mod (!pi/2) - !pi/4)))

;   gradient matrix
gr = ((xx-x0)*cos(t) + (yy-y0)*sin(t))*pix_dist


return, gr
end


; *****************************************************************************


;+
; NAME:
;       MULTI_INTERP
;
; PURPOSE:
;       Performs a multiple 1D interpolation on a 2D image, along a set of
;	lines given by a map (for ex. parallel lines)
;
; CALLING SEQUENCE:
;       interp_array = multi_interp (array, map, theta)
;
; INPUTS:
;	array		an array to interpolate; interpolation is performed
;			on missing values within the array (i.e. null values)
;			thanks to the correct values (non-null values)
;	map		an array of the same dimensions, showing the location
;			of lines where to performs the multiple interpolations
;			The value of each pixel in that map is the number of
;			the line it belongs to (0, 1, ..., N-1) for N lines
;	theta		the angle perpendicular to the parallel lines
;
; OUTPUTS:
;	The interpolated array
;-



function  multi_interp, array, map, theta

;   output array
interp_array = array

;   dimension of the map
s = size(map)
nx = s(1)
ny = s(2)

map = round(map)

for i = 0, max(map) do begin

   ;   subscripts of the slice number i (from 0 to N-1, if there are N slices)

   ;   if the line has a positive slope (x and y both increase or decrease)
   ;   the subscript are picked in the normal order (with "where")
   ;   if the line has a negative slope (x and y vary in oposite order)
   ;   the subscript need to be picked on the image with REVERSED columns
   if ((theta mod !pi) lt !pi/2) $
      then begin
         s = where(reverse(map,1) eq i, n)
         x = s mod nx
         y = s / nx
         s = (nx-1-x)+y*nx
         endif $
      else s = where(map eq i, n)



;draft = map*0
;print
;print
;print, format='($,a)', "s = "
;for k=0, n-1 do begin
;   print, format='($,a,i0,a,i0,a)', $
;   "(", s(k) mod (size(map))(1), ", ", s(k) / (size(map))(1), ")  "
;   draft=draft-1
;   draft(s(k))=100
;   tvz, draft,/n
;   endfor

   ;   slice of points (x,y) extracted from the 2D array along the slice s
   if n gt 0 $
   then begin
      ;   points (x,y) along the slice
      x = indgen(n)
      y = array(s)

      ;   known points (x1,y1) = non-zero values among y
      x1 = where(y ne 0, n1)
      if n1 gt 0 $
         then y1 = y(x1)

      ;   unknown points (x2,y2) = values to interpolate
      x2 = where(y eq 0, n2)

;modif 11/02/2000
      if (n1 gt 1) and (n2 gt 0) then begin
;end modif 11/02/2000
;old line 
      ;if (n1 gt 0) and (n2 gt 0) then begin

         yy = spl_init(x1,y1)
         y2 = spl_interp(x1,y1,yy,x2)

         ;y2 = spline(x1,y1,x2,0.1)

         ;   upates the new values on the array
         interp_array(s(x2)) = y2
         endif
   endif	; if n gt 0



;plot, x, y, /nodata
;oplot, x1, y1, psym=4
;if (size(x2))(0) gt 0 then oplot, x2, y2, psym=0
;k = get_kbrd(1)


   endfor	; for i

return, interp_array
end


; *****************************************************************************


;+
; NAME:
;       MULTI_SMOOTH
;
; PURPOSE:
;       Performs a multiple 1D smoothing on a 2D image, along a set of
;	lines given by a map (for ex. parallel lines)
;	Multi-smooth works exactely in the same way than multi-interp
;
; CALLING SEQUENCE:
;       smooth_array = multi_smooth (array, map, theta)
;
; INPUTS:
;	array		an array to smooth
;	map		an array of the same dimensions, showing the location
;			of lines where to performs the multiple smoothing
;	theta		the angle perpendicular to the parallel lines
;
; OUTPUTS:
;	The smoothed array
;-



function  multi_smooth, array, map, theta

;   output array
smooth_array = array

;   dimension of the map
s = size(map)
nx = s(1)
ny = s(2)

map = round(map)

for i = 0, max(map) do begin

   ;   subscripts of the slice number i (from 0 to N-1, if there are N slices)


   ;   if the line has a positive slope (x and y both increase or decrease)
   ;   the subscript are picked in the normal order (with "where")
   ;   if the line has a negative slope (x and y vary in oposite order)
   ;   the subscript need to be picked on the image with REVERSED columns
   if ((theta mod !pi) lt !pi/2) $
      then begin
         s = where(reverse(map,1) eq i, n)
         x = s mod nx
         y = s / nx
         s = (nx-1-x)+y*nx
         endif $
      else s = where(map eq i, n)

   ;   points (x,y) along the slice
   x = indgen(n)
   y = array(s)

   ;   smooth width
   width = 3

   if n gt width then begin
      ;   smoothed points (x2,y2)
      x2 = x
      y2 = smooth(y, width)

      ;   upates the new values on the array
      smooth_array(s(x2)) = y2
      endif

   endfor	; for i


return, smooth_array
end


; *****************************************************************************
; **********************   MAIN ROUTINE   *************************************
; *****************************************************************************
			


function  hcie_zone, image, list_miss_blocks,rebindex=rebindex

;   side of the blocks
side = 32

;   zone surrounding the missing blocks
zone = read_zone (image, list_miss_blocks, nx, ny,rebindex=rebindex)

;  get the orientation of the rescaled zone
angle = grad_zone(image, list_miss_blocks,rebindex=rebindex)
;angle = round(angle/(!pi/8))*(!pi/8)

; -----------------------------------------------------------------------------

;   rescale the zone to the scale of "sub-blocks"
;   (each block is considered as a set of nsub x nsub sub-blocks, instead of a
;   set of side x side pixels, with nsub < side)
nsub = 8
sub_side = side/nsub
sub_zone = rebin (zone, nx/sub_side, ny/sub_side)

;   in order to process multiple 1D interpolation of the zone, get the map of
;   the lines along wich the interpolation will be processed
grad_map = round(grad(nx/sub_side, ny/sub_side, angle))

;   perform the interpolations
interp_sub_zone = multi_interp(sub_zone, grad_map, angle)


; -----------------------------------------------------------------------------


;   corrected zone (at the original scale) deduced by interpolation with a
;   smooth quintic surface
new_zone = tri_surf (interp_sub_zone, $
           xgrid = [sub_side/2, sub_side], ygrid = [sub_side/2, sub_side], $
           gs = [1, 1], bounds = [0, 0, nx-1, ny-1] )

;   subscripts of the pixels belonging the one of the missing blocks
zero = where(zone eq 0, n_zero)

;   updates the zone for these subscripts
if n_zero gt 0 $
   then zone(zero) = new_zone(zero)

;for i = 1, 10 do begin $
;   sm_zone = smooth(zone, 3)
;   zone(zero) = sm_zone(zero)
;   endfor	; for i

;   smoothes the final result
perpend_map = round(grad(nx, ny, angle+!pi/2))
smooth_zone = multi_smooth(zone, perpend_map, angle+!pi/2)
if n_zero gt 0 $
   then zone(zero) = smooth_zone(zero)



;		zone(zero) = (rebin(grad_map, nx, ny, /sample)*10000)(zero)



return, zone
end


