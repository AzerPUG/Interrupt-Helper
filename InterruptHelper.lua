if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end

AZP.VersionControl["Interrupt Helper"] = 17
if AZP.InterruptHelper == nil then AZP.InterruptHelper = {} end

local AZPIHSelfFrame, AZPInterruptHelperOptionPanel = nil, nil
local AZPInterruptOrder, AZPInterruptHelperGUIDs, AZPInterruptOrderEditBoxes = {}, {}, {}
if AZPInterruptHelperSettingsList == nil then AZPInterruptHelperSettingsList = {} end

if AZPIHShownLocked == nil then AZPIHShownLocked = {false, false} end

local UpdateFrame, EventFrame = nil, nil
local HaveShowedUpdateNotification = false

local PopUpFrame = nil
local curScale = 0.75
local soundID = 8959
local soundChannel = 1

local blinkingBoolean = false
local blinkingTicker, cooldownTicker = nil, nil

local optionHeader = "|cFF00FFFFInterrupt Helper|r"

function AZP.InterruptHelper:OnLoadBoth()
    for i = 1, 10 do
        AZPInterruptOrder[i] = {}
    end
    AZP.InterruptHelper:CreateMainFrame()
    AZP.InterruptHelper:CreatePopUpFrame()
    C_ChatInfo.RegisterAddonMessagePrefix("AZPSHAREINFO")
end

function AZP.InterruptHelper:OnLoadCore()
    AZP.InterruptHelper:OnLoadBoth()
    AZP.Core:RegisterEvents("COMBAT_LOG_EVENT_UNFILTERED", function(...) AZP.InterruptHelper:eventCombatLogEventUnfiltered(...) end)
    AZP.Core:RegisterEvents("VARIABLES_LOADED", function(...) AZP.InterruptHelper:eventVariablesLoaded(...) end)
    AZP.Core:RegisterEvents("CHAT_MSG_ADDON", function(...) AZP.InterruptHelper:eventChatMsgAddonInterrupts(...) end)
    AZP.Core:RegisterEvents("ENCOUNTER_START", function(...) AZP.InterruptHelper:eventPlayerEnterCombat(...) end)
    AZP.Core:RegisterEvents("ENCOUNTER_END", function(...) AZP.InterruptHelper:eventPlayerLeaveCombat(...) end)

    AZP.OptionsPanels:RemovePanel("Interrupt Helper")
    AZP.OptionsPanels:Generic("Interrupt Helper", optionHeader, function(frame)
        AZPInterruptHelperOptionPanel = frame
        AZP.InterruptHelper:FillOptionsPanel(frame)
    end)
end

