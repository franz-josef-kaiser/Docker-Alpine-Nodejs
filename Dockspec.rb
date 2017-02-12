require 'serverspec'
require 'docker'
require 'json'

set :backend, :exec

describe 'Docker image specs' do

	before( :all ) do
		print " ---> Docker Version " + Docker.version['Version'] + "\n\n"

		begin
			# Fetch existing image
			@image = Docker::Image.get( 'nodejs:latest' )
		rescue
			print " … Building Docker Image\n\n"
			# If it does not exist, build it
			@image = Docker::Image.build_from_dir( '.', 't' => 'nodejs:latest' ) do |v|
				if ( log = JSON.parse(v) ) && log.has_key?( 'stream' )
					# Only enable for debugging
					$stdout.puts log['stream']
				end
			end
		end
		print " ---> Image Details:\n"
		puts @image.inspect
		puts ""

		set :os, family: :alpine
		set :backend, :docker
		set :docker_image, @image.id

		print " … Creating Docker container\n\n"
		@container = Docker::Container.create(
			'Image' => @image.id
		)
		@container.start()

		print " ---> Container Details:\n"
		puts @container.json
		puts ""

		@docker = Docker

		print " ---> Details: Host\n"
		print "  Memory: " + ( Docker.info['MemTotal'] / 1024 / 1024 ).to_s + " MB\n"
		print "  OS: " + Docker.info['OperatingSystem'] + "\n\n"
	end

	after( :all ) do
		print "\n\n … Cleaning up. Removing container.\n"

		@container.stop()
		@container.kill()
		@container.delete( :force => true )
	end

	describe command( 'cat /etc/alpine-release' ) do
		its ( :stdout ) { should match '3.5.0' }
	end

	describe docker_image( 'nodejs:latest' ) do
		it ( 'is an existing image' ) { expect( @image ).to_not be_nil }
		it 'should use "node" as CMD' do
			expect( @image.json['Config']['Cmd'] ).to include( 'node' )
		end

		#it 'should use Alpine OS' do
		#	expect( @docker.info['OperatingSystem'] ).to include( 'Alpine Linux' )
		#end

		it 'should have all needed ENV variables set' do
			env = @container.json['Config']['Env']
			expect( env ).to be_a( Array )

			# Convert to Hash so we can check ENV var existence
			envars = Hash.new
			env.each{ | el, key |
				new = el.to_s.split( '=' )
				envars[ new[0] ] = ( defined? new[1] ) ? new[1] : ''
			}

			expect( envars ).to include( 'VERSION' )
			expect( envars ).to include( 'NPM' )
			expect( envars ).to include( 'NPM_VERSION' )
			expect( envars ).to include( 'FLAGS' )

			expect( envars ).to include( 'HOME' )
			expect( envars ).to include( 'PREFIX' )
			expect( envars ).to include( 'TARGET' )
			expect( envars ).to include( 'SRC' )
			expect( envars ).to include( 'NODE_PATH' )

			expect( envars ).to include( 'GPG_KEYS' )
			expect( envars ).to include( 'PACKAGES' )
			expect( envars ).to include( 'DEPS_PACKAGES' )
		end
	end

	describe user( 'node' ) do
		it { should exist }
		it { should have_home_directory '/home/node' }
	end

	describe file( '/usr/lib/node_modules' ) do
		it { should be_owned_by 'root' }
		it { should be_directory }
	end

	it 'should have a running container' do
		@container.start()
		expect( @container.json['State']['Running'] ).to be_truthy
		expect( @container.json['State']['Status'] ).to include( 'running' )
	end

	describe port( 3000 ) do
		it 'should be EXPOSEd' do
			expect( @image.json['ContainerConfig']['ExposedPorts'].has_key?( '3000/tcp' ) )
				.to be_truthy
		end
	end

	describe package( 'libgcc' ) do
		it { should be_installed }
	end

	describe package( 'libstdc++' ) do
		it { should be_installed }
	end

	describe package( 'tini' ) do
		it { should be_installed }
	end

end