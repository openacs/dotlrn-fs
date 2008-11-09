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

# dotlrn-fs/www/all-objects.tcl

ad_page_contract {

    Display all file storage objects that have been added or modified within
    the past N days.

    @author <a href="mailto:yon@openforce.net">yon@openforce.net</a>
    @creation-date 2002-04-25
    @version $Id$

} -query {
    {n_past_days:integer 999999}
    {orderby "folder_name,name"}
} -properties {
    n_past_days:onevalue
    days_singular_or_plural:onevalue
    orderby:onevalue
    table:onevalue
}

set user_id [ad_conn user_id]

set days_singular_or_plural [ad_decode $n_past_days "1" [_ dotlrn-fs.day] [_ dotlrn-fs.days]]

form create n_past_days_form

set options [list [list [_ dotlrn-fs.All] 999999] {1 1} {2 2} {3 3} {7 7} {14 14} {30 30}]
element create n_past_days_form n_past_days \
    -label "" \
    -datatype text \
    -widget select \
    -options $options \
    -html {onChange document.n_past_days_form.submit()} \
    -value $n_past_days

element create n_past_days_form orderby \
    -label "[_ dotlrn-fs.Order_By]" \
    -datatype text \
    -widget hidden \
    -value $orderby

if {[form is_valid n_past_days_form]} {
    form get_values n_past_days_form \
        n_past_days orderby
}

set table_def [list]

lappend table_def [list name [_ dotlrn-fs.Name] {fs_objects.name $order} "<td width=\"30%\"><a href=\"\[ad_decode \$type folder \"\[site_node_object_map::get_url -object_id \$object_id]?folder_id=\$object_id\" url \"\[site_node_object_map::get_url -object_id \$parent_id]url-goto?url_id=\$object_id\" \"\[site_node_object_map::get_url -object_id \$parent_id]download/\$file_upload_name?version_id=\$live_revision\"]\">\$name</a></td>"]
lappend table_def [list folder_name [_ dotlrn-fs.Folder] {} "<td width=\"30%\"><a href=\"\[site_node_object_map::get_url -object_id \$parent_id]?folder_id=\$parent_id\">\$folder_name</a></td>"]
lappend table_def [list type [_ dotlrn-fs.Type] {fs_objects.type $order} {c}]
lappend table_def [list content_size [_ dotlrn-fs.Size] {fs_objects.content_size $order} {<td align=\"center\">[ad_decode $type folder "$content_size item[ad_decode $content_size 1 {} s]" url {} "$content_size byte[ad_decode $content_size 1 {} s]"]</td>}]
lappend table_def [list last_modified [_ dotlrn-fs.Last_Modified] {fs_objects.last_modified $order} {<td align=\"center\">[lc_time_fmt $last_modified "%q"]</td>}]

set dotlrn_package_key [dotlrn::package_key]

set table [ad_table \
    -Tmissing_text "<p><em>[_ dotlrn-fs.No_contents_found]</em></p>" \
    -Torderby $orderby \
    -Ttable_extra_html {width="95%"} \
    select_folder_contents \
    "" \
    $table_def
]

ad_return_template
