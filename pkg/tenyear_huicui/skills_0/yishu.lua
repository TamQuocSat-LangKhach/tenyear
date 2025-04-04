local yishu = fk.CreateSkill {
  name = "yishu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['yishu'] = '易数',
  ['huishu1'] = '摸牌数',
  ['huishu2'] = '摸牌后弃牌数',
  ['huishu3'] = '获得锦囊所需弃牌数',
  ['huishu'] = '慧淑',
  ['#yishu-lose'] = '易数：请选择减少的一项',
  ['@huishu'] = '慧淑',
  ['#yishu-add'] = '易数：请选择增加的一项',
  [':yishu'] = '锁定技，当你于出牌阶段外失去牌后，〖慧淑〗中最小的一个数字+2且最大的一个数字-1。',
  ['$yishu1'] = '此命由我，如织之数可易。',
  ['$yishu2'] = '易天定之数，结人定之缘。',
}

yishu:addEffect(fk.AfterCardsMove, {
  
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yishu.name) and player:hasSkill(huishu, true) and player.phase ~= Player.Play and
      not huishu:triggerable(event, target, player, data) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local yishu_nums = {
      player:getMark("huishu1") + 3,
      player:getMark("huishu2") + 1,
      player:getMark("huishu3") + 2
    }

    local max_c = math.max(yishu_nums[1], yishu_nums[2], yishu_nums[3])
    local min_c = math.min(yishu_nums[1], yishu_nums[2], yishu_nums[3])

    local to_change = {}
    for i = 1, 3, 1 do
      if yishu_nums[i] == max_c then
        table.insert(to_change, "huishu" .. tostring(i))
      end
    end

    local choice = room:askToChoice(player, {
      choices = to_change,
      skill_name = yishu.name,
      prompt = "#yishu-lose"
    })

    local index = tonumber(string.sub(choice, 7))
    yishu_nums[index] = yishu_nums[index] - 1

    room:setPlayerMark(player, "@huishu", yishu_nums)

    to_change = {}
    for i = 1, 3, 1 do
      if yishu_nums[i] == min_c and i ~= index then
        table.insert(to_change, "huishu" .. tostring(i))
      end
    end

    choice = room:askToChoice(player, {
      choices = to_change,
      skill_name = yishu.name,
      prompt = "#yishu-add"
    })

    index = tonumber(string.sub(choice, 7))
    yishu_nums[index] = yishu_nums[index] + 2

    room:setPlayerMark(player, "@huishu", yishu_nums)

    room:setPlayerMark(player, "huishu1", yishu_nums[1] - 3)
    room:setPlayerMark(player, "huishu2", yishu_nums[2] - 1)
    room:setPlayerMark(player, "huishu3", yishu_nums[3] - 2)
  end,
})

return yishu
