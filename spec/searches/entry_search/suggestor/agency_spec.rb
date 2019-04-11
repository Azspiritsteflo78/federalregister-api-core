require "spec_helper"

describe 'EntrySearch::Suggestor::Agency' do
  def suggestor(term, options = {})
    conditions = options.merge(:term => term)
    EntrySearch::Suggestor::Agency.new(EntrySearch.new(:conditions => conditions))
  end

  describe "valid agency in search term" do
    before(:each) do
      @usda = Factory(:agency, :name => "Agriculture Department", :short_name => "USDA", :display_name => "Department of Agriculture")
      @hhs  = Factory(:agency, :name => "Health and Human Services Department", :short_name => "HHS", :display_name => "Department of Health and Human Services")
      @fish = Factory(:agency, :name => "Fish Department")
    end

    it "should suggest an agency when matching a name identically" do
      suggestion = suggestor("Agriculture Department").suggestion
      suggestion.term.should == ''
      suggestion.agency_ids.should == [@usda.id]
    end

    it "should suggest an agency when matching a short_name identically" do
      suggestion = suggestor("USDA").suggestion
      suggestion.term.should == ''
      suggestion.agency_ids.should == [@usda.id]
    end

    it "should suggest an agency when containing a short_name" do
      suggestion = suggestor("HHS Rules").suggestion
      suggestion.term.should == ' Rules'
      suggestion.agency_ids.should == [@hhs.id]
    end

    it "shouldn't suggest an agency who contains a short_name embedded in other words" do
      suggestion = suggestor("HHHSO Rules").suggestion
      suggestion.should be_nil
    end

    it "shouldn't suggest an agency that doesn't have a full match" do
      suggestion = suggestor("cult Rules").suggestion
      suggestion.should be_nil
    end

    it "shouldn't suggest an agency that is already selected" do
      suggestion = suggestor(@usda.name, :agency_ids => [@usda.id]).suggestion
      suggestion.should be_nil
    end

    it "keep words separate" do
      suggestion = suggestor("before USDA after").suggestion
      suggestion.term.should == 'before after'
    end

    it "not match hyphenated words" do
      suggestion = suggestor("pre-USDA").suggestion
      suggestion.should be_nil
    end

    it "doesn't match quoted words" do
      suggestion = suggestor('"425 USDA 123"').suggestion
      suggestion.should be_nil
    end

    it "doesn't match excluded words" do
      suggestion = suggestor('-USDA').suggestion
      suggestion.should be_nil
    end

    it "doesn't match exact words" do
      suggestion = suggestor('=USDA').suggestion
      suggestion.should be_nil
    end

    it "doesn't match exact excluded words" do
      suggestion = suggestor('-=USDA').suggestion
      suggestion.should be_nil
    end
  end
end
