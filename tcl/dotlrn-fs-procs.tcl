#
#  Copyright (C) 2001, 2002 OpenForce, Inc.
#
#  This file is part of dotLRN.
#
#  dotLRN is free software; you can redistribute it and/or modify it under the
#  terms of the GNU General Public License as published by the Free Software
#  Foundation; either version 2 of the License, or (at your option) any later
#  version.
#
#  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#

ad_library {

    Procs to set up the dotLRN file storage applet

    @author Ben Adida (ben@openforce.net)
    @author iArjun Sanyal (arjun@openforce.net)
    @version $Id$

}

namespace eval dotlrn_fs {

    ad_proc -public applet_key {
    } {
        What's my key?
    } {
        return dotlrn_fs
    }

    ad_proc -public package_key {
    } {
        What package do I deal with?
    } {
        return "file-storage"
    }

    ad_proc -public my_package_key {
    } {
        What's my package_key?
    } {
        return "dotlrn-fs"
    }

    ad_proc -public get_pretty_name {
    } {
        returns the pretty name
    } {
        return "File Storage"
    }

    ad_proc -public add_applet {
    } {
        Used for one-time init - must be repeatable!
    } {
        if {![dotlrn::is_package_mounted -package_key [package_key]]} {
            set package_id [dotlrn::mount_package \
                -package_key [package_key] \
                -url [package_key] \
                -directory_p t]

            # create the root folder for this instance
            set folder_id [fs::new_root_folder \
                -package_id $package_id \
                -pretty_name "User Folders" \
                -description "User Folders" \
            ]

            portal::mapping::new \
                -object_id $folder_id \
                -node_id [site_nodes::get_node_id_from_package_id -package_id $package_id]

            set party_id [acs_magic_object registered_users]
            permission::grant -party_id $party_id -object_id $folder_id -privilege read
            permission::revoke -party_id $party_id -object_id $folder_id -privilege write
            permission::revoke -party_id $party_id -object_id $folder_id -privilege admin

            set party_id [acs_magic_object the_public]
            permission::revoke -party_id $party_id -object_id $folder_id -privilege read
            permission::revoke -party_id $party_id -object_id $folder_id -privilege write
            permission::revoke -party_id $party_id -object_id $folder_id -privilege admin

            dotlrn_applet::add_applet_to_dotlrn -applet_key [applet_key]

            # Mount the package
            dotlrn_applet::mount -package_key [my_package_key] -url fs -pretty_name "File Storage"
        }
    }

    ad_proc -public remove_applet {
    } {
        remove the applet from dotlrn
    } {
        ad_return_complaint 1 "[applet_key] remove_applet not implimented!"
    }

    ad_proc -public add_applet_to_community {
        community_id
    } {
        Add the fs applet to a specifc dotlrn community
    } {
        set portal_id [dotlrn_community::get_portal_id -community_id $community_id]
        set package_id [dotlrn::instantiate_and_mount $community_id [package_key]]
        set community_name [dotlrn_community::get_community_name $community_id]

        # set up a forum inside that instance
        set folder_id [fs::new_root_folder \
            -package_id $package_id \
            -pretty_name "${community_name}'s Files" \
            -description "${community_name}'s Files" \
        ]

        set node_id [site_nodes::get_node_id_from_package_id -package_id $package_id]
        portal::mapping::new -object_id $folder_id -node_id $node_id

        set party_id [acs_magic_object registered_users]
        permission::revoke -party_id $party_id -object_id $folder_id -privilege read
        permission::revoke -party_id $party_id -object_id $folder_id -privilege write
        permission::revoke -party_id $party_id -object_id $folder_id -privilege admin

        set party_id [acs_magic_object the_public]
        permission::revoke -party_id $party_id -object_id $folder_id -privilege read
        permission::revoke -party_id $party_id -object_id $folder_id -privilege write
        permission::revoke -party_id $party_id -object_id $folder_id -privilege admin

        # Set up permissions on these folders
        # The root folder is available only to community members
        set members [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_member_rel \
        ]
        permission::grant -party_id $members -object_id $folder_id -privilege read
        # admins of this community can admin the folder
        set admins [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_admin_rel \
        ]
        permission::grant -party_id $admins -object_id $folder_id -privilege admin

        set root_community_type [dotlrn_community::get_toplevel_community_type_from_community_id \
                                     $community_id
        ]

        set folder_list [parameter::get_from_package_key \
                             -package_key [my_package_key] \
                             -parameter "${root_community_type}_default_folders"
        ]
        
        foreach folder [string trim [split $folder_list ',']] {
            set a_folder_id [fs::new_folder \
                -name $folder \
                -pretty_name $folder \
                -parent_id $folder_id]

            portal::mapping::new -object_id $a_folder_id -node_id $node_id
        }

        # Set up public folder
        set public_folder_id [fs::new_folder \
            -name public \
            -pretty_name "${community_name}'s Public Files" \
            -parent_id $folder_id \
        ]

        portal::mapping::new -object_id $public_folder_id -node_id $node_id

        # The public folder is available to all dotLRN Full Access Users
        set dotlrn_public [dotlrn::get_users_rel_segment_id]
        permission::grant -party_id $dotlrn_public -object_id $public_folder_id -privilege read

        #
        # portlet stuff
        #
        
        set args [ns_set create]
        ns_set put $args package_id $package_id
        ns_set put $args folder_id $folder_id
        ns_set put $args param_action overwrite

        add_portlet_helper $portal_id $args

        # non-member portal stuff
        set non_member_portal_id [dotlrn_community::get_non_member_portal_id \
                                      -community_id $community_id
        ]

        # Make public-folder the only one available at non-member page
        ns_set update $args package_id $package_id
        ns_set update $args folder_id $public_folder_id
        ns_set update $args force_region 2

        add_portlet_helper $non_member_portal_id $args

        return $package_id
    }

