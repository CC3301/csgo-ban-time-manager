$(document).ready(function(){

    // All forms are initially hidden except for the controls
    $('#form_modify_steam_api_key').hide();
    $('#form_add_del_user_account').hide();
    $('#form_debug_information').hide();

    // hide all forms including controls except for the debug information
    $("#button_debug_information").click(function(){
        $("#form_debug_information").toggle();
        $('#form_modify_steam_api_key').hide();
        $('#form_add_del_user_account').hide();
        $('#form_controls').hide();
    });

    // hide all forms including controls except for the account creation and deletion page
    $("#button_add_del_user_account").click(function(){
        $("#form_add_del_user_account").toggle();
        $('#form_modify_steam_api_key').hide();
        $('#form_debug_information').hide();
        $('#form_controls').hide();
    });

    // hide all forms including controls except for the steam api key modification page
    $("#button_modify_steam_api_key").click(function(){
        $("#form_modify_steam_api_key").toggle();
        $('#form_add_del_user_account').hide();
        $('#form_debug_information').hide();
        $('#form_controls').hide();
    });

    // hide all forms except for the controls
    $(".button_show_controls").click(function(){
        $('#form_controls').toggle();
        $("#form_modify_steam_api_key").hide();
        $('#form_add_del_user_account').hide();
        $('#form_debug_information').hide();
    });
});
