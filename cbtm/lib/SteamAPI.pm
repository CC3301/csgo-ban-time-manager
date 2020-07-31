################################################################################
# SteamAPI package
################################################################################
package SteamAPI {

  ##############################################################################
  # load modules
  ##############################################################################
  use strict;
  use warnings;
  use Cwd;
  use LWP::UserAgent;
  use JSON;
  use Data::Dumper;
  #use Carp::Always;

  # turn on request/response warnings in log
  # ATTENTION: Activating this will result in your steam api key to be shown in
  # the webservers log files.
  my $WARN = 1;

  # set the proxy
  my $PROXY = "";

  ##############################################################################
  # GetUserAvatarUrl subroutine
  ##############################################################################
  sub GetUserAvatarUrl {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_id64 = shift || die "Need steam id to get data from";
    my $steam_apk  = shift || die "Need steam api key to interact with steam api";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_api_url = 'http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/';

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send api request
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $response = _steam_api_request($steam_id64, $steam_api_url, $steam_apk);

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # return required value
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    return($response->{response}->{players}[0]->{avatarmedium});

  }

  ##############################################################################
  # GetUserProfileName subroutine
  ##############################################################################
  sub GetUserProfileName {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_id64 = shift || die "Need steam id to get data from";
    my $steam_apk  = shift || die "Need steam api key to interact with steam api";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_api_url = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send api request
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $response = _steam_api_request($steam_id64, $steam_api_url, $steam_apk);

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # return required value
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    return($response->{response}->{players}[0]->{personaname});

  }

  ##############################################################################
  # GetUserProfileVisibility subroutine
  ##############################################################################
  sub GetUserProfileVisibility {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_id64 = shift || die "Need steam id to get data from";
    my $steam_apk  = shift || die "Need steam api key to interact with steam api";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my %communityvisibilitystates = (
      1 => 'Private',
      2 => 'Friends Only',
      3 => 'Public',
    );
    my $steam_api_url = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send api request
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $response = _steam_api_request($steam_id64, $steam_api_url, $steam_apk);

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # convert data
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_profile_visibility = $communityvisibilitystates{$response->{response}->{players}[0]->{communityvisibilitystate}};

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # return required value
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    return($steam_profile_visibility);

  }

  ##############################################################################
  # GetUserBanState subroutine
  ##############################################################################
  sub GetUserBanState {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_id64 = shift || die "Need steam id to get data from";
    my $steam_apk  = shift || die "Need steam api key to interact with steam api";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_api_url = "http://api.steampowered.com/ISteamUser/GetPlayerBans/v1/";
    my %steam_ban_state;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send api request
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $response = _steam_api_request($steam_id64, $steam_api_url, $steam_apk);

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # convert data
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    $steam_ban_state{vac} = 0;
    $steam_ban_state{game} = 0;
    $steam_ban_state{trade} = 0;
    $steam_ban_state{community} = 0;

    if ( ! $response->{players}[0]->{NumberOfVACBans} == 0) {
      $steam_ban_state{vac} = $response->{players}[0]->{NumberOfVACBans};
      #$steam_ban_state{vac} = 1;
    }
    if ( ! $response->{players}[0]->{CommunityBanned} == 0) {
      $steam_ban_state{community} = 1;
    }
    if ( ! $response->{players}[0]->{EconomyBan} == 1) {
      $steam_ban_state{trade} = 1;
    }
    if ( ! $response->{players}[0]->{NumberOfGameBans} == 0) {
      $steam_ban_state{game} = 1;
    }

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # return required value
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    return(\%steam_ban_state);

  }

  ##############################################################################
  # _steam_api_request subroutine
  ##############################################################################
  sub _steam_api_request {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_id64    = shift || die "Need steam id to get data from";
    my $steam_api_url = shift;
    my $steam_api_key = shift;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send the request and set the proxy
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $request = "$steam_api_url?key=$steam_api_key&steamids=$steam_id64";
    my $user_agent = LWP::UserAgent->new(
      timeout => 10,
    );
    $user_agent->proxy(
      ['http'],
      $PROXY,
    );
    my $response = $user_agent->get($request);

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # check for success and then return
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if ($response->is_success()) {
      return (decode_json($response->decoded_content()));
    } else {
      #Utils::ErrorPage(
    #    message => "Steam API request timed out",
    #  );
    }
  }

  # perl needs this
  1;
}
