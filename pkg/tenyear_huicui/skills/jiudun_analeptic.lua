local skill = fk.CreateSkill {
  name = "jiudun__analeptic_skill",
}

Fk:loadTranslationTable{
  ["jiudun__analeptic_skill"] = "酒",
}

skill:addEffect("cardskill", {
  mute = true,
  prompt = "#analeptic_skill",
  max_turn_use_time = 1,
  mod_target_filter = Util.TrueFunc,
  can_use = function(self, player, card, extra_data)
    return not player:isProhibited(player, card) and
      ((extra_data and (extra_data.bypass_times or extra_data.analepticRecover)) or
      self:withinTimesLimit(player, Player.HistoryTurn, card, "analeptic", player))
  end,
  on_use = function(self, room, use)
    if #use.tos == 0 then
      use:addTarget(use.from)
    end

    if use.extra_data and use.extra_data.analepticRecover then
      use.extraUse = true
    end
  end,
  on_effect = function(self, room, effect)
    local to = effect.to
    room:setEmotion(to, "./packages/maneuvering/image/anim/analeptic")
    if effect.extra_data and effect.extra_data.analepticRecover then
      if to:isWounded() and not to.dead then
        room:recover({
          who = to,
          num = 1,
          recoverBy = effect.from,
          card = effect.card,
        })
      end
    else
      room:addPlayerMark(to, "@jiudun_drank", 1 + ((effect.extra_data or {}).additionalDrank or 0))
    end
  end,
})

return skill
