@ECHO OFF
for %%f in (.minttyrc .vimrc .wslconfig) do (
  if not exist %userprofile%\%%f (
    mklink /j %userprofile%\%%f %userprofile%\setup-files\%%f
  )
)
