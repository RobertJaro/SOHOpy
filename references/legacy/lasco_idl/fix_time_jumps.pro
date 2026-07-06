PRO FIX_TIME_JUMPS,fname,outname
;
;+
; NAME:
;	FIX_TIME_JUMP
;
; PURPOSE:
;	This procedure reads a file from CDROM and puts the packets in
;	order of the packets. If there is a gap, attempts to fill in 
;	with QL packets using GET_MISSING_PCKTS.
;
; CATEGORY:
;	LASCO PACKETS
;
; CALLING SEQUENCE:
;	FIX_TIME_JUMPS,fname
;
; INPUTS:
;	Fname:	Name of file with packets in it
;
; OUTPUTS:
;       Outname:  Returns the temporary output file name
;
; SIDE EFFECTS:
;	A file with same name as fname and at least as large is generated in $TMOUT
;
; PROCEDURE:
;	The input files must reside in the current working directory.
;	It then finds missing or out of order packets in science stream by 
;	looking at the packet counter, which should increment by one.
;
; MODIFICATION HISTORY:
; 	Written by:	R.A. Howard, NRL, 3 Aug 1996
;	N. Rich 1/31/97	added tm_files variable
;	RAH     2/04/97	Corrected high rate packet sizes
;	N. Rich 3/29/97 added outdir variable
;	N. Rich 1/2000	Implement GET_MISSING_PCKTS
;	N. Rich 2/2000	Add ctrmin2 check
;	N. Rich 4/2000	Fix case where badpckts are in middle; Use packet counter for gap
;			if backwards clock-reset detected
;		4/21/00  Print packet length of gaps and result (LZ 000207 ff.)
;	n. rich 6/19/00  Change how it recognizes packet out of order, and previous packet
;			 out of order
;	n. rich 6/20/00  Start logging out-of-order packets
;	jake 01/01/01	Up'd limit of numexp to 500000 to help 03240101.d01
;	n.rich, 03.10.09 - Allow path in input filename
;       k.battams 9/14/05 - change loop counter @ line 287 to 0L because 52240101.d01 
;                           had "Missing 9551 pkts; returned 58645 pkts", which crashed the
;                           routine.
;   	n.rich, 12/8/08 - Need to add newpkts to wraparound check in line 372 
;   	n.rich, 5/6/09  - Change numexp (num pkts) from 500000 to 700000 
;   	n.rich, 1/28/10 - added datetime to log outputs
;   	n.rich, 3/5/13	- change counter[0]; check for time going backwards; 
;   	    	    	    plot output vs. tai, and highlight new packets
;   	n.rich, 9/ 9/14 - sort packets by time in certain cases
;   	n.rich, 12/5/16 - DO NOT sort by time. Instead, log all time-order issues.
;   	n.rich, 5/23/17 - Stop if excessive out of order packets and do diagnostic plots
;   	n.rich, 6/ 7/17 - Save plots
;
;	%W% %H%  LASCO IDL LIBRARY
;-

common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename

