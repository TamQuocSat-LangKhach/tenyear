local tongyin = fk.CreateSkill {
  name = "tongyin",
  tags = { Skill.Lord },
}

Fk:loadTranslationTable{
  ["tongyin"] = "统荫",
  [":tongyin"] = "主公技，当你受到其他角色使用牌造成的伤害后，若伤害来源与你势力相同，你可以将造成伤害的牌置为“匡祚”；若与你势力不同，"..
  "你可以将其一张牌置为“匡祚”。",

  ["#tongyin1-invoke"] = "统荫：是否将%arg置为“匡祚”？",
  ["#tongyin2-invoke"] = "统荫：是否将 %dest 的一张牌置为“匡祚”？",
  ["#tongyin2-put"] = "统荫：将 %dest 的一张牌置为“匡祚”",
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
      if player.room:askToSkillInvoke(player, {
        skill_name = tongyin.name,
        prompt = "#tongyin2-invoke::"..data.from.id,
      }) then
        event:setCostData(self, {tos = {data.from}})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card
    if data.from.kingdom == player.kingdom then
      card = data.card
    else
      card = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = tongyin.name,
        prompt = "#tongyin2-put::"..data.from.id,
      })
    end
    player:addToPile("kuangzuo", card, true, tongyin.name, player)
  end,
})

return tongyin
