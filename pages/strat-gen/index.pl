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
  # get action
  my $action = $cgi->param("action") || "";
  my $subaction = $cgi->param("subaction") || "";
  my ($form_default, $form_new_strat) = "";
  my $msg = "";

  # get default form template
  my $form_default_template = HTML::Template->new(
    filename => "../general/strat-gen/default.tmpl",
  );

  # decide what action needs to be performed
  if ($action eq "new_strat") {
    if ($subaction eq "confirm") {

      # get values, if not then set default values, for now only difficulty
      my $strat_gen_difficulty = $cgi->param("strat_gen_difficulty") || 0;

      if ($strat_gen_difficulty =~ m/[0-9]/) {

        # write the temp cfg file for strat gen
        open(my $fh, '>', "../../data/tmp/strat_gen_tmp_config.cfg") or $msg = "<span style=\"color: red;\">Failed write temporary strat gen config: <span style=\"color: white;\">$!</span></span>";    
          print $fh "difficulty:$strat_gen_difficulty";
        close $fh;

        $msg = "<span style=\"color: orange;\">Strat gen feature not yet implemented</span>";

        
        # write statistics
        Statistics::IncrementStatistics(DBFILE, 'total_strats_generated');


      } else {
        $msg = "<span style=\"color: red;\">Please enter a valid difficulty number</span>";
      }


    } else {

      # show the strat gen form
      my $form_new_strat_template = HTML::Template->new(
        filename => "../general/strat-gen/new_strat.tmpl",
      );
      $form_new_strat = $form_new_strat_template->output();
    }
  }

  # get main template
  my $template = HTML::Template->new(
    filename => "../general/strat-gen/strat-gen.tmpl",
  );

  # get form default output and set form default vars
  $form_default_template->param(
    MSG => $msg,
  );
  $form_default = $form_default_template->output();

  # set main template vars
  $template->param(
    FORM_DEFAULT => $form_default,
    FORM_NEW_STRAT => $form_new_strat,
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
