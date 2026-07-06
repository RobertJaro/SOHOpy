function solar_north_up,img,telescope
;+
; NAME:				SOLAR_NORTH_UP
;
; PURPOSE:			Rotates the image to put the solar north at the
;				top of the image.
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		Result = SOLAR_NORTH_UP (Img, Tel)
;
; INPUTS:			Img = Image array, corrected for readout port
;				telescope = int representing telescope (0,1,2,3) -or-
;					string representing telescope
; OPTIONAL INPUTS:		None
;	
; KEYWORD PARAMETERS:		None
;
; OUTPUTS:			Result = Image array, corrected for telescope 
;					 orientation
;
; OPTIONAL OUTPUTS:		None
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;   assumes that the images are already rectified so that the readout port 
;   effect has been taken care of
;   To visualize the images properly, the parameter, !order, should be set =1
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:		Written, RA Howard, NRL
;   VERSION 1  rah 3 Nov 1995
;   VERSION 2  rah 2 Jan 1996  EIT changed from 1 to 0
;  	nbr, 3 Jan 2002 - Can use string camera as input
;
;       @(#)solar_north_up.pro	1.2 01/03/02 LASCO IDL LIBRARY
;
;-
;
IF datatype(telescope) EQ 'STR' THEN CASE TRIM(STRUPCASE(telescope)) of
  'C1': telescope = 0
  'C2': telescope = 1
  'C3': telescope = 2
  'EIT': telescope = 3
  'C4': telescope = 3
ENDCASE
;help,telescope
case telescope of
  0:  dir= 0		; C1 needs no rotation
  1:  dir=-1		; C2 needs -90 rotation
  2:  dir=-1		; C3 needs -90 rotation
  3:  dir= 0		; EIT needs no rotation
else: dir= 0
endcase
if (dir eq 0) then return,img else return,rotate(img,dir)
end
