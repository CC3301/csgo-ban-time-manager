#!/usr/bin/perl
#!C:\Strawberry\perl\bin\perl.exe

################################################################################
# Import modules
################################################################################
use strict;
use warnings;

use Cwd;
use CGI;

# own modules and library
use lib getcwd() . "/../../lib/perl5/";
use Utils;
use SteamAPI;
use Statistics;
use DbTools;

# database file
use constant DBFILE => getcwd() . "/../../data/database.db";

################################################################################
# Actual webpage
################################################################################
sub Index() {

  # create a new CGI object and a new Session
  my $cgi = new CGI;
  my $session_id = $cgi->cookie("CGISESSIONID") || undef;

  # call the page init function
  Utils::PageInit($cgi, $session_id, DBFILE);

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Header and navbar
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print $cgi->header();
  print $cgi->start_html(
    -title => "Cooldown Manager",
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
    link_home => "../index.pl",
    link_admin => "../admin/index.pl",
    link_cooldown_manager => "index.pl",
    link_login => "../login/index.pl?action=login",
    link_logout => "../login/index.pl?action=logout",
    link_strat_gen => "../strat-gen/index.pl",
    link_vac_manager => "../vac-manager/index.pl",
    display_user_name => DbTools::GetUserNameBySessionID(DBFILE, $session_id),
    template_file => "../general/navbar.tmpl",
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Page content
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # get action
  my $action = $cgi->param("action") || "";
  my $subaction = $cgi->param("subaction") || "";
  my ($form_default, $table_list_cooldowns, $table_cooldown_detail, $form_add_cooldown) = "";
  my $msg = "";

  # get default form template
  my $form_default_template = HTML::Template->new(
    filename => "../general/cooldown-manager/default.tmpl",
  );

  # decide what action needs to be performed
  if ($action eq "add_cooldown") {
    if ($subaction eq "confirm") {

      # actually add the suspect, get steam_id64 and cooldown information
      my $steam_id64 = $cgi->param("steam_id64");
      my $steam_cooldown_reason = $cgi->param("steam_cooldown_reason");
      my $steam_cooldown_time = $cgi->param("steam_cooldown_time");

      my $old_cooldown_time = 0;
      my $old_cooldown_reason = 0;

      # error page if not valid steam_id64
      unless ($steam_id64 =~ m/[0-9]/) {
        Utils::ErrorPage(
          message => "Invalid steam ID",
          link => "index.pl",
          link_desc => "Back to Cooldown manager"
        );
      }

      # get values from steam API
      my $steam_avatar_url = SteamAPI::GetUserAvatarUrl($steam_id64);
      my $steam_profile_name = SteamAPI::GetUserProfileName($steam_id64);
      my $steam_profile_visibility = SteamAPI::GetUserProfileVisibility($steam_id64);
      my $steam_last_modified = localtime(time());

      # check wether we are updating or adding a new entry
      if (DbTools::CheckDoubleSteamID(DBFILE, $steam_id64, 'cooldowns')) {

        # here goes the update of an existing user

        # get old cooldown time and add it to the new one
        $old_cooldown_time = DbTools::CustomFetchRowArray(DBFILE, "SELECT steam_cooldown_time FROM cooldowns WHERE steam_id64 = '$steam_id64'");
        my $new_cooldown_time = $old_cooldown_time + $steam_cooldown_time;

        # get old cooldown reasons and add new one
        $old_cooldown_reason = DbTools::CustomFetchRowArray(DBFILE, "SELECT steam_cooldown_reason FROM cooldowns WHERE steam_id64 = '$steam_id64'");
        my $new_cooldown_reason = $old_cooldown_reason . "<br />" . $steam_cooldown_reason;

        # update the cooldowns table
        my $query = "
          UPDATE cooldowns SET
            steam_username = '$steam_profile_name',
            steam_cooldown_time = '$new_cooldown_time',
            steam_cooldown_reason = '$new_cooldown_reason',
            steam_avatar_url = '$steam_avatar_url',
            steam_profile_visibility = '$steam_profile_visibility',
            steam_last_modified = '$steam_last_modified'
          WHERE steam_id64 = '$steam_id64';
        ";

        if (DbTools::Custom(DBFILE, $query)) {
          $msg = "<span style=\"color: lightgreen;\">Successfully updated entry for user <span style=\"color: white;\">$steam_profile_name</span></span>";

          # if the above query succeeds, we can increment some statistics
          Statistics::IncrementStatistics(DBFILE, 'cooldown_type_' . $steam_cooldown_time);
          Statistics::IncrementStatistics(DBFILE, 'cooldown_reason_' . $steam_cooldown_reason);
          Statistics::IncrementStatistics(DBFILE, 'cooldown_time_total', $steam_cooldown_time);

        } else {
          $msg = "<span style=\"color: red;\">Failed to update entry for user <span style=\"color: white;\">$steam_profile_name</span></span>";
        }

      } else {

        # here goes the addition of a new user
        my $query = "
          INSERT INTO cooldowns(
            steam_id64, 
            steam_username,
            steam_cooldown_time, 
            steam_cooldown_reason,
            steam_avatar_url,
            steam_profile_visibility,
            steam_last_modified
          ) VALUES (
            '$steam_id64',
            '$steam_profile_name',
            '$steam_cooldown_time',
            '$steam_cooldown_reason',
            '$steam_avatar_url',
            '$steam_profile_visibility',
            '$steam_last_modified'
          );
        ";

        if (DbTools::Custom(DBFILE, $query)) {
          $msg = "<span style=\"color: lightgreen;\">Successfully added entry for user <span style=\"color: white;\">$steam_profile_name</span></span>";

          # if the above query succeeds, we can increment some statistics
          Statistics::IncrementStatistics(DBFILE, 'cooldown_type_' . $steam_cooldown_time);
          Statistics::IncrementStatistics(DBFILE, 'cooldown_reason_' . $steam_cooldown_reason);
          Statistics::IncrementStatistics(DBFILE, 'cooldown_time_total', $steam_cooldown_time);
          Statistics::IncrementStatistics(DBFILE, 'cooldown_users_total');
          Statistics::IncrementStatistics(DBFILE, 'total_users_in_db');

        } else {
          $msg = "<span style=\"color: red;\">Failed to add entry for user <span style=\"color: white;\">$steam_profile_name</span></span>";
        }
      }

    } else {
      # get the add template
      my $form_add_cooldown_template = HTML::Template->new(
        filename => "../general/cooldown-manager/add.tmpl",
      );
      $form_add_cooldown = $form_add_cooldown_template->output();
    } 

  } elsif ($action eq "list_cooldowns") {
    if ($subaction eq "list_cooldown_detail") {

      # detailed view for suspect right here
      my $steam_id64 = $cgi->param("steam_id64");

      # check if steamid is valid
      unless ($steam_id64 =~ m/[0-9]/) {
        Utils::ErrorPage(
          message => "Invalid steam ID",
          link => "index.pl",
          link_desc => "Back to Cooldown manager",
        );
      }

      # fetch data from database
      my $data = DbTools::CustomFetchRowArray(DBFILE, "SELECT * FROM cooldowns WHERE steam_id64 = '$steam_id64'");
      my @data = split (',', @$data[0]);

      # get the detail listing template
      my $table_cooldown_detail_template = HTML::Template->new(
        filename => "../general/cooldown-manager/list_cooldown_detail.tmpl",
      );

      # replace template vars
      $table_cooldown_detail_template->param(
        STEAM_PROFILE_NAME => $data[1],
        STEAM_ID64 => $steam_id64,
        STEAM_AVATAR_URL => $data[4],
        STEAM_PROFILE_VISIBILITY => $data[5],
        STEAM_COOLDOWN_TIME => (int ($data[2]) . " Minutes <br />" . int ($data[2] / 60) . " Hour(s) <br />"),
        STEAM_COOLDOWN_REASON => $data[3],
        STEAM_LAST_MODIFIED => $data[6],
      );


      # get the template output
      $table_cooldown_detail = $table_cooldown_detail_template->output();

      # set the msg
      $msg = "<span style=\"color: lightgreen;\">Successfully listed details for user <span style=\"color: white;\">$data[1]</span></span>";

    } else {
      
      # list suspects right here
      # get all steam_id64's
      my $data = DbTools::CustomFetchRowArray(DBFILE, "SELECT steam_id64 FROM cooldowns;");

      # load the list view template and create the table for each of the steam id's
      my $table_list_cooldowns_rows = "";
      my $table_list_cooldowns_template = HTML::Template->new(
        filename => "../general/cooldown-manager/list_cooldowns.tmpl",
      );

      # get data for each steam id and write to template var
      foreach my $steam_id64 (@$data) {

        # get the template
        my $table_list_cooldowns_rows_template = HTML::Template->new(
          filename => "../general/cooldown-manager/list_cooldowns_row.tmpl",
        );

        # fetch the username from the database
        my $steam_profile_name = DbTools::CustomFetchRowArray(DBFILE, "SELECT steam_username FROM cooldowns WHERE steam_id64 = '$steam_id64'");

        # replace template vars
        $table_list_cooldowns_rows_template->param(
          STEAM_ID64 => $steam_id64,
          STEAM_PROFILE_NAME => @$steam_profile_name,
        );

        # append the table row
        $table_list_cooldowns_rows = $table_list_cooldowns_rows . $table_list_cooldowns_rows_template->output();

      }

      # replace template vars in the suspect listing template
      $table_list_cooldowns_template->param(
        TABLE_LIST_COOLDOWNS => $table_list_cooldowns_rows,
      );
      $table_list_cooldowns = $table_list_cooldowns_template->output();

      # set the msg
      $msg = "<span style=\"color: lightgreen;\">Successfully listed all cooldowns</span>";

    }

  } elsif ($action eq "del_suspect") {
    if ($subaction eq "confirm") {

    } else {

    }
  }

  # get main template
  my $template = HTML::Template->new(
    filename => "../general/cooldown-manager/cooldown-manager.tmpl",
  );

  # get form default output and set form default vars
  $form_default_template->param(
    MSG => $msg,
  );
  $form_default = $form_default_template->output();

  # set main template vars
  $template->param(
    FORM_DEFAULT => $form_default,
    TABLE_LIST_COOLDOWNS => $table_list_cooldowns,
    TABLE_COOLDOWN_DETAIL => $table_cooldown_detail,
    FORM_ADD_COOLDOWN => $form_add_cooldown,
  );
  print $template->output();

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Footer and end of page
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print Utils::Footer(
    template_file => "../general/footer.tmpl",
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
