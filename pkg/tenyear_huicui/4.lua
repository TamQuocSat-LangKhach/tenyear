
local wangjun = General(extension, "ty__wangjun", "qun", 4)
wangjun.subkingdom = "jin"
local changqu = fk.CreateActiveSkill{
  name = "changqu",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if to_select == Self.id then return false end
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return target:getNextAlive() == Self or Self:getNextAlive() == target
    else
      if table.contains(selected, Self:getNextAlive().id) then
        if Fk:currentRoom():getPlayerById(selected[#selected]):getNextAlive() == target then
          return true
        end
      end
      if Fk:currentRoom():getPlayerById(selected[1]):getNextAlive() == Self then
        if target:getNextAlive().id == selected[#selected] then
          return true
        end
      end
    end
  end,
  feasible = function(self, selected, selected_cards)
    if #selected > 0 then
      local p1 = Fk:currentRoom():getPlayerById(selected[1])
      if not (p1:getNextAlive() == Self or Self:getNextAlive() == p1) then return false end
      if #selected == 1 then return true end
      if p1:getNextAlive() == Self then
        for i = 1, #selected - 1, 1 do
          if Fk:currentRoom():getPlayerById(selected[i+1]):getNextAlive() ~= Fk:currentRoom():getPlayerById(selected[i]) then
            return false
          end
        end
        return true
      end
      if Self:getNextAlive() == p1 then
        for i = 1, #selected - 1, 1 do
          if Fk:currentRoom():getPlayerById(selected[i]):getNextAlive() ~= Fk:currentRoom():getPlayerById(selected[i+1]) then
            return false
          end
        end
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = 0
    for _, id in ipairs(effect.tos) do
      local target = room:getPlayerById(id)
      if not target.dead then
        room:setPlayerMark(target, "@@battleship", 1)
        local cards = {}
        local x = math.max(n, 1)
        if target:getHandcardNum() >= x then
          cards = room:askForCard(target, x, x, false, self.name, true, ".", "#changqu-card:"..player.id.."::"..x)
        end
        if #cards > 0 then
          room:obtainCard(player, cards, false, fk.ReasonGive, id)
          n = n + 1
        else
          room:doIndicate(player.id, {target.id})
          if not target.chained then
            target:setChainState(true)
          end
          room:addPlayerMark(target, "@changqu", x)
          room:setPlayerMark(target, "@@battleship", 0)
          break
        end
        room:setPlayerMark(target, "@@battleship", 0)
      end
      if player.dead then return end
    end
  end,
}
local changqu_trigger = fk.CreateTriggerSkill{
  name = "#changqu_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@changqu") > 0 and data.damageType ~= fk.NormalDamage
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@changqu")
    player.room:setPlayerMark(player, "@changqu", 0)
  end,
}
local tongye = fk.CreateTriggerSkill{
  name = "tongye",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.Deathed, fk.DrawNCards},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(self) and
      (
        event ~= fk.DrawNCards or
        (player == target and player:getMark("@tongye_count") > 0 and player:getMark("@tongye_count") < 4)
      )
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      data.n = data.n + 4 - player:getMark("@tongye_count")
    else
      local room = player.room
      local kingdoms = {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      room:setPlayerMark(player, "@tongye_count", #kingdoms)
      room:broadcastProperty(player, "MaxCards")
      if #kingdoms == 1 then
        room:recover{
          who = player,
          num = 3,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
  end,
}
local tongye_maxcards = fk.CreateMaxCardsSkill{
  name = "#tongye_maxcards",
  correct_func = function(self, player)
    if
      player:hasSkill(tongye) and
      player:getMark("@tongye_count") > 0 and
      player:getMark("@tongye_count") <= 4
    then
      return 3
    end
  end,
}
local tongye_attackrange = fk.CreateAttackRangeSkill{
  name = "#tongye_attackrange",
  correct_func = function (self, from, to)
    if
      from:hasSkill(tongye) and
      from:getMark("@tongye_count") > 0 and
      from:getMark("@tongye_count") <= 3
    then
      return 3
    end
  end,
}
local tongye_targetmod = fk.CreateTargetModSkill{
  name = "#tongye_targetmod",
  residue_func = function(self, player, skill, scope)
    if
      skill.trueName == "slash_skill" and
      player:hasSkill(tongye) and
      player:getMark("@tongye_count") > 0 and
      player:getMark("@tongye_count") <= 2
    then
      return 3
    end
    return 0
  end,
}
Fk:loadTranslationTable{
  ["tongye"] = "统业",
  [":tongye"] = "锁定技，游戏开始时，或其他角色死亡后，你根据场上势力数获得对应效果（覆盖之前获得的效果）：不大于4，你的手牌上限+3；" ..
  "不大于3，你的攻击范围+3，摸牌阶段摸牌数增加4减去势力数；不大于2，你于出牌阶段内使用【杀】的次数上限+3；为1，你回复3点体力。",
  ["changqu"] = "长驱",
  [":changqu"] = "出牌阶段限一次，你可以<font color='red'>开一艘战舰</font>，从你的上家或下家开始选择任意名座次连续的其他角色，第一个目标角色获得战舰标记。"..
  "获得战舰标记的角色选择一项：1.交给你X张手牌，然后将战舰标记移动至下一个目标；2.下次受到的属性伤害+X，然后横置武将牌（X为本次选择1的次数，至少为1）。",
  ["@@battleship"] = "战舰",
  ["#changqu-card"] = "长驱：交给 %src %arg张手牌以使战舰驶向下一名角色",
  ["@changqu"] = "长驱",
  ["@tongye_count"] = "统业",

  ["$tongye1"] = "白首全金瓯，著风流于春秋。",
  ["$tongye2"] = "长戈斩王气，统大业于四海。",
  ["$changqu1"] = "布横江之铁索，徒自缚耳。",
  ["$changqu2"] = "艨艟击浪，可下千里江陵。",
}

--奇人异士：张宝 司马徽 蒲元 管辂 葛玄 杜夔 朱建平 吴范 赵直 周宣 笮融
local zhangbao = General(extension, "ty__zhangbao", "qun", 3)
local zhoufu = fk.CreateActiveSkill{
  name = "ty__zhoufu",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__zhoufu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and table.contains(Self.player_cards[Player.Hand], to_select)
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and to_select ~= Self.id and #Fk:currentRoom():getPlayerById(to_select):getPile("ty__zhoufu_zhou") == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    target:addToPile("ty__zhoufu_zhou", effect.cards, true, self.name, effect.from)
  end,
}
local zhoufu_trigger = fk.CreateTriggerSkill{
  name = "#ty__zhoufu_trigger",

  refresh_events = {fk.StartJudge},
  can_refresh = function(self, event, target, player, data)
    return #target:getPile("ty__zhoufu_zhou") > 0 and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    data.card = Fk:getCardById(target:getPile("ty__zhoufu_zhou")[1])
  end,
}
zhoufu:addRelatedSkill(zhoufu_trigger)
zhangbao:addSkill(zhoufu)
local yingbing = fk.CreateTriggerSkill{
  name = "ty__yingbing",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and #player.room:getPlayerById(data.to):getPile("ty__zhoufu_zhou") > 0
    and not table.contains(player:getTableMark("ty__yingbing-turn"), data.to)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "ty__yingbing-turn", data.to)
    player:drawCards(2, self.name)
  end,
}
zhangbao:addSkill(yingbing)
Fk:loadTranslationTable{
  ["ty__zhangbao"] = "张宝",
  ["#ty__zhangbao"] = "地公将军",
  ["illustrator:ty__zhangbao"] = "小牛",

  ["ty__zhoufu"] = "咒缚",
  [":ty__zhoufu"] = "出牌阶段限一次，你可以将一张手牌置于一名没有“咒”的其他角色的武将牌旁，称为“咒”（当有“咒”的角色判定时，将“咒”作为判定牌）。",
  ["#ty__zhoufu"] = "咒缚：将一张手牌置为一名角色的“咒缚”牌，其判定时改为将“咒缚”牌作为判定牌",
  ["#ty__zhoufu_trigger"] = "咒缚",
  ["ty__zhoufu_zhou"] = "咒",

  ["ty__yingbing"] = "影兵",
  [":ty__yingbing"] = "锁定技，每回合每名角色限一次，当你使用牌指定有“咒”的角色为目标后，你摸两张牌。",

  ["$ty__zhoufu1"] = "这束缚，可不是你能挣脱的！",
  ["$ty__zhoufu2"] = "咒术显灵，助我改运！",
  ["$ty__yingbing1"] = "青龙白虎，队仗纷纭！",
  ["$ty__yingbing2"] = "我有影兵三万，何惧你们！",
  ["~ty__zhangbao"] = "你们，如何能破我咒术？",
}

local simahui = General(extension, "simahui", "qun", 3)
local doJianjieMarkChange = function (room, player, mark, acquired, proposer)
  local skill = (mark == "@@dragon_mark") and "jj__huoji&" or "jj__lianhuan&"
  room:setPlayerMark(player, mark, acquired and 1 or 0)
  if not acquired then skill = "-"..skill end
  room:handleAddLoseSkills(player, skill, nil, false)
  local double_mark = (player:getMark("@@dragon_mark") > 0 and player:getMark("@@phoenix_mark") > 0)
  local yy_skill = double_mark and "jj__yeyan&" or "-jj__yeyan&"
  room:handleAddLoseSkills(player, yy_skill, nil, false)
  if acquired then
    proposer:broadcastSkillInvoke("jianjie", double_mark and 3 or math.random(2))
  end
end
local jianjie = fk.CreateActiveSkill{
  name = "jianjie",
  anim_type = "control",
  mute = true,
  can_use = function(self, player)
    return player:getMark("jianjie-turn") == 0 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  interaction = function()
    return UI.ComboBox {choices = {"dragon_mark_move", "phoenix_mark_move"}}
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 2,
  target_filter = function(self, to_select, selected)
    if #selected == 2 or not self.interaction.data then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    local mark = (self.interaction.data == "dragon_mark_move") and "@@dragon_mark" or "@@phoenix_mark"
    if #selected == 0 then
      return to:getMark(mark) > 0
    else
      return to:getMark(mark) == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, self.name)
    local from = room:getPlayerById(effect.tos[1])
    local to = room:getPlayerById(effect.tos[2])
    local mark = (self.interaction.data == "dragon_mark_move") and "@@dragon_mark" or "@@phoenix_mark"
    doJianjieMarkChange (room, from, mark, false, player)
    doJianjieMarkChange (room, to, mark, true, player)
  end,
}
local jianjie_trigger = fk.CreateTriggerSkill{
  name = "#jianjie_trigger",
  events = {fk.TurnStart, fk.Death},
  main_skill = jianjie,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player:hasSkill(jianjie) and player:getMark("jianjie-turn") > 0
    else
      return player:hasSkill(jianjie) and (target:getMark("@@dragon_mark") > 0 or target:getMark("@@phoenix_mark") > 0)
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.TurnStart then return true end
    local room = player.room
    local gives = {}
    if target:getMark("@@dragon_mark") > 0 then
      local dra_tars = table.filter(room.alive_players, function(p) return p:getMark("@@dragon_mark") == 0 end)
      if #dra_tars > 0 then
        local tos = room:askForChoosePlayers(player, table.map(dra_tars, Util.IdMapper), 1, 1, "#dragon_mark-move::"..target.id, self.name, true)
        if #tos > 0 then
          table.insert(gives, {"@@dragon_mark", tos[1]})
        end
      end
    end
    if target:getMark("@@phoenix_mark") > 0 then
      local dra_tars = table.filter(room.alive_players, function(p) return p:getMark("@@phoenix_mark") == 0 end)
      if #dra_tars > 0 then
        local tos = room:askForChoosePlayers(player, table.map(dra_tars, Util.IdMapper), 1, 1, "#phoenix_mark-move::"..target.id, self.name, true)
        if #tos > 0 then
          table.insert(gives, {"@@phoenix_mark", tos[1]})
        end
      end
    end
    if #gives > 0 then
      self.cost_data = gives
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "jianjie")
    if event == fk.TurnStart then
      local dra_tars = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("@@dragon_mark") == 0 end)
      local dra
      if #dra_tars > 0 then
        local tos = room:askForChoosePlayers(player, table.map(dra_tars, Util.IdMapper), 1, 1, "#dragon_mark-give", self.name, false)
        if #tos > 0 then
          dra = room:getPlayerById(tos[1])
          doJianjieMarkChange (room, dra, "@@dragon_mark", true, player)
        end
      end
      local pho_tars = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("@@phoenix_mark") == 0 end)
      table.removeOne(pho_tars, dra)
      if #pho_tars > 0 then
        local tos = room:askForChoosePlayers(player, table.map(pho_tars, Util.IdMapper), 1, 1, "#phoenix_mark-give", self.name, false)
        if #tos > 0 then
          local pho = room:getPlayerById(tos[1])
          doJianjieMarkChange (room, pho, "@@phoenix_mark", true, player)
        end
      end
    else
      for _, dat in ipairs(self.cost_data) do
        local mark = dat[1]
        local p = room:getPlayerById(dat[2])
        doJianjieMarkChange (room, p, mark, true, player)
      end
    end
  end,

  refresh_events = {fk.TurnStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function (self, event, target, player, data)
    if event == fk.TurnStart then
      return player:hasSkill(self,true) and target == player
    elseif event == fk.EventAcquireSkill then
      return target == player and data == self and player.room:getBanner("RoundCount")
    elseif event == fk.EventLoseSkill then
      return data == self and (player:getMark("@@dragon_mark") > 0 or player:getMark("@@phoenix_mark") > 0)
    elseif event == fk.BuryVictim then
      return (target == player or target:hasSkill(self, true, true))
      and (player:getMark("@@dragon_mark") > 0 or player:getMark("@@phoenix_mark") > 0)
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart or event == fk.EventAcquireSkill then
      local current_event = room.logic:getCurrentEvent()
      if not current_event then return end
      local turn_event = current_event:findParent(GameEvent.Turn, true)
      if not turn_event then return end
      local events = room.logic.event_recorder[GameEvent.Turn] or Util.DummyTable
      for _, e in ipairs(events) do
        local current_player = e.data[1]
        if current_player == player then
          if turn_event.id == e.id then
            room:setPlayerMark(player, "jianjie-turn", 1)
          end
          break
        end
      end
    else
      doJianjieMarkChange (room, player, "@@dragon_mark", false)
      doJianjieMarkChange (room, player, "@@phoenix_mark", false)
    end
  end,
}
jianjie:addRelatedSkill(jianjie_trigger)
simahui:addSkill(jianjie)
local chenghao = fk.CreateTriggerSkill{
  name = "chenghao",
  anim_type = "drawcard",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damageType ~= fk.NormalDamage and data.beginnerOfTheDamage and not data.chain and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 1
    for _, p in ipairs(room.alive_players) do
      if p.chained then
        n = n + 1
      end
    end
    local cards = room:getNCards(n)
    room:askForYiji(player, cards, room.alive_players, self.name, #cards, #cards, nil, cards)
  end,
}
simahui:addSkill(chenghao)
local yinshi = fk.CreateTriggerSkill{
  name = "yinshi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and (data.damageType ~= fk.NormalDamage or (data.card and data.card.type == Card.TypeTrick)) and player:getMark("@@dragon_mark") == 0 and player:getMark("@@phoenix_mark") == 0 and #player:getEquipments(Card.SubtypeArmor) == 0
  end,
  on_use = Util.TrueFunc,
}
simahui:addSkill(yinshi)
local jj__lianhuan = fk.CreateActiveSkill{
  name = "jj__lianhuan&",
  card_num = 1,
  min_target_num = 0,
  times = function(self)
    return Self.phase == Player.Play and 3 - Self:usedSkillTimes(self.name, Player.HistoryTurn) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) < 3
  end,
  card_filter = function(self, to_select, selected, selected_targets)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Club and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards, _, _, player)
    if #selected_cards == 1 then
      local card = Fk:cloneCard("iron_chain")
      card:addSubcard(selected_cards[1])
      return card.skill:canUse(player, card) and card.skill:targetFilter(to_select, selected, selected_cards, card, nil, player) and
      not player:prohibitUse(card) and not player:isProhibited(Fk:currentRoom():getPlayerById(to_select), card)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if #effect.tos == 0 then
      room:recastCard(effect.cards, player, self.name)
    else
      room:sortPlayersByAction(effect.tos)
      room:useVirtualCard("iron_chain", effect.cards, player, table.map(effect.tos, Util.Id2PlayerMapper), self.name)
    end
  end,
}
Fk:addSkill(jj__lianhuan)
local jj__huoji = fk.CreateViewAsSkill{
  name = "jj__huoji&",
  anim_type = "offensive",
  pattern = "fire_attack",
  times = function(self)
    return Self.phase == Player.Play and 3 - Self:usedSkillTimes(self.name, Player.HistoryTurn) or -1
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryTurn) < 3
  end,
}
Fk:addSkill(jj__huoji)
local jj__yeyan = fk.CreateActiveSkill{
  name = "jj__yeyan&",
  anim_type = "offensive",
  min_target_num = 1,
  max_target_num = 3,
  min_card_num = 0,
  max_card_num = 4,
  frequency = Skill.Limited,
  prompt = function(self, cards)
    local yeyan_type = self.interaction.data
    if yeyan_type == "great_yeyan" then
      return "#yeyan-great-active"
    elseif yeyan_type == "middle_yeyan" then
      if #cards ~= 4 then
        return "#yeyan-middle-active"
      else
        return "#yeyan-middle-choose"
      end
    else
      return "#yeyan-small-active"
    end
  end,
  interaction = function()
    return UI.ComboBox {
      choices = {"small_yeyan", "middle_yeyan", "great_yeyan"}
    }
  end,
  target_tip = function(self, to_select, selected, selected_cards, card, selectable, extra_data)
    if not selectable then return end
    if #selected == 0 then
      return { {content = self.interaction.data, type = "normal"} }
    else
      if to_select == selected[1] then
        return { {content = self.interaction.data, type = "warning"} }
      elseif table.contains(selected, to_select) then
        return { {content = "small_yeyan", type = "warning"} }
      else
        return { {content = "small_yeyan", type = "normal"} }
      end
    end
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == "small_yeyan" or #selected > 3 or
    Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerHand then return false end
    local card = Fk:getCardById(to_select)
    return not Self:prohibitDiscard(card) and card.suit ~= Card.NoSuit and
    table.every(selected, function (id) return card.suit ~= Fk:getCardById(id).suit end)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if self.interaction.data == "small_yeyan" then
      return #selected_cards == 0 and #selected < 3
    elseif self.interaction.data == "middle_yeyan" then
      return #selected_cards == 4 and #selected < 2
    else
      return #selected_cards == 4 and #selected == 0
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    doJianjieMarkChange (room, player, "@@dragon_mark", false, player)
    doJianjieMarkChange (room, player, "@@phoenix_mark", false, player)
    local first = effect.tos[1]
    local max_damage = 1
    if self.interaction.data == "middle_yeyan" then
      max_damage = 2
    elseif self.interaction.data == "great_yeyan" then
      max_damage = 3
    end
    room:sortPlayersByAction(effect.tos)
    if #effect.cards > 0 then
      room:throwCard(effect.cards, self.name, player, player)
    end
    if max_damage > 1 and not player.dead then
      room:loseHp(player, 3, self.name)
    end
    for _, pid in ipairs(effect.tos) do
      local to = room:getPlayerById(pid)
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = (pid == first) and max_damage or 1,
          damageType = fk.FireDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
Fk:addSkill(jj__yeyan)
Fk:loadTranslationTable{
  ["simahui"] = "司马徽",
  ["#simahui"] = "水镜先生",
  ["cv:simahui"] = "于松涛", -- 艺名：爱恰饭的漠桀
  ["illustrator:simahui"] = "黑桃J",
  ["jianjie"] = "荐杰",
  [":jianjie"] = "①你的第一个回合开始时，你令一名其他角色获得“龙印”，然后令另一名其他角色获得“凤印”；②出牌阶段限一次（你的第一个回合除外），或当拥有“龙印”/“凤印”的角色死亡时，你可以转移“龙印”/“凤印”。"..
  "<br><font color='grey'>•拥有 “龙印”/“凤印” 的角色视为拥有技能“火计”/“连环”（均一回合限三次）；"..
  "<br>•同时拥有“龙印”和“凤印”的角色视为拥有技能“业炎”，且发动“业炎”时移去“龙印”和“凤印”。"..
  "<br>•你失去〖荐杰〗或死亡时移除“龙印”/“凤印”。",
  ["#jianjie_trigger"] = "荐杰",
  ["@@dragon_mark"] = "龙印",
  ["@@phoenix_mark"] = "凤印",
  ["#dragon_mark-give"] = "荐杰：令一名其他角色获得“龙印”",
  ["#phoenix_mark-give"] = "荐杰：令一名其他角色获得“凤印”",
  ["#dragon_mark-move"] = "荐杰：令一名角色获得 %dest 的“龙印”",
  ["#phoenix_mark-move"] = "荐杰：令一名角色获得 %dest 的“凤印”",
  ["dragon_mark_move"] = "转移“龙印”",
  ["phoenix_mark_move"] = "转移“凤印”",

  ["chenghao"] = "称好",
  [":chenghao"] = "当一名角色受到属性伤害后，若其受到此伤害前处于“连环状态”且是此伤害传导的起点，你可以观看牌堆顶的X张牌并将这些牌分配给任意角色（X为横置角色数+1）。",

  ["yinshi"] = "隐士",
  [":yinshi"] = "锁定技，当你受到属性伤害或锦囊牌造成的伤害时，若你没有“龙印”、“凤印”且装备区内没有防具牌，防止此伤害。",

  ["jj__lianhuan&"] = "连环",
  [":jj__lianhuan&"] = "你可以将一张梅花手牌当【铁索连环】使用或重铸（每回合限三次）。",
  ["jj__huoji&"] = "火计",
  [":jj__huoji&"] = "你可以将一张红色手牌当【火攻】使用（每回合限三次）。",
  ["jj__yeyan&"] = "业炎",
  [":jj__yeyan&"] = "限定技，出牌阶段，你可以移去“龙印”和“凤印”并指定一至三名角色，你分别对这些角色造成至多共计3点火焰伤害；若你对一名角色分配2点或更多的火焰伤害，你须先弃置四张不同花色的手牌并失去3点体力。",

  ["$jianjie1"] = "二者得一，可安天下。",
  ["$jianjie2"] = "公怀王佐之才，宜择人而仕。",
  ["$jianjie3"] = "二人齐聚，汉室可兴矣。",
  ["$chenghao1"] = "好，很好，非常好。",
  ["$chenghao2"] = "您的话也很好。",
  ["$yinshi1"] = "山野闲散之人，不堪世用。",
  ["$yinshi2"] = "我老啦，会有胜我十倍的人来帮助你。",
  ["~simahui"] = "这似乎……没那么好了……",
}

local puyuan = General(extension, "ty__puyuan", "shu", 4)
local tianjiang = fk.CreateActiveSkill{
  name = "tianjiang",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player.player_cards[Player.Equip] > 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected, cards)
    if #selected == 0 and #cards == 1 and to_select ~= Self.id then
      return #Fk:currentRoom():getPlayerById(to_select):getAvailableEquipSlots(Fk:getCardById(cards[1]).sub_type) > 0
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    room:moveCardIntoEquip(target, card.id, self.name, true, player)
    if table.contains({"red_spear", "quenched_blade", "poisonous_dagger", "water_sword", "thunder_blade"}, card.name) then
      player:drawCards(2, self.name)
    end
  end,
}
local tianjiang_trigger = fk.CreateTriggerSkill{
  name = "#tianjiang_trigger",
  events = {fk.GameStart},
  main_skill = tianjiang,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("tianjiang")
    local equipMap = {}
    for _, id in ipairs(room.draw_pile) do
      local sub_type = Fk:getCardById(id).sub_type
      if Fk:getCardById(id).type == Card.TypeEquip and player:hasEmptyEquipSlot(sub_type) then
        local list = equipMap[tostring(sub_type)] or {}
        table.insert(list, id)
        equipMap[tostring(sub_type)] = list
      end
    end

    local put = U.getRandomCards(equipMap, 2)
    if #put > 0 then
      room:moveCardIntoEquip(player, put, self.name, false, player)
    end
  end,
}
local zhuren = fk.CreateActiveSkill{
  name = "zhuren",
  anim_type = "special",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local card = Fk:getCardById(effect.cards[1])
    local get
    local name = "slash"
    if card.name == "lightning" then
      name = "thunder_blade"
    elseif card.suit == Card.Heart then
      name = "red_spear"
    elseif card.suit == Card.Diamond then
      name = "quenched_blade"
    elseif card.suit == Card.Spade then
      name = "poisonous_dagger"
    elseif card.suit == Card.Club then
      name = "water_sword"
    end
    if name ~= "slash" and name ~= "thunder_blade" then
      if (0 < card.number and card.number < 5 and math.random() > 0.85) or
        (4 < card.number and card.number < 9 and math.random() > 0.9) or
        (8 < card.number and card.number < 13 and math.random() > 0.95) then
        name = "slash"
      end
    end
    if name ~= "slash" then
      get = table.find(U.prepareDeriveCards(room, {
        {"red_spear", Card.Heart, 1},
        {"quenched_blade", Card.Diamond, 1},
        {"poisonous_dagger", Card.Spade, 1},
        {"water_sword", Card.Club, 1},
        {"thunder_blade", Card.Spade, 1}
      }, "zhuren_derivecards"), function (id)
        return room:getCardArea(id) == Card.Void and Fk:getCardById(id).name == name
      end)
      if not get then
        name = "slash"
      end
    end
    if name == "slash" then
      room:setCardEmotion(effect.cards[1], "judgebad")
    else
      room:setCardEmotion(effect.cards[1], "judgegood")
    end
    room:delay(1000)
    if name == "slash" then
      local ids = room:getCardsFromPileByRule("slash")
      if #ids > 0 then
        room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
      end
    elseif get then
      room:setCardMark(Fk:getCardById(get), MarkEnum.DestructIntoDiscard, 1)
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
tianjiang:addRelatedSkill(tianjiang_trigger)
puyuan:addSkill(tianjiang)
puyuan:addSkill(zhuren)
Fk:loadTranslationTable{
  ["ty__puyuan"] = "蒲元",
  ["#ty__puyuan"] = "淬炼百兵",
  ["illustrator:ty__puyuan"] = "ZOO",
  ["tianjiang"] = "天匠",
  [":tianjiang"] = "游戏开始时，将牌堆中随机两张不同副类别的装备牌置入你的装备区。出牌阶段，你可以将装备区里的一张牌移动至其他角色的装备区"..
  "（可替换原装备），若你移动的是〖铸刃〗打造的装备，你摸两张牌。",
  ["zhuren"] = "铸刃",
  [":zhuren"] = "出牌阶段限一次，你可以弃置一张手牌。根据此牌的花色点数，你有一定概率打造成功并获得一张武器牌（若打造失败或武器已有则改为摸一张【杀】，"..
  "花色决定武器名称，点数决定成功率）。此武器牌进入弃牌堆时，将之移出游戏。",
  ["#tianjiang_trigger"] = "天匠",

  ["$tianjiang1"] = "巧夺天工，超凡脱俗。",
  ["$tianjiang2"] = "天赐匠法，精心锤炼。",
  ["$zhuren1"] = "造刀三千口，用法各不同。",
  ["$zhuren2"] = "此刀，可劈铁珠之筒。",
  ["~ty__puyuan"] = "铸木镂冰，怎成大器。",
}

local guanlu = General(extension, "guanlu", "wei", 3)
local busuan = fk.CreateActiveSkill {
  name = "busuan",
  anim_type = "control",
  prompt = "#busuan-active",
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
    local names = player:getMark("busuan_names")
    if type(names) ~= "table" then
      --这里其实应该用真实卡名的，但是线上不是
      names = U.getAllCardNames("btd")
      room:setPlayerMark(player, "busuan_names", names)
    end
    local mark = target:getTableMark(self.name)
    table.insertTable(mark, room:askForChoices(player, names, 1, 2, self.name, "#busuan-choose::" .. target.id, false))
    room:setPlayerMark(target, self.name, mark)
  end,
}
local busuan_trigger = fk.CreateTriggerSkill {
  name = "#busuan_trigger",
  mute = true,
  events = {fk.BeforeDrawCard},
  can_trigger = function(self, event, target, player, data)
    return player == target and data.num > 0 and player.phase == Player.Draw and type(player:getMark(busuan.name)) == "table"
    --FIXME: can't find skillName(game_rule)!!
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local card_names = player:getMark(busuan.name)
    for i = 1, #card_names, 1 do
      table.insert(cards, -1)
    end
    for i = 1, #card_names, 1 do
      if cards[i] == -1 then
        local name = card_names[i]
        local x = #table.filter(card_names, function (card_name)
          return card_name == name end)

        local tosearch = room:getCardsFromPileByRule(".|.|.|.|" .. name, x, "discardPile")
        if #tosearch < x then
          table.insertTable(tosearch, room:getCardsFromPileByRule(".|.|.|.|" .. name, x - #tosearch))
        end

        for i2 = 1, #card_names, 1 do
          if card_names[i2] == name then
            if #tosearch > 0 then
              cards[i2] = tosearch[1]
              table.remove(tosearch, 1)
            else
              cards[i2] = -2
            end
          end
        end
      end
    end
    local to_get = {}
    local card_names_copy = table.clone(card_names)
    for i = 1, #card_names, 1 do
      if #to_get >= data.num then break end
      if cards[i] > -1 then
        table.insert(to_get, cards[i])
        table.removeOne(card_names_copy, card_names[i])
      end
    end

    room:setPlayerMark(player, busuan.name, (#card_names_copy > 0) and card_names_copy or 0)

    data.num = data.num - #to_get

    if #to_get > 0 then
      room:moveCards({
        ids = to_get,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = busuan.name,
        moveVisible = false,
      })
    end
  end,
}
Fk:loadTranslationTable{
  ["busuan"] = "卜算",
  [":busuan"] = "出牌阶段限一次，你可以选择一名其他角色，然后选择至多两种基本牌或锦囊牌牌名。"..
  "该角色下次摸牌阶段摸牌时，改为从牌堆或弃牌堆中获得你选择的牌。",

  ["#busuan-active"] = "发动 卜算，选择一名其他角色，控制其下个摸牌阶段的摸到的牌的牌名",
  ["#busuan-choose"] = "卜算：选择至多两个卡名，作为%arg下次摸牌阶段摸到的牌",

  ["$busuan1"] = "今日一卦，便知命数。",
  ["$busuan2"] = "喜仰视星辰，夜不肯寐。",
}

local gexuan = General(extension, "gexuan", "wu", 3)
local lianhua = fk.CreateTriggerSkill{
  name = "lianhua",
  anim_type = "special",
  events = {fk.Damaged, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.Damaged then
        return target ~= player and player.phase == Player.NotActive
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damaged then
      local color = "black"
      if table.contains({"lord", "loyalist"}, player.role) and table.contains({"lord", "loyalist"}, target.role) or
        (player.role == target.role) then
        color = "red"
      end
      room:addPlayerMark(player, "lianhua-"..color, 1)
      room:setPlayerMark(player, "@lianhua", player:getMark("lianhua-red") + player:getMark("lianhua-black"))
    elseif event == fk.EventPhaseStart then
      local pattern, skill
      if player:getMark("@lianhua") < 4 then
        pattern, skill = "peach", "ex__yingzi"
      else
        if player:getMark("lianhua-red") > player:getMark("lianhua-black") then
          pattern, skill = "ex_nihilo", "ex__guanxing"
        elseif player:getMark("lianhua-red") < player:getMark("lianhua-black") then
          pattern, skill = "snatch", "ty_ex__zhiyan"
        elseif player:getMark("lianhua-red") == player:getMark("lianhua-black") then
          pattern, skill = "slash", "gongxin"
        end
      end
      local cards = room:getCardsFromPileByRule(pattern)
      if player:getMark("@lianhua") > 3 and player:getMark("lianhua-red") == player:getMark("lianhua-black") then
        table.insertTable(cards, room:getCardsFromPileByRule("duel"))
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
      if not player:hasSkill(skill, true) then
        room:handleAddLoseSkills(player, skill, nil)
        room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
          room:handleAddLoseSkills(player, "-"..skill)
        end)
      end
    end
  end,
}
local lianhua_trigger = fk.CreateTriggerSkill{
  name = "#lianhua_trigger",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@lianhua") > 0 and player.phase == Player.Play
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@lianhua", 0)
    room:setPlayerMark(player, "lianhua-red", 0)
    room:setPlayerMark(player, "lianhua-black", 0)
  end,
}
local zhafu = fk.CreateActiveSkill{
  name = "zhafu",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  prompt = "#zhafu",
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
    room:setPlayerMark(target, "@@zhafu", player.id)
  end,
}
local zhafu_delay = fk.CreateTriggerSkill{
  name = "#zhafu_delay",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and player:getMark("@@zhafu") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = room:getPlayerById(player:getMark("@@zhafu"))
    room:setPlayerMark(player, "@@zhafu", 0)
    if player:getHandcardNum() < 2 or src.dead then return end
    room:doIndicate(src.id, {player.id})
    src:broadcastSkillInvoke("zhafu")
    room:notifySkillInvoked(src, "zhafu", "control")
    local card = room:askForCard(player, 1, 1, false, "zhafu", false, ".|.|.|hand", "#zhafu-invoke:"..src.id)[1]
    local cards = table.filter(player.player_cards[Player.Hand], function(id) return id ~= card end)
    room:obtainCard(src, cards, false, fk.ReasonGive, player.id, "zhafu")
  end,
}
lianhua:addRelatedSkill(lianhua_trigger)
zhafu:addRelatedSkill(zhafu_delay)
gexuan:addSkill(lianhua)
gexuan:addSkill(zhafu)
gexuan:addRelatedSkill("ex__yingzi")
gexuan:addRelatedSkill("ex__guanxing")
gexuan:addRelatedSkill("ty_ex__zhiyan")
gexuan:addRelatedSkill("gongxin")
Fk:loadTranslationTable{
  ["gexuan"] = "葛玄",
  ["#gexuan"] = "太极仙翁",
  ["cv:gexuan"] = "-安志-",
  ["illustrator:gexuan"] = "F.源",
  ["lianhua"] = "炼化",
  [":lianhua"] = "你的回合外，当其他角色受到伤害后，你获得一枚“丹血”标记（阵营与你相同为红色，不同则为黑色，颜色不可见）直到你的出牌阶段开始。<br>"..
  "准备阶段，根据“丹血”标记的数量和颜色，你获得相应的游戏牌，获得相应的技能直到回合结束：<br>"..
  "3枚或以下：【桃】和〖英姿〗；<br>"..
  "超过3枚且红色“丹血”较多：【无中生有】和〖观星〗；<br>"..
  "超过3枚且黑色“丹血”较多：【顺手牵羊】和〖直言〗；<br>"..
  "超过3枚且红色和黑色一样多：【杀】、【决斗】和〖攻心〗。",
  ["zhafu"] = "札符",
  [":zhafu"] = "限定技，出牌阶段，你可以选择一名其他角色。该角色的下个弃牌阶段开始时，其选择保留一张手牌，将其余手牌交给你。",
  ["#zhafu_delay"] = "札符",
  ["@lianhua"] = "丹血",
  ["@@zhafu"] = "札符",
  ["#zhafu"] = "选择一名其他角色：其下个弃牌阶段选择保留一张手牌，其余手牌交给你",
  ["#zhafu-invoke"] = "札符：选择一张保留的手牌，其他手牌全部交给 %src ！",

  ["$lianhua1"] = "白日青山，飞升化仙。",
  ["$lianhua2"] = "草木精炼，万物化丹。",
  ["$zhafu1"] = "垂恩广救，慈悲在怀。",
  ["$zhafu2"] = "行符敕鬼，神变善易。",
  ["$ex__yingzi_gexuan"] = "仙人之姿，凡目岂见！",
  ["$ty_ex__zhiyan_gexuan"] = "仙人之语，凡耳震聩！",
  ["$gongxin_gexuan"] = "仙人之目，因果即现！",
  ["$ex__guanxing_gexuan"] = "仙人之栖，群星浩瀚！",
  ["~gexuan"] = "善变化，拙用身。",
}

local dukui = General(extension, "dukui", "wei", 3)
local fanyin = fk.CreateTriggerSkill{
  name = "fanyin",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x, y = 13, 0
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      y = Fk:getCardById(id).number
      if y < x then
        x = y
        cards = {}
      end
      if x == y then
        table.insert(cards, id)
      end
    end
    if #cards == 0 then return false end
    cards = table.random(cards, 1)
    while true do
      room:moveCards({
        ids = cards,
        toArea = Card.Processing,
        skillName = self.name,
        proposer = player.id,
        moveReason = fk.ReasonJustMove,
      })
      if not room:askForUseRealCard(player, cards, self.name, "#fanyin-ask:::"..Fk:getCardById(cards[1]):toLogString(), {
        expand_pile = cards,
        bypass_distances = true,
      }) then
        room:moveCards({
          ids = cards,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = self.name,
        })
        room:addPlayerMark(player, "@fanyin-turn")
      end
      if player.dead then return end
      x = 2*x
      if x > 13 then return end
      cards = room:getCardsFromPileByRule(".|" .. x)
      if #cards == 0 then return end
    end
  end,
}
local fanyin_delay = fk.CreateTriggerSkill{
  name = "#fanyin_delay",
  events = {fk.AfterCardTargetDeclared},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player == target and player:getMark("@fanyin-turn") > 0 and
    (data.card:isCommonTrick() or data.card.type == Card.TypeBasic)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@fanyin-turn")
    room:setPlayerMark(player, "@fanyin-turn", 0)
    local targets = room:getUseExtraTargets(data)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, x,
    "#fanyin-choose:::"..data.card:toLogString() .. ":" .. tostring(x), fanyin.name, true)
    if #tos > 0 then
      table.forEach(tos, function (id)
        table.insert(data.tos, {id})
      end)
    end
  end,
}
local peiqi = fk.CreateTriggerSkill{
  name = "peiqi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChooseToMoveCardInBoard(player, "#peiqi-choose", self.name, true)
    if #to == 2 and room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), self.name) and
    not player.dead and table.every(room.alive_players, function (p1)
      return table.every(room.alive_players, function (p2)
        return p1 == p2 or p1:inMyAttackRange(p2)
      end)
    end) then
      to = room:askForChooseToMoveCardInBoard(player, "#peiqi-choose", self.name, true)
      if #to == 2 then
        room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), self.name)
      end
    end
  end
}
fanyin:addRelatedSkill(fanyin_delay)
dukui:addSkill(fanyin)
dukui:addSkill(peiqi)

Fk:loadTranslationTable{
  ["dukui"] = "杜夔",
  ["#dukui"] = "律吕调阳",
  ["designer:dukui"] = "七哀",
  ["illustrator:dukui"] = "游漫美绘",
  ["fanyin"] = "泛音",
  [":fanyin"] = "出牌阶段开始时，你可以亮出牌堆中点数最小的一张牌并选择一项：1.使用之（无距离限制）；"..
  "2.令你本回合使用的下一张牌可以多选择一个目标。然后亮出牌堆中点数翻倍的一张牌并重复此流程。",
  ["peiqi"] = "配器",
  [":peiqi"] = "当你受到伤害后，你可以移动场上一张牌。然后若所有角色均在所有角色攻击范围内，你可再移动场上一张牌。",

  ["#fanyin-ask"] = "泛音：使用%arg，或点取消则令你本回合使用的下一张牌可多选目标",
  ["@fanyin-turn"] = "泛音",
  ["#peiqi-choose"] = "配器：你可以移动场上的一张牌",
  ["#fanyin_delay"] = "泛音",
  ["#fanyin-choose"] = "泛音：你可以为%arg额外指定至多%arg2个目标",

  ["$fanyin1"] = "此音可协，此律可振。",
  ["$fanyin2"] = "玄妙殊巧，可谓绝技。",
  ["$peiqi1"] = "声依永，律和声。",
  ["$peiqi2"] = "音律不协，不可用也。",
  ["~dukui"] = "此钟不堪用，再铸！",
}

local zhujianping = General(extension, "zhujianping", "qun", 3)
local xiangmian = fk.CreateActiveSkill{
  name = "xiangmian",
  anim_type = "offensive",
  prompt = "#xiangmian-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
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
    room:setPlayerMark(target, "xiangmian_suit", judge.card:getSuitString(true))
    room:setPlayerMark(target, "xiangmian_num", judge.card.number)
    room:setPlayerMark(target, "@xiangmian", string.format("%s%d", Fk:translate(target:getMark("xiangmian_suit")), target:getMark("xiangmian_num")))
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
    if data.card:getSuitString(true) == target:getMark("xiangmian_suit") or target:getMark("xiangmian_num") == 1 then
      room:setPlayerMark(target, "xiangmian_num", 0)
      room:setPlayerMark(target, "@xiangmian", 0)
      room:loseHp(target, target.hp, "xiangmian")
    else
      room:addPlayerMark(target, "xiangmian_num", -1)
      room:setPlayerMark(target, "@xiangmian", string.format("%s%d",Fk:translate(target:getMark("xiangmian_suit")), target:getMark("xiangmian_num")))
    end
  end,
}
local tianji = fk.CreateTriggerSkill{
  name = "tianji",
  events = {fk.AfterCardsMove},
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local cards = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonJudge and move.skillName == "" then
          table.insertTableIfNeed(cards, table.map(move.moveInfo, function (info)
            return info.cardId
          end))
        end
      end
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local cards = table.simpleClone(self.cost_data)
    for _, id in ipairs(cards) do
      if not player:hasSkill(self) then break end
      self:doCost(event, target, player, {id = id})
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = data.id
    local cards = {}
    local card, card2 = Fk:getCardById(id, true)
    local cardMap = {{}, {}, {}}
    for _, id2 in ipairs(room.draw_pile) do
      card2 = Fk:getCardById(id2, true)
      if card2.type == card.type then
        table.insert(cardMap[1], id2)
      end
      if card2.suit == card.suit then
        table.insert(cardMap[2], id2)
      end
      if card2.number == card.number then
        table.insert(cardMap[3], id2)
      end
    end
    for _ = 1, 3, 1 do
      local x = #cardMap[1] + #cardMap[2] + #cardMap[3]
      if x == 0 then break end
      local index = math.random(x)
      for i = 1, 3, 1 do
        if index > #cardMap[i] then
          index = index - #cardMap[i]
        else
          id = cardMap[i][index]
          table.insert(cards, id)
          cardMap[i] = {}
          for _, v in ipairs(cardMap) do
            table.removeOne(v, id)
          end
          break
        end
      end
    end
    if #cards > 0 then
      room:moveCards{
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      }
    end
  end,
}
xiangmian:addRelatedSkill(xiangmian_record)
zhujianping:addSkill(xiangmian)
zhujianping:addSkill(tianji)
Fk:loadTranslationTable{
  ["zhujianping"] = "朱建平",
  ["#zhujianping"] = "识面知秋",
  ["designer:zhujianping"] = "星移",
  ["illustrator:zhujianping"] = "游漫美绘",

  ["xiangmian"] = "相面",
  [":xiangmian"] = "出牌阶段限一次，你可以令一名其他角色进行一次判定，当该角色使用判定花色的牌或使用第X张牌后（X为判定点数），其失去所有体力。"..
  "每名其他角色限一次。",
  ["tianji"] = "天机",
  [":tianji"] = "锁定技，生效后的判定牌进入弃牌堆后，你从牌堆随机获得与该牌类型、花色和点数相同的牌各一张。",
  ["#xiangmian-active"] = "发动相面，令一名其他角色判定",
  ["@xiangmian"] = "相面",

  ["$xiangmian1"] = "以吾之见，阁下命不久矣。",
  ["$xiangmian2"] = "印堂发黑，将军危在旦夕。",
  ["$tianji1"] = "顺天而行，坐收其利。",
  ["$tianji2"] = "只可意会，不可言传。",
  ["~zhujianping"] = "天机，不可泄露啊……",
}

local wufan = General(extension, "wufan", "wu", 4)
local tianyun = fk.CreateTriggerSkill{
  name = "tianyun",
  events = {fk.GameStart, fk.TurnStart},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.GameStart then
      local suits = {"spade", "heart", "club", "diamond"}
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        table.removeOne(suits, Fk:getCardById(id):getSuitString())
      end
      return #suits > 0
    elseif event == fk.TurnStart then
      return target.seat == player.room:getBanner("RoundCount") and not player:isKongcheng()
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    elseif event == fk.TurnStart then
      return player.room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "heart", "club", "diamond"}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      table.removeOne(suits, Fk:getCardById(id):getSuitString())
    end
    if event == fk.GameStart then
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
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif event == fk.TurnStart then
      local x = 4-#suits
      if x == 0 then return false end
      local result = room:askForGuanxing(player, room:getNCards(x))
      if #result.top == 0 then
        local targets = player.room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper),
        1, 1, "#tianyun-choose:::" .. tostring(x), self.name, true)
        if #targets > 0 then
          room:drawCards(room:getPlayerById(targets[1]), x, self.name)
          if not player.dead then
            room:loseHp(player, 1, self.name)
          end
        end
      end
    end
  end,
}

