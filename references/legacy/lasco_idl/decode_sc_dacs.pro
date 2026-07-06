function ddis_filename,pckt,filetype
;
;   Form a filename in the ddis format: yymmdd_hhmmss.ext
;   The date and time are taken from the LOBT of the packet
;   If it is invalid, then the system date and time are used
;   If the time is the same as the preceeding one, then
;   the time is increased by 1 second.
;
common ddis_fn,oldfn
;
;  Get LOBT time from packet
;
;
;  Check if LOBT is no good and if not get current system date/time
   get_utc,dte,/ecs
;
;  Now form the file name from the date in ECS format
;
fn = strmid(dte,2,2)+strmid(dte,5,2)+strmid(dte,8,2)+'_'
fn = fn+strmid(dte,11,2)+strmid(dte,14,2)+strmid(dte,17,2)
fn = fn+'.'+filetype
return,fn
end

pro close_file,dummy
;
;   closes the ddis file
;
common decode_science,old,lusc,file_open,pno,sc,first,pkttype,lulog
    close,lusc
    file_open = 0
;    print,'File closed at pno,old,pkttype = ',pno,old,pkttype
    printf,lulog,'DDIS file closed at pno,old,pkttype = ',pno,old,pkttype
return
end

pro open_ddis_file,filetype
;
;   Opens a file of type = filetype
;
common decode_science,old,lusc,file_open,pno,sc,first,pkttype,lulog
    sd = getenv_slash ('LEB_IMG')
    if (file_open eq 1) then close_file
    fn=ddis_filename (sc(*,pno),filetype)
    openw,lusc,sd+fn
    file_open = 1
;    print,'File opened '+filetype,pno
    printf,lulog,'File opened of type '+filetype+' at packet number',pno
return
end

pro check_in_dump_file
;
;   checks to see if in dump file of any type and if not closes the file
;   and opens a mem file
;
common decode_science,old,lusc,file_open,pno,sc,first,pkttype,lulog
    if ((old ne 17) and (old ne 18) and (old ne 19) $
    and (old ne 28) ) then begin
        if (file_open eq 1) then begin
           close_file
        endif
    endif
    if (file_open eq 0) then open_ddis_file,'mem'
return
end

pro check_in_fp_file
;
;   checks to see if in fp file of any type and if not closes the file
;   and opens an fp file
;
common decode_science,old,lusc,file_open,pno,sc,first,pkttype,lulog
    if ((old ne 10) and (old ne 11) and (old ne 12) $
    and (old ne 13) and (old ne 14) and (old ne 15) $
    and (old ne 27) ) then begin
        if (file_open eq 1) then begin
           close_file
        endif
    endif
    if (file_open eq 0) then open_ddis_file,'fp'
return
end

pro check_in_img_file
;
;   checks to see if in img file and if not closes the file
;   and opens an img file
;
common decode_science,old,lusc,file_open,pno,sc,first,pkttype,lulog
    if ((old ne 1) and (old ne 2) and (old ne 3) $
    and (old ne 4) and (old ne 5) ) then begin
        if (file_open eq 1) then begin
           close_file
        endif
    endif
    if (file_open eq 0) then open_ddis_file,'img'
return
end

pro decode_sc,dummy
;
;	decodes the science packets for all packet types other than pad
;
;	sc = 2D array containing the science packets
;		the array should contain only data packets when the OBE
;		is running.  ie no packets when the instrument is off,
;		and 'ffff'xl are being transmitted.
;
common decode_science,old,lusc,file_open,pno,sc,first,pkttype,lulog
s=size(sc)
nsc=s(2)	; number of science packets
printf,lulog,'Number of science packets = ',nsc
w=where ((s(0:15,0) and 'ffff'x) eq '88ac'x)
sw = size(w)
if (sw(0) eq 0) then begin
   w=where ((s(0:15,0) and 'ffff'x) eq '88af'x)
   sw = size(w)
   if (sw(0) eq 0) then begin
      printf,lulog,'ERROR:  Packet ID is neither 88ac nor 88af'
      printf,lulog,'        Processing aborted'
      return
   endif else begin
      low_rate=0		; found high rate packet id
   endelse
endif else begin
      low_rate=1		; found low rate packet id
endelse
pktsize = 6+ceil(sc(w(0)+2)/2)	; avoids odd number of bytes
pktstart = 9			; first byte after LOBT
dacs=0
if (w(0) eq 9)  then begin
    dacs=1 			; file created by dacs
    pktstart = pktstart+6	; first byte after LOBT
    pktsize = pktsize+6
