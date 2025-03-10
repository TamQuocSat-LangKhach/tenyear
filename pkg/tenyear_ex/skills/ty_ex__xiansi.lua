local ty_ex__xiansi = fk.CreateSkill {
  name = "ty_ex__xiansi"
}

Fk:loadTranslationTable{
  ['ty_ex__xiansi'] = '陷嗣',
  ['ty_ex__xiansi&'] = '陷嗣',
  ['ty_ex__xiansi_ni'] = '逆',
  ['#ty_ex__xiansi-choose'] = '陷嗣：你可以将至多两名其他角色各一张牌置为“逆”',
  ['ty_ex__xiansi_viewasSkill'] = '陷嗣',
  [':ty_ex__xiansi'] = '回合开始阶段开始时，你可以将至多两名其他角色的各一张牌置于你的武将牌上，称为“逆”。每当其他角色需要对你使用一张【杀】时，该角色可以弃置你武将牌上的两张“逆”，视为对你使用一张【杀】。若“逆”超过你的体力值，你可以移去一张“逆”，视为使用一张【杀】。',
  ['$ty_ex__xiansi1'] = '非我不救，实乃孟达谗言。',
  ['$ty_ex__xiansi2'] = '此皆孟达之过也！'
}

ty_ex__xiansi:addEffect(fk.EventPhaseStart, {
  attached_skill_name = "ty_ex__xiansi&",
  derived_piles = "ty_ex__xiansi_ni",
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(ty_ex__xiansi) and player.phase == Player.Start then
      return not table.every(player.room:getOtherPlayers(player), function (p) return p:isNude() end)
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude()
    end), Util.IdMapper)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 2,
      prompt = "#ty_ex__xiansi-choose",
      skill_name = ty_ex__xiansi.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, p in ipairs(event:getCostData(self)) do
      local id = room:askToChooseCard(player, {
        target = room:getPlayerById(p),
        flag = "he",
        skill_name = ty_ex__xiansi.name,
      })
      player:addToPile("ty_ex__xiansi_ni", id, true, ty_ex__xiansi.name)
    end
  end,
})

ty_ex__xiansi:addEffect('viewas', {
  anim_type = "negative",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local c = Fk:cloneCard("slash")
    c.skillName = "ty_ex__xiansi"
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    local cards = table.random(player:getPile("ty_ex__xiansi_ni"), 1)
    room:moveCards({
      from = player.id,
      ids = cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = "ty_ex__xiansi",
    })
  end,
  enabled_at_play = function(self, player)
    return player:hasSkill(ty_ex__xiansi, true) and #player:getPile("ty_ex__xiansi_ni") > player.hp
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:hasSkill(ty_ex__xiansi, true) and #player:getPile("ty_ex__xiansi_ni") > player.hp
  end,
})

return ty_ex__xiansi
