local extension = Package("tenyear_sp3")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp3"] = "十周年-限定专属3",
  ["wm"] = "武",
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
    not table.contains(U.getMark(player, "@$jiufa"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "@$jiufa")
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
    local mark = U.getMark(player, "sanshou-turn")
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
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 3, "#tianjie-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      local n = math.max(1, #table.filter(p.player_cards[Player.Hand], function(c) return Fk:getCardById(c).name == "jink" end))
      room:damage{
        from = player,
        to = p,
        damage = n,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
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
      not table.contains(U.getMark(player, "jingyu_skills-round"), data.name)
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local skills = U.getMark(player, "jingyu_skills-round")
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
      -- "yiwu_shoulder",
      -- "yiwu_hand",
      "yiwu_upper_limb",
      "yiwu_lower_limb",
      "yiwu_chest",
      "yiwu_abdomen",
    }

    local victim = data.to
    if table.contains(U.getMark(victim, "yiwu_hitter"), player.id) then
      table.insert(choices, 1, "yiwu_head")
    end

    local results = player.room:askForChoices(player, choices, 1, 1, self.name, "#yiwu-choose::" .. victim.id)
    if #results > 0 then
      self.cost_data = results[1]
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

    local hitters = U.getMark(victim, "yiwu_hitter")
    table.insertIfNeed(hitters, player.id)
    room:setPlayerMark(victim, "yiwu_hitter", hitters)

    local choice = self.cost_data
    if choice == "yiwu_head" and victim.hp > 0 then
      room:loseHp(victim, victim.hp, self.name)
      if not victim:isAlive() then
        room:changeMaxHp(player, 1)
      end
    elseif choice == "yiwu_shoulder" then
      local toDiscard = victim:getEquipments(Card.SubtypeWeapon)
      table.insertTable(toDiscard, victim:getEquipments(Card.SubtypeArmor))
      if #toDiscard > 0 then
        room:throwCard(toDiscard, self.name, victim, player)
      end
    elseif choice == "yiwu_hand" then
      local halfMaxCards = math.floor(victim:getMaxCards() / 2)
      room:setPlayerMark(victim, "@@yiwu_hand", halfMaxCards < 1 and -1 or halfMaxCards)
    elseif choice == "yiwu_upper_limb" then
      local toDiscard = table.random(victim:getCardIds("h"), math.floor(#victim:getCardIds("h") / 2))
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
          -- "@@yiwu_hand",
          "@@yiwu_lower_limb",
          "@@yiwu_chest",
          "@@yiwu_abdomen",
        },
        function(markName) return player:getMark(markName) ~= 0 end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, markName in ipairs({ "@@yiwu_hand", "@@yiwu_lower_limb", "@@yiwu_chest", "@@yiwu_abdomen" }) do
      if player:getMark(markName) ~= 0 then
        room:setPlayerMark(player, markName, 0)
      end
    end
  end,
}
local yiwuTrigger = fk.CreateTriggerSkill{
  name = "#yiwu_trigger",
  anim_type = "negative",
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      return
        target == player and
        player.phase ~= Player.NotActive and
        player:getMark("@@yiwu_chest") > 0 and
        data.card and
        data.card.is_damage_card
    end

    return target == player and player:getMark("@@yiwu_lower_limb") > 0 and player.hp > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      data.damage = data.damage - 1
      if data.damage < 1 then
        return true
      end
    else
      data.damage = data.damage + 1
    end
  end,
}
local yiwuMaxCards = fk.CreateMaxCardsSkill{
  name = "#yiwu_max_cards",
  fixed_func = function(self, player)
    local halfMaxCards = player:getMark("@@yiwu_hand")
    return halfMaxCards ~= 0 and math.max(0, halfMaxCards) or nil
  end
}
local yiwuProhibit = fk.CreateProhibitSkill{
  name = "#yiwu_prohibit",
  prohibit_use = function(self, player, card)
    return
      -- (player:getMark("@@yiwu_chest") > 0 and player.phase ~= Player.NotActive and card.is_damage_card) or
      (player:getMark("@@yiwu_abdomen") > 0 and table.contains({ "jink", "peach" }, card.trueName))
  end,
}
Fk:loadTranslationTable{
  ["yiwu"] = "毅武",
  [":yiwu"] = "当你对其他角色造成伤害后，你可以选择以下任一部位进行“击伤”：<br>" ..
  -- "肩部：弃置其装备区里的武器牌和防具牌。<br>" ..
  -- "手部：令其手牌上限基数为“击伤”时的手牌上限的一半（向下取整）直到其回合结束。<br>" ..
  "上肢：令其随机弃置一半手牌（向下取整）。<br>" ..
  "下肢：令其直到其回合结束，当其受到伤害时，若其体力值大于1，则此伤害+1。<br>" ..
  "胸部：令其下回合使用伤害牌造成的伤害-1。<br>" ..
  "腹部：令其不能使用【闪】和【桃】直到其回合结束。<br>" ..
  "若你击伤过该角色，则额外出现“头部”选项。<br>" ..
  "头部：令其失去所有体力，然后若其死亡，则你加1点体力上限。",
  ["#yiwu-invoke"] = "毅武：你可以摸两张牌",
  ["#yiwu-choose"] = "毅武：你可“击伤” %dest 的其中一个部位",

  ["#yiwu_trigger"] = "毅武",
  ["#yiwu_prohibit"] = "毅武",
  ["@yiwu_chi"] = "赤",
  ["yiwu_head"] = "头部：令其失去所有体力，若其死亡你加1体力上限。",
  ["yiwu_shoulder"] = "肩部：弃置其装备区里的武器牌和防具牌。",
  ["yiwu_hand"] = "手部：令其手牌上限基数为“击伤”时的手牌上限的一半（向下取整）直到其回合结束。",
  ["yiwu_upper_limb"] = "上肢：令其随机弃置一半手牌（向下取整）",
  ["yiwu_lower_limb"] = "下肢：令其直到其回合结束，当其受到伤害时，若其体力值大于1，则此伤害+1",
  ["yiwu_chest"] = "胸部：令其下回合使用伤害牌造成的伤害-1",
  ["yiwu_abdomen"] = "腹部：令其不能使用【闪】和【桃】直到其回合结束",
  ["@@yiwu_hand"] = "击伤手部",
  ["@@yiwu_lower_limb"] = "击伤下肢",
  ["@@yiwu_chest"] = "击伤胸部",
  ["@@yiwu_abdomen"] = "击伤腹部",
}

yiwu:addRelatedSkill(yiwuTrigger)
yiwu:addRelatedSkill(yiwuMaxCards)
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
  ["chiren"] = "赤刃",
  [":chiren"] = "出牌阶段开始时，你可以选择一项：1.摸体力值数量的牌，令你此阶段使用【杀】无距离限制且不可被响应；" ..
  "2.摸已损失体力值数量的牌，令你于此阶段造成伤害后回复1点体力。",
  ["#chiren_buff"] = "赤刃",
  ["chiren_hp"] = "摸体力值数量的牌，令你此阶段使用【杀】无距离限制且不可被响应",
  ["chiren_losthp"] = "摸已损失体力值数量的牌，令你于此阶段造成伤害后回复1点体力",
  ["chiren_aim"] = "强中",
  ["chiren_recover"] = "吸血",
  ["@chiren-phase"] = "赤刃",
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
    local mark = U.getMark(player, self.name)
    return table.find(Fk:currentRoom().alive_players, function(p) return not table.contains(mark, p.id) end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local mark = U.getMark(Self, self.name)
    return #selected == 0 and not table.contains(mark, to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    local mark = U.getMark(player, self.name)
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
    local mark = U.getMark(player, "ty__songci")
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
    local mark = U.getMark(data.from, "@ty__jilei")
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
    if table.contains(U.getMark(player, "@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    if table.contains(U.getMark(player, "@ty__jilei"), card:getTypeString() .. "_char") then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
  prohibit_discard = function(self, player, card)
    return table.contains(U.getMark(player, "@ty__jilei"), card:getTypeString() .. "_char")
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
    local names = U.getViewAsCardNames(Self, "zhaowen", all_names, {}, U.getMark(Self, "zhaowen-turn"))
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

--local cuiyanmaojie = General(extension, "ty__cuiyanmaojie", "wei", 3)
Fk:loadTranslationTable{
  ["ty__cuiyanmaojie"] = "崔琰毛玠",
  ["#ty__cuiyanmaojie"] = "日出月盛",
  ["illustrator:ty__cuiyanmaojie"] = "罔両",

  ["ty__zhengbi"] = "征辟",
  [":ty__zhengbi"] = "出牌阶段开始时，你可以选择一名其他角色并选择一项：1.此阶段结束时，若其此阶段获得过手牌，你获得其一张手牌和装备区内"..
  "一张牌；2.交给其一张基本牌，然后其交给你一张非基本牌或两张基本牌。",
  ["ty__fengying"] = "奉迎",
  [":ty__fengying"] = "限定技，出牌阶段，你可以弃置所有手牌，若如此做，此回合结束后，你执行一个额外回合，此额外回合开始时，若你的体力值"..
  "全场最少，你将手牌摸至体力上限。",
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
    local all_names, names = U.getMark(Self, "@$fengying"), {}
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
    local names = U.getMark(player, "@$fengying")
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
    local mark2 = player:getMark("@$shijiz-round")
    if mark2 == 0 then mark2 = {} end
    local names, choices = {}, {}
    for _, name in ipairs(mark) do
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      if target:canUse(card) and not target:prohibitUse(card) then
        table.insert(names, name)
        if not table.contains(mark2, name) then
          table.insert(choices, name)
        end
      end
    end
    table.insert(names, "Cancel")
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name, "#shijiz-invoke::"..target.id, false, names)
    if choice ~= "Cancel" then
      room:doIndicate(player.id, {target.id})
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@$shijiz-round")
    if mark == 0 then mark = {} end
    table.insert(mark, self.cost_data)
    room:setPlayerMark(player, "@$shijiz-round", mark)
    room:doIndicate(player.id, {target.id})
    room:setPlayerMark(target, "shijiz-tmp", self.cost_data)
    local success, dat = room:askForUseActiveSkill(target, "shijiz_viewas", "#shijiz-use:::"..self.cost_data, true)
    room:setPlayerMark(target, "shijiz-tmp", 0)
    if success then
      local card = Fk:cloneCard(self.cost_data)
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
    return #selected == 0 and Self:getMark("shijiz-tmp") ~= 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(Self:getMark("shijiz-tmp"))
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
  ["#shijiz-invoke"] = "十计：你可以选择一种锦囊，令 %dest 可以将一张牌当此牌使用（不能指定其自己为目标）",
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

--祈福：关索 赵襄 鲍三娘 徐荣 曹纯 张琪瑛
local guansuo = General(extension, "ty__guansuo", "shu", 4)
local ty__zhengnan = fk.CreateTriggerSkill{
  name = "ty__zhengnan",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (player:getMark(self.name) == 0 or not table.contains(player:getMark(self.name), target.id))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(self.name)
    if mark == 0 then mark = {} end
    table.insert(mark, target.id)
    room:setPlayerMark(player, self.name, mark)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    local choices = {"ex__wusheng", "ty_ex__dangxian", "ty_ex__zhiman"}
    for i = 3, 1, -1 do
      if player:hasSkill(choices[i], true) then
        table.removeOne(choices, choices[i])
      end
    end
    if #choices > 0 then
      player:drawCards(1, self.name)
      local choice = room:askForChoice(player, choices, self.name, "#zhengnan-choice", true)
      room:handleAddLoseSkills(player, choice, nil)
      if choice == "ty_ex__dangxian" then
        room:setPlayerMark(player, "ty_ex__fuli", 1)  --直接获得升级后的当先
      end
    else
      player:drawCards(3, self.name)
    end
  end,
}
guansuo:addSkill(ty__zhengnan)
guansuo:addSkill("xiefang")
guansuo:addRelatedSkill("ex__wusheng")
guansuo:addRelatedSkill("ty_ex__dangxian")
guansuo:addRelatedSkill("ty_ex__zhiman")
Fk:loadTranslationTable{
  ["ty__guansuo"] = "关索",
  ["#ty__guansuo"] = "倜傥孑侠",
  ["illustrator:ty__guansuo"] = "第七个桔子", -- 传说皮 万花簇威
  ["ty__zhengnan"] = "征南",
  [":ty__zhengnan"] = "每名角色限一次，当一名角色进入濒死状态时，你可以回复1点体力，然后摸一张牌并选择获得下列技能中的一个："..
  "〖武圣〗，〖当先〗和〖制蛮〗（若技能均已获得，则改为摸三张牌）。",

  ["$ty__zhengnan1"] = "南征之役，愿效死力。",
  ["$ty__zhengnan2"] = "南征之险恶，吾已有所准备。",
  ["$ex__wusheng_ty__guansuo"] = "我敬佩你的勇气。",
  ["$ty_ex__dangxian_ty__guansuo"] = "时时居先，方可快人一步。",
  ["$ty_ex__zhiman_ty__guansuo"] = "败军之将，自当纳贡！",
  ["~ty__guansuo"] = "索，至死不辱家风！",
}

local zhaoxiang = General(extension, "ty__zhaoxiang", "shu", 4, 4, General.Female)
local ty__fanghun = fk.CreateViewAsSkill{
  name = "ty__fanghun",
  prompt = "#ty__fanghun-viewas",
  pattern = "slash,jink",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    else
      return false
    end
    return (Fk.currentResponsePattern == nil and c.skill:canUse(Self, c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, "ty__fanghun")
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying")
    player:drawCards(1, self.name)
  end,
}
local ty__fanghun_trigger = fk.CreateTriggerSkill{
  name = "#ty__fanghun_trigger",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "ty__fanghun")
    if not table.contains(data.card.skillNames, "ty__fanghun") or event == fk.TargetConfirmed then
      player:broadcastSkillInvoke("ty__fanghun")
    end
    room:addPlayerMark(player, "@meiying")
  end,
}
local ty__fuhan = fk.CreateTriggerSkill{
  name = "ty__fuhan",
  events = {fk.TurnStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@meiying") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__fuhan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    player:drawCards(n, self.name)
    if player.dead then return end

    local generals, same_g = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_g = Fk:getSameGenerals(general_name)
      table.insert(same_g, general_name)
      same_g = table.filter(same_g, function (g_name)
        local general = Fk.generals[g_name]
        return general.kingdom == "shu" or general.subkingdom == "shu"
      end)
      if #same_g > 0 then
        table.insert(generals, table.random(same_g))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, math.max(4, #room.alive_players))

    local skills = {}
    local choices = {}
    for _, general_name in ipairs(generals) do
      local general = Fk.generals[general_name]
      local g_skills = {}
      for _, skill in ipairs(general.skills) do
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "shu") and player.kingdom == "shu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      for _, s_name in ipairs(general.other_skills) do
        local skill = Fk.skills[s_name]
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "shu") and player.kingdom == "shu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      table.insertIfNeed(skills, g_skills)
      if #choices == 0 and #g_skills > 0 then
        choices = {g_skills[1]}
      end
    end
    if #choices > 0 then
      local result = player.room:askForCustomDialog(player, self.name,
      "packages/tenyear/qml/ChooseGeneralSkillsBox.qml", {
        generals, skills, 1, 2, "#ty__fuhan-choice", false
      })
      if result ~= "" then
        choices = json.decode(result)
      end
      room:handleAddLoseSkills(player, table.concat(choices, "|"), nil)
    end

    if not player.dead and player:isWounded() and
    table.every(room.alive_players, function(p) return p.hp >= player.hp end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
ty__fanghun:addRelatedSkill(ty__fanghun_trigger)
zhaoxiang:addSkill(ty__fanghun)
zhaoxiang:addSkill(ty__fuhan)
Fk:loadTranslationTable{
  ["ty__zhaoxiang"] = "赵襄",
  ["#ty__zhaoxiang"] = "拾梅鹊影",
  ["cv:ty__zhaoxiang"] = "闲踏梧桐",
  ["illustrator:ty__zhaoxiang"] = "木美人", -- 传说皮 芳芷飒敌
  ["ty__fanghun"] = "芳魂",
  [":ty__fanghun"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你获得1个“梅影”标记；你可以移去1个“梅影”标记发动〖龙胆〗并摸一张牌。",
  ["ty__fuhan"] = "扶汉",
  [":ty__fuhan"] = "限定技，回合开始时，若你有“梅影”标记，你可以移去所有“梅影”标记并摸等量的牌，然后从X张（X为存活人数且至少为4）蜀势力"..
  "武将牌中选择并获得至多两个技能（限定技、觉醒技、主公技除外）。若此时你是体力值最低的角色，你回复1点体力。",
  ["#ty__fanghun-viewas"] = "发动 芳魂，弃1枚”梅影“，将【杀】当【闪】、【闪】当【杀】使用或打出，并摸一张牌",
  ["#ty__fanghun_trigger"] = "芳魂",
  ["#ty__fuhan-invoke"] = "扶汉：你可以移去“梅影”标记，获得两个蜀势力武将的技能！",
  ["#ty__fuhan-choice"] = "扶汉：选择你要获得的至多2个技能",

  ["$ty__fanghun1"] = "芳年华月，不负期望。",
  ["$ty__fanghun2"] = "志洁行芳，承父高志。",
  ["$ty__fuhan1"] = "汉盛刘兴，定可指日成之。",
  ["$ty__fuhan2"] = "蜀汉兴存，吾必定尽力而为。",
  ["~ty__zhaoxiang"] = "此生为汉臣，死为汉芳魂……",
}

local baosanniang = General(extension, "ty__baosanniang", "shu", 3, 3, General.Female)
local ty__wuniang = fk.CreateTriggerSkill{
  name = "ty__wuniang",
  anim_type = "control",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      not table.every(player.room:getOtherPlayers(player, false), function(p) return p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#ty__wuniang1-choose"
    if player:usedSkillTimes("ty__xushen", Player.HistoryGame) > 0 and
      table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then
      prompt = "#ty__wuniang2-choose"
    end
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, player, target, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    room:obtainCard(player.id, id, false, fk.ReasonPrey)
    if not to.dead then
      to:drawCards(1, self.name)
    end
    if player:usedSkillTimes("ty__xushen", Player.HistoryGame) > 0 then
      for _, p in ipairs(room.alive_players) do
        if string.find(p.general, "guansuo") and not p.dead then
          p:drawCards(1, self.name)
        end
      end
    end
  end,
}
local ty__xushen = fk.CreateTriggerSkill{
  name = "ty__xushen",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "ty__zhennan", nil, true, false)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__xushen_data = player.id
  end,
}
local ty__xushen_delay = fk.CreateTriggerSkill{
  name = "#ty__xushen_delay",
  events = {fk.AfterDying},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.ty__xushen_data == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(room.alive_players, function(p) return string.find(p.general, "guansuo") end) then return end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#ty__xushen-choose", self.name, true)
    if #to > 0 then
      to = room:getPlayerById(to[1])
      if room:askForSkillInvoke(to, self.name, nil, "#ty__xushen-invoke") then
        U.changeHero(to, "ty__guansuo")
        if not to.dead then
          to:drawCards(3, self.name)
        end
      end
    end
  end,
}
local ty__zhennan = fk.CreateTriggerSkill{
  name = "ty__zhennan",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card:isCommonTrick() and data.firstTarget and #AimGroup:getAllTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#ty__zhennan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,
}
ty__xushen:addRelatedSkill(ty__xushen_delay)
baosanniang:addSkill(ty__wuniang)
baosanniang:addSkill(ty__xushen)
baosanniang:addRelatedSkill(ty__zhennan)
Fk:loadTranslationTable{
  ["ty__baosanniang"] = "鲍三娘",
  ["#ty__baosanniang"] = "南中武娘",
  ["illustrator:ty__baosanniang"] = "DH",
  ["ty__wuniang"] = "武娘",
  [":ty__wuniang"] = "当你使用或打出【杀】时，你可以获得一名其他角色的一张牌，若如此做，其摸一张牌。若你已发动〖许身〗，则关索也摸一张牌。",
  ["ty__xushen"] = "许身",
  [":ty__xushen"] = "限定技，当你进入濒死状态后，你可以回复1点体力并获得技能〖镇南〗，然后如果你脱离濒死状态且关索不在场，"..
  "你可令一名其他角色选择是否用关索代替其武将并令其摸三张牌",
  ["ty__zhennan"] = "镇南",
  [":ty__zhennan"] = "当有角色使用普通锦囊牌指定目标后，若此牌目标数大于1，你可以对一名其他角色造成1点伤害。",
  ["#ty__wuniang1-choose"] = "武娘：你可以获得一名其他角色的一张牌，其摸一张牌",
  ["#ty__wuniang2-choose"] = "武娘：你可以获得一名其他角色的一张牌，其摸一张牌，关索摸一张牌",
  ["#ty__xushen_delay"] = "许身",
  ["#ty__xushen-choose"] = "许身：你可以令一名其他角色选择是否变身为十周年关索并摸三张牌！",
  ["#ty__xushen-invoke"]= "许身：你可以变身为十周年关索并摸三张牌！",
  ["#ty__zhennan-choose"] = "镇南：你可以对一名其他角色造成1点伤害",

  ["$ty__wuniang1"] = "得公亲传，彰其武威。",
  ["$ty__wuniang2"] = "灵彩武动，娇影摇曳。",
  ["$ty__xushen1"] = "倾郎心，许君身。",
  ["$ty__xushen2"] = "世间只与郎君好。",
  ["$ty__zhennan1"] = "遵丞相之志，护南中安乐。",
  ["$ty__zhennan2"] = "哼，又想扰乱南中安宁？",
  ["~ty__baosanniang"] = "彼岸花开红似火，花期苦短终别离……",
}

local xurong = General(extension, "xurong", "qun", 4)
local xionghuo = fk.CreateActiveSkill{
  name = "xionghuo",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#xionghuo-active",
  can_use = function(self, player)
    return player:getMark("@baoli") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@baoli", 1)
    room:addPlayerMark(target, "@baoli", 1)
  end,
}
local xionghuo_record = fk.CreateTriggerSkill{
  name = "#xionghuo_record",
  main_skill = xionghuo,
  anim_type = "offensive",
  events = {fk.GameStart, fk.DamageCaused, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xionghuo) then
      if event == fk.GameStart then
        return player:getMark("@baoli") < 3
      elseif event == fk.DamageCaused then
        return target == player and data.to ~= player and data.to:getMark("@baoli") > 0
      else
        return target ~= player and target:getMark("@baoli") > 0 and target.phase == Player.Play
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("xionghuo")
    if event == fk.GameStart then
      room:setPlayerMark(player, "@baoli", 3)
    elseif event == fk.DamageCaused then
      room:doIndicate(player.id, {data.to.id})
      data.damage = data.damage + 1
    else
      room:doIndicate(player.id, {target.id})
      room:removePlayerMark(target, "@baoli", 1)
      local rand = math.random(1, target:isNude() and 2 or 3)
      if rand == 1 then
        room:damage {
          from = player,
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = "xionghuo",
        }
        local mark = U.getMark(target, "xionghuo_prohibit-turn")
        table.insert(mark, player.id)
        room:setPlayerMark(target, "xionghuo_prohibit-turn", mark)

      elseif rand == 2 then
        room:loseHp(target, 1, "xionghuo")
        room:addPlayerMark(target, "MinusMaxCards-turn", 1)
      else
        local cards = table.random(target:getCardIds{Player.Hand, Player.Equip}, 2)
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, "xionghuo", "", false, player.id)
      end
    end
  end,

  refresh_events = {fk.BuryVictim, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.BuryVictim then
      return player == target and player:hasSkill(xionghuo, true, true) and table.every(player.room.alive_players, function (p)
        return not p:hasSkill(xionghuo, true)
      end)
    elseif event == fk.EventLoseSkill then
      return player == target and data == xionghuo and table.every(player.room.alive_players, function (p)
        return not p:hasSkill(xionghuo, true)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@baoli") > 0 then
        room:setPlayerMark(p, "@baoli", 0)
      end
    end
  end,
}
local xionghuo_prohibit = fk.CreateProhibitSkill{
  name = "#xionghuo_prohibit",
  is_prohibited = function(self, from, to, card)
    return card.trueName == "slash" and table.contains(U.getMark(from, "xionghuo_prohibit-turn") ,to.id)
  end,
}
local shajue = fk.CreateTriggerSkill{
  name = "shajue",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and (player:getMark("@baoli") < 3 or
    (target.hp < 0 and data.damage and data.damage.card and U.hasFullRealCard(player.room, data.damage.card)))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@baoli") < 3 then
      room:addPlayerMark(player, "@baoli", 1)
    end
    if target.hp < 0 and data.damage and data.damage.card and U.hasFullRealCard(room, data.damage.card) then
      room:obtainCard(player, data.damage.card, true, fk.ReasonPrey)
    end
  end
}
xionghuo:addRelatedSkill(xionghuo_record)
xionghuo:addRelatedSkill(xionghuo_prohibit)
xurong:addSkill(xionghuo)
xurong:addSkill(shajue)
Fk:loadTranslationTable{
  ["xurong"] = "徐荣",
  ["#xurong"] = "玄菟战魔",
  ["cv:xurong"] = "曹真",
  ["designer:xurong"] = "Loun老萌",
  ["illustrator:xurong"] = "zoo",
  ["xionghuo"] = "凶镬",
  [":xionghuo"] = "游戏开始时，你获得3个“暴戾”标记（标记上限为3）。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，"..
  "你对有此标记的其他角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”并随机执行一项："..
  "1.受到1点火焰伤害且本回合不能对你使用【杀】；"..
  "2.流失1点体力且本回合手牌上限-1；"..
  "3.你随机获得其两张牌。",
  ["shajue"] = "杀绝",
  [":shajue"] = "锁定技，其他角色进入濒死状态时，你获得一个“暴戾”标记，"..
  "若其需要超过一张【桃】或【酒】救回，你获得使其进入濒死状态的牌。",
  ["#xionghuo_record"] = "凶镬",
  ["@baoli"] = "暴戾",
  ["#xionghuo-active"] = "发动 凶镬，将“暴戾”交给其他角色",

  ["$xionghuo1"] = "此镬加之于你，定有所伤！",
  ["$xionghuo2"] = "凶镬沿袭，怎会轻易无伤？",
  ["$shajue1"] = "杀伐决绝，不留后患。",
  ["$shajue2"] = "吾即出，必绝之！",
  ["~xurong"] = "此生无悔，心中无愧。",
}

local caochun = General(extension, "ty__caochun", "wei", 4)
local ty__shanjia = fk.CreateTriggerSkill{
  name = "ty__shanjia",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, self.name)
    local cards = {}
    if player:getMark(self.name) < 3 then
      local x = 3 - player:getMark(self.name)
      cards = room:askForDiscard(player, x, x, true, self.name, false, ".", "#ty__shanjia-discard:::"..x)
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then
      room:setPlayerMark(player, "ty__shanjia_basic-turn", 1)
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeTrick end) then
      room:setPlayerMark(player, "ty__shanjia_trick-turn", 1)
    end
    if player:getMark("ty__shanjia_basic-turn") > 0 and player:getMark("ty__shanjia_trick-turn") > 0 then
      U.askForUseVirtualCard(room, player, "slash", nil, self.name, "#ty__shanjia-use", true, true, false, true)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:getMark(self.name) < 3
  end,
  on_refresh = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason ~= fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).type == Card.TypeEquip then
            n = n + 1
          end
        end
      end
    end
    if n > 0 then
      player.room:addPlayerMark(player, self.name, math.min(n, 3 - player:getMark(self.name)))
      if player:hasSkill(self, true) then
        player.room:setPlayerMark(player, "@ty__shanjia", player:getMark(self.name))
      end
    end
  end,
}
local ty__shanjia_targetmod = fk.CreateTargetModSkill{
  name = "#ty__shanjia_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card.trueName == "slash" and player:getMark("ty__shanjia_basic-turn") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances =  function(self, player, skill, card)
    return player:getMark("ty__shanjia_trick-turn") > 0
  end,
}
ty__shanjia:addRelatedSkill(ty__shanjia_targetmod)
caochun:addSkill(ty__shanjia)
Fk:loadTranslationTable{
  ["ty__caochun"] = "曹纯",
  ["#ty__caochun"] = "虎豹骑首",
  ["illustrator:ty__caochun"] = "凡果_Make", -- 虎啸龙渊
  ["ty__shanjia"] = "缮甲",
  [":ty__shanjia"] = "出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（你每不因使用而失去过一张装备牌，便少弃置一张），若你本次没有弃置过："..
  "基本牌，你此阶段使用【杀】次数上限+1；锦囊牌，你此阶段使用牌无距离限制；都满足，你可以视为使用【杀】。",
  ["#ty__shanjia-discard"] = "缮甲：你需弃置%arg张牌",
  ["#ty__shanjia-use"] = "缮甲：你可以视为使用【杀】",
  ["@ty__shanjia"] = "缮甲",

  ["$ty__shanjia1"] = "百锤锻甲，披之可陷靡阵、断神兵、破坚城！",
  ["$ty__shanjia2"] = "千炼成兵，邀天下群雄引颈，且试我剑利否！",
  ["~ty__caochun"] = "不胜即亡，唯一死而已！",
}

local zhangqiying = General(extension, "zhangqiying", "qun", 3, 3, General.Female)
local falu = fk.CreateTriggerSkill{
  name = "falu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            self.cost_data = {}
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local suit = Fk:getCardById(info.cardId):getSuitString()
                if player:getMark("@@falu" .. suit) == 0 then
                  table.insertIfNeed(self.cost_data, suit)
                end
              end
            end
            return #self.cost_data > 0
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local suits = {"spade", "club", "heart", "diamond"}
      for i = 1, 4, 1 do
        room:addPlayerMark(player, "@@falu" .. suits[i], 1)
      end
    else
      for _, suit in ipairs(self.cost_data) do
        room:addPlayerMark(player, "@@falu" .. suit, 1)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    for i = 1, 4, 1 do
      room:setPlayerMark(player, "@@falu" .. suits[i], 0)
    end
  end,
}

local zhenyi = fk.CreateViewAsSkill{
  name = "zhenyi",
  anim_type = "support",
  pattern = "peach",
  prompt = "#zhenyi2",
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@@faluclub", 1)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player)
    return player.phase == Player.NotActive and player:getMark("@@faluclub") > 0
  end,
}
local zhenyi_trigger = fk.CreateTriggerSkill {
  name = "#zhenyi_trigger",
  main_skill = zhenyi,
  events = {fk.AskForRetrial, fk.DamageCaused, fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhenyi.name) then
      if event == fk.AskForRetrial then
        return player:getMark("@@faluspade") > 0
      elseif event == fk.DamageCaused then
        return target == player and player:getMark("@@faluheart") > 0
      elseif event == fk.Damaged then
        return target == player and player:getMark("@@faludiamond") > 0 and data.damageType ~= fk.NormalDamage
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if event == fk.AskForRetrial then
      prompt = "#zhenyi1::"..target.id
    elseif event == fk.DamageCaused then
      prompt = "#zhenyi3::"..data.to.id
    elseif event == fk.Damaged then
      prompt = "#zhenyi4"
    end
    return room:askForSkillInvoke(player, zhenyi.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhenyi.name)
    if event == fk.AskForRetrial then
      room:notifySkillInvoked(player, zhenyi.name, "control")
      room:removePlayerMark(player, "@@faluspade", 1)
      local choice = room:askForChoice(player, {"zhenyi_spade", "zhenyi_heart"}, zhenyi.name)
      local new_card = Fk:cloneCard(data.card.name, choice == "zhenyi_spade" and Card.Spade or Card.Heart, 5)
      new_card.skillName = zhenyi.name
      new_card.id = data.card.id
      data.card = new_card
      room:sendLog{
        type = "#ChangedJudge",
        from = player.id,
        to = { data.who.id },
        arg2 = new_card:toLogString(),
        arg = zhenyi.name,
      }
    elseif event == fk.DamageCaused then
      room:notifySkillInvoked(player, zhenyi.name, "offensive")
      room:removePlayerMark(player, "@@faluheart", 1)
      data.damage = data.damage + 1
    elseif event == fk.Damaged then
      room:notifySkillInvoked(player, zhenyi.name, "masochism")
      room:removePlayerMark(player, "@@faludiamond", 1)
      local cards = {}
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = zhenyi.name,
        })
      end
    end
  end,
}
local dianhua = fk.CreateTriggerSkill{
  name = "dianhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish) and
    not table.every({"spade", "club", "heart", "diamond"}, function (suit)
      return player:getMark("@@falu"..suit) == 0
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local n = 0
    for _, suit in ipairs({"spade", "club", "heart", "diamond"}) do
      if player:getMark("@@falu"..suit) > 0 then
        n = n + 1
      end
    end
    if n > 0 and player.room:askForSkillInvoke(player, self.name) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(self.cost_data))
  end,
}
zhenyi:addRelatedSkill(zhenyi_trigger)
zhangqiying:addSkill(falu)
zhangqiying:addSkill(zhenyi)
zhangqiying:addSkill(dianhua)
Fk:loadTranslationTable{
  ["zhangqiying"] = "张琪瑛",
  ["#zhangqiying"] = "禳祷西东",
  ["illustrator:zhangqiying"] = "alien",
  ["falu"] = "法箓",
  [":falu"] = "锁定技，当你的牌因弃置而移至弃牌堆后，根据这些牌的花色，你获得对应标记：<br>"..
  "♠，你获得1枚“紫微”；<br>"..
  "♣，你获得1枚“后土”；<br>"..
  "<font color='red'>♥</font>，你获得1枚“玉清”；<br>"..
  "<font color='red'>♦</font>，你获得1枚“勾陈”。<br>"..
  "每种标记限拥有一个。游戏开始时，你获得以上四种标记。",
  ["zhenyi"] = "真仪",
  [":zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或<font color='red'>♥5</font>；<br>"..
  "当你于回合外需要使用【桃】时，你可以弃置“后土”，然后将你的一张牌当【桃】使用；<br>"..
  "当你造成伤害时，你可以弃置“玉清”，此伤害+1；<br>"..
  "当你受到属性伤害后，你可以弃置“勾陈”，然后你从牌堆中随机获得三种类型的牌各一张。",
  ["dianhua"] = "点化",
  [":dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数）。若如此做，你将这些牌以任意顺序放回牌堆顶或牌堆底。",
  ["@@faluspade"] = "♠紫微",
  ["@@faluclub"] = "♣后土",
  ["@@faluheart"] = "<font color='red'>♥</font>玉清",
  ["@@faludiamond"] = "<font color='red'>♦</font>勾陈",
  ["#zhenyi1"] = "真仪：你可以弃置♠紫微，将 %dest 的判定结果改为♠5或<font color='red'>♥5</font>",
  ["#zhenyi2"] = "真仪：你可以弃置♣后土，将一张牌当【桃】使用",
  ["#zhenyi3"] = "真仪：你可以弃置<font color='red'>♥</font>玉清，对 %dest 造成的伤害+1",
  ["#zhenyi4"] = "真仪：你可以弃置<font color='red'>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张",
  ["#zhenyi_trigger"] = "真仪",
  ["zhenyi_spade"] = "将判定结果改为♠5",
  ["zhenyi_heart"] = "将判定结果改为<font color='red'>♥</font>5",

  ["$falu1"] = "求法之道，以司箓籍。",
  ["$falu2"] = "取舍有法，方得其法。",
  ["$zhenyi1"] = "不疾不徐，自爱自重。",
  ["$zhenyi2"] = "紫薇星辰，斗数之仪。",
  ["$dianhua1"] = "大道无形，点化无为。",
  ["$dianhua2"] = "得此点化，必得大道。",
  ["~zhangqiying"] = "米碎面散，我心欲绝……",
}

--隐山之玉：周夷 卢弈 孙翎鸾 曹轶
local zhouyi = General(extension, "zhouyi", "wu", 3, 3, General.Female)
local zhukou = fk.CreateTriggerSkill{
  name = "zhukou",
  anim_type = "offensive",
  events = {fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local room = player.room
      if event == fk.Damage then
        if room.current and room.current.phase == Player.Play then
          local damage_event = room.logic:getCurrentEvent()
          if not damage_event then return false end
          local x = player:getMark("zhukou_record-phase")
          if x == 0 then
            room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
              local reason = e.data[3]
              if reason == "damage" then
                local first_damage_event = e:findParent(GameEvent.Damage)
                if first_damage_event and first_damage_event.data[1].from == player then
                  x = first_damage_event.id
                  room:setPlayerMark(player, "zhukou_record-phase", x)
                end
                return true
              end
            end, Player.HistoryPhase)
          end
          if damage_event.id == x then
            local events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
            local end_id = player:getMark("zhukou_record-turn")
            if end_id == 0 then
              local turn_event = damage_event:findParent(GameEvent.Turn, false)
              end_id = turn_event.id
            end
            room:setPlayerMark(player, "zhukou_record-turn", room.logic.current_event_id)
            local y = player:getMark("zhukou_usecard-turn")
            for i = #events, 1, -1 do
              local e = events[i]
              if e.id <= end_id then break end
              local use = e.data[1]
              if use.from == player.id then
                y = y + 1
              end
            end
            room:setPlayerMark(player, "zhukou_usecard-turn", y)
            return y > 0
          end
        end
      else
        if player.phase == Player.Finish and #room.alive_players > 2 then
          if player:getMark("zhukou_damaged-turn") > 0 then return false end
          local events = room.logic.event_recorder[GameEvent.ChangeHp] or Util.DummyTable
          local end_id = player:getMark("zhukou_damage_record-turn")
          if end_id == 0 then
            local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
            end_id = turn_event.id
          end
          room:setPlayerMark(player, "zhukou_damage_record-turn", room.logic.current_event_id)
          for i = #events, 1, -1 do
            local e = events[i]
            if e.id <= end_id then break end
            local damage = e.data[5]
            if damage and damage.from == player then
              room:setPlayerMark(player, "zhukou_damaged-turn", 1)
              return false
            end
          end
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      return room:askForSkillInvoke(player, self.name)
    else
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      if #targets < 2 then return end
      local tos = room:askForChoosePlayers(player, targets, 2, 2, "#zhukou-choose", self.name, true)
      if #tos == 2 then
        self.cost_data = tos
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.Damage then
      local x = player:getMark("zhukou_usecard-turn")
      if x > 0 then
        player:drawCards(x, self.name)
      end
    else
      local room = player.room
      local tar
      for _, p in ipairs(self.cost_data) do
        tar = room:getPlayerById(p)
        if not tar.dead then
          room:damage{
            from = player,
            to = tar,
            damage = 1,
            skillName = self.name,
          }
        end
      end
    end
  end,
}
local mengqing = fk.CreateTriggerSkill{
  name = "mengqing",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #table.filter(player.room.alive_players, function(p) return p:isWounded() end) > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 3)
    room:recover({
      who = player,
      num = 3,
      recoverBy = player,
      skillName = self.name
    })
    room:handleAddLoseSkills(player, "-zhukou|yuyun", nil)
  end,
}
local yuyun = fk.CreateTriggerSkill{
  name = "yuyun",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local chs = {"loseHp"}
    if player.maxHp > 1 then table.insert(chs, "loseMaxHp") end
    local chc = room:askForChoice(player, chs, self.name)
    if chc == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, self.name)
    end
    local choices = {"yuyun1", "yuyun2", "yuyun3", "yuyun4", "yuyun5", "Cancel"}
    local n = 1 + player:getLostHp()
    for i = 1, n, 1 do
      if player.dead or #choices < 2 then return end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      if choice == "yuyun1" then
        player:drawCards(2, self.name)
      elseif choice == "yuyun2" then
        local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun2-choose", self.name, false)
          if #to > 0 then
            local tar = room:getPlayerById(to[1])
            room:damage{
              from = player,
              to = tar,
              damage = 1,
              skillName = self.name,
            }
            if not tar.dead then
              room:addPlayerMark(tar, "@@yuyun-turn")
              local targetRecorded = type(player:getMark("yuyun2-turn")) == "table" and player:getMark("yuyun2-turn") or {}
              table.insertIfNeed(targetRecorded, to[1])
              room:setPlayerMark(player, "yuyun2-turn", targetRecorded)
            end
          end
        end
      elseif choice == "yuyun3" then
        room:addPlayerMark(player, "@@yuyun-turn")
        room:addPlayerMark(player, "yuyun3-turn", 1)
      elseif choice == "yuyun4" then
        local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
          return not p:isAllNude() end), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun4-choose", self.name, false)
          if #to > 0 then
            local id = room:askForCardChosen(player, room:getPlayerById(to[1]), "hej", self.name)
            room:obtainCard(player.id, id, false, fk.ReasonPrey)
          end
        end
      elseif choice == "yuyun5" then
        local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
        if #targets > 0 then
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#yuyun5-choose", self.name, false)
          if #to > 0 then
            local p = room:getPlayerById(to[1])
            local x = math.min(p.maxHp, 5) - p:getHandcardNum()
            if x > 0 then
              room:drawCards(p, x, self.name)
            end
          end
        end
      end
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player == target and data.card.trueName == "slash" then
      local mark = U.getMark(player, "yuyun2-turn")
      return #mark > 0 and table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return table.contains(mark, pid)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local yuyun_targetmod = fk.CreateTargetModSkill{
  name = "#yuyun_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card.trueName == "slash" and to and table.contains(U.getMark(player, "yuyun2-turn"), to.id)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card.trueName == "slash" and to and table.contains(U.getMark(player, "yuyun2-turn"), to.id)
  end,
}
local yuyun_maxcards = fk.CreateMaxCardsSkill{
  name = "#yuyun_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("yuyun3-turn") > 0
  end,
}
yuyun:addRelatedSkill(yuyun_targetmod)
yuyun:addRelatedSkill(yuyun_maxcards)
zhouyi:addSkill(zhukou)
zhouyi:addSkill(mengqing)
zhouyi:addRelatedSkill(yuyun)
Fk:loadTranslationTable{
  ["zhouyi"] = "周夷",
  ["#zhouyi"] = "靛情雨黛",
  ["illustrator:zhouyi"] = "Tb罗根",
  ["zhukou"] = "逐寇",
  [":zhukou"] = "当你于每回合的出牌阶段第一次造成伤害后，你可以摸X张牌（X为本回合你已使用的牌数）。结束阶段，若你本回合未造成过伤害，"..
  "你可以对两名其他角色各造成1点伤害。",
  ["mengqing"] = "氓情",
  [":mengqing"] = "觉醒技，准备阶段，若已受伤的角色数大于你的体力值，你加3点体力上限并回复3点体力，失去〖逐寇〗，获得〖玉殒〗。",
  ["yuyun"] = "玉陨",
  [":yuyun"] = "锁定技，出牌阶段开始时，你失去1点体力或体力上限（你的体力上限不能以此法被减至1以下），然后选择X+1项（X为你已损失的体力值）：<br>"..
  "1.摸两张牌；<br>"..
  "2.对一名其他角色造成1点伤害，然后本回合对其使用【杀】无距离和次数限制；<br>"..
  "3.本回合没有手牌上限；<br>"..
  "4.获得一名其他角色区域内的一张牌；<br>"..
  "5.令一名其他角色将手牌摸至体力上限（最多摸至5）。",
  ["#zhukou-choose"] = "是否发动逐寇，选择2名其他角色，对其各造成1点伤害",
  ["yuyun1"] = "摸两张牌",
  ["yuyun2"] = "对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["yuyun3"] = "本回合没有手牌上限",
  ["yuyun4"] = "获得一名其他角色区域内的一张牌",
  ["yuyun5"] = "令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["#yuyun2-choose"] = "玉陨：对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["#yuyun4-choose"] = "玉陨：获得一名其他角色区域内的一张牌",
  ["#yuyun5-choose"] = "玉陨：令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["@@yuyun-turn"] = "玉陨",

  ["$zhukou1"] = "草莽贼寇，不过如此。",
  ["$zhukou2"] = "轻装上阵，利剑出鞘。",
  ["$mengqing1"] = "女之耽兮，不可说也。",
  ["$mengqing2"] = "淇水汤汤，渐车帷裳。",
  ["$yuyun1"] = "春依旧，人消瘦。",
  ["$yuyun2"] = "泪沾青衫，玉殒香消。",
  ["~zhouyi"] = "江水寒，萧瑟起……",
}

local luyi = General(extension, "luyi", "qun", 3, 3, General.Female)

local function searchFuxueCards(room, findOne)
  if #room.discard_pile == 0 then return {} end
  local ids = {}
  local discard_pile = table.simpleClone(room.discard_pile)
  local logic = room.logic
  local events = logic.event_recorder[GameEvent.MoveCards] or Util.DummyTable
  for i = #events, 1, -1 do
    local e = events[i]
    for _, move in ipairs(e.data) do
      for _, info in ipairs(move.moveInfo) do
        local id = info.cardId
        if table.removeOne(discard_pile, id) then
          if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
            table.insertIfNeed(ids, id)
            if findOne then
              return ids
            end
          end
        end
      end
    end
    if #discard_pile == 0 then break end
  end
  return ids
end
local fuxue = fk.CreateTriggerSkill{
  name = "fuxue",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player.phase == Player.Start then
        return #searchFuxueCards(player.room, true) > 0
      elseif player.phase == Player.Finish then
        return player:isKongcheng() or
          table.every(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@fuxue-inhand-turn") == 0 end)
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
      local cards = searchFuxueCards(room, false)
      if #cards == 0 then return false end
      table.sort(cards, function (a, b)
        local cardA, cardB = Fk:getCardById(a), Fk:getCardById(b)
        if cardA.type == cardB.type then
          if cardA.sub_type == cardB.sub_type then
            if cardA.name == cardB.name then
              return a > b
            else
              return cardA.name > cardB.name
            end
          else
            return cardA.sub_type < cardB.sub_type
          end
        else
          return cardA.type < cardB.type
        end
      end)
      local get = room:askForCardsChosen(player, player, 1, player.hp, {
        card_data = {
          { "pile_discard", cards }
        }
      }, self.name, "#fuxue-choose:::" .. tostring(player.hp))
      room:moveCardTo(get, Player.Hand, player, fk.ReasonJustMove, self.name, "", false, player.id, "@@fuxue-inhand-turn")
    else
      player:drawCards(player.hp, self.name)
    end
  end,
}
local yaoyi = fk.CreateTriggerSkill{
  name = "yaoyi",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if not (p.dead or p:hasSkill("shoutan", true)) then
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
    end
  end,
}
local yaoyi_prohibit = fk.CreateProhibitSkill{
  name = "#yaoyi_prohibit",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    if from ~= to and table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill(yaoyi) end) then
      local fromskill
      for _, skill in ipairs(from.player_skills) do
        if skill.switchSkillName then
          if fromskill == nil then
            fromskill = from:getSwitchSkillState(skill.switchSkillName)
          elseif fromskill ~= from:getSwitchSkillState(skill.switchSkillName) then
            return false
          end
        end
      end
      if fromskill == nil then return false end
      local toskill
      for _, skill in ipairs(to.player_skills) do
        if skill.switchSkillName then
          if toskill == nil then
            toskill = to:getSwitchSkillState(skill.switchSkillName)
          elseif toskill ~= to:getSwitchSkillState(skill.switchSkillName) then
            return false
          end
        end
      end
      return fromskill == toskill
    end
  end,
}
local shoutan = fk.CreateActiveSkill{
  name = "shoutan",
  anim_type = "switch",
  switch_skill_name = "shoutan",
  prompt = function()
    local prompt = "#shoutan-active:::"
    if Self:getSwitchSkillState("shoutan", false) == fk.SwitchYang then
      if not Self:hasSkill(yaoyi) then
        prompt = prompt .. "shoutan_yang"
      end
      prompt = prompt .. ":yin"
    else
      if not Self:hasSkill(yaoyi) then
        prompt = prompt .. "shoutan_yin"
      end
      prompt = prompt .. ":yang"
    end
    return prompt
  end,
  card_num = function()
    if Self:hasSkill(yaoyi) then
      return 0
    else
      return 1
    end
  end,
  target_num = 0,
  can_use = function(self, player)
    if player:hasSkill(yaoyi) then
      return player:getMark("shoutan_prohibit-phase") == 0
    else
      return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end
  end,
  card_filter = function(self, to_select, selected)
    if Self:hasSkill(yaoyi) then
      return false
    elseif #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip then
      local card = Fk:getCardById(to_select)
      return not Self:prohibitDiscard(card) and (card.color == Card.Black) == (Self:getSwitchSkillState(self.name, false) == fk.SwitchYin)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
  end,
}
local shoutan_refresh = fk.CreateTriggerSkill{
  name = "#shoutan_refresh",

  refresh_events = {fk.StartPlayCard},
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("shoutan-phase") < player:usedSkillTimes("shoutan", Player.HistoryPhase) then
      room:setPlayerMark(player, "shoutan-phase", player:usedSkillTimes("shoutan", Player.HistoryPhase))
      room:setPlayerMark(player, "shoutan_prohibit-phase", 1)
    else
      room:setPlayerMark(player, "shoutan_prohibit-phase", 0)
    end
  end,
}
yaoyi:addRelatedSkill(yaoyi_prohibit)
shoutan:addRelatedSkill(shoutan_refresh)
luyi:addSkill(fuxue)
luyi:addSkill(yaoyi)
luyi:addRelatedSkill(shoutan)
Fk:loadTranslationTable{
  ["luyi"] = "卢弈",
  ["#luyi"] = "落子惊鸿",
  ["designer:luyi"] = "星移",
  ["illustrator:luyi"] = "匠人绘",
  ["fuxue"] = "复学",
  [":fuxue"] = "准备阶段，你可以从弃牌堆中获得至多X张不因使用而进入弃牌堆的牌。结束阶段，若你手中没有以此法获得的牌，你摸X张牌。（X为你的体力值）",
  ["yaoyi"] = "邀弈",
  [":yaoyi"] = "锁定技，游戏开始时，所有没有转换技的角色获得〖手谈〗；你发动〖手谈〗无需弃置牌且无次数限制。"..
  "所有角色使用牌只能指定自己及与自己转换技状态不同的角色为目标。",
  ["shoutan"] = "手谈",
  [":shoutan"] = "转换技，出牌阶段限一次，你可以弃置一张：阳：非黑色手牌；阴：黑色手牌。",
  ["#fuxue-invoke"] = "复学：你可以获得弃牌堆中至多%arg张不因使用而进入弃牌堆的牌",
  ["#fuxue-choose"] = "复学：从弃牌堆中挑选至多%arg张卡牌获得",
  ["@@fuxue-inhand-turn"] = "复学",
  ["#shoutan-active"] = "发动 手谈，%arg将此技能转换为%arg2状态",
  ["shoutan_yin"] = "弃置一张黑色手牌，",
  ["shoutan_yang"] = "弃置一张非黑色手牌，",

  ["$fuxue1"] = "普天之大，唯此处可安书桌。",
  ["$fuxue2"] = "书中自有风月，何故东奔西顾？",
  ["$yaoyi1"] = "对弈未分高下，胜负可问春风。",
  ["$yaoyi2"] = "我掷三十六道，邀君游弈其中。",
  ["$shoutan1"] = "对弈博雅，落子珠玑胜无声。",
  ["$shoutan2"] = "弈者无言，手执黑白谈古今。",
  ["~luyi"] = "此生博弈，落子未有悔……",
}

local sunlingluan = General(extension, "sunlingluan", "wu", 3, 3, General.Female)
local lingyue = fk.CreateTriggerSkill{
  name = "lingyue",
  anim_type = "drawcard",
  events = {fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or not target then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local x = target:getMark("lingyue_record-round")
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event and first_damage_event.data[1].from == target then
            x = first_damage_event.id
            room:setPlayerMark(target, "lingyue_record-round", x)
            return true
          end
        end
      end, Player.HistoryRound)
    end
    return damage_event.id == x
  end,
  on_use = function(self, event, target, player, data)
    if target.phase == Player.NotActive then
      local room = player.room
      local events = room.logic.event_recorder[GameEvent.ChangeHp] or Util.DummyTable
      local end_id = player:getMark("lingyue_record-turn")
      if end_id == 0 then
        local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
        if not turn_event then
          player:drawCards(1, self.name)
          return false
        end
        end_id = turn_event.id
      end
      room:setPlayerMark(player, "lingyue_record-turn", room.logic.current_event_id)
      local x = player:getMark("lingyue_damage-turn")
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id <= end_id then break end
        local damage = e.data[5]
        if damage and damage.from then
          x = x + damage.damage
        end
      end
      room:setPlayerMark(player, "lingyue_damage-turn", x)
      if x > 0 then
        player:drawCards(x, self.name)
      end
    else
      player:drawCards(1, self.name)
    end
  end,
}
local pandi = fk.CreateActiveSkill{
  name = "pandi",
  anim_type = "control",
  prompt = "#pandi-active",
  can_use = function(self, player)
    return player:getMark("pandi_prohibit-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("pandi_damaged-turn") == 0
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = effect.tos[1]
    room:setPlayerMark(player, "pandi_prohibit-phase", 1)
    room:setPlayerMark(player, "pandi_target", target)
    local general_info = {player.general, player.deputyGeneral}
    local tar_player = room:getPlayerById(target)
    player.general = tar_player.general
    player.deputyGeneral = tar_player.deputyGeneral
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    local _, ret = room:askForUseActiveSkill(player, "pandi_use", "#pandi-use::" .. target, true)
    room:setPlayerMark(player, "pandi_target", 0)
    player.general = general_info[1]
    player.deputyGeneral = general_info[2]
    room:broadcastProperty(player, "general")
    room:broadcastProperty(player, "deputyGeneral")
    if ret then
      room:useCard({
        from = target,
        tos = table.map(ret.targets, function(pid) return { pid } end),
        card = Fk:getCardById(ret.cards[1]),
      })
    end
  end,
}
local pandi_refresh = fk.CreateTriggerSkill{
  name = "#pandi_refresh",

  refresh_events = {fk.EventAcquireSkill, fk.Damage, fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      return player == target and player:getMark("pandi_damaged-turn") == 0
    elseif event == fk.EventAcquireSkill then
      return player == target and data == self and player.room.current == player and player.room:getTag("RoundCount")
    elseif event == fk.PreCardUse then
      return player:getMark("pandi_prohibit-phase") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "pandi_damaged-turn")
    elseif event == fk.EventAcquireSkill then
      local room = player.room
      local current_event = room.logic:getCurrentEvent()
      if current_event == nil then return false end
      local start_event = current_event:findParent(GameEvent.Turn, true)
      if start_event == nil then return false end
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local damage = e.data[5]
        if damage and damage.from then
          room:addPlayerMark(damage.from, "pandi_damaged-turn")
        end
      end, Player.HistoryTurn)
    elseif event == fk.PreCardUse then
      player.room:setPlayerMark(player, "pandi_prohibit-phase", 0)
    end
  end,
}
local pandi_use = fk.CreateActiveSkill{
  name = "pandi_use",
  card_filter = function(self, to_select, selected)
    if #selected > 0 then return false end
    local room = Fk:currentRoom()
    if room:getCardArea(to_select) == Card.PlayerEquip then return false end
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    local card = Fk:getCardById(to_select)
    return target:canUse(card) and not target:prohibitUse(card)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    local card = Fk:getCardById(selected_cards[1])
    local card_skill = card.skill
    local room = Fk:currentRoom()
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    if card_skill:getMinTargetNum() == 0 or #selected >= card_skill:getMaxTargetNum(target, card) then return false end
    return not target:isProhibited(room:getPlayerById(to_select), card) and
      card_skill:modTargetFilter(to_select, selected, target_id, card, true)
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards ~= 1 then return false end
    local card = Fk:getCardById(selected_cards[1])
    local card_skill = card.skill
    local room = Fk:currentRoom()
    local target_id = Self:getMark("pandi_target")
    local target = room:getPlayerById(target_id)
    return #selected >= card_skill:getMinTargetNum() and #selected <= card_skill:getMaxTargetNum(target, card)
  end,
}
Fk:addSkill(pandi_use)
pandi:addRelatedSkill(pandi_refresh)
sunlingluan:addSkill(lingyue)
sunlingluan:addSkill(pandi)
Fk:loadTranslationTable{
  ["sunlingluan"] = "孙翎鸾",
  ["#sunlingluan"] = "弦凤栖梧",
  ["designer:sunlingluan"] = "星移",
  ["illustrator:sunlingluan"] = "HEI-LEI",

  ["lingyue"] = "聆乐",
  [":lingyue"] = "锁定技，一名角色在本轮首次造成伤害后，你摸一张牌。若此时是该角色回合外，改为摸X张牌（X为本回合全场造成的伤害值）。",
  ["pandi"] = "盻睇",
  [":pandi"] = "出牌阶段，你可以选择一名本回合未造成过伤害的其他角色，你此阶段内使用的下一张牌改为由其对你选择的目标使用。" ..
  '<br /><font color="red">（村：发动后必须立即使用牌，且不支持转化使用，否则必须使用一张牌之后才能再次发动此技能）</font>',

  ["pandi_use"] = "盻睇",
  ["#pandi-active"] = "发动盻睇，选择一名其他角色，下一张牌视为由该角色使用",
  ["#pandi-use"] = "盻睇：选择一张牌，视为由 %dest 使用（若需要选目标则你来选择目标）",

  ["$lingyue1"] = "宫商催角羽，仙乐自可聆。",
  ["$lingyue2"] = "玉琶奏折柳，天地尽箫声。",
  ["$pandi1"] = "待君归时，共泛轻舟于湖海。",
  ["$pandi2"] = "妾有一曲，可壮卿之峥嵘。",
  ["~sunlingluan"] = "良人当归，苦酒何妨……",
}

local caoyi = General(extension, "caoyi", "wei", 4, 4, General.Female)
local miyi = fk.CreateTriggerSkill{
  name = "miyi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local _, dat = player.room:askForUseActiveSkill(player, "miyi_active", "#miyi-invoke", true)
    if dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.targets
    room:sortPlayersByAction(targets)
    room:doIndicate(player.id, targets)
    local choice = self.cost_data.interaction
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:setPlayerMark(p, "@@"..choice.."-turn", 1)
        if choice == "miyi2"  then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = self.name,
          }
        elseif p:isWounded() then
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
local miyi_delay = fk.CreateTriggerSkill{
  name = "#miyi_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish
    and table.find(player.room.alive_players, function (p)
      return p:getMark("@@miyi1-turn") > 0 or p:getMark("@@miyi2-turn") > 0
    end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead then
        if p:getMark("@@miyi2-turn") > 0 and p:isWounded() then
          room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = "miyi",
          })
        elseif p:getMark("@@miyi1-turn") > 0 then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            skillName = "miyi",
          }
        end
      end
    end
  end,
}
local miyi_active = fk.CreateActiveSkill{
  name = "miyi_active",
  card_num = 0,
  min_target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"miyi1", "miyi2"}}
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.TrueFunc,
}
local yinjun = fk.CreateTriggerSkill{
  name = "yinjun",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.tos and
      (data.card.trueName == "slash" or data.card.type == Card.TypeTrick) and
      #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id and
      player:getMark("yinjun_fail-turn") == 0 then
      if U.IsUsingHandcard(player, data) then
        local to = player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
        local card = Fk:cloneCard("slash")
        card.skillName = self.name
        return not to.dead and not player:prohibitUse(card) and not player:isProhibited(to, card)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yinjun-invoke::"..TargetGroup:getRealTargets(data.tos)[1])
  end,
  on_use = function(self, event, target, player, data)
    local use = {
      from = player.id,
      tos = {TargetGroup:getRealTargets(data.tos)},
      card = Fk:cloneCard("slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    player.room:useCard(use)
    if not player.dead and player:usedSkillTimes(self.name, Player.HistoryTurn) > player.hp then
      player.room:setPlayerMark(player, "yinjun_fail-turn", 1)
    end
  end,

  refresh_events = {fk.PreDamage},
  can_refresh = function(self, event, target, player, data)
    return data.card and table.contains(data.card.skillNames, self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.from = nil
  end,
}
Fk:addSkill(miyi_active)
caoyi:addSkill(miyi)
miyi:addRelatedSkill(miyi_delay)
caoyi:addSkill(yinjun)
Fk:loadTranslationTable{
  ["caoyi"] = "曹轶",
  ["#caoyi"] = "飒姿缔燹",
  ["designer:caoyi"] = "星移",
  ["miyi"] = "蜜饴",
  [":miyi"] = "准备阶段，你可以选择一项令任意名角色执行：1.回复1点体力；2.你对其造成1点伤害。若如此做，结束阶段，这些角色执行另一项。",
  ["yinjun"] = "寅君",
  [":yinjun"] = "当你对其他角色从手牌使用指定唯一目标的【杀】或锦囊牌结算后，你可以视为对其使用一张【杀】（此【杀】伤害无来源）。若本回合发动次数"..
  "大于你当前体力值，此技能本回合无效。",
  ["miyi_active"] = "蜜饴",
  ["#miyi-invoke"] = "蜜饴：你可以令任意名角色执行你选择的效果，本回合结束阶段执行另一项",
  ["miyi1"] = "各回复1点体力",
  ["miyi2"] = "各受到你的1点伤害",
  ["@@miyi1-turn"] = "蜜饴:伤害",
  ["@@miyi2-turn"] = "蜜饴:回复",
  ["#yinjun-invoke"] = "寅君：你可以视为对 %dest 使用【杀】",

  ["$miyi1"] = "百战黄沙苦，舒颜红袖甜。",
  ["$miyi2"] = "撷蜜凝饴糖，入喉润心颜。",
  ["$yinjun1"] = "既乘虎豹之威，当弘大魏万年。",
  ["$yinjun2"] = "今日青锋在手，可驯四方虎狼。",
  ["~caoyi"] = "霜落寒鸦浦，天下无故人……",
}

--高山仰止：王朗 刘徽
local wanglang = General(extension, "ty__wanglang", "wei", 3)
local ty__gushe = fk.CreateActiveSkill{
  name = "ty__gushe",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  prompt = "#ty__gushe-active",
  can_use = function(self, player)
    return not player:isKongcheng() and #U.getMark(player, "@ty__gushe-turn") == 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 3 and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local tos = table.simpleClone(effect.tos)
    room:sortPlayersByAction(tos)
    room:getPlayerById(effect.from):pindian(table.map(tos, function(p) return room:getPlayerById(p) end), self.name)
  end,
}
local ty__gushe_delay = fk.CreateTriggerSkill{
  name = "#ty__gushe_delay",
  events = {fk.PindianResultConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.reason == "ty__gushe" and data.from == player
    --王朗死亡后依旧有效
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player.dead and data.winner ~= player then
      room:addPlayerMark(player, "@ty__raoshe", 1)
      local mark = U.getMark(player, "@ty__gushe-turn")
      if #mark == 2 and mark[2] > 1 then
        room:setPlayerMark(player, "@ty__gushe-turn", {"times_left", mark[2] - 1})
      end
      if player:getMark("@ty__raoshe") >= 7 then
        room:killPlayer({who = player.id,})
      end
      if not player.dead then
        if #room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty__gushe-discard:"..player.id) == 0 then
          player:drawCards(1, self.name)
        end
      end
    end
    if not data.to.dead and data.winner ~= data.to then
      if player.dead then
        room:askForDiscard(data.to, 1, 1, true, self.name, false, ".", "#ty__gushe2-discard")
      else
        if #room:askForDiscard(data.to, 1, 1, true, self.name, true, ".", "#ty__gushe-discard:"..player.id) == 0 then
          player:drawCards(1, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.PindianResultConfirmed, fk.TurnStart, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player == target and player:hasSkill(ty__gushe, true)
    elseif event == fk.PindianResultConfirmed then
      return data.winner and data.winner == player and player:hasSkill(ty__gushe, true)
    elseif event == fk.EventAcquireSkill then
      return player == target and data == ty__gushe and player.phase ~= Player.NotActive
    elseif event == fk.EventLoseSkill then
      return player == target and data == ty__gushe
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local x = 7 - player:getMark("@ty__raoshe")
      room:setPlayerMark(player, "@ty__gushe-turn", x > 0 and {"times_left", x} or "invalidity")
    elseif event == fk.PindianResultConfirmed then
      local mark = U.getMark(player, "@ty__gushe-turn")
      if #mark == 2 then
        local x = mark[2] - 1
        room:setPlayerMark(player, "@ty__gushe-turn", x > 0 and {"times_left", x} or "invalidity")
      end
    elseif event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "@ty__raoshe", 0)
      room:setPlayerMark(player, "@ty__gushe-turn", {"times_left", 7})
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "@ty__raoshe", 0)
      room:setPlayerMark(player, "@ty__gushe-turn", 0)
    end
  end,
}
local ty__jici = fk.CreateTriggerSkill{
  name = "ty__jici",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.PindianCardsDisplayed, fk.Death},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PindianCardsDisplayed then
      if player:hasSkill(self) then
        if data.from == player then
          return data.fromCard.number <= player:getMark("@ty__raoshe")
        elseif table.contains(data.tos, player) then
          return data.results[player.id].toCard.number <= player:getMark("@ty__raoshe")
        end
      end
    elseif event == fk.Death then
      return target == player and player:hasSkill(self, false, true) and data.damage and data.damage.from and not data.damage.from.dead
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PindianCardsDisplayed then
      local card
      if data.from == player then
        card = data.fromCard
      elseif table.contains(data.tos, player) then
        card = data.results[player.id].toCard
      end
      card.number = card.number + player:getMark("@ty__raoshe")
      if player.dead then return end
      local n = card.number
      if data.fromCard.number > n then
        n = data.fromCard.number
      end
      for _, result in pairs(data.results) do
        if result.toCard.number > n then
          n = result.toCard.number
        end
      end
      local cards = {}
      if data.fromCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
        table.insertIfNeed(cards, data.fromCard)
      end
      for _, result in pairs(data.results) do
        if result.toCard.number == n and room:getCardArea(data.fromCard) == Card.Processing then
          table.insertIfNeed(cards, result.toCard)
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonJustMove, self.name, "", true, player.id)
      end
    elseif event == fk.Death then
      local n = 7 - player:getMark("@ty__raoshe")
      if n > 0 then
        room:askForDiscard(data.damage.from, n, n, true, self.name, false)
        if data.damage.from.dead then return false end
      end
      room:loseHp(data.damage.from, 1, self.name)
    end
  end,
}
ty__gushe:addRelatedSkill(ty__gushe_delay)
wanglang:addSkill(ty__gushe)
wanglang:addSkill(ty__jici)
Fk:loadTranslationTable{
  ["ty__wanglang"] = "王朗",
  ["#ty__wanglang"] = "凤鹛",
  ["illustrator:ty__wanglang"] = "第七个桔子", -- 皮肤 骧龙御宇
  ["ty__gushe"] = "鼓舌",
  [":ty__gushe"] = "出牌阶段，你可以用一张手牌与至多三名角色同时拼点，没赢的角色选择一项: 1.弃置一张牌；2.令你摸一张牌。"..
  "若你没赢，获得一个“饶舌”标记；若你有7个“饶舌”标记，你死亡。当你一回合内累计七次拼点赢时（每有一个“饶舌”标记，此累计次数减1），本回合此技能失效。",
  ["ty__jici"] = "激词",
  [":ty__jici"] = "锁定技，当你的拼点牌亮出后，若此牌点数小于等于X，则点数+X（X为“饶舌”标记的数量）且你获得本次拼点中点数最大的牌。"..
  "你死亡时，杀死你的角色弃置7-X张牌并失去1点体力。",
  ["#ty__gushe-active"] = "发动 鼓舌，与1-3名角色拼点！",
  ["#ty__gushe-discard"] = "鼓舌：你需弃置一张牌，否则 %src 摸一张牌",
  ["#ty__gushe2-discard"] = "鼓舌：你需弃置一张牌",
  ["#ty__gushe_delay"] = "鼓舌",
  ["@ty__gushe-turn"] = "鼓舌",
  ["@ty__raoshe"] = "饶舌",
  ["times_left"] = "剩余",
  ["invalidity"] = "失效",

  ["$ty__gushe1"] = "承寇贼之要，相时而后动，择地而后行，一举更无余事。",
  ["$ty__gushe2"] = "春秋之义，求诸侯莫如勤王。今天王在魏都，宜遣使奉承王命。",
  ["$ty__jici1"] = "天数有变，神器更易，而归于有德之人，此自然之理也。",
  ["$ty__jici2"] = "王命之师，囊括五湖，席卷三江，威取中国，定霸华夏。",
  ["~ty__wanglang"] = "我本东海弄墨客，如何枉做沙场魂……",
}

local liuhui = General(extension, "liuhui", "qun", 4)

local function startCircle(player, points)
  local room = player.room
  table.shuffle(points)
  room:setPlayerMark(player, "@[geyuan]", {
    all = points, ok = {}
  })
end

--- 返回下一个能点亮圆环的点数
---@return integer[]
local function getCircleProceed(value)
  local all_points = value.all
  local ok_points = value.ok
  local all_len = #all_points
  -- 若没有点亮的就全部都满足
  if #ok_points == 0 then return all_points end
  -- 若全部点亮了返回空表
  if #ok_points == all_len then return Util.DummyTable end

  local function c(idx)
    if idx == 0 then idx = all_len end
    if idx == all_len + 1 then idx = 1 end
    return idx
  end

  -- 否则，显示相邻的，逻辑上要构成循环
  local ok_map = {}
  for _, v in ipairs(ok_points) do ok_map[v] = true end
  local start_idx, end_idx
  for i, v in ipairs(all_points) do
    -- 前一个不亮，这个是左端
    if ok_map[v] and not ok_map[all_points[c(i-1)]] then
      start_idx = i
    end
    -- 后一个不亮，这个是右端
    if ok_map[v] and not ok_map[all_points[c(i+1)]] then
      end_idx = i
    end
  end

  start_idx = c(start_idx - 1)
  end_idx = c(end_idx + 1)

  if start_idx == end_idx then
    return { all_points[start_idx] }
  else
    return { all_points[start_idx], all_points[end_idx] }
  end
end

Fk:addQmlMark{
  name = "geyuan",
  how_to_show = function(name, value)
    -- FIXME: 神秘bug导致value可能为空串有待排查
    if type(value) ~= "table" then return " " end
    local nums = getCircleProceed(value)
    if #nums == 1 then
      return Card:getNumberStr(nums[1])
    elseif #nums == 2 then
      return Card:getNumberStr(nums[1]) .. Card:getNumberStr(nums[2])
    else
      return " "
    end
  end,
  qml_path = "packages/tenyear/qml/GeyuanBox"
}

local geyuan = fk.CreateTriggerSkill{
  name = "geyuan",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local circle_data = player:getMark("@[geyuan]")
    if circle_data == 0 then return end
    local proceed = getCircleProceed(circle_data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local number = Fk:getCardById(info.cardId).number
          if table.contains(proceed, number) then return true end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local circle_data = player:getMark("@[geyuan]")
    local proceed = getCircleProceed(circle_data)
    local completed = false
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local number = Fk:getCardById(info.cardId).number
          if table.contains(proceed, number) then
            table.insert(circle_data.ok, number)
            proceed = getCircleProceed(circle_data)
            if proceed == Util.DummyTable then -- 已完成？
              -- FAQ: 成功了后还需结算剩下的？摸了，我不结算
              completed = true
              goto BREAK
            end
          end
        end
      end
    end
    ::BREAK::

    if completed then
      local start, end_ = circle_data.ok[1], circle_data.ok[#circle_data.ok]
      local waked = player:usedSkillTimes("gusuan", Player.HistoryGame) > 0
      if waked then
        local players = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
          0, 3, "#gusuan-choose", self.name, true)

        if players[1] then
          room:getPlayerById(players[1]):drawCards(3, self.name)
        end
        if players[2] then
          local p = room:getPlayerById(players[2])
          room:askForDiscard(p, 4, 4, true, self.name, false)
        end
        if players[3] then
          local p = room:getPlayerById(players[3])
          local cards = p:getCardIds(Player.Hand)
          room:moveCards({
            from = p.id,
            ids = cards,
            toArea = Card.Processing,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false,
          })
          if not p.dead then
            room:moveCardTo(room:getNCards(5, "bottom"), Card.PlayerHand, p, fk.ReasonExchange, self.name, nil, false, player.id)
          end
          if #cards > 0 then
            table.shuffle(cards)
            room:moveCards({
              ids = cards,
              fromArea = Card.Processing,
              toArea = Card.DrawPile,
              moveReason = fk.ReasonExchange,
              skillName = self.name,
              moveVisible = false,
              drawPilePosition = -1,
            })
          end
        end
      else
        local toget = {}
        for _, p in ipairs(room.alive_players) do
          for _, id in ipairs(p:getCardIds("ej")) do
            local c = Fk:getCardById(id, true)
            if c.number == start or c.number == end_ then
              table.insert(toget, c.id)
            end
          end
        end
        for _, id in ipairs(room.draw_pile) do
          local c = Fk:getCardById(id, true)
          if c.number == start or c.number == end_ then
            table.insert(toget, c.id)
          end
        end
        room:moveCardTo(toget, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end

      local all = circle_data.all
      if not waked then
        if #all > 3 then table.removeOne(all, start) end
        if #all > 3 then table.removeOne(all, end_) end
      end
      startCircle(player, all)
    else
      room:setPlayerMark(player, "@[geyuan]", circle_data)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[geyuan]", 0)
  end,
}
local geyuan_start = fk.CreateTriggerSkill{
  name = "#geyuan_start",
  main_skill = geyuan,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(geyuan) and player:getMark("@[geyuan]") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("geyuan")
    local points = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    startCircle(player, points)
  end
}
geyuan:addRelatedSkill(geyuan_start)
local jieshu = fk.CreateTriggerSkill{
  name = "jieshu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player:getMark("@[geyuan]") ~= 0 then
      local proceed = getCircleProceed(player:getMark("@[geyuan]"))
      return table.contains(proceed, data.card.number)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local jieshu_max = fk.CreateMaxCardsSkill{
  name = "#jieshu_maxcard",
  exclude_from = function(self, player, card)
    if player:hasSkill(jieshu) then
      local mark = player:getMark("@[geyuan]")
      local all = Util.DummyTable
      if type(mark) == "table" and mark.all then all = mark.all end
      return not table.contains(all, card.number)
    end
  end,
}
jieshu:addRelatedSkill(jieshu_max)
local gusuan = fk.CreateTriggerSkill{
  name = "gusuan",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local mark = player:getMark("@[geyuan]")
    return type(mark) == "table" and #mark.all == 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
  end,
}
liuhui:addSkill(geyuan)
liuhui:addSkill(jieshu)
liuhui:addSkill(gusuan)
Fk:loadTranslationTable{
  ["liuhui"] = "刘徽",
  ["#liuhui"] = "周天古率",
  ["cv:liuhui"] = "冰霜墨菊",
  ["illustrator:liuhui"] = "凡果_肉山大魔王",

  ["geyuan"] = "割圆",
  [":geyuan"] = '锁定技，游戏开始时，将A~K的所有点数随机排列成一个圆环。有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你获得牌堆和场上所有完成此圆环最初和最后点数的牌，然后从圆环中移除这两个点数（不会被移除到三个以下），重新开始圆环。<br><font color="grey">进度点数：圆环中即将被点亮的点数。</font>',
  ["jieshu"] = "解术",
  [":jieshu"] = "锁定技，非圆环内点数的牌不计入你的手牌上限。你使用或打出牌时，若满足圆环进度点数，你摸一张牌。",
  ["gusuan"] = "股算",
  [":gusuan"] = '觉醒技，每个回合结束时，若圆环剩余点数为3个，你减1点体力上限，并修改“割圆”。<br><font color="grey">☆割圆·改：锁定技，有牌进入弃牌堆时，将满足圆环进度的点数记录在圆环内。当圆环完成后，你至多依次选择三名角色（按照点击他们的顺序）并依次执行其中一项：1.摸三张牌；2.弃四张牌；3.将其手牌与牌堆底五张牌交换。结算完成后，重新开始圆环。</font>',

  ["@[geyuan]"] = "割圆", -- 仅用到了前缀，因为我感觉够了，实际上右括号后能加更多后缀
  ["#geyuan_start"] = "割圆",
  ["#gusuan-choose"] = "割圆：依次点选至多三名角色，第一个摸3，第二个弃4，第三个换牌",

  ["$geyuan1"] = "绘同径之距，置内圆而割之。",
  ["$geyuan2"] = "矩割弥细，圆失弥少，以至不可割。",
  ["$jieshu1"] = "累乘除以成九数者，可以加减解之。",
  ["$jieshu2"] = "数有其理，见筹一可知沙数。",
  ["$gusuan1"] = "勾中容横，股中容直，可知其玄五。",
  ["$gusuan2"] = "累矩连索，类推衍化，开立而得法。",
  ["~liuhui"] = "算学如海，穷我一生，只得杯水……",
}

--武庙：诸葛亮 陆逊 关羽 皇甫嵩
local zhugeliang = General(extension, "wm__zhugeliang", "shu", 4, 7)
local jincui = fk.CreateTriggerSkill{
  name = "jincui",
  anim_type = "control",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.EventPhaseStart, fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self) and player:getHandcardNum() < 7
    elseif event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self) and player.phase == Player.Start
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      local n = 7 - player:getHandcardNum()
      if n > 0 then
        player:drawCards(n, self.name)
      end
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name)
      player:broadcastSkillInvoke(self.name)
      local n = 0
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == 7 then
          n = n + 1
        end
      end
      player.hp = math.min(player.maxHp, math.max(n, 1))
      room:broadcastProperty(player, "hp")
      room:askForGuanxing(player, room:getNCards(player.hp))
    end
  end,
}
local qingshi = fk.CreateTriggerSkill{
  name = "qingshi",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getMark("qingshi_invalidity-turn") == 0 and
      table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end) and
      not table.contains(U.getMark(player, "qingshi-turn"), data.card.trueName)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"qingshi1", "qingshi2", "qingshi3", "Cancel"},
    self.name, "#qingshi-invoke:::"..data.card:toLogString())
    if choice == "qingshi1" then
      local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(data.tos), 1, 1,
        "#qingshi1-choose:::"..data.card:toLogString(), self.name)
      if #to > 0 then
        self.cost_data = {choice, to}
        return true
      end
    elseif choice == "qingshi2" then
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 998,
      "#qingshi2-choose:::"..data.card:toLogString(), self.name)
      if #to > 0 then
        self.cost_data = {choice, to}
        return true
      end
    elseif choice == "qingshi3" then
      self.cost_data = {choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "qingshi-turn")
    table.insert(mark, data.card.trueName)
    room:setPlayerMark(player, "qingshi-turn", mark)
    if self.cost_data[1] == "qingshi1" then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi_data = data.extra_data.qingshi_data or {}
      table.insert(data.extra_data.qingshi_data, {player.id, self.cost_data[2][1]})
    elseif self.cost_data[1] == "qingshi2" then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      local tos = self.cost_data[2]
      room:sortPlayersByAction(tos)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          p:drawCards(1, self.name)
        end
      end
    elseif self.cost_data[1] == "qingshi3" then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name)
      player:drawCards(3, self.name)
      room:setPlayerMark(player, "qingshi_invalidity-turn", 1)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return target == player and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "qingshi-turn", 0)
    room:setPlayerMark(player, "qingshi_invalidity-turn", 0)
  end,
}
local qingshi_delay = fk.CreateTriggerSkill{
  name = "#qingshi_delay",
  events = {fk.DamageCaused},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or data.chain then return false end
    local room = player.room
      local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if not card_event then return false end
      local use = card_event.data[1]
      if use.extra_data then
        local qingshi_data = use.extra_data.qingshi_data
        if qingshi_data then
          return table.find(qingshi_data, function (players)
            return players[1] == player.id and players[2] == data.to.id
          end)
        end
      end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(qingshi.name)
    data.damage = data.damage + 1
  end,
}
local zhizhe = fk.CreateActiveSkill{
  name = "zhizhe",
  prompt = "#zhizhe-active",
  anim_type = "special",
  frequency = Skill.Limited,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
    and not Fk:getCardById(to_select).is_derived and to_select > 0
  end,
  on_use = function(self, room, effect)
    local c = Fk:getCardById(effect.cards[1], true)
    local toGain = room:printCard(c.name, c.suit, c.number)
    room:moveCards({
      ids = {toGain.id},
      to = effect.from,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = effect.from,
      skillName = self.name,
      moveVisible = false,
    })
  end
}
local zhizhe_delay = fk.CreateTriggerSkill{
  name = "#zhizhe_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    local mark = U.getMark(player, "zhizhe")
    if #mark == 0 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    if parent_event and (parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard) then
      local parent_data = parent_event.data[1]
      if parent_data.from == player.id then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        local to_get = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if info.fromArea == Card.Processing and room:getCardArea(id) == Card.DiscardPile and
              table.contains(card_ids, id) and table.contains(mark, id) then
                table.insertIfNeed(to_get, id)
              end
            end
          end
        end
        if #to_get > 0 then
          self.cost_data = to_get
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(zhizhe.name)
    room:obtainCard(player, self.cost_data, true, fk.ReasonJustMove, player.id, "zhizhe")
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local marked = U.getMark(player, "zhizhe")
    local marked2 = U.getMark(player, "zhizhe-turn")
    marked2 = table.filter(marked2, function (id)
      return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player
    end)
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == zhizhe.name then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
            if info.fromArea == Card.Void then
              table.insertIfNeed(marked, id)
            else
              table.insert(marked2, id)
            end
            room:setCardMark(Fk:getCardById(id), "@@zhizhe-inhand", 1)
          end
        end
      elseif move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.removeOne(marked, id)
        end
      end
    end
    room:setPlayerMark(player, "zhizhe", marked)
    room:setPlayerMark(player, "zhizhe-turn", marked2)
  end,
}
local zhizhe_prohibit = fk.CreateProhibitSkill{
  name = "#zhizhe_prohibit",
  prohibit_use = function(self, player, card)
    local mark = U.getMark(player, "zhizhe-turn")
    if #mark == 0 then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("zhizhe-turn")
    if #mark == 0 then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return table.contains(mark, id) end)
  end,
}
qingshi:addRelatedSkill(qingshi_delay)
zhizhe:addRelatedSkill(zhizhe_delay)
zhizhe:addRelatedSkill(zhizhe_prohibit)
zhugeliang:addSkill(jincui)
zhugeliang:addSkill(qingshi)
zhugeliang:addSkill(zhizhe)
Fk:loadTranslationTable{
  ["wm__zhugeliang"] = "武诸葛亮",
  ["#wm__zhugeliang"] = "忠武良弼",
  ["designer:wm__zhugeliang"] = "韩旭",
  ["illustrator:wm__zhugeliang"] = "梦回唐朝",
  ["jincui"] = "尽瘁",
  [":jincui"] = "锁定技，游戏开始时，你将手牌补至7张。准备阶段，你的体力值调整为与牌堆中点数为7的游戏牌数量相等（至少为1）。"..
  "然后你观看牌堆顶X张牌（X为你的体力值），将这些牌以任意顺序放回牌堆顶或牌堆底。",
  ["qingshi"] = "情势",
  [":qingshi"] = "当你于出牌阶段内使用一张牌时（每种牌名每回合限一次），若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1："..
  "2.令任意名其他角色各摸一张牌；3.摸三张牌，然后此技能本回合失效。",
  ["zhizhe"] = "智哲",
  [":zhizhe"] = "限定技，出牌阶段，你可以复制一张手牌（衍生牌除外）。此牌因你使用或打出而进入弃牌堆后，你获得且本回合不能再使用或打出之。",
  ["qingshi-turn"] = "情势",
  ["qingshi_invalidity-turn"] = "情势失效",
  ["#qingshi-invoke"] = "情势：请选择一项（当前使用牌为%arg）",
  ["qingshi1"] = "令此牌对其中一个目标伤害+1",
  ["qingshi2"] = "令任意名其他角色各摸一张牌",
  ["qingshi3"] = "摸三张牌，然后此技能本回合失效",
  ["#qingshi1-choose"] = "情势：令%arg对其中一名目标造成伤害+1",
  ["#qingshi2-choose"] = "情势：令任意名其他角色各摸一张牌",
  ["#qingshi_delay"] = "情势",
  ["#zhizhe_delay"] = "智哲",
  ["#zhizhe-active"] = "发动 智哲，选择一张手牌（衍生牌除外），获得一张此牌的复制",
  ["@@zhizhe-inhand"] = "智哲",

  ["$jincui1"] = "情记三顾之恩，亮必继之以死。",
  ["$jincui2"] = "身负六尺之孤，臣当鞠躬尽瘁。",
  ["$qingshi1"] = "兵者，行霸道之势，彰王道之实。",
  ["$qingshi2"] = "将为军魂，可因势而袭，其有战无类。",
  ["$zhizhe1"] = "轻舟载浊酒，此去，我欲借箭十万。",
  ["$zhizhe2"] = "主公有多大胆略，亮便有多少谋略。",
  ["~wm__zhugeliang"] = "天下事，了犹未了，终以不了了之……",
}

