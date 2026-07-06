pro check_obesumerror,a,hdr,FIXIT=FIXIT
;
;+
; NAME:
;	CHECK_OBESUMERROR
;
; PURPOSE:
;	Checks for OBE error when doing LEB summing
;
; CATEGORY:
;	Reduce
;
; CALLING SEQUENCE:
;	CHECK_OBESUMERROR,A,Hdr
;
; INPUTS:
;	A:	Image to be checked
;	Hdr:	FITS Header 
;
; KEYWORD PARAMETERS:
;	FIXIT:	If present, fixes the LEBXSUM and LEBYSUM keywords
;
; PROCEDURE:
;	An error was discovered in OBE beginning 6 March 1997.
;	It started after sending a command to sum difference in EIT images.
; 	The result was that the LEB summing parameter in the header was not
;  	being set to the proper value.  It always read 1, even though the
;  	summing was performed.
;
; MODIFICATION HISTORY:
;	RA Howard, NRL, 24 March 97
;
;	@(#)check_obesumerror.pro	1.1 05/14/97 LASCO IDL LIBRARY
;-
;
GET_UTC,today,/date_only,/ecs
h = LASCO_FITSHDR2STRUCT(hdr)
s=SIZE(a)
IF (s(0) EQ 2)  THEN BEGIN
   nx=s(1)
   ny=s(2)
   ncol=h.r2col-h.r1col+1
   nrow=h.r2row-h.r1row+1
   xsum = h.lebxsum*(h.sumcol>1)
   ysum = h.lebysum*(h.sumrow>1)
   ncolcor = ncol/xsum
   nrowcor = nrow/ysum
   IF (ncolcor ne nx)  or (nrowcor ne ny)  THEN BEGIN
      facx = ncolcor/nx
      facy = nrowcor/ny
      PRINT,h.detector,h.filename,nx,ny,facx,facy,ncolcor,nrowcor,h.comprssn, $
            format='(a3,2x,a14,6i5,2x,a10)'
      IF KEYWORD_SET(FIXIT)  THEN BEGIN
         FXADDPAR,hdr,'LEBXSUM',facx,'Fixed '+today
         FXADDPAR,hdr,'LEBYSUM',facy,'Fixed '+today
      ENDIF
   ENDIF
ENDIF
RETURN
END
