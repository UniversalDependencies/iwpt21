---
layout: page
title: Task Description and Evaluation
---

# TASK DESCRIPTION AND EVALUATION

We invite participants to develop a system for parsing raw text into [enhanced universal dependencies](https://universaldependencies.org/u/overview/enhanced-syntax.html) for all of the languages and treebanks included in the training data.
The task is similar to that of the CoNLL 2017 and 2018 shared tasks on parsing into UD, except that the prime evaluation metric now is the enhanced dependency annotation. Participants are encouraged to consider all enhancements listed in the UD guidelines, even if some of these enhancements might be absent in some of the treebanks included in the training data. Evaluation will take into account the fact that some treebanks are incomplete in this respect.
Participants are also encouraged to predict all lower levels of annotation (lemma, tag, morphological features, basic dependency tree). These annotations will be evaluated as secondary metrics. Nevertheless, it is possible to train a pre-existing parser (such as [UDPipe](http://ufal.mff.cuni.cz/udpipe)), use it to predict the lower levels of annotation and then develop one's own system that focuses on the transition from the basic UD tree to the enhanced UD graph.

## Training Data

The evaluation will be done on 17 languages from 4 language families: Arabic, Bulgarian, Czech, Dutch, English, Estonian, Finnish, French, Italian, Latvian, Lithuanian, Polish, Russian, Slovak, Swedish, Tamil, Ukrainian. The language selection is driven simply by the fact that at least partial enhanced representation is available for the given language.

Training and development data in the CoNLL-U format is [available on the shared task website](data.html). These datasets are based on the [UD release 2.5](http://hdl.handle.net/11234/1-3105) but the annotation is often not identical to the corresponding treebank in UD 2.5. Nevertheless, the participants are also allowed to use the training and development data from the official UD 2.5 release package on Lindat, even in languages that are not part of the shared task evaluation.

<b>No other version</b> of UD (either previous releases or Github repositories or other copies and clones online) can be used in the shared task; this is to avoid the danger of incompatible training-test splits.

Naturally, the participants must not use the files labeled as _test_ in UD 2.5. The development data (files labeled _dev_) can be used to perform error analysis during development, to tune hyperparameters etc. but it should not be added to training data when training the main model.

## Additional Resources

This is an open track in the sense that systems can use additional resources (word embeddings, training data) with the restriction that these should be publicly available and that participants indicate beforehand which additional resources they plan to use. (See the shared task mailing list, where some teams have already announced the resources they intend to use.)

## Test Data

Blind test data will be made available on the shared task website at the beginning of the test phase (see the schedule on the left). The test data consists of one plain text file per language, that is, individual UD treebanks of one language are not distinguished. Full test data including gold-standard annotation will be published after the shared task.

Since enhanced dependencies are optional in UD treebanks, not all languages cover all types off possible enhancements. Shared task participants can (and are encouraged to) try to predict all enhancement types regardless whether these are available in the gold standard data. We are doing our best to evaluate the system output in a way that does not penalize the systems for predicting more (see Evaluation Metric below).

See [here](enhancements_in_treebanks.html) for an overview of enhancement types in individual languages.

## Format of Submissions

Submissions consist of a [valid](https://github.com/UniversalDependencies/tools/blob/master/validate.py) [CoNLL-U](https://universaldependencies.org/format.html) file for each of the test corpora (it is enough to pass `validate.py --level 2`). Non-whitespace characters in the FORM field of surface tokens must be identical to those in the input file. This is a pre-requisite for the evaluation; files with modified word forms will be rejected. If a CoNLL-U file for a particular test corpus is invalid or missing, the submission is not completely discarded and can still be evaluated for the test corpora for which valid output was submitted, but the scores for the missing/invalid files are set to zero.

The input for the participating system is raw text (untokenized, unsegmented) in the given language. The participants will be told the language of each test file.

For more information, see the [description of the submission format](submission.html).

## Evaluation Metric

Submissions are evaluated as follows:

The main evaluation metric is ELAS (LAS on enhanced dependencies), where ELAS is defined as F1-score over the set of enhanced dependencies in the system output and the gold standard. Complete edge labels are taken into account, i.e. conj:and differs from conj. A second metric is EULAS (LAS on enhanced dependencies where labels are restricted to the universal dependency relation). In this second metric, edge label extensions are ignored, i.e. conj:and, conj:und, and conj are identical.

Second, we will perform a 'coarse, global' evaluation, as well as a treebank specific evaluation. In the first setting, ELAS and EULAS are computed over all edges in the gold standard and in the system output. However, while some effort has gone into ensuring that the data in the various treebanks is annotated consistently w.r.t. the level of enhancements and the format of enhanced labels, not all treebanks include all of the enhancements listed in the UD guidelines. Therefore, systems that try to predict all enhancement types for all treebanks might suffer in this coarse evaluation, as for some treebanks they in fact predict more than has been annotated. To give such systems a fair chance, we will also perform an evaluation where ELAS and EULAS is computed as before, but dependencies that are specific to enhancement E are ignored, if the given treebank does not include enhancement E. The two evaluation methods should give roughly the same result for systems that during training learned to adapt their output to a given treebank, whereas for systems that generally try to predict all possible enhancements, the second method should give more informative results.

A final issue we address is the evaluation of 'empty nodes'. A consequence of the treatment of gapping and ellipsis is that some sentences contain additional nodes (numbered 1.1 etc.). It is not guaranteed that gold and system agree on the position in the string where these should appear, but the information encoded by these additional nodes might nevertheless be identical. Thus, such empty nodes should be considered equal even if their string index might differ. To ensure that this is the case, we have opted for a solution that basically compiles the information expressed by empty nodes into the dependency label of its dependents. I.e. if a dependent with dependency label i2.1:L2 has an empty node with dependency label i1:L1 as parent, its dependency label will be expanded into a path i1:L1>L2. This preserves the information that the dependent was an L2 dependent of 'something' that was itself an L1 dependent of i1, while at the same time removing the potentially conflicting i2.1.

## Evaluation Script

The [evaluation script](iwpt20_xud_eval.py) is an extended version of the script used for CoNLL 2017 and 2018 shared tasks. In particular:

* The script aligns gold and system tokenized input, and tries to find an optimal alignment for those cases where there are alignment mismatches.
* An evaluation metric ELAS has been added, which reports the LAS over enhanced dependencies.
* The flag --enhancements allows certain enhancements to be ignored. Possible values are: 0=all enhancements are included (default), 1=no gapping, 2=no shared parents, 3=no shared dependents 4=no control, 5=no external arguments, 6=no lemma info, combinations are possible as well: 12=both 1 and 2 apply, etc. If a treebank contains no information regarding controlled subjects for instance,
iwpt20_xud_eval --enhancements=4 gold.conllu system.conllu
will filter dependencies for controlled subject and LAS is computed over the filtered set of dependencies.
* The input to the evaluation script should be a version of the gold and system output where empty nodes have been eliminated using the technique described above. The script enhanced_collapse_empty_nodes.pl in the [UD tools directory](https://github.com/UniversalDependencies/tools/) on github can be used for this (see installation instructions in the [README](https://github.com/UniversalDependencies/tools/blob/master/README.txt) for the script). The script is available for the participants so that they can evaluate their results on the development data. However, they must not apply the script to the submission of parsed test data. The submission must consist of valid CoNLL-U files, including the empty nodes; in contrast, the collapsed files are not valid because the '>' character cannot occur in relation labels. When a submission is received, it will be first validated and when it passes validation, empty nodes will be collapsed and the resulting graph evaluated against the gold standard.

