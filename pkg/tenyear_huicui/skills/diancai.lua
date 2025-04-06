local diancai = fk.CreateSkill {
  name = "ty__diancai",
}

Fk:loadTranslationTable{
  ["ty__diancai"] = "典财",
  [":ty__diancai"] = "其他角色出牌阶段结束时，若你此阶段失去了至少X张牌，你可以将手牌摸至体力上限（X为你的体力值，至多为5），"..
  "然后你可以发动一次〖调度〗。",

  ["$ty__diancai1"] = "量入为出，利析秋毫。",
  ["$ty__diancai2"] = "天下熙攘，皆为利往。",
}

diancai:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(diancai.name) and target ~= player and target.phase == Player.Play and
      player:getHandcardNum() < player.maxHp then
      local num = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player and ((move.to and move.to ~= player) or
            not table.contains({Card.PlayerHand, Card.PlayerEquip}, move.toArea)) then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                num = num + 1
                if num > 5 then
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryPhase)
      return num >= math.min(player.hp, 5)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(player.maxHp - player:getHandcardNum(), diancai.name)
    if not player.dead and table.find(room.alive_players, function(p)
      return player:distanceTo(p) <= 1 and #p:getCardIds("e") > 0
    end) then
      Fk.skills["ty__diaodu"]:doCost(event, target, player, data)
    end
  end,
})

return diancai
