if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end
if AZP.OnLoad == nil then AZP.OnLoad = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end

AZP.VersionControl.InterruptHelper = 1
if AZP.InterruptHelper == nil then AZP = {} end

local dash = " - "
local name = "Interrupt Helper"
local nameFull = ("AzerPUG's " .. name)
local promo = (nameFull .. dash ..  AZPInterruptHelperVersion)

local AZPInterruptHelperFrame, AZPInterruptHelperOptionPanel = nil, nil

local AZPInterruptOrder, AZPInterruptOrderEditBoxes, AZPinterruptOrderCooldownBars = {}, {}, {}

AZPinterruptOrderCooldowns = {}

local InterruptButton = nil

local blinkingBoolean = false
local blinkingTicker, cooldownTicker = nil, nil

function AZP.InterruptHelper:VersionControl()
    return AZPInterruptHelperVersion
end

function AZP.InterruptHelper:OnLoad()
    AZPInterruptHelperOptionPanel = CreateFrame("FRAME", nil)
    AZPInterruptHelperOptionPanel.name = "|cFF00FFFFAzerPUG's Interrupt Helper|r"
    InterfaceOptions_AddCategory(AZPInterruptHelperOptionPanel)

    AZPInterruptHelperOptionPanel.header = AZPInterruptHelperOptionPanel:CreateFontString("AZPInterruptHelperOptionPanel", "ARTWORK", "GameFontNormalHuge")
    AZPInterruptHelperOptionPanel.header:SetPoint("TOP", 0, -10)
    AZPInterruptHelperOptionPanel.header:SetText("|cFF00FFFFAzerPUG ToolTips Options!|r")

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

        if i == 1 then
            interruptersFrame.editbox:SetText("Wiredruid")
        elseif i == 2 then
            interruptersFrame.editbox:SetText("Tex")
        end

        AZPInterruptOrderEditBoxes[i] = interruptersFrame
        interruptersFrame.editbox:SetScript("OnEditFocusLost",
        function()
            for j = 1, 10 do
                if (AZPInterruptOrderEditBoxes[j].editbox:GetText() ~= nil and AZPInterruptOrderEditBoxes[j].editbox:GetText() ~= "") then
                    AZPInterruptOrder[j] = AZPInterruptOrderEditBoxes[j].editbox:GetText()
                else
                    AZPInterruptOrder[j] = nil
                end
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
    AZPInterruptHelperFrame:SetScript("OnDragStop", function() AZP.InterruptHelperFrame:StopMovingOrSizing() AZP.InterruptHelper:SaveLocation() end)
    AZPInterruptHelperFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    AZPInterruptHelperFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    AZPInterruptHelperFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
    AZPInterruptHelperFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
    AZPInterruptHelperFrame:SetScript("OnEvent", function(...) AZPInterruptHelper:OnEvent(...) end)
    AZPInterruptHelperFrame:SetSize(200, 200)
    AZPInterruptHelperFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    AZPInterruptHelperFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.75)
    AZPInterruptHelperFrame:SetBackdropBorderColor(1, 1, 1, 1)
    AZPInterruptHelperFrame.header = AZPInterruptHelperFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    AZPInterruptHelperFrame.header:SetSize(AZPInterruptHelperFrame:GetWidth(), AZPInterruptHelperFrame:GetHeight())
    AZPInterruptHelperFrame.header:SetPoint("TOP", 0, -10)
    AZPInterruptHelperFrame.header:SetJustifyV("TOP")
    AZPInterruptHelperFrame.header:SetText("Nothing!")

    InterruptButton = CreateFrame("Button", nil, AZPInterruptHelperFrame, "SecureActionButtonTemplate")
    InterruptButton:SetSize(AZPInterruptHelperFrame:GetWidth(), AZPInterruptHelperFrame:GetHeight())
    InterruptButton:SetPoint("Center", 0, 0)
    InterruptButton:EnableMouse(true)

    for i = 1, 10 do
        AZPinterruptOrderCooldownBars[i] = CreateFrame("StatusBar", nil, AZPInterruptHelperFrame)
        AZPinterruptOrderCooldownBars[i]:SetSize(AZPInterruptHelperFrame:GetWidth() - 20, 18)
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

    local CuntButton = CreateFrame("Button", nil, AZPInterruptHelperFrame, "UIPanelButtonTemplate")
    CuntButton:SetSize(25, 25)
    CuntButton:SetPoint("TOPLEFT", AZPInterruptHelperFrame, "TOPLEFT", -22, 2)
    CuntButton:SetScript("OnClick", function() AZP.InterruptHelper:StructureInterrupts(AZPInterruptOrder[1], nil) end)
    CuntButton:SetText("X")

    AZP.InterruptHelper:ChangeFrameHeight()
end

function AZP.InterruptHelper:PickInterrupt()
    local className = select(2, UnitClass("player"))        -- Find out if select is better then using wildcards.
    local currentSpec = GetSpecialization()
    local currentSpecName = select(2, GetSpecializationInfo(currentSpec))
    for spellID, interruptInfo in pairs(AZP.InterruptHelper.interruptSpells) do
        if interruptInfo[2] == className then
            for i = 1, #interruptInfo[3] do
                if interruptInfo[3][i] == currentSpecName then
                    local spellName = GetSpellInfo(spellID)
                    InterruptButton:SetAttribute("spell", spellName)
                end
            end
        end
    end
end

function AZP.InterruptHelper:GetSpellCooldown(interruptSpellID)
    return AZP.InterruptHelper.interruptSpells[interruptSpellID][4]
end

function AZP.InterruptHelper:SaveLocation()
    local temp = {}
    temp[1], temp[2], temp[3], temp[4], temp[5] = AZPInterruptHelperFrame:GetPoint()
    AZPInterruptHelperLocation = temp
end

function AZP.InterruptHelper:ChangeFrameHeight()
    AZP.InterruptHelperFrame:SetHeight(#AZPInterruptOrder * 25 + 50)
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

function AZP.InterruptHelper:SaveInterrupts()
    local InterruptFrameHeader = "Interrupt Order:\n"
    for i = 1, 10 do
        AZPinterruptOrderCooldownBars[i]:Hide()
        if AZPInterruptOrder[i] ~= nil then
            AZPinterruptOrderCooldownBars[i].name:SetText(AZPInterruptOrder[i])
            AZPinterruptOrderCooldownBars[i]:Show()
        end
    end

    AZPInterruptHelperFrame.header:SetText(InterruptFrameHeader)

    local unitName, unitRealm = UnitFullName("PLAYER")
    if (AZPInterruptOrder[1] == unitName or AZPInterruptOrder[1] == unitName .. "-" .. unitRealm) then
        blinkingTicker = C_Timer.NewTicker(0.5, function() AZPInterruptHelper:InterruptBlinking(blinkingBoolean) end, 10)
    else
        AZPInterruptHelper:InterruptBlinking(false)
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
    local interruptCooldown = nil
    for i = 1, #AZPInterruptOrder do
        if AZPInterruptOrder[i] == interruptedName then
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
        InterruptButton:SetAttribute("type", "spell")
        AZP.InterruptHelper:PickInterrupt()
        InterruptButton:SetAttribute("target", "target")
    elseif event == "PLAYER_ENTER_COMBAT" then
        cooldownTicker = C_Timer.NewTicker(1, function() AZP.InterruptHelper:TickCoolDowns() end, 1000)
    elseif event == "PLAYER_LEAVE_COMBAT" then
        cooldownTicker:Cancel()
    end
end

AZP.InterruptHelper:OnLoad()