tm_files = getenv('TMFILES')
cd,tm_files,curr=old_dir
outdir = getenv_slash('TMOUT')
break_file,fname,dl,dir,root,ext
outname = outdir+root+ext
OPENW,luout,outname,/get_lun
fn = fname
npkts = 0
OPENR,lu,fn,/get_lun
start_loc=48
;
;  Get the packet length
;
point_lun,lu,start_loc
;data = intarr(3)
;readu,lu,data
;pck_len = data(2) AND 'ffff'XL
;pck_len = pck_len+7
;
;  transfer the file header
;
a=ASSOC(lu,bytarr(start_loc))
aa = ASSOC (luout,bytarr(start_loc))
aa(0) = a(0)
;
;  associate the correct packet lengths
;
;a=ASSOC(lu,bytarr(pck_len),start_loc)
scp = READ_TM_PACKET(fn)		; Need to combine packets from two sources
help,scp
sz = size(scp)
numpckts = sz(2)
pck_len = sz(1)
numexp = 700000L		; A guess.... ; A new guess
;numexp = numpckts+15000		; 93120101.d01 had 243005 packets; 93130101 had 415022 packets
;
;    Param   Start(B)	Bit 	Leng(Bit)
;    ======= ===    	=   	====
;    ApiD    0	    	0   	2*8
;    PktCtr  2	    	2   	14
;    OBT     6	    	0   	6*8
;    PktLen  12	    	0   	1*8	    (2-byte words)
;    PktType 13	    	0   	1*8
;    Data    16	    	0   	PktLen*2*8
;    linesyn 16	    	0   	1
;    clrmode 16	    	1   	1
;    polar   16	    	2   	3
;    filter  16	    	5   	3
;    shutter 17	    	0   	1
;    lamp    17	    	2   	2
;    side    17	    	4   	1
;    port    17	    	4   	2
;    camera  17	    	6   	2
;    imgctr  18	    	0   	11
;    Exthdr  62	    	2   	16?

    
print,'Computing tais...'
tais = obt2tai(scp[6:11,*])
; get current day
noon=median(tais)
nutc=tai2utc(noon)
nutc.time=0

print,'Computing pktctr array.'
pktctr=mask(word2dec(scp[2:3,*],/silent),0,14)

; good is between 00:00-100 sec and 23:59+100 sec
tais0 = utc2tai(nutc)-100   ;tais(0)
goodtais = where(tais GE tais0 and tais LT (tais0+86600),n_srtd1, complement=badts)

date_str = utc2str(tai2utc(tais[n_srtd1/2]),/ecs)
date=strmid(date_str,0,10)

msg=date+' ('+fn+'): Number of packets [actual, expected]:'+string(numpckts)+string(numexp)
print,msg
printf,lulog,msg

s = sort(tais[goodtais])
; compute location of out order times.
diffs=s-shift(s,1)
diffs[0]=1

; compute time differences between subsequent packets
taid=tais[goodtais]-shift(tais[goodtais],1)
taid[0]=taid[1]

; compute missing packet counters
difc=pktctr[goodtais]-shift(pktctr[goodtais],1)
difc[0]=1
difc[n_srtd1-1]=1
wm=where(difc ne 1 and difc ne -16383,nwm)
missingpcnts=0

;plot,tais-tais0-100,title='Packet times',yrang=[-100,86500]
plot,diffs-1,ytitle='Number of packets out of order',charsize=1.5, title=date+' ('+fn+'): Packets Out of Time Order', $
xtitle='Packet Index', yrange=[0,max(taid)]
oplot,taid,color=2
xyouts,0.5,0.9,'Difference from previous packet (seconds)',charsize=1.5,color=2, alignment=0.5, /normal
IF (nwm GT 0) THEN BEGIN
    oplot,wm,difc[wm],psym=2,color=4
    xyouts,0.5,0.85,'Missing packet counters',charsize=1.5,color=4,alignment=0.5,/normal
ENDIF

totdiff=total(abs(diffs[1:*]))
help,totdiff
maxmin,diffs[1:*]
wd=where(abs(diffs[2:n_srtd1-3]) gt 2,nwd)
;IF nwd GT 0 THEN $
;    for i=0,nwd-1 do xyouts,wd[i]+2,tais[wd[i]+2],trim(diffs[wd[i]+2]),/data,charsize=2, color=2
;IF totdiff GT 500 THEN BEGIN
;    print,'Sorting by time because of detected anomaly.???'
    wdif=wd-shift(wd,1)
    wdif[0]=1
    newbad=0
    wwd=where(wdif gt 2,nwwd)
    IF nwd GT 0 THEN BEGIN
    	IF (nwwd gt 0) THEN newbad=[newbad,wwd] 
    	FOR i=0,nwwd DO BEGIN
    	    pno=goodtais[wd[newbad[i]]+2]
	    msg=utc2str(tai2utc(tais[pno]),/ecs)+': packets out of time order at packet '+string(pno,'(i6)')
    	    print,msg
	    printf,lulog,msg
    	ENDFOR
    	print,''
    	msg=date+" ("+fn+"): Initial scan found packets out of order at "+string(nwwd+1,'(i4)')+" locations:"
     	print,msg
    	printf,lulog,msg
    ENDIF ELSE BEGIN
    	msg=date+" ("+fn+"): Initial scan found zero packets out of order."
    	print,msg
    ENDELSE
