#
#  Copyright (C) 2001, 2002 OpenForce, Inc.
#
#  This file is part of dotLRN.
#
#  dotLRN is free software; you can redistribute it and/or modify it under the
#  terms of the GNU General Public License as published by the Free Software
#  Foundation; either version 2 of the License, or (at your option) any later
#  version.
#
#  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#

# dotlrn-fs/www/index.tcl

ad_page_contract {

    Display top offending users of file storage.

    @author <a href="mailto:yon@openforce.net">yon@openforce.net</a>
    @creation-date 2002-05-17
    @version $Id$

} -query {
} -properties {
    context_bar:onevalue
    title:onevalue
    folders:multirow
}

set package_id [ad_conn package_id]

permission::require_permission -object_id $package_id -privilege admin

set context_bar {}
set title "Top Offenders"

set fs_package_key [dotlrn_fs::package_key]

db_multirow folders select_top_offending_folders {
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
                                         where fsrf.folder_id <> (select pnm1.object_id
                                                                  from portal_node_mappings pnm1,
                                                                       site_nodes sn1,
                                                                       fs_root_folders fsrf1
                                                                  where pnm1.node_id = sn1.node_id
                                                                  and sn1.object_id = (select min(ap1.package_id)
                                                                                       from apm_packages ap1
                                                                                       where package_key = :fs_package_key)
                                                                  and fsrf1.folder_id = pnm1.object_id))
          or fs_folders.parent_id = (select pnm2.object_id
                                     from portal_node_mappings pnm2,
                                          site_nodes sn2,
                                          fs_root_folders fsrf2
                                     where pnm2.node_id = sn2.node_id
                                     and sn2.object_id = (select min(ap2.package_id)
                                                          from apm_packages ap2
                                                          where ap2.package_key = :fs_package_key)
                                     and fsrf2.folder_id = pnm2.object_id)
          order by content_size desc,
                   fs_folders.name) folders
    where rownum < 11
    and content_size > 0
} {
    set url [portal::mapping::get_url -object_id $folder_id]
}

ad_return_template
