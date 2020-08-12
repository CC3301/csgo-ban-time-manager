package Utils::AdminPage;

use strict;
use warnings;
use Utils;
use Data::Dumper;

sub check_duplicate_user($$) {
    my $database = shift();
    my $username = shift();
    my $query = "SELECT username FROM users;";
    my $sth = $database->prepare($query) or die($database->errstr);
    my @users = $sth->fetchrow_array();

    foreach my $user (@users) {
        if ($user eq $username) {
            return(1);
        }
    }
    return(0);

}

# lists all roles which are available
sub list_roles($) {
    my $database = shift();
    my $query = "SELECT * FROM roles;";
    my $sth = $database->prepare($query) or die($database->errstr);
    $sth->execute();
    my $roles = $sth->fetchall_hashref('id');
    return($roles);
}
1;
