local zunwei = fk.CreateSkill {
  name = "zunwei",
  dynamic_desc = function (self, player)
    if #player:getTableMark(self.name) == 3 then
      return "dummyskill"
    else
      local choices = {}
      for i = 1, 3, 1 do
        if not table.contains(player:getTableMark(self.name), "zunwei"..i) then
          table.insert(choices, Fk:translate("zunwei"..i))
        else
          table.insert(choices, "<font color=\'gray\'>"..Fk:translate("zunwei"..i).."</font>")
        end
      end
      return "zunwei_inner:"..table.concat(choices, "；")
    end
  end,
}

Fk:loadTranslationTable{
  ["zunwei"] = "尊位",
  [":zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，选择执行以下一项，然后移除该选项：1.将手牌数摸至与该角色相同（最多摸五张）；"..
  "2.随机使用牌堆中的装备牌至与该角色相同；3.将体力回复至与该角色相同。",

  [":zunwei_inner"] = "出牌阶段限一次，你可以选择一名其他角色，选择执行以下一项，然后移除该选项：{1}。",

  ["#zunwei"] = "尊位：选择一名其他角色并执行一项效果",
  ["zunwei1"] = "将手牌摸至与其相同（最多摸五张）",
  ["zunwei2"] = "随机使用装备牌至与其相同",
  ["zunwei3"] = "回复体力至与其相同",

  ["$zunwei1"] = "处尊居显，位极椒房。",
  ["$zunwei2"] = "自在东宫，及即尊位。",
}

zunwei:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, zunwei.name, 0)
end)

zunwei:addEffect("active", {
  anim_type = "control",
  prompt = "#zunwei",
  card_num = 0,
  target_num = 1,
  interaction = function(self, player)
    local choices, all_choices = {}, {}
    for i = 1, 3 do
      local choice = "zunwei"..i
      table.insert(all_choices, choice)
      if not table.contains(player:getTableMark(zunwei.name), choice) then
        table.insert(choices, choice)
      end
    end
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(zunwei.name, Player.HistoryPhase) == 0 and
      table.find({1, 2, 3}, function (i)
        return not table.contains(player:getTableMark(zunwei.name), "zunwei"..i)
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return self.interaction.data and #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choice = self.interaction.data
    room:addTableMark(player, zunwei.name, choice)
    if choice == "zunwei1" then
      local x = math.min(target:getHandcardNum() - player:getHandcardNum(), 5)
      if x > 0 then
        player:drawCards(x, zunwei.name)
      end
    elseif choice == "zunwei2" then
      local subtypes = {
        Card.SubtypeWeapon,
        Card.SubtypeArmor,
        Card.SubtypeDefensiveRide,
        Card.SubtypeOffensiveRide,
        Card.SubtypeTreasure
      }
      local subtype
      local cards = {}
      local card
      while not (player.dead or target.dead) and #player:getCardIds("e") < #target:getCardIds("e") do
        while #subtypes > 0 do
          subtype = table.remove(subtypes, 1)
          if player:hasEmptyEquipSlot(subtype) then
            cards = table.filter(room.draw_pile, function (id)
              card = Fk:getCardById(id)
              return card.sub_type == subtype and player:canUseTo(card, player)
            end)
            if #cards > 0 then
              room:useCard{
                from = player,
                tos = {player},
                card = Fk:getCardById(cards[math.random(1, #cards)]),
              }
              break
            end
          end
        end
        if #subtypes == 0 then break end
      end
    elseif choice == "zunwei3" and player:isWounded() then
      local x = target.hp - player.hp
      if x > 0 then
        room:recover{
          who = player,
          num = math.min(player.maxHp - player.hp, x),
          recoverBy = player,
          skillName = zunwei.name,
        }
      end
    end
  end,
})

return zunwei
