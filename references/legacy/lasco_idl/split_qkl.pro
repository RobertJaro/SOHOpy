;+
; NAME:		SPLIT_QKL
;
; PURPOSE:	Pre-process QKL files to split them up if they have gaps
;
; CATEGORY:	REDUCTION
;
; CALLING SEQUENCE:	SPLIT_QKL, yymmdd
;
; INPUTS:	date = Date to be processed
;
; OPTIONAL INPUTS:	None
;
; KEYWORD PARAMETERS:	None
;
; OUTPUTS:	None
;
; OPTIONAL OUTPUTS:	None
;
; COMMON BLOCKS:	UNPACK_SCIENCE
;
; PROCEDURE:
;	A QKL file is broken into smaller files, for which the times in consecutive
;	packets differ by no more than 30 secs.
;
; MODIFICATION HISTORY:
; 	WRITTEN     4 Nov 1998 by Nathan Rich, Interferometrics/NRL
;	12 Nov 1998	NBR	change qkl allowed gap to 30 sec
;	30 Nov 1998	RAH	Check for undefined input date.
;	020312		Jake	Added /SH to SPAWN
;
; SCCS variables for IDL use
; 
; @(#)split_qkl.pro	1.7 03/12/02 :NRL Solar Physics
;
;
;-
;
pro SPLIT_QKL, date

common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
;ver = 'V11  12 Dec 1996'
IF (n_params(0) EQ 0) THEN dte='' $		; rah 11/30/98
   ELSE IF (DATATYPE(date) EQ 'UND')  THEN dte='' ELSE dte=date

;openw,lulog,'test.log',/get_lun
ff = findfile('ELASC*'+dte+'*.QKL')
s  = size(ff)
if (s(0) eq 0) then begin
   print,'No QKL files found'
   printf,lulog,'No QKL files found'
   return
endif ELSE print,'Found ',s(1),' QKL files'

;** SORT BY TIME IN FILENAME
pos = STRPOS(ff, 'ELASC')
temp = STRMID(ff, pos(0)+7, 20-7)	;** modified 12/12/96 SEP 
					;   sort H & L packets by time
ind = SORT(temp)
ff = ff(ind)
last_QKL_tai = 0D

printf,lulog,'Number of QKL Files Found = ',s(1)
first = 1

for i=0,s(1)-1 do begin	;** LOOP OVER ALL FILES

   printf,lulog

   sc = READ_TM_PACKET(ff(i), /SILENT)
   sz = SIZE(sc)
   last = sz(2) - 1

   all_tai = OBT2TAI(sc(6:6+5,*))
   last_tai = 0
   new = 0
   same = 'n'
   jj = long(1)

   WHILE jj LE last DO BEGIN
	diff = all_tai(jj)-all_tai(jj-1)
	IF diff GT 30 or (jj EQ last and new NE 0) THEN BEGIN
		startime=TAI2UTC(OBT2TAI(sc(6:6+5,last_tai)), /ECS)
		print, '    first packet TAI:  ', startime, '  SEQ#: ', $
            	  LONG(sc(2,last_tai) * 2L^8 + sc(3,last_tai)) AND '3FFF'XL
		endtime= TAI2UTC(OBT2TAI(sc(6:6+5,jj-1)), /ECS)
   		print, '    last  packet TAI:  ',endtime, '  SEQ#: ', $
            	  LONG(sc(2,jj-1) * 2L^8 + sc(3,jj-1)) AND '3FFF'XL
		fn='ELASCL_'+ecs2ddis(startime)+'.QKL'
		datatype='ARCHIVED TAPE RECORDER DUMP TELEMETRY'
		num_pack=strtrim(string(jj-last_tai))
		get_utc,now,/ecs
		date_cre=now
		comment='Made by SPLIT_QKL.pro, NRL.'
		OPENW,out,fn,/get_lun
		printf,out,'DATATYPE=       ',datatype
		printf,out,'FILENAME=       ',fn
		printf,out,'APID=           ','88ac'
		printf,out,'DATE_CRE=       ',date_cre
		printf,out,'NUM_PACK=       ',num_pack
		printf,out,'STARTIME=       ',startime
		printf,out,'ENDTIME=        ',endtime
		printf,out,'COMMENT=        ',comment
		printf,out,'END'
		writeu,out,sc(*,last_tai:jj)
		close,out
		free_lun,out
	
   		printf,lulog, '    Writing new file ', fn, '  SEQ#: ', $
		  LONG(sc(2,last_tai) * 2L^8 + sc(3,last_tai)) AND '3FFF'XL
   		printf,lulog, '    last  packet TAI:  ', endtime, '  SEQ#: ', $
		  LONG(sc(2,last) * 2L^8 + sc(3,last)) AND '3FFF'XL
		last_tai=jj
		new = 1
		IF fn EQ ff(i) THEN same = 'y'
	ENDIF
	jj = jj+1
   ENDWHILE
   IF new NE 0 and same NE 'y' THEN BEGIN
	print, 'Removing ',ff(i)
   	printf,lulog, 'Removing ',ff(i)
   	spawn,'/bin/rm -fr '+ff(i), /SH
	new = 0
   ENDIF

endfor	;** END LOOPING OVER ALL FILES


get_utc,dte,/ecs
printf,lulog,'SPLIT_QKL completed at '+dte
;close,lulog
;free_lun,lulog

END
