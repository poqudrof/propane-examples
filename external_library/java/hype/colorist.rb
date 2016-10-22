#!/usr/bin/env jruby -v -W2
# frozen_string_literal: true
require 'propane'

# The Colorist class
class Colorist < Propane::App
  load_library :hype
  include_package 'hype'
  java_import 'hype.extended.colorist.HPixelColorist'
  java_import 'hype.extended.layout.HGridLayout'
  CELL_SIZE = 25

  def settings
    size(618, 482)
  end

  def setup
    sketch_title 'Colorist'
    H.init(self)
    H.background(color('#242424'))
    colors = HPixelColorist.new(data_path('phil_pai.jpg'))
    .fill_only
    # .strokeOnly
    # .fillAndStroke
    pool = HDrawablePool.new(576)
    pool.autoAddToStage
    .add(HRect.new.rounding(4))
    .layout(
    HGridLayout.new
    .start_x(21)
    .start_y(21)
    .spacing(CELL_SIZE + 1, CELL_SIZE + 1)
    .cols(24)
    )
    .on_create do |obj|
      obj.no_stroke.anchor_at(H::CENTER).size(CELL_SIZE)
      colors.applyColor(obj)
    end.request_all
    H.draw_stage
    no_loop
  end
end

Colorist.new
