# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe LocalAuthority do
  before(:all) do
    @tsv = [Rails.root + 'spec/fixtures/cities15000.tsv']
    @nt = [Rails.root + 'spec/fixtures/genreForms.nt']
    @rdfxml = [Rails.root + 'spec/fixtures/lexvo.rdf']
    LocalAuthority.count.should == 0
    LocalAuthorityEntry.count.should == 0
  end
  after(:each) do
    LocalAuthorityEntry.all.each(&:destroy)
    DomainTerm.all.each do |term|
      term.local_authorities.each do |auth|
        auth.destroy
      end
      term.destroy
    end
  end
  it "should harvest an ntriples RDF vocab" do
    LocalAuthority.harvest_rdf("genres", @nt)
    LocalAuthority.count.should == 1
    LocalAuthorityEntry.count.should == 6
  end
  it "should harvest an RDF/XML vocab (w/ an alt predicate)" do
    LocalAuthority.harvest_rdf("langs", @rdfxml, 
                               :format => 'rdfxml',
                               :predicate => RDF::URI("http://www.w3.org/2008/05/skos#prefLabel"))
    LocalAuthority.count.should == 1
    LocalAuthorityEntry.count.should == 35
  end
  it "should harvest TSV vocabs" do
    LocalAuthority.harvest_tsv("geo", @tsv, :prefix => 'http://sws.geonames.org/')
    LocalAuthority.count.should == 1
    auth = LocalAuthority.where(:name => "geo").first
    LocalAuthorityEntry.where(:local_authority_id => auth.id).first.uri.start_with?('http://sws.geonames.org/').should be_true
    LocalAuthorityEntry.count.should == 149
  end
  describe "when vocabs are harvested" do
    before(:all) do
      class MyTestRdfDatastream; end
      LocalAuthority.harvest_rdf("genres", @nt)
      LocalAuthority.harvest_tsv("geo", @tsv, :prefix => 'http://sws.geonames.org/')
      DomainTerm.count.should == 0
      @num_auths = LocalAuthority.count
      @num_entries = LocalAuthorityEntry.count
    end
    after(:all) do
      DomainTerm.destroy_all
      LocalAuthority.destroy_all
      LocalAuthorityEntry.destroy_all
      Object.send(:remove_const, :MyTestRdfDatastream)
    end
    it "should not harvest an RDF vocab twice" do
      LocalAuthority.harvest_rdf("genres", @nt)
      LocalAuthority.count.should == @num_auths
      LocalAuthorityEntry.count.should == @num_entries
    end
    it "should not harvest a TSV vocab twice" do
      LocalAuthority.harvest_tsv("geo", @tsv, :prefix => 'http://sws.geonames.org/')
      LocalAuthority.count.should == @num_auths
      LocalAuthorityEntry.count.should == @num_entries
    end
    it "should register a vocab" do
      LocalAuthority.register_vocabulary(MyTestRdfDatastream, "geographic", "geo")
      DomainTerm.count.should == 1
    end
    describe "when vocabs are registered" do
      before(:all) do
        LocalAuthority.harvest_rdf("genres", @nt)
        LocalAuthority.harvest_tsv("geo", @tsv, :prefix => 'http://sws.geonames.org/')
        class TestRdfDatastream; end
        LocalAuthority.register_vocabulary(MyTestRdfDatastream, "geographic", "geo")
        LocalAuthority.register_vocabulary(MyTestRdfDatastream, "genre", "genres")
        DomainTerm.count.should == 2
      end
      after(:all) do
        DomainTerm.destroy_all
        LocalAuthority.destroy_all
        LocalAuthorityEntry.destroy_all
      end
      it "should return nil for empty queries" do
        LocalAuthority.entries_by_term("my_test", "geographic", "").should be_nil
      end
      it "should return an empty array for unregistered models" do
        LocalAuthority.entries_by_term("my_foobar", "geographic", "E").should == []
      end
      it "should return an empty array for unregistered terms" do
        LocalAuthority.entries_by_term("my_test", "foobar", "E").should == []
      end
      it "should return entries by term" do
        term = DomainTerm.where(:model => "my_tests", :term => "genre").first
        authorities = term.local_authorities.collect(&:id).uniq
        hits = LocalAuthorityEntry.where("local_authority_id in (?)", authorities).where("label like ?", "A%").select("label, uri").limit(25)
        LocalAuthority.entries_by_term("my_tests", "genre", "A").count.should == 6
      end
    end
  end
end
    
