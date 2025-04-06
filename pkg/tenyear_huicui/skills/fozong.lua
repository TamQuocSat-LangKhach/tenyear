local fozong = fk.CreateSkill {
  name = "fozong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fozong"] = "佛宗",
  [":fozong"] = "锁定技，出牌阶段开始时，若你的手牌多于七张，你将超出数量的手牌置于武将牌上，然后若你武将牌上有至少七张牌，"..
  "其他角色依次选择一项：1.获得其中一张牌并令你回复1点体力；2.令你失去1点体力。",

  ["#fozong-ask"] = "佛宗：将 %arg 张手牌置于武将牌上",
  ["#fozong-prey"] = "佛宗：获得其中一张牌令其回复体力，或点“取消”其失去1点体力",

  ["$fozong1"] = "此身无长物，愿奉骨肉为浮屠。",
  ["$fozong2"] = "驱大白牛车，颂无上功德。",
}

Fk:addPoxiMethod{
  name = "fozong",
  prompt = "#fozong-prey",
  card_filter = function(to_select, selected, data, extra_data)
    return #selected == 0
  end,
  feasible = function (selected, data, extra_data)
    return #selected == 1
  end,
}

fozong:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  derived_piles = "fozong",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fozong.name) and player.phase == Player.Play and
      player:getHandcardNum() > 7
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum() - 7
    local cards = room:askToCards(player, {
      skill_name = fozong.name,
      min_num = n,
      max_num = n,
      include_equip = false,
      prompt = "#fozong-ask:::" .. n,
      cancelable = false,
    })
    player:addToPile(fozong.name, cards, true, fozong.name, player)
    if #player:getPile(fozong.name) < 7 then return end

    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      room:doIndicate(player, {p})
      if not p.dead then
        cards = room:askToPoxi(p, {
          poxi_type = fozong.name,
          data = { { fozong.name, player:getPile(fozong.name) } },
          cancelable = true,
        })
        if #cards > 0 then
          room:obtainCard(p, cards, true, fk.ReasonJustMove, p, fozong.name)
          if player:isWounded() and not player.dead then
            room:recover{
              who = player,
              num = 1,
              recoverBy = p,
              skillName = fozong.name,
            }
          end
        else
          room:loseHp(player, 1, fozong.name)
        end
      end
    end
  end,
})

return fozong
