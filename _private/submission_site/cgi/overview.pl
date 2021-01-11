#!/usr/bin/perl -wT

use strict;
use utf8;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
#binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use Encode;

my $sysoutputs = '/home/zeman/iwpt2020/_private/data/sysoutputs';
# We must set our own PATH even if we do not depend on it.
# The system call may potentially use it, and the one from outside is considered insecure.
$ENV{'PATH'} = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';
# Print the output.
my $query = new CGI;
$query->charset('utf-8'); # makes the charset explicitly appear in the headers
print($query->header());
print <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Submissions</title>
  <style type="text/css"> img {border: none;} </style>
</head>
<body>
  <h1>Submissions</h1>
  <table>
    <tr><th>Timestamp</th><th>Team</th><th>Submission</th><th>Dataset</th><th>Name</th><th>Affiliation</th><th>Status</th><th>Eval</th></tr>
EOF
;
# Scan the sysoutputs folder for subfolders (one subfolder per team).
my @submissions = ();
opendir(DIR, $sysoutputs) or die("Cannot read folder '$sysoutputs': $!");
my @objects = readdir(DIR);
closedir(DIR);
foreach my $team (@objects)
{
    next unless($team !~ m/^\./ && -d "$sysoutputs/$team");
    # Scan the team folder for subfolders (one subfolder per submission).
    opendir(DIR, "$sysoutputs/$team") or die("Cannot read folder '$sysoutputs/$team': $!");
    my @submids = readdir(DIR);
    closedir(DIR);
    foreach my $submid (@submids)
    {
        next unless($submid !~ m/^\./ && -d "$sysoutputs/$team/$submid");
        my $metadata = "$sysoutputs/$team/$submid/metadata.txt";
        if(-f $metadata)
        {
            my %metadata;
            open(META, $metadata) or die("Cannot read '$metadata': $!");
            binmode(META, ':utf8');
            while(<META>)
            {
                chomp();
                if(m/^([a-z]+)=(.+)$/)
                {
                    $metadata{$1} = $2;
                }
            }
            close(META);
            # Are there any evaluation logs in the submission folder?
            opendir(DIR, "$sysoutputs/$team/$submid") or die("Cannot read folder '$sysoutputs/$team/$submid': $!");
            my @evallogs = grep {m/\.eval\.log$/} (readdir(DIR));
            closedir(DIR);
            $metadata{evallogs} = scalar(@evallogs);
            push(@submissions, \%metadata);
        }
    }
}
# Sort the submissions by their timestamp.
@submissions = sort {$a->{timestamp} cmp $b->{timestamp}} (@submissions);
# Identify the primary submission of each team.
my $deadline = '2020-04-25-14-05-00';
my %primary;
foreach my $submission (@submissions)
{
    if($submission->{dataset} eq 'test' && $submission->{timestamp} le $deadline)
    {
        if(!exists($primary{$submission->{team}}))
        {
            $primary{$submission->{team}} = $submission;
        }
        elsif($submission->{submid} !~ m/^secondary/)
        {
            $primary{$submission->{team}} = $submission;
        }
    }
}
my $n = 0;
my $was_hr = 0;
foreach my $submission (@submissions)
{
    # 24.4.2020 23:59 anywhere on Earth = 25.4.2020 13:59 Central-European Daylight Saving Time
    if($submission->{timestamp} gt $deadline && !$was_hr)
    {
        print("    <tr><td colspan='100%'><hr/></td></tr>\n");
        $was_hr = 1;
    }
    my $style = $submission == $primary{$submission->{team}} ? ' style="color:blue"' : '';
    # Use a different color for the baseline submissions.
    # Do this regardless whether it is the primary submission and whether the deadline has passed.
    if($submission->{team} =~ m/^baseline/)
    {
        $style = ' style="color:red"';
    }
    # We have one submission that mistakenly inserts 'secondary' in the team name rather than submission id.
    # According to the rules we should treat it as a different team, but the fact is, the name of the submitter and the affiliation matches the non-secondary team.
    if($style ne '' && $submission->{team} =~ m/^secondary/)
    {
        $style = ' style="color:purple"';
    }
    if($style =~ m/blue/)
    {
        $n++;
    }
    print("    <tr$style>");
    print("<td>$submission->{timestamp}</td>");
    print("<td>$submission->{team}</td>");
    print("<td>$submission->{submid}</td>");
    print("<td>$submission->{dataset}</td>");
    print("<td>$submission->{name}</td>");
    print("<td>$submission->{affiliation}</td>");
    print("<td><a href=\"status.pl?timestamp=$submission->{timestamp}&amp;team=$submission->{team}&amp;submid=$submission->{submid}&amp;dataset=$submission->{dataset}\">status</a></td>");
    print("<td>");
    if($submission->{evallogs})
    {
        print("<a href=\"eval.pl?team=$submission->{team}&amp;submid=$submission->{submid}&amp;dataset=$submission->{dataset}\">eval</a>");
    }
    print("</td>");
    print("</tr>\n");
}
print <<EOF
  </table>
  <p>Total $n primary submissions (not counting baselines).</p>
</body>
</html>
EOF
;
