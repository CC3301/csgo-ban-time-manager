#!/usr/bin/perl
#!C:\Strawberry\perl\bin\perl.exe

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Cwd;

# make the database handle, for now sqlite3
my $dbfile = getcwd() . "/../../../data/database.db";
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
    . CGI::Link({-rel => 'stylesheet', -type => 'text/css', -href => '../../../css/list_vb_table.css'})
    . CGI::Link({-rel => 'stylesheet', -type => 'text/css', -href => '../../../css/vb_detail_table.css'}
  ),
});

# print the navbar
print "<div class=\"navbar\">
    <a href=\"../../../index.cgi\">Start</a>
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
          <a href=\"../../../sites/vac/scripts/list-suspects.cgi\">List suspects</a>
        </div>
      </div>
  </div>
  <div class=\"main\">";

# list all steam ids
if(!$query->param()) {

  # read database, and store into table
  my $exec = qq(SELECT steam_id64 FROM vacs;);
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
  print "<center><h1>List of all steam id's and data of suspects (total: $counter)</h1></center>";
  print $query->br();

  # print the table
  print $query->start_table(
    {-id => "suspectlist" }
  );
    # table head
    print $query->start_Tr();
      print $query->start_th();
        print "STEAM 64 ID";
      print $query->end_th();
      print $query->start_th();
        print "STEAM PROFILENAME";
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
          $exec = "SELECT steam_username FROM vacs WHERE steam_id64 = '$steam_id64';";
          $exec = $dbh->prepare($exec);
          $exec->execute();

          while(my @row = $exec->fetchrow_array()){
            print join(", ", @row);
          }
        print $query->end_td();
        print $query->start_td();
          print "<form action=\"list-suspects.cgi\" method=\"post\" id=\"form$steam_id64.1\"><input type=\"hidden\" value=\"$steam_id64\" name=\"steam_id64\"/></form><form action=\"add-suspect.cgi\" method=\"post\" id=\"form$steam_id64.2\"><input type=\"hidden\" value=\"$steam_id64\" name=\"steam_id64\"/></form><button type=\"submit\" form=\"form$steam_id64.1\" value=\"submit\">Details</button><button type=\"submit\" form=\"form$steam_id64.2\" value=\"submit\">Refresh data</button>";
        print $query->end_td();
      print $query->end_Tr();
    }
  
  # end the table
  print $query->end_table();

} else {
  my $steam_id64 = $query->param('steam_id64');
  my $exec = "SELECT * FROM vacs WHERE steam_id64 = $steam_id64;";
  $exec = $dbh->prepare($exec);
  $exec->execute();

  my @data;
  while (my @row = $exec->fetchrow_array) {
    push @data, @row;
  }

  print "<center><h1>Detailed view for user: $data[1]</h1></center>";
  print $query->br();

  # detail table
  print $query->start_table(
    { -id => "suspectdetail" },
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
        print "VAC ban";
      print $query->end_th();
      print $query->start_th();
        print "Game ban";
      print $query->end_th();
      print $query->start_th();
        print "Trade Ban";
      print $query->end_th();
      print $query->start_th();
        print "Community Ban";
      print $query->end_th();
      print $query->start_th();
        print "Last modified";
      print $query->end_th();
      print $query->start_th();
        print "Avatar";
      print $query->end_th();
    print $query->end_Tr();

    # table data
    print $query->start_Tr();
      print $query->start_td();
        print $data[1];
      print $query->end_td();
      print $query->start_td();
        print "<a target=\"_blank\" href=\"http://steamcommunity.com/profiles/$data[0]\">Profile ($data[7])</a>";
      print $query->end_td();
      print $query->start_td();
        print $data[0];
      print $query->end_td();
      print $query->start_td();
        if ($data[2]){
          print "<font color=\"red\">&#10008</font>($data[2])";
        } else {
          print "<font color=\"green\">&#10004</font>";
        }
      print $query->end_td();
      print $query->start_td();
        if ($data[3]){
          print "<font color=\"red\">&#10008</font>($data[3])";
        } else {
          print "<font color=\"green\">&#10004</font>";
        }
      print $query->end_td();
      print $query->start_td();
        if ($data[4]){
          print "<font color=\"red\">&#10008</font>($data[4])";
        } else {
          print "<font color=\"green\">&#10004</font>";
        }
      print $query->end_td();
      print $query->start_td();
        if ($data[5]){
          print "<font color=\"red\">&#10008</font>($data[5])";
        } else {
          print "<font color=\"green\">&#10004</font>";
        }
      print $query->end_td();
      print $query->start_td();
        print $data[8];
      print $query->end_td();
      print $query->start_td();
        print "<img src=\"$data[6]\" alt=\"avatar_img\" align=\"middle\">";
      print $query->end_td();
    print $query->end_Tr();

}

# end html
print "</div>";
print $query->end_html();
