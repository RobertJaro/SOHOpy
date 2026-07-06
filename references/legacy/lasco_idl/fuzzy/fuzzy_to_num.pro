;+
; NAME:
;	FUZZY_TO_NUM
;
; PURPOSE:
;	Converts a fuzzy number to a number
;
; PROCEDURE:
;	Converts a fuzzy number (or array of fuzzy numbers) to a number (or an
;	array of numbers)
;
; CALLING SEQUENCE:
;	a = fuzzy_to_num (afuzzy)
;
; INPUTS:
;	afuzzy		a fuzzy number (scalar or array)
;
; OUTPUTS:
;	The number (or array) best representing the fuzzy number (or array)
;-




function  fuzzy_to_num, afuzzy


a = (afuzzy.low + afuzzy.high) / 2.


return, a
end