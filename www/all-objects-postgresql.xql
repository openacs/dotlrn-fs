<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="select_folder_contents">
        <querytext>
    select fs_objects.*,
           fs_folders.name as folder_name
    from fs_objects,
         fs_folders
    where fs_objects.object_id in (
    	  WITH RECURSIVE fs_objects(object_id) as (
    	       select acs_objects.object_id
    	       from acs_objects
    	       where acs_objects.context_id in (
    	       	     select site_node_object_mappings.object_id
    		     from site_node_object_mappings,
    		     site_nodes,
    		     fs_root_folders
    		     where site_node_object_mappings.node_id = site_nodes.node_id
    		     and site_node_object_mappings.object_id = fs_root_folders.folder_id
    		     and site_nodes.parent_id in (
    		     	 select sn.node_id
    			 from site_nodes sn,
    			 apm_packages ap
    			 where sn.object_id = ap.package_id
    			 and ap.package_key = 'dotlrn'
    		    	 )
    		    )
    
	   UNION ALL 

	   select ao.object_id 
    	   from acs_objects ao join fs_objects fo on (fo.object_id = ao.context_id)
	   )
	   select object_id from fs_objects
	   )
    and fs_objects.parent_id = fs_folders.folder_id
    and fs_objects.type <> 'folder'
    and fs_objects.last_modified >= (now() - (:n_past_days || ' days')::interval)
    and 't' = acs_permission__permission_p(fs_objects.object_id, :user_id, 'read')
    [template::list::orderby_clause -name files -orderby]
        </querytext>
    </fullquery>

</queryset>
