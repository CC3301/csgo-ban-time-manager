##############################################################################
# SteamAPI package
##############################################################################
package SteamAPI {

  ##############################################################################
  # load modules
  ##############################################################################
  use strict;
  use warnings;
  use Cwd;
  use LWP::Simple;
  use JSON;
  use Data::Dumper;

  ##############################################################################
  # GetUserAvatarUrl subroutine
  ##############################################################################
  sub GetUserAvatarUrl {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_id64 = shift || die "Need steam id to get data from";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_api_url = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send api request
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $response = _steam_api_request($steam_id64, $steam_api_url);

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

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_api_url = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/";

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send api request
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $response = _steam_api_request($steam_id64, $steam_api_url);

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
    my $response = _steam_api_request($steam_id64, $steam_api_url);

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

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_api_url = "http://api.steampowered.com/ISteamUser/GetPlayerBans/v1/";
    my %steam_ban_state;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send api request
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $response = _steam_api_request($steam_id64, $steam_api_url);

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
    return(%steam_ban_state); 

  }

  ##############################################################################
  # _steam_api_request subroutine
  ##############################################################################
  sub _steam_api_request {

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get vars passed to function
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_id64 = shift || die "Need steam id to get data from";
    my $steam_api_url = shift;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # other vars
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $steam_api_key_file = getcwd() . "/../../../data/api_key.txt";
    my $steam_api_key = undef;
    
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # get the steam api key
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    open (my $fh, '<', $steam_api_key_file) or die "Failed to read steam api key";
      $steam_api_key = <$fh>;
    close $fh;
    chomp $steam_api_key;

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # send the request
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    my $request = "$steam_api_url?key=$steam_api_key&steamids=$steam_id64";
    my $response = get($request);
    $response = decode_json($response);

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # return the array ref for the response
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    return($response);

  }

  # perl needs this
  1;
}