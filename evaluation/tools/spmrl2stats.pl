#!/usr/bin/env perl

## build HTML stat file from SPRML log

use strict;
use AppConfig qw/:argcount :expand/;

use Text::Table;
use CGI::Pretty qw/:standard *table *ul/;
use List::Util qw/min max/;
use Template;
use File::Slurp qw{slurp};
use YAML::XS qw{DumpFile};

$YAML::XS::QuoteNumericStrings=0;

my $config = AppConfig->new(
                            "verbose!" => {DEFAULT => 1},
                            "html=f" => {DEFAULT => "spmrl_stats.html"},
			    "yaml=f" => {DEFAULT => "spmrl_best.yml"},
			    "scp=f",
			    "loop!" => {DEFAULT => 0},
			    );

$config->args();

my @dir = @ARGV;

@dir or @dir = glob("spmrl_*.beam*");

my $html = $config->html;
my $scp = $config->scp;
my $loop = $config->loop;

my $template = slurp(\*DATA);
 
my $hosts = {};
my $oldres = {};

process_all_old_res();

while(1) {

    my %beam = ();
    my %lang = ();
    my $niters = 0;
    my %best = ();

    foreach my $dir (@dir) {
	-d $dir or next;
	$dir =~ /spmrl_(\w+?)_(gold|pred).*\.beam(\d+)/ or next;
	my ($lang,$mode,$beam) = ($1,$2,$3);
	$beam{$beam}{$lang}{$mode}{dir} = $dir;
	my $log = "$dir/train.log";
	-f $log or next;
	open(LOG,"<",$log) || die "can read log file $log: $!";
	my $iter;
	while(<LOG>) {
	    /:\straining\s+hostname=(\S+)/ and $hosts->{$lang}{$mode}{$beam} = $1;
	    /:\s+iteration\s+(\d+)/ and $iter=$1;
	    /^\[(.+?)\]/ and $beam{$beam}{$lang}{$mode}{timestamp} = $1;
	    /\s+LAS=(\S+)/ or next;
	    my $score = $1;
	    $beam{$beam}{$lang}{$mode}{iter}{$iter} = $score;
	    $lang{$lang}{$beam}{$mode}{iter}{$iter} = $score;
	    if ($beam{$beam}{$lang}{$mode}{max} < $score) {
		$beam{$beam}{$lang}{$mode}{max} = $score;
		$beam{$beam}{$lang}{$mode}{maxiter} = $iter;
	    }
	    if ($lang{$lang}{$beam}{$mode}{max} < $score) {
		$lang{$lang}{$beam}{$mode}{max} = $score;
		$lang{$lang}{$beam}{$mode}{maxiter} = $iter;
	    }
	    if ($best{$lang}{$mode}{max} < $score) {
		$best{$lang}{$mode}{max} = $score;
		$best{$lang}{$mode}{maxiter} = $iter;
		$best{$lang}{$mode}{beam} = $beam;
	    }
	    $niters < $iter and $niters = $iter;
	}
	close(LOG);
    }

    
    my $tt=Template->new({});
    
    $tt->process(\$template,
		 {
		     beams => \%beam,
		     langs => \%lang,
		     best => \%best,
		     iters => [1 .. $niters],
		     hosts => $hosts,
		     oldres => $oldres,
		     info => {
			 french => { lang => 'French', train => 14759, dev => 1235 },
			 german => {  lang => 'German', train => 40472, dev => 5000 },
			 swedish => {  lang => 'Swedish', train => 5000, dev => 493 },
			 polish => {  lang => 'Polish', train => 6578, dev => 821 },
			 korean => {  lang => 'Korean', train => 23010, dev => 2066 },
			 arabic => {  lang => 'Arabic', train => 15762, dev => 1985 },
			 basque => {  lang => 'Basque', train => 7577, dev => 948 },
			 hebrew => {  lang => 'Hebrew', train => 5000, dev => 500 },
			 hungarian => {  lang => 'Hungarian', train => 8146, dev => 1051 },
		     }
		 },
		 $html
		 )
	or die "can't process template: $!";

    $scp and system("scp $html $scp");

    DumpFile($config->yaml,\%lang);

    $loop or last;
    sleep(120);
}


sub process_old_res {
    my $dir = shift;
    -d $dir or next;
    my ($date) = $dir =~ /old(\S+)/;
    my @dir = glob("$dir/spmrl_*.beam*");
    foreach my $ldir (@dir) {
	-d $ldir or next;
	$ldir =~ /spmrl_(\w+?)_(gold|pred).*\.beam(\d+)/ or next;
	my ($lang,$mode,$beam) = ($1,$2,$3);
	my $log = "$ldir/train.log";
	-f $log or next;
	open(LOG,"<",$log) || die "can read log file $log: $!";
	my $iter;
	while(<LOG>) {
	    /:\s+iteration\s+(\d+)/ and $iter=$1;
	    /\s+LAS=(\S+)/ or next;
	    my $score = $1;
	    if ($score > $oldres->{$lang}{$mode}{max}) {
		$oldres->{$lang}{$mode} = { max => $score, dir => $date, beam => $beam, iter => $iter };
	    }
	}
	close(LOG);
    }
}