endif
;
;  the for loop is for each packet
;
if keyword_set(first) then begin
   old = -1
   file_open = 0			; flag for saving
   get_lun,lusc			; lun for science output
endif
mask = 'ffff'xl
for pno=0,nsc-1 do begin

    pkidwd = pktstart
    repeat begin
; is science LOBT and tlm on?
       if ((sc(pkidwd,pno) and mask) eq mask) then begin
          pkttype = 255						; no
          nwds = pktsize
;
;  find if TM is not 'ffff' anywhere in the remaining packet
;  if in high rate, need to shift each word to see if valid data begins later
;
          w = where ((sc(pkidwd:*,pno) and mask) ne mask)
          sw = size(w)
          if (sw(0) eq 0) then goto,endoffor
          pkidwd = w(0)+3
       endif 
       nwds = ishft( sc(pkidwd,pno) and 'ff00'xl , -8) and 'ff'xl 	; yes
       pkttype = sc(pkidwd,pno) and 'ff'x
       case pkttype of
             1:  begin			; start of image data
					; if old packet type not header then 
					; close old file and open new one
                   if (old ne 2) then begin
                      if (file_open eq 1) then close_file
                   endif
                   if (file_open eq 0) then open_ddis_file,'img'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old=pkttype
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
                   if (file_open eq 1) then close_file
                   open_ddis_file,'img'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old=pkttype
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
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old=pkttype
                end
;
;   Packet id = 4 : Image Continue
;              This is the continuation of image data
;              If a file is already open, and it is not an img file
;              then close the old file and open an img file.
;
             4: begin
                   check_in_img_file
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old=pkttype
                end
;
;   Packet id = 5 : Image Block End
;              This is an end of an image block
;              If a file is already open, and it is not an img file
;              then close the old file and open an img file.
;
             5: begin
                   check_in_img_file
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old=pkttype
                end
;
;   Packet id = 23 : Image End
;              This should be the real end of an image
;              It is assumed that no data words should be written.
;              If a file is open, close it.
;
            23: begin			; image end
                   if (file_open eq 1) then close_file
                   file_open = 0
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
                   if (file_open eq 1) then close_file
                   file_open = 0
                end
;
;   Packet id = 8 : M1 Data
;               The M1 status comes down HK.
;               Close a file if open, since this should not occur
;
             8: begin
                   if (file_open eq 1) then close_file
                   file_open = 0
                end
;
;   Packet id = 9 : Memory Parity
;               This is not used.
;               Close a file if open, since this should not occur
;
             9: begin
                   if (file_open eq 1) then close_file
                   file_open = 0
                end
;
;   Packet id = 10 : FP Results type 1
;               This is the beginning of FP results
;               Close any file that is open and open an fp1 file.
;
            10: begin
                   open_ddis_file,'fp1'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 11 : FP Results type 2
;               This is the beginning of FP results
;               Close any file that is open and open an fp2 file.
;
            11: begin			; FP Results 2
                   open_ddis_file,'fp2'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 12 : FP Results type 3
;               This is the beginning of FP results
;               Close any file that is open and open an fp3 file.
;
            12: begin			; FP Results 3
                   open_ddis_file,'fp3'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 13 : FP Results type 4
;               This is the beginning of FP results
;               Close any file that is open and open an fp4 file.
;
            13: begin			; FP Results 4
                   open_ddis_file,'fp4'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 14 : FP Results type 4
;               This is the beginning of FP results
;               Close any file that is open and open an fp5 file.
;
            14: begin			; FP Results 5
                   open_ddis_file,'fp5'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 27 : FP Results type 6
;               This is the beginning of FP results
;               Close any file that is open and open an fp6 file.
;
            27: begin			; FP Results 6
                   open_ddis_file,'fp6'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 15 : FP Continue results data
;               This is a continuation of FP results
;               Check to see if an FP file is open and if not, open one
;               of type = 'fp' since we don't know which type it is.
;
            15: begin			; FP Continue Data
                   check_in_fp_file
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
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
                      writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                      close_file
                   endif else if (nwds gt 1) then begin
                           open_ddis_file,'fp'
                           writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                           close_file
                   endif
                   file_open = 0
                   old = pkttype
                end
