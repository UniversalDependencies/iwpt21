#!/usr/bin/env perl
# Scans the folder with the evaluation results of a shared task submission.
# Collects all scores and creates a HTML page that presents them.
# Copyright © 2020-2021 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ':utf8';
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

# In order to find the configuration file on the disk, we need to know the
# path to the script.
BEGIN
{
    use Cwd;
    my $path = $0;
    $path =~ s:\\:/:g;
    my $currentpath = getcwd();
    $scriptpath = $currentpath;
    if($path =~ m:/:)
    {
        $path =~ s:/[^/]*$:/:;
        chdir($path);
        $scriptpath = getcwd();
        chdir($currentpath);
    }
    require "$scriptpath/config.pm";
}

my $system_unpacked_folder = $config::config{system_unpacked_folder};
# List of language codes and names.
my %languages = %{$config::config{languages}};
my @languages = sort {$languages{$a} cmp $languages{$b}} (keys(%languages));
# List and ordering of treebanks for each language.
my %dev_treebanks = %{$config::config{dev_treebanks}};
my %test_treebanks = %{$config::config{test_treebanks}};
# Enhancement type selection for each treebank (only for information in the table).
my %enhancements = %{$config::config{enhancements}};

if(scalar(@ARGV)!=3)
{
    die("Three arguments expected: team name, submission id, and dev|test");
}
my $team = $ARGV[0];
my $submid = $ARGV[1];
my $portion = $ARGV[2];
if($team !~ m/^[a-z0-9_]+$/)
{
    die("Invalid team name '$team': must be [a-z0-9_]+");
}
if($submid !~ m/^[a-z0-9_]+$/)
{
    die("Invalid submission id '$submid': must be [a-z0-9_]+");
}
if($portion !~ m/^(dev|test)$/)
{
    die("Unknown data portion '$portion', should be 'dev' or 'test'");
}
my $submission_folder = "$system_unpacked_folder/$team/$submid";
my %treebanks = $portion eq 'dev' ? %dev_treebanks : %test_treebanks;

