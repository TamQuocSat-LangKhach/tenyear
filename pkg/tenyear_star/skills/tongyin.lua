local tongyin = fk.CreateSkill {
  name = "tongyin$"
}

Fk:loadTranslationTable{
  ['#tongyin1-invoke'] = '统荫：是否将%arg置为“匡祚”？',
  ['#tongyin2-invoke'] = '统荫：是否将 %dest 的一张牌置为“匡祚”？',
  ['#tongyin2-put'] = '统荫：将 %dest 的一张牌置为“匡祚”',
  ['kuangzuo'] = '匡祚',
}

tongyin:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tongyin.name) and data.from and data.from ~= player and data.card then
      if data.from.kingdom == player.kingdom then
        return player.room:getCardArea(data.card) == Card.Processing
      else
        return not data.from.dead and not data.from:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if data.from.kingdom == player.kingdom then
      return player.room:askToSkillInvoke(player, {
        skill_name = tongyin.name,
        prompt = "#tongyin1-invoke:::"..data.card
      })
    else
      return player.room:askToSkillInvoke(player, {
        skill_name = tongyin.name,
        prompt = "#tongyin2-invoke::"..data.from.id
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card
    if data.from.kingdom == player.kingdom then
      card = data.card
    else
      room:doIndicate(player.id, {data.from.id})
      card = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = tongyin.name,
        prompt = "#tongyin2-put::"..data.from.id
      })
    end
    player:addToPile("kuangzuo", card, true, tongyin.name, player.id)
  end,
})

return tongyin