IF (nwm GT 0) THEN BEGIN
    missingpcnts=total(abs(difc[wm]))
    msg=date+" ("+fn+"): Initial scan found "+string(missingpcnts,'(i6)')+" missing packet counters at "+string(nwm,'(i6)')+" locations."
    print,msg
    printf,lulog,msg
ENDIF
    
    msg=date+" ("+fn+"): Largest time jump is "+trim(taid[where(abs(taid) eq max(abs(taid)))])+" seconds."
    print,msg
    print,''
    wait,60
    printf,lulog,msg
    x=ftvread(/png,filename=getenv_slash('REDUCE_LOG')+'unpack/'+fn, /noprompt)

;typ=scp[13,*]    
;h=where(typ eq 2)    
;wor2=word2dec(scp[18:19,*],/silent)
;imgctr=mask(wor2,5,11) 
;wor1=word2dec(scp[2:3,*],/silent) 
;pktctr=mask(wor1,0,14)
;tot=unwrapctr(pktctr)  

;    a[0,0] = temporary(scp[*,s])
;ENDIF ELSE $

a = BYTARR(pck_len,numexp)
a[0,0] = temporary(scp)

print,'Open aa...'
aa = ASSOC (luout,bytarr(pck_len),start_loc)
;
;  obtain the approximate number of
;  wrap arounds
;
q = fstat(lu)
;numpackets = q.size/pck_len
;counter=lonarr(long(1.1*numpackets))

print,'Create counter array....'
counter = lonarr(numexp)
ctr0all = counter
ctrall = counter
taiall = dblarr(numexp)
isnew  = bytarr(numexp)
badpckts = where(tais LT tais0 or tais GE (tais0+86500))
help,goodtais,badpckts
sec_missed = 0L
pckts_missed = 0L
;
;  Obtain the initial value of the packet counter
;
b = a(*,(goodtais(0)))

ctr = (b(2) * 256L + b(3)) AND '3fff'XL
counter[0] = ctr
 taiall[0] = tais0
;ctr = ctr-1
pno = 0L
wrap = 0L
numnew = 0L
lastctr = ctr - 1
ctrmin2 = ctr - 2
;
;  Loop over all packets in the file AFTER first packet (PNO=0)
;
;stop
misplaced_pkt=0
nmisplaced=0
notoneonly=1

help,ctr

IF missingpcnts GT 1000 THEN BEGIN
    psta=0L
    read,'Enter start pktcnt for zoom to 50000: ',psta
    window,2   
    w=lindgen(50000)+psta     
    plot,pktctr[goodtais[w]] 
    oplot,tais[goodtais[w]]-tais[w[0]] 
    wait,5 
    oplot,pktctr[goodtais[s[w]]]   ,color=2
    oplot,tais[goodtais[s[w]]]-tais[s[w[0]]],color=2
    oplot,pktctr[goodtais[w]] 

    window,1   
    ti=fn+' ('+date+'): PktSeqCnt and TAI'
    
    plot,tais[goodtais]-tais[0] , title=ti,xtitle='Packet',charsize=2
    oplot,pktctr[goodtais]  
    wait,5 
    oplot,pktctr[goodtais[s]]   , color=2
    oplot,tais[goodtais[s]]-tais[s[0]],color=2
    xyouts,10000,80000,'Unsorted',charsi=2
    xyouts,70000,80000,'Sorted by time',charsi=2,color=2
    stop
    
    ;a[*,goodtais]=a[*,s]        ; sort all packets by time
    
    ;a[*,goodtais[w]]=a[*,s[w]]  ; sort subset of packets by time
    
    note=''
    read,'Enter what you did for log (one line): ',note
    printf,lulog,date+" ("+fn+"): "+note

    IF (strpos(note,'goodtais') GT 0) THEN $
    x=ftvread(/png,filename=getenv_slash('REDUCE_LOG')+'unpack/'+fn+'sort')

    wset,0
