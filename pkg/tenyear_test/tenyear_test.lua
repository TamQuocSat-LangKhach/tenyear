
local zhurong = General(extension, "ty_sp__zhurong", "qun", 4, 4, General.Female)
local manhou = fk.CreateActiveSkill{
  name = "manhou",
  anim_type = "special",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 0,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 4,
    }
  end,
  prompt = "#manhou-prompt",
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = self.interaction.data or 1
    player:drawCards(n, self.name)
    for i = 1, n, 1 do
      if player.dead then return end
      if i == 1 then
        room:handleAddLoseSkills(player, "-tanluan", nil, true, false)
      elseif i == 2 then
        room:askForDiscard(player, 1, 1, false, self.name, false)
      elseif i == 3 then
        room:loseHp(player, 1, self.name)
        if player.dead then return end
        local targets = {}
        for _, p in ipairs(room.alive_players) do
          if p ~= player and not p:isKongcheng() then
            table.insert(targets, p.id)
          end
        end
        if #targets > 0 then
          targets = room:askForChoosePlayers(player, targets, 1, 1, "#manhou-prey", self.name, false)
          local to = room:getPlayerById(targets[1])
          local id = room:askForCardChosen(player, to, "h", self.name)
          room:obtainCard(player.id, id, false, fk.ReasonPrey)
        end
      elseif i == 4 then
        local targets = {}
        for _, p in ipairs(room.alive_players) do
          if #p:getCardIds{ Player.Equip, Player.Judge } > 0 then
            table.insert(targets, p.id)
          end
        end
        if #targets > 0 then
          targets = room:askForChoosePlayers(player, targets, 1, 1, "#manhou-throw", self.name, false)
          local to = room:getPlayerById(targets[1])
          local id = room:askForCardChosen(player, to, "ej", self.name)
          room:throwCard(id, self.name, to, player)
        end
        room:handleAddLoseSkills(player, "tanluan", nil, true, false)
      end
    end
  end,

  on_lose = function (self, player)
    player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
  end,
}

local tanluan = fk.CreateActiveSkill{
  name = "tanluan",
  prompt = "#tanluan-active",
  anim_type = "offensive",
  max_phase_use_time = 1,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cards, ids = {}, {}
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn_event == nil then return false end
    local end_id = turn_event.id
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          --if not table.contains(cards, id) then
          --  table.insert(cards, id)
            if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard and
                room:getCardArea(id) == Card.DiscardPile then
              table.insertIfNeed(ids, id)
            end
          --end
        end
      end
      return false
    end, end_id)
    if #ids == 0 then return end
    local use = room:askForUseRealCard(player, ids, self.name, "#tanluan-active", {
      expand_pile = ids,
      bypass_times = true,
      extraUse = true,
    }, true)
    if use and use.damageDealt then
      player:setSkillUseHistory("manhou", 0, Player.HistoryPhase)
    end
  end,

  on_lose = function (self, player)
    player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
  end,
}
Fk:loadTranslationTable{
  ["manhou"] = "蛮后",
  [":manhou"] = "出牌阶段限一次，你可以摸至多四张牌，依次执行前等量项："..
  "1.失去〖探乱〗；2.弃置一张手牌；3.失去1点体力并获得一名其他角色的一张手牌；4.弃置场上的一张牌并获得〖探乱〗。",
  ["tanluan"] = "探乱",
  [":tanluan"] = "出牌阶段限一次，你可以使用一张于此回合内因弃置而移至弃牌堆的牌，然后若此牌造成过伤害，〖蛮后〗视为未发动过。",
  ["#manhou-prompt"] = "蛮后：你可以摸至多四张牌，依次执行等量效果",
  ["#manhou-prey"] = "蛮后：选择1名其他角色，获得其1张手牌",
  ["#manhou-throw"] = "蛮后：选择1名角色，弃置其场上的1张牌",
  ["#tanluan-active"] = "发动 探乱，使用一张本回合内因弃置而置入弃牌堆的牌，若造成伤害则重置 蛮后",
}


