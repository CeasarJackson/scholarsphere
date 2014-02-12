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

describe Collection do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    @collection = Collection.create(:title => "test collection")
    @collection.apply_depositor_metadata(@user.user_key)
  end
  after(:all) do
    @user.delete
    @collection.delete
  end
  it "should have open visibility" do
    @collection.save
    (@collection.datastreams["rightsMetadata"].permissions({group:"public"})).should == "read"
  end
  it "should not allow a collection to be saved without a title" do
     @collection.title = nil
     expect{@collection.save!}.to raise_error(ActiveFedora::RecordInvalid)
  end
end
