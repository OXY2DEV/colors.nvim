local utils = {};

utils.clamp = function (val, min, max)
	return math.min(math.max(val, min), max);
end

utils.num_to_hex = function (num)
	return num and string.format("#%06x", num);
end

---@param hex string
---@return { r: number, g: number, b: number }
utils.hex_to_tbl = function (hex)
	if type(hex) ~= "string" then
		error("Malformed hex color code: " .. hex);
	end

	hex = hex:gsub("#", "");

	if #hex < 3 or #hex > 7 then
		error("Malformed hex color code: " .. hex);
	end

	if #hex == 3 then
		return {
			r = tonumber(string.sub(hex, 1, 1), 16),
			g = tonumber(string.sub(hex, 2, 2), 16),
			b = tonumber(string.sub(hex, 3, 3), 16),
		}
	elseif #hex == 6 then
		return {
			r = tonumber(string.sub(hex, 1, 2), 16),
			g = tonumber(string.sub(hex, 3, 4), 16),
			b = tonumber(string.sub(hex, 5, 6), 16),
		}
	end

	return { r = nil, g = nil, b = nil }
end

utils.tbl_to_hex = function (tbl)
	if not tbl or not tbl.r or not tbl.g or not tbl.b then
		error("Incorrect table format");
	end

	return string.format("#%02x%02x%02x", tbl.r, tbl.g, tbl.b)
end

utils.get_value = function (config_table, value)
	local hl = vim.api.nvim_get_hl(0, config_table);

	if value == nil or value == "bg" then
		return utils.hex_to_tbl(utils.num_to_hex(hl.bg or 0));
	elseif value == "fg" then
		return utils.hex_to_tbl(utils.num_to_hex(hl.fg or 0));
	elseif value == "sp" then
		return utils.hex_to_tbl(utils.num_to_hex(hl.sp or 0));
	else
		return hl[value];
	end
end

utils.lerp = function (x, y, t)
	if not x or not y or type(t) ~= "number" or t > 1 then
		vim.print("Malformed lerp structure");
		return;
	end

	return x + (y - x) * t;
end

utils.color_mix = function (col_1, col_2, amount_1, amount_2)
	if not col_1 or not col_1.r or not col_1.g or not col_1.b then
		error("Incorrect first color");
	end

	if not col_2 or not col_2.r or not col_2.g or not col_2.b then
		error("Incorrect second color");
	end

	if type(amount_1) ~= "number" or amount_1 < 0 or amount_1 > 1 then
		error("Ranges should be between 1 and 0, not " .. amount_1)
	end

	if type(amount_2) ~= "number" or amount_2 < 0 or amount_2 > 2 then
		error("Ranges should be between 1 and 0, not " .. amount_2)
	end

	return utils.tbl_to_hex({
		r = utils.clamp((col_1.r * amount_1) + (col_2.r * amount_2), 0, 255),
		g = utils.clamp((col_1.g * amount_1) + (col_2.g * amount_2), 0, 255),
		b = utils.clamp((col_1.b * amount_1) + (col_2.b * amount_2), 0, 255),
	})
end

utils.rgb_to_hsl = function (color)
	if not color or not color.r or not color.g or not color.b then
		error("Incorrect RGB color");
	end

	local _r = color.r > 1 and color.r / 255 or color.r;
	local _g = color.g > 1 and color.g / 255 or color.g;
	local _b = color.b > 1 and color.b / 255 or color.b;

	local min, max = math.min(_r, _g, _b), math.max(_r, _g, _b);

	local _l = (min + max) / 2;
	local _h, _s;

	if min == max then
		_s = 0;
	elseif _l <= 0.5 then
		_s = (max - min) / (max + min);
	else
		_s = (max - min) / (2 - (max + min));
	end

	if max == _r then
		_h = (_g - _b) / (max - min)
	elseif max == _g then
		_h = 2 + ((_b - _r) / (max - min));
	else
		_h = 4 + ((_r - _g) / (max - min));
	end

	return { h = _h, s = _s, l = _l }
end

return utils;