local lukang = General(extension, "wm__lukang", "wu", 4)
local kegou = fk.CreateTriggerSkill{
  name = "kegou",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self) then
      local events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.DiscardPile then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player.room.discard_pile, info.cardId) then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn)
      return #events == 1
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    cards = table.filter(cards, function (id)
      return table.every(cards, function (id2)
        return Fk:getCardById(id).number >= Fk:getCardById(id2).number
      end)
    end)
    room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
  end,
}
local jiduan = fk.CreateTriggerSkill{
  name = "jiduan",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.firstTarget and
      table.find(AimGroup:getAllTargets(data.tos), function (id)
        return not player.room:getPlayerById(id):isKongcheng() and not table.contains(player:getTableMark("jiduan-turn"), id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(AimGroup:getAllTargets(data.tos), function (id)
      return not room:getPlayerById(id):isKongcheng() and not table.contains(player:getTableMark("jiduan-turn"), id)
    end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jiduan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    if data.card.number ~= 13 then
      room:addTableMark(player, "jiduan-turn", to.id)
    end
    if to:isKongcheng() then return end
    local prompt = "#jiduan0-show"
    if data.card.number > 0 and data.card.number < 14 then
      prompt = "#jiduan-show:::"..data.card.number
    end
    local card = room:askForCard(to, 1, 1, false, self.name, false, nil, "#jiduan-show:::"..data.card.number)
    local yes = prompt ~= "#jiduan0-show" and Fk:getCardById(card[1]).number < data.card.number
    to:showCards(card)
    if player.dead or to.dead or not yes then return end
    local choices = {"jiduan_discard::"..to.id, "jiduan_draw::"..to.id}
    local choice = room:askForChoice(player, choices, self.name)
    if choice:startsWith("jiduan_discard") then
      if table.find(to:getCardIds("h"), function (id)
        return not to:prohibitDiscard(id) and table.contains({1, 2, 3, 4}, Fk:getCardById(id).suit)
      end) then
        local success, dat = room:askForUseActiveSkill(to, "jiduan_active", "#jiduan-discard", false)
        if success and dat then
        else
          dat = {}
          dat.cards = {}
          local suits = {1, 2, 3, 4}
          for _, id in ipairs(to:getCardIds("h")) do
            local suit = Fk:getCardById(id).suit
            if table.contains(suits, suit) and not to:prohibitDiscard(id) then
              table.insert(dat.cards, id)
              table.removeOne(suits, suit)
              if #suits == 0 then
                break
              end
            end
          end
        end
        if #dat.cards > 0 then
          room:throwCard(dat.cards, self.name, to, to)
        end
      end
    else
      local suits = table.filter({1, 2, 3, 4}, function (suit)
        return not table.find(to:getCardIds("h"), function (id)
          return Fk:getCardById(id).suit == suit
        end)
      end)
      if #suits == 0 then return end
      local cards = {}
      local id = -1
      for i = #room.draw_pile, 1, -1 do
        id = room.draw_pile[i]
        if table.removeOne(suits, Fk:getCardById(id).suit) then
          table.insert(cards, id)
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonDraw, self.name, nil, false, to.id)
      end
    end
  end,
}
local jiduan_active = fk.CreateActiveSkill{
  name = "jiduan_active",
  min_card_num = 1,
  target_num = 0,
  card_filter = function (self, to_select, selected, user)
    return table.contains(Self:getCardIds("h"), to_select) and
    not table.find(selected, function (id)
      return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id))
    end) and not Self:prohibitDiscard(to_select)
  end,
  feasible = function (self, selected, selected_cards)
    return #selected == 0 and #selected_cards > 0 and
      not table.find(Self:getCardIds("h"), function (id)
        return Fk:getCardById(id).suit ~= Card.NoSuit and
          not table.find(selected_cards, function (id2)
            return Fk:getCardById(id):compareSuitWith(Fk:getCardById(id2))
          end) and
          not Self:prohibitDiscard(id)
      end)
  end,
}
local dixian = fk.CreateActiveSkill{
  name = "dixian",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  min_card_num = 1,
  target_num = 0,
  prompt = "#dixian",
  can_use = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select)
    return not Self:prohibitDiscard(Fk:getCardById(to_select)) and table.contains(Self:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local cards = {}
    for i = 13, 1, -1 do
      for _, id in ipairs(room.draw_pile) do
        if Fk:getCardById(id).number == i then
          table.insert(cards, id)
          if #cards == #effect.cards then
            break
          end
        end
      end
      if #cards == #effect.cards then
        break
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id, "@@dixian-inhand")
    end
  end,
}
local dixian_maxcards = fk.CreateMaxCardsSkill{
  name = "#dixian_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@dixian-inhand") > 0
  end,
}
Fk:loadTranslationTable{
}
--[[Fk:loadTranslationTable{
  ["kegou"] = "克构",
  [":kegou"] = "锁定技，其他角色回合结束时，你随机获得本回合进入弃牌堆的点数最大的一张牌。",
}
Fk:loadTranslationTable{
  ["jiduan"] = "急断",
  [":jiduan"] = "每回合每名角色限一次，当你使用牌指定目标后，你可以令其中一名角色展示一张手牌，若点数小于你使用的牌，你选择一项："..
  "1.其弃置每种花色的手牌各一张；2.其摸手牌中没有的花色各一张牌。若你使用的牌点数为K，则不计入此技能次数限制。",
  ["#jiduan-choose"] = "急断：令一名角色展示一张手牌，若点数小于你使用的牌则令其弃牌或摸牌",
  ["#jiduan0-show"] = "急断：请展示一张手牌",
  ["#jiduan-show"] = "急断：请展示一张手牌，若点数小于%arg则执行效果",
  ["jiduan_discard"] = "%dest 弃置每种花色手牌各一张",
  ["jiduan_draw"] = "%dest 摸手牌中缺少的花色牌各一张",
  ["jiduan_active"] = "急断",
  ["#jiduan-discard"] = "急断：请弃置每种花色的手牌各一张",
}
Fk:loadTranslationTable{
  ["dixian"] = "砥贤",
  [":dixian"] = "限定技，出牌阶段，你可以弃置任意张手牌，从牌堆中按点数从大到小顺序获得等量的牌，这些牌不计入手牌上限。",
  ["#dixian"] = "砥贤：弃置任意张手牌，从牌堆按点数从大到小获得等量的牌",
  ["@@dixian-inhand"] = "砥贤",
}]]

