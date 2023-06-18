local extension = Package("tenyear_sp3")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp3"] = "十周年专属3",
}

local dufuren = General(extension, "dufuren", "wei", 3, 3, General.Female)
local yise = fk.CreateTriggerSkill{
  name = "yise",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          self.yise_to = move.to
          for _, info in ipairs(move.moveInfo) do
            self.yise_color = Fk:getCardById(info.cardId).color
            if self.yise_color == Card.Red then
              return player.room:getPlayerById(move.to):isWounded()
            else
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if self.yise_color == Card.Red then
      return player.room:askForSkillInvoke(player, self.name, data, "#yise-invoke::"..self.yise_to)
    elseif self.yise_color == Card.Black then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.yise_to)
    if self.yise_color == Card.Red then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    elseif self.yise_color == Card.Black then
      room:addPlayerMark(to, "yise_damage", 1)
    end
  end,
}
local yise_record = fk.CreateTriggerSkill{
  name = "#yise_record",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("yise_damage") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("yise_damage")
    player.room:setPlayerMark(player, "yise_damage", 0)
  end,
}
local shunshi = fk.CreateTriggerSkill{
  name = "shunshi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and not player:isNude() then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if event == fk.EventPhaseStart or (event == fk.Damaged and p ~= data.from) then
        table.insert(targets, p.id)
      end
    end
    local tos, id = room:askForChooseCardAndPlayers(player, targets, 1, 1, ".", "#shunshi-cost", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(self.cost_data[1], self.cost_data[2], false, fk.ReasonGive)
    room:addPlayerMark(player, self.name, 1)
  end,

  refresh_events = {fk.DrawNCards, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if player:getMark(self.name) > 0 then
      if event == fk.DrawNCards then
        return true
      else
        return data.to == Player.NotActive
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + player:getMark("shunshi")
    else
      player.room:setPlayerMark(player, self.name, 0)
    end
  end,
}
local shunshi_targetmod = fk.CreateTargetModSkill{
  name = "#shunshi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("shunshi") and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("shunshi")
    end
  end,
}
local shunshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#shunshi_maxcards",
  correct_func = function(self, player)
    return player:getMark("shunshi")
  end,
}
yise:addRelatedSkill(yise_record)
shunshi:addRelatedSkill(shunshi_targetmod)
shunshi:addRelatedSkill(shunshi_maxcards)
dufuren:addSkill(yise)
dufuren:addSkill(shunshi)
Fk:loadTranslationTable{
  ["dufuren"] = "杜夫人",
  ["yise"] = "异色",
  [":yise"] = "当其他角色获得你的牌后，若此牌为：红色，你可以令其回复1点体力；黑色，其下次受到【杀】造成的伤害时，此伤害+1。",
  ["shunshi"] = "顺世",
  [":shunshi"] = "准备阶段或当你于回合外受到伤害后，你可以交给一名其他角色一张牌（伤害来源除外），然后直到你的回合结束，你：摸牌阶段多摸一张牌、出牌阶段使用的【杀】次数上限+1、手牌上限+1。",
  ["#yise-invoke"] = "异色：你可以令 %dest 回复1点体力",
  ["#shunshi-cost"] = "顺世：你可以交给一名其他角色一张牌，然后直到你的回合结束获得效果",

  ["$yise1"] = "明丽端庄，双瞳剪水。",
  ["$yise2"] = "姿色天然，貌若桃李。",
  ["$shunshi1"] = "顺应时运，得保安康。",
  ["$shunshi2"] = "随遇而安，宠辱不惊。",
  ["~dufuren"] = "往事云烟，去日苦多。",
}
--荀谌 张宁 万年公主 童渊 刘永2021.12.1
local xunchen = General(extension, "ty__xunchen", "qun", 3)
local ty__fenglve = fk.CreateActiveSkill{
  name = "ty__fenglve",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      local dummy = Fk:cloneCard("dilu")
      if #target:getCardIds{Player.Hand, Player.Equip, Player.Judge} < 3 then
        dummy:addSubcards(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      else
        local cards = room:askForCardsChosen(target, target, 2, 2, "hej", self.name)
        dummy:addSubcards(cards)
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, false, fk.ReasonGive)
      end
    elseif pindian.results[target.id].winner == target then
      if room:getCardArea(pindian.fromCard.id) == Card.DiscardPile then
        room:delay(1000)
        room:obtainCard(target, pindian.fromCard.id, true, fk.ReasonJustMove)
      end
    else
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
local anyong = fk.CreateTriggerSkill{
  name = "anyong",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.from and data.from.phase ~= Player.NotActive and data.to ~= data.from then
      if data.from:getMark("anyong-turn") == 0 then
        player.room:addPlayerMark(data.from, "anyong-turn", 1)
        return data.damage == 1 and not data.to.dead and not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#anyong-invoke::"..data.to.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    room:doIndicate(player.id, {data.to.id})
    room:damage{
      from = player,
      to = data.to,
      damage = 1,
      skillName = self.name,
    }
  end,
}
xunchen:addSkill(ty__fenglve)
xunchen:addSkill(anyong)
Fk:loadTranslationTable{
  ["ty__xunchen"] = "荀谌",
  ["ty__fenglve"] = "锋略",
  [":ty__fenglve"] = "出牌阶段限一次，你可以和一名其他角色拼点。若你赢，该角色交给你其区域内的两张牌；若点数相同，此技能视为未发动过；若你输，该角色获得你拼点的牌。",
  ["anyong"] = "暗涌",
  [":anyong"] = "当一名角色于其回合内第一次对另一名角色造成伤害后，若此伤害值为1，你可以弃置一张牌对受到伤害的角色造成1点伤害。",
  ["#anyong-invoke"] = "暗涌：你可以弃置一张牌，对 %dest 造成1点伤害",
}

local zhangning = General(extension, "ty__zhangning", "qun", 3, 3, General.Female)
local tianze = fk.CreateTriggerSkill{
  name = "tianze",
  events = {fk.CardUseFinished},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and data.card.color == Card.Black and
      player:usedSkillTimes(self.name) == 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|spade,club|hand,equip", "#tianze-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:throwCard(self.cost_data, self.name, player, player)
    room:damage{ from = player, to = target, damage = 1, skillName = self.name}
  end,
}
local tianze_draw = fk.CreateTriggerSkill{
  name = "#tianze_draw",
  events = {fk.FinishJudge},
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(tianze.name) and data.card.color == Card.Black
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player.room:broadcastSkillInvoke(tianze.name)
    player.room:notifySkillInvoked(player, tianze.name, self.anim_type)
    room:drawCards(player, 1, self.name)
  end,
}
local difa = fk.CreateTriggerSkill{
  name = "difa",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and player.phase ~= Player.NotActive then
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand and table.find(move.moveInfo, function (info)
          return info.fromArea == Card.DrawPile and player.room:getCardOwner(info.cardId) == player and
            player.room:getCardArea(info.cardId) == Player.Hand and Fk:getCardById(info.cardId).color == Card.Red end) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile and player.room:getCardOwner(info.cardId) == player and
          player.room:getCardArea(info.cardId) == Player.Hand and Fk:getCardById(info.cardId).color == Card.Red then
            table.insert(ids, info.cardId)
          end
        end
      end
    end
    if #ids == 0 then return false end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, tostring(Exppattern{ id = ids }), "#difa-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeTrick and not card.is_derived then
        table.insertIfNeed(names, card.name)
      end
    end
    if #names == 0 then return end
    local name = room:askForChoice(player, names, self.name)
    local cards = room:getCardsFromPileByRule(name, 1, "discardPile")
    if #cards == 0 then
      cards = room:getCardsFromPileByRule(name, 1)
    end
    if #cards > 0 then
      room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
  end,
}
tianze:addRelatedSkill(tianze_draw)
zhangning:addSkill(tianze)
zhangning:addSkill(difa)
Fk:loadTranslationTable{
  ["ty__zhangning"] = "张宁",
  ["tianze"] = "天则",
  [":tianze"] = "其他角色的出牌阶段限一次，其使用黑色牌结算后，你可以弃置一张黑色牌对其造成1点伤害；其他角色的黑色判定牌生效后，你摸一张牌。",
  ["difa"] = "地法",
  [":difa"] = "你的回合内限一次，当你从牌堆摸到红色牌后，你可以弃置此牌，然后选择一种锦囊牌的牌名，从牌堆或弃牌堆获得一张。",

  ["#tianze-invoke"] = "天则：你可弃置一张黑色牌来对%dest造成1点伤害",
  ["#difa-invoke"] = "地法：你可弃置一张摸到的红色牌，然后检索一张锦囊牌",
  ["$tianze1"] = "观天则，以断人事。",
  ["$tianze2"] = "乾元用九，乃见天则。",
  ["$difa1"] = "地蕴天成，微妙玄通。",
  ["$difa2"] = "观地之法，吉在其中。",
  ["~ty__zhangning"] = "全气之地，当葬其止……",
}

local wanniangongzhu = General(extension, "wanniangongzhu", "qun", 3, 3, General.Female)
local zhenge = fk.CreateTriggerSkill{
  name = "zhenge",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local p = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#zhenge-choose", self.name)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:getMark("@zhenge") < 5 then
      room:addPlayerMark(to, "@zhenge", 1)
    end
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(to)) do
      if to:inMyAttackRange(p) and not to:isProhibited(p, Fk:cloneCard("slash")) then
        if p ~= player then
          table.insert(targets, p.id)
        end
      else
        return
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#zhenge-slash::"..to.id, self.name, true)
    if #tos > 0 then
      room:useVirtualCard("slash", nil, to, room:getPlayerById(tos[1]), self.name, true)
    end
  end,
}
local zhenge_attackrange = fk.CreateAttackRangeSkill{
  name = "#zhenge_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@zhenge")
  end,
}
local xinghan = fk.CreateTriggerSkill{
  name = "xinghan",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getMark("@zhenge") > 0 and
      data.card and data.card.trueName == "slash" and data.card.extra_data and table.contains(data.card.extra_data, "xinghan")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not table.every(room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Hand] < #player.player_cards[Player.Hand] end) then
        player:drawCards(math.min(target:getAttackRange(), 5), self.name)
    else
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return player.phase ~= Player.NotActive and data.card.trueName == "slash" and player:getMark("xinghan-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xinghan-turn", 1)
    if target:getMark("@zhenge") > 0 then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "xinghan")
    end
  end,
}
zhenge:addRelatedSkill(zhenge_attackrange)
wanniangongzhu:addSkill(zhenge)
wanniangongzhu:addSkill(xinghan)
Fk:loadTranslationTable{
  ["wanniangongzhu"] = "万年公主",
  ["zhenge"] = "枕戈",
  [":zhenge"] = "准备阶段，你可以令一名角色的攻击范围+1（加值至多为5），然后若其他角色都在其的攻击范围内，你可以令其视为对另一名你选择的角色使用一张【杀】。",
  ["xinghan"] = "兴汉",
  [":xinghan"] = "锁定技，当〖枕戈〗选择过的角色使用【杀】造成伤害后，若此【杀】是本回合的第一张【杀】，你摸一张牌。若你的手牌数不是全场唯一最多的，则改为摸X张牌（X为该角色的攻击范围且最多为5）。",
  ["@zhenge"] = "枕戈",
  ["#zhenge-choose"] = "枕戈：你可以令一名角色的攻击范围+1（至多+5）",
  ["#zhenge-slash"] = "枕戈：你可以选择另一名角色，视为 %dest 对此角色使用【杀】",

  ["$zhenge1"] = "常备不懈，严阵以待。",
  ["$zhenge2"] = "枕戈待旦，日夜警惕。",
  ["$xinghan1"] = "汉之兴旺，不敢松懈。",
  ["$xinghan2"] = "兴汉除贼，吾之所愿。",
  ["~wanniangongzhu"] = "兴汉的使命，还没有完成。",
}

