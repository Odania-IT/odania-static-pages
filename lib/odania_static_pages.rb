require 'active_support/all'
require 'autostacker24'
require 'aws-sdk'
require 'erb'
require 'mimemagic'
require 'thor'
require 'uri'
require 'yaml'

require_relative 'odania_static_pages/cli'
require_relative 'odania_static_pages/config'
require_relative 'odania_static_pages/deploy/docker_compose'
require_relative 'odania_static_pages/deploy/rsync'
require_relative 'odania_static_pages/deploy/s3'
require_relative 'odania_static_pages/generator/jekyll'
require_relative 'odania_static_pages/helper/nginx'
require_relative 'odania_static_pages/server/nginx'
require_relative 'odania_static_pages/version'

module OdaniaStaticPages
	def self.config(path=nil)
		if @config.nil? or !path.nil?
			@config = OdaniaStaticPages::Config.new(path)
			@config.load!
		end

		@config
	end
end
