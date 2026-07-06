;+
; Project     : SOHO - LASCO/EIT
;
; Name        :	MAKE_INDEX
;
; Purpose     :
;
; Use         : IDL>
;
; Inputs      :
;
; Optional Inputs:
;
; Outputs     :
;
; Keywords    :
;
; Comments    :
;
; Side effects:
;
; Category    :
;
; Written     :
;
; Version     :
;
; Modification:	020606 Jake Changed End of Repeat loop to check numpckts as well
;	03.10.08, nbr - change name of output file
;   	10.07.09, nbr - save output file in $QL_IMG/catalogs
;
; @(#)make_index.pro	1.8 05/10/16 :LASCO IDL LIBRARY
;
;-

;-----------------------------------------------------------------------

;
;  EX.	make_index, findfile('/net/corona/ql/ECS/ELASCL_0307*L')
;
; Make a file with start and end times of packet files listed in input
;
; Input:
; list		STRARR	Filenames of packet files
;
;



PRO make_index, list


    	outfil=concat_dir(concat_dir(getenv('QL_IMG'),'catalogs'),'ecs_index.txt')
	openw,1,outfil

	n = n_elements(list)
	for i=0,n-1 do begin
		sc=read_tm_packet(list(i))
		sz = size(sc)
		numpckts = sz(2)
		IF numpckts GT 1 THEN BEGIN
			;tais = obt2tai(sc(6:11,*))
			taist = obt2tai(sc(6:11,0))

			; Assume 5 packets per second
			taien_est = taist + 0.2*numpckts
			REPEAT BEGIN
				taien = obt2tai(sc(6:11,numpckts-1))
				numpckts=numpckts-1
			ENDREP UNTIL (taien GT taist and taien LT taien_est+(60*60*4d)) or ( numpckts LE 0 )
			IF numpckts LE 0 THEN print, "----------------> Numpckts LE 0"
			; Do this to account for bad packets at end of QKL/REL file

			printf,1,string(taist,format='(F22.11)')+'  '+string(taien,format='(F22.11)')+'  '+list(i)
		ENDIF
	endfor
	close,1
	outfil2=outfil+'.'+rstrmid(list[0],11,6)
	print,'Copying to ',outfil2
	spawn,'cp '+outfil+' '+outfil2,/sh
end
