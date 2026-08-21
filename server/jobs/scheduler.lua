local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Scheduler = {
    jobs = {},
    running = false,
    _threadStarted = false,
}

local function nowMs()
    if type(GetGameTimer) == "function" then return GetGameTimer() end
    return os.time() * 1000
end

local function log(level, message, context)
    if CivicOS.Logger and type(CivicOS.Logger[level]) == "function" then
        CivicOS.Logger[level]("SCHEDULER", message, context)
    end
end

function Scheduler:register(name, handler, intervalMs)
    if type(name) ~= "string" or name == "" or type(handler) ~= "function" then
        return CivicOS.Result.err("SCHEDULER_INVALID_JOB", "Scheduler job definition is invalid.")
    end
    self.jobs[name] = {
        handler = handler,
        intervalMs = math.max(100, tonumber(intervalMs) or 1000),
        nextRun = nowMs(),
    }
    return { ok = true, data = name }
end

function Scheduler:runDue(timestamp)
    local now = timestamp or nowMs()
    local maxJobs = CivicOS.Config and CivicOS.Config.Scheduler and CivicOS.Config.Scheduler.MaxJobsPerTick or 25
    local processed = 0
    for name, job in pairs(self.jobs) do
        if processed >= maxJobs then break end
        if job.nextRun <= now then
            job.nextRun = now + job.intervalMs
            processed = processed + 1
            local ok, result = pcall(job.handler)
            if not ok then
                log("error", "Scheduled job failed.", { job = name })
            elseif result and result.ok == false then
                log("warn", "Scheduled job returned an error.", { job = name, code = result.error and result.error.code })
            end
        end
    end
    return { ok = true, data = { processed = processed } }
end

function Scheduler:start()
    if self.running then return { ok = true, data = true } end
    self.running = true
    if self._threadStarted or type(CreateThread) ~= "function" then return { ok = true, data = true } end
    self._threadStarted = true
    CreateThread(function()
        while self.running do
            local interval = CivicOS.Config and CivicOS.Config.Scheduler and CivicOS.Config.Scheduler.IntervalMs or 1000
            Wait(math.max(100, tonumber(interval) or 1000))
            self:runDue()
        end
        self._threadStarted = false
    end)
    return { ok = true, data = true }
end

function Scheduler:stop()
    self.running = false
end

CivicOS.Scheduler = Scheduler
return Scheduler
