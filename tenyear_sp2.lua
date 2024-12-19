local extension = Package("tenyear_sp2")
extension.extensionName = "tenyear"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["tenyear_sp2"] = "十周年-限定专属2",
  ["ty_sp"] = "新服SP",
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
    local mark = to:getTableMark(choice)
    table.insert(mark, player.id)
    room:setPlayerMark(to, choice, mark)
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
      local n = player.room:getTag("RoundCount")
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
    local use = U.askForUseRealCard(room, player, ids, ".", self.name, "#linghui-use",
    {expand_pile = ids, bypass_times = true}, false, true)
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
  pattern = "fire__slash",
  prompt = "#huahuo",
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
  enabled_at_response = function(self, player, response)
    return false
  end,
}
local huahuo_targetmod = fk.CreateTargetModSkill{
  name = "#huahuo_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, huahuo.name)
  end,
}
huahuo:addRelatedSkill(huahuo_targetmod)
Fk:addSkill(xiaoyin_active)
xiaoyin:addRelatedSkill(xiaoyin_trigger)
malingli:addSkill(lima)
malingli:addSkill(xiaoyin)
malingli:addSkill(huahuo)
Fk:loadTranslationTable{
  ["malingli"] = "马伶俐",
  ["#malingli"] = "火树银花",
  ["designer:malingli"] = "星移",
  ["illustrator:malingli"] = "匠人绘",

  ["lima"] = "骊马",
  [":lima"] = "锁定技，场上每有一张坐骑牌，你计算与其他角色的距离-1（至少为1）。",
  ["xiaoyin"] = "硝引",
  [":xiaoyin"] = "准备阶段，你可以亮出牌堆顶X张牌（X为你距离1以内的角色数），获得其中红色牌，将其中任意张黑色牌作为“硝引”放置在等量名连续（不计入你的座位）的其他角色的武将牌上。有“硝引”牌的角色受到伤害时：若为火焰伤害，伤害来源可以弃置一张与“硝引”同类别的牌并随机移去一张此类别的“硝引”牌令此伤害+1；"..
  "不为火焰伤害，伤害来源可以获得其一张“硝引”牌并将此伤害改为火焰伤害。",
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

local moqiongshu = General(extension, "moqiongshu", "wei", 3, 3, General.Female)
local wanchan = fk.CreateActiveSkill{
  name = "wanchan",
  anim_type = "support",
  prompt = "#wanchan-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local x = player:distanceTo(target)
    if x > 0 then
      room:drawCards(target, math.min(3, x), self.name)
      if target.dead then return false end
    end
    local use = U.askForPlayCard(room, target, nil, ".|.|.|.|.|basic,normal_trick", self.name, "#wanchan-use",
    { bypass_times = true, bypass_distances = true }, true)
    if use then
      use.extra_data = {wanchan_source = player.id}
      room:useCard(use)
    end
  end,
}
local wanchan_trigger = fk.CreateTriggerSkill{
  name = "#wanchan_trigger",
  events = {fk.AfterCardTargetDeclared},
  main_skill = wanchan,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(wanchan) and data.extra_data and data.extra_data.wanchan_source == player.id then
      local room = player.room
      local tos = table.map(TargetGroup:getRealTargets(data.tos), Util.Id2PlayerMapper)
      local targets = room:getUseExtraTargets(data, true)
      for _, pid in ipairs(targets) do
        local to = room:getPlayerById(pid)
        for _, p in ipairs(tos) do
          if p:getNextAlive() == to or to:getNextAlive() == p then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = table.map(TargetGroup:getRealTargets(data.tos), Util.Id2PlayerMapper)
    local targets = room:getUseExtraTargets(data, true)
    targets = table.filter(targets, function (pid)
      local to = room:getPlayerById(pid)
      for _, p in ipairs(tos) do
        if p:getNextAlive() == to or to:getNextAlive() == p then
          return true
        end
      end
    end)
    if #targets > 0 then
      room:doIndicate(player.id, targets)
      self.cost_data = {tos = targets}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.tos
    room:sendLog{
      type = "#AddTargetsBySkill",
      from = data.from,
      to = targets,
      arg = wanchan.name,
      arg2 = data.card:toLogString()
    }
    for _, pid in ipairs(targets) do
      table.insert(data.tos, {pid})
    end
  end,
}
local jiangzhi = fk.CreateTriggerSkill{
  name = "jiangzhi",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
    (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and not U.isOnlyTarget(player, data, event)
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
      room:drawCards(player, 3, self.name)
    elseif judge.card.color == Card.Black then
      local targets = table.filter(room.alive_players, function(p)
        return p ~= player and not p:isNude()
      end)
      if #targets == 0 then return false end
      targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#jiangzhi-discard", self.name)
      if #targets == 0 then return false end
      local to = room:getPlayerById(targets[1])
      local cards = room:askForCardsChosen(player, to, 1, 2, "hej", self.name)
      room:throwCard(cards, self.name, to, player)
    end
  end,
}

wanchan:addRelatedSkill(wanchan_trigger)
moqiongshu:addSkill(wanchan)
moqiongshu:addSkill(jiangzhi)

Fk:loadTranslationTable{
  ["moqiongshu"] = "莫琼树",
  ["#moqiongshu"] = "琼黛鬓墨雪",
  ["illustrator:malingli"] = "黯荧岛",

  ["wanchan"] = "宛蝉",
  [":wanchan"] = "出牌阶段限一次，你可以选择一名角色，令其摸X张牌（X为你与其距离且最多为3），"..
  "然后其可以使用一张基本牌或普通锦囊牌（无距离和次数限制），且你令与此牌的目标相邻的角色也成为此牌的目标。",
  ["jiangzhi"] = "绛脂",
  [":jiangzhi"] = "当你成为基本牌或普通锦囊牌的目标后，若你不是唯一目标，你可以判定，"..
  "若结果为：红色，你摸三张牌；黑色，你可以弃置一名其他角色的至多两张牌。",
  ["#wanchan_trigger"] = "宛蝉",

  ["#wanchan-active"] = "发动 宛蝉，选择一名角色，令其摸牌并可以使用牌",
  ["#wanchan-use"] = "宛蝉：你可以使用手牌中的一张基本牌或普通锦囊牌",
  ["#jiangzhi-discard"] = "绛脂：可以选择1名角色，弃置其1-2张牌",

  ["$wanchan1"] = "发如蝉翼轻扬，君王如何不偏爱？",
  ["$wanchan2"] = "轻挽云鬓，可栖玉蝉。",
  ["$jiangzhi1"] = "肌如凝脂，宛若晨露微沾之蕊。",
  ["$jiangzhi2"] = "镜中容颜，肤白胜雪，可胜瑶池仙子否？",
  ["~moqiongshu"] = "昔日桃花面，今朝已泛黄……",
}

--皇家贵胄：孙皓 士燮 曹髦 刘辩 刘虞 全惠解 丁尚涴 袁姬 谢灵毓 孙瑜 甘夫人糜夫人 曹芳 朱佩兰 卞玥 甘夫人 糜夫人 清河公主
local ty__sunhao = General(extension, "ty__sunhao", "wu", 5)
local ty__canshi = fk.CreateTriggerSkill{
  name = "ty__canshi",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.find(player.room.alive_players, function (p)
      return p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player)
    end)
  end,
  on_cost = function (self, event, target, player, data)
    local n = 0
    for _, p in ipairs(player.room.alive_players) do
      if p:isWounded() or (player:hasSkill("guiming") and p.kingdom == "wu" and p ~= player) then
        n = n + 1
      end
    end
    if player.room:askForSkillInvoke(player, self.name, nil, "#ty__canshi-invoke:::"..n) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + self.cost_data
  end,
}
local ty__canshi_delay = fk.CreateTriggerSkill{
  name = "#ty__canshi_delay",
  anim_type = "negative",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      player:usedSkillTimes(ty__canshi.name) > 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:askForDiscard(player, 1, 1, true, self.name, false)
  end,
}
local ty__chouhai = fk.CreateTriggerSkill{
  name = "ty__chouhai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events ={fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isKongcheng() and data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
ty__canshi:addRelatedSkill(ty__canshi_delay)
ty__sunhao:addSkill(ty__canshi)
ty__sunhao:addSkill(ty__chouhai)
ty__sunhao:addSkill("guiming")
Fk:loadTranslationTable{
  ["ty__sunhao"] = "孙皓",
  ["#ty__sunhao"] = "时日曷丧",
  ["designer:ty__sunhao"] = "韩旭",
  ["illustrator:ty__sunhao"] = "君桓文化",--传说皮
  ["ty__canshi"] = "残蚀",
  [":ty__canshi"] = "摸牌阶段，你可以多摸X张牌（X为已受伤的角色数），若如此做，当你于此回合内使用【杀】或普通锦囊牌时，你弃置一张牌。",
  ["#ty__canshi_delay"] = "残蚀",
  ["ty__chouhai"] = "仇海",
  [":ty__chouhai"] = "锁定技，当你受到【杀】造成的伤害时，若你没有手牌，此伤害+1。",
  ["#ty__canshi-invoke"] = "残蚀：你可以多摸 %arg 张牌",

  ["$ty__canshi1"] = "天地不仁，当视苍生为刍狗！",
  ["$ty__canshi2"] = "真龙天子，焉能不择人而噬！",
  ["$ty__chouhai1"] = "大好头颅，谁当斫之？哈哈哈！",
  ["$ty__chouhai2"] = "来来来！且试吾颈硬否！",
  ["$guiming_ty__sunhao1"] = "朕奉天承运，谁敢不从！",
  ["$guiming_ty__sunhao2"] = "朕一日为吴皇，则终生为吴皇！",
  ["~ty__sunhao"] = "八十万人齐卸甲，一片降幡出石头。",
}

local ty__shixie = General(extension, "ty__shixie", "qun", 3)
local ty__biluan = fk.CreateTriggerSkill{
  name = "ty__biluan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      return table.find(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local x = math.min(4, #player.room.alive_players)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#ty__biluan-invoke:::"..x, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local x = math.min(4, #player.room.alive_players)
    local num = tonumber(player:getMark("@ty__shixie_distance"))+x
    room:setPlayerMark(player,"@ty__shixie_distance",num > 0 and "+"..num or num)
  end,
}
local ty__biluan_distance = fk.CreateDistanceSkill{
  name = "#ty__biluan_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num > 0 then
      return num
    end
  end,
}
ty__biluan:addRelatedSkill(ty__biluan_distance)
ty__shixie:addSkill(ty__biluan)
local ty__lixia = fk.CreateTriggerSkill{
  name = "ty__lixia",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Finish and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"draw1", "ty__lixia_draw:"..target.id}, self.name)
    if choice == "draw1" then
      player:drawCards(1, self.name)
    else
      target:drawCards(2, self.name)
    end
    local num = tonumber(player:getMark("@ty__shixie_distance"))-1
    room:setPlayerMark(player,"@ty__shixie_distance",num > 0 and "+"..num or num)
  end,
}
local ty__lixia_distance = fk.CreateDistanceSkill{
  name = "#ty__lixia_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num < 0 then
      return num
    end
  end,
}
ty__lixia:addRelatedSkill(ty__lixia_distance)
ty__shixie:addSkill(ty__lixia)
Fk:loadTranslationTable{
  ["ty__shixie"] = "士燮",
  ["#ty__shixie"] = "雄长百越",
  ["illustrator:ty__shixie"] = "陈龙",--史诗皮
  ["ty__biluan"] = "避乱",
  [":ty__biluan"] = "结束阶段，若有其他角色计算与你的距离为1，你可以弃置一张牌，令其他角色计算与你的距离+X（X为全场角色数且至多为4）。",
  ["ty__lixia"] = "礼下",
  [":ty__lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.令其摸两张牌。选择完成后，其他角色计算与你的距离-1。",
  ["#ty__biluan-invoke"] = "避乱：你可弃一张牌，令其他角色计算与你距离+%arg",
  ["@ty__shixie_distance"] = "距离",
  ["ty__lixia_draw"] = "令%src摸两张牌",

  ["$ty__biluan1"] = "天下攘攘，难觅避乱之地。",
  ["$ty__biluan2"] = "乱世纷扰，唯避居，方为良策。",
  ["$ty__lixia1"] = "得人才者，得天下。",
  ["$ty__lixia2"] = "礼贤下士，方得民心。",
  ["~ty__shixie"] = "老夫此生，了无遗憾。",
}

local caomao = General(extension, "caomao", "wei", 3, 4)
local qianlong = fk.CreateTriggerSkill{
  name = "qianlong",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and target:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = U.turnOverCardsFromDrawPile(player, 3, self.name)
    local result = room:askForGuanxing(player, cards, {0, 3}, {0, player:getLostHp()}, self.name, true, {"Bottom", "toObtain"})
    if #result.bottom > 0 then
      room:moveCardTo(result.bottom, Player.Hand, player, fk.ReasonJustMove, self.name, "", true, player.id)
    end
    U.returnCardsToDrawPile(player, result.top, self.name, false, false)
  end,
}
local fensi = fk.CreateTriggerSkill{
  name = "fensi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getAlivePlayers(), function(p)
      return p.hp >= player.hp end), Util.IdMapper), 1, 1, "#fensi-choose", self.name, false)
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
            if card.skill:modTargetFilter(p.id, {}, player.id, card, false) then
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
                if card.skill:modTargetFilter(second.id, {to.id}, player.id, card, false) then
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
local zhushi = fk.CreateTriggerSkill{
  name = "zhushi$",
  anim_type = "drawcard",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase ~= Player.NotActive and target.kingdom == "wei" and
      player:usedSkillTimes(self.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(target, {"zhushi_draw", "Cancel"}, self.name, "#zhushi-invoke:"..player.id)
    if choice == "zhushi_draw" then
      player:drawCards(1, self.name)
    end
  end,
}
caomao:addSkill(qianlong)
caomao:addSkill(fensi)
caomao:addSkill(juetao)
caomao:addSkill(zhushi)
Fk:loadTranslationTable{
  ["caomao"] = "曹髦",
  ["#caomao"] = "霸业的终耀",
  ["illustrator:caomao"] = "游漫美绘",
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
  ["#juetao-choose"] = "决讨：你可以指定一名其他角色，连续对你或其使用牌堆底牌直到不能使用！",
  ["#juetao-use"] = "决讨：是否对 %dest 使用%arg",
  ["#juetao-ask"] = "决讨：是否使用%arg",
  ["#juetao-target"] = "决讨：选择你使用%arg的目标",
  ["#juetao-second"] = "决讨：选择你使用%arg的副目标",
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

local liubian = General(extension, "liubian", "qun", 3)
local shiyuan = fk.CreateTriggerSkill{
  name = "shiyuan",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.from ~= player.id then
      local from = player.room:getPlayerById(data.from)
      local n = 1
      if player:hasSkill("yuwei") and player.room.current.kingdom == "qun" then
        n = 2
      end
      return (from.hp > player.hp and player:getMark("shiyuan1-turn") < n) or
      (from.hp == player.hp and player:getMark("shiyuan2-turn") < n) or
      (from.hp < player.hp and player:getMark("shiyuan3-turn") < n)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if from.hp > player.hp then
      player:drawCards(3, self.name)
      room:addPlayerMark(player, "shiyuan1-turn", 1)
    elseif from.hp == player.hp then
      player:drawCards(2, self.name)
      room:addPlayerMark(player, "shiyuan2-turn", 1)
    elseif from.hp < player.hp then
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "shiyuan3-turn", 1)
    end
  end,
}
local dushi = fk.CreateTriggerSkill{
  name = "dushi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return not p:hasSkill(self) end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#dushi-choose", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    room:handleAddLoseSkills(room:getPlayerById(to), self.name, nil, true, false)
  end,

  refresh_events = {fk.EnterDying},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(self.name)
    player.room:notifySkillInvoked(player, self.name)
  end,
}
local dushi_prohibit = fk.CreateProhibitSkill{
  name = "#dushi_prohibit",
  prohibit_use = function(self, player, card)
    if card.name == "peach" and not player.dying then
      return table.find(Fk:currentRoom().alive_players, function(p) return p.dying and p:hasSkill("dushi") and p ~= player end)
    end
  end,
}
local yuwei = fk.CreateTriggerSkill{
  name = "yuwei$",
  frequency = Skill.Compulsory,
}
dushi:addRelatedSkill(dushi_prohibit)
liubian:addSkill(shiyuan)
liubian:addSkill(dushi)
liubian:addSkill(yuwei)
Fk:loadTranslationTable{
  ["liubian"] = "刘辩",
  ["#liubian"] = "弘农怀王",
  ["designer:liubian"] = "韩旭",
  ["illustrator:liubian"] = "zoo",
  ["shiyuan"] = "诗怨",
  [":shiyuan"] = "每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；"..
  "3.若其体力值比你少，你摸一张牌。",
  ["dushi"] = "毒逝",
  [":dushi"] = "锁定技，你处于濒死状态时，其他角色不能对你使用【桃】。你死亡时，你选择一名其他角色获得〖毒逝〗。",
  ["yuwei"] = "余威",
  [":yuwei"] = "主公技，锁定技，其他群雄角色的回合内，〖诗怨〗改为“每回合每项限两次”。",
  ["#dushi-choose"] = "毒逝：令一名其他角色获得〖毒逝〗",
  
  ["$shiyuan1"] = "感怀诗于前，绝怨赋于后。",
  ["$shiyuan2"] = "汉宫楚歌起，四面无援矣。",
  ["$dushi1"] = "孤无病，此药无需服。",
  ["$dushi2"] = "辟恶之毒，为最毒。",
  ["~liubian"] = "侯非侯，王非王……",
}

local liuyu = General(extension, "ty__liuyu", "qun", 3)
local suifu = fk.CreateTriggerSkill{
  name = "suifu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and target.phase == Player.Finish and not target:isKongcheng() then
      local count = 0
      return #player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if damage.to == player or damage.to.seat == 1 then
          count = count + damage.damage
        end
        return count > 1
      end, Player.HistoryTurn) > 0
    end
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
      fromArea = Card.PlayerHand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    room:useVirtualCard("amazing_grace", nil, player, table.filter(room:getAlivePlayers(), function (p)
      return not player:isProhibited(p, Fk:cloneCard("amazing_grace")) end), self.name, false)
  end,
}
local pijing = fk.CreateTriggerSkill{
  name = "pijing",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local extra_data = {
      targets = table.map(room.alive_players, Util.IdMapper),
      num = 99,
      min_num = 0,
      pattern = "",
      skillName = self.name,
    }
    local success, dat = room:askForUseActiveSkill(player, "choose_players_skill", "#pijing-choose", true, extra_data, true)
    if success and dat then
      local tos = table.simpleClone(dat.targets)
      table.insertIfNeed(tos, player.id)
      room:sortPlayersByAction(tos)
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(self.cost_data.tos)
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        room:handleAddLoseSkills(p, "-zimu", nil, true, false)
      end
    end
    for _, id in ipairs(tos) do
      room:handleAddLoseSkills(room:getPlayerById(id), "zimu", nil, true, false)
    end
  end,
}
local zimu = fk.CreateTriggerSkill{
  name = "zimu",
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill("zimu", true) then
        p:drawCards(1, self.name)
      end
    end
    room:handleAddLoseSkills(player, "-zimu", nil, true, false)
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function (self, event, target, player, data)
    return target == player and data == self
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@pijing", event == fk.EventAcquireSkill and 1 or 0)
  end,
}
liuyu:addSkill(suifu)
liuyu:addSkill(pijing)
liuyu:addRelatedSkill(zimu)
Fk:loadTranslationTable{
  ["ty__liuyu"] = "刘虞",
  ["#ty__liuyu"] = "维城燕北",
  ["designer:ty__liuyu"] = "七哀",
  ["illustrator:ty__liuyu"] = "君桓文化",
  ["suifu"] = "绥抚",
  [":suifu"] = "其他角色的结束阶段，若本回合你和一号位共计至少受到两点伤害，你可将当前回合角色的所有手牌置于牌堆顶，视为使用一张【五谷丰登】。",
  ["pijing"] = "辟境",
  [":pijing"] = "结束阶段，你可选择包含你的任意名角色，这些角色获得〖自牧〗直到下次发动〖辟境〗。",
  ["zimu"] = "自牧",
  [":zimu"] = "锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗。",
  ["#suifu-invoke"] = "绥抚：你可以将 %dest 所有手牌置于牌堆顶，你视为使用【五谷丰登】",
  ["#pijing-choose"] = "辟境：你可以令包括你的任意名角色获得技能〖自牧〗直到下次发动〖辟境〗<br>"..
  "（锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗）",
  ["@@pijing"] = "辟境",

  ["$suifu1"] = "以柔克刚，方是良策。",
  ["$suifu2"] = "镇抚边疆，为国家计。",
  ["$pijing1"] = "群寇来袭，愿和将军同御外侮。",
  ["$pijing2"] = "天下不宁，愿与阁下共守此州。",
  ["$zimu"] = "既为汉吏，当遵汉律。",
  ["~ty__liuyu"] = "公孙瓒谋逆，人人可诛！",
}

