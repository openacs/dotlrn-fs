<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="select_top_offending_folders">
        <querytext>
    select folders.*
    from (select fs_folders.folder_id,
                 fs_folders.parent_id,
                 fs_folders.name,
                 nvl ((select sum(fs_files.content_size) as content_size
                       from fs_files
                       where fs_files.parent_id in (select cr_items.item_id
                                                    from cr_items
                                                    connect by cr_items.parent_id = prior cr_items.item_id
                                                    start with cr_items.parent_id = fs_folders.folder_id)
                       or fs_files.parent_id = fs_folders.folder_id), 0) as content_size,
                 '' as url
          from fs_folders
          where fs_folders.folder_id in (select fsrf.folder_id
                                         from fs_root_folders fsrf
                                         where fsrf.folder_id <> (select snom1.object_id
                                                                  from site_node_object_mappings snom1,
                                                                       site_nodes sn1,
                                                                       fs_root_folders fsrf1
                                                                  where snom1.node_id = sn1.node_id
                                                                  and sn1.object_id = (select min(ap1.package_id)
                                                                                       from apm_packages ap1
                                                                                       where package_key = :fs_package_key)
                                                                  and fsrf1.folder_id = snom1.object_id))
          or fs_folders.parent_id = (select snom2.object_id
                                     from site_node_object_mappings snom2,
                                          site_nodes sn2,
                                          fs_root_folders fsrf2
                                     where snom2.node_id = sn2.node_id
                                     and sn2.object_id = (select min(ap2.package_id)
                                                          from apm_packages ap2
                                                          where ap2.package_key = :fs_package_key)
                                     and fsrf2.folder_id = snom2.object_id)
          order by content_size desc,
                   fs_folders.name) folders
    where rownum < 11
    and content_size > 0
        </querytext>
    </fullquery>

</queryset>
