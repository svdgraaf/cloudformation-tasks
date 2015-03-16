
module SpaarspotTasks
  module Helper
    def autoscaling
      @autoscaling ||= ::AWS::AutoScaling.new.client
    end

    def s3
      @s3 ||= ::AWS::S3.new
    end

    def stack_resource_name(resource_name, stack_name=ENV['STACK_NAME'])
      "#{stack_name}-#{resource_name}"
    end

    def autoscaling_group_name(asg_name)
      response = aws_api_request do
        autoscaling.describe_auto_scaling_groups
      end
      asgs = response[:auto_scaling_groups].select { |h| h[:auto_scaling_group_arn].include? asg_name }
      asgs.first[:auto_scaling_group_name]
    rescue NoMethodError => e
      $stderr.puts "Autoscaling group #{asg_name} not found"
      raise e
    end

    def aws_api_request(description = nil)
      response = yield
      if response.http_response.status != 200
        raise "#{description} FAILED"
      end
      response
    end

    def execute_task(task, args)
      rescue_on_fail(task) do
        invoke_for_all(task, args)
      end
    end

    def rescue_on_fail(task)
      yield
    rescue
      $stderr.puts "Task #{task} failed to execute"
      raise
    end
  end
end