local yuyan = fk.CreateTriggerSkill{
  name = "yuyan",
  anim_type = "control",
  events = {fk.RoundStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room.alive_players, Util.IdMapper),
    1, 1, "#yuyan-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "yuyan-round", self.cost_data)
  end,
}
local yuyan_delay = fk.CreateTriggerSkill{
  name = "#yuyan_delay",
  anim_type = "control",
  events = {fk.AfterDying, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == nil or player.dead or player:getMark("yuyan-round") ~= target.id then return false end
    local room = player.room
    if event == fk.AfterDying then
      --FIXME:exit_funcs时，无法获取当前事件的信息（迷信规则集不可取……）
      if player:getMark("yuyan_dying_effected-round") > 0 then return false end
      local x = player:getMark("yuyan_dying_record-round")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.Dying, 1, function (e)
          local dying = e.data[1]
          x = dying.who
          room:setPlayerMark(player, "yuyan_dying_record-round", x)
          return true
        end, Player.HistoryRound)
      end
      return target.id == x
    elseif event == fk.Damage then
      local damage_event = room.logic:getCurrentEvent()
      if not damage_event then return false end
      local x = player:getMark("yuyan_damage_record-round")
      if x == 0 then
        room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
          local reason = e.data[3]
          if reason == "damage" then
            local first_damage_event = e:findParent(GameEvent.Damage)
            if first_damage_event then
              x = first_damage_event.id
              room:setPlayerMark(player, "yuyan_damage_record-round", x)
            end
            return true
          end
        end, Player.HistoryRound)
      end
      return damage_event.id == x
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(yuyan.name)
    local room = player.room
    if not target.dead then
      room:addPlayerMark(target, "@@yuyan-round")
    end
    if event == fk.AfterDying then
      room:addPlayerMark(player, "yuyan_dying_effected-round")
      if not player:hasSkill("ty__fenyin", true) then
        room:addPlayerMark(player, "yuyan_tmpfenyin")
        room:handleAddLoseSkills(player, "ty__fenyin", nil, true, false)
      end
    elseif event == fk.Damage then
      player:drawCards(2, yuyan.name)
    end
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target and player:getMark("yuyan_tmpfenyin") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yuyan_tmpfenyin", 0)
    room:handleAddLoseSkills(player, "-ty__fenyin", nil, true, false)
  end,
}

