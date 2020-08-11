
#=======================================================================================================================
# VacManager Page 
#=======================================================================================================================
package Pages::VacManager;


#=======================================================================================================================
# Import modules and extend the cbtm app
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


#=======================================================================================================================
# Global vars
#=======================================================================================================================
our $VERSION = '0.1';

my $dbfile = dirname(abs_path($0)) . '/../data/db.sqlite';
database({ driver => 'SQLite', database => $dbfile });


#=======================================================================================================================
# VAC manager page handler
#=======================================================================================================================

# vac manager default page
get '/vac_manager' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());

    # render the template
    template 'pages/vacmanager/vacmanager' => {
        'title'        => 'VAC Manager',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
    };
};


# vac manager add suspect page
get '/vac_add_suspect' => require_role user => sub {

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
    template 'pages/vacmanager/add_suspect' => {
        'title'        => 'Add VAC Suspect',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
        'status'       => $status,
        'statuscolor'  => $statuscolor,
    };
};

# actually save the suspect to the database after collecting data from steam API
post '/vac_save_suspect' => require_role user => sub {

    # get information
    my $params  = request->params();
    my $steam64 = $params->{steam_id64};
    my $status  = 'Failed';
    my ($query, $sth);

    # try to receive data from steam
    my %suspect_data = _get_suspect_data_from_steam($steam64);

    # check if there is valid data
    if (defined $suspect_data{avatar_url}) {
        $status = "Success";
        $query = "INSERT INTO vacs (steam_id64, steam_username, steam_ban_vac, steam_ban_game, steam_ban_trade,
                                    steam_ban_community, steam_avatar_url, steam_profile_visibility, steam_last_modified)
                                    VALUES ( '$steam64', '$suspect_data{profile_name}', '$suspect_data{ban_state}{vac}',
                                    '$suspect_data{ban_state}{game}', '$suspect_data{ban_state}{trade}',
                                    '$suspect_data{ban_state}{community}', '$suspect_data{avatar_url}',
                                    '$suspect_data{profile_visi}', '$suspect_data{last_mod}'
                                    );";
        $sth    = database->prepare($query);

        # check if we can execute the following query, if not try to update
        if ($sth->execute()) {
            $status = "Success";
        } else {
            $status = "Failed";
            $query = "
              UPDATE vacs SET
                steam_username = '$suspect_data{profile_name}',
                steam_ban_vac = '$suspect_data{ban_state}{vac}',
                steam_ban_game = '$suspect_data{ban_state}{game}',
                steam_ban_trade = '$suspect_data{ban_state}{trade}',
                steam_ban_community = '$suspect_data{ban_state}{community}',
                steam_avatar_url = '$suspect_data{avatar_url}',
                steam_profile_visibility = '$suspect_data{profile_visi}',
                steam_last_modified = '$suspect_data{last_mod}'
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
    redirect '/vac_add_suspect?status=' . $status;
};


# vac manager add suspect page
get '/vac_list_suspects' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());
    my %suspect_data = _get_suspect_data_from_db('vacs');

    # render the template
    template 'pages/vacmanager/list_suspects' => {
        'title'        => 'All VAC Suspects',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
        'suspects'     => \%suspect_data,
    };
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
