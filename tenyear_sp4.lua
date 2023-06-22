local extension = Package("tenyear_sp4")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp4"] = "十周年专属4",
}

--夏侯令女 秦宜禄 2022.7.18
local huangzu = General(extension, "ty__huangzu", "qun", 4)
local jinggong = fk.CreateViewAsSkill{
  name = "jinggong",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local to = player.room:getPlayerById(TargetGroup:getRealTargets(use.tos)[1])
    use.additionalDamage = (use.additionalDamage or 0) + math.min(player:distanceTo(to), 5) - 1
  end,
}
local jinggong_targetmod = fk.CreateTargetModSkill{
  name = "#jinggong_targetmod",
  distance_limit_func =  function(self, player, skill, card)
    if table.contains(card.skillNames, "jinggong") then
      return 999
    end
  end,
}
local xiaojun = fk.CreateTriggerSkill{
  name = "xiaojun",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.firstTarget and #AimGroup:getAllTargets(data.tos) == 1 then
      local to = AimGroup:getAllTargets(data.tos)[1]
      return to ~= player.id and player.room:getPlayerById(to):getHandcardNum() > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = AimGroup:getAllTargets(data.tos)[1]
    return player.room:askForSkillInvoke(player, self.name, nil,
      "#xiaojun-invoke::"..to..":"..tostring(player.room:getPlayerById(to):getHandcardNum() // 2)..":"..data.card:getSuitString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(AimGroup:getAllTargets(data.tos)[1])
    local n = to:getHandcardNum() // 2
    local cards = room:askForCardsChosen(player, to, n, n, "h", self.name)
    room:throwCard(cards, self.name, to, player)
    if player:getHandcardNum() < 2 or data.card == Card.NoSuit then return end
    if table.find(cards, function(id) return Fk:getCardById(id).suit == data.card.suit end) then
      room:askForDiscard(player, 1, 1, false, self.name, false)
    end
  end,
}
jinggong:addRelatedSkill(jinggong_targetmod)
huangzu:addSkill(jinggong)
huangzu:addSkill(xiaojun)
Fk:loadTranslationTable{
  ["ty__huangzu"] = "黄祖",
  ["jinggong"] = "精弓",
  [":jinggong"] = "你可以将装备牌当无距离限制的【杀】使用，此【杀】的伤害基数值改为X（X为你计算与该角色的距离且至多为5）。",
  ["xiaojun"] = "骁隽",
  [":xiaojun"] = "你使用牌指定其他角色为唯一目标后，你可以弃置其一半手牌（向下取整）。若其中有与你指定其为目标的牌花色相同的牌，"..
  "你弃置一张手牌。",
  ["#xiaojun-invoke"] = "骁隽：你可以弃置 %dest 一半手牌（%arg张），若其中有%arg2牌，你弃置一张手牌",
}

local yanghu = General(extension, "ty__yanghu", "wei", 3)
local deshao = fk.CreateTriggerSkill{
  name = "deshao",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.color == Card.Black and data.from ~= player.id and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#deshao-invoke::"..data.from)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local from = room:getPlayerById(data.from)
    if from:getHandcardNum() >= player:getHandcardNum() then
      local id = room:askForCardChosen(player, from, "he", self.name)
      room:throwCard(id, self.name, from, player)
    end
  end,
}
local mingfa = fk.CreateTriggerSkill{
  name = "mingfa",
  anim_type = "offensive",
  events = {fk.CardUseFinished, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.CardUseFinished then
        return target == player and player.phase == Player.Play and #player:getPile(self.name) == 0 and
          (data.card.trueName == "slash" or data.card:isCommonTrick()) and player.room:getCardArea(data.card) == Card.Processing and
          not data.card:isVirtual() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
      else
        return target.phase == Player.Finish and player:getMark(self.name) ~= 0 and #player:getPile(self.name) > 0 and
          player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local room = player.room
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id end), 1, 1, "#mingfa-choose:::"..data.card:toLogString(), self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      player:addToPile(self.name, data.card, true, self.name)
      room:setPlayerMark(player, self.name, self.cost_data)
      local to = room:getPlayerById(self.cost_data)
      local mark = to:getMark("@@mingfa")
      if mark == 0 then mark = {} end
      table.insert(mark, player.id)
      room:setPlayerMark(to, "@@mingfa", mark)
    else
      local card = Fk:cloneCard(Fk:getCardById(player:getPile(self.name)[1]).name)
      if card.trueName ~= "nullification" and card.name ~= "collateral" and not player:isProhibited(target, card) then
        --据说没有合法性检测甚至无懈都能虚空用，甚至不合法目标还能触发贞烈。我不好说
        local n = math.max(target:getHandcardNum(), 1)
        n = math.min(n, 5)
        for i = 1, n, 1 do
          if target.dead then break end
          room:useCard({
            card = card,
            from = player.id,
            tos = {{target.id}},
            skillName = self.name,
          })
        end
      end
      room:setPlayerMark(player, self.name, 0)
      if not target.dead then
        local mark = target:getMark("@@mingfa")
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(target, "@@mingfa", mark)
      end
      room:moveCards({
        from = player.id,
        ids = player:getPile(self.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if #player:getPile(self.name) > 0 and player:getMark(self.name) ~= 0 then
      if event == fk.EventLoseSkill then
        return target == player and data == self
      else
        return target == player or target:getMark("@@mingfa") ~= 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventLoseSkill or (event == fk.Death and target == player) then
      local to = room:getPlayerById(player:getMark(self.name))
      room:setPlayerMark(player, self.name, 0)
      room:moveCards({
        from = player.id,
        ids = player:getPile(self.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
        specialName = self.name,
      })
      if not to.dead then
        local mark = to:getMark("@@mingfa")
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(to, "@@mingfa", mark)
      end
    else
      local mark = target:getMark("@@mingfa")
      if table.contains(mark, player.id) then
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(target, "@@mingfa", mark)
        room:setPlayerMark(player, self.name, 0)
        room:moveCards({
          from = player.id,
          ids = player:getPile(self.name),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
          specialName = self.name,
        })
      end
    end
  end,
}
yanghu:addSkill(deshao)
yanghu:addSkill(mingfa)
Fk:loadTranslationTable{
  ["ty__yanghu"] = "羊祜",
  ["deshao"] = "德劭",
  [":deshao"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后，你可以摸一张牌，然后若其手牌数大于等于你，你弃置其一张牌。",
  ["mingfa"] = "明伐",
  [":mingfa"] = "出牌阶段内限一次，你使用【杀】或普通锦囊牌结算完毕后，若你没有“明伐”牌，可将此牌置于武将牌上并选择一名其他角色。"..
  "该角色的结束阶段，视为你对其使用X张“明伐”牌（X为其手牌数，最少为1，最多为5），然后移去“明伐”牌。",
  ["#deshao-invoke"] = "德劭：你可以摸一张牌，然后若 %dest 手牌数不少于你，你弃置其一张牌",
  ["#mingfa-choose"] = "明伐：将%arg置为“明伐”，选择一名角色，其结束阶段视为对其使用其手牌张数次“明伐”牌",
  ["@@mingfa"] = "明伐",
}

local zhangxuan = General(extension, "zhangxuan", "wu", 4, 4, General.Female)
local tongli = fk.CreateTriggerSkill{
  name = "tongli",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget and
      (not data.card:isVirtual() or #data.card.subcards > 0) and not table.contains(data.card.skillNames, self.name) and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      not (table.contains({"peach", "analeptic"}, data.card.trueName) and table.find(player.room.alive_players, function(p) return p.dying end)) then
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        if Fk:getCardById(id).suit ~= Card.NoSuit then
          table.insertIfNeed(suits, Fk:getCardById(id).suit)
        end
      end
      return #suits == player:getMark("@tongli-turn")
    end
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.tongli = player:getMark("@tongli-turn")
    player.room:setPlayerMark(player, "tongli_tos", AimGroup:getAllTargets(data.tos))
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.AfterCardUseDeclared then
        return player.phase == Player.Play and not table.contains(data.card.skillNames, self.name)
      else
        return data.extra_data and data.extra_data.tongli and player:getMark("tongli_tos") ~= 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:addPlayerMark(player, "@tongli-turn", 1)
    else
      local n = data.extra_data.tongli
      local targets = player:getMark("tongli_tos")
      room:setPlayerMark(player, "tongli_tos", 0)
      local tos = table.simpleClone(targets)
      for i = 1, n, 1 do
        if player.dead then return end
        for _, id in ipairs(targets) do
          if room:getPlayerById(id).dead then
            return
          end
        end
        if table.contains({"savage_assault", "archery_attack"}, data.card.name) then  --to modify tenyear's stupid processing
          for _, p in ipairs(room:getOtherPlayers(player)) do
            if not player:isProhibited(p, Fk:cloneCard(data.card.name)) then
              table.insertIfNeed(tos, p.id)
            end
          end
        elseif table.contains({"amazing_grace", "god_salvation"}, data.card.name) then
          for _, p in ipairs(room:getAlivePlayers()) do
            if not player:isProhibited(p, Fk:cloneCard(data.card.name)) then
              table.insertIfNeed(tos, p.id)
            end
          end
        end
        room:sortPlayersByAction(tos)
        room:useVirtualCard(data.card.name, nil, player, table.map(tos, function(id) return room:getPlayerById(id) end), self.name, true)
      end
    end
  end,
}
local shezang = fk.CreateTriggerSkill{
  name = "shezang",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (target == player or player.phase ~= Player.NotActive) and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
zhangxuan:addSkill(tongli)
zhangxuan:addSkill(shezang)
Fk:loadTranslationTable{
  ["zhangxuan"] = "张嫙",
  ["tongli"] = "同礼",
  [":tongli"] = "出牌阶段，当你使用牌指定目标后，若你手牌中的花色数等于你此阶段已使用牌的张数，你可令此牌效果额外执行X次（X为你手牌中的花色数）。",
  ["shezang"] = "奢葬",
  [":shezang"] = "每轮限一次，当你或你回合内有角色进入濒死状态时，你可以从牌堆获得不同花色的牌各一张。",
  ["@tongli-turn"] = "同礼",

  ["$tongli1"] = "胞妹殊礼，妾幸同之。",
  ["$tongli2"] = "夫妻之礼，举案齐眉。",
  ["$shezang1"] = "世间千百物，物物皆相思。",
  ["$shezang2"] = "伊人将逝，何物为葬？",
  ["~zhangxuan"] = "陛下，臣妾绝无异心！",
}

local wangchang = General(extension, "ty__wangchang", "wei", 3)
local ty__kaiji = fk.CreateActiveSkill{
  name = "ty__kaiji",
  anim_type = "switch",
  switch_skill_name = "ty__kaiji",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      player:drawCards(player.maxHp, self.name)
    else
      room:askForDiscard(player, 1, player.maxHp, true, self.name, false, ".", "#ty__kaiji-discard:::"..player.maxHp)
    end
  end,
}
local pingxi = fk.CreateTriggerSkill{
  name = "pingxi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:getMark("pingxi-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("pingxi-turn")
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#pingxi-choose:::"..player:getMark("pingxi-turn"), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p:isNude() then
        local card = room:askForCardChosen(player, p, "he", self.name)
        room:throwCard({card}, self.name, p, player)
      end
    end
    for _, id in ipairs(self.cost_data) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        room:useVirtualCard("slash", nil, player, p, self.name, true)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
        player.room:addPlayerMark(player, "pingxi-turn", #move.moveInfo)
      end
    end
  end,
}
wangchang:addSkill(ty__kaiji)
wangchang:addSkill(pingxi)
Fk:loadTranslationTable{
  ["ty__wangchang"] = "王昶",
  ["ty__kaiji"] = "开济",
  [":ty__kaiji"] = "转换技，出牌阶段限一次，阳：你可以摸等于体力上限张数的牌；阴：你可以弃置至多等于体力上限张数的牌（至少一张）。",
  ["pingxi"] = "平袭",
  [":pingxi"] = "结束阶段，你可选择至多X名其他角色（X为本回合因弃置而进入弃牌堆的牌数），弃置这些角色各一张牌，然后视为对这些角色各使用一张【杀】。",
  ["#ty__kaiji-discard"] = "开济：你可以弃置至多%arg张牌",
  ["#pingxi-choose"] = "平袭：你可以选择至多%arg名角色，弃置这些角色各一张牌并视为对这些角色各使用一张【杀】",
}
--冯方2022.8.27

local bianxi = General(extension, "bianxi", "wei", 4)
local dunxi = fk.CreateTriggerSkill{
  name = "dunxi",
  anim_type = "control",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.is_damage_card and data.tos
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1, "#dunxi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), "@bianxi_dun", 1)
  end,

  refresh_events = {fk.TargetSpecifying, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.TargetSpecifying then
        return player:getMark("@bianxi_dun") > 0 and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
          data.firstTarget and data.tos and #AimGroup:getAllTargets(data.tos) == 1
      else
        return data.extra_data and data.extra_data.dunxi
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.TargetSpecifying then
      local room = player.room
      room:removePlayerMark(player, "@bianxi_dun", 1)
      local targets = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if not player:isProhibited(p, data.card) then
          if (data.card.trueName == "slash" and p ~= player) or
            (data.card.name == "peach" and p:isWounded()) or
            (data.card.trueName ~= "slash" and data.card.name ~= "peach") then
            table.insertIfNeed(targets, p.id)
          end
        end
      end
      local to = TargetGroup:getRealTargets(data.tos)[1]
      local new_to = table.random(targets)
      TargetGroup:removeTarget(data.targetGroup, to)
      TargetGroup:pushTargets(data.targetGroup, new_to)
      room:delay(1000)  --来一段市长动画？
      room:doIndicate(player.id, {new_to})
      if to == new_to then
        room:loseHp(player, 1, self.name)
        if not player.dead and player.phase == Player.Play then
          data.extra_data = data.extra_data or {}
          data.extra_data.dunxi = true
        end
      end
    else
      player.room.logic:getCurrentEvent():findParent(GameEvent.Phase):shutdown()
    end
  end,
}
bianxi:addSkill(dunxi)
Fk:loadTranslationTable{
  ["bianxi"] = "卞喜",
  ["dunxi"] = "钝袭",
  [":dunxi"] = "当你使用伤害牌结算后，你可令其中一个目标获得1个“钝”标记。有“钝”标记的角色使用基本牌或锦囊牌指定唯一目标时，"..
  "移去一个“钝”，然后目标改为随机一名角色。若随机的目标与原本目标相同，则其失去1点体力并结束出牌阶段。",
  ["#dunxi-choose"] = "钝袭：你可以令一名角色获得“钝”标记，其使用下一张牌目标改为随机角色",
  ["@bianxi_dun"] = "钝",
}

local quanhuijie = General(extension, "quanhuijie", "wu", 3, 3, General.Female)
local huishu = fk.CreateTriggerSkill{
  name = "huishu",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("huishu1"), self.name)
    player.room:askForDiscard(player, player:getMark("huishu2"), player:getMark("huishu2"), false, self.name, false)
  end,

  refresh_events = {fk.GameStart, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        if player:usedSkillTimes(self.name) > 0 and player:getMark("huishu-turn") < player:getMark("huishu3") then
          for _, move in ipairs(data) do
            if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  player.room:addPlayerMark(player, "huishu-turn", 1)
                end
              end
            end
          end
          return player:getMark("huishu-turn") >= player:getMark("huishu3")
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:setPlayerMark(player, "huishu1", 3)
      room:setPlayerMark(player, "huishu2", 1)
      room:setPlayerMark(player, "huishu3", 2)
      room:setPlayerMark(player, "@" .. self.name, string.format("%d-%d-%d", 3, 1, 2))
    else
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", player:getMark("huishu-turn"), "discardPile")
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
local yishu = fk.CreateTriggerSkill{
  name = "yishu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.Play then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local max = math.max(player:getMark("huishu1"), player:getMark("huishu2"), player:getMark("huishu3"))
    local min = math.min(player:getMark("huishu1"), player:getMark("huishu2"), player:getMark("huishu3"))
    local maxes, mins = {}, {}
    for _, mark in ipairs({"huishu1", "huishu2", "huishu3"}) do
      if player:getMark(mark) == max then
        table.insert(maxes, mark)
      end
      if player:getMark(mark) == min then
        table.insert(mins, mark)
      end
    end
    local choice1 = room:askForChoice(player, mins, self.name, "#yishu-add")
    local choice2 = room:askForChoice(player, maxes, self.name, "#yishu-lose")
    room:addPlayerMark(player, choice1, 2)
    room:removePlayerMark(player, choice2, 1)
    room:setPlayerMark(player, "@huishu", string.format("%d-%d-%d",
      player:getMark("huishu1"),
      player:getMark("huishu2"),
      player:getMark("huishu3")))
  end,
}
local ligong = fk.CreateTriggerSkill{
  name = "ligong",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("huishu1") > 4 or player:getMark("huishu2") > 4 or player:getMark("huishu3") > 4
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-yishu", nil)
    local generals = Fk:getGeneralsRandomly(4, Fk:getAllGenerals(),
      table.map(room:getAllPlayers(), function(p) return p.general end),
      (function (p) return (p.kingdom ~= "wu" or p.gender ~= General.Female) end))
    local skills = {"Cancel"}
    for _, general in ipairs(generals) do
      for _, skill in ipairs(general.skills) do
        if skill.frequency ~= Skill.Wake and skill.frequency ~= Skill.Limited then
          table.insertIfNeed(skills, skill.name)
        end
      end
      for _, skill in ipairs(general.other_skills) do
        if skill.frequency ~= Skill.Wake and skill.frequency ~= Skill.Limited then
          table.insertIfNeed(skills, skill.name)
        end
      end
    end
    local choices = {}
    for i = 1, 2, 1 do
      local choice = room:askForChoice(player, skills, self.name, "#ligong-choice", true)
      table.insert(choices, choice)
      if choice == "Cancel" then break end
      table.removeOne(skills, choice)
    end
    if table.contains(choices, "Cancel") then
      player:drawCards(3, self.name)
    else
      room:handleAddLoseSkills(player, "-huishu|"..choices[1].."|"..choices[2], nil)
    end
  end,
}
quanhuijie:addSkill(huishu)
quanhuijie:addSkill(yishu)
quanhuijie:addSkill(ligong)
Fk:loadTranslationTable{
  ["quanhuijie"] = "全惠解",
  ["huishu"] = "慧淑",
  [":huishu"] = "摸牌阶段结束时，你可以摸3张牌然后弃置1张手牌。若如此做，你本回合弃置超过2张牌时，从弃牌堆中随机获得等量的非基本牌。",
  ["yishu"] = "易数",
  [":yishu"] = "锁定技，当你于出牌阶段外失去牌后，〖慧淑〗中最小的一个数字+2且最大的一个数字-1。",
  ["ligong"] = "离宫",
  [":ligong"] = "觉醒技，准备阶段，若〖慧淑〗有数字达到5，你加1点体力上限并回复1点体力，失去〖易数〗，然后从已开通的随机四个吴国女性武将中选择至多两个技能获得（如果不获得技能则不失去〖慧淑〗并摸三张牌）。",
  ["@huishu"] = "慧淑",
  ["huishu1"] = "摸牌数",
  ["huishu2"] = "弃牌数",
  ["huishu3"] = "获得锦囊所需弃牌数",
  ["#yishu-add"] = "易数：请选择增加的一项",
  ["#yishu-lose"] = "易数：请选择减少的一项",
  ["#ligong-choice"] = "离宫：获得两个技能并失去“易数”和“慧淑”，或点“取消”不失去“慧淑”并摸三张牌",

  ["$huishu1"] = "心有慧镜，善解百般人意。",
  ["$huishu2"] = "袖着静淑，可揾夜阑之泪。",
  ["$yishu1"] = "此命由我，如织之数可易。",
  ["$yishu2"] = "易天定之数，结人定之缘。",
  ["$ligong1"] = "伴君离高墙，日暮江湖远。",
  ["$ligong2"] = "巍巍宫门开，自此不复来。",
  ["~quanhuijie"] = "妾有愧于陛下。",
}
--胡昭

local lvkuanglvxiang = General(extension, "ty__lvkuanglvxiang", "wei", 4)
local shuhe = fk.CreateActiveSkill{
  name = "shuhe",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:showCards(effect.cards)
    local card = Fk:getCardById(effect.cards[1])
    local yes = false
    for _, p in ipairs(room:getAlivePlayers()) do
      for _, id in ipairs(p:getCardIds{Player.Equip, Player.Judge}) do
        if Fk:getCardById(id).number == card.number then
          room:obtainCard(player, id, true, fk.ReasonPrey)
          yes = true
        end
      end
    end
    if not yes then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#shuhe-choose:::"..card:toLogString(), self.name, false)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:obtainCard(to, card, true, fk.ReasonGive)
      if player:getMark("@ty__liehou") < 5 then
        room:addPlayerMark(player, "@ty__liehou", 1)
      end
    end
  end,
}
local ty__liehou = fk.CreateTriggerSkill{
  name = "ty__liehou",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DrawNCards, fk.AfterDrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + 1 + player:getMark("@ty__liehou")
    else
      local room = player.room
      local n = 1 + player:getMark("@ty__liehou")
      if #room:askForDiscard(player, n, n, true, self.name, true, ".", "#ty__liehou-discard:::"..n) < n then
        room:loseHp(player, 1, self.name)
      end
    end
  end,
}
lvkuanglvxiang:addSkill(shuhe)
lvkuanglvxiang:addSkill(ty__liehou)
Fk:loadTranslationTable{
  ["ty__lvkuanglvxiang"] = "吕旷吕翔",
  ["shuhe"] = "数合",
  [":shuhe"] = "出牌阶段限一次，你可以展示一张手牌，并获得场上与展示牌相同点数的牌。如果你没有因此获得牌，你需将展示牌交给一名其他角色，"..
  "然后〖列侯〗的额外摸牌数+1（至多为5）。",
  ["ty__liehou"] = "列侯",
  [":ty__liehou"] = "锁定技，摸牌阶段，你额外摸一张牌，然后选择一项：1.弃置等量的牌；2.失去1点体力。",
  ["#shuhe-choose"] = "数合：选择一名其他角色，将%arg交给其",
  ["@ty__liehou"] = "列侯",
  ["#ty__liehou-discard"] = "列侯：你需弃置%arg张牌，否则失去1点体力",
}

local huangquan = General(extension, "ty__huangquan", "shu", 3)
local quanjian = fk.CreateActiveSkill{
  name = "quanjian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("quanjian1-turn") == 0 or player:getMark("quanjian2-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and to_select ~= Self.id then
      if Self:getMark("quanjian2-turn") == 0 then
        return true
      else
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if Fk:currentRoom():getPlayerById(to_select):inMyAttackRange(p) then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if target:inMyAttackRange(p) then
        table.insert(targets, p.id)
      end
    end
    local choices = {}
    if player:getMark("quanjian1-turn") == 0 and #targets > 0 then
      table.insert(choices, "quanjian1")
    end
    if player:getMark("quanjian2-turn") == 0 then
      table.insert(choices, "quanjian2")
    end
    local choice = room:askForChoice(player, choices, self.name)
    room:addPlayerMark(player, choice.."-turn", 1)
    local to
    if choice == "quanjian1" then
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#quanjian-choose", self.name)
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:doIndicate(target.id, {to})
    end
    local choices2 = {"quanjian_cancel"}
    if choice == "quanjian1" then
      table.insert(choices2, 1, "quanjian_damage")
    else
      table.insert(choices2, 1, "quanjian_draw")
    end
    local choice2 = room:askForChoice(target, choices2, self.name)
    if choice2 == "quanjian_damage" then
      room:damage{
        from = target,
        to = room:getPlayerById(to),
        damage = 1,
        skillName = self.name,
      }
    elseif choice2 == "quanjian_draw" then
      if #target.player_cards[Player.Hand] < math.min(target:getMaxCards(), 5) then
        target:drawCards(math.min(target:getMaxCards(), 5) - #target.player_cards[Player.Hand])
      end
      if #target.player_cards[Player.Hand] > target:getMaxCards() then
        local n = #target.player_cards[Player.Hand] - target:getMaxCards()
        room:askForDiscard(target, n, n, false, self.name, false)
      end
      room:addPlayerMark(target, "quanjian_prohibit-turn", 1)
    else
      room:addPlayerMark(target, "quanjian_damage-turn", 1)
    end
  end,
}
local quanjian_prohibit = fk.CreateProhibitSkill{
  name = "#quanjian_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("quanjian_prohibit-turn") > 0
  end,
}
local quanjian_record = fk.CreateTriggerSkill{
  name = "#quanjian_record",
  anim_type = "offensive",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("quanjian_damage-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + target:getMark("quanjian_damage-turn")
    player.room:setPlayerMark(target, "quanjian_damage-turn", 0)
  end,
}
local tujue = fk.CreateTriggerSkill{
  name = "tujue",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p) return p.id end), 1, 1, "#tujue-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Hand])
    dummy:addSubcards(player.player_cards[Player.Equip])
    local n = #dummy.subcards
    room:obtainCard(self.cost_data, dummy, false, fk.ReasonGive)
    room:recover({
      who = player,
      num = math.min(n, player.maxHp - player.hp),
      recoverBy = player,
      skillName = self.name
    })
    player:drawCards(n, self.name)
  end,
}
quanjian:addRelatedSkill(quanjian_prohibit)
quanjian:addRelatedSkill(quanjian_record)
huangquan:addSkill(quanjian)
huangquan:addSkill(tujue)
Fk:loadTranslationTable{
  ["ty__huangquan"] = "黄权",
  ["quanjian"] = "劝谏",
  [":quanjian"] = "出牌阶段每项限一次，你选择以下一项令一名其他角色选择是否执行：1. 对一名其攻击范围内你指定的角色造成1点伤害。2. 将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束。若其不执行，则其本回合下次受到的伤害+1。",
  ["tujue"] = "途绝",
  [":tujue"] = "限定技，当你处于濒死状态时，你可以将所有牌交给一名其他角色，然后你回复等量的体力值并摸等量的牌。",
  ["quanjian1"] = "对一名其攻击范围内你指定的角色造成1点伤害",
  ["quanjian2"] = "将手牌调整至手牌上限（最多摸到5张），其不能使用手牌直到回合结束",
  ["#quanjian-choose"] = "劝谏：选择一名其攻击范围内的角色",
  ["quanjian_damage"] = "对指定的角色造成1点伤害",
  ["quanjian_draw"] = "将手牌调整至手牌上限（最多摸到5张），不能使用手牌直到回合结束",
  ["quanjian_cancel"] = "不执行，本回合下次受到的伤害+1",
  ["#tujue-choose"] = "途绝：你可以将所有牌交给一名其他角色，然后回复等量的体力值并摸等量的牌",

  ["$quanjian1"] = "陛下宜后镇，臣请为先锋！",
  ["$quanjian2"] = "吴人悍战，陛下万不可涉险！",
  ["$tujue1"] = "归蜀无路，孤臣泪尽江北。",
  ["$tujue2"] = "受吾主殊遇，安能降吴！",
  ["~ty__huangquan"] = "败军之将，何言忠乎？",
}

local sunru = General(extension, "ty__sunru", "wu", 3, 3, General.Female)
local xiecui = fk.CreateTriggerSkill{
  name = "xiecui",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.from and not data.from.dead and data.from.phase ~= Player.NotActive and data.card then
      if data.from:getMark("xiecui-turn") == 0 then
        player.room:addPlayerMark(data.from, "xiecui-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#xiecui-invoke:"..data.from.id..":"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.damage = data.damage + 1
    if data.from.kingdom == "wu" and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(data.from, data.card, false)
      room:addPlayerMark(data.from, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,
}
local youxu = fk.CreateTriggerSkill{
  name = "youxu",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.to == Player.NotActive and #target.player_cards[Player.Hand] > target.hp and not target.dead and player:usedSkillTimes(self.name) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#youxu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards({id})
    local targets = table.map(room:getOtherPlayers(target), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#youxu-choose:::"..Fk:getCardById(id):toLogString(), self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    room:obtainCard(to, id, true, fk.ReasonGive)
    to = room:getPlayerById(to)
    if to:isWounded() and table.every(room:getOtherPlayers(to), function (p) return p.hp >= to.hp end) then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
sunru:addSkill(xiecui)
sunru:addSkill(youxu)
Fk:loadTranslationTable{
  ["ty__sunru"] = "孙茹",
  ["xiecui"] = "撷翠",
  [":xiecui"] = "当一名角色于其回合内使用牌首次造成伤害时，你可令此伤害+1。若该角色为吴势力角色，其获得此伤害牌且本回合手牌上限+1。",
  ["youxu"] = "忧恤",
  [":youxu"] = "一名角色回合结束时，若其手牌数大于体力值，你可以展示其一张手牌然后交给另一名角色。若获得牌的角色体力值全场最低，其回复1点体力。",
  ["#xiecui-invoke"] = "撷翠：你可以令 %src 对 %dest造成的伤害+1",
  ["#youxu-invoke"] = "忧恤：你可以展示 %dest 的一张手牌，然后交给另一名角色",
  ["#youxu-choose"] = "忧恤：选择获得%arg的角色",

  ["$xiecui1"] = "东隅既得，亦收桑榆。",
  ["$xiecui2"] = "江东多娇，锦花相簇。",
  ["$youxu1"] = "积富之家，当恤众急。",
  ["$youxu2"] = "周忧济难，请君恤之。",
  ["~ty__sunru"] = "伯言，抗儿便托付于你了。",
}
--赵昂
--牛辅 蔡阳2022.9.24

local zhangfen = General(extension, "zhangfen", "wu", 4)
local wanglu = fk.CreateTriggerSkill{
  name = "wanglu",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getEquipment(Card.SubtypeTreasure) then
      if Fk:getCardById(player:getEquipment(Card.SubtypeTreasure)).name == "siege_engine" then
        room:addPlayerMark(player, self.name, 1)
        return
      end
    else
      for i = 1, 3, 1 do
        room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
      end
    end
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "siege_engine" and room:getCardArea(id) == Card.Void then
        room:useCard({
          from = player.id,
          tos = {{player.id}},
          card = Fk:getCardById(id, true),
        })
        break
      end
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) > 0 and data.from == Player.Start
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
    player:gainAnExtraPhase(Player.Play)
  end,
}
local xianzhu = fk.CreateTriggerSkill{
  name = "xianzhu",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and
      player:getEquipment(Card.SubtypeTreasure) and Fk:getCardById(player:getEquipment(Card.SubtypeTreasure)).name == "siege_engine" and
      (player:getMark("xianzhu1") + player:getMark("xianzhu2") + player:getMark("xianzhu3")) < 5
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"xianzhu2", "xianzhu3"}
    if player:getMark("xianzhu1") == 0 then
      table.insert(choices, 1, "xianzhu1")
    end
    local choice = room:askForChoice(player, choices, self.name, "#xianzhu-choice")
    room:addPlayerMark(player, choice, 1)
  end,
}
local chaixie = fk.CreateTriggerSkill{
  name = "chaixie",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.Void then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId, true).name == "siege_engine" then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for i = 1, 3, 1 do
      n = n + player:getMark("xianzhu"..tostring(i))
      room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
    end
    player:drawCards(n, self.name)
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local id = 0
    for i = #data, 1, -1 do
      local move = data[i]
      if move.toArea ~= Card.Void then
        for j = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[j]
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId, true).name == "siege_engine" then
            id = info.cardId
            table.removeOne(move.moveInfo, info)
            break
          end
        end
      end
    end
    if id ~= 0 then
      local room = player.room
      room:sendLog{
        type = "#destructDerivedCard",
        arg = Fk:getCardById(id, true):toLogString(),
      }
      room:moveCardTo(Fk:getCardById(id, true), Card.Void, nil, fk.ReasonJustMove, "", "", true)
    end
  end,
}
zhangfen:addSkill(wanglu)
zhangfen:addSkill(xianzhu)
zhangfen:addSkill(chaixie)
Fk:loadTranslationTable{
  ["zhangfen"] = "张奋",
  ["wanglu"] = "望橹",
  [":wanglu"] = "锁定技，准备阶段，你将【大攻车】置入你的装备区，若你的装备区内已有【大攻车】，则你执行一个额外的出牌阶段。<br>"..
  "<font color='grey'>【大攻车】<br>♠9 装备牌·宝物<br /><b>装备技能</b>：出牌阶段开始时，你可以视为使用一张【杀】，"..
  "当此【杀】对目标角色造成伤害后，你弃置其一张牌。若此牌未升级，则不能被弃置。离开装备区时销毁。",
  ["xianzhu"] = "陷筑",
  [":xianzhu"] = "当你使用【杀】造成伤害后，你可以升级【大攻车】（每个【大攻车】最多升级5次）。升级选项：<br>"..
  "【大攻车】的【杀】无视距离和防具；<br>【大攻车】的【杀】可指定目标+1；<br>【大攻车】的【杀】造成伤害后弃牌数+1。",
  ["chaixie"] = "拆械",
  [":chaixie"] = "锁定技，当【大攻车】销毁后，你摸X张牌（X为该【大攻车】的升级次数）。",
  ["#xianzhu-choice"] = "陷筑：选择【大攻车】使用【杀】的增益效果",
  ["xianzhu1"] = "无视距离和防具",
  ["xianzhu2"] = "可指定目标+1",
  ["xianzhu3"] = "造成伤害后弃牌数+1",
}
--杜夔2022.10.9

local yinfuren = General(extension, "yinfuren", "wei", 3, 3, General.Female)
local yingyu = fk.CreateTriggerSkill{
  name = "yingyu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (player.phase == Player.Play or (player.phase == Player.Finish and player:usedSkillTimes("yongbi", Player.HistoryGame) > 0))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() end), function(p) return p.id end)
    if #targets < 2 then return end
    local tos = room:askForChoosePlayers(player, targets, 2, 2, "#yingyu-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target1 = room:getPlayerById(self.cost_data[1])
    local target2 = room:getPlayerById(self.cost_data[2])
    room:doIndicate(player.id, {self.cost_data[1]})
    local id1 = room:askForCardChosen(player, target1, "h", self.name)
    room:doIndicate(player.id, {self.cost_data[2]})
    local id2 = room:askForCardChosen(player, target2, "h", self.name)
    target1:showCards(id1)
    target2:showCards(id2)
    if Fk:getCardById(id1).suit ~= Fk:getCardById(id2).suit and
      Fk:getCardById(id1).suit ~= Card.NoSuit and Fk:getCardById(id1).suit ~= Card.NoSuit then
      local to = room:askForChoosePlayers(player, self.cost_data, 1, 1, "#yingyu2-choose", self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(self.cost_data)
      end
      if to == target1.id then
        room:obtainCard(self.cost_data[1], id2, true, fk.ReasonPrey)
      else
        room:obtainCard(self.cost_data[2], id1, true, fk.ReasonPrey)
      end
    end
  end,
}
local yongbi = fk.CreateActiveSkill{
  name = "yongbi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).gender == General.Male
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.player_cards[Player.Hand])
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    local suits = {}
    for _, id in ipairs(dummy.subcards) do
      if Fk:getCardById(id, true).suit ~= Card.NoSuit then
        table.insertIfNeed(suits, Fk:getCardById(id, true).suit)
      end
    end
    if #suits > 1 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
      room:addPlayerMark(target, MarkEnum.AddMaxCards, 2)
    end
    if #suits > 2 then
      room:setPlayerMark(player, "@@yongbi", 1)
      room:setPlayerMark(target, "@@yongbi", 1)
    end
  end,
}
local yingyu_trigger = fk.CreateTriggerSkill{
  name = "#yingyu_trigger",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@yongbi") > 0 and data.damage > 1
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage - 1
  end,
}
yongbi:addRelatedSkill(yingyu_trigger)
yinfuren:addSkill(yingyu)
yinfuren:addSkill(yongbi)
Fk:loadTranslationTable{
  ["yinfuren"] = "尹夫人",
  ["yingyu"] = "媵予",
  [":yingyu"] = "准备阶段，你可以展示两名角色的各一张手牌，若花色不同，则你选择其中的一名角色获得另一名角色的展示牌。",
  ["yongbi"] = "拥嬖",
  [":yongbi"] = "限定技，出牌阶段，你可将所有手牌交给一名男性角色，然后〖媵予〗改为结束阶段也可以发动。根据其中牌的花色数量，"..
  "你与其永久获得以下效果：至少两种，手牌上限+2；至少三种，受到大于1点的伤害时伤害-1。",
  ["#yingyu-choose"] = "媵予：你可以展示两名角色各一张手牌，若花色不同，选择其中一名角色获得另一名角色的展示牌",
  ["#yingyu2-choose"] = "媵予：选择一名角色，其获得另一名角色的展示牌",
  ["@@yongbi"] = "拥嬖",
  ["#yingyu_trigger"] = "拥嬖",

  ["$yingyu1"] = "妾身蒲柳，幸蒙将军不弃。",
  ["$yingyu2"] = "妾之所有，愿尽予君。",
  ["$yongbi1"] = "海誓山盟，此生不渝。",
  ["$yongbi2"] = "万千宠爱，幸君怜之。",
  ["~yinfuren"] = "奈何遇君何其晚乎？",
}

local guanhai = General(extension, "guanhai", "qun", 4)
local suoliang = fk.CreateTriggerSkill{
  name = "suoliang",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      not data.to.dead and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suoliang-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCardsChosen(player, data.to, 1, math.min(data.to.maxHp, 5), "he", self.name)
    if #cards > 0 then
      local dummy = Fk:cloneCard("dilu")
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).suit == Card.Heart or Fk:getCardById(id).suit == Card.Club then
          dummy:addSubcard(id)
        end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, true, fk.ReasonPrey)
      else
        room:throwCard(cards, self.name, data.to, player)
      end
    end
  end,
}
local qinbao = fk.CreateTriggerSkill{
  name = "qinbao",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #table.filter(player.room:getOtherPlayers(player), function(p) return p:getHandcardNum() >= player:getHandcardNum() end) > 0
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return p:getHandcardNum() >= player:getHandcardNum() end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
guanhai:addSkill(suoliang)
guanhai:addSkill(qinbao)
Fk:loadTranslationTable{
  ["guanhai"] = "管亥",
  ["suoliang"] = "索粮",
  [":suoliang"] = "每回合限一次，你对一名其他角色造成伤害后，选择其至多X张牌（X为其体力上限且最多为5），获得其中的<font color='red'>♥</font>和♣牌。若你未获得牌，则弃置你选择的牌。",
  ["qinbao"] = "侵暴",
  [":qinbao"] = "锁定技，手牌数大于等于你的其他角色不能响应你使用的【杀】或普通锦囊牌。",
  ["#suoliang-invoke"] = "索粮：你可以选择 %dest 最多其体力上限张牌，获得其中的<font color='red'>♥</font>和♣牌，若没有则弃置这些牌",
}

--刘徽

local chengui = General(extension, "chengui", "qun", 3)
local yingtu = fk.CreateTriggerSkill{
  name = "yingtu",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 then
      local room = player.room
      if room.current.phase == Player.Draw then return end
      for _, move in ipairs(data) do
        if move.to ~= nil and (move.from == nil or move.to ~= move.from) and move.toArea == Card.PlayerHand then
          local p = room:getPlayerById(move.to)
          if p:getNextAlive() == player or player:getNextAlive() == p then
            self.yingtu_from = p
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if self.yingtu_from:getNextAlive() == player then
      self.yingtu_to = player:getNextAlive()
    else
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p:getNextAlive() == player then
          self.yingtu_to = p
          break
        end
      end
    end
    return room:askForSkillInvoke(player, self.name, nil, "#yingtu-invoke:"..self.yingtu_from.id..":"..self.yingtu_to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCardChosen(player, self.yingtu_from, "he", self.name)
    room:obtainCard(player.id, card, false, fk.ReasonPrey)
    local to = self.yingtu_to
    local card = Fk:getCardById(room:askForCard(player, 1, 1, true, self.name, false, ".", "#yingtu-choose::"..to.id)[1])
    room:obtainCard(to, card, false, fk.ReasonGive)
    if card.type == Card.TypeEquip then
      room:useCard({
        from = to.id,
        tos = {{to.id}},
        card = card,
      })
    end
  end,
}
local congshi = fk.CreateTriggerSkill{
  name = "congshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.card.type == Card.TypeEquip then
      local to = player.room:getPlayerById(data.tos[1][1])
      return table.every(player.room:getOtherPlayers(to), function(p)
        return #to.player_cards[Player.Equip] >= #p.player_cards[Player.Equip]
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1)
  end,
}
chengui:addSkill(yingtu)
chengui:addSkill(congshi)
Fk:loadTranslationTable{
  ["chengui"] = "陈珪",
  ["yingtu"] = "营图",
  [":yingtu"] = "每回合限一次，当一名角色于当前回合的摸牌阶段外获得牌后，若其是你的上家或下家，你可以获得该角色的一张牌，然后交给你的下家或上家一张牌。若以此法给出的牌为装备牌，获得牌的角色使用之。",
  ["congshi"] = "从势",
  [":congshi"] = "锁定技，当一名角色使用一张装备牌结算结束后，若其装备区里的牌数为全场最多的，你摸一张牌。",
  ["#yingtu-invoke"] = "营图：你可以获得 %src 的一张牌，然后交给 %dest 一张牌，若交出的是装备牌则其使用之",
  ["#yingtu-choose"] = "营图：选择交给 %dest 的一张牌",

  ["$yingtu1"] = "不过略施小计，聊戏莽夫耳。",
  ["$yingtu2"] = "栖虎狼之侧，安能不图存身？",
  ["$congshi1"] = "阁下奉天子以令诸侯，珪自当相从。",
  ["$congshi2"] = "将军率六师以伐不臣，珪何敢相抗？",
  ["~chengui"] = "终日戏虎，竟为虎所噬。",
}

local huban = General(extension, "ty__huban", "wei", 4)
local chongyi = fk.CreateTriggerSkill{
  name = "chongyi",
  anim_type = "support",
  events = {fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase == Player.Play and player.tag[self.name] and #player.tag[self.name] > 0 then
      local tag = player.tag[self.name]
      if event == fk.CardUsing then
        return #tag == 1 and tag[1] == "slash"
      else
        local name = tag[#tag]
        player.tag[self.name] = {}
        return name == "slash"
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if event == fk.CardUsing then
      prompt = "#chongyi-draw::"
    else
      prompt = "#chongyi-maxcards::"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      target:drawCards(2, self.name)
      room:addPlayerMark(target, "chongyi-turn", 1)
    else
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and target.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.tag[self.name] = player.tag[self.name] or {}
    table.insert(player.tag[self.name], data.card.trueName)
  end,
}
local chongyi_targetmod = fk.CreateTargetModSkill{
  name = "#chongyi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("chongyi-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
chongyi:addRelatedSkill(chongyi_targetmod)
huban:addSkill(chongyi)
Fk:loadTranslationTable{
  ["ty__huban"] = "胡班",
  ["chongyi"] = "崇义",
  [":chongyi"] = "一名角色出牌阶段内使用的第一张牌若为【杀】，你可令其摸两张牌且此阶段使用【杀】次数上限+1；一名角色出牌阶段结束时，若其此阶段使用的最后一张牌为【杀】，你可令其本回合手牌上限+1。",
  ["#chongyi-draw"] = "崇义：你可以令 %dest 摸两张牌且此阶段使用【杀】次数上限+1",
  ["#chongyi-maxcards"] = "崇义：你可以令 %dest 本回合手牌上限+1",

  ["$chongyi1"] = "班虽卑微，亦知何为大义。",
  ["$chongyi2"] = "大义当头，且助君一臂之力。",
  ["~ty__huban"] = "行义而亡，虽死无憾。",
}

local liuye = General(extension, "ty__liuye", "wei", 3)
local poyuan = fk.CreateTriggerSkill{
  name = "poyuan",
  anim_type = "control",
  events = {fk.GamePrepared, fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      return event == fk.GamePrepared or
        (event == fk.EventPhaseChanging and target == player and data.from == Player.RoundStart)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if not player:getEquipment(Card.SubtypeTreasure) or Fk:getCardById(player:getEquipment(Card.SubtypeTreasure)).name ~= "ty__catapult" then
      return room:askForSkillInvoke(player, self.name, nil, "#poyuan-invoke")
    else
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return not p:isNude() end), function(p) return p.id end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#poyuan-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getEquipment(Card.SubtypeTreasure) then
      if Fk:getCardById(player:getEquipment(Card.SubtypeTreasure)).name == "ty__catapult" then
        local to = room:getPlayerById(self.cost_data)
        local cards = room:askForCardsChosen(player, to, 1, 2, "he", self.name)
        room:throwCard(cards, self.name, to, player)
        return
      end
    end
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id, true).name == "ty__catapult" and room:getCardArea(id) == Card.Void then
        room:useCard({
          from = player.id,
          tos = {{player.id}},
          card = Fk:getCardById(id, true),
        })
        break
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local id = 0
    for i = #data, 1, -1 do
      local move = data[i]
      if move.toArea ~= Card.Void then
        for j = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[j]
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId, true).name == "ty__catapult" then
            id = info.cardId
            table.removeOne(move.moveInfo, info)
            break
          end
        end
      end
    end
    if id ~= 0 then
      local room = player.room
      room:sendLog{
        type = "#destructDerivedCard",
        arg = Fk:getCardById(id, true):toLogString(),
      }
      room:moveCardTo(Fk:getCardById(id, true), Card.Void, nil, fk.ReasonJustMove, "", "", true)
    end
  end,
}
local huace = fk.CreateViewAsSkill{
  name = "huace",
  interaction = function()
    local names = {}
    local mark = Self:getMark("huace2")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id, true)
      if card:isCommonTrick() and card.trueName ~= "nullification" and card.name ~= "adaptation" and not card.is_derived then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    return UI.ComboBox {choices = names}
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local huace_record = fk.CreateTriggerSkill{
  name = "#huace_record",

  refresh_events = {fk.AfterCardUseDeclared, fk.RoundStart},
  can_refresh = function(self, event, target, player, data)
    return (event == fk.AfterCardUseDeclared and data.card:isCommonTrick()) or event == fk.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      local mark = player:getMark("huace1")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.card.trueName)
      room:setPlayerMark(player, "huace1", mark)
    else
      room:setPlayerMark(player, "huace2", player:getMark("huace1"))
      room:setPlayerMark(player, "huace1", 0)
    end
  end,
}
huace:addRelatedSkill(huace_record)
liuye:addSkill(poyuan)
liuye:addSkill(huace)
Fk:loadTranslationTable{
  ["ty__liuye"] = "刘晔",
  ["poyuan"] = "破垣",
  [":poyuan"] = "游戏开始时或回合开始时，若你的装备区里没有【霹雳车】，你可以将【霹雳车】置于装备区；若有，你可以弃置一名其他角色至多两张牌。<br>"..
  "<font color='grey'>【霹雳车】<br>♦9 装备牌·宝物<br /><b>装备技能</b>：锁定技，你回合内使用基本牌的伤害和回复数值+1且无距离限制，"..
  "使用的【酒】使【杀】伤害基数值增加的效果+1。你回合外使用或打出基本牌时摸一张牌。离开装备区时销毁。",
  ["huace"] = "画策",
  [":huace"] = "出牌阶段限一次，你可以将一张手牌当上一轮没有角色使用过的普通锦囊牌使用。",
  ["#poyuan-invoke"] = "破垣：你可以装备【霹雳车】",
  ["#poyuan-choose"] = "破垣：你可以弃置一名其他角色至多两张牌",
  ["#destructDerivedCard"] = "%arg 被销毁",
}

Fk:loadTranslationTable{
  ["wangwei"] = "王威",
  ["ruizhan"] = "锐战",
  [":ruizhan"] = "其他的角色准备阶段，若其手牌数大于等于体力值，你可以与其拼点：若你赢或者拼点牌有【杀】，你视为对其使用一张【杀】；"..
  "若两项均满足，此【杀】造成伤害后你获得其一张牌。",
  ["shilie"] = "示烈",
  [":shilie"] = "出牌阶段限一次，你可以选择一项：1.回复1点体力，然后将两张牌置于武将牌上（不足则全放，总数不能大于游戏人数）；"..
  "2.失去1点体力，然后获得武将牌上的两张牌。<br>你死亡时，你可将武将牌上的牌交给除伤害来源外的一名其他角色。",
}

local zhaoyan = General(extension, "ty__zhaoyan", "wei", 3)
local funing = fk.CreateTriggerSkill{
  name = "funing",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#funing-invoke:::"..player:usedSkillTimes(self.name, Player.HistoryTurn) + 1)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      player.room:askForDiscard(player, n, n, true, self.name, false, ".")
    end
  end,
}
local bingji = fk.CreateActiveSkill{
  name = "bingji",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  interaction = UI.ComboBox {choices = {"slash", "peach"}},
  can_use = function(self, player)
    if not player:isKongcheng() then
      local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString()
      return table.every(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getSuitString() == suit end) and
        (player:getMark("bingji-turn") == 0 or not table.contains(player:getMark("bingji-turn"), suit))
    end
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:showCards(player.player_cards[Player.Hand])
    local card = Fk:cloneCard(self.interaction.data)
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if self.interaction.data == "peach" then
        if p:isWounded() and not player:isProhibited(p, card) then
          table.insert(targets, p.id)
        end
      else
        if not player:isProhibited(p, card) then
          table.insert(targets, p.id)
        end
      end
    end
    if #targets == 0 then return end
    local mark = player:getMark("bingji-turn")
    local icon = player:getMark("@bingji-turn")
    if mark == 0 then mark = {} end
    if icon == 0 then icon = {} end
    local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString()
    local suits = {"spade", "heart", "club", "diamond"}
    local icons = {"♠", "♥", "♣", "♦"}
    for i = 1, 4, 1 do
      if suits[i] == suit then
        table.insert(mark, suit)
        table.insert(icon, icons[i])
      end
    end
    room:setPlayerMark(player, "bingji-turn", mark)
    room:setPlayerMark(player, "@bingji-turn", icon)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#bingji-choose:::"..self.interaction.data, self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    room:useVirtualCard(self.interaction.data, nil, player, to, self.name, false)
  end
}
zhaoyan:addSkill(funing)
zhaoyan:addSkill(bingji)
Fk:loadTranslationTable{
  ["ty__zhaoyan"] = "赵俨",
  ["funing"] = "抚宁",
  [":funing"] = "当你使用一张牌时，你可以摸两张牌然后弃置X张牌（X为此技能本回合发动次数）。",
  ["bingji"] = "秉纪",
  [":bingji"] = "出牌阶段每种花色限一次，若你的手牌均为同一花色，则你可以展示所有手牌（至少一张），然后视为对一名其他角色使用一张【杀】或一张【桃】。",
  ["#funing-invoke"] = "抚宁：你可以摸两张牌，然后弃置%arg张牌",
  ["@bingji-turn"] = "秉纪",
  ["#bingji-choose"] = "秉纪：选择一名角色视为对其使用【%arg】",
}

Fk:loadTranslationTable{
  ["leibo"] = "雷薄",
  ["silve"] = "私掠",
  [":silve"] = "游戏开始时，你选择一名其他角色为“私掠”角色。<br>"..
  "“私掠”角色造成伤害后，你可以获得受伤角色一张牌（每回合每名角色限一次）。<br>"..
  "“私掠”角色受到伤害后，你需对伤害来源使用一张【杀】，否则你弃置一张手牌。",
  ["shuaijie"] = "衰劫",
  [":shuaijie"] = "限定技，出牌阶段，若你体力值与装备区里的牌均大于“私掠”角色或“私掠”角色已死亡，你可以减1点体力上限，然后选择一项：<br>"..
  "1.获得“私掠”角色至多3张牌；<br>2.从牌堆获得三张类型不同的牌。<br>然后“私掠”角色改为你。",
}

local wanglie = General(extension, "wanglie", "qun", 3)
local chongwang = fk.CreateTriggerSkill{
  name = "chongwang",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target ~= player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      local mark = player:getMark(self.name)
      if mark ~= 0 and #mark > 1 then
        return mark[2] == player.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel", "chongwang2"}
    if player.room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, 2, "chongwang1")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#chongwang-invoke::"..target.id)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data == "chongwang1" then
      player.room:obtainCard(target, data.card, true, fk.ReasonJustMove)
    else
      if data.toCard ~= nil then
        data.toCard = nil
      else
        data.nullifiedTargets = TargetGroup:getRealTargets(data.tos)
      end
    end
  end,

  refresh_events = {fk.CardUsing, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return player:hasSkill(self.name, true)
    else
      return data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      if target == player and player:hasSkill(self.name) then
        room:setPlayerMark(player, "@@chongwang", 1)
      else
        room:setPlayerMark(player, "@@chongwang", 0)
      end
      local mark = player:getMark(self.name)
      if mark == 0 then mark = {} end
      if #mark == 2 then
        mark[2] = mark[1]  --mark2上一张牌使用者，mark1这张牌使用者
        mark[1] = data.from
      else
        table.insert(mark, 1, data.from)
      end
      room:setPlayerMark(player, self.name, mark)
    else
      --[[local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryPhase)
      room:addPlayerMark(player, "zuojian-phase", #events)
      room:addPlayerMark(player, "@zuojian-phase", #events)]]  --TODO: 需要一个反向查找记录
    end
  end,
}
local huagui = fk.CreateTriggerSkill{
  name = "huagui",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), function(p) return p.id end)
    if #targets == 0 then return end
    local nums = {0, 0, 0}
    for _, p in ipairs(room.alive_players) do
      if p.role == "lord" or p.role == "loyalist" then
        nums[1] = nums[1] + 1
      elseif p.role == "rebel" then
        nums[2] = nums[2] + 1
      else
        nums[3] = nums[3] + 1
      end
    end
    local n = math.max(table.unpack(nums))
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#huagui-choose:::"..tostring(n), self.name, true, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.map(self.cost_data, function(id) return room:getPlayerById(id) end)

    local extraData = {
      num = 1,
      min_num = 1,
      include_equip = true,
      pattern = ".",
      reason = self.name,
    }
    for _, p in ipairs(tos) do
      p.request_data = json.encode({ "choose_cards_skill", "#huagui-card:"..player.id, true, json.encode(extraData) })
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", tos)
    for _, p in ipairs(tos) do
      local id
      if p.reply_ready then
        local replyCard = json.decode(p.client_reply).card
        id = json.decode(replyCard).subcards[1]
      else
        id = table.random(p:getCardIds{Player.Hand, Player.Equip})
      end
      room:setPlayerMark(p, "huagui-phase", id)
    end

    for _, p in ipairs(tos) do
      local id = p:getMark("huagui-phase")
      local choices = {"huagui1"}
      if room:getCardArea(id) == Player.Hand then
        table.insert(choices, "huagui2")
      end
      local card = Fk:getCardById(id)
      p.request_data = json.encode({ choices, self.name, "#huagui-choice:"..player.id.."::"..card:toLogString() })
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForChoice", tos)
    local get = true
    for _, p in ipairs(tos) do
      local choice
      if p.reply_ready then
        choice = p.client_reply
      else
        choice = "huagui1"
      end
      local card = Fk:getCardById(p:getMark("huagui-phase"))
      if choice == "huagui1" then
        get = false
        room:obtainCard(player, card, false, fk.ReasonGive)
      else
        p:showCards({card})
      end
    end

    if get then
      room:delay(2000)
    end
    for _, p in ipairs(tos) do
      if get then
        local card = Fk:getCardById(p:getMark("huagui-phase"))
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
      room:setPlayerMark(p, "huagui-phase", 0)
    end
  end,
}
wanglie:addSkill(chongwang)
wanglie:addSkill(huagui)
Fk:loadTranslationTable{
  ["wanglie"] = "王烈",
  ["chongwang"] = "崇望",
  [":chongwang"] = "其他角色使用一张基本牌或普通锦囊牌时，若你为上一张牌的使用者，你可令其获得其使用的牌或令该牌无效。",
  ["huagui"] = "化归",
  [":huagui"] = "出牌阶段开始时，你可秘密选择至多X名其他角色（X为最大阵营存活人数），这些角色同时选择一项：交给你一张牌；或展示一张牌。"..
  "若均选择展示牌，你获得这些牌。",
  ["@@chongwang"] = "崇望",
  ["#chongwang-invoke"] = "崇望：你可以令 %dest 对%arg执行的一项",
  ["chongwang1"] = "其获得此牌",
  ["chongwang2"] = "此牌无效",
  ["#huagui-choose"] = "化归：你可以秘密选择至多%arg名角色，各选择交给你一张牌或展示一张牌",
  ["#huagui-card"] = "化归：选择一张牌，交给 %src 或展示之",
  ["#huagui-choice"] = "化归：选择将%arg交给 %src 或展示之",
  ["huagui1"] = "交出",
  ["huagui2"] = "展示",
}

local dingfuren = General(extension, "dingfuren", "wei", 3, 3, General.Female)
local fengyan = fk.CreateActiveSkill{
  name = "fengyan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  interaction = function(self)
    local choices = {}
    if Self:getMark("fengyan1-phase") == 0 then
      table.insert(choices, "fengyan1-phase")
    end
    if Self:getMark("fengyan2-phase") == 0 then
      table.insert(choices, "fengyan2-phase")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:getMark("fengyan1-phase") == 0 or player:getMark("fengyan2-phase") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if self.interaction.data == "fengyan1-phase" then
        return target.hp <= Self.hp and not target:isKongcheng()
      elseif self.interaction.data == "fengyan2-phase" then
        return target:getHandcardNum() <= Self:getHandcardNum() and not Self:isProhibited(target, Fk:cloneCard("slash"))
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data, 1)
    if self.interaction.data == "fengyan1-phase" then
      local card = room:askForCard(target, 1, 1, true, self.name, false, ".", "#fengyan-give:"..player.id)
      room:obtainCard(player.id, card[1], false, fk.ReasonGive)
    elseif self.interaction.data == "fengyan2-phase" then
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    end
  end,
}
local fudao = fk.CreateTriggerSkill{
  name = "fudao",
  anim_type = "support",
  events = {fk.GameStart, fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TargetSpecified then
        return target:getMark("@@fudao") ~= 0 and data.firstTarget and table.find(AimGroup:getAllTargets(data.tos), function(id)
          return player.room:getPlayerById(id):getMark("@@fudao") ~= 0 and table.contains(target:getMark("@@fudao"), id) end) and
          player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
      elseif event == fk.TargetConfirmed then
        return target == player and data.from ~= player.id and player.room:getPlayerById(data.from):getMark("@@juelie") > 0 and
          data.card.color == Card.Black
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#fudao-choose", self.name, false, true)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      local mark = player:getMark("@@fudao")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, to.id)
      room:setPlayerMark(player, "@@fudao", mark)
      mark = to:getMark("@@fudao")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(to, "@@fudao", mark)
    elseif event == fk.TargetSpecified then
      target:drawCards(2, self.name)
      for _, id in ipairs(target:getMark("@@fudao")) do
        if table.contains(AimGroup:getAllTargets(data.tos), id) then
          room:getPlayerById(id):drawCards(2, self.name)
        end
      end
    elseif event == fk.TargetConfirmed then
      room:setPlayerMark(room:getPlayerById(data.from), "fudao-turn", 1)
    end
  end,
}
local fudao_trigger = fk.CreateTriggerSkill{
  name = "#fudao_trigger",
  mute = true,
  events = {fk.Death, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("@@fudao") ~= 0 then
      if event == fk.Death then
        return data.damage and data.damage.from and not data.damage.from.dead and data.damage.from:getMark("@@fudao") == 0
      elseif event == fk.DamageCaused then
        return data.to:getMark("@@juelie") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Death then
      player.room:setPlayerMark(data.damage.from, "@@juelie", 1)
    elseif event == fk.DamageCaused then
      data.damage = data.damage + 1
    end
  end,
}
local fudao_prohibit = fk.CreateProhibitSkill{
  name = "#fudao_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("fudao-turn") > 0
  end,
}
fudao:addRelatedSkill(fudao_trigger)
fudao:addRelatedSkill(fudao_prohibit)
dingfuren:addSkill(fengyan)
dingfuren:addSkill(fudao)
Fk:loadTranslationTable{
  ["dingfuren"] = "丁尚涴",
  ["fengyan"] = "讽言",
  [":fengyan"] = "出牌阶段每项限一次，你可以选择一名其他角色，若其体力值小于等于你，你令其交给你一张手牌；"..
  "若其手牌数小于等于你，你视为对其使用一张无距离和次数限制的【杀】。",
  ["fudao"] = "抚悼",
  [":fudao"] = "游戏开始时，你选择一名其他角色，你与其每回合首次使用牌指定对方为目标后，各摸两张牌。杀死你或该角色的其他角色获得“决裂”标记，"..
  "你或该角色对有“决裂”的角色造成的伤害+1；“决裂”角色使用黑色牌指定你为目标后，其本回合不能再使用牌。",
  ["fengyan1-phase"] = "令一名体力值不大于你的角色交给你一张手牌",
  ["fengyan2-phase"] = "视为对一名手牌数不大于你的角色使用【杀】",
  ["#fengyan-give"] = "讽言：你须交给 %src 一张手牌",
  ["@@fudao"] = "抚悼",
  ["#fudao-choose"] = "抚悼：请选择要“抚悼”的角色",
  ["@@juelie"] = "决裂",
  
  ["$fengyan1"] = "既将我儿杀之，何复念之！",
  ["$fengyan2"] = "乞问曹公，吾儿何时归还？",
  ["$fudao1"] = "弑子之仇，不共戴天！",
  ["$fudao2"] = "眼中泪绝，尽付仇怆。",
  ["~dingfuren"] = "吾儿既丧，天地无光……",
}

local luyi = General(extension, "luyi", "qun", 3, 3, General.Female)
local fuxue = fk.CreateTriggerSkill{
  name = "fuxue",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if player.phase == Player.Start and player.tag[self.name] and #player.tag[self.name] > 0 then
        local tag = player.tag[self.name]
        for i = #tag, 1, -1 do
          if player.room:getCardArea(tag[i]) ~= Card.DiscardPile then
            table.removeOne(player.tag[self.name], tag[i])
          end
        end
        return #player.tag[self.name] > 0
      end
      if player.phase == Player.Finish then
        local cards = player:getMark("fuxue-turn")
        if cards == 0 then
          return true
        else
          for _, id in ipairs(player.player_cards[Player.Hand]) do
            if table.contains(cards, id) then return end
          end
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.phase == Player.Start then
      return player.room:askForSkillInvoke(player, self.name, nil, "#fuxue-invoke:::"..player.hp)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if player.phase == Player.Start then
      local room = player.room
      local cards = player.tag[self.name]
      local get = {}
      while #cards > 0 and #get < player.hp do
        room:fillAG(player, cards)
        local id = room:askForAG(player, cards, true, self.name)  --TODO: temporarily use AG. AG function need cancelable!
        if id ~= nil then
          table.removeOne(cards, id)
          table.insert(get, id)
          room:closeAG(player)
        else
          room:closeAG(player)
          break
        end
      end
      if #get > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(get)
        room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
        room:setPlayerMark(player, "fuxue-turn", get)
      end
    else
      player:drawCards(player.hp, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then --TODO: ReasonJudge
        player.tag[self.name] = player.tag[self.name] or {}
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).sub_type ~= Card.SubtypeDelayedTrick or info.fromArea ~= Card.Processing then
            table.insertIfNeed(player.tag[self.name], info.cardId)
          end
        end
      end
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.DiscardPile and player.tag[self.name] and #player.tag[self.name] > 0 then
          table.removeOne(player.tag[self.name], info.cardId)
        end
      end
    end
  end,
}
local yaoyi = fk.CreateTriggerSkill{
  name = "yaoyi",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(player.room:getAlivePlayers()) do
      local yes = true
      for _, skill in ipairs(p.player_skills) do
        if skill.switchSkillName then
          yes = false
          break
        end
      end
      if yes then
        room:handleAddLoseSkills(p, "shoutan", nil, true, false)
      end
    end
  end,

  refresh_events = {fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, true, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAllPlayers()) do
      room:handleAddLoseSkills(p, "-shoutan", nil, true, true)
    end
  end,
}
local yaoyi_prohibit = fk.CreateProhibitSkill{
  name = "#yaoyi_prohibit",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    if table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill("yaoyi") end) then
      if from ~= to then
        local fromskill = {}
        for _, skill in ipairs(from.player_skills) do
          if skill.switchSkillName then
            table.insertIfNeed(fromskill, skill.switchSkillName)
          end
        end
        local toskill = {}
        for _, skill in ipairs(to.player_skills) do
          if skill.switchSkillName then
            table.insertIfNeed(toskill, skill.switchSkillName)
          end
        end
        if #fromskill == 0 or #toskill == 0 then return false end
        if #fromskill > 1 then  --FIXME: 多个转换技
        end
        return from:getSwitchSkillState(fromskill[1], false) == to:getSwitchSkillState(toskill[1], false)
      end
    end
  end,
}
local shoutan = fk.CreateActiveSkill{
  name = "shoutan",
  anim_type = "switch",
  switch_skill_name = "shoutan",
  card_num = function()
    if Self:hasSkill("yaoyi") then
      return 0
    else
      return 1
    end
  end,
  target_num = 0,
  can_use = function(self, player)
    if player:hasSkill("yaoyi") then
      return true--player:getMark("shoutan-phase") == 0 FIXME: 避免无限空发
    else
      return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end
  end,
  card_filter = function(self, to_select, selected)
    if Self:hasSkill("yaoyi") then
      return false
    elseif #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
        return Fk:getCardById(to_select).color ~= Card.Black
      else
        return Fk:getCardById(to_select).color == Card.Black
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
  end,
}
yaoyi:addRelatedSkill(yaoyi_prohibit)
luyi:addSkill(fuxue)
luyi:addSkill(yaoyi)
luyi:addRelatedSkill(shoutan)
Fk:loadTranslationTable{
  ["luyi"] = "卢弈",
  ["fuxue"] = "复学",
  [":fuxue"] = "准备阶段，你可以从弃牌堆中获得至多X张不因使用而进入弃牌堆的牌。结束阶段，若你手中没有以此法获得的牌，你摸X张牌。（X为你的体力值）",
  ["yaoyi"] = "邀弈",
  [":yaoyi"] = "锁定技，游戏开始时，所有没有转换技的角色获得〖手谈〗；你发动〖手谈〗无需弃置牌且无次数限制。所有角色使用牌只能指定自己及与自己转换技状态不同的角色为目标。",
  ["shoutan"] = "手谈",
  [":shoutan"] = "转换技，出牌阶段限一次，你可以弃置一张：阳：非黑色手牌；阴：黑色手牌。",
  ["#fuxue-invoke"] = "复学：你可以获得弃牌堆中至多%arg张不因使用而进入弃牌堆的牌",
  
  ["$fuxue1"] = "普天之大，唯此处可安书桌。",
  ["$fuxue2"] = "书中自有风月，何故东奔西顾？",
  ["$yaoyi1"] = "对弈未分高下，胜负可问春风。",
  ["$yaoyi2"] = "我掷三十六道，邀君游弈其中。",
  ["$shoutan1"] = "对弈博雅，落子珠玑胜无声。",
  ["$shoutan2"] = "弈者无言，手执黑白谈古今。",
  ["~luyi"] = "此生博弈，落子未有悔……",
}

local mushun = General(extension, "mushun", "qun", 4)
local jinjianm = fk.CreateTriggerSkill{
  name = "jinjianm",
  anim_type = "defensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@mushun_jin", 1)
    if event == fk.Damaged then
      local to = data.from
      if to and not to.dead and to ~= player and not player:isKongcheng() and not to:isKongcheng() and
        room:askForSkillInvoke(player, self.name, nil, "#jinjianm-invoke::"..to.id) then
        local pindian = player:pindian({to}, self.name)
        if pindian.results[to.id].winner == player and player:isWounded() then
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      end
    end
  end
}
local jinjianm_attackrange = fk.CreateAttackRangeSkill{
  name = "#jinjianm_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@mushun_jin")
  end,
}
local shizhao = fk.CreateTriggerSkill{
  name = "shizhao",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:isKongcheng() and player.phase == Player.NotActive and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@mushun_jin") > 0 then
      room:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:removePlayerMark(player, "@mushun_jin", 1)
      player:drawCards(2, self.name)
    else
      room:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      room:addPlayerMark(player, "@shizhao-turn", 1)
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@shizhao-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@shizhao-turn")
    player.room:setPlayerMark(player, "@shizhao-turn", 0)
  end,
}
jinjianm:addRelatedSkill(jinjianm_attackrange)
mushun:addSkill(jinjianm)
mushun:addSkill(shizhao)
Fk:loadTranslationTable{
  ["mushun"] = "穆顺",
  ["jinjianm"] = "劲坚",
  [":jinjianm"] = "当你造成或受到伤害后，你获得一个“劲”标记，然后你可以与伤害来源拼点：若你赢，你回复1点体力。每有一个“劲”你的攻击范围+1。",
  ["shizhao"] = "失诏",
  [":shizhao"] = "锁定技，你的回合外，当你每回合第一次失去最后一张手牌时：若你有“劲”，你移去一个“劲”并摸两张牌；没有“劲”，你本回合下一次受到的伤害值+1。",
  ["@mushun_jin"] = "劲",
  ["#jinjianm-invoke"] = "劲坚：你可以与 %dest 拼点，若赢，你回复1点体力",
  ["@shizhao-turn"] = "失诏",
}

local godzhangfei = General(extension, "godzhangfei", "god", 4)
local shencai = fk.CreateActiveSkill{
  name = "shencai",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1 + player:getMark("xunshi")
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
  end,
}
local shencai_record = fk.CreateTriggerSkill{
  name = "#shencai_record",
  mute = true,
  events = {fk.FinishJudge},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and data.reason == "shencai"
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    end
    local result = {}
    if table.contains({"peach", "analeptic", "silver_lion", "god_salvation", "celestial_calabash"}, data.card.trueName) then
      table.insert(result, "@shencai_chi")
    end
    if data.card.sub_type == Card.SubtypeWeapon or data.card.name == "collateral" then
      table.insert(result, "@shencai_zhang")
    end
    if table.contains({"savage_assault", "archery_attack", "duel", "spear", "eight_diagram", "raid_and_frontal_attack"}, data.card.trueName) then
      table.insert(result, "@shencai_tu")
    end
    if data.card.sub_type == Card.SubtypeDefensiveRide or data.card.sub_type == Card.SubtypeOffensiveRide or
    table.contains({"snatch", "supply_shortage", "chasing_near"}, data.card.trueName) then
      table.insert(result, "@shencai_liu")
    end
    if #result == 0 then
      table.insert(result, "@shencai_si")
    end
    if result[1] ~= "@shencai_si" then
      for _, mark in ipairs({"@shencai_chi", "@shencai_zhang", "@shencai_tu", "@shencai_liu"}) do
        room:setPlayerMark(data.who, mark, 0)
      end
    end
    for _, mark in ipairs(result) do
      room:addPlayerMark(data.who, mark, 1)
      if mark == "@shencai_si" and not data.who:isNude() then
        local card = room:askForCardChosen(player, target, "he", "shencai")
        room:obtainCard(player.id, card, false, fk.ReasonPrey)
      end
    end
  end,
}
local shencai_trigger = fk.CreateTriggerSkill{
  name = "#shencai_trigger",
  anim_type = "offensive",
  events = {fk.Damaged, fk.TargetConfirmed, fk.AfterCardsMove, fk.EventPhaseStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name, true) then
      if event == fk.Damaged then
        return target:getMark("@shencai_chi") > 0
      elseif event == fk.TargetConfirmed then
        return target:getMark("@shencai_zhang") > 0 and data.card.trueName == "slash"
      elseif event == fk.AfterCardsMove then
        self.shencai_target = nil
        for _, move in ipairs(data) do
          if move.skillName ~= "shencai" and move.from and player.room:getPlayerById(move.from):getMark("@shencai_tu") > 0 then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                self.shencai_target = move.from
                return true
              end
            end
          end
        end
      elseif event == fk.EventPhaseStart then
        return target:getMark("@shencai_liu") > 0 and target.phase == Player.Finish
      elseif event == fk.TurnEnd then
        return target:getMark("@shencai_si") > #player.room.alive_players
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      room:loseHp(target, data.damage, "shencai")
    elseif event == fk.TargetConfirmed then
      data.disresponsive = true
    elseif event == fk.AfterCardsMove then
      local to = room:getPlayerById(self.shencai_target)
      if not to:isKongcheng() then
        room:throwCard({table.random(to.player_cards[Player.Hand])}, "shencai", to, to)
      end
    elseif event == fk.EventPhaseStart then
      target:turnOver()
    elseif event == fk.TurnEnd then
      room:killPlayer({who = target.id})
    end
  end,
}
local shencai_maxcards = fk.CreateMaxCardsSkill {
  name = "#shencai_maxcards",
  correct_func = function(self, player)
    return -player:getMark("@shencai_si")
  end,
}
local xunshi = fk.CreateFilterSkill{
  name = "xunshi",
  card_filter = function(self, card, player)
    local names = {"savage_assault", "archery_attack", "amazing_grace", "god_salvation", "iron_chain", "redistribute"}
    return player:hasSkill(self.name) and table.contains(names, card.name) and
      not table.contains(player.player_cards[Player.Judge], card.id)
  end,
  view_as = function(self, card)
    local card = Fk:cloneCard("slash", Card.NoSuit, card.number)
    card.skillName = self.name
    return card
  end,
}
local xunshi_record = fk.CreateTriggerSkill{
  name = "#xunshi_record",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("xunshi") and data.card.color == Card.NoColor and data.targetGroup
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    self.cost_data = {}
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not table.contains(AimGroup:getAllTargets(data.tos), p.id) and not player:isProhibited(p, data.card) then
        table.insertIfNeed(targets, p.id)
      end
    end
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#xunshi-choose", "xunshi", true)
      if #tos > 0 then
        self.cost_data = tos
      end
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    if player:getMark("xunshi") < 4 then
      player.room:addPlayerMark(player, "xunshi", 1)
    end
    if self.cost_data then
      for _, id in ipairs(self.cost_data) do
        TargetGroup:pushTargets(data.targetGroup, id)
      end
    end
  end,
}
local xunshi_targetmod = fk.CreateTargetModSkill{
  name = "#xunshi_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill("xunshi") and card.color == Card.NoColor and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill, card)
    if player:hasSkill("xunshi") and card.color == Card.NoColor then
      return 999
    end
  end,
}
shencai:addRelatedSkill(shencai_record)
shencai:addRelatedSkill(shencai_trigger)
shencai:addRelatedSkill(shencai_maxcards)
xunshi:addRelatedSkill(xunshi_record)
xunshi:addRelatedSkill(xunshi_targetmod)
godzhangfei:addSkill(shencai)
godzhangfei:addSkill(xunshi)
Fk:loadTranslationTable{
  ["godzhangfei"] = "神张飞",
  ["shencai"] = "神裁",
  [":shencai"] = "出牌阶段限一次，你可以令一名其他角色进行判定，你获得判定牌。若判定牌包含以下内容，其获得（已有标记则改为修改）对应标记：<br>"..
  "体力：“笞”标记，每次受到伤害后失去等量体力；<br>"..
  "武器：“杖”标记，无法响应【杀】；<br>"..
  "打出：“徒”标记，以此法外失去手牌后随机弃置一张手牌；<br>"..
  "距离：“流”标记，结束阶段将武将牌翻面；<br>"..
  "若判定牌不包含以上内容，该角色获得一个“死”标记且手牌上限减少其身上“死”标记个数，然后你获得其区域内一张牌。"..
  "“死”标记个数大于场上存活人数的角色回合结束时，其直接死亡。",
  ["xunshi"] = "巡使",
  [":xunshi"] = "锁定技，你的多目标锦囊牌均视为无色【杀】。你使用无色牌无距离和次数限制且可以额外指定任意个目标，然后〖神裁〗的发动次数+1（至多为5）。",
  ["#shencai_trigger"] = "神裁",
  ["@shencai_chi"] = "笞",
  ["@shencai_zhang"] = "杖",
  ["@shencai_tu"] = "徒",
  ["@shencai_liu"] = "流",
  ["@shencai_si"] = "死",
  ["#xunshi_record"] = "巡使",
  ["#xunshi-choose"] = "巡使：无距离限制且可以额外指定任意个目标",

  ["$shencai1"] = "我有三千炼狱，待汝万世轮回！",
  ["$shencai2"] = "纵汝王侯将相，亦须俯首待裁！",
  ["$xunshi1"] = "秉身为正，辟易万邪！",
  ["$xunshi2"] = "巡御两界，路寻不平！",
  ["~godzhangfei"] = "尔等，欲复斩我头乎？",
}

Fk:loadTranslationTable{
  ["liyixiejing"] = "李异谢旌",
  ["douzhen"] = "斗阵",
  [":douzhen"] = "转换技，锁定技，你的回合内，阳：你的黑色基本牌视为【决斗】，且使用时获得目标一张牌；阴：你的红色基本牌视为【杀】，且使用时无次数限制。",
}

local yuanji = General(extension, "yuanji", "wu", 3, 3, General.Female)
local mengchi = fk.CreateTriggerSkill{
  name = "mengchi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.BeforeChainStateChange, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player:getMark("mengchi-turn") == 0 then
      if event == fk.BeforeChainStateChange then
        return not player.chained
      else
        return data.damageType == fk.NormalDamage and player:isWounded()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.BeforeChainStateChange then
      return true
    else
      player.room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and player:getMark("mengchi-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        player.room:addPlayerMark(player, "mengchi-turn", 1)
        return
      end
    end
  end,
}
local mengchi_prohibit = fk.CreateProhibitSkill{
  name = "#mengchi_prohibit",
  prohibit_use = function(self, player, card)
    if player:hasSkill("mengchi") and player:getMark("mengchi-turn") == 0 then
      return true
    end
  end,
}
local jiexing = fk.CreateTriggerSkill{
  name = "jiexing",
  anim_type = "drawcard",
  events = {fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
      --and player:usedSkillTimes("mengchi", Player.HistoryTurn) == 0（听说十周年为防止玩家手欠，不允许第一次掉血发动节行）
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiexing-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = player:drawCards(1, self.name)[1]
    local mark = player:getMark("jiexing-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, id)
    room:setPlayerMark(player, "jiexing-turn", mark)
  end,
}
local jiexing_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiexing_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("jiexing-turn") ~= 0 and table.contains(player:getMark("jiexing-turn"), card.id)
  end,
}
mengchi:addRelatedSkill(mengchi_prohibit)
jiexing:addRelatedSkill(jiexing_maxcards)
yuanji:addSkill(mengchi)
yuanji:addSkill(jiexing)
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["mengchi"] = "蒙斥",
  [":mengchi"] = "锁定技，若你于当前回合内没有获得过牌，你：1.不能使用牌；2.进入横置状态时，取消之；3.受到普通伤害后，回复1点体力。",
  ["jiexing"] = "节行",
  [":jiexing"] = "当你的体力值变化后，你可以摸一张牌（此牌不计入你本回合的手牌上限）。",
  ["#jiexing-invoke"] = "节行：你可以摸一张牌，此牌本回合不计入手牌上限",
}

local panghui = General(extension, "panghui", "wei", 5)
local yiyong = fk.CreateTriggerSkill{
  name = "yiyong",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) < 2 and
      data.to and data.to ~= player and not player:isNude() and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 999, true, self.name, true, ".", "#yiyong-invoke::"..data.to.id)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(data.to, 1, 999, true, self.name, false, ".", "#yiyong-discard:"..player.id)
    local n1 = 0
    local n2 = 0
    for _, id in ipairs(self.cost_data) do
      n1 = n1 + Fk:getCardById(id).number
    end
    for _, id in ipairs(cards) do
      n2 = n2 + Fk:getCardById(id).number
    end
    if n1 <= n2 then
      player:drawCards(#cards, self.name)
    end
    if n1 >= n2 then
      data.damage = data.damage + 1
    end
  end,
}
panghui:addSkill(yiyong)
Fk:loadTranslationTable{
  ["panghui"] = "庞会",
  ["yiyong"] = "异勇",
  [":yiyong"] = "每回合限两次，当你对其他角色造成伤害时，你可以弃置任意张牌，令该角色弃置任意张牌。若你弃置的牌的点数之和：不大于其，你摸X张牌（X为该角色弃置的牌数）；不小于其，此伤害+1。",
  ["#yiyong-invoke"] = "异勇：你可以弃置任意张牌，令 %dest 弃置任意张牌，根据双方弃牌点数之和执行效果",
  ["#yiyong-discard"] = "异勇：你需弃置任意张牌，若点数之和大则 %src 摸牌，若点数小则伤害+1",

  ["$yiyong1"] = "关氏鼠辈，庞令明之子来邪！",
  ["$yiyong2"] = "凭一腔勇力，父仇定可报还。",
  ["~panghui"] = "大仇虽报，奈何心有余创。",
}

local zhaozhi = General(extension, "zhaozhi", "shu", 3)
local tongguan = fk.CreateTriggerSkill{
  name = "tongguan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and data.from == Player.RoundStart and
      table.every({1, 2, 3, 4, 5}, function(i) return target:getMark("@@tongguan"..i) == 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local count = {0, 0, 0, 0, 0}
    for _, p in ipairs(room:getAlivePlayers()) do
      for i = 1, 5, 1 do
        if p:getMark("@@tongguan"..i) > 0 then
          count[i] = count[i] + 1
        end
      end
    end
    local choices = {}
    for i = 1, 5, 1 do
      if count[i] < 2 then
        table.insert(choices, "@@tongguan"..i)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#tongguan-choice::"..target.id, true)
    room:setPlayerMark(target, choice, 1)
  end,
}
local mengjiez = fk.CreateTriggerSkill{
  name = "mengjiez",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and (target:getMark(self.name) > 0 or
      (target:getMark("@@tongguan2") > 0 and target:getHandcardNum() > target.hp))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if target:getMark("@@tongguan3") > 0 then
      return room:askForSkillInvoke(player, self.name, nil, "#mengjiez3-invoke")
    else
      local targets, prompt
      if target:getMark("@@tongguan1") > 0 then
        targets = table.map(room:getOtherPlayers(player), function(p)
          return p.id end)
        prompt = "#mengjiez1-invoke"
      elseif target:getMark("@@tongguan2") > 0 then
        targets = table.map(table.filter(room:getAlivePlayers(), function(p)
          return p:isWounded() end), function(p) return p.id end)
        prompt = "#mengjiez2-invoke"
      elseif target:getMark("@@tongguan4") > 0 then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not p:isAllNude() end), function(p) return p.id end)
        prompt = "#mengjiez4-invoke"
      elseif target:getMark("@@tongguan5") > 0 then
        targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return p:getHandcardNum() < p.maxHp end), function(p) return p.id end)
        prompt = "#mengjiez5-invoke"
      end
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if target:getMark("@@tongguan3") > 0 then
      player:drawCards(2, self.name)
    else
      local room = player.room
      local to = room:getPlayerById(self.cost_data)
      if target:getMark("@@tongguan1") > 0 then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = self.name,
        }
      elseif target:getMark("@@tongguan2") > 0 then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      elseif target:getMark("@@tongguan4") > 0 then
        local cards = room:askForCardsChosen(player, to, 1, 2, "hej", self.name)
        room:throwCard(cards, self.name, to, player)
      elseif target:getMark("@@tongguan5") > 0 then
        to:drawCards(math.min(5, to.maxHp - #to.player_cards[Player.Hand]), self.name)
      end
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Damage, fk.HpRecover, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      return target == player and data.from == Player.RoundStart
    elseif player.phase ~= Player.NotActive then
      if event == fk.Damage then
        return target == player and player:getMark("@@tongguan1") > 0
      elseif event == fk.HpRecover then
        return target == player and player:getMark("@@tongguan2") > 0
      else
        for _, move in ipairs(data) do
          if player:getMark("@@tongguan3") > 0 and
            move.to == player.id and move.moveReason == fk.ReasonDraw and player.phase ~= Player.Draw then
            return true
          end
          if player:getMark("@@tongguan4") > 0 and
            move.from ~= player.id and (move.proposer == player or move.proposer == player.id) and
            (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey) then
            return true
          end
          if player:getMark("@@tongguan5") > 0 and
            move.from == player.id and move.moveReason == fk.ReasonGive then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      player.room:setPlayerMark(player, self.name, 0)
    else
      player.room:addPlayerMark(player, self.name, 1)
    end
  end,
}
zhaozhi:addSkill(tongguan)
zhaozhi:addSkill(mengjiez)
Fk:loadTranslationTable{
  ["zhaozhi"] = "赵直",
  ["tongguan"] = "统观",
  [":tongguan"] = "一名角色的第一个回合开始时，你为其选择一项属性（每种属性至多被选择两次）。",
  ["mengjiez"] = "梦解",
  [":mengjiez"] = "一名角色的回合结束时，若其本回合完成了其属性对应内容，你执行对应效果。<br>"..
  "武勇：造成伤害；对一名其他角色造成1点伤害<br>"..
  "刚硬：回复体力或手牌数大于体力值；令一名角色回复1点体力<br>"..
  "多谋：摸牌阶段外摸牌；摸两张牌<br>"..
  "果决：弃置或获得其他角色的牌；弃置一名其他角色区域内的至多两张牌<br>"..
  "仁智：交给其他角色牌；令一名其他角色将手牌摸至体力上限（至多摸五张）",
  ["#tongguan-choice"] = "统观：为 %dest 选择一项属性（每种属性至多被选择两次）",
  ["@@tongguan1"] = "武勇",
  [":@@tongguan1"] = "回合结束时，若其本回合造成过伤害，你对一名其他角色造成1点伤害",
  ["@@tongguan2"] = "刚硬",
  [":@@tongguan2"] = "回合结束时，若其手牌数大于体力值，或其本回合回复过体力，你令一名角色回复1点体力",
  ["@@tongguan3"] = "多谋",
  [":@@tongguan3"] = "回合结束时，若其本回合摸牌阶段外摸过牌，你摸两张牌",
  ["@@tongguan4"] = "果决",
  [":@@tongguan4"] = "回合结束时，若其本回合弃置或获得过其他角色的牌，你弃置一名其他角色区域内的至多两张牌",
  ["@@tongguan5"] = "仁智",
  [":@@tongguan5"] = "回合结束时，若其本回合交给其他角色牌，你令一名其他角色将手牌摸至体力上限（至多摸五张）",
  ["#mengjiez1-invoke"] = "梦解：你可以对一名其他角色造成1点伤害",
  ["#mengjiez2-invoke"] = "梦解：你可以令一名角色回复1点体力",
  ["#mengjiez3-invoke"] = "梦解：你可以摸两张牌",
  ["#mengjiez4-invoke"] = "梦解：你可以弃置一名其他角色区域内至多两张牌",
  ["#mengjiez5-invoke"] = "梦解：你可以令一名其他角色将手牌摸至体力上限（至多摸五张）",

  ["$tongguan1"] = "极目宇宙，可观如织之命数。",
  ["$tongguan2"] = "命河长往，唯我立于川上。",
  ["$mengjiez1"] = "唇舌之语，难言虚实之境。",
  ["$mengjiez2"] = "解梦之术，如镜中观花尔。",
  ["~zhaozhi"] = "解人之梦者，犹在己梦中。",
}

local chenjiao = General(extension, "chenjiao", "wei", 3)
local xieshou = fk.CreateTriggerSkill{
  name = "xieshou",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not target.dead and player:distanceTo(target) <= 2 and player:getMaxCards() > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xieshou-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
    local choices = {"xieshou_draw"}
    if target:isWounded() then
      table.insert(choices, 1, "recover")
    end
    local choice = room:askForChoice(target, choices, self.name, "#xieshou-choice:"..player.id)
    if choice == "recover" then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      if not target.faceup then
        target:turnOver()
      end
      if target.chained then
        target:setChainState(false)
      end
      target:drawCards(2, self.name)
    end
  end,
}
local qingyan = fk.CreateTriggerSkill{
  name = "qingyan",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.firstTarget and data.card.color == Card.Black and data.from ~= player.id and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    if player:getHandcardNum() < math.min(player.hp, player.maxHp) then
      return player.room:askForSkillInvoke(player, self.name, nil, "#qingyan-invoke")
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#qingyan-card", true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data then
      room:throwCard(self.cost_data, self.name, player, player)
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    end
  end,
}
local qizi = fk.CreateTriggerSkill{
  name = "qizi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:distanceTo(target) > 2
  end,
  on_use = function(self, event, target, player, data)
    player.room:broadcastSkillInvoke(self.name)
    player.room:notifySkillInvoked(player, self.name)
  end,
}
local qizi_prohibit = fk.CreateProhibitSkill{
  name = "#qizi_prohibit",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    if player:hasSkill("qizi") and card.name == "peach" then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and player:distanceTo(p) > 2 end)
    end
  end,
}
qizi:addRelatedSkill(qizi_prohibit)
chenjiao:addSkill(xieshou)
chenjiao:addSkill(qingyan)
chenjiao:addSkill(qizi)
Fk:loadTranslationTable{
  ["chenjiao"] = "陈矫",
  ["xieshou"] = "协守",
  [":xieshou"] = "每回合限一次，一名角色受到伤害后，若你与其距离不大于2，你可以令你的手牌上限-1，然后其选择一项：1.回复1点体力；2.复原武将牌并摸两张牌。",
  ["qingyan"] = "清严",
  [":qingyan"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后，若你的手牌数：小于体力值，你可将手牌摸至体力上限；"..
  "不小于体力值，你可以弃置一张手牌令手牌上限+1。",
  ["qizi"] = "弃子",
  [":qizi"] = "锁定技，其他角色处于濒死状态时，若你与其距离大于2，你不能对其使用【桃】。",
  ["#xieshou-invoke"] = "协守：你可以手牌上限-1，令 %dest 选择回复体力，或复原武将牌并摸牌",
  ["xieshou_draw"] = "复原武将牌并摸两张牌",
  ["#xieshou-choice"] = "协守：选择 %src 令你执行的一项",
  ["#qingyan-invoke"] = "清严：你可以将手牌摸至体力上限",
  ["#qingyan-card"] = "清严：你可以弃置一张手牌令手牌上限+1",
}

local zhujianping = General(extension, "zhujianping", "qun", 3)
local xiangmian = fk.CreateActiveSkill{
  name = "xiangmian",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("xiangmian_suit") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    room:setPlayerMark(target, "@xiangmian", string.format("%s%d",
    Fk:translate(judge.card:getSuitString()),
    judge.card.number))
    room:setPlayerMark(target, "xiangmian_suit", judge.card:getSuitString())
    room:setPlayerMark(target, "xiangmian_num", judge.card.number)
  end,
}
local xiangmian_record = fk.CreateTriggerSkill{
  name = "#xiangmian_record",
  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and target:getMark("xiangmian_num") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card:getSuitString() == target:getMark("xiangmian_suit") or target:getMark("xiangmian_num") == 1 then
      room:setPlayerMark(target, "xiangmian_num", 0)
      room:setPlayerMark(target, "@xiangmian", 0)
      room:loseHp(target, target.hp, "xiangmian")
    else
      room:addPlayerMark(target, "xiangmian_num", -1)
      room:setPlayerMark(target, "@xiangmian", string.format("%s%d",Fk:translate(target:getMark("xiangmian_suit")), target:getMark("xiangmian_num")))
    end
  end,
}
local tianji = fk.CreateTriggerSkill{
  name = "tianji",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonJudge then
          self.cost_data = move
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local move = self.cost_data
    for _, info in ipairs(move.moveInfo) do
      local card = Fk:getCardById(info.cardId, true)
      local cards = {}
      local bigNumber = #room.draw_pile
      local rule = { ".|.|.|.|.|"..card:getTypeString(), ".|.|"..card:getSuitString(), ".|"..card.number }
      for _, r in ipairs(rule) do
        local targetCards = table.filter(room:getCardsFromPileByRule(r, bigNumber), function(cid) return not table.contains(cards, cid) end)
        if #targetCards > 0 then
          local loc = math.random(1, #targetCards)
          table.insert(cards, targetCards[loc])
        end
      end
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
xiangmian:addRelatedSkill(xiangmian_record)
zhujianping:addSkill(xiangmian)
zhujianping:addSkill(tianji)
Fk:loadTranslationTable{
  ["zhujianping"] = "朱建平",
  ["xiangmian"] = "相面",
  [":xiangmian"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定，当该角色使用判定花色的牌或使用第X张牌后（X为判定点数），其失去所有体力。"..
  "每名其他角色限一次。",
  ["tianji"] = "天机",
  [":tianji"] = "锁定技，生效后的判定牌进入弃牌堆后，你从牌堆随机获得与该牌类型、花色和点数相同的牌各一张。",
  ["@xiangmian"] = "相面",

  ["$xiangmian1"] = "以吾之见，阁下命不久矣。",
  ["$xiangmian2"] = "印堂发黑，将军危在旦夕。",
  ["$tianji1"] = "顺天而行，坐收其利。",
  ["$tianji2"] = "只可意会，不可言传。",
  ["~zhujianping"] = "天机，不可泄露啊……",
}

local gongsundu = General(extension, "gongsundu", "qun", 4)
local zhenze = fk.CreateTriggerSkill{
  name = "zhenze",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"zhenze_lose", "zhenze_recover"}, self.name)
    if choice == "zhenze_lose" then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if ((p:getHandcardNum() > p.hp) ~= (player:getHandcardNum() > player.hp) or
          (p:getHandcardNum() == p.hp) ~= (player:getHandcardNum() == player.hp) or
          (p:getHandcardNum() < p.hp) ~= (player:getHandcardNum() < player.hp)) then
            room:loseHp(p, 1, self.name)
        end
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isWounded() and
          ((p:getHandcardNum() > p.hp) and (player:getHandcardNum() > player.hp) or
          (p:getHandcardNum() == p.hp) and (player:getHandcardNum() == player.hp) or
          (p:getHandcardNum() < p.hp) and (player:getHandcardNum() < player.hp)) then
            room:recover({
              who = p,
              num = 1,
              recoverBy = player,
              skillName = self.name
            })
        end
      end
    end
  end,
}
local anliao = fk.CreateActiveSkill{
  name = "anliao",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p.kingdom == "qun" then
        n = n + 1
      end
    end
    return player:usedSkillTimes(self.name) < n
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "he", self.name)
    room:recastCard({id}, target, self.name)
  end,
}
gongsundu:addSkill(zhenze)
gongsundu:addSkill(anliao)
Fk:loadTranslationTable{
  ["gongsundu"] = "公孙度",
  ["zhenze"] = "震泽",
  [":zhenze"] = "弃牌阶段开始时，你可以选择一项：1.令所有手牌数和体力值的大小关系与你不同的角色失去1点体力；"..
  "2.令所有手牌数和体力值的大小关系与你相同的角色回复1点体力。",
  ["anliao"] = "安辽",
  [":anliao"] = "出牌阶段限X次（X为群势力角色数），你可以重铸一名角色的一张牌。",
  ["zhenze_lose"] = "手牌数和体力值的大小关系与你不同的角色失去1点体力",
  ["zhenze_recover"] = "所有手牌数和体力值的大小关系与你相同的角色回复1点体力",

  ["$zhenze1"] = "名震千里，泽被海东。",
  ["$zhenze2"] = "施威除暴，上下咸服。",
  ["$anliao1"] = "地阔天高，大有可为。",
  ["$anliao2"] = "水草丰沛，当展宏图。",
  ["~gongsundu"] = "为何都不愿出仕！",
}

--董贵人 是仪2023.1.18
return extension
