;+
; PROJET:
;	SOHO - LASCO
;
; NAME:
;	FUZZY_BLOCK
;
; PURPOSE:
;	Retrieves high-frequency information of a lost block using fuzzy logic
;
; PROCEDURE:
;	Retrieves high-frequency information of a lost block using fuzzy logic
;	reasoning on blocks specta
;	
; CATEGORY:
;	Missing Blocks, Interpolation
;
; CALLING SEQUENCE:
;	block =	fuzzy_block (image, i, j)
;
; INPUTS:
;	image		the image containing the block to correct
;	i, j		the location (column, row) of this block
;
; KEYWORD INPUT:
;	rebindex : rebin index (see fuzzy_image.pro)
;
; OUTPUTS:
;	The corrected block (array of pixels) is returned
;
; SUB-ROUTINES:
;	fuzzy_block.pro  contains the following sub-routines :
;
;	_ num_to_fuzzy		convert a number to a fuzzy interval
;	_ fuzzy_to_num		convert a fuzzy interval to a number
;	_ inter_fuzzy		intersection of 2 fuzzy intervals
;	_ FUZZY_BLOCK		perform a spectrum correction of a block
;	  (=main routine)	using fuzzy logic reasoning
;
; REFERENCE:
;	( see fuzzy_image.pro )
;
; MODIFICATION HISTORY:
;	Written by J. MORE, October 1996
;	Add of rebindex keyword on 28/01/2000 by A.Thernisien
;-



function  fuzzy_block, image, i, j,rebindex=rebindex


;   side of a square block
side = 32

;   zone made with the nx x ny blocks surrounding the missing block
zone = read_zone (image, [i,j],rebindex=rebindex)
nx = (size(zone))(1) / side
ny = (size(zone))(2) / side


;   array of spectra ( spectr(i0, j0, *, *) has the same dim. as 1 block )
sp = complexarr( side, side, nx, ny )

;   for the nx x ny surrounding blocks...
;   gets the block and its DCT spectrum
for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      begin
         block = read_block (zone, ii, jj)
         sp(*, *, ii, jj) = dct(block)
      end


; ------------------   definition of the subspectra   ------------------------


;   Each spectrum will be divided in several regions called sub-spectrum
;   The subspectra mask represents the map of all these regions

;   "column" array and "row" array
x0 = 0
y0 = 0
xx = indgen(side) # replicate(1, side)
yy = replicate(1, side) # indgen(side)

;   subspectra masks
sub_mask = bytarr(side, side)

;   names of the different regions of this subspectra mask
;   (D.C. coef., low-frequency, horizontal, vertical, diagonal, high frequency)
mean = 0  &  low = 1  &  horiz = 2  &  vert = 3  &  diag = 4  &  high = 5

;   making of this subspectra mask
diag_angle = !pi/6
low_radius = 4
high_radius = side*0.9
sub_mask(*) = diag
sub_mask(where(abs(yy-y0) lt abs(xx-x0)*tan(diag_angle/2)))   = horiz
sub_mask(where(abs(xx-x0) lt abs(yy-y0)*tan(diag_angle/2)))   = vert
sub_mask(where(abs(complex(xx-x0, yy-y0)) lt low_radius))     = low
sub_mask(where(abs(complex(xx-x0, yy-y0)) gt high_radius))    = high
sub_mask(x0, y0)                                              = mean



;sub_mask = shift(sub_mask, side/2, side/2)

;   corresponding subspectra (spectra multiplied by sub-masks)
sub_sp = fltarr(side, side, 6, nx, ny)
for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      for s = 0, 5 do $
         sub_sp(*, *, s, ii, jj) = sp(*, *, ii, jj) * (sub_mask eq s)

;   number of elements en each sub-spectrum
;   n_sub_sp = lonarr(6)
n_sub_sp = histogram(fix(sub_mask))

; ------------------   subspectra features   ---------------------------------


;   normalized energy : energy per element in the subspectra
;   (for each block then for each subspectrum)
norm_en = fltarr(6, nx, ny)

;   for each of the nx x ny blocks
for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      ;   for each subspectrum :
      for s = 0, 5 do $
         norm_en(s, ii, jj) = $
                            total(abs(sub_sp(*, *, s, ii, jj))^2) / n_sub_sp(s)


;   subspectra centroids
xcent = fltarr(6, nx, ny)
ycent = fltarr(6, nx, ny)

;   for each of the nx x ny blocks
for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      ;   for each subspectrum :
      for s = 0, 5 do $
         begin
            xcent(s, ii, jj) = total(xx*abs(sub_sp(*,*, s, ii, jj))^2) / $
                               total(abs(sub_sp(*,*, s, ii, jj))^2)
            ycent(s, ii, jj) = total(yy*abs(sub_sp(*,*, s, ii, jj))^2) / $
                               total(abs(sub_sp(*,*, s, ii, jj))^2)
         endfor		; for s



;   texture orientation, i.e. subspectrum (among horiz., vert. or diag.)
;   with highest energy
orient = bytarr(nx, ny)

