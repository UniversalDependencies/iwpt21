#!/usr/bin/env perl
# Merges multiple UD test files (blind text or CoNLL-U) into one.
# Makes sure that there is a document break in the resulting file at every position where one original file ended and another started.
# This will make it easier to later isolate parser outputs for individual input parts.
# Copyright © 2020 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
if(scalar(@ARGV) < 2)
{
    print STDERR ("Usage: perl mergetest.pl nl.txt UD_Dutch-Alpino/nl_alpino-ud-test.txt UD_Dutch-LassySmall/nl_lassysmall-ud-test.txt\n");
    die("Expected at least two arguments: the target file and at least one source file");
}
my $outfile = shift(@ARGV);
# Trigger mode CoNLL-U if the target file name ends in ".conllu"; assume text mode otherwise.
my $conllu = $outfile =~ m/\.conllu$/;
open(OUT, ">$outfile") or die("Cannot write '$outfile': $!");
my $n = scalar(@ARGV);
my $i = 0;
foreach my $infile (@ARGV)
{
    if($conllu)
    {
        # We do not know whether the input file does or does not use the "newdoc" flags; they are optional.
        # If there is a "newdoc" before the first sentence, we do not want to add our own.
        # If it is not there, we want to add it.
        # Hence we must first read the first few lines to see the situation, then act accordingly.
        my $hasnewdoc = 0;
        open(IN, $infile) or die("Cannot read '$infile': $!");
        while(<IN>)
        {
            if(m/^\#\s*newdoc( |$)/)
            {
                $hasnewdoc = 1;
                last;
            }
            elsif(m/^\d/)
            {
                # First token line and still no newdoc found? Stop it.
                last;
            }
        }
        close(IN);
        unless($hasnewdoc)
        {
            print OUT ("\# newdoc\n");
        }
    }
    open(IN, $infile) or die("Cannot read '$infile': $!");
    while(<IN>)
    {
        print OUT;
    }
    close(IN);
    # In text mode, print an empty line after each file except the last one.
    $i++;
    if(!$conllu && $i < $n)
    {
        print OUT ("\n");
    }
}
close(OUT);
