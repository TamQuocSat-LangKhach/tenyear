local extension = Package("tenyear_huicui3")
extension.extensionName = "tenyear"
local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_huicui3"] = "十周年-群英荟萃3",
  ["mu"] = "乐",
}

--太平甲子：管亥 张闿 刘辟 裴元绍 张楚 张曼成
local guanhai = General(extension, "guanhai", "qun", 4)
local suoliang = fk.CreateTriggerSkill{
  name = "suoliang",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      data.to ~= player and not data.to.dead and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#suoliang-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForCardsChosen(player, data.to, 1, math.min(data.to.maxHp, 5), "he", self.name)
    if #cards > 0 then
      data.to:showCards(cards)
      local suits = {Card.Heart, Card.Club}
      local to_get = table.filter(cards, function (id)
        return table.contains(suits, Fk:getCardById(id).suit)
      end)
      if #to_get > 0 then
        room:obtainCard(player, to_get, true, fk.ReasonPrey, player.id, self.name)
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
    return target == player and player:hasSkill(self) and
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
  ["#guanhai"] = "掠地劫州",
  ["illustrator:guanhai"] = "六道目",
  ["suoliang"] = "索粮",
  [":suoliang"] = "每回合限一次，你对一名其他角色造成伤害后，你可以展示该角色的至多X张牌（X为其体力上限且最多为5），获得其中的<font color='red'>♥</font>和♣牌。"..
  "若你未获得牌，则弃置你选择的牌。",
  ["qinbao"] = "侵暴",
  [":qinbao"] = "锁定技，手牌数大于等于你的其他角色不能响应你使用的【杀】或普通锦囊牌。",
  ["#suoliang-invoke"] = "索粮：你可以选择 %dest 最多其体力上限张牌，获得其中的<font color='red'>♥</font>和♣牌，若没有则弃置这些牌",

  ["$suoliang1"] = "奉上万石粮草，吾便退兵！",
  ["$suoliang2"] = "听闻北海富庶，特来借粮。",
  ["$qinbao1"] = "赤箓护身，神鬼莫当。",
  ["$qinbao2"] = "头裹黄巾，代天征伐。",
  ["~guanhai"] = "这红脸汉子，为何如此眼熟……",
}

local zhangkai = General(extension, "zhangkai", "qun", 4)
local xiangshuz = fk.CreateTriggerSkill{
  name = "xiangshuz",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) and target.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return target:getHandcardNum() >= target.hp
      else
        return player:usedSkillTimes(self.name, Player.HistoryPhase) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xiangshuz-invoke::"..target.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:doIndicate(player.id, {target.id})
      local choices = {}
      for i = 0, 5, 1 do
        table.insert(choices, tostring(i))
      end
      local choice = room:askForChoice(player, choices, self.name, "#xiangshuz-choice::"..target.id)
      local mark = self.name
      if player:isKongcheng() or #room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#xiangshuz-discard") == 0 then
        mark = "@"..self.name
      end
      room:setPlayerMark(target, mark, choice)
    else
      room:doIndicate(player.id, {target.id})
      local n1 = target:getHandcardNum()
      local n2 = math.max(tonumber(target:getMark(self.name)), tonumber(target:getMark("@"..self.name)))
      room:setPlayerMark(target, self.name, 0)
      room:setPlayerMark(target, "@"..self.name, 0)
      if math.abs(n1 - n2) < 2 and not target:isNude() then
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      end
      if n1 == n2 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
zhangkai:addSkill(xiangshuz)
Fk:loadTranslationTable{
  ["zhangkai"] = "张闿",
  ["#zhangkai"] = "无餍狍鸮",
  ["illustrator:zhangkai"] = "猎枭",
  ["xiangshuz"] = "相鼠",
  [":xiangshuz"] = "其他角色出牌阶段开始时，若其手牌数不小于体力值，你可以声明一个0~5的数字（若你弃置一张手牌，则数字不公布）。"..
  "此阶段结束时，若其手牌数与你声明的数：相差1以内，你获得其一张牌；相等，你对其造成1点伤害。",
  ["#xiangshuz-invoke"] = "相鼠：猜测 %dest 此阶段结束时手牌数，若相差1以内，获得其一张牌；相等，再对其造成1点伤害",
  ["#xiangshuz-choice"] = "相鼠：猜测 %dest 此阶段结束时的手牌数",
  ["#xiangshuz-discard"] = "相鼠：你可以弃置一张手牌令你猜测的数值不公布",
  ["@xiangshuz"] = "相鼠",

  ["$xiangshuz1"] = "要财还是要命，选一个吧！",
  ["$xiangshuz2"] = "有什么好东西，都给我交出来！",
  ["~zhangkai"] = "报应竟来得这么快……",
}

local liupi = General(extension, "liupi", "qun", 4)
local juying = fk.CreateTriggerSkill{
  name = "juying",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      for _, name in ipairs({ "slash", "analeptic" }) do
        local card = Fk:cloneCard(name)
        local card_skill = card.skill
        local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
        for _, skill in ipairs(status_skills) do
          if skill:bypassTimesCheck(player, card_skill, Player.HistoryPhase, card, nil) then return true end
        end
        local history = name == "slash" and Player.HistoryPhase or Player.HistoryTurn
        local limit = card_skill:getMaxUseTime(player, history, card, nil)
        if not limit or player:usedCardTimes(name, Player.HistoryPhase) < limit then
          return true
        end
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local all_choices = {"juying1", "juying2", "juying3"}
    local choices = room:askForChoices(player, all_choices, 1, 3, self.name, "#juying-choice", true)

    if #choices == 0 then return false end

    if table.contains(choices, "juying1") then
      room:addPlayerMark(player, self.name)
    end
    if table.contains(choices, "juying2") then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
    end
    if table.contains(choices, "juying3") then
      player:drawCards(3, self.name)
    end

    if not player.dead and #choices > player.hp then
      room:askForDiscard(player, 1, 1, true, self.name, false)
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, MarkEnum.SlashResidue .. "-turn", player:getMark(self.name))
    room:setPlayerMark(player, self.name, 0)
  end,
}

liupi:addSkill(juying)
Fk:loadTranslationTable{
  ["liupi"] = "刘辟",
  ["#liupi"] = "慕义渠帅",
  ["designer:liupi"] = "韩旭",
  ["illustrator:liupi"] = "君桓文化",
  ["juying"] = "踞营",
  [":juying"] = "出牌阶段结束时，若你本阶段使用【杀】或【酒】的次数小于次数上限，你可以选择任意项：1.下个回合出牌阶段使用【杀】次数上限+1；"..
  "2.本回合手牌上限+2；3.摸三张牌。若你选择的选项数大于你的体力值，你弃置一张牌。",
  ["#juying-choice"] = "踞营：你可以选择任意项，每比体力值多选一项便弃一张牌",
  ["juying1"] = "下个回合出牌阶段使用【杀】上限+1",
  ["juying2"] = "本回合手牌上限+2",
  ["juying3"] = "摸三张牌",

  ["$juying1"] = "垒石为寨，纵万军亦可阻。",
  ["$juying2"] = "如虎踞汝南，攻守自有我。",
  ["~liupi"] = "玄德公高义，辟宁死不悔！",
}

local peiyuanshao = General(extension, "peiyuanshao", "qun", 4)
local moyu = fk.CreateActiveSkill{
  name = "moyu",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = function()
    return "#moyu-active:::" .. tostring((Self:getMark("@@moyu1-phase") > 0) and 2 or 1)
  end,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not table.contains(Self:getTableMark("moyu_targets-phase"), to_select) and
    #Fk:currentRoom():getPlayerById(to_select):getCardIds("hej") > Self:getMark("@@moyu1-phase")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "moyu_targets-phase", target.id)
    local x = 1
    if player:getMark("@@moyu1-phase") > 0 then
      x = 2
      room:setPlayerMark(player, "@@moyu1-phase", 0)
    end
    local ids = room:askForCardsChosen(player, target, x, x, "hej", self.name)
    room:obtainCard(player.id, ids, false, fk.ReasonPrey)
    if target.dead then return end
    local use = room:askForUseCard(target, "slash", "slash", "#moyu-slash::"..player.id, true,
      {must_targets = {player.id}, bypass_distances = true, bypass_times = true})
    if use then
      room:useCard(use)
      if player.dead then return end
      if use.damageDealt and use.damageDealt[player.id] then
        room:invalidateSkill(player, self.name, "-turn")
      else
        room:setPlayerMark(player, "@@moyu1-phase", 1)
      end
    end
  end,
}
peiyuanshao:addSkill(moyu)
Fk:loadTranslationTable{
  ["peiyuanshao"] = "裴元绍",
  ["#peiyuanshao"] = "买椟还珠",
  ["designer:peiyuanshao"] = "步穗",
  ["illustrator:peiyuanshao"] = "匠人绘",
  ["moyu"] = "没欲",
  [":moyu"] = "出牌阶段，你可以获得一名此阶段内未选择过的一名其他角色区域里的一张牌，然后该角色可以对你使用一张【杀】（无距离限制），"..
  "若此【杀】：未对你造成过伤害，你于此阶段内下次发动此技能改为获得两张牌；对你造成过伤害，此技能于此回合内无效。",
  ["#moyu-active"] = "发动 没欲，选择1名角色，获得其区域里的%arg张牌",
  ["#moyu-slash"] = "没欲：你可以对 %dest 使用一张【杀】",
  ["@@moyu1-phase"] = "没欲强化",

  ["$moyu1"] = "人之所有，我之所欲。",
  ["$moyu2"] = "胸有欲壑千丈，自当饥不择食。",
  ["~peiyuanshao"] = "好生厉害的白袍小将……",
}

