local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
	-- main function boilerplate
	s("main", {
		t({ "#include <stdio.h>", "", "int main(void) {", "\t" }),
		i(1, "// your code"),
		t({ "", "\treturn 0;", "}" }),
	}),

	-- for loop
	s("for", {
		t("for (int "),
		i(1, "i"),
		t(" = 0; "),
		i(2, "i"),
		t(" < "),
		i(3, "n"),
		t("; "),
		i(4, "i"),
		t({ "++) {", "\t" }),
		i(5),
		t({ "", "}" }),
	}),
}
