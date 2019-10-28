#!/usr/bin/perl
#!C:\Strawberry\perl\bin\perl.exe

################################################################################
# Import modules
################################################################################
use strict;
use warnings;

use Cwd;
use CGI;
use CGI::Session;
use DBI;
use HTML::Template;

# own modules and library
use lib getcwd() . "/../../lib/perl5/";
use Utils;

# database file
use constant DBFILE => getcwd() . "/../../data/database.db";

################################################################################
# Actual webpage
################################################################################
sub Index() {

  # create a new CGI object
  my $cgi = new CGI;

  # check for the cgi parameter, which tells us to either the setup or to just
  # display the information page
  if ($cgi->param("action") eq "confirm") {
    # check if the database is already initialized, then throw an error if it is
    if ( -f DBFILE) {
      Utils::ErrorPage(
        message => "Database already initialized",
        link => "../../index.html",
        link_desc => "Start page",
      );
    }
    _run_setup();
  } elsif ($cgi->param("action") eq "init_admin") {
    if (-f DBFILE) {
      _init_admin();
    } else {
      Utils::ErrorPage(
        message => "Database not initialized",
        link => "index.pl",
        link_desc => "Run Setup",
      );
    }
  } else {
    _show_setup_page("default");
  }

  # exit the subroutine with a numeric return value
  return 0;

}

################################################################################
# _run_setup subroutine
################################################################################
sub _run_setup {

  # get data passed to function
  my $cgi = shift;

  # create a new database handle and an empty query and a query log
  my $dbh = DBI->connect("dbi:SQLite:" . DBFILE);
  my $query = undef;
  my $q_log = "";

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # run varions queries
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  # create application_data table
  $query = "
    CREATE TABLE application_data (
      init_state BOOLEAN
    );
  ";
  $query = $dbh->prepare($query);
  eval {
    $query->execute();
  };
  if ($@) {
    $q_log = $q_log . "Creation of application_data table failed</br>\n";
  } else {
    $q_log = $q_log . "application_data table created successfully</br>\n";
  }

  # create vacs talbe
  $query = "
    CREATE TABLE vacs (
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
  eval {
    $query->execute();
  };
  if ($@) {
    $q_log = $q_log . "Creation of vacs table failed</br>\n";
  } else {
    $q_log = $q_log . "vacs table created successfully</br>\n";
  }

  # create cooldowns talbe
  $query = "
    CREATE TABLE cooldowns (
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
  eval {
    $query->execute();
  };
  if ($@) {
    $q_log = $q_log . "Creation of cooldowns table failed</br>\n";
  } else {
    $q_log = $q_log . "cooldowns table created successfully</br>\n";
  }

  # create statistics talbe
  $query = "
    CREATE TABLE statistics (
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
  eval {
    $query->execute();
  };
  if ($@) {
    $q_log = $q_log . "Creation of statistics table failed</br>\n";
  } else {
    $q_log = $q_log . "statistics table created successfully</br>\n";
  }

  # create users table
  $query = "
    CREATE TABLE users (
      username VARCHAR,
      password VARCHAR,
      session_id VARCHAR,
      auth_state BOOLEAN,
      UNIQUE(username)
    );
  ";
  $query = $dbh->prepare($query);
  eval {
    $query->execute();
  };
  if ($@) {
    $q_log = $q_log . "Creation of users table failed</br>\n";
  } else {
    $q_log = $q_log . "users table created successfully</br>\n";
  }

  # initialize statistics talbe
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
    );
  ";
  $query = $dbh->prepare($query);
  eval {
    $query->execute();
  };
  if ($@) {
    $q_log = $q_log . "Initialization of statistics table failed</br>\n";
  } else {
    $q_log = $q_log . "statistics table initialized successfully</br>\n";
  }

  # initialize application_data talbe
  $query = "
    INSERT INTO application_data (
      init_state
    ) VALUES (
      0
    );
  ";
  $query = $dbh->prepare($query);
  eval {
    $query->execute();
  };
  if ($@) {
    $q_log = $q_log . "Initialization of application_data table failed</br>\n";
  } else {
    $q_log = $q_log . "application_data table initialized successfully</br>\n";
  }

  # end the query log
  $q_log = $q_log . "Database initialization complete<br>\n";

  # show the setup page when done, dont need return here, return is in
  # _show_setup_page subroutine
  _show_setup_page("step1_done", $q_log);

}

################################################################################
# _show_setup_page subroutine
################################################################################
sub _show_setup_page {

  # get data passed to function
  my $action = shift();
  my $q_log = shift() || undef;

  # get a new cgi object
  my $cgi = new CGI;

  # decide what template to load and what vars to replace
  my $tmpl_file = undef;
  if ($action eq "default") {
    $tmpl_file = "/../general/setup/step1.tmpl";
  } elsif ($action eq "step1_done") {
    $tmpl_file = "/../general/setup/step1_done.tmpl";
  } elsif ($action eq "step2_done") {
    $tmpl_file = "/../general/setup/step2_done.tmpl"
  } elsif ($action eq "step2") {
    $tmpl_file = "/../general/setup/step2.tmpl";
  }

  # create new html template object
  my $template = new HTML::Template(
    filename => getcwd() . $tmpl_file,
  );

  # replace vars depending on the Template
  if ($action eq "step1_done") {
    $template->param(Q_LOG => $q_log);
  } elsif ($action eq "step2_done") {
    $template->param(Q_LOG => $q_log);
  }

  # print the templates
  print $cgi->header();
  print $template->output();

  # return out of the subroutine
  return();

}

################################################################################
# _init_admin subroutine
################################################################################
sub _init_admin {

  # create a new CGI object and empty qlog
  my $cgi = new CGI;
  my $q_log = "";
  # check if we are calling ourselves or if this is the first run
  if ($cgi->param("skip") eq "true") {
    # create a new user with the following username and the password
    my $username = "admin";
    my $password = $cgi->param("password");

    # create the database handle
    my $dbh = DBI->connect("dbi:SQLite:" . DBFILE);

    # add the user
    my $query = "
      INSERT INTO users (
        username,
        password,
        session_id
      ) VALUES (
        'admin',
        '$password',
        0
      );
    ";
    $query = $dbh->prepare($query);
    eval {
      $query->execute();
    };
    if ($@) {
      $q_log = $q_log . "Failed to create initial admin account</br>\n";
    } else {
      $q_log = $q_log . "Initial admin account created</br>\n";
    }


    # update the database init state
    $query = "
      UPDATE application_data SET init_state = 1;
    ";
    $query = $dbh->prepare($query);
    eval {
      $query->execute();
    };
    if ($@) {
      $q_log = $q_log . "Failed to updated init state in application_data table</br>\n";
    } else {
      $q_log = $q_log . "Init state updated</br>\n";
    }

    # show the setup page
    _show_setup_page("step2_done", $q_log);

  } else {
    _show_setup_page("step2");
  }
}

################################################################################
# call the index subroutine
################################################################################
exit(Index());
