#!/usr/bin/env perl
# Takes a system output file for one language and splits it into parts corresponding
# to individual source treebanks.
# Copyright © 2020 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

# Usage: evaluate_all.pl TEAM SUBMID dev|test
#        TEAM = team name
#        SUBMID = submission id
#        'dev' or 'test' = what gold data should we use?
# Paths:
#        The code relies on fixed folder structure, which is hard-wired below.

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $ud_folder = '/home/zeman/unidep';
my $validate_script = "/usr/bin/python3 $ud_folder/tools/validate.py";
my $collapse_script = "/usr/bin/perl $ud_folder/tools/enhanced_collapse_empty_nodes.pl";

my $task_folder = "/home/zeman/iwpt2021";
my $gold_treebanks_folder = "$task_folder/_private/data"; # where are UD_* folders with both gold conllu and txt files; also, 'dev-gold' and 'test-gold' subfolders should be there
my $cut_script = "/usr/bin/perl $task_folder/_private/tools/match_and_split_conllu_by_input_text.pl";
my $eval_script = "/usr/bin/python3 $task_folder/iwpt21_xud_eval.py";
my $system_tgz_folder = "$task_folder/_private/data/sysoutputs";
my $system_unpacked_folder = "$task_folder/_private/data/sysoutputs";
my $archived_submissions_folder = "$task_folder/_private/data/archive/sysoutputs";

# List and ordering of treebanks for each language.
my %treebanks =
(
    'ar' => ['Arabic-PADT'],
    'bg' => ['Bulgarian-BTB'],
    'cs' => ['Czech-FicTree', 'Czech-CAC', 'Czech-PDT', 'Czech-PUD'],
    'nl' => ['Dutch-Alpino', 'Dutch-LassySmall'],
    'en' => ['English-EWT', 'English-GUM', 'English-PUD'],
    'et' => ['Estonian-EDT', 'Estonian-EWT'],
    'fi' => ['Finnish-TDT', 'Finnish-PUD'],
    'fr' => ['French-Sequoia', 'French-FQB'],
    'it' => ['Italian-ISDT'],
    'lv' => ['Latvian-LVTB'],
    'lt' => ['Lithuanian-ALKSNIS'],
    'pl' => ['Polish-LFG', 'Polish-PDB', 'Polish-PUD'],
    'ru' => ['Russian-SynTagRus'],
    'sk' => ['Slovak-SNK'],
    'sv' => ['Swedish-Talbanken', 'Swedish-PUD'],
    'ta' => ['Tamil-TTB'],
    'uk' => ['Ukrainian-IU']
);
# Enhancement type selection for each treebank.
my %enhancements =
(
    'Arabic-PADT'        => '4', # no xsubj
    'Bulgarian-BTB'      => '1', # all
    'Czech-FicTree'      => '0', # all
    'Czech-CAC'          => '0', # all
    'Czech-PDT'          => '0', # all
    'Czech-PUD'          => '3', # no coord depend
    'Dutch-Alpino'       => '0', # all
    'Dutch-LassySmall'   => '0', # all
    'English-EWT'        => '0', # all
    'English-GUM'        => '0', # all
    'English-PUD'        => '0', # all
    'Estonian-EDT'       => '4', # no xsubj
    'Estonian-EWT'       => '34', # no coord depend, no xsubj
    'Finnish-TDT'        => '0', # all
    'Finnish-PUD'        => '34', # no coord depend, no xsubj
    'French-Sequoia'     => '156', # no gapping, no relcl, no case deprel
    'French-FQB'         => '156', # no gapping, no relcl, no case deprel
    'Italian-ISDT'       => '0', # all
    'Latvian-LVTB'       => '0', # all
    'Lithuanian-ALKSNIS' => '0', # all
    'Polish-LFG'         => '1', # no gapping
    'Polish-PDB'         => '0', # all
    'Polish-PUD'         => '0', # all
    'Russian-SynTagRus'  => '3', # no coord depend
    'Slovak-SNK'         => '0', # all
    'Swedish-Talbanken'  => '0', # all
    'Swedish-PUD'        => '0', # all
    'Tamil-TTB'          => '14', # no gapping, no xsubj, no relcl
    'Ukrainian-IU'       => '0', # all
);

