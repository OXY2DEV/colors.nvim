local colors = {};
local utils = require("colors.utils");

colors.configuraton = {
	{
		type = "dynamic",

		value = function (helper)
			local from = helper.get_value({ name = "Title" }, "fg");
			local to = helper.get_value({ name = "Comment" }, "fg");

			local _o = {
				{
					group_name = "Glow_0",
					value = { fg = helper.tbl_to_hex(from) }
				}
			};

			for i = 2, 8 do
				local amount = i / 8;

				table.insert(_o, {
					group_name = "Glow_" .. (i - 1),
					value = {
						fg = helper.color_mix(to, from, amount, 1 - amount)
					}
				})
			end

			return _o;
		end
	},
	{
		type = "dynamic",
		value = function (helper)
			local _o = {};
			local bg = helper.get_value({ name = "Normal" });

			for r = 1, 6 do
				local color = helper.get_value({ name = "rainbow" .. r }, "fg");

				if bg ~= nil then
					table.insert(_o, {
						group_name = "rainbow" .. r .. "_dark",
						value = {
							fg = helper.color_mix(bg, color, 0.6, 0.4)
						}
					})
				else
					table.insert(_o, {
						group_name = "rainbow" .. r .. "_dark",
						value = {
							fg = helper.tbl_to_hex(color)
						}
					})
				end
			end

			return _o;
		end
	},
	{
		type = "dynamic",
		value = function (helper)
			local _o = {};
			local fgs = {
				mode_normal = helper.get_value({ name = "Function" }, "fg"),
				mode_insert = helper.get_value({ name = "Normal" }, "fg"),
				mode_visual = helper.get_value({ name = "Conditional" }, "fg"),
				mode_visual_block = helper.get_value({ name = "Special" }, "fg"),
				mode_visual_line = helper.get_value({ name = "rainbow2" }, "fg"),
				mode_cmd = helper.get_value({ name = "rainbow4" }, "fg")
			};
			local bgs = {
				mode_normal = helper.get_value({ name = "Normal" }, "bg"),
				mode_insert = helper.get_value({ name = "Normal" }, "bg"),
				mode_visual = helper.get_value({ name = "Normal" }, "bg"),
				mode_visual_block = helper.get_value({ name = "Normal" }, "bg"),
				mode_visual_line = helper.get_value({ name = "Normal" }, "bg"),
				mode_cmd = helper.get_value({ name = "Normal" }, "bg")
			};
			local buf_bg = helper.get_value({ name = "Normal" });


			for name, value in pairs(fgs) do
				table.insert(_o, {
					group_name = name,
					value = {
						fg = helper.tbl_to_hex(value),
						bg = helper.color_mix(buf_bg, buf_bg, 1, 0.75),
					}
				});

				table.insert(_o, {
					group_name = name .. "_alt",
					value = {
						fg = helper.tbl_to_hex(bgs[name]),
						bg = helper.tbl_to_hex(value)
					}
				})
			end

			return _o;
		end
	},
	{
		type = "dynamic",
		value = function (helper)
			local bg = helper.get_value({ name = "Normal" });
			local fg = helper.get_value({ name = "Normal" }, "fg");

			return {
				{
					group_name = "buf_name",
					value = {
						bg = helper.color_mix(bg, bg, 1, 0.75),
						fg = helper.tbl_to_hex(fg),
					}
				},
				{
					group_name = "buf_name_alt",
					value = {
						fg = helper.color_mix(bg, bg, 1, 0.75),
					}
				},
			}
		end
	},
	{
		type = "dynamic",
		value = function (helper)
			local default_bg = helper.get_value({ name = "Normal" });
			local bg = helper.get_value({ name = "Conditional" }, "fg");

			return {
				{
					group_name = "cursor_position",
					value = {
						bg = helper.tbl_to_hex(bg),
						fg = helper.tbl_to_hex(default_bg)
					}
				},
				{
					group_name = "cursor_position_alt",
					value = {
						fg = helper.tbl_to_hex(bg)
					}
				},
			};
		end
	},
	{
		type = "hl",
		group_name = "Folded",
		value = { fg = "#89B4FA" }
	},
	{
		type = "dynamic",
		value = function (helper)
			local bg = helper.get_value({ name = "Normal" });
			local fg = helper.get_value({ name = "Normal" }, "fg");

			local buf_mix_col = helper.get_value({ name = "rainbow4" }, "fg");
			local tab_mix_col = helper.get_value({ name = "rainbow5" }, "fg");

			return {
				{
					group_name = "tabline_buf_inactive_alt",
					value = {
						bg = helper.color_mix(bg, bg, 1, 0.75),
						fg = helper.tbl_to_hex(fg),
					}
				},
				{
					group_name = "tabline_buf_inactive",
					value = {
						fg = helper.color_mix(bg, bg, 1, 0.75),
					}
				},
				{
					group_name = "tabline_buf_active_alt",
					value = {
						bg = helper.color_mix(buf_mix_col, fg, 0.80, 0.15),
						fg = helper.tbl_to_hex(bg),
					}
				},
				{
					group_name = "tabline_buf_active",
					value = {
						fg = helper.color_mix(buf_mix_col, fg, 0.80, 0.15),
					}
				},

				{
					group_name = "tabline_tab_inactive_alt",
					value = {
						bg = helper.color_mix(bg, bg, 1, 0.75),
						fg = helper.tbl_to_hex(fg),
					}
				},
				{
					group_name = "tabline_tab_inactive",
					value = {
						fg = helper.color_mix(bg, bg, 1, 0.75),
					}
				},
				{
					group_name = "tabline_tab_active_alt",
					value = {
						bg = helper.color_mix(tab_mix_col, fg, 0.70, 0.25),
						fg = helper.tbl_to_hex(bg),
					}
				},
				{
					group_name = "tabline_tab_active",
					value = {
						fg = helper.color_mix(tab_mix_col, fg, 0.70, 0.25),
					}
				},
			}
		end
	}
};

