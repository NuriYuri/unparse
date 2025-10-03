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
