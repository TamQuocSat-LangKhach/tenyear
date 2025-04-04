local extension = Package("tenyear_sp2")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp2"] = "十周年-限定专属2",
}

--豆蔻梢头：花鬘 辛宪英 薛灵芸 芮姬 段巧笑 田尚衣 柏灵筠 马伶俐 莫琼树
local huaman = General(extension, "ty__huaman", "shu", 3, 3, General.Female)
local manyi = fk.CreateTriggerSkill{
  name = "manyi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "savage_assault" and player.id == data.to
  end,
  on_use = Util.TrueFunc,
}
local mansi = fk.CreateViewAsSkill{
  name = "mansi",
  anim_type = "offensive",
  prompt = "#mansi",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("savage_assault")
    card:addSubcards(Self:getCardIds(Player.Hand))
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local mansi_trigger = fk.CreateTriggerSkill{
  name = "#mansi_trigger",
  events = {fk.Damaged},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(mansi) and data.card and data.card.trueName == "savage_assault"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("mansi")
    room:notifySkillInvoked(player, "mansi", "drawcard")
    player:drawCards(1, "mansi")
    room:addPlayerMark(player, "@mansi", 1)
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == mansi and player:getMark("@mansi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@mansi", 0)
  end,
}
local souying = fk.CreateTriggerSkill{
  name = "souying",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
    (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #AimGroup:getAllTargets(data.tos) == 1 then
      local room = player.room
      local events = {}
      if target == player then
        if data.to == player.id or room:getCardArea(data.card) ~= Card.Processing then return false end
        events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == player.id and table.contains(TargetGroup:getRealTargets(use.tos), data.to)
        end, Player.HistoryTurn)
      else
        if AimGroup:getAllTargets(data.tos)[1] ~= player.id then return false end
        events = room.logic:getEventsOfScope(GameEvent.UseCard, 2, function(e)
          local use = e.data[1]
          return use.from == target.id and table.contains(TargetGroup:getRealTargets(use.tos), player.id)
        end, Player.HistoryTurn)
      end
      return #events > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if target == player then
      prompt = "#souying1-invoke:::"..data.card:toLogString()
    else
      prompt = "#souying2-invoke:::"..data.card:toLogString()
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", prompt, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    player:broadcastSkillInvoke(self.name)
    if target == player then
      room:notifySkillInvoked(player, self.name, "drawcard")
      if not player.dead and room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player, data.card, true, fk.ReasonJustMove)
      end
    else
      room:notifySkillInvoked(player, self.name, "defensive")
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
}
local zhanyuan = fk.CreateTriggerSkill{
  name = "zhanyuan",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@mansi") > 6
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p:isMale() and not p:hasSkill("xili", true) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhanyuan-choose", self.name, true)
    if #to > 0 then
      room:handleAddLoseSkills(player, "xili|-mansi", nil, true, false)
      room:handleAddLoseSkills(room:getPlayerById(to[1]), "xili", nil, true, false)
    end
  end,
}
local xili = fk.CreateTriggerSkill{
  name = "xili",
  anim_type = "support",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.from and target ~= player and
      target:hasSkill(self, true, true) and target.phase ~= Player.NotActive and
      not data.to:hasSkill(self, true) and not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#xili-invoke:"..data.from.id..":"..data.to.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    data.damage = data.damage + 1
    if not player.dead then
      player:drawCards(2, self.name)
    end
    if not target.dead then
      target:drawCards(2, self.name)
    end
  end,
}
mansi:addRelatedSkill(mansi_trigger)
huaman:addSkill(manyi)
huaman:addSkill(mansi)
huaman:addSkill(souying)
huaman:addSkill(zhanyuan)
huaman:addRelatedSkill(xili)
Fk:loadTranslationTable{
  ["ty__huaman"] = "花鬘",
  ["#ty__huaman"] = "芳踪载馨",
  ["designer:ty__huaman"] = "梦魇狂朝",
  ["illustrator:ty__huaman"] = "木美人",
  ["manyi"] = "蛮裔",
  [":manyi"] = "锁定技，【南蛮入侵】对你无效。",
  ["mansi"] = "蛮嗣",
  [":mansi"] = "出牌阶段限一次，你可以将所有手牌当【南蛮入侵】使用；当一名角色受到【南蛮入侵】的伤害后，你摸一张牌。",
  ["souying"] = "薮影",
  [":souying"] = "每回合限一次，当你使用基本牌或普通锦囊牌指定其他角色为唯一目标后，若此牌不是本回合你对其使用的第一张牌，你可以弃置一张牌获得之；"..
  "当其他角色使用基本牌或普通锦囊牌指定你为唯一目标后，若此牌不是本回合其对你使用的第一张牌，你可以弃置一张牌令此牌对你无效。",
  ["zhanyuan"] = "战缘",
  [":zhanyuan"] = "觉醒技，准备阶段，若你发动〖蛮嗣〗获得不少于七张牌，你加1点体力上限并回复1点体力。然后你可以选择一名男性角色，"..
  "你与其获得技能〖系力〗，你失去技能〖蛮嗣〗。",
  ["xili"] = "系力",
  [":xili"] = "每回合限一次，其他拥有〖系力〗的角色于其回合内对没有〖系力〗的角色造成伤害时，你可以弃置一张牌令此伤害+1，然后你与其各摸两张牌。",
  ["#mansi"] = "蛮嗣：你可以将所有手牌当【南蛮入侵】使用",
  ["@mansi"] = "蛮嗣",
  ["#souying1-invoke"] = "薮影：你可以弃置一张牌，获得此%arg",
  ["#souying2-invoke"] = "薮影：你可以弃置一张牌，令此%arg对你无效",
  ["#zhanyuan-choose"] = "战缘：你可以与一名男性角色获得技能〖系力〗",
  ["#xili-invoke"] = "系力：你可以弃置一张牌，令 %src 对 %dest 造成的伤害+1，你与 %src 各摸两张牌",

  ["$manyi1"] = "南蛮女子，该当英勇善战！",
  ["$manyi2"] = "蛮族的力量，你可不要小瞧！",
  ["$mansi1"] = "承父母庇护，得此福气。",
  ["$mansi2"] = "多谢父母怜爱。",
  ["$souying1"] = "幽薮影单，只身勇斗！",
  ["$souying2"] = "真薮影移，险战不惧！",
  ["$zhanyuan1"] = "战中结缘，虽苦亦甜。",
  ["$zhanyuan2"] = "势不同，情相随。",
  ["$xili1"] = "系力而为，助君得胜。",
  ["$xili2"] = "有我在，将军此战必能一举拿下！",
  ["~ty__huaman"] = "南蛮之地的花，还在开吗……",
}

