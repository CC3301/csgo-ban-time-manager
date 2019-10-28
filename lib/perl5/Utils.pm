################################################################################
# Utils package
################################################################################
package Utils {

  ##############################################################################
  # load modules
  ##############################################################################
  use strict;
  use warnings;

  use Cwd;
  use CGI;
  use HTML::Template;

  # own modules and library
  use lib getcwd();
  use DbTools;

  ##############################################################################
  # PageInit subroutine
  ##############################################################################
  sub PageInit {

    # get data passed to this function
    my $cgi = shift();
    my $session_id = shift();
    my $dbfile = shift();
    my $skip_auth = shift() || 0;
    my $login_link = shift() || "../login/index.pl?action=login";

    # check if the database is initialized
    unless (DbTools::CheckDBState($dbfile)) {
      ErrorPage(
        message => "Database not initialized",
        link => "../pages/setup/index.pl",
        link_desc => "Run setup",
      );
    }

    # check if the current session id is authenticated
    unless (DbTools::CheckUserAuthState($dbfile, $session_id) || $skip_auth) {
      ErrorPage(
        message => "User not authenticated",
        link => $login_link,
        link_desc => "Login now",
      );
    }
  }

  ##############################################################################
  # ErrorPage subroutine
  ##############################################################################
  sub ErrorPage {

    # html Template
    my $html = '
    <!DOCTYPE html>
    <html lang="en" dir="ltr">
      <head>
        <meta charset="utf-8">
        <title>Hell nah it\'s dead</title>
        <style media="screen">
          body {
            background-color: #1d2021;
          }
          main {
            text-align: center;
            color: darkgrey;
            margin-top: 100px;
          }
          h1 {
            font-size: 100px;
          }
          p {
            font-size: 50px;
          }
        </style>
      </head>
      <body>
        <main>
          <h1>Oops.. something went wrong</h1>
          <p>
            <TMPL_VAR NAME=ERR_MSG> </br>
          </p>
          <a href=<TMPL_VAR NAME=ERR_LINK>><TMPL_VAR NAME=ERR_LINK_DESC></a>
        </main>
      </body>
    </html>
    ';

    # get data passed to function
    my %args = @_;

    # create a new cgi object
    my $cgi = new CGI;

    # get the error template loaded
    my $template = HTML::Template->new(
      scalarref => \$html,
    );

    # set vars in the error Template
    $template->param(
      ERR_LINK => $args{link},
      ERR_LINK_DESC => $args{link_desc},
      ERR_MSG => $args{message}
    );

    # print the error page
    print $cgi->header();
    print $template->output();

    # exit right here, the page calling page init should not be displayed
    exit();

  }

  ##############################################################################
  # NavBar subroutine
  ##############################################################################
  sub NavBar {

    # get data passed to function
    my %args = @_;

    # create a new html template
    my $template = HTML::Template->new(
      filename => $args{template_file},
    );

    # check for Admin User
    if ($args{display_user_name} eq "admin") {
      $args{show_admin} = "inherit";
    } else {
      $args{show_admin} = "none";
    }

    # replace template vars
    $template->param(
      LINK_HOME => $args{link_home},
      LINK_ADMIN => $args{link_admin},
      LINK_LOGIN => $args{link_login},
      LINK_LOGOUT => $args{link_logout},
      LINK_STRAT_GEN => $args{link_strat_gen},
      LINK_VAC_MANAGER => $args{link_vac_manager},
      LINK_COOLDOWN_MANAGER => $args{link_cooldown_manager},
      DISPLAY_USER_NAME => $args{display_user_name},
      SHOW_ADMIN => $args{show_admin},
    );

    # return the output of the template
    return $template->output();

  }

  ##############################################################################
  # Footer subroutine
  ##############################################################################
  sub Footer {

    # get data passed to function
    my %args = @_;

    # create a new html template
    my $template = HTML::Template->new(
      filename => $args{template_file},
    );

    # get current localtime
    $args{display_current_date} = localtime(time());

    # replace template vars
    $template->param(
      DISPLAY_USER_NAME => $args{display_user_name},
      DISPLAY_CURRENT_DATE => $args{display_current_date},
      SHOW_USERNAME => $args{show_username},
    );

    # return the output of the template
    return $template->output();

  }

  ##############################################################################
  # perl needs this
  ##############################################################################
  1;
}
