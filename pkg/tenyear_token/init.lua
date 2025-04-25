-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("tenyear_token", Package.CardPack)
extension.extensionName = "tenyear"

extension:loadSkillSkelsByPath("./packages/tenyear/pkg/tenyear_token/skills")

Fk:loadTranslationTable{
  ["tenyear_token"] = "十周年衍生牌",
}

local ty__drowning = fk.CreateCard{
  name = "&ty__drowning",
  type = Card.TypeTrick,
  skill = "ty__drowning_skill",
  is_damage_card = true,
}
extension:addCardSpec("ty__drowning", Card.Spade, 6)
Fk:loadTranslationTable{
  ["ty__drowning"] = "水淹七军",
  [":ty__drowning"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一至两名角色<br/>"..
  "<b>效果</b>：第一名角色受到1点雷电伤害并弃置一张牌，该角色以外的角色受到1点雷电伤害并摸一张牌。",
}

local red_spear = fk.CreateCard{
  name = "&red_spear",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#red_spear_skill",
}
extension:addCardSpec("red_spear", Card.Heart, 1)
Fk:loadTranslationTable{
  ["red_spear"] = "红缎枪",
  [":red_spear"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：3<br/>"..
  "<b>武器技能</b>：每回合限一次，当你使用【杀】造成伤害后，你可以判定，若结果为红色，你回复1点体力；若结果为黑色，你摸两张牌。",
}

local quenched_blade = fk.CreateCard{
  name = "&quenched_blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#quenched_blade_skill",
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)
    player:setSkillUseHistory("#quenched_blade_skill", 0, Player.HistoryTurn)
  end,
}
extension:addCardSpec("quenched_blade", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["quenched_blade"] = "烈淬刀",
  [":quenched_blade"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：每回合限两次，当你使用【杀】对目标角色造成伤害时，你可以弃置一张牌，令此伤害+1；出牌阶段你可以多使用一张【杀】。",
}

local poisonous_dagger = fk.CreateCard{
  name = "&poisonous_dagger",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 1,
  equip_skill = "#poisonous_dagger_skill",
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)
    player:setSkillUseHistory("#poisonous_dagger_skill", 0, Player.HistoryTurn)
  end,
}
extension:addCardSpec("poisonous_dagger", Card.Spade, 1)
Fk:loadTranslationTable{
  ["poisonous_dagger"] = "混毒弯匕",
  [":poisonous_dagger"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：1<br/>"..
  "<b>武器技能</b>：当你使用【杀】指定目标后，你可以令目标角色失去X点体力（X为你本回合此武器发动技能次数且至多为5）。",
}

local water_sword = fk.CreateCard{
  name = "&water_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 2,
  equip_skill = "#water_sword_skill",
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)
    player:setSkillUseHistory("#water_sword_skill", 0, Player.HistoryTurn)
  end,
}
extension:addCardSpec("water_sword", Card.Club, 1)
Fk:loadTranslationTable{
  ["water_sword"] = "水波剑",
  [":water_sword"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：2<br/>"..
  "<b>武器技能</b>：每回合限两次，你使用【杀】或普通锦囊牌可以额外指定一个目标。你失去装备区内的【水波剑】时，你回复1点体力。",
}

local thunder_blade = fk.CreateCard{
  name = "&thunder_blade",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 4,
  equip_skill = "#thunder_blade_skill",
}
extension:addCardSpec("thunder_blade", Card.Spade, 1)
Fk:loadTranslationTable{
  ["thunder_blade"] = "天雷刃",
  [":thunder_blade"] = "装备牌·武器<br/>"..
  "<b>攻击范围</b>：4<br/>"..
  "<b>武器技能</b>：当你使用【杀】指定目标后，你可以令其判定，若结果为：♠，你对其造成3点雷电伤害；♣，你对其造成1点雷电伤害，"..
  "你回复1点体力并摸一张牌。",
}

local ty__catapult = fk.CreateCard{
  name = "&ty__catapult",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#ty__catapult_skill",
}
extension:addCardSpec("ty__catapult", Card.Diamond, 9)
Fk:loadTranslationTable{
  ["ty__catapult"] = "霹雳车",
  [":ty__catapult"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：锁定技，当你于回合内使用基本牌时，伤害和回复数值+1且无距离限制，使用【酒】使【杀】伤害基数值额外+1。"..
  "当你于回合外使用或打出基本牌时，摸一张牌。离开装备区时销毁。",
}

local siege_engine = fk.CreateCard{
  name = "&siege_engine",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeTreasure,
  equip_skill = "#siege_engine_skill",
  on_uninstall = function(self, room, player)
    Treasure.onUninstall(self, room, player)
    local n = 0
    for i = 1, 3, 1 do
      n = n + self:getMark("xianzhu"..i)
      room:setCardMark(self, "xianzhu"..i, 0)
    end
    if n > 0 then
      local e = room.logic:getCurrentEvent()
      if e and e.event == GameEvent.MoveCards then
        e.data.extra_data = e.data.extra_data or {}
        e.data.extra_data.chaixie_draw = {}
        table.insert(e.data.extra_data.chaixie_draw, {player.id, n})
      end
    end
  end,
}
extension:addCardSpec("siege_engine", Card.Spade, 9)
Fk:loadTranslationTable{
  ["siege_engine"] = "大攻车",
  [":siege_engine"] = "装备牌·宝物<br/>"..
  "<b>宝物技能</b>：出牌阶段开始时，你可以视为使用一张【杀】，当此【杀】对目标角色造成伤害后，你弃置其一张牌。"..
  "若此牌未升级，则不能被弃置。离开装备区后销毁。升级选项：<br>"..
  "1.此【杀】无视距离和防具；<br>2.此【杀】可指定目标+1；<br>3.此【杀】造成伤害后弃牌数+1。",
}

local left_arm = fk.CreateCard{
  name = "&goddianwei_left_arm",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
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
extension:addCardSpec("goddianwei_left_arm")
Fk:loadTranslationTable{
  ["goddianwei_left_arm"] = "左膀",
  [":goddianwei_left_arm"] = "装备牌·武器<br/>"..
  "这是神典韦的左膀，蕴含着【杀】之力。",
}

local right_arm = fk.CreateCard{
  name = "&goddianwei_right_arm",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
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
extension:addCardSpec("goddianwei_right_arm")
Fk:loadTranslationTable{
  ["goddianwei_right_arm"] = "右臂",
  [":goddianwei_right_arm"] = "装备牌·武器<br/>"..
  "这是神典韦的右臂，蕴含着【杀】之力。",
}

extension:loadCardSkels {
  ty__drowning,

  red_spear,
  quenched_blade,
  poisonous_dagger,
  water_sword,
  thunder_blade,
  ty__catapult,
  siege_engine,
  left_arm,
  right_arm,
}

return extension
