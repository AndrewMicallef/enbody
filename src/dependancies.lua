require('lib.batteries'):export()

lg = love.graphics

lg.setDefaultFilter("nearest", "nearest")

cpml = require 'lib.cpml'


-- takes a file containing template tokens of the form {{var}}
-- and fills the tokens from the subs table given {var =  val} is in subs
function from_template(template_file, subs)
	local template = love.filesystem.read(template_file)
	local filled = string.gsub(template, "{{(%w+)}}", subs)
	return filled
end

-- timing function used in Particles update and draw
function update_timer(current_timer, lerp_amount, f)
	local time_start = love.timer.getTime()
	f()
	local time_end = love.timer.getTime()
	return current_timer * (1 - lerp_amount) + (time_end - time_start) * lerp_amount

end