ENDIF    

REPEAT BEGIN
    IF misplaced_pkt THEN prev_misplaced_pkt=1 ELSE prev_misplaced_pkt=0
    misplaced_pkt=0
    misplaced_pkt_wrap=0
    pkt_gap=0
    pno = pno+1
    ctrmin3=ctrmin2		; counter minus 3
    ctrmin2= lastctr		; counter minus 2
    lastctr = ctr
    ctr0 = lastctr+1
    ;b = a(pno)
    b = a[*,goodtais[[pno]]]
    ctr = (b[2] * 256L + b[3]) AND '3fff'XL
    tai = obt2tai(b[6:11])
    IF pno LT n_srtd1-2 THEN BEGIN
    	c = a[*,goodtais[[pno+1]]]
    	nextctr = (c[2] * 256L + c[3]) AND '3fff'XL
    	d = a[*,goodtais[pno+2]]
    	ctrpls2 = (d[2] * 256L + d[3]) AND '3fff'XL
    ENDIF ELSE nextctr = ctr+1
    ;b0 = a(pno-1)
    tai0= obt2tai(a[6:11,goodtais[[pno-1]]])
    tai1= tai   ; current packet
    taic= obt2tai(c[6:11])
    taid= obt2tai(d[6:11])
;
;  Test to see if the packet counter has wrapped around.
;  If the previous packet + 1 exceeds the maximum then it has wrapped.
;  Since the packet containing the greatest packet number might be missing
;  we need to check for a large decrease in the packet counter.
;  If the previous counter is greater than the current counter by
;  more than 55 then it has wrapped.
;
    IF (ctr0 GE '4000'XL) THEN BEGIN		; '4000'XL = 16384
            wrap = wrap+'4000'XL
	    date_str = utc2str(tai2utc(tai),/ecs)
	    msg=date_str+' Found a wrap at pno,ctr0='+string(pno)+string(ctr0)
            print,msg
	    printf,lulog,msg
    ENDIF ELSE $
    IF (ctr0 GT ctr AND ctr0 LT ('4000'XL)-1 AND ctrmin2 NE ctr-1) $
	or (ctr0 LT ctr-1) THEN BEGIN
	   IF nextctr EQ ctr0 or $
	      nextctr EQ ctr0+1 or $
	      ctr EQ ctrmin3 +1 or $
	      ctrpls2 EQ ctr0 THEN BEGIN		; for 1 or 2 packets out of order
		;IF pno GT 16384 THEN testarr = ctrall(pno-16382:pno-1) $
		;	ELSE testarr = ctrall(0:pno-1)
		;there = where(testarr EQ ctrmin2+1, nthere)
		nthere=1
		misplaced_pkt=1
		nmisplaced=nmisplaced+1
		IF ctr LT lastctr and ctr LT ctrmin3 THEN BEGIN
			misplaced_pkt_wrap='4000'XL
			
		ENDIF
	    	date_str = utc2str(tai2utc(obt2tai(b[6:11])),/ecs)
		msg=date_str+' Packet out of order at pno='+string(pno)
         	print,msg
         	printf,lulog,msg
		help,ctrmin2,lastctr,ctr0,ctr,nextctr
		printf,lulog,date_str+' Counters'+string(ctrmin2)+string(lastctr)+string(ctr0)+string(ctr)+string(nextctr)
stop
	   ENDIF 
	
	   IF NOT ( misplaced_pkt or prev_misplaced_pkt ) THEN BEGIN
