
;+
; PROJET:
;	SOHO - LASCO
;
; NAME:
;	GET_MISS_BLOCKS
;
; PURPOSE:
;	Finds all the missing blocks on an image
;
; PROCEDURE:
;	Finds all the missing blocks on an image, and designs the corresponding
;	"missing zones"; returns a map of the missing blocks where each
;	missing block is then given the number of the missing zone it belongs
;	A missing zone is defined as the smallest rectangle that surrounds a
;	cluster of missing blocks (likely to be neighbor missing blocks) but
;	has no missing blocks on its border (its outermost rows and columns)
;
;	Call this routine before using a chain of correction, otherwise the
;	location of all missing blocks would be lost after the 1st correction
;
; CATEGORY:
;	Detection, Missing Blocks
;
; CALLING SEQUENCE:
;	get_miss_blocks, image, map_miss_blocks
;                        [ , list_miss_blocks, n_miss_blocks ]
;
; INPUTS:
;	image			the image to make the map of
;
; OUTPUTS:
;	map_miss_blocks		the map of the missing blocks, a 32x32 array
;				Assume there are nz missing zones, then each
;				element (i,j) on the map represents the state
;				of the block at column i and row j :
;				_ (-1) means it's a correct block
;				_ A integer z (from 0 to nz-1) means this is a
;				  missing block belonging to the "z"th zone
; OPTIONAL OUTPUT:
;	list_miss_blocks	the total list of missing blocks, a 2 columns
;				array, where each row (i,j) represents the
;				location of a missing block
;	n_miss_blocks		the total number of missing blocks
;
; KEYWORD INPUT:
;	detector : C2 or C3 to get the non transmitted block mask (default:C2)
;	rebindex : 0: 1024 * 1024, 1: 512 * 512, 2:256 * 256
;	ALL:	Do not get block mask
;
; EXAMPLE:
;	Given a image "image1" with missing blocks, get its map:
;		get_miss_blocks, image1, map_b
;
;	Print the list and the number of missing blocks :
;		print, where2d(map_b ge 0, n_b)  &  print, n_b
;
;	Get the number of missing zones, then for each missing zone print the
;	blocks it contains :
;		n_z = max(map_b)+1
;		for z=0, n_z - 1 $
;			print, where2d(map_b eq z)
;	
; MODIFICATION HISTORY:
;	Written by J.MORE, September 1996
;	Modif 13/01/2000 A.T. add of detector and rebindex keyword
;	1/24/01, nbr - extend zone to two blocks in each direction instead of one
;	12/31/01, nbr - Add ALL keyword
;	 4/10/03, nbr - Modify map_miss_blocks criteria
;
;-

pro  get_miss_blocks, image, map_miss_blocks, list_miss_blocks, n_miss_blocks,DETECTOR=detector,REBINDEX=rebindex, ALL=all

; side of a square block
side = 32

;set keywords default values
if n_elements(rebindex) eq 0 then rebindex=0
if n_elements(detector) eq 0 then detector='C2'

;dimensions of the image
s = size(image)
xsize = s(1)
ysize = s(2)

;deduced max column and row index
imax = xsize/side
jmax = ysize/side

;same image, reduced to a (imax) x (jmax) array
;(so that each block become 1 pixel)
red_image = rebin(image, imax, jmax)

;----------------------   map of the missing blocks   ----------------------
;
;   0 represents a missing blocks, and -1 otherwise
;map_miss_blocks = -fix(red_image ne 0)
map_miss_blocks = -fix(red_image GT 0.1)  ; rebin may result in small numbers 
					; in missing blocks - nbr,2003/01/06

;------------------------   NON USEFUL BLOCKS   ----------------------------
;   gets the map of non_useful blocks (NUB)
;   then remove the NUB of the list of blocks to correct

IF NOT(keyword_set(ALL)) THEN BEGIN
;get the NUB according to the detector
   get_tmask,detector,rebindex,imsk
   m=where(imsk le -1,nb) ;get only nub of the corners and center of occulter
   if nb gt 0 then begin
	imsk(*)=0
	imsk(m)=-1
   endif else imsk(*)=0
   mnub=where(imsk,cntmnub)
   if cntmnub gt 0 then map_miss_blocks(where(imsk)) = -1
