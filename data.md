---
layout: page
title: IWPT 2020 Shared Task – Data
---

# Shared Task Data

The training, development and evaluation data sets that were used in the
shared task are now publicly available for download in
[Lindat](http://hdl.handle.net/11234/1-3238). The package also includes
scripts used during the shared task by the organizing team, as well as
the primary submissions (parsed data) of each participating team.

## Training and Development Data

Within the .tar.gz package, the datasets are organized similarly to UD
releases, that is, CoNLL-U files are in subfolders that represent treebanks
rather than languages. Each folder contains the README and LICENSE files
(all treebanks come with some type of open license but some of them are
restricted for non-commercial use). Besides gold-standard CoNLL-U files,
there are also raw text files; this is the form which the participating
systems should expect as input. Some folders do not contain data because
the corresponding UD treebank contains only test data and no training
data. Participants can expect that data from such treebanks will be part
of the evaluation; while they cannot use the actual data from those treebanks
to train their systems,
they may use the information from the README files (e.g. to learn what
genres the treebank contains). There is always at least one other treebank
for the same language that has training data.

See the [task description](task_and_evaluation.html) for more details on
what data can be used in the shared task.

## Change Log

* 2020-03-21 16:12 UTC+1: Minor fix in UD_Estonian-EDT/et_edt-ud-train.txt
* 2020-03-17 22:12 UTC+1: Updated Estonian data; fixed SpaceAfter=No issues in UD_Czech-PDT, UD_English-EWT, UD_Latvian-LVTB and UD_Swedish-Talbanken.
* 2020-02-06 16:14 UTC+1: Updated UD_Russian-SynTagRus.
* 2020-02-04 15:18 UTC+1: The first train-dev package prepared.
