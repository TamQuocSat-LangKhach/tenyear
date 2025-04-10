
local tenyear_yj = require "packages/tenyear/pkg/tenyear_yj"
--local tenyear_ex = require "packages/tenyear/pkg/tenyear_ex"
local tenyear_xinghuo = require "packages/tenyear/pkg/tenyear_xinghuo"
local tenyear_sp = require "packages/tenyear/pkg/tenyear_sp"
local tenyear_wei = require "packages/tenyear/pkg/tenyear_wei"
local tenyear_mou = require "packages/tenyear/pkg/tenyear_mou"
local tenyear_star = require "packages/tenyear/pkg/tenyear_star"
local tenyear_huicui = require "packages/tenyear/pkg/tenyear_huicui"
-- local tenyear_test = require "packages/tenyear/pkg/tenyear_test"
local tenyear_other = require "packages/tenyear/pkg/tenyear_other"

local tenyear_token = require "packages/tenyear/pkg/tenyear_token"

Fk:loadTranslationTable{ ["tenyear"] = "十周年" }
Fk:loadTranslationTable(require "packages/tenyear/i18n/en_US", "en_US")

return {
  tenyear_yj,
  --tenyear_ex,
  tenyear_xinghuo,
  tenyear_sp,
  tenyear_wei,
  tenyear_mou,
  tenyear_star,
  tenyear_huicui,
  -- tenyear_test,
  tenyear_other,

  tenyear_token,
}
