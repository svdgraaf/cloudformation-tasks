require_relative '../test_helper'

describe SpaarspotTasks::CloudFormation::ConfigLoader do
  before do
    @loader = SpaarspotTasks::CloudFormation::ConfigLoader
  end

  describe '#load' do
    describe 'when config file given' do
      describe 'and file exists' do
        it 'should return Hash' do
          YAML.stub :load_file, { success: true } do
            @loader.load('config_file').must_be_kind_of Hash
          end
        end
      end

      describe 'and file does not exist' do
        it 'should raise IO' do
          proc { @loader.load('config_file.yml') }.must_raise Errno::ENOENT
        end
      end
    end

    describe 'no config file is given' do
      describe 'and config.yml esists' do
        it 'should return Hash' do
          YAML.stub :load_file, { success: true } do
            @loader.load.must_be_kind_of Hash
          end
        end
      end

      describe 'and file does not exist' do
        it 'should raise IO' do
          proc { @loader.load }.must_raise Errno::ENOENT
        end
      end
    end
  end
end
