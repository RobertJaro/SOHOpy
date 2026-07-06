pro write_closed,nfiles
;+
; NAME:
;	WRITE_CLOSED
;
; PURPOSE:
;	This procedure writes the name of the latest *.img file located in 
;	$LEB_IMG into closed_img_file2.  This file is used by REDUCE_MAIN.
;
; CATEGORY:
;	LASCO DATA REDUCTION
;
; CALLING SEQUENCE:
;	WRITE_CLOSED
;
; OPTIONAL INPUTS:
;	Nfiles:	If this parameter is present, the file name of the nfile-th
;		file will be written.  Otherwise the default is to write the
;		name of the latest .img file
;		
; OUTPUTS:
;	This procedure creates the file $LEB_IMG/closed_img_file2
;
; EXAMPLE:
;	Write the file name of the latest file in $LEB_IMG:
;
;		WRITE_CLOSED
;
;	Write the file name of the 2nd file in $LEB_IMG:
;
;		WRITE_CLOSED,2
;
; MODIFICATION HISTORY:
; 	Written by:	RA Howard, NRL, 23 Dec 1995
;	Version 2  RAH  10 Apr 1996  Added parameter to write nfile/th name
;
;	@(#)write_closed.pro	1.2 21 Apr 1996 LASCO IDL LIBRARY
;-
;
leb_img = getenv ('LEB_IMG')
cd,leb_img
ff = findfile('*.img*')
sff = size(ff)
if (sff(0) gt 0) then begin
   openw,lu,'closed_img_file2',/get_lun
   IF (n_params() EQ 0)  THEN printf,lu,ff(sff(1)-1) $
                         ELSE printf,lu,ff(nfiles-1)
   close,lu
   free_lun,lu
endif
return
end

