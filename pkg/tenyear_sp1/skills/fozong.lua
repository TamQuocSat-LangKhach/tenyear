local fozong = fk.CreateSkill {
  name = "fozong"
}

Fk:loadTranslationTable{
  ['fozong'] = '佛宗',
  ['#fozong-card'] = '佛宗：将 %arg 张手牌置于武将牌上',
  ['fozong_get'] = '获得此牌并令其回复体力',
  ['#fozong-choice'] = '佛宗：选择令 %src 执行的一项',
  ['fozong_lose'] = '令其失去体力',
  [':fozong'] = '锁定技，出牌阶段开始时，若你的手牌多于七张，你将超出数量的手牌置于武将牌上，然后若你武将牌上有至少七张牌，其他角色依次选择一项：1.获得其中一张牌并令你回复1点体力；2.令你失去1点体力。',
  ['$fozong1'] = '此身无长物，愿奉骨肉为浮屠。',
  ['$fozong2'] = '驱大白牛车，颂无上功德。',
}

fozong:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Compulsory,
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fozong.name) and player.phase == Player.Play and player:getHandcardNum() > 7
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum() - 7
    local cards_to_move = room:askToCards(player, {
      min_num = n,
      max_num = n,
      include_equip = false,
      pattern = ".",
      prompt = "#fozong-card:::" .. n,
    })

    if #cards_to_move > 0 then
      room:moveCardTo(cards_to_move, Card.PlayerSpecial, player, fk.ReasonJustMove, fozong.name, fozong.name, true)
    end

    if #player:getPile(fozong.name) < 7 then return false end

    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then break end
      if not p.dead then
        local choices = {"fozong_get"}
        local to_return, choice = room:askToChooseCardsAndChoices(p, {
          min_card_num = 1,
          max_card_num = 1,
          targets = {player},
          pattern = ".",
          prompt = "#fozong-choice:" .. player.id,
          cancelable = false
        }, choices)

        if #to_return > 0 then
          room:obtainCard(p, to_return[1], true, fk.ReasonPrey)
          if player.dead then break end
          room:recover({
            who = player,
            num = 1,
            recoverBy = p,
            skillName = fozong.name
          })
        else
          room:loseHp(player, 1, fozong.name)
        end
      end
    end
  end,
})

return fozong
