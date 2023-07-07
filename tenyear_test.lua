local extension = Package("tenyear_test")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_test"] = "十周年-测试服",
  ["wm"] = "武",
  ["mu"] = "乐",
}

--嵇康 曹不兴

local yuanji = General(extension, "yuanji", "wu", 3, 3, General.Female)
--[[local mengchi = fk.CreateTriggerSkill{
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
}]]--
local fangdu = fk.CreateTriggerSkill{
  name = "fangdu",
  anim_type = "masochism",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and ((player:getMark("fangdu1-round") == 0 and data.damageType == fk.NormalDamage) or
    (player:getMark("fangdu2-round") == 0 and data.damageType ~= fk.NormalDamage))
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.NormalDamage then
      room:setPlayerMark(player, "fangdu1-round", 1)
      if not player:isWounded() then return end
    else
      room:setPlayerMark(player, "fangdu2-round", 1)
      if not data.from or data.from == player or data.from:isKongcheng() then return end
    end
    if player.phase ~= Player.NotActive then return end
    self:doCost(event, target, player, data)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.NormalDamage then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    else
      local id = table.random(data.from.player_cards[Player.Hand])
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end
}
local jiexing = fk.CreateTriggerSkill{
  name = "jiexing",
  anim_type = "drawcard",
  events = {fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
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
--mengchi:addRelatedSkill(mengchi_prohibit)
jiexing:addRelatedSkill(jiexing_maxcards)
--yuanji:addSkill(mengchi)
yuanji:addSkill(fangdu)
yuanji:addSkill(jiexing)
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["fangdu"] = "芳妒",
  [":fangdu"] = "锁定技，你的回合外，你每轮第一次受到普通伤害后回复1点体力，你每轮第一次受到属性伤害后随机获得伤害来源一张手牌。",
  ["jiexing"] = "节行",
  [":jiexing"] = "当你的体力值变化后，你可以摸一张牌，此牌不计入你本回合的手牌上限。",
  ["#jiexing-invoke"] = "节行：你可以摸一张牌，此牌本回合不计入手牌上限",

  ["$fangdu1"] = "浮萍却红尘，何意染是非？",
  ["$fangdu2"] = "我本无意争春，奈何群芳相妒。",
  ["$jiexing1"] = "女子有节，安能贰其行？",
  ["$jiexing2"] = "坐收雨露，皆为君恩。",
  ["~yuanji"] = "妾本蒲柳，幸荣君恩……",
}

Fk:loadTranslationTable{
  ["ty__sunhanhua"] = "孙寒华",
  ["huiling"] = "汇灵",
  [":huiling"] = "锁定技，弃牌堆中的红色牌数量多于黑色牌时，你使用牌时回复1点体力并获得一个“灵”标记；"..
  "弃牌堆中黑色牌数量多于红色牌时，你使用牌时可弃置一名其他角色区域内的一张牌。",
  ["chongxu"] = "冲虚",
  [":chongxu"] = "锁定技，出牌阶段，若“灵”的数量不小于4，你可以失去〖汇灵〗，增加等量的体力上限，并获得〖踏寂〗和〖清荒〗。",
  ["taji"] = "踏寂",
  [":taji"] = "当你失去手牌时，根据此牌的失去方式执行以下效果：使用-此牌不能被响应；打出-摸一张牌；弃置-回复1点体力；其他-你下次对其他角色造成的伤害+1。",
  ["qinghuang"] = "清荒",
  [":qinghuang"] = "出牌阶段开始时，你可以减1点体力上限，然后你本回合失去牌时触发〖踏寂〗时随机额外获得一种效果。",
}

-- 孙桓

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
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    room:addPlayerMark(target, "moyu-turn", 1)
    local use = room:askForUseCard(target, "slash", "slash", "#moyu-use::"..player.id..":"..player:usedSkillTimes(self.name), true,
      {must_targets = {player.id}, bypass_distances = true, bypass_times = true})
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
  [":moyu"] = "出牌阶段每名角色限一次，你可以获得一名其他角色区域内的一张牌，然后该角色可以对你使用一张无距离限制且伤害值为X的【杀】"..
  "（X为本回合本技能发动次数），若此【杀】对你造成了伤害，本技能于本回合失效。",
  ["#moyu-use"] = "没欲：你可以对 %dest 使用一张【杀】，伤害基数为%arg",
}

