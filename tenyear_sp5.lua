local extension = Package("tenyear_sp5")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp5"] = "十周年专属5",
}

--程秉 孙狼 武安国 霍峻 孙寒华 薛灵芸 刘辟 关宁2023.1.18
Fk:loadTranslationTable{
  ["ty__sunhanhua"] = "孙寒华",
  ["huiling"] = "汇灵",
  [":huiling"] = "锁定技，弃牌堆中的红色牌数量多于黑色牌时，你使用牌时回复1点体力并获得一个“灵”标记；弃牌堆中黑色牌数量多于红色牌时，你使用牌时可弃置一名其他角色区域内的一张牌。",
  ["chongxu"] = "冲虚",
  [":chongxu"] = "锁定技，出牌阶段，若“灵”的数量不小于4，你可以失去〖汇灵〗，增加等量的体力上限，并获得〖踏寂〗和〖清荒〗。",
  ["taji"] = "踏寂",
  [":taji"] = "当你失去手牌时，根据此牌的失去方式执行以下效果：使用-此牌不能被响应；打出-摸一张牌；弃置-回复1点体力；其他-你下次对其他角色造成的伤害+1。",
  ["qinghuang"] = "清荒",
  [":qinghuang"] = "出牌阶段开始时，你可以减1点体力上限，然后你本回合失去牌时触发〖踏寂〗时随机额外获得一种效果。",
}
local xuelingyun = General(extension, "xuelingyun", "wei", 3, 3, General.Female)
local xialei = fk.CreateTriggerSkill{
  name = "xialei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove, fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player:getMark("xialei-turn") < 3 then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).color == Card.Red then
                return true
              end
            end
          end
        end
      else
        if target == player and data.card.color and data.card.color == Card.Red then
          return player.room:getCardArea(data.card) == Card.Processing
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3 - player:getMark("xialei-turn"))
    room:fillAG(player, ids)
    local chosen = room:askForAG(player, ids, false, self.name)
    table.removeOne(ids, chosen)
    room:obtainCard(player, chosen, false, fk.ReasonPrey)
    room:closeAG(player)
    if #ids > 0 then
      local choice = room:askForChoice(player, {"xialei_top", "xialei_bottom"}, self.name)
      local place = 1
      if choice == "xialei_top" then
        for i = #ids, 1, -1 do
          table.insert(room.draw_pile, 1, ids[i])
        end
      else
        for _, id in ipairs(ids) do
          table.insert(room.draw_pile, id)
        end
      end
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,
}
local anzhi = fk.CreateActiveSkill{
  name = "anzhi",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("anzhi-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      room:setPlayerMark(player, "xialei-turn", 0)
    elseif judge.card.color == Card.Black then
      room:addPlayerMark(player, "anzhi-turn", 1)
      local ids = player:getMark("anzhi_record-turn")
      if type(ids) ~= "table" then return end
      for _, id in ipairs(ids) do
        if room:getCardArea(id) ~= Card.DiscardPile then
          table.removeOne(ids, id)
        end
      end
      if #ids == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
        return p ~= room.current end), function(p) return p.id end), 1, 1, "#anzhi-choose", self.name)
      if #to > 0 then
        local get = {}
        room:fillAG(player, ids)
        while #get < 2 and #ids > 0 do
          local id = room:askForAG(player, ids, true)
          if id == nil then break end
          table.insert(get, id)
          table.removeOne(ids, id)
          room:takeAG(player, id, {player})
        end
        room:closeAG(player)
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = to[1],
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
    end
  end,
}
local anzhi_record = fk.CreateTriggerSkill{
  name = "#anzhi_record",
  anim_type = "support",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("anzhi-turn") == 0
  end,
  on_cost = function(self, event, target, player, data)
    player.room:askForUseActiveSkill(player, "anzhi", "#anzhi-invoke", true)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      local room = player.room
      local ids = player:getMark("anzhi_record-turn")
      if type(ids) ~= "table" then ids = {} end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
      room:setPlayerMark(player, "anzhi_record-turn", ids)
    end
  end,
}
anzhi:addRelatedSkill(anzhi_record)
xuelingyun:addSkill(xialei)
xuelingyun:addSkill(anzhi)
Fk:loadTranslationTable{
  ["xuelingyun"] = "薛灵芸",
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可观看牌堆顶的三张牌，然后你获得一张并可将其他牌置于牌堆底，你本回合观看牌数-1。",
  ["anzhi"] = "暗织",
  [":anzhi"] = "出牌阶段或当你受到伤害后，你可以进行一次判定，若结果为：红色，重置〖霞泪〗；黑色，你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌，且你本回合不能再发动此技能。",
  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#anzhi-invoke"] = "你想发动技能“暗织”吗？",
  ["#anzhi-choose"] = "暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌",

  ["$xialei1"] = "采霞揾晶泪，沾我青衫湿。",
  ["$xialei2"] = "登车入宫墙，垂泪凝如瑙。",
  ["$anzhi1"] = "深闱行彩线，唯手熟尔。",
  ["$anzhi2"] = "星月独照人，何谓之暗？",
  ["~xuelingyun"] = "寒月隐幕，难作衣裳。",
}
--神张角 周宣2023.2.25
--local godzhangjiao = General(extension, "godzhangjiao", "god", 3)
local yizhao = fk.CreateTriggerSkill{
  name = "yizhao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.number
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1 = tostring(player:getMark("@huang"))
    room:addPlayerMark(player, "@huang", math.min(data.card.number, 184 - player:getMark("@huang")))
    local n2 = tostring(player:getMark("@huang"))
    if #n1 == 1 then
      if #n2 == 1 then return end
    else
      if n1:sub(#n1 - 1, #n1 - 1) == n2:sub(#n2 - 1, #n2 - 1) then return end
    end
    local x = n2:sub(#n2 - 1, #n2 - 1)
    if x == 0 then x = 10 end  --yes, tenyear is so strange
    local card = {getCardByPattern(room, ".|"..x)}
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local sijun = fk.CreateTriggerSkill{
  name = "sijun",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and player:getMark("@huang") > #player.room.draw_pile
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@huang", 0)
    room:shuffleDrawPile()
    local cards = {}
    local total = 36
    local i = 0
    while total > 0 and i < 999 do
      local num = math.random(1, math.min(13, total))
      local id = getCardByPattern(room, ".|"..tostring(num))
      if id ~= nil then
        table.insert(cards, id)
        total = total - num
      end
      i = i + 1
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
--godzhangjiao:addSkill(yizhao)
--godzhangjiao:addSkill(sanshou)
--godzhangjiao:addSkill(sijun)
--godzhangjiao:addSkill(tianjie)
Fk:loadTranslationTable{
  ["godzhangjiao"] = "神张角",
  ["yizhao"] = "异兆",
  [":yizhao"] = "锁定技，当你使用或打出一张牌后，获得等同于此牌点数的“黄”标记，然后若“黄”标记数的十位数变化，你随机获得牌堆中一张点数为变化后十位数的牌。",
  ["sanshou"] = "三首",
  [":sanshou"] = "当你受到伤害时，你可以亮出牌堆顶的三张牌，若其中有本回合所有角色均未使用过的牌的类型，防止此伤害。",
  ["sijun"] = "肆军",
  [":sijun"] = "准备阶段，若“黄”标记数大于牌堆里的牌数，你可以移去所有“黄”标记并洗牌，然后获得随机张点数之和为36的牌。",
  ["tianjie"] = "天劫",
  [":tianjie"] = "一名角色的回合结束时，若本回合牌堆进行过洗牌，你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】的数量且至少为1）。",
  ["@huang"] = "黄",
}

local zhouxuan = General(extension, "zhouxuan", "wei", 3)
local wumei = fk.CreateTriggerSkill{
  name = "wumei",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from == Player.RoundStart and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function(p)
      return p.id end), 1, 1, "#wumei-choose", self.name)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      room:setPlayerMark(p, "wumei_hp", p.hp)
    end
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "wumei_extra", 1)
    to:gainAnExtraTurn()
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("wumei_extra") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "wumei_extra", 0)
    for _, p in ipairs(room:getAlivePlayers()) do
      p.hp = p:getMark("wumei_hp")
      room:broadcastProperty(p, "hp")
      room:setPlayerMark(p, "wumei_hp", 0)
    end
  end,
}
local zhanmeng = fk.CreateTriggerSkill{
  name = "zhanmeng",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i).."-turn") == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    self.cost_data = {}
    if player:getMark("zhanmeng1-turn") == 0 and table.contains(room:getTag("zhanmeng1"), data.card.trueName) then
      table.insert(choices, "zhanmeng1")
    end
    if player:getMark("zhanmeng2-turn") == 0 then
      table.insert(choices, "zhanmeng2")
    end
    local tos = {}
    if player:getMark("zhanmeng3-turn") == 0 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p:getCardIds{Player.Hand, Player.Equip} > 1 then
          table.insertIfNeed(choices, "zhanmeng3")
          table.insert(tos, p)
        end
      end
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "Cancel" then return end
    self.cost_data[1] = choice
    if choice == "zhanmeng3" then
      local p = room:askForChoosePlayers(player, table.map(tos, function(p)
        return p.id end), 1, 1, "#zhanmeng-choose", self.name)
      if #p > 0 then
        self.cost_data[2] = p[1]
      end
    end
    return #self.cost_data > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data[1]
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "zhanmeng1" then
      local card = {getCardByPattern(room, "nondamage_card")}
      if #card > 0 then
        room:moveCards({
          ids = card,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif choice == "zhanmeng2" then
      room:setPlayerMark(player, "zhanmeng2_invoke", data.card.trueName)
    elseif choice == "zhanmeng3" then
      local p = room:getPlayerById(self.cost_data[2])
      local discards = room:askForDiscard(p, 2, 2, true, self.name, false)
      if Fk:getCardById(discards[1]).number + Fk:getCardById(discards[2]).number > 10 then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local zhanmeng_record = fk.CreateTriggerSkill{
  name = "#zhanmeng_record",

  refresh_events = {fk.CardUsing, fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.CardUsing then
        return true
      else
        return player.phase == Player.Start
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      local zhanmeng2 = room:getTag("zhanmeng2") or {}
      if not table.contains(zhanmeng2, data.card.trueName) then
        table.insert(zhanmeng2, data.card.trueName)
        room:setTag("zhanmeng2", zhanmeng2)
      end
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("zhanmeng2_get-turn") == data.card.trueName then
          room:setPlayerMark(p, "zhanmeng2_get-turn", 0)
          local card = {getCardByPattern(room, "damage_card")}
          if #card > 0 then
            room:moveCards({
              ids = card,
              to = p.id,
              toArea = Card.PlayerHand,
              moveReason = fk.ReasonPrey,
              proposer = p.id,
              skillName = "zhanmeng",
            })
          end
        end
      end
    else
      local zhanmeng2 = room:getTag("zhanmeng2") or {}
      room:setTag("zhanmeng1", zhanmeng2)  --cards used in last turn
      zhanmeng2 = {}
      room:setTag("zhanmeng2", zhanmeng2)  --cards used in current turn
      for _, p in ipairs(room:getAlivePlayers()) do
        if type(p:getMark("zhanmeng2_invoke")) == "string" then
          room:setPlayerMark(p, "zhanmeng2_get-turn", p:getMark("zhanmeng2_invoke"))
          room:setPlayerMark(p, "zhanmeng2_invoke", 0)
        end
      end
    end
  end,
}
zhanmeng:addRelatedSkill(zhanmeng_record)
zhouxuan:addSkill(wumei)
zhouxuan:addSkill(zhanmeng)
Fk:loadTranslationTable{
  ["zhouxuan"] = "周宣",
  ["wumei"] = "寤寐",
  [":wumei"] = "每轮限一次，回合开始前，你可以令一名角色执行一个额外的回合：该回合结束时，将所有存活角色的体力值调整为此额外回合开始时的数值。",
  ["zhanmeng"] = "占梦",
  [":zhanmeng"] = "你使用牌时，可以执行以下一项（每回合每项各限一次）：<br>"..
  "1.上一回合内，若没有同名牌被使用，你获得一张非伤害牌。<br>"..
  "2.下一回合内，当同名牌首次被使用后，你获得一张伤害牌。<br>"..
  "3.令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害。",
  ["#wumei-choose"] = "寤寐: 你可以令一名角色执行一个额外的回合",
  ["zhanmeng1"] = "你获得一张非伤害牌",
  ["zhanmeng2"] = "下一回合内，当同名牌首次被使用后，你获得一张伤害牌",
  ["zhanmeng3"] = "令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-choose"] = "占梦: 令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",

  ["$wumei1"] = "大梦若期，皆付一枕黄粱。",
  ["$wumei2"] = "日所思之，故夜所梦之。",
  ["$zhanmeng1"] = "梦境缥缈，然有迹可占。",
  ["$zhanmeng2"] = "万物有兆，唯梦可卜。",
  ["~zhouxuan"] = "人生如梦，假时亦真。",
}
--杨彪 傅肜傅佥 向朗 孙桓 杨弘 芮姬 桥蕤 秦朗 郑浑2023.3.11
local qinlang = General(extension, "qinlang", "wei", 4)
local haochong = fk.CreateTriggerSkill{
  name = "haochong",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #player.player_cards[Player.Hand] ~= player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Hand] - player:getMaxCards()
    if n > 0 then
      if #player.room:askForDiscard(player, n, n, false, self.name, true, ".", "#haochong-discard:::"..n) then
        self.cost_data = n
        return true
      end
    else
      if player.room:askForSkillInvoke(player, self.name, nil, "#haochong-draw:::"..player:getMaxCards()) then
        self.cost_data = n
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data > 0 then
      room:addPlayerMark(player, "AddMaxCards", 1)
    else
      player:drawCards(math.min(-self.cost_data, 5), self.name)
      if player:getMaxCards() > 0 then  --不允许减为负数
        room:addPlayerMark(player, "MinusMaxCards", 1)
      end
    end
  end,
}
local jinjin = fk.CreateTriggerSkill{
  name = "jinjin",
  anim_type = "drawcard",
  events = {fk.Damage, Fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMaxCards() ~= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jinjin-invoke::"..data.from.id..":"..player:getMaxCards())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(player:getMaxCards() - player.hp)
    room:setPlayerMark(player, "AddMaxCards", 0)
    room:setPlayerMark(player, "AddMaxCards-turn", 0)
    room:setPlayerMark(player, "MinusMaxCards", 0)
    room:setPlayerMark(player, "MinusMaxCards-turn", 0)
    if data.from and not data.from.dead then
      local x = #room:askForDiscard(data.from, 1, n, true, self.name, false, ".", "#jinjin-discard:"..player.id.."::"..n)
      if x < n then
        player:drawCards(n - x, self.name)
      end
    end
  end,
}
qinlang:addSkill(haochong)
qinlang:addSkill(jinjin)
Fk:loadTranslationTable{
  ["qinlang"] = "秦朗",
  ["haochong"] = "昊宠",
  [":haochong"] = "当你使用一张牌后，你可以将手牌调整至手牌上限（最多摸五张），然后若你以此法：获得牌，你的手牌上限-1；失去牌，你的手牌上限+1。",
  ["jinjin"] = "矜谨",
  [":jinjin"] = "每回合限一次，当你造成或受到伤害后，你可以将你的手牌上限重置为当前体力值。若如此做，伤害来源可以弃置至多X张牌（X为你因此变化的手牌上限数且至少为1），然后其每少弃置一张，你便摸一张牌。",
  ["#haochong-discard"] = "昊宠：你可以将手牌弃至手牌上限（弃置%arg张），然后手牌上限+1",
  ["#haochong-draw"] = "昊宠：你可以将手牌摸至手牌上限（当前手牌上限%arg，最多摸五张），然后手牌上限-1",
  ["#jinjin-invoke"] = "矜谨：你可将手牌上限（当前为%arg）重置为体力值，令 %dest 弃至多等量的牌",
  ["#jinjin-discard"] = "矜谨：弃置1~%arg张牌，每少弃置一张 %src 便摸一张牌",

  ["$haochong1"] = "幸得义父所重，必效死奉曹。",
  ["$haochong2"] = "朗螟蛉之子，幸隆曹氏厚恩。",
  ["$jinjin1"] = "螟蛉终非麒麟，不可气盛自矜。",
  ["$jinjin2"] = "我姓非曹，可敬人，不可欺人。",
  ["~qinlang"] = "二姓之人，死无其所。",
}
--孟节 孙资刘放 2023.3.19
--裴元绍 张楚 董绾 袁胤 谢灵毓 高翔 笮融 周善 2023.4.19
local peiyuanshao = General(extension, "peiyuanshao", "qun", 4)
local moyu = fk.CreateActiveSkill{
  name = "moyu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("moyu-turn") == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target ~= Self and target:getMark("moyu-turn") == 0 and not target:isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    room:obtainCard(player, id, false, fk.ReasonPrey)
    room:addPlayerMark(target, "moyu-turn", 1)
    local use = room:askForUseCard(target, "slash", "slash", "#moyu-use::"..player.id..":"..player:usedSkillTimes(self.name), true, {must_targets = {player.id}})
    if use then
      use.additionalDamage = (use.additionalDamage or 0) + player:usedSkillTimes(self.name) - 1
      use.card.extra_data = use.card.extra_data or {}
      table.insert(use.card.extra_data, self.name)
      room:useCard(use)
    end
  end,
}
local moyu_record = fk.CreateTriggerSkill{
  name = "#moyu_record",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.extra_data and table.contains(data.card.extra_data, "moyu")
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "moyu-turn", 1)
  end,
}
moyu:addRelatedSkill(moyu_record)
peiyuanshao:addSkill(moyu)
Fk:loadTranslationTable{
  ["peiyuanshao"] = "裴元绍",
  ["moyu"] = "没欲",
  [":moyu"] = "出牌阶段每名角色限一次，你可以获得一名其他角色区域内的一张牌，然后该角色可以选择是否对你使用一张伤害值为X的【杀】（X为本回合本技能发动次数），若此【杀】对你造成了伤害，本技能于本回合失效。",
  ["#moyu-use"] = "没欲：你可以对 %dest 使用一张【杀】，伤害基数为%arg",
}

local zhangchu = General(extension, "zhangchu", "qun", 3, 3, General.Female)
local jizhong = fk.CreateActiveSkill{
  name = "jizhong",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(2, self.name)
    if target:getMark("@@zhangchu_xinzhong") > 0 then
      if #target.player_cards[Player.Hand] <= 3 then
        target:throwAllCards("h")
      else
        room:askForDiscard(target, 3, 3, false, self.name, false, ".", "#jizhong-discard2")
      end
    else
      if #target.player_cards[Player.Hand] < 3 then
        room:setPlayerMark(target, "@@zhangchu_xinzhong", 1)
      else
        local cards = room:askForDiscard(target, 3, 3, false, self.name, true, ".", "#jizhong-discard1")
        if #cards == 0 then
          room:addPsetPlayerMarklayerMark(target, "@@zhangchu_xinzhong", 1)
        end
      end
    end
  end,
}
local jucheng = fk.CreateTriggerSkill{
  name = "jucheng",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name) == 0 and
      ((data.card.type == Card.TypeTrick and data.card.sub_type ~= Card.SubtypeDelayedTrick) or
      (data.card.type == Card.TypeBasic and data.card.color == Card.Black)) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to.dead then return end
    if to:getMark("@@zhangchu_xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@zhangchu_xinzhong") > 0 then
          return room:askForSkillInvoke(player, self.name, data, "#jucheng-use")
        end
      end
    else
      if to:isAllNude() then return end
      return room:askForSkillInvoke(player, self.name, data, "#jucheng-get")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to:getMark("@@zhangchu_xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@zhangchu_xinzhong") > 0 then
          if to.dead or p.dead then return end
          room:useVirtualCard(data.card.name, nil, p, to, self.name, true)
        end
      end
    else
      local id = room:askForCardChosen(player, to, "hej", self.name)
      room:obtainCard(player, id, false, fk.ReasonPrey)
    end
  end,
}
local guangshi = fk.CreateTriggerSkill{
  name = "guangshi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Start and
      table.every(player.room:getOtherPlayers(player), function (p)
        return p:getMark("@@zhangchu_xinzhong") > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
    player:drawCards(2, self.name)
  end,
}
zhangchu:addSkill(jizhong)
zhangchu:addSkill(jucheng)
zhangchu:addSkill(guangshi)
Fk:loadTranslationTable{
  ["zhangchu"] = "张楚",
  ["jizhong"] = "集众",
  [":jizhong"] = "出牌阶段限一次，你可以令一名其他角色摸两张牌，然后若其不是“信众”，则其选择一项：1.成为“信众”；2.弃置三张手牌；若其是“信众”，则其弃置三张手牌（不足则全弃）。",
  ["jucheng"] = "聚逞",
  [":jucheng"] = "每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；是“信众”，你可以获得其区域内的一张牌。",
  ["guangshi"] = "光噬",
  [":guangshi"] = "锁定技，准备阶段，若所有其他角色均是“信众”，你失去1点体力并摸两张牌。",
  ["@@zhangchu_xinzhong"] = "信众",
  ["#jizhong-discard1"] = "集众：你需弃置三张手牌，否则成为“信众”",
  ["#jizhong-discard2"] = "集众：你需弃置三张手牌",
  ["#jucheng-use"] = "聚逞：你可以令所有“信众”视为对其使用此牌",
  ["#jucheng-get"] = "聚逞：你可以获得其区域内一张牌",
}

local dongwan = General(extension, "dongwan", "qun", 3, 3, General.Female)
local shengdu = fk.CreateTriggerSkill{
  name = "shengdu",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from == Player.RoundStart
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local p = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#shengdu-choose", self.name)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,

  refresh_events = {fk.AfterDrawNCards},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local n = target:getMark(self.name)
    player.room:setPlayerMark(target, self.name, 0)
    for i = 1, n, 1 do
      player:drawCards(data.n, self.name)  --yes! do n times!
    end
  end,
}
local xianjiao = fk.CreateActiveSkill{
  name = "xianjiao",
  anim_type = "offensive",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Equip then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return Fk:getCardById(to_select).color ~= Fk:getCardById(selected[1]).color
      else
        return false
      end
    end
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:useVirtualCard("slash", effect.cards, player, target, self.name, false)
  end,
}
local xianjiao_record = fk.CreateTriggerSkill{
  name = "#xianjiao_record",

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, "xianjiao")
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "xianjiao")
    else
      local room = player.room
      for _, p in ipairs(TargetGroup:getRealTargets(data.tos)) do
        local to = room:getPlayerById(p)
        if data.card.extra_data and table.contains(data.card.extra_data, "xianjiao") then
          room:loseHp(to, 1, self.name)
        else
          room:addPlayerMark(to, "shengdu", 1)
        end
      end
    end
  end,
}
xianjiao:addRelatedSkill(xianjiao_record)
dongwan:addSkill(shengdu)
dongwan:addSkill(xianjiao)
Fk:loadTranslationTable{
  ["dongwan"] = "董绾",
  ["shengdu"] = "生妒",
  [":shengdu"] = "回合开始时，你可以选择一名其他角色，该角色下个摸牌阶段摸牌后，你摸等量的牌。",
  ["xianjiao"] = "献绞",
  [":xianjiao"] = "出牌阶段限一次，你可以将两张颜色不同的手牌当无距离和次数限制的【杀】使用。若此【杀】：造成伤害，则目标角色失去1点体力；没造成伤害，则你对目标角色发动一次〖生妒〗。",
  ["#shengdu-choose"] = "生妒：选择一名角色，其下次摸牌阶段摸牌后，你摸等量的牌",
}

