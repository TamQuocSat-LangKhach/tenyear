local chensheng = fk.CreateSkill{
  name = "chensheng",
}

Fk:loadTranslationTable{
  ["chensheng"] = "沉声",
  [":chensheng"] = "其他角色回合结束时，若你与其均不为手牌数唯一最多的角色，你摸一张牌。",

  ["$chensheng1"] = "请卿取狐狸，为天子裘。",
  ["$chensheng2"] = "朕客居许昌，唯仰丞相鼻息。",
}

chensheng:addEffect(fk.TurnEnd, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if target ~= player and player:hasSkill(chensheng.name) then
      local p = table.find(player.room.alive_players, function (p)
        return table.every(player.room.alive_players, function (q)
          return q == p or p:getHandcardNum() > q:getHandcardNum()
        end)
      end)
      return p ~= player and p ~= target
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, chensheng.name)
  end,
})

return chensheng
