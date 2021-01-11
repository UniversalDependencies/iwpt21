#!/usr/bin/env perl
# Reads a plain text and a CoNLL-U file. Splits the CoNLL-U file into two so that
# the first part matches the plain text and the second part contains the rest.
# Copyright © 2020 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use Carp; # confess() instead of die()

if(scalar(@ARGV) != 4)
{
    die("4 arguments expected: 1. input text; 2. input conllu; 3. output first part; 4. output second part");
}
my $intext = shift(@ARGV);
my $inconllu = shift(@ARGV);
my $outpart1 = shift(@ARGV);
my $outpart2 = shift(@ARGV);
# To make my life easier, I am assuming that the plain text fits in the memory
# and I am going to read the entire file first.
open(TEXT, $intext) or die("Cannot read '$intext': $!");
my $text = '';
while(<TEXT>)
{
    $text .= $_;
}
close(TEXT);
# We will ignore whitespace characters and only synchronize on the non-whitespace ones.
$text =~ s/\s//sg;
# Read the input CoNLL-U file and check it against the input text.
open(IN, $inconllu) or die("Cannot read '$inconllu': $!");
open(OUT, ">$outpart1") or die("Cannot write '$outpart1': $!");
my $writingpart = 1;
my $incomplete_sentence = 0;
my @sentence = ();
my $mwtuntil;
while(<IN>)
{
    push(@sentence, $_);
    if(m/^\d+-(\d+)\t/)
    {
        $mwtuntil = $1;
        my @f = split(/\t/, $_);
        check_word_form($f[1]) if($writingpart==1);
    }
    elsif(m/^(\d+)\t/)
    {
        my $id = $1;
        if(defined($mwtuntil) && $id > $mwtuntil)
        {
            $mwtuntil = undef;
        }
        unless(defined($mwtuntil))
        {
            my @f = split(/\t/, $_);
            check_word_form($f[1]) if($writingpart==1);
        }
    }
    elsif(m/^\s*$/) # end of sentence
    {
        if($incomplete_sentence)
        {
            @sentence = fix_sentence(@sentence);
            $incomplete_sentence = 0;
        }
        my $sentence = join('', @sentence);
        print OUT ($sentence);
        if($writingpart==1 && length($text)==0)
        {
            close(OUT);
            open(OUT, ">$outpart2") or die("Cannot write '$outpart2': $!");
            $writingpart = 2;
        }
        @sentence = ();
        $mwtuntil = undef;
    }
}
close(IN);
close(OUT);



