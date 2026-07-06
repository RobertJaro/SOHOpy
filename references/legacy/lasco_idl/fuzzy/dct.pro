;+
; NAME:
;	DCT
;
; PURPOSE:
;	Computes the D.C.T. or the Inverse D.C.T.
;
; PROCEDURE:
;	Computes the D.C.T. (Discrete Cosine Transform) or the I.D.C.T.
;	(Inverse D.C.T.) of a 1D or 2D array
;	The D.C.T. values here are deduced from the F.F.T. values
;
; CATEGORY:
;	Transformation
;
; CALLING SEQUENCE:
;	c = dct(x [, direction] )
;
; INPUTS:
;	array		a 1D or 2D array
;
; Optional INPUTS:
;	direction	Direction of the transform :
;			By convention a negative direction means a forward
;			transform, and positive means a inverse transform; 
;			By default, the forward transform is performed
;
; KEYWORD PARAMETERS:
;	INVERSE		perform the inverse transform, reguardless of the value
;			of the direction parameters
;
; OUTPUTS:
;	the DCT spectrum, with the same dimentions as the input array x
;
; REFERENCE:
;	DIGITAL IMAGE PROCESSING ALGORITHM
;	Ioannis Pitas
;	Prentice Hall, (c) 1993
;	(p107-108 for 1D DFT to DCT transform)
;	(p111,113 for 2D DFT to DCT transform)
;
;	See also the IDL documentation about the FFT function
;
; MODIFICATION HISTORY:
;	Written by J. More, November 1996
;-




function dct, array, direction, INVERSE=inverse

;   forward direction (<0) by default
if n_elements(direction) eq 0  then direction = -1

;   inverse transform (>0) if keyword set
if keyword_set(inverse)  then  direction = 1


;   size of array
s = size(array)
dim = s(0)


case dim of


; -----------------------------------------------------------------------------
; ------------------   1D  D.C.T. transform   ---------------------------------
; -----------------------------------------------------------------------------


   1 : begin
                   
          ;   number of subscripts
          n = s(1)
          ;   subscript k
          k = indgen(n)		; k = [0, 1,..., n-1]

          ;   dft factor : W(4N) = e^(-i.2.pi/N)
          w4n = exp(k*complex(0,-2*!pi/(4*n)))

;.........;   forward transform
          if direction lt 0 $
             then begin
                ;   spatial values
                x = array

                ;   subscript 0, 2, ..., 2k, ..., 2n-2k-1, ..., 3, 1
                sub = [k, reverse(k)]
                sub = sub(2*k)
                v = x(sub)
                vv = fft(v)

                ;   DCT coefficients
                c = 2*float( w4n * vv(k) )
                endif $		; direction lt 0   (forward)

;............;   inverse transform
             else begin
                ;   DCT coefficients
                c = array

                vv = 0.5/w4n * complex(c(k),-c(n-k))
                v = fft(vv, /inverse)

                ;   subscript 0, 2, ..., 2k, ..., 2n-2k-1, ..., 3, 1
                sub = [k, reverse(k)]
                sub = sub(2*k)
                ;   spatial values
                x = fltarr(n)
                x(sub) = v 
                endelse		; direction gt 0   (inverse)

       end	; case dim = 1

; -----------------------------------------------------------------------------
; ------------------   2D  D.C.T. transform   ---------------------------------
; -----------------------------------------------------------------------------


      2 : begin
                   
          ;   number of subscripts in each dimension
          n1 = s(1)
          n2 = s(2)
          ;   subscript  k1=0, 1, ..., N1-1     k2=0, 1, ..., N2-1
          k1 = indgen(n1) # replicate(1,n2)
          k2 = replicate(1,n1) # indgen(n2)
          ;   subscript N1-k1 = [N1, N1-1, ..., 1] mod (N1) = 0, N1-1, ..., 1
          ;   subscript N2-k2 = 0, N2-1, N2-2, ..., 1
          n1_k1 = shift(reverse(k1,1),1,0)
          n2_k2 = shift(reverse(k2,2),0,1)

          ;   subscript 0, 2, ..., 2k, ..., 2n-2k-1, ..., 3, 1
          sub1 = [k1, reverse(k1,1)]
          sub1 = sub1 (2*indgen(n1), *)
          sub2 = [[k2], [reverse(k2,2)]]
          sub2 = sub2 (*, 2*indgen(n2))

          ;   dft factor : W(4N1,2) = e^(-i.2.pi/4N1,2)
          w4n1 = exp(k1*complex(0,-2*!pi/(4*n1)))
          w4n2 = exp(k2*complex(0,-2*!pi/(4*n2)))


;.........;   forward transform
          if direction lt 0 $
             then begin
                ;   spatial values
                x = array

                v = x(sub1, sub2)

                vv = fft(v)

                ;   DCT coefficients
                c = 2*float( w4n1 * ( w4n2*vv(k1, k2) +  $
                                      1./w4n2*vv(k1, n2_k2)))

; alternative : c = 2*float( w4n2 * ( w4n1*vv(k1, k2) + $
;                                      1./w4n1*vv(n1_k1, k2)*mask1))

                endif $		; direction lt 0   (forward)


;............;   inverse transform
             else begin
                ;   DCT coefficients
                c = array

                ;   masks used to zero the first element of c(N1-k1)
                ;   => c(N1-k1)*mask1 = [0, c(N1-1), c(N1-2), ..., c(1)] 
                mask1 = replicate(1, n1, n2)
                mask1(0, *) = 0
                mask2 = replicate(1, n1, n2)
                mask2(*, 0) = 0

                vv = 1./4/w4n1/w4n2 * complex( $
                     c(k1, k2) - c(n1_k1, n2_k2)*mask1*mask2, $
                     -(c(n1_k1, k2)*mask1 + c(k1, n2_k2)*mask2) )

                v = fft(vv, /inverse)

                ;   spatial values
                x = fltarr(n1, n2)
                x(sub1, sub2) = v 

                endelse		; direction gt 0   (inverse)

       end		; dim = 2


; -----------------------------------------------------------------------------


      else : c = -1
   endcase



;print, "x = ", x
;print, "v = ", v
;print, "c = "
;print, format='($, a)', " id = dct( "
;form = '($, "[", ' + string(n) + '(f0.0, :, ", "), a)'
;print, format=form, c
;print, "], /inv)"



;			STOP



if keyword_set(inverse) $
   then return, x $
   else return, c

end