local quanhuijie = General(extension, "quanhuijie", "wu", 3, 3, General.Female)
local huishu = fk.CreateTriggerSkill{
  name = "huishu",
  anim_type = "drawcard",
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
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
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

local yuanji = General(extension, "yuanji", "wu", 3, 3, General.Female)
local fangdu = fk.CreateTriggerSkill{
  name = "fangdu",
  anim_type = "masochism",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) or player.phase ~= Player.NotActive then return false end
    local room = player.room
    local damage_event = room.logic:getCurrentEvent()
    if not damage_event then return false end
    local mark_name = "fangdu1_record-turn"
    if data.damageType == fk.NormalDamage then
      if not player:isWounded() then return false end
    else
      if data.from == nil or data.from == player or data.from:isKongcheng() then return false end
      mark_name = "fangdu2_record-turn"
    end
    local x = player:getMark(mark_name)
    if x == 0 then
      room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local reason = e.data[3]
        if e.data[1] == player and reason == "damage" then
          local first_damage_event = e:findParent(GameEvent.Damage)
          if first_damage_event then
            local damage = first_damage_event.data[1]
            if damage.damageType == data.damageType then
              x = first_damage_event.id
              room:setPlayerMark(player, mark_name, x)
              return true
            end
          end
        end
      end, Player.HistoryTurn)
    end
    return damage_event.id == x
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
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name, nil, "@@jiexing-inhand-turn")
  end,
}
local jiexing_maxcards = fk.CreateMaxCardsSkill{
  name = "#jiexing_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@jiexing-inhand-turn") > 0
  end,
}
jiexing:addRelatedSkill(jiexing_maxcards)
yuanji:addSkill(fangdu)
yuanji:addSkill(jiexing)
Fk:loadTranslationTable{
  ["yuanji"] = "袁姬",
  ["#yuanji"] = "袁门贵女",
  ["designer:yuanji"] = "韩旭",
  ["illustrator:yuanji"] = "匠人绘",
  ["fangdu"] = "芳妒",
  [":fangdu"] = "锁定技，你的回合外，你每回合第一次受到普通伤害后回复1点体力，你每回合第一次受到属性伤害后随机获得伤害来源一张手牌。",
  ["jiexing"] = "节行",
  [":jiexing"] = "当你的体力值变化后，你可以摸一张牌，此牌于本回合内不计入手牌上限。",

  ["#jiexing-invoke"] = "节行：你可以摸一张牌，此牌本回合不计入手牌上限",
  ["@@jiexing-inhand-turn"] = "节行",

  ["$fangdu1"] = "浮萍却红尘，何意染是非？",
  ["$fangdu2"] = "我本无意争春，奈何群芳相妒。",
  ["$jiexing1"] = "女子有节，安能贰其行？",
  ["$jiexing2"] = "坐受雨露，皆为君恩。",
  ["~yuanji"] = "妾本蒲柳，幸荣君恩……",
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
xinyou:addRelatedSkill(xinyou_record)
xielingyu:addSkill(yuandi)
xielingyu:addSkill(xinyou)
Fk:loadTranslationTable{
  ["xielingyu"] = "谢灵毓",
  ["#xielingyu"] = "淑静才媛",
  ["designer:xielingyu"] = "韩旭",
  ["illustrator:xielingyu"] = "游漫美绘",
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
  ["~xielingyu"] = "翠瓦红墙处，最折意中人。",
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
              return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player.id, card, false)
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
              return not target:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, target.id, card, not bypass_distances)
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
            return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player.id, card, not bypass_distances)
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

quanshou:addRelatedSkill(quanshou_trigger)
quanshou:addRelatedSkill(quanshou_targetmod)
Fk:addSkill(shexue_viewas)
sunyu:addSkill(quanshou)
sunyu:addSkill(shexue)
Fk:loadTranslationTable{
  ["sunyu"] = "孙瑜",
  ["#sunyu"] = "镇据边陲",
  ["designer:sunyu"] = "胜天半子ying",
  ["illustrator:sunyu"] = "CatJade玉猫",
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
  ["~sunyu"] = "孙氏始得江东，奈何魂归黄泉……",
}

