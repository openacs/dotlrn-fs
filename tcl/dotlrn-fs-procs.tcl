#
#  Copyright (C) 2001, 2002 MIT
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
    @cvs-id $Id$

}

namespace eval dotlrn_fs {

    ad_proc -public applet_key {
    } {
        What's my key?
    } {
        return "dotlrn_fs"
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
        return "#file-storage.pretty_name#"
    }

    ad_proc -public add_applet {
    } {
        Used for one-time init - must be repeatable!
    } {
        if {![dotlrn::is_package_mounted -package_key [package_key]]} {

            set package_id [dotlrn::mount_package \
                -url [package_key] \
                -package_key [package_key] \
                -pretty_name [_ dotlrn-fs.User_Folders] \
                -directory_p t \
            ]

            set folder_id [fs::get_root_folder -package_id $package_id]
            fs::rename_folder -folder_id $folder_id -name [_ dotlrn-fs.user_folder_pretty_name]

            set node_id [site_node::get_node_id_from_object_id -object_id $package_id]
            site_node_object_map::new -object_id $folder_id -node_id $node_id

	    if {![parameter::get_from_package_key -package_key "dotlrn-fs" -parameter "InheritPermissionsForRootFolderP"]} {
		permission::set_not_inherit -object_id $folder_id
	    } else {
		permission::set_inherit -object_id $folder_id
	    }

            set party_id [acs_magic_object registered_users]
            permission::grant -party_id $party_id -object_id $folder_id -privilege read

            dotlrn_applet::add_applet_to_dotlrn -applet_key [applet_key] -package_key [my_package_key]

            # Mount the package
            dotlrn_applet::mount -package_key [my_package_key] -url fs -pretty_name [_ dotlrn-fs.applet_pretty_name]
        }
    }

    ad_proc -public remove_applet {
    } {
        remove the applet from dotlrn
    } {
        ad_return_complaint 1 "[applet_key] remove_applet not implemented!"
    }