Fk:loadTranslationTable{
  ["ty__tongyuan"] = "童渊",
  ["chaofeng"] = "朝凤",
  [":chaofeng"] = "出牌阶段限一次，当你使用牌造成伤害时，你可以弃置一张手牌，然后摸一张牌。若弃置的牌与造成伤害的牌：颜色相同，则多摸一张牌；"..
  "类型相同，则此伤害+1。",
  ["chuanshu"] = "传术",
  [":chuanshu"] = "限定技，准备阶段若你已受伤，或当你死亡时，你可令一名其他角色获得〖朝凤〗，然后你获得〖龙胆〗、〖从谏〗、〖穿云〗。",
  ["chuanyun"] = "穿云",
  [":chuanyun"] = "当你使用【杀】指定目标后，你可令该角色随机弃置一张装备区里的牌。",
}

Fk:loadTranslationTable{
  ["liuyong"] = "刘永",
  ["zhuning"] = "诛佞",
  [":zhuning"] = "出牌阶段限一次，你可以交给一名其他角色任意张牌，这些牌标记为“隙”，然后你可以视为使用一张不计次数的【杀】或伤害类锦囊牌，"..
  "然后若此牌没有造成伤害，此技能本阶段改为“出牌阶段限两次”。",
  ["fengxiang"] = "封乡",
  [":fengxiang"] = "锁定技，当你受到伤害后，手牌中“隙”唯一最多的角色回复1点体力（没有唯一最多的角色则改为你摸一张牌）；"..
  "当有角色因手牌数改变而使“隙”唯一最多的角色改变时，你摸一张牌。",
}

--嵇康 曹不兴2021.12.3

Fk:loadTranslationTable{
  ["ty__chendeng"] = "陈登",
  ["wangzu"] = "望族",
  [":wangzu"] = "每回合限一次，当你受到其他角色造成的伤害时，你可以随机弃置一张手牌令此伤害-1，若你所在的阵营存活人数全场最多，则改为选择一张手牌弃置。",
  ["yingshui"] = "营说",
  [":yingshui"] = "出牌阶段限一次，你可以交给你攻击范围内的一名其他角色一张牌，然后令其选择一项：1.受到你对其造成的1点伤害；2.交给你至少两张装备牌。",
  ["fuyuan"] = "扶援",
  [":fuyuan"] = "当一名角色成为【杀】的目标后，若其本回合没有成为过红色牌的目标，你可令其摸一张牌。",
}

--local caojinyu = General(extension, "caojinyu", "wei", 3, 3, General.Female)
local yuqi = fk.CreateTriggerSkill{
  name = "yuqi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player.dead and not target.dead and
    (target == player or player:distanceTo(target) <= player:getMark("yuqi1")) and player:getMark("yuqi-turn") < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "yuqi-turn", 1)
    --local card_ids = room:getNCards(player:getMark("yuqi2"))

    --FIXME: askForCardsChosen? or yiji?
    local n1, n2 = 0, 0
    if player:getMark("yuqi2") >= player:getMark("yuqi4") then
      n2 = player:getMark("yuqi4")
      n1 = math.min(player:getMark("yuqi3"), player:getMark("yuqi2") - player:getMark("yuqi4"))
    else
      n2 = player:getMark("yuqi2")
    end
    target:drawCards(n1)
    player:drawCards(n2)
  end,

  refresh_events = {fk.GameStart},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yuqi2", 3)
    room:setPlayerMark(player, "yuqi3", 1)
    room:setPlayerMark(player, "yuqi4", 1)
    room:setPlayerMark(player, "@" .. self.name, string.format("%d-%d-%d-%d", 0, 3, 1, 1))
  end,
}
local function AddYuqi(player, skillName, num)
  local room = player.room
  local choices = {}
  for i = 1, 4, 1 do
    if player:getMark("yuqi" .. tostring(i)) < 5 then
      table.insert(choices, "yuqi" .. tostring(i))
    end
  end
  if #choices > 0 then
    local choice = room:askForChoice(player, choices, skillName)
    local x = player:getMark(choice)
    if x + num < 6 then
      x = x + num
    else
      x = 5
    end
    room:setPlayerMark(player, choice, x)
    room:setPlayerMark(player, "@yuqi", string.format("%d-%d-%d-%d",
    player:getMark("yuqi1"),
    player:getMark("yuqi2"),
    player:getMark("yuqi3"),
    player:getMark("yuqi4")))
  end
end
local shanshen = fk.CreateTriggerSkill{
  name = "shanshen",
  anim_type = "control",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and not player.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    AddYuqi(player, self.name, 2)
    if target:getMark(self.name) == 0 and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name,
      }
    end
  end,
  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name) and data.to:getMark(self.name) == 0
  end,
  on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(data.to, self.name, 1)
  end,
}
local xianjing = fk.CreateTriggerSkill{
  name = "xianjing",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Start then
      for i = 1, 4, 1 do
        if player:getMark("yuqi" .. tostring(i)) < 5 then
          return true
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    AddYuqi(player, self.name, 1)
    if not player:isWounded() then
      AddYuqi(player, self.name, 1)
    end
  end,
}
--caojinyu:addSkill(yuqi)
--caojinyu:addSkill(shanshen)
--caojinyu:addSkill(xianjing)
Fk:loadTranslationTable{
  ["caojinyu"] = "曹金玉",
  ["yuqi"] = "隅泣",
  [":yuqi"] = "每回合限两次，当一名角色受到伤害后，若你与其距离0或者更少，你可以观看牌堆顶的3张牌，将其中至多1张交给受伤角色，"..
  "至多1张自己获得，剩余的牌放回牌堆顶。",
  ["shanshen"] = "善身",
  [":shanshen"] = "当有角色死亡时，你可令〖隅泣〗中的一个数字+2（单项不能超过5）。然后若你没有对死亡角色造成过伤害，你回复1点体力。",
  ["xianjing"] = "娴静",
  [":xianjing"] = "准备阶段，你可令〖隅泣〗中的一个数字+1（单项不能超过5）。若你满体力值，则再令〖隅泣〗中的一个数字+1。",
  ["@yuqi"] = "隅泣",
  ["yuqi1"] = "距离",
  ["yuqi2"] = "观看牌数",
  ["yuqi3"] = "交给受伤角色牌数",
  ["yuqi4"] = "自己获得牌数",

  ["$yuqi1"] = "孤影独泣，困于隅角。",
  ["$yuqi2"] = "向隅而泣，黯然伤感。",
  ["$shanshen1"] = "好善为德，坚守本心。",
  ["$shanshen2"] = "洁身自爱，独善其身。",
  ["$xianjing1"] = "文静娴丽，举止柔美。",
  ["$xianjing2"] = "娴静淡雅，温婉穆穆。",
  ["~caojinyu"] = "平叔之情，吾岂不明。",
}

local tenggongzhu = General(extension, "tenggongzhu", "wu", 3, 3, General.Female)
local xingchong = fk.CreateTriggerSkill{
  name = "xingchong",
  anim_type = "drawcard",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xingchong-invoke:::"..tostring(player.maxHp))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp
    local choices = {}
    local i1 = 0
    if player:isKongcheng() then
      i1 = 1
    end
    for i = i1, n, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askForChoice(player, choices, self.name, "#xingchong-draw")
    player:drawCards(tonumber(choice), self.name)
    if player:isKongcheng() then return end
    n = n - tonumber(choice)
    local cards = room:askForCard(player, 1, n, false, self.name, true, ".", "#xingchong-card:::"..tostring(n))
    if #cards > 0 then
      player:showCards(cards)
      room:sendCardVirtName(cards, self.name)
      room:setPlayerMark(player, "xingchong-round", cards)
    end
  end,
}
local xingchong_trigger = fk.CreateTriggerSkill{
  name = "#xingchong_trigger",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("xingchong-round") ~= 0 and #player:getMark("xingchong-round") > 0 then
      for _, move in ipairs(data) do
        if move.from == player.id then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local mark = player:getMark("xingchong-round")
            if table.contains(mark, info.cardId) then
              n = n + 1
              table.removeOne(mark, info.cardId)
              room:setPlayerMark(player, "xingchong-round", mark)
            end
          end
        end
      end
    end
    if n > 0 then
      player:drawCards(2 * n, "xingchong")
    end
  end,
}
local liunian = fk.CreateTriggerSkill{
  name = "liunian",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:getMark("liunian-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) == 1 then
      room:changeMaxHp(player, 1)
    else
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 10)
    end
  end,

  refresh_events = {fk.AfterDrawPileShuffle},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) < 2
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, self.name, 1)
    player.room:setPlayerMark(player, "liunian-turn", 1)
  end,
}
xingchong:addRelatedSkill(xingchong_trigger)
tenggongzhu:addSkill(xingchong)
tenggongzhu:addSkill(liunian)
Fk:loadTranslationTable{
  ["tenggongzhu"] = "滕公主",
  ["xingchong"] = "幸宠",
  [":xingchong"] = "每轮游戏开始时，你可以摸任意张牌并展示任意张牌（摸牌和展示牌的总数不能超过你的体力上限）。"..
  "若如此做，本轮内当你失去一张以此法展示的手牌后，你摸两张牌。",
  ["liunian"] = "流年",
  [":liunian"] = "锁定技，牌堆第一次洗牌的回合结束时，你加1点体力上限。牌堆第二次洗牌的回合结束时，你回复1点体力，然后本局游戏手牌上限+10。",
  ["#xingchong-invoke"] = "幸宠：你可以摸牌、展示牌合计至多%arg张，本轮失去展示的牌后摸两张牌",
  ["#xingchong-draw"] = "幸宠：选择摸牌数",
  ["#xingchong-card"] = "幸宠：展示至多%arg张牌，本轮失去一张展示牌后摸两张牌",
  
  ["$xingchong1"] = "佳人有荣幸，好女天自怜。",
  ["$xingchong2"] = "世间万般宠爱，独聚我于一身。",
  ["$liunian1"] = "佳期若梦，似水流年。",
  ["$liunian2"] = "逝者如流水，昼夜不将息。",
  ["~tenggongzhu"] = "已过江北，再无江南……",
}
--王桃 王悦 庞德公2022.2.28
Fk:loadTranslationTable{
  ["wufan"] = "吴范",
  ["tianyun"] = "天运",
  [":tianyun"] = "获得起始手牌后，你再从牌堆中随机获得手牌中没有的花色各一张牌。<br>"..
  "一名角色的回合开始时，若其座次等于游戏轮数，你可以观看牌堆顶的X张牌，然后以任意顺序置于牌堆顶或牌堆底，若你将所有牌均置于牌堆底，"..
  "则你可以令一名角色摸X张牌（X为你手牌中的花色数），若如此做，你失去1点体力。",
  ["yuyan"] = "预言",
  [":yuyan"] = "每轮游戏开始时，你选择一名角色，若其是本轮第一个进入濒死状态的角色，则你获得技能〖奋音〗直到你的回合结束。"..
  "若其是本轮第一个造成伤害的角色，则你摸两张牌。",
}

