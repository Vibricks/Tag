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
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
	};

	
	["CanAttack"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
	};


	["Sprinting"] = {
		Bool = false;
		StateType = "Bool";
	};


	["TimedFreeze"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
	};

	["Stunned"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed"
	};

	["ForceRagdoll"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed"
	};

	
	["Iframes"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed"
	};

	["Speed"] = {
		Priority = 1;
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
		DefaultSpeed = 16;
	};

	["Attacking"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
	};
	
	["Dashing"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
	};

	["Sliding"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
	};
	
	["Climbing"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
	};
	
	
	["EndLag"] = {
		StartTime = os.clock();
		Duration = 0;
		StateType = "Timed";
	};
	
	["Emoting"] = {
		StartTime = os.clock();
		Bool = false;
		StateType = "Bool";
	};
	
}

return States
