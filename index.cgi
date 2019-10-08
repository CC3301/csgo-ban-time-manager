#!/usr/bin/perl
#!C:\Strawberry\perl\bin\perl.exe

################################################################################
# Database initialization script
################################################################################

################################################################################
# load modules
################################################################################
use strict;
use warnings;
use DBI;
use Cwd;
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Data::Dumper;

use lib getcwd() . "/data/lib/perl5";
use DbTools;

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# create the cgi 
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
my $cgi = new CGI;

################################################################################
# Main subroutine
################################################################################
sub Main() {

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # var declaration
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $dbfile = getcwd() . "/data/database.db";
  my %statistics_cd = (
    'cooldown_time_total' => 'Total cooldown time issued for all users in hours',
    'cooldown_users_total' => 'Number of unique users on cooldown',
    'cooldown_reason_team_kills_at_round_start' => 'Amount of cooldowns caused by a team kill at round start',
    'cooldown_reason_team_kills' => 'Amount of cooldowns caused by exceeding the team kill limit',
    'cooldown_reason_team_damage' => 'Amount of cooldowns caused by doing too much team damage',
    'cooldown_reason_team_afk_timeout' => 'Amount of cooldowns caused by a disconnect and the AFK-timer running out',
    'cooldown_reason_rage_quit' => 'Amount of cooldowns caused by a player rage-quitting due to provocation',
    'cooldown_type_30' => 'Number of 30-minute cooldowns issued',
    'cooldown_type_120' => 'Number of 2-hour cooldowns issued',
    'cooldown_type_1500' => 'Number of 1-day cooldowns issued',
    'cooldown_type_10500' => 'Number of 7-day cooldowns issued',
  );
  my %statistics_ban = (
    'ban_vac' => 'Number of unique accounts with one or more VAC-bans',
    'ban_game' => 'Number of unique accounts with one ore more game-bans',
    'ban_trade' => 'Number of unique accounts with a trade-ban',
    'ban_community' => 'Number of unique accounts with a community-ban',
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # print cgi stuff
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print $cgi->header();
  print $cgi->start_html({
  -title => "CS:GO - B n' T Manager",
  -head => CGI::Link({-rel => 'stylesheet', -type => 'text/css', -href => 'css/main.css'})
    . CGI::Link({-rel => 'stylesheet', -type => 'text/css', -href => 'css/statistics_table.css'}
  ),
});
  print "
    <div class=\"navbar\">
    <a href=\"#\">Start</a>
    <div class=\"dropdown\">
      <button class=\"dropbtn\">Cooldown
        <i class=\"fa fa-caret-down\">
      </button>
      <div class=\"dropdown-content\">
        <a href=\"sites/cooldown/add.html\">Add victims</a>
        <a href=\"sites/cooldown/scripts/list-items.cgi\">List victims</a>
      </div>
    </div>
    <div class=\"dropdown\">
        <button class=\"dropbtn\">VAC
          <i class=\"fa fa-caret-down\">
        </button>
        <div class=\"dropdown-content\">
          <a href=\"sites/vac/add.html\">Add suspects</a>
          <a href=\"sites/vac/scripts/list-suspects.cgi\">List suspects</a>
        </div>
      </div>
  </div>
  <div class=\"main\">
      <h1>CS:GO ban and troll manager</h1>
  </div>
  ";

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # show some statistics
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  # headline
  print $cgi->br();


  # print the cooldown table
  print $cgi->start_table(
    {-id => "statistics" }
  );

    # table head
    print $cgi->start_Tr();
      print $cgi->start_th();
        print "COOLDOWN STATISTICS";
      print $cgi->end_th();
      print $cgi->start_th();
        print "";
      print $cgi->end_th();
    print $cgi->end_Tr();

    # make a new line for every steam id
    foreach my $key (sort keys %statistics_cd) {
      print $cgi->start_Tr();
        print $cgi->start_td();
          print $statistics_cd{$key};
        print $cgi->end_td();
        print $cgi->start_td();
          if ($key eq 'cooldown_time_total') {
            print DbTools::GetStatistic($dbfile, $key) / 60;
          } else {
            print DbTools::GetStatistic($dbfile, $key);
          }
        print $cgi->end_td();
      print $cgi->end_Tr();
    }

    # table second head
    print $cgi->start_Tr();
      print $cgi->start_th();
        print "BAN STATISTICS";
      print $cgi->end_th();
      print $cgi->start_th();
        print "";
      print $cgi->end_th();
    print $cgi->end_Tr();

    # make a new line for every steam id
    foreach my $key (sort keys %statistics_ban) {
      print $cgi->start_Tr();
        print $cgi->start_td();
          print $statistics_ban{$key};
        print $cgi->end_td();
        print $cgi->start_td();
          print DbTools::GetStatistic($dbfile, $key);
        print $cgi->end_td();
      print $cgi->end_Tr();
    }
  print $cgi->end_table();

  # end html
  print $cgi->end_html();


  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # return an exit code
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  return(0);

}

################################################################################
# Main subroutine call and redirect
################################################################################
exit(Main());
