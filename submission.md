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

<b><a href="https://quest.ms.mff.cuni.cz/sharedtask/">Click here to proceed to the submission site.</a></b>
