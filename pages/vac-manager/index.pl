#!/usr/bin/perl
#!C:\Strawberry\perl\bin\perl.exe

################################################################################
# Import modules
################################################################################
use strict;
use warnings;

use Cwd;
use CGI;
use Data::Dumper;

# own modules and library
use lib getcwd() . "/../../lib/perl5/";
use Utils;
use SteamAPI;
use Statistics;

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
    -title => "VAC Manager",
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
    link_cooldown_manager => "../cooldown-manager/index.pl",
    link_login => "../login/index.pl?action=login",
    link_logout => "../login/index.pl?action=logout",
    link_strat_gen => "../strat-gen/index.pl",
    link_vac_manager => "index.pl",
    display_user_name => DbTools::GetUserNameBySessionID(DBFILE, $session_id),
    template_file => "../general/navbar.tmpl",
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Page content
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # get action
  my $action = $cgi->param("action") || "";
  my $subaction = $cgi->param("subaction") || "";
  my ($form_default, $table_list_suspects, $table_suspect_detail, $form_add_suspect) = "";
  my $msg = "";

  # get default form template
  my $form_default_template = HTML::Template->new(
    filename => "../general/vac-manager/default.tmpl",
  );

  # decide what action needs to be performed
  if ($action eq "add_suspect") {
    if ($subaction eq "confirm") {

      # actually add the suspect, get steam_id64
      my $steam_id64 = $cgi->param("steam_id64");

      # error page if not valid steam_id64
      unless ($steam_id64 =~ m/[0-9]/) {
        Utils::ErrorPage(
          message => "Invalid steam ID",
          link => "index.pl",
          link_desc => "Back to VAC manager"
        );
      }

      # perform database actions right here, first get data from the steam API
      my $steam_avatar_url = SteamAPI::GetUserAvatarUrl($steam_id64);
      my $steam_profile_name = SteamAPI::GetUserProfileName($steam_id64);
      my $steam_profile_visibility = SteamAPI::GetUserProfileVisibility($steam_id64);
      my %steam_ban_state = SteamAPI::GetUserBanState($steam_id64);
      my $steam_last_modified = localtime(time());

      # check if we are updating or adding a new suspect
      if (DbTools::CheckDoubleSteamID(DBFILE, $steam_id64, 'vacs')) {

        # here goes the update, no statistic increment
        my $query = "
          UPDATE vacs SET
            steam_username = '$steam_profile_name',
            steam_ban_vac = '$steam_ban_state{vac}',
            steam_ban_game = '$steam_ban_state{game}',
            steam_ban_trade = '$steam_ban_state{trade}',
            steam_ban_community = '$steam_ban_state{community}',
            steam_avatar_url = '$steam_avatar_url',
            steam_profile_visibility = '$steam_profile_visibility',
            steam_last_modified = '$steam_last_modified'
          WHERE steam_id64 = '$steam_id64';
        ";

        if (DbTools::Custom(DBFILE, $query)) {
          $msg = "<span style=\"color: lightgreen;\">Successfully updated entry for user <span style=\"color: white;\">$steam_profile_name</span></span>";
        } else {
          $msg = "<span style=\"color: red;\">Failed to update entry for user <span style=\"color: white;\">$steam_profile_name</span></span>";
        }

      } else {

        # here goes the addition of a new user
        my $query = "
          INSERT INTO vacs (
            steam_id64,
            steam_username,
            steam_ban_vac,
            steam_ban_game,
            steam_ban_trade,
            steam_ban_community,
            steam_avatar_url,
            steam_profile_visibility,
            steam_last_modified
          ) VALUES (
            '$steam_id64',
            '$steam_profile_name',
            '$steam_ban_state{vac}',
            '$steam_ban_state{game}',
            '$steam_ban_state{trade}',
            '$steam_ban_state{community}',
            '$steam_avatar_url',
            '$steam_profile_visibility',
            '$steam_last_modified'
          )
        ";

        if (DbTools::Custom(DBFILE, $query)) {
          $msg = "<span style=\"color: lightgreen;\">Successfully added entry for user <span style=\"color: white;\">$steam_profile_name</span></span>";

          # if the above query was successful, we can now increment the statistics
          foreach my $key (keys %steam_ban_state) {
            if ($steam_ban_state{$key}) {
              Statistics::IncrementStatistics(DBFILE, 'ban_' . $key);
            }
          }

        } else {
          $msg = "<span style=\"color: red;\">Failed to add entry for user <span style=\"color: white;\">$steam_profile_name</span></span>";
        }

      }


    } else {

      # get the add template
      my $form_add_suspect_template = HTML::Template->new(
        filename => "../general/vac-manager/add.tmpl",
      );
      $form_add_suspect = $form_add_suspect_template->output();

    }

  } elsif ($action eq "list_suspects") {
    if ($subaction eq "list_suspect_detail") {

      # detailed view for suspect right here
      my $steam_id64 = $cgi->param("steam_id64");

      # check if steamid is valid
      unless ($steam_id64 =~ m/[0-9]/) {
        Utils::ErrorPage(
          message => "Invalid steam ID",
          link => "index.pl",
          link_desc => "Back to VAC manager",
        );
      }

      # fetch data from database
      my $data = DbTools::CustomFetchRowArray(DBFILE, "SELECT * FROM vacs WHERE steam_id64 = '$steam_id64'");
      my @data = split (',', @$data[0]);

      # get the detail listing template
      my $table_suspect_detail_template = HTML::Template->new(
        filename => "../general/vac-manager/list_suspect_detail.tmpl",
      );

      # set ban state vars
      if ($data[2] > 0) {
        $data[2] = "<span style=\"color: red;\">&#10004</span>(" . $data[2] . ")";
      } else {
        $data[2] = "<span style=\"color: green;\">&#10008</span>(" . $data[2] . ")";
      }
      if ($data[3] > 0) {
        $data[3] = "<span style=\"color: red;\">&#10004</span>(" . $data[3] . ")";
      } else {
        $data[3] = "<span style=\"color: green;\">&#10008</span>(" . $data[3] . ")";
      }
      if ($data[4] > 0) {
        $data[4] = "<span style=\"color: red;\">&#10004</span>(" . $data[4] . ")";
      } else {
        $data[4] = "<span style=\"color: green;\">&#10008</span>(" . $data[4] . ")";
      }
      if ($data[5] > 0) {
        $data[5] = "<span style=\"color: red;\">&#10004</span>(" . $data[5] . ")";
      } else {
        $data[5] = "<span style=\"color: green;\">&#10008</span>(" . $data[5] . ")";
      }
      
      # replace template vars
      $table_suspect_detail_template->param(
        STEAM_ID64 => $steam_id64,
        STEAM_PROFILE_NAME => $data[1],
        STEAM_AVATAR_URL => $data[6],
        STEAM_PROFILE_VISIBILITY => $data[7],
        STEAM_LAST_MODIFIED => $data[8],
        STEAM_BAN_VAC => $data[2],
        STEAM_BAN_GAME => $data[3],
        STEAM_BAN_TRADE => $data[4],
        STEAM_BAN_COMMUNITY => $data[5],
      );

      # get the template output
      $table_suspect_detail = $table_suspect_detail_template->output();

      # set the msg
      $msg = "<span style=\"color: lightgreen;\">Successfully listed details for user <span style=\"color: white;\">$data[1]</span></span>";

    } else {
      
      # list suspects right here
      # get all steam_id64's
      my $data = DbTools::CustomFetchRowArray(DBFILE, "SELECT steam_id64 FROM vacs;");

      # load the list view template and create the table for each of the steam id's
      my $table_list_suspects_rows = "";
      my $table_list_suspects_template = HTML::Template->new(
        filename => "../general/vac-manager/list_suspects.tmpl",
      );

      # get data for each steam id and write to template var
      foreach my $steam_id64 (@$data) {

        # get the template
        my $table_list_suspects_rows_template = HTML::Template->new(
          filename => "../general/vac-manager/list_suspects_row.tmpl",
        );

        # fetch the username from the database
        my $steam_profile_name = DbTools::CustomFetchRowArray(DBFILE, "SELECT steam_username FROM vacs WHERE steam_id64 = '$steam_id64'");

        # replace template vars
        $table_list_suspects_rows_template->param(
          STEAM_ID64 => $steam_id64,
          STEAM_PROFILE_NAME => @$steam_profile_name,
        );

        # append the table row
        $table_list_suspects_rows = $table_list_suspects_rows . $table_list_suspects_rows_template->output();

      }

      # replace template vars in the suspect listing template
      $table_list_suspects_template->param(
        TABLE_LIST_SUSPECTS => $table_list_suspects_rows,
      );
      $table_list_suspects = $table_list_suspects_template->output();

      # set the msg
      $msg = "<span style=\"color: lightgreen;\">Successfully listed all suspects</span>";

    }
  } elsif ($action eq "del_suspect") {
    if ($subaction eq "confirm") {

    } else {

    }
  }

  # get main template
  my $template = HTML::Template->new(
    filename => "../general/vac-manager/vac-manager.tmpl",
  );

  # get form default output and set form default vars
  $form_default_template->param(
    MSG => $msg,
  );
  $form_default = $form_default_template->output();

  # set main template vars
  $template->param(
    FORM_DEFAULT => $form_default,
    TABLE_LIST_SUSPECTS => $table_list_suspects,
    TABLE_SUSPECT_DETAIL => $table_suspect_detail,
    FORM_ADD_SUSPECT => $form_add_suspect,
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
