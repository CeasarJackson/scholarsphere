require 'spec_helper'

describe 'Routes' do
  routes { Sufia::Engine.routes }
  describe 'Catalog' do
    it 'should route the root url to the catalog controller' do
      { get: '/' }.should route_to(controller: 'catalog', action: 'index')
    end

    it 'should route to recently added files' do
      { get: '/catalog/recent' }.should route_to(controller: 'catalog', action: 'recent')
    end
  end

  describe 'GenericFile' do
    it 'should route to citation' do
      { get: '/files/1/citation' }.should route_to(controller: 'generic_files', action: 'citation', id: '1')
    end

    it 'should route to audit' do
      { post: '/files/7/audit' }.should route_to(controller: 'generic_files', action: 'audit', id: '7')
    end

    it 'should route to create' do
      { post: '/files' }.should route_to(controller: 'generic_files', action: 'create')
    end

    it 'should route to new' do
      { get: '/files/new' }.should route_to(controller: 'generic_files', action: 'new')
    end

    it 'should route to edit' do
      { get: '/files/3/edit' }.should route_to(controller: 'generic_files', action: 'edit', id: '3')
    end

    it "should route to show" do
      { get: '/files/4' }.should route_to(controller: 'generic_files', action: 'show', id: '4')
    end

    it "should route to update" do
      { put: '/files/5' }.should route_to(controller: 'generic_files', action: 'update', id: '5')
    end

    it "should route to destroy" do
      { delete: '/files/6' }.should route_to(controller: 'generic_files', action: 'destroy', id: '6')
    end

    it "should *not* route to index" do
      { get: '/files' }.should_not route_to(controller: 'generic_files', action: 'index')
    end
  end

  describe 'Batch' do
    it "should route to edit" do
      { get: '/batches/1/edit' }.should route_to(controller: 'batch', action: 'edit', id: '1')
    end

    it "should route to update" do
      { post: '/batches/2' }.should route_to(controller: 'batch', action: 'update', id: '2')
    end
  end

  describe 'Download' do
    it "should route to show" do
      { get: '/downloads/9' }.should route_to(controller: 'downloads', action: 'show', id: '9')
    end
  end

  describe 'Dashboard' do
    it "should route to dashboard" do
      { get: '/dashboard' }.should route_to(controller: 'dashboard', action: 'index')
    end

    it "should route to dashboard facet" do
      { get: '/dashboard/facet/1' }.should route_to(controller: 'dashboard', action: 'facet', id: '1')
    end

    it "should route to dashboard activity" do
      { get: '/dashboard/activity' }.should route_to(controller: 'dashboard', action: 'activity')
    end
  end

  describe 'Advanced Search' do
    it "should route to search" do
      { get: '/search' }.should route_to(controller: 'advanced', action: 'index')
    end
  end

  describe 'Authorities' do
    it "should route to query" do
      { get: '/authorities/subject/bio' }.should route_to(controller: 'authorities', action: 'query', model: 'subject', term: 'bio')
    end
  end

  describe "Directory" do
    it "should route to user" do
      { get: '/directory/user/xxx666' }.should route_to(controller: 'directory', action: 'user', uid: 'xxx666')
    end

    it "should route to user attribute" do
      { get: '/directory/user/zzz777/email' }.should route_to(controller: 'directory', action: 'user_attribute', uid: 'zzz777', attribute: 'email')
    end

    it "should route to group and allow periods" do
      { get: '/directory/group/all.staff' }.should route_to(controller: 'directory', action: 'group', cn: 'all.staff')
    end
  end

  describe "Contact Form" do
    it "should route to new" do
      { get: '/contact' }.should route_to(controller: 'contact_form', action: 'new')
    end

    it "should route to create" do
      { post: '/contact' }.should route_to(controller: 'contact_form', action: 'create')
    end
  end

  describe "Static Pages" do
    it "should route to about" do
      { get: '/about' }.should route_to(controller: 'static', action: 'about')
    end

    it "should route to help" do
      { get: '/help' }.should route_to(controller: 'static', action: 'help')
    end

    it "should route to terms" do
      { get: '/terms' }.should route_to(controller: 'static', action: 'terms')
    end

    it "should route to zotero" do
      { get: '/zotero' }.should route_to(controller: 'static', action: 'zotero')
    end

    it "should route to mendeley" do
      { get: '/mendeley' }.should route_to(controller: 'static', action: 'mendeley')
    end

    it "should route to versions" do
      { get: '/versions' }.should route_to(controller: 'static', action: 'versions')
    end

    it "should *not* route a bogus static page" do
      { get: '/awesome' }.should_not route_to(controller: 'static', action: 'awesome')
    end
  end
end
