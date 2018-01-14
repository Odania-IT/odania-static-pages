module NginxHelper
	def generate_nginx_config(do_rebuild)
		vhost_renderer = ERB.new(File.read(File.join(@config.base_dir, 'templates', 'nginx', 'vhost.conf.erb')))
		sites = {}
		grouped_domains.each_pair do |site_name, page_config|
			full_site_name = "#{site_name}.lvh.me"
			puts "Writing vhost for: #{full_site_name}"
			expires = @deploy_config.expires
			FileUtils.mkdir_p @nginx_conf_dir
			File.write File.join(@nginx_conf_dir, "#{site_name}.conf"), vhost_renderer.result(binding)

			sites[site_name] = "#{site_name}.lvh.me:8080"

			page_config.each do |config|
				sites["#{site_name}#{config[:baseurl]}"] = "#{site_name}.lvh.me:8080#{config[:baseurl]}"
			end if page_config.count > 1
		end

		puts 'Generating index.html'
		FileUtils.mkdir_p @config.output_site_path
		renderer = ERB.new(File.read(File.join(@config.base_dir, 'templates', 'nginx', 'index.html.erb')))
		File.write File.join(@config.output_site_path, 'index.html'), renderer.result(binding)

		puts 'Copy default vhost'
		default_vhost_file = 'live'.eql?(@config.environment) ? 'default-live-vhost.conf' : 'default-vhost.conf'
		FileUtils.cp File.join(@config.base_dir, 'templates', 'nginx', default_vhost_file), File.join(@nginx_conf_dir, 'default.conf')

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
