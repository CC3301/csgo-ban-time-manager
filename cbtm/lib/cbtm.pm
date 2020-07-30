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

# vac manager prefix
prefix '/vacmanager' => sub {

    # vac manager default page
    get '/vacmanager' => require_role user => sub {

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
    get '/add_suspect' => require_role user => sub {

        # get information
        my $user   = logged_in_user();
        my $time   = localtime(time());
        my $params = request->params();
        print Dumper($params);
        my $status = 'Failed';
        my $statuscolor = undef;

        # determine what color the status has to be
        if ($status eq 'Success') {
            $statuscolor = '--green';
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
        };
    };

    # actually save the suspect to the database after collecting data from steam API
    post '/save_suspect' => require_role user => sub {

        # get information
        my $params = request->params();
        my $status = 'Failed';
        print Dumper($params);

        redirect '/vacmanager/add_suspect?status=' . $status;
    };


    # vac manager add suspect page
    get '/list_suspects' => require_role user => sub {

        # get information
        my $user = logged_in_user();
        my $time = localtime(time());

        # render the template
        template 'pages/vacmanager/list_suspects' => {
            'title'        => 'All VAC Suspects',
            'version'      => $VERSION,
            'sys_time'     => qq($time),
            'current_user' => $user->{name},
        };
    };
};


#=======================================================================================================================
# Cooldown manager page handler
#=======================================================================================================================

# vac manager default page
get '/cdmanager' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());

    # render the template
    template 'pages/cdmanager/cdmanager' => {
        'title'        => 'VAC Manager',
        'version'      => $VERSION,
        'sys_time'     => qq($time),
        'current_user' => $user->{name},
    };
};


#=======================================================================================================================
# do the perl thing
#=======================================================================================================================
true;
