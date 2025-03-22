local biejun = fk.CreateSkill {
  name = "biejun",
  attached_skill_name = "biejun&",
}

Fk:loadTranslationTable{
  ["biejun"] = "别君",
  [":biejun"] = "其他角色出牌阶段限一次，其可以交给你一张手牌。当你受到伤害时，若你手牌中没有本回合以此法获得的牌，你可以翻面并防止此伤害。",

  ["@@biejun-inhand-turn"] = "别君",
  ["#biejun-invoke"] = "别君：你可以翻面，防止你受到的伤害",

  ["$biejun1"] = "彼岸荼蘼远，落寞北风凉。",
  ["$biejun2"] = "此去经年，不知何时能归？",
}

biejun:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(biejun.name) and
      not table.find(player:getCardIds("h"), function(id)
        return Fk:getCardById(id):getMark("@@biejun-inhand-turn") ~= 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = biejun.name,
      prompt = "#biejun-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    data:preventDamage()
    player:turnOver()
  end,
})

return biejun
