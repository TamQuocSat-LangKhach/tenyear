local yixian = fk.CreateSkill {
  name = "yixian",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["yixian"] = "义贤",
  [":yixian"] = "限定技，出牌阶段，你可以选择：1.获得场上的所有装备牌，你对以此法被你获得牌的角色依次可以令其摸等量的牌并回复1点体力；"..
  "2.获得弃牌堆中的所有装备牌。",

  ["#yixian"] = "义贤：选择一项",
  ["yixian_field"] = "获得场上的装备牌",
  ["yixian_discard"] = "获得弃牌堆里的装备牌",
  ["#yixian-repay"] = "义贤：是否令 %dest 摸%arg张牌并回复1点体力？",

  ["$yixian1"] = "春秋着墨十万卷，长髯映雪千里行。",
  ["$yixian2"] = "义驱千里长路，风起桃园芳菲。",
}

yixian:addEffect("active", {
  anim_type = "control",
  prompt = "#yixian",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(yixian.name, Player.HistoryGame) == 0
  end,
  interaction = UI.ComboBox { choices = { "yixian_field", "yixian_discard" } },
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    if self.interaction.data == "yixian_field" then
      local dat = {}
      local cards = {}
      local equips = {}
      for _, p in ipairs(room.alive_players) do
        equips = p:getCardIds("e")
        if #equips > 0 then
          dat[p.id] = #equips
          table.insertTable(cards, equips)
        end
      end
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, yixian.name, nil, false, player)
      if player.dead then return end
      for _, p in ipairs(room:getAlivePlayers()) do
        if not p.dead then
          local n = dat[p.id]
          if n and n > 0 and room:askToSkillInvoke(player, {
            skill_name = yixian.name,
            prompt = "#yixian-repay::"..p.id..":"..n,
          }) then
            p:drawCards(n, yixian.name)
            if not p.dead and p:isWounded() then
              room:recover{
                who = p,
                num = 1,
                recoverBy = player,
                skillName = yixian.name,
              }
            end
            if player.dead then break end
          end
        end
      end
    elseif self.interaction.data == "yixian_discard" then
      local equips = table.filter(room.discard_pile, function(id)
        return Fk:getCardById(id).type == Card.TypeEquip
      end)
      if #equips > 0 then
        room:moveCardTo(equips, Card.PlayerHand, player, fk.ReasonPrey, yixian.name, nil, false, player)
      end
    end
  end,
})

return yixian