;stop
;if pno eq 5422 then stop
		; ** Search for next valid packet
		IF tai1 LT tais0 OR tai1 GT tais0+87000L or taic EQ tai1 THEN BEGIN
		 print,'Bad packets at pno =',pno,' to'
    	    REPEAT BEGIN
		   IF badpckts(0) LT 0 THEN badpckts=pno $
			ELSE badpckts = [badpckts,pno]
      		;   counter(srtd1(pno))=ctr+wrap
		;   ctr0all(srtd1(pno))=ctr0
	 	;   ctrall(srtd1(pno))=ctr
		   counter[goodtais[pno]]=ctr+wrap
		   ctr0all[goodtais[pno]]=ctr0
		    ctrall[goodtais[pno]]=ctr
		    ;
		    ; in this case leave taiall zero for bad packet

		   pno = pno + 1
		   tai0 = tai1
	 	   b = a[*,goodtais[pno]]
     		   ctr = (b[2] * 256L + b[3]) AND '3fff'XL
		   tai1= obt2tai(b[6:11])
		   ;c = a(*,goodtais((pno+1)))
		   ;taic= obt2tai(c[6:11])
		   tai=tai1
    	    ENDREP UNTIL (tai1 GT tais0 and tai1 LT tais0+87000L and taic NE tai1) $
			or pno GE numpckts-1 
		 print,'pno =',pno
		ENDIF
			
		;IF pno GE numpckts-1 THEN tai1 = tais0+86400L

		pkt_gap = ctr-lastctr-1
	
		IF ctr-lastctr LT 0 or float(pkt_gap)/(tai1-tai0) LT 0.01 THEN  BEGIN
		   pkt_gap=pkt_gap+'4000'XL 
		   IF float(pkt_gap)/(tai1-tai0) GE 1000 THEN pkt_gap=0	
			; IF gt 1000, then probably out-of-order/bad packet
	   	ENDIF
		;IF taic EQ tai1 THEN pkt_gap=0
			; Bad packets in 03340101.d01 pno 5422ff

	    	date_str = utc2str(tai2utc(tai0),/ecs)
		print,'Found missing/bad packets at pno,ctr,time:  '
