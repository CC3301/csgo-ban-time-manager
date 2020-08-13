#=======================================================================================================================
# most used database queries related to the config database packed into neat functions, DbConf package
#=======================================================================================================================
package Utils::DbConf;


#=======================================================================================================================
# import modules
#=======================================================================================================================
use strict;
use warnings;


#=======================================================================================================================
# update proxy
# needs database and proxy args
# returns true on success and undef on failure
#=======================================================================================================================
sub update_proxy($$) {
    my $database   = shift();
    my $proxy_addr = shift();

    # make sure we get what we need
    if (! defined $database ) { return(undef); }

    # check what we need to do
    my $query = "UPDATE config SET outgoing_proxy = '$proxy_addr';";
    my $sth   = $database->prepare($query) || return(undef);
    eval {
        $sth->execute();
    };
    if ($@) {
        return(undef);
    } else {
        return(1);
    }
}


#=======================================================================================================================
# get proxy
# needs database
# returns current proxy string, empty string when proxy string in db is 'NULL'
# returns environment proxy on failure
#=======================================================================================================================
sub get_proxy($) {
    my $database = shift();

    # make sure we get what we need
    if (! defined $database ) { return(undef); }

    # pull the data from the database
    my $query = "SELECT outgoing_proxy FROM config;";
    my $sth   = $database->prepare($query) or return($ENV{'http_proxy'});
    eval {
        $sth->execute();
    };
    if ($@) {
        return($ENV{'http_proxy'});
    } else {
        my @proxy = ();
        eval {
            @proxy = $sth->fetchrow_array();
        };
        if ($@) {
            return($ENV{'http_proxy'});
        } else {
            if ($proxy[0] eq 'NULL') {
                return("");
            } else {
                return($proxy[0]);    
            }
        }
    }
}
1;
