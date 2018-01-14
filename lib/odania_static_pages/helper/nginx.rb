module NginxHelper
	def generate_nginx_config(do_rebuild)
		nginx_default_redirect = @generator_config.nginx_default_redirect
		if 'live'.eql?(@config.environment)
			default_vhost_file = 'default-live-vhost.conf.erb'
			domain_extension = ''
		else
			default_vhost_file = 'default-vhost.conf'
			domain_extension = '.lvh.me'

			puts 'Generating index.html'
			FileUtils.mkdir_p @config.output_site_path
			renderer = ERB.new(File.read(File.join(@config.base_dir, 'templates', 'nginx', 'index.html.erb')))
			File.write File.join(@config.output_site_path, 'index.html'), renderer.result(binding)
		end

		vhost_renderer = ERB.new(File.read(File.join(@config.base_dir, 'templates', 'nginx', 'vhost.conf.erb')))
		sites = {}
		grouped_domains.each_pair do |site_name, page_config|
			full_site_name = "#{site_name}#{domain_extension}"
			puts "Writing vhost for: #{full_site_name}"

			if @deploy_config.respond_to? :expires
				expires = @deploy_config.expires
			else
				expires = 'live'.eql?(@config.environment) ? 'modified +24h' : '-1'
			end

			FileUtils.mkdir_p @nginx_conf_dir
			File.write File.join(@nginx_conf_dir, "#{site_name}.conf"), vhost_renderer.result(binding)

			sites[site_name] = "#{site_name}#{domain_extension}:8080"

			page_config.each do |config|
				sites["#{site_name}#{config[:baseurl]}"] = "#{site_name}#{domain_extension}:8080#{config[:baseurl]}"
			end if page_config.count > 1
		end

		puts 'Copy default vhost'
		renderer = ERB.new(File.read(File.join(@config.base_dir, 'templates', 'nginx', default_vhost_file)))
		File.write File.join(@nginx_conf_dir, 'default.conf'), renderer.result(binding)

		puts 'Copy nginx.conf'
		FileUtils.cp File.join(@config.base_dir, 'templates', 'nginx', 'nginx.conf'), File.join(@nginx_dir, 'nginx.conf')
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
end