local zhangchu = General(extension, "zhangchu", "qun", 3, 3, General.Female)
local jizhong = fk.CreateActiveSkill{
  name = "jizhong",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
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
    if target:getMark("@@xinzhong") > 0 then
      if #target.player_cards[Player.Hand] <= 3 then
        target:throwAllCards("h")
      else
        room:askForDiscard(target, 3, 3, false, self.name, false, ".", "#jizhong-discard2")
      end
    else
      if #target.player_cards[Player.Hand] < 3 then
        room:setPlayerMark(target, "@@xinzhong", 1)
      else
        local cards = room:askForDiscard(target, 3, 3, false, self.name, true, ".", "#jizhong-discard1")
        if #cards == 0 then
          room:setPlayerMark(target, "@@xinzhong", 1)
        end
      end
    end
  end,
}
local jucheng = fk.CreateTriggerSkill{
  name = "jucheng",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      (data.card:isCommonTrick() or (data.card.type == Card.TypeBasic and data.card.color == Card.Black)) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if to.dead then return end
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
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
    if to:getMark("@@xinzhong") == 0 then
      for _, p in ipairs(room:getOtherPlayers(to)) do
        if p:getMark("@@xinzhong") > 0 then
          if to.dead or p.dead then return end
          room:useVirtualCard(data.card.name, nil, p, to, self.name, true)
        end
      end
    else
      local id = room:askForCardChosen(player, to, "hej", self.name)
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
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
        return p:getMark("@@xinzhong") > 0
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
  [":jizhong"] = "出牌阶段限一次，你可以令一名其他角色摸两张牌，然后若其不是“信众”，则其选择一项：1.成为“信众”；"..
  "2.弃置三张手牌；若其是“信众”，则其弃置三张手牌（不足则全弃）。",
  ["jucheng"] = "聚逞",
  [":jucheng"] = "每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；"..
  "是“信众”，你可以获得其区域内的一张牌。",
  ["guangshi"] = "光噬",
  [":guangshi"] = "锁定技，准备阶段，若所有其他角色均是“信众”，你失去1点体力并摸两张牌。",
  ["@@xinzhong"] = "信众",
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
      return p.id end), 1, 1, "#shengdu-choose", self.name, true)
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
  [":xianjiao"] = "出牌阶段限一次，你可以将两张颜色不同的手牌当无距离和次数限制的【杀】使用。"..
  "若此【杀】：造成伤害，则目标角色失去1点体力；没造成伤害，则你对目标角色发动一次〖生妒〗。",
  ["#shengdu-choose"] = "生妒：选择一名角色，其下次摸牌阶段摸牌后，你摸等量的牌",
}

--袁胤 高翔 桓范 孟优 陈泰 孙綝 孙瑜 郤正 刘宠骆俊 乐綝 张曼成

