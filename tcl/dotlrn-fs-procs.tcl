

#
# Procs for DOTLRN fs Applet
# Copyright 2001 OpenForce, inc.
# Distributed under the GNU GPL v2
#
# October 5th, 2001
#

ad_library {
    
    Procs to set up the dotLRN fs applet
    
    @author ben@openforce.net,arjun@openforce.net
    @creation-date 2001-10-05
    
}

namespace eval dotlrn_fs {
    
    ad_proc -public package_key {
    } {
	get the package_key this applet deals with
    } {
	return "file-storage"
    }

    ad_proc portal_element_key {
    } {
	return the portal element key
    } {
	return "fs-portlet"
    }

    ad_proc -public get_pretty_name {
    } {
	returns the pretty name
    } {
	return "dotLRN File Storage"
    }

    ad_proc -public add_applet {
	community_id
    } {
	Add the fs applet
    } {
	set user_id [ad_conn user_id]
	set ip [ns_conn peeraddr]

	# create the calendar package instance (all in one, I've mounted it)
	set package_key [package_key]
	set package_id [dotlrn::instantiate_and_mount $community_id $package_key]

	# set up a forum inside that instance
	set folder_id [db_exec_plsql fs_root_folder "
	begin
        :1 := file_storage.new_root_folder(:package_id);
	end;"]

	# Set up public folder
	set public_folder_id [db_exec_plsql fs_public_folder "
	begin
	:1 := file_storage.new_folder (
	name => 'public',
	folder_name => 'Public',
	parent_id => :folder_id,
	creation_user => :user_id,
	creation_ip => :ip);
	end;"]

	# FIXME: Set up permissions on this folder
	
	# non-member page stuff
	# Get non member page_id
	set non_member_page_id [dotlrn_community::get_community_non_members_page_id $community_id]
	
	# Make file storage available public-folder only at community non-member page
	fs_portlet::add_self_to_page $non_member_page_id $package_id $public_folder_id

	# portal template stuff 
	# get the portal_template_id by callback
	set pt_id [dotlrn_community::get_portal_template_id $community_id]

	# set up the DS for the portal template
	fs_portlet::make_self_available $pt_id
	fs_portlet::add_self_to_page $pt_id $package_id

	# return the package_id
	return $package_id
    }

    ad_proc -public remove_applet {
	community_id
	package_id
    } {
	remove the applet from the community
    } {
	# Remove all instances of the fs portlet! (this is some serious stuff!)

	# Dropping all messages, forums

	# Killing the package
    
    }

    ad_proc -private get_public_folder_id {
	package_id
	parent_folder_id
    } {
	get the folder_id for the public folder
    } {
	return [db_string select_folder_id {} -default ""]
    }    

    ad_proc -public add_user {
	community_id
	user_id
    } {
	Add a user to a community
    } {
	# Get the page_id by callback
	set page_id [dotlrn_community::get_page_id $community_id $user_id]
	
	# Get the package_id by callback
	set package_id [dotlrn_community::get_applet_package_id $community_id dotlrn_fs]

	# Allow user to see the fs folders
	# nothing for now

	# Call the portal element to be added correctly
	# fs portlet needs folder_id too
	set folder_id [fs_get_root_folder -package_id $package_id]

	# Make file storage available at community-user page level
	fs_portlet::add_self_to_page $page_id $package_id $folder_id
    }

    ad_proc -public remove_user {
	community_id
	user_id
    } {
	Remove a user from a community
    } {
	# Get the page_id
	set page_id [dotlrn_community::get_page_id $community_id $user_id]
	
	# Get the package_id by callback
	set package_id [dotlrn_community::get_package_id $community_id]

	# Remove the portal element
	fs_portlet::remove_self_from_page $page_id $package_id

	# Buh Bye.
	fs_portlet::make_self_unavailable $page_id

	# remove user permissions to see fs folders
	# nothing to do here
    }
	
}
