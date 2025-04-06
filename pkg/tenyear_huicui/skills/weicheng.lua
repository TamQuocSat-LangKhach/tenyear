local weicheng = fk.CreateSkill {
  name = "weicheng",
}

Fk:loadTranslationTable{
  ["weicheng"] = "伪诚",
  [":weicheng"] = "其他角色获得你的手牌后，若你的手牌数小于体力值，你可以摸一张牌。",

  ["$weicheng1"] = "略施谋略，敌军便信以为真。",
  ["$weicheng2"] = "吾只观雅规，而非说客。",
}

weicheng:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(weicheng.name) and player:getHandcardNum() < player.hp then
      for _, move in ipairs(data) do
        if move.from == player and move.to and move.to ~= player and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, weicheng.name)
  end,
})

return weicheng
