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
    assert(definition.importMode ~= "reference-only" and definition.importMode ~= "selective-only", "This asset cannot be imported wholesale into runtime")

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

-- Installer-only selection. Source kits are never parented to the DataModel.
-- Every selection becomes a fresh geometry-only model with provenance.
local permitted = {[11961684378]=true,[96103787859080]=true,[9609111841]=true,[8593730677]=true,
    [16551049618]=true,[16592756903]=true,[120661626985584]=true,[16390129962]=true,
    [136978268470872]=true,[72028919182927]=true,[10468403169]=true,
    [130515502281374]=true,[11730123582]=true,[15482908101]=true,[134979255746081]=true}
local cache = {}
local visualClasses = {Decal=true,Texture=true,SurfaceAppearance=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true}
local function countParts(root)
    local count = root:IsA("BasePart") and 1 or 0
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("BasePart") then count += 1 end
    end
    return count
end

function SafeAssetImporter.Select(assetId, exactName)
    assert(permitted[assetId], "Asset not approved for selective geometry import")
    local source=cache[assetId]
    if not source then
        source=AssetService:LoadAssetAsync(assetId)
        assert(source and source:IsA("Model"),"Asset load did not return a Model")
        stripScripts(source)
        for _,d in ipairs(source:GetDescendants()) do
            if d:IsA("Sound") or d:IsA("Animation") or d:IsA("ProximityPrompt") then d:Destroy() end
        end
        cache[assetId]=source
    end
    local selected
    if exactName=="__ALL_STATIC__" then
        assert(assetId==11961684378 or assetId==96103787859080 or assetId==9609111841 or assetId==8593730677,"Whole kit import forbidden")
        selected=source
    elseif assetId==11730123582 and exactName=="__ROCK_GROVE__" then
        for _,d in ipairs(source:GetDescendants()) do
            if d:IsA("Model") and d.Name=="Model" and d.Parent.Name=="Nature Pack" and countParts(d)==16 then
                selected=d;break
            end
        end
    elseif assetId==134979255746081 and exactName:match("^__FLOWER_GROVE_%d+__$") then
        local ordinal=tonumber(exactName:match("(%d+)")) or 1
        for _,container in ipairs(source:GetChildren()) do
            if container:IsA("Model") then
                for _,d in ipairs(container:GetChildren()) do
                    if d:IsA("Model") and countParts(d)==16 then
                        ordinal-=1
                        if ordinal==0 then selected=d;break end
                    end
                end
            end
            if selected then break end
        end
    else
        for _,d in ipairs(source:GetDescendants()) do
            if d.Name==exactName and (d:IsA("Model") or d:IsA("BasePart")) then selected=d; break end
        end
    end
    assert(selected,"Audited selection missing: "..assetId.." / "..tostring(exactName))
    local out=Instance.new("Model"); out.Name=exactName
    local originals=selected:IsA("BasePart") and {selected} or selected:GetDescendants()
    local count=0
    for _,p in ipairs(originals) do
        if p:IsA("BasePart") then
            local c=p:Clone()
            for _,d in ipairs(c:GetDescendants()) do if not visualClasses[d.ClassName] then d:Destroy() end end
            c.Anchored=true; c.CanCollide=false; c.CanTouch=false; c.CanQuery=false
            if c:IsA("MeshPart") then c.RenderFidelity=Enum.RenderFidelity.Performance end
            c.Parent=out; count+=1
        end
    end
    assert(count>0 and count<=24,"Invalid selection part budget")
    local cf=out:GetBoundingBox(); out.WorldPivot=cf
    out:SetAttribute("DeadSignalSourceAssetId",assetId)
    out:SetAttribute("DeadSignalSelection",exactName)
    out:SetAttribute("DeadSignalGeometryOnly",true)
    return out
end
function SafeAssetImporter.ClearSelectionCache()
    for _,m in pairs(cache) do m:Destroy() end
    table.clear(cache)
end
return SafeAssetImporter

