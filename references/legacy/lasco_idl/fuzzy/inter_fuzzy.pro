;+
; NAME:
;	INTER_FUZZY
;
; PURPOSE:
;	Compute the intersection of 2 fuzzy numbers
;
; PROCEDURE:
;	Compute the intersection of 2 fuzzy numbers (this for each element in
;	the case of fuzzy number arrays)
;
; CALLING SEQUENCE:
;	cfuzzy = inter_fuzzy (afuzzy, bfuzzy)
;
; INPUTS:
;	afuzzy, bfuzzy		2 fuzzy numbers (or fuzzy number arrays)
;
; OUTPUTS:
;	a fuzzy number (structure {low, high}) or array of fuzzy numbers
;-




function  inter_fuzzy, afuzzy, bfuzzy

;   c = {c1, c2} = {max(a1,b1), min(a2, b2)} 
cfuzzy = afuzzy
cfuzzy.low = afuzzy.low > bfuzzy.low
cfuzzy.high = afuzzy.high < bfuzzy.high


return, cfuzzy
end
