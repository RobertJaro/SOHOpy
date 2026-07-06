pro reduce_rectify_p1p2,effport,hdr
;
;+
; NAME:	
;			REDUCE_RECTIFY_P1P2
;
; PURPOSE:
;			Generate R1 and R2 coordinates from the P1,P2
;			CCD coordinates that simulate coordinates
;			that would have been used if the CCD had been
;			read out in the rectified position.
;			
; CATEGORY:		
;			LASCO REDUCTION
;
; CALLING SEQUENCE:
;			REDUCE_RECTIFY_P1P2,Effport,Hdr
;
; INPUTS:		
;			Effport:  A character 'A' to 'D' indicating
;				  the CCD readout port, corrected for
;				  the telescope position on the S/C
;			Hdr:	  The FITS image header
;
; OUTPUTS:		
;			None
;
; OPTIONAL OUTPUT PARAMETERS:
;			None
;
; COMMON BLOCKS:
;			None
;
; SIDE EFFECTS:
;			Adds parameters R1COL, R1ROW, R2COL, R2ROW,
;			EFFPORT to the FITS headers
;
; RESTRICTIONS:
;			If the port is not A..D then the values of R1
;			and R2 are just set to P1 and P2
;
;			If R1 is less than 1, the R1 and R2 coordinates
;			are adjusted accordingly
;
; PROCEDURE:
; MODIFICATION HISTORY:
;	Version 1	RA Howard 11 Jan 96	Written
;
;       @(#)reduce_rectify_p1p2.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
;
p1col = fxpar(hdr,'P1COL')
p1row = fxpar(hdr,'P1ROW')
p2col = fxpar(hdr,'P2COL')
p2row = fxpar(hdr,'P2ROW')
case effport of
  'A':  begin
           r1col = p1row+19
           r2col = p2row+19
           r1row = 1044-p2col
           r2row = 1044-p1col
        end
  'B':  begin
           r1col = p1row+19
           r2col = p2row+19
           r1row = p1col-19
           r2row = p2col-19
        end
  'C':  begin
           r1col = 1044-p2row
           r2col = 1044-p1row
           r1row = 1044-p2col
           r2row = 1044-p1col
        end
  'D':  begin
           r1col = 1044-p2row
           r2col = 1044-p1row
           r1row = p1col-19
           r2row = p2col-19
        end
  else: begin
           r1col = p1col
           r2col = p2col
           r1row = p1row
           r2row = p2row
        end
endcase
if (r1col lt 1) then begin
   r2col = r2col+abs(r1col)+1
   r1col = 1
endif
if (r1row lt 1) then begin
   r2row = r2row+abs(r1row)+1
   r1row = 1
endif
fxaddpar,hdr,'R1COL',r1col
fxaddpar,hdr,'R1ROW',r1row
fxaddpar,hdr,'R2COL',r2col
fxaddpar,hdr,'R2ROW',r2row
fxaddpar,hdr,'EFFPORT',effport
return
end
