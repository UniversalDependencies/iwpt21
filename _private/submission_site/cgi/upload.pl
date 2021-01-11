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

# Set the maximum size of an uploaded file to 30MB.
$CGI::POST_MAX = 30*1024*1024;
my $safe_filename_characters = 'a-zA-Z0-9_.-';
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
my $timestamp = sprintf("%4d-%02d-%02d-%02d-%02d-%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
# Before deploying this script, we must create the upload folder (see $upload_dir below).
# We also must chmod the folder to 777 (user www-data must be able to write to it).
my $upload_dir = '/usr/lib/cgi-bin/sysoutputs';
my $task_dir = '/home/zeman/iwpt2020';
my $query = new CGI;
my $remoteaddr = $query->remote_addr();
# The traffic is being forwarded through quest, so normally we see quest's local address as the remote address.
# Let's see if we have the real remote address in the environment.
if ( exists($ENV{HTTP_X_FORWARDED_FOR}) && $ENV{HTTP_X_FORWARDED_FOR} =~ m/^(\d+\.\d+\.\d+\.\d+)$/ )
{
    $remoteaddr = $1;
}
my $team = $query->param('team');
my $submid = $query->param('submid');
my $dataset = $query->param('dataset');
my $affiliation = decode('utf8', $query->param('affiliation'));
my $name = decode('utf8', $query->param('name'));
my $email = $query->param('email');
my $filename = $query->param('tgz');
# Variables with the data from the form are tainted. Running them through a regular
# expression will untaint them and Perl will allow us to use them.
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
if ( $affiliation =~ m/^([\p{L}\p{M}][-\., \p{L}\p{M}]+[\p{L}\p{M}])$/ )
{
    $affiliation = $1;
}
else
{
    die "Affiliation '$affiliation' contains invalid characters";
}
if ( $name =~ m/^([\p{L}\p{M}][-\., \p{L}\p{M}]+[\p{L}\p{M}])$/ )
{
    $name = $1;
}
else
{
    die "Submitter's name '$name' contains invalid characters";
}
if ( $email =~ m/^([-A-Za-z0-9_\.]+@[-A-Za-z0-9_]+(\.[-A-Za-z0-9_]+)+)$/ )
{
    $email = $1;
}
else
{
    die "E-mail '$email' does not seem valid; it does not match our regular expression for e-mail addresses";
}
if ( !$filename )
{
    print $query->header ( );
    print "There was a problem uploading your system output (perhaps the file is too large).\n";
    exit;
}
my ( $basename, $path, $extension ) = fileparse ( $filename, '..*' );
$filename = $basename . $extension;
$filename =~ tr/ /_/;
$filename =~ s/[^$safe_filename_characters]//g;
# $filename is a tainted variable. Running it through a regular expression will untaint it
# and Perl will allow us to use it.
if ( $filename =~ /^([$safe_filename_characters]+)$/ )
{
    $filename = $1;
    if ( $filename !~ m/^$team-$submid\.tgz$/ )
    {
        die "Filename must be '$team-$submid.tgz'";
    }
}
else
{
    die "Filename contains invalid characters";
}
# If the submission will rewrite an older submission with the same id, require
# that both submissions come from the same IP address.
my $previous_metadata = "$task_dir/_private/data/sysoutputs/$team/$submid/metadata.txt";
if(-f $previous_metadata)
{
    open(METADATA, $previous_metadata) or die("Cannot read '$previous_metadata': $!");
    binmode(METADATA, ':utf8');
    while(<METADATA>)
    {
        chomp();
        if(m/^remoteaddr=(\d+\.\d+\.\d+\.\d+)$/)
        {
            my $previous_remoteaddr = $1;
            if($remoteaddr ne $previous_remoteaddr)
            {
                die("Rejected: submission $submid of team $team already exists and the current IP address '$remoteaddr' differs from the previous one");
            }
            last;
        }
    }
    close(METADATA);
}
# Now get and save the file.
my $upload_filehandle = $query->upload('tgz');
open ( UPLOADFILE, ">$upload_dir/$timestamp-$filename" ) or die "$!";
binmode UPLOADFILE;
while ( <$upload_filehandle> )
{
    print UPLOADFILE;
}
close UPLOADFILE;
my $metadata = $filename;
$metadata =~ s/.tgz$/-metadata.txt/;
open ( METADATA, ">$upload_dir/$timestamp-$metadata" ) or die "$!";
binmode(METADATA, ':utf8');
print METADATA "timestamp=$timestamp\n";
print METADATA "remoteaddr=$remoteaddr\n";
print METADATA "team=$team\n";
print METADATA "submid=$submid\n";
print METADATA "dataset=$dataset\n";
print METADATA "affiliation=$affiliation\n";
print METADATA "name=$name\n";
print METADATA "email=$email\n";
print METADATA "filename=$filename\n";
close METADATA;
# Check the contents of the tgz archive.
# We must set our own PATH even if we do not depend on it.
# The backticks may potentially use it, and the one from outside is considered insecure.
$ENV{'PATH'} = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';
my $command = "/bin/gunzip -c $upload_dir/$timestamp-$filename | /bin/tar -tf -";
my $tgzcontentlist = `$command`;
# Untaint the output:
if ( $tgzcontentlist =~ m/^(.+)$/s )
{
    $tgzcontentlist = $1;
    $tgzcontentlist =~ s/\r?\n$//;
}
else
{
    die "$command\nreturned no output";
}
# Get the list of CoNLL-U files submitted. We will list them for the user to confirm we have found them.
my @conllufiles = split(/\n/, $tgzcontentlist);
my @errors;
my $nconllufiles = 0;
foreach my $cf (@conllufiles)
{
    if($cf !~ m/^(ar|bg|cs|en|et|fi|fr|it|lt|lv|nl|pl|ru|sk|sv|ta|uk)\.conllu$/)
    {
        push(@errors, "Unexpected filename '$cf'");
    }
    else
    {
        $nconllufiles++;
    }
}
if($nconllufiles != 17)
{
    push(@errors, "Found $nconllufiles files, expected 17");
}
if(scalar(@errors) > 0)
{
    $tgzcontentlist .= "\n\nWARNING:\n\n".join("\n", @errors);
}
# We keep all submissions in $upload_dir and we don't rewrite or remove them automatically.
# But we also create a working copy of the current submission and that's where the evaluation will happen.
system("/bin/cp $upload_dir/$timestamp-$metadata $task_dir/_private/data/sysoutputs/$metadata");
system("/bin/cp $upload_dir/$timestamp-$filename $task_dir/_private/data/sysoutputs/$filename");
system("/usr/bin/nohup /usr/bin/nice /usr/bin/perl $task_dir/_private/tools/evaluate_all.pl $team $submid $dataset > $upload_dir/$timestamp-eval.log 2>&1 &");
# Now thank the user for the submission.
$query->charset('utf-8'); # makes the charset explicitly appear in the headers
print $query->header ( );
print <<END_HTML
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Thanks!</title>
  <style type="text/css"> img {border: none;} </style>
</head>
<body>
  <p>Thanks for uploading your system output! The following information has been recorded:</p>
  <table border="0">
    <tr><td>Time stamp:</td><td>$timestamp</td></tr>
    <tr><td>Team name:</td><td>$team</td></tr>
    <tr><td>Submission ID:</td><td>$submid</td></tr>
    <tr><td>Dataset:</td><td>$dataset</td></tr>
    <tr><td>Team's affiliation:</td><td>$affiliation</td></tr>
    <tr><td>Submitter's name:</td><td>$name</td></tr>
    <tr><td>Submitter's e-mail address:</td><td>$email</td></tr>
    <tr><td>File name:</td><td>$filename</td></tr>
    <tr><td valign="top">File contents:</td><td valign="top"><pre>$tgzcontentlist</pre></td></tr>
  </table>
  <p>The submission is now being processed on the server.
     You can view the status of the processing
     <a href="status.pl?timestamp=$timestamp&amp;team=$team&amp;submid=$submid&amp;dataset=$dataset">here</a>.
     If there are any errors in your submission, such as invalid CoNLL-U files,
     fix your files and resubmit.</p>
</body>
</html>
END_HTML
; # '
