# hagel - single Makefile static page generator
# Copyright 2015 Patrick Brosi <info@patrickbrosi.de>

BASE = $(abspath html)/
INDEX = /index.html
TEMPLATE = template
P = content
R = render
STATIC = $(abspath static)/
PR = %
PRIM_LANG = en
PRIM_CONT = main
ALLWD_VAR_CHRS = A-Za-z0-9_-

# shorten variable names
B = $(BASE)
I = $(INDEX)
T = $(TEMPLATE)
PLANG = $(PRIM_LANG)
PCONT = $(PRIM_CONT)
S = $(STATIC)

CON_FILES = $(sort $(wildcard $(P)/*/*/*.content))
CON_HTML_FILES = $(subst $(P)/, html/, $(patsubst %.content, %.html, $(CON_FILES)))

LAN_FOLDERS = $(shell find content -maxdepth 1 -mindepth 1 -type d -print)

CAT_FILES = $(wildcard $(P)/*/*/category.info)
CAT_HTML_FILES = $(subst $(P)/, html/, $(patsubst %/category.info, %/index.html, $(CAT_FILES)))
LANG_INDEX_FILES = $(patsubst %,%/index.html,$(subst $(P)/, html/, $(LAN_FOLDERS)))

define var-def
$(eval CATEGORY = $(lastword $(subst /, ,$(subst $(notdir $@),,$(patsubst $(R)/%,%,$@)))))
$(eval LANG = $(firstword $(subst /, ,$(subst $(notdir $@),,$(patsubst $(R)/%,%,$@)))))
$(eval CONTENT = $(subst category,,$(basename $(notdir $<))))
endef

define var-sub
$(var-sub-sub)
@# system call expansion - only one call per line supported - TODO: { and } escaping
@sed -i -e '/\(.*\)$$system{{\(.*\)}}\(.*\)/ { h; s//\1\n\3/; x; s//\2 /e; G;\
	s/\(.*\)\n\(.*\)\n\(.*\)/\2\1\3/; b }' $@
$(var-sub-sub)
endef

define var-sub-sub
$(var-def)
@cat $< | tr '\n' ' ' | sed -e 's|\([$(ALLWD_VAR_CHRS)]*\)={{|\n\1={{|g' -e 's|\\|\\\\|g' \
	-e 's|/|\\/|g' -e 's|\&|\\&|g' | sed 's|\([$(ALLWD_VAR_CHRS)]*\)={{\(.*\)}}|\
	s/$$$(strip $(subst .,,$(suffix $(patsubst %.info,%.category,$<)))){\1}/\2/|'\
	| xargs -0 -I % sed % -i'' $@;

@sed -i -e 's|$$global{BASE_PATH}|$(B)|g' -e 's|$$global{ACTIVE_LANGUAGE}|$(LANG)|g' \
	-e 's|$$global{ACTIVE_CATEGORY}|$(CATEGORY)|g' -e 's|$$category{WEIGHT}|0|g' \
	-e 's|$$content{WEIGHT}|0|g' -e 's|$$content{NAME}|$(CONTENT)|g' \
	-e 's|$$global{INDEX_PATH}|$(I)|g' -e 's|$$global{STATIC_PATH}|$(S)|g' \
	-e 's|$$global{HOME}|$(subst //,/,$(B)$(I))|g' $@

@test -f $(P)/$(LANG)/global.info && cat $(P)/$(LANG)/global.info | tr '\n' ' ' | \
	sed -e 's|\([$(ALLWD_VAR_CHRS)]*\)={{|\n\1={{|g' -e 's|\\|\\\\|g' \
	-e 's|/|\\/|g' -e 's|\&|\\&|g' \
	| sed -e 's|\([$(ALLWD_VAR_CHRS)]*\)={{\(.*\)}}|s/$$global{\1}/\2/|'  \
	| xargs -0 -I % sed % -i'' $@ || :
endef

define menu-sub
$(var-def)
@sed -i -e "s/\$$menu{}/$$(sed -e 's/[\&/]/\\&/g' -e 's/$$/\\n/'\
	$(strip $(subst $(lastword $(subst /, ,$(dir $@)))/, ,$(dir $@)))menu.r | tr -d '\n')/g" $@
@sed -i -e 's|$$__category_active_{$(CATEGORY)}|active|g' \
	-e 's|$$__category_active_{[a-zA-Z0-9]\+}||g' $@

@sed -i -e "s/\$$languageswitcher{}/$$(sed -e 's/[\&/]/\\&/g' -e 's/$$/\\n/'\
	$(R)/lswitch.r | tr -d '\n')/g" $@
@sed -i -e 's|$$__lactive_{$(LANG)}|active|g' -e 's|$$__lactive_{[a-zA-Z0-9]\+}||g' $@
endef

define curcat
$(subst $(realpath $(CURDIR))/$(P)/,,$(realpath $(dir $@)))
endef

.PHONY:
all: $(CAT_HTML_FILES) $(CON_HTML_FILES) $(LANG_INDEX_FILES) html/index.html

.PHONY:
! all!: clean all

.SECONDEXPANSION:
$(R)/%.content.r: $(P)/%.content $(R)/lswitch.r $(T)/page.tmpl \
  $$(strip $$(subst $$(lastword $$(subst /, ,$$(dir $$@)))/, ,$$(dir $$@)))menu.r \
  $(T)/content.tmpl $$(wildcard $$(dir $$(P)/$$*)content.tmpl) | rndr_strct
	@cp $(T)/page.tmpl $@
	@test -f $(dir $(P)/$*)content.tmpl && sed -i -e '/$$content{}/{r $(dir $(P)/$*)content.tmpl'\
		-e 'd}' $@  || sed -i -e '/$$content{}/{r $(T)/content.tmpl' -e 'd}' $@

	$(menu-sub)
	$(var-sub)

