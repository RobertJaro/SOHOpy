PRO GET_MISSING_PCKTS,tai0,tai1,result, USE_CTR=use_ctr
;
;+
; NAME:
;	GET_MISSING_PCKTS
;
; PURPOSE:
;	Searches index of REL/QKL files between times tai0 and tai1 (exclusive).
;	If there are any packets in this interval, return them in
;	'result'. Otherwise return 0.
;
; CATEGORY:
;	LASCO PACKETS
;
; INPUTS:
;	tai0	LONG	Tai time (seconds) of last packet before gap
;	tai1	LONG	Tai time of first packet after gap
;  
; Keywords:
;	USE_CTR		If set, use packet counter instead of time to fill gap
;			(necessary when LOBT clock is reset backwards). Set equal to
;			[lastctr,ctr] (counter before and after gap)
;
; OUTPUTS:
;       Result:  BYTARR(packet length, number of packets)
;
; SIDE EFFECTS:
;
;
; PROCEDURE:
;
;
; MODIFICATION HISTORY:
; 	Written by:	N.B. Rich, Jan. 2000
;	NBRich	Apr 2000 - Account for case where files(ind0-1) includes files(ind0);
;			   Add USE_CTR keyword
;	jake			-	changed /net/gorgon/gg3/ql/ to GETENV('QL_IMG')
;	03.10.08, nbr - Changed input index.txt name/location
;   	12.27.18, nbr - Return if index.txt not found
;
;	%H% %W% LASCO IDL LIBRARY
;-
;
;

COMMON ql_packets, starts,ends,files,scq, taisq,lastfile
;stop
IF datatype(starts) EQ 'UND' THEN BEGIN
   flist = readlist(GETENV_SLASH('QL_IMG')+'catalogs/ecs_index.txt')
   n=n_elements(flist) 
    IF (n EQ 1) THEN BEGIN
    	message,'ecs_index.txt not found.',/info
	wait,3
	return
    ENDIF
   flist=flist(2:n-1)
   starts = double(strmid(flist,0,22))
   ends = double(strmid(flist,24,22))
   files = strmid(flist,48,60)
   lastfile=''
ENDIF
result=0
n=n_elements(starts)+2

ind0 = find_closest(tai0,starts,/less)
;help,ind0
IF tai1 LT starts[0] or tai0 GT ends[n-3] THEN BEGIN
    result=-1
    print,'No files available for gap period; returning.'
    return
ENDIF
IF tai0 GE ends(ind0>0) THEN BEGIN
	help,ind0
	print,'Making ',files(ind0),' INVALID.'
	files(ind0)='INVALID'
	IF tai0 LT ends(ind0-1) THEN ind0=ind0-1 ELSE ind0=ind0+1
	help,ind0
	; in case files(ind0-1) is bigger than files(ind0)
ENDIF

n_ends=n_elements(ends)
IF ind0 GE n_ends THEN BEGIN
    PRINT,'%%% ERROR %%%
    PRINT,'%%% ERROR %%%
    PRINT,'%%% ERROR %%%
    PRINT,'About to subscript an array with a value that is too large.'
    PRINT,'You should fix this before continuing...'
    stop
ENDIF

;stop
IF tai0 LT ends(ind0) THEN $		; tai0 is between start and end of files(ind0)
   REPEAT BEGIN
	IF files(ind0) NE lastfile THEN BEGIN
   	   scq =read_tm_packet(files(ind0))
   	   taisq = obt2tai(scq(6:11,*))
	ENDIF
	lastfile = files(ind0)
	;help,lastfile
	szsc = size(scq)
	pktlen = szsc(1)
	nsc = szsc(2)
   	;indst = find_closest(tai0,taisq)		;,/less)
   	;indst = indst + 1			; Result starts with next packet (indst + 1)
   	;inden = find_closest(tai1,taisq)		;,/less)
	;IF inden NE nsc-1 THEN inden = inden - 1
	IF keyword_set(USE_CTR) THEN BEGIN
	   print,'Using packet counters for gap.'
	   ctr0 = use_ctr(0)
	   ctr1 = use_ctr(1)
	   ctrs = (scq(2,*) * 256L + scq(3,*)) and '3fff'XL
	   ctr0ind = WHERE( ctrs EQ ctr0,ctr0exist)
	   ctr1ind = WHERE( ctrs EQ ctr1,ctr1exist)
	   IF ctr0exist+ctr1exist LT 2 THEN $
	  	goodpk = WHERE( ctrs GT ctr0 and ctrs LT ctr1,ngdp) ELSE BEGIN $
		   ngdp = ctr1ind(0) - ctr0ind(0) -1
		   IF ngdp GT 0 THEN BEGIN
		   	numbers=lindgen(nsc)
		   	goodpk=numbers(ctr0ind(0)+1:ctr1ind(0)-1)
		   ENDIF
	  	ENDELSE
	ENDIF ELSE BEGIN
	   tai0ind = WHERE( taisq EQ tai0,tai0exist)
	   tai1ind = WHERE( taisq EQ tai1,tai1exist)
	   IF NOT(tai0exist and tai1exist) THEN $	;010125 nbr
	  	goodpk = WHERE( taisq GT tai0 and taisq LT tai1,ngdp) ELSE BEGIN
		   ngdp = tai1ind(0) - tai0ind(0) -1
		   IF ngdp GT 0 THEN BEGIN
		   	numbers=lindgen(nsc)
		   	goodpk=numbers(tai0ind(0)+1:tai1ind(0)-1)
		   ENDIF
	  	ENDELSE
	ENDELSE

	IF ngdp LE 0 THEN BEGIN				;010125 nbr
;	   print,'Packets not found in QL; returning.'
	   return
	ENDIF
	sz = size(result)
	IF sz(0) EQ 0 THEN rsiz = 0 ELSE rsiz = sz(2)
	newresult = bytarr(pktlen,rsiz+ngdp)			; must concatenate a 2-d array
	newresult(0,0)=result					; if gap continues to next 
	newresult(*,rsiz:rsiz+ngdp-1) = scq(*,goodpk)		; QKL/REL file
   	result = newresult					;
	ind0=ind0+1
	IF files(ind0) EQ 'INVALID' THEN ind0=ind0+1
;stop

   ENDREP UNTIL goodpk(ngdp-1) LT nsc-1		; in case gap continues to next QKL/REL file

END
