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

<master>
<property name="title">@title@</property>
<property name="context_bar">@context_bar@</property>

<if @folders:rowcount@ gt 0>

  <center>
    <table width="95%" cellpadding="3" cellspacing="3">
      <tr>
        <th>Folder</th>
        <th width="15%">Size (bytes)</th>
      </tr>
<multiple name="folders">
<if @folders.rownum@ odd>
      <tr bgcolor="#ececec">
</if>
<else>
      <tr bgcolor="#ffffff">
</else>
        <td><a href="@folders.url@folder-contents?folder_id=@folders.folder_id@&recurse_p=1&orderby=content_size*">@folders.name@</a></td>
        <td>@folders.content_size@</td>
      </tr>
</multiple>
    </table>
  </center>

</if>
<else>
  <blockqoute><i>No top offending folders to display</i></blockqoute>
</else>
