local cuoruiw = fk.CreateSkill {
  name = "cuoruiw"
}

Fk:loadTranslationTable{
  ['cuoruiw'] = '挫锐',
  ['#cuoruiw-cost'] = '挫锐：你可以弃置距离不大于1的角色区域里的一张牌',
  ['#cuoruiw-use'] = '挫锐：选择另一名其他角色，弃置其装备区至多两张%arg牌，或展示其至多两张手牌',
  ['cuoruiw_equip'] = '弃置其至多两张颜色相同的装备',
  ['cuoruiw_hand'] = '展示其至多两张手牌并获得其中相同颜色牌',
  ['#cuoruiw-throw'] = '挫锐：弃置其至多两张装备牌',
  [':cuoruiw'] = '出牌阶段开始时，你可以弃置一名你计算与其距离不大于1的角色区域里的一张牌。若如此做，你选择一项：1.弃置另一名其他角色装备区里至多两张与此牌颜色相同的牌；2.展示另一名其他角色的至多两张手牌，然后获得其中与此牌颜色相同的牌。',
  ['$cuoruiw1'] = '减辎疾行，挫敌军锐气。',
  ['$cuoruiw2'] = '外物当舍，摄敌为重。',
}

cuoruiw:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(cuoruiw.name) and player.phase == Player.Play
      and table.find(player.room.alive_players, function(p) return player:distanceTo(p) < 2 and not p:isAllNude() end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if player:distanceTo(p) < 2 and not p:isAllNude() then
        table.insert(targets, p.id)
      end
    end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#cuoruiw-cost",
      skill_name = cuoruiw.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local chosen = room:askToChooseCard(player, {
      target = room:getPlayerById(event:getCostData(self)),
      flag = "hej",
      skill_name = cuoruiw.name,
    })
    local color = Fk:getCardById(chosen).color
    room:throwCard({chosen}, cuoruiw.name, room:getPlayerById(event:getCostData(self)), player)
    if player.dead then return end
    local targets = {}
    local targets1 = {}
    local targets2 = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.id ~= event:getCostData(self) then
        if not p:isKongcheng() then
          table.insertIfNeed(targets, p.id)
          table.insert(targets2, p.id)
        end
        if #p.player_cards[Player.Equip] > 0 then
          if table.find(p:getCardIds("e"), function(id) return Fk:getCardById(id).color == color end) then
            table.insertIfNeed(targets, p.id)
            table.insert(targets1, p.id)
          end
        end
      end
    end
    if #targets == 0 then return end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#cuoruiw-use:::"..Fk:getCardById(chosen):getColorString(),
      skill_name = cuoruiw.name,
    })
    local to = room:getPlayerById(tos[1])
    local choices = {}
    if table.contains(targets1, to.id) then
      table.insert(choices, "cuoruiw_equip")
    end
    if table.contains(targets2, to.id) then
      table.insert(choices, "cuoruiw_hand")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = cuoruiw.name,
    })
    if choice == "cuoruiw_equip" then
      local ids = table.filter(to:getCardIds("e"), function(id) return Fk:getCardById(id).color == color end)
      local throw = room:askToChooseCards(player, {
        target = to,
        min = 1,
        max = 2,
        flag = { card_data = { { to.general, ids }  } },
        skill_name = cuoruiw.name,
        prompt = "#cuoruiw-throw",
      })
      room:throwCard(throw, cuoruiw.name, to, player)
    else
      local cards = room:askToChooseCards(player, {
        target = to,
        min = 1,
        max = 2,
        flag = "h",
        skill_name = cuoruiw.name,
      })
      to:showCards(cards)
      room:delay(1000)
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).color == color
      end)
      if #cards > 0 then
        room:obtainCard(player.id, cards, false, fk.ReasonPrey)
      end
    end
  end,
})

return cuoruiw
