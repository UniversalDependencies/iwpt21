#!/usr/bin/perl

# script that generates fancy html results table
# Adapted from Eric de la Clergerie's own visualisation scripts
# Djamé Seddah
# Licence: GPL-2

use strict;
use warnings;


use HTML::TableExtract;
use Data::Dumper;
use Carp qw<longmess>; # to get call stack

# stuff for the app
use AppConfig qw/:argcount :expand/;
use Text::Table;
use List::Util qw/min max/;
use Template;



#######################################

my @header_coarse=qw(Language	Tokens	Words	Sentences	UPOS	XPOS	UFeats	AllTags	Lemmas	UAS	LAS	CLAS	MLAS	BLEX	EULAS	ELAS);
my @header_fine=qw(Treebank	Tokens	Words	Sentences	UPOS	XPOS	UFeats	AllTags	Lemmas	UAS	LAS	CLAS	MLAS	BLEX	EULAS	ELAS	Enhancements	LAvgELAS	cf.);

my %results=();
my @fake_types=();
my $do_coarse=0;
if ($ARGV[0] eq "coarse"){
	$do_coarse=1;
		@fake_types=("coarse");	
}else{
	$do_coarse=0;
	@fake_types=("fine");	
}

my $workdir="";
my $infix="";
if (defined $ARGV[1]){
	$workdir=$ARGV[1];
	print STDERR "Workdir = $workdir\n";
	$workdir="$workdir/*.html";
	$infix="unofficial";
}else{
	print STDERR "Workdir = $workdir\n";
	$workdir="../results/*.html";
	$infix="official";
}

my $outfile="$ARGV[0]_IWPT_SharedTask_".$infix."_results.html";
my $config = AppConfig->new(
                            "verbose!" => {DEFAULT => 1},
                            "html=f" => {DEFAULT => $outfile},
			    );




# reading the whole results and building that giant table
while(glob $workdir){  # get all results
	chomp;
	my $line=$_;
	# read the file
	
	my $html_string=&read_whole_file($line);
	# extract team
	$line=~/\/(.+?).html/;
	my $team=$1;
	if ($team=~/bsala/i){
		$team=~s/_\d+//g;
	}
	print "processing $line\t$team\n";
#	 print STDERR "reading coarse\n";
	 
	 my $table_coarse="";
	 my $table_fine="";
	 if ($do_coarse==1){
		 $table_coarse = HTML::TableExtract->new(headers => [qw(Language	Tokens	Words	Sentences	UPOS	XPOS	UFeats	AllTags	Lemmas	UAS	LAS	CLAS	MLAS	BLEX	EULAS	ELAS)]);
	 	$table_coarse->parse($html_string); 
		$results{$team}{"coarse"}=&get_hash_from_one_table($table_coarse->tables,\@header_coarse);
			
	 }else{
	 	$table_fine=HTML::TableExtract->new(headers => [qw(Treebank	Tokens	Words	Sentences	UPOS	XPOS	UFeats	AllTags	Lemmas	UAS	LAS	CLAS	MLAS	BLEX	EULAS	ELAS	Enhancements	LAvgELAS	cf.)]);
		$table_fine->parse($html_string); 
		$results{$team}{"fine"}=&get_hash_from_one_table($table_fine->tables,\@header_fine);		
		
	 }

	#&print_table($table_coarse->tables);
#	print STDERR "reading fine\n";

	#&print_table($table_fine->tables);

}


my %langH=&get_hash_per_language(\%results);
#print STDERR Dumper(\%langH);

foreach my $el (sort keys %langH){
	print $el."\t";
	print join("\t",sort keys %{ $langH{$el} })."\n";
	
}

# weirdest bug ever !! if the following lines are uncommented, that crap doesn't work anymore

#$fake_types[0]=ucfirst $fake_types[0];
#$infix=ucfirst $infix;



# init template APPS
my $TEXTINFO=$ARGV[1];
$config->args();

my $html = $config->html;



my $tt=Template->new; #({});
exit;


$tt->process(\*DATA,
	     {
	      langs => \%langH,
		  Mresults => \%results,
	      type => \@fake_types,
		  mytype => $fake_types[0],
		  metrics => [qw{LAS EULAS ELAS}],
		  myinfix => $infix,
#	      mode2 => [qw{full 5k}],
	      text => $TEXTINFO
	     },
	     $html
	    )
  or die "can't process template: $!";


  print "Results output in $outfile\n";


