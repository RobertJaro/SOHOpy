FUNCTION UPDATE_HDR_ROLLXY, hdr
;
;+
; NAME:
;       UPDATE_HDR_ROLLXY 
;
; PURPOSE:
;       This function updates a level-1 hdr with the solar roll angle, sun xpos
;       and sun ypos obtained from stars and also their running median
;       equivalents. It also writes the number of stars used to calculate
;       the center and total number of stars that could have been used. 
;       Center values from time files start with 0 but in FTS header
;       starts with 1, therefore 1 is added to these when updating the
;       header.
;
; CATEGORY:
;       LASCO_ANALYSIS
;
; CALLING SEQUENCE:
;       Result = UPDATE_HDR_ROLLXY (Hdr)
;
; INPUTS:
;       Hdr:      A LASCO header structure
;
; OUTPUTS:
;       1:        Update Success
;       0:        Update Failure
;
; PROCEDURE:
;	Update the hdr using the time files as defined in the
;	c*_rollxy_yymmdd.dat format files.
;
; MODIFICATION HISTORY:
;       Written by:     98/10/06  Ed Esfandiari 
;
;-

  res= 0 

  shdr= hdr
  IF (DATATYPE(shdr) EQ 'STC')  THEN BEGIN
    print,'' 
    print,'Update Failed: Header must be a string array (not a structure).' 
    print,''
  ENDIF ELSE BEGIN
    shdr= LASCO_FITSHDR2STRUCT(shdr)  
    cam= strlowcase(STRTRIM(shdr.detector,2))
    fts_name= strlowcase(STRTRIM(shdr.filename,2))
    date= shdr.date_obs
    time= STRMID(shdr.time_obs,0,8)

    utctime= STR2UTC(date+' '+time)
    yymmdd= UTC2YYMMDD(utctime)
    subdir = GETENV('NRL_LIB')+'/lasco/data_anal/data/'+STRMID(yymmdd,0,4)
    sunfile= subdir+'/'+cam+'_rollxy_'+yymmdd+'.dat'

    found= 'FALSE'
    fname=''
    OPENR,lu,sunfile,/GET_LUN, ERR=err
    if(err EQ 0) THEN BEGIN    ; sunfile exists
      WHILE (NOT EOF(lu) and found eq 'FALSE') DO BEGIN 
        READF,lu,fname,yymmdd,time,roll,x,y,used_stars,tot_stars,med_roll,med_x,med_y,$ 
        FORMAT='(a12,2x,a6,2x,f10.3,2x,d11.6,2x,f8.3,2x,f8.3,2x,i3,2x,i3,2x,d11.6,2x,f8.3,2x,f8.3)'
       IF(fname eq fts_name) THEN found= 'TRUE'
      END

      CLOSE,lu
      FREE_LUN,lu
      IF(found EQ 'FALSE') THEN BEGIN
        print,''
        print,"Update Failed: Can't find information on "+fts_name+" in "
        print,sunfile
        print,''
      ENDIF ELSE BEGIN
        res= 1
        FXADDPAR,hdr,'ROLL',roll,'Degrees'         
        FXADDPAR,hdr,'CRPIX1', double (x+1.0),'Pixels'
        FXADDPAR,hdr,'CRPIX2', double (y+1.0),'Pixels'
        FXADDPAR,hdr,'STRS_FND',fix (used_stars),'# of stars used to compute roll & ctr'
        FXADDPAR,hdr,'STRS_TOT',fix (tot_stars),'total stars that should have been used'
        FXADDPAR,hdr,'ROLL_MDN',med_roll,'Degrees - running roll median'
        FXADDPAR,hdr,'CRX_MDN', double (med_x+1.0) ,'Pixels - running X1 median'
        FXADDPAR,hdr,'CRY_MDN', double (med_y+1.0),'Pixels - running X2 median'
      ENDELSE 
    ENDIF ELSE BEGIN ;sunfile does not exist.
      print,''
      print,"Update Failed: Can't find:"
      print,sunfile
      print,"to search for "+fts_name+"."
      print,''
    ENDELSE
  END

  RETURN,res 

end




