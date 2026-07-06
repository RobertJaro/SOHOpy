;+
; PROJET
;     SOHO-LASCO
;
; NAME:
;  INTTOB32
;
; PURPOSE:
;  Convert a integer to a base 32 number
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
;  $Log: inttob32.pro,v $
;  Revision 1.2  2002/07/11 07:24:12  arnaud
;  Insertion of the Log in each header
;
;
;-
function inttob32,in,nbdigit

sze=size(in)

if sze(0) eq 0 then begin
    sx=1 
    out=''
endif else begin
    sx=sze(1)
    out=strarr(sx)
endelse

for i=0,sx-1 do begin
    div=in(i)
    repeat begin
        res=div mod 32
        out(i)=string(byte(res+48+7*(res gt 9)))+out(i)
        div=div / 32
    endrep until (div eq 0)

    if n_elements(nbdigit) ne 0 then begin
        l=strlen(out(i))
        case 1 of
            (l lt nbdigit) : repeat out(i)='0'+out(i) until (strlen(out(i)) ge nbdigit)
            (l gt nbdigit) : out(i)=strjoin(replicate('*',nbdigit))
            else:
        endcase
    endif

endfor

return,out
end
