;+
; NAME:				UNPACK_LZ_SCIENCE
;
; PURPOSE:			Main program to unpack all science TM files
;				from Level-0 disks into raw DDIS files
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		UNPACK_LZ_SCIENCE [, filenames]
;
; INPUTS:			None
;
; OPTIONAL INPUTS:		Name of d01 file[s] to be processed
;	filenames	STR or STRARR	 Ex.: '70750101.d01'
;	
; KEYWORD PARAMETERS:		None
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
;    Version 8   RAH, 28 Feb 1996,    Mods for level-0
;    Version 9   RAH, 21 Apr 1996,    Corrected when TM comes back after off
;    Version 10  RAH, 04 Aug 1996,    Don't process if date < May 1996
;					because getting disks out of order
;					Also check for end of packet
;    Version 11  RAH, 29 Aug 1996,    Correct ddis_name for duplicate times
;    Version 12  RAH, 03 Sep 1996,    Correct for time jumps
;    Version 13  RAH, 04 Feb 1997,    Correct high/low rate packet lengths
;    Version 14  NBR,  3 Aug 1998,    Allow optional input of search parameter
;    Version 15  NBR, 28 Jan 1998,    Check for gaps in packet file
;    Version 16  NBR, 13 Sep 1999,    Stop for gaps of 10 min. or more
;    Version 17 NBR, Feb 2000,	'first GT 0' instead of 'keyword_set(first)'; 
;	If apid NE '88ac' or '88af' then skip packet and go on to the next
;    Version 18 NBR, Apr 2000,  Fix case where most of packet is 255 (skip the packet)
;    Version 19 NBR, 31 Jan 2002 - Add /SH to spawn calls
;    03.10.09, nbr - Allow input of d01 filename(s)
;    03/12/18 - KB - Changed findfiles() to findfiles('*d01') in Line #610
;    05/11/16 - KB - change pkidwd to type long for bad packets
;    2009/01/23 - Added change which was in /home/reduce/PrepLZ: 
;    10/17/2005 Karl Battams    - Add /swap_if_little_endian keyword to 'open*' calls
;   2009/01/26 nbr - Changed check of files available; put sccs tags in ver
;   2013/03/25 nbr - Plotprep for new fix_time_jumps
;   2013/11/15 nbr - Mv original d01 to tmfiles/attic/
;   2016/05/11 nbr - Add subdir for unpack logs; add NOFIX keyword (not fully implemented)
;
;	@(#)unpack_lz_science.pro	1.36 05/11/16 LASCO IDL LIBRARY
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
    printf,lulog,'DDIS file closed at pno,old,pkttype = ',pno,old,pkttype
;    unpack_reduce_main,fn,src
return
end

pro open_ddis_file,filetype,fn
;
;   Opens a file of type = filetype
;
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
    sd = getenv_slash ('LEB_IMG')
    if (file_open eq 1) then close_file,filename
    fn=ddis_filename (sc(*),filetype)
    case filetype of
    'img':  n=0
    'mem':  n=0
    'pdl':  n=0
    else:   fn='FP_'+fn
    endcase
    openw,lusc,sd+fn, /swap_if_little_endian
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

    if datatype(old) NE 'INT' THEN help,old,pkttype,filename,file_open,pno,sc,first
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
;	sc = 1D array containing one science packet as a byte array
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
;nsc=s(2)	; number of science packets
pktsize = s(1)
;printf,lulog,'Number of science packets = ',nsc
;case fix(sc(1,0)) of
;     'ac'x:   low_rate=1		; low rate
;     'af'x:   low_rate=0		; high rate
;      else:   begin
;                 printf,lulog,'ERROR:  Packet ID is neither 88ac nor 88af'
;                 printf,lulog,'        Processing aborted'
;                 return
;              endif
;endcase
pktstart = 6				; first byte of LOBT
if first GT 0 then begin
   old = -1
   file_open = 0			; flag for saving
   get_lun,lusc				; lun for science output
   oldfn = ''
endif
mask = 'ff'x
;
;  the for loop is for each packet
;
;for pno=0L,nsc-1 do begin

    pkidwd = pktstart
;    sc = BYTE (sc AND mask)
    lobt_tai = obt2tai(sc(pkidwd:pkidwd+5))
    pkidwd = pkidwd+6			; skip over LOBT
    repeat begin
    
; is science LOBT and tlm on?

       IF (sc(pkidwd) EQ mask) THEN BEGIN
          pkttype = 255						; no
          nwds = pktsize
;
;  find if TM is not 'ff' anywhere in the remaining packet
;  if in high rate, need to shift each word to see if valid data begins later
;
          w = where ( (sc(pkidwd:*) ne mask) and (sc(pkidwd:*) ne 0) )
          sw = size(w)
;print,'packet id word is 255 at pno = ',pno,'  ',sw(0)
          ;if (sw(0) eq 0) then return
	  IF w(0) EQ -1 OR w(0)+pkidwd+5 GT 411 THEN BEGIN
		mesg = 'Skipping packet number '+trim(string(pno))+': 255 until '+trim(string(w(0)))
		print,mesg
		printf,lulog,mesg
		return
	  ENDIF				; **NBR, 4/24/00

          pkidwd = w(0)+pkidwd		; first occurrence of non-zero data
          lobt_tai = obt2tai(sc(pkidwd:pkidwd+5))
          pkidwd = pkidwd+6		; skip over LOBT
       ENDIF 
       nwds = 2*sc(pkidwd)	 ;	 multiply the word count by 2 for bytes
       IF (nwds eq 0) THEN IF ( MAX (sc(pkidwd:*)) EQ 0)    THEN RETURN
       IF (pkidwd GE (pktsize-1))   THEN RETURN
       pkttype = fix(sc(pkidwd+1))
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
            28: begin			; Open dump fileyou
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
             if (from lt pktsize) then writeu,lusc,sc(from:to)
          endif
          old=pkttype
       endif
       if (write_flag eq 2) then begin
          close_file,filename
       endif
       op = pno					; old packet #
       nrep = 0	                                 ; # repeats
       IF ((pkidwd+nwds+4) LT 0) THEN pkidwd = long(pkidwd) ; catch bad packets  (KB)
       pkidwd=pkidwd+nwds+4			    ; go to next packet id
    endrep until pkidwd ge pktsize		    ; until packet is complete
return
end

pro unpack_lz_science,files,dummy, NOFIX=nofix

IF keyword_set(NOFIX) THEN fixjumps=0 ELSE fixjumps=1
common unpack_science,old,lusc,file_open,pno,sc,first,pkttype,lulog,src,filename
ver = '@(#)unpack_lz_science.pro	1.36 05/11/16'
sd = getenv_slash('REDUCE_LOG')
get_utc,now,/ecs
fn = ecs2ddis (now)
openw,lulog,sd+'unpack/unpk_'+fn+'.log',/get_lun
printf,lulog,'Procedure  = UNPACK_LZ_SCIENCE'
printf,lulog,'Version    = '+ver
printf,lulog,'Date       = '+now
spawn,'hostname',host, /SH
printf,lulog,'Host       = '+host
spawn,'domainname',dom, /SH
printf,lulog,'Domain     = '+dom

plotprep	; for plots in fix_time_jumps.pro
tmfiles = getenv ('TMFILES')
cd,tmfiles
IF n_params() NE 0 THEN BEGIN
;   ff =  findfile(onefile+'*')
	ff = files
ENDIF ELSE ff = findfile('*d01')
s  = size(ff)

if (strpos(ff[0],'d01') LT 9) then begin
   print,'No files found, exiting'
   printf,lulog,'No files found, exiting'
   close,lulog
   free_lun,lulog
   return
endif

printf,lulog,'Number of Files Found = ',s(1)
first = 1

may1_96 = str2utc('1996/05/01')
dec1_95 = str2utc('1995/12/01')
sep9_99 = str2utc('1999/09/09')
oct21_99 = str2utc('1999/10/21')
jan15_00 = str2utc('2000/01/15')
mar27_00 = str2utc('2000/03/27')
apr04_00 = str2utc('2000/04/04')
may02_00 = str2utc('2000/05/02')
jul11_00 = str2utc('2000/07/11')

for i=0,s(1)-1 do $		;** LOOP OVER ALL FILES
   IF (STRPOS( STRLOWCASE(ff(i)) ,'.sfd') le 0) THEN BEGIN	

   for j=0,1 do printf,lulog
   get_utc,dte,/ecs
   printf,lulog,'Start processing of file '+ff(i)+' at '+dte
   print,'Processing file: '+ff(i)
   src = 2

   ;cd,tmfiles
 
   openr,lupacket,ff(i),/get_lun,/swap_if_little_endian
   point_lun,lupacket,48
   data = intarr(3)
   readu,lupacket,data
   pck_len = data(2) AND 'ffff'XL
   pck_len = pck_len+7
   st = fstat(lupacket)
   last = (st.size-48)/pck_len-1
   sci=assoc(lupacket,bytarr(pck_len),48)
;   sz = SIZE(sc)
;   last = sz(2)-1
 
   ;** process packets
   print, ff(i)
   sc = sci(0)
   utc = TAI2UTC(OBT2TAI(sc(6:6+5)))
   PRINT,'    first packet TAI:  ', UTC2STR(utc,/ECS),   $
         '  SEQ#: ', LONG(sc(2) * 2L^8 + sc(3)) AND '3FFF'XL
   printf,lulog,'    first packet TAI:  ',UTC2STR(utc,/ECS),  $
         '  SEQ#: ', LONG(sc(2) * 2L^8 + sc(3)) AND '3FFF'XL
;
   IF utc.mjd EQ jul11_00.mjd THEN BEGIN
	print,'Do not process 000711_163816 - 193225.img'   
	print,'Instead use contents of /net/ares/data1/wang/idl/bin/sumbuff/test/000711/fix'
	stop
   ENDIF
   IF utc.mjd EQ mar27_00.mjd or utc.mjd EQ apr04_00.mjd THEN BEGIN
	print,'Remember to modify headers on .img files for 
	print,'3/27-3/30 and 4/4-4/6 (4 files each day? See notes.)'
	stop
   ENDIF
   IF utc.mjd EQ jan15_00.mjd THEN BEGIN
	print,'Remember to modify headers on .img files for 
	print,'000115 20:24-22:28 (6 C3 dark images)'
	stop
   ENDIF
   IF utc.mjd EQ oct21_99.mjd THEN BEGIN
	print,'Remember to modify headers on 6 .img files for 
	print,'991021 21:01-21:54 , C1 (exptime,LEB prgm, ?)
	stop
   ENDIF
;
;  only process packets after 1 May 1996 because the lz reprocessing
;  is coming so much out of order.  We will wait until we get the
;  data in order and then reprocess.
;  
   IF (utc.mjd LT may1_96.mjd) THEN BEGIN
      PRINT,''
      PRINT,''
      PRINT, 'Aborting the processing, because date prior to 1 May'
;      PRINT, 'Aborting the processing, because date prior to 19 July'
      PRINTF,lulog,''
      PRINTF,lulog,''
      PRINTF,lulog, 'Aborting the processing, because date prior to 1 May 1996'  
   ENDIF ELSE BEGIN

   IF (fixjumps) THEN FIX_TIME_JUMPS,ff(i),fn ELSE fn=ff[i]
   CLOSE,lupacket
   OPENR,lupacket,fn,/swap_if_little_endian		;,/delete
   sci=assoc(lupacket,bytarr(pck_len),48)
;   sc = sci(last)
;   print,'    last  packet TAI:  ',UTC2STR(TAI2UTC(OBT2TAI(sc(6:6+5))),/ECS),$
;         '  SEQ#: ', LONG(sc(2) * 2L^8 + sc(3)) AND '3FFF'XL

;   printf,lulog,'    last packet TAI:  ',UTC2STR(TAI2UTC(OBT2TAI(sc(6:6+5))),$
;                   /ECS), '  SEQ#: ', LONG(sc(2) * 2L^8 + sc(3)) AND '3FFF'XL

;   printf,lulog,'Number of packets in file = ',sz(2)

   pno = 0L
   sc = sci(pno)
   prevtai = OBT2TAI(sc(6:6+5))
   apid0 = sc(0) * 256L + sc(1)
   unpack_science_packet

   REPEAT BEGIN
       	first = 0
       	pno = pno+1
       	sc = sci(pno)
       	apid = sc(0) * 256L + sc(1)
	IF apid EQ '88AC'xl or apid EQ '88AF'xl THEN BEGIN
	   currtai = OBT2TAI(sc(6:6+5))
	   difft = currtai - prevtai
	   IF difft GT 200 and difft LT 86400 THEN BEGIN	; 3.33 minutes/1 day
		print,' Gap in packet file of',difft/60,' minutes.'
		end_of_gap=UTC2STR(TAI2UTC(currtai),/ecs)
		print,end_of_gap
		printf,lulog,' Gap in packet file of',difft/60,' minutes before '+end_of_gap
		;stop
	   ENDIF
	   unpack_science_packet
	   prevtai = currtai
	ENDIF ELSE BEGIN
	   dec2hex,apid,apidhex,/quiet
	   pr_str = 'Skipping packet '+string(pno,format='(i6)')+', apid = '+apidhex
	   print, pr_str
	   printf,lulog,pr_str
	ENDELSE
   ENDREP UNTIL  eof(lupacket)
   ENDELSE	;** END OF TEST FOR MAY 1 DATE
   CLOSE,lupacket
   FREE_LUN,lupacket
   print,'Done with original ',ff[i]
   cmd='mv '+ff[i]+' '+tmfiles+'/attic/'
   print,cmd
   wait,5
   spawn,cmd,/sh
   ; fn is moved to attic in miss_pckts.pro with /auto

ENDIF	;** END LOOPING OVER ALL FILES

if (file_open eq 1) then close_file,filename

free_lun,lusc
for i=0,4 do printf,lulog
get_utc,dte,/ecs
printf,lulog,'UNPACK_ALL_SCIENCE completed at '+dte
close,lulog
free_lun,lulog
return
end