sub get_hash_per_language{
	my $ptr_results=shift;
	my %results=%{$ptr_results};
	my %LangH=();
	foreach my $team (keys %results){
		foreach my $type (keys %{ $results{$team} }){
			foreach my $lang (sort keys %{ $results{$team}{$type}}){
				#if ($lang=~/sequoia|avg|French|English/i){
					print "$team\t$type\t$lang\n";
					$LangH{$lang}{$type}{$team}=$results{$team}{$type}{$lang};
					#}
			}
		}
#	last;	
	}

	return wantarray ? %LangH : \%LangH;
}
sub print_table{
	my $ptr_table=shift;
	foreach my $ts ($ptr_table) {
  		print "Table (", join(',', $ts->coords), "):\n";
		foreach my $row ($ts->rows) {
     		print join("\t", @$row), "\n";
  		}
  	}	

}
sub get_hash_from_one_table{
	my $ptr_table=shift;
	my $ptr_header_list=shift;
	my %team=();
	# beware,there's only one table
	foreach my $ts ($ptr_table) {
		foreach my $row ($ts->rows) {
			 my %buf=&parse_one_line_to_hash($row,$ptr_header_list);
     		 @team{keys %buf}=values %buf;
  		}
	}
#	print Dumper(\%team);
	return wantarray ? %team : \%team;
}
sub parse_one_line_to_hash {
#	print STDERR "@_\n";
	my $ptr_row=shift;
	my $ptr_header_list=shift	;
	my @row=@$ptr_row;
#	print Dumper($ptr_header_list);
#	my $mess = longmess();
#    print Dumper( $mess );
	my @headers=@{$ptr_header_list};
	my %line=();
	my $lang=shift @row;
	$lang=~s/Average/[Avg.]/;
	my $i=1;
	my %buf=map { $headers[$i++] => $_} @row;
	$line{$lang} =\%buf;
#	print Dumper(\%line);	
	return wantarray ? %line : \%line;
}
sub read_whole_file{
	my $filename=shift;
	open FICIN,"<$filename" or die "can't read $filename\n";
	my $html_string="";
	while(<FICIN>){
		$html_string = $html_string . $_;
	}
	close FICIN;
	return $html_string;
}
__END__ 
[%- USE date -%]
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="fr">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>IWPT Shared Task on Parsing into Enhanced Dependencies Results : [%- text %]</title>
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
     
     
		 google.load('visualization', '1', {'packages':['corechart','table']});
	 
	 	 
     // Set a callback to run when the Google Visualization API is loaded.
