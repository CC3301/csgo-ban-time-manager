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

  # check if we are the admin, only admin can see the admin page
  unless (DbTools::GetUserNameBySessionID(DBFILE, $session_id) eq "admin") {
    Utils::ErrorPage(
      message => "You do not have the required powa!",
      link => "../../login/index.pl?action=login",
      link_desc => "Log in as different user",
    );
  }

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Header and navbar
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print $cgi->header();
  print $cgi->start_html(
    -title => "Admin Page",
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
    link_admin => "index.pl",
    link_cooldown_manager => "../cooldown-manager/index.pl",
    link_login => "../login/index.pl?action=login",
    link_logout => "../login/index.pl?action=logout",
    link_strat_gen => "../strat-gen/index.pl",
    link_vac_manager => "../vac-manager/index.pl",
    display_user_name => DbTools::GetUserNameBySessionID(DBFILE, $session_id),
    template_file => "../general/navbar.tmpl",
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # get HTML template
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $admin_panel_template = HTML::Template->new(
    filename => "../general/admin/admin_panel.tmpl",
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # action handling
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  my $action = $cgi->param("action") || "";
  my $subaction = $cgi->param("subaction") || "";
  my ($form_add_user, $form_del_user, $table_list_users, $form_default) = "";

  # get the default form going
  my $form_default_template = HTML::Template->new(
    filename => "../general/admin/default.tmpl"
  );

  # decide what action to perform
  if ($action eq "add_user") {
    if ($subaction eq "confirm") {

      # get data
      my $username = $cgi->param("username");
      my $msg = "";

      # check if the username is even valid
      if ($username eq "username") {
        $msg = "Please enter a valid username";
      } else {

        # check if the username already exists
        unless (DbTools::CheckDoubleUsername(DBFILE, $username)) {
          $msg = "This user already exists";
        } else {

          # get Password
          my $password = $cgi->param("password") || "password";

          # check for valid password
          if ($password eq "password") {
            $msg = "Please enter a valid password";
          } else {
            if (DbTools::RegisterUser(DBFILE, $username, $password)) {
              $msg = "User '$username' has been added";
            } else {
              $msg = "Failed to add user '$username'";
            }
          }
        }
      }

      # print the msg
      $form_default_template->param(
        MSG => $msg,
      );

    } else {

      # load the add user template
      my $form_add_user_template = HTML::Template->new(
        filename => "../general/admin/add_user.tmpl",
      );
      $form_add_user = $form_add_user_template->output();

    }
  } elsif ($action eq "del_user") {
    if ($subaction eq "confirm") {

      # get the username
      my $username = $cgi->param("username") || "username";
      my $msg = "";

      # check if the username is admin
      if ($username eq 'admin') {
        $msg = "Cannot delete admin account!";
      } else {
        $msg = DbTools::RemoveUser(DBFILE, $username);
      }

      # do all the work required to remove the user
      $form_default_template->param(
        MSG => $msg,
      );

    } else {

      # load the del user template
      my $form_del_user_template = HTML::Template->new(
        filename => "../general/admin/del_user.tmpl",
      );
      $form_del_user = $form_del_user_template->output();

    }

  } elsif ($action eq "list_users") {

    # load the list user template
    my $table_list_users_template = HTML::Template->new(
      filename => "../general/admin/list_users.tmpl",
    );

    # load the list of usernames from the database
    my $user_list = "";
    my $users = DbTools::ListUsers(DBFILE);

    # go through all users and add them to the table
    foreach my $user (@$users) {
      $user_list = $user_list . "<li>$user</li></br>";
    }


    # set template vars
    $table_list_users_template->param(
      LIST_USERS => $user_list,
    );

    # get the template output
    $table_list_users = $table_list_users_template->output();

  }

  # print the default form
  $form_default = $form_default_template->output();

  # set template vars
  $admin_panel_template->param(
    FORM_DEFAULT => $form_default,
    FORM_ADD_USER => $form_add_user,
    FORM_DEL_USER => $form_del_user,
    TABLE_LIST_USERS => $table_list_users,
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # get HTML template
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print $admin_panel_template->output();

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
