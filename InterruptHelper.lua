if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end
if AZP.OnLoad == nil then AZP.OnLoad = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end

AZP.VersionControl.InterruptHelper = 3
if AZP.InterruptHelper == nil then AZP.InterruptHelper = {} end

local dash = " - "
local name = "Interrupt Helper"
local nameFull = ("AzerPUG's " .. name)

local AZPInterruptHelperFrame, AZPInterruptHelperOptionPanel = nil, nil
local AZPInterruptOrder, AZPInterruptHelperGUIDs, AZPInterruptOrderEditBoxes, GUIDList = {}, {}, {}, {}

if AZPInterruptHelperSettingsList == nil then AZPInterruptHelperSettingsList = {} end

local InterruptButton = nil

local UpdateFrame = nil

local blinkingBoolean = false
local blinkingTicker = nil

local optionHeader = "|cFF00FFFFInterrupt Helper|r"

function AZP.InterruptHelper:OnLoadBoth()
    AZP.InterruptHelper:CreateMainFrame()
    C_ChatInfo.RegisterAddonMessagePrefix("AZPSHAREINFO")
end

function AZP.InterruptHelper:OnLoadCore()
    AZP.InterruptHelper:OnLoadBoth()
    AZP.Core:RegisterEvents("COMBAT_LOG_EVENT_UNFILTERED", function(...) AZP.InterruptHelper:eventCombatLogEventUnfiltered(...) end)
    AZP.Core:RegisterEvents("VARIABLES_LOADED", function(...) AZP.InterruptHelper:eventVariablesLoaded(...) end)
    AZP.Core:RegisterEvents("CHAT_MSG_ADDON", function(...) AZP.InterruptHelper:eventChatMsgAddon(...) end)
    AZP.OptionsPanels:Generic("Interrupt Helper", optionHeader, function(frame) AZP.InterruptHelper:FillOptionsPanel(frame) end)
end

function AZP.InterruptHelper:OnLoadSelf()
    C_ChatInfo.RegisterAddonMessagePrefix("AZPVERSIONS")

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

    if AZPInterruptHelperLocation == nil then
        AZPInterruptHelperLocation = {"CENTER", 200, -200}
    end

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
    local ShareButton = CreateFrame("Button", nil, frameToFill, "UIPanelButtonTemplate")
    ShareButton.text = ShareButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    ShareButton.text:SetText("Share List")
    ShareButton:SetWidth("100")
    ShareButton:SetHeight("25")
    ShareButton.text:SetWidth("100")
    ShareButton.text:SetHeight("15")
    ShareButton:SetPoint("TOP", 100, -50)
    ShareButton.text:SetPoint("CENTER", 0, -1)
    ShareButton:SetScript("OnClick", function() AZP.InterruptHelper:ShareInterrupters() end )

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
    AZPInterruptHelperFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    AZPInterruptHelperFrame:EnableMouse(true)
    AZPInterruptHelperFrame:SetMovable(true)
    AZPInterruptHelperFrame:RegisterForDrag("LeftButton")
    AZPInterruptHelperFrame:SetScript("OnDragStart", AZPInterruptHelperFrame.StartMoving)
    AZPInterruptHelperFrame:SetScript("OnDragStop", function() AZPInterruptHelperFrame:StopMovingOrSizing() AZP.InterruptHelper:SaveLocation() end)
    AZPInterruptHelperFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    AZPInterruptHelperFrame:RegisterEvent("VARIABLES_LOADED")
    AZPInterruptHelperFrame:RegisterEvent("CHAT_MSG_ADDON")
    AZPInterruptHelperFrame:SetScript("OnEvent", function(...) AZP.InterruptHelper:OnEvent(...) end)
    AZPInterruptHelperFrame:SetSize(200, 200)
    AZPInterruptHelperFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    AZPInterruptHelperFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.75)
    AZPInterruptHelperFrame:SetBackdropBorderColor(1, 1, 1, 1)
    AZPInterruptHelperFrame.header = AZPInterruptHelperFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    AZPInterruptHelperFrame.header:SetSize(AZPInterruptHelperFrame:GetWidth(), AZPInterruptHelperFrame:GetHeight())
    AZPInterruptHelperFrame.header:SetPoint("TOP", 0, -10)
    AZPInterruptHelperFrame.header:SetJustifyV("TOP")
    AZPInterruptHelperFrame.header:SetText("Nothing!")

    AZPInterruptHelperFrame.text = AZPInterruptHelperFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    AZPInterruptHelperFrame.text:SetSize(AZPInterruptHelperFrame:GetWidth(), AZPInterruptHelperFrame:GetHeight())
    AZPInterruptHelperFrame.text:SetPoint("TOP", 0, -40)
    AZPInterruptHelperFrame.text:SetJustifyV("TOP")
    AZPInterruptHelperFrame.text:SetText("Nothing!")

    
    local IUAddonFrameCloseButton = CreateFrame("Button", nil, AZPInterruptHelperFrame, "UIPanelCloseButton")
    IUAddonFrameCloseButton:SetSize(20, 21)
    IUAddonFrameCloseButton:SetPoint("TOPRIGHT", AZPInterruptHelperFrame, "TOPRIGHT", 2, 2)
    IUAddonFrameCloseButton:SetScript("OnClick", function() AZPInterruptHelperFrame:Hide() end )
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

