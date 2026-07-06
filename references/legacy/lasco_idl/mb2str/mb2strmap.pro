;+
; PROJET:
;	SOHO - LASCO
;
; NAME:
;	MB2STRMAP
;
; PURPOSE:
;  Convert a missing block image map to a 'string map'
;
; CATEGORY:
;  missing blocks
;
; CALLING SEQUENCE:
;
;
; INPUTS:
;
; OUTPUTS:
;
;
; OPTIONAL OUTPUTS:
;
; KEYWORD INPUT:
;
;
; MODIFICATION HISTORY:
;	V1.0 Writen by A.Thernisien on 18/09/2001
; CVSLOG:
;  $Log: mb2strmap.pro,v $
;  Revision 1.2  2002/07/11 07:24:17  arnaud
;  Insertion of the Log in each header
;
;
;-
function mb2strmap,mbmap
strmap=''
m=where(rotate(mbmap,1) eq 0,cnt)
if cnt gt 0 then begin
    m2=m(0)
    for i=1,cnt-1 do if m(i) ne m(i-1)+1 then m2=[m2,m(i-1)+1,m(i)]
    m2=[m2,m(cnt-1)]
    strmap=strjoin(inttob32(m2,2))
endif

return,strmap
end
