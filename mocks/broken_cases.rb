def dstr(eid, event)
  return "\nEventID: #{eid} (#{event&.x}, #{event&.y}) | MapID: #{$game_map.map_id}"
end

def regexp_roundtrip(filename,state_suffix)
  filename = filename.sub(/_(?:m|f|nb)#{state_suffix}$/, '')
end

def to_s
  "<PB:#{name},#{@bank},#{@position} lv=#{@level} hp=#{@hp_rate.round(3)} st=#{@status}>"
end

def log_stuff(stat, target, launcher, skill, e)
  log_data("# stat = #{stat}; target = #{target}; launcher = #{launcher}; skill = #{skill}")
  log_data("# FR: stat_increasable? #{e.data} from #{e.hook_name} (#{e.reason})")
end

def stockpile
  log_data("stockpile # increase stages <dfe:#{@pokemon.dfe_stage}(+#{@stages_bonus[:dfe]}), dfs:#{@pokemon.dfs_stage}(+#{@stages_bonus[:dfs]})>")
end

def multiplier(type_to_check, target_type, result)
  maps = [5, 20]
  log_data("multiplier of #{type_to_check} (#{data_type(target_type).name}) = #{result} => new_eff = #{@effectiveness}")
end


module RPG
  # Script that cache bitmaps when they are reusable.
  # @author Nuri Yuri
  module Cache
    # Array of load methods to call when the game starts
    LOADS = %i[load_animation]
  end

  # Some comment
  module Cache2
    # NOOP
    # NOOP2
  end

  module Cache
    # Extension of gif files
    GIF_EXTENSION = '.gif'
    # Common filename of the image to load
    Common_filename = 'Graphics/%s/%s' # After comment
    # Next line comment (will be alone because no matching expression)
  end
end

def safe_code(name, &value)
  receiver = value.binding.receiver
  receiver = Object if receiver.instance_of?(Object)
  return (SafeExec::SAFE_CODE[receiver] ||= {})[name] = value
end

module A
  class B
    def test

    end
  end
end

module A
  class B
    def test2
      (wrapper = test).stuff = true
      puts wrapper
    end
  end
end
