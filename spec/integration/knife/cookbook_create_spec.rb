require 'securerandom'
require 'tmpdir'

require 'spec_helper'

describe Chef::Knife::CookbookCreate do

  let(:knife) { described_class.new }
  let(:cookbook_copyright) { SecureRandom.hex }
  let(:cookbook_email) { SecureRandom.hex }
  let(:cookbook_license) { SecureRandom.hex }
  let(:cookbook_name) { SecureRandom.hex }
  let(:cookbook_path) { SecureRandom.hex }
  let(:cookbook_template) { SecureRandom.hex }
  let(:readme_format) { SecureRandom.hex }

  describe '#run' do

    let(:example_directory) { @example_directory }
    let(:template_directory) { @template_directory }

    around(:each) do |example|
      Dir.mktmpdir do |example_directory|
        @example_directory = example_directory
        @template_directory = File.join(example_directory, 'template')

        @files.directory = File.join(@template_directory, 'files')
        @templates.directory = File.join(@template_directory, 'templates')
        example.run
      end
    end
  end
end