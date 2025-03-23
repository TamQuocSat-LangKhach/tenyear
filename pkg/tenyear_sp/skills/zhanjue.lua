local zhanjue = fk.CreateSkill {
  name = "zhanjueh",
}

Fk:loadTranslationTable{
  ["zhanjueh"] = "斩决",
  [":zhanjueh"] = "出牌阶段开始时，你可以选择一项：1.摸体力值数量的牌，令你此阶段使用下一张【杀】无距离限制且不可被响应；"..
  "2.摸已损失体力值数量的牌，令你于此阶段下一次造成伤害后回复等量体力。",

  ["zhanjueh_hp"] = "摸%arg张牌，下一张【杀】无距离限制且不可响应",
  ["zhanjueh_losthp"] = "摸%arg张牌，下一次造成伤害后回复等量体力",
  ["@zhanjueh-phase"] = "斩决",
  ["zhanjueh_aim"] = "强中",
  ["zhanjueh_recover"] = "吸血",

  ["$zhanjueh1"] = "流不尽的英雄血，斩不尽的逆贼头！",
  ["$zhanjueh2"] = "长刀渴血，当饲英雄胆！"
}

zhanjue:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(zhanjue.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "zhanjueh_hp:::"..player.hp, "zhanjueh_losthp:::"..player:getLostHp(), "Cancel" },
      skill_name = zhanjue.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice:startsWith("zhanjueh_hp") then
      room:setPlayerMark(player, "@zhanjueh-phase", "zhanjueh_aim")
      player:drawCards(player.hp, zhanjue.name)
    else
      room:setPlayerMark(player, "@zhanjueh-phase", "zhanjueh_recover")
      if player:isWounded() then
        player:drawCards(player:getLostHp(), zhanjue.name)
      end
    end
  end,
})

zhanjue:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and player:getMark("@zhanjueh-phase") == "zhanjueh_aim"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhanjueh-phase", 0)
    data.disresponsiveList = table.simpleClone(room.players)
  end,
})

zhanjue:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@zhanjueh-phase") == "zhanjueh_recover"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@zhanjueh-phase", 0)
    room:recover{
      who = player,
      num = data.damage,
      recoverBy = player,
      skillName = zhanjue.name,
    }
  end,
})

zhanjue:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return player:getMark("@zhanjueh-phase") == "zhanjueh_aim" and skill.trueName == "slash_skill"
  end,
})

return zhanjue
