<?xml version="1.0"?>

<queryset>

    <fullquery name="dotlrn_fs::get_community_shared_folder.select_community_shared_folder">
        <querytext>
            select folder_id
            from fs_folders
            where parent_id = :root_folder_id
            and key = 'public'
        </querytext>
    </fullquery>

</queryset>
