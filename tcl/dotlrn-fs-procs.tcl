ad_library {
    Procs to set up the dotLRN fs applet

    Copyright 2001 OpenForce, inc.
    Distributed under the GNU GPL v2

    @author ben@openforce.net
    @author arjun@openforce.net
    @creation-date 2001-10-05
    @cvs-id $Id$
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

    ad_proc -public get_user_default_page {} {
        return the user default page to add the portlet to
    } {
        return "My Files"
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
            set folder_id [fs::new_root_folder -package_id $package_id]

            ad_permission_revoke [acs_magic_object "registered_users"] $folder_id "read"
            ad_permission_revoke [acs_magic_object "registered_users"] $folder_id "write"
            ad_permission_revoke [acs_magic_object "registered_users"] $folder_id "admin"
            ad_permission_revoke [acs_magic_object "the_public"] $folder_id "read"
            ad_permission_revoke [acs_magic_object "the_public"] $folder_id "write"
            ad_permission_revoke [acs_magic_object "the_public"] $folder_id "admin"

        }

        dotlrn_community::add_applet_to_dotlrn -applet_key "dotlrn_fs"
    }

    ad_proc -public add_applet_to_community {
        community_id
    } {
        Add the fs applet to a specifc dotlrn community
    } {
        # create the calendar package instance (all in one, I've mounted it)
        set package_key [package_key]
        set package_id [dotlrn::instantiate_and_mount \
            $community_id \
            $package_key \
        ]

        set community_name [dotlrn_community::get_community_name $community_id]

        # set up a forum inside that instance
        set folder_id [fs::new_root_folder \
            -package_id $package_id \
            -pretty_name "${community_name}'s Files" \
            -description "${community_name}'s Files" \
        ]

        # Set up public folder
        set public_folder_id [fs::new_folder \
            -name "public" \
            -pretty_name "${community_name}'s Public Files" \
            -parent_id $folder_id \
        ]

        # Set up permissions on these folders
        # The public folder is available to all dotLRN Full Access Users
        # The root folder is available only to community members
        set members [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_member_rel \
        ]
        ad_permission_grant $members $folder_id read

        set dotlrn_public [dotlrn::get_full_users_rel_segment_id]
        ad_permission_grant $dotlrn_public $public_folder_id read

        # non-member page stuff
        # Get non member portal_id
        set non_member_portal_id \
            [dotlrn_community::get_community_non_members_portal_id \
                $community_id \
            ]

        # Make public-folder the only one available at non-member page
        fs_portlet::add_self_to_page \
            $non_member_portal_id $package_id $public_folder_id

        # portal template stuff
        # get the portal_template_id by callback
        set pt_id [dotlrn_community::get_portal_template_id $community_id]

        # set up the DS for the portal template
        # that's the private folder_id there
        fs_portlet::make_self_available $pt_id
        fs_portlet::add_self_to_page $pt_id $package_id $folder_id

        # return the package_id
        return $package_id
    }

    ad_proc -public remove_applet {
        community_id
        package_id
    } {
        remove the applet from the community
    } {
        # Remove all instances of the fs portlet!

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

    ad_proc -public get_user_root_folder_name {
        {-user_id:required}
    } {
        Get the internal name for a user's root folder.
    } {
        return "dotlrn_fs_${user_id}_root_folder"
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
        return "dotlrn_fs_${user_id}_shared_folder"
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
        # set package_id [apm_package_id_from_key [package_key]]
        set root_folder_id [fs::get_root_folder -package_id $package_id]

        # does this user already have a root folder?
        set user_root_folder_id [fs::get_folder \
            -name [get_user_root_folder_name -user_id $user_id] \
            -parent_id $root_folder_id \
        ]

        if {[empty_string_p $user_root_folder_id]} {

            # create the user's root folder
            set user_root_folder_id [fs::new_folder \
                -name [get_user_root_folder_name -user_id $user_id] \
                -parent_id $root_folder_id \
                -pretty_name "${user_name}'s Files" \
                -creation_user $user_id \
            ]

            # set the permissions for this folder; only the user has access to it
            ad_permission_grant $user_id $user_root_folder_id "read"
            ad_permission_grant $user_id $user_root_folder_id "write"
            ad_permission_grant $user_id $user_root_folder_id "admin"

        }

        # get the user's portal
        set portal_id [dotlrn::get_workspace_portal_id $user_id]

        set page_id [portal::get_page_id \
            -portal_id $portal_id \
            -page_name [get_user_default_page] \
        ]

        # add the portlet here
        if {![empty_string_p $portal_id]} {
            fs_portlet::add_self_to_page \
                -page_id $page_id $portal_id $package_id $user_root_folder_id
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

            # set the permissions for this folder; only the user has access to it
            # ad_permission_grant [dotlrn::get_full_users_rel_segment_id] $user_shared_folder_id "read"
            ad_permission_grant [acs_magic_object "the_public"] $user_shared_folder_id "read"

        }
    }

    ad_proc -public add_user_to_community {
        community_id
        user_id
    } {
        Add a user to a to a specifc dotlrn community
    } {
        # Get the portal_id by callback
        set portal_id [dotlrn_community::get_portal_id $community_id $user_id]

        # Get the package_id by callback
        set package_id [dotlrn_community::get_applet_package_id \
            $community_id \
            "dotlrn_fs" \
        ]

        # Call the portal element to be added correctly
        # fs portlet needs folder_id too
        set folder_id [fs::get_root_folder -package_id $package_id]

        # Make file storage available at community-user page level
        fs_portlet::add_self_to_page $portal_id $package_id $folder_id

        # get the user's portal
        set portal_id [dotlrn::get_workspace_portal_id $user_id]

        set page_id [portal::get_page_id \
            -portal_id $portal_id \
            -page_name [get_user_default_page] \
        ]

        # add the portlet here
        if {![empty_string_p $portal_id]} {
            fs_portlet::add_self_to_page \
                -page_id $page_id $portal_id $package_id $folder_id
        }

    }

    ad_proc -public remove_user {
        community_id
        user_id
    } {
        Remove a user from a community
    } {
        # Get the portal_id
        set portal_id [dotlrn_community::get_portal_id $community_id $user_id]

        # Get the package_id by callback
        set package_id [dotlrn_community::get_package_id $community_id]

        # get folder id
        set folder_id [fs::get_root_folder -package_id $package_id]

        # Remove the portal element
        fs_portlet::remove_self_from_page $portal_id $package_id $folder_id

        # Buh Bye.
        fs_portlet::make_self_unavailable $portal_id

        # Remove from the main workspace
        set workspace_portal_id [dotlrn::get_workspace_portal_id $user_id]

        # Add the portlet here
        if {![empty_string_p $workspace_portal_id]} {
            fs_portlet::remove_self_from_page \
                $workspace_portal_id \
                $package_id \
                $folder_id
        }

        # remove user permissions to see fs folders
        # nothing to do here
    }

}
