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
    -title => "Strat generator",
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
    link_strat_gen => "index.pl",
    link_vac_manager => "../vac-manager/index.pl",
    display_user_name => DbTools::GetUserNameBySessionID(DBFILE, $session_id),
    template_file => "../general/navbar.tmpl",
  );

  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Page content
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