function AZP.InterruptHelper:OnLoadSelf()
    C_ChatInfo.RegisterAddonMessagePrefix("AZPVERSIONS")

    EventFrame = CreateFrame("FRAME", nil)
    EventFrame:RegisterEvent("CHAT_MSG_ADDON")
    EventFrame:RegisterEvent("VARIABLES_LOADED")
    EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    EventFrame:RegisterEvent("ENCOUNTER_START")
    EventFrame:RegisterEvent("ENCOUNTER_END")
    EventFrame:SetScript("OnEvent", function(...) AZP.InterruptHelper:OnEvent(...) end)

    AZPInterruptHelperOptionPanel = CreateFrame("FRAME", nil)
    AZPInterruptHelperOptionPanel.name = "|cFF00FFFFAzerPUG's Interrupt Helper|r"
    InterfaceOptions_AddCategory(AZPInterruptHelperOptionPanel)

    AZPInterruptHelperOptionPanel.header = AZPInterruptHelperOptionPanel:CreateFontString("AZPInterruptHelperOptionPanel", "ARTWORK", "GameFontNormalHuge")
    AZPInterruptHelperOptionPanel.header:SetPoint("TOP", 0, -10)
    AZPInterruptHelperOptionPanel.header:SetText("|cFF00FFFFAzerPUG's Interrupt Helper Options!|r")

    AZPInterruptHelperOptionPanel.footer = AZPInterruptHelperOptionPanel:CreateFontString("AZPInterruptHelperOptionPanel", "ARTWORK", "GameFontNormalLarge")
    AZPInterruptHelperOptionPanel.footer:SetPoint("TOP", 0, -400)
    AZPInterruptHelperOptionPanel.footer:SetText(
        "|cFF00FFFFAzerPUG Links:\n" ..
        "Website: www.azerpug.com\n" ..
        "Discord: www.azerpug.com/discord\n" ..
        "Twitch: www.twitch.tv/azerpug\n|r"
    )

    AZP.InterruptHelper:FillOptionsPanel(AZPInterruptHelperOptionPanel)
    AZP.InterruptHelper:OnLoadBoth()

    UpdateFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    UpdateFrame:SetPoint("CENTER", 0, 250)
    UpdateFrame:SetSize(400, 200)
    UpdateFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    UpdateFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    UpdateFrame.header = UpdateFrame:CreateFontString("UpdateFrame", "ARTWORK", "GameFontNormalHuge")
    UpdateFrame.header:SetPoint("TOP", 0, -10)
    UpdateFrame.header:SetText("|cFFFF0000AzerPUG's InterruptHelper is out of date!|r")

    UpdateFrame.text = UpdateFrame:CreateFontString("UpdateFrame", "ARTWORK", "GameFontNormalLarge")
    UpdateFrame.text:SetPoint("TOP", 0, -40)
    UpdateFrame.text:SetText("Error!")

    local UpdateFrameCloseButton = CreateFrame("Button", nil, UpdateFrame, "UIPanelCloseButton")
    UpdateFrameCloseButton:SetWidth(25)
    UpdateFrameCloseButton:SetHeight(25)
    UpdateFrameCloseButton:SetPoint("TOPRIGHT", UpdateFrame, "TOPRIGHT", 2, 2)
    UpdateFrameCloseButton:SetScript("OnClick", function() UpdateFrame:Hide() end )

    UpdateFrame:Hide()
end

function AZP.InterruptHelper:FillOptionsPanel(frameToFill)
    frameToFill.LockMoveButton = CreateFrame("Button", nil, frameToFill, "UIPanelButtonTemplate")
    frameToFill.LockMoveButton:SetSize(100, 25)
    frameToFill.LockMoveButton:SetPoint("TOP", 100, -50)
    frameToFill.LockMoveButton:SetText("Share List")
    frameToFill.LockMoveButton:SetScript("OnClick", function() AZP.InterruptHelper:ShareInterrupters() end )

    frameToFill.LockMoveButton = CreateFrame("Button", nil, frameToFill, "UIPanelButtonTemplate")
    frameToFill.LockMoveButton:SetSize(100, 25)
    frameToFill.LockMoveButton:SetPoint("TOP", 100, -100)
    frameToFill.LockMoveButton:SetText("Lock Interrupts")
    frameToFill.LockMoveButton:SetScript("OnClick", function ()
        if AZPIHSelfFrame:IsMovable() then
            AZPIHSelfFrame:EnableMouse(false)
            AZPIHSelfFrame:SetMovable(false)
            frameToFill.LockMoveButton:SetText("Move Interrupts!")
            AZPIHShownLocked[1] = true
        else
            AZPIHSelfFrame:EnableMouse(true)
            AZPIHSelfFrame:SetMovable(true)
            frameToFill.LockMoveButton:SetText("Lock Interrupts")
            AZPIHShownLocked[1] = false
        end
    end)

    frameToFill.ShowHideButton = CreateFrame("Button", nil, frameToFill, "UIPanelButtonTemplate")
    frameToFill.ShowHideButton:SetSize(100, 25)
    frameToFill.ShowHideButton:SetPoint("TOP", 100, -150)
    frameToFill.ShowHideButton:SetText("Hide Interrupts!")
    frameToFill.ShowHideButton:SetScript("OnClick", function () AZP.InterruptHelper:ShowHideFrame() end)

    frameToFill:Hide()

    for i = 1, 10 do
        local interruptersFrame = CreateFrame("Frame", nil, frameToFill)
        interruptersFrame:SetSize(200, 25)
        interruptersFrame:SetPoint("LEFT", 75, -30*i + 250)
        interruptersFrame.editbox = CreateFrame("EditBox", nil, interruptersFrame, "InputBoxTemplate")
        interruptersFrame.editbox:SetSize(100, 25)
        interruptersFrame.editbox:SetPoint("LEFT", 50, 0)
        interruptersFrame.editbox:SetAutoFocus(false)
        interruptersFrame.text = interruptersFrame:CreateFontString("interruptersFrame", "ARTWORK", "GameFontNormalLarge")
        interruptersFrame.text:SetSize(100, 25)
        interruptersFrame.text:SetPoint("LEFT", -50, 0)
        interruptersFrame.text:SetText("Interrupter " .. i .. ":")

        AZPInterruptOrderEditBoxes[i] = interruptersFrame

        interruptersFrame.editbox:SetScript("OnEditFocusLost",
        function()
            for j = 1, 10 do
                if (AZPInterruptOrderEditBoxes[j].editbox:GetText() ~= nil and AZPInterruptOrderEditBoxes[j].editbox:GetText() ~= "") then
                    for k = 1, 40 do
                        if GetRaidRosterInfo(k) ~= nil then             -- For party GetPartyMember(j) ~= nil but this excludes the player.
                            local curGUID = UnitGUID("raid" .. k)
                            local curName = GetRaidRosterInfo(k)
                            if string.find(curName, "-") then
                                curName = string.match(curName, "(.+)-")
                            end
                            if curName == AZPInterruptOrderEditBoxes[j].editbox:GetText() then
                                AZPInterruptOrder[j][1] = curGUID
                                AZPInterruptHelperGUIDs[curGUID] = curName
                            end
                        end
                    end
                else
                    AZPInterruptOrder[j][1] = nil
                end
                AZPInterruptHelperSettingsList[j] = AZPInterruptOrder[j][1]
            end
            AZP.InterruptHelper:SaveInterrupts()
            AZP.InterruptHelper:ChangeFrameHeight()
        end)
    end
    frameToFill:Hide()
