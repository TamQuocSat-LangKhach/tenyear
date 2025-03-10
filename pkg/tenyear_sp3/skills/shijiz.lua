local shijiz = fk.CreateSkill {
  name = "shijiz"
}

Fk:loadTranslationTable{
  ['shijiz'] = '十计',
  ['@$shijiz-round'] = '十计',
  ['#shijiz-invoke'] = '十计：选择一种锦囊，%dest 可将一张牌当此牌使用(不能指定其为目标)',
  ['shijiz_viewas'] = '十计',
  ['#shijiz-use'] = '十计：你可以将一张牌当【%arg】使用',
  [':shijiz'] = '一名角色的结束阶段，若其本回合未造成伤害，你可以声明一种普通锦囊牌（每轮每种牌名限一次），其可以将一张牌当你声明的牌使用（不能指定其为目标）。',
  ['$shijiz1'] = '哼~区区十丈之城，何须丞相图画。',
  ['$shijiz2'] = '顽垒在前，可依不疑之计施为。',
}

shijiz:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target)
    if target.phase == Player.Finish and not target:isNude() then
      return #target.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == target end) == 0
    end
  end,
  on_cost = function(self, event, target)
    local room = target.room
    local mark = target:getMark("shijiz_names")
    if type(mark) ~= "table" then
      mark = U.getAllCardNames("t")
      room:setPlayerMark(target, "shijiz_names", mark)
    end
    local used = target:getTableMark("@$shijiz-round")
    local all_names, names = {}, {}
    for _, name in ipairs(mark) do
      local card = Fk:cloneCard(name)
      card.skillName = shijiz.name
      if target:canUse(card) and not target:prohibitUse(card) then
        table.insert(all_names, name)
        if not table.contains(used, name) then
          table.insert(names, name)
        end
      end
    end
    local choices = U.askForChooseCardNames(room, target, names, 1, 1, shijiz.name, "#shijiz-invoke::"..target.id, all_names, true)
    if #choices == 1 then
      event:setCostData(self, {tos = {target.id}, choice = choices[1]})
      return true
    end
  end,
  on_use = function(self, event, target)
    local room = target.room
    local cardName = event:getCostData(self).choice
    room:addTableMark(target, "@$shijiz-round", cardName)
    local success, dat = room:askToUseActiveSkill(target, {
      skill_name = "shijiz_viewas",
      prompt = "#shijiz-use:::"..cardName,
      cancelable = true,
      extra_data = {shijiz_name = cardName},
    })
    if dat then
      local card = Fk:cloneCard(cardName)
      card:addSubcards(dat.cards)
      card.skillName = shijiz.name
      room:useCard{
        from = target.id,
        tos = table.map(dat.targets, function(p) return {p} end),
        card = card,
      }
    end
  end,
})

shijiz_prohibit = fk.CreateSkill {
  name = "#shijiz_prohibit"
}

shijiz_prohibit:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    return card and from == to and table.contains(card.skillNames, "shijiz")
  end,
})

return shijiz