#------------------------------------------------------------------------------
# Checks the next word form against the input text, and removes it from the
# input text. The form is a parameter, the input text is accessed directly as
# a global variable.
#------------------------------------------------------------------------------
sub check_word_form
{
    my $form = shift;
    # This function should be used only if the global variable $writingpart == 1.
    if($writingpart != 1)
    {
        confess("Expected \$writingpart == 1 but it is '$writingpart'");
    }
    # If there are words with spaces, we ignore the spaces.
    $form =~ s/\s//g;
    my $nt = length($text);
    my $nf = length($form);
    if($nt == 0)
    {
        ###!!! We access directly the global variable with the sentence.
        ###!!! This should perhaps be done better in the future.
        my @sentence1 = @sentence;
        # The current line contains a form that is not in the input text. Discard it.
        # Replace it by the empty line that should terminate every sentence.
        my $current_line = pop(@sentence1);
        push(@sentence1, "\n");
        @sentence1 = fix_sentence(@sentence1);
        my $sentence1 = join('', @sentence1);
        print OUT ($sentence1);
        close(OUT);
        open(OUT, ">$outpart2") or die("Cannot write '$outpart2': $!");
        $writingpart = 2;
        # Modify the current sentence. Keep comments but remove tokens except
        # the current one.
        my @sentence2 = ();
        foreach my $line (@sentence)
        {
            if($line =~ m/^\#/)
            {
                push(@sentence2, $line);
            }
            else
            {
                last;
            }
        }
        push(@sentence2, $current_line);
        @sentence = @sentence2;
        # Set the global flag that the current sentence is incomplete.
        $incomplete_sentence = 1;
        return 0;
    }
    elsif($nf > $nt)
    {
        ###!!!
        # We currently do not support breaking in the middle of a token.
        confess("Input text ends in the middle of a token, which is not supported at present");
    }
    my $prefix = substr($text, 0, $nf);
    $text = substr($text, $nf);
    if($prefix ne $form)
    {
        confess("Word form in CoNLL-U '$form' does not match the input text '$prefix'");
    }
    return 1;
}



#------------------------------------------------------------------------------
# Modifies an incomplete sentence so that it can be printed as a valid CoNLL-U.
#------------------------------------------------------------------------------
sub fix_sentence
{
    my @sentence = @_;
    # Collect node ids that exist in the sentence.
    my @ids;
    my %ids;
    foreach my $line (@sentence)
    {
        if($line =~ m/^(\d+(\.\d+)?)\t/)
        {
            my $id = $1;
            push(@ids, $id);
            $ids{$id}++;
        }
    }
    # Change references to non-existing head nodes to 0.
    foreach my $line (@sentence)
    {
        if($line =~ m/^\d/)
        {
            my @f = split(/\t/, $line);
            # The HEAD column.
            if($f[6] =~ m/^\d+$/ && !exists($ids{$f[6]}))
            {
                $f[6] = 0;
            }
            # The DEPS column.
            if($f[8] ne '_')
            {
                my @deps = split(/\|/, $f[8]);
                foreach my $dep (@deps)
                {
                    if($dep =~ m/^(\d+(?:\.\d+)?):(.+)$/)
                    {
                        my $h = $1;
                        my $d = $2;
                        if(!exists($ids{$h}))
                        {
                            $h = 0;
                            $dep = "$h:$d";
                        }
                    }
                }
                $f[8] = join('|', @deps);
            }
            $line = join("\t", @f);
        }
    }
    # If the ids do not start with 1 (or 0.something), shift them.
    # First determine what the mapping should be.
    # Assume that the original sentence had a valid sequence of ids, i.e.,
    # if the first id is 0.* or 1, no action is needed, and otherwise only
    # constant subtraction is needed.
    if($ids[0] != m/^(1|0\.\d+)$/)
    {
        my $offset = 0;
        if($ids[0] =~ m/^(\d+)\.\d+$/)
        {
            $offset = $1;
        }
        else
        {
            $offset = $ids[0]-1;
        }
        foreach my $line (@sentence)
        {
            if($line =~ m/^\d/)
            {
                my @f = split(/\t/, $line);
                # The ID column.
                if($f[0] =~ m/^(\d+)-(\d+)$/)
                {
                    my $from = $1;
                    my $to = $2;
                    $from -= $offset;
                    $to -= $offset;
                    $f[0] = "$from-$to";
                }
                else
                {
                    $f[0] -= $offset;
                }
                # The HEAD column.
                if($f[6] =~ m/^\d+$/ && $f[6] > $offset)
                {
                    $f[6] -= $offset;
                }
                # The DEPS column.
                if($f[8] ne '_')
                {
                    my @deps = split(/\|/, $f[8]);
                    foreach my $dep (@deps)
                    {
                        if($dep =~ m/^(\d+(?:\.\d+)?):(.+)$/)
                        {
                            my $h = $1;
                            my $d = $2;
                            if($h > $offset)
                            {
                                $h -= $offset;
                                $dep = "$h:$d";
                            }
                        }
                    }
                    $f[8] = join('|', @deps);
                }
                $line = join("\t", @f);
            }
        }
    }
    # Fix the sentence text attribute.
    my $sentence_text = '';
    my $mwtuntil;
    foreach my $line (@sentence)
    {
        if($line =~ m/^\d+-(\d+)\t/)
        {
            $mwtuntil = $1;
            my @f = split(/\t/, $line);
            $sentence_text .= $f[1];
            $sentence_text .= ' ' unless(is_no_space_after($f[9]));
        }
        elsif($line =~ m/^(\d+)\t/)
        {
            my $id = $1;
            if(defined($mwtuntil) && $id > $mwtuntil)
            {
                $mwtuntil = undef;
            }
            unless(defined($mwtuntil))
            {
                my @f = split(/\t/, $line);
                $sentence_text .= $f[1];
                $sentence_text .= ' ' unless(is_no_space_after($f[9]));
            }
        }
    }
    $sentence_text =~ s/\s+$//;
    foreach my $line (@sentence)
    {
        if($line =~ m/^\#\s*text\s*=\s*.+/)
        {
            $line = "\# text = $sentence_text\n";
        }
    }
    return @sentence;
}



#------------------------------------------------------------------------------
# Checks whether the MISC column contains SpaceAfter=No.
#------------------------------------------------------------------------------
sub is_no_space_after
{
    my $misc = shift;
    # MISC is the last column and we do not know whether the end-of-line character has been removed.
    $misc =~ s/\r?\n$//;
    my @nospaceafter = grep {$_ eq 'SpaceAfter=No'} (split(/\|/, $misc));
    return scalar(@nospaceafter) > 0;
}