sub process_all_old_res {
    process_old_res($_) foreach (glob("spmrl.old*"));
}

##    <meta http-equiv="REFRESH" content="120">

__END__
[%- USE date -%]
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="fr">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>SPMRL 2013 Shared Task Results : Dependency Track</title>
    <link rel="stylesheet" href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css" />
    <script src="http://code.jquery.com/jquery-1.9.1.js"></script>
    <script src="http://code.jquery.com/ui/1.10.3/jquery-ui.js"></script>
    <style type="text/css">
     <!--
       .hilight { background: lightgreen; }
     -->
   </style>
   <script type="text/javascript" language="javascript">
<!--
        function showhide(obj) {
           var el=document.getElementById(obj);
           if (el.style.display == "none") {
              el.style.display = "block";
           } else {
              el.style.display = "none";
           }
        }
        function show(obj) {
           var el=document.getElementById(obj);
           el.style.display = "block";
        }
      $(function() {
         $( "#tabs" ).tabs();
         $( "#tabs-1" ).tabs();
         $( "#tabs-2" ).tabs();
         $( "#tabs-3" ).tabs();
      });
-->
  </script>
    <!--Load the AJAX API-->
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
    
      // Load the Visualization API and the piechart package.
      google.load('visualization', '1', {'packages':['corechart','table']});
      
      // Set a callback to run when the Google Visualization API is loaded.
      google.setOnLoadCallback(drawTables);
      
      // Callback that creates and populates a data table, 
      // instantiates the pie chart, passes in the data and
      // draws it.
      function drawTables() {

      // Create the data tables.

      var data = new google.visualization.DataTable();

      var chart = new google.visualization.Table(document.getElementById('chart_best'));
      data.addColumn('string', 'lang');
      data.addColumn('number', 'LAS (%, gold)');
      data.addColumn('number', 'best beam (gold)');
      data.addColumn('number', 'best iter (gold)');
      data.addColumn('number', 'LAS (%, pred)');
      data.addColumn('number', 'best beam (pred)');
      data.addColumn('number', 'best iter (pred)');
      data.addColumn('number', '#sent (train)');
      data.addColumn('number', '#sent (dev)');

      data.addColumn('number', 'LAS (%, gold, old)');
      data.addColumn('string', 'dir (gold, old)');
      data.addColumn('number', 'best beam (gold, old)');
      data.addColumn('number', 'best iter (gold, old)');
      data.addColumn('number', 'LAS (%, pred, old)');
      data.addColumn('string', 'dir (pred, old)');
      data.addColumn('number', 'best beam (pred, old)');
      data.addColumn('number', 'best iter (pred, old)');


[% FOREACH l IN best.keys %]
     data.addRow([ '[%- info.$l.lang %]', 
                    [% best.$l.gold.max || 'null' %], 
		    [% best.$l.gold.beam || 'null' %], 
		    [% best.$l.gold.maxiter || 'null' %], 
		    [% best.$l.pred.max || 'null' %],
		    [% best.$l.pred.beam || 'null' %],
		    [% best.$l.pred.maxiter || 'null' %], 
		    [% info.$l.train %],
		    [% info.$l.dev %],

                    [% oldres.$l.gold.max || 'null' %], 
		    '[% oldres.$l.gold.dir %]', 
		    [% oldres.$l.gold.beam || 'null' %], 
		    [% oldres.$l.gold.iter || 'null' %], 
		    [% oldres.$l.pred.max || 'null' %],
		    '[% oldres.$l.pred.dir %]', 
		    [% oldres.$l.pred.beam || 'null' %],
		    [% oldres.$l.pred.iter || 'null' %]

		 ]);
[% END %]
    var formatter = new google.visualization.ColorFormat();
//    formatter.addGradientRange(70,95,'white','#C5DEEA','#8ABBD7');
    formatter.addGradientRange(80,95,'white','#7BB77E','#37B73D');
    formatter.addGradientRange(70,80,'white','#F48404','#F2D9AE');
    formatter.format(data,1);
    formatter.format(data,4);
    formatter.format(data,9);
    formatter.format(data,13);

    var formatter = new google.visualization.NumberFormat({fractionDigits: 2});
    formatter.format(data,1);
    formatter.format(data,4);
    formatter.format(data,9);
    formatter.format(data,13);

    chart.draw(data, {width: '70em',  allowHtml: true});

[% FOREACH b IN beams.keys.nsort %]
      var data = new google.visualization.DataTable();

      var chart = new google.visualization.Table(document.getElementById('chart_beam_[%- b %]'));
      data.addColumn('string', 'lang');
      data.addColumn('number', 'LAS (%,gold)');
      data.addColumn('number', 'best iter (gold)');
      data.addColumn('number', '#iters (gold)');
      data.addColumn('number', 'LAS (%,pred)');
      data.addColumn('number', 'best iter (pred)');
      data.addColumn('number', '#iters (pred)');
      data.addColumn('number', '#sent (train)');
      data.addColumn('number', '#sent (dev)');
      data.addColumn('string', 'host (gold)');
      data.addColumn('string', 'host (pred)');
      data.addColumn('string', 'last entry (gold)');
      data.addColumn('string', 'last entry (pred)');

[% FOREACH l IN beams.$b.keys %]
     data.addRow([ '[%- info.$l.lang %]', 
                    [% beams.$b.$l.gold.max || 'null' %], 
		    [% beams.$b.$l.gold.maxiter || 'null' %], 
		    [% beams.$b.$l.gold.iter.size || 'null' %], 
		    [% beams.$b.$l.pred.max || 'null' %],
		    [% beams.$b.$l.pred.maxiter || 'null' %],
		    [% beams.$b.$l.pred.iter.size || 'null' %],
		    [% info.$l.train %],
		    [% info.$l.dev %],
                    '[%- hosts.$l.gold.$b -%]',
                    '[%- hosts.$l.pred.$b -%]',
                    '<span title="[% beams.$b.$l.gold.dir %]">[% beams.$b.$l.gold.timestamp %]</span>', 
                    '<span title="[% beams.$b.$l.pred.dir %]">[% beams.$b.$l.pred.timestamp %]</span>'
		 ]);
[% END %]
    var formatter = new google.visualization.ColorFormat();
//    formatter.addGradientRange(80,95,'white','#C5DEEA','#8ABBD7');
    formatter.addGradientRange(80,95,'white','#7BB77E','#37B73D');
    formatter.addGradientRange(70,80,'white','#F48404','#F2D9AE');
    formatter.format(data,1);
    formatter.format(data,4);

    var formatter = new google.visualization.NumberFormat({fractionDigits: 2});
    formatter.format(data,1);
    formatter.format(data,4);

      chart.draw(data, {width: '60em', allowHtml: true});
[% END %]

[% FOREACH l IN langs.keys.sort %]
      var data = new google.visualization.DataTable();

      var chart = new google.visualization.LineChart(document.getElementById('chart_lang_[%- l %]'));
      data.addColumn('string', 'beam');
      data.addColumn('number', 'LAS (gold)');
      data.addColumn('number', 'LAS (pred)');
[% FOREACH b IN langs.$l.keys.nsort %]
     data.addRow([ '[% b %]', [% langs.$l.$b.gold.max || 'null' %], [% langs.$l.$b.pred.max || 'null' %] ]);
[% END %]
      chart.draw(data, {width: 1200});
[% END %]

[% FOREACH l IN langs.keys.sort %]
      var data = new google.visualization.DataTable();

      var chart = new google.visualization.LineChart(document.getElementById('chart_iter_[%- l %]'));
      data.addColumn('string', 'iter');
[% FOREACH b IN langs.$l.keys.nsort %]
      data.addColumn('number', 'gold [% b %]');
      data.addColumn('number', 'pred [% b %]');
[% END %]
[% FOREACH i IN iters %]
      data.addRow([ '[%- i -%]'
 [%- FOREACH b IN langs.$l.keys.nsort %]
      , [% langs.$l.$b.gold.iter.$i || 'null' %], [% langs.$l.$b.pred.iter.$i || 'null' %] 
 [%- END %]
                 ]);
[% END %]
      chart.draw(data, {width: 1200});
[% END %]


    }


 </script>
  </head>

  <body>
    <h1>SPMRL 2013 Shared Task: Dependency Track (Gold Tokenisation)</h1> 
	<i> ([% date.format(date.now, "%y/%m/%d %H:%M:%S") %], dyalog-sr)</i> <br>

    <div id="tabs">
      <ul>
        <li><a href="#tabs-1">by languages</a></li>
        <li><a href="#tabs-2">by beam size</a></li>
        <li><a href="#tabs-3">by iteration</a></li>
        <li><a href="#tabs-4">synthesis</a></li>
      </ul>

      <div id="tabs-1">
      <ul>
