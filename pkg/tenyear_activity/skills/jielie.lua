local jielie = fk.CreateSkill {
  name = "jielie"
}

Fk:loadTranslationTable{
  ['jielie'] = '节烈',
  ['kangge'] = '抗歌',
  ['#jielie-choice'] = '是否发动 节烈，选择一种花色',
  ['@kangge'] = '抗歌',
  [':jielie'] = '当你受到你或〖抗歌〗角色以外的角色造成的伤害时，你可以防止此伤害并选择一种花色，失去X点体力，令〖抗歌〗角色从弃牌堆中随机获得X张此花色的牌（X为伤害值）。',
  ['$jielie1'] = '节烈之妇，从一而终也！',
  ['$jielie2'] = '清闲贞静，守节整齐。',
}

jielie:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jielie.name) and data.from and
      data.from ~= player and data.from.id ~= player:getMark("kangge")
  end,
  on_cost = function(self, event, target, player, data)
    local suits = {"spade", "heart", "club", "diamond"}
    local choices = table.map(suits, function(s) return Fk:translate("log_"..s) end)
    table.insert(choices, "Cancel")
    local choiceParams = {
      choices = choices,
      skill_name = jielie.name,
      prompt = "#jielie-choice"
    }
    local choice = player.room:askToChoice(player, choiceParams)
    if choice ~= "Cancel" then
      event:setCostData(skill, suits[table.indexOf(choices, choice)])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suit = event:getCostData(skill)
    room:loseHp(player, data.damage, jielie.name)
    local kangge_id = player:getMark("kangge")
    if kangge_id ~= 0 then
      local to = room:getPlayerById(kangge_id)
      if to and not to.dead then
        room:setPlayerMark(player, "@kangge", to.general)
        local cards = room:getCardsFromPileByRule(".|.|"..suit, data.damage, "discardPile")
        if #cards > 0 then
          room:moveCards({
            ids = cards,
            to = to.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = jielie.name,
            moveVisible = false
          })
        end
      end
    end
    return true
  end,
})

return jielie