yuyan:addRelatedSkill(yuyan_delay)
wufan:addSkill(tianyun)
wufan:addSkill(yuyan)
wufan:addRelatedSkill("ty__fenyin")

Fk:loadTranslationTable{
  ["wufan"] = "吴范",
  ["#wufan"] = "占星定卜",
  ["illustrator:wufan"] = "胖虎饭票",
  ["tianyun"] = "天运",
  [":tianyun"] = "获得起始手牌后，你再从牌堆中随机获得手牌中没有的花色各一张牌。<br>"..
  "一名角色的回合开始时，若其座次等于游戏轮数，你可以观看牌堆顶的X张牌，然后以任意顺序置于牌堆顶或牌堆底，若你将所有牌均置于牌堆底，"..
  "则你可以令一名角色摸X张牌（X为你手牌中的花色数），若如此做，你失去1点体力。",
  ["yuyan"] = "预言",
  [":yuyan"] = "每轮游戏开始时，你选择一名角色，若其是本轮第一个进入濒死状态的角色，则你获得技能〖奋音〗直到你的回合结束。"..
  "若其是本轮第一个造成伤害的角色，则你摸两张牌。",

  ["#tianyun-choose"] = "天运：你可以令一名角色摸%arg张牌，然后你失去1点体力",
  ["#yuyan-choose"] = "是否发动预言，选择一名角色，若其是本轮第一个进入濒死状态或造成伤害的角色，你获得增益",
  ["#yuyan_delay"] = "预言",
  ["@@yuyan-round"] = "预言",

  ["$tianyun1"] = "天垂象，见吉凶。",
  ["$tianyun2"] = "治历数，知风气。",
  ["$yuyan1"] = "差若毫厘，谬以千里，需慎之。",
  ["$yuyan2"] = "六爻之动，三极之道也。",
  ["$ty__fenyin_wufan1"] = "奋音鼓劲，片甲不留！",
  ["$ty__fenyin_wufan2"] = "奋勇杀敌，声罪致讨！",
  ["~wufan"] = "天运之术今绝矣……",
}

