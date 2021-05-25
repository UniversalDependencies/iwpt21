#!/usr/bin/env perl

## build HTML stat file from official SPMRL results files provided by Djamé
## cat Results.last.all.full.csv | ./spmrl2statsres.pl

use strict;
use AppConfig qw/:argcount :expand/;
use Text::Table;
use List::Util qw/min max/;
use Template;
use Data::Dumper;
my $config = AppConfig->new(
                            "verbose!" => {DEFAULT => 1},
                            "html=f" => {DEFAULT => "$ARGV[0]spmrl_results.html"},
			    );

my $TEXTINFO=$ARGV[1];
 
$config->args();

my $html = $config->html;

my %lang = ();

#$lang{"TEXT"}=$TEXTINFO;
my $mode1;
my $mode2;
my $lang;

my $best = {};

while (<STDIN>) {
  my $line = $_;
  /Evaluating\s+(\S+)$/ and $lang = ucfirst(lc($1));
  /evaluating\s+(gold|pred)\s+files/ and $mode1 = $1;
  /\((full|5k)\)/ and $mode2 = $1;
  chomp $line;
  
  #$line =~ s/^LAS:\s+(\S+)\s+\%\s+UAS:\s+(\S+)\s+\%\s+LaS:\s+(\S+)\s+\%\s+//o or next;
  if ($line !~/:/){next;}
  $line=~s/\%//g;
  $line=~s/ //g;
  my %hline = map { split(/:/, $_) } split(/\t+/, $line);
  $line=$hline{file};
#print Dumper(\%hline);die "here";
  

  my ($team) = ($hline{file} =~ m{\.//*(\S+?)/});
  #die "team : $team";
  $team =~ s/_SUBMISSION_(CONLL|PTB)//o;
  $team eq 'BILBAO_TEAM' and $team = 'BASQUE_TEAM';
  $hline{team} = $team;
  print "Process $lang $team $hline{ACC}\n";
  my ($run) = ($hline{file} =~ /\.(run\d+)$/) ? $1 : 'run1';
  $hline{run} = $run;
  push(@{$lang{$lang}{$mode1}{$mode2}}, \%hline);
  my $entry = $best->{$team}{$mode1}{$mode2}{$lang} ||= {};
  my $ACC = $hline{ACC};
#  print "ACC = $ACC"; die "here";
  (!$entry->{ACC} || $entry->{ACC} < $ACC) and $entry->{ACC} = $ACC;
}
    
my $avg = {};
my $lavg = {};

foreach my $team (keys %$best) {
  foreach my $m1 (qw{gold pred}) {
    foreach my $m2 (qw{full 5k}) {
      foreach my $lang (keys %{$best->{$team}{$m1}{$m2}}) {
	$avg->{$team}{$m1}{$m2}{ACC} += $best->{$team}{$m1}{$m2}{$lang}{ACC};
	$avg->{$team}{$m1}{$m2}{n} ++;
	$lavg->{$lang}{$m1}{$m2}{ACC} += $best->{$team}{$m1}{$m2}{$lang}{ACC};
        $lavg->{$lang}{$m1}{$m2}{n} ++;
      }
    }
  }
}

foreach my $team (keys %$avg) {
  foreach my $m1 (keys %{$avg->{$team}}){
    foreach my $m2  (keys %{$avg->{$team}{$m1}}) {
      $lavg->{soft_avg}{$m1}{$m2}{ACC} += $avg->{$team}{$m1}{$m2}{soft_ACC} = $avg->{$team}{$m1}{$m2}{ACC} / ($avg->{$team}{$m1}{$m2}{n} || 1);
      $lavg->{soft_avg}{$m1}{$m2}{n}++;
      $avg->{$team}{$m1}{$m2}{ACC} /= 9;
    }
  }
}

foreach my $l (keys %$lavg) {
  foreach my $m1 (keys %{$lavg->{$l}}) {
    foreach my $m2 (keys %{$lavg->{$l}{$m1}}) {
      $lavg->{$l}{$m1}{$m2}{ACC} /= ($lavg->{$l}{$m1}{$m2}{n} || 1);
    }
  }
}

my $tt=Template->new({});

$tt->process(\*DATA,
	     {
	      langs => \%lang,
	      mode1 => [qw{pred gold}],
	      mode2 => [qw{full 5k}],
	      best => $best,
	      avg => $avg,
	      lavg => $lavg,
	      text => $TEXTINFO
	     },
	     $html
	    )
  or die "can't process template: $!";


  #print Dumper(\%lang); die"hiere";

__END__
[%- USE date -%]
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="fr">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>SPMRL charts: [%- text %]</title>
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
      $(function() {
         $( "#tabs" ).tabs();
[% FOREACH l IN langs.keys.sort %]
         $( "#tabs-[%- l %]" ).tabs();
[% END %]
         $( "#tabs-synthesis" ).tabs();
      });
-->
  </script>
    <!--Load the AJAX API-->
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
    
      // Load the Visualization API and the piechart package.
      google.load('visualization', '1', {'packages':['coEX_genhart','table']});
      
      // Set a callback to run when the Google Visualization API is loaded.
      google.setOnLoadCallback(drawTables);
      
      // Callback that creates and populates a data table, 
      // instantiates the pie chart, passes in the data and
      // draws it.
      function drawTables() {

      // Create the data tables.

[% FOREACH l IN langs.keys.sort %]
[% FOREACH m1 IN mode1 %]
[% FOREACH m2 IN mode2 %]
      var data = new google.visualization.DataTable();

      var chart = new google.visualization.Table(document.getElementById('chart_lang_[%- l %]_[%- m1 %]_[%- m2 %]'));
      data.addColumn('string', 'team');
      data.addColumn('number', 'ACC (%)');
      data.addColumn('number', 'P (%)');
      data.addColumn('number', 'R (%)');
      data.addColumn('number', 'Norm (%)');
      data.addColumn('number', 'Ex (%)');
      data.addColumn('number', '#unparsed');
      data.addColumn('string', 'run');

[% FOREACH t IN langs.$l.$m1.$m2 %]
     data.addRow([ '[%- t.team %]', 
                    [% t.ACC || 'null' %], 
		    [% t.EX_gold || 'null' %], 
		    [% t.Ex_gen || 'null' %], 
		    [% t.Norm || 'null' %], 
//		    [% t.EX || 'null' %], 
//		    [% t.Unparsed || 'null' %], 
                    '<span title="[% t.file %]">[%  t.run %]</span>'
		 ]);
[% END %]
  var formatter = new google.visualization.ColorFormat();
    formatter.addGradientRange(85,100,'white','#7BB77E','#37B73D');
    formatter.addGradientRange(70,85,'white','#F48404','#F2D9AE');
    formatter.format(data,1);
    formatter.format(data,2);
    formatter.format(data,3);

    var formatter = new google.visualization.NumberFormat({fractionDigits: 2});
    formatter.format(data,1);
    formatter.format(data,2);
    formatter.format(data,3);

    chart.draw(data, {width: '60em', allowHtml: true});

    var synthesis = google.visualization.data.group(
						 data,
						 [0],
       [{'column': 1, 'aggregation': google.visualization.data.max, 'type': 'number'},
        {'column': 2, 'aggregation': google.visualization.data.max, 'type': 'number'},
        {'column': 3, 'aggregation': google.visualization.data.max, 'type': 'number'}
       ]
    );
    var chart = new google.visualization.ColumnChart(document.getElementById('chart_bar_lang_[%- l %]_[%- m1 %]_[%- m2 %]'));
    chart.draw(synthesis, {width: 1200});
[% END %]
[% END %]
[% END %]

// here display, synthesis per page

  [% FOREACH m1 IN mode1 %]
  [% FOREACH m2 IN mode2 %]
      var data = new google.visualization.DataTable();

      data.addColumn('string', 'team');
[% FOREACH l IN langs.keys.sort %]
      data.addColumn('number', 'ACC (%, [%- l %])');
[% END %]
      data.addColumn('number', 'ACC (%, avg)');
//      data.addColumn('number', 'LAS (%, avg2)');

[% FOREACH t IN best.keys.sort %]
      data.addRow([ '[% t %]'
   [% FOREACH l IN langs.keys.sort %]
             , [% best.$t.$m1.$m2.$l.ACC || 'null' %]
   [% END %]
             , [% avg.$t.$m1.$m2.ACC || 0 %]
//             , [% avg.$t.$m1.$m2.ACC2 || 0 %]
                  ]);
[% END %]

  var formatter = new google.visualization.ColorFormat();
    formatter.addGradientRange(85,100,'white','#7BB77E','#37B73D');
    formatter.addGradientRange(70,85,'white','#F48404','#F2D9AE');
    formatter.format(data,1);
    formatter.format(data,2);
    formatter.format(data,3);
    formatter.format(data,4);
    formatter.format(data,5);
    formatter.format(data,6);
    formatter.format(data,7);
    formatter.format(data,8);
    formatter.format(data,9);
    formatter.format(data,10);
//    formatter.format(data,11);


    var formatter = new google.visualization.NumberFormat({fractionDigits: 2});
    formatter.format(data,1);
    formatter.format(data,2);
    formatter.format(data,3);
    formatter.format(data,4);
    formatter.format(data,5);
    formatter.format(data,6);
    formatter.format(data,7);
    formatter.format(data,8);
    formatter.format(data,9);
    formatter.format(data,10);
//    formatter.format(data,11);

  var chart = new google.visualization.Table(document.getElementById('chart_synthesis_[%- m1 %]_[%- m2 %]'));
  chart.draw(data, {width: '60em', allowHtml: true});

  // BEGIN INSERT DJAME
  chart.draw(data, {width: '70em', allowHtml: true});

   var data = new google.visualization.DataTable();
   data.addColumn('string', 'language');
   data.addColumn('number', 'mean as baseline');
[% FOREACH t IN best.keys.sort %]
   data.addColumn('number', '[%- t %]');
[% END %]

[% FOREACH l IN langs.keys.sort %]
   data.addRow([ '[% l %]'
               , [% lavg.$l.$m1.$m2.ACC || 'null' %]
   [% FOREACH t IN best.keys.sort %]
               , [% best.$t.$m1.$m2.$l.ACC || 'null' %]
   [% END %]
               ]);
[% END %]

   data.addRow([ 'soft_avg'
		 , [% lavg.soft_avg.$m1.$m2.ACC || 'null' %]
   [% FOREACH t IN best.keys.sort %]
                , [% avg.$t.$m1.$m2.ACC || 'null' %]
   [% END %]
               ]);
  
	// Ok, until here synthesis first table are corEX_gent 
			     
  
    var chart = new google.visualization.LineChart(document.getElementById('chart_synthesis_scatter_[%- m1 %]_[%- m2 %]'));
    chart.draw(data, {width: 1200, pointSize: 10, lineWidth: 0, height: 800, vAxis: { title: 'ACC (%)', gridlines: { count: -1}, minorGridlines: {count: 1}}, hAxis: {title: 'languages'}, series: {0: {lineWidth: 2, pointSize: 0, visibleInLegend: false }}});
  
  // END INSERT DJAME

  //[% END %]
  //[% END %]

    }


 </script>
  </head>

  <body>
    <h1> SPMRL Results charts (Parseval): Const. Parsing Track (gold tokens, [%- text %]) </h1>
	 <i> ([% date.format(date.now, "%y/%m/%d %H:%M:%S") %]</i><br>

    <div id="tabs">
      <ul>
[% FOREACH l IN langs.keys.sort %]
        <li><a href="#tabs-[%- l %]">[% l %]</a></li>
[% END %]
        <li><a href="#tabs-synthesis">Synthesis</a></li>
      </ul>

[% FOREACH l IN langs.keys.sort %]
      <div id="tabs-[%- l %]">
        <ul>
		[% FOREACH m1 IN mode1 %]
			[% FOREACH m2 IN mode2 %]
				<li><a href="#tabs-[%- l %]-[%- m1 %]-[%- m2 %]">[%- m1 %]/[%- m2 %]</a></li>
			[% END %]
		[% END %]
        </ul>
[% FOREACH m1 IN mode1 %]
  [% FOREACH m2 IN mode2 %]
        <div id="tabs-[%- l %]-[%- m1 %]-[%- m2 %]">
             <div id="chart_lang_[%- l %]_[%- m1 %]_[%- m2 %]"> </div>
             <div id="chart_bar_lang_[%- l %]_[%- m1 %]_[%- m2 %]"> </div>
        </div>
  [% END %]
[% END %]
   </div>
[% END %]
        
     <div id="tabs-synthesis">
        <ul>
[% FOREACH m1 IN mode1 %]
  [% FOREACH m2 IN mode2 %]
          <li><a href="#tabs-synthesis-[%- m1 %]-[%- m2 %]">[%- m1 %]/[%- m2 %]</a></li>
  [% END %]
[% END %]
       </ul>
[% FOREACH m1 IN mode1 %]
  [% FOREACH m2 IN mode2 %]
        <div id="tabs-synthesis-[%- m1 %]-[%- m2 %]">
             <div id="chart_synthesis_[%- m1 %]_[%- m2 %]">
             </div>
             <div id="chart_synthesis_scatter_[%- m1 %]_[%- m2 %]">
             </div>
        </div>
  [% END %]
[% END %]

     </div>

   </div>

  </body>

<html>

