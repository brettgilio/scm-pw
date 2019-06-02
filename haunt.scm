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

(define (link name uri)
  `(a (@ (href ,uri)) ,name))

(define* (centered-image url #:optional alt)
  `(img (@ (class "centered-image")
           (src ,url)
           ,@(if alt
                 `((alt ,alt))
                 '()))))

(define (first-paragraph post)
  (let loop ((sxml (post-sxml post))
             (result '()))
    (match sxml
      (() (reverse result))
      ((or (('p ...) _ ...) (paragraph _ ...))
       (reverse (cons paragraph result)))
      ((head . tail)
       (loop tail (cons head result))))))

(define scm-pw-theme
  (theme #:name "scm-pw"
         #:layout
         (lambda (site title body)
           `((doctype "html")
             (head
              (meta (@ (charset "utf-8")))
              (title ,(string-append title " — " (site-title site)))
              ,(stylesheet "reset")
              ,(stylesheet "fonts")
              ,(stylesheet "scm"))
             (body
              (div (@ (class "container"))
                   (div (@ (class "nav"))
                        (ul (li ,(link "'(SCM.PW)" "/"))
                            (li (@ (class "fade-text")) " ")
                            (li ,(link "About" "/about.html"))
			    (li ,(link "Blog" "/index.html"))
                            (li ,(link "Learning" "/learning.html"))
			    (li ,(link "Contributions" "/contributions.html"))
			    (li ,(link "Media" "/media.html")))))
	      (div (@ (class "container"))
                   (div (@ (class "yav"))
                        (ul
			 (li (@ (class "fade-text")) " ")
			 (li ,(link "C" "/c.html"))
			 (li ,(link "Common Lisp" "/common-lisp.html"))
			 (li ,(link "Coq" "/coq.html"))
			 (li ,(link "F#" "/fsharp.html"))
			 (li ,(link "F*" "/fstar.html"))
			 (li ,(link "Haskell" "/haskell.html"))
			 (li ,(link "OCaml" "/ocaml.html"))
			 (li ,(link "Rust" "/rust.html"))
			 (li ,(link "Scheme" "/scheme.html"))))
	      ,body
	      (footer (@ (class "text-center"))
		      (p (@ (class "copyright"))
			 "©2019 Brett Gilio"
			 ,%cc-by-sa-button)
		      (p "Made with "
			 (a (@ (href "https://schemers.org/"))
			    "λ")
			 " using "
			 (a (@ (href "https://gnu.org/software/guile"))
			    "Guile Scheme")
			 "."))))))
         #:post-template
         (lambda (post)
           `((h1 (@ (class "title")),(post-ref post 'title))
	     (div (@ (class "author")) ; XXX: fix class, and spacing
		  ,(post-ref post 'author)
		  " — " ; Em dash, long dash.
                  ,(date->string (post-date post)
                                 "~B ~d, ~Y"))
             (div (@ (class "post"))
                  ,(post-sxml post))))
         #:collection-template
         (lambda (site title posts prefix)
           (define (post-uri post)
             (string-append "/" (or prefix "")
                            (site-post-slug site post) ".html"))

           `((h1 ,title)
             ,(map (lambda (post)
                     (let ((uri (string-append "/"
                                               (site-post-slug site post)
                                               ".html")))
                       `(div (@ (class "summary"))
                             (h2 (a (@ (href ,uri))
                                    ,(post-ref post 'title)))
                             (div (@ (class "date"))
                                  ,(date->string (post-date post)
                                                 "~B ~d, ~Y"))
                             (div (@ (class "post"))
                                  ,(first-paragraph post))
			     (div (@ (class "read"))
				  (a (@ (href ,uri)) "read more ➔")))))
                   posts)))))

(define %collections
  `(("Recent Entries" "index.html" ,posts/reverse-chronological)))

(define parse-lang
  (let ((rx (make-regexp "-*-[ ]+([a-z]*)[ ]+-*-")))
    (lambda (port)
      (let ((line (read-line port)))
        (match:substring (regexp-exec rx line) 1)))))

(define (maybe-highlight-code lang source)
  (let ((lexer (match lang
                 ('scheme lex-scheme)
                 ('xml    lex-xml)
                 ('c      lex-c)
                 (_ #f))))
    (if lexer
        (highlights->sxml (highlight lexer source))
        source)))

(define (sxml-identity . args) args)

(define (highlight-code . tree)
  (sxml-match tree
    ((code (@ (class ,class) . ,attrs) ,source)
     (let ((lang (string->symbol
                  (string-drop class (string-length "language-")))))
       `(code (@ ,@attrs)
             ,(maybe-highlight-code lang source))))
    (,other other)))

(define (highlight-scheme code)
  `(pre (code ,(highlights->sxml (highlight lex-scheme code)))))

(define (raw-snippet code)
  `(pre (code ,(if (string? code) code (read-string code)))))

;; Markdown doesn't support video, so let's hack around that!  Find
;; <img> tags with a ".webm" source and substitute a <video> tag.
(define (media-hackery . tree)
  (sxml-match tree
    ((img (@ (src ,src) . ,attrs) . ,body)
     (if (string-suffix? ".webm" src)
         `(video (@ (src ,src) (controls "true"),@attrs) ,@body)
         tree))))

(define %commonmark-rules
  `((code . ,highlight-code)
    (img . ,media-hackery)
    (*text* . ,(lambda (tag str) str))
    (*default* . ,sxml-identity)))

(define (post-process-commonmark sxml)
  (pre-post-order sxml %commonmark-rules))

(define commonmark-reader*
  (make-reader (make-file-extension-matcher "md")
               (lambda (file)
                 (call-with-input-file file
                   (lambda (port)
                     (values (read-metadata-headers port)
                             (post-process-commonmark
                              (commonmark->sxml port))))))))

(define (static-page title file-name body)
  (lambda (site posts)
    (make-page file-name
               (with-layout scm-pw-theme site title body)
               sxml->html)))

(define c-page
  (static-page
   "C"
   "c.html"
   `((h1 "C")
     (p (i ("Coming soon..."))))))

(define haskell-page
  (static-page
   "Haskell"
   "haskell.html"
   `((h1 "Haskell")
     (p (i ("Coming soon..."))))))

(define coq-page
  (static-page
   "Coq"
   "coq.html"
   `((h1 "Coq")
     (p (i ("Coming soon..."))))))

(define fsharp-page
  (static-page
   "F#"
   "fsharp.html"
   `((h1 "F#")
     (p (i ("Coming soon..."))))))

(define fstar-page
  (static-page
   "F*"
   "fstar.html"
   `((h1 "F*")
     (p (i ("Coming soon..."))))))

(define common-lisp-page
  (static-page
   "Common Lisp"
   "common-lisp.html"
   `((h1 "Common Lisp")
     (p (i ("Coming soon..."))))))

(define ocaml-page
  (static-page
   "OCaml"
   "ocaml.html"
   `((h1 "OCaml")
     (p (i ("Coming soon..."))))))

(define rust-page
  (static-page
   "Rust"
   "rust.html"
   `((h1 "Rust")
     (p (i ("Coming soon..."))))))

(define scheme-page
  (static-page
   "Scheme"
   "scheme.html"
   `((h1 "Scheme")
     (p (i ("Coming soon..."))))))

(define learning-page
  (static-page
   "Learning"
   "learning.html"
   `((h1 "Learning")
     (p (i ("Coming soon..."))))))

(define contributions-page
  (static-page
   "Contributions"
   "contributions.html"
   `((h1 "Contributions")
     (p (i ("Coming soon..."))))))

(define media-page
  (static-page
   "Media"
   "media.html"
   `((h1 "Media")
     (p (i ("Coming soon..."))))))

(define projects-page
  (static-page
   "Projects"
   "projects.html"
   `((h1 "Projects")
     (p (i ("Coming soon..."))))))

(define brett-cv-page
  (static-page
   "Brett Gilio, C.V."
   "cv.html"
   `((div (@ (class "resume-name"))
	  (h2 "Brett M. Gilio")
	  (div (@ (class "resume-sub-name"))
	       "5309 Michigan Ave")
	  (div (@ (class "resume-sub-name"))
	       "Kansas City, MO 64130"))
     (div (@ (class "resume-contact"))
	  "M: +1 816(668-9215) | E: brettg@posteo.net")
     (div (@ (class "resume-update"))
	  "Last Updated: May 5th, 2019")
     (div (@ (class "resume-category"))
	  "Education")
     (div (@ (class "resume-education"))
	  (span (@ (class "floatleft"))
		"University of Missouri - Kansas City")
	  (span (@ (class "floatright"))
		"Add years"))
     (br)
     (div (@ (class "resume-education"))
	  (span (@ (class "educ"))
		"Bachelor of Science - Biology")
	  (br)
	  (span (@ (class "educit"))
		"Minor in Chemistry"))
     (br)
          (div (@ (class "resume-education"))
	  (span (@ (class "floatleft"))
		"University of Missouri - Kansas City")
	  (span (@ (class "floatright"))
		"Add years"))
     (br)
     (div (@ (class "resume-education"))
	  (span (@ (class "educ"))
		"Bachelor of Music - Music Composition"))
     (div (@ (class "resume-category"))
	  "Work Experience")
     (div (@ (class "resume-category"))
	  "Research Experience"))))
  
(site #:title "'(SCM.PW)"
      #:domain "scm.pw"
      #:default-metadata
      '((author . "Brett Gilio")
        (email  . "brettg@posteo.net"))
      #:readers (list commonmark-reader*)
      #:builders (list (blog #:theme scm-pw-theme #:collections %collections)
                       (atom-feed)
                       (atom-feeds-by-tag)
                       about-page
		       brett-cv-page
                       projects-page
		       c-page
		       common-lisp-page
		       coq-page
		       fsharp-page
		       fstar-page
		       haskell-page
		       ocaml-page
		       rust-page
		       scheme-page
		       learning-page
		       contributions-page
		       media-page
                       ;(static-directory "js")
                       (static-directory "css")
                       (static-directory "fonts")
                       (static-directory "images")
                       (static-directory "videos")
                       (static-directory "src")
                       (static-directory "manuals")
		       (static-directory "keys")))