;   for each of the nx x ny blocks
for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      begin
         m = max(norm_en(*, ii, jj)*[0,0,1,1,1,0], o)
         orient(ii, jj) = o
      endfor	; for ii


;   phase skewing template (map of the negative ac elements)
;ph_sk = bytarr(side, side, 6, nx, ny)
ph_sk = sub_sp lt 0


; ------------------   detecting main orientation   ---------------------------


;   the main orientation is set to the orientation of the majority of the
;   surrounding blocks

;   main orientation smax and number of blocks nmax having this orientation
;   smax is beetween 0 and 5
nmax = max( histogram(fix(orient), min=0, max=5)*[0,0,1,1,1,0], smax )


; ------------------   selecting member blocks   ------------------------------


;   member blocks are blocks with the same orientation than the missing block
;   except the missing block itself !

;   -> A possible improvement would be to select the member blocks according to
;   the degre of similarity beetwen the missing block and a surrounding block
;   for the 4 previous features

;   4 similarities beetween the missing block and the surrounding blocks
sim = fltarr(4, nx, ny)
for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      begin
         sim(0, ii, jj) = 1 - $
                     abs(norm_en(smax, ii, jj) - norm_en(smax, 1, 1)) / $
                     abs(max(norm_en(smax, *, *)) - min(norm_en(smax, *, *)))
         sim(1, ii, jj) = 1 - $
                   sqrt( (xcent(smax, ii, jj)-xcent(smax, 1, 1))^2 + $
                         (ycent(smax, ii, jj)-ycent(smax, 1, 1))^2 ) / 20

      endfor

;   member = bytarr(nx, ny)
member = orient eq smax
member(1,1) = 0

; ------------------   computing confidence levels   --------------------------


;   for each surrounding block, the confidence level in the main orientation
;   subpectrum is the ratio of phase skewing matching beetween the missing
;   block and the surrounding block (phase skewing templates for the
;   corresponding subspectrum in both blocks)

conf = fltarr(nx, ny)
for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      conf(ii,jj) = 1 -  $
         total(ph_sk(*,*,smax,ii,jj) xor ph_sk(*,*,smax,1,1)) / n_sub_sp(smax)


; ------------------   recovering ac coefficient in that subspectrum   --------


;   min and max values (exept where 0) of that subspectrum in all blocks
all_sub_sp = sub_sp(*,*,smax,*,*)
all_sub_sp = all_sub_sp(where(all_sub_sp) ne 0)
min = min(all_sub_sp)
max = max(all_sub_sp)

;   fuzzy version of the array representing the sub-spectrum of the missing
;   block
fuzzy_sub_sp = num_to_fuzzy( sub_sp(*, *, smax, 1, 1), min, max, 0)

;   for all element of the subspectrum, compute several fuzzy intersections
;   (with all member blocks) to narrow down intervals corresponding to fuzzy
;   values
;   
for jj =  0, ny-1 do $
   for ii =  0, nx-1 do $
      if member(ii, jj) then $
         fuzzy_sub_sp = inter_fuzzy( fuzzy_sub_sp, $
                      num_to_fuzzy(sub_sp(*, *, smax, ii, jj), min, max, 0.5) )

;   at the end, return to a deterministic version of the subspectrum
number_sub_sp = fuzzy_to_num(fuzzy_sub_sp)

;   finally update the missing block subspectrum
index = where(sub_mask eq smax)
sp_block = sp(*, *, 1, 1)
sp_block(index) = number_sub_sp(index)
block = dct(sp_block, /inverse)

return, block


; ---------------------- D R A F T --------------------------------------------



for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      begin
         print
         print, format='(a, i0, a, i0, a)', "Block (", ii, ", ", jj, ")"
         tot_en = total(norm_en(1:5, ii, jj))

         for s = 0, 5 do $
            begin
               print, format='(a, i0, a, f7.3, a)', $
                  "N.E.(", s, ") = ", norm_en(s, ii, jj)/tot_en*100, "%"
            end
      end


print
for jj = 0, ny-1 do $
   begin
      print, format='($, a)', "["
      for ii = 0, nx-1 do $
         begin
            m = max(norm_en(*, ii, jj) * [0,0,1,1,1,0], dirmax)
            print, format='($, a, i0, a)', "    (", dirmax, ") "
            case dirmax of
                  2 : print, format='($, a8)', "HORIZONTAL"
                  3 : print, format='($, a8)', "VERTICAL"
                  4 : print, format='($, a8)', "DIAGONAL"
                  else : print, format='($, a8)', "???"
               endcase
         endfor
      print, "]"
   endfor
print



ifact = 256./max(abs(sp))
zonesp = fltarr(side*nx, side*ny)

for jj = 0, ny-1 do $
   for ii = 0, nx-1 do $
      begin
         zonesp(side*ii, side*jj) = sp(*, *, ii, jj)
         zonesp(side*ii, side*jj) = 0.
      endfor	; for ii


wset, 1
tvz, zonesp, sp=[nx,ny]


s=5

print
for jj=0,2 do $
   for ii=0,2 do $
      print, conf(ii, jj)

erase
tvz, sub_mask, /split



; -----------------------------------------------------------------------------


end


