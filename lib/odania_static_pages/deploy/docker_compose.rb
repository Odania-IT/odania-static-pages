module OdaniaStaticPages
	module Deploy
		class DockerCompose
			def initialize
				@config = OdaniaStaticPages.config
				@environment = @config.current_environment
				@deploy_config = @environment.deploy_module
				@generator_config = @config.generator
				@nginx_dir = File.join(@config.output_path, 'nginx')
				@nginx_conf_dir = File.join(@nginx_dir, 'conf.d')
			end

			def prepare
				puts 'Preparing docker-compose state'
				load_state
				state_path = File.dirname(@deploy_config.state_file)
				FileUtils.mkdir_p state_path unless File.exist? state_path
				save_state
			end

			def publish(color, do_rebuild)
				puts 'docker-compose'
				load_state
				color = color.nil? ? @state[:color] : color
				new_color = 'green'.eql?(color) ? 'blue' : 'green'
				puts " -> Current color: #{color}"
				@site_path = @config.output_site_path
				puts " -> Deploying to color: #{new_color} [Path: #{@site_path}]"

				generate_compose_config
				generate_nginx_config(do_rebuild)
				prepare_varnish

				@config.current_environment.do_notify new_color, color
				puts
				puts "Finished deploying color #{new_color}"
			end

			private

			def load_state
				@state = {color: 'blue'}
				@state = YAML.load_file(@deploy_config.state_file).symbolize_keys! if File.exist? @deploy_config.state_file

				@state
			end

			def save_state
				File.write @deploy_config.state_file, YAML.dump(@state)
			end

			def generate_compose_config
				puts 'Generating docker-compose.yml'
				environment = @config.current_environment
				compose_file = File.join(@config.project_dir, environment.output_path, 'docker-compose.yml')

				puts "Writing docker compose to #{compose_file}"
				docker_compose_generator = DockerComposeGenerator.new @config, environment
				docker_compose_generator.write compose_file
			end

			def generate_nginx_config(do_rebuild)
				vhost_renderer = ERB.new(File.read(File.join(@config.base_dir, 'templates', 'nginx', 'vhost.conf.erb')))
				sites = {}
				grouped_domains.each_pair do |site_name, page_config|
					full_site_name = "#{site_name}.lvh.me"
					puts "Writing vhost for: #{full_site_name}"
					expires = @deploy_config.expires
					File.write File.join(@nginx_conf_dir, "#{site_name}.conf"), vhost_renderer.result(binding)

					sites[site_name] = "#{site_name}.lvh.me:8080"

					page_config.each do |config|
						sites["#{site_name}#{config[:baseurl]}"] = "#{site_name}.lvh.me:8080#{config[:baseurl]}"
					end if page_config.count > 1
				end

				puts 'Generating index.html'
				renderer = ERB.new(File.read(File.join(@config.base_dir, 'templates', 'nginx', 'index.html.erb')))
				File.write File.join(@config.output_site_path, 'index.html'), renderer.result(binding)

				puts 'Copy default vhost'
				FileUtils.cp File.join(@config.base_dir, 'templates', 'nginx', 'default-vhost.conf'), File.join(@nginx_conf_dir, 'default.conf')
			end

			def prepare_varnish
				docker_folder = File.join(@config.project_dir, 'docker')
				FileUtils.mkdir_p docker_folder
				puts "Checkout repositories in #{docker_folder}"

				if File.exist? "#{docker_folder}/varnish"
					cmd = "cd #{docker_folder}/varnish && git pull"
				else
					cmd = "git clone -q -b develop https://github.com/Odania-IT/odania-varnish.git #{docker_folder}/varnish"
				end
				puts " -> Executing #{cmd}"
				puts `#{cmd}`
				exit 1 unless $?.success?

				if File.exist? "#{docker_folder}/varnish-generator"
					cmd = "cd #{docker_folder}/varnish-generator && git pull"
				else
					cmd = "git clone -q https://github.com/Odania-IT/odania-varnish-generator.git #{docker_folder}/varnish-generator"
				end
				puts " -> Executing #{cmd}"
				puts `#{cmd}`
				exit 1 unless $?.success?

				puts 'Prepare varnish secret'
				File.write File.join(docker_folder, 'varnish', 'varnish-secret'), @deploy_config.varnish_secret
				File.write File.join(docker_folder, 'varnish-generator', 'varnish-secret'), @deploy_config.varnish_secret
			end

			def grouped_domains
				result = Hash.new { |k, v| k[v] = [] }

				@generator_config.jekyll_config['pages'].each do |page|
					uri = URI.parse(page['url'])
					host = uri.host
					result[host] << {baseurl: page['baseurl'], relative_path: @generator_config.page_path(page)}
				end

				puts result.inspect
				result
			end

			class DockerComposeGenerator
				attr_reader :nginx_volume_html, :nginx_volume_conf_d, :nginx_volume_nginx_conf, :compose_images

				def initialize(config, environment)
					@nginx_volume_html = "#{config.output_site_path}:/srv:ro"
					@nginx_volume_conf_d = "#{@nginx_conf_dir}:/etc/nginx/conf.d:ro"
					@nginx_volume_nginx_conf = "#{File.join(config.output_path, 'nginx', 'nginx.conf')}:/etc/nginx/nginx.conf"
					@compose_images = environment.deploy_module.compose_images
					@erb_template = File.join(config.base_dir, 'templates', 'docker-compose', 'docker-compose.yml.erb')
				end

				def render
					ERB.new(File.read(@erb_template)).result(binding)
				end

				def write(out_dir)
					File.write out_dir, render
				end
			end
		end
	end
end
