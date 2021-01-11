#!/bin/bash
# Applies the Stanford Enhancer to a CoNLL-U file.
# Argument 1 is the input file name (including path if necessary). The file will be replaced with its enhanced version!
# Argument 2 is the language name as in the repository, with underscores if necessary. We will use it to access relative pronouns and word embeddings.
if [[ -z "$2" ]] ; then
  echo Usage: stanford_enhancer.sh grc Ancient_Greek
  exit 1
fi
input="$1"
language="$2"
# Fixed path to our installation of Stanford CoreNLP. We could also take it as an argument if desirable.
CORENLPDIR=/net/work/people/droganova/CoreNLP
DEEPUDDIR=/net/work/people/zeman/deepud
RELPRONDIR=$DEEPUDDIR/data/relpron
EMBEDDIR=$DEEPUDDIR/data/embeddings
TMPOUT=/COMP.TMP/$$.enhanced.conllu
if [[ -e "$TMPOUT" ]] ; then
  echo "$TMPOUT" already exists, giving up.
  exit 1
fi
relpron=`cat $RELPRONDIR/relpron-$language.txt`
if [[ -d "$EMBEDDIR/$language" ]] ; then
  embeddings=$EMBEDDIR/$language/`ls -1 $EMBEDDIR/$language | grep vectors`
  echo $input '('$language, $relpron, $embeddings')'
  TMPVEC=/COMP.TMP/$$.vectors
  echo Extracting $embeddings to $TMPVEC...
  if [[ -e "$TMPVEC" ]] ; then
    echo "$TMPVEC" already exists, giving up.
    exit 1
  fi
  # Avoid running out of memory. Take only vectors of the 2 million most frequent words.
  xzcat $embeddings | head -2000000 > $TMPVEC
  java -mx4g -cp "$CORENLPDIR/*" edu.stanford.nlp.trees.ud.UniversalEnhancer -relativePronouns "$relpron" -conlluFile $input -embeddings $TMPVEC -numHid 100 | $DEEPUDDIR/tools/fix_stanford_enhancer.pl > $TMPOUT
  mv $TMPOUT $input
  rm -f $TMPVEC
else
  echo $input '('$language, $relpron, NO EMBEDDINGS')'
  java -mx4g -cp "$CORENLPDIR/*" edu.stanford.nlp.trees.ud.UniversalEnhancer -relativePronouns "$relpron" -conlluFile $input -numHid 100 | $DEEPUDDIR/tools/fix_stanford_enhancer.pl > $TMPOUT
  mv $TMPOUT $input
fi