    ad_proc -public add_applet_to_community {
        community_id
    } {
        Add the fs applet to a specific dotlrn community
    } {
        set portal_id [dotlrn_community::get_portal_id -community_id $community_id]
        set package_id [dotlrn::instantiate_and_mount $community_id [package_key]]
        set community_name [dotlrn_community::get_community_name $community_id]

        set folder_id [fs::get_root_folder -package_id $package_id]

        fs::rename_folder -folder_id $folder_id -name "[_ dotlrn-fs.lt_community_names_Files]"

        set node_id [site_node::get_node_id_from_object_id -object_id $package_id]
        site_node_object_map::new -object_id $folder_id -node_id $node_id

	if {![parameter::get_from_package_key -package_key "dotlrn-fs" -parameter "InheritPermissionsForRootFolderP"]} {
	    permission::set_not_inherit -object_id $folder_id
	} else {
	    permission::set_inherit -object_id $folder_id
	}


        # Set up permissions on these folders
        # The root folder is available only to community members
        set members [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_member_rel \
        ]
        permission::grant -party_id $members -object_id $folder_id -privilege read

	# We need to grant members the ability to upload files to the folders. This should
	# become a parameter. Not sure though how we can set such a parameter.
	if {[parameter::get -parameter "WritePermissionForMembersP" -default "1"]} {
	    permission::grant -party_id $members -object_id $folder_id -privilege write
	}

        # admins of this community can admin the folder
        set admins [dotlrn_community::get_rel_segment_id \
            -community_id $community_id \
            -rel_type dotlrn_admin_rel \
        ]
        permission::grant -party_id $admins -object_id $folder_id -privilege admin

        set group_id [db_string group_id_from_name "select group_id from groups where group_name='dotlrn-admin'" -default ""]

        if {$group_id ne "" } {
	    permission::grant -party_id $group_id -object_id $folder_id -privilege admin
        }

        set root_community_type [dotlrn_community::get_toplevel_community_type_from_community_id \
                                     $community_id
        ]

        set folder_list [parameter::get_from_package_key \
                             -package_key [my_package_key] \
                             -parameter "${root_community_type}_default_folders"
        ]

        # For the Assignments, Handouts, Exams etc. we store the message keys for
        # multilinguality. This works as long as those messages don't have embedded variables
        # except # is a really bad idea in the URL so we store the
        # localized folder name in cr_items.name and just use the
        # message key in cr_folders.label. This is how the community
        # root folder is created anyway. This will break the
        # "magic" folder copying in the clone procedure if someone
        # changes the site default locale --DaveB 2004-08-04
        foreach folder [split $folder_list ','] {
            set folder [string trim $folder]
            set a_folder_id [fs::new_folder \
                -name [lang::util::localize $folder [lang::system::site_wide_locale]] \
                -pretty_name $folder \
                -parent_id $folder_id
            ]

            # We also don't want anyone other than the site-wide admin to be
            # able to edit or delete these folders, because doing so breaks
            # the standard portlets created to display them.  Admins can write
            # to them, that's all.

            permission::set_not_inherit -object_id $a_folder_id
            permission::grant -party_id $members -object_id $a_folder_id -privilege read
            permission::grant -party_id $admins -object_id $a_folder_id -privilege write

            site_node_object_map::new -object_id $a_folder_id -node_id $node_id

            if {$root_community_type eq "dotlrn_class_instance"} {

                # a class instance has some "folder contents" pe's that need filling
                set portlet_list [parameter::get_from_package_key \
                    -package_key [my_package_key] \
                    -parameter "dotlrn_class_instance_folders_to_show"
                ]

                if {$folder in [split $portlet_list ","]} {
                    # yes, this breaks the applet/portlet/portal abstraction
                    # this folder is in the list, overwrite its folder id
                    set element_id [portal::get_element_id_by_pretty_name \
                        -portal_id $portal_id \
                        -pretty_name $folder
                    ]
                    portal::set_element_param $element_id folder_id $a_folder_id
                }

            }
        }

        # Set up public folder
        # Message lookup uses variable community_name
        set public_folder_id [fs::new_folder \
            -name public \
            -pretty_name [_ dotlrn-fs.lt_community_names_Publi] \
            -parent_id $folder_id \
        ]

        site_node_object_map::new -object_id $public_folder_id -node_id $node_id

        # The public folder is available to all dotLRN Full Access Users.  Admins can
        # write to it but can't delete it by default, because the non-member portlet
        # expects it to exist.

	if {![parameter::get -parameter "InheritPermissionForPublicFolderP" -default "0"]} {
	    permission::set_not_inherit -object_id $public_folder_id
	}

        permission::grant -party_id $admins -object_id $public_folder_id -privilege write

	if {[parameter::get -parameter "WritePermissionForMembersOnPublicP" -default "0"]} {
	    permission::grant -party_id $members -object_id $public_folder_id -privilege write
	}

        set dotlrn_public [dotlrn::get_users_rel_segment_id]
        permission::grant -party_id $dotlrn_public -object_id $public_folder_id -privilege read

        #
        # portlet stuff
        #

	# Add the admin portlet

        set admin_portal_id [dotlrn_community::get_admin_portal_id \
                                 -community_id $community_id
        ]

        fs_admin_portlet::add_self_to_page \
            -portal_id $admin_portal_id \
            -package_id $package_id


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
        remove the fs applet from a specific dotlrn community
    } {
        ad_return_complaint 1 "[applet_key] remove_applet_from_community not implemented!"
    }

