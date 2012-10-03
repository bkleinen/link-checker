require 'spec_helper'
require 'link_checker'

describe Link::Checker do

  it "finds all of the HTML files in the target path." do
    checker = Link::Checker.new('spec/test-site/public/')
    files = checker.find_html_files
    files.size.should == 3
  end

  it "finds all of the external links in an HTML file." do
    links = Link::Checker.find_external_links(
      'spec/test-site/public/blog/2012/10/02/a-list-of-links/index.html')
    links.size.should == 4
  end

  describe "checks links and" do

    before(:all) do
      @good_uri = 'http://goodlink.com'
      FakeWeb.register_uri(:any, @good_uri, :body => "Yay it worked.")

      @bad_uri = 'http://brokenlink.com'
      FakeWeb.register_uri(:get, @bad_uri,
        :body => "File not found", :status => ["404", "Missing"])

      @redirect_uri = 'http://redirect.com'
    end

    it "declares good links to be good." do
      Link::Checker.check_link(@good_uri).should be true
    end

    it "declares bad links to be bad." do
      expect { Link::Checker.check_link(@bad_uri) }.to(
        raise_error(Link::Error))
    end

    describe "follows redirects to the destination and" do

      it "declares good redirect targets to be good." do
        FakeWeb.register_uri(:get, @redirect_uri,
          :location => @good_uri, :status => ["302", "Moved"])
        Link::Checker.check_link(@redirect_uri).should be true
      end

      it "declares bad redirect targets to be bad." do
        FakeWeb.register_uri(:get, @redirect_uri,
          :location => @bad_uri, :status => ["302", "Moved"])
        expect { Link::Checker.check_link(@redirect_uri) }.to(
          raise_error(Link::Error))
      end

    end

  end

end