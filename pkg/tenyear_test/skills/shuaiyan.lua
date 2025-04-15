local shuaiyan = fk.CreateSkill {
  name = "shuaiyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shuaiyan"] = "率言",
  [":shuaiyan"] = "锁定技，当其他角色得到或失去手牌后，若其手牌数与你相等，你弃置其一张牌或摸一张牌。",

  ["shuaiyan_discard"] = "弃置%dest一张牌",

  ["$shuaiyan1"] = "",
  ["$shuaiyan2"] = "",
}

shuaiyan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(shuaiyan.name) then
      local tos = {}
      for _, move in ipairs(data) do
        if move.from and move.from ~= player and move.from:getHandcardNum() == player:getHandcardNum() and
          not move.from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insertIfNeed(tos, move.from)
              break
            end
          end
        end
        if move.to and move.to ~= player and move.toArea == Player.Hand and
          move.to:getHandcardNum() == player:getHandcardNum() and not move.to.dead then
          table.insertIfNeed(tos, move.to)
        end
      end
      if #tos > 0 then
        event:setCostData(self, {extra_data = tos})
        return true
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(event:getCostData(self).extra_data)
    room:sortByAction(tos)
    for _, p in ipairs(tos) do
      if not player:hasSkill(shuaiyan.name) then break end
      if not p.dead then
        event:setCostData(self, {tos = {p}})
        self:doCost(event, target, player, data)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to:isNude() or room:askToChoice(player, {
      choices = {"draw1", "shuaiyan_discard::"..to.id},
      skill_name = shuaiyan.name,
    }) == "draw1" then
      player:drawCards(1, self.name)
    else
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = shuaiyan.name,
      })
      room:throwCard(card, shuaiyan.name, to, player)
    end
  end,
})

return shuaiyan
