#
# Author:: Nuo Yan (<nuo@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'erb'
require 'find'
require 'chef/knife'

class Chef
  class Knife
    class CookbookCreate < Knife

      # Defines the path to the default cookbook template.
      DEFAULT_COOKBOOK_TEMPLATE = File.expand_path('../cookbook_create/template', __FILE__)

      # Provides a binding context for cookbook templates.
      class Context

        # Initializes a new instance of the {Context} class.
        #
        # @param [Hash] hash the hash defining the binding variables and values.
        def initialize(hash)
          hash.each do |key, value|
            singleton_class.send(:define_method, key) { value }
          end
        end

        # Evaluates the +erb+ in the context of this context.
        #
        # @param [ERB] erb the ERB to evaluate
        # @return [String] the result of the evaluation
        def evaluate(erb)
          erb.result(binding)
        end

      end

      deps do
        require 'chef/json_compat'
        require 'uri'
        require 'fileutils'
      end

      banner "knife cookbook create COOKBOOK (options)"

      option :cookbook_path,
        :short => "-o PATH",
        :long => "--cookbook-path PATH",
        :description => "The directory where the cookbook will be created"

      option :readme_format,
        :short => "-r FORMAT",
        :long => "--readme-format FORMAT",
        :description => "Format of the README file, supported formats are 'md' (markdown) and 'rdoc' (rdoc)"

      option :cookbook_license,
        :short => "-I LICENSE",
        :long => "--license LICENSE",
        :description => "License for cookbook, apachev2, gplv2, gplv3, mit or none"

      option :cookbook_copyright,
        :short => "-C COPYRIGHT",
        :long => "--copyright COPYRIGHT",
        :description => "Name of Copyright holder"

      option :cookbook_email,
        :short => "-m EMAIL",
        :long => "--email EMAIL",
        :description => "Email address of cookbook maintainer"

      option :cookbook_template,
        :short => "-t TEMPLATE",
        :long => "--template TEMPLATE",
        :description => "The directory containing a cookbook template"

      def run
        self.config = Chef::Config.merge!(config)
        if @name_args.length < 1
          show_usage
          ui.fatal("You must specify a cookbook name")
          exit 1
        end

        if parameter_empty?(Chef::Config[:cookbook_path]) && parameter_empty?(config[:cookbook_path])
          raise ArgumentError, "Default cookbook_path is not specified in the knife.rb config file, and a value to -o is not provided. Nowhere to write the new cookbook to."
        end

        cookbook_name = @name_args.first
        cookbook_path = File.expand_path(Array(config[:cookbook_path]).first)
        cookbook_template = parameter_empty?(config[:cookbook_template]) ? DEFAULT_COOKBOOK_TEMPLATE : config[:cookbook_template]
        cookbook_context = Context.new(
          cookbook_name: cookbook_name,
          copyright: config[:cookbook_copyright] || 'YOUR_COMPANY_NAME',
          email: config[:cookbook_email] || 'YOUR_EMAIL',
          license: ((config[:cookbook_license] != 'false') && config[:cookbook_license]) || 'none',
          readme_format: ((config[:readme_format] != 'false') && config[:readme_format]) || 'md'
        )
        materialize_path =  File.join(cookbook_path, cookbook_name)
        materialize_files(File.join(cookbook_template, 'files'), materialize_path)
        materialize_templates(File.join(cookbook_template, 'templates'), materialize_path, cookbook_context)
      end

      private

      # Recursively copies the files from the +files_path+ to the +materialize_path+.
      #
      # @param [String] files_path the absolute path to the directory containing the files to materialize
      # @param [String] materialize_path the absolute path to the directory in which the files are materialized
      def materialize_files(files_path, materialize_path)
        Find.find(files_path).each do |source_path|
          destination_path = source_path.gsub(/^#{files_path}/, materialize_path)
          if File.directory?(source_path)
            FileUtils.mkdir_p(destination_path)
          else
            msg("** Creating #{destination_path}")
            FileUtils.cp(source_path, destination_path) # unless File.exist?(destination_path)
          end
        end
      end

      # Recursively materializes the templates from the +templates_path+ to the +materialize_path+ with the provided +context+.
      #
      # @param [String] templates_path the absolute path to the directory containing the templates to materialize
      # @param [String] materialize_path the absolute path to the directory in which the templates are materialized
      # @param [Context] context the context used to materialize templates
      def materialize_templates(templates_path, materialize_path, context)
        Find.find(templates_path).each do |source_path|
          destination_path = source_path.gsub(/^#{templates_path}/, materialize_path).gsub(/\.erb$/, '')
          if File.directory?(source_path)
            FileUtils.mkdir_p(destination_path)
          else
            unless File.exist?(destination_path)
              msg("** Creating #{destination_path}")
              File.open(destination_path, 'w') do |file|
                file.write(context.evaluate(ERB.new(File.read(source_path), nil, '-')))
              end
            end
          end
        end
      end

      # Returns a value indicating whether the provided parameter is nil or an empty string.
      #
      # @param [Object] parameter the parameter to check
      # @return [Boolean] true if the parameter is nil or an empty string; otherwise, false
      def parameter_empty?(parameter)
        parameter.nil? || parameter.empty?
      end
    end
  end
end
