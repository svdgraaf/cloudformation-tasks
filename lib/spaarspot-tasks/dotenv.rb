require 'dotenv'

Dotenv.load File.expand_path('~/.env.private')
Dotenv.load '.env.private'
Dotenv.load '.env'
Dotenv.load ".env.#{ENV['ENVIRONMENT']}" if ENV['ENVIRONMENT'].to_s.strip != ''
