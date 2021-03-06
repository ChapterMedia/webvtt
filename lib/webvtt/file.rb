# -*- encoding : utf-8 -*-
module Webvtt
  class File

    attr_accessor :file, :cues

    def initialize(input_file)
      if input_file.is_a?(String)
        input_file = input_file.encode('UTF-8')
        if ::File.exist?(input_file)
          @file = ::File.read(input_file)
        else
          @file = input_file
        end
      elsif input_file.is_a?(::File)
        @file = input_file.read
      else
        raise
      end
      @cues = []
      parse
    end

    def parse
      remove_bom
      if !webvtt_line?(file.lines.first)
        raise Webvtt::MalformedError
      end
      collected_lines = []
      file_lines = file.dup.lines.to_a
      cue_index = 0
      file_lines.each_with_index do |line,index|
        line.chomp!

        next if webvtt_line?(line)
        if line.empty?
          if !collected_lines.empty? and !notes?(collected_lines)
            cue_index += 1
            add_a_cue(collected_lines, cue_index)
          end
          collected_lines = []
        elsif !line.empty? and file_lines.length == (index + 1)
          collected_lines << line
          cue_index += 1
          add_a_cue(collected_lines, cue_index)
        else
          collected_lines << line
        end
      end
    end

    def webvtt_line?(line)
      line[0,6] == 'WEBVTT'
    end

    def remove_bom
      file.gsub!("\uFEFF", '')
    end

private

    def add_a_cue(collected_lines, ix = 0)
      cue_opts = {}
      if collected_lines.first.include?('-->')
        cue_opts[:cue_line] = collected_lines.first
        cue_opts[:identifier] = ix.to_s
        text_starts_at = 1
      elsif collected_lines[1].include?('-->')
        cue_opts[:identifier] = collected_lines.first
        cue_opts[:cue_line] = collected_lines[1]
        text_starts_at = 2
      end
      cue_opts[:text] = collected_lines[text_starts_at..-1].join("\n")
      cues << Cue.new(cue_opts)
    end

    def notes?(collected_lines)
      if collected_lines.first.match(/^NOTE/)
        true
      else
        false
      end
    end

  end
end
