################################################################################
# Statistics package
################################################################################
package Statistics {

  ##############################################################################
  # load modules
  ##############################################################################
  use strict;
  use warnings;

  use Cwd;
  use DBI;

  ##############################################################################
  # GetStatistic subroutine
  ##############################################################################
  sub GetStatistic {

    # get data passed to function
    my $dbfile = shift();
    my $statistic = shift();

    # get the database handle
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

    # query the database
    my $query = "
      SELECT $statistic FROM statistics;
    ";
    $query = $dbh->prepare($query);
    $query->execute();
    while(my @row = $query->fetchrow_array()) {
      $statistic = join(", ", @row);
    }

    # return the statistic
    return($statistic);
    
  }

  ##############################################################################
  # Perl needs this
  ##############################################################################
  1;

}
