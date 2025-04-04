local cuoruiw = fk.CreateSkill {
  name = "cuoruiw",
}

Fk:loadTranslationTable{
  ["cuoruiw"] = "挫锐",
  [":cuoruiw"] = "出牌阶段开始时，你可以弃置一名你计算与其距离不大于1的角色区域里的一张牌。若如此做，你选择一项："..
  "1.弃置另一名其他角色装备区里至多两张与此牌颜色相同的牌；2.展示另一名其他角色的至多两张手牌，然后获得其中与此牌颜色相同的牌。",

  ["#cuoruiw-choose"] = "挫锐：你可以弃置距离不大于1的角色区域里的一张牌",
  ["#cuoruiw-use"] = "挫锐：选择另一名角色，弃置其装备区至多两张%arg牌，或展示其至多两张手牌",
  ["cuoruiw_equip"] = "弃置其至多两张颜色相同的装备",
  ["cuoruiw_hand"] = "展示其至多两张手牌并获得其中相同颜色牌",
  ["#cuoruiw-throw"] = "挫锐：弃置其至多两张装备牌",

  ["$cuoruiw1"] = "减辎疾行，挫敌军锐气。",
  ["$cuoruiw2"] = "外物当舍，摄敌为重。",
}

cuoruiw:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(cuoruiw.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return player:distanceTo(p) < 2 and not p:isAllNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return player:distanceTo(p) < 2 and not p:isAllNude()
    end)
    if not table.find(player:getCardIds("hej"), function (id)
      return not player:prohibitDiscard(id)
    end) then
      table.removeOne(targets, player)
    end
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#cuoruiw-choose",
        skill_name = cuoruiw.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    else
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = cuoruiw.name,
        pattern = "false",
        prompt = "#cuoruiw-choose",
        cancelable = true,
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id1
    if to == player then
      local ids = table.filter(player:getCardIds("hej"), function (id)
        return not player:prohibitDiscard(id)
      end)
      id1 = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = cuoruiw.name,
        pattern = tostring(Exppattern{ id = ids }),
        cancelable = false,
        expand_pile = player:getCardIds("j"),
      })[1]
    else
      id1 = room:askToChooseCard(player, {
        target = to,
        flag = "hej",
        skill_name = cuoruiw.name,
      })
    end
    local color = Fk:getCardById(id1).color
    room:throwCard(id1, cuoruiw.name, to, player)
    if player.dead then return end

    local targets, targets1, targets2 = {}, {}, {}
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p ~= to then
        if not p:isKongcheng() then
          table.insertIfNeed(targets, p)
          table.insert(targets2, p)
        end
        if table.find(p:getCardIds("e"), function(id)
          return Fk:getCardById(id).color == color
        end) then
          table.insertIfNeed(targets, p)
          table.insert(targets1, p)
        end
      end
    end
    if #targets == 0 then return end
    to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#cuoruiw-use:::"..Fk:getCardById(id1):getColorString(),
      skill_name = cuoruiw.name,
      cancelable = false,
    })[1]

    local choices = {}
    if table.contains(targets1, to) then
      table.insert(choices, "cuoruiw_equip")
    end
    if table.contains(targets2, to) then
      table.insert(choices, "cuoruiw_hand")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = cuoruiw.name,
    })
    if choice == "cuoruiw_equip" then
      local cards = table.filter(to:getCardIds("e"), function(id)
        return Fk:getCardById(id).color == color
      end)
      cards = room:askToChooseCards(player, {
        target = to,
        min = 1,
        max = 2,
        flag = { card_data = { { to.general, cards }  } },
        skill_name = cuoruiw.name,
        prompt = "#cuoruiw-throw",
      })
      room:throwCard(cards, cuoruiw.name, to, player)
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
        return Fk:getCardById(id).color == color and table.contains(to:getCardIds("h"), id)
      end)
      if #cards > 0 and not player.dead then
        room:obtainCard(player, cards, false, fk.ReasonPrey, player, cuoruiw.name)
      end
    end
  end,
})

return cuoruiw
