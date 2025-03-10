local yixian = fk.CreateSkill {
  name = "yixian"
}

Fk:loadTranslationTable{
  ['yixian'] = '义贤',
  ['yixian_field'] = '获得场上的装备牌',
  ['yixian_discard'] = '获得弃牌堆里的装备牌',
  ['#yixian-active'] = '发动 义贤，%arg',
  ['#yixian-repay'] = '义贤：是否令%dest摸%arg张牌并回复1点体力',
  [':yixian'] = '限定技，出牌阶段，你可以选择：1.获得场上的所有装备牌，你对以此法被你获得牌的角色依次可以令其摸等量的牌并回复1点体力；2.获得弃牌堆中的所有装备牌。',
  ['$yixian1'] = '春秋着墨十万卷，长髯映雪千里行。',
  ['$yixian2'] = '义驱千里长路，风起桃园芳菲。',
}

yixian:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(yixian.name, Player.HistoryGame) == 0
  end,
  interaction = function()
    return UI.ComboBox {
      choices = { "yixian_field", "yixian_discard" }
    }
  end,
  prompt = function(self, player)
    return "#yixian-active:::" .. self.interaction.data
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "yixian_field" then
      local yixianmap = {}
      local cards = {}
      local equips = {}
      for _, p in ipairs(room.alive_players) do
        equips = p:getCardIds{Player.Equip}
        if #equips > 0 then
          yixianmap[p.id] = #equips
          table.insertTable(cards, equips)
        end
      end
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, yixian.name, nil, false, player.id)
      if player.dead then return end
      for _, p in ipairs(room:getAlivePlayers()) do
        if not p.dead then
          local n = yixianmap[p.id]
          if n and n > 0 and room:askToSkillInvoke(player, { skill_name = yixian.name, prompt = "#yixian-repay::" .. p.id..":"..tostring(n) }) then
            room:drawCards(p, n, yixian.name)
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
        room:moveCardTo(equips, Card.PlayerHand, player, fk.ReasonPrey, yixian.name, nil, false, player.id)
      end
    end
  end,
})

return yixian
