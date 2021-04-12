if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end
if AZP.OnLoad == nil then AZP.OnLoad = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end

AZP.VersionControl.InterruptHelper = 2
if AZP.InterruptHelper == nil then AZP.InterruptHelper = {} end

local dash = " - "
local name = "Interrupt Helper"
local nameFull = ("AzerPUG's " .. name)

local AZPInterruptHelperFrame, AZPInterruptHelperOptionPanel = nil, nil

local AZPInterruptOrder, AZPInterruptOrderEditBoxes = {}, {}

if AZPInterruptHelperSettingsList == nil then AZPInterruptHelperSettingsList = {} end

local InterruptButton = nil

local UpdateFrame = nil

local blinkingBoolean = false
local blinkingTicker = nil

function AZP.InterruptHelper:VersionControl()
    return AZP.VersionControl.InterruptHelper
end

function AZP.InterruptHelper:OnLoad()
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

    for i = 1, 10 do
        local interruptersFrame = CreateFrame("Frame", nil, AZPInterruptHelperOptionPanel)
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
                    AZPInterruptOrder[j] = AZPInterruptOrderEditBoxes[j].editbox:GetText()
                else
                    AZPInterruptOrder[j] = nil
                end
                AZPInterruptHelperSettingsList[j] = AZPInterruptOrder[j]
            end
            AZP.InterruptHelper:SaveInterrupts()
            AZP.InterruptHelper:ChangeFrameHeight()
        end)
    end

    AZPInterruptHelperOptionPanel:Hide()

    if AZPInterruptHelperLocation == nil then
        AZPInterruptHelperLocation = {"CENTER", 200, -200}
    end

    AZPInterruptHelperFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    AZPInterruptHelperFrame:EnableMouse(true)
    AZPInterruptHelperFrame:SetMovable(true)
    AZPInterruptHelperFrame:RegisterForDrag("LeftButton")
    AZPInterruptHelperFrame:SetScript("OnDragStart", AZPInterruptHelperFrame.StartMoving)
    AZPInterruptHelperFrame:SetScript("OnDragStop", function() AZPInterruptHelperFrame:StopMovingOrSizing() AZP.InterruptHelper:SaveLocation() end)
    AZPInterruptHelperFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
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

function AZP.InterruptHelper:LoadSavedVars()
    for i = 1, 10 do
        if AZPInterruptHelperSettingsList[i] ~= nill then
            AZPInterruptOrderEditBoxes[i].editbox:SetText(AZPInterruptHelperSettingsList[i])
            AZPInterruptOrder[i] = AZPInterruptHelperSettingsList[i]
        end
    end
    AZP.InterruptHelper:SaveInterrupts()
    AZP.InterruptHelper:ChangeFrameHeight()
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
            InterruptOrderText = InterruptOrderText .. AZPInterruptOrder[i] .. "\n"
        end
    end
    AZPInterruptHelperFrame.text:SetText(InterruptOrderText)
    AZPInterruptHelperFrame.header:SetText(InterruptFrameHeader)

    local unitName, unitRealm = UnitFullName("PLAYER")
    if (AZPInterruptOrder[1] == unitName or AZPInterruptOrder[1] == unitName .. "-" .. unitRealm) then
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

function AZP.InterruptHelper:StructureInterrupts(interruptedName, interruptSpellID)
    local interuptedIndex = nil
    for i = 1, #AZPInterruptOrder do
        if AZPInterruptOrder[i] == interruptedName then
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

function AZP.InterruptHelper:ShareVersion()
    local versionString = string.format("|IH:%d|", AZP.VersionControl.InterruptHelper)
    --DelayedExecution(10, function()
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
    --end)
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
        local v1, combatEvent, v3, v4, casterName, v6, v7, v8, v9, v10, v11, spellID, v13, v14, v15 = CombatLogGetCurrentEventInfo()
        -- v12 == SpellID, but not always, sometimes several IDs for one spell (when multiple things happen on one spell)
        if combatEvent == "SPELL_CAST_SUCCESS" then
            local unitName, unitRealm = UnitFullName("PLAYER")
            if AZP.InterruptHelper.interruptSpells[spellID] ~= nil then
                AZP.InterruptHelper:StructureInterrupts(casterName, spellID)
                if (casterName == unitName or casterName == unitName .. "-" .. unitRealm) then
                    if blinkingTicker ~= nil then
                        blinkingTicker:Cancel()
                    end
                    AZP.InterruptHelper:InterruptBlinking(false)
                end
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        AZPInterruptHelperFrame:SetPoint(AZPInterruptHelperLocation[1], AZPInterruptHelperLocation[4], AZPInterruptHelperLocation[5])
    elseif event == "VARIABLES_LOADED" then
        AZP.InterruptHelper:LoadSavedVars()
        AZP.InterruptHelper:ShareVersion()
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, payload, _, sender = ...
        if prefix == "AZPVERSIONS" then
            AZP.InterruptHelper:ReceiveVersion(AZP.InterruptHelper:GetSpecificAddonVersion(payload, "IH"))
        end
    end
end

AZP.InterruptHelper:OnLoad()