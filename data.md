---
layout: page
title: IWPT 2021 Shared Task – Data
---

# Shared Task Data

<!-- MODIFY AND UNCOMMENT THIS AFTER THE TASK WHEN THE DATA IS PUBLISHED

The training, development and evaluation data sets that were used in the
shared task are now publicly available for download in
[Lindat](http://hdl.handle.net/11234/1-3238). The package also includes
scripts used during the shared task by the organizing team, as well as
the primary submissions (parsed data) of each participating team.

TAKE THE BELOW TEXT OUT AFTER THE TASK -->

The full data will be published in Lindat after the shared task.
During the task, the data is temporarily available at the following links:

* [Training and development data by treebank](https://ufal.mff.cuni.cz/~zeman/soubory/iwpt2021-train-dev.tgz)
* [Gold development data by language](https://ufal.mff.cuni.cz/~zeman/soubory/iwpt2021-dev-gold.tgz)
* [Blind development data by language](https://ufal.mff.cuni.cz/~zeman/soubory/iwpt2021-dev-blind.tgz)

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
to train their systems, they may use the information from the README files (e.g. to learn what
genres the treebank contains). There is always at least one other treebank
for the same language that has training data.

See the [task description](task_and_evaluation.html) for more details on
what data can be used in the shared task.

## Gold and Blind Data by Language

Besides being included in the train-dev package described above, the development
data is also available in the form in which the test data will be provided.
Participants can use this data to test their system in similar conditions as
those in which the test phase will run. Here the blind package contains simply
one text file per language, and the system submission should mimic the structure
of the gold package.

## Change Log

* 2021-04-05 22:14 UTC+2: The first train-dev package published.
* 2021-04-07 21:02 UTC+2: Updated annotation of Arabic, Czech, Lithuanian, and Slovak.
