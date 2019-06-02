title: Scheme for the Web
author: Brett Gilio
date: 2019-02-25 18:30
tags: scheme, haunt, scm.pw, blog, about-me, first-post
summary: A new home for Scheme projects
---

At last, the Scheme language has been brought to the web! One of the many
great things I love about the Scheme language is its incredible
versatility. You can find it being used in virtually every domain, and
it manages to scale wonderfully to the needs of experienced and
inexperienced users alike. Scheme, a dialect from the LISP-family, has
been around since the golden days of computer research. The old
photographs of people sitting in front of the
[PDP-1](http://www.computer-history.info/Page4.dir/pages/PDP.1.dir/)
serve as the historical background for MIT wizards like Gerald
Sussman to create the language that would eventually be used in every
academic research domain we can think of: compilers, machine
architecture, biology, natural languages, categorical mathematics, and
more!

Scheme is an old language, one of the oldest still in use today. It has been
through several major and minor revisions, and it has been one of the
more prolific languages in its implementations, offering features that
most people would not see implemented in more corporately-used
languages until the 2000s. Even in recent years (where academia has
been casting away the legacy of Scheme in favor for languages like
[Python](https://www.python.org/)), the structure of Scheme can still
be felt in a variety of non-LISP languages far and wide.

All of this to say, and reiterate the quasi-axiom, that there is
_something_ about Scheme that gives it such a longevity.

Haunt
-----

There seems to have been a resurgent interest in static
websites. Perhaps people are tired of the bloat that seems to be
problematic on the web, or maybe a static website is just such a joy
to maintain (you basically don't have to do anything once the website
is created). Regardless, I think static websites are a joy.

[David Thompson](https://dthompson.us/) seems to agree. David has
created the [Haunt](https://dthompson.us/projects/haunt.html) module
for the [Guile](https://gnu.org/s/guile) implementation of the Scheme 
language. This is truly a remarkable tool, and has been used by many 
Schemers who maintain their own websites. It has functionality to 
support static webpages, embed media, spin up blogs, 
create RSS/Atom feeds and so much more. The extensibility inherent 
in Scheme makes no end to the possibility that Haunt provides.

Haunt is very lightweight and efficient. It takes Scheme code that
you write and generates static HTML/CSS (and optionally JavaScript)
that you may feed to your web server for distribution. It is also
quite fast thanks to the parser built into Guile! Now, you can spin up
your own web content using your new favorite language, Scheme, in no
time at all! Better yet, it is all [free (libre)
software](https://www.gnu.org/philosophy/free-sw.en.html).

### Code Examples

Haunt uses a configuration file to define how it will generate your
website content. I encourage you to read the
[manual](https://dthompson.us/manuals/haunt/index.html)
for Haunt, and visit the official webpage to learn more about 
this. This is __not__ a substitute for the work David, et al. 
have put in. Also, this is __not__ code you can copy
verbatim. Understand the principles behind Haunt, and you can craft
something truly wonderful that will work how _you_ want it.

#### First, lets load some Haunt modules

```scheme
(use-module (haunt site)
            (haunt asset)
			(haunt reader skribe)
			(haunt reader commomark)
			(haunt builder blog)
			(haunt builder assets))
```

Here we have loaded six modules from the Haunt package. The ordering
of modules does not matter, per se; however, I have loaded them
in logical order for the sake of consistency. This is a reduction from my own
configuration file. As you can probably expect, some liberties were
taken in how indentation is used to maintain website readability.

- `(haunt site)` is loaded. This module is used to define and extract
  all of the properties you'd expect for an HTML website. Things like
  the domain name, the title, how addresses are indexed, etc., are all
  defined here. It is understood then that the procedures that
  Haunt uses when invoked will use this information to know how to
  generate your site correctly.
  
  So let's call the site procedure and use some of its arguments.
  
  ```scheme
  (use-modules (haunt site))
  ...
  
  (site #:title "'(SCM.PW)" ; website title
		#:domain "scm.pw"   ; domain name
		#:default-metadata  ; a list of key entries
		'((author . "Brett Gilio")
		  (email  . "brettg@posteo.net"))
		#:readers (list (commonmark-reader*)
                        (skribe-reader*))
		; how to process post entries
		; more on this later...
		#:builders ; procedures for generating output
		          (list (blog)
					    (static-directory "css")
						(static-directory "fonts")
						(static-directory "images")))
						; various directories that will be
						; used to load web content
  ```

- `(haunt asset)` is loaded. Similar to `(haunt site)`, this module is
  used to define how various assets are extracted and loaded into the
  static site directory. Various types of assets include CSS, fonts,
  and images.
  
- `(haunt reader skribe)` & `(haunt reader commonmark)` are
  loaded. The reader modules are used to parse and process text,
  usually from a blog entry. [Commonmark](https://commonmark.org/) is a
  specification of the Markdown language. Similarly,
  [Skribe](https://www-sop.inria.fr/mimosa/fp/Skribe/) is a
  specification of the Scheme language as a markdown-style text
  processor. (Also, check out [Skribilo](https://www.nongnu.org/skribilo/)
  and [Scribble](https://docs.racket-lang.org/scribble/). If you ever
  decide to create a new specification, please refrain from further
  abuse of the _/ˈsk-/_ phonetic.)
  
  We will be using Commonmark in our example, though Skribe/Skribilo
  are orthogonal.
  
  _This example is taken directly from David Thompson's configuration,
  and then reduced._
  
  ```scheme
  (use-modules (haunt reader commonmark)
	           (haunt reader skribe))
  ...

  (define %commonmark-rules
    `((*text* . ,(lambda (tag str) str))
	  (*default* . ,sxml-identity)))
	  ; create a definition to extract sxml
	  ; and convert it into their corresponding
	  ; tag or string element

  (define (post-process-commonmark sxml)
    (pre-post-order sxml %commonmark-rules))
	  ; this definition calls the
	  ; `%commonmark-rules' function and uses
	  ; sxml as an argument to allow for post-processing
	  ; of the text into a web-readable file format.

  (define commonmark-reader*
    (make-reader (make-file-extension-matcher "md")
                 (lambda (file)
                   (call-with-input-file file
                     (lambda (port)
                       (values (read-metadata-headers port)
                               (post-process-commonmark
                                (commonmark->sxml port))))))))
      ; `commonmark-reader*' is defined and uses the functions
	  ; contained in the commonmark module, and the above
	  ; `post-process-commonmark' function to locate a file
	  ; with the .MD extension, read the metadata, and export
	  ; it to an HTML file
  ```
  
- `(haunt builder blog)` & `(haunt builder assets)` are loaded. These
  modules provide a variety of procedures and arguments for defining 
  static content, and manipulating the SXML tree. It gives us the 
  ability to nicely integrate our blog into our website theme with
  relevant CSS and images intact.
  
  ```scheme
  (use-modules (haunt builder blog))
  ...
  
  (theme #:name "scm-pw" ; name to call in builer
         #:layout
         (lambda (site title body) ; SXML tree order
           `((doctype "html")
             (head
              (meta (@ (charset "utf-8"))) ; encoding
              (title ,(string-append title 
		              " — " (site-title site)))
					  ; append an Em-hyphen between the title
					  ; of the page, and the site name
              ,(stylesheet "reset")
              ,(stylesheet "fonts")
              ,(stylesheet "scm"))
			  ; style sheets to load using the assets module
			  
			  ...	  
  ```
  
  After the theme declaration, and the layout of the site, the body
  tag will need to be used in the lambda statement. This is pretty
  self explanatory, and will not be covered in this post. If you need
  help with this section, feel free to email me or David. Or, better
  yet, reference the manual or examples.
  
  ```scheme
  (footer (@ (class "text-center"))
          (p (@ (class "copyright"))
              "© 2019 Brett Gilio, et al."
              ,%cc-by-sa-button) ; defined asset in file
          (p "The text and images on this site are
		     free culture works available under the " 
		     ,%cc-by-sa-link " license.")
          (p "Made with "
             (a (@ (href "https://schemers.org/"))
                 "λ")
              " using "
             (a (@ (href 
				 "https://gnu.org/software/guile"))
             "Guile Scheme")
         "."))))))
		 
		 ...
  ```
  
  Okay, great. We have the header, body, and footer out of the
  way. They are generic in their construction and content. I hope you
  can understand that, and make inferences where you can not. The real
  meat of the exercise with the builder is defining how blog posts
  function.
  
  This is truly the most well-engineered section of Haunt. You can
  roll a blog to be pretty much anything you want. No more limitations
  from Wordpress or your other favorite CMS. Just do what Scheme lets
  you do.
  
  ```scheme
  #:post-template ; generation for blog entry
         (lambda (post)
           `((h1 (@ (class "title")) ; title CSS element
		     ,(post-ref post 'title)) ; retrieve title variable
	     (div (@ (class "author")) ; author CSS element
		  ,(post-ref post 'author) ; trieve author variable
		  " — " ; Separate post author from date.
                  ,(date->string (post-date post) 
				  ; convert date to string
                                 "~B ~d, ~Y")) 
								 ; order of post date
             (div (@ (class "post")) ; post CSS element
                  ,(post-sxml post)))) ; call post-sxml function
         #:collection-template ; generation for blog entry list
         (lambda (site title posts prefix) ; order for SXML tree
           (define (post-uri post) ; definition for post URL
             (string-append "/" (or prefix "")
                 (site-post-slug site post) ".html")) 
				 ; append HTML format
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
							  ; show single paragraph synopsis
                             (a (@ (href ,uri)) "read more ➔"))))
							 ; generate a hyperlink to full post
                   posts)))))
  ```

I hope this is enough information to help open you up to the
possibility of using Haunt for your next (or current) project. I can
not commend David enough for starting this project, and the several
contributors that continue to help extend it to have many new features
every release.

As you can see, Haunt provides a highly accessible interface to
generate your website from Scheme code. The logic can be as terse or
as simple as you want it to be, and you do not have to sacrifice
elegance to achieve more complicated structures in Scheme. Haunt does
a great job complementing your ideas, and lets Scheme do its magic
without getting in the way with arbitrary design impositions. It is
truly a composable system.

_David, thank you for letting me use your website as a template to
create this one. You saved me a lot of time._

SCM.PW
------

As of now, it seems that this website will be organized in a
multi-faceted way. I have intentions of following the tradition that
David Thompson started, creating some Scheme projects (hopefully on
par of that which he created), and maybe some projects in some other
related languages (Common Lisp, anybody?)

Additionally, this will also be organized as a blog on Scheme,
functional programming, programming in general, and likely some
pseudo-political rants on the importance and prevelance of free
software. As of now, it will just be me posting, but perhaps in the
future I will be confident enough to allow others to share their own
blog entries through this website.

In the future, I'd also like this blog to comment on the progress and
releases of projects started here, as well as demonstrate some of the
amazing features of Scheme in small Scheme tutorials. Perhaps this too
will be extended to include other related languages.

Frequent contributors to the blog or projects will be welcomed to
share a small biographical entry on the contributors page. The
contributors page will also be an entry point to my (and their)
contact information, _curriculum vitae_, and other relevant
information as needed. That page is also where you will be able to
find my current GPG key if you wish to send me encrypted email.

If you have made it this far, thank you for taking your time to read
this. I hope it gave you some neat insights into using Scheme as a
static website generator, and also the intent and purpose of this
website as a whole.