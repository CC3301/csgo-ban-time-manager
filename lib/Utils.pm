#=======================================================================================================================
# Utils Package
#=======================================================================================================================
package Utils;


#=======================================================================================================================
# import modules
#=======================================================================================================================
use strict;
use warnings;
use Utils::SteamAPI;
use Data::Dumper;


#=======================================================================================================================
# Log sub
#=======================================================================================================================
sub log($) {
    print("\n[" . localtime(time()) . ']: ' . shift() . "\n\n");
    return();
}


#=======================================================================================================================
# load the steam api key from the database
# returns a string
#=======================================================================================================================
sub get_steam_api_key($) {

    my $database = shift();

    my $query = "SELECT steam_api_key FROM config;";
    my $sth = $database->prepare($query);
    $sth->execute();

    my $steam_api_key = join('', $sth->fetchrow_array());
    chomp $steam_api_key;
    return($steam_api_key);
}


#=======================================================================================================================
# load a list of steam_id64 from the database
# returns an array
# needs the database table and the database object
#=======================================================================================================================
sub list_steam_ids($$) {

    my $database = shift();
    my $table = shift();

    my $query = "SELECT steam_id64 FROM '$table';";
    Utils::log("Running SQL query: $query");
    my $sth = $database->prepare($query); $sth->execute();
    my @steam_id64s = ();
    while (my $row = $sth->fetchrow_arrayref()) {
        push(@steam_id64s, @$row);
    }

    return(@steam_id64s);
}


#=======================================================================================================================
# load data for each suspect from the Database
# returns a hash
# needs the database table and the database object
#=======================================================================================================================
sub get_suspect_data_from_db($$) {

    my $database = shift();
    my $table = shift();
    my @steam_id64s = list_steam_ids($database, $table);
    Utils::log("Loading Suspect data from '$table' table");

    # get data of every suspect
    my %suspect_data = ();
    foreach my $id (@steam_id64s) {
        my $query = "SELECT * FROM '$table' WHERE steam_id64 = '$id'";
        my $sth = $database->prepare($query); $sth->execute();
        my $data = $sth->fetchrow_hashref();
        $suspect_data{$id} = $data;
    }

    return(%suspect_data);
}


#=======================================================================================================================
# get data from steam api
# returns a hash
# needs steam64 id and database object
#=======================================================================================================================
sub get_suspect_data_from_steam($$) {

    my $database      = shift();
    my $steam64       = shift();
    my $steam_api_key = get_steam_api_key($database);
    my %suspect_data  = ();

    # get data from steam
    $suspect_data{avatar_url}   = Utils::SteamAPI::GetUserAvatarUrl(        $steam64, $steam_api_key);
    $suspect_data{profile_name} = Utils::SteamAPI::GetUserProfileName(      $steam64, $steam_api_key);
    $suspect_data{profile_visi} = Utils::SteamAPI::GetUserProfileVisibility($steam64, $steam_api_key);
    $suspect_data{ban_state}    = Utils::SteamAPI::GetUserBanState(         $steam64, $steam_api_key);
    $suspect_data{last_mod}     = localtime(time());

    return(%suspect_data);
}


#=======================================================================================================================
# check if the database is initialized
# returns a boolean
# needs database object
#=======================================================================================================================
sub check_db_uninitialized($) {
    my $database = shift();
    my $query    = "SELECT * FROM config;";
    eval {
        $database->prepare($query)
    };
    if ($@) {
        Utils::log("Database not initialized. Requesting Initialization");
        return(1);
    } else {
        return(0);
    }
}


#=======================================================================================================================
# check if the database is initialized
# returns status and statustype
# needs status
#=======================================================================================================================
sub determine_status_facts($) {
    my $status = shift();
    my $statustype = undef;

    # choose what type of status needs to be returned
    if ($status eq 'Success') {
        $statustype = 'alert-success';
        $status     = 'Successfully added new Suspect';
    } elsif ($status eq "Updated") {
        $statustype = 'alert-info';
        $status     = 'Successfully updated Suspect';
    } else {
        $statustype = 'alert-danger';
        $status     = 'Failed to add or update Suspect';
    }

    return($status, $statustype);
}


1;