end

function AZP.InterruptHelper:CreateMainFrame()
    AZPIHSelfFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    AZPIHSelfFrame:EnableMouse(true)
    AZPIHSelfFrame:SetMovable(true)
    AZPIHSelfFrame:RegisterForDrag("LeftButton")
    AZPIHSelfFrame:SetScript("OnDragStart", AZPIHSelfFrame.StartMoving)
    AZPIHSelfFrame:SetScript("OnDragStop", function() AZPIHSelfFrame:StopMovingOrSizing() AZP.InterruptHelper:SaveLocation() end)
    AZPIHSelfFrame:SetScript("OnEvent", function(...) AZP.InterruptHelper:OnEvent(...) end)
    AZPIHSelfFrame:SetSize(200, 200)
    AZPIHSelfFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    AZPIHSelfFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.75)
    AZPIHSelfFrame:SetBackdropBorderColor(1, 1, 1, 1)
    AZPIHSelfFrame.header = AZPIHSelfFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    AZPIHSelfFrame.header:SetSize(AZPIHSelfFrame:GetWidth(), AZPIHSelfFrame:GetHeight())
    AZPIHSelfFrame.header:SetPoint("TOP", 0, -10)
    AZPIHSelfFrame.header:SetJustifyV("TOP")
    AZPIHSelfFrame.header:SetText("Interrupt Order!")

    AZPIHSelfFrame.text = AZPIHSelfFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    AZPIHSelfFrame.text:SetSize(AZPIHSelfFrame:GetWidth(), AZPIHSelfFrame:GetHeight())
    AZPIHSelfFrame.text:SetPoint("TOP", 0, -40)
    AZPIHSelfFrame.text:SetJustifyV("TOP")
    AZPIHSelfFrame.text:SetText("Nothing!")

    local IUAddonFrameCloseButton = CreateFrame("Button", nil, AZPIHSelfFrame, "UIPanelCloseButton")
    IUAddonFrameCloseButton:SetSize(20, 21)
    IUAddonFrameCloseButton:SetPoint("TOPRIGHT", AZPIHSelfFrame, "TOPRIGHT", 2, 2)
    IUAddonFrameCloseButton:SetScript("OnClick", function() AZP.InterruptHelper:ShowHideFrame() end )

    for i = 1, 10 do
        AZPInterruptOrder[i][2] = CreateFrame("StatusBar", nil, AZPIHSelfFrame)
        AZPInterruptOrder[i][2]:SetSize(AZPIHSelfFrame:GetWidth() - 20, 18)
        AZPInterruptOrder[i][2]:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        AZPInterruptOrder[i][2]:SetPoint("TOP", 0, -20 * i - 20)
        AZPInterruptOrder[i][2]:SetMinMaxValues(0, 100)
        AZPInterruptOrder[i][2]:SetValue(100)
        AZPInterruptOrder[i][2].name = AZPInterruptOrder[i][2]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        AZPInterruptOrder[i][2].name:SetSize(AZPInterruptOrder[i][2]:GetWidth() - 25, 16)
        AZPInterruptOrder[i][2].name:SetPoint("CENTER", 0, -1)
        AZPInterruptOrder[i][2].name:SetText("charName")
        AZPInterruptOrder[i][2].bg = AZPInterruptOrder[i][2]:CreateTexture(nil, "BACKGROUND")
        AZPInterruptOrder[i][2].bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        AZPInterruptOrder[i][2].bg:SetAllPoints(true)
        AZPInterruptOrder[i][2].bg:SetVertexColor(1, 0, 0)
        AZPInterruptOrder[i][2].cooldown = AZPInterruptOrder[i][2]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        AZPInterruptOrder[i][2].cooldown:SetSize(25, 16)
        AZPInterruptOrder[i][2].cooldown:SetPoint("RIGHT", -5, 0)
        AZPInterruptOrder[i][2].cooldown:SetText("-")
        AZPInterruptOrder[i][2]:SetStatusBarColor(0, 0.75, 1)
        AZPInterruptOrder[i][2]:Hide()
    end