;
;   Packet id = 28 : Open memory dump file
;               This is the beginning of a memory dump 
;
            28: begin			; Open dump file
                   if (file_open eq 1) then close_file
                   file_open = 0
                   open_ddis_file,'mem'
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 17 : Memory dump start
;               This is the beginning of a memory dump 
;
            17: begin
                   check_in_dump_file
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 18 : Memory dump continue
;
            18: begin			; Memory dump cont
                   check_in_dump_file
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                end
;
;   Packet id = 19 : Memory dump end
;
            19: begin			; Memory dump end
                   check_in_dump_file
                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
                   old = pkttype
                   close_file
                   file_open = 0
                end
;
;   Packet id = 29 : Memory dump file close
;
            29: begin			; Close dump file
                   if (file_open eq 1) then close_file
                   old = pkttype
                end
;
;   Packet id = 20 : Peripheral Data Logging start
;
            20: begin
;                   if (file_open eq 1) then close_file
;                   open_ddis_file,'pdl'
;                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
;                   old = pkttype
;                 t='Driver Data Start'
                end
;
;   Packet id = 21 : Peripheral Data Logging continue
;
            21: begin
;                   check_in_pdl_file
;                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
;                   old = pkttype
;                 t='Driver Data Cont '
                end
;
;   Packet id = 22 : Peripheral Data Logging end
;
            22: begin
;                   check_in_pdl_file
;                   writeu,lusc,sc(pkidwd+2:pkidwd+nwds+1,pno)
;                   old = pkttype
;                   close_file
                 t='Driver Data End  '
                end
            24: begin
                   if (file_open eq 1) then close_file
                   old = pkttype
                 t='Periph Resp Start'
                end
            25: begin
                   if (file_open eq 1) then close_file
                   old = pkttype
                 t='Periph Resp Cont '
                end
            26: begin
                   if (file_open eq 1) then close_file
                   old = pkttype
                 t='Periph Resp End  '
                end
           255: begin
;                   if (file_open eq 1) then close_file
;                   file_open = 0
;                   old = pkttype
                 t='Power Off        '
                end
          else:  t='Unknown          '
       endcase
       op = pno					; old packet #
       nrep = 0					; # repeats
       pkidwd=pkidwd+nwds+2			; go to next packet id
    endrep until pkidwd ge pktsize		; until packet is complete
endoffor:
endfor
return
end


pro decode_all_science,date
;
;+
; NAME:				DECODE_ALL_SCIENCE
;
; PURPOSE:			Main program to decode all science TM files
;				from DACS, ECS, or Level-0 into raw DDIS files
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		DECODE_ALL_SCIENCE, Date
;
; INPUTS:			None
;
; OPTIONAL INPUTS:		Date = Date to be processed, YYMMDD
;				       If date is not present, then all
;				       science files in $LEB_IMG will be 
;				       processed.
;	
; KEYWORD PARAMETERS:		None
;
; OUTPUTS:			None
;
; OPTIONAL OUTPUTS:		None
;
; COMMON BLOCKS:		decode_science
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
;
;       @(#)decode_sc_dacs.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
;
common decode_science,old,lusc,file_open,pno,sc,first,pkttype,lulog
ver = 'V1  21 Dec 1995'
if (n_params(0) eq 0) then dte='' else dte=date
sd = getenv_slash('REDUCE_LOG')
get_utc,now,/ecs
openw,lulog,sd+'red_'+now+'.log'
printf,lulog,'Procedure  = DECODE_ALL_SCIENCE'
printf,lulog,'Input Parm = '+dte
printf,lulog,'Version    = '+ver
printf,lulog,'Date       = '+now
spawn,'hostname',host
printf,lulog,'Host       = '+host
spawn,'domainname',dom
printf,lulog,'Domain     = '+dom
ff = findfile('LASSC'+dte+'*')
s  = size(ff)
if (s(0) eq 0) then begin
   print,'No files found, exiting'
   printf,lulog,'No files found, exiting'
   close,lulog
   free_lun,lulog
   return
endif else begin
  printf,lulog,'Number of Files Found = ',s(1)
   first = 1
   for i=0,s(1)-1 do begin
       for j=0,1 do printf,lulog
       get_utc,dte,/ecs
       printf,lulog,'Start processing of file '+ff(i)+'at '+dte
       print,'Processing file: '+ff(i)
       sc = readscience (ff(i))
       ssc = size(sc)
       printf,lulog,'Number of packets in file = ',s(2)
       decode_sc
       first = 0
   endfor
   if (file_open eq 1) then close_file
endelse
free_lun,lusc
for i=0,4 do printf,lulog
get_utc,dte,/ecs
printf,lulog,'DECODE_ALL_SCIENCE completed at '+dte
close,lulog
free_lun,lulog
return
end
