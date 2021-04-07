---
layout: page
title: Submission
---

# Submission Rules

One submission is a gzipped tar archive, named “_xxx_-<i>yyy</i>.tgz”, where _xxx_ should be replaced by a team identifier and _yyy_ should be replaced by a unique submission identifier. The team identifier and the submission identifier may contain lowercase English letters a-z, digits 0-9, and the underscore character “_”. If the submission identifier is identical to an identifier of a previous submission of the same team, the previous submission is forgotten and replaced by the current submission.

The most recent submission received from a team is considered the primary submission that will yield the official score of the team in the shared task. Exception: if the submission identifier starts with the prefix “secondary” and if there is at least one submission without such prefix, the submission with the “secondary” prefix is not considered primary.

The tgz archive must contain directly the parsed CoNLL-U files (no folders!) For example, if the current working folder is the one where all parser-output CoNLL-U files reside and there are no other files, you can create the archive like this (on a Unix system):

<pre>
tar czf myteam-mysubmission.tgz *.conllu
</pre>

We intend to batch-process the submissions roughly like this:

<pre>
GOLD=/path/to/gold-standard
TEAM=xxx
SUBMISSION=yyy
if [[ -e “$TEAM/$SUBMISSION” ]] ; then
  rm -rf $TEAM/$SUBMISSION
fi
mkdir -p $TEAM/$SUBMISSION
cd $TEAM/$SUBMISSION
tar xzf ../../$TEAM-$SUBMISSION.tgz
for i in $GOLD/*.conllu ; do evaluate $i `basename $i` ; done
</pre>

It is thus important to name the files inside the tgz archive correctly, otherwise they will not be found by the evaluation procedure. The naming convention is simple. We expect 17 files named “_ll_.conllu”, where _ll_ should be replaced by the ISO code of the language. The same code also appears in the names of the respective plain-text input files: “_ll_.txt”, so the parser knows the code for each file. The codes are:

Arabic … ar; Bulgarian … bg; Czech … cs; Dutch … nl; English … en; Estonian … et; Finnish … fi; French … fr; Italian … it; Latvian … lv; Lithuanian … lt; Polish … pl; Russian … ru; Slovak … sk; Swedish … sv; Tamil … ta; Ukrainian … uk.

See [the data page](data.html) for the test data.

## Validity of the System Output

The submission must be a valid [CoNLL-U](https://universaldependencies.org/format.html) file
and it must be accepted by the [official UD validating script](https://github.com/UniversalDependencies/tools/blob/master/validate.py)
(it is enough to pass `validate.py --level 2`). Participants are
**strongly encouraged to validate the preliminary output of their system well in advance**
so they can spot potential problems early. Here are some of the issues that may arise:

* Make sure your sentence has a unique sent_id, the raw text is copied in the text attribute and it matches the word forms.
  Beware of multi-word tokens and the SpaceAfter=No attribute in MISC.
* If you do not predict LEMMA, XPOS or FEATS, replace it by an underscore ('_').
* If you do not predict UPOS, replace it by 'X' (underscore is not a valid UPOS tag).
* If you do not predict HEAD, replace it by '1', except for the first node, which will get '0'.
  That way you get a rooted tree. DEPREL of the first node must be 'root'; for the other nodes, use 'dep'.
* Multi-word token lines have only ID, FORM and possibly MISC (SpaceAfter=No), all other columns must contain just an underscore ('_').
* Empty nodes have underscores in HEAD and DEPREL; FORM and morphology is optional.
* The DEPS column encodes the enhanced UD graph and is thus the most important piece of annotation in this shared task.
  The graph must be rooted and connected. Unlike in the basic UD tree, there may be multiple root nodes (i.e., having
  a 'root' relation to a fake parent with ID 0) but there must be at least one. All nodes must be reachable through
  traversing directed relation path from at least one root.
* While you can give the relation an unknown label (you will be penalized in your scores but the level-2 validation will succeed),
  you are still not free to put anything there. The enhanced UD guidelines and the CoNLL-U specification define a regular expression
  that every relation label must match. In a nutshell, only letters, underscores and colons can occur in a relation label; therefore,
  if you blindly copy a lemma to the label and the lemma contains other punctuation, your output will be invalid.

In addition to the validity of the CoNLL-U file, it is required that
**non-whitespace characters** in the FORM field of surface tokens **be identical** to those in the input file.
This is a pre-requisite for the evaluation; files with modified word forms will be rejected.

If a CoNLL-U file for a particular test corpus is invalid or missing, the submission is not completely discarded
and can still be evaluated for the test corpora for which valid output was submitted, but the scores for the
missing/invalid files are set to zero.

<b><a href="https://quest.ms.mff.cuni.cz/sharedtask/">Click here to proceed to the submission site.</a></b>