local zhaozhi = General(extension, "zhaozhi", "shu", 3)
local tg_list = {"tg_wuyong","tg_gangying","tg_duomou","tg_guojue","tg_renzhi"}
local tongguan = fk.CreateTriggerSkill{
  name = "tongguan",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target:getMark("tongguan_info") == 0 then
      local events = player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function(e)
        return e.data[1] == target
      end, Player.HistoryGame)
      return #events > 0 and events[1] == player.room.logic:getCurrentEvent()
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local record = room:getTag("tongguan_record") or {2,2,2,2,2}
    local choices = {}
    for i = 1, 5 do
      if record[i] > 0 then
        table.insert(choices, tg_list[i])
      end
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(player, choices, self.name, "#tongguan-choice::"..target.id, true)
    room:setPlayerMark(target, "tongguan_info", choice)
    local i = table.indexOf(tg_list, choice)
    record[i] = record[i] - 1
    room:setTag("tongguan_record", record)
    U.setPrivateMark(target, ":tongguan", {choice}, {player.id})
  end,
}
local mengjiez = fk.CreateTriggerSkill{
  name = "mengjiez",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    local mark = target:getMark("tongguan_info")
    local room = player.room
    if player:hasSkill(self) and mark ~= 0 then
      if mark == "tg_wuyong" then
        return #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == target end) > 0
      elseif mark == "tg_gangying" then
        if target:getHandcardNum() > target.hp then return true end
        local _event = room.logic:getEventsOfScope(GameEvent.Recover, 1, function(e)
          return e.data[1].who == target
        end, Player.HistoryTurn)
        return #_event > 0
      elseif mark == "tg_duomou" then
        local phase_ids = {}
        room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
          if e.data[2] == Player.Draw then
            table.insert(phase_ids, {e.id, e.end_id})
          end
          return false
        end, Player.HistoryTurn)
        local _event = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
          local in_draw = false
          for _, ids in ipairs(phase_ids) do
            if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
              in_draw = true
              break
            end
          end
          if not in_draw then
            for _, move in ipairs(e.data) do
              if move.to == target.id and move.moveReason == fk.ReasonDraw then
                return true
              end
            end
          end
          return false
        end, Player.HistoryTurn)
        return #_event > 0
      elseif mark == "tg_guojue" then
        local _event = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
          for _, move in ipairs(e.data) do
            if move.from ~= target.id and move.proposer == target.id
            and (move.moveReason == fk.ReasonDiscard or move.moveReason == fk.ReasonPrey)
            and table.find(move.moveInfo, function(info)
              return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
            end)
            then
              return true
            end
          end
          return false
        end, Player.HistoryTurn)
        return #_event > 0
      elseif mark == "tg_renzhi" then
        local _event = room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
          for _, move in ipairs(e.data) do
            if (move.from == target.id or move.proposer == target.id) and move.to and move.to ~= move.from and move.moveReason == fk.ReasonGive then
              return true
            end
          end
          return false
        end, Player.HistoryTurn)
        return #_event > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = target:getMark("tongguan_info")
    if mark == "tg_duomou" then
      player:drawCards(2, self.name)
    else
      local targets = room:getOtherPlayers(player)
      local prompt = "#mengjiez1-invoke"
      if mark == "tg_gangying" then
        targets = room:getAlivePlayers()
        prompt = "#mengjiez2-invoke"
      elseif mark == "tg_guojue"  then
        prompt = "#mengjiez4-invoke"
      elseif mark == "tg_renzhi" then
        prompt = "#mengjiez5-invoke"
      end
      if #targets == 0 then return false end
      local to = room:getPlayerById(room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, prompt, self.name, false)[1])
      if mark == "tg_wuyong" then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = self.name,
        }
      elseif mark == "tg_gangying" then
        if to:isWounded() then
          room:recover({
            who = to,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      elseif mark == "tg_guojue" then
        if not to:isAllNude() then
          local cards = room:askForCardsChosen(player, to, 1, 2, "hej", self.name)
          room:throwCard(cards, self.name, to, player)
        end
      elseif mark == "tg_renzhi" then
        if to:getHandcardNum() < to.maxHp then
          to:drawCards(math.min(5, to.maxHp - to:getHandcardNum()), self.name)
        end
      end
    end
    U.showPrivateMark(target, ":tongguan")
  end,
}
zhaozhi:addSkill(tongguan)
zhaozhi:addSkill(mengjiez)
Fk:loadTranslationTable{
  ["zhaozhi"] = "赵直",
  ["#zhaozhi"] = "捕梦黄粱",
  ["designer:zhaozhi"] = "韩旭",
  ["illustrator:zhaozhi"] = "匠人绘",
  ["tongguan"] = "统观",
  [":tongguan"] = "一名角色的第一个回合开始时，你为其选择一项属性（每种属性至多被选择两次）。",
  ["mengjiez"] = "梦解",
  [":mengjiez"] = "一名角色的回合结束时，若其本回合完成了其属性对应内容，你执行对应效果。<br>"..
  "武勇：造成伤害；对一名其他角色造成1点伤害<br>"..
  "刚硬：回复体力或手牌数大于体力值；令一名角色回复1点体力<br>"..
  "多谋：摸牌阶段外摸牌；摸两张牌<br>"..
  "果决：弃置或获得其他角色的牌；弃置一名其他角色区域内的至多两张牌<br>"..
  "仁智：交给其他角色牌；令一名其他角色将手牌摸至体力上限（至多摸五张）",
  ["#tongguan-choice"] = "统观：为 %dest 选择一项属性（每种属性至多被选择两次）",
  ["@[private]:tongguan"] = "统观",
  ["tg_wuyong"] = "武勇",
  [":tg_wuyong"] = "回合结束时，若其本回合造成过伤害，你对一名其他角色造成1点伤害",
  ["tg_gangying"] = "刚硬",
  [":tg_gangying"] = "回合结束时，若其手牌数大于体力值，或其本回合回复过体力，你令一名角色回复1点体力",
  ["tg_duomou"] = "多谋",
  [":tg_duomou"] = "回合结束时，若其本回合摸牌阶段外摸过牌，你摸两张牌",
  ["tg_guojue"] = "果决",
  [":tg_guojue"] = "回合结束时，若其本回合弃置或获得过其他角色的牌，你弃置一名其他角色区域内的至多两张牌",
  ["tg_renzhi"] = "仁智",
  [":tg_renzhi"] = "回合结束时，若其本回合交给其他角色牌，你令一名其他角色将手牌摸至体力上限（至多摸五张）",
  ["#mengjiez1-invoke"] = "梦解：对一名其他角色造成1点伤害",
  ["#mengjiez2-invoke"] = "梦解：令一名角色回复1点体力",
  ["#mengjiez4-invoke"] = "梦解：弃置一名其他角色区域内至多两张牌",
  ["#mengjiez5-invoke"] = "梦解：令一名其他角色将手牌摸至体力上限（至多摸五张）",

  ["$tongguan1"] = "极目宇宙，可观如织之命数。",
  ["$tongguan2"] = "命河长往，唯我立于川上。",
  ["$mengjiez1"] = "唇舌之语，难言虚实之境。",
  ["$mengjiez2"] = "解梦之术，如镜中观花尔。",
  ["~zhaozhi"] = "解人之梦者，犹在己梦中。",
}

local zhouxuan = General(extension, "zhouxuan", "wei", 3)
local wumei = fk.CreateTriggerSkill{
  name = "wumei",
  anim_type = "support",
  events = {fk.BeforeTurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function (p)
      return p:getMark("@@wumei_extra") == 0 end), Util.IdMapper), 1, 1, "#wumei-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "@@wumei_extra", 1)
    local hp_record = {}
    for _, p in ipairs(room.alive_players) do
      table.insert(hp_record, {p.id, p.hp})
    end
    room:setPlayerMark(to, "wumei_record", hp_record)
    to:gainAnExtraTurn()
  end,

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@wumei_extra") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@wumei_extra", 0)
    room:setPlayerMark(player, "wumei_record", 0)
  end,
}
local wumei_delay = fk.CreateTriggerSkill{
  name = "#wumei_delay",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Finish and player:getMark("@@wumei_extra") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, wumei.name, "special")
    local hp_record = player:getMark("wumei_record")
    if type(hp_record) ~= "table" then return false end
    for _, p in ipairs(room:getAlivePlayers()) do
      local p_record = table.find(hp_record, function (sub_record)
        return #sub_record == 2 and sub_record[1] == p.id
      end)
      if p_record then
        p.hp = math.min(p.maxHp, p_record[2])
        room:broadcastProperty(p, "hp")
      end
    end
  end,
}
local zhanmeng = fk.CreateTriggerSkill{
  name = "zhanmeng",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      local room = player.room
      local mark = player:getMark("zhanmeng_last-turn")
      if type(mark) ~= "table" then
        mark = {}
        local logic = room.logic
        local current_event = logic:getCurrentEvent()
        local all_turn_events = logic.event_recorder[GameEvent.Turn]
        if type(all_turn_events) == "table" then
          local index = #all_turn_events
          if index > 0 then
            local turn_event = current_event:findParent(GameEvent.Turn)
            if turn_event ~= nil then
              index = index - 1
            end
            if index > 0 then
              current_event = all_turn_events[index]
              current_event:searchEvents(GameEvent.UseCard, 1, function (e)
                table.insertIfNeed(mark, e.data[1].card.trueName)
                return false
              end)
            end
          end
        end
        room:setPlayerMark(player, "zhanmeng_last-turn", mark)
      end
      return (player:getMark("zhanmeng1-turn") == 0 and not table.contains(mark, data.card.trueName)) or
        player:getMark("zhanmeng2-turn") == 0 or (player:getMark("zhanmeng3-turn") == 0 and
        not table.every(room.alive_players, function (p)
          return p == player or p:isNude()
        end))
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("zhanmeng_last-turn")
    local choices = {}
    self.cost_data = {}
    if player:getMark("zhanmeng1-turn") == 0 and not table.contains(mark, data.card.trueName) then
      table.insert(choices, "zhanmeng1")
    end
    if player:getMark("zhanmeng2-turn") == 0 then
      table.insert(choices, "zhanmeng2")
    end
    local targets = {}
    if player:getMark("zhanmeng3-turn") == 0 then
      for _, p in ipairs(room.alive_players) do
        if p ~= player and not p:isNude() then
          table.insertIfNeed(choices, "zhanmeng3")
          table.insert(targets, p.id)
        end
      end
    end
    table.insert(choices, "Cancel")
    local choice = room:askForChoice(player, choices, self.name, "#zhanmeng-choice", false,
    {"zhanmeng1", "zhanmeng2", "zhanmeng3", "Cancel"})
    if choice == "Cancel" then return false end
    self.cost_data[1] = choice
    if choice == "zhanmeng3" then
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhanmeng-choose", self.name, true)
      if #to > 0 then
        self.cost_data[2] = to[1]
      else
        return false
      end
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data[1]
    room:setPlayerMark(player, choice.."-turn", 1)
    if choice == "zhanmeng1" then
      local cards = {}
      for _, id in ipairs(room.draw_pile) do
        if not Fk:getCardById(id).is_damage_card then
          table.insertIfNeed(cards, id)
        end
      end
      if #cards > 0 then
        local card = table.random(cards)
        room:moveCards({
          ids = {card},
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif choice == "zhanmeng2" then
      room:setPlayerMark(player, "zhanmeng_delay-turn", data.card.trueName)
    elseif choice == "zhanmeng3" then
      local p = room:getPlayerById(self.cost_data[2])
      local cards = room:askForDiscard(p, 2, 2, true, self.name, false, ".", "#zhanmeng-discard:"..player.id)
      local x = Fk:getCardById(cards[1]).number
      if #cards == 2 then
        x = x + Fk:getCardById(cards[2]).number
      end
      if x > 10 and not p.dead then
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

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhanmeng_delay", player:getMark("zhanmeng_delay-turn"))
  end,
}
local zhanmeng_delay = fk.CreateTriggerSkill{
  name = "#zhanmeng_delay",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(self.name) == 0 and player:getMark("@zhanmeng_delay") == data.card.trueName
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id).is_damage_card then
        table.insertIfNeed(cards, id)
      end
    end
    if #cards > 0 then
      local card = table.random(cards)
      room:moveCards({
        ids = {card},
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
wumei:addRelatedSkill(wumei_delay)
zhanmeng:addRelatedSkill(zhanmeng_delay)
zhouxuan:addSkill(wumei)
zhouxuan:addSkill(zhanmeng)
Fk:loadTranslationTable{
  ["zhouxuan"] = "周宣",
  ["#zhouxuan"] = "夜华青乌",
  ["designer:zhouxuan"] = "世外高v狼",
  ["cv:zhouxuan"] = "虞晓旭",
  ["illustrator:zhouxuan"] = "匠人绘",

  ["wumei"] = "寤寐",
  [":wumei"] = "每轮限一次，回合开始前，你可以令一名角色执行一个额外的回合：该回合结束时，将所有存活角色的体力值调整为此额外回合开始时的数值。",
  ["zhanmeng"] = "占梦",
  [":zhanmeng"] = "你使用牌时，可以执行以下一项（每回合每项各限一次）：<br>"..
  "1.上一回合内，若没有同名牌被使用，你获得一张非伤害牌。<br>"..
  "2.下一回合内，当同名牌首次被使用后，你获得一张伤害牌。<br>"..
  "3.令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害。",
  ["#wumei-choose"] = "寤寐: 你可以令一名角色执行一个额外的回合",
  ["#wumei_delay"] = "寤寐",
  ["@@wumei_extra"] = "寤寐",
  ["zhanmeng1"] = "你获得一张非伤害牌",
  ["zhanmeng2"] = "下一回合内，当同名牌首次被使用后，你获得一张伤害牌",
  ["zhanmeng3"] = "令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng_delay"] = "占梦",
  ["@zhanmeng_delay"] = "占梦",
  ["#zhanmeng-choice"] = "是否发动 占梦，选择一项效果",
  ["#zhanmeng-choose"] = "占梦: 令一名其他角色弃置两张牌，若点数之和大于10，对其造成1点火焰伤害",
  ["#zhanmeng-discard"] = "占梦：弃置2张牌，若点数之和大于10，%src 对你造成1点火焰伤害",

  ["$wumei1"] = "大梦若期，皆付一枕黄粱。",
  ["$wumei2"] = "日所思之，故夜所梦之。",
  ["$zhanmeng1"] = "梦境缥缈，然有迹可占。",
  ["$zhanmeng2"] = "万物有兆，唯梦可卜。",
  ["~zhouxuan"] = "人生如梦，假时亦真。",
}

local zerong = General(extension, "zerong", "qun", 4)
local cansi = fk.CreateTriggerSkill{
  name = "cansi",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
      if player.dead then return false end
    end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#cansi-choose", self.name, false)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    if to:isWounded() then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    for _, card_name in ipairs({"slash", "duel", "fire_attack"}) do
      if player.dead or to.dead then break end
      local card = Fk:cloneCard(card_name)
      card.skillName = self.name
      if player:canUseTo(card, to, { bypass_times = true, bypass_distances = true }) then
        room:useCard({
          from = player.id,
          tos = {{to.id}},
          card = card,
          extraUse = true,
          extra_data = {cansi_source = player.id, cansi_target = to.id}
        })
      end
    end
  end,
}
local cansi_draw = fk.CreateTriggerSkill{
  name = "#cansi_draw",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.Damaged},
  main_skill = cansi,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(cansi) or not data.card then return false end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event then
      local use = use_event.data[1]
      return use.card == data.card and use.extra_data and
      use.extra_data.cansi_source == player.id and use.extra_data.cansi_target == target.id
    end
  end,
  on_trigger = function(self, event, target, player, data)
    for i = 1, data.damage do
      if not player:hasSkill(cansi) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(cansi.name)
    player:drawCards(2, cansi.name)
  end,
}
local fozong = fk.CreateTriggerSkill{
  name = "fozong",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and player:getHandcardNum() > 7
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum() - 7
    room:moveCardTo(room:askForCard(player, n, n, false, self.name, false, ".", "#fozong-card:::"..n),
    Card.PlayerSpecial, player, fk.ReasonJustMove, self.name, self.name, true)
    if #player:getPile(self.name) < 7 then return false end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then break end
      if not p.dead then
        local to_return = U.askforChooseCardsAndChoice(p, player:getPile(self.name), {"fozong_get"}, self.name,
        "#fozong-choice:"..player.id, {"fozong_lose"})
        if #to_return > 0 then
          room:obtainCard(p, to_return[1], true, fk.ReasonPrey)
          if player.dead then break end
          room:recover({
            who = player,
            num = 1,
            recoverBy = p,
            skillName = self.name
          })
        else
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
cansi:addRelatedSkill(cansi_draw)
zerong:addSkill(cansi)
zerong:addSkill(fozong)

Fk:loadTranslationTable{
  ["zerong"] = "笮融",
  ["#zerong"] = "刺血济饥",
  ["designer:zerong"] = "步穗",
  ["illustrator:zerong"] = "君桓文化",
  ["cansi"] = "残肆",
  [":cansi"] = "锁定技，准备阶段，你选择一名其他角色，你与其各回复1点体力，然后依次视为对其使用【杀】、【决斗】和【火攻】，其每因此受到1点伤害，你摸两张牌。",
  ["fozong"] = "佛宗",
  [":fozong"] = "锁定技，出牌阶段开始时，若你的手牌多于七张，你将超出数量的手牌置于武将牌上，然后若你武将牌上有至少七张牌，"..
  "其他角色依次选择一项：1.获得其中一张牌并令你回复1点体力；2.令你失去1点体力。",

  ["#cansi-choose"] = "残肆：选择一名角色，令其回复1点体力，然后依次视为对其使用【杀】、【决斗】和【火攻】",
  ["#cansi_draw"] = "残肆",
  ["#fozong-card"] = "佛宗：将 %arg 张手牌置于武将牌上",
  ["#fozong-choice"] = "佛宗：选择令 %src 执行的一项",
  ["fozong_get"] = "获得此牌并令其回复体力",
  ["fozong_lose"] = "令其失去体力",

  ["$cansi1"] = "君不入地狱，谁入地狱？",
  ["$cansi2"] = "众生皆苦，唯渡众生于极乐。",
  ["$fozong1"] = "此身无长物，愿奉骨肉为浮屠。",
  ["$fozong2"] = "驱大白牛车，颂无上功德。",
  ["~zerong"] = "此劫，不可避……",
}

--计将安出：程昱 王允 蒋干 刘琦 赵昂 刘晔 杨弘 桓范 郤正 田丰 吕范
local ty__chengyu = General(extension, "ty__chengyu", "wei", 3)
Fk:addQmlMark{
  name = "ty__shefu",
  how_to_show = function(name, value, p)
    if type(value) ~= "table" then return " " end
    return tostring(#value)
  end,
  qml_path = function(name, value, p)
    if Self:isBuddy(p) then
      return "packages/tenyear/qml/ZixiBox"
    end
    return ""
  end,
}
local ty__shefu_active = fk.CreateActiveSkill{
  name = "ty__shefu_active",
  card_num = 1,
  target_num = 0,
  interaction = function(self)
    local mark = Self:getTableMark("@[ty__shefu]")
    local all_names = U.getAllCardNames("btd", true)
    local names = table.filter(all_names, function(name)
      return table.every(mark, function(shefu_pair)
        return shefu_pair[2] ~= name
      end)
    end)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  can_use = Util.FalseFunc,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and self.interaction.data
  end,
}
Fk:addSkill(ty__shefu_active)
local ty__shefu = fk.CreateTriggerSkill{
  name = "ty__shefu",
  anim_type = "control",
  derived_piles = "#ty__shefu_ambush",
  events ={fk.EventPhaseStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish and not player:isNude()
      else
        return target ~= player and player.phase == Player.NotActive and
        table.find(player:getTableMark("@[ty__shefu]"), function (shefu_pair)
          return shefu_pair[2] == data.card.trueName
        end)
         and U.IsUsingHandcard(target, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local success, dat = room:askForUseActiveSkill(player, "ty__shefu_active", "#ty__shefu-cost", true)
      if success then
        self.cost_data = dat
        return true
      end
    else
      if room:askForSkillInvoke(player, self.name, nil, "#ty__shefu-invoke::"..target.id..":"..data.card:toLogString()) then
        room:doIndicate(player.id, {target.id})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local cid = self.cost_data.cards[1]
      local name = self.cost_data.interaction
      player:addToPile("#ty__shefu_ambush", cid, true, self.name)
      if table.contains(player:getPile("#ty__shefu_ambush"), cid) then
        local mark = player:getTableMark("@[ty__shefu]")
        table.insert(mark, {cid, name})
        room:setPlayerMark(player, "@[ty__shefu]", mark)
      end
    else
      local mark = player:getTableMark("@[ty__shefu]")
      for i = 1, #mark, 1 do
        if mark[i][2] == data.card.trueName then
          local cid = mark[i][1]
          table.remove(mark, i)
          room:setPlayerMark(player, "@[ty__shefu]", #mark > 0 and mark or 0)
          if table.contains(player:getPile("#ty__shefu_ambush"), cid) then
            room:moveCardTo(cid, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
          end
          break
        end
      end
      data.tos = {}
      room:sendLog{ type = "#CardNullifiedBySkill", from = target.id, arg = self.name, arg2 = data.card:toLogString() }
      if not target.dead and target.phase ~= Player.NotActive then
        room:setPlayerMark(target, "@@ty__shefu-turn", 1)
      end
    end
  end,

  refresh_events = {fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return player == target and data == self and player:getMark("@[ty__shefu]") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[ty__shefu]", 0)
  end,
}
local ty__shefu_invalidity = fk.CreateInvaliditySkill {
  name = "#ty__shefu_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@ty__shefu-turn") > 0 and skill:isPlayerSkill(from)
  end
}
ty__shefu:addRelatedSkill(ty__shefu_invalidity)
ty__chengyu:addSkill(ty__shefu)
local ty__benyu = fk.CreateTriggerSkill{
  name = "ty__benyu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not data.from.dead
    and (player:getHandcardNum() < math.min(data.from:getHandcardNum(), 5) or #player:getCardIds("he") > data.from:getHandcardNum())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "ty__benyu_active", nil, true,
    {ty__benyu_data = {data.from.id, data.from:getHandcardNum()}})
    if success and dat then
      room:doIndicate(player.id, {data.from.id})
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data.interaction == "ty__benyu_damage" then
      player.room:throwCard(self.cost_data.cards, self.name, player, player)
      player.room:damage{
        from = player,
        to = data.from,
        damage = 1,
        skillName = self.name,
      }
    else
      player:drawCards(math.min(5, data.from:getHandcardNum()) - player:getHandcardNum())
    end
  end,
}
ty__chengyu:addSkill(ty__benyu)
local ty__benyu_active = fk.CreateActiveSkill{
  name = "ty__benyu_active",
  prompt = function (self)
    local to = self.ty__benyu_data[1]
    local x = self.ty__benyu_data[2]
    if self.interaction.data == "ty__benyu_damage" then
      return "#ty__benyu-discard::"..to..":"..(x+1)
    else
      return "#ty__benyu-draw:::"..math.min(5, x)
    end
  end,
  interaction = function(self)
    local all_choices = {"ty__benyu_draw", "ty__benyu_damage"}
    local choices = {}
    if Self:getHandcardNum() < math.min(self.ty__benyu_data[2], 5) then
      table.insert(choices, all_choices[1])
    end
    if #Self:getCardIds("he") > self.ty__benyu_data[2] then
      table.insert(choices, all_choices[2])
    end
    if #choices > 0 then
      return UI.ComboBox { choices = choices, all_choices = all_choices }
    end
  end,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    return self.interaction.data == "ty__benyu_damage" and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  feasible = function(self, selected, selected_cards)
    if self.interaction.data == "ty__benyu_damage" then
      return #selected_cards > self.ty__benyu_data[2]
    end
    return #selected_cards == 0
  end,
}
Fk:addSkill(ty__benyu_active)
Fk:loadTranslationTable{
  ["ty__chengyu"] = "程昱",
  ["#ty__chengyu"] = "泰山捧日",
  ["illustrator:ty__chengyu"] = "凝聚永恒",

  ["ty__shefu"] = "设伏",
  [":ty__shefu"] = "①结束阶段，你可以记录一个未被记录的基本牌或锦囊牌的牌名并扣置一张牌，称为“伏兵”；<br>"..
  "②当其他角色于你回合外使用手牌时，你可以移去一张记录牌名相同的“伏兵”，令此牌无效（若此牌有目标角色则改为取消所有目标），然后若此时是该角色的回合内，其本回合所有技能失效。",
  ["ty__benyu"] = "贲育",
  [":ty__benyu"] = "当你受到伤害后，你可以选择一项：1.将手牌摸至X张（最多摸至5张）；2.弃置至少X+1张牌，然后对伤害来源造成1点伤害（X为伤害来源的手牌数）。",

  ["ty__shefu_active"] = "设伏",
  ["#ty__shefu-cost"] = "设伏：你可以将一张牌扣置为“伏兵”",
  ["@[ty__shefu]"] = "伏兵",
  ["@@ty__shefu-turn"] = "设伏封技",
  ["#ty__shefu-invoke"] = "设伏：可以令 %dest 使用的 %arg 无效",
  ["#CardNullifiedBySkill"] = "由于 %arg 的效果，%from 使用的 %arg2 无效",
  ["ty__benyu_active"] = "贲育",
  ["#ty__benyu-discard"] = "贲育：你可以弃置至少%arg牌，对 %dest 造成1点伤害",
  ["#ty__benyu-draw"] = "贲育：你可以摸至 %arg 张牌",
  ["ty__benyu_draw"] = "摸牌",
  ["ty__benyu_damage"] = "弃牌并造成伤害",
  ["#ty__shefu_ambush"] = "设伏",

  ["$ty__shefu1"] = "吾已埋下伏兵，敌兵一来，管教他瓮中捉鳖。",
  ["$ty__shefu2"] = "我已设下重重圈套，就等敌军入彀矣。",
  ["$ty__benyu1"] = "助曹公者昌，逆曹公者亡！",
  ["$ty__benyu2"] = "愚民不可共济大事，必当与智者为伍。",
  ["~ty__chengyu"] = "吾命休矣，何以仰报圣恩于万一……",
}

local wangyun = General(extension, "ty__wangyun", "qun", 4)
local ty__lianji = fk.CreateActiveSkill{
  name = "ty__lianji",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt= "#ty__lianji",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local cards = {}
    for i = 1, #room.draw_pile, 1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if card.sub_type == Card.SubtypeWeapon then
        table.insertIfNeed(cards, room.draw_pile[i])
      end
    end
    if #cards > 0 then
      local card = Fk:getCardById(table.random(cards))
      if card.name == "qinggang_sword" then
        for _, id in ipairs(Fk:getAllCardIds()) do
          if Fk:getCardById(id).name == "seven_stars_sword" then
            card = Fk:getCardById(id)
            room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
            break
          end
        end
      end
      if not target:isProhibited(target, card) then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = card,
        })
      end
    end
    if target.dead then return end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local use = room:askForUseCard(target, "slash", "slash", "#ty__lianji-slash:"..player.id, true, {exclusive_targets = targets})
    if use then
      room:setPlayerMark(player, "ty__lianji1", 1)
      use.extraUse = true
      room:useCard(use)
      if not target.dead and target:getEquipment(Card.SubtypeWeapon) then
        local to = table.filter(TargetGroup:getRealTargets(use.tos), function(id) return not room:getPlayerById(id).dead end)
        if #to == 0 then return end
        if #to > 1 then
          to = room:askForChoosePlayers(target, to, 1, 1, "#ty__lianji-give", self.name, false)
        end
        to = room:getPlayerById(to[1])
        room:moveCardTo(Fk:getCardById(target:getEquipment(Card.SubtypeWeapon)),
          Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, target.id)
      end
    else
      room:setPlayerMark(player, "ty__lianji2", 1)
      room:useVirtualCard("slash", nil, player, target, self.name, true)
      if not player.dead and not target.dead and target:getEquipment(Card.SubtypeWeapon) then
        room:moveCardTo(Fk:getCardById(target:getEquipment(Card.SubtypeWeapon)),
          Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, target.id)
      end
    end
  end,
}
local ty__moucheng = fk.CreateTriggerSkill{
  name = "ty__moucheng",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("ty__lianji1") > 0 and player:getMark("ty__lianji2") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-ty__lianji|jingong", nil, true, false)
  end,
}
wangyun:addSkill(ty__lianji)
wangyun:addSkill(ty__moucheng)
wangyun:addRelatedSkill("jingong")
Fk:loadTranslationTable{
  ["ty__wangyun"] = "王允",
  ["#ty__wangyun"] = "忠魂不泯",
  ["illustrator:ty__wangyun"] = "Thinking",
  ["ty__lianji"] = "连计",
  [":ty__lianji"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名其他角色，令其使用牌堆中的一张武器牌。然后该角色选择一项：1.对除你以外的一名角色"..
  "使用一张【杀】，并将武器牌交给其中一名目标角色；2.视为你对其使用一张【杀】，并将武器牌交给你。",
  ["ty__moucheng"] = "谋逞",
  [":ty__moucheng"] = "觉醒技，准备阶段，若你发动〖连计〗的两个选项都被选择过，则你失去〖连计〗，获得〖矜功〗。",
  ["#ty__lianji"] = "连计：弃置一张手牌，令一名角色使用牌堆中的一张武器牌并使用【杀】",
  ["#ty__lianji-slash"] = "连计：你需使用一张【杀】，否则 %src 视为对你使用【杀】",
  ["#ty__lianji-give"] = "连计：你需将武器交给其中一名目标角色",

  ["$ty__lianji1"] = "连环相扣，周密不失。",
  ["$ty__lianji2"] = "切记，此计连不可断。",
  ["$ty__moucheng1"] = "除贼安国，利于天下。",
  ["$ty__moucheng2"] = "董贼已擒，长安可兴。",
  ["$jingong_ty__wangyun1"] = "得民称赞，此功当邀。",
  ["$jingong_ty__wangyun2"] = "吾能擒董贼，又何惧怕？",
  ["~ty__wangyun"] = "奉先，你居然弃我而逃！",
}

local jianggan = General(extension, "jianggan", "wei", 3)
local weicheng = fk.CreateTriggerSkill{
  name = "weicheng",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or player:getHandcardNum() >= player.hp then return false end
    for _, move in ipairs(data) do
      if move.from and move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local daoshu = fk.CreateActiveSkill{
  name = "daoshu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local choice = room:askForChoice(player, suits, self.name)
    room:sendLog{
      type = "#DaoshuLog",
      from = player.id,
      to = effect.tos,
      arg = choice,
      arg2 = self.name,
      toast = true,
    }
    local card = room:askForCardChosen(player, target, "h", self.name)
    room:obtainCard(player, card, true, fk.ReasonPrey)
    if Fk:getCardById(card):getSuitString(true) == choice then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      player:addSkillUseHistory(self.name, -1)
    else
      local suit = Fk:getCardById(card):getSuitString(true)
      table.removeOne(suits, suit)
      suits = table.map(suits, function(s) return s:sub(5) end)
      local others = table.filter(player:getCardIds(Player.Hand), function(id) return Fk:getCardById(id):getSuitString(true) ~= suit end)
      if #others > 0 then
        local cards = room:askForCard(player, 1, 1, false, self.name, false, ".|.|"..table.concat(suits, ","),
          "#daoshu-give::"..target.id..":"..suit)
        if #cards > 0 then
          cards = cards[1]
        else
          cards = table.random(others)
        end
        room:obtainCard(target, cards, true, fk.ReasonGive)
      else
        player:showCards(player:getCardIds(Player.Hand))
      end
    end
  end,
}
jianggan:addSkill(weicheng)
jianggan:addSkill(daoshu)
Fk:loadTranslationTable{
  ["jianggan"] = "蒋干",
  ["#jianggan"] = "锋谪悬信",
  ["designer:jianggan"] = "韩旭",
  ["illustrator:jianggan"] = "biou09",
  ["weicheng"] = "伪诚",
  [":weicheng"] = "你交给其他角色手牌，或你的手牌被其他角色获得后，若你的手牌数小于体力值，你可以摸一张牌。",
  ["daoshu"] = "盗书",
  [":daoshu"] = "出牌阶段限一次，你可以选择一名其他角色并选择一种花色，然后获得其一张手牌。若此牌与你选择的花色："..
  "相同，你对其造成1点伤害且此技能视为未发动过；不同，你交给其一张其他花色的手牌（若没有需展示所有手牌）。",
  ["#DaoshuLog"] = "%from 对 %to 发动了 “%arg2”，选择了 %arg",
  ["#daoshu-give"] = "盗书：交给 %dest 一张非%arg手牌",

  ["$weicheng1"] = "略施谋略，敌军便信以为真。",
  ["$weicheng2"] = "吾只观雅规，而非说客。",
  ["$daoshu1"] = "得此文书，丞相定可高枕无忧。",
  ["$daoshu2"] = "让我看看，这是什么机密。",
  ["~jianggan"] = "丞相，再给我一次机会啊！",
}

local ty__liuqi = General(extension, "ty__liuqi", "qun", 3)
ty__liuqi.subkingdom = "shu"
local ty__wenji = fk.CreateTriggerSkill{
  name = "ty__wenji",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
    table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), Util.IdMapper), 1, 1, "#ty__wenji-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#ty__wenji-give::"..player.id)
    room:addTableMarkIfNeed(player, "@ty__wenji-turn", Fk:getCardById(card[1]):getTypeString().."_char")
    room:obtainCard(player, card[1], false, fk.ReasonGive, to.id)
  end,
}
local ty__wenji_record = fk.CreateTriggerSkill{
  name = "#ty__wenji_record",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local mark = player:getTableMark("@ty__wenji-turn")
      return table.contains(mark, data.card:getTypeString().."_char")
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
}
local ty__tunjiang = fk.CreateTriggerSkill{
  name = "ty__tunjiang",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data[2] == Player.Play and e.end_id then
          table.insert(play_ids, {e.id, e.end_id})
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return true end
      local used = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        if in_play then
          local use = e.data[1]
          if use.from == target.id and use.tos then
            if table.find(TargetGroup:getRealTargets(use.tos), function(pid) return pid ~= target.id end) then
              return true
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      return #used == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local kingdoms = {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms)
  end,
}
ty__wenji:addRelatedSkill(ty__wenji_record)
ty__liuqi:addSkill(ty__wenji)
ty__liuqi:addSkill(ty__tunjiang)
Fk:loadTranslationTable{
  ["ty__liuqi"] = "刘琦",
  ["#ty__liuqi"] = "居外而安",
  ["illustrator:ty__liuqi"] = "黑羽",
  ["ty__wenji"] = "问计",
  [":ty__wenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌，你于本回合内使用与该牌类别相同的牌不能被其他角色响应。",
  ["ty__tunjiang"] = "屯江",
  [":ty__tunjiang"] = "结束阶段，若你于本回合出牌阶段内未使用牌指定过其他角色为目标，则你可以摸X张牌（X为全场势力数）。",
  ["#ty__wenji-choose"] = "问计：你可以令一名其他角色交给你一张牌",
  ["#ty__wenji-give"] = "问计：你需交给 %dest 一张牌",
  ["@ty__wenji-turn"] = "问计",

  ["$ty__wenji1"] = "琦，愿听先生教诲。",
  ["$ty__wenji2"] = "先生，此计可有破解之法？",
  ["$ty__tunjiang1"] = "这浑水，不蹚也罢。",
  ["$ty__tunjiang2"] = "荆州风云波澜动，唯守江夏避险峻。",
  ["~ty__liuqi"] = "这荆州，终究容不下我。",
}

local zhaoang = General(extension, "zhaoang", "wei", 3, 4)
local zhongjie = fk.CreateTriggerSkill{
  name = "zhongjie",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
    not data.damage and not target.dead and target.hp < 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data, "#zhongjie-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = target,
      num = 1,
      recoverBy = player,
      skillName = self.name
    }
    if not target.dead then
      target:drawCards(1, self.name)
    end
  end,
}
local sushou = fk.CreateTriggerSkill{
  name = "sushou",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and player.hp > 0 and not target.dead and
    table.every(player.room.alive_players, function (p)
      return p == target or p:getHandcardNum() < target:getHandcardNum()
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data, "#sushou-invoke::"..target.id) then
      room:doIndicate(player.id, {target.id})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if player.dead then return false end
    local x = player:getLostHp()
    if x > 0 then
      room:drawCards(player, x, self.name)
    end
    if player == target then return false end
    local cards = target:getCardIds(Player.Hand)
    if #cards < 2 then return false end
    cards = table.random(cards, #cards // 2)
    local handcards = player:getCardIds(Player.Hand)
    cards = U.askForExchange(player, "needhand", "wordhand", cards, handcards, "#sushou-exchange::"..target.id .. ":" .. tostring(x), x)
    if #cards == 0 then return false end
    handcards = table.filter(cards, function (id)
      return table.contains(handcards, id)
    end)
    cards = table.filter(cards, function (id)
      return not table.contains(handcards, id)
    end)
    U.swapCards(room, player, player, target, handcards, cards, self.name)
  end,
}

zhaoang:addSkill(zhongjie)
zhaoang:addSkill(sushou)

Fk:loadTranslationTable{
  ["zhaoang"] = "赵昂",
  ["#zhaoang"] = "剜心筑城",
  ["designer:zhaoang"] = "残昼厄夜",
  ["illustrator:zhaoang"] = "君桓文化",
  ["zhongjie"] = "忠节",
  [":zhongjie"] = "每轮限一次，当一名角色因失去体力而进入濒死状态时，你可以令其回复1点体力并摸一张牌。",
  ["sushou"] = "夙守",
  [":sushou"] = "一名角色的出牌阶段开始时，若其手牌数是全场唯一最多的，你可以失去1点体力并摸X张牌。"..
  "若此时不是你的回合内，你观看当前回合角色一半数量的手牌（向下取整），你可以用至多X张手牌替换其中等量的牌。（X为你已损失的体力值）",

  ["#zhongjie-invoke"] = "你可以对%dest发动 忠节，令其回复1点体力并摸一张牌",
  ["#sushou-invoke"] = "你可以对%dest发动 夙守",
  ["#sushou-exchange"] = "夙守：选择要交换你与%dest的至多%arg张手牌",

  ["$zhongjie1"] = "气节之士，不可不救。",
  ["$zhongjie2"] = "志士遭祸，应施以援手。",
  ["$sushou1"] = "敌众我寡，怎可少谋？",
  ["$sushou2"] = "临城据守，当出奇计。",
  ["~zhaoang"] = "援军为何迟迟不至？",
}

local liuye = General(extension, "ty__liuye", "wei", 3)
local poyuan_catapult = {{"ty__catapult", Card.Diamond, 9}}
local poyuan = fk.CreateTriggerSkill{
  name = "poyuan",
  anim_type = "control",
  events = {fk.GameStart, fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and (event == fk.GameStart or (event == fk.TurnStart and target == player)) then
      if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
        return table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
      else
        local catapult = table.find(U.prepareDeriveCards(player.room, poyuan_catapult, "poyuan_catapult"), function (id)
          return player.room:getCardArea(id) == Card.Void
        end)
        return catapult and U.canMoveCardIntoEquip(player, catapult)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#poyuan-choose", self.name, true)
      if #tos > 0 then
        self.cost_data = tos[1]
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, nil, "#poyuan-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local to = room:getPlayerById(self.cost_data)
      local cards = room:askForCardsChosen(player, to, 1, 2, "he", self.name)
      room:throwCard(cards, self.name, to, player)
    else
      local catapult = table.find(U.prepareDeriveCards(room, poyuan_catapult, "poyuan_catapult"), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      if catapult then
        room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutMyEquip, 1)
        room:moveCardIntoEquip(player, catapult, self.name, true, player)
      end
    end
  end,
}
local huace = fk.CreateViewAsSkill{
  name = "huace",
  prompt = "#huace-active",
  interaction = function()
    local all_names = U.getAllCardNames("t")
    local names = U.getViewAsCardNames(Self, "zhaowen", all_names, {}, Self:getTableMark("huace2"))
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local huace_record = fk.CreateTriggerSkill{
  name = "#huace_record",

  refresh_events = {fk.AfterCardUseDeclared, fk.RoundStart},
  can_refresh = function(self, event, target, player, data)
    return (event == fk.AfterCardUseDeclared and data.card:isCommonTrick()) or event == fk.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      local mark = player:getMark("huace1")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, data.card.trueName)
      room:setPlayerMark(player, "huace1", mark)
    else
      room:setPlayerMark(player, "huace2", player:getMark("huace1"))
      room:setPlayerMark(player, "huace1", 0)
    end
  end,
}
huace:addRelatedSkill(huace_record)
liuye:addSkill(poyuan)
liuye:addSkill(huace)
Fk:loadTranslationTable{
  ["ty__liuye"] = "刘晔",
  ["#ty__liuye"] = "佐世之才",
  ["cv:ty__liuye"] = "瀚涛",
  ["illustrator:ty__liuye"] = "一意动漫",
  ["poyuan"] = "破垣",
  [":poyuan"] = "游戏开始时或回合开始时，若你的装备区里没有【霹雳车】，你可以将【霹雳车】置于装备区；若有，你可以弃置一名其他角色至多两张牌。<br>"..
  "<font color='grey'>【霹雳车】<br>♦9 装备牌·宝物<br /><b>装备技能</b>：锁定技，你回合内使用基本牌的伤害和回复数值+1且无距离限制。"..
  "你回合外使用或打出基本牌时摸一张牌。离开你装备区时销毁。",
  ["huace"] = "画策",
  [":huace"] = "出牌阶段限一次，你可以将一张手牌当上一轮没有角色使用过的普通锦囊牌使用。",
  ["#poyuan-invoke"] = "破垣：你可以装备【霹雳车】",
  ["#poyuan-choose"] = "破垣：你可以弃置一名其他角色至多两张牌",
  ["#huace-active"] = "发动 画策，将一张手牌当上一轮没有角色使用过的普通锦囊牌使用",

  ["$poyuan1"] = "砲石飞空，坚垣难存。",
  ["$poyuan2"] = "声若霹雳，人马俱摧。",
  ["$huace1"] = "筹画所料，无有不中。",
  ["$huace2"] = "献策破敌，所谋皆应。",
  ["~ty__liuye"] = "功名富贵，到头来，不过黄土一抔……",
}

local yanghong = General(extension, "yanghong", "qun", 3)
local ty__jianji = fk.CreateActiveSkill{
  name = "ty__jianji",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function()
    return Self:getAttackRange()
  end,
  prompt = function ()
    return "#ty__jianji-prompt:::"..Self:getAttackRange()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getAttackRange() > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected < Self:getAttackRange() and not target:isRemoved() then
      if #selected == 0 then
        return true
      else
        for _, id in ipairs(selected) do
          local p = Fk:currentRoom():getPlayerById(id)
          if target:getNextAlive() == p or p:getNextAlive() == target then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local tos = effect.tos
    room:sortPlayersByAction(tos)
    tos = table.map(tos, Util.Id2PlayerMapper)
    for _, p in ipairs(tos) do
      room:askForDiscard(p, 1, 1, true, self.name, false)
    end
    tos = table.filter(tos, function(p) return not p.dead end)
    if #tos < 2 then return end
    local max_num = 0
    for _, p in ipairs(tos) do
      max_num = math.max(max_num, p:getHandcardNum())
    end
    local froms = table.filter(tos, function(p) return p:getHandcardNum() == max_num end)
    local from = (#froms == 1) and froms[1] or room:getPlayerById(
    room:askForChoosePlayers(player, table.map(froms, Util.IdMapper), 1, 1, "#ty__jianji-from", self.name, false)[1])
    local targets = table.filter(tos, function(p)
      return not p.dead and from:canUseTo(Fk:cloneCard("slash"), p, {bypass_times = true, bypass_distances = true})
    end)
    if #targets > 0 then
      local victim = room:askForChoosePlayers(from, table.map(targets, Util.IdMapper), 1, 1, "#ty__jianji-choose", self.name, true)
      if #victim > 0 then
        room:useVirtualCard("slash", nil, from, room:getPlayerById(victim[1]), self.name, true)
      end
    end
  end,
}
local yuanmo = fk.CreateTriggerSkill{
  name = "yuanmo",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start or (player.phase == Player.Finish and
          table.every(player.room:getOtherPlayers(player), function(p) return not player:inMyAttackRange(p) end))
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#yuanmo1-invoke"
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      prompt = "#yuanmo2-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart and player.phase == Player.Finish then
      room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)  --此处不能用addMark
    else
      local choice = room:askForChoice(player, {"yuanmo_add", "yuanmo_minus"}, self.name)
      if choice == "yuanmo_add" then
        local nos = table.filter(room:getOtherPlayers(player), function(p) return player:inMyAttackRange(p) end)
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") + 1)
        local targets = {}
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if player:inMyAttackRange(p) and not table.contains(nos, p) and not p:isNude() then
            table.insert(targets, p.id)
          end
        end
        local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#yuanmo-choose", self.name, true)
        if #tos > 0 then
          room:sortPlayersByAction(tos)
          for _, id in ipairs(tos) do
            if player.dead then break end
            local p = room:getPlayerById(id)
            if not p.dead and not p:isNude() then
              local card = room:askForCardChosen(player, p, "he", self.name, "#yuanmo-prey:"..id)
              room:obtainCard(player.id, card, false, fk.ReasonPrey)
            end
          end
        end
      else
        room:setPlayerMark(player, "@yuanmo", player:getMark("@yuanmo") - 1)
        player:drawCards(2, self.name)
      end
    end
  end,
}
local yuanmo_attackrange = fk.CreateAttackRangeSkill{
  name = "#yuanmo_attackrange",
  correct_func = function (self, from, to)
    return from:getMark("@yuanmo")
  end,
}
yuanmo:addRelatedSkill(yuanmo_attackrange)
yanghong:addSkill(ty__jianji)
yanghong:addSkill(yuanmo)
Fk:loadTranslationTable{
  ["yanghong"] = "杨弘",
  ["#yanghong"] = "柔迩驭远",
  ["cv:yanghong"] = "于松涛",
  ["designer:yanghong"] = "黑寡妇无敌",
  ["illustrator:yanghong"] = "虫师网络",
  ["ty__jianji"] = "间计",
  [":ty__jianji"] = "出牌阶段限一次，你可以令至多X名相邻的角色各弃置一张牌（X为你的攻击范围），然后你令其中手牌数最多的一名角色选择是否视为对其中的另一名角色使用一张【杀】。",
  ["yuanmo"] = "远谟",
  [":yuanmo"] = "①准备阶段或你受到伤害后，你可以选择一项：1.令你的攻击范围+1，然后获得任意名因此进入你攻击范围内的角色各一张牌；"..
  "2.令你的攻击范围-1，然后摸两张牌。<br>②结束阶段，若你攻击范围内没有角色，你可以令你的攻击范围+1。",
  ["#ty__jianji-choose"] = "间计：你可以视为对其中一名角色使用【杀】",
  ["#ty__jianji-from"] = "间计：选择视为使用【杀】的角色",
  ["#ty__jianji-prompt"] = "间计:令至多 %arg 名相邻的角色各弃置一张牌",
  ["#yuanmo1-invoke"]= "远谟：你可以令攻击范围+1并获得进入你攻击范围的角色各一张牌，或攻击范围-1并摸两张牌",
  ["#yuanmo2-invoke"]= "远谟：你可以令攻击范围+1",
  ["@yuanmo"] = "远谟",
  ["yuanmo_add"] = "攻击范围+1，获得因此进入攻击范围的角色各一张牌",
  ["yuanmo_minus"] = "攻击范围-1，摸两张牌",
  ["#yuanmo-choose"] = "远谟：你可以获得任意名角色各一张牌",
  ["#yuanmo-prey"] = "远谟：选择 %src 的一张牌获得",

  ["$ty__jianji1"] = "备枭雄也，布虓虎也，当间之。",
  ["$ty__jianji2"] = "二虎和则我亡，二虎斗则我兴。",
  ["$yuanmo1"] = "强敌不可战，弱敌不可恕。",
  ["$yuanmo2"] = "孙伯符羽翼已丰，主公当图刘备。",
  ["~yanghong"] = "主公为何不听我一言？",
}

local huanfan = General(extension, "huanfan", "wei", 3)
local jianzheng = fk.CreateActiveSkill{
  name = "jianzheng",
  anim_type = "control",
  target_num = 1,
  card_num = 0,
  prompt = "#jianzheng-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = target.player_cards[Player.Hand]
    local availableCards = table.filter(cards, function(id)
      local card = Fk:getCardById(id)
      return U.getDefaultTargets(player, card, true, false)
    end)
    local get, _ = U.askforChooseCardsAndChoice(player, availableCards, {"OK"}, self.name, "#jianzheng-choose", {"Cancel"}, 1, 1, cards)
    local yes = false
    if #get > 0 then
      local id = get[1]
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
      local card = Fk:getCardById(id)
      if not player.dead and table.contains(player:getCardIds("h"), id) and U.getDefaultTargets(player, card, true, false) then
        local use = room:askForUseRealCard(player, {id}, self.name, "#jianzheng-use:::"..card:toLogString(), {
          bypass_times = true,
          extraUse = true,
        })
        if use and table.contains(TargetGroup:getRealTargets(use.tos), target.id) then
          yes = true
        end
      end
    end
    if yes then
      if not player.dead and not player.chained then
        player:setChainState(true)
      end
      if not target.dead and not target.chained then
        target:setChainState(true)
      end
      if not player.dead and not target.dead and not player:isKongcheng() then
        U.viewCards(target, player:getCardIds("h"), self.name, "$ViewCardsFrom:"..player.id)
      end
    end
  end,
}
local fumou = fk.CreateTriggerSkill{
  name = "fumou",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, player:getLostHp(), "#fumou-choose:::"..player:getLostHp(), self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      if table.removeOne(tos, player.id) then
        table.insert(tos, 1, player.id)
      end
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local choices = {}
        if #room:canMoveCardInBoard() > 0 then
          table.insert(choices, "fumou1")
        end
        if not p:isKongcheng() then
          table.insert(choices, "fumou2")
        end
        if #p:getCardIds("e") > 0 then
          table.insert(choices, "fumou3")
        end
        if #choices == 0 then
          --continue
        else
          local choice = room:askForChoice(p, choices, self.name)
          if choice == "fumou1" then
            local targets = room:askForChooseToMoveCardInBoard(p, "#fumou-move", self.name, false)
            room:askForMoveCardInBoard(p, room:getPlayerById(targets[1]), room:getPlayerById(targets[2]), self.name)
          elseif choice == "fumou2" then
            p:throwAllCards("h")
            if not p.dead then
              p:drawCards(2, self.name)
            end
          elseif choice == "fumou3" then
            p:throwAllCards("e")
            if p:isWounded() then
              room:recover({
                who = p,
                num = 1,
                recoverBy = player,
                skillName = self.name
              })
            end
          end
        end
      end
    end
  end,
}
huanfan:addSkill(jianzheng)
huanfan:addSkill(fumou)
Fk:loadTranslationTable{
  ["huanfan"] = "桓范",
  ["#huanfan"] = "雍国竝世",
  ["illustrator:huanfan"] = "虫师",
  ["jianzheng"] = "谏诤",
  [":jianzheng"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后若其中有你可以使用的牌，你可以获得并使用其中一张。"..
  "若此牌指定了其为目标，则横置你与其武将牌，然后其观看你的手牌。",
  ["fumou"] = "腹谋",
  [":fumou"] = "当你受到伤害后，你可以令至多X名角色依次选择一项：1.移动场上一张牌；2.弃置所有手牌并摸两张牌；3.弃置装备区所有牌并回复1点体力。"..
  "（X为你已损失的体力值）",

  ["#jianzheng-prompt"] = "谏诤：你可观看一名其他角色的手牌，且可以获得并使用其中一张",
  ["#jianzheng-choose"] = "谏诤：选择一张使用",
  ["#jianzheng-use"] = "谏诤：请使用%arg",
  ["#fumou-choose"] = "腹谋：你可以令至多%arg名角色依次选择执行一项",
  ["fumou1"] = "移动场上一张牌",
  ["fumou2"] = "弃置所有手牌，摸两张牌",
  ["fumou3"] = "弃置所有装备，回复1点体力",
  ["#fumou-move"] = "腹谋：请移动场上一张牌(选择两名角色)",

  ["$jianzheng1"] = "将军今出洛阳，恐难再回。",
  ["$jianzheng2"] = "贼示弱于外，必包藏祸心。",
  ["$fumou1"] = "某有良谋，可为将军所用。",
  ["$fumou2"] = "吾负十斗之囊，其盈一石之智。",
  ["~huanfan"] = "有良言而不用，君何愚哉……",
}

local xizheng = General(extension, "xizheng", "shu", 3)
local danyi = fk.CreateTriggerSkill{
  name = "danyi",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.firstTarget then
      local room = player.room
      local targets = AimGroup:getAllTargets(data.tos)
      local use_event = room.logic:getCurrentEvent()
      local last_tos = {}
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id < use_event.id then
          local use = e.data[1]
          if use.from == player.id then
            last_tos = TargetGroup:getRealTargets(use.tos)
            return true
          end
        end
      end, 0)
      if #last_tos == 0 then return false end
      local x = #table.filter(room.alive_players, function (p)
        return table.contains(targets, p.id) and table.contains(last_tos, p.id)
      end)
      if x > 0 then
        self.cost_data = x
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,
}
local wencan = fk.CreateActiveSkill{
  name = "wencan",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = "#wencan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected > 1 or to_select == Self.id then return false end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(to_select).hp ~= Fk:currentRoom():getPlayerById(selected[1]).hp
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if not room:askForUseActiveSkill(p, "wencan_active", "#wencan-discard:"..player.id, true) then
          room:setPlayerMark(p, "@@wencan-turn", 1)
        end
      end
    end
  end,
}
local wencan_active = fk.CreateActiveSkill{
  name = "wencan_active",
  mute = true,
  card_num = 2,
  target_num = 0,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    if not Self:prohibitDiscard(card) and card.suit ~= Card.NoSuit then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return card.suit ~= Fk:getCardById(selected[1]).suit
      else
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, "wencan", player, player)
  end,
}
local wencan_refresh = fk.CreateTriggerSkill{
  name = "#wencan_refresh",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    if player == target and player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 then
      return table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return player.room:getPlayerById(pid):getMark("@@wencan-turn") > 0
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
}
local wencan_targetmod = fk.CreateTargetModSkill{
  name = "#wencan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 and scope == Player.HistoryPhase and
    to and to:getMark("@@wencan-turn") > 0
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return card and player:usedSkillTimes("wencan", Player.HistoryTurn) > 0 and to and to:getMark("@@wencan-turn") > 0
  end,
}
Fk:addSkill(wencan_active)
wencan:addRelatedSkill(wencan_refresh)
wencan:addRelatedSkill(wencan_targetmod)
xizheng:addSkill(danyi)
xizheng:addSkill(wencan)
Fk:loadTranslationTable{
  ["xizheng"] = "郤正",
  ["#xizheng"] = "君子有取",
  ["illustrator:xizheng"] = "黄宝",
  ["danyi"] = "耽意",
  [":danyi"] = "你使用牌指定目标后，若此牌目标与你使用的上一张牌有相同的目标，你可以摸X张牌（X为这些目标的数量）。",
  ["wencan"] = "文灿",
  [":wencan"] = "出牌阶段限一次，你可以选择至多两名体力值不同的角色，这些角色依次选择一项：1.弃置两张花色不同的牌；"..
  "2.本回合你对其使用牌无距离和次数限制。",
  ["#wencan"] = "文灿：选择至多两名体力值不同的角色，其弃牌或你对其使用牌无限制",
  ["@@wencan-turn"] = "文灿",
  ["wencan_active"] = "文灿",
  ["#wencan-discard"] = "文灿：弃置两张不同花色的牌，否则 %src 本回合对你使用牌无限制",

  ["$danyi1"] = "满城锦绣，何及笔下春秋？",
  ["$danyi2"] = "一心向学，不闻窗外风雨。",
  ["$wencan1"] = "宴友以文，书声喧哗，众宾欢也。",
  ["$wencan2"] = "众星灿于九天，犹雅文耀于万世。",
  ["~xizheng"] = "此生有涯，奈何学海无涯……",
}

local ty__tianfeng = General(extension, "ty__tianfeng", "qun", 3)
local ty__sijian = fk.CreateTriggerSkill{
  name = "ty__sijian",
  events = {fk.AfterCardsMove},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or not player:isKongcheng() then return end
    local ret = false
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            ret = true
            break
          end
        end
      end
    end
    if ret then
      return table.find(player.room.alive_players, function(p) return not p:isNude() end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p) return not p:isNude() end), Util.IdMapper)
    local target = room:askForChoosePlayers(player, targets, 1, 1, "#ty__sijian-ask", self.name, true)
    if #target > 0 then
      self.cost_data = target[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    room:throwCard({id}, self.name, to, player)
  end,
}
local ty__suishi = fk.CreateTriggerSkill{
  name = "ty__suishi",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying, fk.Death},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) or target == player then return false end
    if event == fk.EnterDying then
      return data.damage and data.damage.from and player.kingdom == data.damage.from.kingdom
    else
      return player.kingdom == target.kingdom and not player:isKongcheng()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name, 1)
      player:drawCards(1, self.name)
    else
      room:notifySkillInvoked(player, self.name, "negative")
      player:broadcastSkillInvoke(self.name, 2)
      room:askForDiscard(player, 1, 999, false, self.name, false)
    end
  end,
}
ty__tianfeng:addSkill(ty__sijian)
ty__tianfeng:addSkill(ty__suishi)
Fk:loadTranslationTable{
  ["ty__tianfeng"] = "田丰",
  ["#ty__tianfeng"] = "河北瑰杰",
  ["illustrator:ty__tianfeng"] = "君桓文化",

  ["ty__sijian"] = "死谏",
  [":ty__sijian"] = "当你失去手牌后，若你没有手牌，你可弃置一名其他角色的一张牌。",
  ["ty__suishi"] = "随势",
  [":ty__suishi"] = "锁定技，当其他角色进入濒死状态时，若伤害来源与你势力相同，你摸一张牌；当其他角色死亡时，若其与你势力相同，你弃置至少一张"..
  "手牌。",
  ["#ty__sijian-ask"] = "死谏：你可弃置一名其他角色的一张牌",

  ["$ty__sijian1"] = "且听我最后一言！",
  ["$ty__sijian2"] = "忠言逆耳啊！",
  ["$ty__suishi1"] = "一荣俱荣！",
  ["$ty__suishi2"] = "一损俱损……",
  ["~ty__tianfeng"] = "不纳吾言而反诛吾心，奈何奈何！！",
}