local laoyan = fk.CreateTriggerSkill{
  name = "laoyan",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player == target and player:hasSkill(self) then
      local targets = AimGroup:getAllTargets(data.tos)
      local tos = {}
      for _, p in ipairs(player.room.alive_players) do
        if p ~= player and table.contains(targets, p.id) then
          table.insert(tos, p.id)
        end
      end
      if #tos > 0 then
        self.cost_data = { tos = tos }
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(self.cost_data.tos) do
      table.insertIfNeed(data.nullifiedTargets, to)
    end
  end,
}

local jueyan = fk.CreateTriggerSkill{
  name = "jueyanz",
  anim_type = "control",
  dynamic_desc = function(self, player)
    return
      "jueyanz_inner:" ..
      ((#player:getTableMark("jueyanz_choices") > 2) and ":" or "jueyanz_pindian:jueyanz_update") .. ":" ..
      (player:getMark("jueyanz_damage") + 1) .. ":" ..
      (player:getMark("jueyanz_recover") + 1) .. ":" ..
      (player:getMark("jueyanz_prey") + 1)
  end,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player ~= target or not player:hasSkill(self) then return false end
    local tos = TargetGroup:getRealTargets(data.tos)
    if #tos ~= 1 then return false end
    if player.id == tos[1] then return false end
    local mark = player:getTableMark("jueyanz_choices")
    if #mark > 2 then return true end
    local to = player.room:getPlayerById(tos[1])
    return not to.dead and player:canPindian(to)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getTableMark("jueyanz_choices")
    local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
    if #mark > 2 then
      local choices = {
        "jueyanz_damage::" .. to.id .. ":" .. tostring(player:getMark("jueyanz_damage") + 1),
        "jueyanz_recover:::" .. tostring(player:getMark("jueyanz_recover") + 1),
        "jueyanz_prey::" .. to.id .. ":" .. tostring(player:getMark("jueyanz_prey") + 1),
        "Cancel"
      }
      local choice = room:askForChoice(player, choices, self.name, nil, false)
      if choice == "Cancel" then return false end
      self.cost_data = { tos = { to.id }, choice = choice:split(":")[1] }
      return true
    elseif room:askForSkillInvoke(player, self.name, nil, "#jueyanz-invoke::" .. to.id) then
      self.cost_data = { tos = { to.id } }
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data.choice
    local to = room:getPlayerById(self.cost_data.tos[1])
    if choice == nil then
      local pindian = player:pindian({to}, self.name)
      if pindian.results[to.id].winner ~= player or player.dead then return false end
      local choices = {
        "jueyanz_damage::" .. to.id .. ":" .. tostring(player:getMark("jueyanz_damage") + 1),
        "jueyanz_recover:::" .. tostring(player:getMark("jueyanz_recover") + 1),
        "jueyanz_prey::" .. to.id .. ":" .. tostring(player:getMark("jueyanz_prey") + 1),
        "Cancel"
      }
      choice = room:askForChoice(player, choices, self.name, nil, false)
      if choice == "Cancel" then return false end
      choice = choice:split(":")[1]
    end
    local x = player:getMark(choice) + 1
    if choice == "jueyanz_damage" then
      room:damage{
        from = player,
        to = player,
        damage = x,
        skillName = self.name,
      }
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = x,
          skillName = self.name,
        }
      end
    elseif choice == "jueyanz_recover" then
      if player:isWounded() then
        room:recover{
          who = player,
          num = x,
          recoverBy = player,
          skillName = self.name
        }
      end
    else
      x = math.max(x, #to:getCardIds(Player.Hand))
      if x > 0 then
        local ids = room:askForCardsChosen(player, to, x, x, "h", self.name)
        room:obtainCard(player.id, ids, false, fk.ReasonPrey)
      end
    end
    if not player:hasSkill(self, true) then return false end
    for _, choice_name in ipairs({"jueyanz_damage", "jueyanz_recover", "jueyanz_prey"}) do
      if choice_name == choice then
        room:setPlayerMark(player, choice_name, 0)
      else
        room:addPlayerMark(player, choice_name, 1)
      end
    end
    local mark = player:getTableMark("jueyanz_choices")
    if #mark > 2 then return false end
    room:addTableMarkIfNeed(player, "jueyanz_choices", choice)
  end,

  on_lose = function (self, player)
    local room = player.room
    for _, name in ipairs({"jueyanz_damage", "jueyanz_recover", "jueyanz_prey", "jueyanz_choices"}) do
      room:setPlayerMark(player, name, 0)
    end
  end,
}

Fk:loadTranslationTable{
  ["jueyanz"] = "诀言",
  [":jueyanz"] = "当你使用仅指定唯一目标的手牌结算结束后（每回合每种类别限一次），你可以选择一项："..
    "1.摸1张牌；2.随机获得弃牌堆1张牌；3.与一名角色拼点，赢的角色对没赢的角色造成1点伤害。"..
    "然后，此次选择的选项的数值改为1，其他选项的数值均+1。",

  ["#jueyanz-invoke"] = "是否发动 诀言，与 %dest 拼点，若你赢则可选择一项效果",
  ["jueyanz_damage"] = "对你和%dest各造成%arg点伤害",
  ["jueyanz_recover"] = "回复%arg点体力",
  ["jueyanz_prey"] = "获得%dest的%arg张手牌",

  [":jueyanz_inner"] = "当你使用的牌结算结束后，若目标数为1且此目标不为你，你可以{1}选择："..
    "1.对你和其各造成{3}点伤害；2.回复{4}点体力；3.获得其的{5}张手牌。"..
    "然后，此次选择的选项的数值改为1，其他选项的数值均+1{2}。",
  ["jueyanz_pindian"] = "与其拼点，若你赢，你",
  ["jueyanz_update"] = "，若三个选项均被选择过，你修改此技能（跳过拼点步骤直接选择选项）",
}