local licaiwei = General(extension, "licaiwei", "qun", 3, 3, General.Female)
local yijiao = fk.CreateActiveSkill{
  name = "yijiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 4,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(target, "yijiao1", 10 * self.interaction.data)
    room:setPlayerMark(target, "@yijiao", target:getMark("yijiao1"))
    local mark = target:getMark("yijiao_src")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, effect.from)
    room:setPlayerMark(target, "yijiao_src", mark)
  end,
}
local yijiao_record = fk.CreateTriggerSkill{
  name = "#yijiao_record",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@yijiao") ~= 0 and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("yijiao2") - player:getMark("yijiao1")
    local src = table.map(target:getMark("yijiao_src"), function(id) return room:getPlayerById(id) end)
    for _, p in ipairs(src) do
      if not p.dead then
        room:doIndicate(p.id, {player.id})
      end
      room:delay(500)
      if n < 0 then
        if not player:isKongcheng() then
          room:broadcastSkillInvoke("yijiao", 1)
          room:notifySkillInvoked(p, "yijiao", "control")
          room:throwCard({table.random(player.player_cards[Player.Hand])}, "yijiao", player, player)
        end
      elseif n == 0 then
        room:broadcastSkillInvoke("yijiao", 2)
        room:notifySkillInvoked(p, "yijiao", "support")
        player:gainAnExtraTurn(true)
      else
        if not p.dead then
          room:broadcastSkillInvoke("yijiao", 2)
          room:notifySkillInvoked(p, "yijiao", "drawcard")
          p:drawCards(2, "yijiao")
        end
      end
    end
    room:setPlayerMark(player, "@yijiao", 0)
    room:setPlayerMark(player, "yijiao1", 0)
    room:setPlayerMark(player, "yijiao2", 0)
    room:setPlayerMark(player, "yijiao_src", 0)
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@yijiao") ~= 0 and player.phase ~= Player.NotActive and data.card.number
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "yijiao2", data.card.number)
    room:setPlayerMark(player, "@yijiao", string.format("%d/%d", target:getMark("yijiao1"), target:getMark("yijiao2")))
  end,
}
local qibie = fk.CreateTriggerSkill{
  name = "qibie",
  anim_type = "drawcard",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qibie-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum()
    player:throwAllCards("h")
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    player:drawCards(n + 1, self.name)
  end,
}
yijiao:addRelatedSkill(yijiao_record)
licaiwei:addSkill(yijiao)
licaiwei:addSkill(qibie)
Fk:loadTranslationTable{
  ["licaiwei"] = "李采薇",
  ["yijiao"] = "异教",
  [":yijiao"] = "出牌阶段限一次，你可以选择一名其他角色并选择一个1~4的数字，该角色获得十倍的“异”标记；"..
  "有“异”标记的角色结束阶段，若其本回合使用牌的点数之和：<br>"..
  "1.小于“异”标记数，其随机弃置一张手牌；<br>"..
  "2.等于“异”标记数，其于本回合结束后进行一个额外的回合；<br>"..
  "3.大于“异”标记数，你摸两张牌。",
  ["qibie"] = "泣别",
  [":qibie"] = "一名角色死亡后，你可以弃置所有手牌，然后回复1点体力值并摸X+1张牌（X为你以此法弃置牌数）。",
  ["@yijiao"] = "异",
  ["#yijiao_record"] = "异教",
  ["#qibie-invoke"] = "泣别：你可以弃置所有手牌，回复1点体力值并摸弃牌数+1张牌",

  ["$yijiao1"] = "攻乎异教，斯害也已。",
  ["$yijiao2"] = "非我同盟，其心必异。",
  ["$qibie1"] = "忽闻君别，泣下沾襟。",
  ["$qibie2"] = "相与泣别，承其遗志。",
  ["~licaiwei"] = "随君而去……",
}

Fk:loadTranslationTable{
  ["ty__miheng"] = "祢衡",
  ["kuangcai"] = "狂才",
  [":kuangcai"] = "①锁定技，你的回合内，你使用牌无距离和次数限制。<br>②弃牌阶段开始时，若你本回合：没有使用过牌，你的手牌上限+1；"..
  "使用过牌且没有造成伤害，你手牌上限-1。<br>③结束阶段，若你本回合造成过伤害，你摸等于伤害值数量的牌（最多摸五张）。",
  ["shejian"] = "舌剑",
  [":shejian"] = "每回合限两次，当你成为其他角色使用牌的唯一目标后，你可以弃置至少两张手牌。若如此做，你选择一项："..
  "1.弃置该角色等量的牌，2.对其造成1点伤害。",
}

local sunyi = General(extension, "ty__sunyi", "wu", 5)
local jiqiaos = fk.CreateTriggerSkill{
  name = "jiqiaos",
  anim_type = "drawcard",
  expand_pile = "jiqiaos",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, player.room:getNCards(player.maxHp), true, self.name)
  end,
}
local jiqiaos_trigger = fk.CreateTriggerSkill{
  name = "#jiqiaos_trigger",
  anim_type = "drawcard",
  expand_pile = "jiqiaos",
  events = {fk.EventPhaseEnd, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and #player:getPile("jiqiaos") > 0 then
      if event == fk.EventPhaseEnd then
        return player.phase == Player.Play
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      room:moveCards({
        from = player.id,
        ids = player:getPile("jiqiaos"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = "jiqiaos",
        specialName = "jiqiaos",
      })
    else
      local card = room:askForCard(player, 1, 1, false, "jiqiaos", false, ".|.|.|jiqiaos|.|.", "#jiqiaos-card", "jiqiaos")
      if #card == 0 then card = {table.random(player:getPile("jiqiaos"))} end
      room:obtainCard(player, card[1], true, fk.ReasonJustMove)
      local red = #table.filter(player:getPile("jiqiaos"), function (id) return Fk:getCardById(id, true).color == Card.Red end)
      local black = #player:getPile("jiqiaos") - red  --除了不该出现的衍生牌，都有颜色
      if red == black then
        if player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = "jiqiaos",
          }
        end
      else
        room:loseHp(player, 1, "jiqiaos")
      end
    end
  end,
}
local xiongyis = fk.CreateTriggerSkill{
  name = "xiongyis",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#xiongyis1-invoke:::"..tostring(math.min(3, player.maxHp))
    if table.find(player.room.alive_players, function(p) return string.find(p.general, "xushi") end) then
      prompt = "#xiongyis2-invoke"
    end
    if player.room:askForSkillInvoke(player, self.name, nil, prompt) then
      self.cost_data = prompt
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = tonumber(string.sub(self.cost_data, 10, 10))
    if n == 1 then
      local maxHp = player.maxHp
      room:recover({
        who = player,
        num = math.min(3, maxHp) - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      room:changeHero(player, "xushi", false, false, true)
      player.maxHp = maxHp
      room:broadcastProperty(player, "maxHp")
    else
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
      room:handleAddLoseSkills(player, "hunzi", nil, true, false)
    end
  end,
}
jiqiaos:addRelatedSkill(jiqiaos_trigger)
sunyi:addSkill(jiqiaos)
sunyi:addSkill(xiongyis)
sunyi:addRelatedSkill("hunzi")
sunyi:addRelatedSkill("ex__yingzi")
sunyi:addRelatedSkill("yinghun")
Fk:loadTranslationTable{
  ["ty__sunyi"] = "孙翊",
  ["jiqiaos"] = "激峭",
  [":jiqiaos"] = "出牌阶段开始时，你可以将牌堆顶的X张牌至于武将牌上（X为你的体力上限）；当你使用一张牌结算结束后，若你的武将牌上有“激峭”牌，"..
  "你获得其中一张，然后若剩余其中两种颜色牌的数量相等，你回复1点体力，否则你失去1点体力；出牌阶段结束时，移去所有“激峭”牌。",
  ["xiongyis"] = "凶疑",
  [":xiongyis"] = "限定技，当你处于濒死状态时，若徐氏：不在场，你可以将体力值回复至3点并将武将牌替换为徐氏；"..
  "在场，你可以将体力值回复至1点并获得技能〖魂姿〗。",
  ["#jiqiaos_trigger"] = "激峭",
  ["#jiqiaos-card"] = "激峭：获得一张“激峭”牌",
  ["#xiongyis1-invoke"] = "凶疑：你可以将回复体力至%arg点并变身为徐氏！",
  ["#xiongyis2-invoke"] = "凶疑：你可以将回复体力至1点并获得〖魂姿〗！",
}
--赵嫣
--严夫人 郝萌 马日磾2022.4.25

local fengyu = General(extension, "ty__fengfangnv", "qun", 3, 3, General.Female)
local tiqi = fk.CreateTriggerSkill{
  name = "tiqi",
  anim_type = "drawcard",
  events = {fk.AfterDrawNCards},  --tenyear's strange event. change it
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and data.n ~= 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#tiqi-invoke:::"..tostring(math.abs(data.n - 2)))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(data.n - 2)
    player:drawCards(n, self.name)
    local choice = room:askForChoice(player, {"tiqi_add", "tiqi_minus"}, self.name)
    if choice == "tiqi_add" then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, n)
    else
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, n)
    end
  end,
}
local baoshu = fk.CreateTriggerSkill{
  name = "baoshu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
      return p.id
    end), 1, player.maxHp, "#baoshu-choose", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      room:addPlayerMark(p, "@fengyu_shu", player.maxHp - #self.cost_data + 1)
      if not p.faceup then
        p:turnOver()
      end
      if p.chained then
        p:setChainState(false)
      end
    end
  end,

  refresh_events = {fk.DrawNCards},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@fengyu_shu") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@fengyu_shu")
    player.room:setPlayerMark(player, "@fengyu_shu", 0)
  end
}
fengyu:addSkill(tiqi)
fengyu:addSkill(baoshu)
Fk:loadTranslationTable{
  ["ty__fengfangnv"] = "冯妤",
  ["tiqi"] = "涕泣",
  [":tiqi"] = "其他角色摸牌阶段摸牌后，若其摸牌数不等于2，则你摸超出或少于2的牌，然后令该角色本回合手牌上限增加或减少同样的数值。",
  ["baoshu"] = "宝梳",
  [":baoshu"] = "准备阶段，你可以选择至多X名角色（X为你的体力上限），这些角色各获得一个“梳”标记并重置武将牌，"..
  "你每少选一名角色，每名目标角色便多获得一个“梳”。有“梳”标记的角色摸牌阶段多摸其“梳”数量的牌，然后移去其所有“梳”。",
  ["#tiqi-invoke"] = "涕泣：你可以摸%arg张牌，并令其本回合手牌上限+X或-X",
  ["tiqi_add"] = "增加手牌上限",
  ["tiqi_minus"] = "减少手牌上限",
  ["#baoshu-choose"] = "宝梳：你可以令若干名角色获得“梳”标记，重置其武将牌且其摸牌阶段多摸牌",
  ["@fengyu_shu"] = "梳",
  
  ["$tiqi1"] = "远望中原，涕泪交流。",
  ["$tiqi2"] = "瞻望家乡，泣涕如雨。",
  ["$baoshu1"] = "明镜映梳台，黛眉衬粉面。",
  ["$baoshu2"] = "头作扶摇髻，首枕千金梳。",
  ["~ty__fengfangnv"] = "诸位，为何如此对我？",
}

