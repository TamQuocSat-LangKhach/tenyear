
local xugong = General(extension, "ty__xugong", "wu", 3)
local biaozhao = fk.CreateTriggerSkill{
  name = "biaozhao",
  mute = true,
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  derived_piles = "biaozhao_message",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return (player.phase == Player.Finish and #player:getPile("biaozhao_message") == 0) or
      (player.phase == Player.Start and #player:getPile("biaozhao_message") > 0)
    elseif event == fk.AfterCardsMove and #player:getPile("biaozhao_message") > 0 then
      local pile = Fk:getCardById(player:getPile("biaozhao_message")[1])
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card:compareNumberWith(pile) and card:compareSuitWith(pile) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      local cards = room:askForCard(player, 1, 1, true, self.name, true, ".", "#biaozhao-cost")
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
      return false
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "support")
      player:broadcastSkillInvoke(self.name)
      if player.phase == Player.Finish then
        player:addToPile("biaozhao_message", self.cost_data, true, self.name)
      else
        room:moveCards({
          from = player.id,
          ids = player:getPile("biaozhao_message"),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        local targets = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#biaozhao-choose", self.name, false)
        if #targets > 0 then
          local to = room:getPlayerById(targets[1])
          if to:isWounded() then
            room:recover{
              who = to,
              num = 1,
              recoverBy = player,
              skillName = self.name,
            }
          end
          if not to.dead then
            local x = 0
            for _, p in ipairs(room.alive_players) do
              x = math.max(x, p:getHandcardNum())
            end
            x = x - to:getHandcardNum()
            if x > 0 then
              room:drawCards(to, math.min(5, x), self.name)
            end
          end
        end
      end
    elseif event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name)
      local pile = Fk:getCardById(player:getPile("biaozhao_message")[1])
      local targets = {}
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard and move.toArea == Card.DiscardPile and move.from ~= nil and
        move.from ~= player.id and not room:getPlayerById(move.from).dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              local card = Fk:getCardById(info.cardId)
              if card:compareNumberWith(pile) and card:compareSuitWith(pile) then
                table.insertIfNeed(targets, move.from)
              end
            end
          end
        end
      end
      if #targets > 1 then
        targets = room:askForChoosePlayers(player, targets, 1, 1, "#biaozhao-target:::" .. pile:toLogString(), self.name, false)
      end
      if #targets > 0 then
        room:obtainCard(targets[1], pile, false, fk.ReasonPrey)
      end
      if #targets == 0 then
        room:moveCards({
          from = player.id,
          ids = {pile.id},
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        if not player.dead then
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
local yechou = fk.CreateTriggerSkill{
  name = "yechou",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true) and table.find(player.room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getLostHp() > 1
    end)
    local p = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#yechou-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "@@yechou", 1)
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@yechou") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@yechou", 0)
  end,
}
local yechou_delay = fk.CreateTriggerSkill{
  name = "#yechou_delay",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and player:getMark("@@yechou") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, yechou.name)
  end,
}
yechou:addRelatedSkill(yechou_delay)
xugong:addSkill(biaozhao)
xugong:addSkill(yechou)
Fk:loadTranslationTable{
  ["ty__xugong"] = "许贡",
  ["#ty__xugong"] = "独计击流",
  ["illustrator:ty__xugong"] = "红字虾",
  ["biaozhao"] = "表召",
  [":biaozhao"] = "结束阶段，你可将一张牌置于武将牌上，称为“表”。当一张与“表”花色点数均相同的牌移至弃牌堆后，若此牌是其他角色弃置的牌，"..
  "则其获得“表”，否则你移去“表”并失去1点体力。准备阶段，你移去“表”，令一名角色回复1点体力，其将手牌摸至与手牌最多的角色相同（至多摸五张）。",
  ["yechou"] = "业仇",
  ["#yechou_delay"] = "业仇",
  [":yechou"] = "你死亡时，你可以选择一名已损失的体力值大于1的角色。若如此做，每名角色的结束阶段，其失去1点体力，直到其下回合开始。",

  ["biaozhao_message"] = "表",
  ["#biaozhao-cost"] = "你可以发动表召，选择一张牌作为表置于武将牌上",
  ["#biaozhao-choose"] = "表召：选择一名角色，令其回复1点体力并补充手牌",
  ["#biaozhao-target"] = "表召：选择一名角色，令其获得你的“表”%arg",
  ["#yechou-choose"] = "你可以发动表召，选择一名角色，令其于下个回合开始之前的每名角色的结束阶段都会失去1点体力",
  ["@@yechou"] = "业仇",

  ["$biaozhao1"] = "此人有祸患之像，望丞相慎之。",
  ["$biaozhao2"] = "孙策宜加贵宠，须召还京邑！",
  ["$yechou1"] = "会有人替我报仇的！",
  ["$yechou2"] = "我的门客，是不会放过你的！",
  ["~ty__xugong"] = "终究……还是被其所害……",
}

local zhangchangpu = General(extension, "ty__zhangchangpu", "wei", 3, 3, General.Female)
local yanjiao = fk.CreateActiveSkill{
  name = "yanjiao",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#yanjiao",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = 4 + player:getMark("@yanjiao")
    room:setPlayerMark(player, "@yanjiao", 0)
    local cards = room:getNCards(n)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    local data_table = {}
    for _, p in ipairs(room.players) do
      data_table[p.id] = {
        cards,
        player.general,
        target.general,
        p == target
      }
    end
    room:askForMiniGame(room.players, self.name, "yanjiao", data_table)
    local cardmap = json.decode(target.client_reply)
    local rest, pile1, pile2 = cards, {}, {}
    if #cardmap == 3 then
      rest, pile1, pile2 = cardmap[1], cardmap[2], cardmap[3]
    end
    local moveInfos = {}
    if #pile1 > 0 then
      table.insert(moveInfos, {
        ids = pile1,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = target.id,
        skillName = self.name,
        moveVisible = true,
      })
    end
    if #pile2 > 0 then
      table.insert(moveInfos, {
        ids = pile2,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = target.id,
        skillName = self.name,
        moveVisible = true,
      })
    end
    if #rest > 0 then
      table.insert(moveInfos, {
        ids = rest,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        proposer = target.id,
        skillName = self.name,
      })
      if #rest > 1 then
        room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
      end
    end
    room:moveCards(table.unpack(moveInfos))
  end,
}

Fk:addMiniGame{
  name = "yanjiao",
  qml_path = "packages/tenyear/qml/YanjiaoBox",
  default_choice = function(player, data)
    return {}
  end,
  update_func = function(player, data)
    local room = player.room
    if #data == 1 and data[1] == "confirm" then
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        p:doNotify("UpdateMiniGame", "")
      end
    else
      local dat = table.concat(data, ",")
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        p:doNotify("UpdateMiniGame", dat)
      end
    end
  end,
}

local xingshen = fk.CreateTriggerSkill{
  name = "xingshen",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function(p) return p:getHandcardNum() >= player:getHandcardNum() end) then
      player:drawCards(2, self.name)
    else
      player:drawCards(1, self.name)
    end
    if player.dead or player:getMark("@yanjiao") > 5 then return end
    if table.every(room.alive_players, function(p) return p.hp >= player.hp end) then
      room:addPlayerMark(player, "@yanjiao", player:getMark("@yanjiao") > 4 and 1 or 2)
    else
      room:addPlayerMark(player, "@yanjiao", 1)
    end
  end,
}
zhangchangpu:addSkill(yanjiao)
zhangchangpu:addSkill(xingshen)
Fk:loadTranslationTable{
  ["ty__zhangchangpu"] = "张昌蒲",
  ["#ty__zhangchangpu"] = "矜严明训",
  ["designer:ty__zhangchangpu"] = "韩旭",
  ["illustrator:ty__zhangchangpu"] = "biou09",
  ["yanjiao"] = "严教",
  [":yanjiao"] = "出牌阶段限一次，你可以选择一名其他角色并亮出牌堆顶的四张牌，然后令该角色将这些牌分成点数之和相等的两组牌分配给你与其，"..
  "剩余未分组的牌置入弃牌堆。若未分组的牌超过一张，你本回合手牌上限-1。",
  ["xingshen"] = "省身",
  [":xingshen"] = "当你受到伤害后，你可以摸一张牌并令下一次发动〖严教〗亮出的牌数+1。若你的手牌数为全场最少，则改为摸两张牌；"..
  "若你的体力值为全场最少，则下一次发动〖严教〗亮出的牌数改为+2（加值总数至多为6）。",
  ["#yanjiao"]= "严教：对一名其他角色发动“严教”",
  ["#yanjiao-distribute"] = "严教：请分成点数之和相等的两组",
  ["@yanjiao"] = "严教",
  ["Only Watch"] = "仅观看",

  ["$yanjiao1"] = "会虽童稚，勤见规诲。",
  ["$yanjiao2"] = "性矜严教，明于教训。",
  ["$xingshen1"] = "居上不骄，制节谨度。",
  ["$xingshen2"] = "君子之行，皆积小以致高大。",
  ["~ty__zhangchangpu"] = "我还是小看了，孙氏的伎俩……",
}

--上兵伐谋：辛毗 张温 李肃
local xinpi = General(extension, "xinpi", "wei", 3)
local chijie = fk.CreateTriggerSkill{
  name = "chijie",
  anim_type = "control",
  events = {fk.CardEffecting , fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardEffecting then
      return player:hasSkill(self) and data.from ~= player.id and target == player and player:getMark("chijie_a-turn") == 0
      and data.card.sub_type ~= Card.SubtypeDelayedTrick and data.tos and #TargetGroup:getRealTargets(data.tos) > 1
    else
      if target ~= player and player:hasSkill(self) and not data.damageDealt and player:getMark("chijie_b-turn") == 0 and data.tos and
        table.contains(TargetGroup:getRealTargets(data.tos), player.id) then
        local cardList = data.card:isVirtual() and data.card.subcards or {data.card.id}
        return table.find(cardList, function(id) return not player.room:getCardOwner(id) end)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffecting then
      return room:askForSkillInvoke(player, self.name, nil, "#chijie-nullify:::"..data.card.name)
    else
      return room:askForSkillInvoke(player, self.name, nil, "#chijie-give:::"..data.card.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffecting then
      room:addPlayerMark(player, "chijie_a-turn")
      local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e and e.data[1] then
        local use = e.data[1]
        local list = use.nullifiedTargets or {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          table.insertIfNeed(list, p.id)
        end
        use.nullifiedTargets = list
      end
    else
      room:addPlayerMark(player, "chijie_b-turn")
      local cardList = data.card:isVirtual() and data.card.subcards or {data.card.id}
      local cards = table.filter(cardList, function(id) return not room:getCardOwner(id) end)
      if #cards == 0 then return end
      room:obtainCard(player, cards, true, fk.ReasonJustMove)
    end
  end,
}
xinpi:addSkill(chijie)
local yinju = fk.CreateActiveSkill{
  name = "yinju",
  anim_type = "support",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, use)
    local to = room:getPlayerById(use.tos[1])
    room:setPlayerMark(to, "@@yinju-turn", 1)
  end,
}
local yinju_trigger = fk.CreateTriggerSkill{
  name = "#yinju_trigger",
  anim_type = "support",
  events = {fk.DamageCaused, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player then
      if event == fk.DamageCaused then
        return data.to ~= player and data.to:getMark("@@yinju-turn") > 0
      else
        return data.to ~= player.id and player.room:getPlayerById(data.to):getMark("@@yinju-turn") > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yinju")
    if event == fk.DamageCaused then
      if data.to:isWounded() then
        room:recover { num = data.damage, skillName = self.name, who = data.to , recoverBy = player}
      end
      return true
    else
      local to = room:getPlayerById(data.to)
      player:drawCards(1, self.name)
      if not to.dead then
        to:drawCards(1, self.name)
      end
    end
  end,
}
yinju:addRelatedSkill(yinju_trigger)
xinpi:addSkill(yinju)
Fk:loadTranslationTable{
  ["xinpi"] = "辛毗",
  ["#xinpi"] = "一节肃六军",
  ["illustrator:xinpi"] = "石蝉",
  ["designer:xinpi"] = "神壕",

  ["chijie"] = "持节",
  [":chijie"] = "每回合每项各限一次，<br>①当其他角色使用牌对你生效时，你可以令此牌在接下来的结算中对其他角色无效；<br>②当其他角色使用牌结算结束后，"..
  "若你是目标之一且此牌没有造成过伤害，你可以获得之。",
  ["#chijie-nullify"] = "持节：你可以令 %arg 在接下来的结算中对其他角色无效",
  ["#chijie-give"] = "持节：你可以获得此 %arg",
  ["yinju"] = "引裾",
  [":yinju"] = "限定技，出牌阶段，你可以选择一名其他角色。本回合：1.当你对其造成伤害时，改为令其回复等量的体力；2.当你使用牌指定该角色为目标后，"..
  "你与其各摸一张牌。",
  ["@@yinju-turn"] = "引裾",
  ["#yinju_trigger"] = "引裾",

  ["$chijie1"] = "持节阻战，奉帝赐诏。",
  ["$chijie2"] = "此战不在急，请仲达明了。",
  ["$yinju1"] = "据理直谏，吾人臣本分。",
  ["$yinju2"] = "迁徙之计，危涉万民。",
  ["~xinpi"] = "失民心，且无食。",
}

local zhangwen = General(extension, "ty__zhangwen", "wu", 3)
local ty__songshu = fk.CreateActiveSkill{
  name = "ty__songshu",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    else
      if not player.dead then
        player:drawCards(2, self.name)
      end
      if not target.dead then
        target:drawCards(2, self.name)
      end
    end
  end,
}
local sibian = fk.CreateTriggerSkill{
  name = "sibian",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    local min, max = 13, 1
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).number < min then
        min = Fk:getCardById(id).number
      end
      if Fk:getCardById(id).number > max then
        max = Fk:getCardById(id).number
      end
    end
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).number == min or Fk:getCardById(cards[i]).number == max then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    room:delay(1000)
    room:obtainCard(player, get, false, fk.ReasonJustMove)
    if #cards > 0 then
      local n = #player.player_cards[Player.Hand]
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Hand] < n then
          n = #p.player_cards[Player.Hand]
        end
      end
      local targets = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if #p.player_cards[Player.Hand] == n then
          table.insert(targets, p.id)
        end
      end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#sibian-choose", self.name, true)
      if #to > 0 then
        room:obtainCard(to[1], cards, false, fk.ReasonGive, player.id)
      else
        room:moveCards({
          ids = cards,
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
      end
    end
    return true
  end,
}
zhangwen:addSkill(ty__songshu)
zhangwen:addSkill(sibian)
Fk:loadTranslationTable{
  ["ty__zhangwen"] = "张温",
  ["#ty__zhangwen"] = "冲天孤鹭",
  ["illustrator:ty__zhangwen"] = "zoo",
  ["ty__songshu"] = "颂蜀",
  [":ty__songshu"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你没赢，你和该角色各摸两张牌；若你赢，视为本阶段此技能未发动过。",
  ["sibian"] = "思辩",
  [":sibian"] = "摸牌阶段，你可以放弃摸牌，改为亮出牌堆顶的4张牌，你获得其中所有点数最大和最小的牌，然后你可以将剩余的牌交给一名手牌数最少的角色。",
  ["#sibian-choose"] = "思辩：你可以将剩余的牌交给一名手牌数最少的角色",

  ["$ty__songshu1"] = "称颂蜀汉，以表诚心。",
  ["$ty__songshu2"] = "吴蜀两和，方可安稳。",
  ["$sibian1"] = "才藻俊茂，辨思如涌。",
  ["$sibian2"] = "弘雅之素，英秀之德。",
  ["~ty__zhangwen"] = "暨艳过错，强牵吾罪。",
}

local lisu = General(extension, "ty__lisu", "qun", 2)
local lixun = fk.CreateTriggerSkill{
  name = "lixun",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (event == fk.DamageInflicted or (event == fk.EventPhaseStart and player.phase == Player.Play))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageInflicted then
      room:notifySkillInvoked(player, self.name, "defensive")
      room:addPlayerMark(player, "@lisu_zhu", data.damage)
      return true
    else
      room:notifySkillInvoked(player, self.name, "negative")
      local pattern = ".|A~"..(player:getMark("@lisu_zhu") - 1)
      if player:getMark("@lisu_zhu") <= 1 then
        pattern = "."
      end
      local judge = {
        who = player,
        reason = self.name,
        pattern = pattern,
      }
      room:judge(judge)
      local n = player:getMark("@lisu_zhu")
      if judge.card.number < n then
        local cards = room:askForDiscard(player, n, n, false, self.name, false)
        if #cards < n then
          room:loseHp(player, n - #cards)
        end
      end
    end
  end,
}
local kuizhul = fk.CreateTriggerSkill{
  name = "kuizhul",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() and table.every(player.room:getOtherPlayers(player), function(p2)
        return p.hp >= p2.hp
        end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() and table.every(room:getOtherPlayers(player), function(p2)
        return p.hp >= p2.hp
        end)
      end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuizhul-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if math.min(to:getHandcardNum(), 5) > player:getHandcardNum() then
      player:drawCards(math.min(to:getHandcardNum(), 5) - player:getHandcardNum(), player.id)
    end
    if player.dead or to.dead or player:isKongcheng() or to:isKongcheng() then return end
    local cards = table.filter(to:getCardIds("h"), function(id) return not to:prohibitDiscard(Fk:getCardById(id)) end)
    if #cards == 0 then
      U.viewCards(to, player:getCardIds("h"), self.name)
      return
    end
    local results = U.askForExchange(to, player.general, to.general, player:getCardIds("h"), cards, "#kuizhul-exchange:"..player.id, 999)
    if #results == 0 then return end
    local to_throw = table.filter(results, function(id) return table.contains(to:getCardIds("h"), id) end)
    room:throwCard(to_throw, self.name, to, to)
    if to.dead or player.dead then return end
    local to_get = table.filter(results, function(id) return table.contains(player:getCardIds("h"), id) end)
    if #to_get == 0 then return end
    room:moveCardTo(to_get, Card.PlayerHand, to, fk.ReasonPrey, self.name, nil, false, to.id)
    if player.dead or #to_get < 2 then return end
    local targets = table.map(table.filter(room.alive_players, function(p) return to:inMyAttackRange(p) end), Util.IdMapper)
    if #targets > 0 then
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#kuizhul-damage::"..to.id, self.name, true, true)
      if #targets > 0 then
        room:doIndicate(to.id, targets)
        room:damage{
          from = to,
          to = room:getPlayerById(targets[1]),
          damage = 1,
          skillName = self.name,
        }
        return
      end
    end
    room:removePlayerMark(player, "@lisu_zhu", 1)
  end,
}
lisu:addSkill(lixun)
lisu:addSkill(kuizhul)
Fk:loadTranslationTable{
  ["ty__lisu"] = "李肃",
  ["#ty__lisu"] = "魔使",
  ["illustrator:ty__lisu"] = "alien",
  ["lixun"] = "利熏",
  [":lixun"] = "锁定技，当你受到伤害时，你防止此伤害，然后获得等同于伤害值的“珠”标记。出牌阶段开始时，你进行一次判定，若结果点数小于“珠”数，"..
  "你弃置等同于“珠”数的手牌，若弃牌数不足，则失去不足数量的体力值。",
  ["kuizhul"] = "馈珠",
  [":kuizhul"] = "出牌阶段结束时，你可以选择体力值全场最大的一名其他角色，将手牌摸至与该角色相同（最多摸至五张），然后该角色观看你的手牌，"..
  "弃置任意张手牌并从观看的牌中获得等量的牌，若其获得的牌数大于1，则你选择一项：1.移去一个“珠”；2.令其对其攻击范围内的一名角色造成1点伤害。",
  ["@lisu_zhu"] = "珠",
  ["#kuizhul-choose"] = "馈珠：你可以将手牌补至与一名角色相同，其可以获得你的手牌",
  ["#kuizhul-exchange"] = "馈珠：你可以弃置任意张手牌，获得%src等量的手牌",
  ["#kuizhul-damage"] = "馈珠：选择一名角色令 %dest 对其造成伤害，或点“取消”移去一个“珠”",

  ["$lixun1"] = "利欲熏心，财权保命。",
  ["$lixun2"] = "利益当前，岂不心动？",
  ["$kuizhul1"] = "与君同谋，赠君金珠。",
  ["$kuizhul2"] = "金珠熠熠，都归将军了。",
  ["~ty__lisu"] = "金银珠宝再多，也难买命啊。",
}

--戚宦之争：张让 何进 何太后（OL下位） 冯方 赵忠 穆顺 伏完（同国际服）
local zhangrang = General(extension, "ty__zhangrang", "qun", 3)
Fk:addQmlMark{
  name = "ty__taoluan",
  how_to_show = function(_, value)
    if type(value) ~= "table" then return " " end
    if value.loseHp then return Fk:translate("lose_hp") end
    if type(value.suits) ~= "table" or #value.suits == 0 then return " " end
    return table.concat(table.map(value.suits, function(suit)
      return Fk:translate(Card.getSuitString({ suit = suit }, true))
    end), "")
  end,
  qml_path = "packages/utility/qml/ViewPile"
}
local taoluan = fk.CreateViewAsSkill{
  name = "ty__taoluan",
  pattern = ".",
  prompt = "#ty__taoluan-prompt",
  interaction = function()
    local all_names = U.getAllCardNames("bt")
    return U.CardNameBox {
      choices = U.getViewAsCardNames(Self, "ty__taoluan", all_names, nil, Self:getTableMark("@[ty__taoluan]").value),
      all_choices = all_names,
      default_choice = "AskForCardsChosen",
    }
  end,
  card_filter = function(self, to_select, selected)
    if Fk.all_card_types[self.interaction.data] == nil then return false end
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    if card.suit == Card.NoSuit then return false end
    local mark = Self:getMark("@[ty__taoluan]")
    return type(mark) ~= "table" or not table.contains(mark.suits, card.suit)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or Fk.all_card_types[self.interaction.data] == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("@[ty__taoluan]")
    if type(mark) ~= "table" then
      mark = {
        value = {},
        suits = {},
        loseHp = false
      }
    end
    table.insert(mark.value, use.card.trueName)
    table.insert(mark.suits, use.card.suit)
    player.room:setPlayerMark(player, "@[ty__taoluan]", mark)
  end,
  after_use = function (self, player, use)
    local room = player.room
    if player.dead or #room.alive_players < 2 then return end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local type = use.card:getTypeString()
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#ty__taoluan-choose:::"..type, self.name, false)
    local to = room:getPlayerById(tos[1])
    local card = room:askForCard(to, 1, 1, true, self.name, true, ".|.|.|.|.|^"..type, "#ty__taoluan-card:"..player.id.."::"..type)
    if #card > 0 then
      room:obtainCard(player, card[1], false, fk.ReasonGive, to.id)
    elseif player:hasSkill(self, true) then
      room:invalidateSkill(player, "ty__taoluan", "-turn")
      local mark = player:getTableMark("@[ty__taoluan]")
      mark.loseHp = true
      room:setPlayerMark(player, "@[ty__taoluan]", mark)
    end
  end,
  enabled_at_play = function(self, player)
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) ~= "table" or #mark.suits < 4
  end,
  enabled_at_response = function(self, player, response)
    local mark = player:getMark("@[ty__taoluan]")
    return not response and type(mark) ~= "table" or
      (#mark.suits < 4 and #U.getViewAsCardNames(player, "ty__taoluan",  U.getAllCardNames("bt"), nil, mark.value) > 0)
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "@[ty__taoluan]", 0)
  end,
}
local taoluan_trigger = fk.CreateTriggerSkill{
  name = "#ty__taoluan_trigger",
  anim_type = "negative",
  main_skill = taoluan,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) == "table" and mark.loseHp
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) == "table" and (#mark.suits > 0 or mark.loseHp)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@[ty__taoluan]")
    mark.suits = {}
    mark.loseHp = false
    player.room:setPlayerMark(player, "@[ty__taoluan]", mark)
  end,
}
taoluan:addRelatedSkill(taoluan_trigger)
zhangrang:addSkill(taoluan)
Fk:loadTranslationTable{
  ["ty__zhangrang"] = "张让",
  ["#ty__zhangrang"] = "窃幸绝禋",
  ["designer:ty__zhangrang"] = "千幻",
  ["illustrator:ty__zhangrang"] = "zoo", -- 史诗*宦势控权

  ["ty__taoluan"] = "滔乱",
  [":ty__taoluan"] = "每种牌名限一次、每回合每种花色限一次，当你需要使用基本牌/普通锦囊牌时，你可以将一张牌当此基本牌/普通锦囊牌使用，"..
  "然后你令一名其他角色选择：1.将一张不为基本牌/锦囊牌的牌交给你；2.此技能于当前回合内无效，且此回合结束时，你失去1点体力。",
  ["#ty__taoluan_trigger"] = "滔乱",
  ["@[ty__taoluan]"] = "滔乱",
  ["#ty__taoluan-choose"] = "滔乱：令一名其他角色交给你一张非%arg，或你失去1点体力且本回合〖滔乱〗失效",
  ["#ty__taoluan-card"] = "滔乱：你需交给 %src 一张非%arg，否则其失去1点体力且本回合〖滔乱〗失效",
  ["#ty__taoluan-prompt"] = "滔乱：每牌名限一次，你可将一张牌当任意一张基本牌或普通锦囊牌使用",

  ["$ty__taoluan1"] = "汉室动荡？莫来妖言惑众。",
  ["$ty__taoluan2"] = "自打洒家进宫以来，就独得皇上恩宠。",
  ["~ty__zhangrang"] = "尽失权柄，我等难容于天下！",
}

local hejin = General(extension, "ty__hejin", "qun", 4)
local ty__mouzhu = fk.CreateActiveSkill{
  name = "ty__mouzhu",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= Self.id and (target:distanceTo(Self) == 1 or target.hp == Self.hp) and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, p in ipairs(effect.tos) do
      local target = room:getPlayerById(p)
      if player.dead or target.dead then return end
      if not target:isKongcheng() then
        local card = room:askForCard(target, 1, 1, false, self.name, false, ".", "#mouzhu-give::"..player.id)
        room:obtainCard(player, card[1], false, fk.ReasonGive, target.id)
        if #player.player_cards[Player.Hand] > #target.player_cards[Player.Hand] then
          local choice = room:askForChoice(target, {"slash", "duel"}, self.name)
          room:useVirtualCard(choice, nil, target, player, self.name, true)
        end
      end
    end
  end,
}
local ty__yanhuo = fk.CreateTriggerSkill{
  name = "ty__yanhuo",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#yanhuo-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:setTag("yanhuo", true)
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.room:getTag("yanhuo") and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
}
hejin:addSkill(ty__mouzhu)
hejin:addSkill(ty__yanhuo)
Fk:loadTranslationTable{
  ["ty__hejin"] = "何进",
  ["#ty__hejin"] = "色厉内荏",
  ["cv:ty__hejin"] = "冷泉月夜",
  ["illustrator:ty__hejin"] = "凝聚永恒",
  ["ty__mouzhu"] = "谋诛",
  [":ty__mouzhu"] = "出牌阶段限一次，你可以选择任意名与你距离为1或体力值与你相同的其他角色，依次将一张手牌交给你，然后若其手牌数小于你，"..
  "其视为对你使用一张【杀】或【决斗】。",
  ["ty__yanhuo"] = "延祸",
  [":ty__yanhuo"] = "当你死亡时，你可以令本局接下来所有【杀】的伤害基数值+1。",
  ["#mouzhu-give"] = "谋诛：交给%dest一张手牌，然后若你手牌数小于其，视为你对其使用【杀】或【决斗】",
  ["#yanhuo-invoke"] = "延祸：你可以令本局接下来所有【杀】的伤害基数值+1！",

  ["$ty__mouzhu1"] = "尔等祸乱朝纲，罪无可赦，按律当诛！",
  ["$ty__mouzhu2"] = "天下人之怨皆系于汝等，还不快认罪伏法？",
  ["$ty__yanhuo1"] = "你们，都要为我殉葬！",
  ["$ty__yanhuo2"] = "杀了我，你们也别想活！",
  ["~ty__hejin"] = "诛宦不成，反遭其害，遗笑天下人矣……",
}

local fengfang = General(extension, "fengfang", "qun", 3)
local diting = fk.CreateTriggerSkill{
  name = "diting",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Play and not target:isKongcheng() and
      target:inMyAttackRange(player) and player.hp > 0  --fxxk buqu
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#diting-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = table.random(target:getCardIds("h"), math.min(target:getHandcardNum(), player.hp))
    local id = room:askForCardsChosen(player, target, 1, 1, {card_data = {{target.general, cards}}}, self.name)[1]
    room:setPlayerMark(target, "diting_"..player.id.."-phase", id)
  end,
}
local diting_trigger = fk.CreateTriggerSkill{
  name = "#diting_trigger",
  mute = true,
  events = {fk.TargetSpecified, fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:usedSkillTimes("diting", Player.HistoryPhase) > 0 and target:getMark("diting_"..player.id.."-phase") ~= 0 and not player.dead then
      if event == fk.TargetSpecified then
        return data.card:getEffectiveId() == target:getMark("diting_"..player.id.."-phase") and
          table.contains(AimGroup:getAllTargets(data.tos), player.id)
      elseif event == fk.CardUsing then
        return data.card:getEffectiveId() == target:getMark("diting_"..player.id.."-phase") and
          (not data.tos or not table.contains(TargetGroup:getRealTargets(data.tos), player.id))
      elseif event == fk.EventPhaseEnd then
        return target.phase == Player.Play and table.contains(target:getCardIds("h"), target:getMark("diting_"..player.id.."-phase"))
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("diting")
    if event == fk.TargetSpecified then
      room:notifySkillInvoked(player, "diting", "defensive")
      table.insertIfNeed(data.nullifiedTargets, player.id)
    elseif event == fk.CardUsing then
      room:notifySkillInvoked(player, "diting", "drawcard")
      player:drawCards(2, "diting")
    elseif event == fk.EventPhaseEnd then
      room:notifySkillInvoked(player, "diting", "control")
      local id = target:getMark("diting_"..player.id.."-phase")
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local bihuo = fk.CreateTriggerSkill{
  name = "bihuo",
  mute = true,
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and data.from ~= data.to
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = (event == fk.Damaged) and "#bihuo-plus" or "#bihuo-minus"
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper), 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local to = room:getPlayerById(self.cost_data)
    if event == fk.Damaged then
      room:notifySkillInvoked(player, self.name, "support")
      room:setPlayerMark(to, "@bihuo", to:getMark("@bihuo") + 1)
    else
      room:notifySkillInvoked(player, self.name, "control")
      room:setPlayerMark(to, "@bihuo", to:getMark("@bihuo") - 1)
    end
  end,
}
local bihuo_trigger = fk.CreateTriggerSkill{
  name = "#bihuo_trigger",
  mute = true,
  events = {fk.TurnStart, fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.TurnStart then
        return player:getMark("@bihuo") ~= 0
      else
        return player:getMark("@bihuo-turn") ~= 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:setPlayerMark(player, "@bihuo-turn", player:getMark("@bihuo"))
      room:setPlayerMark(player, "@bihuo", 0)
    else
      data.n = data.n + player:getMark("@bihuo-turn")
    end
  end,
}
diting:addRelatedSkill(diting_trigger)
bihuo:addRelatedSkill(bihuo_trigger)
fengfang:addSkill(diting)
fengfang:addSkill(bihuo)
Fk:loadTranslationTable{
  ["fengfang"] = "冯方",
  ["#fengfang"] = "监彻京师",
  ["designer:fengfang"] = "梦魇狂朝",
  ["illustrator:fengfang"] = "游漫美绘",
  ["diting"] = "谛听",
  [":diting"] = "其他角色出牌阶段开始时，若你在其攻击范围内，你可以观看其X张手牌（X为你的体力值），然后秘密选择其中一张。若如此做，本阶段"..
  "该角色使用此牌指定你为目标后，此牌对你无效；若没有指定你为目标，你摸两张牌；若本阶段结束时此牌仍在其手牌中，你获得之。",
  ["bihuo"] = "避祸",
  [":bihuo"] = "当你受到其他角色造成的伤害后，你可令一名角色下回合摸牌阶段摸牌数+1；当你对其他角色造成伤害后，你可令一名角色下回合摸牌阶段摸牌数-1。",
  ["#diting-invoke"] = "谛听：你可以观看 %dest 的手牌并秘密选择一张产生效果",
  ["#bihuo-plus"] = "避祸：你可以令一名角色下回合摸牌阶段摸牌数+1",
  ["#bihuo-minus"] = "避祸：你可以令一名角色下回合摸牌阶段摸牌数-1",
  ["@bihuo"] = "避祸",
  ["@bihuo-turn"] = "避祸",

  ["$diting1"] = "奉命查验，还请配合。",
  ["$diting2"] = "且容我查验一二。",
  ["$bihuo1"] = "董卓乱政，京师不可久留。",
  ["$bihuo2"] = "权臣当朝，不如早日脱身。",
  ["~fengfang"] = "掌控校事，为人所忌。",
}

local zhaozhong = General(extension, "zhaozhong", "qun", 6)
local yangzhong = fk.CreateTriggerSkill{
  name = "yangzhong",
  anim_type = "offensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and not data.to.dead and
      #data.from:getCardIds{Player.Hand, Player.Equip} > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askForDiscard(data.from, 2, 2, true, self.name, true, ".", "#yangzhong-invoke::"..data.to.id, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, data.from, data.from)
    if not data.to.dead then
      room:loseHp(data.to, 1, self.name)
    end
  end
}
local huangkong = fk.CreateTriggerSkill{
  name = "huangkong",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isKongcheng() and player.phase == Player.NotActive and
      (data.card:isCommonTrick() or data.card.trueName == "slash")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
zhaozhong:addSkill(yangzhong)
zhaozhong:addSkill(huangkong)
Fk:loadTranslationTable{
  ["zhaozhong"] = "赵忠",
  ["#zhaozhong"] = "骄纵窃幸",
  ["cv:zhaozhong"] = "贾志超219",
  ["illustrator:zhaozhong"] = "mumu",
  ["yangzhong"] = "殃众",
  [":yangzhong"] = "当你造成或受到伤害后，伤害来源可以弃置两张牌，令受到伤害的角色失去1点体力。",
  ["huangkong"] = "惶恐",
  [":huangkong"] = "锁定技，你的回合外，当你成为【杀】或普通锦囊牌的目标后，若你没有手牌，你摸两张牌。",
  ["#yangzhong-invoke"] = "殃众：你可以弃置两张牌，令 %dest 失去1点体力",

  ["$yangzhong1"] = "窃权利己，弄祸殃众！",
  ["$yangzhong2"] = "宦祸所起，池鱼所终！",
  ["$huangkong1"] = "满腹忠心，如履薄冰！",
  ["$huangkong2"] = "咱家乃皇帝之母，能有什么坏心思？",
  ["~zhaozhong"] = "咱家忠心可鉴啊！！",
}

local mushun = General(extension, "mushun", "qun", 4)
local jinjianm = fk.CreateTriggerSkill{
  name = "jinjianm",
  anim_type = "defensive",
  events = {fk.Damage, fk.Damaged},
  on_cost = Util.TrueFunc,
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
    if player:hasSkill(self) and player:isKongcheng() and player.phase == Player.NotActive and
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
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:removePlayerMark(player, "@mushun_jin", 1)
      player:drawCards(2, self.name)
    else
      player:broadcastSkillInvoke(self.name, 2)
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
  ["#mushun"] = "疾风劲草",
  ["illustrator:mushun"] = "君桓文化",
  ["jinjianm"] = "劲坚",
  [":jinjianm"] = "当你造成或受到伤害后，你获得一个“劲”标记，然后你可以与伤害来源拼点：若你赢，你回复1点体力。每有一个“劲”你的攻击范围+1。",
  ["shizhao"] = "失诏",
  [":shizhao"] = "锁定技，你的回合外，当你每回合第一次失去最后一张手牌时：若你有“劲”，你移去一个“劲”并摸两张牌；没有“劲”，你本回合下一次受到的伤害值+1。",
  ["@mushun_jin"] = "劲",
  ["#jinjianm-invoke"] = "劲坚：你可以与 %dest 拼点，若赢，你回复1点体力",
  ["@shizhao-turn"] = "失诏",

  ["$jinjianm1"] = "卑微之人，脊中亦有七寸硬骨！",
  ["$jinjianm2"] = "目不识丁，胸中却含三分浩气！",
  ["$shizhao1"] = "并无夹带，阁下多心了。",
  ["$shizhao2"] = "将军多虑，顺安有忤逆之心？",
  ["~mushun"] = "这，何来的大风？",
}

--兵临城下：牛金 糜芳傅士仁 李采薇 赵俨 王威 李异谢旌 孙桓 孟达 是仪 孙狼
local niujin = General(extension, "ty__niujin", "wei", 4)
local cuirui = fk.CreateActiveSkill{
  name = "cuirui",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self.hp
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < Self.hp and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      local card = room:askForCardChosen(player, p, "h", self.name)
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
}
local ty__liewei = fk.CreateTriggerSkill{
  name = "ty__liewei",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and
    (player.phase ~= Player.NotActive or player:usedSkillTimes(self.name) < player.hp)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
niujin:addSkill(cuirui)
niujin:addSkill(ty__liewei)
Fk:loadTranslationTable{
  ["ty__niujin"] = "牛金",
  ["#ty__niujin"] = "独进的兵胆",
  ["illustrator:ty__niujin"] = "游漫美绘",
  ["cuirui"] = "摧锐",
  [":cuirui"] = "限定技，出牌阶段，你可以选择至多X名其他角色（X为你的体力值），你获得这些角色各一张手牌。",
  ["ty__liewei"] = "裂围",
  [":ty__liewei"] = "每回合限X次（X为你的体力值，你的回合内无此限制），有角色进入濒死状态时，你可以摸一张牌。",

  ["$cuirui1"] = "摧折锐气，未战先衰。",
  ["$cuirui2"] = "挫其锐气，折其旌旗。",
  ["$ty__liewei1"] = "都给我交出来！",
  ["$ty__liewei2"] = "还有点用，暂且饶你一命！",
  ["~ty__niujin"] = "这酒有毒！",
}

local ty__mifangfushiren = General(extension, "ty__mifangfushiren", "shu", 4)
local ty__fengshih = fk.CreateTriggerSkill{
  name = "ty__fengshih",
  anim_type = "offensive",
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.TargetSpecified then
        if not data.firstTarget then return false end
        local room = player.room
        local n = player:getHandcardNum()
        local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
          local to = room:getPlayerById(id)
          return not to.dead and to:getHandcardNum() < n
        end)
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      else
        local from = player.room:getPlayerById(data.from)
        if not from.dead and from:getHandcardNum() > player:getHandcardNum() then
          self.cost_data = {data.from}
          return true
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(self.cost_data)
    if #targets == 1 then
      if room:askForSkillInvoke(player, self.name, nil, "#ty__fengshih-invoke::" .. targets[1]) then
        room:doIndicate(player.id, targets)
        self.cost_data = targets
        return true
      end
    else
      targets = room:askForChoosePlayers(player, targets, 1, 1, "#ty__fengshih-choose", self.name, true)
      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:askForDiscard(player, 1, 1, true, self.name, false)
    if player.dead then return false end
    if not to:isNude() then
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({card}, self.name, to, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__fengshih = data.extra_data.ty__fengshih or {}
    if event == fk.TargetSpecified then
      table.insert(data.extra_data.ty__fengshih, to.id)
    else
      table.insert(data.extra_data.ty__fengshih, player.id)
    end
  end,
}
local ty__fengshih_delay = fk.CreateTriggerSkill {
  name = "#ty__fengshih_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data[1]
    return use.extra_data and use.extra_data.ty__fengshih and table.contains(use.extra_data.ty__fengshih, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
ty__fengshih:addRelatedSkill(ty__fengshih_delay)
ty__mifangfushiren:addSkill(ty__fengshih)

Fk:loadTranslationTable{
  ["ty__mifangfushiren"] = "糜芳傅士仁",
  ["#ty__mifangfushiren"] = "进退维谷",
  ["illustrator:ty__mifangfushiren"] = "游漫美绘",
  ["ty__fengshih"] = "锋势",
  [":ty__fengshih"] = "当你使用牌指定第一个目标后，若其中一名目标角色手牌数小于你，你可以弃置你与其各一张牌，然后此牌对其伤害+1；"..
  "当你成为其他角色使用牌的目标后，若你的手牌数小于其，你可以弃置你与其各一张牌，然后此牌对你伤害+1。",

  ["#ty__fengshih-invoke"] = "是否对 %dest 发动 锋势，弃置你与其各一张牌",
  ["#ty__fengshih-choose"] = "是否发动 锋势，弃置你与一名目标角色的各一张牌",
  ["#ty__fengshih_delay"] = "锋势",

  ["$ty__fengshih1"] = "锋芒之锐，势不可挡！",
  ["$ty__fengshih2"] = "势须砥砺，就其锋芒。",
  ["~ty__mifangfushiren"] = "愧对将军。",
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
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("yijiao1") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    if not self.interaction.data then self.interaction.data = 1 end  --for AI
    room:addPlayerMark(target, "yijiao1", 10 * self.interaction.data)
    room:setPlayerMark(target, "@yijiao", target:getMark("yijiao1"))
    room:setPlayerMark(target, "yijiao_src", effect.from)
  end,
}
local yijiao_record = fk.CreateTriggerSkill{
  name = "#yijiao_record",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and not player.dead and target:getMark("yijiao_src") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("yijiao2") - target:getMark("yijiao1")
    room:doIndicate(player.id, {target.id})
    if n < 0 then
      player:broadcastSkillInvoke("yijiao", 1)
      room:notifySkillInvoked(player, "yijiao", "control")
      if not target:isKongcheng() then
        local cards = table.filter(target.player_cards[Player.Hand], function (id)
          return not target:prohibitDiscard(Fk:getCardById(id))
        end)
        if #cards > 0 then
          local x = math.random(1, math.min(3, #cards))
          if x < #cards then
            cards = table.random(cards, x)
          end
          room:throwCard(cards, "yijiao", target, target)
        end
      end
    elseif n == 0 then
      player:broadcastSkillInvoke("yijiao", 2)
      room:notifySkillInvoked(player, "yijiao", "support")
      player:drawCards(2, "yijiao")
      target:gainAnExtraTurn(true)
    else
      player:broadcastSkillInvoke("yijiao", 2)
      room:notifySkillInvoked(player, "yijiao", "drawcard")
      player:drawCards(3, "yijiao")
    end
  end,

  refresh_events = {fk.CardUsing, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return target == player and player:getMark("yijiao1") ~= 0 and player.phase ~= Player.NotActive and data.card.number > 0
    elseif event == fk.AfterTurnEnd then
      return target == player and player:getMark("yijiao1") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "yijiao2", data.card.number)
      room:setPlayerMark(player, "@yijiao", string.format("%d/%d", target:getMark("yijiao1"), target:getMark("yijiao2")))
    elseif event == fk.AfterTurnEnd then
      room:setPlayerMark(player, "yijiao1", 0)
      room:setPlayerMark(player, "yijiao2", 0)
      room:setPlayerMark(player, "@yijiao", 0)
      room:setPlayerMark(player, "yijiao_src", 0)
    end
  end,
}
local qibie = fk.CreateTriggerSkill{
  name = "qibie",
  anim_type = "drawcard",
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#qibie-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum()
    player:throwAllCards("h")
    if player.dead then return end
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
  ["#licaiwei"] = "啼雨孤鸯",
  ["illustrator:licaiwei"] = "Jzeo",
  ["yijiao"] = "异教",
  [":yijiao"] = "出牌阶段限一次，你可以选择一名其他角色并选择一个1~4的数字，该角色获得十倍的“异”标记；"..
  "有“异”标记的角色结束阶段，若其本回合使用牌的点数之和：<br>"..
  "1.小于“异”标记数，其随机弃置一至三张手牌；<br>"..
  "2.等于“异”标记数，你摸两张牌且其于本回合结束后进行一个额外的回合；<br>"..
  "3.大于“异”标记数，你摸三张牌。",
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

local zhaoyan = General(extension, "ty__zhaoyan", "wei", 3)
local funing = fk.CreateTriggerSkill{
  name = "funing",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#funing-invoke:::"..player:usedSkillTimes(self.name, Player.HistoryTurn) + 1)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    player.room:askForDiscard(player, n, n, true, self.name, false)
  end,
}
local bingji = fk.CreateActiveSkill{
  name = "bingji",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#bingji",
  can_use = function(self, player)
    if not player:isKongcheng() then
      local suit = Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString(true)
      return not table.contains(player:getTableMark("@bingji-phase"), suit)
      and table.every(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getSuitString(true) == suit end)
    end
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:addTableMark(player, "@bingji-phase", Fk:getCardById(player.player_cards[Player.Hand][1]):getSuitString(true))
    player:showCards(player.player_cards[Player.Hand])
    local targets = {["peach"] = {}, ["slash"] = {}}
    local choices = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player:canUseTo(Fk:cloneCard("slash"), p, {bypass_times = true}) then
        table.insert(targets["slash"], p.id)
      end
      local peach = Fk:cloneCard("peach")
      if not player:prohibitUse(peach) and not player:isProhibited(p, peach) and p:isWounded() then
        table.insert(targets["peach"], p.id)
      end
    end
    if #targets["peach"] > 0 then table.insert(choices, "peach") end
    if #targets["slash"] > 0 then table.insert(choices, "slash") end
    if #choices == 0 then return end
    local choice = room:askForChoice(player, choices, self.name, "#bingji-choice", false, {"slash", "peach"})
    local tos = room:askForChoosePlayers(player, targets[choice], 1, 1, "#bingji-choose:::"..choice, self.name, false)
    local to = room:getPlayerById(tos[1])
    room:useVirtualCard(choice, nil, player, to, self.name, true)
  end
}
zhaoyan:addSkill(funing)
zhaoyan:addSkill(bingji)
Fk:loadTranslationTable{
  ["ty__zhaoyan"] = "赵俨",
  ["#ty__zhaoyan"] = "扬历干功",
  ["cv:ty__zhaoyan"] = "冰霜墨菊",
  ["illustrator:ty__zhaoyan"] = "游漫美绘",
  ["designer:ty__zhaoyan"] = "追风青年",

  ["funing"] = "抚宁",
  [":funing"] = "当你使用一张牌时，你可以摸两张牌然后弃置X张牌（X为此技能本回合发动次数）。",
  ["bingji"] = "秉纪",
  [":bingji"] = "出牌阶段每种花色限一次，若你的手牌均为同一花色，则你可以展示所有手牌（至少一张），然后视为对一名其他角色使用一张【杀】（有距离限制且不计入次数）或一张【桃】。",
  ["#funing-invoke"] = "抚宁：你可以摸两张牌，然后弃置%arg张牌",
  ["@bingji-phase"] = "秉纪",
  ["#bingji-choice"] = "秉纪：选择对其他角色使用的牌名",
  ["#bingji-choose"] = "秉纪：视为对一名其他角色使用【%arg】",
  ["#bingji"] = "秉纪：展示所有手牌，视为对一名其他角色使用【杀】或【桃】",

  ["$funing1"] = "为国效力，不可逞一时之气。",
  ["$funing2"] = "诸将和睦，方为国家之幸。",
  ["$bingji1"] = "权其轻重，而后施令。",
  ["$bingji2"] = "罪而后赦，以立恩威。",
  ["~ty__zhaoyan"] = "背信食言，当有此劫……",
}

local wangwei = General(extension, "wangwei", "qun", 4)
local ruizhan = fk.CreateTriggerSkill{
  name = "ruizhan",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Start and target:getHandcardNum() >= target.hp and
      not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#ruizhan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, self.name)
    if target.dead or player:isProhibited(target, Fk:cloneCard("slash")) then return end
    if pindian.results[target.id].winner == player or
      pindian.fromCard.trueName == "slash" or pindian.results[target.id].toCard.trueName == "slash" then
      local card = Fk:cloneCard("slash")
      card.skillName = self.name
      local use = {
        from = player.id,
        tos = {{target.id}},
        card = card,
      }
      room:useCard(use)
      if pindian.results[target.id].winner == player and
        (pindian.fromCard.trueName == "slash" or pindian.results[target.id].toCard.trueName == "slash")
        and use.damageDealt and use.damageDealt[target.id] and not player.dead and not target.dead and not target:isNude() then
        local id = room:askForCardChosen(player, target, "he", self.name, "#ruizhan-prey::"..target.id)
        room:moveCardTo(Fk:getCardById(id), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
  end
}
local shilie = fk.CreateActiveSkill{
  name = "shilie",
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  derived_piles = "$shilie",
  prompt = function (self)
    return "#shilie-"..self.interaction.data
  end,
  interaction = function(self)
    return UI.ComboBox { choices = {"recover", "loseHp"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "recover" then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
      if not player:isNude() then
        local cards = player:getCardIds("he")
        if #cards > 2 then
          cards = room:askForCard(player, 2, 2, true, self.name, false, ".", "#shilie-put")
        end
        player:addToPile("$shilie", cards, false, self.name)
        local n = #player:getPile("$shilie") - #room.players
        if n > 0 then
          local to_remove = table.slice(player:getPile("$shilie"), 1, n + 1)
          room:moveCardTo(to_remove, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
        end
      end
    else
      room:loseHp(player, 1, self.name)
      if player.dead then return end
      local cards = room:askForCard(player, math.min(#player:getPile("$shilie"), 2), 2, false, self.name, false,
        ".|.|.|$shilie", "#shilie-get", "$shilie")
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
    end
  end,
}
local shilie_trigger = fk.CreateTriggerSkill{
  name = "#shilie_trigger",
  mute = true,
  main_skill = shilie,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true) and #player:getPile("$shilie") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    if data.damage and data.damage.from then
      table.removeOne(targets, data.damage.from.id)
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#shilie-choose", "shilie", true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shilie")
    room:notifySkillInvoked(player, "shilie", "support")
    local to = room:getPlayerById(self.cost_data)
    room:moveCardTo(player:getPile("$shilie"), Card.PlayerHand, to, fk.ReasonJustMove, "shilie", nil, false, player.id)
  end,
}
shilie:addRelatedSkill(shilie_trigger)
wangwei:addSkill(ruizhan)
wangwei:addSkill(shilie)
Fk:loadTranslationTable{
  ["wangwei"] = "王威",
  ["#wangwei"] = "苍心辟道",
  ["illustrator:wangwei"] = "荧光笔工作室",
  ["ruizhan"] = "锐战",
  [":ruizhan"] = "其他角色准备阶段，若其手牌数不小于体力值，你可以与其拼点：若你赢或者拼点牌中有【杀】，你视为对其使用一张【杀】；"..
  "若两项均满足且此【杀】造成伤害，你获得其一张牌。",
  ["shilie"] = "示烈",
  [":shilie"] = "出牌阶段限一次，你可以选择一项：1.回复1点体力，然后将两张牌置为“示烈”牌（不足则全放，总数不能大于游戏人数）；"..
  "2.失去1点体力，然后获得两张“示烈”牌。<br>你死亡时，你可将“示烈”牌交给除伤害来源外的一名其他角色。",
  ["#ruizhan-invoke"] = "锐战：你可与 %dest 拼点，若赢或拼点牌中有【杀】，视为对其使用【杀】",
  ["#ruizhan-prey"] = "锐战：获得 %dest 一张牌",
  ["$shilie"] = "示烈",
  ["#shilie-recover"] = "示烈：回复1点体力，将两张牌置为“示烈”牌",
  ["#shilie-loseHp"] = "示烈：失去1点体力，获得两张牌“示烈”牌",
  ["#shilie-put"] = "示烈：将两张牌置为“示烈”牌",
  ["#shilie-get"] = "示烈：获得两张“示烈”牌",
  ["#shilie-choose"] = "示烈：你可以将所有“示烈”牌交给一名角色",

  ["$ruizhan1"] = "敌势汹汹，当急攻以挫其锐。",
  ["$ruizhan2"] = "威愿领骑兵千人，以破敌前军。",
  ["$shilie1"] = "荆州七郡，亦有怀义之人！",
  ["$shilie2"] = "食禄半生，安能弃旧主而去！",
  ["~wangwei"] = "后有追兵，主公先行！",
}

local liyixiejing = General(extension, "liyixiejing", "wu", 4)
local douzhen = fk.CreateTriggerSkill{
  name = "douzhen",
  anim_type = "switch",
  switch_skill_name = "douzhen",
  events = {fk.CardUsing, fk.CardResponding},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
    not data.card:isVirtual() and table.contains(data.card.skillNames, "douzhen")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "duel" then
      local targets = TargetGroup:getRealTargets(data.tos)
      room:doIndicate(player.id, targets)
      for _, id in ipairs(targets) do
        local p = room:getPlayerById(id)
        if not (p.dead or p:isNude()) then
          local c = room:askForCardChosen(player, p, "he", "douzhen")
          room:obtainCard(player, c, false, fk.ReasonPrey)
        end
        if player.dead then return end
      end
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and not data.card:isVirtual() and table.contains(data.card.skillNames, "douzhen")
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local douzhen_filter = fk.CreateFilterSkill{
  name = "#douzhen_filter",
  anim_type = "offensive",
  card_filter = function(self, card, player)
    if player:hasSkill(douzhen) and player.phase ~= Player.NotActive and card.type == Card.TypeBasic and
    table.contains(player.player_cards[Player.Hand], card.id) then
      if player:getSwitchSkillState("douzhen", false) == fk.SwitchYang then
        return card.color == Card.Black
      else
        return card.color == Card.Red
      end
    end
  end,
  view_as = function(self, card, player)
    local name = "slash"
    if player:getSwitchSkillState("douzhen", false) == fk.SwitchYang then
      name = "duel"
    end
    local c = Fk:cloneCard(name, card.suit, card.number)
    c.skillName = "douzhen"
    return c
  end,
}
local douzhen_targetmod = fk.CreateTargetModSkill{
  name = "#douzhen_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and card.trueName == "slash" and table.contains(card.skillNames, "douzhen") and scope == Player.HistoryPhase
  end,
}
douzhen:addRelatedSkill(douzhen_filter)
douzhen:addRelatedSkill(douzhen_targetmod)
liyixiejing:addSkill(douzhen)
Fk:loadTranslationTable{
  ["liyixiejing"] = "李异谢旌",
  ["#liyixiejing"] = "踵蹑袭进",
  ["designer:liyixiejing"] = "七哀",
  ["illustrator:liyixiejing"] = "匠人绘",
  ["douzhen"] = "斗阵",
  [":douzhen"] = "转换技，锁定技，你的回合内，阳：你的黑色基本牌视为【决斗】，且使用时获得目标一张牌；阴：你的红色基本牌视为【杀】，且使用时无次数限制。",

  ["#douzhen_filter"] = "斗阵",

  ["$douzhen1"] = "擂鼓击柝，庆我兄弟凯旋。",
  ["$douzhen2"] = "匹夫欺我江东无人乎。",
  ["~liyixiejing"] = "蜀军凶猛，虽力战犹不敌……",
}

local sunhuan = General(extension, "sunhuan", "wu", 4)
local niji = fk.CreateTriggerSkill{
  name = "niji",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return target == player and player:hasSkill(self) and data.card.type ~= Card.TypeEquip
    elseif event == fk.EventPhaseStart then
      return target.phase == Player.Finish and not player:isKongcheng() and
        table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand-turn") > 0 end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      return player.room:askForSkillInvoke(player, self.name, nil, "#niji-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetConfirmed then
      player:drawCards(1, self.name, nil, "@@niji-inhand-turn")
    else
      local cards = table.filter(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id):getMark("@@niji-inhand-turn") > 0 end)
      if player:hasSkill(self) then
        room:askForUseRealCard(player, cards, self.name, "#niji-use", {
          bypass_times = true,
          extraUse = true,
        })
      end
      cards = table.filter(cards, function(id) return table.contains(player.player_cards[Player.Hand], id) end)
      if #cards > 0 then
        room:delay(800)
        room:throwCard(cards, self.name, player, player)
      end
    end
  end,
}
sunhuan:addSkill(niji)
Fk:loadTranslationTable{
  ["sunhuan"] = "孙桓",
  ["#sunhuan"] = "扼龙决险",
  ["designer:sunhuan"] = "坑坑",
  ["illustrator:sunhuan"] = "一意动漫",

  ["niji"] = "逆击",
  [":niji"] = "当你成为非装备牌的目标后，你可以摸一张牌，本回合结束阶段弃置这些牌，弃置前你可以先使用其中一张牌。",
  ["@@niji-inhand-turn"] = "逆击",
  ["#niji-invoke"] = "逆击：你可以摸一张牌，本回合结束阶段弃置之",
  ["#niji-use"] = "逆击：即将弃置所有“逆击”牌，你可以先使用其中一张牌",

  ["$niji1"] = "善战者后动，一击而毙敌。",
  ["$niji2"] = "我所善者，后发制人尔。",
  ["~sunhuan"] = "此建功立业之时，奈何……",
}

local mengda = General(extension, "ty__mengda", "wei", 4)
mengda.subkingdom = "shu"
local libang = fk.CreateActiveSkill{
  name = "libang",
  anim_type = "control",
  card_num = 1,
  target_num = 2,
  prompt = "#libang",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < 2 and to_select ~= Self.id and #selected_cards == 1
    and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos, false)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local cards = {}
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    local id1 = room:askForCardChosen(player, target1, "he", self.name)
    room:obtainCard(player, id1, true, fk.ReasonPrey)
    table.insert(cards, id1)
    if not player.dead and not target2:isNude() then
      local id2 = room:askForCardChosen(player, target2, "he", self.name)
      room:obtainCard(player.id, id2, true, fk.ReasonPrey)
      table.insert(cards, id2)
    end
    if player.dead then return end
    player:showCards(cards)
    local pattern = "."
    local suits = {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).color == Card.Red then
        table.insertIfNeed(suits, "heart")
        table.insertIfNeed(suits, "diamond")
      elseif Fk:getCardById(id).color == Card.Black then
        table.insertIfNeed(suits, "spade")
        table.insertIfNeed(suits, "club")
      end
    end
    if #suits > 0 then
      pattern = ".|.|"..table.concat(suits, ",")
    end
    local judge = {
      who = player,
      reason = self.name,
      pattern = pattern,
      extra_data = {effect.tos, cards},
    }
    room:judge(judge)
  end,
}
local libang_delay = fk.CreateTriggerSkill{
  name = "#libang_delay",
  mute = true,
  events = {fk.FinishJudge},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == "libang" and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.color == Card.NoColor then return end
    local targets = data.extra_data[1]
    for i = 2, 1, -1 do
      if room:getPlayerById(targets[i]).dead then
        table.removeOne(targets, targets[i])
      end
    end
    if not data.card:matchPattern(data.pattern) then
      if #targets == 0 or #player:getCardIds{Player.Hand, Player.Equip} < 2 then
        room:loseHp(player, 1, "libang")
      else
        local _,dat = room:askForUseActiveSkill(player, "libang_active", "#libang-card", true, {targets = targets})
        if dat then
          room:obtainCard(dat.targets[1], dat.cards, false, fk.ReasonGive, player.id)
        else
          room:loseHp(player, 1, "libang")
        end
      end
    else
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
      end
      targets = table.filter(targets, function(id) return not player:isProhibited(room:getPlayerById(id), Fk:cloneCard("slash")) end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#libang-slash", "libang", false)
      room:useVirtualCard("slash", nil, player, room:getPlayerById(tos[1]), "libang")
    end
  end,
}
local libang_active = fk.CreateActiveSkill{
  name = "libang_active",
  card_num = 2,
  target_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and table.contains(self.targets, to_select) and #selected_cards == 2
  end,
}
local wujie = fk.CreateTriggerSkill{
  name = "wujie",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared, fk.BuryVictim},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.AfterCardUseDeclared then
        return player:hasSkill(self) and data.card.color == Card.NoColor
      else
        return player:hasSkill(self, false, true)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      if not data.extraUse then
        data.extraUse = true
        player:addCardUseHistory(data.card.trueName, -1)
      end
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.skip_reward_punish = true
    end
  end,
}
local wujie_targetmod = fk.CreateTargetModSkill{
  name = "#wujie_targetmod",
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill(wujie) and card and card.color == Card.NoColor
  end,
}
Fk:addSkill(libang_active)
libang:addRelatedSkill(libang_delay)
wujie:addRelatedSkill(wujie_targetmod)
mengda:addSkill(libang)
mengda:addSkill(wujie)
Fk:loadTranslationTable{
  ["ty__mengda"] = "孟达",
  ["#ty__mengda"] = "据国向己",
  ["designer:ty__mengda"] = "傍晚的水豚巴士",
  ["illustrator:ty__mengda"] = "六道目",
  ["libang"] = "利傍",
  [":libang"] = "出牌阶段限一次，你可以弃置一张牌，获得两名其他角色各一张牌并展示，然后你判定，若结果与这两张牌的颜色："..
  "均不同，你交给其中一名角色两张牌或失去1点体力；至少一张相同，你获得判定牌并视为对其中一名角色使用一张【杀】。",
  ["wujie"] = "无节",
  [":wujie"] = "锁定技，你使用的无色牌不计入次数且无距离限制；其他角色杀死你后不执行奖惩。",
  ["#libang-card"] = "利傍：交给其中一名角色两张牌，否则失去1点体力",
  ["#libang-slash"] = "利傍：视为对其中一名角色使用一张【杀】",
  ["#libang"] = "利傍：弃置一张牌，获得两名其他角色各一张牌，然后判定",
  ["libang_active"] = "利傍",
  ["#libang_delay"] = "利傍",

  ["$libang1"] = "天下熙攘，所为者利尔。",
  ["$libang2"] = "我有武力傍身，必可待价而沽。",
  ["$wujie1"] = "腹中有粮则脊自直，非节盈之。",
  ["$wujie2"] = "气节？可当粟米果腹乎！",
  ["~ty__mengda"] = "司马老贼害我，诸葛老贼误我……",
}

local shiyi = General(extension, "shiyi", "wu", 3)
local cuichuan = fk.CreateActiveSkill{
  name = "cuichuan",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      for _, type in ipairs(types) do
        if card.sub_type == type and target:getEquipment(type) == nil then
          table.insertIfNeed(cards, room.draw_pile[i])
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo({table.random(cards)}, Player.Equip, target, fk.ReasonJustMove, self.name)
    end
    local n = #target.player_cards[Player.Equip]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    if #cards > 0 and n > 3 then
      room:handleAddLoseSkills(player, "-cuichuan|zuojian", nil, true, false)
      target:gainAnExtraTurn(true)
    end
  end,
}
local zhengxu = fk.CreateTriggerSkill{
  name = "zhengxu",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("zhengxu1-turn") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhengxu1-invoke")
  end,
  on_use = Util.TrueFunc,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu1-turn", 1)
  end,
}
local zhengxu_trigger = fk.CreateTriggerSkill{
  name = "#zhengxu_trigger",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:getMark("zhengxu2-turn") > 0 and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      self.cost_data = 0
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              self.cost_data = self.cost_data + 1
            end
          end
        end
      end
      return self.cost_data > 0
    end
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 0)
    return self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhengxu2-invoke:::"..self.cost_data)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "zhengxu2-turn", 1)
  end,
}
local zuojian = fk.CreateTriggerSkill{
  name = "zuojian",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getMark("zuojian-phase") >= player.hp and
      (#table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip] end) > 0 or
      #table.filter(player.room:getOtherPlayers(player), function(p)
        return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng() end) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local targets1 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] > #player.player_cards[Player.Equip] end)
    local targets2 = table.filter(player.room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Equip] < #player.player_cards[Player.Equip] and not p:isKongcheng() end)
    if #targets1 > 0 then
      table.insert(choices, "zuojian1")
    end
    if #targets2 > 0 then
      table.insert(choices, "zuojian2")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "zuojian1" then
      room:doIndicate(player.id, table.map(targets1, Util.IdMapper))
      for _, p in ipairs(targets1) do
        p:drawCards(1, self.name)
      end
    end
    if choice == "zuojian2" then
      room:doIndicate(player.id, table.map(targets2, Util.IdMapper))
      for _, p in ipairs(targets2) do
        local id = room:askForCardChosen(player, p, "h", self.name)
        room:throwCard({id}, self.name, p, player)
      end
    end
  end,

  refresh_events = {fk.CardUsing, fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play then
      if event == fk.CardUsing then
        return target == player
      else
        return data == self and player.room:getBanner("RoundCount")
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "zuojian-phase", 1)
      if player:hasSkill(self, true) then
        room:addPlayerMark(player, "@zuojian-phase", 1)
      end
    else
      local events = room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use.from == player.id
      end, Player.HistoryPhase)
      room:addPlayerMark(player, "zuojian-phase", #events)
      room:addPlayerMark(player, "@zuojian-phase", #events)
    end
  end,
}
zhengxu:addRelatedSkill(zhengxu_trigger)
shiyi:addSkill(cuichuan)
shiyi:addSkill(zhengxu)
shiyi:addRelatedSkill(zuojian)
Fk:loadTranslationTable{
  ["shiyi"] = "是仪",
  ["#shiyi"] = "清恪贞佐",
  ["designer:shiyi"] = "神壕",
  ["illustrator:shiyi"] = "福州乐战",

  ["cuichuan"] = "榱椽",
  [":cuichuan"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名角色，从牌堆中将一张随机装备牌置入其装备区空位，你摸X张牌（X为其装备区牌数）。"..
  "若其装备区内的牌因此达到4张或以上，你失去〖榱椽〗并获得〖佐谏〗，然后令其在此回合结束后获得一个额外回合。",
  ["zhengxu"] = "正序",
  [":zhengxu"] = "每回合各限一次，当你失去牌后，你本回合下一次受到伤害时，你可以防止此伤害；当你受到伤害后，你本回合下一次失去牌后，你可以摸等量的牌。",
  ["zuojian"] = "佐谏",
  [":zuojian"] = "出牌阶段结束时，若你此阶段使用的牌数大于等于你的体力值，你可以选择一项：1.令装备区牌数大于你的角色摸一张牌；"..
  "2.弃置装备区牌数小于你的每名角色各一张手牌。",
  ["#zhengxu_trigger"] = "正序",
  ["#zhengxu1-invoke"] = "正序：你可以防止你受到的伤害",
  ["#zhengxu2-invoke"] = "正序：你可以摸%arg张牌",
  ["@zuojian-phase"] = "佐谏",
  ["zuojian1"] = "装备区牌数大于你的角色各摸一张牌",
  ["zuojian2"] = "你弃置装备区牌数小于你的角色各一张手牌",

  ["$cuichuan1"] = "老臣在，必不使吴垒倾颓。",
  ["$cuichuan2"] = "舍老朽之躯，擎广厦之柱。",
  ["$zhengxu1"] = "陛下怜子无序，此取祸之道。",
  ["$zhengxu2"] = "古语有云，上尊而下卑。",
  ["$zuojian1"] = "关羽者，刘备之枭将，宜除之。",
  ["$zuojian2"] = "主公虽非赵简子，然某可为周舍。",
  ["~shiyi"] = "吾故后，务从省约……",
}

local sunlang = General(extension, "sunlang", "shu", 4)
local tingxian = fk.CreateTriggerSkill{
  name = "tingxian",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and data.firstTarget and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip] + 1
    return player.room:askForSkillInvoke(player, self.name, nil, "#tingxian-invoke:::"..n)
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Equip] + 1
    player:drawCards(n, self.name)
    local targets = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, n, "#tingxian-choose:::"..n, self.name, true)
    if #targets > 0 then
      table.insertTable(data.nullifiedTargets, targets)
    end
  end,
}
local benshi = fk.CreateTriggerSkill{
  name = "benshi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = TargetGroup:getRealTargets(data.tos)
    for _, p in ipairs(room.alive_players) do
      if player:inMyAttackRange(p) and not table.contains(targets, p.id) and
      not player:isProhibited(p, data.card) then
        room:doIndicate(player.id, {p.id})
        TargetGroup:pushTargets(data.tos, p.id)
      end
    end
  end,
}
local benshi_attackrange = fk.CreateAttackRangeSkill{
  name = "#benshi_attackrange",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    return from:hasSkill(benshi) and 1 or 0
  end,
}
benshi:addRelatedSkill(benshi_attackrange)
sunlang:addSkill(tingxian)
sunlang:addSkill(benshi)
Fk:loadTranslationTable{
  ["sunlang"] = "孙狼",
  ["#sunlang"] = "恶惮远役",
  ["designer:sunlang"] = "残昼厄夜",
  ["illustrator:sunlang"] = "六道目",
  ["tingxian"] = "铤险",
  [":tingxian"] = "每回合限一次，你使用【杀】指定目标后，你可以摸X张牌，然后可以令此【杀】对其中至多X个目标无效（X为你装备区的牌数+1）。",
  ["benshi"] = "奔矢",
  [":benshi"] = "锁定技，你使用【杀】须指定攻击范围内所有角色为目标。你的攻击范围+1。",
  ["#tingxian-invoke"] = "铤险：你可以摸%arg张牌，然后可以令此【杀】对至多等量的目标无效",
  ["#tingxian-choose"] = "铤险：你可以令此【杀】对至多%arg名目标无效",

  ["$tingxian1"] = "大争之世，当举兵行义。",
  ["$tingxian2"] = "聚兵三千众，可为天下先。",
  ["$benshi1"] = "今，或为鱼肉，或为刀俎。",
  ["$benshi2"] = "所征徭者必死，可先斩之。",
  ["~sunlang"] = "为关将军死，无憾……",
}

--千里单骑：关羽 杜夫人 秦宜禄 卞喜 胡班 胡金定 关宁
local guanyu = General(extension, "ty__guanyu", "wei", 4)
local ty__danji = fk.CreateTriggerSkill{
  name = "ty__danji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getCardIds("hej") > player.hp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return false end
    local x = player:getLostHp()
    if x > 0 then
      room:recover({
        who = player,
        num = x,
        recoverBy = player,
        skillName = self.name
      })
      if player.dead then return false end
      player:drawCards(x, self.name)
      if player.dead then return false end
    end
    room:handleAddLoseSkills(player, "mashu|nuchen", nil, true, false)
  end,
}
local nuchen = fk.CreateActiveSkill{
  name = "nuchen",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#nuchen-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "h", self.name)
    target:showCards(id)
    local suit = Fk:getCardById(id):getSuitString()
    if suit == "nosuit" then return end
    local cards = room:askForDiscard(player, 1, 999, true, self.name, true, ".|.|"..suit, "#nuchen-card::"..target.id..":"..suit)
    if #cards > 0 then
      room:damage{
        from = player,
        to = target,
        damage = #cards,
        skillName = self.name,
      }
    else
      local get = table.filter(target.player_cards[Player.Hand], function(id)
        return  Fk:getCardById(id):getSuitString() == suit
      end)
      room:moveCardTo(get, Player.Hand, player, fk.ReasonGive, self.name, nil, false, player.id)
    end
  end,
}
guanyu:addSkill("ex__wusheng")
guanyu:addSkill(ty__danji)
guanyu:addRelatedSkill("mashu")
guanyu:addRelatedSkill(nuchen)
Fk:loadTranslationTable{
  ["ty__guanyu"] = "关羽",
  ["#ty__guanyu"] = "汉寿亭侯",
  ["designer:ty__guanyu"] = "韩旭",
  ["illustrator:ty__guanyu"] = "写之火工作室",
  ["ty__danji"] = "单骑",
  [":ty__danji"] = "觉醒技，准备阶段，若你区域里的牌数大于体力值，你减1点体力上限，回复体力至体力上限，摸X张牌（X为你以此法回复的体力值），"..
  "获得〖马术〗和〖怒嗔〗。",
  ["nuchen"] = "怒嗔",
  [":nuchen"] = "出牌阶段限一次，你可以展示一名其他角色的一张手牌，然后你选择一项：1.弃置任意张相同花色的牌，对其造成等量的伤害；"..
  "2.获得其手牌中所有此花色的牌。",
  ["#nuchen-active"] = "发动 怒嗔，选择一名其他角色，展示其一张手牌",
  ["#nuchen-card"] = "怒嗔：你可以弃置任意张%arg牌对 %dest 造成等量伤害，或获得其全部此花色手牌",

  ["$ex__wusheng_ty__guanyu1"] = "以义传魂，以武入圣！",
  ["$ex__wusheng_ty__guanyu2"] = "义击逆流，武安黎庶。",
  ["$ty__danji1"] = "单骑护嫂千里，只为桃园之义！",
  ["$ty__danji2"] = "独身远涉，赤心归国！",
  ["$nuchen1"] = "触关某之逆鳞者，杀无赦！",
  ["$nuchen2"] = "天下碌碌之辈，安敢小觑关某？！",
  ["~ty__guanyu"] = "樊城一去，死亦无惧……",
}

local dufuren = General(extension, "dufuren", "wei", 3, 3, General.Female)
local yise = fk.CreateTriggerSkill{
  name = "yise",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local room = player.room
      for _, move in ipairs(data) do
        if move.from == player.id and move.to and move.to ~= player.id
        and not room:getPlayerById(move.to).dead and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color ~= Card.NoColor then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local list = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.to and move.to ~= player.id and not room:getPlayerById(move.to).dead and
      move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color ~= Card.NoColor then
            list[move.to] = list[move.to] or {}
            table.insertIfNeed(list[move.to], Fk:getCardById(info.cardId).color)
          end
        end
      end
    end
    for _, p in ipairs(room:getAlivePlayers()) do
      if not player:hasSkill(self) then break end
      if not p.dead and list[p.id] then
        self:doCost(event, p, player, list[p.id])
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if table.contains(data, Card.Red) and (not target:isWounded() or
    not player.room:askForSkillInvoke(player, self.name, nil, "#yise-invoke::"..target.id)) then
      table.removeOne(data, Card.Red)
    end
    return #data > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.contains(data, Card.Red) then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if table.contains(data, Card.Black) and not target.dead then
      room:addPlayerMark(target, "@yise", 1)
    end
  end,
}
local yise_delay = fk.CreateTriggerSkill{
  name = "#yise_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@yise") > 0 and data.card and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@yise")
    player.room:setPlayerMark(player, "@yise", 0)
  end,
}
local shunshi = fk.CreateTriggerSkill{
  name = "shunshi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and not player:isNude() then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start
      else
        return player ~= player.room.current
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
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
    room:moveCardTo(self.cost_data[2], Card.PlayerHand, room:getPlayerById(self.cost_data[1]), fk.ReasonGive, self.name, nil, false, player.id)
    if player.dead then return end
    room:addPlayerMark(player, "@shunshi", 1)
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("@shunshi") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@shunshi", 0)
  end,
}
local shunshi_delay = fk.CreateTriggerSkill{
  name = "#shunshi_delay",
  mute = true,
  events = {fk.DrawNCards},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@shunshi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@shunshi")
  end,
}
local shunshi_targetmod = fk.CreateTargetModSkill{
  name = "#shunshi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@shunshi")
    end
  end,
}
local shunshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#shunshi_maxcards",
  correct_func = function(self, player)
    return player:getMark("@shunshi")
  end,
}
yise:addRelatedSkill(yise_delay)
shunshi:addRelatedSkill(shunshi_delay)
shunshi:addRelatedSkill(shunshi_targetmod)
shunshi:addRelatedSkill(shunshi_maxcards)
dufuren:addSkill(yise)
dufuren:addSkill(shunshi)
Fk:loadTranslationTable{
  ["dufuren"] = "杜夫人",
  ["#dufuren"] = "沛王太妃",
  ["designer:dufuren"] = "步穗",
  ["illustrator:dufuren"] = "匠人绘",
  ["yise"] = "异色",
  [":yise"] = "当其他角色获得你的牌后，若此牌为：红色，你可以令其回复1点体力；黑色，其下次受到【杀】造成的伤害时，此伤害+1。",
  ["shunshi"] = "顺世",
  [":shunshi"] = "准备阶段或当你于回合外受到伤害后，你可以交给一名其他角色一张牌（伤害来源除外），然后直到你的回合结束，你：摸牌阶段多摸一张牌、"..
  "出牌阶段使用的【杀】次数上限+1、手牌上限+1。",
  ["#yise-invoke"] = "异色：你可以令 %dest 回复1点体力",
  ["#shunshi-cost"] = "顺世：你可以交给一名其他角色一张牌，然后直到你的回合结束获得效果",
  ["#yise_delay"] = "异色",
  ["#shunshi_delay"] = "顺世",
  ["@yise"] = "异色",
  ["@shunshi"] = "顺世",

  ["$yise1"] = "明丽端庄，双瞳剪水。",
  ["$yise2"] = "姿色天然，貌若桃李。",
  ["$shunshi1"] = "顺应时运，得保安康。",
  ["$shunshi2"] = "随遇而安，宠辱不惊。",
  ["~dufuren"] = "往事云烟，去日苦多。",
}

local qinyilu = General(extension, "qinyilu", "qun", 3)
local piaoping = fk.CreateTriggerSkill{
  name = "piaoping",
  anim_type = "switch",
  switch_skill_name = "piaoping",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("piaoping_invalid-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.min(player:usedSkillTimes(self.name, Player.HistoryTurn), player.hp)
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      player:drawCards(n, self.name)
    else
      room:askForDiscard(player, n, n, true, self.name, false, ".", "#piaoping-discard:::"..n, false)
    end
  end,
}
local tuoxian = fk.CreateTriggerSkill{
  name = "tuoxian",
  anim_type = "spcial",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) < player:getMark(self.name) + 1 then
      for _, move in ipairs(data) do
        if move.skillName == "piaoping" and move.moveReason == fk.ReasonDiscard and move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if player.room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      1, 1, "#tuoxian-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local to_get = {}
    for _, move in ipairs(data) do
      if move.skillName == "piaoping" and move.moveReason == fk.ReasonDiscard and move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insert(to_get, info.cardId)
          end
        end
      end
    end
    room:moveCardTo(to_get, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    local choices = {}
    local n = #to_get
    if not to.dead and #to:getCardIds("hej") >= n then
      table.insert(choices, "tuoxian1:::"..n)
    end
    if not player.dead then
      table.insert(choices, "tuoxian2:"..player.id)
    end
    local choice = room:askForChoice(to, choices, self.name, "#tuoxian-choice:"..player.id)
    if choice[8] == "1" then
      local cards = room:askForCardsChosen(to, to, n, n, "hej", self.name, "#tuoxian-discard:::"..n)
      room:throwCard(cards, self.name, to, to)
    else
      room:setPlayerMark(player, "piaoping_invalid-turn", 1)
    end
    return true
  end,
}
local zhuili = fk.CreateTriggerSkill{
  name = "zhuili",
  anim_type = "spcial",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.color == Card.Black and data.from ~= player.id and
      player:hasSkill(piaoping, true) and player:getMark("zhuili_invalid-turn") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState("piaoping", false) == fk.SwitchYang then
      room:addPlayerMark(player, "tuoxian", 1)
      if player:getMark("tuoxian") - player:usedSkillTimes("tuoxian", Player.HistoryGame) > 2 then
        room:setPlayerMark(player, "zhuili_invalid-turn", 1)
      end
    else
      room:setPlayerMark(player, MarkEnum.SwithSkillPreName.."piaoping", fk.SwitchYang)
      player:setSkillUseHistory("piaoping", player:usedSkillTimes("piaoping", Player.HistoryTurn), Player.HistoryTurn)
    end
  end,
}
qinyilu:addSkill(piaoping)
qinyilu:addSkill(tuoxian)
qinyilu:addSkill(zhuili)
Fk:loadTranslationTable{
  ["qinyilu"] = "秦宜禄",
  ["#qinyilu"] = "尘垢粃糠",
  ["designer:qinyilu"] = "追风少年",
  ["illustrator:qinyilu"] = "君桓文化",
  ["piaoping"] = "漂萍",
  [":piaoping"] = "锁定技，转换技，当你使用一张牌时，阳：你摸X张牌；阴：你弃置X张牌（X为本回合〖漂萍〗发动次数且至多为你当前体力值）。",
  ["tuoxian"] = "托献",
  [":tuoxian"] = "每局游戏限一次，当你因〖漂萍〗弃置的牌进入弃牌堆后，你可以改为将这些牌交给一名其他角色，然后其选择一项：1.其弃置其区域内等量的牌；"..
  "2.令〖漂萍〗本回合失效。",
  ["zhuili"] = "惴栗",
  [":zhuili"] = "锁定技，当你成为其他角色使用黑色牌的目标后，若此时〖漂萍〗状态为：阳，令〖托献〗可使用次数+1，"..
  "然后若〖托献〗可使用次数超过3，此技能本回合失效；"..
  "阴，令〖漂萍〗状态转换为阳。",
  ["#piaoping-discard"] = "漂萍：请弃置%arg张牌",
  ["#tuoxian-choose"] = "托献：你可以将这些牌交给一名其他角色，其选择弃置等量牌或令你的〖漂萍〗失效",
  ["tuoxian1"] = "弃置你区域内%arg张牌",
  ["tuoxian2"] = "令 %src 本回合〖漂萍〗失效",
  ["#tuoxian-choice"] = "托献：%src 令你选择一项",
  ["#tuoxian-discard"] = "托献：弃置你区域内%arg张牌",

  ["$piaoping1"] = "奔波四处，前途未明。",
  ["$piaoping2"] = "辗转各地，功业难寻。",
  ["$tuoxian1"] = "一贵一贱，其情乃见。",
  ["$tuoxian2"] = "一死一生，乃知交情。",
  ["$zhuili1"] = "近况艰难，何不忧愁？",
  ["$zhuili2"] = "形势如此，惴惕难当。",
  ["~qinyilu"] = "我竟落得如此下场……",
}

local bianxi = General(extension, "bianxi", "wei", 4)
local dunxi = fk.CreateTriggerSkill{
  name = "dunxi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.is_damage_card and data.tos
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
}
local dunxi_delay = fk.CreateTriggerSkill{
  name = "#dunxi_delay",
  anim_type = "negative",
  events = {fk.CardUsing, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      if player == target and player:getMark("@bianxi_dun") > 0 and
      (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and #TargetGroup:getRealTargets(data.tos) == 1 then
        for _, p in ipairs(player.room.alive_players) do
          if p.dying then
            return false
          end
        end
        return true
      end
    elseif event == fk.CardUseFinished then
      return not player.dead and data.extra_data and data.extra_data.dunxi_record and
        table.contains(data.extra_data.dunxi_record, player.id)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:removePlayerMark(player, "@bianxi_dun")
      local orig_to = data.tos[1]
      local targets = {}
      local c_pid
      for _, p in ipairs(room.alive_players) do
        if not player:isProhibited(p, data.card) and
        (data.card.sub_type == Card.SubtypeDelayedTrick or data.card.skill:modTargetFilter(p.id, {}, player, data.card, true)) then
          local ho_spair_check = true
          if #orig_to > 1 then
            --target_filter check, for collateral, diversion...
            local ho_spair_target = {p.id}
            for i = 2, #orig_to, 1 do
              c_pid = orig_to[i]
              if not data.card.skill:modTargetFilter(c_pid, ho_spair_target, player, data.card, true) then
                ho_spair_check = false
                break
              end
              table.insert(ho_spair_target, c_pid)
            end
          end
          if ho_spair_check then
            table.insert(targets, p.id)
          end
        end
      end
      if #targets > 0 then
        local random_target = table.random(targets)
        for i = 1, 2, 1 do
          for _, p in ipairs(room:getAllPlayers()) do
            if table.contains(targets, p.id) then
              room:setEmotion(p, "./image/anim/selectable")
              room:notifyMoveFocus(p, self.name)
              room:delay(300)
            end
          end
        end
        for _, p in ipairs(room:getAllPlayers()) do
          if table.contains(targets, p.id) then
            room:setEmotion(p, "./image/anim/selectable")
            room:delay(600)
            if p.id == random_target then
              room:doIndicate(data.from, {random_target})
              break
            end
          end
        end

        if random_target == orig_to[1] then
          data.extra_data = data.extra_data or {}
          local dunxi_record = data.extra_data.dunxi_record or {}
          table.insert(dunxi_record, player.id)
          data.extra_data.dunxi_record = dunxi_record
        else
          orig_to[1] = random_target
          data.tos = { orig_to }
        end
      else
        data.tos = {}
      end
    elseif event == fk.CardUseFinished then
      room:loseHp(player, 1, self.name)
      if player.phase == Player.Play then
        player:endPlayPhase()
      end
    end
  end,
}
dunxi:addRelatedSkill(dunxi_delay)
bianxi:addSkill(dunxi)
Fk:loadTranslationTable{
  ["bianxi"] = "卞喜",
  ["#bianxi"] = "伏龛蛇影",
  ["illustrator:bianxi"] = "君桓文化",
  ["dunxi"] = "钝袭",
  [":dunxi"] = "当你使用伤害牌时，你可令其中一个目标获得1个“钝”标记。有“钝”标记的角色使用基本牌或锦囊牌时，"..
  "若目标数为1且没有处于濒死状态的角色，其移去一个“钝”，然后目标改为随机一名角色。"..
  "若随机的目标与原本目标相同，则其于此牌结算结束后失去1点体力并结束出牌阶段。",

  --濒死使用桃不会触发，引申为隐藏条件：没有处于濒死状态的角色
  --其实不对，濒死用酒会触发技能
  --有距离限制，延迟锦囊牌无使用目标的限制（兵粮寸断能不能指定远位存疑，只知道能转移给给自己），如果没有合法目标则会取消掉所有目标
  --借刀杀人的逻辑依旧采取对原目标的副目标使用【杀】（实测并非如此，但测试结果有限，无法总结规律）
  --实测结果：会随机到没有武器牌的角色，但是又存在能指定原目标的时候取消掉目标的情况
  --最接近实测结果的逻辑推测是：先随机选取一名其他角色，若能对原副目标出杀则转移目标，不能则取消目标
  --个人觉得不太好，故不采用

  ["#dunxi-choose"] = "钝袭：你可以令一名角色获得“钝”标记，其使用下一张牌目标改为随机角色",
  ["@bianxi_dun"] = "钝",
  ["#dunxi_delay"] = "钝袭",

  ["$dunxi1"] = "看锤！",
  ["$dunxi2"] = "且吃我一锤！",
  ["~bianxi"] = "以力破巧，难挡其锋……",
}

local huban = General(extension, "ty__huban", "wei", 4)
local chongyi = fk.CreateTriggerSkill{
  name = "chongyi",
  anim_type = "support",
  events = {fk.CardUsing, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Play and not target.dead then
      if event == fk.CardUsing then
        if data.card.trueName ~= "slash" then return false end
        local room = player.room
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event == nil then return false end
        local x = target:getMark("chongyi_record-turn")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data[1]
            if use.from == target.id then
              x = e.id
              room:setPlayerMark(target, "chongyi_record-turn", x)
              return true
            end
          end, Player.HistoryPhase)
        end
        return x == use_event.id
      else
        local logic = player.room.logic
        local phase_event = logic:getCurrentEvent():findParent(GameEvent.Phase, true)
        if phase_event == nil then return false end
        local use_events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
        for i = #use_events, 1, -1 do
          if use_events[i].id < phase_event.id then return false end
          local use = use_events[i].data[1]
          if use.from == target.id then
            if use.card.trueName == "slash" then
              self.cost_data = Card:getIdList(use.card)
              return true
            else
              return false
            end
          end
        end
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
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, prompt .. target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      target:drawCards(2, self.name)
      room:addPlayerMark(target, MarkEnum.SlashResidue .. "-phase")
    else
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 1)
      local cards = table.filter(self.cost_data, function (id)
        return room:getCardArea(id) == Card.DiscardPile
      end)
      if #cards > 0 then
        room:obtainCard(player, cards, true)
      end
    end
  end,
}

huban:addSkill(chongyi)
Fk:loadTranslationTable{
  ["ty__huban"] = "胡班",
  ["#ty__huban"] = "血火照路",
  ["designer:ty__huban"] = "世外高v狼",
  ["illustrator:ty__huban"] = "君桓文化",
  ["chongyi"] = "崇义",
  [":chongyi"] = "一名角色于出牌阶段内使用的第一张牌若为【杀】，你可令其摸两张牌且于此阶段使用【杀】的次数上限+1；"..
  "一名角色的出牌阶段结束时，若其于此阶段使用过的最后一张牌为【杀】，你可令其于此回合内手牌上限+1，然后你获得弃牌堆中的此【杀】。",
  ["#chongyi-draw"] = "崇义：你可以令 %dest 摸两张牌且此阶段使用【杀】次数上限+1",
  ["#chongyi-maxcards"] = "崇义：你可以令 %dest 本回合手牌上限+1",

  ["$chongyi1"] = "班虽卑微，亦知何为大义。",
  ["$chongyi2"] = "大义当头，且助君一臂之力。",
  ["~ty__huban"] = "行义而亡，虽死无憾。",
}

local hujinding = General(extension, "ty__hujinding", "shu", 3, 6, General.Female)
local deshi = fk.CreateTriggerSkill{
  name = "deshi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and player:isWounded()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("slash", 1, "allPiles")
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
    if not player.dead then
      room:changeMaxHp(player, -1)
    end
    return true
  end,
}
local ty__wuyuan = fk.CreateActiveSkill{
  name = "ty__wuyuan",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__wuyuan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardTo(card, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
    if not target.dead then
      if card.color == Card.Red and target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      local n = card.name ~= "slash" and 2 or 1
      target:drawCards(n, self.name)
    end
  end,
}
hujinding:addSkill(deshi)
hujinding:addSkill(ty__wuyuan)
hujinding:addSkill("huaizi")
Fk:loadTranslationTable{
  ["ty__hujinding"] = "胡金定",
  ["#ty__hujinding"] = "怀子求怜",
  ["illustrator:ty__hujinding"] = "匠人绘",
  ["deshi"] = "德释",  --为了不被管宁拿到改了技能名，不愧是狗ch
  [":deshi"] = "锁定技，当你受到【杀】造成的伤害时，若你已受伤，你防止此伤害并获得一张【杀】，然后减1点体力上限。",
  ["ty__wuyuan"] = "武缘",
  [":ty__wuyuan"] = "出牌阶段限一次，你可以将一张【杀】交给一名其他角色，然后你回复1点体力并与其各摸一张牌；若此【杀】为：红色，其回复1点体力；"..
  "属性【杀】，其多摸一张牌。",
  ["#ty__wuyuan"] = "武缘：将一张【杀】交给一名角色，你回复1点体力并与其各摸一张牌",

  ["$deshi1"] = "你我素无仇怨，何故欺之太急。",
  ["$deshi2"] = "恃强凌弱，非大丈夫之所为。",
  ["$ty__wuyuan1"] = "生为关氏之妇，虽死亦不悔。",
  ["$ty__wuyuan2"] = "我夫关长生，乃盖世之英雄。",
  ["~ty__hujinding"] = "妾不畏死，唯畏君断情。",
}

local guannings = General(extension, "guannings", "shu", 3)
local xiuwen = fk.CreateTriggerSkill{
  name = "xiuwen",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not table.contains(player:getTableMark(self.name), data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, self.name, data.card.trueName)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return target == player and data == self and player:getMark(self.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 0)
  end,
}
local longsong_skills = {
  "qiangwu", "ol_ex__qiangxi", "ol_ex__luanji", "ty_ex__sanyao", "ol__xuehen", "ex__yijue", "daoshu", "m_ex__xianzhen",
  "tianyi", "mansi", "ty__lianji", "ty_ex__wurong", "xuezhao", "hs__kurou", "m_ex__mieji",
  "ex__zhiheng", "ex__guose", "guolun", "duliang", "os__gongxin", "lueming", "jijie", "busuan", "minsi", "ty__lianzhu",
  "ex__fanjian", "tanbei", "ty__qingcheng", "jinhui", "weimeng", "ty__songshu", "poxi", "m_ex__ganlu", "ty__kuangfu", "qice",
  "ty_ex__gongqi", "ty_ex__huaiyi", "shanxi", "cuijian", "ol_ex__tiaoxin", "qingnang", "quji", "ty_ex__anguo", "ex__jieyin",
  "m_ex__anxu", "ty_ex__mingce", "ziyuan", "mou__lijian", "mingjian", "ex__rende", "mizhao", "yanjiao", "ol_ex__dimeng",
  "quhu", "tunan", "nuchen", "feijun", "yingshui", "qiongying", "zigu", "weiwu", "chiying", "qiangzhiz", "ty__jianji",
  "jieling", "xinyou", "jianzheng", "humei", "jianguo", "jiuxianc", "tongli",

  "yangjie", "hongyi", "m_ex__junxing", "m_ex__yanzhu", "ol_ex__changbiao", "yanxi", "xuanbei", "yushen", "guanxu",
  "wencan", "xiangmian", "zhuren", "changqu", "caizhuang", "ty__beini", "jichun", "tongwei",
  "liangyan", "kuizhen", "huiji",
}
local longsong = fk.CreateTriggerSkill{
  name = "longsong",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local tos, cards = player.room:askForChooseCardsAndPlayers(player, 0, 1,
    table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
    1, 1, ".|.|heart,diamond", "#longsong-invoke", self.name, true)
    if #tos == 1 then
      self.cost_data = {tos = tos, cards = cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local cards = table.simpleClone(self.cost_data.cards)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    else
      cards = table.filter(to:getCardIds("he"), function(id) return Fk:getCardById(id).color == Card.Red end)
      if #cards > 0 then
        room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
    if player.dead then return end
    local skills = {}
    local ban_list = {"xionghuo", "mobile__xionghuo", "n_dunshi", "dunshi"}
    for _, s in ipairs(to.player_skills) do
      if not table.contains(ban_list, s.name) and s:isPlayerSkill(to) and not player:hasSkill(s, true) and s.frequency < 4 then
        if table.contains(longsong_skills, s.name) or s:isInstanceOf(ActiveSkill) or s:isInstanceOf(ViewAsSkill) then
          table.insertIfNeed(skills, s.name)
        elseif s:isInstanceOf(TriggerSkill) then
          local str = Fk:translate(":"..s.name)
          if string.sub(str, 1, 12) == "出牌阶段" and string.sub(str, 13, 18) ~= "开始" and string.sub(str, 13, 18) ~= "结束" then
            table.insertIfNeed(skills, s.name)
          end
        end
      end
    end
    if #skills == 0 then
      skills = table.filter(longsong_skills, function (skill_name)
        return Fk.skills[skill_name] and not player:hasSkill(skill_name, true)
      end)
    end
    if #skills > 0 then
      local skill = table.random(skills)
      room:setPlayerMark(player, "longsong-phase", skill)
      room:handleAddLoseSkills(player, skill, nil, true, false)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..skill)
      end)
    end
  end,
}
local longsong_invalidity = fk.CreateInvaliditySkill {
  name = "#longsong_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("longsong-phase") ~= 0 and from:getMark("longsong-phase") == skill.name and
      from:usedSkillTimes(skill.name, Player.HistoryPhase) > 0
  end
}
longsong:addRelatedSkill(longsong_invalidity)
guannings:addSkill(xiuwen)
guannings:addSkill(longsong)
Fk:loadTranslationTable{
  ["guannings"] = "关宁",
  ["#guannings"] = "承义秉文",
  ["designer:guannings"] = "韩旭",
  ["illustrator:guannings"] = "黯荧岛工作室",
  ["xiuwen"] = "修文",
  [":xiuwen"] = "你使用一张牌时，若此牌名是你本局游戏第一次使用，你摸一张牌。",
  ["longsong"] = "龙诵",
  [":longsong"] = "出牌阶段开始时，你可以交给或随机获得一名其他角色一张红色牌，然后你本阶段视为拥有该角色的一个“出牌阶段”的技能直到你发动之（若未获得其的技能则改为随机获得一个技能池中的技能）。"..
  "<br><font color='red'>村：能获取的技能包括所有主动技和转化技、描述前4字为“出牌阶段”且后不接“开始时”和“结束时”的技能；随机技能池同许劭。</font>",
  ["#longsong-invoke"] = "龙诵：你可以交给或获得一名其他角色一张红色牌，本阶段获得其拥有的一个“出牌阶段”技能",

  ["$xiuwen1"] = "书生笔下三尺剑，毫锋可杀人。",
  ["$xiuwen2"] = "吾以书执剑，可斩世间魍魉。",
  ["$longsong1"] = "百家诸子，且听九霄龙吟。",
  ["$longsong2"] = "朗朗书声，岂虚于刀斧铮鸣。",
  ["~guannings"] = "为国捐生，虽死无憾……",
}

--烽火连天：南华老仙 童渊 张宁 庞德公
local nanhualaoxian = General(extension, "ty__nanhualaoxian", "qun", 4)
local gongxiu = fk.CreateTriggerSkill{
  name = "gongxiu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      player:usedSkillTimes("jinghe", Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"Cancel"}
    local all_choices = {"gongxiu_draw", "gongxiu_discard", "Cancel"}
    if table.find(player.room.alive_players, function(p) return p:getMark("jinghe-turn") == 0 and not p:isKongcheng() end) then
      table.insert(choices, "gongxiu_discard")
    end
    if table.find(player.room.alive_players, function(p) return p:getMark("jinghe-turn") ~= 0 end) then
      table.insert(choices, "gongxiu_draw")
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#gongxiu-invoke", false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data[10] == "r" then
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("jinghe-turn") ~= 0 and not p.dead then
          room:doIndicate(player.id, {p.id})
          p:drawCards(1, self.name)
        end
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("jinghe-turn") == 0 and not p.dead then
          room:doIndicate(player.id, {p.id})
          if not p:isKongcheng() then
            room:askForDiscard(p, 1, 1, false, self.name, false)
          end
        end
      end
    end
  end,
}
local jinghe = fk.CreateActiveSkill{
  name = "jinghe",
  anim_type = "support",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#jinghe",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    if #selected < 4 and Fk:currentRoom():getCardArea(to_select) == Player.Hand then
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id) return Fk:getCardById(to_select).trueName ~= Fk:getCardById(id).trueName end)
      end
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < #selected_cards
  end,
  feasible = function (self, selected, selected_cards)
    return #selected > 0 and #selected == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local mark = player:getTableMark("jinghe_data")
    player:showCards(effect.cards)
    local skills = table.random(
      {"ex__leiji", "yinbingn", "huoqi", "guizhu", "xianshou", "lundao", "guanyue", "yanzhengn",
      "ex__biyue", "ex__tuxi", "ty_ex__mingce", "ty_ex__zhiyan"
    }, 4)
    local selected = {}
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local choices = table.filter(skills, function(s) return not p:hasSkill(s, true) and not table.contains(selected, s) end)
        if #choices > 0 then
          local choice = room:askForChoice(p, choices, self.name, "#jinghe-choice", true, skills)
          table.insert(selected, choice)
          room:handleAddLoseSkills(p, choice, nil, true, false)
          table.insert(mark, {p.id, choice})
          room:setPlayerMark(p, "jinghe-turn", 1)
        end
      end
    end
    room:setPlayerMark(player, "jinghe_data", mark)
  end,
}
local jinghe_trigger = fk.CreateTriggerSkill {
  name = "#jinghe_trigger",
  mute = true,
  events = {fk.TurnStart, fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("jinghe_data") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("jinghe_data")
    room:setPlayerMark(player, "jinghe_data", 0)
    for _, dat in ipairs(mark) do
      local p = room:getPlayerById(dat[1])
      room:handleAddLoseSkills(p, "-"..dat[2], nil, true, false)
    end
  end,
}
jinghe:addRelatedSkill(jinghe_trigger)
nanhualaoxian:addSkill(gongxiu)
nanhualaoxian:addSkill(jinghe)
local yinbingn = fk.CreateTriggerSkill{
  name = "yinbingn",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.PreDamage, fk.HpLost},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.PreDamage then
        return target == player and data.card and data.card.trueName == "slash"
      else
        return target ~= player
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreDamage then
      room:loseHp(data.to, data.damage, self.name)
      return true
    else
      player:drawCards(1, self.name)
    end
  end,
}
local huoqi = fk.CreateActiveSkill{
  name = "huoqi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#huoqi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return target:isWounded() and table.every(Fk:currentRoom().alive_players, function(p) return target.hp <= p.hp end)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not target.dead then
      target:drawCards(1, self.name)
    end
  end,
}
local guizhu = fk.CreateTriggerSkill{
  name = "guizhu",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
local xianshou = fk.CreateActiveSkill{
  name = "xianshou",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#xianshou",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = not target:isWounded() and 2 or 1
    target:drawCards(n, self.name)
  end
}
local lundao = fk.CreateTriggerSkill{
  name = "lundao",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead and
      data.from:getHandcardNum() ~= player:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    if data.from:getHandcardNum() > player:getHandcardNum() then
      return player.room:askForSkillInvoke(player, self.name, nil, "#lundao-invoke::"..data.from.id)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    if data.from:getHandcardNum() > player:getHandcardNum() then
      room:doIndicate(player.id, {from.id})
      local id = room:askForCardChosen(player, from, "he", self.name)
      room:throwCard({id}, self.name, from, player)
    else
      player:drawCards(1, self.name)
    end
  end
}
local guanyue = fk.CreateTriggerSkill{
  name = "guanyue",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local result = room:askForGuanxing(player, room:getNCards(2), {1, 2}, {1, 1}, self.name, true, {"Top", "prey"})
    if #result.top > 0 then
      room:sendLog{
        type = "#GuanxingResult",
        from = player.id,
        arg = 1,
        arg2 = 0,
      }
    end
    if #result.bottom > 0 then
      room:obtainCard(player.id, result.bottom[1], false, fk.ReasonJustMove)
    end
  end,
}
local yanzhengn = fk.CreateTriggerSkill{
  name = "yanzhengn",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and player:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(player.room.alive_players, Util.IdMapper)
    local tos, card = player.room:askForChooseCardAndPlayers(player, targets, 1, player:getHandcardNum() - 1, ".|.|.|hand",
      "#yanzhengn-invoke:::"..(player:getHandcardNum() - 1), self.name, true)
    if #tos > 0 and card then
      player.room:sortPlayersByAction(tos)
      self.cost_data = {tos, card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = player:getCardIds("h")
    table.removeOne(ids, self.cost_data[2])
    room:throwCard(ids, self.name, player, player)
    for _, id in ipairs(self.cost_data[1]) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
nanhualaoxian:addRelatedSkill("ex__leiji")
nanhualaoxian:addRelatedSkill(yinbingn)
nanhualaoxian:addRelatedSkill(huoqi)
nanhualaoxian:addRelatedSkill(guizhu)
nanhualaoxian:addRelatedSkill(xianshou)
nanhualaoxian:addRelatedSkill(lundao)
nanhualaoxian:addRelatedSkill(guanyue)
nanhualaoxian:addRelatedSkill(yanzhengn)
nanhualaoxian:addRelatedSkill("ex__biyue")
nanhualaoxian:addRelatedSkill("ex__tuxi")
nanhualaoxian:addRelatedSkill("ty_ex__mingce")
nanhualaoxian:addRelatedSkill("ty_ex__zhiyan")
Fk:loadTranslationTable{
  ["ty__nanhualaoxian"] = "南华老仙",
  ["#ty__nanhualaoxian"] = "仙人指路",
  ["illustrator:ty__nanhualaoxian"] = "君桓文化",
  ["cv:ty__nanhualaoxian"] = "大许哥",

  ["gongxiu"] = "共修",
  [":gongxiu"] = "结束阶段，若你本回合发动过〖经合〗，你可以选择一项：1.令所有本回合因〖经合〗获得过技能的角色摸一张牌；"..
  "2.令所有本回合未因〖经合〗获得过技能的其他角色弃置一张手牌。",
  ["jinghe"] = "经合",
  [":jinghe"] = "出牌阶段限一次，你可展示至多四张牌名各不同的手牌，选择等量的角色，从“写满技能的天书”随机展示四个技能，这些角色依次选择并"..
  "获得其中一个，直到你下回合开始或你死亡。",
  ["#gongxiu-invoke"] = "共修：你可以执行一项",
  ["gongxiu_draw"] = "令“经合”角色各摸一张牌",
  ["gongxiu_discard"] = "令非“经合”角色各弃置一张手牌",
  ["#jinghe"] = "经合：展示至多四张牌名各不同的手牌，令等量的角色获得技能",
  ["#jinghe-choice"] = "经合：选择你要获得的技能",
  ["yinbingn"] = "阴兵",
  [":yinbingn"] = "锁定技，你使用【杀】即将造成的伤害视为失去体力。当其他角色失去体力后，你摸一张牌。",
  ["huoqi"] = "活气",
  [":huoqi"] = "出牌阶段限一次，你可以弃置一张牌，然后令一名体力最少的角色回复1点体力并摸一张牌。",
  ["#huoqi"] = "活气：弃置一张牌，令一名体力最少的角色回复1点体力并摸一张牌",
  ["guizhu"] = "鬼助",
  [":guizhu"] = "每回合限一次，当一名角色进入濒死状态时，你可以摸两张牌。",
  ["xianshou"] = "仙授",
  [":xianshou"] = "出牌阶段限一次，你可以令一名角色摸一张牌。若其未受伤，则多摸一张牌。",
  ["#xianshou"] = "仙授：令一名角色摸一张牌，若其未受伤则多摸一张牌",
  ["lundao"] = "论道",
  [":lundao"] = "当你受到伤害后，若伤害来源的手牌多于你，你可以弃置其一张牌；若伤害来源的手牌数少于你，你摸一张牌。",
  ["#lundao-invoke"] = "论道：你可以弃置 %dest 一张牌",
  ["guanyue"] = "观月",
  [":guanyue"] = "结束阶段，你可以观看牌堆顶的两张牌，然后获得其中一张，将另一张置于牌堆顶。",
  ["prey"] = "获得",
  ["yanzhengn"] = "言政",
  [":yanzhengn"] = "准备阶段，若你的手牌数大于1，你可以选择一张手牌并弃置其余的牌，然后对至多等于弃置牌数的角色各造成1点伤害。",
  ["#yanzhengn-invoke"] = "言政：你可以选择保留一张手牌，弃置其余的手牌，对至多%arg名角色各造成1点伤害",

  ["$gongxiu1"] = "福祸与共，业山可移。",
  ["$gongxiu2"] = "修行退智，遂之道也。",
  ["$jinghe1"] = "大哉乾元，万物资始。",
  ["$jinghe2"] = "无极之外，复无无极。",
  ["~ty__nanhualaoxian"] = "道亦有穷时……",
}

local ty__tongyuan = General(extension, "ty__tongyuan", "qun", 4)
local chaofeng = fk.CreateTriggerSkill{
  name = "chaofeng",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and not player:isKongcheng() and data.card and player.phase == Player.Play and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#chaofeng-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local card = Fk:getCardById(self.cost_data[1])
    local n = (data.card.color == card.color) and 2 or 1
    if not player.dead then
      player:drawCards(n, self.name)
    end
    if data.card.type == card.type then
      data.damage = data.damage + 1
    end
  end,
}
ty__tongyuan:addSkill(chaofeng)
local chuanshu = fk.CreateTriggerSkill{
  name = "chuanshu",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.Death, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self,false,true) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      return event == fk.Death or (player.phase == Player.Start and player:isWounded())
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
      "#chuanshu-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:handleAddLoseSkills(to, "chaofeng")
    room:handleAddLoseSkills(player, "longdan|congjian|chuanyun")
  end,
}
ty__tongyuan:addSkill(chuanshu)
local chuanyun = fk.CreateTriggerSkill{
  name = "chuanyun",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" 
    and #player.room:getPlayerById(data.to):getCardIds("e") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chuanyun-invoke::"..data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local card = table.random(to:getCardIds("e"))
    room:throwCard({card}, self.name, to, to)
  end,
}
ty__tongyuan:addRelatedSkill("longdan")
ty__tongyuan:addRelatedSkill("congjian")
ty__tongyuan:addRelatedSkill(chuanyun)
Fk:loadTranslationTable{
  ["ty__tongyuan"] = "童渊",
  ["#ty__tongyuan"] = "蓬莱枪神散人",
  ["illustrator:ty__tongyuan"] = "目游",
  ["cv:ty__tongyuan"] = "大白siro",
  ["chaofeng"] = "朝凤",
  [":chaofeng"] = "每阶段限一次，当你于出牌阶段使用牌造成伤害时，你可以弃置一张手牌，然后摸一张牌。若弃置的牌与造成伤害的牌：颜色相同，则多摸一张牌；"..
  "类型相同，则此伤害+1。",
  ["#chaofeng-invoke"] = "朝凤：你可以弃置弃置一张手牌，摸一张牌",
  ["chuanshu"] = "传术",
  [":chuanshu"] = "限定技，准备阶段若你已受伤，或当你死亡时，你可令一名其他角色获得〖朝凤〗，然后你获得〖龙胆〗、〖从谏〗、〖穿云〗。",
  ["#chuanshu-choose"] = "传术：你可令一名其他角色获得〖朝凤〗，你获得〖龙胆〗、〖从谏〗、〖穿云〗",
  ["chuanyun"] = "穿云",
  [":chuanyun"] = "当你使用【杀】指定目标后，你可令该角色随机弃置一张装备区里的牌。",
  ["#chuanyun-invoke"] = "穿云：你可令 %dest 随机弃置一张装备区里的牌",

  ["$chaofeng1"] = "鸾凤归巢，百鸟齐鸣。",
  ["$chaofeng2"] = "鸾凤之响，所闻皆朝。",
  ["$chuanshu1"] = "此术不传子，独传于贤。",
  ["$chuanshu2"] = "定倾之术，贤者可习之。",
  ["$longdan_ty__tongyuan"] = "能进能退，方显名将本色。",
  ["$congjian_ty__tongyuan"] = "察言纳谏，安身立命之道也。",
  ["$chuanyun"] = "吾枪所至，人马俱亡！",
  ["~ty__tongyuan"] = "一门三杰，无憾矣！",
}

local zhangning = General(extension, "ty__zhangning", "qun", 3, 3, General.Female)
local tianze = fk.CreateTriggerSkill{
  name = "tianze",
  events = {fk.CardUseFinished, fk.FinishJudge},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and data.card.color == Card.Black then
      if event == fk.FinishJudge then
        return true
      else
        if target.dead or target.phase ~= Player.Play or player:isNude() then return false end
        local room = player.room
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event == nil then return false end
        local x = target:getMark("tianze_record-turn")
        if x == 0 then
          room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data[1]
            if use.from == target.id and use.card.color == Card.Black then
              x = e.id
              room:setPlayerMark(target, "tianze_record-turn", x)
              return true
            end
          end, Player.HistoryPhase)
        end
        return x == use_event.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.FinishJudge then return true end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|spade,club|hand,equip", "#tianze-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardUseFinished then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:doIndicate(player.id, {target.id})
      room:throwCard(self.cost_data, self.name, player, player)
      room:damage{ from = player, to = target, damage = 1, skillName = self.name }
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    end
  end,
}
local difa = fk.CreateTriggerSkill{
  name = "difa",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 and player.phase ~= Player.NotActive then
      local ids = {}
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) and Fk:getCardById(info.cardId).color == Card.Red then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
      if #ids > 0 then
        self.cost_data = ids
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, tostring(Exppattern{ id = self.cost_data }),
      "#difa-invoke", true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local names = player:getMark("difa_names")
    if type(names) ~= "table" then
      names = U.getAllCardNames("td", true)
      room:setPlayerMark(player, "difa_names", names)
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
zhangning:addSkill(tianze)
zhangning:addSkill(difa)
Fk:loadTranslationTable{
  ["ty__zhangning"] = "张宁",
  ["#ty__zhangning"] = "大贤后人",
  ["illustrator:ty__zhangning"] = "君桓文化",
  ["tianze"] = "天则",
  [":tianze"] = "当其他角色于其出牌阶段内使用第一张黑色牌结算结束后，你可以弃置一张黑色牌，对其造成1点伤害；"..
  "当其他角色的黑色判定牌生效后，你摸一张牌。",
  ["difa"] = "地法",
  [":difa"] = "每回合限一次，当你于回合内得到红色牌后，你可以弃置其中一张牌，然后选择一种锦囊牌的牌名，从牌堆或弃牌堆获得一张此牌名的牌。",

  ["#tianze-invoke"] = "是否发动 天则，弃置一张黑色牌来对%dest造成1点伤害",
  ["#difa-invoke"] = "是否发动 地法，弃置一张刚得到的红色牌，然后检索一张锦囊牌",

  ["$tianze1"] = "观天则，以断人事。",
  ["$tianze2"] = "乾元用九，乃见天则。",
  ["$difa1"] = "地蕴天成，微妙玄通。",
  ["$difa2"] = "观地之法，吉在其中。",
  ["~ty__zhangning"] = "全气之地，当葬其止……",
}

local pangdegong = General(extension, "ty__pangdegong", "qun", 3)
local heqia = fk.CreateTriggerSkill{
  name = "heqia",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and (not player:isNude() or
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end))
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "heqia_active", "#heqia-invoke", true, nil, false)
    if success and dat then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to
    local to_get
    if #self.cost_data.cards > 0 then
      to = room:getPlayerById(self.cost_data.targets[1])
      to_get = self.cost_data.cards
    else
      to = player
      local src = room:getPlayerById(self.cost_data.targets[1])
      to_get = room:askForCard(src, 1, 999, true, self.name, false, ".", "#heqia-give:"..player.id)
    end
    room:moveCardTo(to_get, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
    if to.dead or to:isKongcheng() then return end
    room:setPlayerMark(to, "heqia-tmp", #to_get)
    local success, dat = room:askForUseActiveSkill(to, "heqia_viewas", "#heqia-use:::"..#to_get, true)
    if success and dat then
      local card = Fk:cloneCard(dat.interaction)
      card:addSubcards(dat.cards)
      room:useCard{
        from = to.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
        extraUse = true,
      }
    end
  end,
}
local heqia_active = fk.CreateActiveSkill{
  name = "heqia_active",
  min_card_num = 0,
  target_num = 1,
  interaction = function()
    local choices = {}
    if not Self:isNude() then table.insert(choices, "heqia_give") end
    if table.find(Fk:currentRoom().alive_players, function(p) return Self ~= p and not p:isNude() end) then
      table.insert(choices, "heqia_prey")
    end
    return UI.ComboBox {choices = choices}
  end,
  card_filter = function(self, to_select, selected)
    if not self.interaction.data or self.interaction.data == "heqia_prey" then return false end
    return true
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if not self.interaction.data or #selected > 0 or to_select == Self.id then return false end
    if self.interaction.data == "heqia_give" then
      return #selected_cards > 0
    else
      return not Fk:currentRoom():getPlayerById(to_select):isNude()
    end
  end,
}
local heqia_viewas = fk.CreateActiveSkill{
  name = "heqia_viewas",
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "heqia", all_names)
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0 and table.contains(Self:getHandlyIds(true), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if not self.interaction.data or #selected_cards ~= 1 then return false end
    if #selected >= Self:getMark("heqia-tmp") then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use.skillName = "heqia"
    if Self:isProhibited(Fk:currentRoom():getPlayerById(to_select), to_use) then return false end
    return to_use.skill:modTargetFilter(to_select, selected, Self, to_use, false)
  end,
  feasible = function(self, selected, selected_cards)
    if not self.interaction.data or #selected_cards ~= 1 then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use.skillName = "heqia"
    if to_use.skill:getMinTargetNum() == 0 then
      return (#selected == 0 or table.contains(selected, Self.id)) and to_use.skill:feasible(selected, selected_cards, Self, to_use)
    else
      return #selected > 0
    end
  end,
}
local yinyi = fk.CreateTriggerSkill{
  name = "yinyi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self) and data.damageType == fk.NormalDamage and
      data.from and data.from:getHandcardNum() ~= player:getHandcardNum() and data.from.hp ~= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = Util.TrueFunc,
}
Fk:addSkill(heqia_active)
Fk:addSkill(heqia_viewas)
pangdegong:addSkill(heqia)
pangdegong:addSkill(yinyi)
Fk:loadTranslationTable{
  ["ty__pangdegong"] = "庞德公",
  ["#ty__pangdegong"] = "友睦风疏",
  ["cv:ty__pangdegong"] = "大白siro", -- 本名：陈伟
  ["designer:ty__pangdegong"] = "步穗",
  ["illustrator:ty__pangdegong"] = "君桓文化",
  ["heqia"] = "和洽",
  [":heqia"] = "出牌阶段开始时，你可以选择一项：1.你交给一名其他角色至少一张牌；2.令一名有手牌的其他角色交给你至少一张牌。然后获得牌的角色可以将一张手牌当任意基本牌使用（无距离限制），且此牌目标上限改为X（X为其本次获得的牌数）。",
  ["yinyi"] = "隐逸",
  [":yinyi"] = "锁定技，每回合限一次，当你受到非属性伤害时，若伤害来源的手牌数与体力值均与你不同，防止此伤害。",
  ["heqia_active"] = "和洽",
  ["#heqia-invoke"] = "和洽：交给一名其他角色至少一张牌，或选择一名角色将至少一张牌交给你",
  ["heqia_give"] = "交给一名其他角色至少一张牌",
  ["heqia_prey"] = "令一名角色将至少一张牌交给你",
  ["#heqia-give"] = "和洽：交给 %src 至少一张牌",
  ["heqia_viewas"] = "和洽",
  ["#heqia-use"] = "和洽：你可以将一张手牌当任意基本牌使用，可以指定%arg个目标",

  ["$heqia1"] = "和洽不基，贵贱无司。",
  ["$heqia2"] = "教化大行，天下和洽。",
  ["$yinyi1"] = "采山饮河，所以养性。",
  ["$yinyi2"] = "隐于鱼梁，率尔休畅。",
  ["~ty__pangdegong"] = "终无可避……",
}

return extension
