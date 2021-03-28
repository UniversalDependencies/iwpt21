SHELL=/bin/bash
FROMUD27=Arabic-PADT Czech-CAC Czech-FicTree Czech-PDT Czech-PUD Dutch-Alpino Dutch-LassySmall English-EWT English-PUD Italian-ISDT Lithuanian-ALKSNIS Slovak-SNK Swedish-PUD Swedish-Talbanken
FROMDEV=Tamil-TTB
FROMFORK=Bulgarian-BTB Estonian-EDT Estonian-EWT Finnish-PUD Finnish-TDT Latvian-LVTB Polish-LFG Polish-PDB Polish-PUD Russian-SynTagRus Ukrainian-IU
FROMFRENCH=French-FQB French-Sequoia
ALL=$(FROMUD27) $(FROMDEV) $(FROMFORK) $(FROMFRENCH)
UDDIR=/net/work/people/zeman/unidep
LCODES=ar bg cs nl en et fi fr it lv lt pl ru sk sv ta uk
TBKS_ar=Arabic-PADT
TBKS_bg=Bulgarian-BTB
TBKS_cs=Czech-FicTree Czech-CAC Czech-PDT Czech-PUD
TBKS_nl=Dutch-Alpino Dutch-LassySmall
TBKS_en=English-EWT English-PUD
TBKS_et=Estonian-EDT Estonian-EWT
TBKS_fi=Finnish-TDT Finnish-PUD
TBKS_fr=French-Sequoia French-FQB
TBKS_it=Italian-ISDT
TBKS_lv=Latvian-LVTB
TBKS_lt=Lithuanian-ALKSNIS
TBKS_pl=Polish-LFG Polish-PDB Polish-PUD
TBKS_ru=Russian-SynTagRus
TBKS_sk=Slovak-SNK
TBKS_sv=Swedish-Talbanken Swedish-PUD
TBKS_ta=Tamil-TTB
TBKS_uk=Ukrainian-IU

dirs:
	for i in $(ALL) ; do echo $$i ; mkdir -p UD_$$i ; done

fetch:
	for i in $(ALL) ; do rm -f UD_$$i/* ; done
	for i in $(FROMUD27) ; do srcdir=$(UDDIR)/UD_$$i ; pushd $$srcdir ; git checkout master ; popd ; cp $$srcdir/*.conllu $$srcdir/README* $$srcdir/LICENSE* UD_$$i ; pushd $$srcdir ; git checkout dev ; popd ; ls -al UD_$$i | grep conllu ; done
	for i in $(FROMDEV)  ; do srcdir=$(UDDIR)/UD_$$i ; pushd $$srcdir ; git pull --no-edit ; git checkout dev ; popd ; cp $$srcdir/*.conllu $$srcdir/README* $$srcdir/LICENSE* UD_$$i ; ls -al UD_$$i | grep conllu ; done
	for i in $(FROMFORK) ; do srcdir=$(UDDIR)/forks/UD_$$i ; pushd $$srcdir ; git pull --no-edit ; git checkout enhanced ; popd ; cp $$srcdir/*.conllu $$srcdir/README* $$srcdir/LICENSE* UD_$$i ; ls -al UD_$$i | grep conllu ; done
	cp $(UDDIR)/forks/french/fr_fqb-ud-*.conllu $(UDDIR)/forks/french/README* UD_French-FQB ; ls -al UD_French-FQB | grep conllu
	cp $(UDDIR)/forks/french/fr_sequoia-ud-*.conllu $(UDDIR)/forks/french/README* UD_French-Sequoia ; ls -al UD_French-Sequoia | grep conllu
	cat UD_Czech-PDT/cs_pdt-ud-train-*.conllu > UD_Czech-PDT/cs_pdt-ud-train.conllu
	rm UD_Czech-PDT/cs_pdt-ud-train-*.conllu
	ls -al UD_Czech-PDT | grep conllu

# This should have been fixed in the original UD data but the current validator does not catch it.
# We have to fix it here because otherwise the generated plain text would not match the CoNLL-U file.
fix_space_after:
	# Either copy the following to the terminal or uncomment it here and escape the $ to $$!
	# ( for i in UD_* ; do for j in $i/*.conllu ; do echo $j ; check-space-after-paragraph.pl $j ; done ; done ) |& tee test-space-after.log
	fix-space-after-paragraph.pl UD_*/*.conllu |& tee fix-space-after-paragraph.log
	rm UD_*/*.conllu.bak

ls:
	( for i in UD_* ; do echo $$i ; ls -al $$i ; echo ; done ) | less

validate1:
	for i in UD_*/*.conllu ; do echo $$i ; validate.py --lang ud --level 1 $$i ; done

