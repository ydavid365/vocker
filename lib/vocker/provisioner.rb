require_relative "errors"
require_relative "docker_client"
require_relative "docker_installer"

module VagrantPlugins
  module Vocker
    # TODO: Improve handling of vagrant-lxc specifics (like checking for apparmor
    #       profile stuff + autocorrection)
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def initialize(machine, config, installer = nil, client = nil)
        super(machine, config)
        @installer = installer || DockerInstaller.new(@machine, config.version)
        @client    = client    || DockerClient.new(@machine)
      end

      def provision
        @logger = Log4r::Logger.new("vagrant::provisioners::vocker")

        @logger.info("Checking for Docker installation...")
        @installer.ensure_installed

        # Attempt to start service if not running
        @client.start_service
        unless @client.daemon_running?
          raise Errors::DockerNotRunning
        end

        if config.images.any?
          @machine.ui.info(I18n.t("vagrant.docker_pulling_images"))
          @client.pull_images(*config.images)
        end

        if config.containers.any?
          @machine.ui.info(I18n.t("vagrant.docker_starting_containers"))
          @client.run(config.containers)
        end
      end
    end
  end
end
