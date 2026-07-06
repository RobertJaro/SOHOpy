;+
; Project     : SOHO - LASCO/EIT
;
; Name        : GET_CROTA
;
; Purpose     : Returns Nominal Roll Attitude of SOHO ( degrees )
;
; Use         : IDL>    result = GET_CROTA( DATE )
;
; Inputs      : DATE in format 2003/07/21 23:30:05.469
;
; Optional Inputs:
;
; Outputs     : Roll Attitude
;
; Keywords    :
;
; Comments    :
;			# Nominal roll attitude of SOHO (degrees)
;			#
;			1995-12-02 03:08:00   0.00
;			2003-07-08 13:00:00 180.00
;	
;		IDL[hercules]>print, GET_CROTA('2003-07-08 12:59:59')
;		      0.00000
;		IDL[hercules]>print, GET_CROTA('2003-07-08 13:00:00')
;		      180.000
;
; Side effects:
;
; Category    :
;
; Written     : Jake Wendt, NRL, July 10, 2003
;
; Version     :	030722	jake	changed location of nominal_roll_attitude.dat
;				030804, nbr - Add ANCIL_DATA, check only uncommented lines of file 
;       Karl Battams   2 Nov 2005 - Add swap_if_little_endian keyword for opening binary data files
;   	N.Rich, 24 May 2011 - Check for presence of dat file
;       Zarro (ADNET), 24 March 2022 - Check for roll file in different subdirectory levels
;
;   05/24/11 @(#)get_crota.pro	1.9
;
;-

;-----------------------------------------------------------------------

FUNCTION GET_CROTA, indate

	crota = 0.
	FALSE=0
	TRUE=1
	inline = ''	;this defines inline as a string and READF then reads a whole line
	intai = UTC2TAI(STR2UTC(indate))

	;OPENR, DAT, '/net/cronus/opt/local/idl_nrl_lib/lasco/data/attitude/roll/nominal_roll_attitude.dat', /GET_LUN
        datfile1=filepath('nominal_roll_attitude.dat',root=getenv('ANCIL_DATA'),subdir=['attitude','roll'])
        ancil_data=getenv('ANCIL_DATA')
        datdirs=[ancil_data,concat_dir(ancil_data,'attitude'),concat_dir(ancil_data,'roll')]
        datfile2=concat_dir(datdirs,'nominal_roll_attitude.dat')
        datfile=[datfile1,datfile2]
        chk=where(file_test(datfile),count)                                ;-- look in multiple places
        IF count GT 0 then datfile=datfile[chk[0]] ELSE BEGIN
	 message,'nominal_roll_attitude.dat not found; is $ANCIL_DATA defined?',/info
         return,999
	ENDELSE
	OPENR, DAT, datfile, /GET_LUN,/swap_if_little_endian
	DONE=FALSE
	WHILE NOT EOF(DAT) AND NOT DONE DO BEGIN
		READF, DAT, inline
		IF strpos(inline,'#') LT 0 THEN BEGIN
			parts = STR_SEP ( STRCOMPRESS( inline ), ' ' )
			date = parts[0]
			time = parts[1]
			roll = parts[2]

			tai = UTC2TAI(STR2UTC(date + ' ' + time))

			IF ( intai LT tai ) THEN BEGIN
				;print, "indate is before last read date" 
				done=TRUE
			ENDIF ELSE BEGIN
				;print, "indate is after last read date" 
				crota = roll
			ENDELSE
		ENDIF
	END

	CLOSE, DAT
	FREE_LUN, DAT

	RETURN, FLOAT(crota)
END;	FUNCTION GET_CROTA