validate2:
	for i in UD_*/*.conllu ; do echo $$i ; validate.py --lang ud --level 2 $$i ; done

validate:
	for i in UD_*/*.conllu ; do lang=$$(echo -n $$i | perl -pe 's:^.+/::; s/_.*//') ; echo validate.py --lang $$lang $$i ; validate.py --lang $$lang $$i ; done

text:
	for i in UD_*/*.conllu ; do lang=$$(echo -n $$i | perl -pe 's:^.+/::; s/_.*//') ; echo conllu_to_text.pl --lang $$lang $$i '>' `dirname $$i`/`basename $$i .conllu`.txt ; conllu_to_text.pl --lang $$lang $$i > `dirname $$i`/`basename $$i .conllu`.txt ; done

# The lines for test-gold and test-blind are commented out because now we merge test files by languages, see
# the "mergetest" target below.
split:
	for i in $(ALL) ; do rm -rf train-dev/UD_$$i  ; cp -r UD_$$i train-dev  ; rm -f train-dev/UD_$$i/*-test.* ; done
	#for i in $(ALL) ; do rm -rf test-gold/UD_$$i  ; cp -r UD_$$i test-gold  ; rm -f test-gold/UD_$$i/*-{train,dev}.* ; done
	#for i in $(ALL) ; do rm -rf test-blind/UD_$$i ; cp -r UD_$$i test-blind ; rm -f test-blind/UD_$$i/*-{train,dev}.* test-blind/UD_$$i/*.conllu ; done

find_dev_txt     = $(wildcard UD_$(tbk)/*-dev.txt)
find_dev_conllu  = $(wildcard UD_$(tbk)/*-dev.conllu)
find_test_txt    = $(wildcard UD_$(tbk)/*-test.txt)
find_test_conllu = $(wildcard UD_$(tbk)/*-test.conllu)
dev_txt_merge     := $(foreach ll,$(LCODES),../tools/mergetest.pl dev-blind/$(ll).txt $(foreach tbk,$(TBKS_$(ll)),$(find_dev_txt)) ;)
dev_conllu_merge  := $(foreach ll,$(LCODES),../tools/mergetest.pl dev-gold/$(ll).conllu $(foreach tbk,$(TBKS_$(ll)),$(find_dev_conllu)) ;)
test_txt_merge    := $(foreach ll,$(LCODES),../tools/mergetest.pl test-blind/$(ll).txt $(foreach tbk,$(TBKS_$(ll)),$(find_test_txt)) ;)
test_conllu_merge := $(foreach ll,$(LCODES),../tools/mergetest.pl test-gold/$(ll).conllu $(foreach tbk,$(TBKS_$(ll)),$(find_test_conllu)) ;)

mergetest:
	rm -rf dev-blind
	mkdir -p dev-blind
	$(dev_txt_merge)
	rm -rf dev-gold
	mkdir -p dev-gold
	$(dev_conllu_merge)
	rm -rf test-blind
	mkdir -p test-blind
	$(test_txt_merge)
	rm -rf test-gold
	mkdir -p test-gold
	$(test_conllu_merge)

pack:
	rm -f *.tgz
	tar czf iwpt2021-train-dev.tgz train-dev
	cd dev-gold ; tar czf ../iwpt2021-dev-gold.tgz *.conllu
	cd dev-blind ; tar czf ../iwpt2021-dev-blind.tgz *.txt
	cd test-gold ; tar czf ../iwpt2021-test-gold.tgz *.conllu
	cd test-blind ; tar czf ../iwpt2021-test-blind.tgz *.txt

# Make the training and development data available for download.
publish:
	publish iwpt2021-train-dev.tgz
	publish iwpt2021-dev-gold.tgz
	publish iwpt2021-dev-blind.tgz
	@echo Do not forget to archive the current version before it is overwritten next time.
	date

# Baseline 1: Take gold-standard annotation, replace the enhanced graph with the basic tree.
dev_baseline1:
	rm -rf dev-baseline1
	mkdir -p dev-baseline1
	for i in dev-gold/*.conllu ; do echo $$i ; ( conllu-copy-basic-to-enhanced.pl --replace < $$i > dev-baseline1/`basename $$i` ) ; done
	cd dev-baseline1 ; tar czf ../baseline1-dev.tgz *.conllu

test_baseline1:
	rm -rf test-baseline1
	mkdir -p test-baseline1
	for i in test-gold/*.conllu ; do echo $$i ; ( conllu-copy-basic-to-enhanced.pl --replace < $$i > test-baseline1/`basename $$i` ) ; done
	cd test-baseline1 ; tar czf ../baseline1-test.tgz *.conllu

evaluate:
	#../tools/evaluate_all.pl baseline1 dev dev
	#../tools/html_evaluation.pl baseline1 dev dev > sysoutputs/baseline1/dev/eval.html
	../tools/evaluate_all.pl baseline1 test test
	../tools/html_evaluation.pl baseline1 test test > sysoutputs/baseline1/test/eval.html