local xinxianying = General(extension, "ty__xinxianying", "wei", 3, 3, General.Female)
local ty__zhongjian = fk.CreateActiveSkill{
  name = "ty__zhongjian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  no_indicate = true,
  interaction = function(self)
    return UI.ComboBox { choices = {"ty__zhongjian_draw","ty__zhongjian_discard"} }
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark("ty__zhongjian_target-turn") == 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < (1 + player:getMark("ty__caishi_twice-turn"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(to, "ty__zhongjian_target-turn", 1)
    local choice = self.interaction.data
    room:addTableMark(to, choice, player.id)
  end,
}
local ty__zhongjian_trigger = fk.CreateTriggerSkill{
  name = "#ty__zhongjian_trigger",
  mute = true,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    if event == fk.Damage then
      return target and not target.dead and #target:getTableMark("ty__zhongjian_discard") > 0
    else
      return not target.dead and #target:getTableMark("ty__zhongjian_draw") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event == fk.Damage and "ty__zhongjian_discard" or "ty__zhongjian_draw"
    local mark = player:getTableMark(choice)
    room:setPlayerMark(player, choice, 0)
    room:sortPlayersByAction(mark)
    for _, pid in ipairs(mark) do
      if player.dead then break end
      local p = room:getPlayerById(pid)
      if event == fk.Damage then
        room:askForDiscard(target, 2, 2, true, "ty__zhongjian", false)
      else
        target:drawCards(2, "ty__zhongjian")
      end
      if not p.dead then
        p:drawCards(1, "ty__zhongjian")
      end
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return table.contains(player:getTableMark("ty__zhongjian_discard"), target.id)
    or table.contains(player:getTableMark("ty__zhongjian_draw"), target.id)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, mark in ipairs({"ty__zhongjian_discard","ty__zhongjian_draw"}) do
      room:setPlayerMark(player, mark, table.filter(player:getTableMark(mark), function (pid)
        return pid ~= target.id
      end))
    end
  end,
}
ty__zhongjian:addRelatedSkill(ty__zhongjian_trigger)
xinxianying:addSkill(ty__zhongjian)
local ty__caishi = fk.CreateTriggerSkill{
  name = "ty__caishi",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player == target and player.phase == Player.Draw then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local move = e.data[1]
        if move and move.to and player.id == move.to and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.DrawPile then
              return true
            end
          end
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local ids = {}
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      local move = e.data[1]
      if move and move.to and player.id == move.to and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DrawPile then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
    end, Player.HistoryPhase)
    if #ids == 0 then return false end
    local different = table.find(ids, function(id) return Fk:getCardById(id).suit ~= Fk:getCardById(ids[1]).suit end)
    self.cost_data = different
    if different then
      return player:isWounded() and player.room:askForSkillInvoke(player, self.name, nil, "#ty__caishi-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local different = self.cost_data
    if different then
      room:recover({ who = player,  num = 1, skillName = self.name })
      room:addPlayerMark(player, "@@ty__caishi_self-turn")
    else
      room:setPlayerMark(player, "ty__caishi_twice-turn", 1)
    end
  end,
}
local ty__caishi_prohibit = fk.CreateProhibitSkill{
  name = "#ty__caishi_prohibit",
  is_prohibited = function(self, from, to)
    return from:getMark("@@ty__caishi_self-turn") > 0 and from == to
  end,
}
ty__caishi:addRelatedSkill(ty__caishi_prohibit)
xinxianying:addSkill(ty__caishi)
Fk:loadTranslationTable{
  ["ty__xinxianying"] = "辛宪英",
  ["#ty__xinxianying"] = "忠鉴清识",
  ["illustrator:ty__xinxianying"] = "张晓溪", -- 战场绝版
  ["ty__zhongjian"] = "忠鉴",
  [":ty__zhongjian"] = "出牌阶段限一次，你可以秘密选择一名本回合未选择过的角色，并秘密选一项，直到你的下回合开始：1.当该角色下次造成伤害后，"..
  "其弃置两张牌；2.当该角色下次受到伤害后，其摸两张牌。当〖忠鉴〗被触发时，你摸一张牌。",
  ["ty__zhongjian_draw"] = "受到伤害后摸牌",
  ["ty__zhongjian_discard"] = "造成伤害后弃牌",
  ["#ty__zhongjian-choose"] = "忠鉴：选择一名角色，%arg",
  ["#ty__zhongjian_trigger"] = "忠鉴",
  ["ty__caishi"] = "才识",
  [":ty__caishi"] = "摸牌阶段结束时，若你本阶段摸的牌：花色相同，本回合〖忠鉴〗改为“出牌阶段限两次”；花色不同，你可以回复1点体力，然后本回合"..
  "你不能对自己使用牌。",
  ["#ty__caishi-invoke"] = "你可以回复1点体力，然后本回合你不能对自己使用牌",
  ["@@ty__caishi_self-turn"] = "才识",

  ["$ty__zhongjian1"] = "闻大忠似奸、大智若愚，不辨之难鉴之。",
  ["$ty__zhongjian2"] = "以眼为镜可正衣冠，以心为镜可鉴忠奸。",
  ["$ty__caishi1"] = "柔指弄弦商羽，缀符成乐，似落珠玉盘。",
  ["$ty__caishi2"] = "素手点墨二三，绘文成卷，集缤纷万千。",
  ["~ty__xinxianying"] = "百无一用是女子。",
}

local xuelingyun = General(extension, "xuelingyun", "wei", 3, 3, General.Female)
local xialei = fk.CreateTriggerSkill{
  name = "xialei",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:getMark("xialei-turn") > 2 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    local card_ids = {}
    if parent_event ~= nil then
      if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
        local parent_data = parent_event.data[1]
        if parent_data.from == player.id then
          card_ids = room:getSubcardsByRule(parent_data.card)
        end
      elseif parent_event.event == GameEvent.Pindian then
        local pindianData = parent_event.data[1]
        if pindianData.from == player then
          card_ids = room:getSubcardsByRule(pindianData.fromCard)
        else
          for toId, result in pairs(pindianData.results) do
            if player.id == toId then
              card_ids = room:getSubcardsByRule(result.toCard)
              break
            end
          end
        end
      end
    end
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        elseif #card_ids > 0 then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.Processing and table.contains(card_ids, info.cardId) and
            Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = U.turnOverCardsFromDrawPile(player, 3 - player:getMark("xialei-turn"), self.name, false)
    if #ids == 1 then
      room:obtainCard(player, ids, false, fk.ReasonJustMove, player.id, self.name)
    else
      local to_return, choice = U.askforChooseCardsAndChoice(player, ids, {"xialei_top", "xialei_bottom"}, self.name, "#xialei-chooose")
      room:obtainCard(player, to_return, false, fk.ReasonJustMove, player.id, self.name)
      U.returnCardsToDrawPile(player, ids, self.name, choice == "xialei_top", false)
    end
    room:addPlayerMark(player, "xialei-turn", 1)
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "xialei-turn", 0)
  end,
}
local anzhi = fk.CreateActiveSkill{
  name = "anzhi",
  anim_type = "support",
  prompt = "#anzhi-active",
  card_num = 0,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
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
      room:invalidateSkill(player, self.name, "-turn")
      local ids = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      ids = table.filter(ids, function (id) return room:getCardArea(id) == Card.DiscardPile end)
      if #ids == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
        return p ~= room.current end), Util.IdMapper), 1, 1, "#anzhi-choose", self.name, true)
      if #to > 0 then
        local get = {}
        if #ids > 2 then
          get = room:askForCardsChosen(player, player, 2, 2, {
            card_data = {
              { "pile_discard", ids }
            }
          }, self.name, "#anzhi-cards::" .. to[1])
        else
          get = ids
        end
        if #get > 0 then
          room:moveCards({
            ids = get,
            to = to[1],
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
            moveVisible = false,
            visiblePlayers = player.id,
          })
        end
      end
    end
  end,
}
local anzhi_trigger = fk.CreateTriggerSkill{
  name = "#anzhi_trigger",
  anim_type = "masochism",
  events = {fk.Damaged},
  main_skill = anzhi,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anzhi)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#anzhi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(anzhi.name)
    anzhi:onUse(player.room, {
      from = player.id,
      cards = {},
      tos = {},
    })
  end,
}
anzhi:addRelatedSkill(anzhi_trigger)
xuelingyun:addSkill(xialei)
xuelingyun:addSkill(anzhi)
Fk:loadTranslationTable{
  ["xuelingyun"] = "薛灵芸",
  ["#xuelingyun"] = "霓裳缀红泪",
  ["designer:xuelingyun"] = "懵萌猛梦",
  ["illustrator:xuelingyun"] = "Jzeo",
  ["xialei"] = "霞泪",
  [":xialei"] = "当你的红色牌进入弃牌堆后，你可观看牌堆顶的三张牌，然后你获得一张并可将其他牌置于牌堆底，你本回合观看牌数-1。",
  ["anzhi"] = "暗织",
  ["#anzhi_trigger"] = "暗织",
  [":anzhi"] = "出牌阶段，或当你受到伤害后，你可以判定，若结果为：红色，重置〖霞泪〗；"..
  "黑色，你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌，且你本回合不能再发动此技能。",
  ["#xialei-chooose"] = "霞泪：选择一张卡牌获得",
  ["xialei_top"] = "将剩余牌置于牌堆顶",
  ["xialei_bottom"] = "将剩余牌置于牌堆底",
  ["#anzhi-active"] = "发动暗织，进行判定",
  ["#anzhi-invoke"] = "是否使用暗织，进行判定",
  ["#anzhi-choose"] = "暗织：你可以令一名非当前回合角色获得本回合进入弃牌堆的两张牌",
  ["#anzhi-cards"] = "暗织：选择2张卡牌令%dest获得",

  ["$xialei1"] = "采霞揾晶泪，沾我青衫湿。",
  ["$xialei2"] = "登车入宫墙，垂泪凝如瑙。",
  ["$anzhi1"] = "深闱行彩线，唯手熟尔。",
  ["$anzhi2"] = "星月独照人，何谓之暗？",
  ["~xuelingyun"] = "寒月隐幕，难作衣裳。",
}

