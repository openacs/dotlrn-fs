<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="dotlrn_fs::copy_fs_object.copy_file">
        <querytext>
                select file_storage__copy_file (
                    :object_id,
                    :target_folder_id,
                    :user_id,
                    null
                );
        </querytext>
    </fullquery>

</queryset>
