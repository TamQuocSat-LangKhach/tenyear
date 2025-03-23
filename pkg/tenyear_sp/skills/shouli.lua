local shouli = fk.CreateSkill {
  name = "shouli",
}

Fk:loadTranslationTable{
  ["shouli"] = "狩骊",
  [":shouli"] = "游戏开始时，从下家开始所有角色随机使用牌堆中的一张坐骑。你可以将场上的一张进攻马当【杀】（无次数限制）、防御马当【闪】使用或打出，"..
  "以此法失去坐骑的其他角色本回合非锁定技失效，你与其本回合受到的伤害+1且改为雷电伤害。",

  ["#shouli-slash"] = "狩骊：将场上的一张进攻马当【杀】使用或打出（先选【杀】的目标）",
  ["#shouli-jink"] = "狩骊：将场上的一张防御马当【闪】使用或打出",
  ["#shouli-horse"] = "狩骊：选择一名装备着 %arg 的角色",
  ["@@shouli-turn"] = "狩骊",

  ["$shouli1"] = "赤骊骋疆，巡狩八荒！",
  ["$shouli2"] = "长缨在手，百骥可降！",
}

local U = require "packages/utility/utility"

shouli:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = function(self, player, card, selected_targets)
    return "#shouli-" .. self.interaction.data
  end,
  interaction = function(self, player)
    local names = {}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if table.find(p:getEquipments(Card.SubtypeOffensiveRide), function (id)
        return #player:getViewAsCardNames(shouli.name, {"slash"}, {id}) > 0
      end) then
        table.insertIfNeed(names, "slash")
      end
      if table.find(p:getEquipments(Card.SubtypeDefensiveRide), function (id)
        return #player:getViewAsCardNames(shouli.name, {"jink"}, {id}) > 0
      end) then
        table.insertIfNeed(names, "jink")
      end
      if #names == 2 then break end
    end
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = {"slash", "jink"}}
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = shouli.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local horse_type = use.card.trueName == "slash" and Card.SubtypeOffensiveRide or Card.SubtypeDefensiveRide
    local horse_name = use.card.trueName == "slash" and "offensive_horse" or "defensive_horse"
    local targets = table.filter(room.alive_players, function (p)
      return #p:getEquipments(horse_type) > 0
    end)
    local to = room:askToChoosePlayers(player, {
      skill_name = shouli.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#shouli-horse:::" .. horse_name,
      cancelable = false,
      no_indicate = true,
    })[1]
    room:addPlayerMark(to, "@@shouli-turn", 1)
    if to ~= player then
      room:addPlayerMark(player, "@@shouli-turn", 1)
      room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
    end
    use.card:addSubcards(to:getEquipments(horse_type))
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if table.find(p:getEquipments(Card.SubtypeOffensiveRide), function (id)
        return #player:getViewAsCardNames(shouli.name, {"slash"}, {id}) > 0
      end) then
        return true
      end
    end
  end,
  enabled_at_response = function(self, player)
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if table.find(p:getEquipments(Card.SubtypeOffensiveRide), function (id)
        return #player:getViewAsCardNames(shouli.name, {"slash"}, {id}) > 0
      end) then
        return true
      end
      if table.find(p:getEquipments(Card.SubtypeDefensiveRide), function (id)
        return #player:getViewAsCardNames(shouli.name, {"jink"}, {id}) > 0
      end) then
        return true
      end
    end
  end,
})

shouli:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shouli.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player, room.alive_players)
    local temp = player.next
    local players = {}
    while temp ~= player do
      if not temp.dead then
        table.insert(players, temp)
      end
      temp = temp.next
    end
    table.insert(players, player)
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
            from = p,
            tos = {p},
            card = horse,
          }
        end
      end
    end
  end,
})

shouli:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@shouli-turn") > 0
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
    data.damageType = fk.ThunderDamage
  end,
})

shouli:addEffect("targetmod", {
  bypass_times = function(self, player, skillName, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, shouli.name)
  end,
})

return shouli