end

function AZP.InterruptHelper:CreatePopUpFrame()
    PopUpFrame = CreateFrame("FRAME", nil, UIParent)
    PopUpFrame:SetPoint("CENTER", 0, 250)
    PopUpFrame:SetSize(200, 50)

    PopUpFrame.text = PopUpFrame:CreateFontString("PopUpFrame", "ARTWORK", "GameFontNormalHuge")
    PopUpFrame.text:SetPoint("CENTER", 0, 0)
    PopUpFrame.text:SetText("|cFFFF0000INTERRUPT NEXT!|r")
    PopUpFrame.text:SetScale(0.5)
    PopUpFrame.text:Hide()
end

function AZP.InterruptHelper:eventCombatLogEventUnfiltered(...)
    local v1, combatEvent, v3, UnitGUID, casterName, v6, v7, destGUID, destName, v10, v11, spellID, v13, v14, v15 = CombatLogGetCurrentEventInfo()
    -- v12 == SpellID, but not always, sometimes several IDs for one spell (when multiple things happen on one spell)
    if combatEvent == "SPELL_CAST_SUCCESS" then
        local unitName = UnitFullName("PLAYER")
        if AZP.InterruptHelper.interruptSpells[spellID] ~= nil then
            print(UnitGUID, casterName, spellID)
            for i = 1, #AZPInterruptOrder do
                local potentialPetGUID = string.match(UnitGUID, "(.*)-")
                if UnitGUID == AZPInterruptOrder[i][1] then
                    AZP.InterruptHelper:StructureInterrupts(UnitGUID, spellID)
                    break
                end
            end
            if casterName == unitName then      -- Change to GUID.
                if blinkingTicker ~= nil then
                    blinkingTicker:Cancel()
                end
                AZP.InterruptHelper:InterruptBlinking(false)
            end
        end
    elseif combatEvent == "UNIT_DIED" then
        for i = 1, #AZPInterruptOrder do
            if destGUID == AZPInterruptOrder[i][1] then
                AZP.InterruptHelper:StructureInterrupts(destGUID, nil)
                break
            end
        end
    end
end

function AZP.InterruptHelper:eventVariablesLoaded(...)
    AZP.InterruptHelper:LoadSavedVars()
    AZP.InterruptHelper:ShareVersion()
end

function AZP.InterruptHelper:eventChatMsgAddonInterrupts(...)
    local prefix, payload, _, sender = ...
    if prefix == "AZPSHAREINFO" then
        AZP.InterruptHelper:ReceiveInterrupters(payload)
    end
end

