require "serverspec"
require "docker"
require "json"

set :backend, :exec

describe "Dockerfile" do

	before( :all ) do
		print "Running Tests for Docker\n"
		print " ---> Docker Version " + Docker.version["Version"] + "\n\n"

		print " ---> Building Docker Image\n\n"
		begin
			# Fetch existing image
			@image = Docker::Image.get( "nodejs:latest" )
		rescue
			# If it does not exist, build it
			@image = Docker::Image.build_from_dir( ".", "t" => "nodejs:test" ) do |v|
				if ( log = JSON.parse(v) ) && log.has_key?( "stream" )
					# Only enable for debugging
					#$stdout.puts log["stream"]
				end
			end
		end

		set :os, family: :alpine
		set :backend, :docker
		set :docker_image, @image.id

		@container = Docker::Container.create(
			'Image' => @image.id,
			'Cmd'   => [ "node -v" ]
		)
		@container.start

		print " ---> Details: Host\n"

		#print "  OS: " + host_inventory["platform"]
		#print "      " + host_inventory["platform_version"] + "\n"
		#print "  Docker Container: " + host_inventory["hostname"] + "\n"
		print "  Memory: " + ( Docker.info["MemTotal"] / 1024 / 1024 ).to_s + " MB\n\n"

		print " ---> Running tests\n\n"
	end

	after( :all ) do
		print "\n\n ---> Cleaning up. Removing container.\n"

		@container.stop
		@container.kill
		@container.delete( :force => true )
		#@image.remove( :force => true )
	end


	it "has an existing image" do
		expect( @image ).to_not be_nil
	end


	it "container is running" do
		@container.start
		expect( @container.json["State"]["Running"] ).to be_truthy
		expect( @container.json["State"]["Status"] ).to include( "running" )
	end

	it "installs the right version of Alpine" do
		#expect( os_version ).to include( "Alpine" )
	end

	it "exposes the right port" do
		expect( @image.json['ContainerConfig']['ExposedPorts'].has_key?( '3000/tcp' ) )
			.to be_truthy
	end

	it "should have a CMD" do
		expect( @image.json["Config"]["Cmd"] ).to include( "node" )
	end

	it "should have all needed environmental variables set" do
		env = @image.info['Config']['Env']
		expect( env ).to be_a( Array )

		# Convert to Hash so we can check ENV var existence
		envars = Hash.new
		env.each{ | el, key |
			new = el.to_s.split( "=" )
			envars[ new[0] ] = ( defined? new[1] ) ? new[1] : ""
		}

		expect( envars ).to include( "PATH" )
		expect( envars ).to include( "VERSION" )
		expect( envars ).to include( "NPM" )
		expect( envars ).to include( "NPM_VERSION" )
		expect( envars ).to include( "PREFIX" )
		expect( envars ).to include( "FLAGS" )

		expect( envars ).to include( "TARGET" )
		expect( envars ).to include( "SRC" )
		expect( envars ).to include( "NODE_PATH" )
	end

	it "installs required APK packages" do
		#expect( package( "binutils-gold" ) ).to be_installed
		#expect( package( "ca-certificates" ) ).to be_installed
		#expect( package( "curl" ) ).to be_installed
		#expect( package( "g++" ) ).to be_installed
		#expect( package( "gcc" ) ).to be_installed
		#expect( package( "gnupg" ) ).to be_installed
		#expect( package( "libgcc" ) ).to be_installed
		#expect( package( "libstdc++" ) ).to be_installed
		#expect( package( "linux-headers" ) ).to be_installed
		#expect( package( "make" ) ).to be_installed
		#expect( package( "paxctl" ) ).to be_installed
		#expect( package( "python" ) ).to be_installed
	end

	it "installs 'nodejs' package" do
		#expect( package( "node" ) ).to be_installed
	end


	def os_version
		command( "identify_alpine()" ).stdout
	end

end