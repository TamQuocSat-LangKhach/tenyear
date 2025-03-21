local duanwan = fk.CreateSkill {
  name = "duanwan"
}

Fk:loadTranslationTable{
  ['duanwan'] = '断腕',
  ['#duanwan-invoke'] = '断腕：你可以回复体力至2点，删除现在的“叠嶂”状态！',
  ['diezhangYang'] = '叠嶂',
  ['diezhang'] = '叠嶂',
  ['diezhangYin'] = '叠嶂',
  [':duanwan'] = '限定技，当你处于濒死状态时，你可以将体力回复至2点，然后修改〖叠嶂〗：失去当前状态的效果，括号内的数字+1。',
  ['$duanwan1'] = '好你个吕奉先，竟敢卸我膀子！',
  ['$duanwan2'] = '汝这匹夫，为何往手腕上招呼？'
}

duanwan:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(duanwan) and player.dying and player:usedSkillTimes(duanwan.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = duanwan.name, prompt = "#duanwan-invoke" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover({
      who = player,
      num = math.min(2, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = duanwan.name
    })
    if not player:hasSkill(diezhang, true) then return end
    local skill = "diezhangYang"
    if player:getSwitchSkillState("diezhang", false) == fk.SwitchYang then
      skill = "diezhangYin"
    end
    room:handleAddLoseSkills(player, "-diezhang|"..skill, nil, false, true)
  end,
})

return duanwan
