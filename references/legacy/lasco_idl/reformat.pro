;+
; reformat.pro
; Run the reformatting code in the EOF
; 
; SCCS variables for IDL use
; 
; @(#)reformat.pro	1.1 05/14/97 :NRL Solar Physics
;
;-

pro reformat

 print,'Thank you for using the LASCO reformatting software'

 write_closed
 reduce_main, 0, /auto

return
end 