local luxun = General(extension, "wm__luxun", "wu", 3)
local xiongmu = fk.CreateTriggerSkill{
  name = "xiongmu",
  mute = true,
  events = {fk.RoundStart, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundStart then
        return true
      else
        return player == target and player:getHandcardNum() <= player.hp and player:getMark("xiongmu_defensive-turn") == 0 and
        #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          return damage and damage.to == player
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "drawcard")
      local x = player.maxHp - player:getHandcardNum()
      if x > 0 and room:askForSkillInvoke(player, self.name, nil, "#xiongmu-draw:::" .. tostring(x)) then
        room:drawCards(player, x, self.name)
        if player.dead then return false end
      end
      if player:isNude() then return false end
      local cards = room:askForCard(player, 1, 998, true, self.name, true, ".", "#xiongmu-cards")
      x = #cards
      if x == 0 then return false end
      table.shuffle(cards)
      local positions = {}
      local y = #room.draw_pile
      for _ = 1, x, 1 do
        table.insert(positions, math.random(y+1))
      end
      table.sort(positions, function (a, b)
        return a > b
      end)
      local moveInfos = {}
      for i = 1, x, 1 do
        table.insert(moveInfos, {
          ids = {cards[i]},
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
          drawPilePosition = positions[i],
        })
      end
      room:moveCards(table.unpack(moveInfos))
      if player.dead then return false end
      cards = room:getCardsFromPileByRule(".|8", x)
      if x > #cards then
        table.insertTable(cards, room:getCardsFromPileByRule(".|8", x - #cards, "discardPile"))
      end
      if #cards > 0 then
        player.room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
          moveMark = "@@xiongmu-inhand-round",
        })
      end
    else
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "defensive")
      room:setPlayerMark(player, "xiongmu_defensive-turn", 1)
      data.damage = data.damage - 1
    end
  end,

}
local xiongmu_maxcards = fk.CreateMaxCardsSkill{
  name = "#xiongmu_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@xiongmu-inhand-round") > 0
  end,
}
local zhangcai = fk.CreateTriggerSkill{
  name = "zhangcai",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player:getMark("@@ruxian") > 0 or data.card.number == 8)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(math.max(1, #table.filter(player:getCardIds(Player.Hand), function (id)
      return Fk:getCardById(id):compareNumberWith(data.card, false)
    end)), self.name)
  end,
}
local ruxian = fk.CreateActiveSkill{
  name = "ruxian",
  prompt = "#ruxian-active",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    room:setPlayerMark(room:getPlayerById(effect.from), "@@ruxian", 1)
  end,
}
local ruxian_refresh = fk.CreateTriggerSkill{
  name = "#ruxian_refresh",

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@ruxian") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ruxian", 0)
  end,
}
xiongmu:addRelatedSkill(xiongmu_maxcards)
ruxian:addRelatedSkill(ruxian_refresh)
luxun:addSkill(xiongmu)
luxun:addSkill(zhangcai)
luxun:addSkill(ruxian)
Fk:loadTranslationTable{
  ["wm__luxun"] = "武陆逊",
  ["#wm__luxun"] = "释武怀儒",
  ["designer:wm__luxun"] = "韩旭",
  ["illustrator:wm__luxun"] = "小新",
  ["xiongmu"] = "雄幕",
  [":xiongmu"] = "每轮开始时，你可以将手牌摸至体力上限，然后将任意张牌随机置入牌堆，从牌堆或弃牌堆中获得等量的点数为8的牌，"..
  "这些牌此轮内不计入你的手牌上限。当你每回合受到第一次伤害时，若你的手牌数小于等于体力值，此伤害-1。",
  ["zhangcai"] = "彰才",
  [":zhangcai"] = "当你使用或打出点数为8的牌时，你可以摸X张牌（X为手牌中与使用的牌点数相同的牌的数量且至少为1）。",
  ["ruxian"] = "儒贤",
  [":ruxian"] = "限定技，出牌阶段，你可以将〖彰才〗改为所有点数均可触发摸牌直到你的下回合开始。",

  ["#xiongmu-draw"] = "雄幕：是否将手牌补至体力上限（摸%arg张牌）",
  ["#xiongmu-cards"] = "雄幕：你可将任意张牌随机置入牌堆，然后获得等量张点数为8的牌",
  ["@@xiongmu-inhand-round"] = "雄幕",
  ["#ruxian-active"] = "发动 儒贤，令你发动〖彰才〗没有点数的限制直到你的下个回合开始",
  ["@@ruxian"] = "儒贤",

  ["$xiongmu1"] = "步步为营者，定无后顾之虞。",
  ["$xiongmu2"] = "明公彀中藏龙卧虎，放之海内皆可称贤。",
  ["$zhangcai1"] = "今提墨笔绘乾坤，湖海添色山永春。",
  ["$zhangcai2"] = "手提玉剑斥千军，昔日锦鲤化金龙。",
  ["$ruxian1"] = "儒道尚仁而有礼，贤者知命而独悟。",
  ["$ruxian2"] = "儒门有言，仁为己任，此生不负孔孟之礼。",
  ["~wm__luxun"] = "此生清白，不为浊泥所染……",
}

