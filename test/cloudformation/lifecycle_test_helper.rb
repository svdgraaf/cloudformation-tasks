
def stub_aws_calls
  @lifecycle.stub :lifecycle_hook_present?, false do
    @lifecycle.stub :sqs_iam_role_arn, @hook_desc[:role] do
      @lifecycle.stub :lifecycle_queue, @hook_desc[:notification_target] do
        @lifecycle.stub :autoscaling_group_name, @hook_desc[:auto_scaling_group_name] do
          yield
        end
      end
    end
  end
end

def it_should_raise_when_missing(attribute)
  before do
    @hook_desc.delete(attribute)
  end

  it 'should raise ArgumentError' do
    stub_aws_calls do
      proc { @lifecycle.form_lifecycle_description(@hook_desc) }.must_raise ArgumentError
    end
  end
end
