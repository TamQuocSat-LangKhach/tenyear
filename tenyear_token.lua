local extension = Package:new("tenyear_token", Package.CardPack)
Fk:loadTranslationTable{
  ["tenyear_token"] = "十周年衍生牌",
}

local U = require "packages/utility/utility"

local redSpearSkill = fk.CreateTriggerSkill{
  name = "#red_spear_skill",
  attached_equip = "red_spear",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
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
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    elseif judge.card.color == Card.Black then
      if not player.dead then
        player:drawCards(2, self.name)
      end
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
  ["red_spear"] = "红缎枪",
  ["#red_spear_skill"] = "红缎枪",
  [":red_spear"] = "装备牌·武器<br /><b>攻击范围</b>：3<br /><b>武器技能</b>：每回合限一次，当你使用【杀】造成伤害后，"..
  "你可以判定，若结果为红色，你回复1点体力；若结果为黑色，你摸两张牌。",
}

local quenchedBladeSkill = fk.CreateTriggerSkill{
  name = "#quenched_blade_skill",
  attached_equip = "quenched_blade",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and not player:isNude()
    and U.damageByCardEffect(player.room) and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true,
      ".|.|.|.|.|.|^"..tostring(player:getEquipment(Card.SubtypeWeapon)), "#quenched_blade-invoke::"..data.to.id, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, "quenched_blade", player, player)
    data.damage = data.damage + 1
  end,
}
local quenched_blade_targetmod = fk.CreateTargetModSkill{
  name = "#quenched_blade_targetmod",
  attached_equip = "quenched_blade",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
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
  ["quenched_blade"] = "烈淬刀",
  ["#quenched_blade_skill"] = "烈淬刀",
  [":quenched_blade"] = "装备牌·武器<br /><b>攻击范围</b>：2<br/><b>武器技能</b>：每回合限两次，你使用【杀】对目标角色造成伤害时，"..
  "你可以弃置一张牌，令此伤害+1；出牌阶段你可以多使用一张【杀】。",
  ["#quenched_blade-invoke"] = "烈淬刀：你可以弃置一张牌，令你对 %dest 造成的伤害+1",
}

local poisonousDaggerSkill = fk.CreateTriggerSkill{
  name = "#poisonous_dagger_skill",
  attached_equip = "poisonous_dagger",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash"
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
  ["poisonous_dagger"] = "混毒弯匕",
  ["#poisonous_dagger_skill"] = "混毒弯匕",
  [":poisonous_dagger"] = "装备牌·武器<br /><b>攻击范围</b>：1<br /><b>武器技能</b>：当你使用【杀】指定目标后，你可以令目标角色失去X点体力"..
  "（X为此武器本回合发动技能次数且至多为5）。",
  ["#poisonous_dagger-invoke"] = "混毒弯匕：你可以令 %dest 失去%arg点体力",
}

local waterSwordSkill = fk.CreateTriggerSkill{
  name = "#water_sword_skill",
  attached_equip = "water_sword",
  anim_type = "offensive",
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) < 2 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and #U.getUseExtraTargets(player.room, data, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local targets = U.getUseExtraTargets(player.room, data, false)
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#water_sword-invoke:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insert(data.tos, self.cost_data)
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
    if not player.dead and player:isWounded() and self.equip_skill:isEffectable(player) then
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
  ["water_sword"] = "水波剑",
  ["#water_sword_skill"] = "水波剑",
  [":water_sword"] = "装备牌·武器<br /><b>攻击范围</b>：2<br /><b>武器技能</b>：每回合限两次，你使用【杀】或普通锦囊牌可以额外指定一个目标。"..
  "你失去装备区内的【水波剑】时，你回复1点体力。",
  ["#water_sword-invoke"] = "水波剑：你可以为%arg额外指定一个目标",
}

