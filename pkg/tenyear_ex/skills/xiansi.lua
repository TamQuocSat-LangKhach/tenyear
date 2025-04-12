local xiansi = fk.CreateSkill {
  name = "ty_ex__xiansi",
  attached_skill_name = "ty_ex__xiansi&",
}

Fk:loadTranslationTable{
  ["ty_ex__xiansi"] = "陷嗣",
  [":ty_ex__xiansi"] = "准备阶段，你可以将至多两名其他角色的各一张牌置于你的武将牌上，称为“逆”。当其他角色需要对你使用一张【杀】时，"..
  "该角色可以移去你武将牌上的两张“逆”，视为对你使用一张【杀】。若“逆”超过你的体力值，你可以移去一张“逆”，视为使用一张【杀】。",

  ["ty_ex__xiansi_ni"] = "逆",
  ["#ty_ex__xiansi-choose"] = "陷嗣：你可以将至多两名其他角色各一张牌置为“逆”",
  ["#ty_ex__xiansi"] = "陷嗣：你可以移去一张“逆”，视为使用一张【杀】",

  ["$ty_ex__xiansi1"] = "非我不救，实乃孟达谗言。",
  ["$ty_ex__xiansi2"] = "此皆孟达之过也！"
}

xiansi:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#ty_ex__xiansi",
  derived_piles = "ty_ex__xiansi_ni",
  expand_pile = "ty_ex__xiansi_ni",
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getPile("ty_ex__xiansi_ni"), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 0 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = xiansi.name
    self.cost_data = cards
    return c
  end,
  before_use = function(self, player, use)
    player.room:moveCards({
      from = player,
      ids = self.cost_data,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = xiansi.name,
    })
  end,
  enabled_at_play = function(self, player)
    return player:hasSkill(xiansi.name) and #player:getPile("ty_ex__xiansi_ni") > player.hp
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:hasSkill(xiansi.name) and #player:getPile("ty_ex__xiansi_ni") > player.hp
  end,
})

xiansi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiansi.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local tos = room:askToChoosePlayers(player, {
      skill_name = xiansi.name,
      min_num = 1,
      max_num = 2,
      targets = targets,
      prompt = "#ty_ex__xiansi-choose",
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if player.dead then return end
      if not p:isNude() and not p.dead then
        local id = room:askToChooseCard(player, {
          target = p,
          flag = "he",
          skill_name = xiansi.name,
        })
        player:addToPile("ty_ex__xiansi_ni", id, true, xiansi.name)
      end
    end
  end,
})

return xiansi
