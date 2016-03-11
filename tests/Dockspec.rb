require "serverspec"
require "docker"

describe "Dockerfile" do
	before(:all) do
	before( :all ) do
		print "Running Tests for Docker\n"
		print " ---> Docker Version " + Docker.version["Version"] + "\n\n"

		@image = Docker::Image.build_from_dir( "../" )

		set :os, family: :alpine
		set :backend, :docker
		set :docker_image, image.id

		@container = Docker::Container.create(
			'Image' => @image.id,
			'Cmd'   => [ "node", "-v" ]
		)
		@container.start

		print " ---> Details\n"
		print "  OS: " + host_inventory["platform"]
			print " " + host_inventory["platform_version"] + "\n"
		print "  Docker Container: " + host_inventory["hostname"] + "\n"
		print "  Memory: " + host_inventory["memory"]["total"] + "\n\n"

		print " ---> Running tests\n"
	end

	after( :all ) do
		print "\n\n ---> Cleaning up. Removing container."
		@container.stop
		@container.kill
		@container.delete( :force => true )
		@image.remove( :force => true )
	end


	it "Image should exist" do
		expect( @image ).to_not be_nil
	end

	it "installs the right version of Alpine" do
		expect( os_version ).to include( "Alpine" )
	end


	it "installs required APK packages" do
		expect( package( "binutils-gold" ) ).to be_installed
		expect( package( "ca-certificates" ) ).to be_installed
		expect( package( "curl" ) ).to be_installed
		expect( package( "g++" ) ).to be_installed
		expect( package( "gcc" ) ).to be_installed
		expect( package( "gnupg" ) ).to be_installed
		expect( package( "libgcc" ) ).to be_installed
		expect( package( "libstdc++" ) ).to be_installed
		expect( package( "linux-headers" ) ).to be_installed
		expect( package( "make" ) ).to be_installed
		expect( package( "paxctl" ) ).to be_installed
		expect( package( "python" ) ).to be_installed
	end

	it "installs 'nodejs' package" do
		expect( package( "nodejs" ) ).to be_installed
	end


	def os_version
		command( "identify_alpine()" ).stdout
	end
end
