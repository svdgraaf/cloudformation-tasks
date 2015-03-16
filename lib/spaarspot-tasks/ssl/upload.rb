require 'spaarspot-tasks/dotenv'
require 'spaarspot-tasks/checks'

require 'aws-sdk'

module SpaarspotTasks
  module SSL
    class Upload
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        namespace :ssl do
          desc 'Upload SSL certificate to server'
          task :upload do
            check_aws_credentials

            iam = AWS::IAM.new
            cert = iam.server_certificates.upload(
              name: ENV['STACK_NAME'],
              certificate_body: File.read('ssl/public.crt'),
              private_key: File.read('ssl/private.key')
            )
            $stderr.puts "Please set: SSL_CERTIFICATE_ARN = #{cert.arn}"
          end
        end
      end
    end
  end
end

SpaarspotTasks::SSL::Upload.new.install_tasks

