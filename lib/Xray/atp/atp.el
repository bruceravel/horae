;;; atp.el --- major mode for editing Atoms template files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Author:  Bruce Ravel <bravel@anl.gov>
;; Maintainer:  Bruce Ravel <bravel@anl.gov>
;; Created:  25 September 1998
;; Updated:  20 November 2000
;; Version:  see `atp-version'
;; Keywords:  atoms, atp, atoms template files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This file is not part of GNU Emacs.
;;
;; Copyright (C) 1998-2006 Bruce Ravel
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Massachusettes Ave,
;; Cambridge, MA 02139, USA.
;;
;; Everyone is granted permission to copy, modify and redistribute this
;; and related files provided:
;;   1. All copies contain this copyright notice.
;;   2. All modified copies shall carry a prominant notice stating who
;;      made modifications and the date of such modifications.
;;   3. The name of the modified file be changed.
;;   4. No charge is made for this software or works derived from it.
;;      This clause shall not be construed as constraining other software
;;      distributed on the same medium as this software, nor is a
;;      distribution fee considered a charge.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Please note that most of Atoms is distributed under the terms of
;; the Artistic License.  This file is the exception.  This file is
;; distributed under the terms of the GNU Public License.  This
;; distinction is mostly one of convenience, but also due to the
;; nature of the GPL.  Basically, Emacs is a GPL application, thus
;; this emacs-lisp program is also GPL.  Perl is itself released
;; under the AL, so Atoms -- a perl application -- is released under
;; that license as well.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Installation:
;;
;;  Put this file in your lisp load-path and byte compile it.  Add the
;;  following to your .emacs file
;;
;;  (setq load-path (append (list ("\\.atp$" . atp-mode)) load-path))
;;  (autoload 'atp-mode "atp" "Atoms template mode." t)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;  This is a simple major mode for editing Atoms template (atp)
;;  files.  Because the syntax of the atp files is rather rigid and
;;  unforgiving, it is useful to have a tool to help write these
;;  files.  The main purposes of this mode are to highlight (thus
;;  checking spelling), perform tagword completion, and perform syntax
;;  checking.
;;
;;     M-tab or M-ret    complete keyword at point
;;          M-?          describe keyword at point
;;        C-c C-k        display all tagwords in a buffer
;;        C-c C-c        perform syntax check
;;        C-c C-n        scroll through errors after syntax check
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; History:
;;   0.1  initial version
;;   0.2  (BR Feb 23 1999) completion function, tagword description
;;   0.3  (BR Apr 29 1999) syntax checker
;;   1.6  (BR May 26 1999) use cvs number as version number, added
;;        several new tagwords (number ???)
;;   1.1  (BR Jun 17 1999) added new token for dafs and atoms atp files
;;   1.2  (BR Aug 14 1999) added tagword display, fixed menu bug
;;   1.3  (BR Aug 18 1999) actually fixed menu bug ;-) added atp-identify
;;        function
;;   (BR Nov 14 1999) added <utag> <fx> <fy> <fz>
;;   (BR Nov 30 1999) gnxas functionality <gnclass> <redge> <nabs> <gnid>
;;                    gnxas option to symmetry file, :gnxas to <meta>
;;                    <nabs> and <abslist>, <rx>, <ry>, <rz> for gnxas
;;                    sym file
;;   (BR Dec 18 2001) moved :margin to the meta tagword
;;   (BR Aug 14 2005) added and fontified atp tag for file magic
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; To do:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Code:

;; (require 'easymenu)
(require 'cl)

(eval-and-compile
  (condition-case ()
      (require 'custom)
    (error nil))
  (if (and (featurep 'custom) (fboundp 'custom-declare-variable))
      nil ;; We've got what we needed
    ;; We have the old custom-library, hack around it!
    (if (fboundp 'defgroup)
        nil
      (defmacro defgroup (&rest args)
        nil))
    (if (fboundp 'defface)
        nil
      (defmacro defface (var values doc &rest args)
        (` (progn
             (defvar (, var) (quote (, var)))
             ;; To make colors for your faces you need to set your .Xdefaults
             ;; or set them up ahead of time in your .emacs file.
             (make-face (, var))
             ))))
    (if (fboundp 'defcustom)
        nil
      (defmacro defcustom (var value doc &rest args)
        (` (defvar (, var) (, value) (, doc)))))))

;(defconst atp-cvs-version
;  "$Id: atp.el,v 1.5 2000/11/21 01:18:17 bruce Exp $")
(defconst atp-version          "1.6 for Atoms 3.0.1")
(defconst atp-author           "Bruce Ravel")
(defconst atp-maintainer-email "bravel@anl.gov")
(defconst atp-atoms-url        "http://cars9.uchicago.edu/~ravel/software/")

(defgroup atp nil
  "Atoms template mode for Emacs."
  :prefix "atp-"
  :group 'local)

(defcustom atp-mode-hook nil
  "*Hook run when atp minor mode is entered."
  :group 'atp
  :type 'hook)
(defcustom atp-load-hook nil
  "*Hook run when atp.el is first loaded."
  :group 'atp
  :type 'hook)
(defcustom atp-check-buffer-name "*atp-check*"
  "*Name of buffer used to display syntax errors."
  :group 'atp
  :type 'string)
(defcustom atp-keywords-buffer-name "*atp-keywords*"
  "Name of buffer used to display list of ATP tagwords."
  :group 'atp
  :type 'string)

(defvar atp-tagwords-alist nil
  "Alist of tagword properties.")
(setq atp-tagwords-alist
      (list '("1bou"        3 "one bounce flag")
	    '(":file"       6 "file type meta data")
	    '(":feff"       6 "feff version meta data")
	    '(":display"    6 "potential list display flag")
	    '(":incbegin"   6 "beginning of the incremented index")
	    '(":ipots"      6 "potential assignment scheme")
	    '(":gcd"        6 "greatest common denominator flag")
	    '(":gnxas"      6 "GNXAS flag")
	    '(":lines"      6 "fixed number of title lines")
	    '(":list"       6 "list type meta-data")
	    '(":mol"        6 "molecule cluster flag")
	    '(":output"     6 "default output file name")
	    '(":ccupancy"   6 "dopants display flag")
	    '(":precision"  6 "numeric precision meta-data")
	    '(":prefix"     6 "prefix string for a text block")
	    '(":prettyline" 6 "McMaster corrections delimiter")
	    '(":margin"     6 "margin for the overfull list type")
	    '(":sphere"     6 "small sphere multiplier for feff8")
	    '(":style"      6 "list type")
	    '("a"           1 "a lattice constant (or amplitude in a DAFS/powder list)")
	    '("abslist"     1 "comma separated list of absorber sites")
	    '("asqr"        3 "amplitude squared of a point in a DAFS/powder list")
	    '("atp"         5 "file(1) magic for atp files")
	    '("alpha"       1 "angle between b and c")
	    '("b"           1 "b lattice constant")
	    '("beta"        1 "angle between a and c")
	    '("bravais"     1 "bravais vectors")
	    '("c"           1 "c lattice constant")
	    '("central"     1 "central atom element symbol")
	    '("class"       1 "crystal class of the lattice")
	    '("com"         5 "an ignored comment line")
	    '("corrections" 4 "McMaster corrections")
	    '("ctag"        1 "central atom tag")
	    '("dafs"        2 "list in energy from a DAFS calculation")
	    '("dspacing"    1 "d-spacing of the chosen reflection")
	    '("e"           3 "energy of a point in a DAFS list")
	    '("ease"        4 "local variables for EASE")
	    '("edge"        1 "edge symbol")
	    '("eedge"       1 "edge energy")
	    '("elem"        3 "symbol of an element in a list")
	    '("emax"        1 "maximum energy of a DAFS calculation")
	    '("emin"        1 "minimum energy of a DAFS calculation")
	    '("energy"      1 "energy for a powder diffraction simulation")
	    '("estep"       1 "energy step of a DAFS calculation")
	    '("fuse"        4 "synonym for ease")
	    '("fx"          3 "formula for the x coordinate of a site")
	    '("fy"          3 "formula for the y coordinate of a site")
	    '("fz"          3 "formula for the z coordinate of a site")
	    '("fxc"         1 "central atom x-coordinate formula")
	    '("fyc"         1 "central atom y-coordinate formula")
	    '("fzc"         1 "central atom z-coordinate formula")
	    '("gamma"       1 "angle between a and b")
	    '("given"       1 "space group symbol as supplied by the user")
	    '("gncell"      4 "unit cell information in the GNXAS format")
	    '("gnclass"     1 "crystal class symbol for GNXAS files")
	    '("gnid"        1 "silly identifier for GNXAS files")
	    '("group"       1 "space group number")
	    '("h"           3 "miller index in a powder list")
	    '("i"           3 "imaginary part of a point in a DAFS/powder list")
	    '("id"          4 "information identifying Atoms and it author")
	    '("iedge"       1 "edge index")
	    '("inc"         3 "incremented list index")
	    '("ipot"        3 "unique potential of the atom in a cluster")
	    '("itag"        3 "indexed tag of the atom in a cluster")
	    '("k"           3 "miller index in a powder list")
	    '("l"           3 "angular momentum in a list (or miller index)")
	    '("lambda"      1 "wavelength for a powder diffraction simulation")
	    '("lp"          3 "Lorentz-polarization correction in a powder list")
	    '("list"        2 "list of atoms")
	    '("meta"        5 "atp meta-data")
	    '("nabs"        1 "number of sites occupied by the absorber")
	    '("occ"         3 "occupancy of a point in an atoms list")
	    '("os"          1 "name of the operating system")
	    '("mult"        3 "multiplicity in a powder list")
	    '("nclus"       1 "size of the list")
	    '("p"           3 "phase of a point in a DAFS/powder list")
	    '("potentials"  2 "list of unique potentials")
	    '("powder"      2 "list for a powder diffraction simulation")
	    '("r"           3 "the radial distance of an atom in a cluster")
	    '("redge"       1 "edge energy in Rydbergs")
	    '("reflection"  1 "Miller indeces of the reflection")
	    '("resource"    4 "Absorption data resource")
	    '("rmax"        1 "radial size of the cluster")
	    '("rnn"         1 "nearest neighbor distance")
	    '("rss"         1 "small sphere radius (default: 2.2*rnn)")
	    '("rx"          3 "x rotation in GNXAS SYM file")
	    '("ry"          3 "y rotation in GNXAS SYM file")
	    '("rz"          3 "z rotation in GNXAS SYM file")
	    '("space"       1 "canoncalized space group symbol")
	    '("setting"     1 "crystallographic setting")
	    '("shift"       4 "shift vector on a line of its own")
	    '("stoi"        3 "stoichiometry of a unique potential")
	    '("tag"         3 "tag of an atom in a list")
	    '("th"          3 "theta angle in a powder list")
	    '("titles"      4 "user supplied title lines")
	    '("tth"         3 "2theta angle in a powder list")
	    '("utag"        3 "unique tag of an atom in a list")
	    '("x"           3 "x coordinate of an atom in a cluster")
	    '("y"           3 "y coordinate of an atom in a cluster")
	    '("z"           3 "z coordinate of an atom in a cluster")
	    '("znum"        3 "Z number of an atom in a cluster")
	    ))

(defsubst atp-tagword-type        (obj) (elt (assoc obj atp-tagwords-alist) 1))
(defsubst atp-tagword-description (obj) (elt (assoc obj atp-tagwords-alist) 2))


(defvar atp-tagwords nil
  "A list of tagwords used in Atoms template files.")
(defun atp-make-tagwords-list ()
  (let ((list ()) (alist atp-tagwords-alist))
    (while alist
      (setq list  (append list (list (caar alist)))
	    alist (cdr alist)))
    list))
;; (setq atp-tagwords
;;       '("1bou" ":file" ":incbegin" ":ipots" ":list" ":precision"
;;       ":output" ":prefix" ":margin" ":sphere" ":gcd" ":mol" ":display"
;; 	":prettyline" ":style" ":lines" "a" "alpha" "atp" "b" "beta" "bravais" "c"
;; 	"central" "class" "com" "ctag" "corrections" "edge" "eedge"
;; 	"elem" "fuse" "gamma" "given" "id" "iedge" "inc" "ipot" "itag"
;; 	"l" "list" "meta" "os" "nclus" "potentials" "r" "rmax" "space"
;; 	"setting" "stoi" "tag" "titles" "x" "y" "z" "znum" "shift"))


(defvar atp-mode-map nil)
(if atp-mode-map
    ()
  (setq atp-mode-map (make-sparse-keymap))
  (define-key atp-mode-map "\M-\t"    'atp-complete-tagword)
  (define-key atp-mode-map "\M-\r"    'atp-complete-tagword)
  (define-key atp-mode-map "\M-?"     'atp-describe-tagword)
  (define-key atp-mode-map "\C-c\C-k" 'atp-display-tagwords)
  (define-key atp-mode-map "\C-c\C-c" 'atp-check-file)
  (define-key atp-mode-map "\C-c\C-n" 'atp-find-next-error)
  )

(defvar atp-mode-menu nil)
(defvar atp-menu nil
  "Menu for atp mode.")
(setq atp-menu
      '("ATP"
	["Describe tagword"     atp-describe-tagword   t]
	["Display all tagwords" atp-display-tagwords   t]
	"---"
	["Check file"           atp-check-file         t]
	["Next error"           atp-find-next-error    t]
	"---"
	["Version"              atp-identify           t]
	))


(defvar atp-mode-syntax-table nil
  "Syntax table in use in `atp-mode' buffers.")
(if atp-mode-syntax-table
    ()
  (setq atp-mode-syntax-table (make-syntax-table))
  (modify-syntax-entry ?<  "(>"  atp-mode-syntax-table)
  (modify-syntax-entry ?>  ")<"  atp-mode-syntax-table)
  (modify-syntax-entry ?:  "w"   atp-mode-syntax-table)
  (modify-syntax-entry ?.  "w"   atp-mode-syntax-table)
  )



(defun atp-complete-tagword ()
  "Perform completion on tagword preceding point.
This is a pretty simple minded completion function.  It is loosely
adapted from `lisp-complete-symbol'."
  (interactive)
  (let* ((end (point))
	 (beg (unwind-protect (save-excursion (backward-sexp 1) (point))))
	 (patt (buffer-substring beg end))
	 (pattern (if (string-match "\\([^ \t]*\\)\\s-+$" patt)
		      (match-string 1 patt) patt))
	 (alist (mapcar 'list atp-tagwords))
	 (completion (try-completion pattern alist)))
    (cond ((eq completion t))
	  ((null completion)
	   (message "No atp tagwords complete \"%s\"" pattern))
	  (t
	   (when (not (string= pattern completion))
	     (delete-region beg end)
	     (insert completion)
	     (atp-describe-tagword completion))
	   (let* ((list (all-completions pattern alist))
		  (mess (format "\"%s\" could be one of %S" pattern list))
		  (orig (current-buffer))
		  (buff (get-buffer-create "*atp-completions*")))
	     (if (< (length mess) (frame-width))
		 (if (> (length list) 1) (message mess))
	       (switch-to-buffer-other-window buff)
	       (insert mess)
	       (fill-region (point-min) (point-max))
	       (goto-char (point-min))
	       (enlarge-window
		(+ 2 (- (count-lines (point-min) (point-max))
			(window-height))))
	       (sit-for (max (length list) 15))
	       (switch-to-buffer orig)
	       (kill-buffer buff)
	       (delete-other-windows) ))) )))


(defun atp-this-word ()
  "Return the word near point."
  (let (begin)
    (save-excursion
      (or (looking-at "\\<") (= (current-column) 0) (forward-word -1))
      (if (looking-at (regexp-quote "<")) (forward-char 1))
      (setq begin (point-marker))
      (forward-word 1)
      (buffer-substring-no-properties begin (point)))))


(defun atp-describe-tagword (&optional word)
  "Issue a message describing the tagword WORD."
  (interactive)
  (setq word (or word (atp-this-word)))
  (let ((type (atp-tagword-type word)) note (l "<") (r ">"))
    (cond ((equal type 1)
	   (setq note "is replaced by the"))
	  ((equal type 2)
	   (setq note "represents a"))
	  ((equal type 3)
	   (setq note "is replaced by the"))
	  ((equal type 4)
	   (setq note "is replaced by the"))
	  ((equal type 5)
	   (setq note "denotes"))
	  ((equal type 6)
	   (setq note "takes the" l "" r "")) )
    (message "%s%s%s %s %s" l word r note (atp-tagword-description word))))


(defvar atp-matches-alist nil
  "Alist of error check regular expressions.")
(setq atp-matches-alist
      (list
       (cons ":incbegin"   "\\b[+-]?[0-9]+\\b")
       (cons ":lines"      "\\b[0-9]+\\b")
       (cons ":list"       (concat "\\b\\(atoms\\|cluster\\|dafs\\|neutral\\|"
				   "overfull\\|powder\\|symmetry\\|unit\\)\\b"))
       (cons ":style"      (concat "\\b\\(atoms\\|cluster\\|neutral\\|"
				   "overfull\\|symmetry\\|unit\\)\\b"))
       (cons ":ipots"      "\\b\\(sites\\|species\\|tags\\)\\b")
       (cons ":gcd"        "\\b[01]\\b")
       (cons ":margin"     "\\b-?[0-9]+\\.[0-9]\\b")
       (cons ":gnxas"      "\\b[01]\\b")
       (cons ":mol"        "\\b[01]\\b")
       (cons ":display"    "\\b[01]\\b")
       (cons ":occupancy"  "\\b[01]\\b")
       (cons ":sphere"     "\\b[0-9]+\\.[0-9]\\b")
       (cons ":precision"  "\\b[0-9]+\\.[0-9]\\b")
       (cons ":prettyline" "\\b[01]\\b")
       (cons "pot"  "\\b\\(elem\\|ipot\\|l\\|stoi\\|znum\\)\\b")
       (cons "list" (concat "\\b\\(1bou\\|[brxyz]\\|elem\\|"
			    "f\\(x\\|y\\|z\\)\\|"
			    "i\\(nc\\|pot\\|tag\\)\\|occ\\|"
			    "r\\(x\\|y\\|z\\)\\|tag\\|znum\\)\\b"))
       (cons "dafs" "\\b\\([aeipr]\\|asqr\\|inc\\|occ\\)\\b")
       (cons "powder" "\\b\\([ahiklpr]\\|asqr\\|inc\\|lp\\|mult\\|th\\|tth\\)\\b")
       ))
(defvar atp-messages-alist nil
  "Alist of error check message formats.")
(setq atp-messages-alist
      (list
       (cons ":incbegin" "%3s: \":incbegin\" takes an integer argument")
       (cons ":lines" "%3s: \":lines\" takes a non-negative integer argument")
       (cons ":list"
	     (concat "%3s: \":list\" must be one of atoms, "
		     "cluster, dafs, powder, overfull, symmetry, or unit"))
       (cons ":style"
	     (concat "%3s: \":style\" must be one of atoms, "
		     "cluster, overfull, symmetry, or unit"))
       (cons ":ipots"
	     "%3s: \":ipots\" must be one of species, tags, or sites")
       (cons ":gcd" "%3s: \":gcd\" should be 1 or 0 (true/false)")
       (cons ":mol" "%3s: \":mol\" should be 1 or 0 (true/false)")
       (cons ":gnxas" "%3s: \":gnxas\" should be 1 or 0 (true/false)")
       (cons ":display" "%3s: \":mol\" should be 1 or 0 (true/false)")
       (cons ":occupancy" "%3s: \":occupancy\" should be 1 or 0 (true/false)")
       (cons ":margin"
	     "%3s: \":margin\" takes a floating point number")
       (cons ":precision"
	     "%3s: \":precision\" takes a format specification of the form #.#")
       (cons ":prefix"     "prefix string for a text block")
       (cons ":prettyline" "%3s: \":prettyline\" should be 1 or 0 (true/false)")
       (cons ":sphere"
	     "%3s: \":sphere\" takes a floating point number")
       (cons "modifier"    "%3s: \"%s\" is not a <%s> modifier")
       (cons "pot"
	     (concat "%3s: \"%s\" is not a potential list tag\n\t"
		     "should be one of (elem ipot l stoi znum)"))
       (cons "list"
	     (concat "%3s: \"%s\" is not an atoms list tag\n\t"
		     "should be one of "
		     "(x y z r elem inc ipot itag tag znum 1bou occ b)"))
       (cons "dafs"
	     (concat "%3s: \"%s\" is not a dafs list tag\n\t"
		     "should be one of (e a asqr r i p occ inc)"))
       (cons "powder"
	     (concat "%3s: \"%s\" is not a powder list tag\n\t"
		     "should be one of (a asqr r i p h k l mult lp inc)"))
       ))

(defvar atp-error-marker nil)

(defun atp-check-file ()
  "Check the syntax of the current atp file."
  (interactive)
  (let (match word outbuf (error-list ()))
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
	(when (re-search-forward "<\\(\\w+\\)" (point-max) "to_end")
	  (setq match (match-string 1))
	  (cond
	   ;; not a keyword
	   ((not (assoc match atp-tagwords-alist))
	    (setq error-list
		  (append error-list
			  (list
			   (format
			    "%3s: \"%s\" is not a keyword"
			    (count-lines (point-min) (point)) match)))))
	   ;; type 1 keyword with whitespace
	   ((= 1 (atp-tagword-type match))
	    (or (looking-at ">")
		(setq error-list
			(append
			 error-list
		       (list (format
			"%3s: \"%s\" must be surrounded by <> with no white space"
			(count-lines (point-min) (point)) match))))))
	   ;; comment -- skip line
	   ((string= match "com")
	    (forward-line 1))
	   ;; meta line
	   ((string= match "meta")
	    (let ((b (point)))
	      (while (not (looking-at "[ \t]*>"))
		(unless (looking-at "[ \t]*>") (forward-sexp 1))
		(setq word (atp-this-word))
		(cond
		 ((member* word '(":precision" ":incbegin" ":list"
				  ":sphere" ":occupancy" ":margin")
			   :test 'string=)
		  (forward-sexp 1)
		  (unless (string-match (cdr (assoc word atp-matches-alist))
					(atp-this-word))
		    (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc word atp-messages-alist))
			     (count-lines (point-min) (point)) ))))))
		 ((member* word '(":file" ":output" ":feff" ":gnxas")
			   :test 'string=)
		  (forward-sexp 1) )
		 (t
		  (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc "modifier" atp-messages-alist))
			     (count-lines (point-min) (point))
			     word "meta"))))) ) )
	      (goto-char b)
	      (forward-line 1)) )
	   ;; corrections line
	   ((string= match "corrections")
	    (let ((b (point)))
	      (while (not (looking-at "[ \t]*>"))
		(unless (looking-at "[ \t]*>") (forward-sexp 1))
		(setq word (atp-this-word))
		(cond
		 ((string= word ":prefix")
		  (forward-sexp 1) )
		 ((string= word ":units")
		  (forward-sexp 1) )
		 ((string= word ":prettyline")
		  (forward-sexp 1)
		  (unless (string-match (cdr (assoc word atp-matches-alist))
					(atp-this-word))
		    (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc word atp-messages-alist))
			     (count-lines (point-min) (point)) ))))))
		 (t
		  (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc "modifier" atp-messages-alist))
			     (count-lines (point-min) (point))
			     word "corrections"))))) ) )
		(goto-char b)
		(forward-line 1)) )
	   ;; titles, id, resource line
	   ((member* match '("titles" "id" "resource" "shift") :test 'string=)
	    (let ((b (point)))
	      (while (not (looking-at "[ \t]*>"))
		(unless (looking-at "[ \t]*>") (forward-sexp 1))
		(setq word (atp-this-word))
		(cond
		 ((string= word ":prefix")
		  (forward-sexp 1))
		 ((and (string= word ":lines") (string= match "titles"))
		  (forward-sexp 1)
		  (unless (string-match (cdr (assoc word atp-matches-alist))
					(atp-this-word))
		    (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc word atp-messages-alist))
			     (count-lines (point-min) (point)) ))))))
		 (t
		  (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc "modifier" atp-messages-alist))
			     (count-lines (point-min) (point))
			     word match))))) ) )
		(goto-char b)
		(forward-line 1)) )
	   ;; fuse line
	   ((or (string= match "ease") (string= match "fuse"))
	    (let ((b (point)))
	      (while (not (looking-at "[ \t]*>"))
		(unless (looking-at "[ \t]*>") (forward-sexp 1))
		(setq word (atp-this-word))
		(cond
		 ((or (string= word ":file") (string= word ":prefix"))
		  (forward-sexp 1))
		 (t
		  (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc "modifier" atp-messages-alist))
			     (count-lines (point-min) (point))
			     word "ease"))))) ) )
		(goto-char b)
		(forward-line 1)) )
	   ;; potentials line
	   ((string= match "potentials")
	    (let ((b (point)))
	      (while (not (looking-at "[ \t]*>"))
		(unless (looking-at "[ \t]*>") (forward-sexp 1))
		(setq word (atp-this-word))
		(cond
		 ((member* word '(":ipots" ":gcd" ":mol" ":display")
			   :test 'string=)
		  (forward-sexp 1)
		  (unless (string-match (cdr (assoc word atp-matches-alist))
					(atp-this-word))
		    (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc word atp-messages-alist))
			     (count-lines (point-min) (point)) ))))))
		 (t
		  (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc "modifier" atp-messages-alist))
			     (count-lines (point-min) (point))
			     word "potentials"))))) ) )
		(goto-char b)
		(forward-line 1))
	    (let ((list-line (buffer-substring-no-properties
			      (point)
			      (save-excursion (end-of-line) (point))))
		  b e m)
	      (while (not (string= list-line ""))
		(setq b (or (string-match "<" list-line) (1- (length list-line)))
		      e (or (string-match ">" list-line) (length list-line))
		      m (substring list-line (1+ b) e))
		(unless (or (= (1+ b) e)
			    (string-match
			     (cdr (assoc "pot" atp-matches-alist)) m))
		    (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc "pot" atp-messages-alist))
			     (1+ (count-lines (point-min) (point))) m )))))
		(setq list-line (if (= (1+ b) e) ""
				  (substring list-line (1+ e))) )))
	    (forward-line 1) )
	   ;; list line
	   ((string= match "list")
	    (let ((b (point)))
	      (while (not (looking-at "[ \t]*>"))
		(unless (looking-at "[ \t]*>") (forward-sexp 1))
		(setq word (atp-this-word))
		(cond
		 ((member* word '(":style") :test 'string=)
		  (forward-sexp 1)
		  (unless (string-match (cdr (assoc word atp-matches-alist))
					(atp-this-word))
		    (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc word atp-messages-alist))
			     (count-lines (point-min) (point)) ))))))
		 (t
		  (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc "modifier" atp-messages-alist))
			     (count-lines (point-min) (point))
			     word "list"))))) ) )
		(goto-char b)
		(forward-line 1))
	    (let ((list-line (buffer-substring-no-properties
			      (point)
			      (save-excursion (end-of-line) (point))))
		  b e m)
	      (while (not (string= list-line ""))
		(setq b (or (string-match "<" list-line) (1- (length list-line)))
		      e (or (string-match ">" list-line) (length list-line))
		      m (substring list-line (1+ b) e))
		(unless (or (= (1+ b) e)
			    (string-match
			     (cdr (assoc "list" atp-matches-alist)) m))
		    (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc "list" atp-messages-alist))
			     (1+ (count-lines (point-min) (point))) m )))))
		(setq list-line (if (= (1+ b) e) ""
				  (substring list-line (1+ e))) )))
	    (forward-line 1) )
	   ;; dafs line
	   ((or (string= match "dafs") (string= match "powder"))
	    (forward-line 1)
	    (let ((list-line (buffer-substring-no-properties
			      (point)
			      (save-excursion (end-of-line) (point))))
		  b e m)
	      (while (not (string= list-line ""))
		(setq b (or (string-match "<" list-line) (1- (length list-line)))
		      e (or (string-match ">" list-line) (length list-line))
		      m (substring list-line (1+ b) e))
		(unless (or (= (1+ b) e)
			    (string-match
			     (cdr (assoc match atp-matches-alist)) m))
		    (setq error-list
			  (append
			   error-list
			   (list
			    (format
			     (cdr (assoc match atp-messages-alist))
			     (1+ (count-lines (point-min) (point))) m )))))
		(setq list-line (if (= (1+ b) e) ""
				  (substring list-line (1+ e))) )))
	    (forward-line 1) )

	   ))))
    (if (get-buffer atp-check-buffer-name) (kill-buffer atp-check-buffer-name))
    (if error-list
	(progn
	  (setq outbuf (get-buffer-create atp-check-buffer-name))
	  (switch-to-buffer-other-window outbuf)
	  (erase-buffer)
	  (insert "line      error\n" (make-string 72 ?-) "\n")
	  (while error-list
	    (insert (format "%s" (car error-list)) "\n")
	    (setq error-list (cdr error-list)))
	  (insert "\n\n" (substitute-command-keys "\\[atp-find-next-error]")
		  " scrolls through the errors.\n")
	  (help-mode)
	  (font-lock-mode)
	  (goto-char (point-min))
	  (setq atp-error-marker (point-marker))
	  (other-window 1))
      (message "No syntax errors found in this atp file."))
    ))

(defun atp-find-next-error ()
  "Move point to the line containing the next syntax error."
  (interactive)
  (if (get-buffer atp-check-buffer-name)
      (let (line)
	(save-excursion
	  (set-buffer (get-buffer atp-check-buffer-name))
	  (goto-char atp-error-marker)
	  (if (re-search-forward "^ *\\([0-9]+\\):" (point-max) "to_end")
	      (setq line (match-string 1)
		    atp-error-marker (point-marker)) ))
	(if line
	    (progn
	      (goto-char (point-min))
	      (forward-line (1- (string-to-number line))))
	  (message "no more errors")))
    (message (substitute-command-keys
	      "First do \\[atp-check-file] to check this file."))))


(defun atp-display-tagwords ()
  "Open a buffer displaying all tagwords for atp files.
Bound to \\[atp-display-tagwords]"
  (interactive)
  (let* (keyword arg-descr
	 (keyword-alist (copy-alist atp-tagwords-alist))
	 (keyword-buffer-name atp-keywords-buffer-name))
    (if (get-buffer keyword-buffer-name)
	(switch-to-buffer-other-window keyword-buffer-name)
      (switch-to-buffer-other-window keyword-buffer-name)
      ;;(erase-buffer)
      (insert "\tATP Tagwords\n\n")
      (insert "Tagword\t\tdescription\n"
	      (concat (make-string 75 ?\-) "\n"))
      (while keyword-alist
	(setq keyword    (caar keyword-alist)
	      arg-descr  (nth 1 (cdar keyword-alist)))
	(insert (format "%-14s %s\n" keyword arg-descr))
	(setq keyword-alist (cdr keyword-alist)))
      (help-mode)
      (setq truncate-lines t
	    buffer-read-only t) )
    (goto-char (point-min)) ))



(defvar atp-font-lock-keywords nil)
(defvar atp-font-lock-keywords-1 nil)
(defvar atp-font-lock-keywords-2 nil)

(defvar atp-tab-face 'atp-tab-face)
(cond ((and (featurep 'custom) (fboundp 'custom-declare-variable))
       (defface atp-tab-face '((((class color))
				       (:background "beige"))
				      (t
				       (:reverse t)))
	 "Face used to mark tabs."
	 :group 'atp))
      (t
       (copy-face 'highlight 'atp-tab-face)
       (set-face-background  'atp-tab-face   "beige") ))


(if (featurep 'font-lock)
    (setq atp-font-lock-keywords
	  (list				; comments
	   (list "<com>.*$" 0 font-lock-comment-face)
	   (list "<atp.*$" 0 font-lock-builtin-face)
					; tagword arguments
	   (list (concat
		  ":"
		  "\\(display\\|f\\(eff\\|ile\\)\\|g\\(cd\\|nxas\\)"
		  "\\|i\\(ncbegin\\|pots\\)\\|li\\(nes\\|st\\)\\|"
		  "o\\(ccupancy\\|utput\\)\\|m\\(argin\\|ol\\)\\|"
		  "pre\\(cision\\|fix\\|ttyline\\)\\|"
		  "s\\(phere\\|tyle\\)\\)\\>")
	     0 font-lock-reference-face)
					; tagwords
	   (list (concat
		  "<\\("
		  "[abcehiklnprxyz]\\|1bou\\|"
		  "a\\(bslist\\|lpha\\|sqr\\)\\|"
		  "b\\(eta\\|ravais\\|x\\|y\\|z\\)\\|"
		  "c\\(entral\\|lass\\|o\\(lor\\|m\\|rrections\\)\\|tag\\)\\|"
		  "d\\(afs\\|spacing\\)\\|"
		  "e\\(ase\\|dge\\|edge\\|lem\\|m\\(ax\\|in\\)\\|nergy\\|step\\)\\|"
		  "f\\(ile\\|use\\|xc?\\|yc?\\|zc?\\)\\|"
		  "g\\(amma\\|iven\\|n\\(c\\(ell\\|lass\\)\\|id\\)\\|roup\\)\\|"
		  "i\\(d\\|edge\\|nc\\|pot\\|tag\\)\\|"
		  "l\\(ambda\\|ist\\)\\|m\\(eta\\|ult\\)\\|n\\(abs\\|clus\\)\\|"
		  "o\\(cc\\|s\\)\\|po\\(tentials\\|wder\\)\\|"
		  "r\\(e\\(dge\\|flection\\|source\\)\\|max\\|nn\\|ss\\|x\\|y\\|z\\)\\|"
		  "s\\(etting\\|hift\\|pace\\|toi\\)\\|"
		  "t\\(ag\\|h\\|itles\\|th\\)\\|utag\\|valence\\|znum"
		  "\\)\\>")
		 1 font-lock-function-name-face)
					; quoted strings
	   (list "[\"]\\([^\"\n]+\\)[\"]" 0 font-lock-string-face)
					; tabs
	   '("\t+" 0 atp-tab-face t)
	   ))
  (setq atp-font-lock-keywords-1 atp-font-lock-keywords)
  (setq atp-font-lock-keywords-2 atp-font-lock-keywords))


(defun atp-identify ()
  "Print an identifier message in the echo area."
  (interactive)
  (message "atp-mode %s by %s <%s>"
	   atp-version atp-author atp-maintainer-email)
  (sleep-for 3)
  (message "Atoms is part of the horae package: %s" atp-atoms-url) )

(defun atp-mode ()
  "Major mode for editing Atoms template (atp) files.
This is a pretty simple emacs mode intended for a pretty simple file
syntax.  Because the atp parsing code in Atoms is fairly rigid and
non-forgiving, the major purpose of this mode is to remind the atp
author of the spellings and arguments of the various tagwords.  A
syntax checker is also provided.  `atp-load-hook' and `atp-mode-hook'
are run when atp.el is loaded and `atp-mode' is started, respectively.

Key bindings:
\\{atp-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (use-local-map atp-mode-map)
  (easy-menu-define			; set up gnuplot menu
   atp-mode-menu atp-mode-map "Menu used in atp-mode"
   atp-menu)
  (easy-menu-add atp-mode-menu atp-mode-map)
  (setq major-mode 'atp-mode
	mode-name "ATP")
  (set (make-local-variable 'comment-start) "<com> ")
  (set (make-local-variable 'comment-end) "")
  (if (featurep 'comment)
      (setq comment-mode-alist
	    (append comment-mode-alist '((atp-mode "<com> ")) )))
  (set-syntax-table atp-mode-syntax-table)
  (make-variable-buffer-local 'font-lock-defaults)
  (setq font-lock-defaults '(atp-font-lock-keywords t t))
  (setq atp-tagwords (atp-make-tagwords-list))
  (turn-on-font-lock)
  (message "atp mode %s -- send bugs to %s"
	   atp-version atp-maintainer-email)
  (run-hooks 'atp-mode-hook))


;;; That's it! ----------------------------------------------------------------


;;;--- any final chores before leaving
(provide 'atp)
(run-hooks 'atp-load-hook)

;;;============================================================================
;;;
;;; atp.el ends here