local zhugeliang = General(extension, "wm__zhugeliang", "shu", 4, 7)
local jincui = fk.CreateTriggerSkill{
  name = "jincui",
  anim_type = "control",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.EventPhaseStart, fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name) and player:getHandcardNum() < 7
    elseif event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self.name) and player.phase == Player.Start
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:broadcastSkillInvoke(self.name)
      local n = 7 - player:getHandcardNum()
      if n > 0 then
        player:drawCards(n, self.name)
      end
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name)
      room:broadcastSkillInvoke(self.name)
      local n = 0
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == 7 then
          n = n + 1
        end
      end
      n = math.max(n, 1)
      if player.hp > n then
        room:loseHp(player, player.hp - n, self.name)
      elseif player.hp < n then
        room:recover({
          who = player,
          num = math.min(n - player.hp, player:getLostHp()),
          recoverBy = player,
          skillName = self.name
        })
      end
      room:askForGuanxing(player, room:getNCards(player.hp))
    end
  end,
}
local qingshi = fk.CreateTriggerSkill{
  name = "qingshi",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:getMark("@@qingshi-turn") == 0 and
      table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end) and
      (player:getMark("@$qingshi-turn") == 0 or not table.contains(player:getMark("@$qingshi-turn"), data.card.trueName))
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel", "qingshi2", "qingshi3"}
    if data.card.is_damage_card and data.tos then
      table.insert(choices, 2, "qingshi1")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#qingshi-invoke:::"..data.card:toLogString())
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$qingshi-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "@$qingshi-turn", mark)
    if self.cost_data == "qingshi1" then
      local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1,
        "#qingshi1-choose:::"..data.card:toLogString(), self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(TargetGroup:getRealTargets(data.tos))
      end
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi = to
    elseif self.cost_data == "qingshi2" then
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local tos = room:askForChoosePlayers(player, targets, 1, 10, "#qingshi2-choose", self.name, false)
      if #tos == 0 then
        tos = table.random(targets, 1)
      end
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    elseif self.cost_data == "qingshi3" then
      player:drawCards(3, self.name)
      room:setPlayerMark(player, "@@qingshi-turn", 1)
    end
  end,

  refresh_events = {fk.DamageCaused},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        return use.extra_data and use.extra_data.qingshi and data.to.id == use.extra_data.qingshi
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local zhizhe = fk.CreateActiveSkill{
  name = "zhizhe",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and
      (card.type == Card.TypeBasic or card:isCommonTrick())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = nil
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id).name == "zhizhe_token" then
        card = id
        break
      end
    end
    if card then
      room:moveCards({
        ids = {card},
        fromArea = Card.Void,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
      local c = Fk:getCardById(effect.cards[1])
      room:setCardMark(Fk:getCardById(card), self.name, {c.name, c.suit, c.number})
      room:setPlayerMark(player, self.name, card)
    end
  end
}
local zhizhe_filter = fk.CreateFilterSkill{
  name = "#zhizhe_filter",
  mute = true,
  card_filter = function(self, card, player)
    return card:getMark("zhizhe") ~= 0
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card:getMark("zhizhe")[1], card:getMark("zhizhe")[2], card:getMark("zhizhe")[3])
  end,
}
--[[local zhizhe_maxcards = fk.CreateMaxCardsSkill{
  name = "#zhizhe_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("zhizhe") ~= 0 and player:getMark("zhizhe") == card:getEffectiveId()
  end,
}]]--
local zhizhe_trigger = fk.CreateTriggerSkill{
  name = "#zhizhe_trigger",
  mute = true,
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card:getMark("zhizhe") ~= 0 and player:getMark("zhizhe") == data.card:getEffectiveId() and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, fk.ReasonJustMove)
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local id = 0
    for i = #data, 1, -1 do
      local move = data[i]
      if move.toArea ~= Card.Processing and move.toArea ~= Card.Void then
        for j = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[j]
          if Fk:getCardById(info.cardId, true):getMark("zhizhe") ~= 0 then
            if move.to and move.toArea == Card.PlayerHand and player.room:getPlayerById(move.to):getMark("zhizhe") == info.cardId then
              --continue
            else
              id = info.cardId
              table.removeOne(move.moveInfo, info)
            end
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
local zhizhe_prohibit = fk.CreateProhibitSkill{
  name = "#zhizhe_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("zhizhe") ~= 0 and player:usedSkillTimes("#zhizhe_trigger", Player.HistoryTurn) > 0 and
      player:getMark("zhizhe") == card:getEffectiveId()
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("zhizhe") ~= 0 and player:usedSkillTimes("#zhizhe_trigger", Player.HistoryTurn) > 0 and
      player:getMark("zhizhe") == card:getEffectiveId()
  end,
}
zhizhe:addRelatedSkill(zhizhe_filter)
--zhizhe:addRelatedSkill(zhizhe_maxcards)
zhizhe:addRelatedSkill(zhizhe_trigger)
zhizhe:addRelatedSkill(zhizhe_prohibit)
zhugeliang:addSkill(jincui)
zhugeliang:addSkill(qingshi)
zhugeliang:addSkill(zhizhe)
Fk:loadTranslationTable{
  ["wm__zhugeliang"] = "诸葛亮",
  ["jincui"] = "尽瘁",
  [":jincui"] = "锁定技，游戏开始时，你将手牌补至7张。准备阶段，你的体力值调整为与牌堆中点数为7的游戏牌数量相等（至少为1）。"..
  "然后你观看牌堆顶X张牌，将这些牌以任意顺序放回牌堆顶或牌堆底（X为你的体力值）",
  ["qingshi"] = "情势",
  [":qingshi"] = "当你于出牌阶段内使用一张牌时（每种牌名每回合限一次），若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1："..
  "2.令任意名其他角色各摸一张牌；3.摸三张牌，然后此技能本回合失效。",
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张（基本牌或普通锦囊牌）手牌。当你使用或打出此牌结算后，收回手牌，"..
  "然后本回合你不能再使用或打出此牌。",
  ["@$qingshi-turn"] = "情势",
  ["@@qingshi-turn"] = "情势失效",
  ["#qingshi-invoke"] = "情势：请选择一项（当前使用牌为%arg）",
  ["qingshi1"] = "令此牌对其中一个目标伤害+1",
  ["qingshi2"] = "令任意名其他角色各摸一张牌",
  ["qingshi3"] = "摸三张牌，然后此技能本回合失效",
  ["#qingshi1-choose"] = "情势：令%arg对其中一名目标造成伤害+1",
  ["#qingshi2-choose"] = "情势：令任意名其他角色各摸一张牌",
  ["#zhizhe_filter"] = "智哲",

  ["$jincui1"] = "情记三顾之恩，亮必继之以死。",
  ["$jincui2"] = "身负六尺之孤，臣当鞠躬尽瘁。",
  ["$qingshi1"] = "兵者，行霸道之势，彰王道之实。",
  ["$qingshi2"] = "将为军魂，可因势而袭，其有战无类。",
  ["$zhizhe1"] = "轻舟载浊酒，此去，我欲借箭十万。",
  ["$zhizhe2"] = "主公有多大胆略，亮便有多少谋略。",
  ["~wm__zhugeliang"] = "天下事，了犹未了，终以不了了之……",
}

