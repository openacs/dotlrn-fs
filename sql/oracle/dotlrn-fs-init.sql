
--
-- The fs applet for dotLRN
-- copyright 2001, OpenForce
-- distributed under GPL v2.0
--
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
		'dotlrn_applet',
		'dotlrn_fs',
		'dotlrn_fs'
	);

	-- add all the hooks

	-- AddApplet
	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddApplet',
	       'dotlrn_fs::add_applet',
	       'TCL'
	);

	-- RemoveApplet
	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveApplet',
	       'dotlrn_fs::remove_applet',
	       'TCL'
	);

	-- AddUser
	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'AddUser',
	       'dotlrn_fs::add_user',
	       'TCL'
	);

	-- RemoveUser
	foo := acs_sc_impl.new_alias (
	       'dotlrn_applet',
	       'dotlrn_fs',
	       'RemoveUser',
	       'dotlrn_fs::remove_user',
	       'TCL'
	);
end;
/
show errors