    ad_proc -public add_user {
        user_id
    } {
        One time user-specific init
    } {
        # Message lookups below need variable user_name
        set user_name [person::name -person_id $user_id]

        #
        # Get the root folder of .LRN file-storage instance. Note that
        # in theory there might be multiple instances, but we assume
        # here that only one exists.
        #
        set package_id [lindex [site_node::get_children \
                                    -package_key [package_key] \
                                    -element object_id \
                                    -node_id [dotlrn::get_node_id]] 0]

        set root_folder_id [fs::get_root_folder -package_id $package_id]

        # does this user already have a root folder?
        set user_root_folder_id [get_user_root_folder_not_cached \
                                     -user_id $user_id]

        set node_id [site_node::get_node_id_from_object_id -object_id $package_id]

        if {$user_root_folder_id eq ""} {

            # create the user's root folder
            set user_root_folder_id [fs::new_folder \
                -name [get_user_root_folder_name -user_id $user_id] \
                -parent_id $root_folder_id \
                -pretty_name [_ dotlrn-fs.user_names_Files] \
                -creation_user $user_id \
            ]

            site_node_object_map::new -object_id $user_root_folder_id -node_id $node_id

            # set the permissions for this folder; only the user has access to it
            permission::set_not_inherit -object_id $user_root_folder_id
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege read
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege write
            permission::grant -party_id $user_id -object_id $user_root_folder_id -privilege admin

        }

        # does this user already have a shared folder?
        set user_shared_folder_id [get_user_shared_folder -user_id $user_id]

        if {$user_shared_folder_id eq ""} {

            # create the user's shared folder
            set user_shared_folder_id [fs::new_folder \
                -name [get_user_shared_folder_name -user_id $user_id] \
                -parent_id $user_root_folder_id \
                -pretty_name [_ dotlrn-fs.lt_user_names_Shared_Fil] \
                -creation_user $user_id \
            ]

            site_node_object_map::new -object_id $user_shared_folder_id -node_id $node_id

            # set the permissions for this folder
            permission::grant \
                -party_id [acs_magic_object the_public] \
                -object_id $user_shared_folder_id \
                -privilege read
        }

        #
        # portlet stuff
        #

        # Get the user's portal, avoid a stale cache
        ::dotlrn::dotlrn_user_cache flush -partition_key $user_id $user_id-portal_id
        set portal_id [dotlrn::get_portal_id -user_id $user_id]

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
        helper proc to remove a user from dotlrn

        @author Deds Castillo (deds@i-manila.com.ph)
        @creation-date 2004-08-12
    } {
        # reverse the logic done by add_user
        # Message lookups below need variable user_name
        set user_name [person::name -person_id $user_id]

        set root_folder_id [dotlrn_fs::get_dotlrn_root_folder_id]

        # check this first as we use it as parent of the shared folders
        # does this user have a root folder?
        set user_root_folder_id [fs::get_folder \
                                     -name [get_user_root_folder_name -user_id $user_id] \
                                     -parent_id $root_folder_id
                                ]

        # does this user have a shared folder?
        set user_shared_folder_id [fs::get_folder \
            -name [get_user_shared_folder_name -user_id $user_id] \
            -parent_id $user_root_folder_id \
        ]

        if {$user_shared_folder_id ne ""} {

            # delete the mapping
            site_node_object_map::del -object_id $user_shared_folder_id

            # delete the user's shared folder
            set desired_folder_id $user_shared_folder_id
            db_exec_plsql delete_folder {}
        }

        if {$user_root_folder_id ne ""} {

            # delete the mapping
            site_node_object_map::del -object_id $user_root_folder_id

            # delete the user's root folder
            set desired_folder_id $user_root_folder_id
            db_exec_plsql delete_folder {}
        }

    }

