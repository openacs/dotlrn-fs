

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
	# Callback to get node_id from community
	# REVISIT this (ben)
	set node_id [site_node_id [ad_conn url]]

	# create the fs package instance (all in one, I've mounted it)
	set package_key [package_key]
	set package_id [site_node_mount_application -return package_id $node_id $package_key $package_key $package_key]

	# set up a forum inside that instance
	set folder_id [db_exec_plsql fs_root_folder "
	begin
        :1 := file_storage.new_root_folder(:package_id);
	end;"]
	
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

	# remove user permissions to see fs folders
	# nothing to do here
    }
	
}