function AZP.InterruptHelper:eventChatMsgAddonVersion(...)
    local prefix, payload, _, sender = ...
    if prefix == "AZPVERSIONS" then
        local version = AZP.InterruptHelper:GetSpecificAddonVersion(payload, "IH")
        if version ~= nil then
            AZP.InterruptHelper:ReceiveVersion(version)
        end
    end
end

function AZP.InterruptHelper:eventPlayerEnterCombat()
    cooldownTicker = C_Timer.NewTicker(1, function() AZP.InterruptHelper:TickCoolDowns() end, 1000)
end

function AZP.InterruptHelper:eventPlayerLeaveCombat()
    cooldownTicker:Cancel()
end

function AZP.InterruptHelper:LoadSavedVars()
    if AZPInterruptHelperLocation == nil then
        AZPInterruptHelperLocation = {"CENTER", nil, nil, 0, 0}
    end
    AZPIHSelfFrame:SetPoint(AZPInterruptHelperLocation[1], AZPInterruptHelperLocation[4], AZPInterruptHelperLocation[5])
    AZP.InterruptHelper:PutNamesInList()
    AZP.InterruptHelper:SaveInterrupts()
    AZP.InterruptHelper:ChangeFrameHeight()

    if AZPIHShownLocked[1] then
        AZPInterruptHelperOptionPanel.LockMoveButton:SetText("Move Interrupts!")
        AZPIHSelfFrame:EnableMouse(false)
        AZPIHSelfFrame:SetMovable(false)
    else
        AZPInterruptHelperOptionPanel.LockMoveButton:SetText("Lock Interrupts!")
        AZPIHSelfFrame:EnableMouse(true)
        AZPIHSelfFrame:SetMovable(true)
    end

    if AZPIHShownLocked[2] then
        AZPIHSelfFrame:Hide()
        AZPInterruptHelperOptionPanel.ShowHideButton:SetText("Show Interrupts!")
    else
        AZPIHSelfFrame:Show()
        AZPInterruptHelperOptionPanel.ShowHideButton:SetText("Hide Interrupts!")
    end
end

function AZP.InterruptHelper:ShowHideFrame()
    if AZPIHSelfFrame:IsShown() then
        AZPIHSelfFrame:Hide()
        AZPInterruptHelperOptionPanel.ShowHideButton:SetText("Show Interrupts!")
        AZPIHShownLocked[2] = true
    else
        AZPIHSelfFrame:Show()
        AZPInterruptHelperOptionPanel.ShowHideButton:SetText("Hide Interrupts!")
        AZPIHShownLocked[2] = false
    end
end

function AZP.InterruptHelper:PutNamesInList()
    for i = 1, 10 do
        if AZPInterruptHelperSettingsList[i] ~= nil then
            for j = 1, 40 do
                local curName = GetRaidRosterInfo(j)
                local curGUID = UnitGUID("raid" .. j)
                if curName ~= nil then
                    if string.find(curName, "-") then
                        curName = string.match(curName, "(.+)-")
                    end
                    if AZPInterruptHelperSettingsList[i] == curGUID then
                        AZPInterruptHelperGUIDs[curGUID] = curName
                    end
                end
            end
            if AZPInterruptHelperGUIDs[AZPInterruptHelperSettingsList[i]] ~= nil then
                local temp = AZPInterruptHelperGUIDs[AZPInterruptHelperSettingsList[i]]
                AZPInterruptOrderEditBoxes[i].editbox:SetText(temp)
                AZPInterruptOrder[i][1] = AZPInterruptHelperSettingsList[i]
            end
        else
            AZPInterruptOrderEditBoxes[i].editbox:SetText("")
        end
    end
end

function AZP.InterruptHelper:SaveLocation()
    local temp = {}
    temp[1], temp[2], temp[3], temp[4], temp[5] = AZPIHSelfFrame:GetPoint()
    AZPInterruptHelperLocation = temp
end

function AZP.InterruptHelper:ChangeFrameHeight()
    local countGUID = 0
    for i = 1, 10 do
        if AZPInterruptOrder[i] ~= nil then
            if AZPInterruptOrder[i][1] ~= nil then countGUID = countGUID + 1 end
        end
    end
    AZPIHSelfFrame:SetHeight(countGUID * 20 + 50)
end

