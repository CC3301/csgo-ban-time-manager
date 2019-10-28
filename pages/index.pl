#!/usr/bin/perl
#!C:\Strawberry\perl\bin\perl.exe

################################################################################
# Import modules
################################################################################
use strict;
use warnings;

use Cwd;
use CGI;
use HTML::Template;

# own modules and library
use lib getcwd() . "/../lib/perl5/";
use Utils;
use Statistics;

# database file
use constant DBFILE => getcwd() . "/../data/database.db";

################################################################################
# Actual webpage
################################################################################
sub Index() {

  # create a new CGI object and a new Session
  my $cgi = new CGI;
  my $session_id = $cgi->cookie("CGISESSIONID") || undef;

  # call the page init function, with custom Loginlink
  Utils::PageInit($cgi, $session_id, DBFILE, 0, "/pages/login/index.pl?action=login");

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # declare some Statistics
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my %statistics_cooldown = (
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
  my %statistics_vac = (
    'ban_vac' => 'Number of unique accounts with one or more VAC-bans',
    'ban_game' => 'Number of unique accounts with one ore more game-bans',
    'ban_trade' => 'Number of unique accounts with a trade-ban',
    'ban_community' => 'Number of unique accounts with a community-ban',
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Header and navbar
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print $cgi->header();
  print $cgi->start_html(
    -title => "Start Page",
    -head=>CGI::Link(
      {
        -rel => "stylesheet",
        -media => "all",
        -type => "text/css",
        -href => "../../lib/css/main.css",
      },
    ),
  );

  # get the navbar printed
  print Utils::NavBar(
    link_home => "index.pl",
    link_admin => "admin/index.pl",
    link_cooldown_manager => "cooldown-manager/index.pl",
    link_login => "login/index.pl?action=login",
    link_logout => "login/index.pl?action=logout",
    link_strat_gen => "strat-gen/index.pl",
    link_vac_manager => "vac-manager/index.pl",
    display_user_name => DbTools::GetUserNameBySessionID(DBFILE, $session_id),
    template_file => "general/navbar.tmpl",
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Page content
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $start_page_template = HTML::Template->new(
    filename => "general/start_page.tmpl",
  );

  # build the VAC Statistics tables
  my $table_statistics_vac = "
    <table class=\"statistics-table\">
  ";
  foreach my $key (sort keys %statistics_vac) {
    $table_statistics_vac = $table_statistics_vac . "<tr>\n";
    $table_statistics_vac = $table_statistics_vac . "\t<td>\n";
    $table_statistics_vac = $table_statistics_vac . "\t\t$statistics_vac{$key}\n";
    $table_statistics_vac = $table_statistics_vac . "\t</td>\n";
    $table_statistics_vac = $table_statistics_vac . "\t<td>\n";
    $table_statistics_vac = $table_statistics_vac . "\t\t" . Statistics::GetStatistic(DBFILE, $key) . "\n";
    $table_statistics_vac = $table_statistics_vac . "\t</td>\n";
    $table_statistics_vac = $table_statistics_vac . "</tr>\n";
  }
  $table_statistics_vac = $table_statistics_vac . "
    </table>
  ";

  # build the Cooldown Statistics tables
  my $table_statistics_cooldown = "
    <table class=\"statistics-table\" style=\"text-align:left;\">
  ";
  foreach my $key (sort keys %statistics_cooldown) {
    $table_statistics_cooldown = $table_statistics_cooldown . "<tr>\n";
    $table_statistics_cooldown = $table_statistics_cooldown . "\t<td>\n";
    $table_statistics_cooldown = $table_statistics_cooldown . "\t\t$statistics_cooldown{$key}\n";
    $table_statistics_cooldown = $table_statistics_cooldown . "\t</td>\n";
    $table_statistics_cooldown = $table_statistics_cooldown . "\t<td>\n";
    $table_statistics_cooldown = $table_statistics_cooldown . "\t\t" . Statistics::GetStatistic(DBFILE, $key) . "\n";
    $table_statistics_cooldown = $table_statistics_cooldown . "\t</td>\n";
    $table_statistics_cooldown = $table_statistics_cooldown . "</tr>\n";
  }
  $table_statistics_cooldown = $table_statistics_cooldown . "
    </table>
  ";


  # replace template vars
  $start_page_template->param(
    TABLE_STATISTICS_VAC => $table_statistics_vac,
    TABLE_STATISTICS_COOLDOWN => $table_statistics_cooldown,
  );
  print $start_page_template->output();

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Footer and end of page
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print Utils::Footer(
    template_file => "general/footer.tmpl",
    display_user_name => DbTools::GetUserNameBySessionID(DBFILE, $session_id),
  );
  print $cgi->end_html();

  # exit the subroutine with a numeric return value
  return 0;

}


################################################################################
# call the index subroutine
################################################################################
exit(Index());
