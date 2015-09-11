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
    {orderby "name"}
} -properties {
    n_past_days:onevalue
    days_singular_or_plural:onevalue
    orderby:onevalue
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

set dotlrn_package_key [dotlrn::package_key]

template::list::create -name files \
    -multirow files_list \
    -no_data "#dotlrn-fs.No_contents_found#" \
    -elements {
	name {
	    label "#dotlrn-fs.Name#"
	    link_url_col name_url
	    orderby name
	}
	folder_name {
	    label "#dotlrn-fs.Folder#"
	    html {width "30%"}
	    link_url_col folder_name_url
	    orderby folder_name
	}
	type {
	    label "#dotlrn-fs.Type#"
	    orderby type
	}
	content_size {
	    label "#dotlrn-fs.Size#"
	    html {align center}
	    orderby content_size
	}
	last_modified {
	    label "#dotlrn-fs.Last_Modified#"
	    html {align center}
	    orderby last_modified
	}
    }

db_multirow -extend {name_url folder_name_url content_size_url} files_list select_folder_contents {} {
    set folder_name_url "[site_node_object_map::get_url -object_id $parent_id]?folder_id=$parent_id"
    set last_modified [lc_time_fmt $last_modified "%q"]
    switch $type {
	"folder" {
	    set name_url "[site_node_object_map::get_url -object_id $object_id]?folder_id=$object_id"
	    set content_size "$content_size item[ad_decode $content_size 1 {} s]"
	}
	"url" {
	    set name_url "[site_node_object_map::get_url -object_id $parent_id]url-goto?url_id=$object_id"
	    set content_size "$content_size byte[ad_decode $content_size 1 {} s]"
	}
	default {
	    set name_url "[site_node_object_map::get_url -object_id $parent_id]download/$file_upload_name?version_id=$live_revision" 
	}
    }
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