local caimaozhangyun = General(extension, "caimaozhangyun", "wei", 4)
local lianzhou = fk.CreateTriggerSkill{
  name = "lianzhou",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.chained then
      player:setChainState(true)
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp == player.hp and not p.chained end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 999, "#lianzhou-choose", self.name, true)
    if #tos > 0 then
      table.forEach(tos, function(p) room:getPlayerById(p):setChainState(true) end)
    end
  end,
}
local jinglan = fk.CreateTriggerSkill{
  name = "jinglan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player.player_cards[Player.Hand] > player.hp then
      if #player.player_cards[Player.Hand] < 4 then
        player:throwAllCards("h")
      else
        room:askForDiscard(player, 3, 3, false, self.name, false)
      end
    elseif #player.player_cards[Player.Hand] == player.hp then
      if #player.player_cards[Player.Hand] < 2 then
        player:throwAllCards("h")
      else
        room:askForDiscard(player, 1, 1, false, self.name, false)
      end
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    elseif #player.player_cards[Player.Hand] < player.hp then
      room:damage{
        to = player,
        damage = 1,
        damageType = fk.FireDamage,
        skillName = self.name,
      }
      if not player.dead then
        player:drawCards(4, self.name)
      end
    end
  end,
}
caimaozhangyun:addSkill(lianzhou)
caimaozhangyun:addSkill(jinglan)
Fk:loadTranslationTable{
  ["caimaozhangyun"] = "蔡瑁张允",
  ["lianzhou"] = "连舟",
  [":lianzhou"] = "锁定技，准备阶段，将你的武将牌横置，然后横置任意名体力值等于你的角色。",
  ["jinglan"] = "惊澜",
  [":jinglan"] = "锁定技，当你造成伤害后，若你的手牌数：大于体力值，你弃三张手牌；等于体力值，你弃一张手牌并回复1点体力；"..
  "小于体力值，你受到1点火焰伤害并摸四张牌。",
  ["#lianzhou-choose"] = "连舟：你可以横置任意名体力值等于你的角色",
}

local gaolan = General(extension, "ty__gaolan", "qun", 4)
local xizhen = fk.CreateTriggerSkill{
  name = "xizhen",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not (player:isProhibited(p, Fk:cloneCard("slash")) and player:isProhibited(p, Fk:cloneCard("duel"))) then
        table.insert(targets, p.id)
      end
    end
    if #targets > 0 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#xizhen-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:setPlayerMark(player, "xizhen-phase", to.id)
    local choices = {}
    for _, name in ipairs({"slash", "duel"}) do
      if not player:isProhibited(to, Fk:cloneCard(name)) then
        table.insert(choices, name)
      end
    end
    local choice = room:askForChoice(player, choices, self.name, "#xizhen-choice::"..to.id)
    room:useVirtualCard(choice, nil, player, to, self.name, true)
  end,
}
local xizhen_trigger = fk.CreateTriggerSkill{
  name = "#xizhen_trigger",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("xizhen-phase") ~= 0 and data.responseToEvent and data.responseToEvent.from and
      data.responseToEvent.from == player.id
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("xizhen-phase"))
    if not to.dead then
      if to:isWounded() then
        room:recover{
          who = to,
          num = 1,
          recoverBy = player,
          skillName = "xizhen",
        }
        player:drawCards(1, "xizhen")
      else
        player:drawCards(2, "xizhen")
      end
    end
  end,
}
xizhen:addRelatedSkill(xizhen_trigger)
gaolan:addSkill(xizhen)
Fk:loadTranslationTable{
  ["ty__gaolan"] = "高览",
  ["xizhen"] = "袭阵",
  [":xizhen"] = "出牌阶段开始时，你可选择一名其他角色，视为对其使用【杀】或【决斗】，然后本阶段你的牌每次被使用或打出牌响应时，"..
  "该角色回复1点体力，你摸一张牌（若其未受伤，改为两张）。",
  ["#xizhen-choose"] = "袭阵：你可视为对一名角色使用【杀】或【决斗】；<br>本阶段你的牌被响应时其回复1点体力，你摸一张牌（若其未受伤则改为摸两张）",
  ["#xizhen-choice"] = "袭阵：选择视为对 %dest 使用的牌",

  ["$xizhen1"] = "今我为刀俎，尔等皆为鱼肉。",
  ["$xizhen2"] = "先发可制人，后发制于人。",
  ["~ty__gaolan"] = "郭公则害我！",
}

