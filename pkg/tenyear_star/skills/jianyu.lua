local jianyu = fk.CreateSkill {
  name = "jianyud",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jianyud"] = "翦羽",
  [":jianyud"] = "锁定技，其他角色于你的回合内失去装备区的牌后，你摸一张牌。",

  ["$jianyud1"] = "綝友党甚盛，当翦羽而后诛之。",
  ["$jianyud2"] = "奉虽不能吏书，犹怀一腔忠胆。",
}

jianyu:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.room.current == player then
      for _, move in ipairs(data) do
        if move.from and move.from ~= player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jianyu.name)
  end,
})

return jianyu
