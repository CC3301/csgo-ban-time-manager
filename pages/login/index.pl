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
use HTML::Template;

# own modules and library
use lib getcwd() . "/../../lib/perl5/";
use DbTools;
use Utils;

# database file
use constant DBFILE => getcwd() . "/../../data/database.db";

################################################################################
# Actual webpage
################################################################################
sub Index() {

  # create a new CGI object and a new Session
  my $cgi = new CGI;
  my $session = new CGI::Session(undef, $cgi, {Directory => '/../data/tmp'});

  Utils::PageInit($cgi, undef, DBFILE, 1);

  # decide what tempalte to use
  my $tmpl_file = undef;
  if ($cgi->param("action") eq "login") {
    $tmpl_file = "../general/login/login.tmpl";
  } elsif ($cgi->param("action") eq "confirm-login") {
    $tmpl_file = "../general/login/login.tmpl";
  } elsif ($cgi->param("action") eq "logout") {
    $tmpl_file = "../general/login/logout.tmpl";
  }

  # create the html template
  my $template = HTML::Template->new(
    filename => $tmpl_file,
  );

  # get the action we want to perform
  if ($cgi->param("action") eq "confirm-login") {

    # get username and password for database comparison
    my $username = $cgi->param("username");
    my $password = $cgi->param("password");

    # create a session id if the user can be authenticated
    my $session_id = DbTools::AuthenticateUser(DBFILE, $username, $password, $session);

    # if we do not get a valid session id, there was an error in the username or password
    unless ($session_id) {

      # set template vars
      $template->param(MSG => "Invalid username or password");

      # get cookie
      my $cookie = $cgi->cookie(CGISESSIONID => $session_id);

      # print the navbar and headers
      print $cgi->header(
        -cookie => $cookie,
      );
      _print_login_navbar($cgi);

      # main page content
      print $template->output();

      # Footer
      _print_login_footer($cgi);

      # exit
      exit();
    }

    # login was successfull, set template vars
    $template->param(MSG => "Logged in as $username");

    # get cookie
    my $cookie = $cgi->cookie(CGISESSIONID => $session_id);

    # print the navbar and headers
    print $cgi->header(
      -cookie => $cookie,
    );
    _print_login_navbar($cgi);

    # main page content
    print $template->output();

    # Footer
    _print_login_footer($cgi);


  } elsif ($cgi->param("action") eq "logout") {

    # get the session id
    my $session_id = $cgi->cookie("CGISESSIONID") || undef;

    # print an error if the user is not logged in and tries to log out
    unless (DbTools::CheckUserAuthState(DBFILE, $session_id)) {

      # set template var
      $template->param(MSG => "You are not logged in");

      # print the navbar and headers
      print $cgi->header();
      _print_login_navbar($cgi);

      # main page content
      print $template->output();

      # Footer
      _print_login_footer($cgi);

      # exit
      exit();

    }

    # now we can overwrite the session id and reset the cookie
    my $cookie = $cgi->cookie(CGISESSIONID => 0);
    DbTools::LogOutUser(DBFILE, $session_id);

    # set template vars
    $template->param(MSG => "Logged out successfully");

    # print the navbar and headers
    print $cgi->header(
      -cookie => $cookie,
    );
    _print_login_navbar($cgi);

    # main page content
    print $template->output();

    # Footer
    _print_login_footer($cgi);

  } else {

    # set template vars
    $template->param(MSG => "Please log in");

    # print the navbar and headers
    print $cgi->header();
    _print_login_navbar($cgi);

    # main page content
    print $template->output();

    # Footer
    _print_login_footer($cgi, 'none');


  }
  return(0);
}

################################################################################
# _print_login_navbar
################################################################################
sub _print_login_navbar {

  # get the cgi object
  my $cgi = shift;

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Navbar
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print $cgi->start_html(
    -title => "Login",
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
    display_user_name => "none",
    template_file => "../general/navbar.tmpl",
  );

  # return out of the sub
  return 0;
}

################################################################################
# _print_login_footer
################################################################################
sub _print_login_footer {

  # get the cgi object
  my $cgi = shift;
  my $show_username = shift || "inherit";

  # get the session id
  my $session_id =  $cgi->cookie("CGISESSIONID") || undef;

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Footer and end of page
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  print Utils::Footer(
    template_file => "../general/footer.tmpl",
    display_user_name => DbTools::GetUserNameBySessionID($session_id),
    show_username => $show_username,
  );
  print $cgi->end_html();

  # return out of the sub
  return 0;

}

################################################################################
# call the index subroutine
################################################################################
exit(Index());