local ruiji = General(extension, "ty__ruiji", "wu", 4, 4, General.Female)
local wangyuan = fk.CreateTriggerSkill{
  name = "wangyuan",
  anim_type = "special",
  derived_piles = "ruiji_wang",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase == Player.NotActive and #player:getPile("ruiji_wang") < #player.room.players then
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
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wangyuan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local names = {}
    for _, id in ipairs(player:getPile("ruiji_wang")) do
      table.insertIfNeed(names, Fk:getCardById(id, true).trueName)
    end
    local cards = table.filter(room.draw_pile, function(id)
      local card = Fk:getCardById(id)
      return card.type ~= Card.TypeEquip and not table.contains(names, card.trueName)
    end)
    if #cards > 0 then
      player:addToPile("ruiji_wang", table.random(cards), true, self.name)
    end
  end,
}
local lingyin = fk.CreateViewAsSkill{
  name = "lingyin",
  anim_type = "offensive",
  prompt = "#lingyin-viewas",
  pattern = "duel",
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.sub_type == Card.SubtypeWeapon or card.sub_type == Card.SubtypeArmor)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@@lingyin-turn") > 0
  end,
}
local lingyin_trigger = fk.CreateTriggerSkill{
  name = "#lingyin_trigger",
  mute = true,
  expand_pile = "ruiji_wang",
  main_skill = lingyin,
  events = {fk.EventPhaseStart, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Play and #player:getPile("ruiji_wang") > 0
      else
        return player:getMark("@@lingyin-turn") > 0 and not data.chain and data.to ~= player
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local n = player.room:getBanner("RoundCount")
      local cards = player.room:askForCard(player, 1, n, false, "liying", true,
        ".|.|.|ruiji_wang|.|.", "#lingyin-invoke:::"..tostring(n), "ruiji_wang")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      player:broadcastSkillInvoke("lingyin")
      room:notifySkillInvoked(player, "lingyin", "drawcard")
      local cards = table.simpleClone(self.cost_data)
      local colors = {}
      for _, id in ipairs(player:getPile("ruiji_wang")) do
        if not table.contains(cards, id) then
          table.insertIfNeed(colors, Fk:getCardById(id).color)
        end
      end
      if #colors < 2 then
        room:setPlayerMark(player, "@@lingyin-turn", 1)
      end
      room:obtainCard(player, cards, true, fk.ReasonJustMove)
    else
      data.damage = data.damage + 1
    end
  end,
}
local liying = fk.CreateTriggerSkill{
  name = "liying",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.Draw and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(ids, info.cardId)
        end
      end
    end
    local prompt = "#liying1-invoke"
    if player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
      prompt = "#liying2-invoke"
    end
    local tos, cards = room:askForChooseCardsAndPlayers(player, 1, 999,
    table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, tostring(Exppattern{ id = ids }),
    prompt, self.name, true, false)
    if #tos > 0 and #cards > 0 then
      self.cost_data = {tos, cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ret = self.cost_data
    room:obtainCard(ret[1][1], ret[2], false, fk.ReasonGive, player.id)
    if not player.dead then
      player:drawCards(1, self.name)
      if not player.dead and player.phase ~= Player.NotActive and #player:getPile("ruiji_wang") < #room.players then
        local skill = Fk.skills["wangyuan"]
        skill:use(event, target, player, data)
      end
    end
  end,
}
lingyin:addRelatedSkill(lingyin_trigger)
ruiji:addSkill(wangyuan)
ruiji:addSkill(lingyin)
ruiji:addSkill(liying)
Fk:loadTranslationTable{
  ["ty__ruiji"] = "芮姬",
  ["#ty__ruiji"] = "柔荑弄钺",
  ["designer:ty__ruiji"] = "韩旭",
  ["illustrator:ty__ruiji"] = "匠人绘",
  ["wangyuan"] = "妄缘",
  [":wangyuan"] = "当你于回合外失去牌后，你可以随机将牌堆中一张基本牌或锦囊牌置于你的武将牌上，称为“妄”（“妄”的牌名不重复且至多为游戏人数）。",
  ["lingyin"] = "铃音",
  [":lingyin"] = "出牌阶段开始时，你可以获得至多X张“妄”（X为游戏轮数）。然后若“妄”颜色均相同，你本回合对其他角色造成的伤害+1且"..
  "可以将武器或防具牌当【决斗】使用。",
  ["liying"] = "俐影",
  [":liying"] = "每回合限一次，当你于摸牌阶段外获得牌后，你可以将其中任意张牌交给一名其他角色，然后你摸一张牌。若此时是你的回合内，再增加一张“妄”。",
  ["#wangyuan-invoke"] = "妄缘：是否增加一张“妄”？",
  ["ruiji_wang"] = "妄",
  ["#lingyin-invoke"] = "铃音：获得至多%arg张“妄”，然后若剩余“妄”颜色相同，你本回合伤害+1且可以将武器、防具当【决斗】使用",
  ["#lingyin-viewas"] = "发动 铃音，将一张武器牌或防具牌当【决斗】使用",
  ["@@lingyin-turn"] = "铃音",
  ["liying_active"] = "俐影",
  ["#liying1-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌",
  ["#liying2-invoke"] = "俐影：你可以将其中任意张牌交给一名其他角色，然后摸一张牌并增加一张“妄”",

  ["$wangyuan1"] = "小女子不才，愿伴公子余生。",
  ["$wangyuan2"] = "纵有万钧之力，然不斩情丝。",
  ["$lingyin1"] = "环佩婉尔，心动情动铃儿动。",
  ["$lingyin2"] = "小鹿撞入我怀，银铃焉能不鸣？",
  ["$liying1"] = "飞影略白鹭，日暮栖君怀。",
  ["$liying2"] = "妾影婆娑，摇曳君心。",
  ["~ty__ruiji"] = "佳人芳华逝，空余孤铃鸣……",
}

local duanqiaoxiao = General(extension, "duanqiaoxiao", "wei", 3, 3, General.Female)
local caizhuang = fk.CreateActiveSkill{
  name = "caizhuang",
  anim_type = "drawcard",
  prompt = function (self, selected_cards, selected_targets)
    local suits = {}
    local suit = Card.NoSuit
    for _, id in ipairs(selected_cards) do
      suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    return "#caizhuang-active:::" .. tostring(#suits)
  end,
  min_card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local suits = {}
    local suit = Card.NoSuit
    for _, id in ipairs(effect.cards) do
      suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        table.insertIfNeed(suits, suit)
      end
    end
    room:throwCard(effect.cards, self.name, player, player)
    local x = #suits
    if x == 0 then return end
    while true do
      player:drawCards(1, self.name)
      suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(suits, suit)
        end
      end
      if #suits >= x then return end
    end
  end,
}
local huayi = fk.CreateTriggerSkill{
  name = "huayi",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if judge.card.color ~= Card.NoColor then
      room:setPlayerMark(player, "@huayi", judge.card:getColorString())
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@huayi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@huayi", 0)
  end,
}
local huayi_trigger = fk.CreateTriggerSkill{
  name = "#huayi_trigger",
  mute = true,
  events = {fk.TurnEnd, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@huayi") ~= 0 then
      if event == fk.TurnEnd then
        return player:getMark("@huayi") == "red"
      elseif event == fk.Damaged then
        return target == player and player:getMark("@huayi") == "black"
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnEnd then
      player:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(1, "huayi")
    elseif event == fk.Damaged then
      player:broadcastSkillInvoke("huayi")
      room:notifySkillInvoked(player, "huayi", "drawcard")
      player:drawCards(2, "huayi")
    end
  end,
}
huayi:addRelatedSkill(huayi_trigger)
duanqiaoxiao:addSkill(caizhuang)
duanqiaoxiao:addSkill(huayi)
Fk:loadTranslationTable{
  ["duanqiaoxiao"] = "段巧笑",
  ["#duanqiaoxiao"] = "柔荑点绛唇",
  ["designer:duanqiaoxiao"] = "韩旭",
  ["illustrator:duanqiaoxiao"] = "Jzeo",

  ["caizhuang"] = "彩妆",
  [":caizhuang"] = "出牌阶段限一次，你可以弃置任意张牌，然后重复摸牌直到手牌中的花色数等同于弃牌花色数。",
  ["huayi"] = "华衣",
  [":huayi"] = "结束阶段，你可以判定，然后直到你的下回合开始时根据结果获得以下效果：红色，每个回合结束时摸一张牌；黑色，受到伤害后摸两张牌。",
  ["#huayi_trigger"] = "华衣",
  ["#caizhuang-active"] = "发动 彩妆，弃置任意张牌（包含的花色数：%arg）",
  ["@huayi"] = "华衣",

  ["$caizhuang1"] = "素手调脂粉，女子自有好颜色。",
  ["$caizhuang2"] = "为悦己者容，撷彩云为妆。",
  ["$huayi1"] = "皓腕凝霜雪，罗襦绣鹧鸪。",
  ["$huayi2"] = "绝色戴珠玉，佳人配华衣。",
  ["~duanqiaoxiao"] = "佳人时光少，君王总薄情……",
}

local tianshangyi = General(extension, "tianshangyi", "wei", 3, 3, General.Female)
local posuo = fk.CreateViewAsSkill{
  name = "posuo",
  prompt = "#posuo-viewas",
  interaction = function()
    local mark = Self:getTableMark("@posuo-phase")
    local names = Self:getMark("posuo_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          names[card.name] = names[card.name] or {}
          table.insertIfNeed(names[card.name], card:getSuitString(true))
        end
      end
      Self:setMark("posuo_names", names)
    end
    local choices, all_choices = {}, {}
    for name, suits in pairs(names) do
      local _suits = {}
      for _, suit in ipairs(suits) do
        if not table.contains(mark, suit) then
          table.insert(_suits, U.ConvertSuit(suit, "sym", "icon"))
        end
      end
      local posuo_name = "posuo_name:::" .. name.. ":" .. table.concat(_suits, "")
      table.insert(all_choices, posuo_name)
      if #_suits > 0 then
        local to_use = Fk:cloneCard(name)
        if Self:canUse(to_use) and not Self:prohibitUse(to_use) then
          table.insert(choices, posuo_name)
        end
      end
    end
    if #choices == 0 then return false end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  enabled_at_play = function(self, player)
    local mark = player:getMark("@posuo-phase")
    return mark ~= "posuo_prohibit" and mark == 0 or (#mark < 4)
  end,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == nil or #selected > 0 or
    Fk:currentRoom():getCardArea(to_select) == Player.Equip then return false end
    local card = Fk:getCardById(to_select)
    local posuo_name = string.split(self.interaction.data, ":")
    return string.find(posuo_name[#posuo_name], U.ConvertSuit(card.suit, "int", "icon"))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local posuo_name = string.split(self.interaction.data, ":")
    local card = Fk:cloneCard(posuo_name[4])
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = Self:getTableMark("@posuo-phase")
    table.insert(mark, use.card:getSuitString(true))
    player.room:setPlayerMark(player, "@posuo-phase", mark)
  end,
}
local posuo_refresh = fk.CreateTriggerSkill{
  name = "#posuo_refresh",

  refresh_events = {fk.EventAcquireSkill, fk.HpChanged},
  can_refresh = function(self, event, target, player, data)
    if not player:hasSkill(posuo, true) or player.phase ~= Player.Play or
    player:getMark("@posuo-phase") == "posuo_prohibit" then return false end
    if event == fk.HpChanged then
      return data.damageEvent and data.damageEvent.from == player
    elseif event == fk.EventAcquireSkill then
      return data == posuo and player == target
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.HpChanged then
      player.room:setPlayerMark(player, "@posuo-phase", "posuo_prohibit")
    elseif event == fk.EventAcquireSkill then
      local room = player.room
      room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if damage.from == player then
          room:setPlayerMark(player, "@posuo-phase", "posuo_prohibit")
          return true
        end
      end, Player.HistoryPhase)
    end
  end,
}
local xiaoren = fk.CreateTriggerSkill{
  name = "xiaoren",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("xiaoren_break-turn") == 0 and
    (player:usedSkillTimes(self.name) == 0 or data.skillName == self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if player.dead then return false end
    if judge.card.color == Card.Red then
      local targets = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper)
      , 1, 1, "#xiaoren-recover", self.name, true)
      if #targets > 0 then
        local tar = room:getPlayerById(targets[1])
        if tar:isWounded() then
          room:recover({
            who = tar,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          })
          if not (tar.dead or tar:isWounded()) then
            room:drawCards(tar, 1, self.name)
          end
        else
          room:drawCards(tar, 1, self.name)
        end
      end
    elseif judge.card.color == Card.Black then
      local tar = data.to
      if tar.dead then return false end
      local targets = table.map(table.filter(room.alive_players, function (p)
        return p:getNextAlive() == tar or tar:getNextAlive() == p
      end), Util.IdMapper)
      if #targets == 0 then return false end
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#xiaoren-damage::" .. tar.id, self.name, false)
      tar = room:getPlayerById(targets[1])
      room:damage{
        from = player,
        to = tar,
        damage = 1,
        skillName = self.name,
      }
    end
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function (self, event, target, player, data)
    return not player.dead and player:getMark("xiaoren_break-turn") == 0 and player:usedSkillTimes(self.name) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "xiaoren_break-turn", 1)
  end,
}
posuo:addRelatedSkill(posuo_refresh)
tianshangyi:addSkill(posuo)
tianshangyi:addSkill(xiaoren)

Fk:loadTranslationTable{
  ["tianshangyi"] = "田尚衣",
  ["#tianshangyi"] = "婀娜盈珠袖",
  ["designer:tianshangyi"] = "韩旭",
  ["illustrator:tianshangyi"] = "alien",
  ["posuo"] = "婆娑",
  [":posuo"] = "出牌阶段每种花色限一次，若你本阶段未对其他角色造成过伤害，你可以将一张手牌当此花色有的一张伤害牌使用。",
  ["xiaoren"] = "绡刃",
  [":xiaoren"] = "每回合限一次，当你造成伤害后，你可以判定，"..
  "若结果为：红色，你可以选择一名角色。其回复1点体力，若其未受伤，其摸一张牌；"..
  "黑色，对受伤角色的上家或下家造成1点伤害，然后你可以再次判定并执行对应结果直到有角色进入濒死状态。",

  ["#posuo-viewas"] = "发动 婆娑，将一张手牌当此花色有的一张伤害牌来使用",
  ["posuo_name"] = "%arg [%arg2]",
  ["@posuo-phase"] = "婆娑",
  ["posuo_prohibit"] = "失效",
  ["#xiaoren-recover"] = "绡刃：可令一名角色回复1点体力，然后若其满体力，其摸一张牌",
  ["#xiaoren-damage"] = "绡刃：对%dest的上家或下家造成1点伤害，未濒死可继续发动此技能",

  ["$posuo1"] = "绯纱婆娑起，佳人笑靥红。",
  ["$posuo2"] = "红烛映俏影，一舞影斑斓。",
  ["$xiaoren1"] = "红绡举腕重，明眸最溺人。",
  ["$xiaoren2"] = "飘然回雪轻，言然游龙惊。",
  ["~tianshangyi"] = "红梅待百花，魏宫无春风……",
}

local bailingyun = General(extension, "bailingyun", "wei", 3, 3, General.Female)
local linghui = fk.CreateTriggerSkill{
  name = "linghui",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish then
      if player == target then return true end
      local logic = player.room.logic
      local dyingevents = logic.event_recorder[GameEvent.Dying] or Util.DummyTable
      local turnevents = logic.event_recorder[GameEvent.Turn] or Util.DummyTable
      return #dyingevents > 0 and #turnevents > 0 and dyingevents[#dyingevents].id > turnevents[#turnevents].id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = U.turnOverCardsFromDrawPile(player, 3, self.name, false)
    local use = room:askForUseRealCard(player, ids, self.name, "#linghui-use", {
      expand_pile = ids,
      bypass_times = true,
      extraUse = true,
    }, true)
    if not player.dead and use then
      local toObtain = table.filter(ids, function (id)
        return room:getCardArea(id) == Card.Processing
      end)
      if #toObtain > 0 then
        room:obtainCard(player, table.random(toObtain, 1), false, fk.ReasonJustMove, player.id, self.name)
      end
    end
    U.returnCardsToDrawPile(player, ids, self.name, true, false)
  end,
}
local xiace = fk.CreateTriggerSkill{
  name = "xiace",
  anim_type = "masochism",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.Damage then
        return player:getMark("xiace_damage-turn") == 0 and not player:isNude()
      else
        return player:getMark("xiace_damaged-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.Damage then
      local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#xiace-recover", true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      local room = player.room
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#xiace-control", self.name, true)
      if #targets > 0 then
        self.cost_data = targets[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:setPlayerMark(player, "xiace_damage-turn", 1)
      room:throwCard(self.cost_data, self.name, player)
      if not player.dead and player:isWounded() then
        room:recover {
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    else
      room:setPlayerMark(player, "xiace_damaged-turn", 1)
      local tar = room:getPlayerById(self.cost_data)
      room:addPlayerMark(tar, "@@xiace-turn")
      room:addPlayerMark(tar, MarkEnum.UncompulsoryInvalidity .. "-turn")
    end
  end
}
local yuxin = fk.CreateTriggerSkill{
  name = "yuxin",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#yuxin-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover {
      who = target,
      num = math.max(1, player.hp) - target.hp,
      recoverBy = player,
      skillName = self.name,
    }
  end,
}
bailingyun:addSkill(linghui)
bailingyun:addSkill(xiace)
bailingyun:addSkill(yuxin)

Fk:loadTranslationTable{
  ["bailingyun"] = "柏灵筠",
  ["#bailingyun"] = "玲珑心窍",
  ["designer:bailingyun"] = "残昼厄夜",
  ["illustrator:bailingyun"] = "君桓文化",
  ["linghui"] = "灵慧",
  [":linghui"] = "一名角色的结束阶段，若其为你或有角色于本回合内进入过濒死状态，"..
  "你可以观看牌堆顶的三张牌，你可以使用其中一张牌，然后随机获得剩余牌中的一张。",
  ["xiace"] = "黠策",
  [":xiace"] = "每回合各限一次，当你受到伤害后，你可令一名其他角色的所有非锁定技于本回合内失效；"..
  "当你造成伤害后，你可以弃置一张牌并回复1点体力。",
  ["yuxin"] = "御心",
  [":yuxin"] = "限定技，当一名角色进入濒死状态时，你可以令其回复体力至X点（X为你的体力值且至少为1）。",

  ["#linghui-use"] = "灵慧：你可以使用其中的一张牌，然后获得剩余的随机一张",
  ["#xiace-recover"] = "是否发动 黠策，弃置一张牌来回复1点体力",
  ["#xiace-control"] = "是否发动 黠策，选择一名其他角色，令其本回合所有非锁定技失效",
  ["@@xiace-turn"] = "黠策",
  ["#yuxin-invoke"] = "是否对 %dest 发动 御心",

  ["$linghui1"] = "福兮祸所依，祸兮福所伏。",
  ["$linghui2"] = "枯桑知风，沧海知寒。",
  ["$xiace1"] = "风之积非厚，其负大翼也无力。",
  ["$xiace2"] = "人情同于抔土，岂穷达而异心。",
  ["$yuxin1"] = "得一人知情识趣，何妨同甘共苦。",
  ["$yuxin2"] = "临千军而不改其静，御心无波尔。",
  ["~bailingyun"] = "世人皆惧司马，独我痴情仲达……",
}

local malingli = General(extension, "malingli", "shu", 3, 3, General.Female)
local lima = fk.CreateDistanceSkill{
  name = "lima",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        for _, id in ipairs(p:getCardIds("e")) do
          local card_type = Fk:getCardById(id).sub_type
          if card_type == Card.SubtypeOffensiveRide or card_type == Card.SubtypeDefensiveRide then
            n = n + 1
          end
        end
      end
      return -math.max(1, n)
    end
    return 0
  end,
}
local xiaoyin = fk.CreateTriggerSkill{
  name = "xiaoyin",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function(p)
      return player == p or player:distanceTo(p) == 1
    end)
    local ids = U.turnOverCardsFromDrawPile(player, n, self.name)
    room:delay(2000)
    local to_get = {}
    for i = #ids, 1, -1 do
      if Fk:getCardById(ids[i]).color == Card.Red then
        table.insert(to_get, ids[i])
        table.remove(ids, i)
      end
    end
    if #to_get > 0 then
      room:obtainCard(player.id, to_get, true, fk.ReasonJustMove)
    end
    local targets = {}
    while #ids > 0 and not player.dead do
      room:setPlayerMark(player, "xiaoyin_cards", ids)
      room:setPlayerMark(player, "xiaoyin_targets", targets)
      local success, dat = room:askForUseActiveSkill(player, "xiaoyin_active", "#xiaoyin-give", true)
      room:setPlayerMark(player, "xiaoyin_cards", 0)
      room:setPlayerMark(player, "xiaoyin_targets", 0)
      if not success then break end
      table.insert(targets, dat.targets[1])
      table.removeOne(ids, dat.cards[1])
      room:getPlayerById(dat.targets[1]):addToPile("xiaoyin", dat.cards[1], true, self.name)
    end
    room:cleanProcessingArea(ids, self.name)
  end,
}
local xiaoyin_active = fk.CreateActiveSkill{
  name = "xiaoyin_active",
  mute = true,
  card_num = 1,
  target_num = 1,
  expand_pile = function (self)
    return Self:getTableMark("xiaoyin_cards")
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(Self:getTableMark("xiaoyin_cards"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local to = Fk:currentRoom():getPlayerById(to_select)
      if to:isRemoved() then return false end
      local targets = Self:getTableMark("xiaoyin_targets")
      if #targets == 0 then return true end
      if table.contains(targets, to_select) then return false end
      return table.find(targets, function(pid)
        local p = Fk:currentRoom():getPlayerById(pid)
        return p:getNextAlive() == to or to:getNextAlive() == p
        or (p:getNextAlive() == Self and Self:getNextAlive() == to)
        or (to:getNextAlive() == Self and Self:getNextAlive() == p)
      end)
    end
  end,
}
local xiaoyin_trigger = fk.CreateTriggerSkill{
  name = "#xiaoyin_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function (self, event, target, player, data)
    if target == player and #player:getPile("xiaoyin") > 0 and data.from and not data.from.dead then
      if data.damageType == fk.FireDamage then
        return not data.from:isNude()
      else
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if data.damageType == fk.FireDamage then
      local types = {}
      for _, id in ipairs(target:getPile("xiaoyin")) do
        table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
      end
      local card = player.room:askForDiscard(data.from, 1, 1, true, self.name, true,
      ".|.|.|.|.|"..table.concat(types, ","), "#xiaoyin-damage::"..target.id, true)
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      return player.room:askForSkillInvoke(data.from, "xiaoyin", nil, "#xiaoyin-fire::"..target.id)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if data.from:hasSkill(xiaoyin, true) then
      data.from:broadcastSkillInvoke("xiaoyin")
      room:notifySkillInvoked(data.from, "xiaoyin", "offensive")
    end
    room:doIndicate(data.from.id, {target.id})
    if data.damageType == fk.FireDamage then
      local card_type = Fk:getCardById(self.cost_data[1]).type
      room:throwCard(self.cost_data, "xiaoyin", data.from, data.from)
      local ids = table.filter(target:getPile("xiaoyin"), function(id)
        return Fk:getCardById(id).type == card_type end)
      if #ids > 0 then
        room:moveCards({
          from = target.id,
          ids = table.random(ids, 1),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = "xiaoyin",
          specialName = "xiaoyin",
        })
        data.damage = data.damage + 1
      end
    else
      local id = room:askForCardChosen(data.from, target, {
        card_data = {
          { "xiaoyin", target:getPile("xiaoyin") }
        }
      }, "xiaoyin", "#xiaoyin-fire::" .. target.id)
      room:moveCardTo(id, Card.PlayerHand, data.from, fk.ReasonJustMove, self.name, nil, true, data.from.id)
      data.damageType = fk.FireDamage
    end
  end,
}
local huahuo = fk.CreateViewAsSkill{
  name = "huahuo",
  anim_type = "offensive",
  prompt = "#huahuo",
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire__slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    local room = player.room
    local tos = TargetGroup:getRealTargets(use.tos)
    if table.find(tos, function(id) return #room:getPlayerById(id):getPile("xiaoyin") > 0 end) and
      table.find(room:getOtherPlayers(player), function(p) return not table.contains(tos, p.id) and #p:getPile("xiaoyin") > 0 end) then
      if room:askForSkillInvoke(player, self.name, nil, "#huahuo-invoke") then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if not table.contains(tos, p.id) and #p:getPile("xiaoyin") > 0 and not player:isProhibited(p, use.card) then
            TargetGroup:pushTargets(use.tos, p.id)
          end
        end
      end
    end
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
}
local huahuo_targetmod = fk.CreateTargetModSkill{
  name = "#huahuo_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, huahuo.name)
  end,
}
Fk:loadTranslationTable{
  ["malingli"] = "马伶俐",
  ["#malingli"] = "火树银花",
  ["cv:malingli"] = "寂言_zttt", -- 本名：曾彤
  ["designer:malingli"] = "星移",
  ["illustrator:malingli"] = "匠人绘",

  ["lima"] = "骊马",
  [":lima"] = "锁定技，场上每有一张坐骑牌，你计算与其他角色的距离-1（至少为1）。",
  ["xiaoyin"] = "硝引",
  [":xiaoyin"] = "准备阶段，你可以亮出牌堆顶X张牌（X为你距离1以内的角色数），获得其中红色牌，将其中任意张黑色牌作为“硝引”放置在等量名座次连续"..
  "（不计入你的座位）的其他角色的武将牌上。有“硝引”牌的角色受到伤害时：若为火焰伤害，伤害来源可以弃置一张与“硝引”同类别的牌并随机移去一张"..
  "此类别的“硝引”牌令此伤害+1；不为火焰伤害，伤害来源可以获得其一张“硝引”牌并将此伤害改为火焰伤害。",
  ["huahuo"] = "花火",
  [":huahuo"] = "出牌阶段限一次，你可以将一张红色手牌当无次数限制的【杀】使用。若目标有“硝引”牌，此【杀】可改为指定所有有“硝引”牌的角色为目标。",
  ["xiaoyin_active"] = "硝引",
  ["#xiaoyin_trigger"] = "硝引",
  ["#xiaoyin-give"] = "硝引：将黑色牌作为“硝引”放置在连续的其他角色武将牌上",
  ["#xiaoyin-damage"] = "硝引：你可以弃置一张与 %dest “硝引”同类别的牌，令其受到伤害+1",
  ["#xiaoyin-fire"] = "硝引：你可以获得 %dest 的一张“硝引”，令此伤害改为火焰伤害",
  ["#huahuo"] = "花火：你可以将一张红色手牌当不计次的火【杀】使用，目标可以改为所有有“硝引”的角色",
  ["#huahuo-invoke"] = "花火：是否将目标改为所有有“硝引”的角色？",

  ["$xiaoyin1"] = "鹿栖于野，必能奔光而来。",
  ["$xiaoyin2"] = "磨硝作引，可点心中灵犀。",
  ["$huahuo1"] = "馏石漆取上清，可为胜爆竹之花火。",
  ["$huahuo2"] = "莫道繁花好颜色，此火犹胜二月黄。",
  ["~malingli"] = "花无百日好，人无再少年……",
}

local juetao = fk.CreateTriggerSkill{
  name = "juetao",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
    and player.hp == 1 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
    1, 1, "#juetao-choose", self.name, true)
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
      local id = U.turnOverCardsFromDrawPile(player, -1, self.name)[1]
      local card = Fk:getCardById(id, true)
      local canUse = player:canUse(card, { bypass_times = true, bypass_distances = true }) and not player:prohibitUse(card)
      local tos
      if canUse then
        local targets = {}
        for _, p in ipairs({player, to}) do
          if not player:isProhibited(p, card) then
            if card.skill:modTargetFilter(p.id, {}, player, card, false) then
              table.insert(targets, p.id)
            end
          end
        end
        if #targets > 0 then
          if card.skill:getMinTargetNum() == 0 then
            if not card.multiple_targets then
              if table.contains(targets, player.id) then
                tos = {player.id}
              end
            else
              tos = targets
            end
            if not room:askForSkillInvoke(player, self.name, data, "#juetao-ask:::"..card:toLogString()) then
              tos = nil
            end
          elseif card.skill:getMinTargetNum() == 2 then
            if table.contains(targets, to.id) then
              local seconds = {}
              for _, second in ipairs(room:getOtherPlayers(to, false)) do
                if card.skill:modTargetFilter(second.id, {to.id}, player, card, false) then
                  table.insert(seconds, second.id)
                end
              end
              if #seconds > 0 then
                local temp = room:askForChoosePlayers(player, seconds, 1, 1, "#juetao-second:::"..card:toLogString(), self.name, true)
                if #temp > 0 then
                  tos = {to.id, temp[1]}
                end
              end
            end
          else
            if #targets == 1 then
              if room:askForSkillInvoke(player, self.name, data, "#juetao-use::"..targets[1]..":"..card:toLogString()) then
                tos = targets
              end
            else
              local temp = room:askForChoosePlayers(player, targets, 1, #targets, "#juetao-target:::"..card:toLogString(), self.name, true)
              if #temp > 0 then
                tos = temp
              end
            end
          end
        end
      end
      if tos then
        room:useCard({
          card = card,
          from = player.id,
          tos = table.map(tos, function(p) return {p} end) ,
          skillName = self.name,
          extraUse = true,
        })
      else
        room:delay(800)
        room:cleanProcessingArea({id}, self.name)
        return
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["juetao"] = "决讨",
  [":juetao"] = "限定技，出牌阶段开始时，若你的体力值为1，你可以选择一名角色并依次使用牌堆底的牌直到你无法使用，这些牌不能指定除你和该角色以外的角色为目标。",

  ["#juetao-choose"] = "决讨：你可以指定一名其他角色，连续对你或其使用牌堆底牌直到不能使用！",
  ["#juetao-use"] = "决讨：是否对 %dest 使用%arg",
  ["#juetao-ask"] = "决讨：是否使用%arg",
  ["#juetao-target"] = "决讨：选择你使用%arg的目标",
  ["#juetao-second"] = "决讨：选择你使用%arg的副目标",

  ["$juetao1"] = "登车拔剑起，奋跃搏乱臣！",
  ["$juetao2"] = "陵云决心意，登辇讨不臣！",
}

local quanhuijie = General(extension, "quanhuijie", "wu", 3, 3, General.Female)
local huishu = fk.CreateTriggerSkill{
  name = "huishu",
  anim_type = "drawcard",
  dynamic_desc = function(self, player)
    return
      "huishu_inner:" ..
      (player:getMark("huishu1") + 3) .. ":" ..
      (player:getMark("huishu2") + 1) .. ":" ..
      (player:getMark("huishu3") + 2)
  end,
  events = {fk.EventPhaseEnd, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseEnd then
      return target == player and player.phase == Player.Draw
    elseif player:usedSkillTimes(self.name) > 0 and player:getMark("_huishu-turn") == 0 then
      local room = player.room
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
              if turn_event == nil then return false end
              local end_id = turn_event.id
              local x = 0
              room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
                for _, move2 in ipairs(e.data) do
                  if move2.from == player.id and move2.moveReason == fk.ReasonDiscard then
                    for _, info2 in ipairs(move2.moveInfo) do
                      if info2.fromArea == Card.PlayerHand or info2.fromArea == Card.PlayerEquip then
                        x = x + 1
                      end
                    end
                  end
                end
                return false
              end, end_id)
              return x > player:getMark("huishu3") + 2 and table.find(room.discard_pile, function (id)
                return Fk:getCardById(id) ~= Card.TypeBasic
              end)
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return player.room:askForSkillInvoke(player, self.name)
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      player:drawCards(player:getMark("huishu1") + 3, self.name)
      if player.dead then return false end
      local x = player:getMark("huishu2") + 1
      player.room:askForDiscard(player, x, x, false, self.name, false)
    else
      local room = player.room
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|^basic", player:getMark("huishu3") + 2, "discardPile")
      if #cards > 0 then
        room:setPlayerMark(player, "_huishu-turn", 1)
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player.id, self.name)
      end
    end
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    room:setPlayerMark(player, "huishu1", 0)
    room:setPlayerMark(player, "huishu2", 0)
    room:setPlayerMark(player, "huishu3", 0)
    room:setPlayerMark(player, "@" .. self.name, {3, 1, 2})
  end,
  on_lose = function (self, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "huishu1", 0)
    room:setPlayerMark(player, "huishu2", 0)
    room:setPlayerMark(player, "huishu3", 0)
    room:setPlayerMark(player, "@" .. self.name, 0)
  end,
}
local yishu = fk.CreateTriggerSkill{
  name = "yishu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:hasSkill(huishu, true) and player.phase ~= Player.Play and
      not huishu:triggerable(event, target, player, data) then
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
    local yishu_nums = {
      player:getMark("huishu1") + 3,
      player:getMark("huishu2") + 1,
      player:getMark("huishu3") + 2
    }

    local max_c = math.max(yishu_nums[1], yishu_nums[2], yishu_nums[3])
    local min_c = math.min(yishu_nums[1], yishu_nums[2], yishu_nums[3])

    local to_change = {}
    for i = 1, 3, 1 do
      if yishu_nums[i] == max_c then
        table.insert(to_change, "huishu" .. tostring(i))
      end
    end

    local choice = room:askForChoice(player, to_change, self.name, "#yishu-lose")
    local index = tonumber(string.sub(choice, 7))
    yishu_nums[index] = yishu_nums[index] - 1

    room:setPlayerMark(player, "@huishu", yishu_nums)

    to_change = {}
    for i = 1, 3, 1 do
      if yishu_nums[i] == min_c and i ~= index then
        table.insert(to_change, "huishu" .. tostring(i))
      end
    end

    choice = room:askForChoice(player, to_change, self.name, "#yishu-add")
    index = tonumber(string.sub(choice, 7))
    yishu_nums[index] = yishu_nums[index] + 2

    room:setPlayerMark(player, "@huishu", yishu_nums)

    room:setPlayerMark(player, "huishu1", yishu_nums[1] - 3)
    room:setPlayerMark(player, "huishu2", yishu_nums[2] - 1)
    room:setPlayerMark(player, "huishu3", yishu_nums[3] - 2)
  end,
}
local ligong = fk.CreateTriggerSkill{
  name = "ligong",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:hasSkill(huishu, true) and
    (player:getMark("huishu1") > 1 or player:getMark("huishu2") > 3 or player:getMark("huishu3") > 2)
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

    local generals, same_g = {}, {}
    for _, general_name in ipairs(room.general_pile) do
      same_g = Fk:getSameGenerals(general_name)
      table.insert(same_g, general_name)
      same_g = table.filter(same_g, function (g_name)
        local general = Fk.generals[g_name]
        return (general.kingdom == "wu" or general.subkingdom == "wu") and general.gender == General.Female
      end)
      if #same_g > 0 then
        table.insert(generals, table.random(same_g))
      end
    end
    if #generals == 0 then return false end
    generals = table.random(generals, 4)

    local skills = {}
    for _, general_name in ipairs(generals) do
      local general = Fk.generals[general_name]
      local g_skills = {}
      for _, skill in ipairs(general.skills) do
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "wu") and player.kingdom == "wu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      for _, s_name in ipairs(general.other_skills) do
        local skill = Fk.skills[s_name]
        if not (table.contains({Skill.Limited, Skill.Wake, Skill.Quest}, skill.frequency) or skill.lordSkill) and
        (#skill.attachedKingdom == 0 or (table.contains(skill.attachedKingdom, "wu") and player.kingdom == "wu")) then
          table.insertIfNeed(g_skills, skill.name)
        end
      end
      table.insertIfNeed(skills, g_skills)
    end
    local result = player.room:askForCustomDialog(player, self.name,
    "packages/tenyear/qml/ChooseGeneralSkillsBox.qml", {
      generals, skills, 1, 2, "#ligong-choice", true
    })
    local choices = {}
    if result ~= "" then
      choices = json.decode(result)
    end
    if #choices == 0 then
      player:drawCards(3, self.name)
    else
      room:handleAddLoseSkills(player, "-huishu|"..table.concat(choices, "|"), nil)
    end
  end,
}
quanhuijie:addSkill(huishu)
quanhuijie:addSkill(yishu)
quanhuijie:addSkill(ligong)
Fk:loadTranslationTable{
  ["quanhuijie"] = "全惠解",
  ["#quanhuijie"] = "春宫早深",
  ["illustrator:quanhuijie"] = "游漫美绘",
  ["designer:quanhuijie"] = "笔枔",

  ["huishu"] = "慧淑",
  [":huishu"] = "摸牌阶段结束时，你可以摸3张牌然后弃置1张手牌。"..
  "若如此做，你本回合弃置超过2张牌时，从弃牌堆中随机获得等量的非基本牌。",
  [":huishu_inner"] = "摸牌阶段结束时，你可以摸{1}张牌然后弃置{2}张手牌。"..
  "若如此做，你本回合弃置超过{3}张牌时，从弃牌堆中随机获得等量的非基本牌。",
  ["yishu"] = "易数",
  [":yishu"] = "锁定技，当你于出牌阶段外失去牌后，〖慧淑〗中最小的一个数字+2且最大的一个数字-1。",
  ["ligong"] = "离宫",
  [":ligong"] = "觉醒技，准备阶段，若〖慧淑〗有数字达到5，你加1点体力上限并回复1点体力，失去〖易数〗，"..
  "然后从随机四个吴国女性武将中选择至多两个技能获得并失去〖慧淑〗（如果不获得技能则改为摸三张牌）。",
  ["@huishu"] = "慧淑",
  ["huishu1"] = "摸牌数",
  ["huishu2"] = "摸牌后弃牌数",
  ["huishu3"] = "获得锦囊所需弃牌数",
  ["#yishu-add"] = "易数：请选择增加的一项",
  ["#yishu-lose"] = "易数：请选择减少的一项",
  ["#ligong-choice"] = "离宫：选择至多2个武将技能",

  ["$huishu1"] = "心有慧镜，善解百般人意。",
  ["$huishu2"] = "袖着静淑，可揾夜阑之泪。",
  ["$yishu1"] = "此命由我，如织之数可易。",
  ["$yishu2"] = "易天定之数，结人定之缘。",
  ["$ligong1"] = "伴君离高墙，日暮江湖远。",
  ["$ligong2"] = "巍巍宫门开，自此不复来。",
  ["~quanhuijie"] = "妾有愧于陛下。",
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
  card_filter = Util.FalseFunc,
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
      local card = room:askForCard(target, 1, 1, false, self.name, false, ".|.|.|hand", "#fengyan-give:"..player.id)
      room:obtainCard(player.id, card[1], false, fk.ReasonGive, target.id)
    elseif self.interaction.data == "fengyan2-phase" then
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    end
  end,
}
local fudao = fk.CreateTriggerSkill{
  name = "fudao",
  anim_type = "support",
  mute = true,
  events = {fk.GameStart, fk.TargetSpecified, fk.Death, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.Death then
      if player:hasSkill(self, false, (player == target)) then
        local to = player.room:getPlayerById(player:getMark(self.name))
        return to ~= nil and ((player == target and not to.dead) or to == target) and data.damage and data.damage.from and
          not data.damage.from.dead and data.damage.from ~= player and data.damage.from ~= to
      end
      return false
    end
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.TargetSpecified then
        local to = player.room:getPlayerById(data.to)
        return ((player == target and player:getMark(self.name) == to.id) or (player == to and player:getMark(self.name) == target.id)) and
          player:getMark("fudao_specified-turn") == 0
      elseif event == fk.TargetConfirmed then
        return target == player and data.from ~= player.id and player.room:getPlayerById(data.from):getMark("@@juelie") > 0 and
          data.card.color == Card.Black
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:notifySkillInvoked(player, self.name)
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#fudao-choose", self.name, false, true)
      if #tos > 0 then
        room:setPlayerMark(player, self.name, tos[1])
        room:setPlayerMark(player, "@@fudao", 1)
        room:setPlayerMark(room:getPlayerById(tos[1]), "@@fudao", 1)
      end
    elseif event == fk.TargetSpecified then
      room:notifySkillInvoked(player, self.name)
      room:addPlayerMark(player, "fudao_specified-turn")
      local targets = {player.id, player:getMark(self.name)}
      room:sortPlayersByAction(targets)
      room:doIndicate(player.id, targets)
      for _, pid in ipairs(targets) do
        local p = room:getPlayerById(pid)
        if p and not p.dead then
          room:drawCards(p, 2, self.name)
        end
      end
    elseif event == fk.Death then
      room:notifySkillInvoked(player, self.name, "offensive")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(data.damage.from, "@@juelie", 1)
    elseif event == fk.TargetConfirmed then
      room:notifySkillInvoked(player, self.name, "control")
      player:broadcastSkillInvoke(self.name)
      room:setPlayerMark(room:getPlayerById(data.from), "@@fudao-turn", 1)
    end
  end,
}
local fudao_delay = fk.CreateTriggerSkill{
  name = "#fudao_delay",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@@fudao") > 0 and data.to:getMark("@@juelie") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, fudao.name, "offensive")
    if player:hasSkill(fudao, true) then
      player:broadcastSkillInvoke(fudao.name)
    end
    data.damage = data.damage + 1
  end,
}
local fudao_prohibit = fk.CreateProhibitSkill{
  name = "#fudao_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@fudao-turn") > 0
  end,
}
fudao:addRelatedSkill(fudao_delay)
fudao:addRelatedSkill(fudao_prohibit)
dingfuren:addSkill(fengyan)
dingfuren:addSkill(fudao)
Fk:loadTranslationTable{
  ["dingfuren"] = "丁尚涴",
  ["#dingfuren"] = "与君不载",
  ["designer:dingfuren"] = "韩旭",
  ["illustrator:dingfuren"] = "匠人绘",
  ["fengyan"] = "讽言",
  [":fengyan"] = "出牌阶段每项限一次，你可以选择一名其他角色，若其体力值小于等于你，你令其交给你一张手牌；"..
  "若其手牌数小于等于你，你视为对其使用【杀】（无距离限制）。",
  ["fudao"] = "抚悼",
  ["#fudao_delay"] = "抚悼",
  [":fudao"] = "游戏开始时，你选择一名其他角色，你与其每回合首次使用牌指定对方为目标后，各摸两张牌。杀死你或该角色的其他角色获得“决裂”标记，"..
  "你或该角色对有“决裂”的角色造成的伤害+1；“决裂”角色使用黑色牌指定你为目标后，其本回合不能再使用牌。",
  ["fengyan1-phase"] = "令一名体力值不大于你的角色交给你一张手牌",
  ["fengyan2-phase"] = "视为对一名手牌数不大于你的角色使用【杀】",
  ["#fengyan-give"] = "讽言：你须交给 %src 一张手牌",
  ["@@fudao"] = "抚悼",
  ["#fudao-choose"] = "抚悼：请选择要“抚悼”的角色",
  ["@@juelie"] = "决裂",
  ["@@fudao-turn"] = "抚悼 不能出牌",

  ["$fengyan1"] = "既将我儿杀之，何复念之！",
  ["$fengyan2"] = "乞问曹公，吾儿何时归还？",
  ["$fudao1"] = "弑子之仇，不共戴天！",
  ["$fudao2"] = "眼中泪绝，尽付仇怆。",
  ["~dingfuren"] = "吾儿既丧，天地无光……",
}

local xielingyu = General(extension, "xielingyu", "wu", 3, 3, General.Female)
local yuandi = fk.CreateTriggerSkill{
  name = "yuandi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and target.phase == Player.Play and target:getMark("yuandi-phase") == 0 then
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
    return (player:isWounded() or player:getHandcardNum() < player.maxHp) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
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
    local n = player.maxHp - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, self.name)
      if n > 2 then
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
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      ((player:getMark("xinyou_recover-turn") > 0 and not player:isNude()) or player:getMark("xinyou_draw-turn") > 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("xinyou_recover-turn") > 0 then
      room:askForDiscard(player, 1, 1, true, "xinyou", false)
    end
    if player:getMark("xinyou_draw-turn") > 0 then
      room:loseHp(player, 1, "xinyou")
    end
  end,
}
Fk:loadTranslationTable{
  ["yuandi"] = "元嫡",
  [":yuandi"] = "其他角色于其出牌阶段使用第一张牌时，若此牌没有指定除其以外的角色为目标，你可以选择一项：1.弃置其一张手牌；2.你与其各摸一张牌。",
  ["xinyou"] = "心幽",
  [":xinyou"] = "出牌阶段限一次，你可以回复体力至体力上限并将手牌摸至体力上限。若你因此摸超过两张牌，结束阶段你失去1点体力；"..
  "若你因此回复体力，结束阶段你弃置一张牌。",
  ["#yuandi-invoke"] = "元嫡：你可以弃置 %dest 的一张手牌或与其各摸一张牌",
  ["yuandi_discard"] = "弃置其一张手牌",
  ["yuandi_draw"] = "你与其各摸一张牌",
  ["#xinyou_record"] = "心幽",

  ["$yuandi1"] = "此生与君为好，共结连理。",
  ["$yuandi2"] = "结发元嫡，其情唯衷孙郎。",
  ["$xinyou1"] = "我有幽月一斛，可醉十里春风。",
  ["$xinyou2"] = "心在方外，故而不闻市井之声。",
}

local sunyu = General(extension, "sunyu", "wu", 3)
local quanshou = fk.CreateTriggerSkill{
  name = "quanshou",
  anim_type = "support",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target:getHandcardNum() <= target.maxHp
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#quanshou-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(target, {"quanshou1", "quanshou2:"..player.id}, self.name, "#quanshou-choice:"..player.id)
    if choice == "quanshou1" then
      room:setPlayerMark(target, "quanshou1-turn", 1)
      local n = math.min(target.maxHp - target:getHandcardNum(), 5)
      if n > 0 then
        target:drawCards(n, self.name)
      end
    else
      room:setPlayerMark(player, "quanshou2-turn", target.id)
    end
  end,
}
local quanshou_trigger = fk.CreateTriggerSkill{
  name = "#quanshou_trigger",
  mute = true,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("quanshou2-turn") ~= 0 and data.from and data.from == player:getMark("quanshou2-turn")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, "quanshou")
  end,
}
local quanshou_targetmod = fk.CreateTargetModSkill{
  name = "#quanshou_targetmod",
  residue_func = function(self, player, skill, scope, card)
    if card and card.trueName == "slash" and player:getMark("quanshou1-turn") > 0 and scope == Player.HistoryPhase then
      return -1
    end
  end,
}
local shexue = fk.CreateTriggerSkill{
  name = "shexue",
  anim_type = "special",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Play and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        if target:isNude() then return false end
        local room = player.room
        if player == target then
          local all_names = player:getMark("shexue_last-turn")
          if type(all_names) ~= "table" then
            all_names = {}
            local logic = room.logic
            local turn_event = logic:getCurrentEvent():findParent(GameEvent.Turn)
            if turn_event == nil then return false end
            local all_turn_events = logic.event_recorder[GameEvent.Turn]
            if type(all_turn_events) == "table" then
              local index = #all_turn_events
              if index > 1 then
                turn_event = all_turn_events[index - 1]
                local last_player = turn_event.data[1]
                local all_phase_events = logic.event_recorder[GameEvent.Phase]
                if type(all_phase_events) == "table" then
                  local play_ids = {}
                  for i = #all_phase_events, 1, -1 do
                    local e = all_phase_events[i]
                    if e.id < turn_event.id then
                      break
                    end
                    if e.id < turn_event.end_id and e.data[2] == Player.Play then
                      table.insert(play_ids, {e.id, e.end_id})
                    end
                  end
                  if #play_ids > 0 then
                    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
                      local in_play = false
                      for _, ids in ipairs(play_ids) do
                        if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
                          in_play = true
                          break
                        end
                      end
                      if in_play then
                        local use = e.data[1]
                        if use.from == last_player.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
                          table.insertIfNeed(all_names, use.card.name)
                        end
                      end
                    end, turn_event.id)
                  end
                end
              end
            end
            room:setPlayerMark(player, "shexue_last-turn", all_names)
          end
          local extra_data = {bypass_times = true, bypass_distances = true}
          local names = table.filter(all_names, function (n)
            local card = Fk:cloneCard(n)
            card.skillName = "shexue"
            return card.skill:canUse(player, card, extra_data) and not player:prohibitUse(card)
            and table.find(room.alive_players, function (p)
              return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, false)
            end)
          end)
          if #names > 0 then
            extra_data.virtualuse_allnames = all_names
            extra_data.virtualuse_names = names
            self.cost_data = extra_data
            return true
          end
        elseif not target.dead then
          local all_names = player:getTableMark("shexue_invoking-turn")
          if #all_names == 0 then return false end
          local extra_data = {bypass_times = true, bypass_distances = true}
          local names = table.filter(all_names, function (n)
            local card = Fk:cloneCard(n)
            card.skillName = "shexue"
            return card.skill:canUse(target, card, extra_data) and not target:prohibitUse(card)
            and table.find(room.alive_players, function (p)
              return not target:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, target, card, not bypass_distances)
            end)
          end)
          if #names > 0 then
            extra_data.virtualuse_allnames = all_names
            extra_data.virtualuse_names = names
            self.cost_data = extra_data
            return true
          end
        end
      elseif event == fk.EventPhaseEnd and player == target then
        local room = player.room
        local names = {}
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          local use = e.data[1]
          if use.from == player.id and (use.card.type == Card.TypeBasic or use.card:isCommonTrick()) then
            table.insertIfNeed(names, use.card.name)
          end
        end, Player.HistoryPhase)
        if #names > 0 then
          self.cost_data = names
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      if player == target then
        local success, dat = room:askForUseActiveSkill(player, "shexue_viewas", "#shexue-use", true, self.cost_data)
        if success then
          self.cost_data = dat
          return true
        end
      else
        room:doIndicate(player.id, {target.id})
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, nil, "#shexue-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local dat = table.simpleClone(self.cost_data)
      if player == target then
        local card = Fk:cloneCard(dat.interaction)
        card:addSubcards(dat.cards)
        card.skillName = "shexue"
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
        if player.dead or player ~= target then return false end
        local all_names = player:getTableMark("shexue_invoking-turn")
        if #all_names == 0 then return false end
        local extra_data = {bypass_times = true, bypass_distances = true}
        local names = table.filter(all_names, function (n)
          local card = Fk:cloneCard(n)
          card.skillName = "shexue"
          return card.skill:canUse(player, card, extra_data) and not player:prohibitUse(card)
          and table.find(room.alive_players, function (p)
            return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, not bypass_distances)
          end)
        end)
        if #names == 0 then return false end
        extra_data.virtualuse_allnames = all_names
        extra_data.virtualuse_names = names
        dat = extra_data
      end
      local success, dat2 = room:askForUseActiveSkill(target, "shexue_viewas", "#shexue-use", true, dat)
      if success and dat2 then
        local card = Fk:cloneCard(dat2.interaction)
        card:addSubcards(dat2.cards)
        card.skillName = "shexue"
        room:useCard{
          from = target.id,
          tos = table.map(dat2.targets, function(id) return {id} end),
          card = card,
          extraUse = true,
        }
      end
    else
      room:setPlayerMark(player, "shexue_invoking", table.simpleClone(self.cost_data))
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return player:getMark("shexue_invoking") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "shexue_invoking-turn", player:getMark("shexue_invoking"))
    room:setPlayerMark(player, "shexue_invoking", 0)
  end,
}

local shexue_viewas = fk.CreateViewAsSkill{
  name = "shexue_viewas",
  interaction = function(self)
    return UI.ComboBox {choices = self.virtualuse_names, all_choices = self.virtualuse_allnames }
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = "shexue"
    return card
  end,
}
Fk:loadTranslationTable{
  ["quanshou"] = "劝守",
  [":quanshou"] = "一名角色回合开始时，若其手牌数不大于体力上限，你可以令其选择："..
  "1.将手牌摸至体力上限（至多摸五张），其于此回合的出牌阶段内使用【杀】的次数上限-1；"..
  "2.其于此回合内使用牌被抵消后，你摸一张牌。",
  ["shexue"] = "设学",
  [":shexue"] = "出牌阶段开始时，你可以将一张牌当上个回合角色出牌阶段内使用过的一张基本牌或普通锦囊牌使用（无距离限制）；"..
  "出牌阶段结束时，你可以令下个回合角色于其出牌阶段开始时可以将一张牌当你本阶段使用过的一张基本牌或普通锦囊牌使用（无距离限制）。",
  ["#quanshou-invoke"] = "劝守：是否对 %dest 发动“劝守”？",
  ["#quanshou-choice"] = "劝守：选择 %src 令你执行的一项",
  ["quanshou1"] = "摸牌至体力上限，本回合使用【杀】次数-1",
  ["quanshou2"] = "你本回合使用牌被抵消后，%src摸一张牌",
  ["#shexue-invoke"] = "是否使用 设学，令下回合角色出牌阶段开始时可以将一张牌当你本阶段使用过的牌使用",
  ["shexue_viewas"] = "设学",
  ["#shexue-use"] = "是否使用 设学，将一张牌当上个回合角色出牌阶段内使用过的牌使用",

  ["$quanshou1"] = "曹军势大，不可刚其锋。",
  ["$quanshou2"] = "持重待守，不战而胜十万雄兵。",
  ["$shexue1"] = "虽为武夫，亦需极目汗青。",
  ["$shexue2"] = "武可靖天下，然不能定天下。",
}

local zhangfen = General(extension, "zhangfen", "wu", 4)
local wanglu_engine = {{"siege_engine", Card.Spade, 9}}
local wanglu = fk.CreateTriggerSkill{
  name = "wanglu",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "siege_engine" end) then
      player:gainAnExtraPhase(Player.Play)
    else
      local engine = table.find(U.prepareDeriveCards(room, wanglu_engine, "wanglu_engine"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if engine and U.canMoveCardIntoEquip(player, engine) then
        for i = 1, 3, 1 do
          room:setPlayerMark(player, "xianzhu"..tostring(i), 0)
        end
        room:moveCardIntoEquip(player, engine, self.name, true, player)
      end
    end
  end,
}
local xianzhu = fk.CreateTriggerSkill{
  name = "xianzhu",
  anim_type = "offensive",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
    table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "siege_engine" end)
    and (player:getMark("xianzhu1") + player:getMark("xianzhu2") + player:getMark("xianzhu3")) < 5
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
Fk:loadTranslationTable{
  ["wanglu"] = "望橹",
  [":wanglu"] = "锁定技，准备阶段，你将【大攻车】置入你的装备区，若你的装备区内已有【大攻车】，则你执行一个额外的出牌阶段。<br>"..
  "<font color='grey'>【大攻车】<br>♠9 装备牌·宝物<br /><b>装备技能</b>：出牌阶段开始时，你可以视为使用一张【杀】，"..
  "当此【杀】对目标角色造成伤害后，你弃置其一张牌。若此牌未升级，则防止此牌被弃置。此牌离开装备区时销毁。",
  ["xianzhu"] = "陷筑",
  [":xianzhu"] = "当你使用【杀】造成伤害后，你可以升级【大攻车】（每个【大攻车】最多升级5次）。升级选项：<br>"..
  "【大攻车】的【杀】无视距离和防具；<br>【大攻车】的【杀】可指定目标+1；<br>【大攻车】的【杀】造成伤害后弃牌数+1。",
  ["#xianzhu-choice"] = "陷筑：选择【大攻车】使用【杀】的增益效果",
  ["xianzhu1"] = "无视距离和防具",
  ["xianzhu2"] = "可指定目标+1",
  ["xianzhu3"] = "造成伤害后弃牌数+1",

  ["$wanglu1"] = "大攻车前，坚城弗当。",
  ["$wanglu2"] = "大攻既作，天下可望！",
  ["$xianzhu1"] = "敌垒已陷，当长驱直入！",
  ["$xianzhu2"] = "舍命陷登，击蛟蟒于狂澜！",
  ["$chaixie1"] = "利器经久，拆合自用。",
  ["$chaixie2"] = "损一得十，如鲸落宇。",
}
