
local extension = Package:new("tenyear_token", Package.CardPack)
Fk:loadTranslationTable{
  ["tenyear_token"] = "十周年衍生牌",
}

local redSpearSkill = fk.CreateTriggerSkill{
  name = "#red_spear_skill",
  attached_equip = "&red_spear",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    elseif judge.card.color == Card.Black then
      player:drawCards(2, self.name)
    end
  end,
}
Fk:addSkill(redSpearSkill)
local redSpear = fk.CreateWeapon{
  name = "&red_spear",
  suit = Card.Heart,
  number = 1,
  attack_range = 3,
  equip_skill = redSpearSkill,
}
extension:addCard(redSpear)
Fk:loadTranslationTable{
  ["&red_spear"] = "红缎枪",
  ["#red_spear_skill"] = "红缎枪",
  [":&red_spear"] = "装备牌·武器<br /><b>攻击范围</b>：3<br /><b>武器技能</b>：每回合限一次，当你使用【杀】造成伤害后，你可以判定，若结果为红色，你回复1点体力；若结果为黑色，你摸两张牌。",
}

local quenchedBladeSkill = fk.CreateTriggerSkill{
  name = "#quenched_blade_skill",
  attached_equip = "&quenched_blade",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not data.chain and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#quenched_blade-invoke::"..data.to.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local quenched_blade_targetmod = fk.CreateTargetModSkill{
  name = "#quenched_blade_targetmod",
  attached_equip = "&quenched_blade",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self.name) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
quenchedBladeSkill:addRelatedSkill(quenched_blade_targetmod)
Fk:addSkill(quenchedBladeSkill)
local quenchedBlade = fk.CreateWeapon{
  name = "&quenched_blade",
  suit = Card.Diamond,
  number = 1,
  attack_range = 2,
  equip_skill = quenchedBladeSkill,
}
extension:addCard(quenchedBlade)
Fk:loadTranslationTable{
  ["&quenched_blade"] = "烈淬刀",
  ["#quenched_blade_skill"] = "烈淬刀",
  [":&quenched_blade"] = "装备牌·武器<br /><b>攻击范围</b>：2<br /><b>武器技能</b>：每回合限两次，你使用【杀】对目标角色造成伤害时，你可以弃置一张牌，令此伤害+1；出牌阶段你可以多使用一张【杀】。",
  ["#quenched_blade-invoke"] = "烈淬刀：你可以弃置一张牌，令你对 %dest 造成的伤害+1",
}

local poisonousDaggerSkill = fk.CreateTriggerSkill{
  name = "#poisonous_dagger_skill",
  attached_equip = "&poisonous_dagger",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#poisonous_dagger-invoke::"..data.to..":"..math.min(player:usedSkillTimes(self.name, Player.HistoryTurn) + 1, 5))
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player.room:getPlayerById(data.to), math.min(player:usedSkillTimes(self.name, Player.HistoryTurn), 5), self.name)
  end,
}
Fk:addSkill(poisonousDaggerSkill)
local poisonousDagger = fk.CreateWeapon{
  name = "&poisonous_dagger",
  suit = Card.Spade,
  number = 1,
  attack_range = 1,
  equip_skill = poisonousDaggerSkill,
}
extension:addCard(poisonousDagger)
Fk:loadTranslationTable{
  ["&poisonous_dagger"] = "混毒弯匕",
  ["#poisonous_dagger_skill"] = "混毒弯匕",
  [":&poisonous_dagger"] = "装备牌·武器<br /><b>攻击范围</b>：1<br /><b>武器技能</b>：当你使用【杀】指定目标后，你可以令目标角色失去X点体力（X为此武器本回合发动技能次数且至多为5）。",
  ["#poisonous_dagger-invoke"] = "混毒弯匕：你可以令 %dest 失去%arg点体力",
}

local waterSwordSkill = fk.CreateTriggerSkill{
  name = "#water_sword_skill",
  attached_equip = "&water_sword",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2 and
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick)) and
      data.targetGroup and #data.targetGroup == 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not player:isProhibited(p, data.card) then
        table.insertIfNeed(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#water_sword-invoke:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if data.card.name == "collateral" then  --TODO:

    else
      TargetGroup:pushTargets(data.targetGroup, self.cost_data)  --TODO: sort by action order
    end
  end,
}
Fk:addSkill(waterSwordSkill)
local waterSword = fk.CreateWeapon{
  name = "&water_sword",
  suit = Card.Club,
  number = 1,
  attack_range = 2,
  equip_skill = waterSwordSkill,
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)
    if player:isAlive() and player:isWounded() and self.equip_skill:isEffectable(player) then
      --room:broadcastPlaySound("./packages/tenyear/audio/card/&water_sword")
      --room:setEmotion(player, "./packages/tenyear/image/anim/&water_sword")
      room:recover{
        who = player,
        num = 1,
        skillName = self.name
      }
    end
  end,
}
extension:addCard(waterSword)
Fk:loadTranslationTable{
  ["&water_sword"] = "水波剑",
  ["#water_sword_skill"] = "水波剑",
  [":&water_sword"] = "装备牌·武器<br /><b>攻击范围</b>：2<br /><b>武器技能</b>：每回合限两次，你使用【杀】或普通锦囊牌可以额外指定一个目标。你失去装备区内的【水波剑】时，你回复1点体力。",
  ["#water_sword-invoke"] = "水波剑：你可以为%arg额外指定一个目标",
}

local thunderBladeSkill = fk.CreateTriggerSkill{
  name = "#thunder_blade_skill",
  attached_equip = "&thunder_blade",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#thunder_blade-invoke::"..data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local judge = {
      who = to,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.suit == Card.Spade then
      room:damage{
        to = to,
        damage = 3,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    elseif judge.card.suit == Card.Club then
      room:damage{
        to = to,
        damage = 1,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
Fk:addSkill(thunderBladeSkill)
local thunderBlade = fk.CreateWeapon{
  name = "&thunder_blade",
  suit = Card.Spade,
  number = 1,
  attack_range = 4,
  equip_skill = thunderBladeSkill,
}
extension:addCard(thunderBlade)
Fk:loadTranslationTable{
  ["&thunder_blade"] = "天雷刃",
  ["#thunder_blade_skill"] = "天雷刃",
  [":&thunder_blade"] = "装备牌·武器<br /><b>攻击范围</b>：4<br /><b>武器技能</b>：当你使用【杀】指定目标后，可以令其判定，若结果为：♠，其受到3点雷电伤害；♣，其受到1点雷电伤害，你回复1点体力并摸一张牌。",
  ["#thunder_blade-invoke"] = "天雷刃：你可以令 %dest 判定<br>♠，其受到3点雷电伤害；♣，其受到1点雷电伤害，你回复1点体力并摸一张牌",
}
Fk:loadTranslationTable{
  ["&ty__"] = "霹雳车",
  ["#ty__"] = "霹雳车",
  [":&ty__"] = "装备牌·宝物<br /><b>宝物技能</b>：锁定技，你回合内使用基本牌的伤害和回复数值+1且无距离限制。你回合外使用或打出基本牌时摸一张牌。此宝物离开装备区时销毁。",
}

return extension
