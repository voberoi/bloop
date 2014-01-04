#!/usr/bin/env ruby

require 'terminfo'
require 'curses'

class Bloop
    SMILEY = "\u263a".encode("utf-8")

    def initialize
        @view = BloopView.new
        @model = BloopModel.new(view.width)
        @previous_render_time = 0
        @milliseconds_between_frames = 50
    end

    def run!
        begin
            view.setup
            loop do
                if time_to_render?
                    update_render_time
                    model.tick(view.width)
                    render
                end
            end
        ensure
            view.teardown
        end
    end

    private

    attr_reader :model, :view

    def time_to_render?
        elapsed = milliseconds_since_epoch - @previous_render_time
        elapsed >= @milliseconds_between_frames
    end

    def update_render_time
        @previous_render_time = milliseconds_since_epoch
    end

    def render
        view.set_position(model.smiley_position, 50)
        view.add_string(SMILEY)
        view.redraw_view
    end

    def milliseconds_since_epoch
        (Time.now.to_f * 1000).truncate
    end
end

class BloopView
    include Curses

    def width
        cols
    end

    def set_position(x, y)
        setpos(x, y)
    end

    def add_string(string)
        addstr(string)
    end

    def redraw_view
        refresh
    end

    def setup
        init_screen
        cbreak
        noecho
    end

    def teardown
        close_screen
        nocbreak
        echo
    end
end

class BloopModel
    attr_reader :smiley_position

    def initialize(width)
        @width = width
        @smiley_position = random_position
        @velocity = random_velocity
    end

    def tick(width)
        @width = width
        reverse_direction if collision_detected?
        move_smiley
    end


    private

    attr_reader :width

    def move_smiley
        @smiley_position += @velocity
        if out_of_bounds?
            snap_smiley_back_into_bounds
        end
    end

    def snap_smiley_back_into_bounds
        if out_of_left_bounds?
            snap_smiley_to_left
        elsif out_of_right_bounds?
            snap_smiley_to_right
        end
    end

    def snap_smiley_to_left
        @smiley_position = 0
    end

    def snap_smiley_to_right
        @smiley_position = width - 1
    end

    def reverse_direction
        @velocity *= -1
    end

    def collision_detected?
        left_collision_detected? || right_collision_detected?
    end
    alias_method :out_of_bounds?, :collision_detected?

    def left_collision_detected?
        smiley_position <= 0
    end
    alias_method :out_of_left_bounds?, :left_collision_detected?

    def right_collision_detected?
        smiley_position >= width - 1
    end
    alias_method :out_of_right_bounds?, :right_collision_detected?

    def random_position
        rand(0..width)
    end

    def random_velocity
        [-3, 3].sample
    end
end

# Bloop.
require 'ostruct'
run = OpenStruct.new({ bloop: Bloop.new })
run.bloop.run!
