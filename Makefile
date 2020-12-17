# Export the org file to html
#
# Targets in this file are:
# html          Export html file from org
# omniexport    Export omni file to image
# export				Copy html, image, css and omni export files to export folder
# watch					Remake html file if the org file is updated
# guard					Refresh browser if the guard specified files are updated
# clean         Clean up generated files
#

EMACS := emacs
SED := gsed
OSASCRIPT := osascript
TEXI2HTML_FLAGS := --html --no-split --css-ref=css/style.css
ORGS := $(wildcard *.org)
HTMLS := $(ORGS:.org=.html)
OMSRCDIR := omni-sources
OMEXPTDIR := omni-exports
IMGSUFFIX := .png
IMGMID := -2x
OMSRCS := $(wildcard $(OMSRCDIR)/*.graffle)
OMEXPTS := $(patsubst $(OMSRCDIR)/%.graffle,$(OMEXPTDIR)/%$(IMGMID)$(IMGSUFFIX),$(OMSRCS))

.PHONY: html
html: $(HTMLS)

.PHONY: omniexport
omniexport: $(OMEXPTS)

.PHONY: export
export: html omniexport
	mkdir -p export
	cp $(HTMLS) export
	cp -R omni-exports export
	cp -R images export
	cp -R css export

.PHONY: watch
watch:
	fswatch -o $(ORGS) | xargs -n1 -I{} make

.PHONY: guard
guard:
	guard

.PHONY: clean
clean:
	rm -rf *.texi *.html omni-exports export

%.html: %.texi
	@echo 'generate $@ from $<'
	@$(MAKEINFO) $(TEXI2HTML_FLAGS) $<
	@echo 'add latex support to $@'
	@$(SED) -i 's~</head>~<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>\n<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>\n</head>~g' $<

%.texi: %.org
	@echo 'generate $@ from $<'
	@$(EMACS) --batch --quick --eval '$(call org2texi,$(realpath $<))'

# (call export,src)
define org2texi
(progn\
(find-file "$1")\
(org-texinfo-export-to-texinfo))
endef

$(OMEXPTDIR)/%$(IMGMID)$(IMGSUFFIX): $(OMSRCDIR)/%.graffle
	@echo 'export $< to $@'
	@$(OSASCRIPT) $(call omni2img,$(realpath $<),$(abspath $@))

# (call omni2img,src,export)
define omni2img
-e 'tell application "OmniGraffle"'\
-e 'open POSIX file "$1"'\
-e 'export document 1 as "PNG" scope all graphics to POSIX file "$2" with properties {resolution: 2.0}'\
-e 'close document 1'\
-e 'end tell'
endef

$(OMEXPTS): | $(OMEXPTDIR)

$(OMEXPTDIR):
	@echo 'ensure directory $@' 
	@mkdir -p $(OMEXPTDIR)