    ad_proc -public remove_applet_from_community {
        community_id
    } {
        remove the fs applet from a specifc dotlrn community
    } {
        ad_return_complaint 1 "[applet_key] remove_applet_from_community not implimented!"
    }

    ad_proc -public add_user {
        user_id
    } {
        One time user-specfic init
    } {
        # get the name of the user to stick in the folder name
        set user_name [db_string select_user_name {
            select first_names || ' ' || last_name
            from persons
            where person_id = :user_id
        }]

        # get the root folder of this package instance
        set package_id [site_nodes::get_child_package_id \
            -parent_package_id [dotlrn::get_package_id] \
            -package_key [package_key] \
        ]

        set root_folder_id [fs::get_root_folder -package_id $package_id]

        # does this user already have a root folder?
        set user_root_folder_id [fs::get_folder \
            -name [get_user_root_folder_name -user_id $user_id] \
            -parent_id $root_folder_id \
        ]

        set node_id [site_nodes::get_node_id_from_package_id -package_id $package_id]

        if {[empty_string_p $user_root_folder_id]} {

            # create the user's root folder
            set user_root_folder_id [fs::new_folder \
                -name [get_user_root_folder_name -user_id $user_id] \
                -parent_id $root_folder_id \
                -pretty_name "${user_name}'s Files" \
                -creation_user $user_id \
            ]

            portal::mapping::new -object_id $user_root_folder_id -node_id $node_id

            # set the permissions for this folder; only the user has access to it
            permission::set_not_inherit -object_id $user_root_folder_id
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege read
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege write
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege admin

        }

        # does this user already have a shared folder?
        set user_shared_folder_id [fs::get_folder \
            -name [get_user_shared_folder_name -user_id $user_id] \
            -parent_id $user_root_folder_id \
        ]

        if {[empty_string_p $user_shared_folder_id]} {

            # create the user's shared folder
            set user_shared_folder_id [fs::new_folder \
                -name [get_user_shared_folder_name -user_id $user_id] \
                -parent_id $user_root_folder_id \
                -pretty_name "${user_name}'s Shared Files" \
                -creation_user $user_id \
            ]

            portal::mapping::new -object_id $user_shared_folder_id -node_id $node_id

            # set the permissions for this folder
            permission::grant \
                -party_id [acs_magic_object the_public] \
                -object_id $user_shared_folder_id \
                -privilege read
        }

        #
        # portlet stuff
        #

        # get the user's portal
        set portal_id [dotlrn::get_portal_id_not_cached -user_id $user_id]

        set args [ns_set create]
        ns_set put $args package_id $package_id
        ns_set put $args folder_id $user_root_folder_id
        ns_set put $args param_action overwrite
        ns_set put $args extra_params [list scoped_p f contents_url "[get_url]all-objects"]

        add_portlet_helper $portal_id $args
    }

    ad_proc -public remove_user {
        user_id
    } {
    } {
        ad_return_complaint 1 "[applet_key] remove_user not implimented!"
    }

    ad_proc -public add_user_to_community {
        community_id
        user_id
    } {
        Add a user to a to a specifc dotlrn community
    } {
        # Get the package_id by callback
        set package_id [dotlrn_community::get_applet_package_id $community_id [applet_key]]
        set portal_id [dotlrn::get_portal_id -user_id $user_id]
        set folder_id [fs::get_root_folder -package_id $package_id]

        set args [ns_set create]
        ns_set put $args package_id $package_id
        ns_set put $args folder_id $folder_id
        ns_set put $args param_action append

        add_portlet_helper $portal_id $args
    }

