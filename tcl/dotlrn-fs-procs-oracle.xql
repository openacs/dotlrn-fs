<?xml version="1.0"?>

<queryset>

<fullquery name="create_fs_root_folder">
<querytext>
  begin
    :1 := file_storage.new_root_folder(:package_id);
  end
</querytext>
</fullquery>

<fullquery name="create_fs_public_folder">
<querytext>
begin
  :1 := file_storage.new_folder (
     name => :name,
     folder_name => :folder_name,
     parent_id => :folder_id,
     creation_user => :user_id,
     creation_ip => :ip);
end
        
</querytext>
</fullquery>


</queryset>
