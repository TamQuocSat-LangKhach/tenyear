local moyu = fk.CreateSkill {
  name = "moyu"
}

Fk:loadTranslationTable{
  ['moyu'] = '没欲',
  ['#moyu-active'] = '发动 没欲，选择1名角色，获得其区域里的%arg张牌',
  ['@@moyu1-phase'] = '没欲强化',
  ['#moyu-slash'] = '没欲：你可以对 %dest 使用一张【杀】',
  [':moyu'] = '出牌阶段，你可以获得一名此阶段内未选择过的一名其他角色区域里的一张牌，然后该角色可以对你使用一张【杀】（无距离限制），若此【杀】：未对你造成过伤害，你于此阶段内下次发动此技能改为获得两张牌；对你造成过伤害，此技能于此回合内无效。',
  ['$moyu1'] = '人之所有，我之所欲。',
  ['$moyu2'] = '胸有欲壑千丈，自当饥不择食。',
}

moyu:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = function(self, player)
    return "#moyu-active:::" .. tostring((player:getMark("@@moyu1-phase") > 0) and 2 or 1)
  end,
  can_use = Util.TrueFunc,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and not table.contains(player:getTableMark("moyu_targets-phase"), to_select) and
      #Fk:currentRoom():getPlayerById(to_select):getCardIds("hej") > player:getMark("@@moyu1-phase")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "moyu_targets-phase", target.id)
    local x = 1
    if player:getMark("@@moyu1-phase") > 0 then
      x = 2
      room:setPlayerMark(player, "@@moyu1-phase", 0)
    end
    local ids = room:askToChooseCards(player, {
      target = target,
      min = x,
      max = x,
      flag = "hej",
      skill_name = moyu.name
    })
    room:obtainCard(player.id, ids, false, fk.ReasonPrey)
    if target.dead then return end
    local use = room:askToUseCard(target, {
      pattern = "slash",
      prompt = "#moyu-slash::" .. player.id,
      cancelable = true,
      extra_data = {must_targets = {player.id}, bypass_distances = true, bypass_times = true}
    })
    if use then
      room:useCard(use)
      if player.dead then return end
      if use.damageDealt and use.damageDealt[player.id] then
        room:invalidateSkill(player, moyu.name, "-turn")
      else
        room:setPlayerMark(player, "@@moyu1-phase", 1)
      end
    end
  end,
})

return moyu