colors.hl_applier = function (config_table)
	if type(config_table.group_name) ~= "string" or type(config_table.value) ~= "table" then
		return;
	end

	vim.api.nvim_set_hl(0, config_table.group_name, config_table.value)
end

colors.gradient_applier = function (config_table)
	if  not config_table or not config_table.from or not config_table.to then
		error("Malformed gradient inputs");
	end

	local from = utils.hex_to_tbl(config_table.from);
	local to = utils.hex_to_tbl(config_table.to);

	local _g = { from };
	local ease = config_table.ease and pcall(config_table.ease) and config_table.ease or utils.lerp;

	for i = 1, config_table.steps and config_table.steps - 1 or 10 do
		table.insert(_g, {
			r = ease(from.r, to.r, i / (config_table.steps and config_table.steps - 1 or 10)),
			g = ease(from.g, to.g, i / (config_table.steps and config_table.steps - 1 or 10)),
			b = ease(from.b, to.b, i / (config_table.steps and config_table.steps - 1 or 10)),
		})
	end

	for i, color in ipairs(_g) do
		local _hl = {};

		if not config_table.mode or config_table.mode == "fg" then
			_hl.fg = utils.tbl_to_hex(color);
		end

		if config_table.mode == "bg" then
			_hl.bg = utils.tbl_to_hex(color);
		end

		vim.api.nvim_set_hl(0, (config_table.prefix or "Colors") .. i, _hl);
	end
end

colors.render_dynamic_color = function (config_table)
	if not config_table.value or not pcall(config_table.value, utils) then
		error("Invalid dynamic highlight group");
	end

	local _hl = config_table.value(utils);

	if vim.islist(_hl) then
		for _, color in ipairs(_hl) do
			vim.api.nvim_set_hl(0, color.group_name, color.value);
		end
	elseif type(_hl) == "table" and _hl.group_name and _hl.value then
		vim.api.nvim_set_hl(0, _hl.group_name, _hl.value);
	end
end

colors.init = function ()
	for _, color in ipairs(colors.configuraton) do
		if color.type == "hl" then
			colors.hl_applier(color);
		elseif color.type == "gradient" then
			colors.gradient_applier(color);
		elseif color.type == "dynamic" then
			colors.render_dynamic_color(color);
		end
	end
end

colors.setup = function (config_table)
	colors.configuraton = vim.list_extend(colors.configuraton, config_table or {});
	colors.init();

	if not colors.created_autocmd then
		vim.api.nvim_create_autocmd({ "Colorscheme" }, {
			callback = function ()
				colors.init();
			end
		})

		colors.created_autocmd = true;
	end
end

return colors;