foreach my $language (@languages)
{
    # Read the evaluation scores.
    my $file = "$submission_folder/$language.eval.log";
    if(-f $file)
    {
        open(EVAL, $file) or die("Cannot read '$file': $!");
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
}
my @treebanks;
my $doing_dev;
foreach my $language (@languages)
{
    my $language_reliable = exists($score{language}{$language});
    foreach my $treebank (@{$treebanks{$language}})
    {
        push(@treebanks, $treebank);
        my $tcode = lc($treebank);
        $tcode =~ s/^.+-//;
        # Read the evaluation scores.
        my $file = "$submission_folder/pertreebank/${language}_$tcode-ud";
        if(-e "$file-dev.eval.log" && -e "$file-test.eval.log")
        {
            die("Both dev and test eval.log exist for '$file'");
        }
        elsif(-e "$file-dev.eval.log")
        {
            $file .= '-dev.eval.log';
            if(!defined($doing_dev))
            {
                $doing_dev = 1;
            }
            elsif($doing_dev==0)
            {
                die("Both dev and test eval logs are present in the per-treebank folder.");
            }
        }
        elsif(-e "$file-test.eval.log")
        {
            $file .= '-test.eval.log';
            if(!defined($doing_dev))
            {
                $doing_dev = 0;
            }
            elsif($doing_dev==1)
            {
                die("Both dev and test eval logs are present in the per-treebank folder.");
            }
        }
        # Score of a treebank is not reliable if the score for the language does not exist.
        if(-f $file && $language_reliable)
        {
            open(EVAL, $file) or die("Cannot read '$file': $!");
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
                    $score{treebank}{$treebank}{$metric} =
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
        # For comparison, add a copy of (link to) the language coarse scores to each treebank.
        $score{treebank}{$treebank}{language} = $score{language}{$language};
        # Sum up (and average) the qualitative ELAS scores for each language.
        $score{language}{$language}{QualitativeSUM}{ELAS}{f} += $score{treebank}{$treebank}{ELAS}{f};
        $score{language}{$language}{QualitativeCNT}++;
    }
}
my $html = "<html>\n";
$html .= "<head>\n";
$html .= "  <title>IWPT Results of $team/$submid</title>\n";
$html .= "</head>\n";
$html .= "<body>\n";
$html .= "  <h1>IWPT $config::config{year} Shared Task Results of <span style='color:blue'>$team</span>/$submid</h1>\n";
my @metrics = qw(Tokens Words Sentences UPOS XPOS UFeats AllTags Lemmas UAS LAS CLAS MLAS BLEX EULAS ELAS);
$html .= "  <h2>Coarse F<sub>1</sub> Scores</h2>\n";
$html .= "  <p>Each score pertains to the combined test set of the language, without distinguishing individual treebanks and the enhancement types they annotate. The last line shows the macro-average over languages.</p>\n";
$html .= "  <table>\n";
$html .= "    <tr><td><b>Language</b></td>";
foreach my $metric (@metrics)
{
    $html .= "<td><b>$metric</b></td>";
}
$html .= "</tr>\n";
foreach my $language (@languages)
{
    my $lh = $score{language}{$language};
    $html .= "    <tr><td>$languages{$language}</td>";
    foreach my $metric (@metrics)
    {
        $html .= "<td>$lh->{$metric}{f}</td>";
        $score{language}{SUM}{$metric}{f} += $lh->{$metric}{f};
    }
    $html .= "</tr>\n";
}
my $n = scalar(@languages);
$html .= "    <tr><td><b>Average</b></td>";
foreach my $metric (@metrics)
{
    $score{language}{AVG}{$metric}{f} = $n > 0 ? sprintf("%.2f", $score{language}{SUM}{$metric}{f}/$n) : '';
    $html .= "<td><b>$score{language}{AVG}{$metric}{f}</b></td>";
}
$html .= "</tr>\n";
$html .= "  </table>\n";
$html .= "  <h2>Qualitative F<sub>1</sub> Scores</h2>\n";
$html .= "  <p>The system output for each language was split into parts corresponding to individual source treebanks. ".
              "The scores then ignore errors in enhancement types for which the treebank lacks gold-standard annotation. ".
              "The column LAvgELAS shows the qualitative ELAS averaged over treebanks of the same language; ".
              "the final average in bold is averaged over languages rather than treebanks. ".
              "For comparison, the last column then shows the coarse ELAS F<sub>1</sub> for the given language.</p>\n";
$html .= "  <table>\n";
$html .= "    <tr><td><b>Treebank</b></td>";
foreach my $metric (@metrics)
{
    $html .= "<td><b>$metric</b></td>";
}
# Inform about omitted enhancements in the treebank.
$html .= "<td><b>Enhancements</b></td>";
# Add a column for the average of the qualitative ELAS scores over the treebanks of one language.
$html .= "<td><b>LAvgELAS</b></td>";
# Add a column for comparison with language coarse ELAS.
$html .= "<td><b>cf.</b></td>";
$html .= "</tr>\n";
foreach my $treebank (@treebanks)
{
    my $lh = $score{treebank}{$treebank};
    $html .= "    <tr><td>$treebank</td>";
    foreach my $metric (@metrics)
    {
        $html .= "<td>$lh->{$metric}{f}</td>";
        $score{treebank}{SUM}{$metric}{f} += $lh->{$metric}{f};
    }
    # Indicate which enhancements are missing in the treebank.
    my $omitted = $enhancements{$treebank} ne '' ? "($enhancements{$treebank})" : '';
    $html .= "<td>$omitted</td>";
    # Average the qualitative ELAS scores for each language.
    my $sum = $lh->{language}{QualitativeSUM}{ELAS}{f};
    my $cnt = $lh->{language}{QualitativeCNT};
    my $avg = $lh->{language}{QualitativeAVG}{ELAS}{f} = $cnt==0 ? 0 : sprintf("%.2f", $sum/$cnt);
    $html .= "<td>$avg</td>";
    # Add a column for comparison with language coarse ELAS.
    $html .= "<td>$lh->{language}{ELAS}{f}</td>";
    $html .= "</tr>\n";
}
$n = scalar(@treebanks);
$html .= "    <tr><td><b>Average</b></td>";
foreach my $metric (@metrics)
{
    $score{treebank}{AVG}{$metric}{f} = $n==0 ? 0 : sprintf("%.2f", $score{treebank}{SUM}{$metric}{f}/$n);
    $html .= "<td><b>$score{treebank}{AVG}{$metric}{f}</b></td>";
}
# Inform about omitted enhancements in the treebank.
$html .= "<td></td>";
# Add a column for the average of the qualitative ELAS scores over the treebanks of one language.
# We want to average these averages over languages, not over treebanks!
my $sum = 0;
$n = scalar(@languages);
foreach my $language (@languages)
{
    $sum += $score{language}{$language}{QualitativeAVG}{ELAS}{f};
}
$score{language}{QualitativeAVG}{ELAS}{f} = $n==0 ? 0 : sprintf("%.2f", $sum/$n);
$html .= "<td><b>$score{language}{QualitativeAVG}{ELAS}{f}</b></td>";
# Add a column for comparison with language coarse ELAS.
$html .= "<td></td>";
$html .= "</tr>\n";
$html .= "  </table>\n";
$html .= "</body>\n";
$html .= "</html>\n";
print($html);
