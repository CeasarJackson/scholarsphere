# frozen_string_literal: true
require 'spec_helper'

describe User, type: :model do
  let(:user) { FactoryGirl.find_or_create(:ldap_jill) }

  it "has a login" do
    expect(user.login).to eq("jilluser")
  end
  it "redefines to_param to make redis keys more recognizable" do
    expect(user.to_param).to eq(user.login)
  end
  describe "#ldap_exist?" do
    subject { user.ldap_exist? }
    context "when the user exists" do
      before { allow(LdapUser).to receive(:check_ldap_exist!).and_return(true) }
      it { is_expected.to be true }
    end
    context "when the user does not exist" do
      before { allow(LdapUser).to receive(:check_ldap_exist!).and_return(false) }
      it { is_expected.to be false }
    end
    context "when LDAP misbehaves" do
      before do
        Sufia.config.retry_unless_sleep = 0.01
        filter = Net::LDAP::Filter.eq('uid', user.login)
        allow(Hydra::LDAP).to receive(:does_user_exist?).twice.with(filter).and_return(true)
      end

      it "returns true after LDAP returns 'unwilling' first, then sleeps and returns true on the second call" do
        expect(Hydra::LDAP.connection).to receive(:get_operation_result).once.and_return(OpenStruct.new(code: 53, message: "Unwilling"))
        expect(Hydra::LDAP.connection).to receive(:get_operation_result).once.and_return(OpenStruct.new(code: 0, message: "sucess"))
        expect(LdapUser).to receive(:sleep).with(0.01)
        expect(user.ldap_exist?).to eq(true)
      end
    end
  end

  describe "#directory_attributes" do
    let(:entry) do
      Net::LDAP::Entry.new("uid=mjg36,dc=psu,edu").tap do |entry|
        entry['cn'] = ["MICHAEL JOSEPH GIARLO"]
      end
    end
    before { expect(Hydra::LDAP).to receive(:get_user).and_return([entry]) }
    it "returns user attributes from LDAP" do
      expect(described_class.directory_attributes('mjg36', ['cn']).first['cn']).to eq(['MICHAEL JOSEPH GIARLO'])
    end
  end

  describe "#query_ldap_by_name_or_id" do
    let(:name_part) { "cam" }
    let(:filter) { Net::LDAP::Filter.construct("(& (| (uid=#{name_part}* ) (givenname=#{name_part}*) (sn=#{name_part}*)) (| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE))))") }
    let(:results) do
      [
        Net::LDAP::Entry.new("uid=cac6094,dc=psu,dc=edu").tap do |e|
          e[:uid] = ["cac6094"]
          e[:displayname] = ["CAMILO CAPURRO"]
        end,
        Net::LDAP::Entry.new("uid=csl5210,dc=psu,dc=edu").tap do |e|
          e[:uid] = ["csl5210"]
          e[:displayname] = ["CAMERON SIERRA LANGSJOEN"]
        end,
        Net::LDAP::Entry.new("uid=cnt5046,dc=psu,dc=edu").tap do |e|
          e[:uid] = ["cnt5046"]
          e[:displayname] = ["CAMILLE NAKIA TINDAL"]
        end
      ]
    end
    let(:attrs) { ["uid", "displayname"] }

    before do
      expect(Hydra::LDAP).to receive(:get_user).with(filter, attrs).and_return(results)
      allow(Hydra::LDAP.connection).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
    end
    it "returns a list or people" do
      expect(described_class.query_ldap_by_name_or_id("cam")).to eq([{ id: "cac6094", text: "CAMILO CAPURRO (cac6094)" },
                                                                     { id: "csl5210", text: "CAMERON SIERRA LANGSJOEN (csl5210)" },
                                                                     { id: "cnt5046", text: "CAMILLE NAKIA TINDAL (cnt5046)" }
                                                                    ])
    end
  end

  describe "#query_ldap_by_name" do
    context "when known user" do
      let(:first_name) { "Carolyn Ann" }
      let(:last_name) { "Cole" }
      let(:first_name_parts) { ["Carolyn", "Ann"] }
      let(:filter) { Net::LDAP::Filter.construct("(& (& (givenname=#{first_name_parts[0]}*) (givenname=*#{first_name_parts[1]}*) (sn=#{last_name})) (| (eduPersonPrimaryAffiliation=STUDENT) (eduPersonPrimaryAffiliation=FACULTY) (eduPersonPrimaryAffiliation=STAFF) (eduPersonPrimaryAffiliation=EMPLOYEE) (eduPersonPrimaryAffiliation=RETIREE) (eduPersonPrimaryAffiliation=EMERITUS) (eduPersonPrimaryAffiliation=MEMBER)))))") }
      let(:attrs) {  ['uid', 'givenname', 'sn', 'mail', "eduPersonPrimaryAffiliation"] }

      let(:results) do
        [
          Net::LDAP::Entry.new("uid=cam156,dc=psu,dc=edu").tap do |e|
            e[:uid] = ["cam156"]
            e[:givenname] = ["CAROLYN A"]
            e[:sn] = "COLE"
            e[:mail] = ["cam156@psu.edu"]
          end
        ]
      end
      before do
        expect(Hydra::LDAP).to receive(:get_user).with(filter, attrs).and_return(results)
        allow(Hydra::LDAP.connection).to receive(:get_operation_result).and_return(OpenStruct.new(code: 0, message: "Success"))
      end
      it "returns an array of people" do
        expect(described_class.query_ldap_by_name(first_name, last_name)).to eq([{ id: "cam156", given_name: "CAROLYN A", surname: "COLE", email: "cam156@psu.edu", affiliation: [] }])
      end
    end
  end

  describe "#from_url_component" do
    let(:entry) do
      Net::LDAP::Entry.new("uid=mjg36,dc=psu,edu").tap do |entry|
        entry[:cn] = ["MICHAEL JOSEPH GIARLO"]
        entry[:displayname] = ["John Smith"]
        entry[:psofficelocation] = ["Beaver Stadium$Seat 100"]
      end
    end
    subject { described_class.from_url_component("cam") }

    context "when user exists" do
      before do
        allow(LdapUser).to receive(:check_ldap_exist!).and_return(true)
        allow(LdapUser).to receive(:group_response_from_ldap).and_return([])
        allow(Hydra::LDAP).to receive(:get_user).and_return([entry])
      end

      it "creates a user" do
        expect(described_class.count).to eq 0
        is_expected.to be_a_kind_of(described_class)
        expect(subject.display_name).to eq "John Smith"
        expect(subject.office).to eq "Beaver Stadium\nSeat 100"
        expect(subject.website).to be_nil
        expect(subject.title).to be_nil
        expect(described_class.count).to eq 1
      end
    end

    context "user does not exists" do
      before { allow(Hydra::LDAP).to receive(:does_user_exist?).and_return(false) }

      it "does not create a user" do
        expect(described_class.count).to eq 0
        is_expected.to_not be_a_kind_of(described_class)
        expect(described_class.count).to eq 0
      end
    end
  end
end
