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

# In order to find the configuration file on the disk, we need to know the
# path to the script.
my $scriptpath;
BEGIN
{
    use Cwd;
    my $path = $0;
    $path = $1 if($path =~ m/^(.+\.pl)$/); # untaint $path
    $path =~ s:\\:/:g;
    my $currentpath = getcwd();
    $currentpath = $1 if($currentpath =~ m/^(.+)$/); # untaint $currentpath
    $scriptpath = $currentpath;
    if($path =~ m:/:)
    {
        $path =~ s:/[^/]*$:/:;
        chdir($path);
        $scriptpath = getcwd();
        $scriptpath = $1 if($scriptpath =~ m/^(.+)$/); # untaint $scriptpath
        chdir($currentpath);
    }
    require "$scriptpath/config.pm";
}

my $upload_dir = $config::config{upload_folder};
my $query = new CGI;
my $timestamp = $query->param('timestamp');
my $team = $query->param('team');
my $submid = $query->param('submid');
my $dataset = $query->param('dataset');
# Variables with the data from the form are tainted. Running them through a regular
# expression will untaint them and Perl will allow us to use them.
if($timestamp =~ m/^(\d+-\d+-\d+-\d+-\d+-\d+)$/)
{
    $timestamp = $1;
}
else
{
    die "Invalid timestamp '$timestamp'";
}
if ( $team =~ m/^([a-z0-9_]+)$/ )
{
    $team = $1;
}
else
{
    die "Team name '$team' contains invalid characters";
}
if ( $submid =~ m/^([a-z0-9_]+)$/ )
{
    $submid = $1;
}
else
{
    die "Submission ID '$submid' contains invalid characters";
}
if ( $dataset =~ m/^(dev|test)$/ )
{
    $dataset = $1;
}
else
{
    die "Dataset is not 'dev' or 'test'";
}
my $path = "$upload_dir/$timestamp-eval.log";
if(!-f $path)
{
    die "No log for timestamp '$timestamp'";
}
# Print the output.
$query->charset('utf-8'); # makes the charset explicitly appear in the headers
print $query->header ( );
print <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Refresh" content="30" />
  <title>$timestamp Status</title>
  <style type="text/css"> img {border: none;} </style>
</head>
<body>
  <p>The report on processing submission $timestamp is embedded below.
     If it is incomplete, reload the page later.</p>
  <pre>
EOF
;
open(LOG, "$upload_dir/$timestamp-eval.log") or die("Cannot read $upload_dir/$timestamp-eval.log: $!");
binmode(LOG, ':utf8');
my $last_line = '';
while(<LOG>)
{
    unless(m/^(Incoming path to an empty node ignored|Cyclic enhanced path will not be used)/)
    {
        $last_line = $_;
        # Make more readable the evaluator's complaint that non-whitespace characters do not match.
        # Replace escape sequences of the form \u0627 with the actual Unicode characters.
        if(m/^First 20 differing characters/)
        {
            while(m/\\u([0-9a-fA-F]+)/)
            {
                my $u = $1;
                my $c = chr(hex($u));
                $x =~ s/\\u$u/$c/g;
            }
        }
        # Escape special HTML characters.
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        # Highlight lines that say "Killed". They mean that e.g. the collapser ran out of memory and the subsequent evaluation failed.
        s/Killed/<span style='color:red;background-color:yellow'>Killed<\/span>/g;
        print;
    }
}
close(LOG);
print <<EOF
  </pre>
EOF
;
if($last_line =~ m/^Finished processing/)
{
    print("  <p>The submission has been processed. See <a href=\"eval.pl?team=$team&amp;submid=$submid&amp;dataset=$dataset\">here</a> for evaluation results.</p>\n");
}
else
{
    print("  <p>The processing has not finished yet, or did not finish successfully. If you do not see an error message above, refresh the page later.</p>\n");
}
print <<EOF
</body>
</html>
EOF
;
