#=======================================================================================================================
# Cooldown Manager Page 
#=======================================================================================================================
package Pages::CooldownManager;


#=======================================================================================================================
# Import modules
#=======================================================================================================================

# Dancer
use Dancer2 appname => 'cbtm';
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


#=======================================================================================================================
# Global vars
#=======================================================================================================================
our $VERSION = '0.1';

my $dbfile = dirname(abs_path($0)) . '/../data/db.sqlite';
database({ driver => 'SQLite', database => $dbfile });


#=======================================================================================================================
# Cooldown manager page handler
#=======================================================================================================================

# vac manager add suspect page
get '/cd_add_cooldown' => require_role user => sub {

    # get information
    my $user   = logged_in_user();
    my $time   = localtime(time());
    my $params = request->params();
    my $status = $params->{status};
    my $statuscolor = undef;

    # determine what color the status has to be
    if ($status eq 'Success') {
        $statuscolor = 'green';
    } elsif ($status eq "Updated") {
        $statuscolor = 'orange';
    } else {
        $statuscolor = 'red';
    }

    # render the template
    template 'pages/cdmanager/add_cooldown' => {
        'title'        => 'Add Cooldown',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
        'status'       => $status,
        'statuscolor'  => $statuscolor,
    };
};


# vac manager add suspect page
get '/cd_list_cooldowns' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());
    my %suspect_data = _get_suspect_data_from_db('cooldowns');

    # render the template
    template 'pages/cdmanager/list_cooldowns' => {
        'title'        => 'All Cooldowns',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
        'cooldowns'     => \%suspect_data,
    };
};

# actually save the suspect to the database after collecting data from steam API
post '/cd_save_cooldown' => require_role user => sub {

    # get information
    my $params    = request->params();
    my $steam64   = $params->{steam_id64};
    my $cd_time   = $params->{steam_cooldown_time};
    my $cd_reason = $params->{steam_cooldown_reason};
    my $status    = 'Failed';
    my ($query, $sth);

    # grab all suspect data from steam
    my %suspect_data = _get_suspect_data_from_steam($steam64);
    $suspect_data{cooldown}{time}   = $cd_time;
    $suspect_data{cooldown}{reason} = $cd_reason;

    # execute query and check if data was successfully received
    if (defined $suspect_data{avatar_url}) {

        $status = "Success";
        $query = "
            INSERT INTO cooldowns (
                steam_id64,
                steam_username,
                steam_cooldown_time,
                steam_cooldown_reason,
                steam_avatar_url,
                steam_profile_visibility,
                steam_last_modified
            ) VALUES (
                '$steam64',
                '$suspect_data{profile_name}',
                '$suspect_data{cooldown}{time}',
                '$suspect_data{cooldown}{reason}',
                '$suspect_data{avatar_url}',
                '$suspect_data{profile_visi}',
                '$suspect_data{last_mod}'
            );
        ";
        $sth    = database->prepare($query);

        # check if we can execute the following query, if not try to update
        if ($sth->execute()) {
            $status = "Success";
        } else {
            $status = "Failed";
            $query = "
                UPDATE cooldowns SET
                    steam_username           = '$suspect_data{profile_name}',
                    steam_cooldown_time      = '$suspect_data{cooldown}{time}',
                    steam_cooldown_reason    = '$suspect_data{cooldown}{reason}',
                    steam_avatar_url         = '$suspect_data{avatar_url}',
                    steam_profile_visibility = '$suspect_data{profile_visi}',
                    steam_last_modified      = '$suspect_data{last_mod}'
                WHERE steam_id64 = '$steam64';
            ";
            $sth = database->prepare($query);
            if ($sth->execute()) {
                $status = "Updated";
            } else {
                $status = "Failed";
            }
        }
    } else {
        $status = "Failed";
    }

    # redirect back to the add page to show if it was successful or if it failed
    redirect '/cd_add_cooldown?status=' . $status;
};

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

1;
