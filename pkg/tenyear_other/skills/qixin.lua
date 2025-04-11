local qixin = fk.CreateSkill {
  name = "qixin",
  tags = { Skill.Switch }
}

Fk:loadTranslationTable{
  ["qixin"] = "齐心",
  [":qixin"] = "转换技，出牌阶段，你可以：阳，将性别变为女性，然后将体力值调整为“齐心”记录的数值并记录调整前的体力；阴，将性别变为男性，"..
  "然后将体力调整为“齐心”记录的数值并记录调整前的体力。<br>"..
  "隐藏效果：当你获得此技能时，记录你的体力上限并将你的性别改为男性；当濒死求桃结束后，若你仍处于濒死状态且“齐心”记录的数值大于0，"..
  "则你将体力调整至记录的数值且清除此记录，将你的性别改为异性，“齐心”失效。",
}

qixin:addEffect("active", {
  anim_type = "switch",
  prompt = "#qixin",
  card_num = 0,
  target_num = 0,
  switch_skill_name = qixin.name,
  can_use = function(self, player)
    return player:getMark("qixin_fail-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:setPlayerMark(player, "qixin_fail-phase", 1)
    local gender = player:getSwitchSkillState(qixin.name, true) == fk.SwitchYin and General.Male or General.Female
    room:setPlayerProperty(player, "gender", gender)
    room:setPlayerMark(player, "@!qixi_" .. (gender == General.Male and "male" or "female"), 1)
    room:setPlayerMark(player, "@!qixi_" .. (gender == General.Male and "female" or "male"), 0)

    local hp = player:getMark("qixin_restore")
    room:setPlayerMark(player, "qixin_restore", player.hp)
    room:changeHp(player, hp - player.hp)
  end,
})

qixin:addEffect(fk.AskForPeachesDone, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.dying and player:getMark("qixin_restore") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local gender = player:getSwitchSkillState(qixin.name, false) == fk.SwitchYin and General.Male or General.Female
    room:setPlayerProperty(player, "gender", gender)
    room:setPlayerMark(player, "@!qixi_" .. (gender == General.Male and "male" or "female"), 1)
    room:setPlayerMark(player, "@!qixi_" .. (gender == General.Male and "female" or "male"), 0)

    local hp = player:getMark("qixin_restore")
    room:setPlayerMark(player, "qixin_restore", 0)
    room:invalidateSkill(player, qixin.name)
    room:changeHp(player, hp - player.hp)
  end,
})

qixin:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "qixin_fail-phase", 0)
  end,
})

qixin:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  room:setPlayerMark(player, "qixin_restore", player.maxHp)
  room:setPlayerProperty(player, "gender", General.Male)
  room:setPlayerMark(player, "@!qixi_male", 1)
end)

qixin:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "qixin_restore", 0)
end)

return qixin
