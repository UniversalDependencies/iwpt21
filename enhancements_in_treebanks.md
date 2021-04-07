---
layout: page
title: Enhancements in Treebanks
---

# Enhancement Types

We do not have gold-standard annotation of all [enhancement types](https://universaldependencies.org/u/overview/enhanced-syntax.html) for all languages. We will do [per-type evaluation](task_and_evaluation.html#evaluation-metric) so that a parser is not penalized for predicting an enhancement type that is not available in the gold standard. In some languages we have some enhancement types annotated only for a subset of the test corpus. The parser will not know which part it is; however, we will isolate the subset in the parser output and evaluate the enhancement type only on the part where gold standard is available.

| Language    | ar  | bg  | cs  | nl  | en  | et  | fi  | fr  | it  | lv  | lt  | pl  | ru  | sk  | sv  | ta  | uk  |
|-------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Gapping     | yes |     | yes | yes | yes | yes | yes |     | yes | yes | yes | prt | yes | yes | yes |     | yes |
| CoordParent | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| CoordDep    | yes | yes | prt | yes | yes | prt | prt | yes | yes | yes | yes | yes |     | yes | yes | yes | yes |
| XSubject    |     | yes | yes | yes | yes |     | prt | yes | yes | yes | yes | yes | yes | yes | yes |     | yes |
| RelClause   | yes | yes | yes | yes | yes | yes | yes |     | yes | yes | yes | yes | yes | yes | yes | yes | yes |
| CaseDeprel  | yes | yes | yes | yes | yes | yes | yes |     | yes | yes | yes | yes | yes | yes | yes | yes | yes |


If a cell says “prt”, it means that gold-standard annotation is available only for a part of the test data.

Note that even within one enhancement type, there are differences in the annotation across languages that have the type:

* In the instances of gapping, some languages have empty nodes but the relation between the empty node and its argument is just “dep”, although ideally it should be “nsubj”, “obj”, “obl” etc.
* The case-enhanced deprels (relation types) contain both the morphological case and the preposition in some languages, while they contain only the preposition in others. In some languages, conj relations are similarly enhanced with the conjunction lemma, although this is not described in the EUD guidelines.
* Some languages contain additional subtypes of the dependency relation types that are not used in the basic tree. An example is “nsubj:xsubj” for the external subject of xcomp infinitives.
  <!-- A special case is French where the data also encode diathesis normalization as described by Candito et al. (2017). This information is encoded as relation subtypes in a somewhat cryptic way so that the file is formally valid CoNLL-U. -->