//     google.charts.setOnLoadCallback(drawTables);
	 	google.setOnLoadCallback(function() {drawTables()});
	 
	 // Callback that creates and populates a data table, 
	  // instantiates the pie chart, passes in the data and
	       // draws it.
		   
	 function drawTables() {
		 
		 [% FOREACH l IN langs.keys.sort %]  //1
		
		 	[% FOREACH m1 IN type %]//2
			
			<!-- starting processing [% l %] - [% m1 %] - -->
			
			
				var data = new google.visualization.DataTable();
			
				var chart = new google.visualization.Table(document.getElementById('chart_lang_[%- l %]_[%- m1 %]'));
			 	//# create columns 
				data.addColumn('string', 'team');
				 
				[% FOREACH metric IN metrics %]
				 	data.addColumn('number','[% metric %] (%)');
				[% END %]
				
				//# add rows
				[% FOREACH t IN langs.$l.$m1.keys.sort %] 
					data.addRow(['[%- t %]', [% FOREACH metric IN metrics %] [% langs.$l.$m1.$t.$metric || 'null' %], [% END %] ]);
				[% END %]	
				
			    var formatter = new google.visualization.ColorFormat();
			      formatter.addGradientRange(70,100,'white','#7BB77E','#37B73D');
			      formatter.addGradientRange(50,70,'white','#F48404','#F2D9AE');
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
	      var chart = new google.visualization.ColumnChart(document.getElementById('chart_bar_lang_[%- l %]_[%- m1 %]'));
	      chart.draw(synthesis, {width: 1200,height: 600});

				 
			[% END %]//2
		 [% END %]//1
		  
		
		 // DEBUG_HERE
 		[% FOREACH m1 IN type %] //3
 		       var data = new google.visualization.DataTable();

 		       data.addColumn('string', 'team / ELAS (%)');
 			   var lang_counter=0;
 			   [% FOREACH l IN langs.keys.sort %]
 		       		data.addColumn('number', '[%- l %]');
 					lang_counter++;
 				[% END %]
 		 //      data.addColumn('number', 'ACC (%, avg)');
 		 //      data.addColumn('number', 'LAS (%, avg2)');
		 
		 
 		//# add rows
 	 		[% FOREACH t IN Mresults.keys.sort %]  //4
 	 			data.addRow(['[%- t %]',
 				[% FOREACH l IN langs.keys.sort %] // the horror, Mresults != lang bc of the debugging
 					[% Mresults.$t.$m1.$l.ELAS || 'null' %],
 				[% END %]
 				]);
				
			[% END %] //4 #foreach t	
				
 		[% END %]	 //3 # foreach m1 #3
		
		 <!-- here end displays synthesis per page -->		 
 	     var formatter = new google.visualization.ColorFormat();
 	       formatter.addGradientRange(85,100,'white','#7BB77E','#37B73D');
 	       formatter.addGradientRange(70,85,'white','#F48404','#F2D9AE');
 		   var i;
 		   for (i = 0; i < lang_counter+1; i++) { // team col + nb of langages
 			   formatter.format(data,i);
 			}   


 	       var formatter = new google.visualization.NumberFormat({fractionDigits: 2});
 		   for (i = 0; i < lang_counter+1; i++) { 
 			   formatter.format(data,i);
 			}   

 	     var chart = new google.visualization.Table(document.getElementById('chart_synthesis_[%- m1 %]'));
 	     chart.draw(data, {width: '600em', allowHtml: true});


		 // printing synthesis graphic
		 
		 
//		 var data = new google.visualization.DataTable();
		 var data = transposeDateDataTable(data)
		




		 var chart = new google.visualization.LineChart(document.getElementById('chart_synthesis_scatter_[%- m1 %]'));
		 chart.draw(data, {width: 1200, pointSize: 10, lineWidth: 0, height: 800, 
		 vAxis: { title: 'ELAS (%)', gridlines: { count: -1}, minorGridlines: {count: 1}}, 
		 hAxis: {title: '', slantedText:true, slantedTextAngle:45 }, series: {0: {lineWidth: 2, pointSize: 0, visibleInLegend: false }}});


		 
	 }// end drawTables
	 
	 
	 
	 function transposeDateDataTable (dataTable) {

	     // Create new datatable

	     var newDataTable = new google.visualization.DataTable ();

	     // Add first column from original datatable

	     newDataTable.addColumn ('string', dataTable.getColumnLabel (0));

	     // Convert column labels to row labels

	     for (var x=1; x < dataTable.getNumberOfColumns (); x++) {
	         var label = dataTable.getColumnLabel (x);
	         newDataTable.addRow ([label]);
	     }

	     // Convert row labels and data to columns

	     for (var x=0; x < dataTable.getNumberOfRows (); x++) {
	         newDataTable.addColumn ('number', dataTable.getValue (x, 0)); // Use first column date as label
	         for (var y=1; y < dataTable.getNumberOfColumns (); y++) {
	             newDataTable.setValue (y-1, x+1, dataTable.getValue (x, y));
	         }
	     }

	     return newDataTable;

	 }// end of transpose
   </script>
    
  </head>

  <body>
    <h1> IWPT EUD  Parsing Results Overview Charts ([%- mytype %] F1 scores - [%- myinfix %])  </h1>
	 <i> ([% date.format(date.now, "%y/%m/%d %H:%M:%S") %])</i><br>

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
  			[% FOREACH m1 IN type %]
  	        	<li><a href="#tabs-[%- l %]-[%- m1 %]">[%- m1 %]</a></li>
  			[% END %]
  	        </ul>
	
  			[% FOREACH m1 IN type %]
  			        <div id="tabs-[%- l %]-[%- m1 %]">
  			             <div id="chart_lang_[%- l %]_[%- m1 %]"></div>
  			             <div id="chart_bar_lang_[%- l %]_[%- m1 %]"></div>
  			        </div>
  			[% END %]
	  		</div> <!-- id="tabs-[%- l %]" -->
    [% END %] <!-- foreach language -->    
	
     
	  


     <div id="tabs-synthesis">
        <ul>
[% FOREACH m1 IN type %]
           <li><a href="#tabs-synthesis-[%- m1 %]">[%- m1 %]</a></li>
[% END %]
       </ul>
  
	   [% FOREACH m1 IN type %]
	           <div id="tabs-synthesis-[%- m1 %]">
	                <div id="chart_synthesis_[%- m1 %]"></div>
	                <div id="chart_synthesis_scatter_[%- m1 %]"></div>
	           </div><!-- div id="tabs-synthesis-[%- m1 %]" -->

	   [% END %]
	  </div> <!-- div id="tabs" -->
    </body>

  <html>
