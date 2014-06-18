generic module ResourcePowerManagerProviderP(){
	provides interface Resource;
	provides interface ResourceDefaultOwner;
	uses interface Resource as SubResource;
}
implementation{
	norace bool requested = FALSE;
	norace bool defaultOwner=TRUE;
	norace bool halfReady=FALSE;
	
  async command error_t Resource.request(){
		atomic{
			if(requested){
				if(call SubResource.isOwner())
					return EALREADY;
				else
					return EBUSY;
			}
			requested = TRUE;
		}
		halfReady = FALSE;
		signal ResourceDefaultOwner.requested();
		return call SubResource.request();
	}
	
	async command error_t Resource.immediateRequest(){
		atomic{
			if(requested){
				if(call SubResource.isOwner())
					return EALREADY;
				else
					return EBUSY;
			}
			requested = TRUE;
		}
		halfReady = FALSE;
		signal ResourceDefaultOwner.immediateRequested();
		if( !defaultOwner )
			return call SubResource.immediateRequest();
	}

	async command error_t Resource.release(){
		error_t err = call SubResource.release();
		if(err == SUCCESS){
			defaultOwner = TRUE;
			signal ResourceDefaultOwner.granted();
			requested = FALSE;
		}
		return err;
	}

	async command bool Resource.isOwner(){
		return call SubResource.isOwner();
	}
	
	event void SubResource.granted(){
		if(halfReady)
			signal Resource.granted();
		else
			halfReady = TRUE;
	}
	
	task void grantedTask(){
		signal Resource.granted();
	}
	
	async command error_t ResourceDefaultOwner.release(){
		if( requested && defaultOwner){
			defaultOwner = FALSE;
			if(halfReady)
				post grantedTask();
			else
				halfReady = TRUE;
		}
		return SUCCESS;
	}
	
	async command bool ResourceDefaultOwner.isOwner(){
		return defaultOwner;
	}
}