local extension = Package("tenyear_sp4")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp4"] = "十周年专属4",
}

--夏侯令女 秦宜禄 黄祖 羊祜2022.7.18

local zhangxuan = General(extension, "zhangxuan", "wu", 4, 4, General.Female)
local tongli = fk.CreateTriggerSkill{
  name = "tongli",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark(self.name) == 0 then
      local suits = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        table.insertIfNeed(suits, Fk:getCardById(id).suit)
      end
      return #suits == player:getMark("@tongli-turn")
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, player:getMark("@tongli-turn"))
  end,

  refresh_events = {fk.PreCardUse, fk.PreCardRespond, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.PreCardUse or event == fk.PreCardRespond then
        return player.phase == Player.Play
      else
        return player:getMark(self.name) > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreCardUse or event == fk.PreCardRespond then
      room:addPlayerMark(player, "@tongli-turn", 1)
    else
      local n = player:getMark(self.name)
      local use = {
        from = data.from,
        card = Fk:cloneCard(data.card.name),
        tos = data.tos,
        nullifiedTargets = data.nullifiedTargets,
      }
      for i = 1, n, 1 do  --TODO: modify this to tenyear's effect
        if not player.dead then
          room:doCardUseEffect(use)
        end
      end
      room:setPlayerMark(player, self.name, 0)
    end
  end,
}
local shezang = fk.CreateTriggerSkill{
  name = "shezang",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and (target == player or player.phase ~= Player.NotActive) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insert(cards, getCardByPattern(room, ".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
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

--王昶 冯方2022.8.27
--卞喜2022.9.6
--全惠解 胡昭 魏吕旷吕翔 黄权 孙茹 赵昂2022.9.17
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
      local cards = {}
      for i = 1, player:getMark("huishu-turn"), 1 do
        local id = getCardByPattern(room, ".|.|.|.|.|trick,equip", room.discard_pile)
        if id then
          table.removeOne(room.discard_pile, id)
          table.insert(cards, id)
        end
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
    local generals = Fk:getGeneralsRandomly(2, Fk:getAllGenerals(),
      table.map(room:getAllPlayers(), function(p) return p.general end),
      (function (p) return (p.kingdom ~= "wu" or p.gender ~= General.Female) end))
    local skills = {"Cancel"}
    for _, general in ipairs(generals) do
      for _, skill in ipairs(general.skills) do
        if skill.frequency ~= Skill.Wake and skill.frequency ~= Skill.Limited then
          table.insertIfNeed(skills, skill.name)
        end
      end
    end
    local choices = {}
    for i = 1, 2, 1 do
      local choice = room:askForChoice(player, skills, self.name)
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

  ["$huishu1"] = "心有慧镜，善解百般人意。",
  ["$huishu2"] = "袖着静淑，可揾夜阑之泪。",
  ["$yishu1"] = "此命由我，如织之数可易。",
  ["$yishu2"] = "易天定之数，结人定之缘。",
  ["$ligong1"] = "伴君离高墙，日暮江湖远。",
  ["$ligong2"] = "巍巍宫门开，自此不复来。",
  ["~quanhuijie"] = "妾有愧于陛下。",
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
      room:addPlayerMark(data.from, "AddMaxCards-turn", 1)
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
--牛辅 蔡阳2022.9.24
--张奋2022.9.29
--杜夔2022.10.9
--尹夫人2022.10.21
--管亥2022.11.
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
      (data.card.trueName == "slash" or (data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick)) and
      #table.filter(player.room:getOtherPlayers(player), function(p) return #p.player_cards[Player.Hand] >= #player.player_cards[Player.Hand] end) > 0
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Hand] >= #player.player_cards[Player.Hand] end)
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
--刘徽 陈珪 胡班2022.11.13
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
      room:addPlayerMark(target, "AddMaxCards-turn", 1)
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
--刘晔 王威 赵俨 雷薄 王烈2022.11.17
Fk:loadTranslationTable{
  ["ty__liuye"] = "刘晔",
  ["poyuan"] = "破垣",
  [":poyuan"] = "游戏开始时或回合开始时，若你的装备区里没有【霹雳车】，你可以将【霹雳车】置于装备区；若你的装备区里有【霹雳车】，你可以弃置一名其他角色至多两张牌。",
  ["huace"] = "画策",
  [":huace"] = "出牌阶段限一次，你可以将一张手牌当上一轮没有角色使用过的普通锦囊牌使用。",
}

Fk:loadTranslationTable{
  ["wangwei"] = "王威",
  ["ruizhan"] = "锐战",
  [":ruizhan"] = "其他的角色准备阶段，若其手牌数大于等于体力值，你可以与其进行一次拼点；若你赢或者拼点牌有【杀】，你视为对其使用一张【杀】；若两项均满足，此【杀】造成伤害后你获得其一张牌。",
  ["shilie"] = "示烈",
  [":shilie"] = "出牌阶段限一次，你可以选择一项：1.回复1点体力，然后将两张牌置于武将牌上（不足则全放，且总数不能超过游戏人数）；2.失去1点体力，然后获得武将牌上的两张牌。你死亡时，你可将武将牌上的牌交给除伤害来源外的一名其他角色。",
}

Fk:loadTranslationTable{
  ["ty__zhaoyan"] = "赵俨",
  ["funing"] = "抚宁",
  [":funing"] = "当你使用一张牌时，你可以摸两张牌然后弃置X张牌（X为此技能本回合发动次数）。",
  ["bingji"] = "秉纪",
  [":bingji"] = "出牌阶段每种花色限一次，若你的手牌均为同一花色，则你可以展示所有手牌（至少一张），然后视为对一名其他角色使用一张【杀】或一张【桃】。",
}

Fk:loadTranslationTable{
  ["leibo"] = "雷薄",
  ["silve"] = "私掠",
  [":silve"] = "游戏开始时，你选择一名其他角色为“私掠”角色。<br>"..
  "“私掠”角色造成伤害后，你可以获得受伤角色一张牌（每回合每名角色限一次）。<br>"..
  "“私掠”角色受到伤害后，除非你对伤害来源使用一张【杀】，否则你弃置一张手牌。",
  ["shuaijie"] = "衰劫",
  [":shuaijie"] = "限定技，出牌阶段，若你体力值与装备区里的牌均大于“私掠”角色或“私掠”角色已死亡，你可以减1点体力上限，然后选择一项：<br>"..
  "1.获得“私掠”角色至多3张牌；2.从牌堆获得三张类型不同的牌。<br>"..
  "然后“私掠”角色改为你。",
}
--丁尚涴
--卢弈 穆顺 神张飞 2022.12.17
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
      if player.phase == Player.Finish and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then
        local cards = player:getMark("fuxue-turn")
        if cards ~= 0 then
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
          table.insertIfNeed(player.tag[self.name], info.cardId)
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
local yaoyi_prohibit = fk.CreateProhibitSkill{
  name = "#yaoyi_prohibit",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
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
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.Damaged, fk.TargetConfirmed, fk.AfterCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.Damaged then
        return target:getMark("@shencai_chi") > 0
      elseif event == fk.TargetConfirmed then
        return target:getMark("@shencai_zhang") > 0 and data.card.trueName == "slash"
      elseif event == fk.AfterCardsMove then
        self.shencai_target = nil
        for _, move in ipairs(data) do
          if move.skillName ~= "shencai" and move.from ~= nil and player.room:getPlayerById(move.from):getMark("@shencai_tu") > 0 then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                self.shencai_target = move.from
                return true
              end
            end
          end
        end
      elseif event == fk.EventPhaseStart then
        return (target:getMark("@shencai_liu") > 0 and target.phase == Player.Finish) or
          (target:getMark("@shencai_si") > #player.room.alive_players and target.phase == Player.NotActive)
      end
    end
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
      if target.phase == Player.Finish then
        target:turnOver()
      else
      room:killPlayer({who = target.id})
      end
    end
  end,

  refresh_events = {fk.FinishJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and data.reason == "shencai"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
    local result = {}
    if table.contains({"peach", "analeptic", "silver_lion", "god_salvation"}, data.card.trueName) then
      table.insert(result, "@shencai_chi")
    end
    if data.card.sub_type == Card.SubtypeWeapon or data.card.name == "collateral" then
      table.insert(result, "@shencai_zhang")
    end
    if table.contains({"savage_assault", "archery_attack", "duel", "spear", "eight_diagram"}, data.card.trueName) then
      table.insert(result, "@shencai_tu")
    end
    if data.card.sub_type == Card.SubtypeDefensiveRide or data.card.sub_type == Card.SubtypeOffensiveRide or data.card.name == "snatch" or data.card.name == "supply_shortage" then
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
local shencai_maxcards = fk.CreateMaxCardsSkill {
  name = "#shencai_maxcards",
  correct_func = function(self, player)
    return -player:getMark("@shencai_si")
  end,
}
local xunshi = fk.CreateFilterSkill{
  name = "xunshi",
  card_filter = function(self, to_select, player)
    local names = {"savage_assault", "archery_attack", "amazing_grace", "god_salvation", "iron_chain"}
    return player:hasSkill(self.name) and table.contains(names, to_select.name)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("slash", Card.NoSuit, to_select.number)
    card.skillName = self.name
    return card
  end,
}
local xunshi_record = fk.CreateTriggerSkill{
  name = "#xunshi_record",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.suit == Card.NoSuit and data.tos ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not table.contains(data.tos[1], p.id) and not player:isProhibited(p, data.card) then
        table.insertIfNeed(targets, p.id)
      end
    end
    local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#xunshi-choose", self.name)
    self.cost_data = tos
    return true
  end,
  on_use = function(self, event, target, player, data)
    if player:getMark("xunshi") < 4 then
      player.room:addPlayerMark(player, "xunshi", 1)
    end
    player:addCardUseHistory(data.card.trueName, -1)
    if self.cost_data == nil then return end
    for _, p in ipairs(self.cost_data) do  --TODO: sort by action order
      table.insert(data.tos, {p})
    end
  end,
}
local xunshi_targetmod = fk.CreateTargetModSkill{
  name = "#xunshi_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if player:hasSkill(self.name) and card ~= nil and card.color == Card.NoColor and scope == Player.HistoryPhase then
      return 999
    end
  end,
  distance_limit_func =  function(self, player, skill, card)
    if player:hasSkill(self.name) and card.color == Card.NoColor then
      return 999
    end
  end,
}
shencai:addRelatedSkill(shencai_record)
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
  "若判定牌不包含以上内容，该角色获得一个“死”标记且手牌上限减少其身上“死”标记个数。然后，你获得其区域内一张牌。“死”标记个数大于场上存活人数的角色回合结束时，其直接死亡。",
  ["xunshi"] = "巡使",
  [":xunshi"] = "锁定技，你的多目标锦囊牌均视为无色的【杀】。你使用无色牌无距离和次数限制且可以额外指定任意个目标，然后修改“神裁”的发动次数（每次修改次数+1，至多为5）。",
  ["#shencai_record"] = "神裁",
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
--李异谢旌 袁姬 庞会 赵直 陈矫 朱建平 2022.12.22
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["mengchi"] = "蒙斥",
  [":mengchi"] = "锁定技，若你于当前回合内没有获得过牌，你：1.不能使用牌；2.进入横置状态时，取消之；3.受到普通伤害后，回复1点体力。",
  ["jiexing"] = "节行",
  [":jiexing"] = "当你的体力值变化后，你可以摸一张牌（此牌不计入你本回合的手牌上限）。",
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

Fk:loadTranslationTable{
  ["zhaozhi"] = "赵直",
  ["tongguan"] = "统观",
  [":tongguan"] = "一名角色的第一个回合开始时，你为其选择一项属性（每种属性至多被选择两次）。",
  ["mengjie"] = "梦解",
  [":mengjie"] = "一名角色的回合结束时，若其本回合完成了其属性对应内容，你执行对应效果。<br>"..
  "武勇：造成伤害；对一名其他角色造成1点伤害<br>"..
  "刚硬：回复体力或手牌数大于体力值；令一名角色回复1点体力<br>"..
  "多谋：摸牌阶段外摸牌；摸两张牌<br>"..
  "果决：弃置或获得其他角色的牌；弃置一名其他角色区域内的至多两张牌<br>"..
  "仁智：交给其他角色牌；令一名其他角色将手牌摸至体力上限（至多摸五张）",
  ["@mengjie_wuyong"] = "武勇",
  ["@mengjie_gangying"] = "刚硬",
  ["@mengjie_duomou"] = "多谋",
  ["@mengjie_guojue"] = "果决",
  ["@mengjie_renzhi"] = "仁智",
}

Fk:loadTranslationTable{
  ["chenjiao"] = "陈矫",
  ["xieshou"] = "协守",
  [":xieshou"] = "每回合限一次，当有角色受到伤害后，若你与其距离小于等于2，你可以令你的手牌上限-1，然后其选择一项：1.回复1点体力；2.将武将牌复原并摸两张牌。",
  ["qingyan"] = "清严",
  [":qingyan"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后：若你的手牌小于体力值，你可将手牌摸至体力上限；若你的手牌数不小于体力值，你可以弃置一张手牌令手牌上限+1。",
  ["qizi"] = "弃子",
  [":qizi"] = "锁定技，其他角色处于濒死状态时，若你与其距离大于2，你不能对其使用【桃】。",
}

local zhujianping = General(extension, "zhujianping", "qun", 3)
local xiangmian = fk.CreateActiveSkill{
  name = "xiangmian",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) < 1
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
    room:setPlayerMark(target, "@xiangmian", string.format("%s-%d",
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
    room:addPlayerMark(target, self.name, 1)
    if data.card:getSuitString() == target:getMark("xiangmian_suit") or target:getMark(self.name) == target:getMark("xiangmian_num") then
      room:setPlayerMark(target, "xiangmian_num", 0)
      room:setPlayerMark(target, "@xiangmian", 0)
      room:loseHp(target, target.hp, "xiangmian")
    end
  end,
}
local tianji = fk.CreateTriggerSkill{
  name = "tianji",
  events = {fk.FinishJudge},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = data.card
    local cards = {}
    table.insert(cards, getCardByPattern(room, ".|.|.|.|.|"..card:getTypeString()))
    table.insert(cards, getCardByPattern(room, ".|.|"..card:getSuitString()))
    table.insert(cards, getCardByPattern(room, ".|"..card.number))
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
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
  [":xiangmian"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定，当该角色使用判定花色的牌或使用第X张牌后（X为判定点数），其失去所有体力。每名其他角色限一次。",
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
        if ((#p.player_cards[Player.Hand] > p.hp) ~= (#player.player_cards[Player.Hand] > player.hp) or
          (#p.player_cards[Player.Hand] == p.hp) ~= (#player.player_cards[Player.Hand] == player.hp) or
          (#p.player_cards[Player.Hand] < p.hp) ~= (#player.player_cards[Player.Hand] < player.hp)) then
            room:loseHp(p, 1, self.name)
        end
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isWounded() and
          ((#p.player_cards[Player.Hand] > p.hp) and (#player.player_cards[Player.Hand] > player.hp) or
          (#p.player_cards[Player.Hand] == p.hp) and (#player.player_cards[Player.Hand] == player.hp) or
          (#p.player_cards[Player.Hand] < p.hp) and (#player.player_cards[Player.Hand] < player.hp)) then
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
    room:moveCards({
      ids = {id},
      from = effect.tos[1],
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,  --TODO: reason recast
    })
    target:drawCards(1, self.name)
  end,
}
gongsundu:addSkill(zhenze)
gongsundu:addSkill(anliao)
Fk:loadTranslationTable{
  ["gongsundu"] = "公孙度",
  ["zhenze"] = "震泽",
  [":zhenze"] = "弃牌阶段开始时，你可以选择一项：1.令所有手牌数和体力值的大小关系与你不同的角色失去1点体力；2.令所有手牌数和体力值的大小关系与你相同的角色回复1点体力。",
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