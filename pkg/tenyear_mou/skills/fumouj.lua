local fumouj = fk.CreateSkill {
  name = "fumouj"
}

Fk:loadTranslationTable{
  ['fumouj'] = '覆谋',
  ['#fumouj-Yang'] = '发动 覆谋（阳），观看1名其他角色的手牌，并将其中一半的牌交给另一名其他角色',
  ['#fumouj-Yin'] = '发动 覆谋（阴），观看1名其他角色的手牌，令其依次使用其中一半的牌',
  ['#fumouj-show'] = '覆谋：展示%dest的至多%arg张手牌',
  ['#fumouj-choose'] = '覆谋：选择1名其他角色，令其获得%dest展示的这些卡牌',
  ['#fumouj-use'] = '覆谋：使用 %arg（无距离限制且不能被响应）',
  ['#fumouj_switch'] = '覆谋',
  [':fumouj'] = '转换技，游戏开始时可自选阴阳状态，出牌阶段限一次，你可以观看一名其他角色的所有手牌，展示其中至多一半的牌（向上取整），阳：令另一名其他角色获得这些牌（正面朝上移动），你与失去牌的角色各摸等量张牌。阴：令其按你选择的顺序依次使用这些牌（无距离限制且不能被响应）。',
  ['$fumouj1'] = '恩仇付浊酒，荡平劫波，且做英雄吼。',
  ['$fumouj2'] = '人无恒敌，亦无恒友，唯有恒利。',
}

fumouj:addEffect('active', {
  anim_type = "switch",
  switch_skill_name = "fumouj",
  card_num = 0,
  target_num = 1,
  prompt = function (self, player)
    return player:getSwitchSkillState("fumouj", false) == fk.SwitchYang and "#fumouj-Yang" or "#fumouj-Yin"
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(fumouj.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected, selected_cards)
    return to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    setTYMouSwitchSkillState(player, "jiaxu", fumouj.name)
    local switch_state = player:getSwitchSkillState(fumouj.name, true)

    local cids = target:getCardIds(Player.Hand)
    local x = (#cids + 1) // 2
    cids = room:askToChooseCards(player, {
      min_num = 1,
      max_num = x,
      target = target,
      skill_name = fumouj.name,
      prompt = "#fumouj-show::" .. target.id .. ":" .. x,
      flag = { card_data = { { "$Hand", cids } } }
    })
    target:showCards(cids)
    room:delay(1000)

    if switch_state == fk.SwitchYang then
      local tos = {}
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p ~= target then
          table.insert(tos, p.id)
        end
      end

      if #tos == 0 then return end
      tos = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#fumouj-choose::" .. target.id,
        skill_name = fumouj.name,
        cancelable = false
      })

      if #tos == 0 then return end
      room:obtainCard(tos[1], cids, true, fk.ReasonPrey, tos[1], fumouj.name)
      x = #cids

      if not player.dead then
        player:drawCards(x, fumouj.name)
      end

      if not target.dead then
        target:drawCards(x, fumouj.name)
      end
    else
      local card
      local extra_data = { bypass_times = true, bypass_distances = true }
      local disresponsive_list = table.map(room.players, Util.IdMapper)

      for _, id in ipairs(cids) do
        if target.dead then break end

        if table.contains(target:getCardIds(Player.Hand), id) then
          card = Fk:getCardById(id)
          if U.getDefaultTargets(target, card, true, true) then
            local use = room:askToUseRealCard(target, {
              pattern = {id},
              skill_name = fumouj.name,
              prompt = "#fumouj-use:::" .. card:toLogString(),
              extra_data = extra_data,
              skip = true
            })

            if use then
              use.disresponsiveList = disresponsive_list
              room:useCard(use)
            end
          end
        end
      end
    end
  end,
})

fumouj:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fumouj.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    setTYMouSwitchSkillState(player, "jiaxu", fumouj.name,
      room:askToChoice(player, {
        choices = { "tymou_switch:::fumouj:yang", "tymou_switch:::fumouj:yin" },
        skill_name = fumouj.name,
        prompt = "#tymou_switch-transer:::fumouj"
      }) == "tymou_switch:::fumouj:yin")
  end,
})

return fumouj
