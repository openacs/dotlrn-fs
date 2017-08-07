# 

ad_library {
    
    Install and upgrade callbacks
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-08-05
    @arch-tag: 97132c7c-a38d-4974-b11e-85ca4acb735f
    @cvs-id $Id$
}

namespace eval dotlrn_fs::install {}

ad_proc -private dotlrn_fs::install::upgrade {
    -from_version_name
    -to_version_name
} {
    
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-08-05
    
    @param from_version_name

    @param to_version_name

    @return 
    
    @error 
} {

    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            2.1.0d1 2.1.0d2 {
                dotlrn_fs::install::upgrade::localize_folder_names
            }
            2.1.a2 2.1.a3 {
                dotlrn_fs::install::upgrade::localize_folder_names
            }
    }
    
}

namespace eval dotlrn_fs::install::upgrade {}

ad_proc -public dotlrn_fs::install::upgrade::localize_folder_names {
} {
    Remove hash marks from folder cr_items.name
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-08-05
    
    @return 
    
    @error 
} {
    # update folder names in cr_items to be localized
    # to the site wide locale to get rid of hash marks
    # in the URLs

    # loop through the community types
    foreach root_community_type {dotlrn_class_instance dotlrn_community dotlrn_club} {
        # get list of folder names message keys from the parameter
        set folder_list [parameter::get_from_package_key \
                         -package_key [dotlrn_fs::my_package_key] \
                         -parameter "${root_community_type}_default_folders"]
        foreach folder_key [split $folder_list ","] {
            # only update folders that contain a message key
            if {[string match "#*#" $folder_key]} {
                # get the localized name in the site wide locale
                set folder_name [lang::util::localize \
                                     $folder_key \
                                     [lang::system::site_wide_locale]]
                # update all folders with that message key to the
                # localized name
                db_dml update_folder_name "update cr_items set name=:folder_name where name=:folder_key and content_type='content_folder'"
            }
        }
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
