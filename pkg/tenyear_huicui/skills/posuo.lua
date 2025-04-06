local posuo = fk.CreateSkill {
  name = "posuo",
}

Fk:loadTranslationTable{
  ["posuo"] = "婆娑",
  [":posuo"] = "出牌阶段每种花色限一次，若你本阶段未对其他角色造成过伤害，你可以将一张手牌当此花色有的一张伤害牌使用。",

  ["#posuo"] = "婆娑：将一张手牌当此花色有的一张伤害牌使用",
  ["posuo_name"] = "%arg [%arg2]",

  ["$posuo1"] = "绯纱婆娑起，佳人笑靥红。",
  ["$posuo2"] = "红烛映俏影，一舞影斑斓。",
}

posuo:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#posuo",
  interaction = function(self, player)
    local names = player:getMark("posuo_names")
    if names == 0 then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          names[card.name] = names[card.name] or {}
          table.insertIfNeed(names[card.name], card:getSuitString(true))
        end
      end
      player:setMark("posuo_names", names)
    end

    local choices, all_choices = {}, {}
    for name, suits in pairs(names) do
      local _suits = {}
      for _, suit in ipairs(suits) do
        if not table.contains(player:getTableMark("posuo-phase"), suit) then
          table.insert(_suits, Fk:translate(suit))
        end
      end
      local posuo_name = "posuo_name:::" .. name.. ":" .. table.concat(_suits, "")
      table.insert(all_choices, posuo_name)
      if #_suits > 0 then
        local to_use = Fk:cloneCard(name)
        if player:canUse(to_use) and not player:prohibitUse(to_use) then
          table.insert(choices, posuo_name)
        end
      end
    end

    if #choices == 0 then return end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data and #selected == 0 and
      table.contains(player:getHandlyIds(), to_select) then
        local name = string.split(self.interaction.data, ":")
        return string.find(name[#name], Fk:translate(Fk:getCardById(to_select):getSuitString(true)))
      end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(string.split(self.interaction.data, ":")[4])
    card:addSubcard(cards[1])
    card.skillName = posuo.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "posuo-phase", use.card:getSuitString(true))
  end,
  enabled_at_play = function(self, player)
    local mark = player:getMark("posuo-phase")
    return mark ~= "posuo_prohibit" and mark == 0 or (#mark < 4)
  end,
})

posuo:addAcquireEffect(function (self, player, is_start)
  if player.phase == Player.Play then
    local room = player.room
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data
      if damage.from == player then
        room:setPlayerMark(player, "posuo-phase", "posuo_prohibit")
        return true
      end
    end, Player.HistoryPhase)
  end
end)

posuo:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(posuo.name, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "posuo-phase", "posuo_prohibit")
  end,
})

return posuo
