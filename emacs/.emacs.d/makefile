SOURCES = \
	dlAbbrevs.el     \
	dlStyleGuide.el  \
	dlUtils.el       \
	dlUtilsExtras.el \
	dlClearcase.el   \
	clearcase.el     \
	find-file.el     \
	imouse.el        \
	myFontLock.el    \
	myKeyBindings.el \
	myUtilities.el   

TARGETS = $(patsubst %.el, %.elc, $(SOURCES))

.PHONY: all clean
all: $(TARGETS)

clean:
	rm -f $(TARGETS)

$(TARGETS) : %.elc : %.el
	@echo '\n*** Compiling $@ ***'
	xemacs -q -batch -eval '(progn (setq load-path ( cons ( expand-file-name "." ) load-path ) ) (byte-compile-file "$<"))'


