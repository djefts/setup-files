@ECHO OFF
for %%f in (.gitconfig .minttyrc .vimrc .wslconfig) do (
::  echo "Attempting to make link for %%f..."
  if not exist "%userprofile%\%%f" (
    mklink /j "%userprofile%\%%f" "%userprofile%\setup-files\%%f"
  )
)