if(scalar(@ARGV)!=3)
{
    die("Three arguments expected: team name, submission id, and dev|test");
}
my $team_name = $ARGV[0];
my $submission_id = $ARGV[1];
my $portion = $ARGV[2];
if($team_name !~ m/^[a-z0-9_]+$/)
{
    die("Invalid team name '$team_name': must be [a-z0-9_]+");
}
if($submission_id !~ m/^[a-z0-9_]+$/)
{
    die("Invalid submission id '$submission_id': must be [a-z0-9_]+");
}
if($portion !~ m/^(dev|test)$/)
{
    die("Unknown data portion '$portion', should be 'dev' or 'test'");
}
my $gold_languages_folder = "$gold_treebanks_folder/$portion-gold";
my $system_tgz = "$system_tgz_folder/$team_name-$submission_id.tgz";
my $system_folder = "$system_unpacked_folder/$team_name/$submission_id";
# Make sure that the input TGZ archive exists.
if(!-e $system_tgz)
{
    die("Archive '$system_tgz' not found");
}
# If there already is a submission with the same id, we should replace it.
# However, we will keep it archived, just in case anything goes wrong.
if(-e $system_folder)
{
    my $archive_number = 1;
    my $archive_name = sprintf("$archived_submissions_folder/$team_name-$submission_id-%02d", $archive_number);
    while(-e $archive_name)
    {
        $archive_number++;
        $archive_name = sprintf("$archived_submissions_folder/$team_name-$submission_id-%02d", $archive_number);
    }
    print("$system_folder already exists. Archiving as $archive_name\n");
    system("mv $system_folder $archive_name");
}
# Unpack the submission.
if(!-d "$system_unpacked_folder/$team_name")
{
    mkdir("$system_unpacked_folder/$team_name") or die ("Cannot create folder '$system_unpacked_folder/$team_name': $!");
}
if(!-d "$system_unpacked_folder/$team_name/$submission_id")
{
    mkdir("$system_unpacked_folder/$team_name/$submission_id") or die ("Cannot create folder '$system_unpacked_folder/$team_name/$submission_id': $!");
}
my $command = "cd $system_folder && /bin/gunzip -c $system_tgz | /bin/tar xf -";
print STDERR ("Executing: $command\n");
system($command);
my $system_metadata = $system_tgz;
$system_metadata =~ s/\.tgz$/-metadata.txt/;
if(-f $system_metadata)
{
    system("/bin/cp $system_metadata $system_folder/metadata.txt");
}
# First evaluate each language against its gold standard without splitting the data by treebanks.
my %score;
my @languages = sort(keys(%treebanks));
my %errlang;
foreach my $language (@languages)
{
    my $gold = "$gold_languages_folder/$language.conllu";
    my $sys = "$system_folder/$language.conllu";
    if(!-e $gold)
    {
        die("Missing gold file '$gold'");
    }
    if(!-e $sys)
    {
        print("Missing system file '$sys'\n");
        next;
    }
    print("$sys\n");
    print("Validating on level 2...\n");
    if(!saferun("$validate_script --level 2 --lang ud $sys"))
    {
        # Invalid language, try next.
        $errlang{$language}++;
        next;
    }
    print("Collapsing empty nodes...\n");
    my $goldnen = $gold;
    $goldnen =~ s/\.conllu$/.gold.nen.conllu/;
    # We must not write in the gold standard folder.
    # (Especially not if this script is invoked by the user www-data who does not have write access there.)
    $goldnen =~ s/$gold_languages_folder/$system_folder/;
    my $sysnen = $sys;
    $sysnen =~ s/\.conllu$/.nen.conllu/;
    system("$collapse_script < $gold > $goldnen");
    system("$collapse_script < $sys > $sysnen");
    print("Evaluating against gold standard...\n");
    system("$eval_script -v $goldnen $sysnen > $system_folder/$language.eval.log");
    # Read the evaluation scores.
    open(EVAL, "$system_folder/$language.eval.log") or die("Cannot read '$system_folder/$language.eval.log': $!");
    while(<EVAL>)
    {
        s/\r?\n$//;
        if(m/^\w+.*\|.*\d+/)
        {
            my @f = split(/\s*\|\s*/, $_);
            my $metric = shift(@f);
            my $p = shift(@f);
            my $r = shift(@f);
            my $f = shift(@f);
            my $a = shift(@f);
            $score{language}{$language}{$metric} =
            {
                'p' => $p,
                'r' => $r,
                'f' => $f,
                'a' => $a
            };
        }
    }
    close(EVAL);
}
# Create a subfolder in the system output folder for per-treebank files.
my $pertreebank = $system_folder.'/pertreebank';
system("/bin/rm -rf $pertreebank");
mkdir($pertreebank) or die("Cannot create folder '$pertreebank': $!");
foreach my $language (@languages)
{
    # Do not perform per-treebank evaluation for languages whose input file
    # has errors.
    if($errlang{$language})
    {
        print("Skipping per-treebank evaluation of language [$language] because of errors in format.\n");
        next;
    }
    system("/bin/cp $system_folder/$language.conllu $pertreebank/rest.conllu");
    my @treebanks = @{$treebanks{$language}};
    foreach my $treebank (@treebanks)
    {
        my $treebank_folder = $gold_treebanks_folder.'/UD_'.$treebank;
        my ($langname, $tbkname) = split(/-/, $treebank);
        my $tcode = lc($tbkname);
        my $treebank_file = $language.'_'.$tcode.'-ud-'.$portion;
        my $treebank_enhancements = exists($enhancements{$treebank}) ? "--enhancements $enhancements{$treebank}" : '';
        # Some treebanks have test data but not dev data.
        if(-e "$treebank_folder/$treebank_file.conllu")
        {
            print("$treebank_file\n");
            system("$cut_script $treebank_folder/$treebank_file.txt $pertreebank/rest.conllu $pertreebank/$treebank_file-sys.conllu $pertreebank/rest2.conllu");
            system("/bin/mv $pertreebank/rest2.conllu $pertreebank/rest.conllu");
            system("$collapse_script < $treebank_folder/$treebank_file.conllu > $pertreebank/$treebank_file-gold.nen.conllu");
            system("$collapse_script < $pertreebank/$treebank_file-sys.conllu > $pertreebank/$treebank_file-sys.nen.conllu");
            system("$eval_script -v $treebank_enhancements $pertreebank/$treebank_file-gold.nen.conllu $pertreebank/$treebank_file-sys.nen.conllu > $pertreebank/$treebank_file.eval.log");
        }
        else
        {
            print("$treebank_file: $treebank_folder/$treebank_file.conllu does not exist\n");
        }
    }
}
# Print a summary of selected scores.
print("\nELAS F1-score Summary\n");
print(  "---------------------\n");
my $sum = 0;
my $n = scalar(@languages);
foreach my $language (@languages)
{
    my $score = $score{language}{$language}{ELAS}{f};
    print("$language\t$score\n");
    $sum += $score;
}
print(  "---------------------\n");
printf( "AVG\t%.2f\n", $sum/$n);
print("\n");
print("Finished processing $team_name $submission_id $portion.\n");



