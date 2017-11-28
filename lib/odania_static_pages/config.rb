require_relative 'config/docker_compose'
require_relative 'config/generator/jekyll'
require_relative 'config/rsync'
require_relative 'config/s3'

module OdaniaStaticPages
	class Config
		attr_accessor :environment
		attr_reader :project_dir, :base_dir, :output_sites_path, :output_nginx_path, :environments,
								:generator_type, :generator

		def initialize(path=nil)
			@base_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
			@project_dir = path.nil? ? Dir.getwd : path
			@output_sites_path = 'sites'
			@output_nginx_path = 'nginx'
			@generator_type = 'Jekyll'
			@environments = {
				develop: Environment.new('_develop', 'DockerCompose'),
				live: Environment.new('_live', 'Rsync')
			}
			@generator = Generator::Jekyll.new(@project_dir, {})
		end

		def load!
			if File.exist? config_file
				config = YAML.load_file(config_file).stringify_keys!
				@output_sites_path = config['output_sites_path'] unless config['output_sites_path'].nil?
				@output_nginx_path = config['output_nginx_path'] unless config['output_nginx_path'].nil?
				@generator_type = config['generator_type'] unless config['generator_type'].nil?

				unless config['environments'].nil?
					@environments = {}
					config['environments'].each_pair do |name, data|
						@environments[name] = Environment.from_hash data
					end
				end

				@deploy = Deploy.from_hash(config['deploy']) unless config['deploy'].nil?

				unless config['generator'].nil?
					generator_config_module = "OdaniaStaticPages::Config::Generator::#{@generator_type}".constantize
					@generator = generator_config_module.from_hash @project_dir, config['generator']
				end
			end

			self
		end

		def config_file
			File.join(@project_dir, '_config.yml')
		end

		def output_site_path
			File.join @project_dir, current_environment.output_path, @output_sites_path
		end

		def output_path
			File.join @project_dir, current_environment.output_path
		end

		def pages_path
			File.join @project_dir, 'pages'
		end

		def current_environment
			if @environments[@environment].nil?
				puts "Environment #{environment} no found!"
				puts "Available Environments: #{@environments.keys}"
				exit 1
			end
			@environments[@environment]
		end

		def save!
			puts "Writing config file #{config_file}"
			File.write config_file, YAML.dump(to_h)
		end

		private

		def to_h
			environment_hash = {}
			@environments.each_pair do |name, environment|
				environment_hash[name.to_s] = environment.to_h
			end

			config = {
				output_sites_path: @output_sites_path,
				output_nginx_path: @output_nginx_path,
				generator_type: @generator_type,
				generator: @generator.to_h,
				environments: environment_hash
			}

			config.stringify_keys!
		end

		class Environment
			attr_reader :output_path, :deploy_type, :deploy_module, :notify

			def initialize(output_path, deploy_type, deploy_module_config={}, notify='echo Switched from OLD-COLOR to NEW-COLOR!')
				@output_path = output_path
				@deploy_type = deploy_type
				@notify = notify
				clazz_name = "OdaniaStaticPages::Config::Deploy::#{deploy_type}"
				@deploy_module = clazz_name.constantize.new deploy_module_config.symbolize_keys!
			end

			def to_h
				{
					output_path: @output_path,
					deploy_type: @deploy_type,
					notify: @notify,
					deploy_config: @deploy_module.to_h
				}.stringify_keys!
			end

			def self.from_hash(data)
				Environment.new data['output_path'], data['deploy_type'], data['deploy_config'], data['notify']
			end

			def do_notify(new_color, old_color)
				unless @notify.nil?
					replaced_notify = @notify.gsub('NEW-COLOR', new_color).gsub('OLD-COLOR', old_color)
					puts "Ececuting notify: #{replaced_notify}"
					puts `#{replaced_notify}`
				end
			end
		end
	end
end
