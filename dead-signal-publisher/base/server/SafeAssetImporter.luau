local AssetService = game:GetService("AssetService")

local SafeAssetImporter = {}

local SCRIPT_CLASSES = {
    Script = true,
    LocalScript = true,
    ModuleScript = true,
}

local function stripScripts(root)
    local removed = 0
    for _, descendant in ipairs(root:GetDescendants()) do
        if SCRIPT_CLASSES[descendant.ClassName] then
            descendant:Destroy()
            removed += 1
        end
    end
    return removed
end

local function normalizeStatic(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanTouch = false
        end
    end
end

function SafeAssetImporter.Load(definition)
    assert(type(definition) == "table", "Asset definition required")
    assert(type(definition.id) == "number", "Asset id required")
    assert(definition.importMode ~= "reference-only", "Reference-only asset cannot be imported into runtime")

    local asset = AssetService:LoadAssetAsync(definition.id)
    assert(asset, "AssetService returned nil for " .. tostring(definition.id))

    local removedScripts = 0
    if definition.stripScripts ~= false then
        removedScripts = stripScripts(asset)
    end

    if definition.importMode == "static" then
        normalizeStatic(asset)
    end

    asset:SetAttribute("DeadSignalSourceAssetId", definition.id)
    asset:SetAttribute("DeadSignalImportMode", definition.importMode)
    asset:SetAttribute("DeadSignalScriptsRemoved", removedScripts)

    return asset, {
        assetId = definition.id,
        removedScripts = removedScripts,
        importMode = definition.importMode,
    }
end

function SafeAssetImporter.CloneStatic(definition, parent, pivot)
    local asset, report = SafeAssetImporter.Load(definition)
    asset.Parent = parent
    if pivot then asset:PivotTo(pivot) end
    return asset, report
end

return SafeAssetImporter