.SECONDEXPANSION:
$(R)/%.crow.r: $(P)/%.content $(T)/content_row.tmpl $$(wildcard $$(dir $$(P)/$$*)content_row.tmpl) \
  | rndr_strct
	@test -f $(dir $(P)/$*)/content_row.tmpl && cp $(dir $(P)/$*)/content_row.tmpl $@\
		|| cp $(T)/content_row.tmpl $@
	@sed -i '1s/^/$$__cnt_w_{$$content{WEIGHT}} /' $@
	$(var-sub)
	@sed -i -e 's|$$content{URL}|$(B)$(patsubst $(P)/%.content,%.html,$<)|g' $@
	@tr '\n' ' ' < $@ > $@.tmp && printf '\n' >> $@.tmp && mv -f $@.tmp $@

.SECONDEXPANSION:
$(R)/%/crows.r:$$(patsubst $$(P)/$$(PR).content,$$(R)/$$(PR).crow.r,\
  $$(wildcard $(P)/$$*/*.content)) | rndr_strct
	@touch $@ && test -f '$<' && cat $^ | sort -Vk1,1 | sed 's/$$__cnt_w_{[a-zA-Z0-9-]\+}//g' >$@ ||:

.SECONDEXPANSION:
$(R)/%/category.r: $(P)/%/category.info $(R)/%/crows.r $(R)/lswitch.r \
  $$(strip $$(subst $$(lastword $$(subst /, ,$$(dir $$@)))/, ,$$(dir $$@)))menu.r \
  $(T)/page.tmpl $(T)/category.tmpl $$(wildcard $$(dir $$(P)/$$*)category.tmpl) | rndr_strct
	@test -f $(P)/$*/page.tmpl && cp $(P)/$*/page.tmpl $@ || cp $(T)/page.tmpl $@
	@test -f $(P)/$*/category.tmpl && sed -i \
		-e '/$$content{}/{r $(P)/$*/category.tmpl' -e 'd}' $@ \
		|| sed -i -e '/$$content{}/{r $(T)/category.tmpl' -e 'd}' $@

	@sed -i -e "s/\$$rows{}/$$(sed -e 's/[\&/]/\\&/g' -e 's/$$/\\n/' \
		$(R)/$*/crows.r | tr -d '\n')/g" $@

	$(menu-sub)
	$(var-sub)

$(R)/%/mrow.r: $(P)/%/category.info $(T)/menu_row.tmpl | rndr_strct
	@cp $(T)/menu_row.tmpl $@ && sed -i '1s/^/$$__cweight_{$$category{WEIGHT}} /' $@
	$(var-sub)

	@sed -i -e 's|$$category{URL}|$(subst //,/,$(B)$(patsubst %/,%,$(patsubst\
		/%,%,$(subst /$(PCONT),,$(subst /$(PLANG)/$(PCONT)/,/,/$*/))))$(I))|g' \
		-e 's|$$category{ACTIVE}|$$__category_active_{$(lastword\
		$(subst /, ,$(subst $(notdir $@),,$(patsubst $(P)/%,%,$@))))}|g' $@
    
	@tr '\n' ' ' < $@ > $@.tmp && printf '\n' >> $@.tmp && mv -f $@.tmp $@

$(R)/%/lrow.r: $(T)/lan_switch_row.tmpl | rndr_strct
	$(eval LACT = $(firstword $(subst /, ,$(subst $(notdir $@),,$(patsubst $(R)/%,%,$@)))))
	@cp $< $@ && sed -i -e 's|$$language{URL}|$(B)$*$(I)|g' \
		-e 's|$$language{ACTIVE}|$$__lactive_{$(LACT)}|g' -e 's|$$language{NAME}|$(LACT)|g' $@

$(CAT_HTML_FILES): html/%/index.html : $(R)/%/category.r
$(CON_HTML_FILES): html/%.html : $(R)/%.content.r
$(CON_HTML_FILES) $(CAT_HTML_FILES):
	@mkdir -p $(dir $@)
	@sed 's!$$\(content\|category\|global\){[A-Za-z0-9_-]*}!!g' $< > $@

.SECONDEXPANSION:
$(R)/%/menu.r: $$(patsubst $$(P)/$$(PR)/category.info,$$(R)/$$(PR)/mrow.r,\
  $$(wildcard $(P)/$$*/**/category.info)) | rndr_strct
	@cat $^ | sort -V -k1,1 | sed 's/$$__cweight_{[a-zA-Z0-9-]\+}//g' > $@

$(R)/lswitch.r: $(patsubst $(P)/%,$(R)/%/lrow.r,$(LAN_FOLDERS)) | rndr_strct
	@cat $^ > $@

html/index.html: html/$(PLANG)/$(PCONT)/index.html
$(LANG_INDEX_FILES): html/%/index.html : html/%/$(PCONT)/index.html
$(LANG_INDEX_FILES) html/index.html:
	@mkdir -p $(dir $@)
	@cp $< $@

.PHONY:
rndr_strct:
	@mkdir -p $(sort $(subst $(P)/, $(R)/, $(dir $(wildcard $(P)/*/*/))))

.PHONY:
clean:
	@rm -rf render ||:
	@rm -rf html ||: