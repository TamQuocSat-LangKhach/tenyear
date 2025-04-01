local lundao = fk.CreateSkill {
  name = "lundao",
}

Fk:loadTranslationTable{
  ["lundao"] = "论道",
  [":lundao"] = "当你受到伤害后，若伤害来源的手牌多于你，你可以弃置其一张牌；若伤害来源的手牌数少于你，你摸一张牌。",

  ["#lundao-invoke"] = "论道：你可以弃置 %dest 一张牌",
}

lundao:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lundao.name) and
      data.from and not data.from.dead and
      data.from:getHandcardNum() ~= player:getHandcardNum()
  end,
  on_cost = function(self, event, target, player, data)
    if data.from:getHandcardNum() > player:getHandcardNum() then
      local room = player.room
      if room:askToSkillInvoke(player, {
        skill_name = lundao.name,
        prompt = "#lundao-invoke::" .. data.from.id,
      }) then
        event:setCostData(self, {tos = {data.from}})
        return true
      end
    else
      event:setCostData(self, nil)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from:getHandcardNum() > player:getHandcardNum() then
      local id = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = lundao.name,
      })
      room:throwCard(id, lundao.name, data.from, player)
    else
      player:drawCards(1, lundao.name)
    end
  end,
})

return lundao