local caomao = General(extension, "caomao", "wei", 3, 4)
local qianlong = fk.CreateTriggerSkill{
  name = "qianlong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
    })
    local result = room:askForGuanxing(player, cards, {0, player:getLostHp()}, {},
      "#qianlong-guanxing:::"..player:getLostHp(), true, {"qianlong_get", "qianlong_bottom"})
    if #result.top > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(result.top)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #result.bottom > 0 then
      for _, id in ipairs(result.bottom) do
        table.insert(room.draw_pile, id)
      end
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = #result.top,
        arg2 = #result.bottom,
      }
    end
  end,
}
local fensi = fk.CreateTriggerSkill{
  name = "fensi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.hp >= player.hp end), function(p) return p.id end), 1, 1, "#fensi-choose", self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = player
    end
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = self.name,
    }
    if not to.dead and to ~= player then
      room:useVirtualCard("slash", nil, to, player, self.name, true)
    end
  end,
}
local juetao = fk.CreateTriggerSkill{
  name = "juetao",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player.hp == 1 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#juetao-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    while true do
      if player.dead or to.dead then return end
      local id = room:getNCards(1, "bottom")[1]
      room:moveCards({
        ids = {id},
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      local card = Fk:getCardById(id, true)
      local tos
      if (card.trueName == "slash") or
        ((table.contains({"dismantlement", "snatch", "chasing_near"}, card.name)) and not to:isAllNude()) or
        (table.contains({"fire_attack", "unexpectation"}, card.name) and not to:isKongcheng()) or
        (table.contains({"duel", "savage_assault", "archery_attack", "iron_chain", "raid_and_frontal_attack", "enemy_at_the_gates"}, card.name)) or
        (table.contains({"indulgence", "supply_shortage"}, card.name) and not to:hasDelayedTrick(card.name)) then
        tos = {{to.id}}
      elseif (table.contains({"amazing_grace", "god_salvation"}, card.name)) then
        tos = {{player.id}, {to.id}}
      elseif (card.name == "collateral" and to:getEquipment(Card.SubtypeWeapon)) then
        tos = {{to.id}, {player.id}}
      elseif (card.type == Card.TypeEquip) or
        (card.name == "peach" and player:isWounded()) or
        (card.name == "analeptic") or
        (table.contains({"ex_nihilo", "foresight"}, card.name)) or
        (card.name == "fire_attack" and not player:isKongcheng()) or
        (card.name == "lightning" and not player:hasDelayedTrick("lightning")) then
        tos = {{player.id}}
      end
      if tos and room:askForSkillInvoke(player, self.name, data, "#juetao-use:::"..card:toLogString()) then
        room:useCard({
          card = card,
          from = player.id,
          tos = tos,
          skillName = self.name,
          extraUse = true,
        })
      else
        room:delay(800)
        room:moveCards({
          ids = {id},
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
        })
        return
      end
    end
  end,
}
local zhushi = fk.CreateTriggerSkill{
  name = "zhushi$",
  anim_type = "drawcard",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase ~= Player.NotActive and target.kingdom == "wei" and
      player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(target, {"zhushi_draw", "Cancel"}, self.name, "#zhushi-invoke:"..player.id)
    if choice == "zhushi_draw" then
      player:drawCards(1)
    end
  end,
}
caomao:addSkill(qianlong)
caomao:addSkill(fensi)
caomao:addSkill(juetao)
caomao:addSkill(zhushi)
Fk:loadTranslationTable{
  ["caomao"] = "曹髦",
  ["qianlong"] = "潜龙",
  [":qianlong"] = "当你受到伤害后，你可以展示牌堆顶的三张牌并获得其中至多X张牌（X为你已损失的体力值），然后将剩余的牌置于牌堆底。",
  ["fensi"] = "忿肆",
  [":fensi"] = "锁定技，准备阶段，你对一名体力值不小于你的角色造成1点伤害；若受伤角色不为你，则其视为对你使用一张【杀】。",
  ["juetao"] = "决讨",
  [":juetao"] = "限定技，出牌阶段开始时，若你的体力值为1，你可以选择一名角色并依次使用牌堆底的牌直到你无法使用，这些牌不能指定除你和该角色以外的角色为目标。",
  ["zhushi"] = "助势",
  [":zhushi"] = "主公技，其他魏势力角色每回合限一次，该角色回复体力时，你可以令其选择是否令你摸一张牌。",
  ["#qianlong-guanxing"] = "潜龙：获得其中至多%arg张牌（获得上方的牌，下方的牌置于牌堆底）",
  ["qianlong_get"] = "获得",
  ["qianlong_bottom"] = "置于牌堆底",
  ["#fensi-choose"] = "忿肆：你须对一名体力值不小于你的角色造成1点伤害，若不为你，视为其对你使用【杀】",
  ["#juetao-choose"] = "决讨：你可以指定一名角色，连续对其使用牌堆底牌直到不能使用！",
  ["#juetao-use"] = "决讨：是否使用%arg！",
  ["#zhushi-invoke"] = "助势：你可以令 %src 摸一张牌",
  ["zhushi_draw"] = "其摸一张牌",
  
  ["$qianlong1"] = "鸟栖于林，龙潜于渊。",
  ["$qianlong2"] = "游鱼惊钓，潜龙飞天。",
  ["$fensi1"] = "此贼之心，路人皆知！",
  ["$fensi2"] = "孤君烈忿，怒愈秋霜。",
  ["$juetao1"] = "登车拔剑起，奋跃搏乱臣！",
  ["$juetao2"] = "陵云决心意，登辇讨不臣！",
  ["$zhushi1"] = "可有爱卿愿助朕讨贼？",
  ["$zhushi2"] = "泱泱大魏，忠臣俱亡乎？",
  ["~caomao"] = "宁作高贵乡公死，不作汉献帝生……",
}

--吉平

local laiyinger = General(extension, "laiyinger", "qun", 3, 3, General.Female)
local xiaowu = fk.CreateActiveSkill{
  name = "xiaowu",
  anim_type = "offensive",
  --prompt = "#xiaowu",
  max_card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local players = room:getOtherPlayers(player)
    local targets = {}
    local choice = #players == 1 and "xiaowu_clockwise" or
    room:askForChoice(player, {"xiaowu_clockwise", "xiaowu_anticlockwise"}, self.name, "#xiawu_order::" .. target.id)
    for i = 1, #players, 1 do
      local real_i = i
      if choice == "xiaowu_anticlockwise" then
        real_i = #players + 1 - real_i
      end
      local temp = players[real_i]
      table.insert(targets, temp)
      if temp == target then break end
    end
    room:doIndicate(player.id, table.map(targets, function (p) return p.id end))
    local x = 0
    local to_damage = {}
    for _, p in ipairs(targets) do
      if not p.dead and not player.dead then
        choice = room:askForChoice(p, {"xiaowu_draw1", "draw1"}, self.name, "#xiawu_draw:" .. player.id)
        if choice == "xiaowu_draw1" then
          player:drawCards(1, self.name)
          x = x+1
        elseif choice == "draw1" then
          p:drawCards(1, self.name)
          table.insert(to_damage, p.id)
        end
      end
    end
    if not player.dead then
      if x > #to_damage then
        room:addPlayerMark(player, "@xiaowu_sand")
      elseif x < #to_damage then
        room:sortPlayersByAction(to_damage)
        for _, pid in ipairs(to_damage) do
          local p = room:getPlayerById(pid)
          if not p.dead then
            room:damage{ from = player, to = p, damage = 1, skillName = self.name }
          end
        end
      end
    end
  end,
}
local huaping = fk.CreateTriggerSkill{
  name = "huaping",
  events = {fk.Death},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name, false, player == target) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player == target then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
        return p.id end), 1, 1, "#huaping-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#huaping-invoke::"..target.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player == target then
      local to = room:getPlayerById(self.cost_data)
      room:handleAddLoseSkills(to, "shawu", nil, true, false)
      room:setPlayerMark(to, "@xiaowu_sand", player:getMark("@xiaowu_sand"))
    else
      local skills = {}
      for _, s in ipairs(target.player_skills) do
        if not (s.attached_equip or s.name[#s.name] == "&") then
          table.insertIfNeed(skills, s.name)
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
      end
      local x = player:getMark("@xiaowu_sand")
      room:handleAddLoseSkills(player, "-xiaowu", nil, true, false)
      room:setPlayerMark(player, "@xiaowu_sand", 0)
      if x > 0 then
        player:drawCards(x, self.name)
      end
    end
  end,
}
local shawu_select = fk.CreateActiveSkill{
  name = "#shawu_select",
  can_use = function() return false end,
  target_num = 0,
  max_card_num = 2,
  min_card_num = function ()
    if Self:getMark("@xiaowu_sand") > 0 then
      return 0
    end
    return 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and not Self:prohibitDiscard(Fk:getCardById(to_select)) and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
}
local shawu = fk.CreateTriggerSkill{
  name = "shawu",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and
      (player:getMark("@xiaowu_sand") > 0 or player:getHandcardNum() > 1) and not player.room:getPlayerById(data.to).dead
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "#shawu_select", "#shawu-invoke::" .. data.to, true)
    if ret then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(data.to)
    local draw2 = false
    if #self.cost_data > 1 then
      room:throwCard(self.cost_data, self.name, player, player)
    else
      room:removePlayerMark(player, "@xiaowu_sand")
      draw2 = true
    end
    if not to.dead then
      room:damage{ from = player, to = to, damage = 1, skillName = self.name }
    end
    if draw2 and not player.dead then
      player:drawCards(2, self.name)
    end
  end,
}
shawu:addRelatedSkill(shawu_select)
laiyinger:addSkill(xiaowu)
laiyinger:addSkill(huaping)
laiyinger:addRelatedSkill(shawu)
Fk:loadTranslationTable{
  ["laiyinger"] = "来莺儿",
  ["xiaowu"] = "绡舞",
  [":xiaowu"] = "出牌阶段限一次，你可以从你的上家或下家起选择任意名座位连续的其他角色，每名角色依次选择一项：1.令你摸一张牌；2.自己摸一张牌。"..
  "选择完成后，若令你摸牌的选择人数较多，你获得一个“沙”标记；若自己摸牌的选择人数较多，你对这些角色各造成1点伤害。",
  ["huaping"] = "化萍",
  [":huaping"] = "限定技，一名其他角色死亡时，你可以获得其所有武将技能，然后你失去〖绡舞〗和所有“沙”标记并摸等量的牌。"..
  "你死亡时，若此技能未发动过，你可令一名其他角色获得技能〖沙舞〗和所有“沙”标记。",
  ["shawu"] = "沙舞",
  ["#shawu_select"] = "沙舞",
  [":shawu"] = "当你使用【杀】指定目标后，你可以弃置两张手牌或1枚“沙”标记对目标角色造成1点伤害。若你弃置的是“沙”标记，你摸两张牌。",

  ["#xiaowu"] = "绡舞：选择作为终点的目标角色，然后选择顺时针或逆时针顺序",
  ["@xiaowu_sand"] = "沙",
  ["#xiawu_order"] = "绡舞：选择从你至终点为%dest的目标顺序",
  ["xiaowu_clockwise"] = "顺时针顺序",
  ["xiaowu_anticlockwise"] = "逆时针顺序",
  ["#xiawu_draw"] = "绡舞：选择令%src摸一张牌或自己摸一张牌",
  ["xiaowu_draw1"] = "令其摸一张牌",
  ["#huaping-choose"] = "化萍：选择一名角色，令其获得沙舞",
  ["#huaping-invoke"] = "化萍：你可以获得%dest的所有武将技能，然后失去绡舞",
  ["#shawu-invoke"] = "沙舞：你可选择两张手牌弃置，或直接点确定弃置沙标记。来对%dest造成1点伤害",

  ["$xiaowu1"] = "繁星临云袖，明月耀舞衣。",
  ["$xiaowu2"] = "逐舞飘轻袖，传歌共绕梁。",
  ["$huaping1"] = "风絮飘残，化萍而终。",
  ["$huaping2"] = "莲泥刚倩，藕丝萦绕。",
  ["~laiyinger"] = "谷底幽兰艳，芳魂永留香……",
}

local godjiangwei = General(extension, "godjiangwei", "god", 4)
local tianren = fk.CreateTriggerSkill {
  name = "tianren",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      self.cost_data = 0
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeBasic or card:isCommonTrick() then
              self.cost_data = self.cost_data + 1
            end
          end
        end
      end
      return self.cost_data > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for i = 1, self.cost_data, 1 do
      room:addPlayerMark(player, "@tianren", 1)
      if player:getMark("@tianren") >= player.maxHp then
        room:removePlayerMark(player, "@tianren", player.maxHp)
        room:changeMaxHp(player, 1)
        player:drawCards(2, self.name)
      end
    end
  end,
}
local jiufa = fk.CreateTriggerSkill{
  name = "jiufa",
  events = {fk.CardUsing, fk.CardResponding},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      local mark = player:getMark(self.name)
      if mark == 0 then mark = {} end
      if #mark == 9 then
        player.room:setPlayerMark(player, "@$jiufa", 0)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card_ids = room:getNCards(9)
    local get, throw = {}, {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
    })
    table.forEach(room.players, function(p) room:fillAG(p, card_ids) end)
    local numbers = {}
    for _, id in ipairs(card_ids) do
      local num = Fk:getCardById(id, true).number
      numbers[num] = (numbers[num] or 0) + 1
    end
    while true do
      for i = #card_ids, 1, -1 do
        local id = card_ids[i]
        if numbers[Fk:getCardById(id, true).number] < 2 then
          room:takeAG(player, id, room.players)
          table.insert(throw, id)
          table.removeOne(card_ids, id)
        end
      end
      if #card_ids == 0 then break end
      local card_id = room:askForAG(player, card_ids, false, self.name)
      --if card_id == nil then break end
      room:takeAG(player, card_id, room.players)
      table.insert(get, card_id)
      table.removeOne(card_ids, card_id)
      numbers[Fk:getCardById(card_id, true).number] = 0
      if #card_ids == 0 then break end
    end
    table.forEach(room.players, function(p)
      room:closeAG(p)
    end)
    if #get > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(get)
      room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
  end,

  refresh_events = {fk.CardUsing, fk.CardResponding},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark(self.name)
    if mark == 0 or #mark > 8 then mark = {} end
    if not table.contains(mark, data.card.trueName) then
      table.insert(mark, data.card.trueName)
    end
    player.room:setPlayerMark(player, self.name, mark)
    if player:hasSkill(self.name, true) then
      player.room:setPlayerMark(player, "@$jiufa", mark)
    end
  end,
}
local pingxiang = fk.CreateActiveSkill{
  name = "pingxiang",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player.maxHp > 9 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:changeMaxHp(player, -9)
    for i = 1, 9, 1 do
      if player.dead then return end
      local success, data = room:askForUseActiveSkill(player, "pingxiang_viewas", "#pingxiang-slash:::"..tostring(i), true)
      if success then
        local card = Fk:cloneCard("fire__slash")
        card.skillName = self.name
        room:useCard{
          from = player.id,
          tos = table.map(data.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      else
        break
      end
    end
    room:handleAddLoseSkills(player, "-jiufa", nil, true, false)
  end,
}
local pingxiang_viewas = fk.CreateViewAsSkill{
  name = "pingxiang_viewas",
  card_filter = function(self, to_select, selected)
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("fire__slash")
    card.skillName = "pingxiang"
    return card
  end,
}
local pingxiang_maxcards = fk.CreateMaxCardsSkill{
  name = "#pingxiang_maxcards",
  fixed_func = function(self, player)
    if player:usedSkillTimes("pingxiang", Player.HistoryGame) > 0 then
      return player.maxHp
    end
  end
}
Fk:addSkill(pingxiang_viewas)
pingxiang:addRelatedSkill(pingxiang_maxcards)
godjiangwei:addSkill(tianren)
godjiangwei:addSkill(jiufa)
godjiangwei:addSkill(pingxiang)
Fk:loadTranslationTable{
  ["godjiangwei"] = "神姜维",
  ["tianren"] = "天任",
  [":tianren"] = "锁定技，当一张基本牌或普通锦囊牌不是因使用而置入弃牌堆后，你获得1个“天任”标记，"..
  "然后若“天任”标记数不小于X，你移去X个“天任”标记，加1点体力上限并摸两张牌（X为你的体力上限）。",
  ["jiufa"] = "九伐",
  [":jiufa"] = "当你每累计使用或打出九张不同牌名的牌后，你可以亮出牌堆顶的九张牌，然后若其中有点数相同的牌，你选择并获得其中每个重复点数的牌各一张。",
  ["pingxiang"] = "平襄",
  [":pingxiang"] = "限定技，出牌阶段，若你的体力上限大于9，你可以减9点体力上限，然后你视为使用至多九张火【杀】。"..
  "若如此做，你失去技能〖九伐〗且本局游戏内你的手牌上限等于体力上限。",
  ["@tianren"] = "天任",
  ["@$jiufa"] = "九伐",
  ["pingxiang_viewas"] = "平襄",
  ["#pingxiang-slash"] = "平襄：你可以视为使用火【杀】（第%arg张，共9张）！",

  ["$tianren1"] = "举石补苍天，舍我更复其谁？",
  ["$tianren2"] = "天地同协力，何愁汉道不昌？",
  ["$jiufa1"] = "九伐中原，以圆先帝遗志。",
  ["$jiufa2"] = "日日砺剑，相报丞相厚恩。",
  ["$pingxiang1"] = "策马纵慷慨，捐躯抗虎豺。",
  ["$pingxiang2"] = "解甲事仇雠，竭力挽狂澜。",
  ["~godjiangwei"] = "武侯遗志，已成泡影矣……",
}

--骆统 张媱 张勋 滕胤 神马超 黄承彦2022.6.15

local zhangyao = General(extension, "zhangyao", "wu", 3, 3, General.Female)
local yuanyu = fk.CreateActiveSkill{
  name = "yuanyu",
  anim_type = "control",
  --prompt = "#yuanyu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + player:getMark("yuanyu_extra_times-phase")
  end,
  card_filter = function() return false end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:drawCards(player, 1, self.name)
    if player:isKongcheng() then return end
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, ".|.|.|hand", "#yuanyu-choose", self.name, false)
    if #tar > 0 and card then
      local targetRecorded = type(player:getMark("yuanyu_targets")) == "table" and player:getMark("yuanyu_targets") or {}
      if not table.contains(targetRecorded, tar[1]) then
        table.insert(targetRecorded, tar[1])
        room:addPlayerMark(room:getPlayerById(tar[1]), "@@yuanyu")
      end
      room:setPlayerMark(player, "yuanyu_targets", targetRecorded)
      player:addToPile("yuanyu_resent", card, true, self.name)
    end
  end
}
local yuanyu_trigger = fk.CreateTriggerSkill{
  name = "#yuanyu_trigger",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuanyu.name) then
      if event == fk.Damage then
        return target and not target:isKongcheng() and player:getMark("yuanyu_targets") ~= 0 and table.contains(player:getMark("yuanyu_targets"), target.id)
      elseif event == fk.EventPhaseStart and target.phase == Player.Discard then
        if target == player then
          return player:getMark("yuanyu_targets") ~= 0 and table.find(player:getMark("yuanyu_targets"), function (pid)
            local p = player.room:getPlayerById(pid)
            return not p:isKongcheng() and not p.dead end)
        else
          return not target:isKongcheng() and player:getMark("yuanyu_targets") ~= 0 and table.contains(player:getMark("yuanyu_targets"), target.id)
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local x = 1
    if event == fk.Damage then
      x = data.damage
    end
    for i = 1, x do
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    if event == fk.EventPhaseStart and target == player then
      local targetRecorded = player:getMark("yuanyu_targets")
      tos = table.filter(room:getAlivePlayers(), function (p) return table.contains(targetRecorded, p.id) end)
    else
      table.insert(tos, target)
    end
    room:doIndicate(player.id, table.map(tos, function (p) return p.id end))
    for _, to in ipairs(tos) do
      if player.dead then break end
      local targetRecorded = player:getMark("yuanyu_targets")
      if targetRecorded == 0 then break end
      if not to.dead and not to:isKongcheng() and table.contains(targetRecorded, to.id) then
        local card = room:askForCard(to, 1, 1, false, self.name, false, ".|.|.|hand", "#yuanyu-push:" .. player.id)
        player:addToPile("yuanyu_resent", card, false, self.name)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= yuanyu then return false end
    return player == target and type(player:getMark("yuanyu_targets")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
  end,
}
local xiyan = fk.CreateTriggerSkill{
  name = "xiyan",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerSpecial and move.specialName == "yuanyu_resent" then
          local suits = {}
          for _, id in ipairs(player:getPile("yuanyu_resent")) do
            table.insertIfNeed(suits, Fk:getCardById(id).suit)
          end
          table.removeOne(suits, Card.NoSuit)
          return #suits > 3
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player:getPile("yuanyu_resent"))
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    if room.current and not room.current.dead and room.current.phase ~= Player.NotActive then
      if room.current == player then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 4)
        if player:usedSkillTimes(yuanyu.name, Player.HistoryPhase) > player:getMark("yuanyu_extra_times-phase") then
          room:addPlayerMark(player, "yuanyu_extra_times-phase")
        end
        room:addPlayerMark(player, "yuanyu_targetmod-turn")
      elseif room:askForSkillInvoke(player, self.name, nil, "#xiyan-debuff::"..room.current.id) then
        room:addPlayerMark(room.current, MarkEnum.MinusMaxCardsInTurn, 4)
        room:addPlayerMark(room.current, "yuanyu_prohibit-trun")
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if (move.from == player.id and table.find(move.moveInfo, function (info)
        return info.fromSpecialName == "yuanyu_resent" end)) or (move.to == player.id and move.specialName == "yuanyu_resent") then
          return true
        end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local suitsRecorded = {}
    if player:hasSkill(self.name, true) then
      for _, id in ipairs(player:getPile("yuanyu_resent")) do
        table.insertIfNeed(suitsRecorded, Fk:getCardById(id):getSuitString(true))
      end
    end
    player.room:setPlayerMark(player, "@xiyan", #suitsRecorded > 0 and suitsRecorded or 0)
  end,
}
local xiyan_targetmod = fk.CreateTargetModSkill{
  name = "#xiyan_targetmod",
  residue_func = function(self, player, skill, scope, card)
    return (card and player:getMark("yuanyu_targetmod-turn") > 0) and 999 or 0
  end,
}
local xiyan_prohibit = fk.CreateProhibitSkill{
  name = "#local xiyan_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("yuanyu_prohibit-trun") > 0 and card.type == Card.TypeBasic
  end,
}
yuanyu:addRelatedSkill(yuanyu_trigger)
xiyan:addRelatedSkill(xiyan_targetmod)
xiyan:addRelatedSkill(xiyan_prohibit)
zhangyao:addSkill(yuanyu)
zhangyao:addSkill(xiyan)
Fk:loadTranslationTable{
  ["zhangyao"] = "张媱",
  ["yuanyu"] = "怨语",
  ["#yuanyu_trigger"] = "怨语",
  [":yuanyu"] = "出牌阶段限一次，你可以摸一张牌并将一张手牌置于武将牌上，称为“怨”。然后选择一名其他角色，你与其的弃牌阶段开始时，该角色每次造成1点伤害后也须放置一张“怨”直到你触发“夕颜”。",
  ["xiyan"] = "夕颜",
  [":xiyan"] = "每次增加“怨”时，若“怨”的花色数达到4种，你可以获得所有“怨”。然后若此时是你的回合，你的“怨语”视为未发动过，本回合手牌上限+4且使用牌无次数限制；若不是你的回合，你可令当前回合角色本回合手牌上限-4且本回合不能使用基本牌。",

  ["yuanyu_resent"] = "怨",
  ["@@yuanyu"] = "怨语",
  ["#yuanyu"] = "怨语：你可以摸一张牌，然后放置一张手牌作为怨",
  ["#yuanyu-choose"] = "怨语：选择作为怨的一张手牌以及作为目标的一名其他角色",
  ["#yuanyu-push"] = "怨语：选择一张手牌作为%src的怨",
  ["@xiyan"] = "夕颜",
  ["#xiyan-debuff"] = "夕颜：是否令%dest本回合不能使用基本牌且手牌上限-4",

  ["$yuanyu1"] = "此生最恨者，吴垣孙氏人。",
  ["$yuanyu2"] = "愿为宫外柳，不做建章卿。",
  ["$xiyan1"] = "夕阳绝美，只叹黄昏。",
  ["$xiyan2"] = "朱颜将逝，知我何求。",
  ["~zhangyao"] = "花开人赏，花败谁怜……",
}

