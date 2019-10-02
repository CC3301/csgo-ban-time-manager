#!perl

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

# make the database handle, for now sqlite3
my $dbfile = "../../../data/cooldowns.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

# make the html part
my $query = new CGI;
print $query->header();

# get the title
my $title = "default";
if (!$query->param('steam_id64')) {
  $title = "List of all cooldown victims";
} else {
  $title = $query->param('steam_id64');
}

# print the start of the html and add the stylesheets
print $query->start_html({
  -title => $title,
  -head => CGI::Link({-rel => 'stylesheet', -type => 'text/css', -href => '../../../css/main.css'})
    . CGI::Link({-rel => 'stylesheet', -type => 'text/css', -href => '../../../css/list_cd_table.css'}),
});

# print the navbar
print "<div class=\"navbar\">
    <a href=\"../../../index.html\">Start</a>
    <div class=\"dropdown\">
      <button class=\"dropbtn\">Cooldown
        <i class=\"fa fa-caret-down\">
      </button>
      <div class=\"dropdown-content\">
        <a href=\"../../../sites/cooldown/add.html\">Add victims</a>
        <a href=\"../../../sites/cooldown/scripts/list-items.cgi\">List victims</a>
      </div>
    </div>
    <div class=\"dropdown\">
        <button class=\"dropbtn\">VAC
          <i class=\"fa fa-caret-down\">
        </button>
        <div class=\"dropdown-content\">
          <a href=\"../../../sites/vac/add.html\">Add suspects</a>
          <a href=\"../../../sites/vac/list.html\">List suspects</a>
        </div>
      </div>
  </div>
  <div class=\"main\">";

# list all steam ids
if(!$query->param()) {

  # headline
  print "<center><h1>List of all steam id's and data for cooldown</h1></center>";
  print $query->br();

  # read database, and store into table
  my $exec = qq(SELECT steam_id64 FROM cooldowns;);
  $exec = $dbh->prepare($exec);
  $exec->execute();

  # get the row data
  my @ids;
  while (my @row = $exec->fetchrow_array){
    push @ids, join(", ", @row);
  }

  # print the table
  print $query->start_table(
    { -width => 400, -id => "victimlist" }
  );
    # table head
    print $query->start_Tr();
      print $query->start_th();
        print "STEAM 64 ID";
      print $query->end_th();
      print $query->start_th();
        print "Details";
      print $query->end_th();
    print $query->end_Tr();

    # make a new line for every steam id
    foreach my $steam_id64 (@ids) {
      print $query->start_Tr();
        print $query->start_td();
          print $steam_id64;
        print $query->end_td();
        print $query->start_td();
          print "<a href=\"list-items.cgi?steam_id64=$steam_id64\">Details</a>";
        print $query->end_td();
      print $query->end_Tr();
    }
  
  # end the table
  print $query->end_table();

} else {
  my $steam_id64 = $query->param('steam_id64');
  print "STEAD 64 ID: $steam_id64\n";
}

# end html
print "</div>";
print $query->end_html();