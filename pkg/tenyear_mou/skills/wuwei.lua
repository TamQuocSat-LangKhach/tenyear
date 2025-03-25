local wuwei = fk.CreateSkill {
  name = "wuwei",
}

Fk:loadTranslationTable{
  ["wuwei"] = "武威",
  [":wuwei"] = "出牌阶段限一次，你可以将一种颜色的所有手牌当【杀】使用（无距离次数限制）并依次选择X次（X为用于转化的类别数）："..
  "1.摸一张牌；2.目标角色本回合非锁定技失效；3.此技能本回合可发动次数+1。若执行了所有项，此【杀】伤害+1。",

  ["#wuwei"] = "武威：将一种颜色的所有手牌当【杀】使用，根据类别数执行等量的效果",
  ["wuwei_invalidity"] = "目标非锁定技失效",
  ["wuwei_addtimes"] = "此技能发动次数+1",
  ["#wuwei-choose"] = "武威：选择一项执行（第%arg次，共%arg2次）",
  ["@@wuwei-turn"] = "武威",

  ["$wuwei1"] = "残阳洗长刀，漫卷天下帜。",
  ["$wuwei2"] = "武效万人敌，复行千里路。",
}

wuwei:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#wuwei",
  times = function(self, player)
    if player.phase == Player.Play then
      return 1 + player:getMark("wuwei_addtimes-turn") - player:usedEffectTimes(wuwei.name, Player.HistoryPhase)
    end
    return -1
  end,
  interaction = function(self, player)
    local red, black = {}, {}
    local colors = {}
    for _, id in ipairs(player:getCardIds("h")) do
      local color = Fk:getCardById(id).color
      if color == Card.Red then
        table.insert(red, id)
      elseif color == Card.Black then
        table.insert(black, id)
      end
    end
    if #red > 0 and #player:getViewAsCardNames(wuwei.name, {"slash"}, red) > 0 then
      table.insert(colors, "red")
    end
    if #black > 0 and #player:getViewAsCardNames(wuwei.name, {"slash"}, black) > 0 then
      table.insert(colors, "black")
    end
    return UI.ComboBox {choices = colors, all_choices = {"red", "black"}}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("slash")
    card:addSubcards(table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getColorString() == self.interaction.data
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
    use.extra_data.wuwei = {player.id, #types}
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedEffectTimes(wuwei.name, Player.HistoryPhase) <= player:getMark("wuwei_addtimes-turn") and
      not player:isKongcheng()
  end,
})

wuwei:addEffect("targetmod", {
  bypass_times = function(self, player, skill2, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, wuwei.name)
  end,
  bypass_distances = function(self, player, skill2, card)
    return card and table.contains(card.skillNames, wuwei.name)
  end,
})

wuwei:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and data.extra_data and data.extra_data.wuwei and data.extra_data.wuwei[1] == player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = data.extra_data.wuwei[2]
    local choices = {}
    for i = 1, x, 1 do
      local choice = room:askToChoice(player, {
        choices = {"draw1", "wuwei_invalidity", "wuwei_addtimes"},
        skill_name = wuwei.name,
        prompt = "#wuwei-choose:::"..i..":"..x,
      })
      table.insertIfNeed(choices, choice)
      if choice == "draw1" then
        player:drawCards(1, wuwei.name)
        if player.dead then break end
      elseif choice == "wuwei_invalidity" then
        for _, to in ipairs(data.tos) do
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
