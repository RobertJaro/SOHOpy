pro MOVE_REDUCE_LOG,dte
;
;+
; NAME:
;	MOVE_REDUCE_LOG
;
; PURPOSE:
;	This procedure moves the log and db files produced by the pipeline 
;	processing from the directory pointed to by $REDUCE_LOG into 
;	subdirectories by process date.
;
; CATEGORY:
;	REDUCE
;
; CALLING SEQUENCE:
;
;	MOVE_REDUCE_LOG
;
; OPTIONAL INPUTS:
;	Dte:	String giving the date to be processed in the format YYMMDD.
;		The default is to process all files.
;
; OUTPUTS:
;	None
;
; SIDE EFFECTS:
;	Moves files into a subdirectory
;
; MODIFICATION HISTORY:
; 	Written by:	R.A. Howard, NRL, 25 Apr 1996
;	2002.02.01, NBR - Add /SH to SPAWN
;
;	@(#)move_reduce_log.pro	1.2 02/01/02 LASCO IDL LIBRARY
;-
cd,getenv('REDUCE_LOG')
np = N_PARAMS()
REPEAT BEGIN
   f = FINDFILE('red_*')
   sz = SIZE(f)
   IF (sz(0) EQ 0) THEN BEGIN
      PRINT,'No log or db files found, returning'
      RETURN
   ENDIF
   d = strmid(f(0),4,6)
   IF ( ((np eq 1) AND (dte eq d)) OR (np EQ 0)) THEN BEGIN
      yesorno = ''
      READ,'Do you want to move '+d+' files?  ',yesorno
      IF (STRUPCASE(yesorno) NE 'Y')    THEN RETURN
      PRINT,'Moving red_'+d+'* to subdirectory'
      SPAWN,'mkdir '+d, /SH
      SPAWN,'mv red_'+d+'* '+d, /SH
   ENDIF
ENDREP UNTIL (sz(0) EQ 0)
RETURN
END
