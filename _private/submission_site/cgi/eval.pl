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

my $task_dir = $config::config{task_folder};
my $query = new CGI;
my $team = $query->param('team');
my $submid = $query->param('submid');
my $dataset = $query->param('dataset');
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
# Print the output.
$query->charset('utf-8'); # makes the charset explicitly appear in the headers
print $query->header ( );
# We must set our own PATH even if we do not depend on it.
# The system call may potentially use it, and the one from outside is considered insecure.
$ENV{'PATH'} = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';
system("/usr/bin/perl $task_dir/_private/tools/html_evaluation.pl $team $submid $dataset");