;stop
		print,pno,'  ',ctr,'  ',utc2str(tai2utc(tai0),/ecs)+' to '+utc2str(tai2utc(tai1),/ecs)
		printf,lulog,date_str+' Found missing/bad packets at pno,ctr '+trim(string(pno))+'  '+trim(string(ctr))+ ' until '+utc2str(tai2utc(tai1),/ecs)
		result=0
		;if tai1-tai0 GT 3000 then stop
		IF float(pkt_gap)/(tai1-tai0) GT 10 or tai1-tai0 LT 0 THEN BEGIN
			IF pno EQ 253597 or pno EQ 281175 THEN BEGIN
			   ctr=ctr+50	
				; ** special case for 00390101.d01
			   pno = pno-1+ctr-lastctr
			ENDIF
			use_ctr=[lastctr,ctr] 
			use_ctr_flag=1
			printf,lulog,'Using packet counters for gap.'
			print,'Using packet counters for gap.'
			help,use_ctr_flag
		ENDIF ELSE BEGIN
			use_ctr=0 
			use_ctr_flag=0
		ENDELSE

    	    	;
		; Try for missing packets if (difference between packets is LT 1 sec or there is a clock reset during a gap
		; nbr, 4/14/00: if use_ctr_flag, then there should be a clock reset backwards
		IF tai1-tai0 GT 1 or use_ctr_flag THEN BEGIN
			IF (use_ctr_flag) THEN wait,5
			GET_MISSING_PCKTS,tai0,tai1,result, USE_CTR=use_ctr 
		   	szr = size(result)
		   	IF result[0] LE 0 THEN totret=0 ELSE totret = szr(2)
			IF result[0] LT 0 THEN $
			mesg=date_str+' Missing GE '+trim(string(pkt_gap))+' pkts; NO QKL/REL FILES AVAILABLE' ELSE $
			mesg=date_str+' Missing GE '+trim(string(pkt_gap))+' pkts; returned '+trim(string(totret))+' pkts'
			print,mesg
			printf,lulog,mesg
		ENDIF ELSE BEGIN
			print,'Gap less than 1 second--continuing. Pkt_gap ='+string(pkt_gap)
			printf,lulog,date_str+' Gap less than 1 second--continuing. Pkt_gap ='+string(pkt_gap)
		ENDELSE
		; ** Ignore any gap less than 1 seconds
		sec_missed = sec_missed + (tai1-tai0)

;
; ** "result" is a BYTARR(numpkts,pck_len), where num_pckts is the number of missing packets 
;    found for the interval tai0 to tai1. If no packets are found, then result=0.
;
;stop
		ctra = lastctr
		IF result[0] GT 0 THEN BEGIN
		   help,result
		   ret_tais = obt2tai(result(6:11,*))
    	    	    help,nextctr,lastctr,ctrmin2
		   FOR i=0L,totret-1 DO BEGIN
			numnew = numnew+1
			ctr0a = ctra+1
			b = result(*,i)
      			ctra = (b(2) * 256L + b(3)) AND '3fff'XL
      			taia=obt2tai(b[6:11])
 	    	    	date_str = utc2str(tai2utc(taia),/ecs)
        		IF (ctr0a GE '4000'XL) THEN BEGIN
        	   	   wrap = wrap+'4000'XL
         		   print,'Found a wrap in retrieved QL packets at pno,numnew=',pno,numnew
         		   printf,lulog,date_str+' Found a wrap in retrieved QL packets at pno,cnumnew='+string(pno)+string(numnew)
 			   help,ctra,ctr0a,wrap
			   ;pkt_gap=pkt_gap+'4000'XL
        		ENDIF ELSE $
			IF (ctr0a GT ctra AND ctr0a LT ('4000'XL)-1 AND ctrmin2 NE ctra-1) THEN BEGIN
         		   wrap = wrap+'4000'XL
         		   print,'Found a wrap before retrieved QL packets at pno,ctr0a=',pno,ctr0a
         		   printf,lulog,date_str+' Found a wrap before retrieved QL packets at pno,ctr0a='+string(pno)+string(ctr0a)
			   ;pkt_gap=pkt_gap+'4000'XL
			ENDIF

			counter[numpckts-1+numnew] = ctra+wrap
			ctrall [numpckts-1+numnew] = ctra
			 taiall[numpckts-1+numnew] = taia
			  isnew[numpckts-1+numnew] =1
			;
			; ** puts packet number at the end of array 'counter' to match placement 
			;    of new packets at the end of array 'a'
			;
			a[*,numpckts-1+numnew] = b

		   ENDFOR
;stop
		ENDIF 
		ctr0a = ctra+1
		;IF (ctr0a GT (ctr+55)) THEN BEGIN
		;IF  ctr0a GT (ctr+110)  and pno LT n_srtd1-2 and ABS(ctra-ctrmin2) GT 2 THEN BEGIN
		IF (ctr-ctra LT 0 and pkt_gap GT 1) or float(pkt_gap)/(tai1-tai0) LT 0.01 THEN  BEGIN
         	   wrap = wrap+'4000'XL
         	   print,'Found a wrap in missing packets at pno,ctra=',pno,ctra
         	   printf,lulog,'Found a wrap in missing packets at pno,ctra=',pno,ctra
			help,ctr,ctra,ctr0,ctr0a,nextctr,lastctr,ctrmin2
		;   pkt_gap=pkt_gap+'4000'xl
       	  	ENDIF		
		pckts_missed=pckts_missed+pkt_gap

	   ENDIF else help,misplaced_pkt,prev_misplaced_pkt,misplaced_pkt_wrap		
	   ; NOT ( misplaced_pkt or prev_misplaced_pkt )
	   wait,5
    ENDIF ELSE $
;
; Log out-of-time-order packets
;
    IF abs(tai1-tai0) gt 1 and (notoneonly) THEN BEGIN
    	time0=utc2str(tai2utc(tai0),/ecs)
	IF abs(taic-tai0) LT 1 THEN BEGIN
	    notoneonly=0
	    msg=time0+': one packet is out of time order by '+trim(tai1-tai0)+' seconds at packet '+trim(pno)+'.'
	    print,msg
	ENDIF ELSE BEGIN
	    msg=time0+': time jump of '+string(tai1-tai0,'(F8.2)')+' seconds at packet '+string(pno,'(I6)')+'.'
    	    print,msg
	    nomwait=20
	    IF abs(tai1-tai0) GT 31 and abs(tai1-tai0) LT 33 THEN nomwait=3
	    wait,nomwait
	ENDELSE
	    
	printf,lulog,msg
	    
    ENDIF ELSE notoneonly=1
;
;  Add the current packet number, corrected for the counter wrap, to
;  the array of all packet numbers
;
        counter[goodtais[pno]]=ctr+wrap+misplaced_pkt_wrap

	ctr0all[goodtais[pno]]=ctr0
	 ctrall[goodtais[pno]]=ctr
	 taiall[goodtais[pno]]=tai

;ENDREP UNTIL EOF(lu)
ENDREP UNTIL pno GE n_srtd1-1

totpckts = numpckts+numnew
counter = counter[0:totpckts-1]
taiall  = taiall [0:totpckts-1]
nbad = n_elements(badpckts)
good = WHERE(counter GT 0,ngood)

printf,lulog
print
missing_secs = 'TotalMissing '+string(ceil(sec_missed),format='(i5)')+' seconds,  '+string(pckts_missed,format='(i6)')+' packets'
print,missing_secs
print,trim(string(numpckts))+' orig pckts    '+trim(string(numnew))+' new pckts    '+string(nbad,format='(i4)')+' bad pckts  '+string(nmisplaced,format='(i5)')+' misplaced pckts'
IF datatype(date_str) EQ 'UND' THEN stop
printf,lulog,fn+'   '+string(numpckts,format='(i6)')+' orig pckts    '+string(numnew,format='(i6)')+' new pckts    '+string(nbad,format='(i5)')+' bad pckts  '+string(nmisplaced,format='(i5)')+' misplaced pckts. '
printf,lulog,fn+'   '+missing_secs

;ctr0all=ctr0all(0:pno)
;ctrall2= (a(2,*) * 256L + a(3,*)) AND '3fff'XL
;tais2 = obt2tai(a(6:11,*))

print,'Sorting packet counters'
sorted = SORT(counter(good))		; Sort the array of packets
isnew=isnew[sorted]
wisnew=where(isnew,nnew)
plot, taiall[good[sorted]]-tais0, counter[good[sorted]], title=utc2str(tai2utc(tais0),/ecs),ytitle='Counter',psym=3, xtitle='Seconds'
IF nnew GT 2 THEN oplot,taiall[wisnew],counter[good[sorted[wisnew]]],psym=1,color=2
oplot,taiall[good[sorted]]-tais0, ctrall[good[sorted]]*(pno/30000)+20000,psym=3
IF nnew GT 2 THEN oplot,taiall[wisnew],ctrall[good[sorted[wisnew]]]*(pno/30000)+20000,psym=1,color=2

wait,60
IF wrap GT counter(0)+pno+pckts_missed+numnew THEN BEGIN
	print,'ERROR?: Number of wraparounds exceeds number of packets counted'
	help,wrap,pno,pckts_missed,numnew,counter,good
	stop
	ENDIF

;
;  Now write packets from d01 and packets from REL/QKL out to
;  a magnetic disk file.
;

print,'Creating sorted packet file ',outname
FOR i=0L,ngood-1 DO aa(i) = a(*,good(sorted(i)))
FREE_LUN,lu
CLOSE,luout
FREE_LUN,luout
CD,old_dir
print,'Finished FIX_TIME_JUMPS'

;window,color=10,/free

RETURN
END
