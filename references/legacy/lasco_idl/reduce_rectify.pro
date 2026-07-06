function reduce_rectify,a,h
;
;+
; NAME:			REDUCE_RECTIFY
; PURPOSE:
;	function procedure to rectify the CCD image to account
;	for the port that the image has been read out
; 
; CATEGORY:
; CALLING SEQUENCE:	x = REDUCE_RECTIFY (a,h)
;
; INPUTS:		a = input image
;			h = FITS header
;
; OUTPUTS:		x = rectified image
;			h will be modified to reflect the rectification
;
; OPTIONAL OUTPUT PARAMETERS:
; COMMON BLOCKS:
; SIDE EFFECTS:
; RESTRICTIONS:
; PROCEDURE:
;	rectifies an image taken with the CCD camera to be as
;	though the observer were looking through the CCD.
;	The telescope is assumed to be an erecting one.
;
;	If !order is 0, the image will be displayed on the screen
;	properly.
; MODIFICATION HISTORY:
;
;	rah 3/16/93  revised to use idl built in function, rotate
;	rah 11/7/95  revised to accept readport as string or number
;	V4  rah 11/7/95  revised to accept header as FITS header
;	V5  rah 1/11/96  revised to rectify image for !order=0, origin at
;                        bottom left of image
;	V6  rah 1/14/96  EIT doesn't need a rotation, it is an inverting 
;			 telescope
;	V7  rah 1/30/96  Correction to C1
;	V8  rah 3/6/96   Correction to C1 orientation and "R" coordinates
;
; SCCS variables for IDL use
; 
;
;	@(#)reduce_rectify.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
;
s = size(a)
readport = strtrim(fxpar(h,'READPORT'),2)
detector = strtrim(fxpar(h,'DETECTOR'),2)
;
;   effport takes into account the rotation for the orientation
;   of the camera on the spacecraft, to put the solar north "up"
;
;   C1 needs completely different processing
;   EIT do not need any rotation for spacecraft orientation
;   C2 and C3 do not need any additional rotation
;
if (detector eq 'C1') then begin
   case readport of
      'A':   begin
                b=rotate(a,5)
                rect = 'TRUE'
                r1row=fxpar(h,'P1ROW')
                r2row=fxpar(h,'P2ROW')
                r1col=1063-fxpar(h,'P2COL')
                r2col=1063-fxpar(h,'P1COL')
             end
      'B':   begin
	        b=a
                rect = 'TRUE'
                r1row=fxpar(h,'P1ROW')
                r2row=fxpar(h,'P2ROW')
                r1col=fxpar(h,'P1COL')
                r2col=fxpar(h,'P2COL')
             end
      'C':   begin
                b=rotate(a,2)
                rect = 'TRUE'
                r1row=1025-fxpar(h,'P2ROW')
                r2row=1025-fxpar(h,'P1ROW')
                r1col=1063-fxpar(h,'P2COL')
                r2col=1063-fxpar(h,'P1COL')
             end
      'D':   begin
                b=rotate(a,7)
                rect = 'TRUE'
                r1row=1025-fxpar(h,'P2ROW')
                r2row=1025-fxpar(h,'P1ROW')
                r1col=fxpar(h,'P1COL')
                r2col=fxpar(h,'P2COL')
             end
      else:  begin
                rect='FALSE'
	        print,'Read port for image ',fxpar(h,'FILENAME'),   $
	     	 ' not legal value: "',readport,'"'
	        b = -1
                r1row=fxpar(h,'P1ROW')
                r2row=fxpar(h,'P2ROW')
                r1col=fxpar(h,'P1COL')
                r2col=fxpar(h,'P2COL')
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
   effport = 'B'
   fxaddpar,h,'R1COL',r1col
   fxaddpar,h,'R2COL',r2col
   fxaddpar,h,'R1ROW',r1row
   fxaddpar,h,'R2ROW',r2row
   fxaddpar,h,'EFFPORT',effport
endif else begin
effport = readport
reduce_rectify_p1p2,effport,h
case effport of
     'A': begin
	      b=rotate(a,3)	; rotate 270 (order=1 & 0)
	      temp = fxpar(h,'NAXIS1')	; interchange size of axes
	      fxaddpar,h,'NAXIS1',fxpar(h,'NAXIS2')
	      fxaddpar,h,'NAXIS2',temp
              rect = 'TRUE'
	  end
     'B': begin
              b=rotate(a,4)	; transpose  (order=0)
;	      b=rotate(a,6)	; transpose, rotate 180 (order=1)
	      temp = fxpar(h,'NAXIS1')	; interchange size of axes
	      fxaddpar,h,'NAXIS1',fxpar(h,'NAXIS2')
	      fxaddpar,h,'NAXIS2',temp
              rect = 'TRUE'
          end
     'C':  begin
	      b=rotate(a,6)	; transpose, rotate 180 (order=0)
;              b=rotate(a,4)	; transpose  (order=1)
	      temp = fxpar(h,'NAXIS1')	; interchange size of axes
	      fxaddpar,h,'NAXIS1',fxpar(h,'NAXIS2')
	      fxaddpar,h,'NAXIS2',temp
              rect = 'TRUE'
           end
     'D':  begin
              b=rotate(a,1)	; rotate 90 (order=1 & 0)
	      temp = fxpar(h,'NAXIS1')	; interchange size of axes
	      fxaddpar,h,'NAXIS1',fxpar(h,'NAXIS2')
	      fxaddpar,h,'NAXIS2',temp
              rect = 'TRUE'
           end
  else:	begin
	   print,'Read port for image ',fxpar(h,'FILENAME'),   $
		 ' not legal value: "',readport,'"'
	   b = -1
           rect = 'FALSE'
	end
endcase
endelse
fxaddpar,h,'RECTIFY',rect
return,b
end
