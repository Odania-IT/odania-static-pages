module OdaniaStaticPages
	class GeneratorCli < Thor
		desc 'init', 'Initialize'
		def init
			config = OdaniaStaticPages.config
			deploy_module = "OdaniaStaticPages::Generator::#{config.generator_type}".constantize.new
			deploy_module.init
		end

		desc 'build', 'Build websites'
		def build
			config = OdaniaStaticPages.config
			deploy_module = "OdaniaStaticPages::Generator::#{config.generator_type}".constantize.new
			deploy_module.build options[:environment]
		end
	end
end
