##############################################################################
# DbTools package
##############################################################################
package DbTools {

  ##############################################################################
  # load modules
  ##############################################################################
  use strict;
  use warnings;
  use DBI;
  use Cwd;

  ##############################################################################
  # IncrementStatistics subroutine
  ##############################################################################
  sub IncrementStatistics {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $dbfile = shift;
    my $statistic = shift || die "Invalid function call for statistics increment";
    my $value = shift;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $old_value = undef;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # create the database handle
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    unless( -r $dbfile && -w $dbfile ) {
      die("Failed to acces database: permission denied or file does not exist");
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # we need to handle the total cooldown statistic a bit differently
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if ($statistic eq 'cooldown_time_total') {
      
      # check if we even got a value to add
      unless(defined $value) {
        die "Invalid function call for statistics increment";
      }
      if ($value eq '') {
        die "Invalid function call for statistics increment";
      }

      # get old cooldowntime
      my $query = "
        SELECT cooldown_time_total FROM statistics;
      ";
      $query = $dbh->prepare($query);
      $query->execute();
      while(my @row = $query->fetchrow_array()) {
        $old_value = join(", ", @row);
      }
      $value = $value + $old_value;
      $query = "
        UPDATE statistics SET cooldown_time_total = '$value';
      ";
      $query = $dbh->prepare($query);
      $query->execute();

      #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      # return and clear the query
      #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      $dbh->disconnect();
      $query = undef;
      return();

    }

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # increment the statistic
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # query the database for the old value of that statistic
    my $query = "
      SELECT $statistic FROM statistics;
    ";
    $query = $dbh->prepare($query);
    $query->execute();

    # get the previous data
    while (my @row = $query->fetchrow_array) {
      $old_value = join(", ", @row);
    }

    # increment that statistic by one
    $old_value++;

    # write back to the database
    $query = "
      UPDATE statistics SET $statistic = '$old_value';
    ";
    $query = $dbh->prepare($query);
    $query->execute();

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # return and clear the query
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    $dbh->disconnect();
    $query = undef;
    return();

  }

  ##############################################################################
  # CheckDoubleSteamID subroutine
  ##############################################################################
  sub CheckDoubleSteamID {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $dbh = shift;
    my $steam_id64 = shift;
    my $table = shift;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my @ids = ();
    my $query = undef;
    my $return = 0;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # check for the steam_id64 in the database
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    $query = "
      SELECT steam_id64 FROM $table;
    ";
    $query = $dbh->prepare($query);
    $query->execute();

    # get all the ids
    while(my @row = $query->fetchrow_array()) {
      push @ids, join(", ", @row);
    }

    # check if we find a matching id
    foreach (@ids) {
      if ($_ == $steam_id64) {
        $return = 1;
      }
    }  

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # return either true or false
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    return($return);

  }

  ##############################################################################
  # GetStatistic subroutine
  ##############################################################################
  sub GetStatistic {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $dbfile = shift;
    my $statistic = shift || die "Invalid function call for statistics increment";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # create the database handle
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    unless( -r $dbfile) {
      die("Failed to acces database: permission denied or file does not exist");
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "");

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # query the database
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $query = "
      SELECT $statistic FROM statistics;
    ";
    $query = $dbh->prepare($query);
    $query->execute();
    while(my @row = $query->fetchrow_array()) {
      $statistic = join(", ", @row);
    }

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # return either true or false
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    return($statistic);

  }

  # perl needs this
  1;
}