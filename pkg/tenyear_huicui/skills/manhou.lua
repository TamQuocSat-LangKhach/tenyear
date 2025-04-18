local manhou = fk.CreateSkill{
  name = "manhou",
}

Fk:loadTranslationTable {
  ["manhou"] = "蛮后",
  [":manhou"] = "出牌阶段限一次，你可以摸至多四张牌，依次执行前等量项：1.失去〖探乱〗；2.弃置一张手牌；3.失去1点体力并弃置场上一张牌；\
  4.弃置一张牌并获得〖探乱〗。",

  ["#manhou"] = "蛮后：你可以摸至多四张牌，依次执行等量效果",
  ["#manhou-choose"] = "蛮后：选择一名角色，弃置其场上一张牌",

  ["$manhou1"] = "既为蛮王之妻，当彰九黎之仪。",
  ["$manhou2"] = "君行役四海，妾怎敢居后。",
}

manhou:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#manhou",
  card_num = 0,
  target_num = 0,
  max_phase_use_time = 1,
  interaction = UI.Spin {
    from = 1,
    to = 4,
  },
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = self.interaction.data or 1
    player:drawCards(n, manhou.name)
    for i = 1, n, 1 do
      if player.dead then return end
      if i == 1 then
        room:handleAddLoseSkills(player, "-tanluan")
      elseif i == 2 then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = manhou.name,
          cancelable = false,
        })
      elseif i == 3 then
        room:loseHp(player, 1, manhou.name)
        if player.dead then return end
        local targets = table.filter(room.alive_players, function(p)
          return #p:getCardIds("ej") > 0
        end)
        if #targets > 0 then
          local to = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = targets,
            skill_name = manhou.name,
            prompt = "#manhou-choose",
            cancelable = false,
          })[1]
          local card = room:askToChooseCard(player, {
            target = to,
            flag = "ej",
            skill_name = manhou.name,
          })
          room:throwCard(card, manhou.name, to, player)
        end
      elseif i == 4 then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = manhou.name,
          cancelable = false,
        })
        if player.dead then return end
        room:handleAddLoseSkills(player, "tanluan")
      end
    end
  end,
})

return manhou