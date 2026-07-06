;+
; PROJET
;     SOHO-LASCO
;
; NAME:
;  B32TOINT
;
; PURPOSE:
;  Convert a base 32 number to integer
;
; CATEGORY:
;  Mathematics
;
; CALLING SEQUENCE:
;   
; DESCRIPTION:
;
; INPUTS:
;
; INPUT KEYWORD:
;
; OUTPUTS:
;
; PROCEDURE:
;  
; CALLED ROUTINES:
;
; HISTORY:
;	V1 A.Thernisien 10/07/2001
; CVSLOG:
;  $Log: b32toint.pro,v $
;  Revision 1.2  2002/07/11 07:24:12  arnaud
;  Insertion of the Log in each header
;
;
;-
function b32toint,in

in=strupcase(in)

sze=size(in)
if sze(0) eq 0 then begin
    sx=1 
    out=0L
endif else begin
    sx=sze(1)
    out=lonarr(sx)
endelse

for i=0L,sx-1 do begin
    for j=0,strlen(in(i))-1 do begin
        r=byte(strmid(in(i),j,1,/reverse))
        out(i)=out(i)+(r-48-7*(r ge 65))*long(32)^j
    endfor
endfor

return,out
end
