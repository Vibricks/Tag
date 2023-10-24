local PhysicsService = game:GetService("PhysicsService")


local SlideBarrier = PhysicsService:RegisterCollisionGroup("SlideBarrier")
local Slider = PhysicsService:RegisterCollisionGroup("Slider")


PhysicsService:CollisionGroupSetCollidable("Slider", "SlideBarrier", false)