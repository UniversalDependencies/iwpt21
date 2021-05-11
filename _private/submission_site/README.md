# Shared Task Submission Site

[https://quest.ms.mff.cuni.cz/sharedtask/](https://quest.ms.mff.cuni.cz/sharedtask/)

This folder contains files that are needed on the submission web server 'sharedtask'
(maintained by Dan at Charles University). On the server, this repository is cloned
in Dan's home folder and the relevant files are symlinked from the folders where the
Apache server looks for content:

<pre>
/var/www/html/index.html   --> $REPO/<nowiki>_</nowiki>private/submission<nowiki>_</nowiki>site/html
/usr/lib/cgi-bin/upload.pl --> $REPO/<nowiki>_</nowiki>private/submission<nowiki>_</nowiki>site/cgi
    (... same for all other cgi scripts ...)
/usr/lib/cgi-bin/config.pm --> $REPO/<nowiki>_</nowiki>private/tools
</pre>

The server's configuration permits following of symlinks if the owner of the source
and the target is the same.

