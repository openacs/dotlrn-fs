<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="dotlrn_fs::copy_fs_object.copy_file">
        <querytext>
          begin
            :1 := file_storage.copy_file (
                    file_id => :object_id,
                    target_folder_id => :target_folder_id,
                    creation_user => :user_id, 
                    creation_ip => null
                );
          end;
        </querytext>
    </fullquery>

    <fullquery name="dotlrn_fs::remove_user.delete_folder">
        <querytext>
         begin
            file_storage.delete_folder(:desired_folder_id,'f');
         end;
        </querytext>
    </fullquery>

    <fullquery name="dotlrn_fs::remove_user.delete_folder">
        <querytext>
         begin
            file_storage.delete_folder(:desired_folder_id,'f');
         end;
        </querytext>
    </fullquery>

</queryset>
