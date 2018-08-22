# hagel - single Makefile static page generator
# Copyright 2015 Patrick Brosi <info@patrickbrosi.de>

BASE = $(abspath html)/
INDEX = /index.html
TEMPLATE = template
CSUFF = .html
P = content
R = render
STATIC = $(abspath static)/
PR = %
PRIM_LANG = $(shell (test -d content/en && echo en) || find content -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort | head -n1)
PRIM_CONT = $(shell (test -d content/$(PRIM_LANG)/main && echo main) || find content/$(PRIM_LANG) -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort | head -n1)
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
$(eval LNEUT = $(patsubst $(LANG)/%,%,$(patsubst content/%,%,\
  $(patsubst %.content,%$(CSUFF),$(subst /category.info,$(I),$<)))))
endef

define var-sub
$(var-sub-sub)
@sed -i 's/$$system{{\([^}]*\|}[^}]\)*}*}}/&$$__hagel_syscall_brk_{}\n/g' $@
@sed -i -e '/\(.*\)$$system{{\(.*\)}}\(.*\)/ { h; s//\1\n\3/; x; s//\2 /e; G;\
	s/\(.*\)\n\(.*\)\n\(.*\)/\2\1\3/; b }' $@
@sed -i -e ':a' -e 'N' -e '$$!ba' -e 's/$$__hagel_syscall_brk_{}\n//g' $@
$(var-sub-sub)
endef

define var-sub-sub
$(var-def)
@sed -e ':a' -e 'N' -e '$$!ba' -e 's/\n/\\n/g' $< > $(dir $@).$(notdir $@).$(notdir $<).newlesc.tmp
@sed -i -E -e 's|(^\|\}\})[\\n\s]*([$(ALLWD_VAR_CHRS)]*=\{\{\|$$)|\1\2|g' $(dir $@).$(notdir $@).$(notdir $<).newlesc.tmp
@cat $(dir $@).$(notdir $@).$(notdir $<).newlesc.tmp | tr -d '\n' | sed -e 's|\([$(ALLWD_VAR_CHRS)]*\)={{|\n\1={{|g' -e 's|\\\([^n]\)|\\\\\1|g' -e 's|/|\\/|g' -e 's|\&|\\&|g' | sed 's|\([$(ALLWD_VAR_CHRS)]*\)={{\(.*\)}}| s/$$$(strip $(subst .,,$(suffix $(patsubst %.info,%.category,$<)))){\1}/\2/|' > $@.var.sub.tmp
@cat $< | tr -d '\n' | sed -e 's|\([$(ALLWD_VAR_CHRS)]*\)={{|\n\1={{|g' -e 's|\\\([^n]\)|\\\\\1|g' -e 's|/|\\/|g' -e 's|\&|\\&|g' | sed 's|\([$(ALLWD_VAR_CHRS)]*\)={{\(.*\)}}| s/$$$(strip $(subst .,,$(suffix $(patsubst %.info,%.category,$<)))){\\[\1\\]}/\2/|' >> $@.var.sub.tmp
@sed -i -f $@.var.sub.tmp $@
@sed -i -e 's|$$global{BASE_PATH}|$(B)|g' -e 's|$$global{ACTIVE_LANGUAGE}|$(LANG)|g' \
	-e 's|$$global{ACTIVE_CATEGORY}|$(CATEGORY)|g' -e 's|$$category{WEIGHT}|0|g' \
	-e 's|$$content{WEIGHT}|0|g' -e 's|$$content{NAME}|$(CONTENT)|g' \
	-e 's|$$global{INDEX_PATH}|$(I)|g' -e 's|$$global{STATIC_PATH}|$(S)|g' \
	-e 's|$$global{LNEUT}|$(LNEUT)|g' \
	-e 's|$$global{HOME}|$(subst //,/,$(B)/$(LANG)$(I))|g' $@
@test -f $(P)/$(LANG)/global.info && cat $(P)/$(LANG)/global.info | tr '\n' ' ' | \
	sed -e 's|\([$(ALLWD_VAR_CHRS)]*\)={{|\n\1={{|g' -e 's|\\|\\\\|g' \
	-e 's|/|\\/|g' -e 's|\&|\\&|g' \
	| sed -e 's|\([$(ALLWD_VAR_CHRS)]*\)={{\(.*\)}}|s/$$global{\1}/\2/|'  \
	| xargs -0 -I % sed % -i'' $@ || :
@rm $@.var.sub.tmp && rm $(dir $@).$(notdir $@).$(notdir $<).newlesc.tmp
endef

