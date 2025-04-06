
local leftArm = fk.CreateWeapon{
  name = "&goddianwei_left_arm",
  suit = Card.NoSuit,
  number = 0,
  attack_range = 1,
  dynamic_attack_range = function(self, player)
    if player then
      local mark = player:getTableMark("@qiexie_left")
      return #mark == 2 and tonumber(mark[2]) or nil
    end
  end,
  dynamic_equip_skills = function(self, player)
    if player then
      return table.map(player:getTableMark("qiexie_left_skills"), Util.Name2SkillMapper)
    end
  end,
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)

    local qiexieInfo = player:getTableMark("@qiexie_left")
    if #qiexieInfo == 2 then
      room:returnToGeneralPile({ qiexieInfo[1] })
    end
    room:setPlayerMark(player, "qiexie_left_skills", 0)
    room:setPlayerMark(player, "@qiexie_left", 0)
  end,
}
Fk:loadTranslationTable{
  ["goddianwei_left_arm"] = "左膀",
  [":goddianwei_left_arm"] = "这是神典韦的左膀，蕴含着【杀】之力。",
}

local rightArm = fk.CreateWeapon{
  name = "&goddianwei_right_arm",
  suit = Card.NoSuit,
  number = 0,
  attack_range = 1,
  dynamic_attack_range = function(self, player)
    if player then
      local mark = player:getTableMark("@qiexie_right")
      return #mark == 2 and tonumber(mark[2]) or nil
    end
  end,
  dynamic_equip_skills = function(self, player)
    if player then
      return table.map(player:getTableMark("qiexie_right_skills"), Util.Name2SkillMapper)
    end
  end,
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)

    local qiexieInfo = player:getTableMark("@qiexie_right")
    if #qiexieInfo == 2 then
      room:returnToGeneralPile({ qiexieInfo[1] })
    end
    room:setPlayerMark(player, "qiexie_right_skills", 0)
    room:setPlayerMark(player, "@qiexie_right", 0)
  end,
}
Fk:loadTranslationTable{
  ["goddianwei_right_arm"] = "右臂",
  [":goddianwei_right_arm"] = "这是神典韦的右臂，蕴含着【杀】之力。",
}