function AZP.InterruptHelper:TickCoolDowns()
    for i = 1, #AZPInterruptOrder do
        if AZPInterruptOrder[i][3] ~= nil then
            if AZPInterruptOrder[i][3] <= 0 then
                AZPInterruptOrder[i][3] = nil
                AZPInterruptOrder[i][2].cooldown:SetText("-")
                AZPInterruptOrder[i][2]:SetMinMaxValues(0, 100)
                AZPInterruptOrder[i][2]:SetValue(100)
            else
                AZPInterruptOrder[i][3] = AZPInterruptOrder[i][3] - 1
                AZPInterruptOrder[i][2].cooldown:SetText(AZPInterruptOrder[i][3])
                AZPInterruptOrder[i][2]:SetValue(AZPInterruptOrder[i][3])
            end
        end
    end
end

function AZP.InterruptHelper:GetClassColor(classIndex)
    if classIndex ==  0 then return 0.00, 0.00, 0.00          -- None
    elseif classIndex ==  1 then return 0.78, 0.61, 0.43      -- Warrior
    elseif classIndex ==  2 then return 0.96, 0.55, 0.73      -- Paladin
    elseif classIndex ==  3 then return 0.67, 0.83, 0.45      -- Hunter
    elseif classIndex ==  4 then return 1.00, 0.96, 0.41      -- Rogue
    elseif classIndex ==  5 then return 1.00, 1.00, 1.00      -- Priest
    elseif classIndex ==  6 then return 0.77, 0.12, 0.23      -- Death Knight
    elseif classIndex ==  7 then return 0.00, 0.44, 0.87      -- Shaman
    elseif classIndex ==  8 then return 0.25, 0.78, 0.92      -- Mage
    elseif classIndex ==  9 then return 0.53, 0.53, 0.93      -- Warlock
    elseif classIndex == 10 then return 0.00, 1.00, 0.60      -- Monk
    elseif classIndex == 11 then return 1.00, 0.49, 0.04      -- Druid
    elseif classIndex == 12 then return 0.64, 0.19, 0.79      -- Demon Hunter
    end
end

function AZP.InterruptHelper:SaveInterrupts()
    local InterruptOrderText = ""
    for i = 1, 10 do
        if AZPInterruptOrder[i][1] ~= nil then
            AZPInterruptOrder[i][2].name:SetText(AZPInterruptHelperGUIDs[AZPInterruptOrder[i][1]])
            local raidN = nil
            for j = 1, 40 do
                if GetRaidRosterInfo(j) ~= nil then             -- For party GetPartyMember(j) ~= nil but this excludes the player.
                    local curGUID = UnitGUID("raid" .. j)
                    if curGUID == AZPInterruptOrder[i][1] then
                        raidN = ("raid" .. j)
                    end
                end
            end
            if raidN ~= nil then
                local _, _, classIndex = UnitClass(raidN)
                if AZP.InterruptHelper:CheckIfDead(AZPInterruptOrder[i][1]) then
                    AZPInterruptOrder[i][2].name:SetTextColor(0.5, 0.5, 0.5)
                else
                    AZPInterruptOrder[i][2].name:SetTextColor(AZP.InterruptHelper:GetClassColor(classIndex))
                end
            end
            AZPInterruptOrder[i][2]:Show()
        else
            AZPInterruptOrder[i][2]:Hide()
        end
    end
    AZPIHSelfFrame.text:SetText(InterruptOrderText)

    local playerGUID = UnitGUID("player")
    if AZPInterruptOrder[1] ~= nil then
        if AZPInterruptOrder[1][1] == playerGUID then
            curScale = 0.5
            PopUpFrame.text:SetScale(curScale)
            PopUpFrame.text:Show()
            PlaySound(soundID, soundChannel)
            C_Timer.NewTimer(2.5, function() PopUpFrame.text:Hide() end)
            C_Timer.NewTicker(0.005,
            function()
                curScale = curScale + 0.15
                PopUpFrame.text:SetScale(curScale)
            end,
            35)
            blinkingTicker = C_Timer.NewTicker(0.5, function() AZP.InterruptHelper:InterruptBlinking(blinkingBoolean) end, 10)
        else
            AZP.InterruptHelper:InterruptBlinking(false)
        end
    end
end

