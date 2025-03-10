local wuwei = fk.CreateSkill {
  name = "wuwei"
}

Fk:loadTranslationTable{
  ['wuwei'] = '武威',
  ['#wuwei-active'] = '发动 武威，将一种颜色的所有手牌当【杀】使用，并根据类别数选择等量的效果',
  ['#wuwei_trigger'] = '武威',
  ['wuwei_invalidity'] = '目标非锁定技失效',
  ['wuwei_addtimes'] = '此技能发动次数+1',
  ['#wuwei-choose'] = '武威：选择一项执行（%arg/%arg2）',
  ['@@wuwei-turn'] = '武威',
  [':wuwei'] = '出牌阶段限一次，你可以将一种颜色的所有手牌当【杀】使用（无距离和次数限制），当此【杀】被使用时，你依次选择X次（X为转化前这些牌的类别数）：1.摸一张牌；2.目标角色的所有不带“锁定技”标签的技能于此回合内无效；3.此技能于此回合内发动的次数上限+1。若你选择了所有项，此【杀】的伤害值基数+1。',
  ['$wuwei1'] = '残阳洗长刀，漫卷天下帜。',
  ['$wuwei2'] = '武效万人敌，复行千里路。',
}

wuwei:addEffect('viewas', {
  anim_type = "offensive",
  prompt = "#wuwei-active",
  interaction = function(player)
    local reds, blacks = {}, {}
    local colors = {}
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local color = Fk:getCardById(id).color
      if color == Card.Red then
        table.insert(reds, id)
      elseif color == Card.Black then
        table.insert(blacks, id)
      end
    end
    if #reds > 0 then
      local card = Fk:cloneCard("slash")
      card:addSubcards(reds)
      card.skillName = "wuwei"
      if not player:prohibitUse(card) then
        table.insert(colors, "red")
      end
    end
    if #blacks > 0 then
      local card = Fk:cloneCard("slash")
      card:addSubcards(blacks)
      card.skillName = "wuwei"
      if not player:prohibitUse(card) then
        table.insert(colors, "black")
      end
    end
    return UI.ComboBox {choices = colors, all_choices = {"red", "black"}}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("slash")
    card:addSubcards(table.filter(player:getCardIds(Player.Hand), function(id)
      return Fk:getCardById(id):getColorString() == skill.interaction.data
    end))
    card.skillName = wuwei.name
    return card
  end,
  before_use = function(self, player, use)
    local types = {}
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    use.extra_data = use.extra_data or {}
    use.extra_data.wuwei_num = {player.id, #types}
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(wuwei.name, Player.HistoryPhase) <= player:getMark("wuwei_addtimes-turn") and
      not player:isKongcheng()
  end,
  times = function(self, player)
    if player.phase == Player.Play then
      return 1 + player:getMark("wuwei_addtimes-turn") - player:usedSkillTimes(wuwei.name, Player.HistoryPhase)
    end
    return -1
  end,
})

wuwei:addEffect('targetmod', {
  bypass_times = function(self, player, skill2, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, wuwei.name)
  end,
  bypass_distances = function(self, player, skill2, card)
    return card and table.contains(card.skillNames, wuwei.name)
  end,
})

wuwei:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.extra_data and data.extra_data.wuwei_num and data.extra_data.wuwei_num[1] == player.id then
      event:setCostData(skill, data.extra_data.wuwei_num[2])
      return true
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = event:getCostData(skill)
    local choices = {}
    for i = 1, x, 1 do
      local choice = room:askToChoice(player, {
        choices = {"draw1", "wuwei_invalidity", "wuwei_addtimes"},
        skill_name = wuwei.name,
        prompt = "#wuwei-choose:::" .. i .. ":" .. x
      })
      table.insertIfNeed(choices, choice)
      if choice == "draw1" then
        player:drawCards(1, wuwei.name)
        if player.dead then break end
      elseif choice == "wuwei_invalidity" then
        for _, pid in ipairs(TargetGroup:getRealTargets(data.tos)) do
          local to = room:getPlayerById(pid)
          if not to.dead then
            room:addPlayerMark(to, "@@wuwei-turn")
            room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
          end
        end
      elseif choice == "wuwei_addtimes" then
        room:addPlayerMark(player, "wuwei_addtimes-turn")
      end
    end
    if #choices == 3 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
})

return wuwei