local guanyu = General(extension, "wm__guanyu", "shu", 5)
local juewu = fk.CreateViewAsSkill{
  name = "juewu",
  prompt = "#juewu-viewas",
  anim_type = "offensive",
  pattern = ".",
  interaction = function()
    local names = Self:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      Self:setMark("juewu_names", names)
    end
    local choices = U.getViewAsCardNames(Self, "juewu", names, nil, U.getMark(Self, "juewu-turn"))
    if #choices == 0 then return end
    return UI.ComboBox { choices = choices, all_choices = names }
  end,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == nil or #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    if card.number == 2 then
      return true
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = U.getMark(player, "juewu-turn")
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "juewu-turn", mark)
  end,
  enabled_at_play = function(self, player)
    local names = player:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      player:setMark("juewu_names", names)
    end
    local mark = U.getMark(player, "juewu-turn")
    local choices = {}
    for _, name in pairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if not table.contains(mark, to_use.trueName) and player:canUse(to_use) then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return false end
    if Fk.currentResponsePattern == nil then return false end
    local names = player:getMark("juewu_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          table.insertIfNeed(names, card.name)
        end
      end
      table.insertIfNeed(names, "ty__drowning")
      player:setMark("juewu_names", names)
    end
    local mark = U.getMark(player, "juewu-turn")
    local choices = {}
    for _, name in pairs(names) do
      local to_use = Fk:cloneCard(name)
      to_use.skillName = self.name
      if not table.contains(mark, to_use.trueName) and Exppattern:Parse(Fk.currentResponsePattern):match(to_use) then
        return true
      end
    end
  end,
}
local juewu_trigger = fk.CreateTriggerSkill{
  name = "#juewu_trigger",
  events = {fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(juewu) then return false end
    local cards = {}
    local handcards = player:getCardIds(Player.Hand)
    for _, move in ipairs(data) do
      if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if table.contains({Player.Hand, Player.Equip}, info.fromArea) and  table.contains(handcards, id) then
            table.insert(cards, id)
          end
        end
      end
    end
    cards = U.moveCardsHoldingAreaCheck(player.room, cards)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      room:setCardMark(Fk:getCardById(id), "@@juewu-inhand", 1)
    end
  end,
}
local juewu_filter = fk.CreateFilterSkill{
  name = "#juewu_filter",
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@juewu-inhand") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card.name, card.suit, 2)
  end,
}
local wuyou = fk.CreateActiveSkill{
  name = "wuyou",
  prompt = "#wuyou-active",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = effect.tos and #effect.tos > 0 and room:getPlayerById(effect.tos[1]) or player
    local card_names = player:getMark("wuyou_names")
    if type(card_names) ~= "table" then
      card_names = {}
      local tmp_names = {}
      local card, index
      for _, id in ipairs(Fk:getAllCardIds()) do
        card = Fk:getCardById(id, true)
        if not card.is_derived and card.type ~= Card.TypeEquip then
          index = table.indexOf(tmp_names, card.trueName)
          if index == -1 then
            table.insert(tmp_names, card.trueName)
            table.insert(card_names, {card.name})
          else
            table.insertIfNeed(card_names[index], card.name)
          end
        end
      end
      room:setPlayerMark(player, "wuyou_names", card_names)
    end
    if #card_names == 0 then return end
    card_names = table.map(table.random(card_names, 5), function (card_list)
      return table.random(card_list)
    end)
    local success, dat = room:askForUseActiveSkill(player, "wuyou_declare",
    "#wuyou-declare::" .. target.id, true, { interaction_choices = card_names })
    if not success then return end
    local id = dat.cards[1]
    local card_name = dat.interaction
    if target == player then
      room:setCardMark(Fk:getCardById(id), "@@wuyou-inhand", card_name)
    else
      room:moveCardTo(id, Player.Hand, target, fk.ReasonGive, self.name, nil, false, player.id, {"@@wuyou-inhand", card_name})
    end
  end,
}
local wuyou_refresh = fk.CreateTriggerSkill{
  name = "#wuyou_refresh",

  refresh_events = {fk.PreCardUse, fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      return player == target and not data.card:isVirtual() and data.card:getMark("@@wuyou-inhand") ~= 0
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    elseif event == fk.BuryVictim then
      return player:hasSkill(self, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.PreCardUse then
      data.extraUse = true
      return false
    end
    local room = player.room
    if table.every(room.alive_players, function(p) return not p:hasSkill(self, true) or p == player end) then
      if player:hasSkill("wuyou&", true, true) then
        room:handleAddLoseSkills(player, "-wuyou&", nil, false, true)
      end
    else
      if not player:hasSkill("wuyou&", true, true) then
        room:handleAddLoseSkills(player, "wuyou&", nil, false, true)
      end
    end
  end,
}
local wuyou_active = fk.CreateActiveSkill{
  name = "wuyou&",
  anim_type = "support",
  prompt = "#wuyou-other",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    local targetRecorded = U.getMark(player, "wuyou_targets-phase")
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p ~= player and p:hasSkill(wuyou) and not table.contains(targetRecorded, p.id)
    end)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill(wuyou) and
    not table.contains(U.getMark(Self, "wuyou_targets-phase"), to_select)
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.from)
    local player = room:getPlayerById(effect.tos[1])
    player:broadcastSkillInvoke("wuyou")
    local targetRecorded = U.getMark(target, "wuyou_targets-phase")
    table.insertIfNeed(targetRecorded, player.id)
    room:setPlayerMark(target, "wuyou_targets-phase", targetRecorded)
    room:moveCardTo(effect.cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, target.id)
    if player.dead or player:isKongcheng() or target.dead then return end
    wuyou:onUse(room, {from = player.id, tos = {target.id}})
  end,
}
local wuyou_declare = fk.CreateActiveSkill{
  name = "wuyou_declare",
  card_num = 1,
  target_num = 0,
  interaction = function(self)
    return UI.ComboBox { choices = self.interaction_choices}
  end,
  can_use = Util.FalseFunc,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
}
local wuyou_filter = fk.CreateFilterSkill{
  name = "#wuyou_filter",
  mute = true,
  card_filter = function(self, card, player, isJudgeEvent)
    return card:getMark("@@wuyou-inhand") ~= 0 and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard(card:getMark("@@wuyou-inhand"), card.suit, card.number)
  end,
}
local wuyou_targetmod = fk.CreateTargetModSkill{
  name = "#wuyou_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return not card:isVirtual() and card:getMark("@@wuyou-inhand") ~= 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return not card:isVirtual() and card:getMark("@@wuyou-inhand") ~= 0
  end,
}
local yixian = fk.CreateActiveSkill{
  name = "yixian",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  interaction = function()
    return UI.ComboBox {
      choices = {"yixian_field", "yixian_discard"}
    }
  end,
  prompt = function(self)
    return "#yixian-active:::" .. self.interaction.data
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "yixian_field" then
      local yixianmap = {}
      local cards = {}
      local equips = {}
      for _, p in ipairs(room.alive_players) do
        equips = p:getCardIds{Player.Equip}
        if #equips > 0 then
          yixianmap[p.id] = #equips
          table.insertTable(cards, equips)
        end
      end
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      if player.dead then return end
      for _, p in ipairs(room:getAlivePlayers()) do
        if not p.dead then
          local n = yixianmap[p.id]
          if n and n > 0 and room:askForSkillInvoke(player, self.name, nil, "#yixian-repay::" .. p.id..":"..tostring(n)) then
            room:drawCards(p, n, self.name)
            if not p.dead and p:isWounded() then 
              room:recover{
                who = p,
                num = 1,
                recoverBy = player,
                skillName = self.name,
              }
            end
            if player.dead then break end
          end
        end
      end
    elseif self.interaction.data == "yixian_discard" then
      local equips = table.filter(room.discard_pile, function(id)
        return Fk:getCardById(id).type == Card.TypeEquip
      end)
      if #equips > 0 then
        room:moveCardTo(equips, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
  end,
}
Fk:addSkill(wuyou_active)
Fk:addSkill(wuyou_declare)
juewu:addRelatedSkill(juewu_trigger)
juewu:addRelatedSkill(juewu_filter)
wuyou:addRelatedSkill(wuyou_refresh)
wuyou:addRelatedSkill(wuyou_filter)
wuyou:addRelatedSkill(wuyou_targetmod)
guanyu:addSkill(juewu)
guanyu:addSkill(wuyou)
guanyu:addSkill(yixian)
Fk:loadTranslationTable{
  ["wm__guanyu"] = "武关羽",
  ["#wm__guanyu"] = "义武千秋",
  ["illustrator:wm__guanyu"] = "黯荧岛_小董",
  ["juewu"] = "绝武",
  [":juewu"] = "你可以将点数为2的牌当伤害牌或【水淹七军】使用（每回合每种牌名限一次）。当你得到其他角色的牌后，这些牌的点数视为2。",
  ["wuyou"] = "武佑",
  [":wuyou"] = "出牌阶段限一次，你可以从五个随机的不为装备牌的牌名中声明一个并选择你的一张手牌，此牌视为你声明的牌且使用时无距离和次数限制。"..
  "其他角色的出牌阶段限一次，其可以将一张手牌交给你，然后你可以从五个随机的不为装备牌的牌名中声明一个并将一张手牌交给该角色，"..
  "此牌视为你声明的牌且使用时无距离和次数限制。",
  ["yixian"] = "义贤",
  [":yixian"] = "限定技，出牌阶段，你可以选择：1.获得场上的所有装备牌，你对以此法被你获得牌的角色依次可以令其摸等量的牌并回复1点体力；"..
  "2.获得弃牌堆中的所有装备牌。",

  ["#juewu-viewas"] = "发动 绝武，将点数为2的牌转化为任意伤害牌使用",
  ["#juewu_trigger"] = "绝武",
  ["#juewu_filter"] = "绝武",
  ["@@juewu-inhand"] = "绝武",
  ["wuyou&"] = "武佑",
  [":wuyou&"] = "出牌阶段限一次，你可以将一张牌交给武关羽，然后其可以将一张牌交给你并声明一种基本牌或普通锦囊牌的牌名，此牌视为声明的牌。",
  ["#wuyou-active"] = "发动 武佑，令一张手牌视为你声明的牌（五选一）",
  ["#wuyou-other"] = "发动 武佑，选择一张牌交给一名拥有“武佑”的角色",
  ["#wuyou-declare"] = "武佑：将一张手牌交给%dest并令此牌视为声明的牌名",
  ["wuyou_declare"] = "武佑",
  ["#wuyou_filter"] = "武佑",
  ["@@wuyou-inhand"] = "武佑",
  ["#yixian-active"] = "发动 义贤，%arg",
  ["yixian_field"] = "获得场上的装备牌",
  ["yixian_discard"] = "获得弃牌堆里的装备牌",
  ["#yixian-repay"] = "义贤：是否令%dest摸%arg张牌并回复1点体力",

  ["$juewu1"] = "此身屹沧海，覆手潮立，浪涌三十六天。",
  ["$juewu2"] = "青龙啸肃月，长刀裂空，威降一十九将。",
  ["$wuyou1"] = "秉赤面，观春秋，虓菟踏纛，汗青著峥嵘！",
  ["$wuyou2"] = "着青袍，饮温酒，五关已过，来将且通名！",
  ["$yixian1"] = "春秋着墨十万卷，长髯映雪千里行。",
  ["$yixian2"] = "义驱千里长路，风起桃园芳菲。",
  ["~wm__guanyu"] = "天下泪染将军袍，且枕青山梦桃园……",
}

local huangfusong = General(extension, "wm__huangfusong", "qun", 4)
local chaozhen = fk.CreateTriggerSkill{
  name = "chaozhen",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@@chaozhen-turn") == 0 and
      (event == fk.EventPhaseStart and player.phase == Player.Start or event == fk.EnterDying)
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"Field", "Pile", "Cancel"}, self.name, "#chaozhen-invoke")
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards, num = {}, 14
    if self.cost_data.choice == "Field" then
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds("ej")) do
          if Fk:getCardById(id).number <= num then
            num = Fk:getCardById(id).number
            table.insert(cards, id)
          end
        end
      end
    else
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number <= num then
          num = Fk:getCardById(id).number
          table.insert(cards, id)
        end
      end
    end
    cards = table.filter(cards, function (id)
      return Fk:getCardById(id).number == num
    end)
    if #cards == 0 then return end
    local card = table.random(cards)
    local yes = Fk:getCardById(card).number == 1
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    if player.dead then return end
    if yes then
      room:setPlayerMark(player, "@@chaozhen-turn", 1)
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    else
      room:changeMaxHp(player, -1)
    end
  end,
}
local lianjie = fk.CreateTriggerSkill{
  name = "lianjie",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and player:getHandcardNum() < player.maxHp and
      U.IsUsingHandcard(player, data) and not player:isKongcheng() and
      table.every(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number >= data.card.number
      end) and
      not table.contains(player:getTableMark("lianjie-turn"), data.card.number)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "lianjie-turn", data.card.number)
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name, "top", "@@lianjie-inhand-turn")
  end,
}
local lianjie_targetmod = fk.CreateTargetModSkill{
  name = "#lianjie_targetmod",
  bypass_times = function (self, player, skill, scope, card, to)
    return card:getMark("@@lianjie-inhand-turn") > 0
  end,
  bypass_distances = function(self, player, skill, card)
    return card:getMark("@@lianjie-inhand-turn") > 0
  end,
}
local jiangxian = fk.CreateActiveSkill{
  name = "jiangxian",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  prompt = "#jiangxian",
  interaction = function()
    local choices = {"jiangxian2"}
    if Self:hasSkill(chaozhen, true) then
      table.insert(choices, 1, "jiangxian1")
    end
    return UI.ComboBox {choices = choices}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "jiangxian1" then
      room:handleAddLoseSkills(player, "-chaozhen", nil, true, false)
      if player.dead then return end
      room:setPlayerMark(player, "jiangxian1", 1)
      if player.maxHp < 5 then
        room:changeMaxHp(player, 5 - player.maxHp)
      end
    else
      room:setPlayerMark(player, "@@jiangxian-turn", 1)
    end
  end,
}
local jiangxian_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiangxian_maxcards",
  fixed_func = function(self, player)
    if player:getMark("jiangxian1") > 0 then
      return 5
    end
  end
}
local jiangxian_delay = fk.CreateTriggerSkill{
  name = "#jiangxian_delay",
  mute = true,
  events = {fk.DamageCaused, fk.AfterTurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target and target == player and player:getMark("@@jiangxian-turn") > 0 then
      if event == fk.DamageCaused then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event then
        local use = use_event.data[1]
        return (use.extra_data or {}).jiangxian == player.id
      end
      elseif event == fk.AfterTurnEnd then
        return player:hasSkill(lianjie, true)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      data.damage = data.damage + math.min(5,
      #player.room.logic:getActualDamageEvents(5, function(e)
        return e.data[1].from == player
      end, Player.HistoryTurn))
    elseif event == fk.AfterTurnEnd then
      room:handleAddLoseSkills(player, "-lianjie", nil, true, false)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("@@jiangxian-turn") > 0 and data.card.is_damage_card and
      data.card:getMark("@@lianjie-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.jiangxian = player.id
  end,
}
lianjie:addRelatedSkill(lianjie_targetmod)
jiangxian:addRelatedSkill(jiangxian_maxcards)
jiangxian:addRelatedSkill(jiangxian_delay)
huangfusong:addSkill(chaozhen)
huangfusong:addSkill(lianjie)
huangfusong:addSkill(jiangxian)
Fk:loadTranslationTable{
  ["wm__huangfusong"] = "武皇甫嵩",
  ["#wm__huangfusong"] = "",
  ["illustrator:wm__huangfusong"] = "",

  ["chaozhen"] = "朝镇",
  [":chaozhen"] = "准备阶段或当你进入濒死状态时，你可以选择从场上或牌堆中随机获得一张点数最小的牌，若此牌点数：为A，你回复1点体力，"..
  "此技能本回合失效；不为A，你减1点体力上限。",
  ["lianjie"] = "连捷",
  [":lianjie"] = "当你使用手牌指定目标后，若你手牌的点数均不小于此牌点数（每个点数每回合限一次，无点数视为0），你可以将手牌摸至体力上限，"..
  "本回合使用以此法摸到的牌无距离次数限制。",
  ["jiangxian"] = "将贤",
  [":jiangxian"] = "限定技，出牌阶段，你可以选择一项：<br>1.失去〖朝镇〗，将体力上限和手牌上限增加至5；<br>2.直到回合结束，当你使用因"..
  "〖连捷〗获得的牌造成伤害时，此伤害+X（X为你本回合造成伤害次数，至多为5），此回合结束后你失去〖连捷〗。",
  ["#chaozhen-invoke"] = "朝镇：你可以从场上或牌堆中随机获得一张点数最小的牌",
  ["@@chaozhen-turn"] = "朝镇失效",
  ["@@lianjie-inhand-turn"] = "连捷",
  ["#jiangxian"] = "将贤：选择一项",
  ["jiangxian1"] = "失去“朝镇”，体力上限和手牌上限增加至5",
  ["jiangxian2"] = "使用“连捷”牌伤害增加，回合结束失去“连捷”",
  ["@@jiangxian-turn"] = "将贤",
}



return extension
