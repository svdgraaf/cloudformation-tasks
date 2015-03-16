require_relative '../test_helper'
require_relative './lifecycle_test_helper'

describe SpaarspotTasks::CloudFormation::Lifecycle do
  before do
    @lifecycle = SpaarspotTasks::CloudFormation::Lifecycle.new
  end

  describe '#form_lifecycle_description' do
    describe 'when input is valid' do
      before do
        @hook_desc = {
          name: 'worker_termination_hook',
          auto_scaling_group_name: 'ApiAutoScalingGroup',
          lifecycle_transition: 'autoscaling:EC2_INSTANCE_TERMINATING',
          notification_target: 'LifecycleMgmtQueue',
          role: 'SpaarspotWorkerIamLifecycleRole'
        }
      end

      it 'should return a valid hook description' do
        stub_aws_calls do
          formed_hook = @lifecycle.form_lifecycle_description(@hook_desc)
          formed_hook.must_include :role_arn
          formed_hook.must_include :notification_target_arn
          formed_hook.must_include :auto_scaling_group_name
          formed_hook.must_include :lifecycle_hook_name
          formed_hook.wont_include :name
          formed_hook[:role_arn].must_equal @hook_desc[:role]
          formed_hook[:notification_target_arn].must_equal @hook_desc[:notification_target]
          formed_hook[:auto_scaling_group_name].must_equal @hook_desc[:auto_scaling_group_name]
          formed_hook[:lifecycle_hook_name].must_equal @hook_desc[:name]
        end
      end

      describe 'when input is invalid' do
        describe 'no hook name given' do
          it_should_raise_when_missing(:name)
        end

        describe 'no hook auto_scaling_group_name given' do
          it_should_raise_when_missing(:auto_scaling_group_name)
        end

        describe 'no hook lifecycle_transition given' do
          it_should_raise_when_missing(:lifecycle_transition)
        end

        describe 'no hook role given' do
          it_should_raise_when_missing(:role)
        end

        describe 'no hook notification_target given' do
          it_should_raise_when_missing(:notification_target)
        end
      end
    end
  end

  describe '#lifecycle_hook_present?' do
    before do
      @hook_desc = {
        name: 'worker_termination_hook',
        auto_scaling_group_name: 'ApiAutoScalingGroup',
        lifecycle_transition: 'autoscaling:EC2_INSTANCE_TERMINATING',
        notification_target: 'LifecycleMgmtQueue',
        role: 'SpaarspotWorkerIamLifecycleRole'
      }
    end

    describe 'when hook is not present' do
      it 'should return false' do
        @lifecycle.autoscaling.stub :describe_lifecycle_hooks, { lifecycle_hooks: [] } do
          @lifecycle.lifecycle_hook_present?(@hook_desc).must_equal false
        end
      end
    end

    describe 'when hook is  present' do
      it 'should return true' do
        @lifecycle.autoscaling.stub :describe_lifecycle_hooks,
          { lifecycle_hooks: [ {
            autoscaling_group_name: 'ApiAutoScalingGroup',
            lifecycle_transition:'autoscaling:EC2_INSTANCE_TERMINATING'}]
          } do
            @lifecycle.lifecycle_hook_present?(@hook_desc).must_equal true
        end
      end

      describe 'but on a different transition' do
        it 'should return false' do
          @lifecycle.autoscaling.stub :describe_lifecycle_hooks,
            { lifecycle_hooks: [ {
              autoscaling_group_name: 'ApiAutoScalingGroup',
              lifecycle_transition:'autoscaling:EC2_INSTANCE_LAUNCHING'}]
            } do
              @lifecycle.lifecycle_hook_present?(@hook_desc).must_equal false
          end
        end
      end
    end
  end
end