    ad_proc -public add_user_to_community {
        community_id
        user_id
    } {
        Add a user to a to a specific dotlrn community
    } {
        # Get the package_id by callback
        set package_id [dotlrn_community::get_applet_package_id -community_id $community_id -applet_key [applet_key]]
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
        set package_id [dotlrn_community::get_applet_package_id -community_id $community_id -applet_key [applet_key]]
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

        ns_set put $args page_name [get_default_page $type]

        if { $type eq "dotlrn_class_instance" || $type eq "dotlrn_club" } {
            # club or class template

            if {$type ne "dotlrn_club" } {
                # it's a class instance, so add the "Assignments", etc
                # fs-contents-portlets, which are initially hidden
                set portlet_list [parameter::get_from_package_key \
                    -package_key [my_package_key] \
                    -parameter "dotlrn_class_instance_folders_to_show"
                ]

                foreach folder [split $portlet_list ','] {
                    set folder [string trim $folder]
                    fs_contents_portlet::add_self_to_page \
                        -portal_id $portal_id \
                        -pretty_name $folder \
                        -folder_id [ns_set get $args folder_id] \
                        -param_action overwrite \
                        -page_name [ns_set get $args page_name] \
                        -hide_p t
                }
            }
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
        ns_log notice "Cloning: [applet_key]"

        # this code is copied from add_applet_to_community above
        # they should be refactored together

        # get the old comm's root folder id
        set old_package_id [dotlrn_community::get_applet_package_id \
            -community_id $old_community_id \
            -applet_key [applet_key]
        ]
        set old_root_folder [fs::get_root_folder -package_id $old_package_id]

        #
        # do root folder stuff
        #
        set portal_id [dotlrn_community::get_portal_id -community_id $new_community_id]
        set package_id [dotlrn::instantiate_and_mount $new_community_id [package_key]]
        set community_name [dotlrn_community::get_community_name $new_community_id]
        set folder_id [fs::get_root_folder -package_id $package_id]

        fs::rename_folder -folder_id $folder_id -name [_ dotlrn-fs.lt_community_names_Files]

        set node_id [site_node::get_node_id_from_object_id -object_id $package_id]
        site_node_object_map::new -object_id $folder_id -node_id $node_id

        set party_id [acs_magic_object registered_users]
        permission::revoke -party_id $party_id -object_id $folder_id -privilege read
        permission::revoke -party_id $party_id -object_id $folder_id -privilege write
        permission::revoke -party_id $party_id -object_id $folder_id -privilege admin

        set party_id [acs_magic_object the_public]
        permission::revoke -party_id $party_id -object_id $folder_id -privilege read
        permission::revoke -party_id $party_id -object_id $folder_id -privilege write
        permission::revoke -party_id $party_id -object_id $folder_id -privilege admin

        # The root folder is available only to community members
        set members [dotlrn_community::get_rel_segment_id \
            -community_id $new_community_id \
            -rel_type dotlrn_member_rel \
        ]
        permission::grant -party_id $members -object_id $folder_id -privilege read
        # admins of this community can admin the folder
        set admins [dotlrn_community::get_rel_segment_id \
            -community_id $new_community_id \
            -rel_type dotlrn_admin_rel \
        ]
        permission::grant -party_id $admins -object_id $folder_id -privilege admin

        #
        # do public folder stuff
        #
        # Message lookup user variable community_name
        set public_folder_id [fs::new_folder \
            -name public \
            -pretty_name [_ dotlrn-fs.lt_community_names_Publi] \
            -parent_id $folder_id \
        ]

        site_node_object_map::new -object_id $public_folder_id -node_id $node_id

        # The public folder is available to all dotLRN Full Access Users.  Admins can
        # write to it but can't delete it by default, because the non-member portlet
        # expects it to exist.

        permission::set_not_inherit -object_id $public_folder_id
        permission::grant -party_id $admins -object_id $public_folder_id -privilege write

        set dotlrn_public [dotlrn::get_users_rel_segment_id]
        permission::grant \
             -party_id $dotlrn_public \
             -object_id $public_folder_id \
             -privilege read
        #
        # now to the cloning
        #

        # first, get the contents of the old root folder and public folder_id
        set user_id [ad_conn user_id]
        set old_root_contents [fs::get_folder_objects \
            -folder_id $old_root_folder \
            -user_id $user_id
        ]
        set old_public_folder_id [get_public_folder_id -parent_id $old_root_folder]

        # go through the list of stuff
        foreach object_id $old_root_contents {

            if {$object_id == $old_public_folder_id} {
                # this is the old public folder so, copy
                # its _contents_ into the new public folder
                set old_public_contents [fs::get_folder_objects \
                    -folder_id $object_id \
                    -user_id $user_id
                ]

                foreach public_item_id $old_public_contents {
                    copy_fs_object  \
                        -object_id $public_item_id \
                        -target_folder_id $public_folder_id \
                        -user_id $user_id
                }
                # if we don't grant admins the ability to admin these files
                # they won't be able to delete them, because they only have
                # write on the folder
                set public_folder_contents [fs::get_folder_objects \
                    -folder_id $public_folder_id \
                    -user_id $user_id
                ]
                foreach object_id $public_folder_contents {
                    permission::grant -party_id $admins -object_id $object_id -privilege admin
                }

                # done with the old public folder
                continue
            }

            # the object is something not in the public folder
            copy_fs_object  \
                -object_id $object_id \
                -target_folder_id $folder_id \
                -user_id $user_id

        }

        # Jerk around the permissions for the default folders in the community ...

        set root_community_type [dotlrn_community::get_toplevel_community_type_from_community_id \
                                     $old_community_id
        ]

        set folder_list [parameter::get_from_package_key \
                             -package_key [my_package_key] \
                             -parameter "${root_community_type}_default_folders"
        ]

        foreach folder [split $folder_list ','] {
            set folder [lang::util::localize [string trim $folder] [lang::system::site_wide_locale]]
            if { [db_0or1row get_default_folder {}] } {
                permission::set_not_inherit -object_id $item_id
                permission::grant -party_id $members -object_id $item_id -privilege read
                permission::grant -party_id $admins -object_id $item_id -privilege admin
            }
        }

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
                                      -community_id $new_community_id
        ]

        # Make public-folder the only one available at non-member page
        ns_set update $args package_id $package_id
        ns_set update $args folder_id $public_folder_id
        ns_set update $args force_region 2

        add_portlet_helper $non_member_portal_id $args

        return $package_id
    }

    #
    # misc helper procs
    #

