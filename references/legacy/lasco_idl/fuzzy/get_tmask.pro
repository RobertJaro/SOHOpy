;+
; PROJET
;     SOHO - LASCO
; NAME:
;     get_tmask
; PURPOSE:
;     Classify blocks of image level 0.5
; CATEGORY:
;	Masking, Missing Blocks
; CALLING SEQUENCE
;     get_tmask,camera,rebin_index,imsk
; INPUTS
;     camera       string 'C1','C2','C3'     
;     rebin_index  0=1024x1024, 1=512x512, 2,256x256
; KEYWORD INPUTS:
;     none
; OUTPUTS:
;
;     imsk       intarray of 32x32, multivalued image mask of 
;                -2 non useful blocks (NUB) on the corner
;                -1 non useful blocks (NUB) on center
;                1    useful blocks 
;                2    fringe blocs
;                3    NS center fringe blocs
;                4    EW center fringe blocs
;                note: 0 is reserved for non transmitted useful blocks
; PROCEDURE:
;
;
; HISTORY:
;    written by A.LL. May 1996
;-
pro get_tmask,camera,rebin_index,imsk
;
  imsksize = 32
  imsk = intarr(imsksize,imsksize)+1
  channel = strupcase(camera)
;
case channel of
  'C2': begin
   if rebin_index eq 0 then begin
;
; ----- mask of not transmited blocks
;
 lpmsk =                                    $
 [  0,   1,                 30,  31,        $
   32,                           63,        $
  960,                          991,        $
  992, 993,               1022,1023 ]
        nlp = n_elements(lpmsk)
;
 lcmsk = [                                  $
       397, 398, 399, 400, 401,             $
       429, 430, 431, 432, 433, 434,        $
  460, 461, 462, 463, 464, 465, 466, 467,   $
  492, 493, 494, 495, 496, 497, 498, 499,   $
  524, 525, 526, 527, 528, 529, 530, 531,   $
  556, 557, 558, 559, 560, 561, 562, 563,   $
       589, 590, 591, 592, 593, 594,        $ 
            622, 623, 624, 625 ]
        nlc = n_elements(lcmsk)
    endif else begin
        if rebin_index eq 1 then begin
        nlp = 0
 lcmsk = [                                  $
            398, 399, 400, 401,             $
            430, 431, 432, 433,             $
  460, 461, 462, 463, 464, 465, 466, 467,   $
  492, 493, 494, 495, 496, 497, 498, 499,   $
  524, 525, 526, 527, 528, 529, 530, 531,   $
  556, 557, 558, 559, 560, 561, 562, 563,   $
            590, 591, 592, 593,             $ 
            622, 623, 624, 625 ]
        nlc = n_elements(lcmsk)
        endif else begin
           nlp = 0
           nlc = 0
        endelse
    endelse
;
; ----- mask of frange
;
  lfmsk =    [ 333, 334, 335, 336, 337, 338,               $
               365, 366, 367, 368, 369, 370, 371,          $
                                             403, 404,     $
426, 427,                                         436, 437,$ 
458, 459,                                         468, 469,$
490, 491,                                         500, 501,$
522, 523,                                         532, 533,$
554, 555,                                         564, 565,$
     587, 588,                               595, 596,     $
     619, 620, 621,                     626, 627, 628,     $
          652, 653, 654, 655, 656, 657, 658, 659,          $
                    686, 687, 688, 689]
        nlf = n_elements(lfmsk)
;
; ----- mask of frange diameter NS
;
  lfnsmsk = [ 335, 336,         $
              367, 368,         $
              655, 656,         $
              687, 688]
        nlfns = n_elements(lfnsmsk)
;
; ----- mask of frange diameter EW
;
  lfewmsk = [458, 459,   468, 469,$
             490, 491,   500, 501,$
             522, 523,   532, 533]
        nlfew = n_elements(lfewmsk)
        end
  'C3': begin
;
; ----- mask of not transmited blocks
;
        if rebin_index le 0 then begin
  lpmsk = $
[  0,  1,  2,  3,  4,  5,  6,  7,   24, 25, 26, 27, 28, 29, 30, 31 $
, 32, 33, 34, 35, 36, 37                  , 58, 59, 60, 61, 62, 63 $
, 64, 65, 66, 67, 68                          , 91, 92, 93, 94, 95 $
, 96, 97, 98, 99,100                                  ,125,126,127 $
,128,129,130,131,132                                      ,158,159 $
,160,161                                                  ,190,191 $
,192                                                          ,223 $
,224                                                               $
]
;
 lpmsk = [lpmsk                                                    $
,800                                                               $
,832                                                          ,863 $
,864,865                                                      ,895 $
,896,897,898                                              ,926,927 $
,928,929,930,931                                      ,957,958,959 $
,960,961,962,963,964                              ,988,989,990,991 $
,992,993,994,995,996,997            ,1018,1019,1020,1021,1022,1023 $
]       
        nlp = n_elements(lpmsk)
;
  lcmsk = $
         [495,496     $
         ,527,528,529 $
         ,559,560     ]
        nlc = n_elements(lcmsk)
;
        endif else begin
        if rebin_index eq 1 then begin
;
 lpmsk = $
[   0,   1,   2,   3,   4,   5,  26,  27,  28,  29,  30,  31 $
,  32,  33,  34,  35,  36,  37,  58,  59,  60,  61,  62,  63 $
,  64,  65,  66,  67,                                94,  95 $
,  96,  97,  98,  99,                               126, 127 $
, 128, 129,                                         158, 159 $
, 160, 161,                                         190, 191 $
, 896, 897,                                         926, 927 $
, 928, 929,                                         958, 959 $
, 960, 961, 962, 963,                     988, 989, 990, 991 $
, 992, 993, 994, 995,                    1020,1021,1022,1023 ]
       nlp = n_elements(lpmsk)
       nlc = 0
        endif else begin
 lpmsk = $
[   0,   1,   2,   3  $
,  32,  33,  34,  35  $  
,  64,  65,  66,  67  $ 
,  96,  97,  98,  99  ]
       nlp = n_elements(lpmsk)
       nlc = 0
        endelse
        endelse
;
  lfmsk = $
     [462,463,464,465     $
     ,494        ,497,498 $
     ,526            ,530 $
     ,558        ,561,562 $
         ,591,592,593     ]
        nlf = n_elements(lfmsk)
;
  lfnsmsk = $
         [463,464     $
         ,591,592     ]
        nlfns = n_elements(lfnsmsk)
;
  lfewmsk = [ 526,530 ] 
        nlfew = n_elements(lfewmsk)
        end
  else: begin
         print,'%GET_TMASK: WARNING! Unknow channel name: '+camera 
         nlp = 0
         nlc = 0
         nlf = 0
         nlfns = 0
         nlfew = 0
       end
  endcase
;
  if nlp   ne 0 then    imsk(lpmsk) = -2
  if nlc   ne 0 then    imsk(lcmsk) = -1
  if nlf   ne 0 then    imsk(lfmsk) =  2
  if nlfns ne 0 then  imsk(lfnsmsk) =  3
  if nlfew ne 0 then  imsk(lfewmsk) =  4
;
return
end
