local zhanjue = fk.CreateSkill {
  name = "ty_god__zhanjue"
}

Fk:loadTranslationTable{
  ['ty_god__zhanjue'] = '斩决',
  ['ty_god__zhanjue_hp'] = '摸体力值数量的牌，令你此阶段下一张【杀】无距离限制且不可被响应',
  ['ty_god__zhanjue_losthp'] = '摸已损失体力值数量的牌，令你此阶段下一次造成伤害后回复等量体力',
  ['@ty_god__zhanjue-phase'] = '斩决',
  ['ty_god__zhanjue_aim'] = '强中',
  ['ty_god__zhanjue_recover'] = '吸血',
  ['#ty_god__zhanjue_buff'] = '斩决',
  [':ty_god__zhanjue'] = '出牌阶段开始时，你可以选择一项：1.摸体力值数量的牌，令你此阶段使用下一张【杀】无距离限制且不可被响应；2.摸已损失体力值数量的牌，令你于此阶段下一次造成伤害后回复等量体力。',
  ['$ty_god__zhanjue1'] = '流不尽的英雄血，斩不尽的逆贼头！',
  ['$ty_god__zhanjue2'] = '长刀渴血，当饲英雄胆！'
}

-- 主技能效果
zhanjue:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:hasSkill(zhanjue.name)
  end,
  on_cost = function (self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = { "ty_god__zhanjue_hp", "ty_god__zhanjue_losthp", "Cancel" },
      skill_name = zhanjue.name
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self) == "ty_god__zhanjue_hp" then
      player:drawCards(player.hp, zhanjue.name)
      room:setPlayerMark(player, "@ty_god__zhanjue-phase", "ty_god__zhanjue_aim")
    else
      player:drawCards(player:getLostHp(), zhanjue.name)
      room:setPlayerMark(player, "@ty_god__zhanjue-phase", "ty_god__zhanjue_recover")
    end
  end,
})

-- buff效果
zhanjue:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and player:getMark("@ty_god__zhanjue-phase") == "ty_god__zhanjue_aim"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ty_god__zhanjue-phase", 0)
    data.disresponsiveList = table.map(room.players, Util.IdMapper)
  end,
})

-- 恢复效果
zhanjue:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@ty_god__zhanjue-phase") == "ty_god__zhanjue_recover"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ty_god__zhanjue-phase", 0)
    room:recover{
      who = player,
      num = data.damage,
      recoverBy = player,
      skillName = "ty_god__zhanjue",
    }
  end,
})

-- 目标修正效果
zhanjue:addEffect('targetmod', {
  bypass_distances = function(self, player, skill, card)
    return player:getMark("@ty_god__zhanjue-phase") == "ty_god__zhanjue_aim" and skill.trueName == "slash_skill"
  end,
})

return zhanjue
