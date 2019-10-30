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
  # get action and subactiom, set vars
  my $action = $cgi->param("action") || "";
  my $subaction = $cgi->param("subaction") || "";
  my ($form_default, $form_add_suspect, $form_list_suspects, $form_detail_suspect) = "";
  my $msg = "";

  # get default form template
  my $form_default_template = HTML::Template->new(
    filename => "../general/vac-manager/default.tmpl",
  );

  # decide what action needs to be performed
  if ($action eq "add_suspect") {
    if ($subaction eq "confirm") {

      # get values
      my $steam_id64 = $cgi->param("steam_id64");
      if ($steam_id64 =~ m/[0-9]/) {

        # get values from steam API
        my $steam_avatar_url = SteamAPI::GetUserAvatarUrl($steam_id64);
        my $steam_profile_name = SteamAPI::GetUserProfileName($steam_id64);
        my $steam_profile_visibility = SteamAPI::GetUserProfileVisibility($steam_id64);
        my %steam_ban_state = SteamAPI::GetUserBanState($steam_id64);

        # timestamp
        my $steam_last_modified = localtime(time());

        # check if we are updating the entry or adding a new one
        if (DbTools::CheckDoubleSteamID(DBFILE, $steam_id64, 'vacs')) {

          my $query = "
            UPDATE vacs
            SET steam_username = '$steam_profile_name',
            steam_ban_vac = '$steam_ban_state{vac}',
            steam_ban_game = '$steam_ban_state{game}',
            steam_ban_trade = '$steam_ban_state{trade}',
            steam_ban_community = '$steam_ban_state{commnity}',
            steam_avatar_url = '$steam_avatar_url',
            steam_profile_visibility = '$steam_profile_visibility',
            steam_last_modified = '$steam_last_modified'
            WHERE steam_id64 = '$steam_id64',
          ";

          if (DbTools::Custom(DBFILE, $query)) {
            $msg = "Successfully updated steamID: $steam_id64";
          } else {
            $msg = "Failed to update steamID: $steam_id64";
          }

        } else {

          my $query = "
            INSERT INTO vacs(
              steam_id64,
              steam_username,
              steam_ban_