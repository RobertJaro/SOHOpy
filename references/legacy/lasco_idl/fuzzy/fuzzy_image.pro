;+

function fuzzy_image,ima,HDR=hdr,VERBOSE=verbose, TOO_MANY=too_many, ALL=all
;
; PROJECT:
;	SOHO - LASCO
;
; NAME:
;	FUZZY_IMAGE
;
; PURPOSE:
;	Corrects missing blocks on a image with a fuzzy logic method
;	
; CATEGORY:
;	Missing Blocks, Enhancement
;
; CALLING SEQUENCE:
;	image =	fuzzy_image (ima,HDR=hdr)
;
; INPUTS:
;	ima : the image containing blocks to correct
;
; OUTPUTS:
;	The corrected image
;
; KEYWORDS:
;	hdr : FITS header of the image. WARNING: If the image header is not passed, fuzzy_image concider that 
;		the image is from C2 and 1024 * 1024: the procedure failed if it's not the case.
;	verbose : print running informations
; 	TOO_MANY: Flag for reduce_level_1.pro to mask missing blocks
;	ALL:	Replace all missing blocks, regardless of number or mask
;
; SUBROUTINES:
;	fuzzy_image.pro getl05hdrparam.pro sxpar.pro getok.pro get_tmask.pro get_miss_blocks.pro where2d.pro 
;	hcie_zone.pro read_zone.pro grad_zone.pro tri_surf.pro reverse.pro write_zone.pro fuzzy_block.pro 
;	read_block.pro dct.pro num_to_fuzzy.pro inter_fuzzy.pro fuzzy_to_num.pro write_block.pro
;
; REFERENCE:
;		-> This method is based upon the following :
;	Information Loss Recovery for Block-Based Image Coding Techniques
;	- A Fuzzy Logic Approach
;	Xiaobing Lee, Ya-Qin Zhang, Alberto Leon-Garcia
;	IEEE TRANSACTIONS ON IMAGE PROCESSING, VOL.4, NO.3, MARCH 1995
;
; MODIFICATION HISTORY:
;	V1.0 Written by J. MORE, October 1996
;	Modif by A.T. 13/01/2000 and 18/01/2000: 
;	- add of the HDR keyword the take account of the size and the detector. 
;	- small modif to avoid crash when a missing block is near a non transmitted block
;	1/23/01, nbr : Compute new blocks if number of good blocks in a zone greater than number of bad; 
;		remove if statement for doing fuzzy_block; add TOO_MANY keyword
;	12/4/01, nbr : Move function statement to top
;	12/31/01, nbr :	Add ALL keyword
;	 1/ 9/03, nbr : Add logfile; don't create window 2; change way n_in_zone is computed
;	 3/20/03, nbr : Re-enable TOO_MANY and make threshold 16
;	 4/ 9/03, nbr : add COMMON dbms, logging; add edge exclusion logic
;	 4/11/03, nbr : set too_many equal to number missing; do not continue if gt 100 missing in a zone
;       05.07.25, nbr - Update/fix too_many implementation for subfield cases
;
version = '@(#)fuzzy_image.pro	1.7, 07/25/05' ; LASCO IDL Library
;
;-

COMMON dbms, ludb,lulog

;welcome message
if n_elements(verbose) ne 0 then BEGIN
	message,'Entering missing block correction procedure',/inform
	openw,zonelun, 'fuzzy/zoneinfo.lst',/append,/get_lun
ENDIF

;init image var
image1=ima
image = image1
;side of a square block
side=32
too_many=0

;read the header if it's present
if n_elements(hdr) ne 0 then begin
	;get the header parameters
	getl05hdrparam,hdr,hdrfieldstruct
	
	;compute the position of the inferior left corner
	idep=hdrfieldstruct.fxstart/side
	jdep=hdrfieldstruct.fystart/side
	ifin=hdrfieldstruct.fxend/side
	jfin=hdrfieldstruct.fyend/side
	
	;deduced max column and row index
	imax = hdrfieldstruct.sx/side
	jmax = hdrfieldstruct.sy/side
	
	;if the image doesn't recover the all field of view, place the image in a square array
	imsqr=replicate(1.,1024/hdrfieldstruct.rebindex,1024/hdrfieldstruct.rebindex)
	imsqr((idep*side)/hdrfieldstruct.rebindex,(jdep*side)/hdrfieldstruct.rebindex)=image
	image1=imsqr
	image=imsqr

	;set common variables (with hdr not present)
	rebindex=hdrfieldstruct.rebindex
	detector=hdrfieldstruct.detector

