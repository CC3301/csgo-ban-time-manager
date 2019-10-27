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
  use experimental qw(declared_refs);

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
        link => "../pages/login/index.pl?action=login",
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
            background-color: #292935;
          }
          main {
            text-align: center;
            color: white;
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
  # perl needs this
  ##############################################################################
  1;
}
