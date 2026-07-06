;+
; PROJET
;	SOHO-LASCO
;
; NAME:
;	getl05hdrparam
;
; PURPOSE:
;	Extracts from fits header parameters of the image
;
; CATEGORY
;	Fits Management
;
; CALLING SEQUENCE:
;	getl05hdrparam,hdr,hdrfieldstruct
;
; INPUTS:
;	hdr : header of a C2 or C3 image
;     
; KEYWORD INPUT:
;	offsetbias : set to compute the electronical offset bias
;
; OPTIONAL INPUTS PARAMETERS:
;     none
;
; OUTPUTS:
;	structure containing image parameters
;		filename : FILENAME
;		bitpix : BITPIX
;		detector : DETECTOR
;		sx : NAXIS1
;		sy : NAXIS2
;		fystart : R1ROW-1
;		fxstart : R1COL-20
;		fyend : P2ROW-1
;		fxend : P2COL-20
;		nrebinx : (fxend-fxstart+1)/sx
;		nrebiny : (fyend-fystart+1)/sy
;		bias : bias give by offset_bias
;		lebxsum : LEBXSUM
;		lebysum : LEBYSUM
;		sumcolx : SUMCOL (1,2,4: 1 instead of 0 in the header)
;		sumrowy : SUMROW (1,2,4: 1 instead of 0 in the header)
;		rebindex : = nrebinx if nrebinx==nrebiny else =-1
;
; OPTIONAL OUTPUT PARAMETERS:
;     none
;
;
; CALLED ROUTINES:
;	t_param.pre_offset_bias
;
; HISTORY:
;		V1.0 coded by A.Thernisien on 17/01/2000 based upon ima05dim.pro from A.LL
;-
pro getl05hdrparam,hdr,hdrfieldstruct,offsetbias=offsetbias

bitpix=sxpar(hdr,'BITPIX')
detector   = strtrim(sxpar(hdr, 'DETECTOR'), 2)
sx= sxpar(hdr,'NAXIS1')
sy= sxpar(hdr,'NAXIS2')

fystart=sxpar(hdr,'R1ROW')-1
if !ERR eq -1 then idep = sxpar(hdr,'P1ROW')-1
if !ERR eq -1 then fystart  = 0
fystart = long(fystart)
fxstart  = sxpar(hdr,'R1COL')-20
if !ERR eq -1 then fxstart  = sxpar(hdr,'P1COL')-20
if !ERR eq -1 then fxstart  = 0
fxstart  = long(fxstart)

fyend  = sxpar(hdr,'R2ROW')-1
if !ERR eq -1 then fyend  = sxpar(hdr,'P2ROW')-1
if !ERR eq -1 then fyend  = 1024-1
fyend  = long(fyend)
fxend  = sxpar(hdr,'R2COL')-20
if !ERR eq -1 then fxend  = sxpar(hdr,'P2COL')-20
if !ERR eq -1 then fxend  = 1043-20
fxend  = long(fxend)

nrebinx = (fxend-fxstart+1)/sx
nrebiny = (fyend-fystart+1)/sy

if bitpix gt 0 then begin                  ; integer coded                
if n_elements(offsetbias) ne 0 then begin
	offsbias=offset_bias(hdr,/sum)
endif else offsbias=0.
;	if !ERR eq -1 then camera_ok = 0
	lebxsum =  sxpar(hdr,'LEBXSUM')
	if !ERR eq -1 then nxleb  = 1
	lebysum =  sxpar(hdr,'LEBYSUM')
	if !ERR eq -1 then nyleb  = 1

	B_thresh = t_param(detector,'BIAS')*float(lebxsum*lebysum)  
	if (offsbias lt B_thresh*.95 or offsbias gt B_thresh*1.5) and (n_elements(offsetbias) ne 0) then begin
		message,'extrange value for bias from offset_bias?',/inform
		print,'bias ->',offsbias,' modified to ->',B_thresh
		offsbias = B_thresh
	endif
	sumcolx = 1 > sxpar(hdr,'SUMCOL')
	sumrowy = 1 > sxpar(hdr,'SUMROW')

endif else begin
	offsbias   = 0.                           ;(not 0.5 image)
	lebxsum  = 1
	lebysum  = 1
	sumcolx= nrebinx
	sumrowy= nrebiny
endelse

filename=strtrim(sxpar(hdr,'FILENAME'),2)

case 1 of 
	(nrebinx eq 1 and nrebiny eq 1): rebindex=1 
	(nrebinx eq 2 and nrebiny eq 2): rebindex=2 
	(nrebinx eq 4 and nrebiny eq 4): rebindex=4 
	else : begin
		message,'Unknown format for '+filename+' image ?',/inform
		rebindex=-1
	endelse
endcase

hdrfieldstruct={filename:filename,bitpix:bitpix,detector:detector,sx:sx,sy:sy,fystart:fystart,fxstart:fxstart,fyend:fyend,fxend:fxend,nrebinx:nrebinx,nrebiny:nrebiny,offsbias:offsbias,lebxsum:lebxsum,lebysum:lebysum,sumcolx:sumcolx,sumrowy:sumrowy,rebindex:rebindex}

return
end



