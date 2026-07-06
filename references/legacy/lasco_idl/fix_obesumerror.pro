pro fix_obesumerror,date,FIXIT=FIXIT,QL=QL,LZ=LZ
;
;+
; NAME:
;	FIX_OBESUMERROR
;
; PURPOSE:
;	Fix an OBE error encountered when doing LEB summing
;
; CATEGORY:
;	REDUCE
;
; CALLING SEQUENCE:
;	FIX_OBESUMERRROR
;
; OPTIONAL INPUTS:
;	Date:	If present processes the date specified.  Otherwise processes dates
;		6 March 1997 -20 March 1997
;	
; KEYWORD PARAMETERS:
;	QL:	If present goes to the quick-look Directory, the default is QL
;	LZ:	If present goes to the Level-0 Directory
;	FIXIT:	If specified then writes the FITS file out, with LEBXSUM and LEBYSUM corrected.
;
; PROCEDURE:
;	An error was discovered in OBE beginning 6 March 1997 through xx March.
;	It started after sending a command to sum difference in EIT images.  
;	The result was that the LEB summing parameter in the header was not 
;	being set to the proper value.  It always read 1, even though the 
;	summing was performed.
;
;	This routine goes out to the date directory specified and reads in all of the FITS
;	files one by one and then calls CHECK_OBESUMERROR to see if the error has
;	occurred.  
;
; EXAMPLE:
;	To see if the files on 970307 have the problem, use the following command:
;		FIX_OBESUMERROR,'970307',/QL
;	To correct the file
;		FIX_OBESUMERROR,'970307',/QL,/FIXIT
;	To correct all the files between 6 Mar and 20 Mar
;		FIX_OBESUMERROR,/QL,/FIXIT
;
; MODIFICATION HISTORY:
;	RA Howard, NRL, 23 March 97
;
;	@(#)fix_obesumerror.pro	1.1 05/14/97 LASCO IDL LIBRARY
;-

imgdir=GETENV('QL_IMG')		; default
IF KEYWORD_SET(QL) THEN imgdir=GETENV('QL_IMG')
IF KEYWORD_SET(LZ) THEN imgdir=GETENV('LZ_IMG')
CD,imgdir+'/level_05',current=cdtop
np = N_PARAMS()
IF (np EQ 1)   THEN nd=0 ELSE nd=13
FOR kd=0,nd DO BEGIN
    CASE kd OF
        0:  dte='970306'
        1:  dte='970307'
        2:  dte='970308'
        3:  dte='970309'
        4:  dte='970310'
        5:  dte='970311'
        6:  dte='970312'
        7:  dte='970313'
        8:  dte='970314'
        9:  dte='970315'
        10: dte='970316'
        11: dte='970317'
        12: dte='970318'
        13: dte='970319'
    ENDCASE
    IF (np EQ 1)   THEN dte=date
    CD,dte
    ;FOR i=1,4 DO BEGIN
    FOR i=2,3 DO BEGIN	; only C2 and C3 are affected by this error
        tel = 'c'+STRING(i,format='(i1)')
        f=FINDFILE(tel+'/*.fts')
        nf = N_ELEMENTS(f)
        PRINT,'Processing',nf,' files in '+dte+'/'+tel
        FOR j=0,nf-1 DO BEGIN
            a=READFITS(f(j),hdr,/silent)
            CHECK_OBESUMERROR,a,hdr
            IF KEYWORD_SET(FIXIT)  THEN BEGIN
               WRITEFITS,f(j),a,hdr
            ENDIF
        ENDFOR
    ENDFOR
    CD,'..'
ENDFOR
CD,cdtop
RETURN
END
