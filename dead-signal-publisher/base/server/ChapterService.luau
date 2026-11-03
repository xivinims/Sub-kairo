local ChapterService = {}
ChapterService.__index = ChapterService

function ChapterService.new(config, saveService)
    local self = setmetatable({}, ChapterService)
    self.Config = config
    self.SaveService = saveService
    self.ObjectiveChanged = Instance.new("BindableEvent")
    self.ChapterChanged = Instance.new("BindableEvent")
    return self
end

function ChapterService:GetChapter(player)
    local data = self.SaveService:Get(player)
    return data.chapter
end

function ChapterService:SetChapter(player, chapterId)
    assert(self.Config.Chapters[chapterId], "Unknown chapter: " .. tostring(chapterId))

    self.SaveService:Mutate(player, function(data)
        data.chapter = chapterId
        data.checkpoint = self.Config.Chapters[chapterId].firstCheckpoint
        data.objectives = {}
    end)

    self.ChapterChanged:Fire(player, chapterId)
end

function ChapterService:SetObjectiveState(player, objectiveId, state)
    assert(type(objectiveId) == "string" and objectiveId ~= "", "Objective id required")
    assert(state == "inactive" or state == "active" or state == "complete" or state == "failed", "Invalid objective state")

    self.SaveService:Mutate(player, function(data)
        local previous = data.objectives[objectiveId]
        data.objectives[objectiveId] = state
        if state == "complete" and previous ~= "complete" then
            data.stats.puzzlesSolved = (data.stats.puzzlesSolved or 0) + 1
        end
    end)

    self.ObjectiveChanged:Fire(player, objectiveId, state)
end

function ChapterService:GetObjectiveState(player, objectiveId)
    local data = self.SaveService:Get(player)
    return data.objectives[objectiveId] or "inactive"
end

function ChapterService:SetFlag(player, flag, value)
    self.SaveService:Mutate(player, function(data)
        data.flags[flag] = value
    end)
end

function ChapterService:GetFlag(player, flag)
    return self.SaveService:Get(player).flags[flag]
end

function ChapterService:ExportState(player)
    local data = self.SaveService:Get(player)
    return {
        chapter = data.chapter,
        checkpoint = data.checkpoint,
        objectives = table.clone(data.objectives),
        flags = table.clone(data.flags),
        settings = table.clone(data.settings),
    }
end

return ChapterService