[% FOREACH b IN beams.keys.nsort %]
           <li><a href="#tabs-1-[%- b %]">beam [%- b %]</a></li>
[% END %]
      </ul>
[% FOREACH b IN beams.keys.sort %]
    <div id="tabs-1-[%- b %]">
    <div id="chart_beam_[%- b %]"></div>
    </div>
[% END %]
     </div>

    <div id="tabs-2">
      <ul>
[% FOREACH l IN langs.keys.sort %]
           <li><a href="#tabs-2-[%- l %]">[%- info.$l.lang %]</a></li>
[% END %]
      </ul>

[% FOREACH l IN langs.keys %]
    <div id="tabs-2-[%- l %]">
    <div id="chart_lang_[%- l %]"></div>
    </div>
[% END %]
    </div>


    <div id="tabs-3">
      <ul>
[% FOREACH l IN langs.keys.sort %]
           <li><a href="#tabs-3-[%- l %]">[%- info.$l.lang %]</a></li>
[% END %]
      </ul>
[% FOREACH l IN langs.keys %]
    <div id="tabs-3-[%- l %]">
    <div id="chart_iter_[%- l %]"></div>
    </div>
[% END %]
    </div>

    <div id="tabs-4">
       <div id="chart_best"></div>
    </div>

   </div>

  </body>

<html>


