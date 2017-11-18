module OdaniaStaticPages
	class DeployCli < Thor
		desc 'init', 'Initialize'
		def init
			config = OdaniaStaticPages.config
			deploy_module = "OdaniaStaticPages::Deploy::#{config.current_environment.deploy_type}".constantize.new
			deploy_module.prepare
		end

		desc 'publish <color> <do_rebuild>', 'Publish website. Color is optional and can be used to force a publish of a specific color'
		def publish(color=nil, do_rebuild=false)
			config = OdaniaStaticPages.config
			deploy_module = "OdaniaStaticPages::Deploy::#{config.current_environment.deploy_type}".constantize.new
			deploy_module.publish(color, do_rebuild)
		end
	end
end
