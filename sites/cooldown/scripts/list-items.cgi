#!C:\Strawberry\perl\bin\perl.exe

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
    . CGI::Link({-rel => 'stylesheet', -type => 'text/css', -href => '../../../css/list_cd_table.css'})
    . CGI::Link({-rel => 'stylesheet', -type => 'text/css', -href => '../../../css/cd_detail_table.css'}
  ),
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

  # read database, and store into table
  my $exec = qq(SELECT steam_id64 FROM cooldowns;);
  $exec = $dbh->prepare($exec);
  $exec->execute();

  # get the row data
  my @ids;
  my $counter = 0;
  while (my @row = $exec->fetchrow_array){
    push @ids, join(", ", @row);
    $counter++;
  }

  # headline
  print "<center><h1>List of all steam id's and data for cooldown (total: $counter)</h1></center>";
  print $query->br();

  # print the table
  print $query->start_table(
    {-id => "victimlist" }
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
  my $exec = "SELECT * FROM cooldowns WHERE steam_id64 = $steam_id64;";
  $exec = $dbh->prepare($exec);
  $exec->execute();

  my @data;
  while (my @row = $exec->fetchrow_array) {
    push @data, @row;
  }

  print "<center><h1>Detailed view for user: $data[0]</h1></center>";
  print $query->br();

  # detail table
  print $query->start_table(
    { -id => "victimdetail" },
  );

    # table head
    print $query->start_Tr();
      print $query->start_th();
        print "Profile Name";
      print $query->end_th();
      print $query->start_th();
        print "Profile Permalink";
      print $query->end_th();
      print $query->start_th();
        print "Steam 64 ID";
      print $query->end_th();
      print $query->start_th();
        print "Cooldown Time";
      print $query->end_th();
      print $query->start_th();
        print "Cooldown Reason";
      print $query->end_th();
      print $query->start_th();
        print "Avatar";
      print $query->end_th();
    print $query->end_Tr();

    # table data
    print $query->start_Tr();
      print $query->start_td();
        print $data[0];
      print $query->end_td();
      print $query->start_td();
        print "<a target=\"_blank\" href=\"http://steamcommunity.com/profiles/$data[1]\">Profile ($data[5])</a>";
      print $query->end_td();
      print $query->start_td();
        print $data[1];
      print $query->end_td();
      print $query->start_td();
        print int ($data[3]) . " Minutes</br>";
        print int ($data[3] / 60) . " Hour(s)</br>";
        print int ($data[3] / 60 / 24) . " Day(s)</br>";
        print int ($data[3] / 60 / 24 / 7) . " Week(s)</br>";
      print $query->end_td();
      print $query->start_td();
        print $data[4];
      print $query->end_td();
      print $query->start_td();
        print "<img src=\"$data[2]\" alt=\"avatar_img\" align=\"middle\">";
      print $query->end_td();
    print $query->end_Tr();

}

# end html
print "</div>";
print $query->end_html();