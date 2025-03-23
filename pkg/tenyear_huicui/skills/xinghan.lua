local xinghan = fk.CreateSkill {
  name = "xinghan"
}

Fk:loadTranslationTable{
  ['xinghan'] = '兴汉',
  ['@zhenge'] = '枕戈',
  [':xinghan'] = '锁定技，当〖枕戈〗选择过的角色使用【杀】造成伤害后，若此【杀】是本回合的第一张【杀】，你摸一张牌。若你的手牌数不是全场唯一最多，则改为摸X张牌（X为该角色的攻击范围且最多为5）。',
  ['$xinghan1'] = '汉之兴旺，不敢松懈。',
  ['$xinghan2'] = '兴汉除贼，吾之所愿。',
}

xinghan:addEffect(fk.Damage, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xinghan.name) and target and target:getMark("@zhenge") > 0 and
      data.card and data.card.trueName == "slash" then
      local room = player.room
      local logic = room.logic
      local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if use_event == nil then return false end
      local mark = player:getMark("xinghan_record-turn")
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data[1]
          if last_use.card.trueName == "slash" then
            mark = e.id
            room:setPlayerMark(player, "xinghan_record-turn", mark)
            return true
          end
          return false
        end, Player.HistoryTurn)
      end
      return mark == use_event.id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if table.find(room:getOtherPlayers(player), function(p)
      return p:getHandcardNum() >= player:getHandcardNum()
    end) then
      player:drawCards(math.min(target:getAttackRange(), 5), xinghan.name)
    else
      player:drawCards(1, xinghan.name)
    end
  end,
})

return xinghan