ENDIF

;   list of the missing blocks
list_miss_blocks = where2d(map_miss_blocks eq 0, n_miss_blocks)


;   if no missing blocks, aborts
if n_miss_blocks eq 0 then return


;----------------------   map of the missing zones   -----------------------

;   resets map_image (the location of the missing blocks is saved in the list)
map_miss_blocks(*,*) = -1

;   the missing zone will be described in a list ( a 4 x n array, where n is
;   the number of missing zones, and each row [i1,i2,j1,j2] represents the 2
;   extreme blocks b1[i1,j1] and b2[i2,j2] of the zone
list_miss_zones = bytarr(4, n_miss_blocks)

;   generates the missing zones, thanks to the list of the missing blocks
;   At first, each missing block is considered as a new missing zone,
;   then every time a newly created missing zone interferes with any of the
;   old missing zones, the 2 zones merge (in fact the new zone "eats" every
;   old zone interfering with it)


for new_z = 0, n_miss_blocks-1 do $

   begin
      i = list_miss_blocks(0, new_z)
      j = list_miss_blocks(1, new_z)
      list_miss_zones(*, new_z) = $
         [  (i-1) > 1,   (i+1) < (imax-2),   (j-1) > 1,   (j+1) < (jmax-2)  ]
      map_miss_blocks(i,j) = new_z

      ;   scans every old zone
      for old_z = 0, new_z-1 do $
         begin
            ;   first, looks for old missing blocks in the new missing zone PLUS 1
            i1 = list_miss_zones(0, new_z)
            i2 = list_miss_zones(1, new_z)
            j1 = list_miss_zones(2, new_z)
            j2 = list_miss_zones(3, new_z)
            old_in_new = $
               where(map_miss_blocks(i1-1:i2+1, j1-1:j2+1) eq old_z, n_old_in_new)

            ;   secondly, looks for new missing blocks in that old missing zone PLUS 1
            i1 = list_miss_zones(0, old_z)
            i2 = list_miss_zones(1, old_z)
            j1 = list_miss_zones(2, old_z)
            j2 = list_miss_zones(3, old_z)
            if (i2 eq 0) and (j2 eq 0) $	; empty zone
               then n_new_in_old = 0 $
               else new_in_old = $
                  where(map_miss_blocks(i1-1:i2+1, j1-1:j2+1) eq new_z, n_new_in_old)

            if (i2 eq 0) and (j2 eq 0) then new_in_old = 0

            ;   if either exists, the new zone will eat the old zone
            if (n_old_in_new gt 0) or (n_new_in_old gt 0) then $
               begin

                  ;   gets the reunion of the 2 zones (new and old)
                  i1 = min(list_miss_zones(0, [old_z, new_z]))
                  i2 = max(list_miss_zones(1, [old_z, new_z]))
                  j1 = min(list_miss_zones(2, [old_z, new_z]))
                  j2 = max(list_miss_zones(3, [old_z, new_z]))

                  ;   the new_zone is spread to this union, the old is killed
                  list_miss_zones(*, new_z) = [i1, i2, j1, j2]
                  list_miss_zones(*, old_z) = [0, 0, 0, 0]

                  ;   updates the map relatively to the new zone
                  old = where(map_miss_blocks eq old_z, n_old)
                  if n_old gt 0 $
                     then map_miss_blocks(old) = new_z

                  ;   if 2 zones have just merged, it is necessary to scan
                  ;   again ALL the old zones (from 0) for new merging cases
                  old_z = -1
               endif

         endfor        ;   ( for old_z = 0 to new_z-1 do $ )

   endfor              ;   ( for new_z = 0 to n_miss_blocks-1 do $ )


;   now compresses the list of the missing zones, as some of them have been
;   "eaten" by newer zones and have been set to 0
;   what follows simply changes the subscripts of the zones to fit : 0,1,2,etc.

;   list of the actual missing zones (and the actual number of them)
index = where(list_miss_zones(3,*) ne 0, n_miss_zones)


;   keeps only those zones
list_miss_zones = list_miss_zones(*, index)

;   rescales the map with the values (0,1,2,etc.)
for z = 0, n_miss_zones-1 do $
   map_miss_blocks( where(map_miss_blocks eq index(z)) ) = z

;stop
return
end




