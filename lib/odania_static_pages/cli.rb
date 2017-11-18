require_relative 'cli/deploy_cli'
require_relative 'cli/generator_cli'

module OdaniaStaticPages
	class Cli < Thor
		class_option :environment, default: 'develop', aliases: '-e', desc: 'Environment'

		def initialize(*args)
			super

			OdaniaStaticPages.config.environment = options[:environment]
		end

		desc 'new <path>', 'creates a new project'
		def new(path='.')
			path = File.absolute_path path
			puts "Generating project under #{path}"

			FileUtils.mkdir_p path unless File.exist? path
			config = OdaniaStaticPages.config path
			config.save!
		end

		desc 'deploy', 'Deploy subcommand'
		subcommand 'deploy', OdaniaStaticPages::DeployCli

		desc 'generate', 'Generate subcommand'
		subcommand 'generate', OdaniaStaticPages::GeneratorCli
	end
end
