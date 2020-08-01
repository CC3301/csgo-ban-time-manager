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


#=======================================================================================================================
# Global vars
#=======================================================================================================================
our $VERSION = '0.1';


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
        $statuscolor = '--green';
    } elsif ($status eq "Updated") {
        $statuscolor = '--yellow';
    } else {
        $statuscolor = '--red';
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
# Cooldown manager page handler
#=======================================================================================================================
get '/cdmanager' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());

    # render the template
    template 'pages/cdmanager/cdmanager' => {
        'title'        => 'Generate random strategy',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
    };
};


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
        $statuscolor = '--green';
    } elsif ($status eq "Updated") {
        $statuscolor = '--yellow';
    } else {
        $statuscolor = '--red';
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
get '/cd_list_suspects' => require_role user => sub {

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
post '/cd_save_suspect' => require_role user => sub {

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
    redirect '/vac_add_suspect?status=' . $status;
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
get '/admin' => require_role admin => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());
    my $dbh  = database();
    my ($sth, $query, %database_data, $state);

    my $dbpath = Cwd::getcwd() . '/data/db.sqlite';

    # check if we need to initialize the database and if yes then render a different template
    if (_check_db_uninitialized()) {
        template 'pages/admin/setupdb' => {
            'title' => "Set up Database",
            'sys_time'     => qq($time),
            'current_user' => $user->{name},
        };
    } else {

        $database_data{old_steam_api_key} = _get_steam_api_key();

        # render template
        template 'pages/admin/admin' => {
            'title'        => 'VAC Manager',
            'version'      => $VERSION,
            'sys_time'     => qq($time),
            'current_user' => $user->{name},
            'old_steam_api_key' => $database_data{old_steam_api_key},
        };
    }
};

# save the new steam api key
post '/admin_save_steam_api_key' => require_role admin => sub {

    # get information
    my $params = request->params();
    my $steam_api_key = $params->{steam_api_key};
    my $sth;

    # save the steam api Key

    # try to read the steam api key from the database
    my $steam_apk = _get_steam_api_key();
    my $query     = undef;
    if (!$steam_apk eq '') {
        $query = "UPDATE config SET steam_api_key = '$steam_api_key';";
    } else {
        $query = "INSERT INTO config (steam_api_key) VALUES ('$steam_api_key');";
    }
    Utils::log("Running SQL query: $query");
    $sth = database->prepare($query);

    # internal server error if database query didnt work
    if ($sth->execute()) {
        redirect '/admin';
    } else {
        redirect '/500';
    }
};


# setup db should only be called if there is no database yet
post '/admin_setupdb' => require_role admin => sub {

    my $sth;

    # create the vacs table
    my $vacsquery = "
        CREATE TABLE vacs (
            steam_id64 INTEGER,
            steam_username VARCHAR,
            steam_ban_vac BOOLEAN,
            steam_ban_game BOOLEAN,
            steam_ban_trade BOOLEAN,
            steam_ban_community BOOLEAN,
            steam_avatar_url VARCHAR,
            steam_profile_visibility INTEGER,
            steam_last_modified VARCHAR,
            UNIQUE(steam_id64)
        );
    ";

    # create the cooldown table
    my $cdquery = "
        CREATE TABLE cooldowns (
            steam_id64 INTEGER,
            steam_username VARCHAR,
            steam_cooldown_time INTEGER,
            steam_cooldown_reason VARCHAR,
            steam_avatar_url VARCHAR,
            steam_profile_visibility INTEGER,
            steam_last_modified VARCHAR,
            UNIQUE(steam_id64)
        );
    ";

    # create statistics talbe
    my $statsquery = "
        CREATE TABLE statistics (
            cooldown_reason_team_kills_at_round_start INTEGER,
            cooldown_reason_team_kills INTEGER,
            cooldown_reason_team_damage INTEGER,
            cooldown_reason_rage_quit INTEGER,
            cooldown_reason_team_afk_timeout INTEGER,
            cooldown_type_30 INTEGER,
            cooldown_type_120 INTEGER,
            cooldown_type_1500 INTEGER,
            cooldown_type_10500 INTEGER,
            ban_vac INTEGER,
            ban_game INTEGER,
            ban_trade INTEGER,
            ban_community INTEGER,
            cooldown_time_total INTEGER,
            cooldown_users_total INTEGER,
            total_strats_generated INTEGER
        );
    ";

    # create users table
    my $usersquery = "
        CREATE TABLE users (
            username VARCHAR,
            password VARCHAR,
            roles VARCHAR,
            UNIQUE(username)
        );
    ";

    # create the config table
    my $cfgquery = "
        CREATE TABLE config (
            id INTEGER PRIMARY KEY,
            steam_api_key VARCHAR
        );
    ";

    # execute all querys
    Utils::log("Running SQL query: $vacsquery");
    $sth = database->prepare($vacsquery);
    $sth->execute();

    Utils::log("Running SQL query: $cdquery");
    $sth = database->prepare($cdquery);
    $sth->execute();

    Utils::log("Running SQL query: $statsquery");
    $sth = database->prepare($statsquery);
    $sth->execute();

    Utils::log("Running SQL query: $cfgquery");
    $sth = database->prepare($cfgquery);
    $sth->execute();

    redirect '/admin';

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

#=======================================================================================================================
# do the perl thing
#=======================================================================================================================
true;
