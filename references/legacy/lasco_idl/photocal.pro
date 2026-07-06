function photocal,x,hx,cal,stray,vig,dark,hnew
;+
; NAME:				PHOTOCAL
;
; PURPOSE:			Performs the Level 1 photometric calibration of
;				an image from digital counts to mean solar 
;				brightness units
;
; CATEGORY:			REDUCTION
;
; CALLING SEQUENCE:		Result = PHOTOCAL (X,Hx,Cal,Stray,Vig,Dark,Hnew)
;
; INPUTS:			X = Input uncalibrated image
;				Hx = Header structure for X
;				Cal = Photometric Calibration Structure
;				Stray = Stray Light Calibration Structure
;				Vig = Vignetting Calibration Structure
;				Dark = Dark Image Calibration Structure
;
; OUTPUTS:			Result = Calibrated image
;				Hnew = New FITS header
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
;     The LASCO calibration images will be derived from flat field images
;     through each filter / polarizer at several known brightness levels and
;     for several exposure times.  The flat field images also contain 
;     information about the vignetting function, but this information will be
;     backed out of the flat fields to create the calibration images used
;     here.  A dark field image will be used to subtract off any dark
;     counts for that exposure time and to correct for any electronic
;     bias that is introduced.
;
;     The CCD response is linear.  However, there may be non-linearity due
;     to the shutter opening and closing times.  This gives the following 
;     formula to convert a raw image, in counts, to a calibrated image, in 
;     photometric units.
;
;     B  =  ( cal.B1 + cal.slope * ( xd - DN1 ) * ( cal.e1 / exptime ) )
;           *  vig.img   -  stray.img
;
;     DN1 = cal.img1 + ( ( cal.img3 - cal.img1 ) ) / ( cal.e3 - cal.e1 ) ) 
;                       * ( exptime - cal.e1 )
;
;     xd  = x - dark1
;
;     dark1 = dark.img1 + ( (dark.img2 - dark.img1) ) / (dark.e2 - dark.e1) )
;                          * ( exptime - dark.e1 )
;
;     where,
;           cal.e1    = exposure time for reference image #1
;           cal.B1    = brightness level of reference image #1
;           cal.slope = slope to convert DN to MSB for exposure e1
;           x         = observed image in counts (DN)
;           hx        = FITS header associated with image, x
;           exptime   = current exposure time (in FITS header)
;           DN1       = reference image at current exposure time
;           dark1     = dark field image at current exposure time
;           xd        = observed image in counts with dark field subtracted
;           stray.img = stray light image
;           vig.img   = vignetting correction image
;                       The vignetting correction is the reciprocal of the 
;                       function in the range of [0,1] except that close to 
;                       the occulting disk where the function is close to 0, 
;                       the correction might be set to 0, rather than permit 
;                       the very large correction.
;           hnew      = FITS header associated with calibrated image
;
;     cal is an idl structure containing the following elements
;
;           version   = version identification (string)
;           date      = date generated (string)
;           start     = start date and time when valid (UTC string)
;           end       = end date and time when valid (UTC string)
;           teles     = telescope (integer)
;           tel_conf  = telescope configuration (integer)
;           cam_conf  = camera configuration (integer)
;           e1        = exposure time at reference image #1 (float)
;           e2        = exposure time at reference image #2 (float)
;                       (must be equal to e1)
;           e3        = exposure time at reference image #3 (float)
;           B1        = brightness level of reference image #1 (float)
;           B2        = brightness level of reference image #2 (float)
;           B3        = brightness level of reference image #3 (float)
;                       (must be equal to B1)
;           img1      = reference image #1 (integer image) dark subtracted
;           img2      = reference image #2 (integer image) dark subtracted
;           img3      = reference image #3 (integer image) dark subtracted
;           slope     = slope of linear conversion (MSB/DN) (float image)
;
;     dark is an idl structure containing the following elements
;
;           version   = version identification (string)
;           date      = date generated (string)
;           start     = start date and time when valid (UTC string)
;           end       = end date and time when valid (UTC string)
;           teles     = telescope (integer)
;           tel_conf  = telescope configuration (integer)
;           cam_conf  = camera configuration (integer)
;           e1        = exposure time at reference image #1 (float)
;           e2        = exposure time at reference image #2 (float)
;           img1      = reference image #1 (integer image) dark subtracted
;           img2      = reference image #2 (integer image) dark subtracted
;
;     stray is an idl structure containing the following elements
;
;           version   = version identification (string)
;           date      = date generated (string)
;           start     = start date and time when valid (UTC string)
;           end       = end date and time when valid (UTC string)
;           teles     = telescope (integer)
;           tel_conf  = telescope configuration (integer)
;           cam_conf  = camera configuration (integer)
;           img       = stray light image (float image)
;
;     vig is an idl structure containing the following elements
;
;           version   = version identification (string)
;           date      = date generated (string)
;           start     = start date and time when valid (UTC string)
;           end       = end date and time when valid (UTC string)
;           teles     = telescope (integer)
;           tel_conf  = telescope configuration (integer)
;           cam_conf  = camera configuration (integer)
;           img       = vignetting correction image (float image)
;
;
; MODIFICATION HISTORY:
;     Written R.A. Howard, Naval Research Lab, 23 Apr 1993
;         Version 1
;                 2   RAH, 12 Nov 1994 additional comments
;                 3   RAH, 3 Oct 1995 added sub image capability
;                                     header is in fits format
;                                     adding dark image correction
;                 4   RAH, 15 Nov 1995 added additional HISTORY to header
;
;       @(#)photocal.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-
ver='V4'
;
;   The conversion slope needs to be corrected for the difference in the
;   exposure times between the reference time and the actual time.
;
exptime = fxpar (hx,'EXPTIME')
cor_slope = cal.e1 / exptime
;
;   Obtain a calibration reference image, DN1, for the actual exposure time
;   from reference images at two exposure times and the same brightness level
;   DN1 would have the same counts as the input image at the same input 
;   brightness level.
;
ratio_exptime = ( exptime - cal.e1 ) / ( cal.e3 - cal.e1 )
;
;   determine starting and ending column numbers: x0,x1
;
x0 = fxpar (hx,'CRPIX1')
nx = fxpar (hx,'NAXIS1')
sx = fxpar (hx,'SUMX')
x1 = (x0-20)/sx+nx-1
;
;   determine starting and ending row numbers: y0,y1
;
y0 = fxpar (hx,'CRPIX2')
ny = fxpar (hx,'NAXIS2')
sy = fxpar (hx,'SUMY')
y1 = (y0-1)/sy+ny-1
cal_1 = cal.img1(x0:x1,y0:y1)
dn1 = cal_1 + ( cal.img3(x0:x1,y0:y1) - cal_1 ) * ratio_exptime
sub1 = dark.img1(x0:x1,y0:y1)
sub2 = dark.img2(x0:x1,y0:y1)
dark1 = sub1 + (sub2 - sub1) * ( exptime - dark.e1) / (dark.e2-dark.e1)
;
;   Now compute the flat field corrected image, then correct for 
;   vignetting and stray light
;
vig_sub = vig.img(x0:x1,y0:y1)
stray_sub = stray.img(x0:x1,y0:y1)
xd = x-dark1
b = ( cal.B1 + ( cal.slope * cor_slope ) * ( xd - dn1 ) ) * vig_sub - stray_sub
;
;  set calibration status into header
;
hnew = hx
fxaddpar,hnew,'B0',1.
fxaddpar,hnew,'DATAMIN',min(b,max=datamax)
fxaddpar,hnew,'DATAMAX',datamax
;***********
;  NOTE:  units will be different for spectral line images
;***********
tel = fxpar (hx,'TELESCOP')
if (tel eq 'C1') then fxaddpar,hnew,'UNITS','erg/cm2/sr/A'
if ((tel eq 'C2') or (tel eq 'C3')) then  fxaddpar,hnew,'UNITS','MSB'
fxaddpar,hnew,'HISTORY',cal.version+' '+cal.date
fxaddpar,hnew,'HISTORY',stray.version+' '+stray.date
fxaddpar,hnew,'HISTORY',vig.version+' '+vig.date
fxaddpar,hnew,'HISTORY',dark.version+' '+dark.date
fxaddpar,hnew,'HISTORY','photocal version = '+ver
return,b
end

