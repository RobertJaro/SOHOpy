pro unpack_reduce_main,filename,src
;+
; NAME:				UNPACK_REDUCE_MAIN
;
; PURPOSE:			Main program to perform pipeline processing 
;                               on a file created by unpack_science 
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		UNPACK_REDUCE_MAIN, Filename, Src
;
; INPUTS:			Filename = file name to process
;                        	Src = 1 for processing QL files at NRL
; 				      2 for processing Level-0 files at NRL
;
; OPTIONAL INPUTS:		None
;	
; KEYWORD PARAMETERS:		None
;
; OUTPUTS:			None
;
; OPTIONAL OUTPUTS:		None
;
; COMMON BLOCKS:		DBMS
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
;    Version 1   RAH, 25 Dec 1995,    Modified from REDUCE_MAIN, V3
;    Version 2	NBR, 31 Jan 2002 - Add /SH to spawn calls
;       Karl Battams   2 Nov 2005 - Add swap_if_little_endian keyword for opening binary data files
;
;       @(#)unpack_reduce_main.pro	1.3 11/02/05 LASCO IDL LIBRARY
;
;-
;
common dbms,ludb,lulog
   ver = 'V1'
   true=1
   leb_img = getenv ('LEB_IMG')
;
;  Find the root portion of the file name and form file names
;
   n = strpos(filename,'.')
   root = strmid (filename,0,n)
   print,'UNPACK_REDUCE_MAIN:  Processing file: '+filename
;
;  Open a log file, and print pertinent information
;
   lastfn = ''   ;  process anything next time
   log = getenv_slash ('REDUCE_LOG')
   root = log+'red_'+root
   get_utc,dte,/ecs
   openw,lulog,root+'.log',/get_lun
   printf,lulog,'Procedure = reduce_main'
   printf,lulog,'Version   = '+ver
   printf,lulog,'Date      = '+dte
   spawn,'hostname',host, /SH
   printf,lulog,'Host      = '+host
   spawn,'domainname',dom, /SH
   printf,lulog,'Domain    = '+dom
;
;  Get the processing options from environment string
;
   opt = strupcase(getenv ('REDUCE_OPTS'))
   printf,lulog,'Reduce options = '+opt
;
;  now open the file to get the file size
;
   leb_img = getenv_slash ('LEB_IMG')
   cd,leb_img
   openr,lu,filename,/get_lun,/swap_if_little_endian
   st=fstat(lu)
   oldsize=st.size
   close,lu
   free_lun,lu
   printf,lulog,'Reducing image file  ='+filename
   printf,lulog,'File size (bytes)    =',oldsize
;
;  If generating the DBMS update commands, then open a file
;
   if (strpos(opt,'DBMS') ge 0)   then begin
      openw,ludb,root+'.db',/get_lun
      printf,lulog,'DB update file = '+root+'.db'
   endif
;
;  Now process the image file after changing default directory to
;  $IMAGES
;
   images = getenv_slash ('IMAGES')
   cd,images
   printf,lulog,'Changing to directory ='+images
   for i=0,5 do printf,lulog
   reduce_image,filename,src
   if (strpos(opt,'DBMS') ge 0)   then begin
      close,ludb
      free_lun,ludb
      if (strpos(opt,'UPDATE') ge 0)   then $
         spawn,'isql '+root+'.db', /SH
   endif
   get_utc,dte,/ecs
   printf,lulog,'Reduce_main completed at '+dte
   close,lulog
   free_lun,lulog
return
end
