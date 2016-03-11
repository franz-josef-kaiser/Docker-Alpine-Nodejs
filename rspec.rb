require "serverspec"
require "docker"

describe "Dockerfile" do
	before(:all) do
		image = Docker::Image.build_from_dir( '.' )

		set :os, family: :alpine
		set :backend, :docker
		set :docker_image, image.id
	end


	it "installs the right version of Alpine" do
		expect( os_version ).to include( "Alpine" )
	end

	it "installs required packages" do
		expect( package( "nodejs" ) ).to be_installed
	end

	def os_version
		command( "identify_alpine()" ).stdout
	end
end
