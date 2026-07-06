;+
; NAME:				UNPACK_ALL_SCIENCE
;
; PURPOSE:			Main program to unpack all science TM files
;				from DACS, or ECS into raw DDIS files
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		UNPACK_ALL_SCIENCE, Date
;
; INPUTS:			None
;
; OPTIONAL INPUTS:		Date = Date to be processed, YYMMDD
;				       If date is not present, then all
;				       science files in $LEB_IMG will be 
;				       processed.
;	
; KEYWORD PARAMETERS:		/QKL	Set to process only QKL files
;
; OUTPUTS:			None
;
; OPTIONAL OUTPUTS:		None
;
; COMMON BLOCKS:		unpack_science
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:		Written  RA Howard, NRL
;    Version 1   RAH, 21 Dec 1995,    Initial Release
;    Version 2   RAH, 23 Dec 1995,    Changed to read in QKL and REL files
;    Version 3   RAH, 25 Dec 1995,    Added call to reduction processing
;    Version 4   RAH, 28 Dec 1995,    Removed call to reduction processing
;    Version 5   SEP, 14 Jan 1996,    Sort QKL/REL by time
;    Version 6   RAH, 19 Jan 1996,    Modified FP file names
;    Version 7   RAH, 26 Jan 1996,    Corrected write if nwds=0
;    Version 8   RAH, 22 Apr 1996,    Mods for TM returning after 0 or FF
;    Version 9   RAH, 01 Aug 1996,    Added check for end of packet
;    Version 10  RAH, 27 Aug 1996,    Correct ddis_name for duplicate times
;    Version 11  SEP, 12 Dec 1996,    Sort High & Low packets by time
;    Version 12  NBR, 29 Dec 1997,    Ensure pkidwd is less than pktsize in 
;					UNPACK_SCIENCE_PACKET
;    Version 13  NBR, 13 May 1998,    Fix findfile to not find *.SDU files
;    Version 14  NBR,  4 Nov 1998,    Call SPLIT_QKL.pro for QKL files
;    Version 15  NBR, 16 Nov 1998,    Added QKL keyword
;    Version 16  NBR, 11 Dec 1998,    Do not call SPLIT_QKL with QKL keyword
;    Version 17  NBR,    Feb 2000,    Fix unpack_science_packet again
;    Version 18  NBR,    May 2000,    Fix endelse in unpack_science_packet
;    Version 19  NBR, 31 Jan 2002,    Add /SH to spawn calls
;       Karl Battams  Nov 04, 2005    Add /swap_if_little_endian kw to open[ruw] calls
;
;
;       11/04/05 @(#)unpack_all_science.pro	1.17 LASCO IDL LIBRARY
;
;-
;

function ecs2ddis,dte
;
;   converts the time in ECS format to a time in ddis format
;
yy = strmid(dte,2,2)	; year
mo = strmid(dte,5,2)	; month
dd = strmid(dte,8,2)	; day
hh = strmid(dte,11,2)	; hours
mm = strmid(dte,14,2)	; minutes
ss = strmid(dte,17,2)	; seconds
ddis = yy+mo+dd+'_'+hh+mm+ss
return,ddis
end


function ddis_filename,pckt,filetype
;
;   Form a filename in the ddis format: yymmdd_hhmmss.ext
;   The date and time are taken from the LOBT of the packet
;   If it is invalid, then the system date and time are used
;   If the time is the same as the preceeding one, then
;   the time is increased by 1 second.
;
common ddis_fn,oldfn,lobt_tai
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
sd = getenv_slash ('LEB_IMG')
;
;  Get LOBT time from packet
;
ecstime=tai2utc(lobt_tai,/ecs)
fn=ecs2ddis(ecstime)
fn = fn+'.'+filetype
ff = FINDFILE (sd+fn)
fz = SIZE(ff)
WHILE (fz(0) EQ 1)  DO BEGIN
;
;  A file of the new name already exists so increment the
;  time, one second at a time, until a unique name is found
;  Extract the numeric values of date and time
;
   yy = fix(strmid(fn,0,2))	; year
   mo = fix(strmid(fn,2,2))	; month
   dd = fix(strmid(fn,4,2))	; day
   hh = fix(strmid(fn,7,2))	; hours
   mm = fix(strmid(fn,9,2))	; minutes
   ss = fix(strmid(fn,11,2))	; seconds
   oldss = fix(strmid(oldfn,11,2))	; old seconds
;printf,lulog,ss,oldss,oldfn
   ss = ss+1
      if (ss eq 60) then begin
         ss = 0
         mm = mm+1
         if (mm eq 60) then begin
            mm = 0
            hh = hh+1
            if (hh eq 24) then begin
               hh = 0
               dd = dd+1
               CASE mo OF
               4:   dm = 30
               6:   dm = 30
               9:   dm = 30
               11:  dm = 30
               2:   BEGIN
                      IF (4*(yy/4) EQ yy)  THEN dm=29 ELSE dm=28
                      IF (yy EQ 00)   THEN dm=28
                    END
               ELSE: dm = 31
               ENDCASE
               IF (dd GT dm)   THEN BEGIN
                  mo = mo+1
                  if (mo eq 13) then begin
                     mo = 1
                     yy = yy+1
                     if (yy eq 100) then yy=00
                  endif
               ENDIF
            endif
         endif
      endif
   fn = string(yy,mo,dd,hh,mm,ss,format='(3i2.2,1h_,3i2.2)')
   fn = fn+'.'+filetype
   ff = FINDFILE (sd+fn)
   fz = SIZE(ff)
ENDWHILE
return,fn
end

pro close_file,fn
;
;   closes the ddis file and starts processing
;
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
    close,lusc
    file_open = 0
;    print,'File closed at pno,old,pkttype = ',pno,old,pkttype
    printf,lulog,'DDIS file closed at pno,oldunpack_all_science,pkttype = ',pno,old,pkttype
;    unpack_reduce_main,fn,src
return
end

pro open_ddis_file,filetype,fnunpack_all_science

;
;   Opens a file of type = filetype
;
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
    sd = getenv_slash ('LEB_IMG')
    if (file_open eq 1) then close_file,filename
    fn=ddis_filename (sc(*,pno),filetype)
    case filetype of
    'img':  n=0
    'mem':  n=0
    'pdl':  n=0
    else:   fn='FP_'+fn
    endcase
    openw,lusc,sd+fn,/swap_if_little_endian
    file_open = 1
;    print,'Opened file '+fn+' at packet offset ',pno
    printf,lulog,'Opened file '+fn+' at packet offset ',pno
return
end

pro check_in_dump_file,dummy
;
;   checks to see if in dump file of any type and if not closes the file
;   and opens a mem file
;
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
    if ((old ne 17) and (old ne 18) and (old ne 19) $
    and (old ne 28) ) then begin
        if (file_open eq 1) then begin
           close_file,filename
        endif
    endif
    if (file_open eq 0) then open_ddis_file,'mem',filename
return
end

pro check_in_fp_file,dummy
;
;   checks to see if in fp file of any type and if not closes the file
;   and opens an fp file
;
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
    if ((old ne 10) and (old ne 11) and (old ne 12) $
    and (old ne 13) and (old ne 14) and (old ne 15) $
    and (old ne 27) ) then begin
        if (file_open eq 1) then begin
           close_file,filename
        endif
    endif
    if (file_open eq 0) then open_ddis_file,'fp',filename
return
end

pro check_in_img_file,dummy
;
;   checks to see if in img file and if not closes the file
;   and opens an img file
;
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
    if ((old ne 1) and (old ne 2) and (old ne 3) $
    and (old ne 4) and (old ne 5) ) then begin
        if (file_open eq 1) then begin
           close_file,filename
        endif
    endif
    if (file_open eq 0) then open_ddis_file,'img',filename
return
end

pro unpack_science_packet,dummy
;
;	unpacks science packets for all subpacket types other than pad
;
;	sc = 2D array containing the science packets as byte arrays
;               The packet format is as collected by the OBDH, and 
;               does not contain any extra information, as was originally
;               put on by DACS.
;               Bytes 1 and 2   APID
;                     3 and 4   Packet Counter
;                     5 and 6   Packet Length
;                     7 - 12    LOBT put on by OBE
;                     13-end    Science data put on by OBE
;
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
common ddis_fn,oldfn,lobt_tai
s=size(sc)
nsc=s(2)	; number of science packets
pktsize = s(1)
printf,lulog,'Number of science packets = ',nsc
case fix(sc(1,0)) of
     'ac'x:   low_rate=1		; low rate
     'af'x:   low_rate=0		; high rate
      else:   begin
                 printf,lulog,'ERROR:  Packet ID is neither 88ac nor 88af'
                 printf,lulog,'        Processing aborted'
                 return
              endelse		; nbr, 5/23/00
endcase
pktstart = 6				; first byte of LOBT
if keyword_set(first) then begin
   old = -1
   file_open = 0			; flag for saving
   get_lun,lusc				; lun for science output
   oldfn = ''
endif
mask = 'ff'x
;
;  the for loop is for each packet
;
for pno=0L,nsc-1 do begin

    pkidwd = pktstart
    lobt_tai = obt2tai(sc(pkidwd:pkidwd+5,pno))
    pkidwd = pkidwd+6			; skip over LOBT
    repeat begin
; is science LOBT and tlm on?
       if ((sc(pkidwd,pno) and mask) eq mask) then begin
          pkttype = 255						; no
          nwds = pktsize
;
;  find if TM is not 'ffff' anywhere in the remaining packet
;  if in high rate, need to shift each word to see if valid data begins later
;
          scm = sc(pkidwd:*,pno) and mask
          w = where ((scm ne mask) and (scm ne 0))
          sw = size(w)
	  print,'packet id word is 255 at pno = ',pno,'  ',sw(0)
          if (sw(0) eq 0) then goto,endoffor
          pkidwd = w(0)+pkidwd		; first occurrence of non-zero data
	  IF pkidwd GT pktsize-6 THEN goto, endoffor	; NBR, 2/8/00 
          lobt_tai = obt2tai(sc(pkidwd:pkidwd+5,pno))
          pkidwd = pkidwd+6		; skip over LOBT
       endif 
       IF pkidwd GT (pktsize-1) THEN pkidwd = pktsize-1	;*** NBR, 12/29/97
       nwds = 2*sc(pkidwd,pno)		; multiply the word count by 2 for bytes
       IF (nwds eq 0) THEN IF (MAX(sc(pkidwd:*,0)) EQ 0) THEN goto,endoffor
       IF (pkidwd GE (pktsize-1))    THEN GOTO,endoffor
       pkttype = fix(sc(pkidwd+1,pno))
       write_flag = 0				; don't write the science TM 
       case pkttype of
             1:  begin			; start of image data
					; if old packet type not header then 
					; close old file and open new one
                   if (old ne 2) then begin
                      if (file_open eq 1) then close_file,filename
                   endif
                   if (file_open eq 0) then open_ddis_file,'img',filename
                   write_flag = 1		; write the science TM
                 end
;
;   Packet id = 2 : Image Header
;              This is the image header.  It is the first packet
;              type being sent associated with an image.  There
;              does not need to be data following.
;              If a file is already open, then close it.
;              Always open a new img file 
;
             2: begin
                   if (file_open eq 1) then close_file,filename
                   open_ddis_file,'img',filename
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 3 : Image Block Start
;              This should be the start of an image.  There can be
;              several starts of an image block without a Block end
;              if the starts are in the same packet.
;              If a file is already open, and it is not an img file
;              then close the old file and open an img file.
;
             3: begin
                   check_in_img_file
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 4 : Image Continue
;              This is the continuation of image data
;              If a file is already open, and it is not an img file
;              then close the old file and open an img file.
;
             4: begin
                   check_in_img_file
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 5 : Image Block End
;              This is an end of an image block
;              If a file is already open, and it is not an img file
;              then close the old file and open an img file.
;
             5: begin
                   check_in_img_file
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 23 : Image End
;              This should be the real end of an image
;              It is assumed that no data words should be written.
;              If a file is open, close it.
;
            23: begin			; image end
                   if (file_open eq 1) then close_file,filename
                   old=pkttype
                end
;
;   Packet id = 6 : Pad Data
;               Always ignore
;
             6: begin
                end
;
;   Packet id = 7 : Activity Buffer
;               The activity buffer comes down HK.
;               Close a file if open, since this should not occur
;
             7: begin
                   if (file_open eq 1) then close_file,filename
                end
;
;   Packet id = 8 : M1 Data
;               The M1 status comes down HK.
;               Close a file if open, since this should not occur
;
             8: begin
                   if (file_open eq 1) then close_file,filename
                end
;
;   Packet id = 9 : Memory Parity
;               This is not used.
;               Close a file if open, since this should not occur
;
             9: begin
                   if (file_open eq 1) then close_file,filename
                end
;
;   Packet id = 10 : FP Results type 1
;               This is the beginning of FP results
;               Close any file that is open and open an occ file.
;
            10: begin
                   open_ddis_file,'OCC',filename
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 11 : FP Results type 2
;               This is the beginning of FP results
;               Close any file that is open and open an central aperture scan file.
;
            11: begin			; FP Results 2
                   open_ddis_file,'CA',filename
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 12 : FP Results type 3
;               This is the beginning of FP results
;               Close any file that is open and open an finesse op file.
;
            12: begin			; FP Results 3
                   open_ddis_file,'FO',filename
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 13 : FP Results type 4
;               This is the beginning of FP results
;               Close any file that is open and open an chr file.
;
            13: begin			; FP Results 4
                   open_ddis_file,'CHR',filename
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 14 : FP Results type 5
;               This is the beginning of FP results
;               Close any file that is open and open an cch file.
;
            14: begin			; FP Results 5
                   open_ddis_file,'CCH',filename
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 27 : FP Results type 6
;               This is the beginning of FP results
;               Close any file that is open and open an twk file.
;
            27: begin			; FP Results 6
                   open_ddis_file,'TWK',filename
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 15 : FP Continue results data
;               This is a continuation of FP results
;               Check to see if an FP file is open and if not, open one
;               of type = 'fp' since we don't know which type it is.
;
            15: begin			; FP Continue Data
                   check_in_fp_file
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 16 : FP data end
;               This is the end of FP results
;               Check to see if an FP file is open and if so, write
;               out the data and close the file.
;               If one is not open, then if the number of words is 1
;               ignore the packet, otherwise open a file of type fp
;               write out the information, and close the file
;
            16: begin			; FP Data End
                   if (file_open eq 1) then begin
                      write_flag = 2		; write the science TM
                   endif else if (nwds gt 2) then begin
                      open_ddis_file,'FP',filename
                      write_flag = 2		; write the science TM
                   endif
                end
;
;   Packet id = 28 : Open memory dump file
;               This is the beginning of a memory dump 
;
            28: begin			; Open dump file
                   if (file_open eq 1) then close_file,filename
                   open_ddis_file,'mem',filename
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 17 : Memory dump start
;               This is the beginning of a memory dump 
;
            17: begin
                   check_in_dump_file
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 18 : Memory dump continue
;
            18: begin			; Memory dump cont
                   check_in_dump_file
                   write_flag = 1		; write the science TM
                end
;
;   Packet id = 19 : Memory dump end
;
            19: begin			; Memory dump end
                   check_in_dump_file
                   write_flag = 2		; write the science TM
                end
;
;   Packet id = 29 : Memory dump file close
;
            29: begin			; Close dump file
                   if (file_open eq 1) then close_file,filename
                   old = pkttype
                end
;
;   Packet id = 20 : Peripheral Data Logging start
;
            20: begin
;                   if (file_open eq 1) then close_file,filename
;                   open_ddis_file,'pdl',filename
;                    write_flag = 1		; write the science TM
;                 t='Driver Data Start'
                end
;
;   Packet id = 21 : Peripheral Data Logging continue
;
            21: begin
;                   check_in_pdl_file
;                    write_flag = 1		; write the science TM
;                 t='Driver Data Cont '
                end
;
;   Packet id = 22 : Peripheral Data Logging end
;
            22: begin
;                   check_in_pdl_file
;                    write_flag = 2		; write the science TM
                 t='Driver Data End  '
                end
            24: begin
                   if (file_open eq 1) then close_file,filename
                   old = pkttype
                 t='Periph Resp Start'
                end
            25: begin
                   if (file_open eq 1) then close_file,filename
                   old = pkttype
                 t='Periph Resp Cont '
                end
            26: begin
                   if (file_open eq 1) then close_file,filename
                   old = pkttype
                 t='Periph Resp End  '
                end
           255: begin
;                   if (file_open eq 1) then close_file,filename
;                   old = pkttype
                 t='Power Off        '
                end
          else:  t='Unknown          '
       endcase
       if (write_flag ge 1) then begin
          from = pkidwd+4
          to = pkidwd+nwds+3
          if (to gt pktsize) then to=pktsize-1
          if (nwds gt 0) then begin
             if (from lt pktsize) then writeu,lusc,sc(from:to,pno)
          endif
          old=pkttype
       endif
       if (write_flag eq 2) then begin
          close_file,filename
       endif
       op = pno					; old packet #
       nrep = 0					; # repeats
       pkidwd=pkidwd+nwds+4			; go to next packet id
    endrep until pkidwd ge pktsize		; until packet is complete
endoffor:
endfor
return
end

pro unpack_all_science,date, QKL=qkl
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
ver = 'V11  12 Dec 1996'
if (n_params(0) eq 0) then dte='' else dte=date
sd = getenv_slash('REDUCE_LOG')
get_utc,now,/ecs
fn = ecs2ddis (now)
openw,lulog,sd+'unpk_'+fn+'.log',/get_lun
printf,lulog,'Procedure  = UNPACK_ALL_SCIENCE'
printf,lulog,'Input Parm = '+dte
printf,lulog,'Version    = '+ver
printf,lulog,'Date       = '+now
spawn,'hostname',host, /SH
printf,lulog,'Host       = '+host
spawn,'domainname',dom, /SH
printf,lulog,'Domain     = '+dom
tmfiles = getenv ('TMFILES')
cd,tmfiles
IF keyword_set(QKL) THEN ff = findfile('ELASC*'+dte+'*QKL') $
	ELSE BEGIN			; NBR, 11Dec98
	   SPLIT_QKL,date		;** NBR, 4Nov98
	   ff = findfile('ELASC*'+dte+'*L')	; ** NBR, 16Nov98
	ENDELSE
s  = size(ff)
if (s(0) eq 0) then begin
   print,'No files found, exiting'
   printf,lulog,'No files found, exiting'
   close,lulog
   free_lun,lulog
   return
endif else begin

   ;** SORT BY TIME IN FILENAME
   pos = STRPOS(ff, 'ELASC')
   temp = STRMID(ff, pos(0)+7, 20-7)	;** modified 12/12/96 SEP sort H & L packets by time
   ind = SORT(temp)
   ff = ff(ind)
   last_QKL_tai = 0D

  printf,lulog,'Number of Files Found = ',s(1)
   first = 1

   for i=0,s(1)-1 do begin	;** LOOP OVER ALL FILES

       skipflag = 0

       for j=0,1 do printf,lulog
       get_utc,dte,/ecs
       printf,lulog,'Start processing of file '+ff(i)+' at '+dte
       print,'Processing file: '+ff(i)
;
;    Determine file type to indicate source of data
;    If not quick look then must be Level-0
;
       n = strpos(ff(i),'REL',0)		; Quick Look Realtime
       if (n gt 0) then src=1 else begin
          n = strpos(ff(i),'QKL',0)		; Quick Look Playback
          if (n gt 0) then src=1 else begin
             n = strpos(ff(i),'CMB',0)		; Quick Look Combined
             if (n gt 0) then src=1 else src=2
          endelse
       endelse

   cd,tmfiles
   IF (STRPOS(ff(i), '.QKL') NE -1) THEN BEGIN    ;** QKL FILE
 
      sc = READ_TM_PACKET(ff(i), /SILENT)
      sz = SIZE(sc)
      last = sz(2)-1
      ;** get the TAI timestamp for the last QKL packet in this file
      last_QKL_tai = OBT2TAI(sc(6:6+5,last))
 
   ENDIF ELSE BEGIN     ;** REL FILE
 
      sc = READ_TM_PACKET(ff(i), /SILENT)
 
      ;** if last_QKL_tai NE 0  then we need to skip packets up to last_QKL_tai
      all_tai = OBT2TAI(sc(6:6+5,*))
      IF (last_QKL_tai NE 0) THEN BEGIN
         start_ind = WHERE(all_tai GT last_QKL_tai)
         IF (start_ind(0) NE -1) THEN BEGIN
            sc = sc(*,start_ind(0):*)
            all_tai = all_tai(start_ind(0):*)
         ENDIF ELSE skipflag = 1        ;** skip this entire .REL FILE all packets were in the previous QKL
      ENDIF
      IF NOT(skipflag) THEN BEGIN
      ;** if next file is an QKL then we need to chop packets off the end up to the
      ;** first packet in that QKL file
      IF (i LT (N_ELEMENTS(ff)-1)) THEN BEGIN
         IF (STRPOS(ff(i+1), '.QKL') NE -1) THEN BEGIN
            packet = READ_TM_PACKET(ff(i+1), /FIRST_ONLY, /SILENT)
            ;** get the TAI timestamp for the first QKL packet in this file
            first_QKL_tai = OBT2TAI(packet(6:6+5))
 
            IF (all_tai(0) EQ 0) THEN all_tai = OBT2TAI(sc(6:6+5,*))
            stop_ind = WHERE(all_tai GE first_QKL_tai)
            ;** check if all packets are later than the 1st packet of next QKL file
            IF (stop_ind(0) EQ 0) THEN skipflag = 1 ELSE $
              IF (stop_ind(0) NE -1) THEN sc = sc(*,0:stop_ind(0)-1)
         ENDIF
      ENDIF
 
      last_QKL_tai = 0D
      all_tai = 0D
      ENDIF ;** NOT(skipflag)
 
   ENDELSE      ;** REL FILE
 
   ;** process packets
   print, ff(i)
   sz = SIZE(sc)
   last = sz(2)-1
   print, '    first packet TAI:  ', UTC2STR(TAI2UTC(OBT2TAI(sc(6:6+5,0))), /ECS), '  SEQ#: ', $
            LONG(sc(2,0) * 2L^8 + sc(3,0)) AND '3FFF'XL
   print, '    last  packet TAI:  ', UTC2STR(TAI2UTC(OBT2TAI(sc(6:6+5,last))), /ECS), '  SEQ#: ', $
            LONG(sc(2,last) * 2L^8 + sc(3,last)) AND '3FFF'XL

   printf,lulog, '    first packet TAI:  ', UTC2STR(TAI2UTC(OBT2TAI(sc(6:6+5,0))), /ECS), $
            '  SEQ#: ', LONG(sc(2,0) * 2L^8 + sc(3,0)) AND '3FFF'XL
   printf,lulog, '    last  packet TAI:  ', UTC2STR(TAI2UTC(OBT2TAI(sc(6:6+5,last))), /ECS), $
            '  SEQ#: ', LONG(sc(2,last) * 2L^8 + sc(3,last)) AND '3FFF'XL

       ssc = size(sc)
       printf,lulog,'Number of packets in file = ',ssc(2)

   IF (skipflag) THEN $
      print, '****skipping packet file: ', ff(i), ' all packets were in previous file' $
   ELSE $
       unpack_science_packet
       first = 0
   endfor	;** END LOOPING OVER ALL FILES

   if (file_open eq 1) then close_file,filename
endelse
free_lun,lusc
for i=0,4 do printf,lulog
get_utc,dte,/ecs
printf,lulog,'UNPACK_ALL_SCIENCE completed at '+dte
close,lulog
free_lun,lulog
return
end
