def prompt(*args)
  print(*args)
  STDIN.gets.strip
end

def inform(string)
  "\e[32m#{string}\e[0m"
end

def warn(string)
  "\e[35m#{string}\e[0m"
end