local ganfurenmifuren = General(extension, "ganfurenmifuren", "shu", 3, 3, General.Female)
local chanjuan = fk.CreateTriggerSkill{
  name = "chanjuan",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card:isCommonTrick() or data.card.type == Card.TypeBasic) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and U.IsUsingHandcard(player, data) and 
      #table.filter(player:getTableMark("@$chanjuan"), function(s) return s == data.card.trueName end) < 2
  end,
  on_cost = function(self, event, target, player, data)
    local use = U.askForUseVirtualCard(player.room, player, data.card.trueName, nil, self.name, "#chanjuan-use::"..TargetGroup:getRealTargets(data.tos)[1]..":"..data.card.trueName, true, true, false, true, {}, true)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = self.cost_data
    room:addTableMark(player, "@$chanjuan", data.card.trueName)
    room:useCard(use)
    if not player.dead and #TargetGroup:getRealTargets(use.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] == TargetGroup:getRealTargets(use.tos)[1] then
      player:drawCards(1, self.name)
    end
  end,
  
  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@$chanjuan") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@$chanjuan", 0)
  end,
}
local xunbie = fk.CreateTriggerSkill{
  name = "xunbie",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local generals = {}
    if not table.find(room.alive_players, function(p) return p.general == "ty__ganfuren" or p.deputyGeneral == "ty__ganfuren" end) then
      table.insert(generals, "ty__ganfuren")
    end
    if not table.find(room.alive_players, function(p) return p.general == "ty__mifuren" or p.deputyGeneral == "ty__mifuren" end) then
      table.insert(generals, "ty__mifuren")
    end
    if #generals > 0 then
      local general = room:askForGeneral(player, generals, 1, true)
      U.changeHero(player, general, false)
      if player.dead then return end
    end
    room:setPlayerMark(player, "@@xunbie-turn", 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local xunbie_trigger = fk.CreateTriggerSkill{
  name = "#xunbie_trigger",
  events = {fk.DamageInflicted},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@xunbie-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("xunbie")
    return true
  end,
}
xunbie:addRelatedSkill(xunbie_trigger)
ganfurenmifuren:addSkill(chanjuan)
ganfurenmifuren:addSkill(xunbie)
Fk:loadTranslationTable{
  ["ganfurenmifuren"] = "甘夫人糜夫人",
  ["#ganfurenmifuren"] = "千里婵娟",
  ["designer:ganfurenmifuren"] = "星移",
  ["illustrator:ganfurenmifuren"] = "七兜豆",

  ["chanjuan"] = "婵娟",
  [":chanjuan"] = "每种牌名限两次，你使用指定唯一目标的基本牌或普通锦囊牌结算完毕后，你可以视为使用一张同名牌，若目标完全相同，你摸一张牌。",
  ["xunbie"] = "殉别",
  [":xunbie"] = "限定技，当你进入濒死状态时，你可以将武将牌改为甘夫人或糜夫人，然后回复体力至1并防止你受到的伤害直到回合结束。",
  ["@$chanjuan"] = "婵娟",
  ["#chanjuan-use"] = "婵娟：你可以视为使用【%arg】，若目标为 %dest ，你摸一张牌",
  ["chanjuan_viewas"] = "婵娟",
  ["#xunbie_trigger"] = "殉别",
  ["@@xunbie-turn"] = "殉别",

  ["$chanjuan1"] = "姐妹一心，共侍玄德无忧。",
  ["$chanjuan2"] = "双姝从龙，姊妹宠荣与共。",
  ["$xunbie1"] = "既为君之妇，何惧为君之鬼。",
  ["$xunbie2"] = "今临难将罹，唯求不负皇叔。",
  ["~ganfurenmifuren"] = "人生百年，奈何于我十不存一……",
}

local caofang = General(extension, "caofang", "wei", 4)
local zhimin = fk.CreateTriggerSkill{
  name = "zhimin",
  events = {fk.RoundStart, fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      local cards1, cards2 = {}, {}
      local handcards = player:getCardIds(Player.Hand)
      local mark = player:getTableMark("zhimin_record")
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Player.Hand then
          if player.phase == Player.NotActive then
            for _, info in ipairs(move.moveInfo) do
              local id = info.cardId
              if table.contains(handcards, id) then
                table.insert(cards1, id)
              end
            end
          end
        elseif move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if info.fromArea == Player.Hand and table.contains(mark, id) then
              table.insert(cards2, id)
            end
          end
        end
      end
      if #cards1 > 0 or #cards2 > 0 then
        self.cost_data = {cards1, cards2}
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local zhimin_data = table.simpleClone(self.cost_data)
      local mark = player:getTableMark("zhimin_record")
      if #zhimin_data[1] > 0 then
        table.insertTableIfNeed(mark, zhimin_data[1])
        for _, id in ipairs(zhimin_data[1]) do
          room:setCardMark(Fk:getCardById(id), "@@zhimin-inhand", 1)
        end
      end
      for _, id in ipairs(zhimin_data[2]) do
        table.removeOne(mark, id)
      end
      room:setPlayerMark(player, "zhimin_record", mark)
      if #zhimin_data[2] > 0 then
        local num = player.maxHp - player:getHandcardNum()
        if num > 0 then
          player:drawCards(num, self.name)
        end
      end
    elseif event == fk.RoundStart then
      local targets = table.filter(room.alive_players, function (p)
        return p ~= player and not p:isKongcheng()
      end)
      if #targets == 0 then return false end
      targets = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, player.hp,
      "#zhimin-choose:::" .. tostring(player.hp), self.name, false)
      local to, card, n
      local toObtain = {}
      for _, pid in ipairs(targets) do
        to = room:getPlayerById(pid)
        local cards = {}
        for _, id in ipairs(to:getCardIds(Player.Hand)) do
          card = Fk:getCardById(id)
          if #cards == 0 then
            table.insert(cards, id)
            n = card.number
          else
            if n > card.number then
              n = card.number
              cards = {id}
            elseif n == card.number then
              table.insert(cards, id)
            end
          end
        end
        if #cards > 0 then
          table.insert(toObtain, table.random(cards))
        end
      end
      if #toObtain > 0 then
        room:moveCardTo(toObtain, Player.Hand, player, fk.ReasonPrey, self.name, "", false, player.id)
      end
    end
  end,
}
local jujianc = fk.CreateActiveSkill{
  name = "jujianc$",
  anim_type = "support",
  prompt = "#jujianc-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select).kingdom == "wei"
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:drawCards(target, 1, self.name)
    if player.dead or target.dead then return end
    local mark = target:getTableMark("@@jujianc-round")
    table.insert(mark, player.id)
    room:setPlayerMark(target, "@@jujianc-round", mark)
  end,
}
local jujianc_delay = fk.CreateTriggerSkill{
  name = "#jujianc_delay",
  events = {fk.PreCardEffect},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player.id == data.to and data.card:isCommonTrick() and target and
    table.contains(target:getTableMark("@@jujianc-round"), player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(jujianc.name)
    return true
  end,
}
jujianc:addRelatedSkill(jujianc_delay)
caofang:addSkill(zhimin)
caofang:addSkill(jujianc)

Fk:loadTranslationTable{
  ["caofang"] = "曹芳",
  ["#caofang"] = "迷瞑终觉",
  ["cv:caofang"] = "陆泊云",
  ["illustrator:caofang"] = "鬼画府",

  ["zhimin"] = "置民",
  [":zhimin"] = "锁定技，每轮开始时，你选择至多X名其他角色（x为你的体力值），获得这些角色点数最小的一张手牌。"..
  "你于回合外得到牌后，这些牌称为“民”。当你失去“民”后，你将手牌补至体力上限。",
  ["jujianc"] = "拒谏",
  [":jujianc"] = "主公技，出牌阶段限一次，你可以令一名其他魏势力角色摸一张牌，直到本轮结束，其使用的普通锦囊牌对你无效。",
  ["#jujianc-active"] = "发动 拒谏，令一名其他魏势力角色摸一张牌，其本轮内使用普通锦囊牌对你无效",
  ["#zhimin-choose"] = "置民：选择1-%arg名角色，获得这些角色手牌中点数最小的牌",
  ["@@zhimin-inhand"] = "民",
  ["@@jujianc-round"] = "拒谏",
  ["#jujianc_delay"] = "拒谏",

  ["$zhimin1"] = "渤海虽阔，亦不及朕胸腹之广。",
  ["$zhimin2"] = "民众渡海而来，当筑梧居相待。",
  ["$jujianc1"] = "尔等眼中，只见到朕的昏庸吗？",
  ["$jujianc2"] = "我做天子，不得自在邪？",
  ["~caofang"] = "匹夫无罪，怀璧其罪……",
}

local zhupeilan = General(extension, "zhupeilan", "wu", 3, 3, General.Female)
local cilv = fk.CreateTriggerSkill{
  name = "cilv",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card:isCommonTrick() and not table.every({1,2,3}, function (i)
      return player:getMark("cilv" .. tostring(i)) > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local nums = table.filter({1,2,3}, function (i)
      return player:getMark("cilv" .. tostring(i)) == 0
    end)
    player:drawCards(#nums, self.name)
    if player.dead or player:getHandcardNum() <= player.maxHp then return false end
    local all_choices = {"cilv1", "cilv2", "cilv3"}
    local choices = table.filter(all_choices, function (choice)
      return player:getMark(choice) == 0
    end)
    if #choices == 0 then return false end
    local choice = room:askForChoice(player, choices, self.name, "#cilv-choose:::"..data.card:toLogString(), false, all_choices)
    room:setPlayerMark(player, choice, 1)
    if choice == "cilv1" then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    elseif choice == "cilv2" then
      data.extra_data = data.extra_data or {}
      data.extra_data.cilv_defensive = data.extra_data.cilv_defensive or {}
      table.insert(data.extra_data.cilv_defensive, player.id)
    elseif choice == "cilv3" then
      data.extra_data = data.extra_data or {}
      data.extra_data.cilv_recycle = data.extra_data.cilv_recycle or {}
      table.insert(data.extra_data.cilv_recycle, player.id)
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "cilv1", 0)
    room:setPlayerMark(player, "cilv2", 0)
    room:setPlayerMark(player, "cilv3", 0)
  end,
}
local cilv_delay = fk.CreateTriggerSkill{
  name = "#cilv_delay",
  mute = true,
  events = {fk.CardUseFinished, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if event == fk.CardUseFinished then
      return data.extra_data and data.extra_data.cilv_recycle and table.contains(data.extra_data.cilv_recycle, player.id) and
      player.room:getCardArea(data.card) == Card.Processing
    elseif event == fk.DamageCaused then
      if data.card then
        local card_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if not card_event then return false end
        local use = card_event.data[1]
        return use.extra_data and use.extra_data.cilv_defensive and table.contains(use.extra_data.cilv_defensive, player.id)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove, player.id, "cilv")
    else
      return true
    end
  end,
}
local tongdao = fk.CreateTriggerSkill{
  name = "tongdao",
  anim_type = "support",
  events = {fk.AskForPeaches},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      data.who == player.id and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, "#tongdao-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local skills = {}
    for _, s in ipairs(to.player_skills) do
      if s:isPlayerSkill(to) then
        table.insertIfNeed(skills, s.name)
      end
    end
    if room.settings.gameMode == "m_1v2_mode" and to.role == "lord" then
      table.removeOne(skills, "m_feiyang")
      table.removeOne(skills, "m_bahu")
    end
    if #skills > 0 then
      room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
    end
    skills = Fk.generals[to.general]:getSkillNameList(true)
    if to.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[to.deputyGeneral]:getSkillNameList(true))
    end
    local skill
    if not (room:isGameMode("role_mode") and
    to.role_shown and to.role == "lord") then
      skills = table.filter(skills, function (skill_name)
        skill = Fk.skills[skill_name]
        return not skill.lordSkill
      end)
    end
    if #skills > 0 then
      --需要重置限定技、觉醒技、转换技、使命技
      for _, skill_name in ipairs(skills) do
        skill = Fk.skills[skill_name]
        if skill.frequency == Skill.Quest then
          room:setPlayerMark(to, MarkEnum.QuestSkillPreName .. skill_name, 0)
        end
        if skill.switchSkillName then
          room:setPlayerMark(to, MarkEnum.SwithSkillPreName .. skill_name, fk.SwitchYang)
        end
        to:setSkillUseHistory(skill_name, 0, Player.HistoryPhase)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryTurn)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryRound)
        to:setSkillUseHistory(skill_name, 0, Player.HistoryGame)
      end
      room:handleAddLoseSkills(to, table.concat(skills, "|"), nil, true, false)
    end
    if not (player.dead or target.dead) and player:isWounded() and player.hp < to.hp then
      room:recover {
        who = player,
        num = to.hp - player.hp,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
cilv:addRelatedSkill(cilv_delay)
zhupeilan:addSkill(cilv)
zhupeilan:addSkill(tongdao)
Fk:loadTranslationTable{
  ["zhupeilan"] = "朱佩兰",
  ["#zhupeilan"] = "景皇后",
  --["designer:zhupeilan"] = "",
  ["illustrator:zhupeilan"] = "匠人绘",

  ["cilv"] = "辞虑",
  [":cilv"] = "当你成为普通锦囊牌的目标后，你可以摸X张牌（X为此技能的剩余选项数），"..
  "若你的手牌数大于你的体力上限，你选择并移除一项："..
  "1.此牌对你无效；2.此牌造成伤害时防止之；3.此牌结算结束后你获得之。",
  ["tongdao"] = "痛悼",
  [":tongdao"] = "限定技，当你处于濒死状态时，你可以选择一名角色，其失去所有技能，其获得其武将牌上的所有技能，"..
  "你回复体力至X点（X为其体力值）。",

  ["#tongdao-choose"] = "是否发动 痛悼，选择一名角色，令其技能还原为初始状态，并回复体力至与该角色相同",
  ["#cilv-choose"] = "辞虑：选择一项对%arg执行，然后移除此项",
  ["cilv1"] = "此牌对你无效",
  ["cilv2"] = "防止此牌造成伤害",
  ["cilv3"] = "此牌结算后你获得之",
  ["#cilv_delay"] = "辞虑",

  ["$cilv1"] = "妾一介女流，安知社稷之虑。",
  ["$cilv2"] = "若家国无损、宗庙得续，我无异议。",
  ["$tongdao1"] = "安定宫无一丈之长，恐难七步成诗。",
  ["$tongdao2"] = "故峻恶，皓恶甚于峻。",
  ["~zhupeilan"] = "生如浮萍，随波而逝……",
}

local bianyue = General(extension, "bianyue", "wei", 3, 3, General.Female)
local bizu = fk.CreateActiveSkill{
  name = "bizu",
  anim_type = "support",
  prompt = function()
    local x = Self:getHandcardNum()
    local tos = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:getHandcardNum() == x then
        table.insert(tos, p.id)
      end
    end
    local mark = Self:getTableMark("bizu_targets-turn")
    if table.find(mark, function(tos2)
      return #tos == #tos2 and table.every(tos, function(pid)
        return table.contains(tos2, pid)
      end)
    end) then
      return "#bizu-active-last"
    else
      return "#bizu-active"
    end
  end,
  card_num = 0,
  target_num = 0,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  target_tip = function(self, to_select, selected, selected_cards, card, selectable, extra_data)
    if Fk:currentRoom():getPlayerById(to_select):getHandcardNum() == Self:getHandcardNum() then
      return { {content = "draw1", type = "normal"} }
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local x = player:getHandcardNum()
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return p:getHandcardNum() == x
    end)
    local tos = table.map(targets, Util.IdMapper)
    room:doIndicate(player.id, tos)
    local mark = player:getTableMark("bizu_targets-turn")
    if table.find(mark, function(tos2)
      return #tos == #tos2 and table.every(tos, function(pid)
        return table.contains(tos2, pid)
      end)
    end) then
      room:invalidateSkill(player, self.name, "-turn")
    else
      table.insert(mark, tos)
      room:setPlayerMark(player, "bizu_targets-turn", mark)
    end
    for _, p in ipairs(targets) do
      if p:isAlive() then
        room:drawCards(p, 1, self.name)
      end
    end
  end,
}
local wuxie = fk.CreateTriggerSkill{
  name = "wuxie",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Play and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, 
    "#wuxie-cost", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local card
    local cards = table.filter(player:getCardIds(Player.Hand), function (id)
      card = Fk:getCardById(id)
      return card.is_damage_card
    end)
    local x = #cards
    if x > 0 then
      table.shuffle(cards)
      room:moveCards{
        ids = cards,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = -1,
        moveVisible = false,
      }
    end
    local y = 0
    if not to.dead then
      cards = table.filter(to:getCardIds(Player.Hand), function (id)
        card = Fk:getCardById(id)
        return card.is_damage_card
      end)
      y = #cards
      if y > 0 then
        table.shuffle(cards)
        room:moveCards{
          ids = cards,
          from = to.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
          drawPilePosition = -1,
          moveVisible = false,
        }
      end
    end
    if player.dead then return false end
    local targets = {}
    if x > y then
      if not player:isWounded() then return false end
      targets = {player.id}
    elseif x == y then
      if player:isWounded() then
        targets = {player.id}
      end
      if not to.dead and to:isWounded() then
        table.insert(targets, to.id)
      end
      if #targets == 0 then return false end
    else
      if to.dead or not to:isWounded() then return false end
      targets = {to.id}
    end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#wuxie-recover", self.name, true)
    if #tos > 0 then
      room:recover({
        who = room:getPlayerById(tos[1]),
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
bianyue:addSkill(bizu)
bianyue:addSkill(wuxie)
Fk:loadTranslationTable{
  ["bianyue"] = "卞玥",
  ["#bianyue"] = "暮辉映族",
  --["designer:bianyue"] = "",
  ["illustrator:bianyue"] = "黯荧岛",

  ["bizu"] = "庇族",
  [":bizu"] = "出牌阶段，你可以选择手牌数与你相等的所有角色，这些角色各摸一张牌，"..
  "若这些角色与你此前于此回合内发动此技能时选择的角色完全相同，此技能于此回合内无效。",
  ["wuxie"] = "无胁",
  [":wuxie"] = "出牌阶段结束时，你可以选择一名其他角色，你与其各将手牌区中的所有伤害类牌随机置于牌堆底，"..
  "你可以令以此法失去牌较多的角色回复1点体力。",

  ["#bizu-active"] = "发动 庇族，令所有手牌数与你相同的角色各摸一张牌（未重复目标）",
  ["#bizu-active-last"] = "发动 庇族，令所有手牌数与你相同的角色各摸一张牌（技能无效）",
  ["#wuxie-cost"] = "是否发动 无胁，选择一名其他角色，将你与该角色手牌中的所有伤害牌放到牌堆底",
  ["#wuxie-recover"] = "无胁：可以令一名角色回复1点体力",

  ["$bizu1"] = "花既繁于枝，当为众乔灌荫。",
  ["$bizu2"] = "手执金麾伞，可为我族遮风挡雨。",
  ["$wuxie1"] = "一个弱质女流，安能登辇拔剑？",
  ["$wuxie2"] = "主上既亡，我当为生者计。",
  ["~bianyue"] = "空怀悲怆之心，未有杀贼之力……",
}

local ganfuren = General(extension, "ty__ganfuren", "shu", 3, 3, General.Female)
local ty__shushen = fk.CreateTriggerSkill{
  name = "ty__shushen",
  anim_type = "support",
  events = {fk.HpRecover},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.num do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#ty__shushen-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local choices = {"ty__shushen_draw"}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name, "#ty__shushen-choice::"..to.id)
    if choice == "ty__shushen_draw" then
      player:drawCards(1, self.name)
      to:drawCards(1, self.name)
    else
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ty__shenzhi = fk.CreateTriggerSkill{
  name = "ty__shenzhi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:getHandcardNum() > player.hp and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#ty__shenzhi-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
ganfuren:addSkill(ty__shushen)
ganfuren:addSkill(ty__shenzhi)
Fk:loadTranslationTable{
  ["ty__ganfuren"] = "甘夫人",
  ["#ty__ganfuren"] = "昭烈皇后",
  ["illustrator:ty__ganfuren"] = "胖虎饭票",

  ["ty__shushen"] = "淑慎",
  [":ty__shushen"] = "当你回复1点体力后，你可以选择一名其他角色，令其回复1点体力或与其各摸一张牌。",
  ["ty__shenzhi"] = "神智",
  [":ty__shenzhi"] = "准备阶段，若你手牌数大于体力值，你可以弃置一张手牌并回复1点体力。",
  ["#ty__shushen-choose"] = "淑慎：你可以令一名其他角色回复1点体力或与其各摸一张牌",
  ["#ty__shushen-choice"] = "淑慎：选择令 %dest 执行的一项",
  ["ty__shushen_draw"] = "各摸一张牌",
  ["#ty__shenzhi-invoke"] = "神智：你可以弃置一张手牌，回复1点体力",

  ["$ty__shushen1"] = "妾身无恙，相公请安心征战。",
  ["$ty__shushen2"] = "船到桥头自然直。",
  ["$ty__shenzhi1"] = "子龙将军，一切都托付给你了。",
  ["$ty__shenzhi2"] = "阿斗，相信妈妈，没事的。",
  ["~ty__ganfuren"] = "请替我照顾好阿斗……",
}

local mifuren = General(extension, "ty__mifuren", "shu", 3, 3, General.Female)
local ty__guixiu = fk.CreateTriggerSkill{
  name = "ty__guixiu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart, fk.AfterSkillEffect},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TurnStart then
        return player:getMark(self.name) == 0
      else
        return data.name == "ty__cunsi" and player:isWounded()
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      player:drawCards(2, self.name)
      room:setPlayerMark(player, self.name, 1)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local ty__cunsi = fk.CreateActiveSkill{
  name = "ty__cunsi",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  prompt = "#ty__cunsi",
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
    room:handleAddLoseSkills(target, "ty__yongjue", nil, true, false)
    if target ~= player then
      player:drawCards(2, self.name)
    end
  end,
}
local ty__yongjue = fk.CreateTriggerSkill{
  name = "ty__yongjue",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.trueName == "slash" and
      player:usedCardTimes("slash", Player.HistoryPhase) == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#ty__yongjue-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"ty__yongjue_time"}
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "ty__yongjue_obtain")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "ty__yongjue_time" then
      player:addCardUseHistory(data.card.trueName, -1)
    else
      room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    end
  end,
}
mifuren:addSkill(ty__guixiu)
mifuren:addSkill(ty__cunsi)
mifuren:addRelatedSkill(ty__yongjue)
Fk:loadTranslationTable{
  ["ty__mifuren"] = "糜夫人",
  ["#ty__mifuren"] = "乱世沉香",
  ["illustrator:ty__mifuren"] = "鲨鱼嚼嚼",
  ["ty__guixiu"] = "闺秀",
  [":ty__guixiu"] = "锁定技，你获得此技能后的第一个回合开始时，你摸两张牌；当你发动〖存嗣〗后，你回复1点体力。",
  ["ty__cunsi"] = "存嗣",
  [":ty__cunsi"] = "限定技，出牌阶段，你可以令一名角色获得〖勇决〗；若不为你，你摸两张牌。",
  ["ty__yongjue"] = "勇决",
  [":ty__yongjue"] = "当你于出牌阶段内使用第一张【杀】时，你可以令其不计入使用次数或获得之。",
  ["#ty__cunsi"] = "存嗣：你可以令一名角色获得〖勇决〗，若不为你，你摸两张牌",
  ["#ty__yongjue-invoke"] = "勇决：你可以令此%arg不计入使用次数，或获得之",
  ["ty__yongjue_time"] = "不计入次数",
  ["ty__yongjue_obtain"] = "获得之",

  ["$ty__guixiu1"] = "闺楼独看花月，倚窗顾影自怜。",
  ["$ty__guixiu2"] = "闺中女子，亦可秀气英拔。",
  ["$ty__cunsi1"] = "存汉室之嗣，留汉室之本。",
  ["$ty__cunsi2"] = "一切，便托付将军了！",
  ["$ty__yongjue1"] = "能救一个是一个！",
  ["$ty__yongjue2"] = "扶幼主，成霸业！",
  ["~ty__mifuren"] = "阿斗被救，妾身……再无牵挂……",
}

local qinghegongzhu = General(extension, "ty__qinghegongzhu", "wei", 3, 3, General.Female)
local ty__zhangjiq = fk.CreateTriggerSkill{
  name = "ty__zhangjiq",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.BeforeCardUseEffect},  --FIXME: 睿智描述，先胡乱结算
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #TargetGroup:getRealTargets(data.tos) > 1 and
      table.contains(TargetGroup:getRealTargets(data.tos), player.id)
  end,
  on_use = function(self, event, target, player, data)
    local new_tos = {}
    for _, info in ipairs(data.tos) do
      if info[1] == player.id then
        table.insert(new_tos, info)
      end
    end
    for _, info in ipairs(data.tos) do
      if info[1] ~= player.id then
        table.insert(new_tos, info)
      end
    end
    data.tos = new_tos
    player:drawCards(#TargetGroup:getRealTargets(data.tos) - 1, self.name)
  end,
}
local ty__zengou = fk.CreateActiveSkill{
  name = "ty__zengou",
  anim_type = "control",
  min_card_num = 1,
  target_num = 1,
  prompt = function()
    return "#ty__zengou:::"..Self.maxHp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected < Self.maxHp
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = effect.cards
    room:setPlayerMark(target, "@@ty__zengou", 1)
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id, "@@ty__zengou-inhand")
    if not player.dead then
      player:drawCards(#cards, self.name)
    end
  end,
}
local ty__zengou_delay = fk.CreateTriggerSkill{
  name = "#ty__zengou_delay",
  mute = true,
  events = {fk.HpChanged, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("@@ty__zengou") > 0 then
      if event == fk.HpChanged then
        return data.num > 0
      else
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ty__zengou", 0)
    if player:isKongcheng() then return end
    local cards = player:getCardIds("h")
    local n = #table.filter(cards, function(id)
      return Fk:getCardById(id):getMark("@@ty__zengou-inhand") > 0
    end)
    player:showCards(cards)
    if player.dead or n == 0 then return end
    room:loseHp(player, n, "ty__zengou")
  end,
}
ty__zengou:addRelatedSkill(ty__zengou_delay)
qinghegongzhu:addSkill(ty__zhangjiq)
qinghegongzhu:addSkill(ty__zengou)
Fk:loadTranslationTable{
  ["ty__qinghegongzhu"] = "清河公主",
  ["#ty__qinghegongzhu"] = "大魏长公主",
  ["illustrator:ty__qinghegongzhu"] = "七兜豆",
  ["~ty__qinghegongzhu"] = "夏侯楙，不能和好，为何不和离？",

  ["ty__zhangjiq"] = "长姬",
  [":ty__zhangjiq"] = "锁定技，一张牌指定包括你在内的多名角色为目标时，先结算对你产生的效果，然后你摸X张牌（X为剩余目标数）。",
  ["ty__zengou"] = "谮构",
  [":ty__zengou"] = "出牌阶段限一次，你可以交给一名其他角色至多你体力上限张牌并摸等量的牌，若如此做，其下次体力值增加或使用牌后展示所有手牌，"..
  "每有一张“谮构”牌，其失去1点体力。",
  ["#ty__zengou"] = "谮构：交给一名角色至多%arg张牌并摸等量牌，其下次体力增加或使用牌后失去体力",
  ["@@ty__zengou"] = "谮构",
  ["@@ty__zengou-inhand"] = "谮构",

  ["$ty__zhangjiq1"] = "功赏过惩，此魏武所教我者。",
  ["$ty__zhangjiq2"] = "长公主之言，谁敢不从？",
  ["$ty__zengou1"] = "既已同床异梦，休怪妾身无情。",
  ["$ty__zengou2"] = "我所恨者，唯夏侯子林一人耳。",
}

--往者可谏：大乔小乔 SP马超 SP赵云 SP甄姬 SP孙策
local zhenji = General(extension, "ty_sp__zhenji", "qun", 3, 3, General.Female)
local jijiez = fk.CreateTriggerSkill{
  name = "jijiez",
  events = {fk.AfterCardsMove, fk.HpRecover},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        if player:getMark("jijiez_draw-turn") > 0 then return false end
        local ban_players = {player.id}
        if player.room.current.phase ~= Player.NotActive then
          table.insert(ban_players, player.room.current.id)
        end
        local x = 0
        for _, move in ipairs(data) do
          if move.to and not table.contains(ban_players, move.to) and move.toArea == Card.PlayerHand then
            x = x + #move.moveInfo
          end
        end
        if x > 0 then
          self.cost_data = x
          return true
        end
      elseif event == fk.HpRecover then
        return player:getMark("jijiez_recover-turn") == 0 and player:isWounded() and
        target ~= player and target.phase == Player.NotActive
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:setPlayerMark(player, "jijiez_draw-turn", 1)
      player:drawCards(self.cost_data, self.name)
    elseif event == fk.HpRecover then
      room:notifySkillInvoked(player, self.name, "support")
      room:setPlayerMark(player, "jijiez_recover-turn", 1)
      room:recover{
        who = player,
        num = data.num,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,

  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "jijiez_draw-turn", 0)
    room:setPlayerMark(player, "jijiez_recover-turn", 0)
  end,
}
local huiji__amazingGraceSkill = fk.CreateActiveSkill{
  name = "huiji__amazing_grace_skill",
  prompt = "#amazing_grace_skill",
  can_use = Util.GlobalCanUse,
  on_use = Util.GlobalOnUse,
  mod_target_filter = Util.TrueFunc,
  on_action = function(self, room, use, finished)
    local player = room:getPlayerById(use.from)
    if not finished then
      local toDisplay = player:getCardIds(Player.Hand)
      room:moveCardTo(toDisplay, Card.Processing, nil, fk.ReasonJustMove, "amazing_grace_skill", "", true, player.id)

      table.forEach(room.players, function(p)
        room:fillAG(p, toDisplay)
      end)

      use.extra_data = use.extra_data or {}
      use.extra_data.AGFilled = toDisplay
    else
      if use.extra_data and use.extra_data.AGFilled then
        table.forEach(room.players, function(p)
          room:closeAG(p)
        end)

        local toDiscard = table.filter(use.extra_data.AGFilled, function(id)
          return room:getCardArea(id) == Card.Processing
        end)

        if #toDiscard > 0 then
          if player.dead then
            room:moveCards({
              ids = toDiscard,
              toArea = Card.DiscardPile,
              moveReason = fk.ReasonPutIntoDiscardPile,
            })
          else
            room:moveCardTo(toDiscard, Card.PlayerHand, player, fk.ReasonJustMove, "amazing_grace_skill", "", true, player.id)
          end
        end
      end

      use.extra_data.AGFilled = nil
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if not (effect.extra_data and effect.extra_data.AGFilled and #effect.extra_data.AGFilled > 0) then
      return
    end

    local chosen = room:askForAG(to, effect.extra_data.AGFilled, false, "amazing_grace_skill")
    room:takeAG(to, chosen, room.players)
    room:obtainCard(effect.to, chosen, true, fk.ReasonPrey)
    table.removeOne(effect.extra_data.AGFilled, chosen)
  end,
}
huiji__amazingGraceSkill.cardSkill = true
Fk:addSkill(huiji__amazingGraceSkill)
local huiji = fk.CreateActiveSkill{
  name = "huiji",
  target_num = 1,
  card_num = 0,
  prompt = "#huiji-active",
  anim_type = "control",
  interaction = function()
    return UI.ComboBox {
      choices = {"draw2", "huiji_equip"}
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if self.interaction.data == "draw2" then
      target:drawCards(2, self.name)
    else
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        if card.type == Card.TypeEquip and target:canUseTo(card, target) then
          table.insertIfNeed(cards, card)
        end
      end
      if #cards > 0 then
        room:useCard{
          from = target.id,
          card = cards[math.random(1, #cards)],
          tos = {{target.id}},
        }
      end
    end
    if target.dead or target:getHandcardNum() < #room.alive_players then return end
    local amazing_grace = Fk:cloneCard("amazing_grace")
    amazing_grace.skillName = self.name
    if target:prohibitUse(amazing_grace) or table.every(room.alive_players, function (p)
      return target:isProhibited(p, amazing_grace)
    end) then return end
    amazing_grace.skill = huiji__amazingGraceSkill
    room:useCard{
      from = target.id,
      card = amazing_grace
    }
  end,
}
zhenji:addSkill(jijiez)
zhenji:addSkill(huiji)
Fk:loadTranslationTable{
  ["ty_sp__zhenji"] = "甄姬",
  ["#ty_sp__zhenji"] = "善言贤女",
  ["illustrator:ty_sp__zhenji"] = "匠人绘",

  ["jijiez"] = "己诫",
  [":jijiez"] = "锁定技，每回合各限一次，当其他角色于其回合外得到牌后/回复体力后，你摸等量的牌/回复等量的体力。",
  ["huiji"] = "惠济",
  [":huiji"] = "出牌阶段限一次，你可以令一名角色摸两张牌或使用牌堆中的一张随机装备牌。若其手牌数不小于存活角色数，"..
  "其视为使用【五谷丰登】（改为从该角色的手牌中挑选）。",

  ["#huiji-active"] = "发动 惠济，选择一名角色",
  ["huiji_equip"] = "使用装备",

  ["$jijiez1"] = "闻古贤女，未有不学前世成败者。",
  ["$jijiez2"] = "不知书，何由见之。",
  ["$huiji1"] = "云鬓释远，彩衣婀娜。",
  ["$huiji2"] = "明眸善睐，瑰姿艳逸。",
  ["~ty_sp__zhenji"] = "自古英雄迟暮，谁见佳人白头？",
}

--章台春望：郭照 樊玉凤 阮瑀 杨婉 潘淑
local guozhao = General(extension, "guozhao", "wei", 3, 3, General.Female)
local pianchong = fk.CreateTriggerSkill{
  name = "pianchong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local color = Card.NoColor
    for _, id in ipairs(room.draw_pile) do
      local _color = Fk:getCardById(id).color
      if _color ~= color and _color ~= Card.NoColor then
        color = _color
        table.insert(cards, id)
        if #cards == 2 then break end
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
        moveVisible = true,
      })
    end
    local choice = room:askForChoice(player, {"red", "black"}, self.name, "#pianchong-choice")
    room:addTableMarkIfNeed(player, "@pianchong", choice)
    return true
  end,
  
  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@pianchong") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@pianchong", 0)
  end,
}
local pianchong_delay = fk.CreateTriggerSkill{
  name = "#pianchong_delay",
  mute = true,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    local colors = player:getTableMark("@pianchong")
    if #colors == 0 then return false end
    local x, y = 0, 0
    local color
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            color = Fk:getCardById(info.cardId).color
            if color == Card.Red then
              x = x + 1
            elseif color == Card.Black then
              y = y + 1
            end
          end
        end
      end
    end
    if not table.contains(colors, "red") then
      x = 0
    end
    if not table.contains(colors, "black") then
      y = 0
    end
    if x > 0 or y > 0 then
      self.cost_data = {x, y}
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x, y = table.unpack(self.cost_data)
    local color
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      color = Fk:getCardById(id).color
      if color == Card.Black then
        if x > 0 then
          x = x - 1
          table.insert(cards, id)
        end
      elseif color == Card.Red then
        if y > 0 then
          y = y - 1
          table.insert(cards, id)
        end
      end
      if x == 0 and y == 0 then break end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = pianchong.name,
        moveVisible = true,
      })
    end
  end,
}
local zunwei = fk.CreateActiveSkill{
  name = "zunwei",
  prompt = "#zunwei-active",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  interaction = function()
    local choices, all_choices = {}, {}
    for i = 1, 3 do
      local choice = "zunwei"..tostring(i)
      table.insert(all_choices, choice)
      if Self:getMark(choice) == 0 then
        table.insert(choices, choice)
      end
    end
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i)) == 0 then
          return true
        end
      end
    end
    return false
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return self.interaction.data and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choice = self.interaction.data
    if choice == "zunwei1" then
      local x = math.min(target:getHandcardNum() - player:getHandcardNum(), 5)
      if x > 0 then
        room:drawCards(player, x, self.name)
      end
    elseif choice == "zunwei2" then
      local subtypes = {
        Card.SubtypeWeapon,
        Card.SubtypeArmor,
        Card.SubtypeDefensiveRide,
        Card.SubtypeOffensiveRide,
        Card.SubtypeTreasure
      }
      local subtype
      local cards = {}
      local card
      while not (player.dead or target.dead) and
      #player.player_cards[Player.Equip] < #target.player_cards[Player.Equip] do
        while #subtypes > 0 do
          subtype = table.remove(subtypes, 1)
          if player:hasEmptyEquipSlot(subtype) then
            cards = table.filter(room.draw_pile, function (id)
              card = Fk:getCardById(id)
              return card.sub_type == subtype and U.canUseCardTo(room, player, player, card)
            end)
            if #cards > 0 then
              room:useCard{
                from = player.id,
                card = Fk:getCardById(cards[math.random(1, #cards)]),
              }
              break
            end
          end
        end
        if #subtypes == 0 then break end
      end
    elseif choice == "zunwei3" and player:isWounded() then
      local x = target.hp - player.hp
      if x > 0 then
      room:recover{
        who = player,
        num = math.min(player:getLostHp(), x),
        recoverBy = player,
        skillName = self.name}
      end
    end
    room:setPlayerMark(player, choice, 1)
  end,
}
pianchong:addRelatedSkill(pianchong_delay)
guozhao:addSkill(pianchong)
guozhao:addSkill(zunwei)
Fk:loadTranslationTable{
  ["guozhao"] = "郭照",
  ["#guozhao"] = "碧海青天",
  ["designer:guozhao"] = "世外高v狼",
  ["illustrator:guozhao"] = "杨杨和夏季",
  ["pianchong"] = "偏宠",
  [":pianchong"] = "摸牌阶段，你可以改为从牌堆获得红牌和黑牌各一张，然后选择一项直到你的下回合开始：1.你每失去一张红色牌时摸一张黑色牌，"..
  "2.你每失去一张黑色牌时摸一张红色牌。",
  ["zunwei"] = "尊位",
  [":zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；"..
  "2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同。",
  ["#pianchong_delay"] = "偏宠",
  ["@pianchong"] = "偏宠",
  ["#pianchong-choice"] = "偏宠：选择一种颜色，失去此颜色的牌时，摸另一种颜色的牌",
  ["#zunwei-active"] = "发动 尊位，选择一名其他角色并执行一项效果",
  ["zunwei1"] = "将手牌摸至与其相同（最多摸五张）",
  ["zunwei2"] = "使用装备至与其相同",
  ["zunwei3"] = "回复体力至与其相同",

  ["$pianchong1"] = "得陛下怜爱，恩宠不衰。",
  ["$pianchong2"] = "谬蒙圣恩，光授殊宠。",
  ["$zunwei1"] = "处尊居显，位极椒房。",
  ["$zunwei2"] = "自在东宫，及即尊位。",
  ["~guozhao"] = "我的出身，不配为后？",
}

local fanyufeng = General(extension, "fanyufeng", "qun", 3, 3, General.Female)
local bazhan = fk.CreateActiveSkill{
  name = "bazhan",
  anim_type = "switch",
  switch_skill_name = "bazhan",
  prompt = function ()
    return Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang and "#bazhan-Yang" or "#bazhan-Yin"
  end,
  target_num = 1,
  max_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 2 or 0
  end,
  min_card_num = function ()
    return (Self:getSwitchSkillState("bazhan", false) == fk.SwitchYang) and 1 or 0
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = function(self, to_select, selected)
    return #selected < self:getMaxCardNum() and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected_cards >= self:getMinCardNum() and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local isYang = player:getSwitchSkillState(self.name, true) == fk.SwitchYang

    local to_check = {}
    if isYang and #effect.cards > 0 then
      table.insertTable(to_check, effect.cards)
      room:obtainCard(target.id, to_check, false, fk.ReasonGive, player.id)
    elseif not isYang and not target:isKongcheng() then
      to_check = room:askForCardsChosen(player, target, 1, 2, "h", self.name)
      room:obtainCard(player, to_check, false, fk.ReasonPrey)
      target = player
    end
    if not player.dead and not target.dead and table.find(to_check, function (id)
    return Fk:getCardById(id).name == "analeptic" or Fk:getCardById(id).suit == Card.Heart end) then
      local choices = {"cancel"}
      if not target.faceup or target.chained then
        table.insert(choices, 1, "bazhan_reset")
      end
      if target:isWounded() then
        table.insert(choices, 1, "recover")
      end
      if #choices > 1 then
        local choice = room:askForChoice(player, choices, self.name, "#bazhan-support::" .. target.id)
        if choice == "recover" then
          room:recover{ who = target, num = 1, recoverBy = player, skillName = self.name }
        elseif choice == "bazhan_reset" then
          if not target.faceup then
            target:turnOver()
          end
          if target.chained then
            target:setChainState(false)
          end
        end
      end
    end
  end,
}
local jiaoying = fk.CreateTriggerSkill{
  name = "jiaoying",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
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
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local to = room:getPlayerById(move.to)
        local jiaoying_colors = type(to:getMark("jiaoying_colors-turn")) == "table" and to:getMark("jiaoying_colors-turn") or {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            local color = Fk:getCardById(info.cardId).color
            if color ~= Card.NoColor then
              table.insertIfNeed(jiaoying_colors, color)
              table.insertIfNeed(jiaoying_targets, to.id)
              if to:getMark("@jiaoying-turn") == 0 then
                room:setPlayerMark(to, "@jiaoying-turn", {})
              end
            end
          end
        end
        room:setPlayerMark(to, "jiaoying_colors-turn", jiaoying_colors)
      end
    end
    room:setPlayerMark(player, "jiaoying_targets-turn", jiaoying_targets)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    return table.contains(jiaoying_targets, target.id) and not table.contains(jiaoying_ignores, target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
    table.insert(jiaoying_ignores, target.id)
    player.room:setPlayerMark(player, "jiaoying_ignores-turn", jiaoying_ignores)
    player.room:setPlayerMark(target, "@jiaoying-turn", {"jiaoying_usedcard"})
  end,
}
local jiaoying_delay = fk.CreateTriggerSkill{
  name = "#jiaoying_delay",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish then
      local jiaoying_targets = type(player:getMark("jiaoying_targets-turn")) == "table" and player:getMark("jiaoying_targets-turn") or {}
      local jiaoying_ignores = type(player:getMark("jiaoying_ignores-turn")) == "table" and player:getMark("jiaoying_ignores-turn") or {}
      self.cost_data = #jiaoying_targets - #jiaoying_ignores
      if self.cost_data > 0 then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    local targets = player.room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < 5 end), Util.IdMapper), 1, x, "#jiaoying-choose:::" .. x, self.name, true)
    if #targets > 0 then
      room:sortPlayersByAction(targets)
      for _, pid in ipairs(targets) do
        local to = room:getPlayerById(pid)
        if not to.dead and to:getHandcardNum() < 5 then
          to:drawCards(5-to:getHandcardNum(), self.name)
        end
      end
    end
  end,
}
local jiaoying_prohibit = fk.CreateProhibitSkill{
  name = "#jiaoying_prohibit",
  prohibit_use = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
  prohibit_response = function(self, player, card)
    local jiaoying_colors = player:getMark("jiaoying_colors-turn")
    return type(jiaoying_colors) == "table" and table.contains(jiaoying_colors, card.color)
  end,
}
jiaoying:addRelatedSkill(jiaoying_delay)
jiaoying:addRelatedSkill(jiaoying_prohibit)
fanyufeng:addSkill(bazhan)
fanyufeng:addSkill(jiaoying)
Fk:loadTranslationTable{
  ["fanyufeng"] = "樊玉凤",
  ["#fanyufeng"] = "红鸾寡宿",
  ["cv:fanyufeng"] = "杨子怡",
  ["illustrator:fanyufeng"] = "匠人绘",
  ["bazhan"] = "把盏",
  [":bazhan"] = "转换技，出牌阶段限一次，阳：你可以交给一名其他角色至多两张手牌；阴：你可以获得一名其他角色至多两张手牌。"..
  "然后若这些牌里包括【酒】或<font color='red'>♥</font>牌，你可令获得此牌的角色回复1点体力或复原武将牌。",
  ["jiaoying"] = "醮影",
  ["#jiaoying_delay"] = "醮影",
  [":jiaoying"] = "锁定技，其他角色获得你的手牌后，该角色本回合不能使用或打出与此牌颜色相同的牌。然后此回合结束阶段，"..
  "若其本回合没有再使用牌，你令一名角色将手牌摸至五张。",
  ["#bazhan-Yang"] = "把盏（阳）：选择一至两张手牌，交给一名其他角色",
  ["#bazhan-Yin"] = "把盏（阴）：选择一名有手牌的其他角色，获得其一至两张手牌",
  ["#bazhan-support"] = "把盏：可以选择令 %dest 回复1点体力或复原武将牌",
  ["#jiaoying-choose"] = "醮影：可选择至多%arg名角色将手牌补至5张",
  ["@jiaoying-turn"] = "醮影",
  ["jiaoying_usedcard"] = "使用过牌",

  ["$bazhan1"] = "此酒，当配将军。",
  ["$bazhan2"] = "这杯酒，敬于将军。",
  ["$jiaoying1"] = "独酌清醮，霓裳自舞。",
  ["$jiaoying2"] = "醮影倩丽，何人爱怜。",
  ["~fanyufeng"] = "醮妇再遇良人难……",
}

local ruanyu = General(extension, "ruanyu", "wei", 3)
local xingzuo = fk.CreateTriggerSkill{
  name = "xingzuo",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3, "bottom")
    local handcards = player:getCardIds(Player.Hand)
    local cardmap = room:askForArrangeCards(player, self.name,
    {cards, handcards, "Bottom", "$Hand"}, "#xingzuo-invoke")
    U.swapCardsWithPile(player, cardmap[1], cardmap[2], self.name, "Bottom")
  end,
}
local xingzuo_delay = fk.CreateTriggerSkill{
  name = "#xingzuo_delay",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
    player:usedSkillTimes(xingzuo.name, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xingzuo-choose", xingzuo.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(xingzuo.name)
    local to = room:getPlayerById(self.cost_data)
    local cards = to:getCardIds(Player.Hand)
    local n = #cards
    U.swapCardsWithPile(to, cards, room:getNCards(3, "bottom"), self.name, "Bottom")
    if n > 3 and not player.dead then
      room:loseHp(player, 1, xingzuo.name)
    end
  end,
}
local miaoxian = fk.CreateViewAsSkill{
  name = "miaoxian",
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#miaoxian",
  interaction = function()
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return false end
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(Self, "miaoxian", all_names, blackcards)
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return nil end
    local blackcards = table.filter(Self.player_cards[Player.Hand], function(id) return Fk:getCardById(id).color == Card.Black end)
    if #blackcards ~= 1 then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(blackcards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
  enabled_at_response = function(self, player, response)
    return not response and Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(self.pattern) and
      not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id).color == Card.Black end) == 1
  end,
}
local miaoxian_trigger = fk.CreateTriggerSkill{
  name = "#miaoxian_trigger",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and table.every(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color ~= Card.Red end) and data.card.color == Card.Red and
      not (data.card:isVirtual() and #data.card.subcards ~= 1)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, miaoxian.name, self.anim_type)
    player:broadcastSkillInvoke(miaoxian.name)
    player:drawCards(1, "miaoxian")
  end,
}
xingzuo:addRelatedSkill(xingzuo_delay)
miaoxian:addRelatedSkill(miaoxian_trigger)
ruanyu:addSkill(xingzuo)
ruanyu:addSkill(miaoxian)
Fk:loadTranslationTable{
  ["ruanyu"] = "阮瑀",
  ["#ruanyu"] = "斐章雅律",
  ["designer:ruanyu"] = "步穗",
  ["illustrator:ruanyu"] = "alien",
  ["xingzuo"] = "兴作",
  [":xingzuo"] = "出牌阶段开始时，你可观看牌堆底的三张牌并用任意张手牌替换其中等量的牌。若如此做，结束阶段，"..
  "你可以令一名有手牌的角色用所有手牌替换牌堆底的三张牌，然后若交换前该角色的手牌数大于3，你失去1点体力。",
  ["miaoxian"] = "妙弦",
  [":miaoxian"] = "每回合限一次，你可以将手牌中的唯一黑色牌当任意一张普通锦囊牌使用；当你使用手牌中的唯一红色牌时，你摸一张牌。",
  ["#xingzuo-invoke"] = "兴作：你可观看牌堆底的三张牌，并用任意张手牌替换其中等量的牌",
  ["#xingzuo_delay"] = "兴作",
  ["#xingzuo-choose"] = "兴作：你可以令一名角色用所有手牌替换牌堆底的三张牌，若交换前其手牌数大于3，你失去1点体力",
  ["#miaoxian_trigger"] = "妙弦",
  ["#miaoxian"] = "妙弦：将手牌中的黑色牌当任意锦囊牌使用",

  ["$xingzuo1"] = "顺人之情，时之势，兴作可成。",
  ["$xingzuo2"] = "兴作从心，相继不绝。",
  ["$miaoxian1"] = "女为悦者容，士为知己死。",
  ["$miaoxian2"] = "与君高歌，请君侧耳。",
  ["~ruanyu"] = "良时忽过，身为土灰。",
}

local yangwan = General(extension, "ty__yangwan", "shu", 3, 3, General.Female)
local youyan = fk.CreateTriggerSkill{
  name = "youyan",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and (player.phase == Player.Play or player.phase == Player.Discard) and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      local suits = {"spade", "club", "heart", "diamond"}
      local can_invoked = false
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                can_invoked = true
              end
            end
          else
            local room = player.room
            local parentPindianEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
            if parentPindianEvent then
              local pindianData = parentPindianEvent.data[1]
              if pindianData.from == player then
                local leftFromCardIds = room:getSubcardsByRule(pindianData.fromCard)
                for _, info in ipairs(move.moveInfo) do
                  if info.fromArea == Card.Processing and table.contains(leftFromCardIds, info.cardId) then
                    table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                    can_invoked = true
                  end
                end
              end
              for toId, result in pairs(pindianData.results) do
                if player.id == toId then
                  local leftToCardIds = room:getSubcardsByRule(result.toCard)
                  for _, info in ipairs(move.moveInfo) do
                    if info.fromArea == Card.Processing and table.contains(leftToCardIds, info.cardId) then
                      table.removeOne(suits, Fk:getCardById(info.cardId):getSuitString())
                      can_invoked = true
                    end
                  end
                end
              end
            end
          end
        end
      end
      if can_invoked and #suits > 0 then
        self.cost_data = suits
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = self.cost_data
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
local zhuihuan = fk.CreateTriggerSkill{
  name = "zhuihuan",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, "#zhuihuan-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player.room:getPlayerById(self.cost_data), self.name, 1)
  end,
}
local zhuihuan_delay = fk.CreateTriggerSkill{
  name = "#zhuihuan_delay",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:getMark("zhuihuan") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "zhuihuan", 0)
    local mark = player:getTableMark("zhuihuan_record")
    local targets = table.filter(room:getAlivePlayers(), function (p)
      return table.contains(mark, p.id)
    end)
    room:setPlayerMark(player, "zhuihuan_record", 0)
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not p.dead then
        if p.hp > player.hp then
          room:damage({
            from = player,
            to = p,
            damage = 2,
            damageType = fk.NormalDamage,
            skillName = "zhuihuan"
          })
        else
          local cards = table.filter(p:getCardIds(Player.Hand), function (id)
            return not p:prohibitDiscard(Fk:getCardById(id))
          end)
          cards = table.random(cards, 2)
          if #cards > 0 then
            room:throwCard(cards, "zhuihuan", p, p)
          end
        end
      end
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("zhuihuan") ~= 0 and data.from
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "zhuihuan_record", data.from.id)
  end,
}
zhuihuan:addRelatedSkill(zhuihuan_delay)
yangwan:addSkill(youyan)
yangwan:addSkill(zhuihuan)
Fk:loadTranslationTable{
  ["ty__yangwan"] = "杨婉",
  ["#ty__yangwan"] = "融沫之鲡",
  ["illustrator:ty__yangwan"] = "木美人",
  ["youyan"] = "诱言",
  [":youyan"] = "你的回合内，当你的牌因使用或打出之外的方式进入弃牌堆后，你可以从牌堆中获得本次弃牌中没有的花色的牌各一张（出牌阶段、弃牌阶段各限一次）。",
  ["zhuihuan"] = "追还",
  [":zhuihuan"] = "结束阶段，你可以秘密选择一名角色。直到该角色的下个准备阶段，此期间内对其造成过伤害的角色："..
  "若体力值大于该角色，则受到其造成的2点伤害；若体力值小于等于该角色，则随机弃置两张手牌。",
  ["#zhuihuan-choose"] = "追还：选择一名角色，直到其准备阶段，对此期间对其造成过伤害的角色造成伤害或弃牌",
  ["#zhuihuan_delay"] = "追还",

  ["$youyan1"] = "诱言者，为人所不齿。",
  ["$youyan2"] = "诱言之弊，不可不慎。",
  ["$zhuihuan1"] = "伤人者，追而还之！",
  ["$zhuihuan2"] = "追而还击，皆为因果。",
  ["~ty__yangwan"] = "遇人不淑……",
}

local panshu = General(extension, "ty__panshu", "wu", 3, 3, General.Female)
local zhiren = fk.CreateTriggerSkill{
  name = "zhiren",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and not data.card:isVirtual() and
    (player.phase ~= Player.NotActive or player:getMark("@@yaner") > 0) then
      local room = player.room
      local logic = room.logic
      local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local mark = player:getMark("zhiren_record-turn")
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data[1]
          if last_use.from == player.id and not last_use.card:isVirtual() then
            mark = e.id
            room:setPlayerMark(player, "zhiren_record-turn", mark)
            return true
          end
          return false
        end, Player.HistoryTurn)
      end
      return mark == use_event.id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:translate(data.card.trueName, "zh_CN"):len()
    room:askForGuanxing(player, room:getNCards(n), nil, nil, "", false)
    if n > 1 then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Equip] > 0 end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren1-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "e", self.name)
          room:throwCard({id}, self.name, to, player)
          if player.dead then return false end
        end
      end
      targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Judge] > 0 end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhiren2-choose", self.name, true)
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askForCardChosen(player, to, "j", self.name)
          room:throwCard({id}, self.name, to, player)
          if player.dead then return false end
        end
      end
    end
    if n > 2 then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
        if player.dead then return false end
      end
    end
    if n > 3 then
      room:drawCards(player, 3, self.name)
    end
  end,
}
local yaner = fk.CreateTriggerSkill{
  name = "yaner",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      local current = player.room.current
      if current == player or current.dead or current.phase ~= Player.Play or not current:isKongcheng() then
        return false
      end
      for _, move in ipairs(data) do
        if move.from == current.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#yaner-invoke::"..player.room.current.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room.current
    room:doIndicate(player.id, {to.id})
    local cards = player:drawCards(2, self.name)
    if #cards == 2 and Fk:getCardById(cards[1]).type == Fk:getCardById(cards[2]).type then
      room:setPlayerMark(player, "@@yaner", 1)
    end
    if to.dead then return false end
    cards = to:drawCards(2, self.name)
    if not to.dead and to:isWounded()
    and #cards == 2 and Fk:getCardById(cards[1]).type == Fk:getCardById(cards[2]).type then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yaner") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yaner", 0)
  end,
}
panshu:addSkill(zhiren)
panshu:addSkill(yaner)
Fk:loadTranslationTable{
  ["ty__panshu"] = "潘淑",
  ["#ty__panshu"] = "神女",
  ["designer:ty__panshu"] = "韩旭",
  ["illustrator:ty__panshu"] = "杨杨和夏季",
  ["zhiren"] = "织纴",
  [":zhiren"] = "你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；"..
  "不小于2，你可以弃置场上一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌名称字数）。",
  ["yaner"] = "燕尔",
  [":yaner"] = "每回合限一次，当其他角色于其出牌阶段内失去最后的手牌后，你可以与其各摸两张牌，然后若因此摸到相同类型的两张牌的角色为："..
  "你，〖织纴〗改为回合外也可以发动直到你的下个回合开始；其，其回复1点体力。",
  ["#zhiren1-choose"] = "织纴：你可以弃置场上一张装备牌",
  ["#zhiren2-choose"] = "织纴：你可以弃置场上一张延时锦囊牌",
  ["#yaner-invoke"] = "燕尔：你可以与 %dest 各摸两张牌，若摸到的牌类型形同则获得额外效果",
  ["@@yaner"] = "燕尔",

  ["$zhiren1"] = "穿针引线，栩栩如生。",
  ["$zhiren2"] = "纺绩织纴，布帛可成。",
  ["$yaner1"] = "如胶似漆，白首相随。",
  ["$yaner2"] = "新婚燕尔，亲睦和美。",
  ["~ty__panshu"] = "有喜必忧，以为深戒！",
}

