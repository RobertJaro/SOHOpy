pro write_last_img,img,hdr
;+
; NAME:				WRITE_LAST_IMG
;
; PURPOSE:			Create GIF image of the last real time image
;				processed so that xv can then read and display
;				it.
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		WRITE_LAST_IMG,Img,Hdr
;
; INPUTS:			Img = Input Image array
;				Hdr = FITS header
;
; OPTIONAL INPUTS:		None
;
; KEYWORD PARAMETERS:		None
;
; OUTPUTS:			None
;
; OPTIONAL OUTPUTS:		None
;
; COMMON BLOCKS:		None
;
; SIDE EFFECTS:			None
;
; RESTRICTIONS:			This must be done with IDL haveing an X window
;				display.
;
; PROCEDURE:			Scales the image to not larger than 512 x 512,
;				and creates a GIF image with annotation along
;				the side
;
; EXAMPLE:
;
; MODIFICATION HISTORY:		Written, RA Howard, NRL
;    VERSION 1   rah    9 Nov 1995
;    VERSION 2   rah   16 Nov 1995  Conversions added
;    VERSION 3   rah   29 Nov 1995  Modified layout
;    VERSION 4   rah   11 Dec 1995  Modified Detector conversion
;    VERSION 5   rah   12 Jan 1996  Changed assumption to be !order = 0
;				    Added R1 and R2 in place of P1, P2
;    VERSION 6   rah   19 Apr 1996  Modified scaling of EIT image
;                                   Corrected display of PIXSUM to include LEB
;    VERSION 7   rah   23 May 1996  Corrected handling of images outside of chip
;    VERSION 8   rah   22 Jul 1996  Corrected handling of cals > 1024 lines
;    VERSION 9   rah    8 Oct 1996  Added subtraction of background model
;    VERSION 10  sep   18 Jun 1997  Changed call for new OFFSET_BIAS()
;    VERSION 11  nbr   28 Oct 1998  Use current year for background image
;    VERSION 12  rah    3 Mar 1999  Added test for C2/3 Cont RO and Dark
;    VERSION 13  nbr   23 Mar 1999  Change header to structure before calling REDUCE_STD_SIZE
;    VERSION 14  nbr   29 Sep 1999  Change min/max for C2 and C3
;    V 15	nbr	Feb 2000    Use ANY_YEAR, new min/max for C2
;		nbr, 31 Jan 2001 - Do not use ANY_YEAR for C2
;		nbr, 21 Oct 2001 - Move placement of Logo
;		nbr, 31 Jan 2002 - no change
;
;
; @(#)write_last_img.pro	1.24 08/11/03 :LASCO IDL LIBRARY
;
;-
;
;   If not full image then insert into proper place in a
;   full & square image
;
common lastimage,full_img


sumrow = fxpar(hdr,'SUMROW')
sumcol = fxpar(hdr,'SUMCOL')
lebxsum = fxpar(hdr,'LEBXSUM')
lebysum = fxpar(hdr,'LEBYSUM')
if (sumrow eq 0) then sumrow=1
if (sumcol eq 0) then sumcol=1
if (lebxsum eq 0) then lebxsum=1
if (lebysum eq 0) then lebysum=1
nxsum = sumcol*lebxsum
nysum = sumrow*lebysum
naxis1 = fxpar(hdr,'NAXIS1')
naxis2 = fxpar(hdr,'NAXIS2')
telescope = fxpar (hdr,'TELESCOP')
detector = strtrim(fxpar(hdr,'DETECTOR'),2)
filter = STRUPCASE(STRCOMPRESS(FXPAR(hdr,'FILTER'),/remove_all))
IF (detector NE 'EIT') then polar='POLAR' ELSE polar='SECTOR'
polar = STRUPCASE(STRCOMPRESS(FXPAR(hdr,polar),/remove_all))
compr = fxpar (hdr,'COMPRSSN')
IF (STRPOS(compr,'P') GE 0)       $  ; Is radial spoke used?
   THEN radial_spoke=1 ELSE radial_spoke=0
nx = nxsum*naxis1
ny = nysum*naxis2
stchdr = lasco_fitshdr2struct(hdr)
full_img = reduce_std_size(img,stchdr)
lp = FXPAR(hdr,'LP_NUM')
CASE detector OF
  'EIT': full_img = BYTSCL(ALOG10((full_img-848)>1))
  'C1':  BEGIN		; get the offband image if available and form subtraction
	    sd = getenv_slash ('IMAGES')
            filter = STRLOWCASE ( STRCOMPRESS (fxpar(hdr,'FILTER'),/remove_all))
            basename = sd + 'cont_path_'+filter
            fsz = size(findfile(basename))
            IF (fsz(0) EQ 0)  THEN fail=1 ELSE BEGIN
               openr,lu,basename,/get_lun
               readf,lu,basename
               free_lun,lu
               IF (basename ne '')  THEN BEGIN
                  print,'Reading in base image: '+basename
                  fsz = size(findfile(basename))
                  IF (fsz(0) EQ 0)  THEN fail=1 ELSE BEGIN
                     base=readfits(basename,hbase)
                     IF (base(0) NE -1)  THEN BEGIN
                        bias = OFFSET_BIAS(hbase)
                        base = reduce_std_size(base,hbase)
                        expratio = FXPAR(hdr,'EXPTIME') / FXPAR(hbase,'EXPTIME')
                        base = (base-bias) * expratio
                        full_img = (full_img - lebxsum*lebysum*OFFSET_BIAS(hdr))/(nxsum*nysum)
                        wl = FXPAR(hdr,'WAVELENG')
                        IF (abs(wl-5309) LT 1)  THEN BEGIN
                           full_img = full_img / (base>1)
                           full_img = BYTSCL(full_img,min=0.95,max=1.1)
                        ENDIF ELSE BEGIN
                           full_img = full_img / (base>1)
                           full_img = BYTSCL(full_img,min=0.95,max=1.1)
                        ENDELSE
                        fail = 0
                     ENDIF ELSE fail=1.0
                  ENDELSE
               ENDIF ELSE fail=1
            ENDELSE
            IF (fail EQ 1)    THEN full_img = BYTSCL(alog(full_img>1),min=6,max=10)
         END
;  'C2':  full_img=difbkgnd(full_img,hdr,minval=-100,maxval=600,altmin=1500,altmax=4000, /USE_CURRENT)
;  'C3':  full_img=difbkgnd(full_img,hdr,/logscl,minval=20,maxval=500,altmin=3600,altmax=10000, /USE_CURRENT)
'C2':  BEGIN
          IF ((STRPOS(lp,'Cont RO') LT 0) AND (STRPOS(lp,'Dark') LT 0))  THEN BEGIN
             ;full_img=difbkgnd(full_img,stchdr,minval=0.8,maxval=1.9, /ratio , /ANY_YEAR)
             full_img=difbkgnd(full_img,stchdr,minval=0.8,maxval=1.9, /ratio)
		; ** NBR, min/max values changed, 2/29/00
          ENDIF ELSE full_img=hist_equal(full_img)
       END
'C3':  BEGIN
          IF ((STRPOS(lp,'Cont RO') LT 0) AND (STRPOS(lp,'Dark') LT 0))  THEN BEGIN
             full_img=difbkgnd(full_img,stchdr,minval=0.9,maxval=1.15, /ratio)
          ENDIF ELSE full_img=hist_equal(full_img)
       END
  ELSE:  full_img = BYTSCL(full_img)
ENDCASE
sz = SIZE(full_img)
FXADDPAR,hdr,'NAXIS1',sz(1)
FXADDPAR,hdr,'NAXIS2',sz(1)
;
;
;  Add in the LASCO logo
;
restore,getenv('NRL_LIB')+'/lasco/display/lasco_logo.sav'
;tmp = full_img(384:*,0:127)		; order=0
;w_logo = where(logo ne 0)
;IF (detector NE 'EIT') THEN tmp(w_logo)=255
;full_img(384,0) = tmp			; order=0
if (!d.name eq 'X') then window,xsize=512+300,ysize=512+50,title='LAST IMAGE' $
                    else begin
			device,set_resolution=[512+250,512+50]
			tverase
			endelse
tvscl,full_img,0,0,order=0
IF (detector NE 'EIT') THEN tvscl,logo,512+((300-128)/2), 32
del=40
y=525
!p.charsize=3.2
!p.charthick=2.
!p.font=-1
xyouts,0,y,'!3 LASCO-'+detector,/device,charsize=3.2
months='JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC'
date_obs = fxpar (hdr,'DATE-OBS')
date = strmid(date_obs,2,2)
date = date + strmid(months,3*(strmid(date_obs,5,2)-1),3)
date = date + strmid(date_obs,8,2)
xyouts,' '+date+' '+strmid(date_obs,11,8),charsize=3.2
time_obs = fxpar (hdr,'TIME-OBS')
xyouts,strmid(time_obs,0,5)+'UT',charsize=3.2
filename = fxpar (hdr,'FILENAME')
y = 520-del
!p.charthick=1.
sidebar=1.9
xyouts,511+10,y,'FILENAME: '+filename,/device,charsize=sidebar
y=y-del
exptime = fxpar (hdr,'EXPTIME')
s=string(exptime,format='(f8.1,1x,3hsec)')
xyouts,511+10,y,'EXPTIME: '+s,/device,charsize=sidebar
y=y-del
t=strtrim(fxpar(hdr,'DETECTOR'),2)
xyouts,511+10,y,'FILTER:  '+filter,/device,charsize=sidebar
y=y-del
if (t ne 'EIT') then begin
   xyouts,511+10,y,'POLAR:  '+polar,/device,charsize=sidebar
endif else begin
   xyouts,511+10,y,'SECTOR: '+polar,/device,charsize=sidebar
endelse
if (t eq 'C1') then begin
   y=y-del
   wl = fxpar(hdr,'WAVELENG')
   s = string(wl,format='(f10.4,1x,1hA)')
   xyouts,511+10,y,'FP: '+s,/device,charsize=sidebar
endif
y=y-del
xyouts,511+10,y,'LP: '+lp,/device,charsize=sidebar
y=y-del
osnum = fxpar (hdr,'OS_NUM')
xyouts,511+10,y,'OS: '+string(osnum,format='(i8)'),/device,charsize=sidebar
y=y-del
s = string(nxsum,nysum,format='(i3,1x,1hx,1x,i3)')
xyouts,511+10,y,'PIXSUM: '+s,/device,charsize=sidebar
y=y-del
compr = fxpar (hdr,'COMPRSSN')
s=size(compr)
if ((s(0) eq 0) and s(1) lt 3)  then compr='N'
xyouts,511+10,y,'COMPR: '+compr,/device,charsize=sidebar
b=tvrd()
fname = 'lastimg_'+detector
fname = getenv_slash('LAST_IMG')+fname+'.gif'
;fname2 = getenv_slash('LAST_IMG')+'lastimg.gif'
;
;   find out if link from lastimg.gif to individual last images is present
;   if so, then delete it
;
;spawn,'ls '+fname2,exist
;s=size(exist)
;if s(0) eq 1 then spawn,'/bin/rm '+fname2
write_gif,fname,b
;spawn,'ln -s '+fname+' '+fname2
!p.charsize=0
!p.charthick=0
!p.font=0
return
end