local thunderBladeSkill = fk.CreateTriggerSkill{
  name = "#thunder_blade_skill",
  attached_equip = "thunder_blade",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash"
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
      if not to.dead then
        room:damage{
          to = to,
          damage = 3,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    elseif judge.card.suit == Card.Club then
      if not to.dead then
        room:damage{
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      if not player.dead then
        player:drawCards(1, self.name)
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
  ["thunder_blade"] = "天雷刃",
  ["#thunder_blade_skill"] = "天雷刃",
  [":thunder_blade"] = "装备牌·武器<br /><b>攻击范围</b>：4<br /><b>武器技能</b>：当你使用【杀】指定目标后，可以令其判定，"..
  "若结果为：♠，其受到3点雷电伤害；♣，其受到1点雷电伤害，你回复1点体力并摸一张牌。",
  ["#thunder_blade-invoke"] = "天雷刃：你可以令 %dest 判定<br>♠，其受到3点雷电伤害；♣，其受到1点雷电伤害，你回复1点体力并摸一张牌",
}

local siege_engine_slash = fk.CreateViewAsSkill{
  name = "siege_engine_slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("slash")
    card.skillName = "#siege_engine_skill"
    return card
  end,
}
Fk:addSkill(siege_engine_slash)
local siegeEngineSkill = fk.CreateTriggerSkill{
  name = "#siege_engine_skill",
  attached_equip = "siege_engine",
  events = {fk.EventPhaseStart, fk.Damage, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self) and player.phase == Player.Play
    elseif event == fk.Damage then
      return target == player and player:hasSkill(self) and data.card and table.contains(data.card.skillNames, self.name) and
      U.damageByCardEffect(player.room) and not data.to.dead and not data.to:isNude()
    elseif event == fk.TargetSpecified then
      return target == player and player:hasSkill(self) and data.card and table.contains(data.card.skillNames, self.name)
      and player:getMark("xianzhu1") > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local success, dat = player.room:askForUseActiveSkill(player, "siege_engine_slash", "#siege_engine-invoke", true)
      if success then
        self.cost_data = dat
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local card = Fk:cloneCard("slash")
      card.skillName = self.name
      room:useCard{
        from = player.id,
        tos = table.map(self.cost_data.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    elseif event == fk.Damage then
      local cards = room:askForCardsChosen(player, data.to, 1, 1 + player:getMark("xianzhu3"), "he", self.name)
      room:throwCard(cards, self.name, data.to, player)
    elseif event == fk.TargetSpecified then
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
      data.extra_data = data.extra_data or {}
      data.extra_data.siege_engineNullified = data.extra_data.siege_engineNullified or {}
      data.extra_data.siege_engineNullified[tostring(data.to)] = (data.extra_data.siege_engineNullified[tostring(data.to)] or 0) + 1
    end
  end,

  refresh_events = {fk.CardUseFinished, fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.BeforeCardsMove then
      return table.find(player:getCardIds("e"), function (id)
        return Fk:getCardById(id).name == "siege_engine"
      end)
    else
      return data.extra_data and data.extra_data.siege_engineNullified
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.BeforeCardsMove then
      local mirror_moves = {}
      local to_void, cancel_move = {},{}
      local no_updata = (player:getMark("xianzhu1") + player:getMark("xianzhu2") + player:getMark("xianzhu3")) == 0
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea ~= Card.Void then
          local move_info = {}
          local mirror_info = {}
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if Fk:getCardById(id).name == "siege_engine" and info.fromArea == Card.PlayerEquip then
              if not player.dead and no_updata and move.moveReason == fk.ReasonDiscard then
                table.insert(cancel_move, id)
              else
                table.insert(mirror_info, info)
                table.insert(to_void, id)
              end
            else
              table.insert(move_info, info)
            end
          end
          move.moveInfo = move_info
          if #mirror_info > 0 then
            local mirror_move = table.clone(move)
            mirror_move.to = nil
            mirror_move.toArea = Card.Void
            mirror_move.moveInfo = mirror_info
            table.insert(mirror_moves, mirror_move)
          end
        end
      end
      if #cancel_move > 0 then
        player.room:sendLog{ type = "#cancelDismantle", card = cancel_move, arg = "#siege_engine_skill"  }
      end
      if #to_void > 0 then
        table.insertTable(data, mirror_moves)
        player.room:sendLog{ type = "#destructDerivedCards", card = to_void, }
      end
    else
      for key, num in pairs(data.extra_data.siege_engineNullified) do
        local p = room:getPlayerById(tonumber(key))
        if p:getMark(fk.MarkArmorNullified) > 0 then
          room:removePlayerMark(p, fk.MarkArmorNullified, num)
        end
      end
      data.siege_engineNullified = nil
    end
  end,
}
local siege_engine_targetmod = fk.CreateTargetModSkill{
  name = "#siege_engine_targetmod",
  bypass_distances = function(self, player, skill, card)
    return skill.trueName == "slash_skill" and card and table.contains(card.skillNames, "#siege_engine_skill")
    and player:getMark("xianzhu1") > 0
  end,
  extra_target_func = function(self, player, skill, card)
    if skill.trueName == "slash_skill" and card and table.contains(card.skillNames, "#siege_engine_skill") then
      return player:getMark("xianzhu2")
    end
  end,
}
siegeEngineSkill:addRelatedSkill(siege_engine_targetmod)
Fk:addSkill(siegeEngineSkill)
local siegeEngine = fk.CreateTreasure{
  name = "&siege_engine",
  suit = Card.Spade,
  number = 9,
  equip_skill = siegeEngineSkill,
  on_uninstall = function(self, room, player)
    Treasure.onUninstall(self, room, player)
    local n = 0
    for i = 1, 3, 1 do
      n = n + player:getMark("xianzhu"..tostring(i))
      room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
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
extension:addCard(siegeEngine)
Fk:loadTranslationTable{
  ["siege_engine"] = "大攻车",
  [":siege_engine"] = "装备牌·宝物<br /><b>宝物技能</b>：出牌阶段开始时，你可以视为使用一张【杀】，当此【杀】对目标角色造成伤害后，你弃置其一张牌。"..
  "若此牌未升级，则不能被弃置。离开装备区后销毁。<br>升级选项：<br>1.此【杀】无视距离和防具；<br>2.此【杀】可指定目标+1；<br>3.此【杀】造成伤害后弃牌数+1。",
  ["#siege_engine_skill"] = "大攻车",
  ["siege_engine_slash"] = "大攻车",
  ["#siege_engine-invoke"] = "大攻车：你可以视为使用【杀】",
}

local catapultSkill = fk.CreateTriggerSkill{
  name = "#ty__catapult_skill",
  attached_equip = "ty__catapult",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.type == Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUsing and player.phase ~= Player.NotActive then
      if data.card.is_damage_card then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      elseif data.card.name == "peach" then
        data.additionalRecover = (data.additionalRecover or 0) + 1
      elseif data.card.name == "analeptic" then
        if data.extra_data and data.extra_data.analepticRecover then
          data.additionalRecover = (data.additionalRecover or 0) + 1
        else
          data.extra_data = data.extra_data or {}
          data.extra_data.additionalDrank = (data.extra_data.additionalDrank or 0) + 1
        end
      end
    elseif player.phase == Player.NotActive then
      player:drawCards(1, self.name)
    end
  end,
}
local catapult_targetmod = fk.CreateTargetModSkill{
  name = "#catapult_targetmod",
  bypass_distances =  function(self, player, skill, card)
    return player:hasSkill(catapultSkill) and player.phase ~= Player.NotActive and card and card.type == Card.TypeBasic
  end,
}
catapultSkill:addRelatedSkill(catapult_targetmod)
Fk:addSkill(catapultSkill)
local catapult = fk.CreateTreasure{
  name = "&ty__catapult",
  suit = Card.Diamond,
  number = 9,
  equip_skill = catapultSkill,
}
extension:addCard(catapult)
Fk:loadTranslationTable{
  ["ty__catapult"] = "霹雳车",
  ["#ty__catapult_skill"] = "霹雳车",
  [":ty__catapult"] = "装备牌·宝物<br /><b>宝物技能</b>：锁定技，你回合内使用基本牌的伤害和回复数值+1且无距离限制。"..
  "你回合外使用或打出基本牌时摸一张牌。离开装备区时销毁。",
}

local ty__drowningSkill = fk.CreateActiveSkill{
  name = "ty__drowning_skill",
  prompt = "#ty__drowning_skill",
  min_target_num = 1,
  max_target_num = 2,
  mod_target_filter = Util.TrueFunc,
  target_filter = function (self, to_select, selected, selected_cards, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, Self.id, card)
    end
  end,
  on_use = function(self, room, cardUseEvent)
    if cardUseEvent.tos == nil or #cardUseEvent.tos == 0 then return end
    cardUseEvent.extra_data = cardUseEvent.extra_data or {}
    cardUseEvent.extra_data.firstTargetOfTYDrowning = cardUseEvent.tos[1][1]
  end,
  on_effect = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    room:damage({
      from = from,
      to = to,
      card = effect.card,
      damage = 1,
      damageType = fk.ThunderDamage,
      skillName = self.name
    })
    if not to.dead then
      if effect.extra_data and effect.extra_data.firstTargetOfTYDrowning == effect.to then
        room:askForDiscard(to, 1, 1, true, self.name, false)
      else
        to:drawCards(1, self.name)
      end
    end
  end
}
local ty__drowning = fk.CreateTrickCard{
  name = "&ty__drowning",
  skill = ty__drowningSkill,
  is_damage_card = true,
  suit = Card.Spade,
  number = 6,
}
extension:addCard(ty__drowning)
Fk:loadTranslationTable{
  ["ty__drowning"] = "水淹七军",
  ["ty__drowning_skill"] = "水淹七军",
  [":ty__drowning"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一至两名角色<br /><b>效果</b>："..
  "第一名角色受到1点雷电伤害并弃置一张牌，该角色以外的角色受到1点雷电伤害并摸一张牌",
  ["#ty__drowning_skill"] = "选择1-2名目标角色，第一名角色受到1点雷电伤害并摸牌，第二名角色受到1点雷电伤害并弃牌",
}

local leftArm = fk.CreateWeapon{
  name = "&goddianwei_left_arm",
  suit = Card.NoSuit,
  number = 0,
  attack_range = 1,
  dynamic_attack_range = function(self, player)
    if player then
      local mark = U.getMark(player, "@qiexie_left")
      return #mark == 2 and tonumber(mark[2]) or nil
    end
  end,
  dynamic_equip_skills = function(self, player)
    if player then
      return table.map(U.getMark(player, "qiexie_left_skills"), function(skillName) return Fk.skills[skillName] end)
    end
  end,
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)

    local qiexieInfo = U.getMark(player, "@qiexie_left")
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

extension:addCard(leftArm)

local rightArm = fk.CreateWeapon{
  name = "&goddianwei_right_arm",
  suit = Card.NoSuit,
  number = 0,
  attack_range = 1,
  dynamic_attack_range = function(self, player)
    if player then
      local mark = U.getMark(player, "@qiexie_right")
      return #mark == 2 and tonumber(mark[2]) or nil
    end
  end,
  dynamic_equip_skills = function(self, player)
    if player then
      return table.map(U.getMark(player, "qiexie_right_skills"), function(skillName) return Fk.skills[skillName] end)
    end
  end,
  on_uninstall = function(self, room, player)
    Weapon.onUninstall(self, room, player)

    local qiexieInfo = U.getMark(player, "@qiexie_right")
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

extension:addCard(rightArm)

return extension