define menu-sub
$(var-def)
@(echo -n s/\$$menu{}/ && (sed -e 's/[\&/]/\\&/g' -e 's/$$/\\n/' $(strip $(subst $(lastword $(subst /, ,$(dir $@)))/, ,$(dir $@)))menu.r | tr -d '\n') && echo -n /g) > $(strip $(dir $@)).$(strip $(notdir $@)).cmrows.temp.r
@sed -i -f $(strip $(dir $@)).$(strip $(notdir $@)).cmrows.temp.r $@
@sed -i -e 's|$$__category_active_{$(CATEGORY)}|active|g' -e 's|$$__category_active_{[a-zA-Z0-9]\+}||g' $@
@(echo -n s/\$$__category_submenu_{$(CATEGORY)}/ && (sed -e 's/[\&/]/\\&/g' -e 's/$$/\\n/' $(strip $(dir $@))cmrows.r | tr -d '\n') && echo -n /g) > $(strip $(dir $@)).$(strip $(notdir $@)).cmrows.temp.r
@test -n '$(CONTENT)' && sed -i -f $(strip $(dir $@)).$(strip $(notdir $@)).cmrows.temp.r $@ ||:
@sed -i -e 's|$$__category_submenu_{[a-zA-Z0-9]\+}||g' $@
@sed -i -e 's|$$__content_active_{$(CONTENT)}|active|g' -e 's|$$__content_active_{[a-zA-Z0-9]\+}||g' $@
@(echo -n s/\$$languageswitcher{}/ && (sed -e 's/[\&/]/\\&/g' -e 's/$$/\\n/'\
	$(R)/lswitch.r | tr -d '\n') && echo -n /g) > $(strip $(dir $@)).$(strip $(notdir $@)).cmrows.temp.r
@sed -i -f $(strip $(dir $@)).$(strip $(notdir $@)).cmrows.temp.r $@
@sed -i -e 's|$$__lactive_{$(LANG)}|active|g' -e 's|$$__lactive_{[a-zA-Z0-9]\+}||g' $@
@rm $(strip $(dir $@)).$(strip $(notdir $@)).cmrows.temp.r
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
  $(T)/content.tmpl $$(wildcard $$(dir $$(P)/$$*)content.tmpl) $$(dir $$(R)/$$*)cmrows.r | rndr_strc
	@echo "Building $@"
	@cp $(T)/page.tmpl $@
	@test -f $(dir $(P)/$*)content.tmpl && sed -i -e '/$$content{}/{r $(dir $(P)/$*)content.tmpl'\
		-e 'd}' $@  || sed -i -e '/$$content{}/{r $(T)/content.tmpl' -e 'd}' $@
	$(menu-sub)
	$(var-sub)

.SECONDEXPANSION:
$(R)/%.crow.r: $(P)/%.content $(T)/content_row.tmpl $$(wildcard $$(dir $$(P)/$$*)content_row.tmpl) \
  | rndr_strc
	@echo "Building $@"
	@test -f $(dir $(P)/$*)/content_row.tmpl && cp $(dir $(P)/$*)/content_row.tmpl $@\
		|| cp $(T)/content_row.tmpl $@
	@sed -i '1s/^/$$__cnt_w{$$content{WEIGHT}} /' $@
	$(var-sub)
	@sed -i -e 's|$$content{URL}|$(B)$(patsubst $(P)/%.content,%$(CSUFF),$<)|g' $@
	@tr '\n' ' ' < $@ > $@.tmp && printf '\n' >> $@.tmp && mv -f $@.tmp $@

.SECONDEXPANSION:
$(R)/%.cmrow.r: $(P)/%.content $(T)/content_menu_row.tmpl | rndr_strc
	@echo "Building $@"
	@cp $(T)/content_menu_row.tmpl $@
	@sed -i -e '1s/^/$$__cnt_w{$$content{WEIGHT}} /'\
		-e 's|$$content{ACTIVE}|$$__content_active_{$(basename $(notdir $<))}|g' $@
	$(var-sub)
	@sed -i -e 's|$$content{URL}|$(B)$(patsubst $(P)/%.content,%$(CSUFF),$<)|g' $@
	@tr '\n' ' ' < $@ > $@.tmp && printf '\n' >> $@.tmp && mv -f $@.tmp $@

.SECONDEXPANSION:
$(R)/%/cmrows.r:$$(patsubst $$(P)/$$(PR).content,$$(R)/$$(PR).cmrow.r,\
  $$(wildcard $(P)/$$*/*.content)) | rndr_strc
	@echo "Building $@"
	@touch $@ && test -f '$<' && cat $^ | sort -Vk1,1 | sed 's/$$__cnt_w{[_a-zA-Z0-9-]\+}//g' >$@ ||:

$(R)/%/crows.r:$$(patsubst $$(P)/$$(PR).content,$$(R)/$$(PR).crow.r,\
  $$(wildcard $(P)/$$*/*.content)) | rndr_strc
	@echo "Building $@"
	@touch $@ && test -f '$<' && cat $^ | sort -Vk1,1 | sed 's/$$__cnt_w{[_a-zA-Z0-9-]\+}//g' >$@ ||:

