local shouli = fk.CreateSkill {
  name = "shouli"
}

Fk:loadTranslationTable{
  ['shouli'] = '狩骊',
  ['#shouli-horse'] = '狩骊：选择一名装备着 %arg 的角色',
  ['@@shouli-turn'] = '狩骊',
  ['#shouli_trigger'] = '狩骊',
  ['#shouli_delay'] = '狩骊',
  [':shouli'] = '游戏开始时，从下家开始所有角色随机使用牌堆中的一张坐骑。你可以将场上的一张进攻马当【杀】（无次数限制）、防御马当【闪】使用或打出，以此法失去坐骑的其他角色本回合非锁定技失效，你与其本回合受到的伤害+1且改为雷电伤害。',
  ['$shouli1'] = '赤骊骋疆，巡狩八荒！',
  ['$shouli2'] = '长缨在手，百骥可降！',
}

shouli:addEffect('viewas', {
  pattern = "slash,jink",
  prompt = function(self, player, card, selected_targets)
    return "#shouli-" .. skill.interaction.data
  end,
  interaction = function()
    local names = {}
    local pat = Fk.currentResponsePattern
    if pat == nil and table.find(Fk:currentRoom().alive_players, function(p)
      return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil
    end) then
      local slash = Fk:cloneCard("slash")
      slash.skillName = "shouli"
      if player:canUse(slash) and not player:prohibitUse(slash) then
        table.insert(names, "slash")
      end
    else
      if Exppattern:Parse(pat):matchExp("slash") and table.find(Fk:currentRoom().alive_players, function(p)
        return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil
      end) then
        table.insert(names, "slash")
      end
      if Exppattern:Parse(pat):matchExp("jink") and table.find(Fk:currentRoom().alive_players, function(p)
        return p:getEquipment(Card.SubtypeDefensiveRide) ~= nil
      end) then
        table.insert(names, "jink")
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}  --FIXME: 体验很不好！
  end,
  view_as = function(self, player, cards)
    if skill.interaction.data == nil then return end
    local card = Fk:cloneCard(skill.interaction.data)
    card.skillName = shouli.name
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
      local tos = room:askToChoosePlayers(player, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#shouli-horse:::" .. horse_name,
        skill_name = shouli.name,
        cancelable = false,
        no_indicate = true
      })
      if #tos > 0 then
        local to = room:getPlayerById(tos[1])
        room:addPlayerMark(to, "@@shouli-turn")
        if to ~= player then
          room:addPlayerMark(player, "@@shouli-turn")
          room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
        end
        local horse = to:getEquipment(horse_type)
        if horse then
          -- room:obtainCard(player.id, horse, false, fk.ReasonPrey)
          -- if room:getCardOwner(horse) == player and room:getCardArea(horse) == Player.Hand then
          use.card:addSubcard(horse)
          use.extraUse = true
          return
          -- end
        end
      end
    end
    return ""
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p:getEquipment(Card.SubtypeOffensiveRide) ~= nil
    end)
  end,
  enabled_at_response = function(self, player)
    local pat = Fk.currentResponsePattern
    return pat and table.find(Fk:currentRoom().alive_players, function(p)
      return (Exppattern:Parse(pat):matchExp("slash") and p:getEquipment(Card.SubtypeOffensiveRide) ~= nil) or
        (Exppattern:Parse(pat):matchExp("jink") and p:getEquipment(Card.SubtypeDefensiveRide) ~= nil)
    end)
  end,
})

shouli:addEffect(fk.GameStart, {
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
})

shouli:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@shouli-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
    data.damageType = fk.ThunderDamage
  end,
})

shouli:addEffect('targetmod', {
  bypass_times = function(self, player, skillName, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, shouli.name)
  end,
})

return shouli