local zhangxun = General(extension, "zhangxun", "qun", 4)
local suizheng = fk.CreateTriggerSkill{
  name = "suizheng",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        return target:getMark("@@suizheng-turn") > 0 and target.phase == Player.Play and player.tag[self.name] and #player.tag[self.name] > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt
    if player.phase == Player.Finish then
      targets = table.map(room:getAlivePlayers(), function (p) return p.id end)
      prompt = "#suizheng-choose"
    else
      room:setPlayerMark(player, "@@suizheng-turn", 1)
      targets = table.filter(player.tag[self.name], function(id) return not room:getPlayerById(id).dead end)
      player.tag[self.name] = {}
      if #targets == 0 then return end
      prompt = "#suizheng-slash"
    end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if player.phase == Player.Finish then
      room:setPlayerMark(to, "@@suizheng", 1)
    else
      room:useVirtualCard("slash", nil, player, to, self.name, true)
    end
  end,

  refresh_events = {fk.EventPhaseStart, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:getMark("@@suizheng") > 0 and player.phase == Player.Play
    else
      return player:hasSkill(self.name, true) and target:getMark("@@suizheng-turn") > 0 and data.to ~= player and not data.to.dead
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      room:setPlayerMark(player, "@@suizheng", 0)
      room:setPlayerMark(player, "@@suizheng-turn", 1)
    else
      player.tag[self.name] = player.tag[self.name] or {}
      table.insert(player.tag[self.name], data.to.id)
    end
  end,
}
local suizheng_targetmod = fk.CreateTargetModSkill{
  name = "#suizheng_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@suizheng-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("@@suizheng-turn") > 0 then
      return 999
    end
  end,
}
suizheng:addRelatedSkill(suizheng_targetmod)
zhangxun:addSkill(suizheng)
Fk:loadTranslationTable{
  ["zhangxun"] = "张勋",
  ["suizheng"] = "随征",
  [":suizheng"] = "结束阶段，你可以选择一名角色，该角色下个回合的出牌阶段使用【杀】无距离限制且可以多使用一张【杀】。"..
  "然后其出牌阶段结束时，你可以视为对其本阶段造成过伤害的一名其他角色使用一张【杀】。",
  ["@@suizheng"] = "随征",
  ["@@suizheng-turn"] = "随征",
  ["#suizheng-choose"] = "随征：令一名角色下回合出牌阶段使用【杀】无距离限制且次数+1",
  ["#suizheng-slash"] = "随征：你可以视为对其中一名角色使用【杀】",
}

local godmachao = General(extension, "godmachao", "god", 4)
local shouli = fk.CreateViewAsSkill{
  name = "shouli",
  pattern = "slash,jink",
  interaction = function()
    local names = {}
    local pat = Fk.currentResponsePattern
    if pat == nil and Fk:cloneCard("slash").skill:canUse(Self) and table.find(Fk:currentRoom().alive_players, function(p)
      return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil end) then
      table.insert(names, "slash")
    else
      if Exppattern:Parse(pat):matchExp("slash") and table.find(Fk:currentRoom().alive_players, function(p)
        return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil end) then
          table.insert(names, "slash")
      end
      if Exppattern:Parse(pat):matchExp("jink") and table.find(Fk:currentRoom().alive_players, function(p)
        return p:getEquipment(Card.SubtypeDefensiveRide) ~= nil end) then
          table.insert(names, "jink")
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}  --FIXME: 体验很不好！
  end,
  view_as = function(self, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local horse_type = use.card.trueName == "slash" and Card.SubtypeOffensiveRide or Card.SubtypeDefensiveRide
    local horse_name = use.card.trueName == "slash" and "offensive_horse" or "defensive_horse"
    local targets = table.filter(room.alive_players, function (p)
      return p:getEquipment(horse_type) ~= nil
    end)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
        return p.id end), 1, 1, "#shouli-horse:::" .. horse_name, self.name, false, true)
      if #tos > 0 then
        local to = room:getPlayerById(tos[1])
        room:addPlayerMark(to, "@@shouli-turn")
        if to ~= player then
          room:addPlayerMark(player, "@@shouli-turn")
          room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
        end
        local horse = to:getEquipment(horse_type)
        if horse then
          room:obtainCard(player.id, horse, false, fk.ReasonPrey)
          if room:getCardOwner(horse) == player and room:getCardArea(horse) == Player.Hand then
            use.card:addSubcard(horse)
            use.extraUse = true
            return
          end
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil end)
  end,
  enabled_at_response = function(self, player)
    local pat = Fk.currentResponsePattern
    return pat and table.find(Fk:currentRoom().alive_players, function(p)
      return (Exppattern:Parse(pat):matchExp("slash") and p:getEquipment(Card.SubtypeOffensiveRide) ~= nil) or
        (Exppattern:Parse(pat):matchExp("jink") and p:getEquipment(Card.SubtypeDefensiveRide) ~= nil)
    end)
  end,
}
local shouli_trigger = fk.CreateTriggerSkill{
  name = "#shouli_trigger",
  events = {fk.GameStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shouli.name)
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(shouli.name)
    room:notifySkillInvoked(player, shouli.name)
    local temp = player.next
    local players = {}
    while temp ~= player do
      if not temp.dead then
        table.insert(players, temp)
      end
      temp = temp.next
    end
    table.insert(players, player)
    room:doIndicate(player.id, table.map(players, function (p) return p.id end))
    for _, p in ipairs(players) do
      if not p.dead then
        local cards = {}
        for i = 1, #room.draw_pile, 1 do
          local card = Fk:getCardById(room.draw_pile[i])
          if (card.sub_type == Card.SubtypeOffensiveRide or card.sub_type == Card.SubtypeDefensiveRide) and
              card.skill.canUse(card.skill, p, card) and not p:prohibitUse(card) then
            table.insertIfNeed(cards, card)
          end
        end
        if #cards > 0 then
          local horse = cards[math.random(1, #cards)]
          room:useCard{
            from = p.id,
            card = horse,
          }
        end
      end
    end
  end,
}
local shouli_delay = fk.CreateTriggerSkill{
  name = "#shouli_delay",
  events = {fk.DamageInflicted},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@shouli-turn") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    data.damageType = fk.ThunderDamage
  end,
}
local shouli_negated = fk.CreateTriggerSkill{
  name = "#shouli_negated",
  events = {fk.PreCardUse, fk.PreCardRespond},
  mute = true,
  priority = 10,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, shouli.name) and #data.card.subcards == 0
  end,
  on_cost = function() return true end,
  on_use = function() return true end,
}
shouli:addRelatedSkill(shouli_trigger)
shouli:addRelatedSkill(shouli_delay)
shouli:addRelatedSkill(shouli_negated)
local hengwu = fk.CreateTriggerSkill{
  name = "hengwu",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      local suit = data.card.suit
      return table.every(player.player_cards[Player.Hand], function (id)
        return Fk:getCardById(id).suit ~= suit end) and table.find(player.room.alive_players, function (p)
          return table.find(p.player_cards[Player.Equip], function (id)
            return Fk:getCardById(id).suit == suit end) end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local x = 0
    local suit = data.card.suit
    for _, p in ipairs(player.room.alive_players) do
      for _, id in ipairs(p.player_cards[Player.Equip]) do
        if Fk:getCardById(id).suit == suit then
          x = x + 1
        end
      end
    end
    if x > 0 then
      player:drawCards(x, self.name)
    end
  end,
}
godmachao:addSkill(shouli)
godmachao:addSkill(hengwu)
Fk:loadTranslationTable{
  ["godmachao"] = "神马超",
  ["shouli"] = "狩骊",
  ["#shouli_trigger"] = "狩骊",
  ["#shouli_delay"] = "狩骊",
  [":shouli"] = "游戏开始时，从下家开始所有角色随机使用牌堆中的一张坐骑。你可将场上的一张进攻马当【杀】（不计入次数，有次数限制）、防御马当【闪】使用或打出，以此法失去坐骑的其他角色本回合非锁定技失效，你与其本回合受到的伤害+1且改为雷电伤害（不叠加）。",
  ["hengwu"] = "横骛",
  [":hengwu"] = "当你使用或打出牌时，若你没有该花色的手牌，你可摸X张牌（X为场上与此牌花色相同的装备数量）。",

  ["@@shouli-turn"] = "狩骊",
  ["#shouli-horse"] = "狩骊：选择一名装备着 %arg 的角色",

  ["$shouli1"] = "赤骊骋疆，巡狩八荒！",
  ["$shouli2"] = "长缨在手，百骥可降！",
  ["$hengwu1"] = "横枪立马，独啸秋风！",
  ["$hengwu2"] = "世皆彳亍，唯我纵横！",
  ["~godmachao"] = "离群之马，虽强亦亡……",
}

local guanning = General(extension, "guanning", "qun", 3, 7)
local dunshi = fk.CreateViewAsSkill{
  name = "dunshi",
  pattern = "slash,jink,peach,analeptic",
  interaction = function()
    local names = {"slash", "jink", "peach", "analeptic"}
    local mark = Self:getMark("dunshi")
    if mark ~= 0 then
      for _, name in ipairs(mark) do
        table.removeOne(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "dunshi_name-turn", use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and (player:getMark(self.name) == 0 or #player:getMark(self.name) < 4)
  end,
  enabled_at_response = function(self, player, response)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and (player:getMark(self.name) == 0 or #player:getMark(self.name) < 4)
  end,
}
local dunshi_record = fk.CreateTriggerSkill{
  name = "#dunshi_record",
  anim_type = "special",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("dunshi", Player.HistoryTurn) > 0 and target and target.phase ~= Player.NotActive then
      if target:getMark("dunshi-turn") == 0 then
        player.room:addPlayerMark(target, "dunshi-turn", 1)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"dunshi1", "dunshi2", "dunshi3"}
    for i = 1, 2, 1 do
      local choice = room:askForChoice(player, choices, self.name)
      table.removeOne(choices, choice)
      if choice == "dunshi1" then
        local skills = {}
        for _, general in ipairs(Fk:getAllGenerals()) do
          for _, skill in ipairs(general.skills) do
            local str = Fk:translate(skill.name)
            if not target:hasSkill(skill) and
              (string.find(str, "仁") or string.find(str, "义") or string.find(str, "礼") or string.find(str, "智") or string.find(str, "信")) then
              table.insertIfNeed(skills, skill.name)
            end
          end
        end
        if #skills > 0 then
          local skill = room:askForChoice(player, table.random(skills, math.min(3, #skills)), self.name, "#dunshi-chooseskill::"..target.id, true)
          room:handleAddLoseSkills(target, skill, nil, true, false)
        end
      elseif choice == "dunshi2" then
        room:changeMaxHp(player, -1)
        if not player.dead and player:getMark("dunshi") ~= 0 then
          player:drawCards(#player:getMark("dunshi"), "dunshi")
        end
      elseif choice == "dunshi3" then
        local mark = player:getMark("dunshi")
        if mark == 0 then
          mark = {}
        end
        table.insert(mark, player:getMark("dunshi_name-turn"))
        room:setPlayerMark(player, "dunshi", mark)
      end
    end
    if not table.contains(choices, "dunshi1") then
      return true
    end
  end,
}
dunshi:addRelatedSkill(dunshi_record)
guanning:addSkill(dunshi)
Fk:loadTranslationTable{
  ["guanning"] = "管宁",
  ["dunshi"] = "遁世",
  [":dunshi"] = "每回合限一次，你可视为使用或打出一张【杀】，【闪】，【桃】或【酒】。然后当前回合角色本回合下次造成伤害时，你选择两项：<br>"..
  "1.防止此伤害，选择1个包含“仁义礼智信”的技能令其获得；<br>"..
  "2.减1点体力上限并摸X张牌（X为你选择3的次数）；<br>"..
  "3.删除你本次视为使用的牌名。",
  ["#dunshi_record"] = "遁世",
  ["dunshi1"] = "防止此伤害，选择1个“仁义礼智信”的技能令其获得",
  ["dunshi2"] = "减1点体力上限并摸X张牌",
  ["dunshi3"] = "删除你本次视为使用的牌名",
  ["#dunshi-chooseskill"] = "遁世：选择令%dest获得的技能",

  ["$dunshi1"] = "失路青山隐，藏名白水游。",
  ["$dunshi2"] = "隐居青松畔，遁走孤竹丘。",
  ["~guanning"] = "高节始终，无憾矣。",
}

local liuyu = General(extension, "ty__liuyu", "qun", 3)
local suifu = fk.CreateTriggerSkill{
  name = "suifu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Finish and player:getMark("suifu-turn") > 1 and
      not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suifu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.reverse(target.player_cards[Player.Hand])
    room:moveCards({
      ids = cards,
      from = target.id,
      fromArea = Player.Hand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:useVirtualCard("amazing_grace", nil, player, table.filter(room:getAlivePlayers(), function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace")) end), self.name, false)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and (target == player or target.seat == 1)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "suifu-turn", data.damage)
  end,
}
local pijing = fk.CreateTriggerSkill{
  name = "pijing",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 10, "#pijing-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        room:handleAddLoseSkills(p, "-zimu", nil, true, false)
      end
    end
    if not table.contains(self.cost_data, player.id) then
      table.insert(self.cost_data, 1, player.id)
    end
    for _, id in ipairs(self.cost_data) do
      room:handleAddLoseSkills(room:getPlayerById(id), "zimu", nil, true, false)
    end
  end,
}
local zimu = fk.CreateTriggerSkill{
  name = "zimu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:hasSkill("zimu", true) then
        p:drawCards(1, self.name)
      end
    end
    room:handleAddLoseSkills(player, "-zimu", nil, true, false)
  end,
}
liuyu:addSkill(suifu)
liuyu:addSkill(pijing)
liuyu:addRelatedSkill(zimu)
Fk:loadTranslationTable{
  ["ty__liuyu"] = "刘虞",
  ["suifu"] = "绥抚",
  [":suifu"] = "其他角色的结束阶段，若本回合你和一号位共计至少受到两点伤害，你可将当前回合角色的所有手牌置于牌堆顶，视为使用一张【五谷丰登】。",
  ["pijing"] = "辟境",
  [":pijing"] = "结束阶段，你可选择包含你的任意名角色，这些角色获得〖自牧〗直到下次发动〖辟境〗。",
  ["zimu"] = "自牧",
  [":zimu"] = "锁定技，当你受到伤害后，其他有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗。",
  ["#suifu-invoke"] = "绥抚：你可以将 %dest 所有手牌置于牌堆顶，你视为使用【五谷丰登】",
  ["#pijing-choose"] = "辟境：你可以令包括你的任意名角色获得技能〖自牧〗直到下次发动〖辟境〗<br>"..
  "（锁定技，当你受到伤害后，其他有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗）",
}

local caohua = General(extension, "caohua", "wei", 3, 3, General.Female)
local function doCaiyi(player, target, choice, n)
  local room = player.room
  local state = string.sub(choice, 6, 9)
  local i = tonumber(string.sub(choice, 10))
  if i == 4 then
    local num = {}
    for i = 1, 3, 1 do
      if player:getMark("caiyi"..state..tostring(i)) == 0 then
        table.insert(num, i)
      end
    end
    doCaiyi(player, target, "caiyi"..state..tostring(table.random(num)), n)
  else
    if state == "yang" then
      if i == 1 then
        if target:isWounded() then
          room:recover({
            who = target,
            num = math.min(n, target:getLostHp()),
            recoverBy = player,
            skillName = "caiyi",
          })
        end
      elseif i == 2 then
        target:drawCards(n, "caiyi")
      else
        if not target.faceup then
          target:turnOver()
        end
        if target.chained then
          target:setChainState(false)
        end
      end
    else
      if i == 1 then
        room:damage{
          to = target,
          damage = n,
          skillName = "caiyi",
        }
      elseif i == 2 then
        if #target:getCardIds{Player.Hand, Player.Equip} <= n then
          target:throwAllCards("he")
        else
          room:askForDiscard(target, n, n, true, "caiyi", false)
        end
      else
        target:turnOver()
        if not target.chained then
          target:setChainState(true)
        end
      end
    end
  end
end
local caiyi = fk.CreateTriggerSkill{
  name = "caiyi",
  anim_type = "switch",
  switch_skill_name = "caiyi",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Finish then
      local state = "yang"
      if player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
        state = "yinn"
      end
      for i = 1, 4, 1 do
        local mark = "caiyi"..state..tostring(i)
        if player:getMark(mark) == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#caiyi1-invoke"
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYin then
      prompt = "#caiyi2-invoke"
    end
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local state = "yang"
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYin then
      state = "yinn"
    end
    for i = 1, 4, 1 do
      local mark = "caiyi"..state..tostring(i)
      if player:getMark(mark) == 0 then
        table.insert(choices, mark)
      end
    end
    local num = #choices
    if num == 4 then
      table.remove(choices, 4)
    end
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, choices, self.name, "#caiyi-choice:::"..tostring(num))
    room:setPlayerMark(player, choice, 1)
    doCaiyi(player, to, choice, num)
  end,
}
local guili = fk.CreateTriggerSkill{
  name = "guili",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if target == player and data.from == Player.RoundStart then
        return player:getMark(self.name) == 0
      else
        return player:getMark(self.name) == target.id and data.to == Player.NotActive and
        target:getMark("guili-round") == 1 and target:getMark("guili_damage-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) == 0 then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#guili-choose", self.name, false, true)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:setPlayerMark(player, self.name, to)
      room:setPlayerMark(room:getPlayerById(to), "@@guili", 1)
    else
      player:gainAnExtraTurn(true)
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if player:getMark(self.name) ~= 0 and target and player:getMark(self.name) == target.id then
      if event == fk.EventPhaseChanging then
        return data.from == Player.RoundStart
      else
        return target.phase ~= Player.NotActive and target:getMark("guili-round") == 1
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:addPlayerMark(target, "guili-round", 1)
    else
      room:setPlayerMark(target, "guili_damage-turn", 1)
    end
  end,
}
caohua:addSkill(caiyi)
caohua:addSkill(guili)
Fk:loadTranslationTable{
  ["caohua"] = "曹华",
  ["caiyi"] = "彩翼",
  [":caiyi"] = "转换技，结束阶段，你可以令一名角色选择一项并移除该选项：阳：1.回复X点体力；2.摸X张牌；3.复原武将牌；4.随机执行一个已移除的阳选项；"..
  "阴：1.受到X点伤害；2.弃置X张牌；3.翻面并横置；4.随机执行一个已移除的阴选项（X为当前状态剩余选项数）。",
  ["guili"] = "归离",
  [":guili"] = "你的第一个回合开始时，你选择一名其他角色。该角色每轮的第一个回合结束时，若其本回合未造成过伤害，你执行一个额外的回合。",
  ["#caiyi1-invoke"] = "彩翼：你可以令一名角色执行一个正面选项",
  ["#caiyi2-invoke"] = "彩翼：你可以令一名角色执行一个负面选项",
  ["#caiyi-choice"] = "彩翼：选择执行的一项（其中X为%arg）",
  ["caiyiyang1"] = "回复X点体力",
  ["caiyiyang2"] = "摸X张牌",
  ["caiyiyang3"] = "复原武将牌",
  ["caiyiyang4"] = "随机一个已移除的阳选项",
  ["caiyiyinn1"] = "受到X点伤害",
  ["caiyiyinn2"] = "弃置X张牌",
  ["caiyiyinn3"] = "翻面并横置",
  ["caiyiyinn4"] = "随机一个已移除的阴选项",
  ["@@guili"] = "归离",
  ["#guili-choose"] = "归离：选择一名角色，其回合结束时，若其本回合未造成过伤害，你执行一个额外回合",

  ["$caiyi1"] = "凰凤化越，彩翼犹存。",
  ["$caiyi2"] = "身披彩翼，心有灵犀。",
  ["$guili1"] = "既离厄海，当归泸沽。",
  ["$guili2"] = "山野如春，不如归去。",
  ["~caohua"] = "自古忠孝难两全……",
}

return extension
