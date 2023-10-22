RegisterNetEvent("kloud-farm:client:pickProp", function(data)
    local zoneData = KloudDev.Locations[data.currentZone]
    local canStart, msg = lib.callback.await("kloud-farm:callback:canStart", false, zoneData)
    if not canStart then Notify(msg, "error") return end
    _G.IsBusy = true
    if zoneData.anim.scenario then
        TaskStartScenarioInPlace(cache.ped, zoneData.anim.scenario, 0, false)
    else
        PlayAnim(cache.ped, zoneData.anim.dict, zoneData.anim.clip, -1, zoneData.anim.upperBody)
    end
    if zoneData.action.type == "progress" then
        
        local progress = Progress(zoneData.action.progressDuration, locale("uprooting", FormatStr(zoneData.item.label)))
        if not progress then 
            ClearPedTasksImmediately(cache.ped)
            DeleteProp(data.entity)
            _G.IsBusy = false
            return
        end
    elseif zoneData.action.type == "skillCheck" then
        if not SkillCheck(zoneData.action.skillCheckDifficulty, zoneData.action.skillCheckInputs) then 
            ClearPedTasksImmediately(cache.ped)
            DeleteProp(data.entity)
            _G.IsBusy = false
            return
        end
    end
    _G.IsBusy = false
    ClearPedTasksImmediately(cache.ped)
    if not DoesEntityExist(data.entity) then return end
    DeleteProp(data.entity)
    lib.callback("kloud-farm:callback:uprooted", 3000, nil, zoneData)
end)

RegisterNetEvent("kloud-farm:client:pickTree", function(data)
    local zoneData = KloudDev.Trees[data.currentZone]
    local canStart, msg = lib.callback.await("kloud-farm:callback:canStart", false, zoneData)
    print(json.encode(data))
    if not canStart then Notify(msg, "error") return end
    _G.IsBusy = true
    if zoneData.anim.scenario then
        TaskStartScenarioInPlace(cache.ped, zoneData.anim.scenario, 0, false)
    else
        PlayAnim(cache.ped, zoneData.anim.dict, zoneData.anim.clip, -1, zoneData.anim.upperBody)
    end
    if zoneData.action.type == "progress" then
        local progress = Progress(zoneData.action.progressDuration, locale("uprooting", FormatStr(zoneData.item.label)))
        if not progress then
            ClearPedTasksImmediately(cache.ped)
            _G.IsBusy = false
            return
        end
    elseif zoneData.action.type == "skillCheck" then
        if not SkillCheck(zoneData.action.skillCheckDifficulty, zoneData.action.skillCheckInputs) then 
            ClearPedTasksImmediately(cache.ped)
            _G.IsBusy = false
            return
        end
    end
    ClearPedTasksImmediately(cache.ped)
    _G.IsBusy = false
    table.insert(_T.PickedTrees, {entity = data.name, cooldown = zoneData.cooldown})
    TriggerEvent("kloud-farm:client:startTreesCooldown")
    lib.callback("kloud-farm:callback:uprooted", 3000, nil, zoneData)
end)

RegisterNetEvent("kloud-farm:client:startTreesCooldown", function()
    if _G.Cooldown then return end
    _G.Cooldown = true
    while true do
        for k, tree in pairs(_T.PickedTrees) do
            for key, value in pairs(tree) do
                if key == "cooldown" then
                    _T.PickedTrees[k].cooldown = value - 1
                    print("Cooldown: " .. value)
                    if value <= 0 then
                        table.remove(_T.PickedTrees, k)
                    end
                end
            end
        end
        if next(_T.PickedTrees) == nil then
            _G.Cooldown = false
            return 
        end
        Wait(1000)
    end
end)

RegisterNetEvent("kloud-farm:client:wash", function()
    HideText()
    local optionsTbl = {}
    for _, v in pairs(KloudDev.WashLocations.items) do
        if GetItemCount(v[1], nil, false) > 0 then
            local values = {}
            for i = 1, GetItemCount(v[1], nil, false) do
                if i <= KloudDev.WashLocations.maxWash then
                    table.insert(values, i)
                end
            end
            table.insert(optionsTbl, {
                label = "x1 ".. FormatStr(v[1]).." : x1 "..FormatStr(v[2]),
                icon = KloudDev.ImagePath .. v[2] .. ".png",
                values = values,
                args = {
                    itemRequired = v[1],
                    itemResult = v[2]
                }
            })
        end
    end
    if next(optionsTbl) == nil then
        Notify(locale("no_crops_to_wash"), "error")
        return
    end
    lib.registerMenu({
        id = "kloud-farm:wash",
        title = locale("wash_crops"),
        position = "top-right",
        options = optionsTbl,
        disableInput = true,
    }, function(selected, scrollIndex, args)
        WashCrops({itemRequired = args.itemRequired, itemResult = args.itemResult, amount = scrollIndex})
    end)
    lib.showMenu("kloud-farm:wash")
end)

AddEventHandler("onResourceStop", function(name)
    if GetCurrentResourceName() ~= name then return end
    ClearProps()
end)