--锦瑟良缘：曹金玉 孙翊 冯妤 来莺儿 曹华 张奋 诸葛梦雪 诸葛若雪 曹宪 柳婒 文鸳
local caojinyu = General(extension, "caojinyu", "wei", 3, 3, General.Female)
local yuqi = fk.CreateTriggerSkill{
  name = "yuqi",
  anim_type = "masochism",
  events = {fk.Damaged},
  times = function(self)
    return 2 - Self:usedSkillTimes(self.name)
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and player:usedSkillTimes(self.name) < 2 and
    (target == player or player:distanceTo(target) <= player:getMark("yuqi1"))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n1, n2, n3 = player:getMark("yuqi2") + 3, player:getMark("yuqi3") + 1, player:getMark("yuqi4") + 1
    if n1 < 2 and n2 < 1 and n3 < 1 then
      return false
    end
    local cards = U.turnOverCardsFromDrawPile(player, n1, self.name, false)
    local result = room:askForArrangeCards(player, self.name, {cards, "Top", target.general, player.general}, "#yuqi",
    false, 0, {n1, n2, n3}, {0, 1, 1})
    local top, bottom = result[2], result[3]
    local moveInfos = {}
    if #top > 0 then
      table.insert(moveInfos, {
        ids = top,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = self.name,
        moveVisible = false,
        visiblePlayers = player.id,
      })
    end
    if #bottom > 0 then
      table.insert(moveInfos, {
        ids = bottom,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        moveVisible = false,
        skillName = self.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    U.returnCardsToDrawPile(player, cards, self.name, true, false)
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    room:setPlayerMark(player, "yuqi1", 0)
    room:setPlayerMark(player, "yuqi2", 0)
    room:setPlayerMark(player, "yuqi3", 0)
    room:setPlayerMark(player, "yuqi4", 0)
    room:setPlayerMark(player, "@" .. self.name, {0, 3, 1, 1})
  end,
  on_lose = function (self, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "yuqi1", 0)
    room:setPlayerMark(player, "yuqi2", 0)
    room:setPlayerMark(player, "yuqi3", 0)
    room:setPlayerMark(player, "yuqi4", 0)
    room:setPlayerMark(player, "@" .. self.name, 0)
  end,
}
local function AddYuqi(player, skillName, num)
  local room = player.room
  local choices = {}
  local all_choices = {}
  local yuqi_initial = {0, 3, 1, 1}
  for i = 1, 4, 1 do
    table.insert(all_choices, "yuqi" .. tostring(i))
    if player:getMark("yuqi" .. tostring(i)) + yuqi_initial[i] < 5 then
      table.insert(choices, "yuqi" .. tostring(i))
    end
  end
  if #choices > 0 then
    local choice = room:askForChoice(player, choices, skillName, "#yuqi-upgrade:::" .. tostring(num), false, all_choices)
    room:setPlayerMark(player, choice, math.min(5-yuqi_initial[table.indexOf(all_choices, choice)], player:getMark(choice)+num))
    room:setPlayerMark(player, "@yuqi",
    {player:getMark("yuqi1"),
    player:getMark("yuqi2")+3,
    player:getMark("yuqi3")+1,
    player:getMark("yuqi4")+1})
  end
end
local shanshen = fk.CreateTriggerSkill{
  name = "shanshen",
  anim_type = "control",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    AddYuqi(player, self.name, 2)
    if player:isWounded() and #player.room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data[1]
      if damage.from == player and damage.to == target then
        return true
      end
    end, nil, 0) == 0 then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name,
      }
    end
  end,
}
local xianjing = fk.CreateTriggerSkill{
  name = "xianjing",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      local yuqi_initial = {0, 3, 1, 1}
      for i = 1, 4, 1 do
        if player:getMark("yuqi" .. tostring(i)) + yuqi_initial[i] < 5 then
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
caojinyu:addSkill(yuqi)
caojinyu:addSkill(shanshen)
caojinyu:addSkill(xianjing)
Fk:loadTranslationTable{
  ["caojinyu"] = "曹金玉",
  ["#caojinyu"] = "金乡公主",
  ["designer:caojinyu"] = "韩旭",
  ["illustrator:caojinyu"] = "MUMU",
  ["yuqi"] = "隅泣",
  [":yuqi"] = "每回合限两次，当一名角色受到伤害后，若你与其距离0或者更少，你可以观看牌堆顶的3张牌，将其中至多1张交给受伤角色，"..
  "至多1张自己获得，剩余的牌放回牌堆顶。",
  ["shanshen"] = "善身",
  [":shanshen"] = "当一名角色死亡时，你可令〖隅泣〗中的一个数字+2（单项不能超过5）。若你没有对其造成过伤害，你回复1点体力。",
  ["xianjing"] = "娴静",
  [":xianjing"] = "准备阶段，你可令〖隅泣〗中的一个数字+1（单项不能超过5）。若你满体力值，则再令〖隅泣〗中的一个数字+1。",
  ["@yuqi"] = "隅泣",
  ["#yuqi-upgrade"] = "选择令〖隅泣〗中的一个数字+%arg",
  ["yuqi1"] = "距离",
  ["yuqi2"] = "观看牌数",
  ["yuqi3"] = "交给受伤角色牌数",
  ["yuqi4"] = "自己获得牌数",
  ["#yuqi"] = "隅泣：请分配卡牌，余下的牌置于牌堆顶",

  ["$yuqi1"] = "孤影独泣，困于隅角。",
  ["$yuqi2"] = "向隅而泣，黯然伤感。",
  ["$shanshen1"] = "好善为德，坚守本心。",
  ["$shanshen2"] = "洁身自爱，独善其身。",
  ["$xianjing1"] = "文静娴丽，举止柔美。",
  ["$xianjing2"] = "娴静淡雅，温婉穆穆。",
  ["~caojinyu"] = "平叔之情，吾岂不明。",
}

local sunyi = General(extension, "ty__sunyi", "wu", 5)
local jiqiaos = fk.CreateTriggerSkill{
  name = "jiqiaos",
  anim_type = "drawcard",
  derived_piles = "jiqiaos",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, player.room:getNCards(player.maxHp), true, self.name)
  end,
}
local jiqiaos_trigger = fk.CreateTriggerSkill{
  name = "#jiqiaos_trigger",
  anim_type = "drawcard",
  mute = true,
  events = {fk.EventPhaseEnd, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and #player:getPile("jiqiaos") > 0 then
      if event == fk.EventPhaseEnd then
        return player.phase == Player.Play
      elseif event == fk.CardUseFinished then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
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
      room:notifySkillInvoked(player, "jiqiaos")
      player:broadcastSkillInvoke("jiqiaos")
      local cards = player:getPile("jiqiaos")
      if #cards == 0 then return false end
      local id = room:askForCardChosen(player, player, {
        card_data = {
          { "jiqiaos", cards }
        }
      }, "jiqiaos")
      room:obtainCard(player, id, true, fk.ReasonJustMove)
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
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#xiongyis1-invoke:::"..tostring(math.min(3, player.maxHp))
    if table.find(player.room.alive_players, function(p)
      return Fk.generals[p.general].trueName == "xushi"
      or (Fk.generals[p.deputyGeneral] and Fk.generals[p.deputyGeneral].trueName == "xushi") end)
    then
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
      U.changeHero(player, "xushi", false)
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
  ["#ty__sunyi"] = "虓风快意",
  ["designer:ty__sunyi"] = "七哀",
  ["illustrator:ty__sunyi"] = "君桓文化",
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

  ["$jiqiaos1"] = "为将者，当躬冒矢石！",
  ["$jiqiaos2"] = "吾承父兄之志，危又何惧？",
  ["$xiongyis1"] = "此仇不报，吾恨难消！",
  ["$xiongyis2"] = "功业未立，汝可继之！",
  ["$hunzi_ty__sunyi1"] = "身临绝境，亦当心怀壮志！",
  ["$hunzi_ty__sunyi2"] = "危难之时，自当振奋以对！",
  ["$ex__yingzi_ty__sunyi"] = "骁悍果烈，威震江东！",
  ["$yinghun_ty__sunyi"] = "兄弟齐心，以保父兄基业！",
  ["~ty__sunyi"] = "功业未成而身先死，惜哉，惜哉！",
}

local fengyu = General(extension, "ty__fengfangnv", "qun", 3, 3, General.Female)
local tiqi = fk.CreateTriggerSkill{
  name = "tiqi",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if
      not (
        player:hasSkill(self) and
        player ~= target and
        target and
        not target.dead
        and target:getMark("tiqi-turn") ~= 2 and
        player:usedSkillTimes(self.name) < 1
      )
    then
      return false
    end

    if data.to == Player.Play or data.to == Player.Discard or data.to == Player.Finish then
      --FIXME:无法判断是否处于额外阶段@Ho-spair
      return
        target.skipped_phases[Player.Draw] or
        #player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
          return e.data[2] == Player.Draw
        end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.abs(target:getMark("tiqi-turn") - 2)
    player:drawCards(n, self.name)
    local choice = room:askForChoice(player, {"tiqi_add", "tiqi_minus", "Cancel"}, self.name,
      "#tiqi-choice::" .. target.id .. ":" .. tostring(n))
    if choice == "tiqi_add" then
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, n)
    elseif choice == "tiqi_minus" then
      room:addPlayerMark(target, MarkEnum.MinusMaxCardsInTurn, n)
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Draw
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player.id and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        player.room:addPlayerMark(player, "tiqi-turn", #move.moveInfo)
      end
    end
  end,
}
local baoshu = fk.CreateTriggerSkill{
  name = "baoshu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), Util.IdMapper), 1, player.maxHp, "#baoshu-choose", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player.maxHp - #self.cost_data + 1
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:addPlayerMark(p, "@fengyu_shu", x)
        if p.chained then
          p:setChainState(false)
        end
      end
    end
  end,
}
local baoshu_delay = fk.CreateTriggerSkill{
  name = "#baoshu_delay",
  anim_type = "drawcard",
  events = {fk.DrawNCards},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@fengyu_shu") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@fengyu_shu")
    player.room:setPlayerMark(player, "@fengyu_shu", 0)
  end,
}
baoshu:addRelatedSkill(baoshu_delay)
fengyu:addSkill(tiqi)
fengyu:addSkill(baoshu)
Fk:loadTranslationTable{
  ["ty__fengfangnv"] = "冯妤",
  ["#ty__fengfangnv"] = "泣珠伊人",
  ["illustrator:ty__fengfangnv"] = "君桓文化",
  ["tiqi"] = "涕泣",
  [":tiqi"] = "每回合限一次，其他角色的额定的出牌阶段、弃牌阶段、结束阶段开始前，若其于此回合的摸牌阶段内因摸牌而得到过的牌数之和不等于2，"..
  "你摸那个相差数值的牌，然后可以选择令该角色的手牌上限于此回合内增加或减少同样的数值。",
  ["baoshu"] = "宝梳",
  ["#baoshu_delay"] = "宝梳",
  [":baoshu"] = "准备阶段，你可以选择至多X名角色（X为你的体力上限），这些角色各获得一个“梳”标记并重置武将牌，"..
  "你每少选一名角色，每名目标角色便多获得一个“梳”。有“梳”标记的角色摸牌阶段多摸其“梳”数量的牌，然后移去其所有“梳”。",
  ["#tiqi-choice"] = "涕泣：你可以令%dest本回合的手牌上限增加或减少 %arg",
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

local laiyinger = General(extension, "laiyinger", "qun", 3, 3, General.Female)
local xiaowu = fk.CreateActiveSkill{
  name = "xiaowu",
  anim_type = "offensive",
  prompt = "#xiaowu",
  max_card_num = 0,
  target_num = 1,
  interaction = function(self)
    return UI.ComboBox { choices = {"xiaowu_anticlockwise", "xiaowu_clockwise"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local players = room:getOtherPlayers(player)
    local targets = {}
    local choice = self.interaction.data
    for i = 1, #players, 1 do
      local real_i = i
      if choice == "xiaowu_clockwise" then
        real_i = #players + 1 - real_i
      end
      local temp = players[real_i]
      table.insert(targets, temp)
      if temp == target then break end
    end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
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
    return player:hasSkill(self, false, player == target) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    if player == target then
      local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#huaping-choose", self.name, true)
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
        if s:isPlayerSkill(target) then
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
  name = "shawu_select",
  can_use = Util.FalseFunc,
  target_num = 0,
  max_card_num = 2,
  min_card_num = function ()
    if Self:getMark("@xiaowu_sand") > 0 then
      return 0
    end
    return 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected < 2 and not Self:prohibitDiscard(Fk:getCardById(to_select))
    and table.contains(Self:getCardIds("h"), to_select)
  end,
  feasible = function (self, selected, selected_cards)
    if #selected_cards == 0 then
      return Self:getMark("@xiaowu_sand") > 0
    else
      return #selected_cards == 2
    end
  end,
}
local shawu = fk.CreateTriggerSkill{
  name = "shawu",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      (player:getMark("@xiaowu_sand") > 0 or player:getHandcardNum() > 1) and not player.room:getPlayerById(data.to).dead
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "shawu_select", "#shawu-invoke::" .. data.to, true)
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
Fk:addSkill(shawu_select)
laiyinger:addSkill(xiaowu)
laiyinger:addSkill(huaping)
laiyinger:addRelatedSkill(shawu)
Fk:loadTranslationTable{
  ["laiyinger"] = "来莺儿",
  ["#laiyinger"] = "雀台歌女",
  ["illustrator:laiyinger"] = "君桓文化",
  ["xiaowu"] = "绡舞",
  [":xiaowu"] = "出牌阶段限一次，你可以从你的上家或下家起选择任意名座位连续的其他角色，每名角色依次选择一项：1.令你摸一张牌；2.自己摸一张牌。"..
  "选择完成后，若令你摸牌的选择人数较多，你获得一个“沙”标记；若自己摸牌的选择人数较多，你对这些角色各造成1点伤害。",
  ["huaping"] = "化萍",
  [":huaping"] = "限定技，一名其他角色死亡时，你可以获得其所有武将技能，然后你失去〖绡舞〗和所有“沙”标记并摸等量的牌。"..
  "你死亡时，你可以令一名其他角色获得技能〖沙舞〗和所有“沙”标记。",
  ["shawu"] = "沙舞",
  ["shawu_select"] = "沙舞",
  [":shawu"] = "当你使用【杀】指定目标后，你可以弃置两张手牌或1枚“沙”标记对目标角色造成1点伤害。若你弃置的是“沙”标记，你摸两张牌。",

  ["#xiaowu"] = "发动 绡舞，选择按逆时针（行动顺序）或顺时针顺序结算，并选择作为终点的目标角色",
  ["xiaowu_clockwise"] = "顺时针顺序",
  ["xiaowu_anticlockwise"] = "逆时针顺序",
  ["#xiawu_draw"] = "绡舞：选择令%src摸一张牌或自己摸一张牌",
  ["xiaowu_draw1"] = "令其摸一张牌",
  ["@xiaowu_sand"] = "沙",
  ["#huaping-choose"] = "化萍：选择一名角色，令其获得沙舞",
  ["#huaping-invoke"] = "化萍：你可以获得%dest的所有武将技能，然后失去绡舞",
  ["#shawu-invoke"] = "沙舞：你可选择两张手牌弃置，或直接点确定弃置沙标记。来对%dest造成1点伤害",

  ["$xiaowu1"] = "繁星临云袖，明月耀舞衣。",
  ["$xiaowu2"] = "逐舞飘轻袖，传歌共绕梁。",
  ["$huaping1"] = "风絮飘残，化萍而终。",
  ["$huaping2"] = "莲泥刚倩，藕丝萦绕。",
  ["~laiyinger"] = "谷底幽兰艳，芳魂永留香……",
}

local caohua = General(extension, "caohua", "wei", 3, 3, General.Female)
local function doCaiyi(player, target, choice, n)
  local room = player.room
  local state = string.sub(choice, 6, 9)
  local i = tonumber(string.sub(choice, 10))
  if i == 4 then
    local num = {}
    for i = 1, 3, 1 do
      if player:getMark("caiyi"..state..tostring(i)) ~= 0 then
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
        target:reset()
      end
    else
      if i == 1 then
        room:damage{
          to = target,
          damage = n,
          skillName = "caiyi",
        }
      elseif i == 2 then
        room:askForDiscard(target, n, n, true, "caiyi", false)
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
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
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
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), Util.IdMapper), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices, all_choices = {}, {}
    local state = "yang"
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYin then
      state = "yinn"
    end
    for i = 1, 4, 1 do
      local mark = "caiyi"..state..tostring(i)
      if player:getMark(mark) == 0 then
        table.insert(choices, mark)
      end
      table.insert(all_choices, mark)
    end
    local num = #choices
    if num == 4 then
      table.remove(choices, 4)
    end
    local to = room:getPlayerById(self.cost_data)
    local choice = room:askForChoice(to, choices, self.name, "#caiyi-choice:::"..tostring(num), nil, all_choices)
    room:setPlayerMark(player, choice, 1)
    doCaiyi(player, to, choice, num)
  end,

  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "caiyiyang1", 0)
    room:setPlayerMark(player, "caiyiyang2", 0)
    room:setPlayerMark(player, "caiyiyang3", 0)
    room:setPlayerMark(player, "caiyiyang4", 0)
    room:setPlayerMark(player, "caiyiyinn1", 0)
    room:setPlayerMark(player, "caiyiyinn2", 0)
    room:setPlayerMark(player, "caiyiyinn3", 0)
    room:setPlayerMark(player, "caiyiyinn4", 0)
  end,
}
local guili = fk.CreateTriggerSkill{
  name = "guili",
  anim_type = "control",
  events = {fk.TurnStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
        local room = player.room
      if target == player and event == fk.TurnStart then
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = player:getMark("guili_record")
        if x == 0 then
          local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
          for _, e in ipairs(events) do
            local current_player = e.data[1]
            if current_player == player then
              x = e.id
              room:setPlayerMark(player, "guili_record", x)
              break
            end
          end
        end
        return turn_event.id == x
      elseif event == fk.TurnEnd and not target.dead and player:getMark(self.name) == target.id then
        local turn_event = room.logic:getCurrentEvent()
        if not turn_event then return false end
        local x = target:getMark("guili_record-round")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
            local current_player = e.data[1]
            if current_player == target then
              x = e.id
              room:setPlayerMark(target, "guili_record", x)
              return true
            end
          end, Player.HistoryRound)
        end
        return turn_event.id == x and #room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local damage = e.data[5]
          if damage and target == damage.from then
            return true
          end
        end, Player.HistoryTurn) == 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#guili-choose", self.name, false, true)
      local to
      if #tos > 0 then
        to = tos[1]
      else
        to = table.random(targets)
      end
      room:setPlayerMark(player, self.name, to)
      room:setPlayerMark(room:getPlayerById(to), "@@guili", 1)
    elseif event == fk.TurnEnd then
      player:gainAnExtraTurn(true)
    end
  end,
}
caohua:addSkill(caiyi)
caohua:addSkill(guili)
Fk:loadTranslationTable{
  ["caohua"] = "曹华",
  ["#caohua"] = "殊凰求凤",
  ["designer:caohua"] = "七哀",
  ["illustrator:caohua"] = "HEI-LE",
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
local chaixie = fk.CreateTriggerSkill{
  name = "chaixie",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      return data.extra_data and data.extra_data.chaixie_draw and table.find(data.extra_data.chaixie_draw, function (dat)
        return dat[1] == player.id
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, dat in ipairs(data.extra_data.chaixie_draw) do
      if dat[1] == player.id then
        n = n + dat[2]
      end
    end
    player:drawCards(n, self.name)
  end,
}
zhangfen:addSkill(wanglu)
zhangfen:addSkill(xianzhu)
zhangfen:addSkill(chaixie)
Fk:loadTranslationTable{
  ["zhangfen"] = "张奋",
  ["#zhangfen"] = "御驰大攻",
  ["designer:zhangfen"] = "七哀",
  ["illustrator:zhangfen"] = "杨李ping",
  ["wanglu"] = "望橹",
  [":wanglu"] = "锁定技，准备阶段，你将【大攻车】置入你的装备区，若你的装备区内已有【大攻车】，则你执行一个额外的出牌阶段。<br>"..
  "<font color='grey'>【大攻车】<br>♠9 装备牌·宝物<br /><b>装备技能</b>：出牌阶段开始时，你可以视为使用一张【杀】，"..
  "当此【杀】对目标角色造成伤害后，你弃置其一张牌。若此牌未升级，则防止此牌被弃置。此牌离开装备区时销毁。",
  ["xianzhu"] = "陷筑",
  [":xianzhu"] = "当你使用【杀】造成伤害后，你可以升级【大攻车】（每个【大攻车】最多升级5次）。升级选项：<br>"..
  "【大攻车】的【杀】无视距离和防具；<br>【大攻车】的【杀】可指定目标+1；<br>【大攻车】的【杀】造成伤害后弃牌数+1。",
  ["chaixie"] = "拆械",
  [":chaixie"] = "锁定技，当【大攻车】销毁后，你摸X张牌（X为该【大攻车】的升级次数）。",
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
  ["~zhangfen"] = "身陨外，愿魂归江东……",
}

local zhugemengxue = General(extension, "zhugemengxue", "wei", 3, 3, General.Female)
local jichun = fk.CreateActiveSkill{
  name = "jichun",
  anim_type = "support",
  prompt = "#jichun-active",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 and
      (player:getMark("jichun1-phase") == 0 or player:getMark("jichun2-phase") == 0)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:getCardById(effect.cards[1])
    local n = Fk:translate(card.trueName, "zh_CN"):len()
    player:showCards(effect.cards)
    --room:delay(1000)
    local targets = table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() < player:getHandcardNum()
    end), Util.IdMapper)
    local choices = {}
    if #targets > 0 and player:getMark("jichun1-phase") == 0 then
      table.insert(choices, "jichun1")
    end
    if player:getMark("jichun2-phase") == 0 then
      table.insert(choices, "jichun2")
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(player, choices, self.name,
      "#jichun-choice:::"..card:toLogString()..":"..tostring(n), false, {"jichun1", "jichun2"})
    room:setPlayerMark(player, choice.."-phase", 1)
    if choice == "jichun1" then
      targets = room:askForChoosePlayers(player, targets, 1, 1,
      "#jichun-give:::" .. card:toLogString() .. ":" .. tostring(n), self.name, false)
      room:moveCardTo(effect.cards, Player.Hand, room:getPlayerById(targets[1]), fk.ReasonGive, self.name,
      nil, true, player.id)
      if not player.dead then
        player:drawCards(n, self.name)
      end
    elseif not player:prohibitDiscard(card) then
      room:throwCard(effect.cards, self.name, player)
      if player.dead then return end
      targets = table.map(table.filter(room.alive_players, function (p)
        return p:getHandcardNum() > player:getHandcardNum()
      end), Util.IdMapper)
      if #targets == 0 then return end
      targets = room:askForChoosePlayers(player, targets, 1, 1,
      "#jichun-discard:::" .. tostring(n), self.name, false)
      local to = room:getPlayerById(targets[1])
      local cards = room:askForCardsChosen(player, to, 1, n, "hej", self.name)
      if #cards > 0 then
        room:throwCard(cards, self.name, to, player)
      end
    end
  end,

  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "jichun1-phase", 0)
    room:setPlayerMark(player, "jichun2-phase", 0)
  end,
}
local hanying = fk.CreateTriggerSkill{
  name = "hanying",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = nil
    for _, id in ipairs(room.draw_pile) do
      local c = Fk:getCardById(id)
      if c.type == Card.TypeEquip then
        card = c
        break
      end
    end
    if card == nil then
      room:sendLog{ type = "#SearchFailed", from = player.id, arg = self.name, arg2 = "equip" }
      return false
    end
    room:moveCards({
      ids = {card.id},
      toArea = Card.Processing,
      skillName = self.name,
      proposer = player.id,
      moveReason = fk.ReasonJustMove,
    })
    --room:delay(1000)
    local targets = table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() == player:getHandcardNum() and p:canUseTo(card, p)
    end), Util.IdMapper)
    if #targets == 0 then
      room:moveCards{
        ids = {card.id},
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
      }
      return false
    end
    targets = room:askForChoosePlayers(player, targets, 1, 1,
    "#hanying-choose:::" .. card:toLogString(), self.name, false)
    --FIXME:暂不考虑赠物（十周年逐鹿天下版）
    room:useCard{
      from = targets[1],
      card = card,
      tos = { targets }
    }
  end,
}

