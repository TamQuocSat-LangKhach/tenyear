local zhinang = fk.CreateSkill {
  name = "zhinang"
}

Fk:loadTranslationTable{
  ['zhinang'] = '智囊',
  ['@zhinang_skills'] = '',
  [':zhinang'] = '当你使用锦囊牌后，你可以获得一个技能台词包含“谋”的技能直到下次获得；当你使用装备牌后，你可以获得一个技能名包含“谋”的技能直到下次获得。',
  ['$zhinang1'] = '',
  ['$zhinang2'] = '',
}

zhinang:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhinang.name) and data.card.type ~= Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("zhinang_pool") == 0 then
      local skills1, skills2 = {}, {}
      for name, s in pairs(Fk.skills) do
        if s.isPlayerSkill and s.visible then
          if string.find(Fk:translate("$"..name.."1", "zh_CN"), "谋") or
            string.find(Fk:translate("$"..name.."2", "zh_CN"), "谋") then  --暂时先这样，多句台词或者固定技能池看反馈
            table.insert(skills1, name)
          end
          if string.find(Fk:translate(name, "zh_CN"), "谋") then
            table.insert(skills2, name)
          end
        end
      end
      room:setPlayerMark(player, "zhinang_pool", {skills1, skills2})
    end
    if data.card.type == Card.TypeTrick then
      if player:getMark("zhinang_trick") ~= 0 and player:hasSkill(player:getMark("zhinang_trick"), true) then
        room:handleAddLoseSkills(player, "-"..player:getMark("zhinang_trick"), nil, true, false)
        if player.dead then return end
      end
      local skills = table.filter(player:getMark("zhinang_pool")[1], function (s)
        return not player:hasSkill(s, true)
      end)
      if #skills > 0 then
        local s = table.random(skills)
        room:setPlayerMark(player, "zhinang_trick", s)
        if string.find(Fk:translate("$"..s.."1", "zh_CN"), "谋") then
          player:chat(string.format("$%s:%d", s, 1))
        else
          player:chat(string.format("$%s:%d", s, 2))
        end
        room:handleAddLoseSkills(player, s, nil, true, false)
      end
    elseif data.card.type == Card.TypeEquip then
      if player:getMark("zhinang_equip") ~= 0 and player:hasSkill(player:getMark("zhinang_equip"), true) then
        room:handleAddLoseSkills(player, "-"..player:getMark("zhinang_equip"), nil, true, false)
        if player.dead then return end
      end
      local skills = table.filter(player:getMark("zhinang_pool")[2], function (s)
        return not player:hasSkill(s, true)
      end)
      if #skills > 0 then
        local s = table.random(skills)
        room:setPlayerMark(player, "zhinang_equip", s)
        room:handleAddLoseSkills(player, s, nil, true, false)
      end
    end
    local mark = ""
    if player:getMark("zhinang_trick") ~= 0 then
      mark = Fk:translate(player:getMark("zhinang_trick"))
    end
    if player:getMark("zhinang_equip") ~= 0 then
      mark = mark.." "..Fk:translate(player:getMark("zhinang_equip"))
    end
    room:setPlayerMark(player, "@zhinang_skills", "<font color='#87CEFA'>" .. mark .. "</font>")
  end,
})

return zhinang
