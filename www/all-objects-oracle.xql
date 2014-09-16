<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="select_folder_contents">
        <querytext>
    select fs_objects.*,
           fs_folders.name as folder_name
    from fs_objects,
         fs_folders
    where fs_objects.object_id in (select acs_objects.object_id
                                   from acs_objects
                                   connect by acs_objects.context_id = prior acs_objects.object_id
                                   start with acs_objects.context_id in (select site_node_object_mappings.object_id
                                                                         from site_node_object_mappings,
                                                                              site_nodes,
                                                                              fs_root_folders
                                                                         where site_node_object_mappings.node_id = site_nodes.node_id
                                                                         and site_node_object_mappings.object_id = fs_root_folders.folder_id
                                                                         and site_nodes.parent_id in (select sn.node_id
                                                                                                      from site_nodes sn,
                                                                                                           apm_packages ap
                                                                                                      where sn.object_id = ap.package_id
                                                                                                      and ap.package_key = :dotlrn_package_key)))
    and fs_objects.parent_id = fs_folders.folder_id
    and fs_objects.type <> 'folder'
    and fs_objects.last_modified >= (sysdate - :n_past_days)
    and 't' = acs_permission.permission_p(fs_objects.object_id, :user_id, 'read')
    [template::list::orderby_clause -name files -orderby]
        </querytext>
    </fullquery>

</queryset>
