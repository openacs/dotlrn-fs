<?xml version="1.0"?>

<queryset>

    <fullquery name="dotlrn_fs::get_public_folder_id">
        <querytext>
            select folder_id
            from cr_folders,
                 cr_items
            where name = 'public'
            and parent_id = :parent_folder_id
        </querytext>
    </fullquery>

</queryset>
