local fensi = fk.CreateSkill {
  name = "fensi"
}

Fk:loadTranslationTable{
  ['fensi'] = '忿肆',
  ['#fensi-choose'] = '忿肆：你须对一名体力值不小于你的角色造成1点伤害，若不为你，视为其对你使用【杀】',
  [':fensi'] = '锁定技，准备阶段，你对一名体力值不小于你的角色造成1点伤害；若受伤角色不为你，则其视为对你使用一张【杀】。',
  ['$fensi1'] = '此贼之心，路人皆知！',
  ['$fensi2'] = '孤君烈忿，怒愈秋霜。',
}

fensi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fensi.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.map(table.filter(room:getAlivePlayers(), function(p)
        return p.hp >= player.hp
      end), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#fensi-choose",
      skill_name = fensi.name,
      cancelable = false,
    })

    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = player
    end

    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = fensi.name,
    }

    if not to.dead and to ~= player then
      room:useVirtualCard("slash", nil, to, player, fensi.name, true)
    end
  end,
})

return fensi