    ad_proc -public copy_fs_object {
        {-object_id:required}
        {-target_folder_id:required}
        {-user_id:required}
        {-node_id ""}
    } {
        Copy an fs object of any type to a new folder.
        Currently either simple, folder or file.
        Optionally set up a node mapping on folders too.
    } {

        if {[content::extlink::is_extlink -item_id $object_id]} {

	    content::item::copy -item_id $item_id  -target_folder_id $target_folder_id \
		-creation_user $user_id -creation_ip [ad_conn peeraddr]

        } elseif {[fs::folder_p -object_id $object_id]} {

            set name [fs_get_folder_name $object_id]
            set ip [ns_conn peeraddr]

            # create a new folder since fs doesn't have copy_folder
            set new_folder_id [fs::new_folder \
                -name $name \
                -pretty_name $name \
                -parent_id $target_folder_id
            ]

            # set up the node mapping, if available
            if {$node_id ne ""} {
                site_node_object_map::new -object_id $new_folder_id -node_id $node_id
            }

            # we gotta copy the contents of the folder now
            set folder_contents [fs::get_folder_objects \
                -folder_id $object_id \
                -user_id $user_id
            ]

            foreach item_id $folder_contents {

                copy_fs_object  \
                    -object_id $item_id \
                    -target_folder_id $new_folder_id \
                    -user_id $user_id \
                    -node_id $node_id
            }

        } else {
            # move this to fs:: sometime
            db_exec_plsql copy_file {}
        }
    }

    ad_proc -public change_event_handler {
        community_id
        event
        old_value
        new_value
    } {
        dotlrn-fs listens for the following events: rename
    } {
        switch $event {
            rename {
                handle_rename -community_id $community_id -old_value $old_value -new_value $new_value
            }
        }
    }

    ad_proc -private handle_rename {
        {-community_id:required}
        {-old_value:required}
        {-new_value:required}
    } {
        what we do when a community is renamed
    } {
        fs::rename_folder \
            -folder_id [get_community_root_folder -community_id $community_id] \
            -name "[_ dotlrn-fs.new_values_Files]"

        fs::rename_folder \
            -folder_id [get_community_shared_folder -community_id $community_id] \
            -name "[_ dotlrn-fs.lt_new_values_Shared_Fil]"
    }


    ad_proc -private get_default_page { portal_type } {
        The pretty name of the page to add the portlet to.
    } {
        switch $portal_type {
            user {
                set page_name "#dotlrn.user_portal_page_file_storage_title#"
            }
            dotlrn_community {
                set page_name "#dotlrn.subcomm_page_file_storage_title#"
            }
            dotlrn_class_instance {
                set page_name "#dotlrn.class_page_file_storage_title#"
            }
            dotlrn_club {
                set page_name "#dotlrn.club_page_file_storage_title#"
            }
            default {
                ns_log Error "dotlrn-fs applet: Don't know page name to add portlet to for portal type $portal_type"
            }
        }

        return $page_name
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
        return [lindex [site_node::get_url_from_object_id -object_id [get_package_id]] 0]
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
        return [util_memoize [list dotlrn_fs::get_user_root_folder_not_cached -user_id $user_id]]
    }

    ad_proc -private get_user_root_folder_not_cached {
	{-user_id:required}
    } {
        Get the folder_id of a user's root folder.
    } {
        set name [get_user_root_folder_name -user_id $user_id]
        set parent_id [get_dotlrn_root_folder_id]
        return [db_string get_user_root_folder {
            select folder_id
            from fs_folders
            where key = :name
            and parent_id = :parent_id
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
        set parent_id [get_user_root_folder -user_id $user_id]
        return [db_string get_user_root_folder {
            select folder_id
            from fs_folders
            where key = :name
            and parent_id = :parent_id
        } -default ""]
    }

    ad_proc -public get_community_root_folder {
        {-community_id:required}
    } {
        get the community's root folder id
    } {
        set package_id [dotlrn_community::get_applet_package_id \
            -community_id $community_id \
            -applet_key [applet_key] \
        ]

        return [fs::get_root_folder -package_id $package_id]
    }

    ad_proc -public get_community_shared_folder {
        {-community_id:required}
    } {
        get the community's sahred folder id
    } {
        set root_folder_id [get_community_root_folder -community_id $community_id]

        return [db_string select_community_shared_folder {} -default ""]
    }

    ad_proc -public get_dotlrn_root_folder_id {
    } {
        get the root file storage folder for dotlrn
    } {
        #
        # Get the root folder of .LRN file-storage instance. Note that
        # in theory there might be multiple instances, but we assume
        # here that only one exists.
        #
        set package_id [lindex [site_node::get_children \
                                    -package_key [package_key] \
                                    -element object_id \
                                    -node_id [dotlrn::get_node_id]] 0]

        return [fs::get_root_folder -package_id $package_id]

    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
