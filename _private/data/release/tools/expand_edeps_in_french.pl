#!/usr/bin/env perl
# Expands enhanced relation labels in French. For certain relations, the French
# treebanks provide a double label, consisting of a canonical and a final
# relation. This is to neutralize diathesis: final passive subject is canonical
# object etc. (Candito et al. 2017). Unfortunately it is not possible to
# represent a double label in the CoNLL-U file while complying with the UD
# guidelines, specifically with the limited set of characters that are allowed
# in a relation label. Therefore, the labels have been encoded in a form that
# makes the file formally valid but the label poorly readable by human users,
# e.g., "nsubj:passxoxobjenh". This script expands the labels to improve their
# readability while preserving the information they encode. It is thus a kind
# of antipole of the script fix_edeps_in_french.pl, although it will not restore
# the relation labels exactly in the form in which the other script reads them.
#
# With --list-edeprels, the script will also list the resulting edeprels to STDERR.
# Copyright © 2020 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use Getopt::Long;

my $list_edeprels = 0;
GetOptions
(
    'list-edeprels' => \$list_edeprels
);

my %edeprels;
while(<>)
{
    my $line = $_;
    if($line =~ m/^\d/)
    {
        my @f = split(/\t/, $line);
        my $edeps = $f[8];
        if($edeps ne '_')
        {
            my @edeps = map {m/^(\d+(?:\.\d+)?):(.+)$/; [$1, $2]} (split(/\|/, $edeps));
            foreach my $edep (@edeps)
            {
                my $h = $edep->[0];
                my $d = $edep->[1];
                # Relations that are specific to the enhanced graph (they don't have a counterpart in the basic tree)
                # have the suffix "enh". Sometimes it is not preceded by a colon because the maximum allowed number of
                # colons would be exceeded.
                #$d =~ s/([^:])enh$/$1:enh/;
                # Marie: the ":enh" suffix is only here to *easily spot* the enhanced dependencies,
                # it is used (in a different form) in our internal format. Since the information on
                # what is the original non-enhanced dependency is given in columns 7 and 8, you should
                # completely remove all the :enh suffixes in column 9, they are useless and harmful.
                $d =~ s/:?enh$//;
                # The final and canonical relations are separated by "xox" or ":xox", a sequence that does not occur
                # anywhere else in the labels. Again, the colon may not be there and may have to be restored.
                $d =~ s/([^:])xox/$1:xox/g;
                # Finally, replace ":xox" by something looking more like a delimiter.
                $d =~ s/:xox/\@/g;
                # In rare cases, a colon may also be missing between a main universal relation and its subtype. Restore it.
                $d =~ s/(nsubj)(caus|xxx)/$1:$2/g;
                # It is a bug in the original annotation that some relations have the ":xxx" subtype.
                # Marie: the XXX suffixes in labels are an internal mark. Could you
                # - remove the :xxx suffix in the Sequoia (i.e. keep "obj@nsubj" as label)
                # - change all "obj@nsubj:xxx" into "obj" in the FQB files?
                # This script does not know whether it is processing Sequoia or FQB.
                # But there are 9 occurrences in FQB and 1 in Sequoia, so we are taking the FQB rule as default.
                $d =~ s/^obj\@nsubj:xxx$/obj/;
                $edeprels{$d}++;
                $edep->[0] = $h;
                $edep->[1] = $d;
            }
            $edeps = join('|', map {"$_->[0]:$_->[1]"} (sort {my $r = $a->[0] <=> $b->[0]; unless($r) {$r = $a->[1] cmp $b->[1]} $r} (@edeps)));
        }
        $f[8] = $edeps;
        $line = join("\t", @f);
    }
    print($line);
}
if($list_edeprels)
{
    my @edeprels = sort(keys(%edeprels));
    foreach my $edeprel (@edeprels)
    {
        print STDERR ("$edeprel\n");
    }
}