zhugemengxue:addSkill(jichun)
zhugemengxue:addSkill(hanying)

Fk:loadTranslationTable{
  ["zhugemengxue"] = "诸葛梦雪",
  ["#zhugemengxue"] = "仙苑停云",
  ["designer:zhugemengxue"] = "韩旭",
  --["illustrator:zhugemengxue"] = "",
  ["jichun"] = "寄春",
  [":jichun"] = "出牌阶段限两次，你可以展示一张牌，选择于当前阶段内未选择过的项：1.将此牌交给一名手牌数小于你的角色，然后摸X张牌；"..
  "2.弃置此牌，然后弃置一名手牌数大于你的角色区域里至多X张牌。（X为此牌的牌名字数）",
  ["hanying"] = "寒英",
  [":hanying"] = "准备阶段，你可以展示牌堆顶第一张装备牌，然后令一名手牌数等于你的角色使用之。",

  ["#jichun-active"] = "发动 寄春，选择一张牌展示之",
  ["#jichun-choice"] = "寄春：你展示的%arg牌名字数为%arg2，清选择：",
  ["jichun1"] = "将展示牌交给一名手牌数小于你的角色并摸牌",
  ["jichun2"] = "弃置展示牌，然后弃置一名手牌数大于你的角色区域里的牌",
  ["#jichun-give"] = "寄春：将展示的%arg交给一名手牌数小于你的角色并摸%arg2张牌",
  ["#jichun-discard"] = "寄春：选择一名手牌数大于你的角色弃置其区域里至多%arg张牌",
  ["#SearchFailed"] = "%from 发动 %arg 失败，无法检索到 %arg2",
  ["#hanying-choose"] = "寒英：选择一名手牌数等于你的角色，令其使用%arg",

  ["$jichun1"] = "寒冬已至，花开不远矣。",
  ["$jichun2"] = "梅凌霜雪，其香不逊晚来者。",
  ["$hanying1"] = "寒梅不争春，空任群芳妒。",
  ["$hanying2"] = "三九寒天，尤有寒英凌霜。",
  ["~zhugemengxue"] = "雪落青丝上，与君共白头……",
}

