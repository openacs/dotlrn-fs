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
    Procs to set up the dotLRN fs applet

    Copyright 2001 OpenForce, inc.
    Distributed under the GNU GPL v2

    @author ben@openforce.net
    @author arjun@openforce.net
    @creation-date 2001-10-05
    @version $Id$
}

namespace eval dotlrn_fs {

    ad_proc -public applet_key {
    } {
        get the applet_key
    } {
        return "dotlrn_fs"
    }

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
        return "dotLRN File Storage Applet"
    }

    ad_proc -public add_applet {
    } {
        Used for one-time init - must be repeatable!
    } {
        if {![dotlrn::is_package_mounted -package_key [package_key]]} {
            set package_id [dotlrn::mount_package \
                -package_key [package_key] \
                -url [package_key] \
                -directory_p "t"]

            # create the root folder for this instance
            set folder_id [fs::new_root_folder \
                -package_id $package_id \
                -pretty_name "User Folders" \
                -description "User Folders" \
            ]

            portal::mapping::new \
                -object_id $folder_id \
                -node_id [site_nodes::get_node_id_from_package_id -package_id $package_id]

            set party_id [acs_magic_object "registered_users"]
            permission::grant -party_id $party_id -object_id $folder_id -privilege "read"
            permission::revoke -party_id $party_id -object_id $folder_id -privilege "write"
            permission::revoke -party_id $party_id -object_id $folder_id -privilege "admin"

            set party_id [acs_magic_object "the_public"]
            permission::revoke -party_id $party_id -object_id $folder_id -privilege "read"
            permission::revoke -party_id $party_id -object_id $folder_id -privilege "write"
            permission::revoke -party_id $party_id -object_id $folder_id -privilege "admin"

            dotlrn_applet::add_applet_to_dotlrn -applet_key [applet_key]

            # Mount the package
            dotlrn_applet::mount -package_key "dotlrn-fs" -url "fs" -pretty_name "File Storage"
        }
    }

    ad_proc -public remove_applet {
    } {
        remove the applet from dotlrn
    } {
    }

    ad_proc -public add_applet_to_community {
        community_id
    } {
        Add the fs applet to a specifc dotlrn community
    } {
        set portal_id [dotlrn_community::get_portal_id -community_id $community_id]
        set community_type [dotlrn_community::get_community_type_from_community_id $community_id]

        if {$community_type == "dotlrn_community"} {
            set page_name [get_subcomm_default_page]
        } else {
            set page_name [get_community_default_page]
        }

        if {[dotlrn_community::dummy_comm_p -community_id $community_id]} {
            fs_portlet::add_self_to_page \
                -portal_id $portal_id \
                -page_name $page_name \
                -package_id 0 \
                -folder_id 0
            return
        }

        set package_key [package_key]
        set package_id [dotlrn::instantiate_and_mount $community_id $package_key]
        set community_name [dotlrn_community::get_community_name $community_id]

        # set up a forum inside that instance
        set folder_id [fs::new_root_folder \
            -package_id $package_id \
            -pretty_name "${community_name}'s Files" \
            -description "${community_name}'s Files" \
        ]

        set node_id [site_nodes::get_node_id_from_package_id -package_id $package_id]
        portal::mapping::new -object_id $folder_id -node_id $node_id

        fs_portlet::add_self_to_page \
            -portal_id $portal_id \
            -page_name $page_name \
            -package_id $package_id \
            -folder_id $folder_id

        set party_id [acs_magic_object "registered_users"]
        permission::revoke -party_id $party_id -object_id $folder_id -privilege "read"
        permission::revoke -party_id $party_id -object_id $folder_id -privilege "write"
        permission::revoke -party_id $party_id -object_id $folder_id -privilege "admin"

        set party_id [acs_magic_object "the_public"]
        permission::revoke -party_id $party_id -object_id $folder_id -privilege "read"
        permission::revoke -party_id $party_id -object_id $folder_id -privilege "write"
        permission::revoke -party_id $party_id -object_id $folder_id -privilege "admin"

        # Set up permissions on these folders
        # The root folder is available only to community members
        set members [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_member_rel \
        ]
        permission::grant -party_id $members -object_id $folder_id -privilege "read"
        # admins of this community can admin the folder
        set admins [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_admin_rel \
        ]
        permission::grant -party_id $admins -object_id $folder_id -privilege "admin"

        set root_community_type [dotlrn_community::get_toplevel_community_type_from_community_id $community_id]
        foreach folder [string trim [split [ad_parameter -package_id [apm_package_id_from_key "dotlrn-fs"] "${root_community_type}_default_folders"] ',']] {
            set a_folder_id [fs::new_folder \
                -name $folder \
                -pretty_name $folder \
                -parent_id $folder_id]

            portal::mapping::new -object_id $a_folder_id -node_id $node_id
        }

        # Set up public folder
        set public_folder_id [fs::new_folder \
            -name "public" \
            -pretty_name "${community_name}'s Public Files" \
            -parent_id $folder_id \
        ]

        portal::mapping::new -object_id $public_folder_id -node_id $node_id

        # The public folder is available to all dotLRN Full Access Users
        set dotlrn_public [dotlrn::get_users_rel_segment_id]
        permission::grant -party_id $dotlrn_public -object_id $public_folder_id -privilege "read"

        # non-member page stuff
        # Get non member portal_id
        set non_member_portal_id [dotlrn_community::get_non_member_portal_id -community_id $community_id]

        # Make public-folder the only one available at non-member page
        fs_portlet::add_self_to_page \
            -portal_id $non_member_portal_id \
            -package_id $package_id \
            -folder_id $public_folder_id \
            -force_region 2

        return $package_id
    }

    ad_proc -public remove_applet_from_community {
        community_id
    } {
        remove the fs applet from a specifc dotlrn community
    } {
        set package_id [dotlrn::get_community_applet_package_id \
            -community_id $community_id \
            -package_key [package_key]
        ]

        set root_folder_id [fs::get_root_folder -package_id $package_id]
        set public_folder_id [get_public_folder_id -parent_id $root_folder_id]

        set admins [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_admin_rel \
        ]
        permission::revoke -party_id $admins -object_id $root_folder_id -privilege "admin"

        set members [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_member_rel \
        ]
        permission::revoke -party_id $members -object_id $root_folder_id -privilege "read"

        # remove the portlet from the non_member_portal
        set non_member_portal_id \
            [dotlrn_community::get_non_member_portal_id -community_id $community_id]

        fs_portlet::remove_self_from_page \
            $non_member_portal_id \
            $package_id \
            $public_folder_id

        # set node_id [site_nodes::get_node_id_from_package_id -package_id $package_id]
        
        # just unmount fs, dont attempt of delete the package
        # the delete_p flag deletes the "node" not the "package" like other
        # procs do

        # aks fixme - need to re-factor, re-name all deletetion procs
        # both in dotlrn and in site_nodes
        #       site_map_unmount_application -delete_p "t" $node_id
        
        # aks hack deleting the root folder
        db_dml delete_root_folder {
            delete from fs_root_folders where folder_id = :root_folder_id
        }

        db_exec_plsql delete_content_folder {
            declare 
            begin 
              content_folder.delete(:root_folder_id); 
            end;
        }

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
        set package_key [package_key]
        set package_id [db_string select_min_package_id {
            select min(package_id)
            from apm_packages
            where package_key = :package_key
        }]
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
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege "read"
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege "write"
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege "admin"

        }

        # get the user's portal
        set portal_id [dotlrn::get_workspace_portal_id $user_id]
        if {![empty_string_p $portal_id]} {
            fs_portlet::add_self_to_page \
                -portal_id $portal_id \
                -page_name [get_user_default_page] \
                -package_id $package_id \
                -folder_id $user_root_folder_id \
                -extra_params [list scoped_p f contents_url "[get_url]all-objects"]
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
                -party_id [acs_magic_object "the_public"] \
                -object_id $user_shared_folder_id \
                -privilege "read"
        }
    }

    ad_proc -public remove_user {
        user_id
    } {
    } {
        # get the user's portal
        set portal_id [dotlrn::get_workspace_portal_id $user_id]

        if {![empty_string_p $portal_id]} {

            # get the root folder of this package instance
            set package_key [package_key]
            set package_id [db_string select_min_package_id {
                select min(package_id)
                from apm_packages
                where package_key = :package_key
            }]

            # set package_id [apm_package_id_from_key [package_key]]
            set root_folder_id [fs::get_root_folder -package_id $package_id]

            # does this user already have a root folder?
            set user_root_folder_id [fs::get_folder \
                -name [get_user_root_folder_name -user_id $user_id] \
                -parent_id $root_folder_id \
            ]

            if {![empty_string_p $user_root_folder_id]} {
                fs_portlet::remove_self_from_page $portal_id $package_id $user_root_folder_id
            }
        }
    }

    ad_proc -public add_user_to_community {
        community_id
        user_id
    } {
        Add a user to a to a specifc dotlrn community
    } {
        # Get the package_id by callback
        set package_id [dotlrn_community::get_applet_package_id $community_id [applet_key]]
        set portal_id [dotlrn::get_workspace_portal_id $user_id]
        set folder_id [fs::get_root_folder -package_id $package_id]

        fs_portlet::add_self_to_page \
            -portal_id $portal_id \
            -page_name [get_user_default_page] \
            -package_id $package_id \
            -folder_id $folder_id
    }

    ad_proc -public remove_user_from_community {
        community_id
        user_id
    } {
        Remove a user from a community
    } {
        set package_id [dotlrn_community::get_applet_package_id $community_id [applet_key]]
        set portal_id [dotlrn::get_workspace_portal_id $user_id]
        set folder_id [fs::get_root_folder -package_id $package_id]

        set args [ns_set create args]
        ns_set put $args user_id $user_id
        ns_set put $args community_id $community_id
        ns_set put $args package_id $package_id
        ns_set put $args folder_id $folder_id
        set list_args [list $portal_id $args]

        remove_portlet $portal_id $args
    }

    ad_proc -public add_portlet {
        args
    } {
        A helper proc to add the underlying portlet to the given portal.

        @param args a list-ified array of args defined in add_applet_to_community
    } {
        ns_log notice "** Error in [get_pretty_name]: 'add_portlet' not implemented!"
        ad_return_complaint 1  "Please notifiy the administrator of this error:
        ** Error in [get_pretty_name]: 'add_portlet' not implemented!"
    }

    ad_proc -public remove_portlet {
        portal_id
        args
    } {
        A helper proc to remove the underlying portlet from the given portal. 
        
        @param portal_id
        @param args A list of key-value pairs (possibly user_id, community_id, and more)
    } { 
        set user_id [ns_set get $args "user_id"]
        set community_id [ns_set get $args "community_id"]

        if {![empty_string_p $user_id]} {
            # the portal_id is a user's portal
            set fs_package_id [ns_set get $args "fs_package_id"]
            set folder_id [ns_set get $args "folder_id"]
        } elseif {![empty_string_p $community_id]} {
            # the portal_id is a community portal
            ad_return_complaint 1  "[applet_key] aks1 unimplimented"
        } else {
            # the portal_id is a portal template
            ad_return_complaint 1  "[applet_key] aks2 unimplimented"
        }

        fs_portlet::remove_self_from_page $portal_id $fs_package_id $folder_id
    }

    ad_proc -public clone {
        old_community_id
        new_community_id
    } {
        Clone this applet's content from the old community to the new one
    } {
        ns_log notice "** Error in [get_pretty_name] 'clone' not implemented!"
        ad_return_complaint 1  "Please notifiy the administrator of this error: ** Error in [get_pretty_name]: 'clone' not implemented!"
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
        return "Files"
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
        set foo [fs::get_folder -name "public" -parent_id $parent_id]
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
            select item_id
            from cr_items
            where name = :name
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
            select item_id
            from cr_items
            where name = :name
        } -default ""]
    }

}
