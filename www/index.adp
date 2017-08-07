<!--

  Copyright (C) 2001, 2002 MIT

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

<master>
<property name="doc(title)">@title;literal@</property>
<property name="context_bar">@context_bar;literal@</property>

<p>This page should not be in the normal link paths of users, but one can get here via <a href="/acs-admin/">/acs-admin/</a>.
<p>
<if @folders:rowcount@ gt 0>
  <center>
    <table width="95%" cellpadding="3" cellspacing="3">
      <tr>
        <th>#dotlrn-fs.Folder#</th>
        <th width="15%">#dotlrn-fs.Size_bytes#</th>
      </tr>
<multiple name="folders">
<if @folders.rownum@ odd>
      <tr bgcolor="#eeeeee">
</if>
<else>
      <tr bgcolor="#ffffff">
</else>
        <td><a href="@folders.url@folder-contents?folder_id=@folders.folder_id@&amp;recurse_p=1&amp;orderby=content_size*">@folders.name@</a></td>
        <td>@folders.content_size@</td>
      </tr>
</multiple>
    </table>
  </center>

</if>
<else>
  <blockqoute><em>#dotlrn-fs.lt_No_top_offending_fold#</em></blockqoute>
</else>

<p>
Manage <a href="all-objects">all objects</a>.