require 'spec_helper'

describe EntryEmail do
  it { should belong_to :entry }
  it { should validate_presence_of(:entry) }
  it { should validate_presence_of(:remote_ip) }
  it { should validate_presence_of(:sender_hash) }
  it { should validate_presence_of(:sender) }
  it { should validate_presence_of(:recipients) }
  
  describe 'sender=' do
    it "hashes the sender email address consistently" do
      email_1 = Factory.build(:entry_email, :sender_hash => nil)
      email_1.sender = 'john.doe@example.com'
      email_1.save!
      
      email_2 = Factory.build(:entry_email, :sender_hash => nil)
      email_2.sender = 'john.doe@example.com'
      email_2.save!
      
      email_1.sender_hash.should == email_2.sender_hash
    end
    
    it "should add an error if sender is not a valid email address" do
      email = Factory.build(:entry_email, :sender => "NOT-A-VALID-EMAIL-ADDRESS")
      email.should have(1).errors_on(:sender)
    end
    
    it "should accept valid sender emails" do
      email = Factory.build(:entry_email, :sender => "john@example.com")
      email.should have(:no).errors_on(:sender)
    end
  end
  
  describe 'email' do
    it "should be sent after record is originally created" do
      email = Factory.build(:entry_email)
      Mailer.should_receive(:deliver_entry_email).with(email)
      email.save!
    end
  end
  
  describe 'recipients=' do
    it "stores the provided array unchanged if given an array" do
      email = Factory.build(:entry_email, :recipients => ["john@example.com","jane@example.com"])
      email.recipients.should == ["john@example.com", "jane@example.com"]
    end
    
    it "splits a string into an array" do
      email = Factory.build(:entry_email, :recipients => "john@example.com, jane@example.com")
      email.recipients.should == ["john@example.com", "jane@example.com"]
    end
    
    # keep the fuzzer happy
    it "doesn't blow up when given a hash" do
      lambda {Factory.build(:entry_email, :recipients => {})}.should_not raise_error
    end
    
    it "should add errors when recipients are invalid" do
      email = Factory.build(:entry_email, :recipients => ["NOT-AN-EMAIL-ADDRESS", "doe@foo_com", "john@example.com"])
      email.should have(2).errors_on(:recipients)
    end
    
    it "should allow valid recipients" do
      email = Factory.build(:entry_email, :recipients => ["john@example.com"])
      email.should have(0).errors_on(:recipients)
    end
    
    it "adds errors when more than 10 recipients are added" do
      email = Factory.build(:entry_email, :recipients => "one@example.com,two@example.com,three@example.com,four@example.com,five@example.com,six@example.com,seven@example.com,eight@example.com,nine@example.com,ten@example.com,eleven@example.com")
      email.should have(1).error_on(:recipients)
    end
    
    it "allows 10 recipients when 10 are added" do
      email = Factory.build(:entry_email, :recipients => "one@example.com,two@example.com,three@example.com,four@example.com,five@example.com,six@example.com,seven@example.com,eight@example.com,nine@example.com,ten@example.com")
      email.should have(0).error_on(:recipients)
    end
  end
  
  describe "num_recipients" do
    it "should be calculated based on the number of recipients" do
      Factory(:entry_email, :recipients => "jane@example.com").num_recipients.should == 1
      Factory(:entry_email, :recipients => "jane@example.com, judy@example.com").num_recipients.should == 2
    end
  end
end