local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

if CivicOS.Scheduler then
    CivicOS.Scheduler:register("sla", function()
        return CivicOS.SlaService:processDue()
    end, 1000)
end

return CivicOS.SlaWorker or true
