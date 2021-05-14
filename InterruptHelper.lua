if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end

AZP.VersionControl["Interrupt Helper"] = 9
if AZP.InterruptHelper == nil then AZP.InterruptHelper = {} end

local AZPIHSelfFrame, AZPInterruptHelperOptionPanel = nil, nil
local AZPInterruptOrder, AZPInterruptHelperGUIDs, AZPInterruptOrderEditBoxes, AZPinterruptOrderCooldownBars  = {}, {}, {}, {}
local AZPinterruptOrderCooldowns = {}
if AZPInterruptHelperSettingsList == nil then AZPInterruptHelperSettingsList = {} end

if AZPIHShownLocked == nil then AZPIHShownLocked = {false, false} end

local UpdateFrame, EventFrame = nil, nil
local HaveShowedUpdateNotification = false

local blinkingBoolean = false
local blinkingTicker, cooldownTicker = nil, nil

local optionHeader = "|cFF00FFFFInterrupt Helper|r"

function AZP.InterruptHelper:OnLoadBoth()
    AZP.InterruptHelper:CreateMainFrame()
    C_ChatInfo.RegisterAddonMessagePrefix("AZPSHAREINFO")
end

function AZP.InterruptHelper:OnLoadCore()
    AZP.InterruptHelper:OnLoadBoth()
    AZP.Core:RegisterEvents("COMBAT_LOG_EVENT_UNFILTERED", function(...) AZP.InterruptHelper:eventCombatLogEventUnfiltered(...) end)
    AZP.Core:RegisterEvents("VARIABLES_LOADED", function(...) AZP.InterruptHelper:eventVariablesLoaded(...) end)
    AZP.Core:RegisterEvents("CHAT_MSG_ADDON", function(...) AZP.InterruptHelper:eventChatMsgAddonInterrupts(...) end)
    AZP.Core:RegisterEvents("PLAYER_ENTER_COMBAT", function(...) AZP.InterruptHelper:eventPlayerEnterCombat(...) end)
    AZP.Core:RegisterEvents("PLAYER_LEAVE_COMBAT", function(...) AZP.InterruptHelper:eventPlayerLeaveCombat(...) end)

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
    EventFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
    EventFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
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
                                AZPInterruptOrder[j] = curGUID
                                AZPInterruptHelperGUIDs[curGUID] = curName
                            end
                        end
                    end
                else
                    AZPInterruptOrder[j] = nil
                end
                AZPInterruptHelperSettingsList[j] = AZPInterruptOrder[j]
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
        AZPinterruptOrderCooldownBars[i] = CreateFrame("StatusBar", nil, AZPIHSelfFrame)
        AZPinterruptOrderCooldownBars[i]:SetSize(AZPIHSelfFrame:GetWidth() - 20, 18)
        AZPinterruptOrderCooldownBars[i]:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        AZPinterruptOrderCooldownBars[i]:SetPoint("TOP", 0, -20 * i - 25)
        AZPinterruptOrderCooldownBars[i]:SetMinMaxValues(0, 100)
        AZPinterruptOrderCooldownBars[i]:SetValue(100)
        AZPinterruptOrderCooldownBars[i].name = AZPinterruptOrderCooldownBars[i]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        AZPinterruptOrderCooldownBars[i].name:SetSize(AZPinterruptOrderCooldownBars[i]:GetWidth() - 25, 16)
        AZPinterruptOrderCooldownBars[i].name:SetPoint("CENTER", 0, -1)
        AZPinterruptOrderCooldownBars[i].name:SetText("charName")
        AZPinterruptOrderCooldownBars[i].bg = AZPinterruptOrderCooldownBars[i]:CreateTexture(nil, "BACKGROUND")
        AZPinterruptOrderCooldownBars[i].bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        AZPinterruptOrderCooldownBars[i].bg:SetAllPoints(true)
        AZPinterruptOrderCooldownBars[i].bg:SetVertexColor(1, 0, 0)
        AZPinterruptOrderCooldownBars[i].cooldown = AZPinterruptOrderCooldownBars[i]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        AZPinterruptOrderCooldownBars[i].cooldown:SetSize(25, 16)
        AZPinterruptOrderCooldownBars[i].cooldown:SetPoint("RIGHT", -5, 0)
        AZPinterruptOrderCooldownBars[i].cooldown:SetText("-")
        AZPinterruptOrderCooldownBars[i]:SetStatusBarColor(0, 0.75, 1)
        AZPinterruptOrderCooldownBars[i]:Hide()
    end
end

