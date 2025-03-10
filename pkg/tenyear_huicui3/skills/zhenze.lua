local zhenze = fk.CreateSkill {
  name = "zhenze"
}

Fk:loadTranslationTable{
  ['zhenze'] = '震泽',
  ['@zhenze'] = '震泽',
  ['zhenze_lose'] = '手牌数和体力值的大小关系与你不同的角色失去1点体力',
  ['zhenze_recover'] = '所有手牌数和体力值的大小关系与你相同的角色回复1点体力',
  [':zhenze'] = '弃牌阶段开始时，你可以选择一项：1.令所有手牌数和体力值的大小关系与你不同的角色失去1点体力；2.令所有手牌数和体力值的大小关系与你相同的角色回复1点体力。',
  ['$zhenze1'] = '名震千里，泽被海东。',
  ['$zhenze2'] = '施威除暴，上下咸服。',
}

zhenze:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zhenze.name) and player.phase == Player.Discard
  end,
  on_cost = function (self, event, target, player)
    local room = player.room
    local a = player:getHandcardNum() - player.hp
    local targets = {{},{}}
    for _, p in ipairs(room:getAlivePlayers()) do
      local b = p:getHandcardNum() - p.hp
      if b == a or (a * b) > 0 then
        room:setPlayerMark(p, "@zhenze", "recover")
        table.insert(targets[2], p.id)
      else
        room:setPlayerMark(p, "@zhenze", "loseHp")
        table.insert(targets[1], p.id)
      end
    end
    local all_choices = {"zhenze_lose", "zhenze_recover", "Cancel"}
    local choices = {"zhenze_recover", "Cancel"}
    if #targets[1] > 0 then table.insert(choices, 1, "zhenze_lose") end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhenze.name,
      all_choices = all_choices
    })
    for _, p in ipairs(room.alive_players) do
      room:setPlayerMark(p, "@zhenze", 0)
    end
    if choice ~= "Cancel" then
      event:setCostData(self, {choice, targets[table.indexOf(all_choices, choice)]})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice, targets = table.unpack(event:getCostData(self))
    room:doIndicate(player.id, targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        if choice == "zhenze_lose" then
          room:loseHp(p, 1, zhenze.name)
        elseif p:isWounded() then
          room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = zhenze.name
          })
        end
      end
    end
  end,
})

return zhenze
