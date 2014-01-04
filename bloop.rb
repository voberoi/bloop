#!/usr/bin/env ruby

require 'terminfo'

class Bloop
    SMILEY = "\u263a".encode("utf-8")

    def initialize
        @model = BloopModel.new
        @previous_render_time = 0
        @milliseconds_between_frames = 50
    end

    def run!
        clear_screen

        loop do
            if time_to_render?
                update_render_time
                model.tick
                render
            end
        end
    end

    private

    attr_reader :model

    def time_to_render?
        elapsed = milliseconds_since_epoch - @previous_render_time
        elapsed >= @milliseconds_between_frames
    end

    def update_render_time
        @previous_render_time = milliseconds_since_epoch
    end

    def render
        puts left_of_smiley + SMILEY
    end

    def left_of_smiley
        " " * model.width_left_of_smiley
    end

    def milliseconds_since_epoch
        (Time.now.to_f * 1000).truncate
    end

    def clear_screen
        puts "\e[H\e[2J"
    end
end

class BloopModel
    attr_reader :smiley_position
    attr_reader :width

    def initialize
        set_current_width
        @smiley_position = random_position
        @velocity = random_velocity
    end

    def tick
        set_current_width
        reverse_direction if collision_detected?
        move_smiley
    end

    def width_left_of_smiley
        smiley_position
    end


    private

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

    def set_current_width
        @width = terminal_width
    end

    def random_position
        rand(0..terminal_width)
    end

    def random_velocity
        [-3, 3].sample
    end

    def terminal_width
        TermInfo.screen_size[1]
    end
end

# Bloop.
require 'ostruct'
run = OpenStruct.new({ bloop: Bloop.new })
run.bloop.run!