.SECONDEXPANSION:
$(R)/%/category.r: $(P)/%/category.info $(R)/%/cmrows.r $(R)/%/crows.r $(R)/lswitch.r \
  $$(strip $$(subst $$(lastword $$(subst /, ,$$(dir $$@)))/, ,$$(dir $$@)))menu.r \
  $(T)/page.tmpl $(T)/category.tmpl $$(wildcard $(P)/%/category.tmpl) | rndr_strc
	@echo "Building $@"
	@test -f $(P)/$*/page.tmpl && cp $(P)/$*/page.tmpl $@ || cp $(T)/page.tmpl $@
	@test -f $(P)/$*/category.tmpl && sed -i \
		-e '/$$content{}/{r $(P)/$*/category.tmpl' -e 'd}' $@ \
		|| sed -i -e '/$$content{}/{r $(T)/category.tmpl' -e 'd}' $@
	@(echo -n s/\$$rows{}/ && (sed -e 's/[\&/]/\\&/g' -e 's/$$/\\n/' $(R)/$*/crows.r | tr -d '\n') && echo -n /g) > $(R)/$*/.catrep.tmp
	@sed -i -f $(R)/$*/.catrep.tmp $@ && rm $(R)/$*/.catrep.tmp
	$(menu-sub)
	$(var-sub)

$(R)/%/mrow.r: $(P)/%/category.info $(T)/category_menu_row.tmpl | rndr_strc
	@echo "Building $@"
	@cp $(T)/category_menu_row.tmpl $@ && sed -i '1s/^/$$__cweight{$$category{WEIGHT}} /' $@
	$(var-sub)
	@sed -i -e 's|$$category{URL}|$(subst //,/,$(B)$(patsubst %/,%,$(patsubst\
		/%,%,$(subst /$(PCONT),,/$*/)))$(I))|g' \
		-e 's|$$category{ACTIVE}|$$__category_active_{$(lastword\
		$(subst /, ,$(subst $(notdir $@),,$(patsubst $(P)/%,%,$@))))}|g'\
		-e 's|$$submenu{}|$$__category_submenu_{$(lastword\
		$(subst /, ,$(subst $(notdir $@),,$(patsubst $(P)/%,%,$@))))}|g' $@
	@tr '\n' ' ' < $@ > $@.tmp && printf '\n' >> $@.tmp && mv -f $@.tmp $@

$(R)/%/lrow.r: $(T)/lan_switch_row.tmpl | rndr_strc
	@echo "Building $@"
	$(eval LACT = $(firstword $(subst /, ,$(subst $(notdir $@),,$(patsubst $(R)/%,%,$@)))))
	@cp $< $@\
		&& sed -i -e 's|$$language{URL}|$$global{BASE_PATH}$(LACT)/$$global{LNEUT}|g' \
		-e 's|$$language{ACTIVE}|$$__lactive_{$(LACT)}|g' -e 's|$$language{NAME}|$(LACT)|g' $@

$(CAT_HTML_FILES): html/%/index.html : $(R)/%/category.r
$(CON_HTML_FILES): html/%.html : $(R)/%.content.r
$(CON_HTML_FILES) $(CAT_HTML_FILES):
	@mkdir -p $(dir $@)
	@sed 's!$$\(content\|category\|global\){[A-Za-z0-9_-]*}!!g' $< > $@

.SECONDEXPANSION:
$(R)/%/menu.r: $$(patsubst $$(P)/$$(PR)/category.info,$$(R)/$$(PR)/mrow.r,\
  $$(wildcard $(P)/$$*/**/category.info)) | rndr_strc
	@echo "Building $@"
	@cat $^ | sort -V -k1,1 | sed 's/$$__cweight{[a-zA-Z0-9-]\+}//g' > $@

$(R)/lswitch.r: $(patsubst $(P)/%,$(R)/%/lrow.r,$(LAN_FOLDERS)) | rndr_strc
	@echo "Building $@"
	@cat $^ > $@

html/index.html: html/$(PLANG)/$(PCONT)/index.html
$(LANG_INDEX_FILES): html/%/index.html : html/%/$(PCONT)/index.html
$(LANG_INDEX_FILES) html/index.html:
	@mkdir -p $(dir $@)
	@cp $< $@

.PHONY:
rndr_strc:
	@mkdir -p $(sort $(subst $(P)/, $(R)/, $(dir $(wildcard $(P)/*/*/))))

.PHONY:
clean:
	@rm -rf render
	@rm -rf html