function AZP.InterruptHelper:eventCombatLogEventUnfiltered(...)
    local v1, combatEvent, v3, UnitGUID, casterName, v6, v7, v8, v9, v10, v11, spellID, v13, v14, v15 = CombatLogGetCurrentEventInfo()
    -- v12 == SpellID, but not always, sometimes several IDs for one spell (when multiple things happen on one spell)
    if combatEvent == "SPELL_CAST_SUCCESS" then
        local unitName = UnitFullName("PLAYER")
        if AZP.InterruptHelper.interruptSpells[spellID] ~= nil then
            for i = 1, #AZPInterruptOrder do
                if UnitGUID == AZPInterruptOrder[i] then
                    AZP.InterruptHelper:StructureInterrupts(UnitGUID, spellID)
                end
            end
            if casterName == unitName then      -- Change to GUID.
                if blinkingTicker ~= nil then
                    blinkingTicker:Cancel()
                end
                AZP.InterruptHelper:InterruptBlinking(false)
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
                AZPInterruptOrder[i] = AZPInterruptHelperSettingsList[i]
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
    AZPIHSelfFrame:SetHeight(#AZPInterruptOrder * 15 + 65)
end

function AZP.InterruptHelper:TickCoolDowns()
    for i = 1, #AZPinterruptOrderCooldownBars do
        if AZPinterruptOrderCooldowns[i] ~= nil then
            if AZPinterruptOrderCooldowns[i] <= 0 then
                AZPinterruptOrderCooldowns[i] = nil
                AZPinterruptOrderCooldownBars[i].cooldown:SetText("-")
                AZPinterruptOrderCooldownBars[i]:SetMinMaxValues(0, 100)
                AZPinterruptOrderCooldownBars[i]:SetValue(100)
            else
                AZPinterruptOrderCooldowns[i] = AZPinterruptOrderCooldowns[i] - 1
                AZPinterruptOrderCooldownBars[i].cooldown:SetText(AZPinterruptOrderCooldowns[i])
                AZPinterruptOrderCooldownBars[i]:SetValue(AZPinterruptOrderCooldowns[i])
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
        AZPinterruptOrderCooldownBars[i]:Hide()
        if AZPInterruptOrder[i] ~= nil then
            AZPinterruptOrderCooldownBars[i].name:SetText(AZPInterruptHelperGUIDs[AZPInterruptOrder[i]])
            local raidN = nil
            for j = 1, 40 do
                if GetRaidRosterInfo(j) ~= nil then             -- For party GetPartyMember(j) ~= nil but this excludes the player.
                    local curGUID = UnitGUID("raid" .. j)
                    if curGUID == AZPInterruptOrder[i] then
                        raidN = ("raid" .. j)
                    end
                end
            end
            if raidN ~= nil then
                local _, _, classIndex = UnitClass(raidN)
                AZPinterruptOrderCooldownBars[i].name:SetTextColor(AZP.InterruptHelper:GetClassColor(classIndex))
            end
            AZPinterruptOrderCooldownBars[i]:Show()
        end
    end
    AZPIHSelfFrame.text:SetText(InterruptOrderText)

    local playerGUID = UnitGUID("player")
    if AZPInterruptOrder[1] == playerGUID then
        blinkingTicker = C_Timer.NewTicker(0.5, function() AZP.InterruptHelper:InterruptBlinking(blinkingBoolean) end, 10)
    else
        AZP.InterruptHelper:InterruptBlinking(false)
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

function AZP.InterruptHelper:StructureInterrupts(interruptedGUID, interruptSpellID)
    local interuptedIndex = nil
    for i = 1, #AZPInterruptOrder do
        if AZPInterruptOrder[i] == interruptedGUID then
            interuptedIndex = i
        end
    end

    local spellCooldown = AZP.InterruptHelper:GetSpellCooldown(interruptSpellID)
    AZPinterruptOrderCooldowns[interuptedIndex] = spellCooldown
    AZPinterruptOrderCooldownBars[interuptedIndex]:SetMinMaxValues(0, spellCooldown)
    AZPinterruptOrderCooldownBars[interuptedIndex].cooldown:SetText(spellCooldown)

    local temp = AZPInterruptOrder[interuptedIndex]
    local temp2 = AZPinterruptOrderCooldownBars[interuptedIndex]
    local temp3 = AZPinterruptOrderCooldowns[interuptedIndex]

    for i = interuptedIndex, #AZPInterruptOrder - 1 do
        AZPInterruptOrder[i] = AZPInterruptOrder[i+1]
        AZPinterruptOrderCooldownBars[i] = AZPinterruptOrderCooldownBars[i+1]
        AZPinterruptOrderCooldowns[i] = AZPinterruptOrderCooldowns[i+1]
        AZPinterruptOrderCooldownBars[i]:SetPoint("TOP", 0, -20 * i - 25)
    end
    AZPInterruptOrder[#AZPInterruptOrder] = temp
    AZPinterruptOrderCooldownBars[#AZPInterruptOrder] = temp2
    AZPinterruptOrderCooldowns[#AZPInterruptOrder] = temp3
    AZPinterruptOrderCooldownBars[#AZPInterruptOrder]:SetPoint("TOP", 0, -20 * #AZPInterruptOrder - 25)

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
                local curGUID = UnitGUID("raid" .. j)
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
    AZPInterruptOrder = {}
    AZPInterruptHelperGUIDs = {}
    AZPInterruptHelperSettingsList = {}

    local pattern = ":([^:]+):"
    local stringIndex = 1
    while stringIndex < #interruptersString do
        local _, endPos = string.find(interruptersString, pattern, stringIndex)
        local unitGUID = string.match(interruptersString, pattern, stringIndex)
        unitGUID = "Player-" .. unitGUID
        stringIndex = endPos + 1
        AZPInterruptOrder[#AZPInterruptOrder + 1] = unitGUID
    end
    for i = 1, #AZPInterruptOrder do
        for j = 1, 40 do
            if GetRaidRosterInfo(j) ~= nil then
                local curName = GetRaidRosterInfo(j)           -- For party GetPartyMember(j) ~= nil but this excludes the player.
                if string.find(curName, "-") then
                    curName = string.match(curName, "(.+)-")
                end
                local curGUID = UnitGUID("raid" .. j)
                if curGUID == AZPInterruptOrder[i] then
                    AZPInterruptHelperGUIDs[i] = curName
                    AZPInterruptHelperSettingsList[i] = curGUID
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
    elseif event == "PLAYER_ENTER_COMBAT" then
        AZP.InterruptHelper:eventPlayerEnterCombat()
    elseif event == "PLAYER_LEAVE_COMBAT" then
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