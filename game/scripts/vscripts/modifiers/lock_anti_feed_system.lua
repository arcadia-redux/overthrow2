lock_anti_feed_system = class({})

function lock_anti_feed_system:IsHidden()
    return true
end

function lock_anti_feed_system:OnCreated(event)

end

function lock_anti_feed_system:IsPurgable()
    return false
end

function lock_anti_feed_system:RemoveOnDeath()
    return false
end