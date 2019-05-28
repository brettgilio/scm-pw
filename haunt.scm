(use-modules (haunt asset)
             (haunt builder blog)
             (haunt builder atom)
             (haunt builder assets)
             (haunt html)
             (haunt page)
             (haunt post)
             (haunt reader)
             (haunt reader commonmark)
             (haunt site)
             (haunt utils)
             (commonmark)
             (syntax-highlight)
             (syntax-highlight scheme)
             (syntax-highlight xml)
             (syntax-highlight c)
             (sxml match)
             (sxml transform)
             (texinfo)
             (texinfo html)
             (srfi srfi-1)
             (srfi srfi-19)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 match)
             (web uri))

(define (date year month day)
  "Create a SRFI-19 date for the given YEAR, MONTH, DAY"
  (let ((tzoffset (tm:gmtoff (localtime (time-second (current-time))))))
    (make-date 0 0 0 0 day month year tzoffset)))

(define (stylesheet name)
  `(link (@ (rel "stylesheet")
            (href ,(string-append "/css/" name ".css")))))

(define* (anchor content #:optional (uri content))
  `(a (@ (href ,uri)) ,content))

(define %cc-by-sa-link
  '(a (@ (href "https://creativecommons.org/licenses/by-sa/4.0/"))
      "Creative Commons Attribution Share-Alike 4.0 International"))

(define %cc-by-sa-button
  '(a (@ (class "cc-button")
         (href "https://creativecommons.org/licenses/by-sa/4.0/"))
      (img (@ (src "https://licensebuttons.net/l/by-sa/4.0/80x15.png")))))