function AZP.InterruptHelper:eventChatMsgAddon(...)
    local prefix, payload, _, sender = ...
    if prefix == "AZPVERSIONS" then
        local version = AZP.InterruptHelper:GetSpecificAddonVersion(payload, "IH")
        if version ~= nil then
            AZP.InterruptHelper:ReceiveVersion(version)
        end
    elseif prefix == "AZPSHAREINFO" then
        AZP.InterruptHelper:ReceiveInterrupters(payload)
    end
end

function AZP.InterruptHelper:LoadSavedVars()
    AZPInterruptHelperFrame:SetPoint(AZPInterruptHelperLocation[1], AZPInterruptHelperLocation[4], AZPInterruptHelperLocation[5])
    AZP.InterruptHelper:PutNamesInList()
    AZP.InterruptHelper:SaveInterrupts()
    AZP.InterruptHelper:ChangeFrameHeight()
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
            local temp = AZPInterruptHelperGUIDs[AZPInterruptHelperSettingsList[i]]
            AZPInterruptOrderEditBoxes[i].editbox:SetText(temp)
            AZPInterruptOrder[i] = AZPInterruptHelperSettingsList[i]
        end
    end
end

function AZP.InterruptHelper:SaveLocation()
    local temp = {}
    temp[1], temp[2], temp[3], temp[4], temp[5] = AZPInterruptHelperFrame:GetPoint()
    AZPInterruptHelperLocation = temp
end

function AZP.InterruptHelper:ChangeFrameHeight()
    AZPInterruptHelperFrame:SetHeight(#AZPInterruptOrder * 15 + 50)
end

function AZP.InterruptHelper:SaveInterrupts()
    local InterruptFrameHeader = "Interrupt Order:\n"
    local InterruptOrderText = ""
    for i = 1, 10 do
        if AZPInterruptOrder[i] ~= nil then
            local temp = AZPInterruptHelperGUIDs[AZPInterruptOrder[i]]
            InterruptOrderText = InterruptOrderText .. temp .. "\n"
        end
    end
    AZPInterruptHelperFrame.header:SetText(InterruptFrameHeader)
    AZPInterruptHelperFrame.text:SetText(InterruptOrderText)

    local playerGUID = UnitGUID("player")
    if AZPInterruptOrder[1] == playerGUID then
        blinkingTicker = C_Timer.NewTicker(0.5, function() AZP.InterruptHelper:InterruptBlinking(blinkingBoolean) end, 10)
    else
        AZP.InterruptHelper:InterruptBlinking(false)
    end
end

function AZP.InterruptHelper:InterruptBlinking(boolean)
    if boolean == true then
        AZPInterruptHelperFrame:SetBackdropColor(1,0,0,1)
        AZPInterruptHelperFrame:SetBackdropBorderColor(1, 1, 1, 1)
        blinkingBoolean = false
    else
        AZPInterruptHelperFrame:SetBackdropColor(1, 1, 1, 1)
        AZPInterruptHelperFrame:SetBackdropBorderColor(1, 0, 0, 1)
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

    if interuptedIndex ~= nill then
        local temp = AZPInterruptOrder[interuptedIndex]

        for i = interuptedIndex, #AZPInterruptOrder - 1 do      -- InterruptedIndex == nil if some one interrupts not in the list.
            AZPInterruptOrder[i] = AZPInterruptOrder[i+1]
        end
        AZPInterruptOrder[#AZPInterruptOrder] = temp

        AZP.InterruptHelper:SaveInterrupts()
    end
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
    local versionString = string.format("|IH:%d|", AZP.VersionControl.InterruptHelper)
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

function AZP.InterruptHelper:ReceiveVersion(version)
    if version > AZP.VersionControl.InterruptHelper then
        if (not HaveShowedUpdateNotification) then
            HaveShowedUpdateNotification = true
            UpdateFrame:Show()
            UpdateFrame.text:SetText(
                "Please download the new version through the CurseForge app.\n" ..
                "Or use the CurseForge website to download it manually!\n\n" .. 
                "Newer Version: v" .. version .. "\n" .. 
                "Your version: v" .. AZP.VersionControl.InterruptHelper
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
        AZP.InterruptHelper:eventChatMsgAddon(...)
    end
end

if not IsAddOnLoaded("AzerPUG's Core") then
    AZP.InterruptHelper:OnLoadSelf()
end

SLASH_SHOW1 = "/azpshow"
SLASH_SHOW2 = "/showazp"
SlashCmdList["SHOW"] = function()
    print("Test bla bla ")
    AZPInterruptHelperFrame:Show()
end