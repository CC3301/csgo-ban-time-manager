#!/usr/bin/perl

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


################################################################################
# Main subroutine
################################################################################
sub Main() {

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # var declaration
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $query = undef;

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # create the database handle
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $dbfile = getcwd() . "/data/database.db";
  my $dbh    = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "") or die 
    "Failed to open database";

  # status information
  print "Initializing database...\n";

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # initialize tables
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  # statistics table
  print "TABLE: statistics..";
  $query = "
    CREATE TABLE statistics(
      cooldown_reason_team_kills_at_round_start INTEGER,
      cooldown_reason_team_kills INTEGER,
      cooldown_reason_team_damage INTEGER,
      cooldown_reason_rage_quit INTEGER,
      cooldown_reason_team_afk_timeout INTEGER,
      cooldown_type_30 INTEGER,
      cooldown_type_120 INTEGER,
      cooldown_type_1500 INTEGER,
      cooldown_type_10500 INTEGER,
      ban_vac INTEGER,
      ban_game INTEGER,
      ban_trade INTEGER,
      ban_community INTEGER,
      cooldown_time_total INTEGER,
      cooldown_users_total INTEGER
    );
  ";
  $query = $dbh->prepare($query);
  $query->execute();

  # fill statistics with 0's
  $query = "
    INSERT INTO statistics(
      cooldown_reason_team_kills_at_round_start,
      cooldown_reason_team_kills,
      cooldown_reason_team_damage,
      cooldown_reason_rage_quit,
      cooldown_reason_team_afk_timeout,
      cooldown_type_30,
      cooldown_type_120,
      cooldown_type_1500,
      cooldown_type_10500,
      ban_vac,
      ban_game,
      ban_trade,
      ban_community,
      cooldown_time_total,
      cooldown_users_total    
    )VALUES(
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    )
  ";
  $query = $dbh->prepare($query);
  $query->execute();
  print "[OK]\n";

  # cooldowns table
  print "TABLE: cooldowns..";
  $query = "
    CREATE TABLE cooldowns(
      steam_id64 INTEGER,
      steam_username VARCHAR,
      steam_cooldown_time INTEGER,
      steam_cooldown_reason VARCHAR,
      steam_avatar_url VARCHAR,
      steam_profile_visibility INTEGER,
      steam_last_modified VARCHAR,
      UNIQUE(steam_id64)
    );
  ";
  $query = $dbh->prepare($query);
  $query->execute();
  print "[OK]\n";

  # vacs table
  print "TABLE: vacs..";
  $query = "
    CREATE TABLE vacs(
      steam_id64 INTEGER,
      steam_username VARCHAR,
      steam_ban_vac BOOLEAN,
      steam_ban_game BOOLEAN,
      steam_ban_trade BOOLEAN,
      steam_ban_community BOOLEAN,
      steam_avatar_url VARCHAR,
      steam_profile_visibility INTEGER,
      steam_last_modified VARCHAR,
      UNIQUE(steam_id64)
    );
  ";
  $query = $dbh->prepare($query);
  $query->execute();
  print "[OK]\n";

  print "Database initialized.";

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # return an exit code and do some cleanup
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  $dbh->disconnect();
  $query = undef;
  return(0);

}
################################################################################
# Main subroutine call
################################################################################
exit(Main());