local xielingyu = General(extension, "xielingyu", "wu", 3, 3, General.Female)
local yuandi = fk.CreateTriggerSkill{
  name = "yuandi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and target:getMark("yuandi-phase") == 0 then
      player.room:addPlayerMark(target, "yuandi-phase", 1)
      if data.tos then
        for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
          if id ~= target.id then
            return
          end
        end
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yuandi-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"yuandi_draw"}
    if not target:isKongcheng() then
      table.insert(choices, 1, "yuandi_discard")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "yuandi_discard" then
      local id = room:askForCardChosen(player, target, "h", self.name)
      room:throwCard({id}, self.name, target, player)
    else
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    end
  end,
}
local xinyou = fk.CreateActiveSkill{
  name = "xinyou",
  anim_type = "drawcard",
  can_use = function(self, player)
    return (player:isWounded() or #player.player_cards[Player.Hand] < player.maxHp) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    return false
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name
      })
      room:addPlayerMark(player, "xinyou_recover-turn", 1)
    end
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, self.name)
      if n > 1 then
        room:addPlayerMark(player, "xinyou_draw-turn", 1)
      end
    end
  end
}
local xinyou_record = fk.CreateTriggerSkill{
  name = "#xinyou_record",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      ((player:getMark("xinyou_recover-turn") > 0 and not player:isNude()) or player:getMark("xinyou_draw-turn") > 0)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("xinyou_recover-turn") > 0 and not player:isNude() then
      if #player:getCardIds{Player.Hand, Player.Equip} < 3 then
        player:throwAllCards("he")
      else
        room:askForDiscard(player, 2, 2, true, "xinyou", false)
      end
    end
    if player:getMark("xinyou_draw-turn") > 0 then
      room:loseHp(player, 1, "xinyou")
    end
  end,
}
xinyou:addRelatedSkill(xinyou_record)
xielingyu:addSkill(yuandi)
xielingyu:addSkill(xinyou)
Fk:loadTranslationTable{
  ["xielingyu"] = "谢灵毓",
  ["yuandi"] = "元嫡",
  [":yuandi"] = "其他角色于其出牌阶段使用第一张牌时，若此牌没有选择除该角色以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.你与其各摸一张牌。",
  ["xinyou"] = "心幽",
  [":xinyou"] = "出牌阶段限一次，你可以回满体力并将手牌摸至体力上限。若你因此摸超过1张牌，结束阶段你失去1点体力；若你因此回复体力，结束阶段你弃置两张牌。",
  ["#yuandi-invoke"] = "元嫡：你可以弃置 %dest 的一张手牌或与其各摸一张牌",
  ["yuandi_discard"] = "弃置其一张手牌",
  ["yuandi_draw"] = "你与其各摸一张牌",
  ["#xinyou_record"] = "心幽",

  ["$yuandi1"] = "此生与君为好，共结连理。",
  ["$yuandi2"] = "结发元嫡，其情唯衷孙郎。",
  ["$xinyou1"] = "我有幽月一斛，可醉十里春风。",
  ["$xinyou2"] = "心在方外，故而不闻市井之声。",
  ["~xielingyu"] = "翠瓦红墙处，最折意中人。",
}
return extension
