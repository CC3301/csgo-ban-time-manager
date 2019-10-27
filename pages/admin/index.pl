#!C:\Strawberry\perl\bin\perl.exe
#!/usr/bin/perl

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

  # check if we are the admin, only admin can see the admin page
  unless (DbTools::GetUserNameBySessionID(DBFILE, $session_id) eq "admin") {
    Utils::ErrorPage(
      message => "You do not have the required powa!",
      link => "../login/index.pl?action=login",
      link_desc => "Log in as different user",
    );
  }

  # start printing the webpage
  print $cgi->header();
  print $cgi->start_html();
  print "You are admin";
  print $cgi->end_html();

  # exit the subroutine with a numeric return value
  return 0;

}


################################################################################
# call the index subroutine
################################################################################
exit(Index());
