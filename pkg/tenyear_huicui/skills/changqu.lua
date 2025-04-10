local changqu = fk.CreateSkill {
  name = "changqu",
}

Fk:loadTranslationTable{
  ["changqu"] = "长驱",
  [":changqu"] = "出牌阶段限一次，你可以<font color='red'>开一艘战舰</font>，从你的上家或下家开始选择任意名座次连续的其他角色，"..
  "第一个目标角色获得战舰标记。获得战舰标记的角色选择一项：1.交给你X张手牌，然后将战舰标记移动至下一个目标；2.下次受到的属性伤害+X，"..
  "然后横置武将牌（X为本次选择1的次数，至少为1）。",

  ["#changqu"] = "长驱：从上家或下家开始选择座次连续的角色，这些角色选择交给你牌或受到伤害增加",
  ["@@battleship"] = "战舰",
  ["#changqu-card"] = "长驱：交给 %src %arg张手牌以使战舰驶向下一名角色",
  ["@changqu"] = "长驱",

  ["$changqu1"] = "布横江之铁索，徒自缚耳。",
  ["$changqu2"] = "艨艟击浪，可下千里江陵。",
}

changqu:addEffect("active", {
  anim_type = "control",
  prompt = "#changqu",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(changqu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if to_select == player then return end
    if #selected == 0 then
      return to_select:getNextAlive() == player or player:getNextAlive() == to_select
    else
      if table.contains(selected, player:getNextAlive()) then
        if selected[#selected]:getNextAlive() == to_select then
          return true
        end
      end
      if selected[1]:getNextAlive() == player then
        if to_select:getNextAlive() == selected[#selected] then
          return true
        end
      end
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected > 0 then
      if not (selected[1]:getNextAlive() == player or player:getNextAlive() == selected[1]) then return false end
      if #selected == 1 then return true end
      if selected[1]:getNextAlive() == player then
        for i = 1, #selected - 1, 1 do
          if selected[i + 1]:getNextAlive() ~= selected[i] then
            return false
          end
        end
        return true
      end
      if player:getNextAlive() == selected[1] then
        for i = 1, #selected - 1, 1 do
          if selected[i]:getNextAlive() ~= selected[i + 1] then
            return false
          end
        end
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = 0
    for _, target in ipairs(effect.tos) do
      if not target.dead then
        room:setPlayerMark(target, "@@battleship", 1)
        local cards = {}
        local x = math.max(n, 1)
        if target:getHandcardNum() >= x then
          cards = room:askToCards(target, {
            min_num = x,
            max_num = x,
            include_equip = false,
            skill_name = changqu.name,
            cancelable = true,
            prompt = "#changqu-card:"..player.id.."::"..x,
          })
        end
        if #cards > 0 then
          room:obtainCard(player, cards, false, fk.ReasonGive, target, changqu.name)
          n = n + 1
        else
          room:doIndicate(player, {target})
          room:addPlayerMark(target, "@changqu", x)
          room:setPlayerMark(target, "@@battleship", 0)
          if not target.chained then
            target:setChainState(true)
          end
          break
        end
        room:setPlayerMark(target, "@@battleship", 0)
      end
      if player.dead then return end
    end
  end,
})

changqu:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@changqu") > 0 and data.damageType ~= fk.NormalDamage
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(player:getMark("@changqu"))
    player.room:setPlayerMark(player, "@changqu", 0)
  end,
})

return changqu
