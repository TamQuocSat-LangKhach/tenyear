local lixun = fk.CreateSkill {
  name = "lixun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lixun"] = "利熏",
  [":lixun"] = "锁定技，当你受到伤害时，防止此伤害，改为获得等同于伤害值的“珠”标记。出牌阶段开始时，你进行一次判定，若结果点数小于“珠”数，"..
  "你弃置等同于“珠”数的手牌，若弃牌数不足，则失去不足数量的体力值。",

  ["@lisu_zhu"] = "珠",

  ["$lixun1"] = "利欲熏心，财权保命。",
  ["$lixun2"] = "利益当前，岂不心动？",
}

lixun:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@lisu_zhu", 0)
end)

lixun:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lixun.name)
  end,
  on_use = function(self, event, target, player, data)
    local n = data.damage
    data:preventDamage()
    player.room:addPlayerMark(player, "@lisu_zhu", n)
  end,
})

lixun:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lixun.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pattern = ".|"..player:getMark("@lisu_zhu").."~K"
    if player:getMark("@lisu_zhu") <= 1 then
      pattern = "."
    end
    local judge = {
      who = player,
      reason = lixun.name,
      pattern = pattern,
    }
    room:judge(judge)
    if player.dead then return end
    local n = player:getMark("@lisu_zhu")
    if judge.card.number < n then
      local cards = room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = lixun.name,
        cancelable = false,
      })
      if #cards < n and not player.dead then
        room:loseHp(player, n - #cards)
      end
    end
  end,
})

return lixun
