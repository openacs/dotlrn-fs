#
#  Copyright (C) 2001, 2002 MIT
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
set title "[_ dotlrn-fs.Top_Offenders]"

set fs_package_key [dotlrn_fs::package_key]

db_multirow folders select_top_offending_folders {} {
    set url [site_node_object_map::get_url -object_id $folder_id]
}

ad_return_template
