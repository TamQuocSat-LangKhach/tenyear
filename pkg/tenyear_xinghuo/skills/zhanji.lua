local zhanji = fk.CreateSkill {
  name = "zhanji"
}

Fk:loadTranslationTable{
  ['zhanji'] = '展骥',
  [':zhanji'] = '锁定技，当你于出牌阶段内不因此技能摸牌后，你摸一张牌。',
  ['$zhanji1'] = '公瑾安全至吴，心安之。',
  ['$zhanji2'] = '功曹之恩，吾必有展骥之机。',
}

zhanji:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zhanji.name) and player.phase == Player.Play then
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonDraw and move.skillName ~= zhanji.name then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, zhanji.name)
  end,
})

return zhanji