    ad_proc -public remove_user_from_community {
        community_id
        user_id
    } {
        Remove a user from a community
    } {
        set package_id [dotlrn_community::get_applet_package_id $community_id [applet_key]]
        set portal_id [dotlrn::get_portal_id -user_id $user_id]
        set folder_id [fs::get_root_folder -package_id $package_id]

        set args [ns_set create]
        ns_set put $args package_id $package_id
        ns_set put $args folder_id $folder_id

        remove_portlet $portal_id $args
    }

    ad_proc -public add_portlet {
        portal_id
    } {
        A helper proc to add the underlying portlet to the given portal.

        @param portal_id
    } {
        set args [ns_set create]
        ns_set put $args folder_id 0
        ns_set put $args package_id 0
        ns_set put $args param_action overwrite

        set type [dotlrn::get_type_from_portal_id -portal_id $portal_id]
        
        if {[string equal $type user]} {
            # the user portal template 
            ns_set put $args page_name [get_user_default_page]
        }  elseif {[string equal $type dotlrn_community]} {
            # subcom template
            ns_set put $args page_name [get_subcomm_default_page]
        } else {
            # club or class template
            ns_set put $args page_name [get_community_default_page]
        }     

        add_portlet_helper $portal_id $args
    }

    ad_proc -public add_portlet_helper {
        portal_id
        args
    } {
        A helper proc to add the underlying portlet to the given portal.

        @param portal_id
        @param args an ns_set
    } {
        fs_portlet::add_self_to_page \
            -portal_id $portal_id \
            -package_id [ns_set get $args package_id] \
            -folder_id [ns_set get $args folder_id] \
            -page_name [ns_set get $args page_name] \
            -force_region [ns_set get $args force_region] \
            -param_action [ns_set get $args param_action] \
            -extra_params [ns_set get $args extra_params]
    }

    ad_proc -public remove_portlet {
        portal_id
        args
    } {
        A helper proc to remove the underlying portlet from the given portal. 
        
        @param portal_id
        @param args A list of key-value pairs (possibly user_id, community_id, and more)
    } { 
        fs_portlet::remove_self_from_page \
            -portal_id $portal_id \
            -package_id [ns_set get $args package_id] \
            -folder_id [ns_set get $args folder_id]
    }

    ad_proc -public clone {
        old_community_id
        new_community_id
    } {
        Clone this applet's content from the old community to the new one
    } {
        # check out content_folder.copy method
        ns_log error "** Error in [get_pretty_name] 'clone' not implemented!"
    }

    # 
    # misc helper procs
    #

    ad_proc -public get_user_default_page {} {
        return the user default page to add the portlet to
    } {
        return "My Files"
    }

    ad_proc -public get_community_default_page {} {
        return the user default page to add the portlet to
    } {
        return "File Storage"
    }

    ad_proc -public get_subcomm_default_page {} {
        return the user default page to add the portlet to
    } {
        return Files
    }

    ad_proc -public get_package_id {
    } {
        returns the package_id of the dotlrn-fs package
    } {
        return [db_string select_package_id {
            select min(package_id)
            from apm_packages
            where package_key = 'dotlrn-fs'
        }]
    }

    ad_proc -public get_url {
    } {
        returns the URL for the dotlrn-fs package
    } {
        return [site_nodes::get_url_from_package_id -package_id [get_package_id]]
    }

    ad_proc -private get_public_folder_id {
        {-parent_id:required}
    } {
        get the folder_id for the public folder given the parent folder id
    } {
        set foo [fs::get_folder -name public -parent_id $parent_id]
    }

    ad_proc -public get_user_root_folder_name {
        {-user_id:required}
    } {
        Get the internal name for a user's root folder.
    } {
        return "[applet_key]_${user_id}_root_folder"
    }

    ad_proc -public get_user_root_folder {
        {-user_id:required}
    } {
        Get the folder_id of a user's root folder.
    } {
        set name [get_user_root_folder_name -user_id $user_id]

        return [db_string get_user_root_folder {
            select folder_id
            from fs_folders
            where key = :name
        } -default ""]
    }

    ad_proc -public get_user_shared_folder_name {
        {-user_id:required}
    } {
        Get the internal name for a user's root folder.
    } {
        return "[applet_key]_${user_id}_shared_folder"
    }

    ad_proc -public get_user_shared_folder {
        {-user_id:required}
    } {
        Get the folder_id of a user's shared folder.
    } {
        set name [get_user_shared_folder_name -user_id $user_id]

        return [db_string get_user_root_folder {
            select folder_id
            from fs_folders
            where key = :name
        } -default ""]
    }

}
