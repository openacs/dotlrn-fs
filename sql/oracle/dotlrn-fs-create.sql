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


declare
	foo integer;
begin
	-- create the implementation
	foo := acs_sc_impl.new (
		impl_contract_name => 'dotlrn_applet',
		impl_name => 'dotlrn_fs',
		impl_pretty_name => 'dotlrn_fs',
		impl_owner_name => 'dotlrn_fs'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'GetPrettyName',
	       'dotlrn_fs::get_pretty_name',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddApplet',
	       'dotlrn_fs::add_applet',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveApplet',
	       'dotlrn_fs::remove_applet',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddAppletToCommunity',
	       'dotlrn_fs::add_applet_to_community',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveAppletFromCommunity',
	       'dotlrn_fs::remove_applet_from_community',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddUser',
	       'dotlrn_fs::add_user',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveUser',
	       'dotlrn_fs::remove_user',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddUserToCommunity',
	       'dotlrn_fs::add_user_to_community',
	       'TCL'
	);

	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveUserFromCommunity',
	       'dotlrn_fs::remove_user_from_community',
	       'TCL'
	);

    foo := acs_sc_impl.new_alias (
        impl_contract_name => 'dotlrn_applet',
        impl_name => 'dotlrn_fs',
        impl_operation_name => 'AddPortlet',
        impl_alias => 'dotlrn_fs::add_portlet',
        impl_pl => 'TCL'
    );

    foo := acs_sc_impl.new_alias (
        impl_contract_name => 'dotlrn_applet',
        impl_name => 'dotlrn_fs',
        impl_operation_name => 'RemovePortlet',
        impl_alias => 'dotlrn_fs::remove_portlet',
        impl_pl => 'TCL'
    );

    foo := acs_sc_impl.new_alias (
        impl_contract_name => 'dotlrn_applet',
        impl_name => 'dotlrn_fs',
        impl_operation_name => 'Clone',
        impl_alias => 'dotlrn_fs::clone',
        impl_pl => 'TCL'
    );

    foo := acs_sc_impl.new_alias (
        impl_contract_name => 'dotlrn_applet',
        impl_name => 'dotlrn_fs',
        impl_operation_name => 'ChangeEventHandler',
        impl_alias => 'dotlrn_fs::change_event_handler',
        impl_pl => 'TCL'
    );

    acs_sc_binding.new (
        contract_name => 'dotlrn_applet',
        impl_name => 'dotlrn_fs'
    );
end;
/
show errors
