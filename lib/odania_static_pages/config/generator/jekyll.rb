module OdaniaStaticPages
	class Config
		module Generator
			class Jekyll
				attr_reader :plugins, :encoding, :common_folder, :extra_options, :gem_extra

				def initialize(project_dir, options)
					@plugins = options['plugins'] || %w(jekyll-feed octopress-image-tag octopress-gist)
					@encoding = options['encoding'] || 'utf-8'
					@common_folder = options['common_folder'] || 'common'
					@extra_options = options['extra_options'] || {}
					@gem_extra = options['gem_extra'] || ''
					@project_dir = project_dir
				end

				def to_h
					{
						plugins: @plugins,
						encoding: @encoding,
						common_folder: @common_folder,
						extra_options: @extra_options,
						gem_extra: @gem_extra
					}.stringify_keys!
				end

				def self.from_hash(project_dir, data)
					Jekyll.new project_dir, data
				end

				def prepare_config(cfg)
					page_config = cfg.clone
					page_config['plugins'] = @plugins
					page_config['encoding'] = @encoding
					@extra_options.merge page_config
				end

				def link(base_dir, page_path, page)
					common_subfolders.each do |folder|
						create_link_if_required page_path, folder
					end

					puts ' -> Linking plugins'
					plugins_dir = File.join(page_path, '_plugins')
					FileUtils.mkdir_p plugins_dir

					Dir.glob(File.join(full_common_folder, '_plugins', '*')).each do |plugin_file|
						puts "   -> Linking plugin #{File.basename(plugin_file)}"
						FileUtils.ln_s plugin_file, plugins_dir, force: true
					end

					puts ' -> Linking Gemfile*'
					dot_bundle_folder = File.join(full_common_folder, '.bundle')
					FileUtils.ln_s dot_bundle_folder, page_path, force: true if File.exist? dot_bundle_folder
					FileUtils.ln_s File.join(full_common_folder, 'Gemfile'), File.join(page_path, 'Gemfile'), force: true
					FileUtils.ln_s File.join(full_common_folder, 'Gemfile.lock'), File.join(page_path, 'Gemfile.lock'), force: true

					puts ' -> Linking common pages'
					FileUtils.mkdir_p template_pages_dir
					link_common_pages template_pages_dir, page_path, template_pages_dir, page['lang']
				end

				def full_common_folder
					File.join(@project_dir, @common_folder)
				end

				def template_pages_dir
					File.join(full_common_folder, '_pages')
				end

				def pages_dir
					File.join(@project_dir, 'pages')
				end

				def page_path(page_config)
					uri = URI.parse(page_config['url'])
					uri.host
				end

				def jekyll_config_file
					File.join(@project_dir, '_jekyll_config.yml')
				end

				def jekyll_config
					return YAML.load_file jekyll_config_file if File.exist? jekyll_config_file
					{}
				end

				private

				def create_link_if_required(page_path, name)
					puts " -> Linking #{name}"
					file = File.join(full_common_folder, name)
					FileUtils.mkdir_p file unless File.exist? file
					FileUtils.ln_s file, page_path, force: true
				end

				def common_subfolders
					%w(_affiliate _i18n _layouts _themes)
				end

				def link_common_pages(src_folder, target_folder, pages_dir, lang)
					Dir.glob(File.join(src_folder, '*')).each do |common_page_file|
						if File.directory? common_page_file
							link_common_pages common_page_file, target_folder, pages_dir, lang
						else
							short_file = common_page_file.gsub("#{pages_dir}/", '')
							target_file = File.join target_folder, short_file

							basename = File.basename(short_file)
							if basename.start_with? 'lang-'
								cleaned_name = basename.split('-')
								cleaned_name.shift
								file_lang = cleaned_name.shift
								next unless lang.eql? file_lang

								target_file = File.join target_folder, File.dirname(short_file), cleaned_name.join('-')
							end

							puts "   -> Linking common page #{short_file} => #{target_file.gsub(target_folder, '')}"
							FileUtils.mkdir_p File.dirname target_file
							FileUtils.ln_s common_page_file, target_file, force: true
						end
					end
				end
			end
		end
	end
end
