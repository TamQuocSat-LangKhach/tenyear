local extension = Package("tenyear_sp3")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp3"] = "十周年-限定专属3",
}

--神·武：姜维 马超 张飞 张角 邓艾 典韦 许褚
local godjiangwei = General(extension, "godjiangwei", "god", 4)
local tianren = fk.CreateTriggerSkill {
  name = "tianren",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeBasic or card:isCommonTrick() then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card.type == Card.TypeBasic or card:isCommonTrick() then
            x = x + 1
          end
        end
      end
    end
    room:addPlayerMark(player, "@tianren", x)
    while player:getMark("@tianren") >= player.maxHp do
      room:removePlayerMark(player, "@tianren", player.maxHp)
      room:changeMaxHp(player, 1)
      if player.dead then return false end
      player:drawCards(2, self.name)
      if player.dead then return false end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@tianren") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@tianren", 0)
  end,
}
Fk:addPoxiMethod{
  name = "jiufa",
  card_filter = function(to_select, selected, data)
    if table.contains(data[2], to_select) then return true end
    local number = Fk:getCardById(to_select).number
    return table.every(data[2], function (id)
      return Fk:getCardById(id).number ~= number
    end) and not table.every(data[1], function (id)
      return id == to_select or Fk:getCardById(id).number ~= number
    end)
  end,
  feasible = function(selected)
    return true
  end,
}
local jiufa = fk.CreateTriggerSkill{
  name = "jiufa",
  events = {fk.CardUsing, fk.CardResponding},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
    not table.contains(player:getTableMark("@$jiufa"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("@$jiufa")
    table.insertIfNeed(mark, data.card.trueName)
    room:setPlayerMark(player, "@$jiufa", mark)
    if #mark < 9 or not room:askForSkillInvoke(player, self.name, nil, "#jiufa-invoke") then return false end
    room:setPlayerMark(player, "@$jiufa", 0)
    local card_ids = room:getNCards(9)
    local get, throw = {}, {}
    room:moveCards({
      ids = card_ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })

    local number_table = {}
    for _ = 1, 13, 1 do
      table.insert(number_table, 0)
    end
    for _, id in ipairs(card_ids) do
      local x = Fk:getCardById(id).number
      number_table[x] = number_table[x] + 1
      if number_table[x] == 2 then
        table.insert(get, id)
      else
        table.insert(throw, id)
      end
    end
    local result = room:askForArrangeCards(player, self.name, {card_ids},
    "#jiufa", false, 0, {9, 9}, {0, #get}, ".", "jiufa", {throw, get})
    throw = result[1]
    get = result[2]
    if #get > 0 then
      room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, self.name, "", true, player.id)
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@$jiufa") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$jiufa", 0)
  end,
}
local pingxiang = fk.CreateActiveSkill{
  name = "pingxiang",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#pingxiang",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player.maxHp > 9 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:changeMaxHp(player, -9)
    if player.dead then return end
    room:handleAddLoseSkills(player, "-jiufa", nil, true, false)
    for i = 1, 9, 1 do
      if player.dead or not U.askForUseVirtualCard(room, player, "fire__slash", nil, self.name, "#pingxiang-slash:::" .. i, true, true) then
        break
      end
    end
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
pingxiang:addRelatedSkill(pingxiang_maxcards)
godjiangwei:addSkill(tianren)
godjiangwei:addSkill(jiufa)
godjiangwei:addSkill(pingxiang)
Fk:loadTranslationTable{
  ["godjiangwei"] = "神姜维",
  ["#godjiangwei"] = "怒麟布武",
  ["designer:godjiangwei"] = "韩旭",
  ["illustrator:godjiangwei"] = "匠人绘",
  ["tianren"] = "天任",
  [":tianren"] = "锁定技，当一张基本牌或普通锦囊牌不因使用而置入弃牌堆后，你获得1个“天任”标记，"..
  "然后若“天任”标记数不小于X，你移去X个“天任”标记，加1点体力上限并摸两张牌（X为你的体力上限）。",
  ["jiufa"] = "九伐",
  [":jiufa"] = "当你每累计使用或打出九张不同牌名的牌后，你可以亮出牌堆顶的九张牌，然后若其中有点数相同的牌，你选择并获得其中每个重复点数的牌各一张。",
  ["pingxiang"] = "平襄",
  [":pingxiang"] = "限定技，出牌阶段，若你的体力上限大于9，你可以减9点体力上限。"..
  "若如此做，你失去技能〖九伐〗且本局游戏内你的手牌上限等于体力上限，然后你可以视为使用至多九张火【杀】。",
  ["@tianren"] = "天任",
  ["@$jiufa"] = "九伐",
  ["#jiufa-invoke"] = "九伐：是否亮出牌堆顶九张牌，获得重复点数的牌各一张！",
  ["#pingxiang"] = "平襄：你可以减9点体力上限，视为使用至多九张火【杀】！",
  ["#pingxiang-slash"] = "平襄：你可以视为使用火【杀】（第%arg张，共9张）！",

  ["#jiufa"] = "九伐：从亮出的牌中选择并获得其中每个重复点数的牌各一张",
  ["AGCards"] = "亮出的牌",
  ["toGetCards"] = "获得的牌",

  ["$tianren1"] = "举石补苍天，舍我更复其谁？",
  ["$tianren2"] = "天地同协力，何愁汉道不昌？",
  ["$jiufa1"] = "九伐中原，以圆先帝遗志。",
  ["$jiufa2"] = "日日砺剑，相报丞相厚恩。",
  ["$pingxiang1"] = "策马纵慷慨，捐躯抗虎豺。",
  ["$pingxiang2"] = "解甲事仇雠，竭力挽狂澜。",
  ["~godjiangwei"] = "武侯遗志，已成泡影矣……",
}

local godmachao = General(extension, "godmachao", "god", 4)
local shouli = fk.CreateViewAsSkill{
  name = "shouli",
  pattern = "slash,jink",
  prompt = function(self, card, selected_targets)
    return "#shouli-" .. self.interaction.data
  end,
  interaction = function()
    local names = {}
    local pat = Fk.currentResponsePattern
    if pat == nil and table.find(Fk:currentRoom().alive_players, function(p)
      return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil end) then
      local slash = Fk:cloneCard("slash")
      slash.skillName = "shouli"
      if Self:canUse(slash) and not Self:prohibitUse(slash) then
        table.insert(names, "slash")
      end
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
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#shouli-horse:::" .. horse_name, self.name, false, true)
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
    return ""
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
  main_skill = shouli,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shouli)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(shouli.name)
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
    room:doIndicate(player.id, table.map(players, Util.IdMapper))
    for _, p in ipairs(players) do
      if not p.dead then
        local cards = {}
        for i = 1, #room.draw_pile, 1 do
          local card = Fk:getCardById(room.draw_pile[i])
          if (card.sub_type == Card.SubtypeOffensiveRide or card.sub_type == Card.SubtypeDefensiveRide) and
          p:canUse(card) and not p:prohibitUse(card) then
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
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    data.damageType = fk.ThunderDamage
  end,
}
local shouli_targetmod = fk.CreateTargetModSkill{
  name = "#shouli_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, shouli.name)
  end,
}
shouli:addRelatedSkill(shouli_trigger)
shouli:addRelatedSkill(shouli_delay)
shouli:addRelatedSkill(shouli_targetmod)
local hengwu = fk.CreateTriggerSkill{
  name = "hengwu",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
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
  ["#godmachao"] = "神威天将军",
  ["cv:godmachao"] = "张桐铭",
  ["designer:godmachao"] = "七哀",
  ["illustrator:godmachao"] = "君桓文化",
  ["shouli"] = "狩骊",
  [":shouli"] = "游戏开始时，从下家开始所有角色随机使用牌堆中的一张坐骑。你可以将场上的一张进攻马当【杀】（无次数限制）、"..
  "防御马当【闪】使用或打出，以此法失去坐骑的其他角色本回合非锁定技失效，你与其本回合受到的伤害+1且改为雷电伤害。",
  ["hengwu"] = "横骛",
  [":hengwu"] = "当你使用或打出牌时，若你没有该花色的手牌，你可以摸X张牌（X为场上与此牌花色相同的装备数量）。",

  ["#shouli-slash"] = "发动狩骊，将场上的一张进攻马当【杀】使用或打出，选择【杀】的目标角色",
  ["#shouli-jink"] = "发动狩骊，将场上的一张防御马当【闪】使用或打出",
  ["@@shouli-turn"] = "狩骊",
  ["#shouli-horse"] = "狩骊：选择一名装备着 %arg 的角色",
  ["#shouli_trigger"] = "狩骊",
  ["#shouli_delay"] = "狩骊",

  ["$shouli1"] = "赤骊骋疆，巡狩八荒！",
  ["$shouli2"] = "长缨在手，百骥可降！",
  ["$hengwu1"] = "横枪立马，独啸秋风！",
  ["$hengwu2"] = "世皆彳亍，唯我纵横！",
  ["~godmachao"] = "离群之马，虽强亦亡……",
}

local godzhangfei = General(extension, "godzhangfei", "god", 4)
local shencai = fk.CreateActiveSkill{
  name = "shencai",
  prompt = "#shencai-active",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + player:getMark("xunshi")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local data = {
      who = target,
      reason = self.name,
      pattern = ".",
      extra_data = {shencaiSource = effect.from}
    }
    room:judge(data)
    local result = {}
    if table.contains({"peach", "analeptic", "silver_lion", "god_salvation", "celestial_calabash"}, data.card.trueName) then
      table.insert(result, "@@shencai_chi")
    end
    if data.card.sub_type == Card.SubtypeWeapon or data.card.name == "collateral" then
      table.insert(result, "@@shencai_zhang")
    end
    if table.contains({"savage_assault", "archery_attack", "duel", "spear", "eight_diagram", "raid_and_frontal_attack"}, data.card.trueName) then
      table.insert(result, "@@shencai_tu")
    end
    if data.card.sub_type == Card.SubtypeDefensiveRide or data.card.sub_type == Card.SubtypeOffensiveRide or
    table.contains({"snatch", "supply_shortage", "chasing_near"}, data.card.trueName) then
      table.insert(result, "@@shencai_liu")
    end
    if #result == 0 then
      table.insert(result, "@shencai_si")
    end
    if result[1] ~= "@shencai_si" then
      for _, mark in ipairs({"@@shencai_chi", "@@shencai_zhang", "@@shencai_tu", "@@shencai_liu"}) do
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
local shencai_delay = fk.CreateTriggerSkill{
  name = "#shencai_delay",
  anim_type = "offensive",
  events = {fk.FinishJudge, fk.Damaged, fk.TargetConfirmed, fk.AfterCardsMove, fk.EventPhaseStart, fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if event == fk.FinishJudge then
      return data.extra_data and data.extra_data.shencaiSource == player.id and player.room:getCardArea(data.card) == Card.Processing
    elseif event == fk.Damaged then
      return player == target and player:getMark("@@shencai_chi") > 0
    elseif event == fk.TargetConfirmed then
      return player == target and data.card.trueName == "slash" and player:getMark("@@shencai_zhang") > 0
    elseif event == fk.AfterCardsMove and player:getMark("@@shencai_tu") > 0 and not player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.skillName ~= shencai.name and move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    elseif event == fk.EventPhaseStart then
      return player == target and player:getMark("@@shencai_liu") > 0 and player.phase == Player.Finish
    elseif event == fk.TurnEnd then
      return player == target and player:getMark("@shencai_si") > #player.room.alive_players
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.FinishJudge then
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
      end
      return false
    end
    room:notifySkillInvoked(player, shencai.name, "negative")
    player:broadcastSkillInvoke(shencai.name)
    if event == fk.Damaged then
      room:loseHp(player, data.damage, shencai.name)
    elseif event == fk.TargetConfirmed then
      data.disresponsive = true
    elseif event == fk.AfterCardsMove then
      local cards = table.filter(player.player_cards[Player.Hand], function (id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end)
      if #cards > 0 then
        room:throwCard(table.random(cards, 1), shencai.name, player, player)
      end
    elseif event == fk.EventPhaseStart then
      player:turnOver()
    elseif event == fk.TurnEnd then
      room:killPlayer({who = player.id})
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
  mute = true,
  frequency = Skill.Compulsory,
  card_filter = function(self, card, player)
    return player:hasSkill(self) and card.multiple_targets and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", Card.NoSuit, card.number)
  end,
}
local xunshi_trigger = fk.CreateTriggerSkill{
  name = "#xunshi_trigger",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunshi) and data.card.color == Card.NoColor
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, xunshi.name)
    player:broadcastSkillInvoke(xunshi.name)
    if player:getMark("xunshi") < 4 then
      room:addPlayerMark(player, "xunshi", 1)
    end
    local targets = U.getUseExtraTargets(room, data)
    local n = #targets
    if n == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#xunshi-choose:::"..data.card:toLogString(), xunshi.name, true)
    if #tos > 0 then
      table.forEach(tos, function (id)
        table.insert(data.tos, {id})
      end)
      room:sendLog{ type = "#AddTargetsBySkill", from = target.id, to = tos, arg = xunshi.name, arg2 = data.card:toLogString() }
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.card.color == Card.NoColor and player:hasSkill(xunshi)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local xunshi_targetmod = fk.CreateTargetModSkill{
  name = "#xunshi_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and card.color == Card.NoColor and player:hasSkill(xunshi)
  end,
  bypass_distances =  function(self, player, skill, card)
    return card and card.color == Card.NoColor and player:hasSkill(xunshi)
  end,
}
shencai:addRelatedSkill(shencai_delay)
shencai:addRelatedSkill(shencai_maxcards)
xunshi:addRelatedSkill(xunshi_trigger)
xunshi:addRelatedSkill(xunshi_targetmod)
godzhangfei:addSkill(shencai)
godzhangfei:addSkill(xunshi)
Fk:loadTranslationTable{
  ["godzhangfei"] = "神张飞",
  ["#godzhangfei"] = "两界大巡环使",
  ["designer:godzhangfei"] = "星移",
  ["illustrator:godzhangfei"] = "荧光笔工作室",

  ["shencai"] = "神裁",
  ["#shencai_delay"] = "神裁",
  [":shencai"] = "出牌阶段限一次，你可以令一名其他角色进行判定，你获得判定牌。若判定牌包含以下内容，其获得（已有标记则改为修改）对应标记：<br>"..
  "体力：“笞”标记，每次受到伤害后失去等量体力；<br>"..
  "武器：“杖”标记，无法响应【杀】；<br>"..
  "打出：“徒”标记，以此法外失去手牌后随机弃置一张手牌；<br>"..
  "距离：“流”标记，结束阶段将武将牌翻面；<br>"..
  "若判定牌不包含以上内容，该角色获得一个“死”标记且手牌上限减少其身上“死”标记个数，然后你获得其区域内一张牌。"..
  "“死”标记个数大于场上存活人数的角色回合结束时，其直接死亡。",
  ["xunshi"] = "巡使",
  ["#xunshi_trigger"] = "巡使",
  [":xunshi"] = "锁定技，你的多目标锦囊牌均视为无色【杀】。你使用无色牌无距离和次数限制且可以额外指定任意个目标，然后〖神裁〗的发动次数+1（至多为5）。",
  ["@@shencai_chi"] = "笞",
  ["@@shencai_zhang"] = "杖",
  ["@@shencai_tu"] = "徒",
  ["@@shencai_liu"] = "流",
  ["@shencai_si"] = "死",
  ["#shencai-active"] = "发动神裁，选择一名其他角色，令其判定",
  ["#xunshi-choose"] = "巡使：可为此 %arg 额外指定任意个目标",

  ["$shencai1"] = "我有三千炼狱，待汝万世轮回！",
  ["$shencai2"] = "纵汝王侯将相，亦须俯首待裁！",
  ["$xunshi1"] = "秉身为正，辟易万邪！",
  ["$xunshi2"] = "巡御两界，路寻不平！",
  ["~godzhangfei"] = "尔等，欲复斩我头乎？",
}

local godzhangjiao = General(extension, "godzhangjiao", "god", 3)
local yizhao = fk.CreateTriggerSkill{
  name = "yizhao",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@zhangjiao_huang") < 184 and data.card.number > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1 = tostring(player:getMark("@zhangjiao_huang"))
    room:addPlayerMark(player, "@zhangjiao_huang", math.min(data.card.number, 184 - player:getMark("@zhangjiao_huang")))
    local n2 = tostring(player:getMark("@zhangjiao_huang"))
    if #n1 == 1 then
      if #n2 == 1 then return end
    else
      if n1:sub(#n1 - 1, #n1 - 1) == n2:sub(#n2 - 1, #n2 - 1) then return end
    end
    local x = n2:sub(#n2 - 1, #n2 - 1)
    if x == 0 then x = 10 end  --yes, tenyear is so strange
    local card = room:getCardsFromPileByRule(".|"..x)
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@zhangjiao_huang") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhangjiao_huang", 0)
  end,
}
local sanshou = fk.CreateTriggerSkill{
  name = "sanshou",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    local mark = player:getTableMark("sanshou-turn")
    if #mark ~= 3 then
      mark = {0, 0, 0}
    end
    if not table.every(mark, function (value) return value == 1 end) then
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
      if turn_event ~= nil then
        local mark_change = false
        U.getEventsByRule(room, GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if mark[use.card.type] == 0 then
            mark_change = true
            mark[use.card.type] = 1
          end
        end, turn_event.id)
        if mark_change then
          room:setPlayerMark(player, "sanshou-turn", mark)
        end
      end
    end
    local yes = false
    for _, id in ipairs(cards) do
      if mark[Fk:getCardById(id).type] == 0 then
        room:setCardEmotion(id, "judgegood")
        yes = true
      else
        room:setCardEmotion(id, "judgebad")
      end
    end
    room:delay(1000)
    room:moveCards({
      ids = cards,
      fromArea = Card.Processing,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    return yes
  end,
}
local sijun = fk.CreateTriggerSkill{
  name = "sijun",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
    player:getMark("@zhangjiao_huang") > #player.room.draw_pile
  end,
  on_use = function(self, event, tar, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhangjiao_huang", 0)
    room:shuffleDrawPile()
    local cards = {}
    if #room.draw_pile > 3 then
      local ret = {}
      local total = 36
      local numnums = {}
      local maxs = {}
      local pileToSearch = {}
      for i = 1, 13, 1 do
        table.insert(numnums, 0)
        table.insert(maxs, 36//i)
        table.insert(pileToSearch, {})
      end
      for _, id in ipairs(room.draw_pile) do
        local x = Fk:getCardById(id).number
        if x > 0 and x < 14 then
          table.insert(pileToSearch[x], id)
          if numnums[x] < maxs[x] then
            numnums[x] = numnums[x] + 1
          end
        end
      end
      local nums = {}
      for index, value in ipairs(numnums) do
        for _ = 1, value, 1 do
          table.insert(nums, index)
        end
      end
      local postsum = {}
      local nn = #nums
      postsum[nn+1] = 0
      for i = nn, 1, -1 do
        postsum[i] = postsum[i+1] + nums[i]
      end
      local function nSum(n, l, r, target)
        local _ret = {}
        if n == 1 then
          for i = l, r, 1 do
            if nums[i] == target then
              table.insert(_ret, {target})
              break
            end
          end
        elseif n == 2 then
          while l < r do
            local now = nums[l] + nums[r]
            if now > target then
              r = r - 1
            elseif now < target then
              l = l + 1
            else
              table.insert(_ret, {nums[l], nums[r]})
              l = l + 1
              r = r - 1
              while l < r and nums[l] == nums[l-1] do
                l = l + 1
              end
              while l < r and nums[r] == nums[r+1] do
                r = r - 1
              end
            end
          end
        else
          for i = l, r-(n-1), 1 do
            if (i > l and nums[i] == nums[i-1]) or
              (nums[i] + postsum[r - (n-1) + 1] < target) then
            else
              if postsum[i] - postsum[i+n] > target then
                break
              end
              local v = nSum(n-1, i+1, r, target - nums[i])
              for j = 1, #v, 1 do
                table.insert(v[j], nums[i])
                table.insert(_ret, v[j])
              end
            end
          end
        end
        return _ret
      end
      for i = 3, total, 1 do
        table.insertTable(ret, nSum(i, 1, #nums, total))
      end
      if #ret > 0 then
        local compare = table.random(ret)
        table.sort(compare)
        local x = 0
        local current_n = compare[1]
        for _, value in ipairs(compare) do
          if value == current_n then
            x = x + 1
          else
            table.insertTable(cards, table.random(pileToSearch[current_n], x))
            x = 1
            current_n = value
          end
        end
        table.insertTable(cards, table.random(pileToSearch[current_n], x))
      end
    end
    if #cards == 0 then
      local tmp_drawPile = table.simpleClone(room.draw_pile)
      local sum = 0
      while sum < 36 and #tmp_drawPile > 0 do
        local id = table.remove(tmp_drawPile, math.random(1, #tmp_drawPile))
        sum = sum + Fk:getCardById(id).number
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
    end
  end,
}
local tianjie = fk.CreateTriggerSkill{
  name = "tianjie",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if player:getMark(self.name) > 0 then
        player.room:setPlayerMark(player, self.name, 0)
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 3,
      "#tianjie-choose", self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local n = math.max(1, #table.filter(p:getCardIds("h"), function(c) return Fk:getCardById(c).trueName == "jink" end))
        room:damage{
          from = player,
          to = p,
          damage = n,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.AfterDrawPileShuffle},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, self.name, 1)
  end,
}
godzhangjiao:addSkill(yizhao)
godzhangjiao:addSkill(sanshou)
godzhangjiao:addSkill(sijun)
godzhangjiao:addSkill(tianjie)
Fk:loadTranslationTable{
  ["godzhangjiao"] = "神张角",
  ["#godzhangjiao"] = "末世的起首",
  ["cv:godzhangjiao"] = "虞晓旭",
  ["designer:godzhangjiao"] = "韩旭",
  ["illustrator:godzhangjiao"] = "黯荧岛工作室",
  ["yizhao"] = "异兆",
  [":yizhao"] = "锁定技，当你使用或打出一张牌后，获得等同于此牌点数的“黄”标记，然后若“黄”标记数的十位数变化，你随机获得牌堆中一张点数为变化后十位数的牌。",
  ["sanshou"] = "三首",
  [":sanshou"] = "当你受到伤害时，你可以亮出牌堆顶的三张牌，若其中有本回合所有角色均未使用过的牌的类型，防止此伤害。",
  ["sijun"] = "肆军",
  [":sijun"] = "准备阶段，若“黄”标记数大于牌堆里的牌数，你可以移去所有“黄”标记并洗牌，然后获得随机张点数之和为36的牌。",
  ["tianjie"] = "天劫",
  [":tianjie"] = "一名角色的回合结束时，若本回合牌堆进行过洗牌，你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】的数量且至少为1）。",
  ["@zhangjiao_huang"] = "黄",
  ["#tianjie-choose"] = "天劫：你可以对至多三名其他角色各造成X点雷电伤害（X为其手牌中【闪】数，至少为1）",

  ["$yizhao1"] = "苍天已死，此黄天当立之时。",
  ["$yizhao2"] = "甲子尚水，显炎汉将亡之兆。",
  ["$sanshou1"] = "三公既现，领大道而立黄天。",
  ["$sanshou2"] = "天地三才，载厚德以驱魍魉。",
  ["$sijun1"] = "联九州黎庶，撼一家之王庭。",
  ["$sijun2"] = "吾以此身为药，欲医天下之疾。",
  ["$tianjie1"] = "苍天既死，贫道当替天行道。",
  ["$tianjie2"] = "贫道张角，请大汉赴死！",
  ["~godzhangjiao"] = "诸君唤我为贼，然我所窃何物？",
}

local goddengai = General(extension, "goddengai", "god", 4)
local tuoyu = fk.CreateTriggerSkill{
  name = "tuoyu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng() and
    table.find({"1", "2", "3"}, function(n) return player:getMark("tuoyu"..n) > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    local markedcards = {{}, {}, {}}
    local card
    for _, id in ipairs(cards) do
      card = Fk:getCardById(id)
      for i = 1, 3, 1 do
        if card:getMark("@@tuoyu" .. tostring(i) .. "-inhand") > 0 then
          table.insert(markedcards[i], id)
          break
        end
      end
    end
    local result = room:askForCustomDialog(player, self.name,
    "packages/tenyear/qml/TuoyuBox.qml", {
      cards,
      markedcards[1], player:getMark("tuoyu1") > 0,
      markedcards[2], player:getMark("tuoyu2") > 0,
      markedcards[3], player:getMark("tuoyu3") > 0,
    })
    if result ~= "" then
      local d = json.decode(result)
      for _, id in ipairs(cards) do
        card = Fk:getCardById(id)
        for i = 1, 3, 1 do
          room:setCardMark(card, "@@tuoyu"..i .. "-inhand", table.contains(d[i], id) and 1 or 0)
        end
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return target == player and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local card
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      card = Fk:getCardById(id)
      room:setCardMark(card, "@@tuoyu1-inhand", 0)
      room:setCardMark(card, "@@tuoyu2-inhand", 0)
      room:setCardMark(card, "@@tuoyu3-inhand", 0)
    end
  end,
}
local tuoyu_targetmod = fk.CreateTargetModSkill{
  name = "#tuoyu_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return player:hasSkill(tuoyu) and card:getMark("@@tuoyu2-inhand") > 0
  end,
  bypass_distances =  function(self, player, skill, card)
    return player:hasSkill(tuoyu) and card:getMark("@@tuoyu2-inhand") > 0
  end,
}
local tuoyu_trigger = fk.CreateTriggerSkill{
  name = "#tuoyu_trigger",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and player:hasSkill(tuoyu) and
    (data.card:getMark("@@tuoyu1-inhand") > 0 or data.card:getMark("@@tuoyu2-inhand") > 0 or data.card:getMark("@@tuoyu3-inhand") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    if data.card:getMark("@@tuoyu1-inhand") > 0 then
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
    elseif data.card:getMark("@@tuoyu2-inhand") > 0 then
      data.extraUse = true
    elseif data.card:getMark("@@tuoyu3-inhand") > 0 then
      data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
    end
  end,
}
local xianjin = fk.CreateTriggerSkill{
  name = "xianjin",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("xianjin_damage") > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "xianjin_damage", 0)

    local choices = table.map(table.filter({"1", "2", "3"}, function(n)
      return player:getMark("tuoyu"..n) == 0 end), function(n) return "tuoyu"..n end)
    if #choices > 0 then
      local choice = room:askForChoice(player, choices, self.name, "#xianjin-choice", true)
      room:setPlayerMark(player, choice, 1)
    end
    if table.every(room.alive_players, function(p) return player:getHandcardNum() >= p:getHandcardNum() end) then
      player:drawCards(1, self.name)
    else
      player:drawCards(#table.filter({"1", "2", "3"}, function(n) return player:getMark("tuoyu"..n) > 0 end), self.name)
    end
  end,

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xianjin_damage")
  end,
}
local qijing = fk.CreateTriggerSkill{
  name = "qijing",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("tuoyu1") > 0 and player:getMark("tuoyu2") > 0 and player:getMark("tuoyu3") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    room:handleAddLoseSkills(player, "cuixin", nil, true, false)
    local tos = table.filter(room.alive_players, function (p)
      return p ~= player and p:getNextAlive(true) ~= player
      --无视被调虎吧……
    end)
    if #tos > 0 then
      local to = room:askForChoosePlayers(player, table.map(tos, Util.IdMapper), 1, 1, "#qijing-choose", self.name, true, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        local players = table.simpleClone(room.players)
        local n = 1
        for i, v in ipairs(room.players) do
          if v == to and i < #room.players then
            n = i + 1
            break
          end
        end

        players[n] = player
        repeat
          local nextIndex = n + 1 > #room.players and 1 or n + 1
          players[nextIndex] = room.players[n]

          n = nextIndex
        until room.players[n] == player

        room.players = players
        local player_circle = {}
        for i = 1, #room.players do
          room.players[i].seat = i
          table.insert(player_circle, room.players[i].id)
        end
        for i = 1, #room.players - 1 do
          room.players[i].next = room.players[i + 1]
        end
        room.players[#room.players].next = room.players[1]
        room:doBroadcastNotify("ArrangeSeats", json.encode(player_circle))
      end
    end
    player:gainAnExtraTurn(true)
  end,
}
local cuixin = fk.CreateTriggerSkill{
  name = "cuixin",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.extra_data and data.extra_data.cuixin_tos
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    if #data.extra_data.cuixin_tos == 1 then
      if #data.extra_data.cuixin_adjacent == 1 then
        if not player:isProhibited(player:getNextAlive(), data.card) then
          table.insert(targets, player:getNextAlive().id)
        else
          return
        end
      else
        for _, id in ipairs(data.extra_data.cuixin_adjacent) do
          if id ~= data.extra_data.cuixin_tos[1] then
            local p = room:getPlayerById(id)
            if not p.dead and not player:isProhibited(p, data.card) then
              table.insert(targets, id)
              break
            end
          end
        end
      end
    else
      for _, id in ipairs(data.extra_data.cuixin_adjacent) do
        local p = room:getPlayerById(id)
        if not p.dead and not player:isProhibited(p, data.card) then
          table.insert(targets, id)
        end
      end
    end
    if #targets == 0 then
      return
    elseif #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#cuixin-invoke::"..targets[1]..":"..data.card.name) then
        self.cost_data = targets[1]
        return true
      end
    elseif #targets == 2 then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#cuixin2-choose:::"..data.card.name, self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard(data.card.name, nil, player, player.room:getPlayerById(self.cost_data), self.name, true)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and not table.contains(data.card.skillNames, self.name) and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local tos, adjacent = {}, {}
    for _, p in ipairs(room.alive_players) do
      if player:getNextAlive() == p or p:getNextAlive() == player then
        table.insertIfNeed(adjacent, p.id)
        if table.contains(TargetGroup:getRealTargets(data.tos), p.id) then
          table.insertIfNeed(tos, p.id)
        end
      end
    end
    if #tos > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.cuixin_tos = tos
      data.extra_data.cuixin_adjacent = adjacent
    end
  end,
}
tuoyu:addRelatedSkill(tuoyu_targetmod)
tuoyu:addRelatedSkill(tuoyu_trigger)
goddengai:addSkill(tuoyu)
goddengai:addSkill(xianjin)
goddengai:addSkill(qijing)
goddengai:addRelatedSkill(cuixin)
Fk:loadTranslationTable{
  ["goddengai"] = "神邓艾",
  ["#goddengai"] = "带砺山河",
  ["designer:goddengai"] = "步穗",
  ["illustrator:goddengai"] = "黯荧岛工作室",
  ["tuoyu"] = "拓域",
  [":tuoyu"] = "锁定技，你的手牌区域添加三个未开发的副区域：<br>丰田：伤害和回复值+1；<br>清渠：无距离和次数限制；<br>峻山：不能被响应。<br>"..
  "出牌阶段开始时和结束时，你将手牌分配至已开发的副区域中，每个区域至多五张。",
  ["xianjin"] = "险进",
  [":xianjin"] = "锁定技，当你造成或受到两次伤害后开发一个手牌副区域，摸X张牌（X为你已开发的手牌副区域数，若你手牌全场最多则改为1）。",
  ["qijing"] = "奇径",
  [":qijing"] = "觉醒技，每个回合结束时，若你的手牌副区域均已开发，你减1点体力上限，获得技能“摧心”，然后将座次移动至相邻的两名其他角色之间并执行一个额外回合。",
  ["cuixin"] = "摧心",
  [":cuixin"] = "当你不以此法对上家/下家使用的牌结算后，你可以视为对下家/上家使用一张同名牌。",
  ["tuoyu1"] = "丰田",
  ["@@tuoyu1-inhand"] = "丰田",
  [":tuoyu1"] = "伤害和回复值+1",
  ["tuoyu2"] = "清渠",
  ["@@tuoyu2-inhand"] = "清渠",
  [":tuoyu2"] = "无距离和次数限制",
  ["tuoyu3"] = "峻山",
  ["@@tuoyu3-inhand"] = "峻山",
  [":tuoyu3"] = "不能被响应",
  ["#tuoyu"] = "拓域：将手牌分配至已开发的副区域中（每个区域至多5张）",
  ["#xianjin-choice"] = "险进：选择你要开发的手牌副区域",
  ["#qijing-choose"] = "奇径：选择一名角色，你移动座次成为其下家",
  ["#cuixin-invoke"] = "摧心：你可以视为对 %dest 使用【%arg】",
  ["#cuixin2-choose"] = "摧心：你可以视为对其中一名角色使用【%arg】",

  ["$tuoyu1"] = "本尊目之所及，皆为麾下王土。",
  ["$tuoyu2"] = "擎五丁之神力，碎万仞之高山。",
  ["$xianjin1"] = "大风！大雨！大景！！",
  ["$xianjin2"] = "行役沙场，不战胜，则战死！",
  ["$qijing1"] = "今神兵于天降，贯奕世之长虹！",
  ["$qijing2"] = "辟罗浮之险径，捣伪汉之黄龙！",
  ["$cuixin1"] = "今兵临城下，其王庭可摧。",
  ["$cuixin2"] = "四面皆奏楚歌，问汝降是不降？",
  ["~goddengai"] = "灭蜀者，邓氏士载也！",
}

local godxuchu = General(extension, "godxuchu", "god", 5)
local zhengqing = fk.CreateTriggerSkill{
  name = "zhengqing",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.players) do
      if p:getMark("@zhengqing_qing") then
        room:setPlayerMark(p, "@zhengqing_qing", 0)
      end
    end

    local phases = room.logic:getEventsOfScope(GameEvent.Turn, 999, Util.TrueFunc, Player.HistoryRound)
    local damageEvents = U.getActualDamageEvents(room, 999, Util.TrueFunc, Player.HistoryRound)

    if #phases > 0 and #damageEvents > 0 then
      local curIndex = 1
      local bestRecord = {}
      for i = 1, #phases do
        local records = {}
        for j = curIndex, #damageEvents do
          curIndex = j

          local phaseEvent = phases[i]
          local damageEvent = damageEvents[j]
          if phaseEvent.id < damageEvent.id and (i == #phases or phases[i + 1].id > damageEvent.id) then
            local damageData = damageEvent.data[1]
            if damageData.from then
              records[damageData.from.id] = (records[damageData.from.id] or 0) + damageData.damage
            end
          end

          if i < #phases and phases[i + 1].id < damageEvent.id then
            break
          end
        end

        for playerId, damage in pairs(records) do
          local curDMG = bestRecord.damage or 0
          if damage > curDMG then
            bestRecord = { playerIds = { playerId }, damage = damage }
          elseif damage == curDMG then
            table.insertIfNeed(bestRecord.playerIds, playerId)
          end
        end
      end

      local winnerId = table.find(bestRecord.playerIds, function(id) return id == player.id end) or table.random(bestRecord.playerIds)
      if winnerId and room:getPlayerById(winnerId):isAlive() then
        local winner = room:getPlayerById(winnerId)
        local preRecord = (player.tag["zhengqing_best"] or 0)
        room:addPlayerMark(winner, "@zhengqing_qing", bestRecord.damage)
        player.tag["zhengqing_best"] = bestRecord.damage
        if winner == player and bestRecord.damage > preRecord then
          player:drawCards(math.min(bestRecord.damage, 5), self.name)
        else
          local players = { winnerId, player.id }
          room:sortPlayersByAction(players)
          for _, p in ipairs(players) do
            room:getPlayerById(p):drawCards(1, self.name)
          end
        end
      end
    end
  end,
}

godxuchu:addSkill(zhengqing)

local zhuangpo = fk.CreateViewAsSkill{
  name = "zhuangpo",
  anim_type = "offensive",
  prompt = "#zhuangpo",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    return
      #selected == 0 and
      (
        Fk:getCardById(to_select).trueName == "slash" or
        string.find(Fk:translate(":" .. Fk:getCardById(to_select).name, "zh_CN"), "【杀】")
      )
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return not player:isNude()
  end,
}
local zhuangpoBuff = fk.CreateTriggerSkill{
  name = "#zhuangpo_buff",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and player:hasSkill(self) and
      table.contains(data.card.skillNames, zhuangpo.name) and
      (
        player:getMark("@zhengqing_qing") > 0 or
        (
          data.firstTarget and
          table.find(AimGroup:getAllTargets(data.tos), function(p)
            return player.room:getPlayerById(p):getMark("@zhengqing_qing") > 0
          end)
        )
      )
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@zhengqing_qing") > 0 and room:getPlayerById(data.to):isAlive() then
      local choices = {}
      for i = 1, player:getMark("@zhengqing_qing") do
        table.insert(choices, tostring(i))
      end
      table.insert(choices, "Cancel")

      local choice = room:askForChoice(player, choices, zhengqing.name, "#zhuangpo-choice::" .. data.to)
      if choice == "Cancel" then
        return (
          data.firstTarget and
          table.find(AimGroup:getAllTargets(data.tos), function(p)
            return room:getPlayerById(p):getMark("@zhengqing_qing") > 0
          end)
        )
      else
        self.cost_data = tonumber(choice)
      end
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if (self.cost_data or 0) > 0 then
      local discardNum = self.cost_data
      self.cost_data = nil
      room:removePlayerMark(player, "@zhengqing_qing", discardNum)
      room:askForDiscard(room:getPlayerById(data.to), discardNum, discardNum, true, self.name, false)
    end

    if
      data.firstTarget and
      table.find(AimGroup:getAllTargets(data.tos), function(p)
        return room:getPlayerById(p):getMark("@zhengqing_qing") > 0
      end)
    then
      data.additionalDamage = (data.additionalDamage or 0) + 1
      data.extra_data = data.extra_data or {}
      data.extra_data.zhengqingBuff = true

      -- local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      -- if e then
      --   local _data = e.data[1]
      --   _data.additionalDamage = (_data.additionalDamage or 0) + 1
      -- end
    end
  end,

  --FIXME: 需要本体取使用流程和指定流程的附加伤害基数最大值
  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return (data.extra_data or {}).zhengqingBuff
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}

zhuangpo:addRelatedSkill(zhuangpoBuff)
godxuchu:addSkill(zhuangpo)

Fk:loadTranslationTable{
  ["godxuchu"] = "神许褚",
  ["#godxuchu"] = "嗜战的熊罴",
  ["designer:godxuchu"] = "商天害",
  ["illustrator:godxuchu"] = "小新",
  ["zhengqing"] = "争擎",
  [":zhengqing"] = "锁定技，每轮结束时，移去所有“擎”标记，然后本轮单回合内造成伤害值最多的角色获得X个“擎”标记"..
  "并与你各摸一张牌（X为其该回合造成的伤害数）。若是你获得“擎”且是获得数量最多的一次，你改为摸X张牌（最多摸5）。",
  ["@zhengqing_qing"] = "擎",

  ["zhuangpo"] = "壮魄",
  [":zhuangpo"] = "你可将牌面信息中有【杀】字的牌当【决斗】使用。"..
  "若你拥有“擎”，则此【决斗】指定目标后，你可以移去任意个“擎”，然后令其弃置等量的牌；"..
  "若此【决斗】指定了有“擎”的角色为目标，则此牌伤害+1。",
  ["#zhuangpo_buff"] = "壮魄",
  ["#zhuangpo"] = "壮魄：你可将牌面信息中有【杀】字的牌当【决斗】使用",
  ["#zhuangpo-choice"] = "壮魄：你可移去至少一枚“擎”标记，令 %dest 弃置等量的牌",

  ["$zhengqing1"] = "锐势夺志，斩将者虎候是也！",
  ["$zhengqing2"] = "三军争勇，擎纛者舍我其谁！",
  ["$zhuangpo1"] = "腹吞龙虎，气撼山河！",
  ["$zhuangpo2"] = "神魄凝威，魍魉辟易！",
  ["~godxuchu"] = "猛虎归林晚，不见往来人……",
}

local godhuatuo = General(extension, "ty__godhuatuo", "god", 3)
Fk:loadTranslationTable{
  ["ty__godhuatuo"] = "神华佗",
  ["#ty__godhuatuo"] = "灵魂的医者",
  ["illustrator:ty__godhuatuo"] = "君桓文化",
  ["~ty__godhuatuo"] = "世无良医，枉死者半……",
}

local jingyu = fk.CreateTriggerSkill{
  name = "jingyu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.SkillEffect},
  can_trigger = function(self, _, target, player, data)
    return
      player:hasSkill(self) and
      data.visible and
      data ~= self and
      target and
      target:hasSkill(data, true, true) and
      not data:isEquipmentSkill(player) and
      not table.contains({ "m_feiyang", "m_bahu" }, data.name) and
      not table.contains(player:getTableMark("jingyu_skills-round"), data.name)
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local skills = player:getTableMark("jingyu_skills-round")
    table.insertIfNeed(skills, data.name)
    room:setPlayerMark(player, "jingyu_skills-round", skills)

    player:drawCards(1, self.name)
  end,
}
Fk:loadTranslationTable{
  ["jingyu"] = "静域",
  [":jingyu"] = "锁定技，每项技能每轮限一次，当一名角色发动除“静域”外的技能时，你摸一张牌。" ..
  "<br/><font color='red'><b>注</b>：请不要反馈此技能相关的任何问题。</font>",
  ["$jingyu1"] = "人身疾苦，与我无异。",
  ["$jingyu2"] = "医以济世，其术贵在精诚。",
}

godhuatuo:addSkill(jingyu)

local lvxin = fk.CreateActiveSkill{
  name = "lvxin",
  anim_type = "control",
  prompt = "#lvxin",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive, player.id)
    local round = math.min(5, room:getTag("RoundCount"))
    local choice = room:askForChoice(
      player,
      { "lvxin_draw:::" .. round, "lvxin_discard:::" .. round },
      self.name,
      "#lvxin-choose::" .. target.id
    )
    if choice:startsWith("lvxin_discard") then
      local canDiscard = table.filter(target:getCardIds("h"), function(id) return not target:prohibitDiscard(id) end)
      if #canDiscard == 0 then
        return false
      end

      local toDiscard = canDiscard
      if #canDiscard > round then
        toDiscard = table.random(canDiscard, round)
      end

      local hasSameName = table.find(
        toDiscard,
        function(id)
          return Fk:getCardById(id).trueName == Fk:getCardById(effect.cards[1]).trueName
        end
      )
      room:throwCard(toDiscard, self.name, target, target)
      if hasSameName then
        room:setPlayerMark(target, "@lvxinLoseHp", "lvxin_loseHp")
      end
    else
      local idsDrawn = target:drawCards(round, self.name)
      if table.find(idsDrawn, function(id) return Fk:getCardById(id).trueName == Fk:getCardById(effect.cards[1]).trueName end) then
        room:setPlayerMark(target, "@lvxinRecover", "lvxin_recover")
      end
    end
  end,
}
local lvxinDelayedEffect = fk.CreateTriggerSkill{
  name = "#lvxin_delayed_effect",
  mute = true,
  events = {fk.SkillEffect},
  can_trigger = function(self, _, target, player, data)
    return
      target == player and
      data.visible and
      target:hasSkill(data, true, true) and
      not table.contains({ "m_feiyang", "m_bahu" }, data.name) and
      (target:getMark("@lvxinLoseHp") ~= 0 or target:getMark("@lvxinRecover") ~= 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local lvxinLoseHp = target:getMark("@lvxinLoseHp")
    local lvxinRecover = target:getMark("@lvxinRecover")
    room:setPlayerMark(target, "@lvxinLoseHp", 0)
    room:setPlayerMark(target, "@lvxinRecover", 0)
    if lvxinRecover ~= 0 then
      room:recover{
        who = target,
        num = 1,
        skillName = lvxin.name
      }
    end

    if lvxinLoseHp ~= 0 then
      room:loseHp(target, 1, lvxin.name)
    end
  end,
}
Fk:loadTranslationTable{
  ["lvxin"] = "滤心",
  [":lvxin"] = "出牌阶段限一次，你可以交给一名其他角色一张手牌，然后选择一项：1.令其摸X张牌；2.令其随机弃置X张手牌（X为游戏轮数且至多为5）。" ..
  "若其以此法摸到/弃置与你交给其的牌牌名相同的牌，则其下次发动技能时，其回复1点体力/失去1点体力。"..
  "<br/><font color='red'><b>注</b>：请不要反馈此技能相关的任何问题。</font>",
  ["#lvxin"] = "滤心：你可交给其他角色手牌，令其摸牌或弃牌",
  ["#lvxin_delayed_effect"] = "滤心",
  ["lvxin_draw"] = "令其摸%arg张牌",
  ["lvxin_discard"] = "令其随机弃置%arg张手牌",
  ["@lvxinRecover"] = "滤心",
  ["@lvxinLoseHp"] = "滤心",
  ["lvxin_loseHp"] = "失去体力",
  ["lvxin_recover"] = "回复体力",
  ["$lvxin1"] = "医病非难，难在医人之心。",
  ["$lvxin2"] = "知人者有验于天，知天者有验于人。",
}

lvxin:addRelatedSkill(lvxinDelayedEffect)
godhuatuo:addSkill(lvxin)

local huandao = fk.CreateActiveSkill{
  name = "huandao",
  anim_type = "support",
  prompt = "#huandao",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])

    target:reset()
    local sameGenerals = Fk:getSameGenerals(target.general)
    local trueName = Fk.generals[target.general].trueName
    if trueName:startsWith("god") then
      table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals(string.sub(trueName, 4)))
    else
      table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals("god" .. trueName))
      if Fk.generals["god" .. trueName] then
        table.insertIfNeed(sameGenerals, "god" .. trueName)
      end
    end
    
    if target.deputyGeneral and target.deputyGeneral ~= "" then
      table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals(target.deputyGeneral))
      trueName = Fk.generals[target.deputyGeneral].trueName
      if trueName:startsWith("god") then
        table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals(string.sub(trueName, 4)))
      else
        table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals("god" .. trueName))
        if Fk.generals["god" .. trueName] then
          table.insertIfNeed(sameGenerals, "god" .. trueName)
        end
      end
    end

    if #sameGenerals == 0 then
      return
    end

    local randomSkill = table.random(Fk.generals[table.random(sameGenerals)]:getSkillNameList())
    if room:askForSkillInvoke(target, self.name, nil, "#huandao-choose:::" .. randomSkill) then
      room:handleAddLoseSkills(target, randomSkill)
      local toLose = {}
      for _, s in ipairs(target.player_skills) do
        if s:isPlayerSkill(target) and s.name ~= randomSkill then
          table.insertIfNeed(toLose, s.name)
        end
      end

      if #toLose > 0 then
        local choice = room:askForChoice(target, toLose, self.name, "#huandao-lose")
        room:handleAddLoseSkills(target, "-" .. choice)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["huandao"] = "寰道",
  [":huandao"] = "限定技，出牌阶段，你可以选择一名其他角色，令其复原武将牌，然后其可随机获得一项同名武将的技能并选择失去一项其他技能。",
  ["#huandao"] = "寰道：你可令其他角色复原武将牌并获得同名武将技能",
  ["#huandao-choose"] = "寰道：你可以获得技能“%arg”，然后选择另一项技能失去",
  ["#huandao-lose"] = "寰道：请选择你要失去的技能",
  ["$huandao1"] = "一语一默，道尽医者慈悲。",
  ["$huandao2"] = "亦疾亦缓，抚平世间苦难。",
}

godhuatuo:addSkill(huandao)

local godhuangzhong = General(extension, "godhuangzhong", "god", 4)
Fk:loadTranslationTable{
  ["godhuangzhong"] = "神黄忠",
  ["#godhuangzhong"] = "战意破苍穹",
  -- ["illustrator:godhuangzhong"] = "君桓文化",
  -- ["~godhuangzhong"] = "世无良医，枉死者半……",
}

local yiwu = fk.CreateTriggerSkill{
  name = "yiwu",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and data.to:isAlive() and player:hasSkill(self)
  end,
  on_cost = function (self, event, target, player, data)
    local choices = {
      "yiwu_upper_limb",
      "yiwu_lower_limb",
      "yiwu_chest",
      "yiwu_abdomen",
    }

    local victim = data.to
    if table.contains(player:getTableMark("yiwu_hitter-turn"), victim.id) then
      table.insert(choices, 1, "yiwu_head")
    end

    local results = player.room:askForChoices(player, choices, 1, 1, self.name, "#yiwu-choose::" .. victim.id)
    if #results > 0 then
      self.cost_data = {tos = {data.to.id}, choice = results[1]}
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local victim = data.to
    if not victim:isAlive() then
      return false
    end

    local hitters = player:getTableMark("yiwu_hitter-turn")
    table.insertIfNeed(hitters, victim.id)
    room:setPlayerMark(player, "yiwu_hitter-turn", hitters)

    local choice = self.cost_data.choice
    if choice == "yiwu_head" and victim.hp > 0 then
      room:loseHp(victim, victim.hp, self.name)
      if victim.dead then
        room:changeMaxHp(player, 1)
      end
    elseif choice == "yiwu_upper_limb" then
      local toDiscard = table.random(victim:getCardIds("h"), math.ceil(#victim:getCardIds("h") / 2))
      if #toDiscard > 0 then
        room:throwCard(toDiscard, self.name, victim, victim)
      end
    else
      room:setPlayerMark(victim, "@@" .. choice, 1)
    end
  end,

  refresh_events = { fk.AfterTurnEnd },
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      table.find(
        {
          "@@yiwu_lower_limb",
          "@@yiwu_chest",
          "@@yiwu_abdomen",
        },
        function(markName) return player:getMark(markName) ~= 0 end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, markName in ipairs({ "@@yiwu_lower_limb", "@@yiwu_chest", "@@yiwu_abdomen" }) do
      if player:getMark(markName) ~= 0 then
        room:setPlayerMark(player, markName, 0)
      end
    end
  end,
}
local yiwuTrigger = fk.CreateTriggerSkill{
  name = "#yiwu_trigger",
  anim_type = "negative",
  events = {fk.CardUsing, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return
        target == player and
        player:getMark("@@yiwu_chest") > 0
    end

    return target == player and player:getMark("@@yiwu_lower_limb") > 0 and player.hp > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:setPlayerMark(player, "@@yiwu_chest", 0)
      if data.toCard then
        data.toCard = nil
      else
        data.tos = {}
      end
    else
      room:setPlayerMark(player, "@@yiwu_lower_limb", 0)
      data.damage = data.damage + 1
    end
  end,
}
local yiwuProhibit = fk.CreateProhibitSkill{
  name = "#yiwu_prohibit",
  prohibit_use = function(self, player, card)
    return
      player:getMark("@@yiwu_abdomen") > 0 and card.suit == Card.Heart
  end,
}
Fk:loadTranslationTable{
  ["yiwu"] = "裂穹",
  [":yiwu"] = "当你对其他角色造成伤害后，你可以选择以下任一部位进行“击伤”：<br>" ..
  "力烽：令其随机弃置一半手牌（向上取整）。<br>" ..
  "地机：令其下次受到伤害+1直到其回合结束。<br>" ..
  "地机：令其使用下一张牌失效直到其回合结束。<br>" ..
  "气海：令其不能使用<font color='red'>♥</font>牌直到其回合结束。<br>" ..
  "若你本回合击伤过该角色，则额外出现“天冲”选项。<br>" ..
  "天冲：令其失去所有体力，然后若其死亡，则你加1点体力上限。",
  ["#yiwu-choose"] = "裂穹：你可“击伤” %dest 的其中一个部位",

  ["#yiwu_trigger"] = "裂穹",
  ["#yiwu_prohibit"] = "裂穹",
  ["yiwu_head"] = "天冲：令其失去所有体力，若其死亡你加1体力上限",
  ["yiwu_upper_limb"] = "力烽：令其随机弃置一半手牌（向上取整）",
  ["yiwu_lower_limb"] = "地机：令其下次受到伤害+1直到其回合结束",
  ["yiwu_chest"] = "地机：令其使用下一张牌失效直到其回合结束",
  ["yiwu_abdomen"] = "气海：令其不能使用<font color='red'>♥</font>牌直到其回合结束",
  ["@@yiwu_lower_limb"] = "地机:受伤+1",
  ["@@yiwu_chest"] = "地机:牌无效",
  ["@@yiwu_abdomen"] = "气海:禁<font color='red'>♥</font>",
}

yiwu:addRelatedSkill(yiwuTrigger)
yiwu:addRelatedSkill(yiwuProhibit)
godhuangzhong:addSkill(yiwu)

local chiren = fk.CreateTriggerSkill{
  name = "chiren",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(self)
  end,
  on_cost = function (self, event, target, player, data)
    local choice = player.room:askForChoice(player, { "chiren_hp", "chiren_losthp", "Cancel" }, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "chiren_hp" then
      player:drawCards(player.hp, self.name)
      room:setPlayerMark(player, "@chiren-phase", "chiren_aim")
    else
      player:drawCards(player:getLostHp(), self.name)
      room:setPlayerMark(player, "@chiren-phase", "chiren_recover")
    end
  end,
}
local chirenBuff = fk.CreateTriggerSkill{
  name = "#chiren_buff",
  mute = true,
  events = {fk.CardUsing, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return target == player and data.card.trueName == "slash" and player:getMark("@chiren-phase") == "chiren_aim"
    end

    return target == player and player:getMark("@chiren-phase") == "chiren_recover"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@chiren-phase", 0)
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(room.players, Util.IdMapper)
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "chiren",
      }
    end
  end,
}
local chirenUnlimited = fk.CreateTargetModSkill{
  name = "#chiren_unlimited",
  bypass_distances = function(self, player, skill, card)
    return player:getMark("@chiren-phase") == "chiren_aim" and skill.trueName == "slash_skill"
  end,
}
Fk:loadTranslationTable{
  ["chiren"] = "斩决",
  [":chiren"] = "出牌阶段开始时，你可以选择一项：1.摸体力值数量的牌，令你此阶段使用下一张【杀】无距离限制且不可被响应；" ..
  "2.摸已损失体力值数量的牌，令你于此阶段下一次造成伤害后回复1点体力。",
  ["#chiren_buff"] = "斩决",
  ["chiren_hp"] = "摸体力值数量的牌，令你此阶段下一张【杀】无距离限制且不可被响应",
  ["chiren_losthp"] = "摸已损失体力值数量的牌，令你此阶段下一次造成伤害后回复1点体力",
  ["chiren_aim"] = "强中",
  ["chiren_recover"] = "吸血",
  ["@chiren-phase"] = "斩决",
}

chiren:addRelatedSkill(chirenBuff)
chiren:addRelatedSkill(chirenUnlimited)
godhuangzhong:addSkill(chiren)

--笔舌如椽：陈琳 杨修 骆统 王昶 程秉 杨彪 阮籍 崔琰毛玠
local ty__chenlin = General(extension, "ty__chenlin", "wei", 3)
local ty__songci = fk.CreateActiveSkill{
  name = "ty__songci",
  anim_type = "control",
  mute = true,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    local mark = player:getTableMark(self.name)
    return table.find(Fk:currentRoom().alive_players, function(p) return not table.contains(mark, p.id) end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local mark = Self:getTableMark(self.name)
    return #selected == 0 and not table.contains(mark, to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    local mark = player:getTableMark(self.name)
    table.insert(mark, target.id)
    room:setPlayerMark(player, self.name, mark)
    if #target.player_cards[Player.Hand] <= target.hp then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name, 1)
      target:drawCards(2, self.name)
    else
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name, 2)
      room:askForDiscard(target, 2, 2, true, self.name, false)
    end
  end,
}
local ty__songci_trigger = fk.CreateTriggerSkill{
  name = "#ty__songci_trigger",
  mute = true,
  main_skill = ty__songci,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    local mark = player:getTableMark("ty__songci")
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
    and table.every(player.room.alive_players, function (p) return table.contains(mark, p.id) end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, "ty__songci", "drawcard")
    player:broadcastSkillInvoke("ty__songci", 3)
    player:drawCards(1, "ty__songci")
  end,
}
ty__chenlin:addSkill("bifa")
ty__songci:addRelatedSkill(ty__songci_trigger)
ty__chenlin:addSkill(ty__songci)
Fk:loadTranslationTable{
  ["ty__chenlin"] = "陈琳",
  ["#ty__chenlin"] = "破竹之咒",
  ["illustrator:ty__chenlin"] = "Thinking", -- 破竹之咒 皮肤
  ["ty__songci"] = "颂词",
  [":ty__songci"] = "①出牌阶段，你可以选择一名角色（每名角色每局游戏限一次），若该角色的手牌数：不大于体力值，其摸两张牌；大于体力值，其弃置两张牌。②弃牌阶段结束时，若你对所有存活角色均发动过“颂词”，你摸一张牌。",
  ["#ty__songci_trigger"] = "颂词",

  ["$ty__songci1"] = "将军德才兼备，大汉之栋梁也！",
  ["$ty__songci2"] = "汝窃国奸贼，人人得而诛之！",
  ["$ty__songci3"] = "义军盟主，众望所归！",
  ["~ty__chenlin"] = "来人……我的笔呢……",
}

local yangxiu = General(extension, "ty__yangxiu", "wei", 3)
local ty__danlao = fk.CreateTriggerSkill{
  name = "ty__danlao",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and not U.isOnlyTarget(player, data, event)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__danlao-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
local ty__jilei = fk.CreateTriggerSkill{
  name = "ty__jilei",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#ty__jilei-invoke::"..data.from.id) then
      room:doIndicate(player.id, {data.from.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"basic", "trick", "equip"}, self.name)
    local mark = data.from:getTableMark("@ty__jilei")
    if table.insertIfNeed(mark, choice .. "_char") then
      room:setPlayerMark(data.from, "@ty__jilei", mark)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@ty__jilei") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@ty__jilei", 0)
  end,
}
local ty__jilei_prohibit = fk.CreateProhibitSkill{
  name = "#ty__jilei_prohibit",
  prohibit_use = function(self, player, card)
    if table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_discard = function(self, player, card)
    return table.contains(player:getTableMark("@ty__jilei"), card:getTypeString() .. "_char")
  end,
}
ty__jilei:addRelatedSkill(ty__jilei_prohibit)
yangxiu:addSkill(ty__danlao)
yangxiu:addSkill(ty__jilei)
Fk:loadTranslationTable{
  ["ty__yangxiu"] = "杨修",
  ["#ty__yangxiu"] = "恃才放旷",
  ["illustrator:ty__yangxiu"] = "alien", -- 传说皮 度龙品酥
  ["ty__danlao"] = "啖酪",
  [":ty__danlao"] = "当你成为【杀】或锦囊牌的目标后，若你不是唯一目标，你可以摸一张牌，然后此牌对你无效。",
  ["ty__jilei"] = "鸡肋",
  [":ty__jilei"] = "当你受到伤害后，你可以声明一种牌的类别，伤害来源不能使用、打出或弃置你声明的此类手牌直到其下回合开始。",
  ["#ty__danlao-invoke"] = "啖酪：你可以摸一张牌，令 %arg 对你无效",
  ["#ty__jilei-invoke"] = "鸡肋：是否令 %dest 不能使用、打出、弃置一种类别的牌直到其下回合开始？",
  ["@ty__jilei"] = "鸡肋",

  ["$ty__danlao1"] = "此酪味美，诸君何不与我共食之？",
  ["$ty__danlao2"] = "来来来，丞相美意，不可辜负啊。",
  ["$ty__jilei1"] = "今进退两难，势若鸡肋，魏王必当罢兵而还。",
  ["$ty__jilei2"] = "汝可令士卒收拾行装，魏王明日必定退兵。",
  ["~ty__yangxiu"] = "自作聪明，作茧自缚，悔之晚矣……",
}

local luotong = General(extension, "ty__luotong", "wu", 3)
local renzheng = fk.CreateTriggerSkill{
  name = "renzheng",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.DamageFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if not data.dealtRecorderId then return true end
      if data.extra_data and data.extra_data.renzheng_maxDamage then
        return data.damage < data.extra_data.renzheng_maxDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,

  refresh_events = {fk.AfterSkillEffect, fk.SkillEffect},
  can_refresh = function (self, event, target, player, data)
    return player == player.room.players[1]
  end,
  on_refresh = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.Damage, true)
    if e then
      local dat = e.data[1]
      dat.extra_data = dat.extra_data or {}
      dat.extra_data.renzheng_maxDamage = dat.extra_data.renzheng_maxDamage or 0
      dat.extra_data.renzheng_maxDamage = math.max(dat.damage, dat.extra_data.renzheng_maxDamage)
    end
  end,
}
local jinjian = fk.CreateTriggerSkill{
  name = "jinjian",
  mute = true,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return player:getMark("@@jinjian_plus-turn") > 0 or player.room:askForSkillInvoke(player, self.name, nil, "#jinjian1-invoke::"..data.to.id)
    else
      return player:getMark("@@jinjian_minus-turn") > 0 or player.room:askForSkillInvoke(player, self.name, nil, "#jinjian2-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      if player:getMark("@@jinjian_plus-turn") > 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        room:setPlayerMark(player, "@@jinjian_plus-turn", 0)
        data.damage = data.damage - 1
      else
        room:notifySkillInvoked(player, self.name, "offensive")
        room:setPlayerMark(player, "@@jinjian_plus-turn", 1)
        data.damage = data.damage + 1
      end
    else
      if player:getMark("@@jinjian_minus-turn") > 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        room:setPlayerMark(player, "@@jinjian_minus-turn", 0)
        data.damage = data.damage + 1
      else
        room:notifySkillInvoked(player, self.name, "defensive")
        room:setPlayerMark(player, "@@jinjian_minus-turn", 1)
        data.damage = data.damage - 1
      end
    end
  end,
}
luotong:addSkill(renzheng)
luotong:addSkill(jinjian)
Fk:loadTranslationTable{
  ["ty__luotong"] = "骆统",
  ["#ty__luotong"] = "蹇谔匪躬",
  ["illustrator:ty__luotong"] = "匠人绘",
  ["renzheng"] = "仁政",  --这两个烂大街的技能名大概率撞车叭……
  [":renzheng"] = "锁定技，当有伤害被减少或防止后，你摸两张牌。",
  ["jinjian"] = "进谏",
  [":jinjian"] = "当你造成伤害时，你可令此伤害+1，若如此做，你此回合下次造成的伤害-1且不能发动〖进谏〗；当你受到伤害时，你可令此伤害-1，"..
  "若如此做，你此回合下次受到的伤害+1且不能发动〖进谏〗。",
  ["#jinjian1-invoke"] = "进谏：你可以令对 %dest 造成的伤害+1",
  ["#jinjian2-invoke"] = "进谏：你可以令受到的伤害-1",
  ["@@jinjian_plus-turn"] = "进谏+",
  ["@@jinjian_minus-turn"] = "进谏-",


  ["$renzheng1"] = "仁政如水，可润万物。",
  ["$renzheng2"] = "为官一任，当造福一方。",
  ["$jinjian1"] = "臣代天子牧民，闻苛自当谏之。",
  ["$jinjian2"] = "为将者死战，为臣者死谏！",
  ["~ty__luotong"] = "而立之年，奈何早逝。",
}

local wangchang = General(extension, "ty__wangchang", "wei", 3)
local ty__kaiji = fk.CreateActiveSkill{
  name = "ty__kaiji",
  anim_type = "switch",
  switch_skill_name = "ty__kaiji",
  min_card_num = function ()
    if Self:getSwitchSkillState("ty__kaiji", false) == fk.SwitchYang then
      return 0
    else
      return 1
    end
  end,
  max_card_num = function ()
    if Self:getSwitchSkillState("ty__kaiji", false) == fk.SwitchYang then
      return 0
    else
      return Self.maxHp
    end
  end,
  target_num = 0,
  prompt = function ()
    return "#ty__kaiji-"..Self:getSwitchSkillState("ty__kaiji", false, true)..":::"..Self.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    if Self:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return false
    else
      return #selected < Self.maxHp and not Self:prohibitDiscard(to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      player:drawCards(player.maxHp, self.name)
    else
      room:throwCard(effect.cards, self.name, player, player)
    end
  end,
}
local pingxi = fk.CreateTriggerSkill{
  name = "pingxi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
            return true
          end
        end
      end, Player.HistoryTurn) > 0 and
      table.find(player.room:getOtherPlayers(player), function(p)
        return not p:isNude() or not player:isProhibited(p, Fk:cloneCard("slash"))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile then
          n = n + #move.moveInfo
        end
      end
    end, Player.HistoryTurn)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() or not player:isProhibited(p, Fk:cloneCard("slash"))
    end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#pingxi-choose:::"..n, self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = self.cost_data.tos
    room:sortPlayersByAction(tos)
    for _, id in ipairs(tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p:isNude() and not p.dead then
        local card = room:askForCardChosen(player, p, "he", self.name)
        room:throwCard(card, self.name, p, player)
      end
    end
    for _, id in ipairs(tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        room:useVirtualCard("slash", nil, player, p, self.name, true)
      end
    end
  end,
}
wangchang:addSkill(ty__kaiji)
wangchang:addSkill(pingxi)
Fk:loadTranslationTable{
  ["ty__wangchang"] = "王昶",
  ["#ty__wangchang"] = "攥策及江",
  ["designer:ty__wangchang"] = "韩旭",
  ["illustrator:ty__wangchang"] = "游漫美绘",
  ["ty__kaiji"] = "开济",
  [":ty__kaiji"] = "转换技，出牌阶段限一次，阳：你可以摸体力上限张数的牌；阴：你可以弃置至多体力上限张数的牌（至少一张）。",
  ["pingxi"] = "平袭",
  [":pingxi"] = "结束阶段，你可以选择至多X名其他角色（X为本回合因弃置而进入弃牌堆的牌数），弃置这些角色各一张牌（无牌则不弃），然后视为对"..
  "这些角色各使用一张【杀】。",
  ["#ty__kaiji-yang"] = "开济：你可以摸%arg张牌",
  ["#ty__kaiji-yin"] = "开济：你可以弃置至多%arg张牌",
  ["#pingxi-choose"] = "平袭：你可以选择至多%arg名角色，弃置这些角色各一张牌并视为对这些角色各使用一张【杀】",

  ["$ty__kaiji1"] = "谋虑渊深，料远若近。",
  ["$ty__kaiji2"] = "视昧而察，筹不虚运。",
  ["$pingxi1"] = "地有常险，守无常势。",
  ["$pingxi2"] = "国有常众，战无常胜。",
  ["~ty__wangchang"] = "志存开济，人亡政息……",
}

local chengbing = General(extension, "chengbing", "wu", 3)
local jingzao = fk.CreateActiveSkill{
  name = "jingzao",
  anim_type = "drawcard",
  prompt = function ()
    return "#jingzao-active:::" + tostring(3 + Self:getMark("jingzao-turn"))
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("jingzao-turn") > -3
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("jingzao-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "jingzao-phase", 1)
    local n = 3 + player:getMark("jingzao-turn")
    if n < 1 then return false end
    local cards = room:getNCards(n)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })

    local pattern = table.concat(table.map(cards, function(id) return Fk:getCardById(id).trueName end), ",")
    if #room:askForDiscard(target, 1, 1, true, self.name, true, pattern, "#jingzao-discard:"..player.id) > 0 then
      room:addPlayerMark(player, "jingzao-turn", 1)
      room:moveCards({
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      })
      return
    end

    local to_get = {}
    while #cards > 0 do
      local id = table.random(cards)
      table.insert(to_get, id)
      local name = Fk:getCardById(id).trueName
      cards = table.filter(cards, function (id2)
        return Fk:getCardById(id2).trueName ~= name
      end)
    end
    room:setPlayerMark(player, "jingzao-turn", player:getMark("jingzao-turn") - #to_get)
    room:moveCardTo(to_get, Player.Hand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
  end,
}
local enyu = fk.CreateTriggerSkill{
  name = "enyu",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 2, function (e)
        local use = e.data[1]
        return use.card.trueName == data.card.trueName and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
      end, Player.HistoryTurn) > 1
  end,
  on_use = function(self, event, target, player, data)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,
}
chengbing:addSkill(jingzao)
chengbing:addSkill(enyu)
Fk:loadTranslationTable{
  ["chengbing"] = "程秉",
  ["#chengbing"] = "通达五经",
  ["designer:chengbing"] = "韩旭",
  ["illustrator:chengbing"] = "匠人绘",
  ["jingzao"] = "经造",
  [":jingzao"] = "出牌阶段每名角色限一次，你可以选择一名其他角色并亮出牌堆顶三张牌，然后该角色选择一项："..
  "1.弃置一张与亮出牌同名的牌，然后此技能本回合亮出的牌数+1；"..
  "2.令你随机获得这些牌中牌名不同的牌各一张，每获得一张，此技能本回合亮出的牌数-1。",
  ["enyu"] = "恩遇",
  [":enyu"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，若你本回合已成为过同名牌的目标，此牌对你无效。",
  ["#jingzao-active"] = "经造：选择一名其他角色，亮出牌堆顶的%arg张卡牌",
  ["#jingzao-discard"] = "经造：弃置一张同名牌使本回合“经造”亮出牌+1，或点“取消”令%src获得其中不同牌名各一张",

  ["$jingzao1"] = "闭门绝韦编，造经教世人。",
  ["$jingzao2"] = "著文成经，可教万世之人。",
  ["$enyu1"] = "君以国士待我，我必国士报之。",
  ["$enyu2"] = "吾本乡野腐儒，幸隆君之大恩。",
  ["~chengbing"] = "著经未成，此憾事也……",
}

local yangbiao = General(extension, "ty__yangbiao", "qun", 3)
local ty__zhaohan = fk.CreateTriggerSkill{
  name = "ty__zhaohan",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  on_use = function(self, event, target, player, data)
    data.n = data.n + 2
  end,
}
local ty__zhaohan_delay = fk.CreateTriggerSkill{
  name = "#ty__zhaohan_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player:usedSkillTimes(ty__zhaohan.name, Player.HistoryPhase) > 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:isKongcheng() end), Util.IdMapper)
    if #targets > 0 then
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#zhaohan-choose", self.name, true, true)
    end
    if #targets > 0 then
      local cards = player:getCardIds(Player.Hand)
      if #cards > 2 then
        cards = room:askForCard(player, 2, 2, false, self.name, false, ".", "#zhaohan-give::" .. targets[1])
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, room:getPlayerById(targets[1]), fk.ReasonGive, self.name, nil, false, player.id)
      end
    else
      room:askForDiscard(player, 2, 2, false, self.name, false, ".", "#zhaohan-discard")
    end
  end,
}
local jinjie = fk.CreateTriggerSkill{
  name = "jinjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and player:usedSkillTimes(self.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw0", "draw1", "draw2", "draw3", "Cancel"},
    self.name, "#jinjie-invoke::"..target.id)
    if choice ~= "Cancel" then
      room:doIndicate(player.id, {target.id})
      self.cost_data = tonumber(string.sub(choice, 5, 5))
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    if x > 0 then
      room:drawCards(target, x, self.name)
      if player.dead or #player:getCardIds("he") < x or
      #room:askForDiscard(player, x, x, true, self.name, true, ".", "#jinjie-discard::"..target.id..":"..tostring(x)) == 0 or
      target.dead or not target:isWounded() then return false end
    end
    room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = self.name
    }
  end,
}
local jue = fk.CreateTriggerSkill{
  name = "jue",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not target.dead and target.phase == Player.Finish and
    player:usedSkillTimes(self.name, Player.HistoryRound) < 1 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = turn_event.id
      local cards = {}
      U.getEventsByRule(room, GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
        return false
      end, end_id)
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        self.cost_data = #cards
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    if target == player then
      local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      1, 1, "#jue-choose:::" .. tostring(x), self.name, true)
      if #targets > 0 then
        self.cost_data = {targets[1], x}
        return true
      end
    else
      x = math.min(x, target.maxHp)
      if room:askForSkillInvoke(player, self.name, nil, "#jue-invoke::" .. target.id .. ":" .. tostring(x)) then
        room:doIndicate(player.id, {target.id})
        self.cost_data = {target.id, x}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local x = math.min(self.cost_data[2], to.maxHp)
    for i = 1, x, 1 do
      local cards = {}
      for _, name in ipairs({"slash", "dismantlement", "amazing_grace"}) do
        local card = Fk:cloneCard(name)
        card.skillName = self.name
        if player:canUseTo(card, to, {bypass_distances = true, bypass_times = true}) then
          table.insert(cards, card)
        end
      end
      if #cards == 0 then break end
      local tos = {{to.id}}
      local card = table.random(cards)
      if card.trueName == "amazing_grace" and not player:isProhibited(player, card) then
        table.insert(tos, {player.id})
      end
      room:useCard{
        from = player.id,
        tos = tos,
        card = card,
        extraUse = true
      }
      if player.dead or to.dead then break end
    end
  end,
}
ty__zhaohan:addRelatedSkill(ty__zhaohan_delay)
yangbiao:addSkill(ty__zhaohan)
yangbiao:addSkill(jinjie)
yangbiao:addSkill(jue)
Fk:loadTranslationTable{
  ["ty__yangbiao"] = "杨彪",
  ["#ty__yangbiao"] = "德彰海内",
  ["cv:ty__yangbiao"] = "袁国庆",
  ["illustrator:ty__yangbiao"] = "DH", -- 忧心国事

  ["ty__zhaohan"] = "昭汉",
  [":ty__zhaohan"] = "摸牌阶段，你可以多摸两张牌，然后选择一项：1.交给一名没有手牌的角色两张手牌；2.弃置两张手牌。",
  ["jinjie"] = "尽节",
  [":jinjie"] = "一名角色进入濒死状态时，若你于此轮内未发动过此技能，你可以令其摸0-3张牌，"..
  "然后你可以弃置等量的牌令其回复1点体力。",
  ["jue"] = "举讹",
  [":jue"] = "一名角色的结束阶段，若你于此轮内未发动过此技能，你可以视为随机对其使用【过河拆桥】、【杀】或【五谷丰登】共计X次"..
  "（X为弃牌堆里于此回合内因弃置而移至此区域的牌数且至多为其体力上限，若其为你，改为你选择一名其他角色）。",

  ["#ty__zhaohan_delay"] = "昭汉",
  ["#zhaohan-choose"] = "昭汉：选择一名没有手牌的角色交给其两张手牌，或点“取消”则你弃置两张牌",
  ["#zhaohan-discard"] = "昭汉：弃置两张手牌",
  ["#zhaohan-give"] = "昭汉：选择两张手牌交给 %dest",
  ["draw0"] = "摸零张牌",
  ["draw3"] = "摸三张牌",
  ["#jinjie-invoke"] = "你可以发动 尽节，令 %dest 摸0-3张牌，然后你可以弃等量的牌令其回复体力",
  ["#jinjie-discard"] = "尽节：你可以弃置%arg张手牌，令 %dest 回复1点体力",
  ["#jue-choose"] = "你可以发动 举讹，选择一名其他角色，视为对其随机使用%arg张牌（【过河拆桥】、【杀】或【五谷丰登】）",
  ["#jue-invoke"] = "你可以发动 举讹，视为对 %dest 随机使用%arg张牌（【过河拆桥】、【杀】或【五谷丰登】）",

  ["$ty__zhaohan1"] = "此心昭昭，惟愿汉明。",
  ["$ty__zhaohan2"] = "天曰昭德！天曰昭汉！",
  ["$jinjie1"] = "大汉养士百载，今乃奉节之时。",
  ["$jinjie2"] = "尔等皆忘天地君亲师乎？",
  ["$jue1"] = "尔等一家之言，难堵天下悠悠之口。",
  ["$jue2"] = "区区黄门而敛财千万，可诛其九族。",
  ["~ty__yangbiao"] = "愧无日磾先见之明，犹怀老牛舐犊之爱……",
}

local ruanji = General(extension, "ruanji", "wei", 3)
local zhaowen = fk.CreateViewAsSkill{
  name = "zhaowen",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#zhaowen",
  interaction = function()
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(Self, "zhaowen", all_names, {}, Self:getTableMark("zhaowen-turn"))
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.color == Card.Black and card:getMark("@@zhaowen-turn") > 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("zhaowen-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "zhaowen-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes("zhaowen", Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes("zhaowen", Player.HistoryTurn) > 0 and
      table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-turn") > 0 end)
  end,
}
local zhaowen_trigger = fk.CreateTriggerSkill{
  name = "#zhaowen_trigger",
  main_skill = zhaowen,
  mute = true,
  events = {fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhaowen) and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return not player:isKongcheng()
      else
        return data.card.color == Card.Red and not data.card:isVirtual() and data.card:getMark("@@zhaowen-turn") > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, "zhaowen", nil, "#zhaowen-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhaowen")
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "zhaowen", "special")
      local cards = table.simpleClone(player:getCardIds("h"))
      player:showCards(cards)
      if not player.dead and not player:isKongcheng() then
        room:setPlayerMark(player, "zhaowen-turn", cards)
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id, true), "@@zhaowen-turn", 1)
        end
      end
    else
      room:notifySkillInvoked(player, "zhaowen", "drawcard")
      player:drawCards(1, "zhaowen")
    end
  end,

  refresh_events = {fk.AfterCardsMove, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Death and player ~= target then return end
    return player:getMark("zhaowen-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("zhaowen-turn")
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea ~= Card.Processing then
          for _, info in ipairs(move.moveInfo) do
            table.removeOne(mark, info.cardId)
            room:setCardMark(Fk:getCardById(info.cardId), "@@zhaowen-turn", 0)
          end
        end
      end
      room:setPlayerMark(player, "zhaowen-turn", mark)
    elseif event == fk.Death then
      for _, id in ipairs(mark) do
        room:setCardMark(Fk:getCardById(id), "@@zhaowen-turn", 0)
      end
    end
  end,
}
local jiudun = fk.CreateTriggerSkill{
  name = "jiudun",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.color == Card.Black and data.from ~= player.id and
      (player.drank + player:getMark("@jiudun_drank") == 0 or not player:isKongcheng())
  end,
  on_cost = function(self, event, target, player, data)
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      return player.room:askForSkillInvoke(player, self.name, nil, "#jiudun-invoke")
    else
      local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|hand", "#jiudun-card:::"..data.card:toLogString(), true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.drank + player:getMark("@jiudun_drank") == 0 then
      player:drawCards(1, self.name)
      room:useVirtualCard("analeptic", nil, player, player, self.name, false)
    else
      room:throwCard(self.cost_data, self.name, player, player)
      if data.card.sub_type == Card.SubtypeDelayedTrick then
        AimGroup:cancelTarget(data, player.id)
      else
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    end
  end,
}

local jiudun__analepticSkill = fk.CreateActiveSkill{
  name = "jiudun__analepticSkill",
  prompt = "#analeptic_skill",
  max_turn_use_time = 1,
  mod_target_filter = function(self, to_select, _, _, card, _)
    return not table.find(Fk:currentRoom().alive_players, function(p)
      return p.dying
    end)
  end,
  can_use = function(self, player, card, extra_data)
    return ((extra_data and (extra_data.bypass_times or extra_data.analepticRecover)) or
      self:withinTimesLimit(player, Player.HistoryTurn, card, "analeptic", player))
  end,
  on_use = function(_, _, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end

    if use.extra_data and use.extra_data.analepticRecover then
      use.extraUse = true
    end
  end,
  on_effect = function(_, room, effect)
    local to = room:getPlayerById(effect.to)
    if to.dead then return end
    if effect.extra_data and effect.extra_data.analepticRecover then
      room:recover({
        who = to,
        num = 1,
        recoverBy = room:getPlayerById(effect.from),
        card = effect.card,
      })
    else
      room:addPlayerMark(to, "@jiudun_drank", 1 + ((effect.extra_data or {}).additionalDrank or 0))
    end
  end,
}
jiudun__analepticSkill.cardSkill = true
Fk:addSkill(jiudun__analepticSkill)

local jiudun_rule = fk.CreateTriggerSkill{
  name = "#jiudun_rule",
  events = {fk.PreCardEffect},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiudun) and data.to == player.id and data.card.trueName == "analeptic" and
    not (data.extra_data and data.extra_data.analepticRecover)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = jiudun__analepticSkill
    data.card = card
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and player:getMark("@jiudun_drank") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@jiudun_drank")
    data.extra_data = data.extra_data or {}
    data.extra_data.drankBuff = player:getMark("@jiudun_drank")
    player.room:setPlayerMark(player, "@jiudun_drank", 0)
  end,
}
zhaowen:addRelatedSkill(zhaowen_trigger)
jiudun:addRelatedSkill(jiudun_rule)
ruanji:addSkill(zhaowen)
ruanji:addSkill(jiudun)
Fk:loadTranslationTable{
  ["ruanji"] = "阮籍",
  ["#ruanji"] = "命世大贤",
  ["designer:ruanji"] = "韩旭",
  ["illustrator:ruanji"] = "匠人绘",
  ["zhaowen"] = "昭文",
  [":zhaowen"] = "出牌阶段开始时，你可以展示所有手牌。若如此做，本回合其中的黑色牌可以当任意一张普通锦囊牌使用（每回合每种牌名限一次），"..
  "其中的红色牌你使用时摸一张牌。",
  ["jiudun"] = "酒遁",
  [":jiudun"] = "以使用方法①使用的【酒】对你的作用效果改为：目标角色使用的下一张[杀]的伤害值基数+1。"..
  "当你成为其他角色使用黑色牌的目标后，若你未处于【酒】状态，你可以摸一张牌并视为使用一张【酒】；"..
  "若你处于【酒】状态，你可以弃置一张手牌令此牌对你无效。",

  ["#zhaowen"] = "昭文：将一张黑色“昭文”牌当任意普通锦囊牌使用（每回合每种牌名限一次）",
  ["#zhaowen_trigger"] = "昭文",
  ["#zhaowen-invoke"] = "昭文：你可以展示手牌，本回合其中黑色牌可以当任意锦囊牌使用，红色牌使用时摸一张牌",
  ["@@zhaowen-turn"] = "昭文",
  ["#jiudun-invoke"] = "酒遁：你可以摸一张牌，视为使用【酒】",
  ["#jiudun-card"] = "酒遁：你可以弃置一张手牌，令%arg对你无效",
  ["#jiudun_rule"] = "酒遁",
  ["@jiudun_drank"] = "酒",

  ["$zhaowen1"] = "我辈昭昭，正始之音浩荡。",
  ["$zhaowen2"] = "正文之昭，微言之绪，绝而复续。",
  ["$jiudun1"] = "籍不胜酒力，恐失言失仪。",
  ["$jiudun2"] = "秋月春风正好，不如大醉归去。",
  ["~ruanji"] = "诸君，欲与我同醉否？",
}

local cuiyanmaojie = General(extension, "ty__cuiyanmaojie", "wei", 3)
local ty__zhengbi = fk.CreateTriggerSkill{
  name = "ty__zhengbi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and #player.room.alive_players > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "ex__choose_skill", "#ty__zhengbi-choose", true, {
      targets = table.map(room:getOtherPlayers(player), Util.IdMapper),
      min_c_num = 0,
      max_c_num = 1,
      min_t_num = 1,
      max_t_num = 1,
      pattern = ".|.|.|.|.|basic",
      skillName = self.name,
    }, false)
    if success and dat then
      if #dat.cards > 0 then
        self.cost_data = {tos = dat.targets, cards = dat.cards}
      else
        self.cost_data = {tos = dat.targets}
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    if self.cost_data.cards then
      room:moveCardTo(self.cost_data.cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, player.id)
      if player.dead or to.dead or to:isNude() then return end
      local cards = to:getCardIds("he")
      if #cards > 1 then
        local choices = {}
        local num = #table.filter(to:getCardIds(Player.Hand), function(id)
          return Fk:getCardById(id).type == Card.TypeBasic end)
        if num > 1 then
          table.insert(choices, "zhengbi__basic-back:"..player.id)
        end
        if #to:getCardIds("he") - num > 0 then
          table.insert(choices, "zhengbi__nobasic-back:"..player.id)
        end
        if #choices == 0 then return end
        local choice = room:askForChoice(to, choices, self.name)
        if choice:startsWith("zhengbi__basic-back") then
          cards = room:askForCard(to, 2, 2, false, self.name, false, ".|.|.|.|.|basic", "#ld__zhengbi-give1:"..player.id)
        else
          cards = room:askForCard(to, 1, 1, true, self.name, false, ".|.|.|.|.|^basic", "#ld__zhengbi-give2:"..player.id)
        end
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, to.id)
    else
      room:setPlayerMark(player, "ty__zhengbi-phase", to.id)
    end
  end,
}
local ty__zhengbi_delay = fk.CreateTriggerSkill{
  name = "#ty__zhengbi_delay",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and player:getMark("ty__zhengbi-phase") ~= 0 then
      local room = player.room
      local p = room:getPlayerById(player:getMark("ty__zhengbi-phase"))
      if p.dead or p:isNude() then return end
      return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          return move.to == p.id and move.toArea == Card.PlayerHand
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ty__zhengbi")
    room:notifySkillInvoked(player, "ty__zhengbi", "control")
    local to = room:getPlayerById(player:getMark("ty__zhengbi-phase"))
    room:doIndicate(player.id, {to.id})
    local cards = U.askforCardsChosenFromAreas(player, to, "he", self.name, nil, nil, false)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
  end,
}
local ty__fengying = fk.CreateActiveSkill{
  name = "ty__fengying",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  prompt = function(self, card)
    return "#ty__fengying"
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      table.find(player:getCardIds("h"), function(id)
        return not player:prohibitDiscard(Fk:getCardById(id))
    end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:throwAllCards("h")
    if not player.dead then
      player:gainAnExtraTurn(true, self.name)
    end
  end,
}
local ty__fengying_delay = fk.CreateTriggerSkill{
  name = "#ty__fengying_delay",
  mute = true,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:insideExtraTurn() and player:getCurrentExtraTurnReason() == "ty__fengying" and
      player:getHandcardNum() < player.maxHp and
      table.every(player.room.alive_players, function (p)
        return p.hp >= player.hp
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), "ty__fengying")
  end,
}
ty__zhengbi:addRelatedSkill(ty__zhengbi_delay)
ty__fengying:addRelatedSkill(ty__fengying_delay)
cuiyanmaojie:addSkill(ty__zhengbi)
cuiyanmaojie:addSkill(ty__fengying)
Fk:loadTranslationTable{
  ["ty__cuiyanmaojie"] = "崔琰毛玠",
  ["#ty__cuiyanmaojie"] = "日出月盛",
  ["illustrator:ty__cuiyanmaojie"] = "罔両",
  ["~ty__cuiyanmaojie"] = "为世所痛惜，冤哉！",

  ["ty__zhengbi"] = "征辟",
  [":ty__zhengbi"] = "出牌阶段开始时，你可以选择一名其他角色并选择一项：1.此阶段结束时，若其此阶段获得过手牌，你获得其一张手牌和装备区内"..
  "一张牌；2.交给其一张基本牌，然后其交给你一张非基本牌或两张基本牌。",
  ["ty__fengying"] = "奉迎",
  [":ty__fengying"] = "限定技，出牌阶段，你可以弃置所有手牌，若如此做，此回合结束后，你执行一个额外回合，此额外回合开始时，若你的体力值"..
  "全场最少，你将手牌摸至体力上限。",
  ["#ty__zhengbi-choose"] = "征辟：选择一名角色<br>点“确定”，若其此阶段获得手牌，此阶段结束时你获得其牌；<br>"..
  "选一张基本牌点“确定”，将此牌交给其，然后其交给你一张非基本牌或两张基本牌。",
  ["#ty__zhengbi_delay"] = "征辟",
  ["#ty__fengying"] = "奉迎：你可以弃置所有手牌，此回合结束后执行一个额外回合！",
  ["#ty__fengying_delay"] = "奉迎",

  ["$ty__zhengbi1"] = "跅弛之士，在御之而已。",
  ["$ty__zhengbi2"] = "内不避亲，外不避仇。",
  ["$ty__fengying1"] = "二臣恭奉，以迎皇嗣。",
  ["$ty__fengying2"] = "奉旨典选，以迎忠良。",
}

--钟灵毓秀：董贵人 滕芳兰 张瑾云 周不疑 许靖 关樾 诸葛京
local dongguiren = General(extension, "dongguiren", "qun", 3, 3, General.Female)
local lianzhi = fk.CreateTriggerSkill{
  name = "lianzhi",
  anim_type = "special",
  events = {fk.GameStart, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        return player:getMark(self.name) == target.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    if event == fk.GameStart then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhi-choose", self.name, false, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(player, self.name, to.id)
    else
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#lianzhi2-choose", self.name, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        room:handleAddLoseSkills(player, "shouze", nil, true, false)
        room:handleAddLoseSkills(to, "shouze", nil, true, false)
        room:addPlayerMark(to, "@dongguiren_jiao", math.max(player:getMark("@dongguiren_jiao"), 1))
      end
    end
  end,
}
local lianzhi_trigger = fk.CreateTriggerSkill{
  name = "#lianzhi_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianzhi) and player:getMark("lianzhi") ~= 0 and
      not player.room:getPlayerById(player:getMark("lianzhi")).dead and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("lianzhi")
    room:notifySkillInvoked(player, "lianzhi", "support")
    local lianzhi_id = player:getMark("lianzhi")
    local to = room:getPlayerById(lianzhi_id)
    if player:getMark("@lianzhi") == 0 then
      room:setPlayerMark(player, "@lianzhi", to.general)
    end
    room:doIndicate(player.id, {lianzhi_id})
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = "lianzhi"
    })
    if not player.dead then
      player:drawCards(1, "lianzhi")
    end
    if not to.dead then
      to:drawCards(1, "lianzhi")
    end
  end,
}
local lingfang = fk.CreateTriggerSkill{
  name = "lingfang",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return player == target and player.phase == Player.Start
    elseif event == fk.CardUseFinished then
      if data.card.color == Card.Black and data.tos then
        if target == player then
          return table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id end)
        else
          return table.contains(TargetGroup:getRealTargets(data.tos), player.id)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@dongguiren_jiao", 1)
  end,
}
local fengying = fk.CreateViewAsSkill{
  name = "fengying",
  anim_type = "special",
  pattern = ".",
  prompt = "#fengying",
  interaction = function()
    local all_names, names = Self:getTableMark("@$fengying"), {}
    for _, name in ipairs(all_names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = "fengying"
      if ((Fk.currentResponsePattern == nil and to_use.skill:canUse(Self, to_use) and not Self:prohibitUse(to_use)) or
         (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use))) then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).number <= Self:getMark("@dongguiren_jiao") and
      Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("@$fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if to_use.skill:canUse(player, to_use) and not player:prohibitUse(to_use) then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    local names = player:getMark("@$fengying")
    if player:getMark("@dongguiren_jiao") == 0 or type(names) ~= "table" then return false end
    for _, name in ipairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(to_use)) then
        return true
      end
    end
  end,
  before_use = function(self, player, useData)
    useData.extraUse = true
    local names = player:getTableMark("@$fengying")
    if table.removeOne(names, useData.card.name) then
      player.room:setPlayerMark(player, "@$fengying", names)
    end
  end,
}
local fengying_trigger = fk.CreateTriggerSkill{
  name = "#fengying_trigger",
  events = {fk.TurnStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fengying)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(room.discard_pile) do
      local card = Fk:getCardById(id)
      if card.color == Card.Black and (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(names, card.name)
      end
    end
    room:setPlayerMark(player, "@$fengying", #names > 0 and names or 0)
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == fengying
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$fengying", 0)
  end,
}
local fengying_targetmod = fk.CreateTargetModSkill{
  name = "#fengying_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, "fengying")
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "fengying")
  end,
}
local shouze = fk.CreateTriggerSkill{
  name = "shouze",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and player:getMark("@dongguiren_jiao") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@dongguiren_jiao", 1)
    local card = room:getCardsFromPileByRule(".|.|spade,club", 1, "discardPile")
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    room:loseHp(player, 1, self.name)
  end,
}
lianzhi:addRelatedSkill(lianzhi_trigger)
fengying:addRelatedSkill(fengying_trigger)
fengying:addRelatedSkill(fengying_targetmod)
dongguiren:addSkill(lianzhi)
dongguiren:addSkill(lingfang)
dongguiren:addSkill(fengying)
dongguiren:addRelatedSkill(shouze)
Fk:loadTranslationTable{
  ["dongguiren"] = "董贵人",
  ["#dongguiren"] = "衣雪宫柳",
  ["designer:dongguiren"] = "韩旭",
  ["illustrator:dongguiren"] = "君桓文化",
  ["lianzhi"] = "连枝",
  [":lianzhi"] = "游戏开始时，你选择一名其他角色。每回合限一次，当你进入濒死状态时，若该角色没有死亡，你回复1点体力且与其各摸一张牌。"..
  "该角色死亡时，你可以选择一名其他角色，你与其获得〖受责〗，其获得与你等量的“绞”标记（至少1个）。",
  ["lingfang"] = "凌芳",
  [":lingfang"] = "锁定技，准备阶段或当其他角色对你使用或你对其他角色使用的黑色牌结算后，你获得一枚“绞”标记。",
  ["fengying"] = "风影",
  ["#fengying_trigger"] = "风影",
  [":fengying"] = "一名角色的回合开始时，你记录弃牌堆中的黑色基本牌和黑色普通锦囊牌牌名。"..
  "你可以将一张点数不大于“绞”标记数的手牌当一张记录的本回合未以此法使用过的牌使用（无距离和次数限制）。",
  ["shouze"] = "受责",
  [":shouze"] = "锁定技，结束阶段，你弃置一枚“绞”，然后随机获得弃牌堆一张黑色牌并失去1点体力。",
  ["@lianzhi"] = "连枝",
  ["#lianzhi-choose"] = "连枝：选择一名角色成为“连枝”角色",
  ["#lianzhi2-choose"] = "连枝：你可以选择一名角色，你与其获得技能〖受责〗",
  ["@dongguiren_jiao"] = "绞",
  ["@$fengying"] = "风影",
  ["#fengying"] = "发动风影，将一张点数不大于绞标记数的手牌当一张记录的牌使用",

  ["$lianzhi1"] = "刘董同气连枝，一损则俱损。",
  ["$lianzhi2"] = "妾虽女流，然亦有忠侍陛下之心。",
  ["$lingfang1"] = "曹贼欲加之罪，何患无据可言。",
  ["$lingfang2"] = "花落水自流，何须怨东风。",
  ["$fengying1"] = "可怜东篱寒累树，孤影落秋风。",
  ["$fengying2"] = "西风落，西风落，宫墙不堪破。",
  ["~dongguiren"] = "陛下乃大汉皇帝，不可言乞。",
}

local tengfanglan = General(extension, "ty__tengfanglan", "wu", 3, 3, General.Female)
local ty__luochong = fk.CreateTriggerSkill{
  name = "ty__luochong",
  anim_type = "control",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:getMark(self.name) < 4 and
      not table.every(player.room.alive_players, function (p) return p:isAllNude() end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local total = 4 - player:getMark(self.name)
    local n = total
    local to, targets, cards
    local luochong_map = {}
    repeat
      targets = table.map(table.filter(room.alive_players, function(p)
        return not p:isAllNude() end), Util.IdMapper)
      if #targets == 0 then break end
      targets = room:askForChoosePlayers(player, targets, 1, 1,
        "#ty__luochong-choose:::"..tostring(total)..":"..tostring(n), self.name, true)
      if #targets == 0 then break end
      to = room:getPlayerById(targets[1])
      cards = room:askForCardsChosen(player, to, 1, n, "hej", self.name)
      room:throwCard(cards, self.name, to, player)
      luochong_map[to.id] = luochong_map[to.id] or 0
      luochong_map[to.id] = luochong_map[to.id] + #cards
      n = n - #cards
      if n <= 0 then break end
    until total == 0 or player.dead
    for _, value in pairs(luochong_map) do
      if value > 2 then
        room:addPlayerMark(player, self.name, 1)
        break
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
local ty__aichen = fk.CreateTriggerSkill{
  name = "ty__aichen",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.EventPhaseChanging, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove and #player.room.draw_pile > 80 and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 then
        for _, move in ipairs(data) do
          if move.skillName == "ty__luochong" and move.from == player.id then
            return true
          end
        end
      elseif event == fk.EventPhaseChanging and #player.room.draw_pile > 40 then
        return target == player and data.to == Player.Discard
      elseif event == fk.TargetConfirmed and #player.room.draw_pile < 40 then
        return target == player and data.card.type ~= Card.TypeEquip and data.card.suit == Card.Spade
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(2, self.name)
    elseif event == fk.EventPhaseChanging then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "defensive")
      return true
    elseif event == fk.TargetConfirmed then
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "negative")
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertIfNeed(data.disresponsiveList, player.id)
    end
  end,
}
tengfanglan:addSkill(ty__luochong)
tengfanglan:addSkill(ty__aichen)
Fk:loadTranslationTable{
  ["ty__tengfanglan"] = "滕芳兰",
  ["#ty__tengfanglan"] = "铃兰零落",
  ["designer:ty__tengfanglan"] = "步穗",
  ["illustrator:ty__tengfanglan"] = "鬼画府",
  ["ty__luochong"] = "落宠",
  [":ty__luochong"] = "每轮开始时，你可以弃置任意名角色区域内共计至多4张牌，若你一次性弃置了一名角色区域内至少3张牌，〖落宠〗弃置牌数-1。",
  ["ty__aichen"] = "哀尘",
  [":ty__aichen"] = "锁定技，若剩余牌堆数大于80，当你发动〖落宠〗弃置自己区域内的牌后，你摸两张牌；"..
  "若剩余牌堆数大于40，你跳过弃牌阶段；若剩余牌堆数小于40，当你成为♠牌的目标后，你不能响应此牌。",
  ["#ty__luochong-choose"] = "落宠：你可以依次选择角色，弃置其区域内的牌（共计至多%arg张，还剩%arg2张）",

  ["$ty__luochong1"] = "陛下独宠她人，奈何雨露不均。",
  ["$ty__luochong2"] = "妾贵于佳丽，然宠不及三千。",
  ["$ty__aichen1"] = "君可负妾，然妾不负君。",
  ["$ty__aichen2"] = "所思所想，皆系陛下。",
  ["~ty__tengfanglan"] = "今生缘尽，来世两宽……",
}

local zhangjinyun = General(extension, "zhangjinyun", "shu", 3, 3, General.Female)
local huizhi = fk.CreateTriggerSkill{
  name = "huizhi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local discard_data = {
      num = 999,
      min_num = 0,
      include_equip = false,
      skillName = self.name,
      pattern = ".",
    }
    local success, ret = player.room:askForUseActiveSkill(player, "discard_skill", "#huizhi-invoke", true, discard_data)
    if success then
      self.cost_data = ret.cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:throwCard(self.cost_data, self.name, player, player)
    end
    if player.dead then return end
    local n = 0
    for _, p in ipairs(room.alive_players) do
      n = math.max(n, p:getHandcardNum())
    end
    room:drawCards(player, math.max(math.min(n - player:getHandcardNum(), 5), 1), self.name)
  end,
}
local jijiao = fk.CreateActiveSkill{
  name = "jijiao",
  prompt = "#jijiao-active",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local ids = {}
    local discard_pile = table.simpleClone(room.discard_pile)
    local logic = room.logic
    local events = logic.event_recorder[GameEvent.MoveCards] or Util.DummyTable
    for i = #events, 1, -1 do
      local e = events[i]
      local move_by_use = false
      local parentUseEvent = e:findParent(GameEvent.UseCard)
      if parentUseEvent then
        local use = parentUseEvent.data[1]
        if use.from == effect.from then
          move_by_use = true
        end
      end
      for _, move in ipairs(e.data) do
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.removeOne(discard_pile, id) and Fk:getCardById(id):isCommonTrick() then
            if move.toArea == Card.DiscardPile then
              if move.moveReason == fk.ReasonUse and move_by_use then
                table.insert(ids, id)
              elseif move.moveReason == fk.ReasonDiscard and move.from == player.id then
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  table.insert(ids, id)
                end
              end
            end
          end
        end
      end
      if #discard_pile == 0 then break end
    end

    if #ids > 0 then
      room:obtainCard(target.id, ids, false, fk.ReasonJustMove, target.id, self.name, "@@jijiao-inhand")
    end
  end,
}
local jijiao_delay = fk.CreateTriggerSkill{
  name = "#jijiao_delay",
  anim_type = "special",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(jijiao, true) and player:usedSkillTimes("jijiao", Player.HistoryGame) > 0 then
      if player:getMark("jijiao-turn") > 0 then return true end
      local logic = player.room.logic
      local deathevents = logic.event_recorder[GameEvent.Death] or Util.DummyTable
      local turnevents = logic.event_recorder[GameEvent.Turn] or Util.DummyTable
      return #deathevents > 0 and #turnevents > 0 and deathevents[#deathevents].id > turnevents[#turnevents].id
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:setSkillUseHistory("jijiao", 0, Player.HistoryGame)
  end,

  refresh_events = {fk.AfterDrawPileShuffle, fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      return player == target and not data.card:isVirtual() and data.card:getMark("@@jijiao-inhand") > 0
    else
      return player:getMark("jijiao-turn") == 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      data.unoffsetableList = table.map(player.room.alive_players, Util.IdMapper)
    else
      player.room:setPlayerMark(player, "jijiao-turn", 1)
    end
  end,
}
jijiao:addRelatedSkill(jijiao_delay)
zhangjinyun:addSkill(huizhi)
zhangjinyun:addSkill(jijiao)
Fk:loadTranslationTable{
  ["zhangjinyun"] = "张瑾云",
  ["#zhangjinyun"] = "慧秀淑德",
  ["designer:zhangjinyun"] = "韩旭",
  ["illustrator:zhangjinyun"] = "匠人绘",
  ["huizhi"] = "蕙质",
  [":huizhi"] = "准备阶段，你可以弃置任意张手牌（可不弃），然后将手牌摸至与全场手牌最多的角色相同（至少摸一张，最多摸五张）。",
  ["jijiao"] = "继椒",
  [":jijiao"] = "限定技，出牌阶段，你可以令一名角色获得弃牌堆中本局游戏你使用和弃置的所有普通锦囊牌，这些牌不能被抵消。"..
  "每回合结束后，若此回合内牌堆洗过牌或有角色死亡，复原此技能。",
  ["#huizhi-invoke"] = "蕙质：你可以弃置任意张手牌，然后将手牌摸至与全场手牌最多的角色相同（最多摸五张）",
  ["#jijiao-active"] = "发动 继椒，令一名角色获得弃牌堆中你使用或弃置的所有普通锦囊牌",
  ["#jijiao_delay"] = "继椒",
  ["@@jijiao-inhand"] = "继椒",

  ["$huizhi1"] = "妾有一席幽梦，予君三千暗香。",
  ["$huizhi2"] = "我有玲珑之心，其情唯衷陛下。",
  ["$jijiao1"] = "哀吾姊早逝，幸陛下垂怜。",
  ["$jijiao2"] = "居椒之殊荣，妾得之惶恐。",
  ["~zhangjinyun"] = "陛下，妾身来陪你了……",
}

local zhoubuyi = General(extension, "zhoubuyi", "wei", 3)
local shijiz = fk.CreateTriggerSkill{
  name = "shijiz",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish and not target:isNude() then
      local events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[5]
        return damage and target == damage.from
      end, Player.HistoryTurn)
      return #events == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("shijiz_names")
    if type(mark) ~= "table" then
      mark = U.getAllCardNames("t")
      room:setPlayerMark(player, "shijiz_names", mark)
    end
    local used = player:getTableMark("@$shijiz-round")
    local all_names, names = {}, {}
    for _, name in ipairs(mark) do
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      if target:canUse(card) and not target:prohibitUse(card) then
        table.insert(all_names, name)
        if not table.contains(used, name) then
          table.insert(names, name)
        end
      end
    end
    local choices = U.askForChooseCardNames(room, player, names, 1, 1, self.name, "#shijiz-invoke::"..target.id, all_names, true)
    if #choices == 1 then
      self.cost_data = {tos = {target.id}, choice = choices[1]}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cardName = self.cost_data.choice
    room:addTableMark(player, "@$shijiz-round", cardName)
    local success, dat = room:askForUseActiveSkill(target, "shijiz_viewas", "#shijiz-use:::"..cardName, true,
    {shijiz_name = cardName})
    if dat then
      local card = Fk:cloneCard(cardName)
      card:addSubcards(dat.cards)
      card.skillName = self.name
      room:useCard{
        from = target.id,
        tos = table.map(dat.targets, function(p) return {p} end),
        card = card,
      }
    end
  end,
}
local shijiz_viewas = fk.CreateViewAsSkill{
  name = "shijiz_viewas",
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.shijiz_name)
    card:addSubcard(cards[1])
    card.skillName = "shijiz"
    return card
  end,
}
local shijiz_prohibit = fk.CreateProhibitSkill{
  name = "#shijiz_prohibit",
  is_prohibited = function(self, from, to, card)
    return card and from == to and table.contains(card.skillNames, "shijiz")
  end,
}
local silun = fk.CreateTriggerSkill{
  name = "silun",
  anim_type = "masochism",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(4, self.name)
    for i = 1, 4, 1 do
      if player.dead or player:isNude() then return end
      local _, dat = room:askForUseActiveSkill(player, "silun_active", "#silun-card:::" .. tostring(i), false)
      local card_id = dat and dat.cards[1] or player:getCardIds("he")[1]
      local choice = dat and dat.interaction or "Top"
      local reset_self = room:getCardArea(card_id) == Card.PlayerEquip
      if choice == "Field" then
        local to = room:getPlayerById(dat.targets[1])
        local card = Fk:getCardById(card_id)
        if card.type == Card.TypeEquip then
          room:moveCardTo(card, Card.PlayerEquip, to, fk.ReasonPut, "silun", "", true, player.id)
          if not to.dead then
            to:reset()
          end
        elseif card.sub_type == Card.SubtypeDelayedTrick then
          -- FIXME : deal with visual DelayedTrick
          room:moveCardTo(card, Card.PlayerJudge, to, fk.ReasonPut, "silun", "", true, player.id)
        end
      else
        local drawPilePosition = 1
        if choice == "Bottom" then
          drawPilePosition = -1
        end
        room:moveCards({
          ids = {card_id},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = "silun",
          drawPilePosition = drawPilePosition,
          moveVisible = true
        })
      end
      if reset_self and not player.dead then
        player:reset()
      end
    end
  end,
}
local silun_active = fk.CreateActiveSkill{
  name = "silun_active",
  mute = true,
  card_num = 1,
  max_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"Field", "Top", "Bottom"}}
  end,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      if self.interaction.data == "Field" then
        local card = Fk:getCardById(to_select)
        return card.type == Card.TypeEquip or card.sub_type == Card.SubtypeDelayedTrick
      end
      return true
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and self.interaction.data == "Field" and #selected_cards == 1 then
      local card = Fk:getCardById(selected_cards[1])
      local target = Fk:currentRoom():getPlayerById(to_select)
      if card.type == Card.TypeEquip then
        return target:hasEmptyEquipSlot(card.sub_type)
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        return not target:isProhibited(target, card)
      end
    end
    return false
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards == 1 then
      if self.interaction.data == "Field" then
        return #selected == 1
      else
        return true
      end
    end
  end,
}
Fk:addSkill(shijiz_viewas)
shijiz:addRelatedSkill(shijiz_prohibit)
Fk:addSkill(silun_active)
zhoubuyi:addSkill(shijiz)
zhoubuyi:addSkill(silun)
Fk:loadTranslationTable{
  ["zhoubuyi"] = "周不疑",
  ["#zhoubuyi"] = "幼有异才",
  ["designer:zhoubuyi"] = "拔都沙皇",
  ["illustrator:zhoubuyi"] = "虫师",
  ["shijiz"] = "十计",
  [":shijiz"] = "一名角色的结束阶段，若其本回合未造成伤害，你可以声明一种普通锦囊牌（每轮每种牌名限一次），其可以将一张牌当你声明的牌使用"..
  "（不能指定其为目标）。",
  ["silun"] = "四论",
  [":silun"] = "准备阶段或当你受到伤害后，你可以摸四张牌，然后将四张牌依次置于场上、牌堆顶或牌堆底，若此牌为你装备区里的牌，你复原武将牌，"..
  "若你将装备牌置于一名角色装备区，其复原武将牌。",
  ["@$shijiz-round"] = "十计",
  ["#shijiz-invoke"] = "十计：选择一种锦囊，%dest 可将一张牌当此牌使用(不能指定其为目标)",
  ["shijiz_viewas"] = "十计",
  ["#shijiz-use"] = "十计：你可以将一张牌当【%arg】使用",
  ["silun_active"] = "四论",
  ["#silun-card"] = "四论：将一张牌置于场上、牌堆顶或牌堆底（第%arg张/共4张）",
  ["Field"] = "场上",

  ["$shijiz1"] = "哼~区区十丈之城，何须丞相图画。",
  ["$shijiz2"] = "顽垒在前，可依不疑之计施为。",
  ["$silun1"] = "习守静之术，行务时之风。",
  ["$silun2"] = "纵笔瑞白雀，满座尽高朋。",
  ["~zhoubuyi"] = "人心者，叵测也。",
}

local xujing = General(extension, "ty__xujing", "shu", 3)
local shangyu = fk.CreateTriggerSkill{
  name = "shangyu",
  anim_type = "support",
  events = {fk.AfterCardsMove, fk.Damage, fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      local cid = player:getMark("shangyu_slash")
      if player.room:getCardArea(cid) ~= Card.DiscardPile then return false end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if info.cardId == cid then
              return true
            end
          end
        end
      end
    elseif event == fk.Damage then
      if data.card and data.card.trueName == "slash" then
        local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
        if #cardlist == 1 and cardlist[1] == player:getMark("shangyu_slash") then
          local room = player.room
          local parentUseEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
          if parentUseEvent then
            local use = parentUseEvent.data[1]
            local from = room:getPlayerById(use.from)
            if from and not from.dead then
              self.cost_data = use.from
              return true
            end
          end
        end
      end
    elseif event == fk.GameStart then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local targets = table.map(room.alive_players, Util.IdMapper)
      local marks = player:getMark("shangyu_prohibit-turn")
      if type(marks) == "table" then
        targets = table.filter(targets, function (pid)
          return not table.contains(marks, pid)
        end)
      else
        marks = {}
      end
      if #targets == 0 then return false end
      local card = Fk:getCardById(player:getMark("shangyu_slash"))
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#shangyu-give:::" .. card:toLogString(), self.name, false)
      if #to > 0 then
        table.insert(marks, to[1])
        room:setPlayerMark(player, "shangyu_prohibit-turn", marks)
        room:moveCardTo(card, Card.PlayerHand, room:getPlayerById(to[1]), fk.ReasonGive, self.name, nil, true, player.id)
      end
    elseif event == fk.Damage then
      local tar = room:getPlayerById(self.cost_data)
      room:doIndicate(player.id, {self.cost_data})
      room:drawCards(player, 1, self.name)
      if not tar.dead then
        room:drawCards(tar, 1, self.name)
      end
    elseif event == fk.GameStart then
      local cards = room:getCardsFromPileByRule("slash", 1)
      if #cards > 0 then
        local cid = cards[1]
        room:setPlayerMark(player, "shangyu_slash", cid)
        local card = Fk:getCardById(cid)
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
        if player.dead or not table.contains(player:getCardIds(Player.Hand), cid) then return false end
        local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
        "#shangyu-give:::" .. card:toLogString(), self.name, true)
        if #to > 0 then
          room:moveCardTo(card, Card.PlayerHand, room:getPlayerById(to[1]), fk.ReasonGive, self.name, nil, true, player.id)
        end
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return not player.dead and player:getMark("shangyu_slash") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cid = player:getMark("shangyu_slash")
    local card = Fk:getCardById(cid)
    if room:getCardArea(cid) == Card.PlayerHand and card:getMark("@@shangyu-inhand") == 0 then
      room:setCardMark(Fk:getCardById(cid), "@@shangyu-inhand", 1)
    end
  end,
}

local caixia = fk.CreateTriggerSkill{
  name = "caixia",
  events = {fk.Damage, fk.Damaged, fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUsing then
      return player == target and player:getMark("@caixia") > 0
    else
      return player == target and player:getMark("@caixia") == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return true
    else
      local room = player.room
      local choices = {}
      for i = 1, math.min(5, #room.players), 1 do
        table.insert(choices, "caixia_draw" .. tostring(i))
      end
      table.insert(choices, "Cancel")
      local choice = room:askForChoice(player, choices, self.name, "#caixia-draw")
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:removePlayerMark(player, "@caixia")
    else
      room:notifySkillInvoked(player, self.name, event == fk.Damaged and "masochism" or "drawcard")
      player:broadcastSkillInvoke(self.name)
      local x = tonumber(string.sub(self.cost_data, 12, 12))
      room:setPlayerMark(player, "@caixia", x)
      room:drawCards(player, x, self.name)
    end
  end
}
xujing:addSkill(shangyu)
xujing:addSkill(caixia)
Fk:loadTranslationTable{
  ["ty__xujing"] = "许靖",
  ["#ty__xujing"] = "璞玉有瑕",
  ["designer:ty__xujing"] = "步穗",
  ["cv:ty__xujing"] = "虞晓旭",
  ["illustrator:ty__xujing"] = "黯荧岛工作室",
  ["shangyu"] = "赏誉",
  [":shangyu"] = "锁定技，游戏开始时，你获得一张【杀】并标记之，然后可以将其交给一名角色。此【杀】：造成伤害后，你和使用者各摸一张牌；"..
  "进入弃牌堆后，你将其交给一名本回合未以此法指定过的角色。",
  ["caixia"] = "才瑕",
  [":caixia"] = "当你造成或受到伤害后，你可以摸至多X张牌（X为游戏人数且至多为5）。若如此做，此技能失效直到你累计使用了等量的牌。",

  ["@@shangyu-inhand"] = "赏誉",
  ["#shangyu-give"] = "赏誉：将“赏誉”牌【%arg】交给一名角色",
  ["#caixia-draw"] = "你可以发动 才瑕，选择摸牌的数量",
  ["caixia_draw1"] = "摸一张牌",
  ["caixia_draw2"] = "摸两张牌",
  ["caixia_draw3"] = "摸三张牌",
  ["caixia_draw4"] = "摸四张牌",
  ["caixia_draw5"] = "摸五张牌",
  ["@caixia"] = "才瑕",

  ["$shangyu1"] = "君满腹才学，当为国之大器。",
  ["$shangyu2"] = "一腔青云之志，正待梦日之时。",
  ["$caixia1"] = "吾习扫天下之术，不善净一屋之秽。",
  ["$caixia2"] = "玉有十色五光，微瑕难掩其瑜。",
  ["~ty__xujing"] = "时人如江鲫，所逐者功利尔……",
}

local guanyueg = General(extension, "guanyueg", "shu", 4)
local shouzhi = fk.CreateTriggerSkill{
  name = "shouzhi",
  events = {fk.TurnEnd},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local x = player:getMark("@shouzhi-turn")
      if x == 0 then return false end
      if type(x) == "string" then x = 0 end
      return x ~= player:getHandcardNum()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@shouzhi-turn")
    if x == 0 then return false end
    if type(x) == "string" then x = 0 end
    x = x - player:getHandcardNum()
    player:broadcastSkillInvoke(self.name)
    if x > 0 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(2, self.name)
    elseif x < 0 then
      room:notifySkillInvoked(player, self.name, "negative")
      room:askForDiscard(player, 1, 1, false, self.name, false)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local x = player:getHandcardNum()
    player.room:setPlayerMark(player, "@shouzhi-turn", x > 0 and x or "0")
  end,
}
local shouzhiEX = fk.CreateTriggerSkill{
  name = "shouzhiEX",
  events = {fk.TurnEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local x = player:getMark("@shouzhi-turn")
      if x == 0 then return false end
      if type(x) == "string" then x = 0 end
      return x ~= player:getHandcardNum()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local x = player:getMark("@shouzhi-turn")
    if x == 0 then return false end
    if type(x) == "string" then x = 0 end
    x = x - player:getHandcardNum()
    if x > 0 then
      if player.room:askForSkillInvoke(player, "shouzhi", nil, "#shouzhi-draw") then
        self.cost_data = {}
        return true
      end
    else
      local cards = player.room:askForDiscard(player, 1, 1, false, "shouzhi", true, ".", "#shouzhi-discard", true)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shouzhi")
    if #self.cost_data > 0 then
      room:notifySkillInvoked(player, "shouzhi", "negative")
      room:throwCard(self.cost_data, "shouzhi", player, player)
    else
      room:notifySkillInvoked(player, "shouzhi", "drawcard")
      player:drawCards(2, "shouzhi")
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local x = player:getHandcardNum()
    player.room:setPlayerMark(player, "@shouzhi-turn", x > 0 and x or "0")
  end,
}
local fenhui = fk.CreateActiveSkill{
  name = "fenhui",
  anim_type = "offensive",
  frequency = Skill.Limited,
  prompt = "#fenhui-active",
  interaction = function()
    local choices = {"fenhui_count"}
    local all_choices = {"fenhui_count"}
    local x
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p ~= Self then
        x = math.min(p:getMark("fenhui_count"), 5)
        table.insert(all_choices, "fenhui_target::" .. p.id .. ":".. tostring(x))
        if x > 0 then
          table.insert(choices, "fenhui_target::" .. p.id .. ":".. tostring(x))
        end
      end
    end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
    and Fk:currentRoom():getPlayerById(to_select):getMark("fenhui_count") > 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = math.min(target:getMark("fenhui_count"), 5)
    room:setPlayerMark(target, "@fenhui_hatred", n)
    room:setPlayerMark(player, "fenhui_target", target.id)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "fenhui_count", 0)
    end
    player:drawCards(n, self.name)
  end,
}
local fenhui_delay = fk.CreateTriggerSkill{
  name = "#fenhui_delay",
  mute = true,
  events = {fk.DamageInflicted, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if event == fk.DamageInflicted then
      return player == target and player:getMark("@fenhui_hatred") > 0
    elseif event == fk.Death then
      return player:getMark("fenhui_target") == target.id and target:getMark("@fenhui_hatred") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      player.room:removePlayerMark(player, "@fenhui_hatred")
      data.damage = data.damage + 1
    elseif event == fk.Death then
      local room = player.room
      room:notifySkillInvoked(player, "fenhui")
      player:broadcastSkillInvoke("fenhui")
      room:changeMaxHp(player, -1)
      if player.dead then return false end
      local skills = "xingmen"
      if player:hasSkill(shouzhi, true) then
        skills = "-shouzhi|shouzhiEX|" .. skills
      end
      room:handleAddLoseSkills(player, skills, nil, true, false)
    end
  end,

  refresh_events = {fk.TargetSpecified, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      return player == target and player.id ~= data.to and player:hasSkill(fenhui, true) and
      player:usedSkillTimes("fenhui", Player.HistoryGame) == 0
    elseif event == fk.BuryVictim then
      return player:getMark("@fenhui_hatred") > 0 and table.every(player.room.alive_players, function (p)
        return p:getMark("fenhui_target") ~= player.id
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      if not to.dead then
        room:addPlayerMark(to, "fenhui_count")
      end
    else
      room:setPlayerMark(player, "@fenhui_hatred", 0)
    end
  end,
}
local xingmen = fk.CreateTriggerSkill{
  name = "xingmen",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local cards = {}
      local recover = false
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand and move.moveReason == fk.ReasonDraw then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(cards, info.cardId)
          end
        end
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and
        move.skillName == shouzhi.name and #move.moveInfo > 0 and player:isWounded() then
          recover = true
        end
      end
      if #cards < 2 then
        cards = {}
      end
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).color == Card.Red
      end)
      if #cards > 0 or recover then
        self.cost_data = {cards, recover}
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    for _, id in ipairs(self.cost_data[1]) do
      if table.contains(cards, id) then
        room:setCardMark(Fk:getCardById(id), "@@xingmen-inhand", 1)
      end
    end
    if self.cost_data[2] and room:askForSkillInvoke(player, self.name) then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name)
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not data.card:isVirtual() and data.card:getMark("@@xingmen-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.players, Util.IdMapper)
  end,
}
fenhui:addRelatedSkill(fenhui_delay)
guanyueg:addSkill(shouzhi)
guanyueg:addSkill(fenhui)
guanyueg:addRelatedSkill(shouzhiEX)
guanyueg:addRelatedSkill(xingmen)
Fk:loadTranslationTable{
  ["guanyueg"] = "关樾",
  ["#guanyueg"] = "动心忍性",
  --["designer:guanyueg"] = "",
  ["illustrator:guanyueg"] = "匠人绘",
  ["shouzhi"] = "守执",
  [":shouzhi"] = "锁定技，一名角色的回合结束时，若你的手牌数：大于此回合开始时的手牌数，你弃置一张手牌；"..
  "小于此回合开始时的手牌数，你摸两张牌。",
  ["shouzhiEX"] = "守执",
  [":shouzhiEX"] = "一名角色的回合结束时，若你的手牌数：大于此回合开始时的手牌数，你可以弃置一张手牌；"..
  "小于此回合开始时的手牌数，你可以摸两张牌。",
  ["fenhui"] = "奋恚",
  [":fenhui"] = "限定技，出牌阶段，你可以令一名其他角色获得X枚“恨”（X为你对其使用过牌的次数且至多为5），你摸等量的牌。"..
  "当其受到伤害时，其弃1枚“恨”且伤害值+1；当其死亡时，若其有“恨”，你减1点体力上限，失去〖守执〗，获得〖守执〗和〖兴门〗。",
  ["xingmen"] = "兴门",
  [":xingmen"] = "当你因执行〖守执〗的效果而弃置手牌后，你可以回复1点体力。当你因摸牌而得到牌后，"..
  "若这些牌数大于1，你使用其中的红色牌不能被响应。",

  ["@shouzhi-turn"] = "守执",
  ["#shouzhi-draw"] = "是否发动 守执，摸两张牌",
  ["#shouzhi-discard"] = "是否发动 守执，弃置一张牌",
  ["#fenhui-active"] = "发动 奋恚，令一名角色获得“恨”标记",
  ["fenhui_count"] = "查看数值",
  ["fenhui_target"] = "%dest[%arg]",
  ["#fenhui_delay"] = "奋恚",
  ["@fenhui_hatred"] = "恨",
  ["@@xingmen-inhand"] = "兴门",

  ["$shouzhi1"] = "日暮且眠岗上松，散尽千金买东风。",
  ["$shouzhi2"] = "这沽来的酒，哪有赊的有味道。",
  ["$fenhui1"] = "国仇家恨，不共戴天！",
  ["$fenhui2"] = "手中虽无青龙吟，心有长刀仍啸月。",
  ["$xingmen1"] = "尔等，休道我关氏无人！",
  ["$xingmen2"] = "义在人心，人人皆可成关公！",
  ["~guanyueg"] = "提履无处归，举目山河冷……",
}

local zhugejing = General(extension, "zhugejing", "qun", 3)
zhugejing.subkingdom = "jin"
local yanzuo = fk.CreateActiveSkill{
  name = "yanzuo",
  anim_type = "special",
  card_num = 1,
  target_num = 0,
  prompt = "#yanzuo",
  derived_piles = "yanzuo",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + player:getMark("zuyin")
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.type == Card.TypeBasic or card:isCommonTrick())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:addToPile(self.name, effect.cards, true, self.name, player.id)
    if player.dead or #player:getPile(self.name) == 0 then return end
    -- local names = {}
    -- for _, id in ipairs(player:getPile(self.name)) do
    --   local card = Fk:getCardById(id)
    --   if card.type == Card.TypeBasic or card:isCommonTrick() then
    --     table.insertIfNeed(names, card.name)
    --   end
    -- end
    -- U.askForPlayCard(room, player, names, nil, self.name, "#yanzuo-ask", false, true, false, true)
    local cards = player:getPile("yanzuo")
    if #cards > 0 then
      local use = U.askForUseRealCard(room, player, cards, ".|.|.|yanzuo", self.name, "#yanzuo-ask", {expand_pile = "yanzuo", bypass_times = true}, true, false)
      if use then
        room:useCard{
          card = Fk:cloneCard(use.card.name),
          from = player.id,
          tos = use.tos,
          skillName = self.name,
          extraUse = true
        }
      end
    end
  end,
}
local zuyin = fk.CreateTriggerSkill{
  name = "zuyin",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getPile("yanzuo"), function (id)
      return Fk:getCardById(id).trueName == data.card.trueName
    end)
    if #cards > 0 then
      data.nullifiedTargets = table.map(room:getAlivePlayers(), Util.IdMapper)
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
    else
      if player:getMark(self.name) < 2 then
        room:addPlayerMark(player, self.name, 1)
      end
      cards = room:getCardsFromPileByRule(data.card.trueName, 1, "allPiles")
      if #cards > 0 then
        player:addToPile("yanzuo", cards, true, self.name, player.id)
      end
    end
  end,
}
local pijian = fk.CreateTriggerSkill{
  name = "pijian",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      #player:getPile("yanzuo") >= #player.room.alive_players
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1,
      "#pijian-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:moveCardTo(player:getPile("yanzuo"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
    if not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 2,
        skillName = self.name,
      }
    end
  end,
}
zhugejing:addSkill(yanzuo)
zhugejing:addSkill(zuyin)
zhugejing:addSkill(pijian)
Fk:loadTranslationTable{
  ["zhugejing"] = "诸葛京",
  ["#zhugejing"] = "武侯遗秀",
  --["designer:zhugejing"] = "",
  --["illustrator:zhugejing"] = "",

  ["yanzuo"] = "研作",
  [":yanzuo"] = "出牌阶段限一次，你可以将一张基本牌或普通锦囊牌置于武将牌上，然后视为使用一张“研作”牌。",
  ["zuyin"] = "祖荫",
  [":zuyin"] = "锁定技，你成为其他角色使用【杀】或普通锦囊牌的目标后，若你的“研作”牌中：没有同名牌，你从牌堆或弃牌堆中将一张同名牌置为"..
  "“研作”牌，然后令〖研作〗出牌阶段可发动次数+1（至多为3）；有同名牌，令此牌无效并移去“研作”牌中全部同名牌。",
  ["pijian"] = "辟剑",
  [":pijian"] = "结束阶段，若“研作”牌数不少于存活角色数，你可移去这些牌，对一名角色造成2点伤害。",
  ["#yanzuo"] = "研作：将一张基本牌或普通锦囊牌置为“研作”牌，然后视为使用一张“研作”牌",
  ["#yanzuo-ask"] = "研作：视为使用一张牌",

   ["#pijian-choose"] = "辟剑：你可以移去所有“研作”牌，对一名角色造成2点伤害！",
}

return extension
