;+
; PROJET:
;	SOHO - LASCO
;
; NAME:
;	FIND_MISS_BLOCKS
;
; PURPOSE:
;	Finds all the missing blocks on an image. Generate the map of the non usefull blocks and the missing blocks.
;
;	Call this routine before using a chain of correction, otherwise the location of all missing blocks would be lost after the 1st correction
;
; CATEGORY:
;  missing blocks
;
; CALLING SEQUENCE:
;	find_miss_blocks,ima,hdr,missblock,imafuzz,hdrfuzz,/fuzzyima
;
; ADMITTED INPUT TYPE OF IMAGES:
;	all
;
; INPUTS:
;	ima : the image to make the map
;	hdr : fits header of the image
;
; OUTPUTS:
;
;	missblock : output structure for fits table
;		FILENAME : filename of the image
;		NBMISS : number of missing blocks
;		NBNUSEF : number of non usefull blocks
;		MBMAP : map of the missing blocks
;			1: block OK
;			0: non transmitted usefull block
;			-1: non usefull block
;		MBMAPALL : map of all the non transmited blocks (lost plus non useful)
;			1: block OK
;			0: non transmitted useful or non usefull block
;			note that if a block is set to -1 in MBMAP and also set to 1 in MBMAPALL it means that, even so, this block was transmitted
;
; OPTIONAL OUTPUTS:
;	imafuzz : image with the corrected blocks
;	hdrfuzz : header of the corrected image: the HISTORY specify that the image was corrected by fuzzy_image procedure
;
; KEYWORD INPUT:
;	fuzzyima : compute the missing block interpolation by fuzzy_image procedure
;       hdrstru : header structure given by getl05hdrstru
;       full : resample output maps to 32*32 
;       strmap : string map for the DB 
;
; CALLED ROUTINES:
;	SXPAR.GETTOK.GET_TMASK.FUZZY_IMAGE.GET_MISS_BLOCKS.GET_TMASK_F.WHERE2D.HCIE_ZONE.READ_ZONE.GRAD_ZONE.REVERSE.SPLINE.TRI_SURF.WRITE_ZONE.FUZZY_BLOCK.READ_BLOCK.DCT.NUM_TO_FUZZY.INTER_FUZZY.FUZZY_TO_NUM.WRITE_BLOCK.SXADDPAR.
;
; MODIFICATION HISTORY:
;	V1.0 Writen by A.Thernisien on 23/12/99 from get_miss_blocks.pro by J.MORE, September 1996
;	V2.0 by A.T. 18/01/2000
;       V2.1 by AT 18/09/2001 add of STRMAP and FULL keywords
; CVSLOG:
;  $Log: find_miss_blocks.pro,v $
;  Revision 1.2  2002/07/11 07:24:17  arnaud
;  Insertion of the Log in each header
;
;
;-
pro find_miss_blocks,ima,hdr,missblock,imafuzz,hdrfuzz,FUZZYIMA=fuzzyima,hdrstru=hdrstru,full=full,strmap=strmap
;get image parameters from its header
if n_elements(hdrstru) eq 0 then begin 
    getl05hdrparam,hdr,hdrfieldstruct
    hdrstru=hdrfieldstruct
endif else hdrfieldstruct=hdrstru

;if getl05hdrparam failled then abort
if hdrfieldstruct.rebindex eq -1 then begin
	message,'Can''t process find_miss_blocks: bad image format',/inform
	return
endif

;side of a square block
side=32

;compute the position of the inferior left corner
;idep=hdrfieldstruct.fxstart/side
;jdep=hdrfieldstruct.fystart/side
;ifin=hdrfieldstruct.fxend/side
;jfin=hdrfieldstruct.fyend/side

;deduced max column and row index
imax = hdrfieldstruct.sx/side
jmax = hdrfieldstruct.sy/side

;   same image, reduced to a (imax) x (jmax) array
;   (so that each block become 1 pixel)
red_image = rebin(ima, imax, jmax,/sample)

