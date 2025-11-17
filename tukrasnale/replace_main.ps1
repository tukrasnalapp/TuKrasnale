# Delete old main.dart and replace with fixed version
Remove-Item "c:\Repo\TuKrasnale\tukrasnale\lib\main.dart"
Move-Item "c:\Repo\TuKrasnale\tukrasnale\lib\main_fixed.dart" "c:\Repo\TuKrasnale\tukrasnale\lib\main.dart"