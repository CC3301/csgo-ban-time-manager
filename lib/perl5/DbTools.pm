################################################################################
# DbTools package
################################################################################
package DbTools {

  ##############################################################################
  # load modules
  ##############################################################################
  use strict;
  use warnings;

  use Cwd;
  use DBI;

  ##############################################################################
  # CheckUserAuthState subroutine
  ##############################################################################
  sub CheckUserAuthState {

    # get data passed to the function
    my $dbfile = shift();
    my $session_id = shift();

    # return 0 if the session id is undefined
    unless (defined $session_id) {
      return 0;
    }

    # create new database handle
    my $dbh = DBI->connect("dbi:SQLite:$dbfile");
    my $query = "SELECT auth_state FROM users WHERE session_id = '$session_id';";
    $query = $dbh->prepare($query);
    $query->execute();

    if ($query->fetchrow_array()) {
      return 1;
    } else {
      return 0;
    }
  }

  ##############################################################################
  # CheckDBState subroutine
  ##############################################################################
  sub CheckDBState {

    # get data passed to the function
    my $dbfile = shift();
    my $session_id = shift();

    # check if the database file even exists
    if (-f $dbfile) {
      # check if the database is initialized
      # create a new database handle
      my $dbh = DBI->connect("dbi:SQLite:$dbfile");
      my $query = "
        SELECT init_state FROM application_data;
      ";
      $query = $dbh->prepare($query);
      $query->execute();

      if ($query->fetchrow_array()) {
        return 1;
      } else {
        return 0;
      }

    } else {
      return 0;
    }

  }

  ##############################################################################
  # AuthenticateUser subroutine
  ##############################################################################
  sub AuthenticateUser {

    # get data passed to the function
    my $dbfile = shift;
    my $username = shift;
    my $password = shift;
    my $session = shift;

    # create database handle
    my $dbh = DBI->connect("dbi:SQLite:$dbfile");
    my $query = undef;

    # get the password
    $query = "SELECT password FROM users WHERE username = '$username';";
    $query = $dbh->prepare($query);
    $query->execute();

    if ($query->fetchrow_array() eq $password) {

      # get a session id
      my $session_id = $session->id();

      # update the users session id so that the auth state can be checked
      $query = "
        UPDATE users SET
        auth_state = 1,
        session_id = '$session_id'
        WHERE username = '$username';
      ";
      $query = $dbh->prepare($query);
      $query->execute();

      return $session_id;

    } else {
      return 0;
    }

  }

  ##############################################################################
  # CheckDoubleUsername subroutine
  ##############################################################################
  sub CheckDoubleUsername {

    # get the username to check
    my $dbfile = shift();
    my $username = shift();

    # create the database handle
    my $dbh = DBI->connect("dbi:SQLite:$dbfile");
    my $query = "
      SELECT 1 FROM users WHERE username = '$username';
    ";
    $query = $dbh->prepare($query);
    $query->execute();

    if ($query->fetchrow_array()) {
      return 0;
    } else {
      return 1;
    }
  }

  ##############################################################################
  # RegisterUser subroutine
  ##############################################################################
  sub RegisterUser {

    # get data passed to the function
    my $dbfile = shift();
    my $username = shift();
    my $password = shift();

    # create the database handle
    my $dbh = DBI->connect("dbi:SQLite:$dbfile");
    my $query = "
      INSERT INTO users (
        username,
        password,
        session_id,
        auth_state
      ) VALUES (
        '$username',
        '$password',
        0,
        0
      );
    ";
    $query = $dbh->prepare($query);
    eval {
      $query->execute();
    };
    if ($@) {
      return 0;
    } else {
      return 1;
    }
  }

  ##############################################################################
  # GetUserNameBySessionID subroutine
  ##############################################################################
  sub GetUserNameBySessionID {

    # get data passed to function
    my $dbfile = shift();
    my $session_id = shift();

    # create db handle
    my $dbh = DBI->connect("dbi:SQLite:$dbfile");
    my $query = "SELECT username FROM users WHERE session_id = '$session_id';";
    $query = $dbh->prepare($query);
    $query->execute();

    # return the Username
    return $query->fetchrow_array();

  }

  ##############################################################################
  # LogOutUser subroutine
  ##############################################################################
  sub LogOutUser {

    # get data passed to function
    my $dbfile = shift();
    my $session_id = shift();

    # create the database handle
    my $dbh = DBI->connect("dbi:SQLite:$dbfile");
    my $query = "
      UPDATE users SET
        auth_state = 0,
        session_id = 0
      WHERE session_id = '$session_id';
    ";
    $query = $dbh->prepare($query);
    $query->execute();

    # return something
    return 1;

  }


  ##############################################################################
  # Perl needs this
  ##############################################################################
  1;

}
