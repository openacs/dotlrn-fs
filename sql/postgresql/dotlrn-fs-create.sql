--
--  Copyright (C) 2001, 2002 MIT
--
--  This file is part of dotLRN.
--
--  dotLRN is free software; you can redistribute it and/or modify it under the
--  terms of the GNU General Public License as published by the Free Software
--  Foundation; either version 2 of the License, or (at your option) any later
--  version.
--
--  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
--  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
--  details.
--


--
-- The fs applet for dotLRN
--
-- ben,arjun@openforce.net
--
-- 10/05/2001
--

-- @author dan chak (chak@openforce.net)
-- ported to postgres 2002-07-09




--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(

) RETURNS integer AS $$
DECLARE
	foo integer;
BEGIN
	-- create the implementation
	foo := acs_sc_impl__new (
		'dotlrn_applet',
		'dotlrn_fs',
		'dotlrn_fs'
	);

	-- add all the hooks

	-- GetPrettyName
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'GetPrettyName',
	       'dotlrn_fs::get_pretty_name',
	       'TCL'
	);

	-- AddApplet
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddApplet',
	       'dotlrn_fs::add_applet',
	       'TCL'
	);

	-- RemoveApplet
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveApplet',
	       'dotlrn_fs::remove_applet',
	       'TCL'
	);

	-- AddAppletToCommunity
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddAppletToCommunity',
	       'dotlrn_fs::add_applet_to_community',
	       'TCL'
	);

	-- RemoveAppletFromCommunity
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveAppletFromCommunity',
	       'dotlrn_fs::remove_applet_from_community',
	       'TCL'
	);

	-- AddUser
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddUser',
	       'dotlrn_fs::add_user',
	       'TCL'
	);

	-- RemoveUser
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveUser',
	       'dotlrn_fs::remove_user',
	       'TCL'
	);

	-- AddUserToCommunity
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddUserToCommunity',
	       'dotlrn_fs::add_user_to_community',
	       'TCL'
	);

	-- RemoveUserFromCommunity
	foo := acs_sc_impl_alias__new (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveUserFromCommunity',
	       'dotlrn_fs::remove_user_from_community',
	       'TCL'
	);

    -- AddPortlet
    foo := acs_sc_impl_alias__new (
          'dotlrn_applet',
          'dotlrn_fs',
          'AddPortlet',
          'dotlrn_fs::add_portlet',
          'TCL'
    );

    -- RemovePortlet
    foo := acs_sc_impl_alias__new (
          'dotlrn_applet',
          'dotlrn_fs',
          'RemovePortlet',
          'dotlrn_fs::remove_portlet',
          'TCL'
    );

    foo := acs_sc_impl_alias__new (
          'dotlrn_applet',
          'dotlrn_fs',
          'Clone',
          'dotlrn_fs::clone',
          'TCL'
    );

    foo := acs_sc_impl_alias__new (
          'dotlrn_applet',
          'dotlrn_fs',
          'ChangeEventHandler',
          'dotlrn_fs::change_event_handler',
          'TCL'
    );

    perform acs_sc_binding__new (
            'dotlrn_applet',
            'dotlrn_fs'
    );

    return 0;

END;
$$ LANGUAGE plpgsql;

select inline_0();
drop function inline_0();
