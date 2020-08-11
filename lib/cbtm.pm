#=======================================================================================================================
# cbtm package
#=======================================================================================================================
package cbtm;


#=======================================================================================================================
# Import modules
#=======================================================================================================================

# Dancer
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;

# other
use Data::Dumper;
use SteamAPI;
use Utils;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

use Pages::Admin;
use Pages::VacManager;
use Pages::CooldownManager;


#=======================================================================================================================
# Global vars
#=======================================================================================================================
our $VERSION = '0.1';

my $dbfile = dirname(abs_path($0)) . '/../data/db.sqlite';
database({ driver => 'SQLite', database => $dbfile });
Utils::log($dbfile);


#=======================================================================================================================
# Index Page handler
#=======================================================================================================================
get '/' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());

    # render the template
    template 'pages/index' => {
         'title'        => 'CSGO Ban Time Manager',
         'version'      => $VERSION,
         'sys_time'     => qq($time),
         'current_user' => $user->{name},
    };
};





#=======================================================================================================================
# Strategy generator page handler
#=======================================================================================================================

# stratgen manager default page
get '/stratgen' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());

    # render the template
    template 'pages/stratgen/stratgen' => {
        'title'        => 'VAC Manager',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
    };
};


#=======================================================================================================================
# Admin Page stuff
#=======================================================================================================================


#=======================================================================================================================
# useful subroutines
#=======================================================================================================================

# load a list of steam_id64 from the database
# returns an array
# needs the database table
sub _list_steam_ids($) {

    my $table = shift();

    my $query = "SELECT steam_id64 FROM '$table';";
    Utils::log("Running SQL query: $query");
    my $sth = database->prepare($query); $sth->execute();
    my @steam_id64s = ();
    while (my $row = $sth->fetchrow_arrayref()) {
        push(@steam_id64s, @$row);
    }

    return(@steam_id64s);
}

# load the steam api key from the database
# returns a string
sub _get_steam_api_key() {

    my $query = "SELECT steam_api_key FROM config;";
    my $sth = database->prepare($query);
    $sth->execute();

    my $steam_api_key = join('', $sth->fetchrow_array());
    chomp $steam_api_key;
    Utils::log(Dumper($steam_api_key));
    return($steam_api_key);
}

# load data for each suspect from the Database
# returns a hash
# needs the database table
sub _get_suspect_data_from_db($) {

    my $table = shift();
    my @steam_id64s = _list_steam_ids($table);
    Utils::log("Loading Suspect data from '$table' table");

    # get data of every suspect
    my %suspect_data = ();
    foreach my $id (@steam_id64s) {
        my $query = "SELECT * FROM '$table' WHERE steam_id64 = '$id'";
        my $sth = database->prepare($query); $sth->execute();
        my $data = $sth->fetchrow_hashref();
        $suspect_data{$id} = $data;
    }

    return(%suspect_data);
}

# get data from steam api
# returns a hash
# needs steam64 id
sub _get_suspect_data_from_steam() {
    my $steam64       = shift();
    my $steam_api_key = _get_steam_api_key();
    my %suspect_data  = ();

    # get data from steam
    $suspect_data{avatar_url}   = SteamAPI::GetUserAvatarUrl(        $steam64, $steam_api_key);
    $suspect_data{profile_name} = SteamAPI::GetUserProfileName(      $steam64, $steam_api_key);
    $suspect_data{profile_visi} = SteamAPI::GetUserProfileVisibility($steam64, $steam_api_key);
    $suspect_data{ban_state}    = SteamAPI::GetUserBanState(         $steam64, $steam_api_key);
    $suspect_data{last_mod}     = localtime(time());

    return(%suspect_data);
}

# check if the database is initialized
# returns a boolean
sub _check_db_uninitialized() {
    my $query = "SELECT * FROM config;";
    my $sth = database->prepare($query) or return(1);
    return(0);
}

#=======================================================================================================================
# do the perl thing
#=======================================================================================================================
true;
