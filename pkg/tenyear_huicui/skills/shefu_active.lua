local shefu_active = fk.CreateSkill{
  name = "ty__shefu_active",
}

Fk:loadTranslationTable{
  ["ty__shefu_active"] = "设伏",
}

local U = require "packages/utility/utility"

shefu_active:addEffect("active", {
  card_num = 1,
  target_num = 0,
  interaction = function (self, player)
    local all_names = Fk:getAllCardNames("btd", true)
    local names = table.filter(all_names, function (name)
      return not table.find(player:getPile("$ty__shefu"), function (id)
        return Fk:getCardById(id):getMark("@ty__shefu") == Fk:translate(name)
      end)
    end)
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
})

return shefu_active