local zhangchu = General(extension, "zhangchu", "qun", 3, 3, General.Female)
local jizhong = fk.CreateActiveSkill{
  name = "jizhong",
  anim_type = "control",
  prompt = "#jizhong-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    target:drawCards(2, self.name)
    if target.dead or player.dead then return end

    --并不清楚卡牌不足三张时能不能选给牌
    if target:getMark("@@xinzhong") > 0 or
    room:askForChoice(target, {"become_xinzhong", "donate3cardsto:" .. player.id}, self.name) ~= "become_xinzhong" then
      local cards = target:getCardIds{Player.Hand, Player.Equip}
      if #cards > 3 then
        cards = room:askForCardsChosen(player, target, 3, 3, "he", self.name)
      end
      if #cards > 0 then
        room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    else
      room:setPlayerMark(target, "@@xinzhong", 1)
    end
  end,
}
local rihui = fk.CreateTriggerSkill{
  name = "rihui",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
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
          return room:askForSkillInvoke(player, self.name, data, "#rihui-use::" .. to.id .. ":" .. data.card.name)
        end
      end
    else
      if to:isAllNude() then return end
      return room:askForSkillInvoke(player, self.name, data, "#rihui-get::" .. to.id)
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
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player.room.alive_players > 1 and
    table.every(player.room:getOtherPlayers(player, false), function (p)
      return p:getMark("@@xinzhong") > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(#room.alive_players - 1, self.name)
    if player:isAlive() then
      player.room:loseHp(player, 1, self.name)
    end
  end,
}
zhangchu:addSkill(jizhong)
zhangchu:addSkill(rihui)
zhangchu:addSkill(guangshi)
Fk:loadTranslationTable{
  ["zhangchu"] = "张楚",
  ["#zhangchu"] = "大贤后裔",
  ["designer:zhangchu"] = "韩旭",
  ["illustrator:zhangchu"] = "黯荧岛工作室",
  ["jizhong"] = "集众",
  [":jizhong"] = "出牌阶段限一次，你可以令一名其他角色摸两张牌，其选择：1.成为“信众”；2.令你获得其三张牌。",
  ["rihui"] = "日慧",
  [":rihui"] = "每回合限一次，当你使用指定唯一其他角色为目标的普通锦囊牌或黑色基本牌后，若其：不是“信众”，所有“信众”均视为对其使用此牌；"..
  "是“信众”，你可以获得其区域内的一张牌。",
  ["guangshi"] = "光噬",
  [":guangshi"] = "锁定技，准备阶段，若所有其他角色均是“信众”，你摸X张牌（X为这些角色数），失去1点体力。",
  ["#jizhong-active"] = "发动 集众，令一名其他角色摸两张牌，然后其选择成为“信众”或被你获取3张卡牌",
  ["@@xinzhong"] = "信众",
  ["become_xinzhong"] = "成为“信众”",
  ["donate3cardsto"] = "%src获得你的3张牌",
  ["#rihui-use"] = "日慧：你可以令所有“信众”视为对 %dest 使用一张【%arg】",
  ["#rihui-get"] = "日慧：你可以获得 %dest 区域内一张牌",

  ["$jizhong1"] = "聚八方之众，昭黄天之明。",
  ["$jizhong2"] = "联苦厄黎庶，传大道太平。",
  ["$rihui1"] = "甲子双至，黄巾再起。",
  ["$rihui2"] = "日中必彗，操刀必割。",
  ["$guangshi1"] = "舍身饲火，光耀人间。",
  ["$guangshi2"] = "愿为奉光之薪柴，照太平于人间。",
  ["~zhangchu"] = "苦难不尽，黄天不死……",
}

local zhangmancheng = General(extension, "ty__zhangmancheng", "qun", 4)
local luecheng = fk.CreateActiveSkill{
  name = "luecheng",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#luecheng",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "@@luecheng-turn", 1)
    local card
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      card = Fk:getCardById(id)
      if card.trueName == "slash" then
        room:setCardMark(card, "@@luecheng-inhand-phase", 1)
      end
    end
  end,
}
local luecheng_targetmod = fk.CreateTargetModSkill{
  name = "#luecheng_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and to:getMark("@@luecheng-turn") ~= 0 and card.trueName == "slash" and card:getMark("@@luecheng-inhand-phase") ~= 0
  end,
}
local luecheng_delay = fk.CreateTriggerSkill{
  name = "#luecheng_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not (player.dead or target.dead) and target.phase == Player.Finish and
    player:getMark("@@luecheng-turn") ~= 0 and not player:isKongcheng()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = player:getCardIds(Player.Hand)
    player:showCards(cards)
    local slashs = table.filter(cards, function (id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    while #slashs > 0 do
    local pat = "slash|.|.|hand|.|.|"..table.concat(slashs, ",")
      local use = room:askForUseCard(player, "slash", pat,
      "#luecheng-slash::" .. target.id, true,
      { exclusive_targets = {target.id}, bypass_distances = true, bypass_times = true })
      if use then
        use.extraUse = true
        room:useCard(use)
      else
        break
      end
      if player.dead or target.dead then break end
      slashs = table.filter(slashs, function (id)
        return table.contains(player:getCardIds(Player.Hand), id) and Fk:getCardById(id).trueName == "slash"
      end)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and data.card:getMark("@@luecheng-inhand-phase") ~= 0 and
    table.find(TargetGroup:getRealTargets(data.tos), function (pid)
      return player.room:getPlayerById(pid):getMark("@@luecheng-turn") > 0
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local zhongji = fk.CreateTriggerSkill{
  name = "zhongji",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getHandcardNum() < player.maxHp and
    not table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).suit == data.card.suit end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    if n > 0 then
      room:askForDiscard(player, n, n, true, self.name, false)
    end
  end,
}
luecheng:addRelatedSkill(luecheng_targetmod)
luecheng:addRelatedSkill(luecheng_delay)
zhangmancheng:addSkill(luecheng)
zhangmancheng:addSkill(zhongji)
Fk:loadTranslationTable{
  ["ty__zhangmancheng"] = "张曼成",
  ["#ty__zhangmancheng"] = "蚁萃宛洛",
  ["designer:ty__zhangmancheng"] = "快雪时晴",
  ["illustrator:ty__zhangmancheng"] = "君桓文化",
  ["luecheng"] = "掠城",
  [":luecheng"] = "出牌阶段限一次，你可以选择一名其他角色，你本回合对其使用当前手牌中的【杀】无次数限制。"..
  "若如此做，回合结束时，该角色展示手牌：若其中有【杀】，其可选择对你依次使用手牌中所有的【杀】。",
  ["zhongji"] = "螽集",
  [":zhongji"] = "当你使用牌时，若你没有该花色的手牌且手牌数小于体力上限，你可将手牌摸至体力上限并弃置X张牌（X为本回合发动此技能的次数）。",

  ["#luecheng"] = "掠城：选择一名其他角色，本回合对其使用当前手牌中的【杀】无次数限制",
  ["@@luecheng-turn"] = "被掠城",
  ["@@luecheng-inhand-phase"] = "掠城",
  ["#luecheng_delay"] = "掠城",
  ["#luecheng-slash"] = "掠城：你可以依次对 %dest 使用手牌中所有【杀】！",

  ["$luecheng1"] = "我等一无所有，普天又有何惧？",
  ["$luecheng2"] = "我视百城为饵，皆可食之果腹。",
  ["$zhongji1"] = "羸汉暴政不息，黄巾永世不绝。",
  ["$zhongji2"] = "宛洛膏如秋实，怎可不生螟虫？",
  ["~ty__zhangmancheng"] = "逡巡不前，坐以待毙……",
}

--异军突起：公孙度 孟优 孟获 公孙修 马腾
local gongsundu = General(extension, "gongsundu", "qun", 4)
local zhenze = fk.CreateTriggerSkill{
  name = "zhenze",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local a = player:getHandcardNum() - player.hp
    local targets = {{},{}}
    for _, p in ipairs(room:getAlivePlayers()) do
      local b = p:getHandcardNum() - p.hp
      if b == a or (a * b) > 0 then
        room:setPlayerMark(p, "@zhenze", "recover")
        table.insert(targets[2], p.id)
      else
        room:setPlayerMark(p, "@zhenze", "loseHp")
        table.insert(targets[1], p.id)
      end
    end
    local all_choices = {"zhenze_lose", "zhenze_recover", "Cancel"}
    local choices = {"zhenze_recover", "Cancel"}
    if #targets[1] > 0 then table.insert(choices, 1, "zhenze_lose") end
    local choice = room:askForChoice(player, choices, self.name, nil, false, all_choices)
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@zhenze", 0)
    end
    if choice ~= "Cancel" then
      self.cost_data = {choice, targets[table.indexOf(all_choices, choice)]}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice, targets = table.unpack(self.cost_data)
    room:doIndicate(player.id, targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        if choice == "zhenze_lose" then
          room:loseHp(p, 1, self.name)
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
local anliao = fk.CreateActiveSkill{
  name = "anliao",
  anim_type = "control",
  card_num = 0,
  times = function(self)
    if Self.phase == Player.Play then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.kingdom == "qun" then
          n = n + 1
        end
      end
      return math.max(0, n - Self:usedSkillTimes(self.name, Player.HistoryPhase))
    end
    return -1
  end,
  target_num = 1,
  prompt = "#anliao-prompt",
  can_use = function(self, player)
    local n = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p.kingdom == "qun" then
        n = n + 1
      end
    end
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < n
  end,
  card_filter = Util.FalseFunc,
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
  ["#gongsundu"] = "雄张海东",
  ["designer:gongsundu"] = "拔都沙皇",
  ["illustrator:gongsundu"] = "匠人绘",
  ["zhenze"] = "震泽",
  [":zhenze"] = "弃牌阶段开始时，你可以选择一项：1.令所有手牌数和体力值的大小关系与你不同的角色失去1点体力；"..
  "2.令所有手牌数和体力值的大小关系与你相同的角色回复1点体力。",
  ["anliao"] = "安辽",
  [":anliao"] = "出牌阶段限X次（X为群势力角色数），你可以重铸一名角色的一张牌。",
  ["#anliao-prompt"] = "安辽：你可以重铸一名角色的一张牌",
  ["zhenze_lose"] = "手牌数和体力值的大小关系与你不同的角色失去1点体力",
  ["zhenze_recover"] = "所有手牌数和体力值的大小关系与你相同的角色回复1点体力",
  ["@zhenze"] = "震泽",

  ["$zhenze1"] = "名震千里，泽被海东。",
  ["$zhenze2"] = "施威除暴，上下咸服。",
  ["$anliao1"] = "地阔天高，大有可为。",
  ["$anliao2"] = "水草丰沛，当展宏图。",
  ["~gongsundu"] = "为何都不愿出仕！",
}

local mengyou = General(extension, "mengyou", "qun", 5)
local manzhi = fk.CreateTriggerSkill{
  name = "manzhi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return end
    local room = player.room
    if player.phase == Player.Finish then
      if player:getMark("@manzhi-turn") == 0 or player.hp ~= tonumber(player:getMark("@manzhi-turn")) then return end
      local record = player:getTableMark("_manzhi-turn")
      if #record >= 2 then return end
      return table.find(room:getOtherPlayers(player), function(p)
        return (not table.contains(record, "manzhi_give") and #p:getCardIds("he") > 1)
        or (not table.contains(record, "manzhi_get") and #p:getCardIds("hej") > 0)
      end)
    elseif player.phase == Player.Start then
      return table.find(room.alive_players, function(p) return not p:isAllNude() and p ~= player end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local _, dat = room:askForUseActiveSkill(player, "manzhi_active", "#manzhi-ask", true, nil, false)
    if dat then
      local choice = dat.interaction
      room:addTableMark(player, "_manzhi-turn", choice)
      self.cost_data = {dat.targets[1], choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local choice = self.cost_data[2]
    if choice == "manzhi_give" then
      local cards = room:askForCard(to, 2, 2, true, self.name, false, nil, "#manzhi-give:" .. player.id)
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, player.id)
      if not to.dead then
        U.askForUseVirtualCard(room, to,  "slash", nil, self.name, nil, false, true, true)
      end
    else
      local card = room:askForCardsChosen(player, to, 1, 2, "hej", self.name)
      room:moveCardTo(card, Player.Hand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      local num = #card
      if player.dead or player:isNude() then return false end
      local give = player:getCardIds{Player.Hand, Player.Equip}
      if #give > num then
        give = room:askForCard(player, num, num, true, self.name, false, nil, "#manzhi-back::" .. to.id .. ":" .. num)
      end
      room:moveCardTo(give, Player.Hand, to, fk.ReasonGive, self.name, nil, false, player.id)
      if not player.dead then player:drawCards(1, self.name) end
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return player == target and target:hasSkill(self) and player.phase == Player.Start -- ...
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@manzhi-turn", tostring(player.hp))
  end,
}
local manzhi_active = fk.CreateActiveSkill{
  name = "manzhi_active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    local all_choices = {"manzhi_give", "manzhi_prey"}
    local choices = table.filter(all_choices, function (str) return not table.contains(Self:getTableMark("_manzhi-turn"), str) end)
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local to = Fk:currentRoom():getPlayerById(to_select)
    if #selected > 0 or  Self.id == to_select then return false end
    if self.interaction.data == "manzhi_give" then
      return #to:getCardIds("he") > 1
    else
      return not to:isAllNude()
    end
  end,
}
Fk:addSkill(manzhi_active)
mengyou:addSkill("manyi")
mengyou:addSkill(manzhi)

Fk:loadTranslationTable{
  ["mengyou"] = "孟优",
  ["#mengyou"] = "蛮杰陷谋",
  ["designer:mengyou"] = "残昼厄夜",
  ["illustrator:mengyou"] = "韩少侠&错落宇宙",
  ["manzhi"] = "蛮智",
  [":manzhi"] = "准备阶段，你可以选择一名其他角色，然后选择一项：1.令其交给你两张牌，然后其视为使用一张无距离限制的【杀】；"..
  "2.获得其区域内的至多两张牌，然后交给其等量牌并摸一张牌。"..
  "结束阶段，若你的体力值与此回合准备阶段开始时相等，你可以执行此回合未选择过的一项。",

  ["manzhi_active"] = "蛮智",
  ["#manzhi-ask"] = "你可对一名其他角色发动“蛮智”",
  ["manzhi_give"] = "令其交给你两张牌，其视为使用【杀】",
  ["manzhi_prey"] = "获得至多两张牌，交给其等量牌并牌",
  ["#manzhi-give"] = "蛮智：请交给%src两张牌",
  ["#manzhi_slash-ask"] = "蛮智：视为使用一张无距离限制的【杀】",
  ["#manzhi-back"] = "蛮智：交给%dest%arg张牌",
  ["@manzhi-turn"] = "蛮智",

  ["$manyi_mengyou1"] = "我辈蛮夷久居荒野，岂为兽虫所伤。",
  ["$manyi_mengyou2"] = "我乃蛮王孟获之弟，谁敢伤我！",
  ["$manzhi1"] = "吾有蛮勇可攻，亦有蛮智可御。",
  ["$manzhi2"] = "远交近攻之法，怎可不为我所用。",
  ["~mengyou"] = "大哥，诸葛亮又打来了。",
}

local menghuo = General(extension, "ty_sp__menghuo", "qun", 4)
--- 执行蛮王的某项
local function doManwang(player, i)
  local room = player.room
  if i == 1 then
    room:handleAddLoseSkills(player, "ty__panqin", nil, true, false)
  elseif i == 2 then
    player:drawCards(1, "ty__manwang")
  elseif i == 3 then
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = "ty__manwang",
      }
    end
  elseif i == 4 then
    player:drawCards(2, "ty__manwang")
    room:handleAddLoseSkills(player, "-ty__panqin", nil, true, false)
  end
end
local manwang = fk.CreateActiveSkill{
  name = "ty__manwang",
  anim_type = "special",
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  prompt = function ()
    return "#ty__manwang-prompt:::"..(#Self:getTableMark("@[:]ty__manwang"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for i = 1, #effect.cards, 1 do
      if i > 4 or i > #player:getTableMark("@[:]ty__manwang") or player.dead then return end
      doManwang(player, i)
    end
  end,
  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@[:]ty__manwang", 0)
  end,
  on_acquire = function (self, player)
    player.room:setPlayerMark(player, "@[:]ty__manwang", {"ty__manwang1", "ty__manwang2", "ty__manwang3", "ty__manwang4"})
  end,
}
local panqin = fk.CreateTriggerSkill{
  name = "ty__panqin",
  anim_type = "offensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and (player.phase == Player.Play or player.phase == Player.Discard) then
      local ids = {}
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile and move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerHand) and
                table.contains(player.room.discard_pile, info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
        return false
      end, Player.HistoryPhase)
      if #ids == 0 then return false end
      local card = Fk:cloneCard("savage_assault")
      card:addSubcards(ids)
      local tos = table.filter(player.room:getOtherPlayers(player), function(p) return not player:isProhibited(p, card) end)
      if not player:prohibitUse(card) and #tos > 0 then
        self.cost_data = {ids, tos}
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards_num = #self.cost_data[1]
    local tos_num = #self.cost_data[2]
    local promot = (#player:getTableMark("@[:]ty__manwang") > 0 and tos_num >= cards_num) and "#ty__panqin_delete-invoke" or "#ty__panqin-invoke"
    if player.room:askForSkillInvoke(player, self.name, nil, promot) then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data[1]
    local tos = self.cost_data[2]
    room:useVirtualCard("savage_assault", cards, player, tos, self.name)
    if #tos >= #cards then
      doManwang(player, #player:getTableMark("@[:]ty__manwang"))
      local mark = player:getTableMark("@[:]ty__manwang")
      if #mark > 0 then
        room:removeTableMark(player, "@[:]ty__manwang", mark[#mark])
        room:changeMaxHp(player, 1)
        if player:isWounded() and not player.dead then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          }
        end
      end
    end
  end,
}
menghuo:addSkill(manwang)
menghuo:addRelatedSkill(panqin)
Fk:loadTranslationTable{
  ["ty_sp__menghuo"] = "孟获",
  ["#ty_sp__menghuo"] = "勒格诗惹",
  ["designer:ty_sp__menghuo"] = "玄蝶既白",
  ["illustrator:ty_sp__menghuo"] = "凡果",

  ["ty__manwang"] = "蛮王",
  [":ty__manwang"] = "出牌阶段，你可以弃置任意张牌依次执行前等量项：1.获得〖叛侵〗；2.摸一张牌；3.回复1点体力；4.摸两张牌并失去〖叛侵〗。",
  ["ty__panqin"] = "叛侵",
  [":ty__panqin"] = "出牌阶段或弃牌阶段结束时，你可以将本阶段你因弃置进入弃牌堆且仍在弃牌堆的牌当【南蛮入侵】使用，然后若此牌目标数不小于"..
  "这些牌的数量，你执行并移除〖蛮王〗的最后一项，然后加1点体力上限并回复1点体力。",
  ["@[:]ty__manwang"] = "蛮王",
  ["ty__manwang1"] = "蛮王1",
  ["ty__manwang2"] = "蛮王2",
  ["ty__manwang3"] = "蛮王3",
  ["ty__manwang4"] = "蛮王4",
  [":ty__manwang1"] = "获得〖叛侵〗",
  [":ty__manwang2"] = "摸一张牌",
  [":ty__manwang3"] = "回复1点体力",
  [":ty__manwang4"] = "摸两张牌并失去〖叛侵〗",
  ["#ty__manwang-prompt"] = "蛮王：弃置任意张牌，依次执行〖蛮王〗的前等量项（剩余 %arg 项）",

  ["#ty__panqin-invoke"] = "叛侵：你可将弃牌堆中你弃置的牌当【南蛮入侵】使用",
  ["#ty__panqin_delete-invoke"] = "叛侵：将弃牌堆中你弃置的牌当【南蛮入侵】使用，然后执行并移除〖蛮王〗的最后一项，加1点体力上限并回复1点体力",
}

local gongsunxiu = General(extension, "gongsunxiu", "qun", 4)
local gangu = fk.CreateTriggerSkill{
  name = "gangu",
  frequency = Skill.Compulsory,
  events = {fk.HpLost},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(3, self.name)
    if not player.dead then
      player.room:loseHp(player, 1, self.name)
    end
  end,
}
local kuizhen = fk.CreateActiveSkill{
  name = "kuizhen",
  anim_type = "offensive",
  prompt = "#kuizhen-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if target.hp >= Self.hp or target:getHandcardNum() >= Self:getHandcardNum() then
        local duel = Fk:cloneCard("duel")
        duel.skillName = self.name
        return target:canUseTo(duel, Self)
      end
    end
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:cloneCard("duel")
    card.skillName = self.name
    local use = {} ---@type CardUseStruct
    use.from = target.id
    use.tos = { {player.id} }
    use.card = card
    use.extraUse = true
    room:useCard(use)
    if target.dead then return end
    if use.damageDealt and use.damageDealt[player.id] then
      if player.dead then return end
      local cards = target:getCardIds(Player.Hand)
      if #cards == 0 then return end
      U.viewCards(player, cards, self.name)
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id, "@@kuizhen-inhand")
    else
      room:loseHp(target, 1, self.name)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and
    data.card.trueName == "slash" and not data.card:isVirtual() and data.card:getMark("@@kuizhen-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local kuizhen_targetmod = fk.CreateTargetModSkill{
  name = "#kuizhen_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and not card:isVirtual() and card:getMark("@@kuizhen-inhand") > 0
  end,
}
kuizhen:addRelatedSkill(kuizhen_targetmod)
gongsunxiu:addSkill(gangu)
gongsunxiu:addSkill(kuizhen)
Fk:loadTranslationTable{
  ["gongsunxiu"] = "公孙修",
  ["#gongsunxiu"] = "寸莛击钟",
  ["illustrator:gongsunxiu"] = "鬼画府",
  ["gangu"] = "干蛊",
  [":gangu"] = "锁定技，每回合限一次，当一名角色失去体力后，你摸三张牌，失去1点体力。",
  ["kuizhen"] = "溃阵",
  [":kuizhen"] = "出牌阶段限一次，你可以选择一名手牌数或体力值不小于你的角色，其视为对你使用【决斗】，若你："..
  "受到过此【决斗】造成的伤害，你观看其所有手牌，获得其中所有的【杀】且你使用以此法获得的【杀】无次数限制；"..
  "未受到过此【决斗】造成的伤害，其失去1点体力。",

  ["#kuizhen-active"] = "发动 溃阵，选择一名角色，令其视为对你使用【决斗】",
  ["@@kuizhen-inhand"] = "溃阵",

  ["$gangu1"] = "承志奉祠，达于行伍之事。",
  ["$gangu2"] = "干父之蛊，全辽裔未竟之业。",
  ["$kuizhen1"] = "今一马当先，效霸王破釜！",
  ["$kuizhen2"] = "自古北马皆傲，视南风为鱼俎。",
  ["~gongsunxiu"] = "大星坠地，父子俱亡……",
}

local ty__mateng = General(extension, "ty__mateng", "qun", 4)
local ty__xiongyi = fk.CreateActiveSkill{
  name = "ty__xiongyi",
  anim_type = "drawcard",
  target_num = 1,
  card_num = 0,
  frequency = Skill.Limited,
  prompt = "#ty__xiongyi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:drawCards(3, self.name)
    if not target.dead then
      target:drawCards(3, self.name)
    end
    if player:isWounded() and not player.dead and player:getMark("ty__xiongyi") == 0 and
      table.every(room:getOtherPlayers(player), function (p)
        return p.hp > player.hp
      end) then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
    end
  end,
}
local ty__xiongyi_trigger = fk.CreateTriggerSkill{
  name = "#ty__xiongyi_trigger",

  refresh_events = {fk.AfterDying},
  can_refresh = function(self, event, target, player, data)
    return target == player and not player.dead and player:usedSkillTimes("ty__xiongyi", Player.HistoryGame) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory("ty__xiongyi", 0, Player.HistoryGame)
    player.room:setPlayerMark(player, "ty__xiongyi", 1)
  end,
}
ty__xiongyi:addRelatedSkill(ty__xiongyi_trigger)
ty__mateng:addSkill("mashu")
ty__mateng:addSkill(ty__xiongyi)
Fk:loadTranslationTable{
  ["ty__mateng"] = "马腾",
  ["#ty__mateng"] = "驰骋西陲",
  ["illustrator:ty__mateng"] = "君桓文化",

  ["ty__xiongyi"] = "雄异",
  [":ty__xiongyi"] = "限定技，出牌阶段，你可以选择一名其他角色，你与其各摸三张牌，然后若你体力值全场唯一最少，你回复1点体力。"..
  "当你进入濒死状态被救回后，若你发动过此技能，此技能视为未发动过并移除回复体力的效果。",
  ["#ty__xiongyi"] = "雄异：选择一名其他角色，与其各摸三张牌！",

  ["$ty__xiongyi1"] = "弟兄们，我们的机会来啦！",
  ["$ty__xiongyi2"] = "此时不战，更待何时！",
  ["~ty__mateng"] = "儿子，为爹报仇啊！",
}


--正音雅乐：蔡文姬 周妃 蔡邕 大乔 小乔
local caiwenji = General(extension, "mu__caiwenji", "qun", 3, 3, General.Female)
local shuangjia = fk.CreateTriggerSkill{
  name = "shuangjia",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@shuangjia-inhand", 1)
    end
    room:setPlayerMark(player, "beifen", cards)
    room:setPlayerMark(player, "@shuangjia", #cards)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return #player:getTableMark("beifen") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("beifen")
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local value = table.contains(mark, id) and 1 or 0
      if card:getMark("@@shuangjia-inhand") ~= value then
        room:setCardMark(card, "@@shuangjia-inhand", value)
      end
    end
  end,

  on_lose = function(self, player)
    local room = player.room
    room:setPlayerMark(player, "beifen", 0)
    room:setPlayerMark(player, "@shuangjia", 0)
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@shuangjia-inhand", 0)
    end
  end,
}
local shuangjia_maxcards = fk.CreateMaxCardsSkill{
  name = "#shuangjia_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@shuangjia-inhand") > 0
  end,
}
local shuangjia_distance = fk.CreateDistanceSkill{
  name = "#shuangjia_distance",
  correct_func = function(self, from, to)
    return math.min(to:getMark("@shuangjia"), 5)
  end,
}
local beifen = fk.CreateTriggerSkill{
  name = "beifen",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local mark = player:getTableMark("beifen")
      if #mark == 0 then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and table.contains(mark, info.cardId) then
              table.insert(cards, info.cardId)
            end
          end
        end
      end
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("beifen")
    for _, id in ipairs(self.cost_data) do
      table.removeOne(mark, id)
    end
    room:setPlayerMark(player, "beifen", #mark > 0 and mark or 0)
    room:setPlayerMark(player, "@shuangjia", #mark)

    local suits = {"heart", "diamond", "spade", "club"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      if card:getMark("@@shuangjia-inhand") > 0 then
        table.removeOne(suits, card:getSuitString())
      end
    end
    if #suits == 0 then return false end
    local patternTable = {}
    for _, suit in ipairs(suits) do
      patternTable[suit] = {}
    end
    for _, id in ipairs(room.draw_pile) do
      local suit = Fk:getCardById(id):getSuitString()
      if table.contains(suits, suit) then
        table.insert(patternTable[suit], id)
      end
    end
    local cards = {}
    for _, suit in ipairs(suits) do
      local ids = patternTable[suit]
      if #ids > 0 then
        table.insert(cards, table.random(ids))
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

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
    player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local beifen_targetmod = fk.CreateTargetModSkill{
  name = "#beifen_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(beifen) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
    player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(beifen) and player:usedSkillTimes("shuangjia", Player.HistoryGame) > 0 and
    player:getHandcardNum() > 2 * player:getMark("@shuangjia")
  end,
}
shuangjia:addRelatedSkill(shuangjia_maxcards)
shuangjia:addRelatedSkill(shuangjia_distance)
beifen:addRelatedSkill(beifen_targetmod)
caiwenji:addSkill(shuangjia)
caiwenji:addSkill(beifen)
Fk:loadTranslationTable{
  ["mu__caiwenji"] = "乐蔡文姬",
  ["#mu__caiwenji"] = "胡笳十八拍",
  ["designer:mu__caiwenji"] = "星移",
  ["illustrator:mu__caiwenji"] = "匠人绘",
  ["shuangjia"] = "霜笳",
  [":shuangjia"] = "锁定技，游戏开始时，你的初始手牌增加“胡笳”标记且不计入手牌上限。你每拥有一张“胡笳”，其他角色计算与你距离+1（最多+5）。",
  ["beifen"] = "悲愤",
  [":beifen"] = "锁定技，当你失去“胡笳”后，你获得与手中“胡笳”花色均不同的牌各一张。你手中“胡笳”少于其他牌时，你使用牌无距离和次数限制。",
  ["@@shuangjia-inhand"] = "胡笳",
  ["@shuangjia"] = "胡笳",

  ["$shuangjia1"] = "塞外青鸟匿，不闻折柳声。",
  ["$shuangjia2"] = "向晚吹霜笳，雪落白发生。",
  ["$beifen1"] = "此心如置冰壶，无物可暖。",
  ["$beifen2"] = "年少爱登楼，欲说语还休。",
  ["~mu__caiwenji"] = "天何薄我，天何薄我……",
}

local zhoufei = General(extension, "mu__zhoufei", "wu", 3, 3, General.Female)
local lingkong = fk.CreateTriggerSkill{
  name = "lingkong",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local handcards = player:getCardIds(Player.Hand)
    if event == fk.GameStart then
      return #handcards > 0
    elseif event == fk.AfterCardsMove then
      local room = player.room
      if room.current == nil or room.current.phase == Player.Draw or player:getMark("lingkongused-turn") > 0 then return false end
      local cards = {}
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if table.contains(handcards, id) then
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
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 1)
      end
    elseif event == fk.AfterCardsMove then
      room:setPlayerMark(player, "lingkongused-turn", 1)
      for _, id in ipairs(self.cost_data) do
        room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 1)
      end
    end
  end,

  on_lose = function(self, player)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@konghou-inhand", 0)
    end
  end,
}
local lingkong_maxcards = fk.CreateMaxCardsSkill{
  name = "#lingkong_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@konghou-inhand") > 0
  end,
}
local xianshu = fk.CreateActiveSkill{
  name = "xianshu",
  card_num = 1,
  target_num = 1,
  prompt = "#xianshu-active",
  anim_type = "drawcard",
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@konghou-inhand") > 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local color = Fk:getCardById(effect.cards[1]).color
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target.id, effect.cards[1], true, fk.ReasonGive, player.id)
    if player.dead or target.dead then return end
    local x = math.abs(player.hp - target.hp)
    if x > 0 then
      room:drawCards(player, math.min(x, 5), self.name)
    end
    if player.dead or target.dead then return end
    if color == Card.Red and target.hp <= player.hp and target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
    if color == Card.Black and target.hp >= player.hp then
      room:loseHp(target, 1, self.name)
    end
  end,
}
lingkong:addRelatedSkill(lingkong_maxcards)
zhoufei:addSkill(lingkong)
zhoufei:addSkill(xianshu)
Fk:loadTranslationTable{
  ["mu__zhoufei"] = "乐周妃",
  ["#mu__zhoufei"] = "芙蓉泣露",
  ["illustrator:mu__zhoufei"] = "匠人绘",
  ["lingkong"] = "灵箜",
  [":lingkong"] = "锁定技，游戏开始时，你的初始手牌增加“箜篌”标记且不计入手牌上限。每回合你于摸牌阶段外首次获得牌后，将这些牌标记为“箜篌”。",
  ["xianshu"] = "贤淑",
  [":xianshu"] = "出牌阶段，你可以将一张“箜篌”牌交给一名其他角色并摸X张牌（X为你与该角色体力值之差且至多为5），"..
  "若此牌为：红色，且该角色体力值不大于你，该角色回复1点体力；黑色，且该角色体力值不小于你，该角色失去1点体力。",

  ["@@konghou-inhand"] = "箜篌",
  ["#xianshu-active"] = "发动 贤淑，选择一张带有“箜篌”标记的牌交给其他角色",

  ["$lingkong1"] = "箜篌奏晚歌，渔樵有归期。",
  ["$lingkong2"] = "吴宫绿荷惊涟漪，飞燕啄新泥。",
  ["$xianshu1"] = "居宠而不骄，秉贤淑于内庭。",
  ["$xianshu2"] = "心怀玲珑意，宜家国于春秋。",
  ["~mu__zhoufei"] = "红颜薄命，望君珍重……",
}

local mu__miheng = General(extension, "mu__miheng", "qun", 3)
local jigu = fk.CreateTriggerSkill{
  name = "jigu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    local handcards = player:getCardIds(Player.Hand)
    if event == fk.GameStart then
      return #handcards > 0
    elseif player == target then
      local record = player:getMark("jiguused_record")
      if record == 0 then
        local players = table.map(player.room.players, Util.IdMapper)
        player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
          table.removeOne(players, e.data[1].id)
          return #players == 0
        end, Player.HistoryGame)
        record = #player.room.players - #players
        if #players == 0 then
          player.room:setPlayerMark(player, "jiguused_record", record)
        end
      end
      if player:getMark("jiguused-round") < record then
        local x = #player:getCardIds(Player.Equip)
        if x == #table.filter(handcards, function (id)
          return Fk:getCardById(id):getMark("@@jigu-inhand") > 0
        end) then
          x = #player:getAvailableEquipSlots() - x
          if x > 0 then
            self.cost_data = x
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@jigu-inhand", 1)
      end
    else
      room:addPlayerMark(player, "jiguused-round")
      player:drawCards(self.cost_data, self.name)
    end
  end,

  on_lose = function(self, player)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@jigu-inhand", 0)
    end
  end,
}
local jigu_maxcards = fk.CreateMaxCardsSkill{
  name = "#jigu_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@jigu-inhand") > 0
  end,
}
local sirui = fk.CreateViewAsSkill{
  name = "sirui",
  prompt = "#sirui-viewas",
  pattern = ".",
  interaction = function()
    local all_names = U.getAllCardNames("bt")
    local names = U.getViewAsCardNames(Self, "sirui", all_names)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    if #selected > 0 or not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    return Fk:translate(card.trueName, "zh_CN"):len() == Fk:translate(Fk:getCardById(to_select).trueName, "zh_CN"):len()
  end,
  view_as = function(self, cards)
    if #cards == 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  enabled_at_response = function(self, player, response)
    return false
  end,
}
local sirui_targetmod = fk.CreateTargetModSkill{
  name = "#sirui_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, sirui.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, sirui.name)
  end,
}
jigu:addRelatedSkill(jigu_maxcards)
sirui:addRelatedSkill(sirui_targetmod)
mu__miheng:addSkill(jigu)
mu__miheng:addSkill(sirui)
Fk:loadTranslationTable{
  ["mu__miheng"] = "乐祢衡",
  ["#mu__miheng"] = "鹗立鸷群",
  --["designer:mu__miheng"] = "",
  ["illustrator:mu__miheng"] = "君桓文化",
  ["cv:mu__miheng"] = "虞晓旭",

  ["jigu"] = "激鼓",
  [":jigu"] = "锁定技，游戏开始时，你的初始手牌增加“激鼓”标记且不计入手牌上限。当你造成或受到伤害后，"..
  "若你于此轮内发动过此技能的次数小于本局游戏已进入回合的角色数，且你装备区里的牌数等于你手牌区里的“激鼓”牌数，你摸X张牌（X为你空置的装备栏数）。",
  ["sirui"] = "思锐",
  [":sirui"] = "出牌阶段限一次，你可以将一张牌当牌名字数相等的基本牌或普通锦囊牌使用（无距离和次数限制）。",

  ["@@jigu-inhand"] = "激鼓",
  ["#sirui-viewas"] = "发动 思锐，将一张牌转化为牌名字数相等的牌使用（无距离和次数限制）",

  ["$jigu1"] = "我接着奏乐，诸公接着舞！",
  ["$jigu2"] = "这不是鼓，而是曹公的脸面。",
  ["$sirui1"] = "暑气可借酒气消，此间艳阳最佐酒！",
  ["$sirui2"] = "诸君饮泥而醉，举世唯我独醒！",
  ["~mu__miheng"] = "映日荷花今尤在，不见当年采荷人……",
}

local daqiao = General(extension, "mu__daqiao", "wu", 3, 3, General.Female)
local qiqin = fk.CreateTriggerSkill{
  name = "qiqin",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self) and not player:isKongcheng()
    elseif player:hasSkill(self) and target == player and player.phase == Player.Start then
      local get = table.filter(player.room.discard_pile, function(id)
        return Fk:getCardById(id):getMark("qiqin") > 0
      end)
      if #get > 0 then
        self.cost_data = get
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local cards = player:getCardIds(Player.Hand)
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@qiqin-inhand", 1)
        room:setCardMark(Fk:getCardById(id), "qiqin", 1)
      end
    else
      room:moveCardTo(self.cost_data, Player.Hand, player, fk.ReasonJustMove, self.name, "", false, player.id)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local value = (card:getMark("qiqin") > 0 and player:hasSkill(self, true)) and 1 or 0
      if card:getMark("@@qiqin-inhand") ~= value then
        room:setCardMark(card, "@@qiqin-inhand", value)
      end
    end
  end,

  on_lose = function(self, player)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@qiqin-inhand", 0)
    end
  end,
}
local qiqin_maxcards = fk.CreateMaxCardsSkill{
  name = "#qiqin_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill(qiqin) and card:getMark("qiqin") > 0
  end,
}
Fk:addQmlMark{
  name = "zixi",
  how_to_show = function(name, value, p)
    if type(value) ~= "table" then return " " end
    return table.concat(table.map(value, function(zixi_pair)
      return Fk:translate(zixi_pair[2] .. "_short")
    end), " ")
  end,
  qml_path = "packages/tenyear/qml/ZixiBox"
}
local zixi_active = fk.CreateActiveSkill{
  name = "zixi_active",
  card_num = 1,
  target_num = 1,
  interaction = function()
    return UI.ComboBox {choices = {"indulgence", "supply_shortage", "lightning"}}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("qiqin") > 0
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected_cards == 0 or #selected > 0 then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    return not (table.contains(to.sealedSlots, Player.JudgeSlot) or to:hasDelayedTrick(self.interaction.data))
  end,
}
Fk:addSkill(zixi_active)
local zixi = fk.CreateTriggerSkill{
  name = "zixi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self) then return false end
    if event == fk.TargetSpecified then
      if (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not table.contains(data.card.skillNames, self.name) then
        local to = player.room:getPlayerById(data.to)
        local x = #to:getCardIds(Player.Judge)
        if x > 0 and x < 4 and U.isOnlyTarget(to, data, event) then
          return true
        end
      end
    else
      return player.phase == Player.Play and not player:isNude()
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      local x = #to:getCardIds(Player.Judge)
      if room:askForSkillInvoke(player, self.name, nil,
      "#zixi-invoke" .. tostring(x) .. "::" .. data.to .. ":" .. data.card:toLogString()) then
        room:doIndicate(player.id, {data.to})
        return true
      end
    else
      local _, dat = room:askForUseActiveSkill(player, "zixi_active", "#zixi-cost", true)
      if dat then
        self.cost_data = dat
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      local x = #to:getCardIds(Player.Judge)
      if x == 1 then
        data.extra_data = data.extra_data or {}
        data.extra_data.zixi = {
          from = player.id,
          to = data.to,
          subTargets = data.subTargets
        }
      elseif x == 2 then
        room:drawCards(player, 2, self.name)
      elseif x == 3 then
        to:throwAllCards("j")
        if not to.dead then
          room:damage{
            from = player,
            to = to,
            damage = 3,
            skillName = self.name,
          }
        end
      end
    else
      local dat = table.simpleClone(self.cost_data)
      local to = room:getPlayerById(dat.targets[1])
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcard(dat.cards[1])
      card.skillName = self.name
      to:addVirtualEquip(card)
      room:moveCardTo(card, Player.Judge, to, fk.ReasonJustMove, self.name)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, id in ipairs(player:getCardIds(Player.Judge)) do
      local zixi_card = player:getVirualEquip(id)
      if zixi_card and table.contains(zixi_card.skillNames, "zixi") then
        table.insert(mark, {id, zixi_card.trueName})
      end
    end
    local old_mark = player:getMark("@[zixi]")
    if #mark == 0 then
      if old_mark ~= 0 then
        room:setPlayerMark(player, "@[zixi]", 0)
      end
      return false
    end
    if type(old_mark) ~= "table" or #mark ~= #old_mark then
      room:setPlayerMark(player, "@[zixi]", mark)
    end
  end,
}
local zixi_delay = fk.CreateTriggerSkill{
  name = "#zixi_delay",
  mute = true,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.zixi and not player.dead then
      local use = table.simpleClone(data.extra_data.zixi)
      if use.from == player.id then
        local card = Fk:cloneCard(data.card.name)
        card.skillName = zixi.name
        if player:prohibitUse(card) then return false end
        use.card = card
        local room = player.room
        local to = room:getPlayerById(use.to)
        if not to.dead and U.canTransferTarget(to, use, false) then
          local tos = {use.to}
          if use.subTargets then
            table.insertTable(tos, use.subTargets)
          end
          self.cost_data = {
            from = player.id,
            tos = table.map(tos, function(pid) return { pid } end),
            card = card,
            extraUse = true
          }
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:useCard(table.simpleClone(self.cost_data))
  end,
}
local zixi_special_rule = fk.CreateTriggerSkill{
  name = "#zixi_special_rule",
  events = {fk.EventPhaseStart},
  mute = true,
  priority = 0, -- game rule
  can_trigger = function(self, event, target, player, data)
    return player.phase == Player.Judge
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Judge)
    for i = #cards, 1, -1 do
      if table.contains(player:getCardIds(Player.Judge), cards[i]) then
        local zixi_card = player:getVirualEquip(cards[i])
        if zixi_card == nil or not table.contains(zixi_card.skillNames, "zixi") then
          local card
          card = player:removeVirtualEquip(cards[i])
          if not card then
            card = Fk:getCardById(cards[i])
          end

          room:moveCardTo(card, Card.Processing, nil, fk.ReasonPut, "game_rule")

          ---@type CardEffectEvent
          local effect_data = {
            card = card,
            to = player.id,
            tos = { {player.id} },
          }
          room:doCardEffect(effect_data)
          if effect_data.isCancellOut and card.skill then
            card.skill:onNullified(room, effect_data)
          end
        end
      end
    end
    return true
  end,
}

qiqin:addRelatedSkill(qiqin_maxcards)
zixi:addRelatedSkill(zixi_delay)
zixi:addRelatedSkill(zixi_special_rule)
daqiao:addSkill(qiqin)
daqiao:addSkill(zixi)

Fk:loadTranslationTable{
  ["mu__daqiao"] = "乐大乔",
  ["#mu__daqiao"] = "玉桐姊韵",
  ["designer:mu__daqiao"] = "星移",

  ["qiqin"] = "绮琴",
  [":qiqin"] = "锁定技，游戏开始时，你的初始手牌增加“琴”标记且不计入手牌上限。准备阶段，你获得弃牌堆中所有“琴”牌。",
  ["zixi"] = "姊希",
  [":zixi"] = "出牌阶段开始时和结束时，你可以将一张“琴”放置在一名角色的判定区"..
  "（牌名当做【兵粮寸断】、【乐不思蜀】或【闪电】使用，且判定阶段不执行效果）。"..
  "你使用基本牌或普通锦囊牌指定唯一目标后，可根据其判定区里的牌数执行："..
  "1张：此牌结算后，你视为对其使用一张牌名相同的牌；2张：你摸2张牌；3张：弃置其判定区里的所有牌，对其造成3点伤害。",
  ["@@qiqin-inhand"] = "琴",
  ["#zixi-cost"] = "是否发动 姊希，将一张“琴”放置在一名角色的判定区",
  ["zixi_active"] = "姊希",
  ["#zixi_delay"] = "姊希",
  ["#zixi_special_rule"] = "姊希",
  ["#zixi-invoke1"] = "是否发动 姊希，令%arg对%dest额外结算一次",
  ["#zixi-invoke2"] = "是否发动 姊希，摸两张牌",
  ["#zixi-invoke3"] = "是否发动 姊希，令%dest弃置判定区所有牌并受到3点伤害",

  ["@[zixi]"] = "姊希",
  ["indulgence_short"] = "乐",
  ["supply_shortage_short"] = "兵",
  ["lightning_short"] = "电",

  ["$qiqin_mu__daqiao1"] = "山月栖瑶琴，一曲渔歌和晚音。",
  ["$qiqin_mu__daqiao2"] = "指尖有琴音，何不于君指上听？",
  ["$zixi1"] = "日暮飞伯劳，倦梳头，坐看鸥鹭争舟。",
  ["$zixi2"] = "姊折翠柳寄江北，念君心悠悠。",
  ["~mu__daqiao"] = "曲终人散，再会奈何桥畔……",
}

local xiaoqiao = General(extension, "mu__xiaoqiao", "wu", 3, 3, General.Female)
local weiwan = fk.CreateActiveSkill{
  name = "weiwan",
  anim_type = "offensive",
  prompt = "#weiwan-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function (self, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return not Self:prohibitDiscard(card) and card:getMark("qiqin") > 0
  end,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local qin_suit = Fk:getCardById(effect.cards[1]).suit
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead or to.dead then return end
    local cardsMap = {}
    for _, id in ipairs(to:getCardIds("hej")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit and suit ~= qin_suit then
        cardsMap[suit] = cardsMap[suit] or {}
        table.insert(cardsMap[suit], id)
      end
    end
    local get = {}
    for _, value in pairs(cardsMap) do
      table.insert(get, table.random(value))
    end
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      if to.dead then return end
      if #get == 1 then
        room:loseHp(to, 1, self.name)
      elseif #get == 2 then
        room:addTableMark(player, "weiwan_targetmod-turn", to.id)
      elseif #get == 3 then
        room:addTableMark(player, "weiwan_prohibit-turn", to.id)
      end
    end
  end,
}
local weiwan_refresh = fk.CreateTriggerSkill{
  name = "#weiwan_refresh",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player == target then
      local mark = player:getTableMark("weiwan_targetmod-turn")
      return #mark > 0 and table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return table.contains(mark, pid)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local weiwan_targetmod = fk.CreateTargetModSkill{
  name = "#weiwan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("weiwan_targetmod-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("weiwan_targetmod-turn"), to.id)
  end,
}
local weiwan_prohibit = fk.CreateProhibitSkill{
  name = "#weiwan_prohibit",
  is_prohibited = function(self, player, to, card)
    return table.contains(player:getTableMark("weiwan_prohibit-turn"), to.id)
  end,
}
weiwan:addRelatedSkill(weiwan_refresh)
weiwan:addRelatedSkill(weiwan_targetmod)
weiwan:addRelatedSkill(weiwan_prohibit)
xiaoqiao:addSkill("qiqin")
xiaoqiao:addSkill(weiwan)
Fk:loadTranslationTable{
  ["mu__xiaoqiao"] = "乐小乔",
  ["#mu__xiaoqiao"] = "绿绮嫒媛",
  ["designer:mu__xiaoqiao"] = "星移",

  ["weiwan"] = "媦婉",
  [":weiwan"] = "出牌阶段限一次，你可以弃置一张“琴”并选择一名其他角色，随机获得其区域内与此“琴”不同花色的牌各一张。"..
  "若你获得的牌数为：1，其失去1点体力；2，你本回合对其使用牌无距离与次数限制；3，你本回合不能对其使用牌。",
  ["#weiwan-active"] = "发动 媦婉，选择一张“琴”弃置并选择一名其他角色",

  ["$qiqin_mu__xiaoqiao1"] = "渔歌唱晚落山月，素琴薄暮声。",
  ["$qiqin_mu__xiaoqiao2"] = "指上琴音浅，欲听还需抚瑶琴。",
  ["$weiwan1"] = "繁花初成，所幸未晚于桑榆。",
  ["$weiwan2"] = "群胥泛舟，共载佳期若瑶梦。",
  ["~mu__xiaoqiao"] = "独寄人间白首，曲误周郎难顾……",
}

local zoushi = General(extension, "mu__zoushi", "qun", 3, 3, General.Female)
local yunzheng = fk.CreateTriggerSkill{
  name = "yunzheng",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    local card
    for _, id in ipairs(cards) do
      card = Fk:getCardById(id)
      room:setCardMark(card, "@@yunzheng-inhand", 1)
      room:setCardMark(card, "yunzheng", 1)
    end
    room:setPlayerMark(player, "@yunzheng", #cards)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
      if move.to == player.id and move.toArea == Player.Hand and #move.moveInfo > 0 then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local card
    local x = #table.filter(player:getCardIds(Player.Hand), function (id)
      card = Fk:getCardById(id)
      if card:getMark("yunzheng") > 0 then
        if card:getMark("@@yunzheng-inhand") == 0 then
          room:setCardMark(card, "@@yunzheng-inhand", 1)
        end
        return true
      end
    end)
    if player:getMark("@yunzheng") ~= x then
      room:setPlayerMark(player, "@yunzheng", x)
    end
  end,

  on_lose = function(self, player)
    local room = player.room
    if table.every(room.alive_players, function (p)
      return not p:hasSkill(self, true)
    end) then
      for _, p in ipairs(room.alive_players) do
        for _, id in ipairs(p:getCardIds(Player.Hand)) do
          room:setCardMark(Fk:getCardById(id), "@@yunzheng-inhand", 0)
        end
        room:setPlayerMark(p, "@yunzheng", 0)
      end
    end
  end,
}
local yunzheng_maxcards = fk.CreateMaxCardsSkill{
  name = "#yunzheng_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill(yunzheng) and card:getMark("yunzheng") > 0
  end,
}
local yunzheng_invalidity = fk.CreateInvaliditySkill {
  name = "#yunzheng_invalidity",
  invalidity_func = function(self, from, skill)
    if from:getMark("@yunzheng") > 0 and table.contains(from.player_skills, skill)
    and skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Wake and skill:isPlayerSkill(from) then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= from and p:hasSkill(yunzheng)
      end)
    end
  end,
}
local huoxin = fk.CreateTriggerSkill{
  name = "mu__huoxin",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.type ~= Card.TypeEquip and
    table.find(player.room.alive_players, function (p)
      return p ~= player and not p:isKongcheng()
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p ~= player and not p:isKongcheng()
    end), Util.IdMapper), 1, 1, "#mu__huoxin-choose", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    local id = room:askForCardChosen(player, to, "h", self.name)
    to:showCards({id})
    local card = Fk:getCardById(id)
    local toObtain = true
    if card:getMark("yunzheng") == 0 then
      toObtain = false
      room:setCardMark(card, "yunzheng", 1)
      room:setCardMark(card, "@@yunzheng-inhand", 1)
      room:addPlayerMark(to, "@yunzheng")
    end
    if (toObtain or (card.suit == data.card.suit and card.suit ~= Card.NoSuit)) and
    room:askForSkillInvoke(player, self.name, nil, "#yunzheng-prey::" .. to.id .. ":" .. card:toLogString()) then
      room:obtainCard(player, id, true, fk.ReasonPrey, player.id, self.name)
    end
  end,
}
yunzheng:addRelatedSkill(yunzheng_maxcards)
yunzheng:addRelatedSkill(yunzheng_invalidity)
zoushi:addSkill(yunzheng)
zoushi:addSkill(huoxin)
Fk:loadTranslationTable{
  ["mu__zoushi"] = "乐邹氏",
  ["#mu__zoushi"] = "淯水吟",
  --["designer:mu__zoushi"] = "",
  ["illustrator:mu__zoushi"] = "黯荧岛",

  ["yunzheng"] = "韵筝",
  [":yunzheng"] = "锁定技，游戏开始时，你的初始手牌增加“筝”标记且不计入手牌上限。手牌区里有“筝”的其他角色的不带“锁定技”标签的技能无效。",
  ["mu__huoxin"] = "惑心",
  [":mu__huoxin"] = "当你使用不为装备牌的牌时，你可以展示一名其他角色的一张手牌并标记为“筝”，"..
  "若此牌与你使用的牌花色相同或已被标记，你可以获得之。",

  ["@yunzheng"] = "筝",
  ["@@yunzheng-inhand"] = "筝",
  ["#mu__huoxin-choose"] = "是否发动 惑心，选择一名其他角色，展示其一张手牌标记为“筝”",
  ["#yunzheng-prey"] = "惑心：是否获得%dest展示的%arg",

  ["$yunzheng1"] = "佳人弄青丝，柔荑奏鸣筝。",
  ["$yunzheng2"] = "玉柱冷寒雪，清商怨羽声。",
  ["$mu__huoxin1"] = "闻君精通音律，与我合奏一曲如何？",
  ["$mu__huoxin2"] = "知君有心意，此筝寄我情。",
  ["~mu__zoushi"] = "雁归衡阳，良人当还……",
}

local diaochan = General(extension, "mu__diaochan", "qun", 3, 3, General.Female)
local tanban = fk.CreateTriggerSkill{
  name = "tanban",
  anim_type = "special",
  events = {fk.GameStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:isKongcheng() then return false end
    if event == fk.GameStart then
      return true
    else
      return target == player and player.phase == Player.Draw
    end
  end,
  on_cost = function(self, event, target, player, data)
    return event == fk.GameStart or player.room:askForSkillInvoke(player, self.name, nil, "#tanban-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local cards = player:getCardIds(Player.Hand)
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@tanban-inhand", 1)
      end
    else
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        room:setCardMark(Fk:getCardById(id), "@@tanban-inhand", Fk:getCardById(id):getMark("@@tanban-inhand") > 0 and 0 or 1)
      end
    end
  end,

  on_lose = function(self, player)
    local room = player.room
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      room:setCardMark(Fk:getCardById(id), "@@tanban-inhand", 0)
    end
  end,
}
local tanban_maxcards = fk.CreateMaxCardsSkill{
  name = "#tanban_maxcards",
  exclude_from = function(self, player, card)
    return player:hasSkill(tanban) and card:getMark("@@tanban-inhand") > 0
  end,
}
tanban:addRelatedSkill(tanban_maxcards)
diaochan:addSkill(tanban)

local diou = fk.CreateTriggerSkill{
  name = "diou",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player:isKongcheng() and
    (data.extra_data or {}).usingTanban
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local ids, record = {}, player:getTableMark("diou-turn")
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      if Fk:getCardById(id):getMark("@@tanban-inhand") == 0 then
        table.insert(ids, id)
        if table.contains(record, id) then
          room:setCardMark(Fk:getCardById(id), "@@diou_showed", 1)
        end
      end
    end
    local cards = room:askForCard(player, 1, 1, false, self.name, true, tostring(Exppattern{ id = ids }), "#diou-card")
    if #cards > 0 then
      self.cost_data = {cards = cards}
    end
    for _, id in ipairs(ids) do
      if Fk:getCardById(id):getMark("@@diou_showed") ~= 0 then
        room:setCardMark(Fk:getCardById(id), "@@diou_showed", 0)
      end
    end
    return #cards > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local chosen = self.cost_data.cards[1]
    local draw = not table.contains(player:getTableMark("diou-turn"), chosen)
    if draw then
      room:addTableMark(player, "diou-turn", chosen)
    else
      draw = Fk:getCardById(chosen).trueName == data.card.trueName
    end
    player:showCards({chosen})
    local card = Fk:getCardById(chosen)
    if card.type == Card.TypeBasic or card:isCommonTrick() then
      U.askForUseVirtualCard(room, player, card.name, nil, self.name, nil, false, true, false, true)
    end
    if draw and not player.dead then
      player:drawCards(2, self.name)
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card:getMark("@@tanban-inhand") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.usingTanban = true
  end,
}
diaochan:addSkill(diou)

Fk:loadTranslationTable{
  ["mu__diaochan"] = "乐貂蝉",
  ["#mu__diaochan"] = "檀声向晚",
  --["designer:mu__diaochan"] = "",
  ["illustrator:mu__diaochan"] = "鬼画府",

  ["tanban"] = "檀板",
  [":tanban"] = "游戏开始时，你的初始手牌增加“檀板”标记且不计入手牌上限。"..
  "摸牌阶段结束时，你可以交换手牌区里的“檀板”牌和非“檀板”牌的标记。",
  ["diou"] = "低讴",
  [":diou"] = "当你使用“檀板”牌结算结束后，你可以展示一张不为“檀板”牌的手牌，"..
  "若展示了基本牌或普通锦囊牌，你视为使用展示牌。若为你本回合第一次展示此牌或与使用的“檀板”牌牌名相同，你摸两张牌。",
  ["#diou-card"] = "低讴：你可以展示一张非“檀板”牌，视为使用之。初次展示此牌则摸两张牌",
  ["@@tanban-inhand"] = "檀板",
  ["#tanban-invoke"] = "檀板：你可以改变手牌区里所有“檀板”牌和非“檀板”牌的标记状态",
  ["@@diou_showed"] = "已展示",

  ["$tanban1"] = "将军，妾身奏得如何？",
  ["$tanban2"] = "将军还想再听一曲？",
  ["$diou1"] = "一日不见兮，思之如狂。",
  ["$diou2"] = "有一美人兮，见之不忘。",
  ["~mu__diaochan"] = "红颜薄命，一曲离歌终……",
}

local zhouyu = General(extension, "mu__zhouyu", "wu", 3)
local guyinz = fk.CreateTriggerSkill{
  name = "guyinz",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard) then
          for _, info in ipairs(move.moveInfo) do
            if info.extra_data and info.extra_data.guyinz and info.extra_data.guyinz ~= player.id then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function (self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard) then
        for _, info in ipairs(move.moveInfo) do
          if info.extra_data and info.extra_data.guyinz and info.extra_data.guyinz ~= player.id then
            n = n + 1
          end
        end
      end
    end
    for _ = 1, n, 1 do
      if not player:hasSkill(self) then return end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.DrawInitialCards, fk.AfterDrawInitialCards, fk.AfterCardsMove},
  can_refresh = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DrawInitialCards then
        return true
      elseif event == fk.AfterDrawInitialCards then
        return target ~= player and not target:isKongcheng()
      end
    end
    if event == fk.AfterCardsMove and player.seat == 1 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          return true
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    if event == fk.DrawInitialCards then
      if target == player then
        data.num = 0
      else
        data.num = data.num + 1
      end
    elseif event == fk.AfterDrawInitialCards then
      local room = player.room
      for _, id in ipairs(target:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@guyinz", target.id)
      end
    elseif event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("@@guyinz") ~= 0 then
              if move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonDiscard then
                info.extra_data = info.extra_data or {}
                info.extra_data.guyinz = Fk:getCardById(info.cardId):getMark("@@guyinz")
              end
              player.room:setCardMark(Fk:getCardById(info.cardId), "@@guyinz", 0)
            end
          end
        end
      end
    end
  end,
}
local pinglu = fk.CreateActiveSkill{
  name = "pinglu",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#pinglu",
  can_use = function(self, player)
    return not table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@pinglu-inhand-phase") > 0
    end) and
    table.find(Fk:currentRoom().alive_players, function (p)
      return player:inMyAttackRange(p) and not p:isKongcheng()
    end)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      if player:inMyAttackRange(p) and not p.dead and not p:isKongcheng() then
        room:moveCardTo(table.random(p:getCardIds("h")), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id,
          "@@pinglu-inhand-phase")
      end
    end
  end,
}
zhouyu:addSkill(guyinz)
zhouyu:addSkill(pinglu)
Fk:loadTranslationTable{
  ["mu__zhouyu"] = "乐周瑜",
  ["#mu__zhouyu"] = "顾曲周郎",
  ["illustrator:mu__zhouyu"] = "觉觉",

  ["guyinz"] = "顾音",
  [":guyinz"] = "锁定技，你没有初始手牌，其他角色的初始手牌+1。其他角色的初始手牌被使用或弃置进入弃牌堆后，你摸一张牌。",
  ["pinglu"] = "平虏",
  [":pinglu"] = "出牌阶段，你可以获得攻击范围内每名其他角色各一张随机手牌。你此阶段不能再发动该技能直到这些牌离开你的手牌。",
  ["@@guyinz"] = "顾音",
  ["#pinglu"] = "平虏：获得攻击范围内每名角色各一张随机手牌",
  ["@@pinglu-inhand-phase"] = "平虏",

  ["$guyinz1"] = "曲有误，不可不顾。",
  ["$guyinz2"] = "兀音曳绕梁，愿君去芜存菁。",
  ["$pinglu1"] = "惊涛卷千雪，如林敌舰今何存？",
  ["$pinglu2"] = "羽扇摧樯橹，纶巾曳风流。",
  ["~mu__zhouyu"] = "高山难觅流水意，曲终人散皆难违。",
}

return extension
