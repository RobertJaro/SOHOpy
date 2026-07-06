function diff2time,time1,time2
;+
; NAME:				DIFF2TIME
;
; PURPOSE:			Compares two times 
;
; CATEGORY:			REDUCTION			
;
; CALLING SEQUENCE:		Result = DIFF2TIME (Time1, Time2)
;
; INPUTS:			Time1 = First time as CDS time structure
;				Time2 = Second time as CDS time structure
;
; OUTPUTS:			Result = Result of comparison:
;					-1 if Time1 > Time2
;					 0 if Time1 = Time2
;					+1 if Time1 < Time2
;
; MODIFICATION HISTORY:
;
;       @(#)diff2time.pro	1.1 04 Apr 1996 LASCO IDL LIBRARY
;
;-

if (time1.mjd lt time2.mjd) then result=1 else begin
   if (time1.mjd gt time2.mjd)  then result=-1 else begin
      if (time1.time lt time2.time) then result=1 else begin
         if (time1.time gt time2.time) then result=-1 else result=0
      endelse
   endelse
endelse
return,result
end
