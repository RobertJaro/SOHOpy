;+
; NAME:
;	NUM_TO_FUZZY
;
; PURPOSE:
;	Converts a number to a fuzzy number
;
; PROPCEDURE:
;	Converts a number (or array of numbers) to a fuzzy number (resp. array
;	of fuzzy numbers with the same dimensions)
;
;	A "fuzzy number" is a confidence interval around a given number.
;	Given 1 number a0 (highest confidence case) and a [min,max] interval
;	(lowest confidence case), the fuzzy number is an compromise beetween
;	[amin,amax] and [a0, a0] according to a confidence level (0 to 1) for
;	the number a0.
;;	
; CALLING SEQUENCE:
;	afuzzy = num_to_fuzzy (a0, amin, amax, conf)
;
; INPUTS:
;	a0		a non-complex number or array of numbers
;	amin		the minimum value for a confidence level 0
;	amax		the maximum value for a confidence level 0
;	conf		a confidence level, ranging from 0 (no confidence in
;			the number a0) to 1 (total confidence in the number a0)
;
; OUTPUTS:
;	A fuzzy number (structure with the form {low,high})
;-




function num_to_fuzzy, a0, amin, amax, conf

;   fuzzy number type
f = {fuzzy, low:0.0, high:0.0}

;   if amin>amax, swap amin and amax
if amax lt amin then begin $
   in=[amin,amax] & amin=in(1) & amax=in(0)
   endif

;   each element of a0 < amin (resp. > amax) is assigned to amin (resp. amax)
a = a0 > amin
a = a < amax

;   dimensions of a
s = size(a)
dim = s(0)

;   create an array of fuzzy numbers
case dim of
      0 : afuzzy = {fuzzy}
      1 : afuzzy = replicate({fuzzy}, s(1))
      2 : afuzzy = replicate({fuzzy}, s(1), s(2))
   endcase

;   assign the low and high value for each fuzzy number
afuzzy.low  = amin+conf*(a-amin)
afuzzy.high = amax-conf*(amax-a)


return, afuzzy
end
