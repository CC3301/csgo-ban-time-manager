#=======================================================================================================================
# Admin Page
#=======================================================================================================================
package Pages::Admin;


#=======================================================================================================================
# Import modules, extend the cbtm package
#=======================================================================================================================
use Dancer2 appname => 'cbtm';
use Dancer2::Plugin::Auth::Extensible;
use Dancer2::Plugin::Database;

# other
use Data::Dumper;
use Utils::SteamAPI;
use Utils::AdminPage;
use Utils::DbConf;
use Utils;
use File::Basename qw(dirname);
use Cwd qw(abs_path realpath);
use FindBin;


#=======================================================================================================================
# Database setting
#=======================================================================================================================
database({ driver => 'SQLite', database => setting('dbfile') });
my $appdir = realpath("$FindBin::Bin/..");


#=======================================================================================================================
# Main Admin Page
#=======================================================================================================================
get '/admin' => require_role admin => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());
    my $params = request->params();
    my %database_data = ();
    my $toast = undef;

    # check if we need to make a toast
    if (exists $params->{status} && exists $params->{statustext}) {
        my ($status, $statustype) = Utils::determine_status_facts($params->{status});
        $toast = template setting('frontend') . '/toast' => {
            'layout' => 'toast',
            'alert_text'  => $params->{statustext},
            'alert_time'  => qq($time),
            'alert_title' => 'Admin',
            'alert_type'  => $statustype,
        };
    }

    # check if we need to initialize the database and if yes then render a different template
    if (Utils::check_db_uninitialized(database)) {
        template setting('frontend') . '/pages/setupdb' => {
            'title' => "Set up Database",
            'sys_time'     => qq($time),
            'current_user' => $user->{username},
        };
    } else {

        $database_data{old_steam_api_key}      = Utils::get_steam_api_key(database);
        $database_data{user_roles}             = Utils::AdminPage::list_roles(database);
        $database_data{current_outgoing_proxy} = Utils::DbConf::get_proxy(database);

        # render template
        template setting('frontend') . '/pages/admin/admin' => {
            'title'        => 'VAC Manager',
            'version'      => setting('version'),
            'sys_time'     => qq($time),
            'current_user' => $user->{username},
            'toast'        => $toast,
            'old_steam_api_key' => $database_data{old_steam_api_key},
            'user_roles' => Utils::AdminPage::list_roles(database),
        };
    }
};


#=======================================================================================================================
# save a new user
#=======================================================================================================================
post '/admin_save_user_new_user' => require_role admin => sub {

    my $params = request->params();
    my $query = undef;
    my %sths = ();

    Utils::log(Data::Dumper::Dumper($params));

    if (exists $params->{new_user_username} && exists $params->{new_user_password} && exists $params->{new_user_roles}) {

        # check if the user with this username already exists
        if (Utils::AdminPage::check_duplicate_user(database, $params->{username})) {
            redirect '/admin?status=Failed&statustext=Failed to add user: A user with this username already exists';
        } else {
            $query = "INSERT INTO users (username, password) VALUES ($params->{new_user_username}, $params->{new_user_password})";
            $sths{user_table_insertion} = database->prepare($query) or redirect '/admin?status=Failed&statustext=Failed to add user';

            my $user_id = Utils::AdminPage::get_userid_by_username(database, $params->{username});

            foreach my $role (split(',', $params->{new_user_roles})) {
                $query = "INSERT INTO user_roles (user_id, role_id) VALUES ($user_id, $role);";
                $sths{'role'.$role} = database->prepare($query) or redirect '/admin?status=Failed&statustext=Failed to save role data for new user';
            }

            # if we get here, all queries were successfully prepared. Now execute them in bulk
            foreach my $key (keys %sths) {
                $sths{$key}->execute();
            }

            redirect '/admin?status=Success&statustext=User ' . $params->{username} . ' added.';

        }

    } else {
        redirect '/admin?status=Failed&statustext=Failed to add user: missing parameters';
    }

};


#=======================================================================================================================
# save the new steam api key
#=======================================================================================================================
post '/admin_save_steam_api_key' => require_role admin => sub {

    # get information
    my $params = request->params();
    my $steam_api_key = $params->{steam_api_key};
    my $sth;
    my $update_flag = undef;


    # try to read the steam api key from the database
    my $steam_apk = Utils::get_steam_api_key(database);
    my $query     = undef;
    if (!$steam_apk eq '') {
        $update_flag = 1;
        $query = "UPDATE config SET steam_api_key = '$steam_api_key';";
    } else {
        $query = "INSERT INTO config (steam_api_key) VALUES ('$steam_api_key');";
    }
    Utils::log("Running SQL query: $query");
    $sth = database->prepare($query);

    # internal server error if database query didn't work
    if ($sth->execute()) {
        if (defined $update_flag) {
            redirect '/admin?status=Updated&statustext=Successfully updated SteamAPI-Key';
        } else {
            redirect '/admin?status=Success&statustext=Successfully added SteamAPI-Key';
        }
    } else {
        redirect '/admin?status=Failed&statustext=Failed to add/update SteamAPI-Key';
    }
};

# export the Database
get  '/admin_export_db' => require_role admin => sub {
    my $dbfile = $appdir . "/" . setting('dbfile');
    Utils::log($dbfile);
    send_file($dbfile, system_path => 1, filename => "dbexport_" . time() . ".sqlite");
};

#=======================================================================================================================
# set proxy routine
#=======================================================================================================================
post '/admin_save_proxy' => require_role admin => sub {

    my $params = request->params();
    if ($params->{proxy_addr} eq "") {
        $params->{proxy_addr} = 'NULL';
    }

    if (Utils::DbConf::update_proxy(database, $params->{proxy_addr})) {
        redirect '/admin?status=Updated&statustext=Successfully updated/changed proxy settings';
    } else {
        redirect '/admin?status=Failed&statustext=Failed to update/change proxy settings';
    }

};


#=======================================================================================================================
# setup database routine
#=======================================================================================================================
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
            steam_first_added VARCHAR,
            steam_first_banned VARCHAR,
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
            steam_first_added VARCHAR,
            UNIQUE(steam_id64)
        );
    ";

    # create statistics table
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
    my $smurfsquery = "
        CREATE TABLE smurfs (
            steam_username VARCHAR,
            steam_password VARCHAR,
            email VARCHAR,
            email_password VARCHAR,
            steam_guard BOOLEAN,
            UNIQUE(steam_username)
        );
    ";

    # create the config table
    my $cfgquery = "
        CREATE TABLE config (
            id INTEGER PRIMARY KEY,
            steam_api_key VARCHAR,
            outgoing_proxy VARCHAR
        );
    ";

    # execute all queries
    $sth = database->prepare($vacsquery);
    $sth->execute() or redirect '/admin?status=Failed&statustext=Failed to initialize database';

    $sth = database->prepare($cdquery);
    $sth->execute() or redirect '/admin?status=Failed&statustext=Failed to initialize database';

    $sth = database->prepare($statsquery);
    $sth->execute() or redirect '/admin?status=Failed&statustext=Failed to initialize database';

    $sth = database->prepare($smurfsquery);
    $sth->execute() or redirect '/admin?status=Failed&statustext=Failed to initialize database';

    $sth = database->prepare($cfgquery);
    $sth->execute() or redirect '/admin?status=Failed&statustext=Failed to initialize database';

    redirect '/admin?status=Success&statustext=Initialized Database';

};

post '/admin_git_update' => require_role admin => sub {

    my $command = "cd " . $appdir . "; git pull";
    system($command);

    redirect '/admin?status=Success&statustext=Updated to latest version';

};
1;
