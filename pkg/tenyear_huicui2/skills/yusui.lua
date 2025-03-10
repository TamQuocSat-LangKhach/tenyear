local yusui = fk.CreateSkill {
  name = "yusui"
}

Fk:loadTranslationTable{
  ['yusui'] = '玉碎',
  ['yusui_discard'] = '令其弃置手牌至与你相同',
  ['yusui_loseHp'] = '令其失去体力值至与你相同',
  [':yusui'] = '每回合限一次，当你成为其他角色使用黑色牌的目标后，你可以失去1点体力，然后选择一项：1.令其弃置手牌至与你相同；2.令其失去体力值至与你相同。',
  ['$yusui1'] = '宁为玉碎，不为瓦全！',
  ['$yusui2'] = '生义相左，舍生取义。',
}

yusui:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yusui.name) and data.from ~= player.id and data.card.color == Card.Black and
      player:usedSkillTimes(yusui.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    room:loseHp(player, 1, yusui.name)
    if player.dead or to.dead then return end
    local choices = {}
    if #to.player_cards[Player.Hand] > #player.player_cards[Player.Hand] then
      table.insert(choices, "yusui_discard")
    end
    if to.hp > player.hp then
      table.insert(choices, "yusui_loseHp")
    end
    if #choices > 0 then
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = yusui.name
      })
      if choice == "yusui_discard" then
        local n = #to.player_cards[Player.Hand] - #player.player_cards[Player.Hand]
        room:askToDiscard(to, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = yusui.name,
          cancelable = false
        })
      else
        room:loseHp(to, to.hp - player.hp, yusui.name)
      end
    end
  end,
})

return yusui
