local States = {
	["Frozen"] = {
		Bool = false;
		StateType = "Bool";
	};

	["LedgeGrabbing"] = {
		Bool = false;
		StateType = "Bool";
	};

	["CanSprint"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};

	
	["CanAttack"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};

	["Vaulting"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};


	["Sprinting"] = {
		Bool = false;
		StateType = "Bool";
	};


	["TimedFreeze"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};

	["Stunned"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed"
	};

	["ForceRagdoll"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed"
	};

	
	["Iframes"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed"
	};

	["Speed"] = {
		Priority = 1;
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
		DefaultSpeed = 16;
	};

	["Attacking"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};
	
	["Dashing"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};

	["Sliding"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};
	
	["Climbing"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};
	["Ragdolled"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};
	
	["EndLag"] = {
		StartTime = tick();
		Duration = 0;
		StateType = "Timed";
	};
	
	["Emoting"] = {
		StartTime = tick();
		Bool = false;
		StateType = "Bool";
	};
	
}

return States
