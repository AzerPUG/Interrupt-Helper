if AZP == nil then AZP = {} end
if AZP.InterruptHelper == nil then AZP = {} end

AZP.InterruptHelper.interruptSpells =
{
    [15487] = {"Silence", "PRIEST", {"Shadow"}, 45},        -- Cooldown can be lowered with a talent.

    [2139] = {"Counterspell", "MAGE", {"Fire", "Arcane", "Frost"}, 24},

    [19647] = {"Spell Lock", "WARLOCK", {"Destruction", "Affliction", "Demonology"}, 24},       -- Fellhunter, Jinx gave 119910 as extra ID?
    [89766] = {"Axe Toss", "WARLOCK", {"Demonology"}, 30},                                      -- Wrathguard, Jinx gave 119914 as extra ID?

    [106839] = {"Skull Bash", "DRUID", {"Feral", "Guardian"}, 15},
    [78675] = {"Solar Beam", "DRUID", {"Balance"}, 60},

    [1766] = {"Kick", "ROGUE", {"Assassination", "Subtlety", "Outlaw"}, 15},

    [116705] = {"Spear Hand Strike", "MONK", {"Brewmaster", "Windwalker"}, 15},

    [183752] = {"Disrupt", "DEMONHUNTER", {"Havoc", "Vengeance"}, 15},

    [57994] = {"Wind Shear", "SHAMAN", {"Restoration", "Elemental", "Enhancement"}, 12},

    [147362] = {"Counter Shot", "HUNTER", {"Marksman", "Beast Mastery"}, 24},
    [187707] = {"Muzzle", "HUNTER", {"Survival"}, 15},

    [6552] = {"Pummel", "WARRIOR", {"Protection", "Arms", "Fury"}, 15},

    [96231] = {"Rebuke", "PALADIN", {"Protection", "Retribution"}, 15},

    [47528] = {"Mind Freeze", "DEATHKNIGHT", {"Blood", "Frost", "Unholy"}, 15},
}