endif else begin
	;the header is not present: set default values and compare to the image size
	sx=(size(image))(1)
	sy=(size(image))(2)
	detector='C2'
	idep=0
	jdep=0	
	ifin=31
	jfin=31
	rebindex=1

	;if there's no correspondance then don't correct the image
	if (sx ne 1024) or (sy ne 1024) then begin
		message,'Input image is not square: please give its header',/inform
		return,-1
	endif
endelse

;get the non usefull block mask
get_tmask,detector,rebindex/2,imsk
imsk=rebin(imsk,1024/rebindex,1024/rebindex,/sample)
m=where(imsk le -1,nb)
	
;replace nub by 1 instead of 0 to avoid crash with interpolation
IF NOT(keyword_set(ALL)) THEN if nb gt 0 then image1(m)=1

;gets the list of the missing blocks
get_miss_blocks, image1, map_miss_blocks,detector=detector,rebindex=(rebindex / 2), ALL=all

;performs the HCIE correction on each missing zone
n_miss_zones = max(map_miss_blocks)+1

if n_elements(verbose) ne 0 then BEGIN
	message,'Performs the HCIE correction on each missing zone',/inform
	;window,2
	;surface,map_miss_blocks,/lego
	tvscl,rebin(map_miss_blocks,512,512,/sam)
ENDIF

for z = 0, n_miss_zones-1 do begin
	print, format = '("Zone ",i3," of ", i3, " ")', z+1, n_miss_zones
	list_miss_blocks = where2d(map_miss_blocks eq z)
	; list_miss_blocks in form replicate(intarr[x,y], num missing blocks)
	IF keyword_set(VERBOSE) THEN print,'LIST_MISS_BLOCKS: ',list_miss_blocks
	; 
	n_in_zone = n_elements(list_miss_blocks)/2
	; Do it if there are more good blocks in zone then bad. First, figure out zone:
	zone = read_zone (image1, list_miss_blocks, nx, ny,rebindex=rebindex)
	zzone=where(zone EQ 0,nzzone)
	nzone=where(zone NE 0,nnzzone)
	
	if (nnzzone GT nzzone) OR keyword_set(ALL) then begin
		angle = grad_zone(image1,list_miss_blocks,rebindex=rebindex)
		zone=hcie_zone(image1, list_miss_blocks,rebindex=rebindex) 
		write_zone, image, list_miss_blocks, zone,rebindex=rebindex

	endif ;else print,'Too many missing blocks for this zone:',n_in_zone
	help,n_in_zone
	
	min1 = min(list_miss_blocks[0,*],max=max1)
	min2 = min(list_miss_blocks[1,*],max=max2)
	;IF keyword_set(VERBOSE) THEN $
	printf,lulog,  'ZONEINFO,'+ $
			fxpar(hdr,'DATE-OBS')+','+ $
			fxpar(hdr,'FILENAME')+','+ $
			trim(string(n_in_zone))+','+ $
			trim(string(min1))+','+ $
			trim(string(min2))+','+ $
			trim(string(max1))+','+ $
			trim(string(max2))
			
                        ;stop
	IF n_in_zone GT 16 OR $
		min1 EQ idep OR $
		max1 EQ ifin OR $
		min2 EQ jdep OR $
		max2 EQ jfin THEN too_many=n_in_zone
	; Mask missing blocks if GT 16 in a zone or 
	; if one occurs on an edge.
	IF n_in_zone GT 100 THEN BEGIN
		printf,lulog,'Fuzzy_image not used.'
		print,'Fuzzy_image not used.',n_in_zone
		help,too_many
		return,ima
	ENDIF
 endfor	; for z
help,too_many

;after interpolation, replace the 1 by 0 for nub
if nb gt 0 then image1(m)=0

;performs the "fuzzy logic" correction on each block
if n_elements(verbose) ne 0 then message,'performs the ''fuzzy logic'' correction on each block',/inform

;if (size(list_miss_blocks))(2) lt 6 then begin
	list_miss_blocks = where2d(map_miss_blocks ge 0, n_miss_blocks)
	for b = 0, n_miss_blocks-1 do begin
		i = list_miss_blocks(0, b)
		j = list_miss_blocks(1, b)
	
		block = fuzzy_block(image, i, j,rebindex=rebindex)
	
		write_block, image, i, j, block
	endfor
;endif

;stop

;cut the image according the its initial size
image=image((idep*side)/rebindex:(((ifin+1)*side)/rebindex)-1,(jdep*side)/rebindex:(((jfin+1)*side)/rebindex)-1)
IF keyword_set(VERBOSE) THEN BEGIN
	print,'Waiting before exiting FUZZY_IMAGE....
	wait,5
	print,'Returning.'
	close,zonelun
	free_lun,zonelun
ENDIF
return,image
end