-- 城孙权

Fk:loadTranslationTable{
  ["ty__duyu"] = "杜预",
  ["jianguo"] = "谏国",
  [":jianguo"] = "出牌阶段限一次，你可以选择一项：令一名角色摸一张牌然后弃置一半的手牌（向下取整）；"..
  "令一名角色弃置一张牌然后摸与当前手牌数一半数量的牌（向下取整）",
  ["qingshid"] = "倾势",
  [":qingshid"] = "当你于回合内使用【杀】或锦囊牌指定一名其他角色为目标后，若此牌是你本回合使用的第X张牌，你可对其中一名目标角色造成1点伤害（X为你的手牌数）",
}

local caiwenji = General(extension, "mu__caiwenji", "qun", 3, 3, General.Female)
local shuangjia = fk.CreateTriggerSkill{
  name = "shuangjia",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      player.room:setCardMark(Fk:getCardById(id), "@@shuangjia", 1)
    end
    player.room:setPlayerMark(player, "shuangjia", player:getHandcardNum())
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
  local room = player.room
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.PlayerHand then
          if Fk:getCardById(info.cardId):getMark("@@shuangjia") > 0 then
            room:setCardMark(Fk:getCardById(info.cardId), "@@shuangjia", 0)
            room:removePlayerMark(room:getPlayerById(move.from), "shuangjia", 1)
          end
        end
      end
    end
  end,
}
local shuangjia_maxcards = fk.CreateMaxCardsSkill{
  name = "#shuangjia_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@shuangjia") > 0
  end,
}
local shuangjia_distance = fk.CreateDistanceSkill{
  name = "#shuangjia_distance",
  correct_func = function(self, from, to)
    if to:hasSkill("shuangjia") and to:getMark("shuangjia") > 0 then
      return math.min(to:getMark("shuangjia"), 5)
    end
  end,
}
local beifen = fk.CreateTriggerSkill{
  name = "beifen",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.extra_data and move.extra_data.beifen then
          return true
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.extra_data and move.extra_data.beifen then
        n = n + move.extra_data.beifen
      end
    end
    for i = 1, n, 1 do
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      if not table.find(player.player_cards[Player.Hand], function(id)
        return Fk:getCardById(id):getMark("@@shuangjia") > 0 and Fk:getCardById(id):getSuitString() == pattern end) then
        table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
      end
      table.removeOne(suits, pattern)
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

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@shuangjia") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        local n = 0
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@shuangjia") > 0 then
            n = n + 1
          end
        end
        if n > 0 then
          move.extra_data = move.extra_data or {}
          move.extra_data.beifen = n
        end
      end
    end
  end,
}
local beifen_targetmod = fk.CreateTargetModSkill{
  name = "#beifen_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill("beifen") then
      local n = #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@shuangjia") > 0 end)
      if player:getHandcardNum() > 2 * n then
        return 999
      end
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if player:hasSkill("beifen") then
      local n = #table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@shuangjia") > 0 end)
      if player:getHandcardNum() > 2 * n then
        return 999
      end
    end
  end,
}
shuangjia:addRelatedSkill(shuangjia_maxcards)
shuangjia:addRelatedSkill(shuangjia_distance)
beifen:addRelatedSkill(beifen_targetmod)
caiwenji:addSkill(shuangjia)
caiwenji:addSkill(beifen)
Fk:loadTranslationTable{
  ["mu__caiwenji"] = "蔡文姬",
  ["shuangjia"] = "霜笳",
  [":shuangjia"] = "锁定技，游戏开始时，你的初始手牌增加“胡笳”标记且不计入手牌上限。你每拥有一张“胡笳”，其他角色计算与你距离+1（最多+5）。",
  ["beifen"] = "悲愤",
  [":beifen"] = "锁定技，当你失去“胡笳”后，你获得与手中“胡笳”花色均不同的牌各一张。你手中“胡笳”少于其他牌时，你使用牌无距离和次数限制。",
  ["@@shuangjia"] = "胡笳",

  ["$shuangjia1"] = "塞外青鸟匿，不闻折柳声。",
  ["$shuangjia2"] = "向晚吹霜笳，雪落白发生。",
  ["$beifen1"] = "此心如置冰壶，无物可暖。",
  ["$beifen2"] = "年少爱登楼，欲说语还休。",
  ["~mu__caiwenji"] = "天何薄我，天何薄我……",
}

return extension
