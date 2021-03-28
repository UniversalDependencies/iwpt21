#!/usr/bin/env perl
# Fixes enhanced deprels in French data.
# Copyright © 2019 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

while(<>)
{
    my $line = $_;
    if($line =~ m/^\d/)
    {
        my @f = split(/\t/, $line);
        # The basic DEPREL sometimes contains invalid extensions: "obj__nsubjXXX" etc.
        my $deprel = $f[7];
        unless($deprel eq '_')
        {
            $deprel = lc($deprel);
            $deprel =~ s/_.*//;
        }
        $f[7] = $deprel;
        my $edeps = $f[8];
        # Multi-word tokens have "_:_" here. They should have just "_".
        if($edeps eq '_:_')
        {
            $edeps = '_';
        }
        elsif($edeps ne '_')
        {
            my @edeps = map {m/^(\d+(?:\.\d+)?):(.+)$/; [$1, $2]} (split(/\|/, $edeps));
            foreach my $edep (@edeps)
            {
                my $h = $edep->[0];
                my $d = $edep->[1];
                # Some labels comprise two relations, surface and canonical, separated by "__".
                # As underscores cannot occur in relation labels, we will replace them by letters.
                # Furthermore, we must insert a colon to separate them from the universal part of the relation type (which will be verified by the validator).
                $d =~ s/__/:xox/g;
                # The enhanced relation from a controlled verb to its inherited subject is labeled "E:nsubj" instead of "nsubj" or "nsubj:xsubj".
                # This is not acceptable because relations must not contain uppercase letters, and because "nsubj" must be the first part of the label.
                # We can make it "nsubj:e" unless there is another subtype, e.g., "E:nsubj:pass".
                if($d =~ s/^E://)
                {
                    $d .= ':enh';
                }
                # The current French data does not contain case-enhanced relation labels.
                # Therefore, no label should contain more than one colon. (We may have introduced an extra colon in the above steps.)
                if($d =~ m/:.*:/)
                {
                    my @parts = split(/:/, $d);
                    my $firstpart = shift(@parts);
                    my $tail = join('', @parts);
                    $d = "$firstpart:$tail";
                }
                # Also apply lowercasing because some of the input labels contained uppercase "XXX".
                $d = lc($d);
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
