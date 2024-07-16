local pickers = {};
local utils = require("colors/utils");

pickers.color_picker = {
	from = nil,
	from_win = nil,

	rgb_picker = vim.api.nvim_create_buf(false, true),
	txt_picker = vim.api.nvim_create_buf(false, true),
	history = vim.api.nvim_create_buf(false, true),

	rgb_win = nil,
	txt_win = nil,
	history_win = nil,

	__ns = vim.api.nvim_create_namespace("color_picker"),
	__r = 0,
	__g = 0,
	__b = 0,

	history_values = {},
	history_index = 1,

	get_level = function (value)
		local val_per_lvl = 255 / 10;
		local lvl = math.floor(value / val_per_lvl);

		return math.min(math.max(lvl, 1), 10);
	end,
	get_layout_position = function ()
		local width, height = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0);
		local layout_w, layout_h = 34, 10;

		return { math.floor((width - layout_w) / 2), math.floor((height - layout_h) / 2) }
	end,
	prepare_window = function (window, buffer)
		vim.bo[buffer].filetype = "Colors";

		vim.wo[window].number = false;
		vim.wo[window].relativenumber = false;
		vim.wo[window].statuscolumn = "";

		vim.wo[window].spell = false;
		vim.wo[window].cursorline = false;
	end,
	create_hls = function (self)
		local bg = utils.get_value({ name = "Normal" }, "fg");

		for i = 0, 9 do
			local v = utils.lerp(0, 255, i / 9);

			vim.api.nvim_set_hl(0, "Colors_r_" .. (i + 1), {
				fg = utils.tbl_to_hex({ r = v, g = 0, b = 0 }),
				bg = utils.tbl_to_hex(bg)
			});
			vim.api.nvim_set_hl(0, "Colors_g_" .. (i + 1), {
				fg = utils.tbl_to_hex({ r = 0, g = v, b = 0 }),
				bg = utils.tbl_to_hex(bg)
			});
			vim.api.nvim_set_hl(0, "Colors_b_" .. (i + 1), {
				fg = utils.tbl_to_hex({ r = 0, g = 0, b = v }),
				bg = utils.tbl_to_hex(bg)
			});
		end

		local fg = ((self.__r + self.__g + self.__b) / (3 * 255)) > 0.5 and "#000000" or"#ffffff";

		vim.api.nvim_set_hl(0, "Colors_current", {
			fg = utils.tbl_to_hex({ r = self.__r, g = self.__g, b = self.__b })
		});
		vim.api.nvim_set_hl(0, "Colors_current_alt", {
			fg = fg,
			bg = utils.tbl_to_hex({ r = self.__r, g = self.__g, b = self.__b })
		});
	end,
	create_ui = function (self)
		local r_lvl = self.get_level(self.__r);
		local g_lvl = self.get_level(self.__g);
		local b_lvl = self.get_level(self.__b);

		vim.bo[self.rgb_picker].modifiable = true;

		vim.api.nvim_buf_set_lines(self.rgb_picker, 0, -1, false, {
			"R: ",
			"G: ",
			"B: ",
			"",
			"Color:"
		});

		vim.bo[self.rgb_picker].modifiable = false;

		local slider_r = {};
		local slider_g = {};
		local slider_b = {};

		for i = 1, 10 do
			if i == r_lvl then
				table.insert(slider_r, { "▞", "Colors_r_" .. i })
			else
				table.insert(slider_r, { "█", "Colors_r_" .. i })
			end

			if i == g_lvl then
				table.insert(slider_g, { "▞", "Colors_g_" .. i })
			else
				table.insert(slider_g, { "█", "Colors_g_" .. i })
			end

			if i == b_lvl then
				table.insert(slider_b, { "▞", "Colors_b_" .. i })
			else
				table.insert(slider_b, { "█", "Colors_b_" .. i })
			end
		end

		table.insert(slider_r, { string.format(" %3d", self.__r) });
		table.insert(slider_g, { string.format(" %3d", self.__g) });
		table.insert(slider_b, { string.format(" %3d", self.__b) });

		vim.api.nvim_buf_clear_namespace(self.rgb_picker, self.__ns, 0, -1);

		vim.api.nvim_buf_set_extmark(self.rgb_picker, self.__ns, 0, 3, {
			virt_text = slider_r,
			hl_mode = "combine",
		});
		vim.api.nvim_buf_set_extmark(self.rgb_picker, self.__ns, 1, 3, {
			virt_text = slider_g,
			hl_mode = "combine",
		});
		vim.api.nvim_buf_set_extmark(self.rgb_picker, self.__ns, 2, 3, {
			virt_text = slider_b,
			hl_mode = "combine",
		});


		vim.api.nvim_buf_set_extmark(self.rgb_picker, self.__ns, 4, 3, {
			virt_text_pos = "eol",
			virt_text = {
				{ utils.tbl_to_hex({ r = self.__r, g = self.__g, b = self.__b }), "Colors_current_alt" },
				{ " ██", "Colors_current" },
			},

			hl_mode = "combine",
		});
	end,
	create_hl_text = function (self)
		vim.api.nvim_buf_set_lines(self.txt_picker, 0, -1, false, {
			utils.tbl_to_hex({ r = self.__r, g = self.__g, b = self.__b })
		})
	end,
	create_history = function (self)
		vim.api.nvim_buf_set_lines(self.history, 0, -1, false, self.history_values);
		vim.api.nvim_buf_clear_namespace(self.history, self.__ns, 0, -1);

		for l, _ in ipairs(self.history_values) do
			vim.api.nvim_buf_set_extmark(self.history, self.__ns, l - 1, 0, {
				virt_text_pos = "inline",
				virt_text = { { "  ", "Special" } },

				line_hl_group = l == self.history_index and "CursorLine" or nil,
				hl_mode = "combine"
			})
		end
	end,
	write = function (self, txt)
		local from_pos = vim.api.nvim_win_get_cursor(self.from_win);

		if not txt then
			table.insert(self.history_values, utils.tbl_to_hex({ r = self.__r, g = self.__g, b = self.__b }));
		end

		vim.api.nvim_buf_set_text(self.from, from_pos[1] - 1, from_pos[2], from_pos[1] - 1, from_pos[2], {
			txt or utils.tbl_to_hex({ r = self.__r, g = self.__g, b = self.__b })
		});
	end,

	set_keymaps = function (self)
		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "<left>", "", {
			callback = function ()
				local Y = vim.api.nvim_win_get_cursor(self.rgb_win)[1];

				if Y == 1 and (self.__r - 1) > 0 then
					self.__r = self.__r - 1;
				elseif Y == 2 and (self.__g - 1) > 0 then
					self.__g = self.__g - 1;
				elseif Y == 3 and (self.__b - 1) > 0 then
					self.__b = self.__b - 1;
				end

				self:create_hls();
				self:create_hl_text();
				self:create_ui();
			end
		});
		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "h", "", {
			callback = function ()
				local Y = vim.api.nvim_win_get_cursor(self.rgb_win)[1];

				if Y == 1 and (self.__r - 5) > 0 then
					self.__r = self.__r - 5;
				elseif Y == 2 and (self.__g - 5) > 0 then
					self.__g = self.__g - 5;
				elseif Y == 3 and (self.__b - 5) > 0 then
					self.__b = self.__b - 5;
				end

				self:create_hls();
				self:create_hl_text();
				self:create_ui();
			end
		});

		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "<right>", "", {
			callback = function ()
				local Y = vim.api.nvim_win_get_cursor(self.rgb_win)[1];

				if Y == 1 and (self.__r + 1) <= 255 then
					self.__r = self.__r + 1;
				elseif Y == 2 and (self.__g + 1) <= 255 then
					self.__g = self.__g + 1;
				elseif Y == 3 and (self.__b + 1) <= 25 then
					self.__b = self.__b + 1;
				end

				self:create_hls();
				self:create_hl_text();
				self:create_ui();
			end
		})
		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "l", "", {
			callback = function ()
				local Y = vim.api.nvim_win_get_cursor(self.rgb_win)[1];

				if Y == 1 and (self.__r + 5) <= 255 then
					self.__r = self.__r + 5;
				elseif Y == 2 and (self.__g + 5) <= 255 then
					self.__g = self.__g + 5;
				elseif Y == 3 and (self.__b + 5) <= 25 then
					self.__b = self.__b + 5;
				end

				self:create_hls();
				self:create_hl_text();
				self:create_ui();
			end
		});


		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "q", ":q<CR>", { silent = true })
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "q", ":q<CR>", { silent = true })

		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "<tab>", "", {
			callback = function ()
				local current = vim.api.nvim_get_current_win();

				if current == self.rgb_win then
					vim.api.nvim_set_current_win(self.txt_win);
				elseif current == self.txt_win then
					vim.api.nvim_set_current_win(self.rgb_win);
				end
			end
		})
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "<tab>", "", {
			callback = function ()
				local current = vim.api.nvim_get_current_win();

				if current == self.rgb_win then
					vim.api.nvim_set_current_win(self.txt_win);
				elseif current == self.txt_win then
					vim.api.nvim_set_current_win(self.rgb_win);
				end
			end
		})

		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "<enter>", "", {
			callback = function ()
				self:create_history();
				self:write();
				vim.cmd("q");
			end
		})
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "<enter>", "", {
			callback = function ()
				self:create_history();
				self:write();
				vim.cmd("q");
			end
		})

		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "j", "", {
			callback = function ()
				if self.history_index - 1 > 0 then
					self.history_index = self.history_index - 1;
				elseif not vim.tbl_isempty(self.history_values) then
					self.history_index = #self.history_values
				end

				self:create_history();
			end
		})
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "j", "", {
			callback = function ()
				if self.history_index - 1 > 0 then
					self.history_index = self.history_index - 1;
				elseif not vim.tbl_isempty(self.history_values) then
					self.history_index = #self.history_values
				end

				self:create_history();
			end
		})
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "<up>", "", {
			callback = function ()
				if self.history_index - 1 > 0 then
					self.history_index = self.history_index - 1;
				elseif not vim.tbl_isempty(self.history_values) then
					self.history_index = #self.history_values
				end

				self:create_history();
			end
		})
		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "k", "", {
			callback = function ()
				if self.history_index + 1 <= #self.history_values then
					self.history_index = self.history_index + 1;
				else
					self.history_index = 1;
				end

				self:create_history();
			end
		})
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "k", "", {
			callback = function ()
				if self.history_index + 1 <= #self.history_values then
					self.history_index = self.history_index + 1;
				else
					self.history_index = 1;
				end

				self:create_history();
			end
		})
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "<down>", "", {
			callback = function ()
				if self.history_index + 1 <= #self.history_values then
					self.history_index = self.history_index + 1;
				else
					self.history_index = 1;
				end

				self:create_history();
			end
		})

		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "w", "", {
			callback = function ()
				if vim.tbl_isempty(self.history_values) then
					return;
				end

				self:write(self.history_values[self.history_index]);
				vim.cmd("q");
			end
		})
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "w", "", {
			callback = function ()
				if vim.tbl_isempty(self.history_values) then
					return;
				end

				self:write(self.history_values[self.history_index]);
				vim.cmd("q");
			end
		})


		vim.api.nvim_buf_set_keymap(self.rgb_picker, "n", "W", "", {
			callback = function ()
				if vim.tbl_isempty(self.history_values) then
					return;
				end

				local _o = "";

				for i, value in ipairs(self.history_values) do
					_o = _o .. value;

					if i ~= #self.history_values then
						_o = _o .. ", ";
					end
				end

				self.history_values = {};
				self.history_index = 1;

				self:write(_o);
				vim.cmd("q");
			end
		});
		vim.api.nvim_buf_set_keymap(self.txt_picker, "n", "W", "", {
			callback = function ()
				if vim.tbl_isempty(self.history_values) then
					return;
				end

				local _o = "";

				for i, value in ipairs(self.history_values) do
					_o = _o .. value;

					if i ~= #self.history_values then
						_o = _o .. ", ";
					end
				end

				self.history_values = {};
				self.history_index = 1;

				self:write(_o);
				vim.cmd("q");
			end
		});
	end,
	set_autocmd = function (self)
		vim.api.nvim_create_autocmd({ "WinClosed" }, {
			group = self.__au,
			buffer = self.rgb_picker,

			callback = function ()
				if vim.api.nvim_win_is_valid(self.history_win) then
					vim.api.nvim_win_close(self.history_win, true);
				end

				if vim.api.nvim_win_is_valid(self.txt_win) then
					vim.api.nvim_win_close(self.txt_win, true);
				end
			end
		});
		vim.api.nvim_create_autocmd({ "WinClosed" }, {
			group = self.__au,
			buffer = self.txt_picker,

			callback = function ()
				if vim.api.nvim_win_is_valid(self.rgb_win) then
					vim.api.nvim_win_close(self.rgb_win, true);
				end

				if vim.api.nvim_win_is_valid(self.history_win) then
					vim.api.nvim_win_close(self.history_win, true);
				end
			end
		});
		vim.api.nvim_create_autocmd({ "WinClosed" }, {
			group = self.__au,
			buffer = self.history,

			callback = function ()
				if vim.api.nvim_win_is_valid(self.rgb_win) then
					vim.api.nvim_win_close(self.rgb_win, true);
				end

				if vim.api.nvim_win_is_valid(self.txt_win) then
					vim.api.nvim_win_close(self.txt_win, true);
				end
			end
		});


		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			group = self.__au,
			buffer = self.txt_picker,

			callback = function ()
				local lines = vim.api.nvim_buf_get_lines(self.txt_picker, 0, -1, false);

				if pcall(utils.hex_to_tbl, lines[1]) then
					local _o = utils.hex_to_tbl(lines[1]);

					self.__r = _o.r or self.__r;
					self.__g = _o.g or self.__g;
					self.__b = _o.b or self.__b;

					self:create_hls();
					self:create_ui();
					self:create_history();
				end
			end
		})
	end,
	init = function (self)
		self.from = vim.api.nvim_get_current_buf();
		self.from_win = vim.api.nvim_get_current_win();

		local start_pos = self.get_layout_position();

		self.rgb_win = vim.api.nvim_open_win(self.rgb_picker, true, {
			relative = "editor",

			row = start_pos[2], col = start_pos[1],
			width = 20, height = 5,

			title = " RGB color ",
			border = "rounded"
		});
		self.txt_win = vim.api.nvim_open_win(self.txt_picker, false, {
			relative = "editor",

			row = start_pos[2] + 7, col = start_pos[1],
			width = 20, height = 1,

			title = " Input ",
			border = "rounded"
		});
		self.history_win = vim.api.nvim_open_win(self.history, false, {
			relative = "editor",

			row = start_pos[2], col = start_pos[1] + 22,
			width = 12, height = 8,

			focusable = false,
			title = " History ",
			border = "rounded"
		});

		self.prepare_window(self.rgb_win, self.rgb_picker)
		self.prepare_window(self.txt_win, self.txt_picker)
		self.prepare_window(self.history_win, self.history)

		if not self.__au then
			self.__au = vim.api.nvim_create_augroup("color_picker", {});
			self:set_autocmd(self.rgb_picker);
		end

		self:create_hls();
		self:create_hl_text();
		self:create_ui();
		self:create_history();

		if not self.__set_keymap then
			self:set_keymaps();
			self.__set_keymap = true;
		end
	end
}

return pickers;
