;+
; PROJET:
;	SOHO - LASCO
;
; NAME:
;	STRMAP2MB
;
; PURPOSE:
;  Convert a 'string map' to a missing block image map
;
; CATEGORY:
;  missing blocks
;
; CALLING SEQUENCE:
;
;
; INPUTS:
;  sm : string coded MB map
;  sx,sy : size in pixel of the original image
;
; OPTIONAL INPUTS:
;  rebindex : only necessary if 'full' parameter is passed
;             rebin factor of the original image: 1 : full resolution
;                                                 2 : half resolution
;                                                 4 : quarter resolution
;                                                 8 : 8th resolution
; OUTPUTS:
;  mb : missing block map mask
;
; OPTIONAL OUTPUTS:
;
; KEYWORD INPUT:
;  full : set to [frame_start_X,frame_start_Y] in 1024 CCD pix if
;         image is not full field
;
; MODIFICATION HISTORY:
;	V1.0 Writen by A.Thernisien on 18/07/2001
; CVSLOG:
;  $Log: strmap2mb.pro,v $
;  Revision 1.2  2002/07/11 07:24:19  arnaud
;  Insertion of the Log in each header
;
;
;-
pro strmap2mb,sm,sx,sy,rebindex,mb,full=full

; -- count the MB
nbmb=strlen(sm)/2

if nbmb gt 0 then begin
    ; -- split the sm into slice of two chars
    pos=strarr(nbmb)
    m=lonarr(nbmb)

    for i=0,nbmb-1 do pos(i)=strmid(sm,i*2,2)
    ; -- convert each base32 position into map position
    m=b32toint(pos)

    m(n_elements(m)-1)=m(n_elements(m)-1)+1

    diff=shift(m,-1)-m
;    diff(n_elements(diff)-1)=diff(n_elements(diff)-1)+m(n_elements(m)-1)+1
    mpos=0L

    for i=0,n_elements(diff)-2,2 do begin
        mpos=[mpos,m(i)+lindgen(diff(i))]
    endfor
    mpos=mpos(1:*)

    ; -- build the output mb
    mb=replicate(1,sy/32,sx/32)
    mb(mpos)=0

    mb=rotate(mb,3)

endif else begin
    mb=replicate(1,sx/32,sy/32)
endelse

if n_elements(full) ne 0 then begin
    mbf=replicate(-1,32,32)
    mbf(full(0)/32,full(1)/32)=rebin(mb,sx*rebindex/32,sy*rebindex/32,/sample)
    mb=mbf
endif


return
end
