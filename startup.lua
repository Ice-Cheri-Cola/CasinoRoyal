local ok, problem = pcall(function()
    shell.run("casino.lua")
end)

if not ok then
    term.setTextColor(colors.red)
    print("Casino Royal failed to start:")
    term.setTextColor(colors.white)
    print(tostring(problem))
end
