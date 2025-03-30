local shenzhi = fk.CreateSkill {
  name = "ty__shenzhi",
}

Fk:loadTranslationTable{
  ["ty__shenzhi"] = "神智",
  [":ty__shenzhi"] = "准备阶段，若你手牌数大于体力值，你可以弃置一张手牌并回复1点体力。",

  ["#ty__shenzhi-invoke"] = "神智：你可以弃置一张手牌，回复1点体力",

  ["$ty__shenzhi1"] = "子龙将军，一切都托付给你了。",
  ["$ty__shenzhi2"] = "阿斗，相信妈妈，没事的。",
}

shenzhi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shenzhi.name) and player.phase == Player.Start and
      player:getHandcardNum() > player.hp and player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = shenzhi.name,
      cancelable = true,
      prompt = "#ty__shenzhi-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, shenzhi.name, player, player)
    if not player.dead and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = shenzhi.name,
      }
    end
  end,
})

return shenzhi
