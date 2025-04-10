local qixin = fk.CreateSkill {
  name = "qixin"
}

Fk:loadTranslationTable{
  ['qixin'] = '齐心',
  ['#qixin_trigger'] = '齐心',
  [':qixin'] = '转换技，出牌阶段，你可以：阳，将性别变为女性，然后将体力值调整为“齐心”记录的数值并记录调整前的体力；阴，将性别变为男性，然后将体力调整为“齐心”记录的数值并记录调整前的体力。<br>隐藏效果：当你获得此技能时，记录你的体力上限并将你的性别改为男性；当濒死求桃结束后，若你仍处于濒死状态且“齐心”记录的数值大于0，则你将体力调整至记录的数值且清除此记录，将你的性别改为异性，“齐心”失效。',
}

qixin:addEffect('active', {
  anim_type = "switch",
  card_num = 0,
  target_num = 0,
  prompt = "#qixin-active",
  switch_skill_name = qixin.name,
  can_use = function(self, player)
    return player:getMark("qixinUsed-phase") == 0 and player:getMark("qixin_restore") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "qixinUsed-phase", 1)
    room:setPlayerProperty(
      player,
      "gender",
      player:getSwitchSkillState(qixin.name, true) == fk.SwitchYin and General.Male or General.Female
    )
    room:setPlayerMark(player, "@!qixi_" .. (player.gender == General.Male and "male" or "female"), 1)
    room:setPlayerMark(player, "@!qixi_" .. (player.gender == General.Male and "female" or "male"), 0)

    local hpRecord = player:getMark("qixin_restore")
    room:setPlayerMark(player, "qixin_restore", player.hp)
    room:changeHp(player, hpRecord - player.hp)
  end,
})

qixin:addEffect(fk.AskForPeachesDone, {
  mute = true,
  main_skill = qixin,
  switch_skill_name = qixin.name,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.dying and player:getMark("qixin_restore") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    room:setPlayerProperty(
      player,
      "gender",
      player:getSwitchSkillState(qixin.name, true) == fk.SwitchYin and General.Male or General.Female
    )
    room:setPlayerMark(player, "@!qixi_" .. (player.gender == General.Male and "male" or "female"), 1)
    room:setPlayerMark(player, "@!qixi_" .. (player.gender == General.Male and "female" or "male"), 0)

    local hpRecord = player:getMark("qixin_restore")
    room:setPlayerMark(player, "qixin_restore", 0)
    room:changeHp(player, hpRecord - player.hp)
  end,
})

qixin:addEffect({fk.AfterCardUseDeclared, fk.EventAcquireSkill, fk.EventLoseSkill}, {
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and player:getMark("qixinUsed-phase") > 0
    end

    return
      target == player and
      data == qixin and
      not (event == fk.EventLoseSkill and player:getMark("qixin_restore") == 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "qixin_restore", player.maxHp)
      room:setPlayerProperty(player, "gender", General.Male)
      room:setPlayerMark(player, "@!qixi_male", 1)
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "qixin_restore", 0)
    else
      room:setPlayerMark(player, "qixinUsed-phase", 0)
    end
  end,
})

return qixin
