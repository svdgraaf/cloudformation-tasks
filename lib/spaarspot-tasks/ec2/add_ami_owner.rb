require 'spaarspot-tasks/dotenv'
require 'spaarspot-tasks/locksmith/assume_role'

require 'aws-sdk'

module SpaarspotTasks
  module Ec2
    class AddAmiOwner
      include Rake::DSL if defined? Rake::DSL

      def install_tasks
        namespace :ec2 do
          desc 'Add AMI account owners'
          task :add_ami_owner, [:ami_id] => ['locksmith:assume_role_if_needed'] do |t, args|
            prompted = false
            # Use AMI id or prompt user
            if args.ami_id.nil? || args.ami_id.empty?
              prompted = true
              ami_id = prompt inform 'Specify AWS AMI id: '
            else
              ami_id = args.ami_id
            end
            # Fetch AMI
            image = find_ami(ami_id)
            # Use AWS account ids or prompt user
            if args.extras.empty? && prompted
              aws_account_ids = prompt inform 'Specify comma seperated list of AWS account ids: '
            elsif !args.extras.empty?
              aws_account_ids = args.extras.join(',')
            elsif !ENV['SHARED_AMI_OWNERS'].nil? && !ENV['SHARED_AMI_OWNERS'].empty?
              aws_account_ids = ENV['SHARED_AMI_OWNERS']
            end
            # Add AMI owners
            add_ami_owners(image, aws_account_ids)
          end
        end
      end

      def ec2
        @ec2 ||= AWS::EC2.new
      end

      def find_ami(ami_id)
        # Validate input
        abort 'Error: No AMI id specified' if ami_id.empty?
        # Fetch AMI/Image
        image = ec2.images.with_owner(ENV['AWS_ACCOUNT']).select{|i| i.id == ami_id }.first
        abort "Error: Could not find ami with id #{ami_id}" if image.nil?
        return image
      end

      def add_ami_owners(image, aws_account_ids)
        # Validate input
        abort 'Error: No AWS accounts specified' if aws_account_ids.empty?
        # Add owners to AMI/Image
        aws_account_ids = aws_account_ids.split(/,\s*|\s+/).map(&:strip)
        image.permissions.add(*aws_account_ids)
        # Confirmation message
        $stderr.puts inform "Updated #{image.id} ownership permissions to:"
        $stderr.puts image.permissions.map{|p| p}.join(', ')
      end
    end
  end
end

SpaarspotTasks::Ec2::AddAmiOwner.new.install_tasks
