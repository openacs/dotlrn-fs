<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="dotlrn_fs::add_applet_to_community.create_fs_root_folder">
  <querytext>
    declare
    begin
      :1 := file_storage.new_root_folder(:package_id);
    end;
  </querytext>
</fullquery>

<fullquery name="dotlrn_fs::add_applet_to_community.create_fs_public_folder">
  <querytext>
    declare
    begin
      :1 := file_storage.new_folder (
         name => :name,
         folder_name => :folder_name,
         parent_id => :folder_id,
         creation_user => :user_id,
         creation_ip => :ip);
    end;
  </querytext>
</fullquery>


</queryset>

