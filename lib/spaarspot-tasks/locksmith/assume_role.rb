require 'aws-sdk'
require 'spaarspot-tasks/dotenv'

module SpaarspotTasks
  module Locksmith
    class AssumeRole
      include Rake::DSL if defined? Rake::DSL

      def ask(question)
        $stdout.print "#{question} "
        $stdout.flush
        $stdin.gets.strip
      end

      def install_tasks
        namespace :locksmith do
          desc 'Assume cross account role if no credentials are set'
          task :assume_role_if_needed do
            not_needed = true

            [
              'AWS_ACCESS_KEY_ID',
              'AWS_SECRET_ACCESS_KEY',
            ].each do |var|
              if !ENV[var] or ENV[var].strip.empty?
                not_needed = false
              end
            end

            Rake::Task['locksmith:assume_role'].invoke unless not_needed
          end

          desc 'Assume cross account role'
          task :assume_role, [:token_code] => [:check_environment] do |t, args|
            sts = AWS::STS.new(
              access_key_id:     ENV['LS_AWS_ACCESS_KEY_ID'],
              secret_access_key: ENV['LS_AWS_SECRET_ACCESS_KEY']
            )

            begin
              options = {
                role_arn: "arn:aws:iam::#{ENV['AWS_ACCOUNT']}:role/#{ENV['AWS_ROLE']}",
                role_session_name: "AssumeRoleSession",
              }

              if args[:token_code] != nil and args[:token_code].to_s.strip != ''
                options.merge!(
                  serial_number: ENV['LS_AWS_MFA_SERIAL'],
                  token_code: args[:token_code]
                )
              end

              assumed_role = sts.assume_role(options)

              ENV['ASSUMED_ROLE_USER'] = \
                assumed_role[:assumed_role_user][:arn]
              ENV['ASSUMED_ROLE_ID'] = \
                assumed_role[:assumed_role_user][:assumed_role_id]
              ENV['AWS_SESSION_TOKEN'] = \
                assumed_role[:credentials][:session_token]
              ENV['AWS_ACCESS_KEY_ID'] = \
                assumed_role[:credentials][:access_key_id]
              ENV['AWS_SECRET_ACCESS_KEY'] = \
                assumed_role[:credentials][:secret_access_key]
            rescue AWS::STS::Errors::AccessDenied
              otp = ask("Token code:")
              Rake::Task['locksmith:assume_role'].reenable
              Rake::Task['locksmith:assume_role'].invoke(otp)
            end
          end

          task :check_environment do
            [
              'LS_AWS_ACCESS_KEY_ID',
              'LS_AWS_SECRET_ACCESS_KEY',
              'LS_AWS_MFA_SERIAL'
            ].each do |var|
              if !ENV[var] or ENV[var].strip.empty?
                abort "ERROR: Please set '#{var}' environment variable" \
                      " (in '~/.env.private')"
              end
            end

            [
              'AWS_ACCOUNT',
            ].each do |var|
              if !ENV[var] or ENV[var].strip.empty?
                abort "ERROR: Please set '#{var}' environment variable" \
                      " (in '.env')"
              end
            end

            [
              'AWS_ROLE'
            ].each do |var|
              if !ENV[var] or ENV[var].strip.empty?
                abort "ERROR: Please set '#{var}' environment variable" \
                      " (in '.env.private')"
              end
            end
          end
        end
      end
    end
  end
end

SpaarspotTasks::Locksmith::AssumeRole.new.install_tasks
