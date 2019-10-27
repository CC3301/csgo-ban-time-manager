#!C:\Strawberry\perl\bin\perl.exe
#!/usr/bin/perl

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
  my $session = new CGI::Session(undef, $cgi, {Directory => '/../../data/tmp'});

  Utils::PageInit($cgi, undef, DBFILE, 1);

  # decide what tempalte to use
  my $tmpl_file = undef;
  if ($cgi->param("action") eq "login") {
    $tmpl_file = "/login.tmpl";
  } elsif ($cgi->param("action") eq "confirm-login") {
    $tmpl_file = "/login.tmpl";
  } elsif ($cgi->param("action") eq "register") {
    $tmpl_file = "/register.tmpl";
  } elsif ($cgi->param("action") eq "confirm-register") {
    $tmpl_file = "/register.tmpl";
  } elsif ($cgi->param("action") eq "logout") {
    $tmpl_file = "/logout.tmpl";
  }

  # create the html template
  my $template = HTML::Template->new(
    filename => getcwd() . $tmpl_file,
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
      $template->param(MSG => "Invalid username or password");
      my $cookie = $cgi->cookie(CGISESSIONID => $session_id);
      print $cgi->header( -cookie => $cookie );
      print $template->output();
      exit();
    }

    # login was successfull
    $template->param(MSG => "Logged in as $username");
    my $cookie = $cgi->cookie(CGISESSIONID => $session_id);
    print $cgi->header( -cookie => $cookie );
    print $template->output();

  } elsif ($cgi->param("action") eq "register") {

    # print template and wait for data
    $template->param(MSG => "Please enter a desired username and password");
    print $cgi->header();
    print $template->output();

  } elsif ($cgi->param("action") eq "confirm-register") {

    # get username and password for database comparison
    my $username = $cgi->param("username");

    # print the template and an error if the username is already in use
    unless (DbTools::CheckDoubleUsername(DBFILE, $username)) {
      $template->param(MSG => "Username already allocated");
      print $cgi->header();
      print $template->output();
      exit();
    }

    # get the rest of the data
    my $password = $cgi->param("password");

    # if the registration fails, print an error
    unless (DbTools::RegisterUser(DBFILE, $username, $password)) {
      $template->param(MSG => "Registration failed");
      print $cgi->header();
      print $template->output();
      exit();
    }

    $template->param(MSG => "Registration successfull, you can log in now");
    print $cgi->header();
    print $template->output();

  } elsif ($cgi->param("action") eq "logout") {

    # get the session id
    my $session_id = $cgi->cookie("CGISESSIONID") || undef;

    # print an error if the user is not logged in and tries to log out
    unless (DbTools::CheckUserAuthState(DBFILE, $session_id)) {
      $template->param(MSG => "You are not logged in");
      print $cgi->header();
      print $template->output();
      exit();
    }

    # now we can overwrite the session id
    my $cookie = $cgi->cookie(CGISESSIONID => 0);
    DbTools::LogOutUser(DBFILE, $session_id);
    $template->param(MSG => "Logged out successfully");
    print $cgi->header(
      -cookie => $cookie,
    );
    print $template->output();

  } else {

    $template->param(MSG => "Please log in");
    print $cgi->header();
    print $template->output();

  }
  return(0);
}

################################################################################
# call the index subroutine
################################################################################
exit(Index());
