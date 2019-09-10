# packages/dotlrn-fs/tcl/test/dotlrn-fs-procs.tcl

ad_library {

    Tests for dotlrn file storage integration package

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2006-04-17
    @cvs-id $Id$
}

aa_register_case -cats {api smoke db} dotlrn_fs_user_folders {
    Test user folders procedures
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            # create a new dotlrn user
            array set creation_info [acs::test::user::create]
            aa_log "create user result is: $creation_info(creation_status)"
            aa_equals creation_ok $creation_info(creation_status) ok

            set rel_id [dotlrn::user_add -user_id $creation_info(user_id)]
            aa_false "dotlrn_rel_created" [string equal $rel_id ""]
            aa_log "dotlrn::user_add rel_id result is: $rel_id"

            aa_log "now calling dotlrn::remove_user_completely to try and remove this user"

            # create a test instance of file storage
            set fs_package_id \
                [site_node::instantiate_and_mount \
                     -node_name [ns_mktemp "__test__XXXXXX"] \
                     -package_key file-storage]
            # get the user folder and shared folders
            set user_root_folder_name \
                [dotlrn_fs::get_user_root_folder_name \
                     -user_id $creation_info(user_id)]
            set user_shared_folder_name \
                [dotlrn_fs::get_user_shared_folder_name \
                     -user_id $creation_info(user_id)]
            set user_root_folder_id \
                [dotlrn_fs::get_user_root_folder_not_cached \
                     -user_id $creation_info(user_id)]
            set user_shared_folder_id \
                [dotlrn_fs::get_user_shared_folder \
                     -user_id $creation_info(user_id)]

            # create new duplicately named folders in the
            # test file storage instance
            set fs_root_folder_id [fs::get_root_folder \
                                       -package_id $fs_package_id]
            set fs_user_root_folder_id \
                [content::folder::new \
                     -parent_id $fs_root_folder_id \
                     -name $user_root_folder_name]
            set fs_iser_shared_folder_id \
                [content::folder::new \
                     -parent_id $fs_root_folder_id \
                     -name $user_shared_folder_name]

            # see if we get the same user folder and shared folder
            # back again
            set check_user_root_folder_id ""
            set check_user_shared_folder_id ""
            catch {set check_user_root_folder_id \
                       [dotlrn_fs::get_user_root_folder_not_cached \
                            -user_id $creation_info(user_id)]} \
                root_err_msg
            aa_log $root_err_msg

            aa_true "User root folder OK" {
                $check_user_root_folder_id \
                    == $user_root_folder_id}
            catch {set check_user_shared_folder_id \
                       [dotlrn_fs::get_user_shared_folder \
                            -user_id $creation_info(user_id)]} shared_err_msg

            aa_log $shared_err_msg
            aa_true "User shared folder OK" {
                $check_user_shared_folder_id \
                    == $user_shared_folder_id}
        }
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        dotlrn_fs::package_key
        dotlrn_fs::my_package_key
        dotlrn_fs::applet_key
    } \
    dotlrn_fs__keys {

        Simple test for the various dotlrn_fs::..._key procs.

        @author Héctor Romojaro <hector.romojaro@gmail.com>
        @creation-date 2019-09-10
} {
    aa_equals "Package key" "[dotlrn_fs::package_key]" "file-storage"
    aa_equals "My Package key" "[dotlrn_fs::my_package_key]" "dotlrn-fs"
    aa_equals "Applet key" "[dotlrn_fs::applet_key]" "dotlrn_fs"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