function AZP.InterruptHelper:InterruptBlinking(boolean)
    if boolean == true then
        AZPIHSelfFrame:SetBackdropColor(1,0,0,1)
        AZPIHSelfFrame:SetBackdropBorderColor(1, 1, 1, 1)
        blinkingBoolean = false
    else
        AZPIHSelfFrame:SetBackdropColor(1, 1, 1, 1)
        AZPIHSelfFrame:SetBackdropBorderColor(1, 0, 0, 1)
        blinkingBoolean = true
    end
end

function AZP.InterruptHelper:CheckIfDead(playerGUID)
    local deathStatus
    for i = 1, 40 do
        local curGUID = UnitGUID("Raid" .. i)
        if curGUID ~= nil then
            if curGUID == playerGUID then
                deathStatus = UnitIsDeadOrGhost("Raid" .. i)
            end
        end
    end
    return deathStatus
end

function AZP.InterruptHelper:StructureInterrupts(interruptedGUID, interruptSpellID)
    local interuptedIndex = nil
    local tempDeadList, tempAliveList, tempInactiveList = {}, {}, {}
    for i = 1, #AZPInterruptOrder do
        if AZPInterruptOrder[i][1] == nil then
            tempInactiveList[#tempInactiveList + 1] = AZPInterruptOrder[i]
        else
            if AZP.InterruptHelper:CheckIfDead(AZPInterruptOrder[i][1]) then
                tempDeadList[#tempDeadList + 1] = AZPInterruptOrder[i]
            else
                tempAliveList[#tempAliveList + 1] = AZPInterruptOrder[i]
            end
        end
    end

    for i = 1, #tempAliveList do
        if tempAliveList[i][1] == interruptedGUID then
            interuptedIndex = i
        end
    end

    if interuptedIndex == nil then interuptedIndex = 1 end

    local tempInterrupter = tempAliveList[interuptedIndex]

    if interruptSpellID ~= nil then
        local spellCooldown = AZP.InterruptHelper:GetSpellCooldown(interruptSpellID)
        tempInterrupter[3] = spellCooldown
        tempInterrupter[2]:SetMinMaxValues(0, spellCooldown)
        tempInterrupter[2].cooldown:SetText(spellCooldown)
    end

    for i = interuptedIndex, #tempAliveList - 1 do
        tempAliveList[i] = tempAliveList[i+1]
    end
    tempAliveList[#tempAliveList] = tempInterrupter

    for i = 1, #tempAliveList do
        AZPInterruptOrder[i] = tempAliveList[i]
    end
    for i = 1, #tempDeadList do
        AZPInterruptOrder[i + #tempAliveList] = tempDeadList[i]
    end
    for i = 1, #tempInactiveList do
        AZPInterruptOrder[i + #tempDeadList + #tempAliveList] = tempInactiveList[i]
    end

    for i = 1, #AZPInterruptOrder do
        AZPInterruptOrder[i][2]:SetPoint("TOP", 0, -20 * i - 20)
    end

    AZP.InterruptHelper:SaveInterrupts()
end

function AZP.InterruptHelper:GetSpellCooldown(interruptSpellID)
    return AZP.InterruptHelper.interruptSpells[interruptSpellID][4]
end

function AZP.InterruptHelper:ShareInterrupters()
    local GUIDString = ""
    for i = 1, #AZPInterruptHelperSettingsList do
        for j = 1, 40 do
            if GetRaidRosterInfo(j) ~= nil then             -- For party GetPartyMember(j) ~= nil but this excludes the player.
                local curGUID = UnitGUID("Raid" .. j)
                if curGUID == AZPInterruptHelperSettingsList[i] then
                    curGUID = string.match(curGUID, "-(.+)")
                    GUIDString = GUIDString .. ":" .. curGUID .. ":"
                end
            end
        end
    end
    if IsInGroup() then
        if IsInRaid() then
            C_ChatInfo.SendAddonMessage("AZPSHAREINFO", GUIDString ,"RAID", 1)
        else
            C_ChatInfo.SendAddonMessage("AZPSHAREINFO", GUIDString ,"PARTY", 1)
        end
    end
end

function AZP.InterruptHelper:ReceiveInterrupters(interruptersString)
    for i = 1, 10 do
        AZPInterruptOrder[i][1] = nil
    end
    AZPInterruptHelperGUIDs = {}
    AZPInterruptHelperSettingsList = {}

    local pattern = ":([^:]+):"
    local stringIndex = 1
    local index = 0
    while stringIndex < #interruptersString do
        local _, endPos = string.find(interruptersString, pattern, stringIndex)
        local unitGUID = string.match(interruptersString, pattern, stringIndex)
        unitGUID = "Player-" .. unitGUID
        stringIndex = endPos + 1
        index = index + 1
        if AZPInterruptOrder[index][1] == nil then
            AZPInterruptOrder[index][1] = unitGUID
        end
    end
    for i = 1, #AZPInterruptOrder do
        if AZPInterruptOrder[i][1] ~= nil then
            for j = 1, 40 do
                if GetRaidRosterInfo(j) ~= nil then
                    local curName = GetRaidRosterInfo(j)           -- For party GetPartyMember(j) ~= nil but this excludes the player.
                    if string.find(curName, "-") then
                        curName = string.match(curName, "(.+)-")
                    end
                    local curGUID = UnitGUID("raid" .. j)
                    if curGUID == AZPInterruptOrder[i][1] then
                        AZPInterruptHelperGUIDs[i] = curName
                        AZPInterruptHelperSettingsList[i] = curGUID
                    end
                end
            end
        end
    end

    AZP.InterruptHelper:PutNamesInList()
    AZP.InterruptHelper:SaveInterrupts()
    AZP.InterruptHelper:ChangeFrameHeight()
end

function AZP.InterruptHelper:ShareVersion()
    local versionString = string.format("|IH:%d|", AZP.VersionControl["Interrupt Helper"])
    if UnitInBattleground("player") ~= nil then
        -- BG stuff?
    else
        if IsInGroup() then
            if IsInRaid() then
                C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"RAID", 1)
            else
                C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"PARTY", 1)
            end
        end
        if IsInGuild() then
            C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"GUILD", 1)
        end
    end
end

function AZP.InterruptHelper:ReceiveVersion(version)
    if version > AZP.VersionControl["Interrupt Helper"] then
        if (not HaveShowedUpdateNotification) then
            HaveShowedUpdateNotification = true
            UpdateFrame:Show()
            UpdateFrame.text:SetText(
                "Please download the new version through the CurseForge app.\n" ..
                "Or use the CurseForge website to download it manually!\n\n" .. 
                "Newer Version: v" .. version .. "\n" .. 
                "Your version: v" .. AZP.VersionControl["Interrupt Helper"]
            )
        end
    end
end

function AZP.InterruptHelper:GetSpecificAddonVersion(versionString, addonWanted)
    local pattern = "|([A-Z]+):([0-9]+)|"
    local index = 1
    while index < #versionString do
        local _, endPos = string.find(versionString, pattern, index)
        local addon, version = string.match(versionString, pattern, index)
        index = endPos + 1
        if addon == addonWanted then
            return tonumber(version)
        end
    end
end

function AZP.InterruptHelper:OnEvent(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        AZP.InterruptHelper:eventCombatLogEventUnfiltered(...)
    elseif event == "VARIABLES_LOADED" then
        AZP.InterruptHelper:eventVariablesLoaded(...)
    elseif event == "CHAT_MSG_ADDON" then
        AZP.InterruptHelper:eventChatMsgAddonVersion(...)
        AZP.InterruptHelper:eventChatMsgAddonInterrupts(...)
    elseif event == "ENCOUNTER_START" then
        AZP.InterruptHelper:eventPlayerEnterCombat()
    elseif event == "ENCOUNTER_END" then
        AZP.InterruptHelper:eventPlayerLeaveCombat()
    elseif event == "GROUP_ROSTER_UPDATE" then
        AZP.InterruptHelper:ShareVersion()
    end
end

if not IsAddOnLoaded("AzerPUGsCore") then
    AZP.InterruptHelper:OnLoadSelf()
end

AZP.SlashCommands["IH"] = function()
    if AZPIHSelfFrame ~= nil then AZPIHSelfFrame:Show() end
end

AZP.SlashCommands["ih"] = AZP.SlashCommands["IH"]
AZP.SlashCommands["interrupt"] = AZP.SlashCommands["IH"]
AZP.SlashCommands["interrupt helper"] = AZP.SlashCommands["IH"]