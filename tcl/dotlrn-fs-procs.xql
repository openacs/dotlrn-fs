<?xml version="1.0"?>

<queryset>

    <fullquery name="dotlrn_fs::get_community_shared_folder.select_community_shared_folder">
        <querytext>
            select item_id
            from cr_items
            where parent_id = :root_folder_id
            and name = 'public'
        </querytext>
    </fullquery>

    <fullquery name="dotlrn_fs::clone.get_default_folder">
        <querytext>
            select item_id
            from cr_items
            where parent_id = :folder_id
            and name = :folder
        </querytext>
    </fullquery>

</queryset>
