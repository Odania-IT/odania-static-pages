module OdaniaStaticPages
	module Generator
		class Jekyll
			def init
				puts 'Initliazing jekyll pages'
				puts
				setup_generator

				FileUtils.mkdir_p @pages_path unless File.exist? @pages_path

				unless File.exist? @jekyll_config_file
					FileUtils.cp File.join(@config.base_dir, 'templates', 'jekyll', 'example_config.yml'), @jekyll_config_file
					setup_generator
				end

				FileUtils.mkdir_p @generator_config.full_common_folder unless File.exist? @generator_config.full_common_folder

				puts 'Initialize Gemfile'
				gemfile_template = File.join(@config.base_dir, 'templates', 'jekyll', 'Gemfile.erb')
				gem_extra = @generator_config.gem_extra
				File.write File.join(@generator_config.full_common_folder, 'Gemfile'), ERB.new(File.read(gemfile_template)).result(binding)

				puts 'Install gems'
				puts `cd #{@generator_config.full_common_folder} && bundle check`
				puts `cd #{@generator_config.full_common_folder} && bundle install --path ~/.gems` unless $?.success?

				@jekyll_config['pages'].each do |page|
					relative_page_path = @generator_config.page_path page
					relative_page_path += page['baseurl'] unless page['baseurl'].empty?
					page_path = File.join @pages_path, relative_page_path

					puts '*' * 100
					puts "Processing #{relative_page_path} => #{page_path}"

					unless File.directory? page_path
						puts "Creating page #{page['name']}"
						`cd #{@pages_path} && octopress new #{relative_page_path}`
					end

					page_config = @generator_config.prepare_config page
					current_config_file = File.join page_path, '_config.yml'
					current_config = YAML.load_file current_config_file

					unless current_config.eql? page_config
						puts ' -> Updating config'
						File.write current_config_file, YAML.dump(page_config)
					end

					@generator_config.link @config.base_dir, page_path, page

					puts
				end

			end

			def build(env)
				puts 'Building all jekyll websites'
				setup_generator

				grouped_domains.each_pair do |site_name, page_config|
					build_for_configs(page_config, site_name, @config.output_site_path, env)
				end
			end

			private

			def setup_generator
				@config = OdaniaStaticPages.config
				@current_environment = @config.current_environment
				@generator_config = @config.generator
				@pages_path = @config.pages_path
				@jekyll_config_file = @generator_config.jekyll_config_file
				@jekyll_config = @generator_config.jekyll_config
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

			def build_site(site_path, options, jekyll_env='development')
				puts 'Install gems'
				puts `cd #{File.join(@generator_config.pages_dir, site_path)} && bundle check`
				puts `cd #{File.join(@generator_config.pages_dir, site_path)} && bundle install --path ~/.gems` unless $?.success?

				full_site_path = File.join(@generator_config.pages_dir, site_path)
				env_vars = "BUNDLE_GEMFILE=#{full_site_path}/Gemfile JEKYLL_ENV=#{jekyll_env}"
				cmd = "cd #{full_site_path} && #{env_vars} bundle exec jekyll build #{options}"
				puts " -> Building site [cmd: #{cmd}]"
				unless system(cmd)
					puts "Error building site: #{site_path}"
					exit 1
				end
			end

			def build_for_configs(page_config, site_name, target_site_path, jekyll_env='development')
				page_config.each do |config|
					site_path = site_name
					site_path = File.join(site_path, config[:baseurl]) unless config[:baseurl].nil?
					options = "-d #{File.join(target_site_path, site_path)}"
					build_site site_path, options, jekyll_env
				end
			end
		end
	end
end