#------------------------------------------------------------------------------
# Calls an external program. Uses system(). In addition, echoes the command
# line to the standard error output, and returns true/false according to
# whether the call was successful and the external program returned 0 (success)
# or non-zero (error).
#
# Typically called as follows:
#     saferun($command) or die;
#------------------------------------------------------------------------------
sub saferun
{
    my $command = join(' ', @_);
#    my $ted = cas::ted()->{datumcas};
#    print STDERR ("[$ted] Executing: $command\n");
    system($command);
    # The external program does not exist, is not executable or the execution failed for other reasons.
    if($?==-1)
    {
        die("ERROR: Failed to execute: $command\n  $!\n");
    }
    # We were able to start the external program but its execution failed.
    elsif($? & 127)
    {
        printf STDERR ("ERROR: Execution of: $command\n  died with signal %d, %s coredump\n",
            ($? & 127), ($? & 128) ? 'with' : 'without');
        die;
    }
    # The external program ended "successfully" (this still does not guarantee
    # that the external program returned zero!)
    else
    {
        my $exitcode = $? >> 8;
        print STDERR ("Exit code: $exitcode\n") if($exitcode);
        # Return false if the program returned a non-zero value.
        # It is up to the caller how they will handle the return value.
        # (The easiest is to always write:
        # saferun($command) or die;
        # )
        return ! $exitcode;
    }
}
