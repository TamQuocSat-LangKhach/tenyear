local jiqiaos = fk.CreateSkill {
  name = "jiqiaos"
}

Fk:loadTranslationTable{
  ['jiqiaos'] = '激峭',
  ['#jiqiaos_trigger'] = '激峭',
  [':jiqiaos'] = '出牌阶段开始时，你可以将牌堆顶的X张牌至于武将牌上（X为你的体力上限）；当你使用一张牌结算结束后，若你的武将牌上有“激峭”牌，你获得其中一张，然后若剩余其中两种颜色牌的数量相等，你回复1点体力，否则你失去1点体力；出牌阶段结束时，移去所有“激峭”牌。',
  ['$jiqiaos1'] = '为将者，当躬冒矢石！',
  ['$jiqiaos2'] = '吾承父兄之志，危又何惧？',
}

-- 第一个效果
jiqiaos:addEffect(fk.EventPhaseStart, {
  derived_piles = "jiqiaos",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(jiqiaos.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player)
    player:addToPile(jiqiaos.name, player.room:getNCards(player.maxHp), true, jiqiaos.name)
  end,
})

-- 第二个效果
jiqiaos:addEffect({fk.EventPhaseEnd, fk.CardUseFinished}, {
  derived_piles = "jiqiaos",
  mute = true,
  can_trigger = function(self, event, target, player)
    if target == player and #player:getPile("jiqiaos") > 0 then
      if event == fk.EventPhaseEnd then
        return player.phase == Player.Play
      elseif event == fk.CardUseFinished then
        return true
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.EventPhaseEnd then
      room:moveCards({
        from = player.id,
        ids = player:getPile("jiqiaos"),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = jiqiaos.name,
        specialName = "jiqiaos",
      })
    else
      room:notifySkillInvoked(player, jiqiaos.name)
      player:broadcastSkillInvoke(jiqiaos.name)
      local cards = player:getPile("jiqiaos")
      if #cards == 0 then return false end
      local id = room:askToChooseCard(player, {
        target = player,
        flag = { card_data = {{ jiqiaos.name, cards }} },
        skill_name = "jiqiaos"
      })
      room:obtainCard(player, id, true, fk.ReasonJustMove)
      local red = #table.filter(player:getPile("jiqiaos"), function (id) return Fk:getCardById(id, true).color == Card.Red end)
      local black = #player:getPile("jiqiaos") - red  --除了不该出现的衍生牌，都有颜色
      if red == black then
        if player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = jiqiaos.name,
          }
        end
      else
        room:loseHp(player, 1, jiqiaos.name)
      end
    end
  end,
})

return jiqiaos
