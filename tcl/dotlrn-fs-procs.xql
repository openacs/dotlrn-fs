<?xml version="1.0"?>

<!--

  Copyright (C) 2001, 2002 OpenForce, Inc.

  This file is part of dotLRN.

  dotLRN is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2 of the License, or (at your option) any later
  version.

  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

-->

<queryset>

<fullquery name="dotlrn_fs::get_public_folder_id">
<querytext>
select folder_id from cr_folders,cr_items where name='public' and parent_id= :parent_folder_id
</querytext>
</fullquery>

</queryset>