red_imsq=fltarr(32/hdrfieldstruct.rebindex,32/hdrfieldstruct.rebindex)
idep=hdrfieldstruct.fxstart/side/hdrfieldstruct.rebindex
jdep=hdrfieldstruct.fystart/side/hdrfieldstruct.rebindex
ifin=(hdrfieldstruct.fxend+1)/side/hdrfieldstruct.rebindex-1
jfin=(hdrfieldstruct.fyend+1)/side/hdrfieldstruct.rebindex-1
red_imsq(idep,jdep)=red_image
red_image=red_imsq

;   ----------------------   map of the missing blocks   ----------------------

;   map of missing blocks
;   0 represents a missing blocks, and 1 otherwise
missbmap=fix(red_image ne 0)
missbmapall=missbmap

; ------------------------   NON USEFUL BLOCKS   ------------------------------

;   gets the map of non_useful blocks (NUB)
;   then remove the NUB of the list of blocks to correct
get_tmask,hdrfieldstruct.detector,hdrfieldstruct.rebindex/2 , imskbig
imsk=rebin(imskbig,32/hdrfieldstruct.rebindex,32/hdrfieldstruct.rebindex,/sample)
m=where(imsk lt 0,cntnub)
if cntnub gt 0 then missbmap(m) = -1

;interpolate missed blocks if FUZZYIMA keyword is set
;place the image in a square array 
if n_elements(fuzzyima) ne 0 then begin

	;call fuzzy image
	imafuzz=fuzzy_image(ima,hdr=hdr)

	;modify the header
	hdrfuzz=hdr
	;sxaddpar,hdrfuzz,'HISTORY','Corrected by fuzzy_image.pro'

endif

;cut the output image according to the size of the input image
missbmap=missbmap(idep:ifin,jdep:jfin)
missbmapall=missbmapall(idep:ifin,jdep:jfin)

mm=where(missbmap eq 0,cntmiss)
mnu=where(missbmap eq -1,cntnub)

; ---- compute strmap if requested
if n_elements(strmap) ne 0 then begin
;    m=where(rotate(missbmapall,1) eq 0,cnt)
;    mmm=where(rotate(missbmap,1) eq 0,cntmiss)

    strmap={mbpos:'',ntbpos:'',nbmb:cntmiss}
    strmap.ntbpos=mb2strmap(missbmapall)
    strmap.mbpos=mb2strmap(missbmap)

;    if cnt gt 0 then begin
;        m2=m(0)
;        for i=1,cnt-1 do if m(i) ne m(i-1)+1 then m2=[m2,m(i-1)+1,m(i)]
;        m2=[m2,m(cnt-1)]
;        strmap.ntbpos=strjoin(inttob32(m2,2))
;    endif
;    if cntmiss gt 0 then begin
;        mmm2=mmm(0)
;        for i=1,cntmiss-1 do if mmm(i) ne mmm(i-1)+1 then mmm2=[mmm2,mmm(i-1)+1,mmm(i)]
;        mmm2=[mmm2,mmm(cntmiss-1)]
;        strmap.mbpos=strjoin(inttob32(mmm2,2))
;    endif
endif

; --- resample to 32*32 if requested
if n_elements(full) ne 0 then begin
    rebindex=hdrfieldstruct.rebindex
    mmfull=replicate(-1,32,32)
    mmafull=replicate(-1,32,32)
    mmfull(idep*rebindex:ifin*rebindex+rebindex-1,jdep*rebindex:jfin*rebindex+rebindex-1)=rebin(missbmap,(ifin-idep)*rebindex+rebindex,(jfin-jdep)*rebindex+rebindex,/sample)
    mmafull(idep*rebindex:ifin*rebindex+rebindex-1,jdep*rebindex:jfin*rebindex+rebindex-1)=rebin(missbmapall,(ifin-idep)*rebindex+rebindex,(jfin-jdep)*rebindex+rebindex,/sample)
    missbmap=mmfull
    missbmapall=mmafull
endif


;create the structure
missblock={FILENAME: hdrfieldstruct.filename ,NBMISS: cntmiss ,NBNUSEF: cntnub,MBMAP:missbmap, MBMAPALL: missbmapall}


return
end
