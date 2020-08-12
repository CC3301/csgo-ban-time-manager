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
use File::Basename qw(dirname);
use Cwd qw(abs_path);

use Utils;
use Utils::SteamAPI;

use Pages::Admin;
use Pages::VacManager;
use Pages::CooldownManager;


#=======================================================================================================================
# Database setting
#=======================================================================================================================
database({ driver => 'SQLite', database => setting('dbfile') });


#=======================================================================================================================
# Index Page handler
#=======================================================================================================================
get '/' => require_role user => sub {

    # get information
    my $user = logged_in_user();
    my $time = localtime(time());

    # render the template
    template setting('frontend') . '/pages/index' => {
         'title'        => 'CSGO Ban Time Manager',
         'version'      => setting('version'),
         'sys_time'     => qq($time),
         'current_user' => $user->{username},
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
    template setting('frontend') . '/pages/stratgen/stratgen' => {
        'title'        => 'VAC Manager',
        'version'      => setting('version'),
        'sys_time'     => qq($time),
        'current_user' => $user->{username},
        'alert'        => 'hidden',
    };
};


#=======================================================================================================================
# do the perl thing
#=======================================================================================================================
true;
