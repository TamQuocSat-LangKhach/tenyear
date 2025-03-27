local qingtan = fk.CreateSkill {
  name = "qingtan"
}

Fk:loadTranslationTable{
  ['qingtan'] = '清谈',
  ['#qingtan'] = '清谈：所有角色展示一张手牌，你获得其中一种花色的牌，弃置其余牌',
  ['#qingtan-card'] = '清谈：请展示一张手牌',
  ['#qingtan-get'] = '清谈：选择获得其中一种花色的牌',
  [':qingtan'] = '出牌阶段限一次，你可令所有角色同时选择一张手牌并展示。你可以获得其中一种花色的牌，然后展示此花色牌的角色各摸一张牌。弃置其余的牌。',
  ['$qingtan1'] = '事而为事，由无以成。',
  ['$qingtan2'] = '转蓬去其根，流飘从风移。',
}

qingtan:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#qingtan",
  can_use = function(self, player)
    return player:usedSkillTimes(qingtan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() end)
    if #targets == 0 then return end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local result = room:askToCardsChosen(targets, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = qingtan.name,
      pattern = ".|.|.|hand",
      prompt = "#qingtan-card"
    })
    local cards = {}
    for pid, cds in pairs(result) do
      local p = room:getPlayerById(pid)
      if table.contains(p:getCardIds("h"), cds[1]) then
        p:showCards(cds)
        table.insert(cards, cds[1])
      end
    end
    if player.dead or #cards == 0 then return end
    local suits = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(suits, Fk:getCardById(id):getSuitString(true))
    end
    local _, choice = room:askToChooseCardsAndChoices(player, {
      cards = cards,
      choices = suits,
      skill_name = qingtan.name,
      prompt = "#qingtan-get",
      all_choices = {"Cancel"},
      min_num = 0,
      max_num = 0
    })
    if choice ~= "Cancel" then
      for _, p in ipairs(targets) do
        if not player.dead and not p.dead then
          local id = result[p.id][1]
          if Fk:getCardById(id):getSuitString(true) == choice and table.contains(p:getCardIds("h"), id) then
            table.removeOne(cards, id)
            if p ~= player then
              room:obtainCard(player, id, true, fk.ReasonPrey)
            end
            if not p.dead then
              p:drawCards(1, qingtan.name)
            end
          end
        end
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        local id = result[p.id][1]
        if table.contains(p:getCardIds("h"), id) and table.contains(cards, id) then
          room:throwCard({id}, qingtan.name, p, player)
        end
      end
    end
  end,
})

return qingtan
