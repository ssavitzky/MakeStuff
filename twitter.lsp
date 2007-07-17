;;; make fake modem tones.  Used in "Vampire Megabyte"
;;;	$Id: twitter.lsp,v 1.2 2007-07-17 06:20:49 steve Exp $

;;; c4 ~= 256Hz; let's use c4 and c6
;;; c4 = midi 60; c5=72; c6=84

;;; If we want the actual frequencies used in a 300Baud modem[1]:
;;;   originating station:  mark= 1,270 Hz;  space= 1,070 Hz.
;;;   answering station:    mark= 2,225 Hz;  space= 2,025 Hz.
;;;   [1] http://en.wikipedia.org/wiki/Bell_103_modem

;;; (sine pitch duration)
;;; (step-to-hz 60) -> 261.626
;;;
;;; (char string index) extracts a character from a string
;;; (char-code char) -> integer character code

(defun char-to-bits (theChar) 
  ;; return a list containing the character's bits from left to right
  (let ((theCode (char-code theChar)))
    (mapcar (lambda (bit) (logand bit theCode))
	    '(128 64 32 16 8 4 2 1))))

(defun string-to-chars (theString)
  (if (zerop (length theString)) 
      nil
    (cons (char theString 0) 
	  (string-to-chars (subseq theString 1)))))

(setq zero-note 60)
(setq one-note 84)
(setq bit-dur (/ 4.0 (step-to-hz 60)))

(defun sappend (sound) 
  (s-save sound 50000 "tmp.wav" :format snd-head-none)
  (system "cat tmp.wav >> output.wav")
)

(defun play-bits (theBits)
  (mapc (lambda (n) 
	  (sappend (sine (if (zerop n) zero-note one-note) bit-dur)))
	theBits))

(defun play-string (str)
    (mapc (lambda (c) (play-bits (char-to-bits c))) (string-to-chars str)))

;;; start out with a suitable header.
;;;    you have to do "sox output.wav twitter.wav" to get a file with a 
;;;    correct length header that Audacity will accept.
;;;
(defun start ()
  (s-save (sine zero-note bit-dur) 50000 "output.wav"))

(defun do-it () 
  (start)
  (play-string "You will unload all your data, and then erase it all!")
)
