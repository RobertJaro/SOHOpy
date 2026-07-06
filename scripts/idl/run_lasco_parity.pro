; Run small LASCO REDUCE parity cases and write JSON-like output.
;
; Usage from a shell:
;   scripts/idl/run_lasco_parity.sh tests/fixtures/idl/lasco_parity.json
;
; This script assumes SolarSoft/LASCO IDL paths are already configured. It avoids
; raw data and calibration files where possible so it can run on a normal SSW
; installation.

pro _json_pair, lu, key, value, last=last
  comma = ','
  if keyword_set(last) then comma = ''
  printf, lu, '  "' + key + '": ' + value + comma
end

function _json_string, value
  return, '"' + strtrim(value, 2) + '"'
end

pro run_lasco_parity, output_json
  if n_elements(output_json) eq 0 then output_json = 'lasco_parity.json'

  openw, lu, output_json, /get_lun
  printf, lu, '{'

  ; DDIS/ECS time parsing.
  _json_pair, lu, 'ddis_2_digit', _json_string(ddistim2ecs('970307_010203'))
  _json_pair, lu, 'ddis_4_digit', _json_string(ddistim2ecs('19970307_010203'))

  ; Base-32 conversions.
  _json_pair, lu, 'inttob32_1023', _json_string(inttob32(1023, 2))
  _json_pair, lu, 'b32toint_vv', strtrim(string(b32toint('VV')), 2)

  ; Calibration factors from synthetic FITS headers.
  h = strarr(40)
  fxhmake, h, fltarr(2, 2)
  fxaddpar, h, 'DETECTOR', 'C3'
  fxaddpar, h, 'FILTER', 'Clear'
  fxaddpar, h, 'POLAR', 'CLEAR'
  fxaddpar, h, 'DATE-OBS', '2005-01-01T00:00:00.000'
  fxaddpar, h, 'SUMCOL', 2
  fxaddpar, h, 'SUMROW', 1
  fxaddpar, h, 'LEBXSUM', 2
  fxaddpar, h, 'LEBYSUM', 1
  _json_pair, lu, 'c3_clear_calfactor', strtrim(string(c3_calfactor(h)), 2)

  h2 = h
  fxaddpar, h2, 'DETECTOR', 'C2'
  fxaddpar, h2, 'FILTER', 'Orange'
  _json_pair, lu, 'c2_orange_calfactor', strtrim(string(c2_calfactor(h2)), 2), /last

  printf, lu, '}'
  close, lu
  free_lun, lu
end
