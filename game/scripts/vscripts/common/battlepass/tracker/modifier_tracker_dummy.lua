modifier_tracker_dummy = class({})

function modifier_tracker_dummy:IsPurgable() return false end

if not IsServer() then return end

function modifier_tracker_dummy:OnCreated()
	self.events = {}

	for event_name, value in pairs(ProgressTracker.dummy_events_names) do
		table.insert(self.events, value[1])

		self[value[2]] = function(self, params)
			ProgressTracker:EventTriggered(event_name, params)
		end
	end
end

function modifier_tracker_dummy:DeclareFunctions()
	if not self.events or #self.events == 0 then self:OnCreated() end
	return self.events
end


