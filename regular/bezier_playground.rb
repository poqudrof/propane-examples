#!/usr/bin/env jruby -v -w
require 'propane'

X1, Y1, X2, Y2 = 50.0, 50.0, 250.0, 250.0
REDDISH = [250, 100, 100]
RADIUS = 7

module Olap
  def self.overlaps(x, y, point_x, point_y)
    Math.hypot(x - point_x, y - point_y) < RADIUS
  end
end

class Curve
  include Olap, Propane::Proxy
  attr_accessor :x1, :y1, :c1x, :c1y, :c2x, :c2y, :x2, :y2

  def initialize
    @x1, @y1, @x2, @y2 = X1, Y1, X2, Y2
    set_control_points(X1 + 30, Y1, X2 - 30, Y2)
  end

  def contains(x, y)
    return :one if Olap.overlaps(x1, y1, x, y)
    return :two if Olap.overlaps(x2, y2, x, y)
  end

  def all_points
    return x1, y1, c1x, c1y, c2x, c2y, x2, y2
  end

  def control_points
    return c1x, c1y, c2x, c2y
  end

  def set_control_points(*points)
    @c1x, @c1y, @c2x, @c2y = *points
  end

  def draw
    bezier(*all_points)
    ellipse x1, y1, 3, 3
    ellipse x2, y2, 3, 3
  end

  def print_equation(id)
    pt = all_points.map(&:to_i)
    puts ''
    puts format('*** line #%s ***', id)
    xformat = 'x = (1-t)^3 %s + 3(1-t)^2 t%s + 3(1-t)t^2 %s + t^3 %s'
    yformat = 'y = -1 * ((1-t)^3 %s + 3(1-t)^2 t%s + 3(1-t)t^2 %s + t^3 %s'
    puts format(xformat, pt[0], pt[2], pt[4], pt[6])
    puts format(yformat, pt[1], pt[3], pt[5], pt[7])
    puts ''
  end
end

class BezierPlayground < Propane::App
  # A Bezier playground. Click to shape the curve. Drag to move it.
  # Arrows toggle between curves, delete removes them.
  # You can print out the parametric equations for t = 0..1

  attr_accessor :curves, :c1x, :c1y, :c2x, :c2y
  attr_reader :panel, :hide

  load_library :control_panel
  include Olap

  def setup
    size 300, 300
    @curves = []
    @hide = false
    control_panel do |c|
      c.look_feel 'Nimbus'
      c.button :new_curve
      c.button :print_equations
      @panel = c
    end
    generate_curve
  end

  def draw
    unless hide
      panel.visible = visible
      @hide = true
    end
    background 50
    draw_control_tangent_lines
    draw_curves
    draw_current_control_points
  end

  def print_equations
    curves.each_with_index { |c, i| c.print_equation(i + 1) }
  end

  def control_points
    return c1x, c1y, c2x, c2y
  end

  def set_control_points(*points)
    @c1x, @c1y, @c2x, @c2y = points.any? ? points : [X1, Y1, X2, Y2]
  end

  def generate_curve
    curves << current_curve = Curve.new
    @current = curves.length - 1
    set_control_points(*current_curve.control_points)
  end

  def current_curve
    curves[@current]
  end

  def new_curve
    current_curve.set_control_points(c1x, c1y, c2x, c2y)
    generate_curve
  end

  def clicked_control_point?
    x, y = mouse_x, mouse_y
    return :one if Olap.overlaps(c1x, c1y, x, y)
    return :two if Olap.overlaps(c2x, c2y, x, y)
  end

  def mouse_pressed
    switch_curve_if_endpoint_clicked
    @control = clicked_control_point?
    return if @control
    curve = curves.detect { |c| c.contains(mouse_x, mouse_y) }
    @end_point = curve.contains(mouse_x, mouse_y) if curve
  end

  def mouse_released
    @control, @end_point = nil, nil
    @hide = false
  end

  def mouse_dragged
    offs = compute_offsets
    return if offs.map(&:abs).max > 100
    return move_control_point(*offs) if @control
    return move_end_point(*offs) && move_control_point(*offs) if @end_point
    move_current_curve(*offs)
  end

  def switch_curve_if_endpoint_clicked
    become = curves.detect { |c| c.contains(mouse_x, mouse_y) }
    return unless become && become != current_curve
    current_curve.set_control_points(*control_points)
    self.set_control_points(*become.control_points)
    @current = curves.index(become)
  end

  def move_current_curve(x_off, y_off)
    @c1x += x_off; @c2x += x_off
    @c1y += y_off; @c2y += y_off
    current_curve.set_control_points(*control_points)
    current_curve.x1 += x_off; current_curve.x2 += x_off
    current_curve.y1 += y_off; current_curve.y2 += y_off
  end

  def move_control_point(x_off, y_off)
    case @control || @end_point
    when :one then @c1x += x_off and @c1y += y_off
    when :two then @c2x += x_off and @c2y += y_off
    end
    current_curve.set_control_points(*control_points)
  end

  def move_end_point(x_off, y_off)
    c = current_curve
    case @end_point
    when :one then c.x1 += x_off and c.y1 += y_off
    when :two then c.x2 += x_off and c.y2 += y_off
    end
  end

  def compute_offsets
    return mouse_x - pmouse_x, mouse_y - pmouse_y
  end

  def draw_curves
    stroke 255
    no_fill
    stroke_width 2
    curves.each(&:draw)
  end

  def draw_current_control_points
    fill color(*REDDISH)
    no_stroke
    ellipse c1x, c1y, 5, 5
    ellipse c2x, c2y, 5, 5
  end

  def draw_control_tangent_lines
    c = current_curve
    stroke color(*REDDISH)
    stroke_width 1
    line c1x, c1y, c.x1, c.y1
    line c2x, c2y, c.x2, c.y2
  end
end

BezierPlayground.new title: 'Bezier Playground'