local lvfan = General(extension, "ty__lvfan", "wu", 3)
local ty__diaodu = fk.CreateTriggerSkill{
  name = "ty__diaodu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return player:distanceTo(p) <= 1 and #p:getCardIds("e") > 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return player:distanceTo(p) <= 1 and #p:getCardIds("e") > 0
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#ty__diaodu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local id = room:askForCardChosen(player, to, "e", self.name)
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    if player.dead or not table.contains(player:getCardIds("h"), id) then return end
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p ~= to
    end), Util.IdMapper)
    local p = room:askForChoosePlayers(player, targets, 1, 1,
      "#ty__diaodu-give:::"..Fk:getCardById(id):toLogString(), self.name, to ~= player)
    if #p > 0 then
      p = room:getPlayerById(p[1])
      room:moveCardTo(id, Card.PlayerHand, p, fk.ReasonGive, self.name, nil, true, player.id)
      local card = Fk:getCardById(id)
      if p.dead or not table.contains(p:getCardIds("h"), id) or p:isProhibited(p, card) then return end
      if room:askForSkillInvoke(p, self.name, nil, "#ty__diaodu-use:"..player.id.."::"..card:toLogString()) then
        room:useCard({
          from = p.id,
          tos = {{p.id}},
          card = card,
        })
        if not player.dead then
          player:drawCards(1, self.name)
        end
      else
        p:drawCards(1, self.name)
      end
    end
  end,
}
local ty__diancai = fk.CreateTriggerSkill{
  name = "ty__diancai",
  events = {fk.EventPhaseEnd},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target ~= player and target.phase == Player.Play and player:getHandcardNum() < player.maxHp then
    local num = 0
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from == player.id and ((move.to and move.to ~= player.id) or
          not table.contains({Card.PlayerHand, Card.PlayerEquip}, move.toArea)) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              num = num + 1
              if num > 5 then
                return true
              end
            end
          end
        end
      end
    end, Player.HistoryPhase)
      return num >= math.min(player.hp, 5)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    if not player.dead and table.find(room.alive_players, function(p)
      return player:distanceTo(p) <= 1 and #p:getCardIds("e") > 0
    end) then
      ty__diaodu:doCost(event, target, player, data)
    end
  end,
}
lvfan:addSkill(ty__diaodu)
lvfan:addSkill(ty__diancai)
Fk:loadTranslationTable{
  ["ty__lvfan"] = "吕范",
  ["#ty__lvfan"] = "忠笃亮直",
  ["illustrator:ty__lvfan"] = "叶孑",
  ["~ty__lvfan"] = "印绶未下，疾病已发。",

  ["ty__diaodu"] = "调度",
  [":ty__diaodu"] = "出牌阶段开始时，你可以获得距离1以内一名角色装备区内的一张牌，然后将此牌交给除其以外一名角色，该角色选择一项：1.使用此牌，"..
  "然后你摸一张牌；2.不使用此牌，其摸一张牌。",
  ["ty__diancai"] = "典财",
  [":ty__diancai"] = "其他角色出牌阶段结束时，若你此阶段失去了至少X张牌，你可以将手牌摸至体力上限（X为你的体力值，至多为5），然后你可以发动"..
  "一次〖调度〗。",
  ["#ty__diaodu-choose"] = "调度：获得一名角色装备区一张牌，然后交给除其以外的角色，该角色可以使用之",
  ["#ty__diaodu-give"] = "调度：将%arg交给一名角色，其可以使用之",
  ["#ty__diaodu-use"] = "调度：使用%arg令 %src 摸一张牌；或不使用，你摸一张牌",

  ["$ty__diaodu1"] = "开源节流，作法于凉。",
  ["$ty__diaodu2"] = "调度征求，省行薄敛。",
  ["$ty__diancai1"] = "量入为出，利析秋毫。",
  ["$ty__diancai2"] = "天下熙攘，皆为利往。",
}