local zhugeruoxue = General(extension, "zhugeruoxue", "wei", 3, 3, General.Female)
local qiongying = fk.CreateActiveSkill{
  name = "qiongying",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  prompt = "#qiongying",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(selected[1]):canMoveCardsInBoardTo(target, nil)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local result = room:askForMoveCardInBoard(player, room:getPlayerById(effect.tos[1]), room:getPlayerById(effect.tos[2]), self.name)
    if player.dead or player:isKongcheng() then return end
    local suit = result.card:getSuitString()
    if #room:askForDiscard(player, 1, 1, false, self.name, false, ".|.|"..suit) == 0 then
      player:showCards(player:getCardIds("h"))
    end
  end,
}
local nuanhui = fk.CreateTriggerSkill{
  name = "nuanhui",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
    "#nuanhui-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = math.max(#to:getCardIds("e"), 1)
    local throwEquip = false
    local names = {}
    for i = 1, n, 1 do
      local use = U.askForUseVirtualCard(room, to, U.getAllCardNames("b"), nil, self.name,
      "#nuanhui-use:::"..i..":"..n, true, true, false, true)
      if use then
        if not table.insertIfNeed(names, use.card.trueName) then
          throwEquip = true
        end
        if to.dead then return false end
        n = math.max(#to:getCardIds("e"), 1)
      else
        break
      end
    end
    if throwEquip then
      to:throwAllCards("e")
    end
  end,
}
zhugeruoxue:addSkill(qiongying)
zhugeruoxue:addSkill(nuanhui)
Fk:loadTranslationTable{
  ["zhugeruoxue"] = "诸葛若雪",
  ["#zhugeruoxue"] = "玉榭霑露",
  ["designer:zhugeruoxue"] = "星移",

  ["qiongying"] = "琼英",
  [":qiongying"] = "出牌阶段限一次，你可以移动场上一张牌，然后你弃置一张同花色的手牌（若没有需展示手牌）。",
  ["nuanhui"] = "暖惠",
  [":nuanhui"] = "结束阶段，你可以选择一名角色，该角色可视为使用X张基本牌（X为其装备区牌数且至少为1）。"..
  "若其使用了同名牌，其弃置装备区所有牌。",
  ["#qiongying"] = "琼英：你可以移动场上一张牌，然后弃置一张此花色的手牌",
  ["#nuanhui-choose"] = "暖惠：选择一名角色，其可以视为使用其装备区内牌张数的基本牌",
  ["nuanhui_viewas"] = "暖惠",
  ["#nuanhui-use"] = "暖惠：你可以视为使用基本牌（第%arg张，共%arg2张）",

  ["$qiongying1"] = "冰心碎玉壶，光转琼英灿。",
  ["$qiongying2"] = "玉心玲珑意，撷英倚西楼。",
  ["$nuanhui1"] = "暖阳映雪，可照八九之风光。",
  ["$nuanhui2"] = "晓风和畅，吹融附柳之霜雪。",
  ["~zhugeruoxue"] = "自古佳人叹白头……",
}

local caoxian = General(extension, "caoxian", "wei", 3, 3, General.Female)
local lingxi = fk.CreateTriggerSkill{
  name = "lingxi",
  derived_piles = "lingxi_wing",
  mute = true,
  events = {fk.EventPhaseStart, fk.EventPhaseEnd, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromSpecialName == "lingxi_wing" then
              return true
            end
          end
        end
      end
    else
      return target == player and player.phase == Player.Play and not player:isNude()
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then return true end
    local room = player.room
    local x = player.maxHp
    local card = room:askForCard(player, 1, x, true, self.name, true, ".", "#lingxi-put:::"..x)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.AfterCardsMove then
      local suits = {}
      for _, id in ipairs(player:getPile("lingxi_wing")) do
        local suit = Fk:getCardById(id).suit
        table.insertIfNeed(suits, suit)
      end
      local x = (2 * #suits) - player:getHandcardNum()
      if x > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        player:drawCards(x, self.name)
      elseif x < 0 then
        room:notifySkillInvoked(player, self.name, "negative")
        room:askForDiscard(player, -x, -x, false, self.name, false)
      end
    else
      room:notifySkillInvoked(player, self.name, "special")
      player:addToPile("lingxi_wing", self.cost_data, true, self.name)
    end
  end,
}
caoxian:addSkill(lingxi)
local zhifou = fk.CreateTriggerSkill{
  name = "zhifou",
  anim_type = "control",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and #player:getTableMark("zhifou-turn") < 3
    and #player:getPile("lingxi_wing") > player:usedSkillTimes(self.name, Player.HistoryTurn)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = player:usedSkillTimes(self.name, Player.HistoryTurn) + 1
    local cards = room:askForCard(player, x, 9999, false, self.name, true, ".|.|.|lingxi_wing", "#zhifou-invoke:::"..x, "lingxi_wing")
    if #cards >= x then
      self.cost_data = {cards = cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(self.cost_data.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
    if player.dead then return end
    local _, dat = room:askForUseActiveSkill(player, "zhifou_active", "#zhifou-active", false)
    if not dat then
      dat = {targets = {table.random(room.alive_players).id}}
      local all_choices = {"zhifou_put", "zhifou_discard", "zhifou_losehp"}
      dat.interaction = table.find(all_choices, function(choice)
        return not table.contains(player:getTableMark("zhifou-turn"), choice)
      end)
    end
    local choice = dat.interaction
    local to = room:getPlayerById(dat.targets[1])
    room:addTableMark(player, "zhifou-turn", choice)
    if choice == "zhifou_put" then
      if player.dead or to:isNude() then return end
      local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#zhifou-put")
      player:addToPile("lingxi_wing", card[1], true, self.name)
    elseif choice == "zhifou_discard" then
      room:askForDiscard(to, 2, 2, true, self.name, false)
    else
      room:loseHp(to, 1, self.name)
    end
  end,
}
local zhifou_active = fk.CreateActiveSkill{
  name = "zhifou_active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    local all_choices = {"zhifou_put", "zhifou_discard", "zhifou_losehp"}
    local choices = table.filter(all_choices, function(choice)
      return not table.contains(Self:getTableMark("zhifou-turn"), choice)
    end)
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
}
Fk:addSkill(zhifou_active)
caoxian:addSkill(zhifou)
Fk:loadTranslationTable{
  ["caoxian"] = "曹宪",
  ["#caoxian"] = "蝶步韶华",
  ["designer:caoxian"] = "快雪时晴",
  ["lingxi"] = "灵犀",
  [":lingxi"] = "出牌阶段开始时或结束时，你可以将至多体力上限张牌置于你的武将牌上，称为“翼”。当你的“翼”被移去后，你将手牌摸至或弃置至“翼”包含的花色数的两倍。",
  ["#lingxi-put"] = "灵犀：将至多 %arg 张牌置入“翼”",
  ["lingxi_wing"] = "翼",
  ["zhifou"] = "知否",
  [":zhifou"] = "当你使用牌结算结束后，你可以移去至少X张“翼”（X为你本回合发动此技能的次数），若如此做，你选择一名角色并选择一项（每回合每项限一次），令其执行之：1.将一张牌置入“翼”；2.弃置两张牌；3.失去1点体力。",
  ["zhifou_active"] = "知否",
  ["#zhifou-invoke"] = "知否：你可以移去至少 %arg 张“翼”",
  ["#zhifou-active"] = "知否：选择一名角色，令其执行一项",
  ["zhifou_put"] = "将一张牌置入“翼”",
  ["zhifou_discard"] = "弃置两张牌",
  ["zhifou_losehp"] = "失去1点体力",
  ["#zhifou-put"] = "知否：你须将一张牌置入“翼”中",

  ["$lingxi1"] = "灵犀渡清潭，涟漪扰我心。",
  ["$lingxi2"] = "心有玲珑曲，万籁皆空灵。",
  ["$zhifou1"] = "满怀相思意，念君君可知？",
  ["$zhifou2"] = "世有人万万，相知无二三。",
  ["~caoxian"] = "恨生枭雄府，恨嫁君王家……",
}

local liutan = General(extension, "liutan", "shu", 3, 3, General.Female)
local jingyin = fk.CreateTriggerSkill{
  name = "jingyin",
  anim_type = "support",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:usedSkillTimes(self.name) > 0 then return false end
    local room = player.room
    local move_event = room.logic:getCurrentEvent()
    local parent_event = move_event.parent
    if parent_event ~= nil and parent_event.event == GameEvent.UseCard then
      local parent_data = parent_event.data[1]
      if parent_data.from and parent_data.from ~= room.current.id and parent_data.card.trueName == "slash" then
        local card_ids = room:getSubcardsByRule(parent_data.card)
        if #card_ids == 0 then return false end
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonUse then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.Processing and room:getCardArea(info.cardId) == Card.DiscardPile then
                if not table.removeOne(card_ids, info.cardId) then
                  --不懂有没有意义，暂且要求必须实体牌完全对应才行
                  return false
                end
              end
            end
          end
        end
        if #card_ids == 0 then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, false)
    if use_event == nil then return false end
    local targets = table.map(room.alive_players, Util.IdMapper)
    table.removeOne(targets, use_event.data[1].from)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jingyin-card:::"..use_event.data[1].card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = {to[1], room:getSubcardsByRule(use_event.data[1].card)}
      --不二次检测了
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(self.cost_data[2], Card.PlayerHand, self.cost_data[1], fk.ReasonGive, self.name, "", true,
    player.id, "@@jingyin-inhand")
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and data.card:getMark("@@jingyin-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local jingyin_targetmod = fk.CreateTargetModSkill{
  name = "#jingyin_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and card:getMark("@@jingyin-inhand") > 0
  end,
}
local chixing = fk.CreateTriggerSkill{
  name = "chixing",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Play then
      local room = player.room
      local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase, true)
      if phase_event == nil then return false end
      local x = 0
      room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId, true).trueName == "slash" then
                x = x + 1
              end
            end
          end
        end
        return false
      end, phase_event.id)
      if x > 0 then
        self.cost_data = x
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:drawCards(player, self.cost_data, self.name)
    local handcards = player:getCardIds(Player.Hand)
    cards = table.filter(cards, function (id)
      return table.contains(cards, id) and Fk:getCardById(id).trueName == "slash"
    end)
    if #cards > 0 then
      local use = U.askForUseRealCard(room, player, cards, ".", self.name, "#chixing-use",
      {bypass_times = true}, false, true)
    end
  end,
}
jingyin:addRelatedSkill(jingyin_targetmod)
liutan:addSkill(jingyin)
liutan:addSkill(chixing)
Fk:loadTranslationTable{
  ["liutan"] = "柳婒",
  ["#liutan"] = "维情所止",
  --["designer:liutan"] = "",
  ["illustrator:liutan"] = "黯荧岛",

  ["jingyin"] = "经音",
  [":jingyin"] = "每回合限一次，当一名角色于其回合外使用的【杀】移至弃牌堆后，你可以令其以外的一名角色获得此牌，"..
  "以此法得到的牌被使用时无次数限制。",
  ["chixing"] = "迟行",
  [":chixing"] = "一名角色的出牌阶段结束时，若有【杀】于此阶段内移至过弃牌堆，你可以摸等量的牌，"..
  "然后你可以使用你摸到的这些牌中的一张【杀】。",

  ["#jingyin-card"] = "是否发动 经音，令一名角色获得%arg（其使用时无次数限制）",
  ["@@jingyin-inhand"] = "经音",
  ["#chixing-use"] = "迟行：你可以使用一张【杀】",

  ["$jingyin1"] = "金柝越关山，唯送君于南。",
  ["$jingyin2"] = "燕燕于飞，寒江照孤影。",
  ["$chixing1"] = "孤鸿鸣晚林，泪垂大江流。",
  ["$chixing2"] = "若路的尽头是离别，妾宁愿蹒跚一世。",
  ["~liutan"] = "孤灯照长夜，羹熟唤何人？",
}

local wenyuan = General(extension, "wenyuan", "shu", 3, 3, General.Female)
local kengqiang = fk.CreateTriggerSkill{
  name = "kengqiang",
  anim_type = "drawcard",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if player:usedSkillTimes("shangjue", Player.HistoryGame) == 0 then
        return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
          player:getMark("kengqiang1-turn") == 0 and player:getMark("kengqiang2-turn") == 0
      else
        return player:getMark("kengqiang1-turn") == 0 or player:getMark("kengqiang2-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"kengqiang1", "kengqiang2", "Cancel"}
    local choices = table.simpleClone(all_choices)
    for i = 2, 1, -1 do
      if player:getMark("kengqiang"..i.."-turn") > 0 then
        table.remove(choices, i)
      end
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#kengqiang-invoke", false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data.choice
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "kengqiang1" then
      player:drawCards(player.maxHp, self.name)
    else
      data.damage = data.damage + 1
      if data.card and room:getCardArea(data.card) == Card.Processing then
        room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
      end
    end
  end,
}
local kuichi = fk.CreateTriggerSkill{
  name = "kuichi",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local room = player.room
      local n = 0
      room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        if damage.from == player then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      if n < player.maxHp then return false end
      n = 0
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.moveReason == fk.ReasonDraw then
            n = n + #move.moveInfo
          end
        end
      end, Player.HistoryTurn)
      return n >= player.maxHp
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
  end,
}
local shangjue = fk.CreateTriggerSkill{
  name = "shangjue",
  anim_type = "defensive",
  events = {fk.EnterDying},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = self.name,
    })
    if not player.dead then
      room:changeMaxHp(player, 1)
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "kunli", nil, true, false)
    end
  end,
}
local kunli = fk.CreateTriggerSkill{
  name = "kunli",
  anim_type = "defensive",
  events = {fk.EnterDying},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = math.min(2, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name,
    })
    if not player.dead then
      room:changeMaxHp(player, 1)
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "-kuichi", nil, true, false)
    end
  end,
}
wenyuan:addSkill(kengqiang)
wenyuan:addSkill(kuichi)
wenyuan:addSkill(shangjue)
wenyuan:addRelatedSkill(kunli)
Fk:loadTranslationTable{
  ["wenyuan"] = "文鸳",
  ["#wenyuan"] = "揾泪红袖",
  ["illustrator:wenyuan"] = "匠人绘",

  ["kengqiang"] = "铿锵",
  [":kengqiang"] = "每回合限一次，当你造成伤害时，你可以选择一项：1.摸X张牌（X为你的体力上限）；2.此伤害+1，你获得造成伤害的牌。",
  ["kuichi"] = "匮饬",
  [":kuichi"] = "锁定技，回合结束时，若你本回合摸牌数和造成的伤害值均不小于你的体力上限，你失去1点体力。",
  ["shangjue"] = "殇决",
  [":shangjue"] = "觉醒技，当你进入濒死状态时，你将体力值回复至1点，加1点体力上限，并获得〖困励〗，然后将〖铿锵〗改为每回合各限一次。",
  ["kunli"] = "困励",
  [":kunli"] = "觉醒技，当你进入濒死状态时，你将体力值回复至2点，加1点体力上限，并失去〖匮饬〗。",
  ["#kengqiang-invoke"] = "铿锵：你可以选择一项",
  ["kengqiang1"] = "摸体力上限张牌",
  ["kengqiang2"] = "此伤害+1，你获得造成伤害的牌",

  ["$kengqiang1"] = "女子着征袍，战意越关山。",
  ["$kengqiang2"] = "兴武效妇好，挥钺断苍穹！",
  ["$kuichi1"] = "久战沙场，遗伤无数。",
  ["$kuichi2"] = "人无完人，千虑亦有一失。",
  ["$shangjue1"] = "伯约，奈何桥畔，再等我片刻。",
  ["$shangjue2"] = "与君同生共死，岂可空待黄泉！",
  ["$kunli1"] = "回首万重山，难阻轻舟一叶。",
  ["$kunli2"] = "已过山穷水尽，前有柳暗花明。",
  ["~wenyuan"] = "伯约，回家了。",
}

return extension
