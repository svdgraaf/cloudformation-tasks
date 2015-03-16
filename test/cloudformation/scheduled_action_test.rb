require_relative '../test_helper'

describe SpaarspotTasks::CloudFormation::ScheduledActions do
  before do
    @schedule = SpaarspotTasks::CloudFormation::ScheduledActions.new
  end

  describe '#scaling_processes' do
    describe 'when none specified' do
      it 'should return empty hash' do
        @schedule.scaling_processes.must_be_empty
        @schedule.scaling_processes.must_be_kind_of Hash
      end
    end

    describe 'when process specified' do
      before do
        @args = { processes: 'ScheduledActions' }
      end
      it 'should return non-empty hash' do
        @schedule.scaling_processes(@args).wont_be_empty
        @schedule.scaling_processes(@args).must_be_kind_of Hash
      end
    end
  end

  describe '#request_params' do
    before do
      @asg_name = 'DemoAutoscalingGroup'
      @args = { processes: 'ScheduledActions' }
    end

    describe 'with valid args' do
      it 'should be valid hash' do
        @schedule.stub :autoscaling_group_name, @asg_name do
          params = @schedule.request_params(@asg_name, nil)
          params.wont_be_empty
          params.must_include :auto_scaling_group_name
          params[:auto_scaling_group_name].must_equal @asg_name
        end
      end

      describe 'with processes specified' do
        it 'should be valid hash' do
          @schedule.stub :autoscaling_group_name, @asg_name do
            params = @schedule.request_params(@asg_name, @args)
            params.wont_be_empty
            params.must_include :scaling_processes
            params[:scaling_processes].must_equal [@args[:processes]]
          end
        end
      end
    end

    describe 'with invalid args' do
      describe 'inexistent asg' do
        it 'should raise error' do
          @schedule.stub :autoscaling_group_name, nil do
            proc { @schedule.request_params(@asg_name, @args) }.must_raise ArgumentError
          end
        end
      end
    end
  end
end
