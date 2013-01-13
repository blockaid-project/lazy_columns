require 'spec_helper'

describe LazyColumns::ActsAsLazyColumnLoader do
  before(:each) do
    @action = create_and_reload_action_from_db
  end

  describe "#lazy_column" do
    it "excludes single column from active record objects" do
      @action.has_attribute?(:comments).should_not == "The action should not contain the lazy :comments attribute"
    end

    it "loads column when requested" do
      @action.comments.should == "some comments"
    end

    it "should not reload the object if the column was eagerly loaded" do
      @action = Action.select(:comments).first
      @action.should_not_receive :reload
      @action.comments
    end

    it "should not reload the object if after the column was fetched" do
      @action.comments
      @action.should_not_receive :reload
      @action.comments
    end

    it "should let you define the attribute when creating the object" do
      @action = Action.create!(comments: "some new comments")
      @action.comments.should == "some new comments"
    end

    it "should let you update the attribute using #update_attribute" do
      @action.update_attribute(:comments, "some new comments")
      @action.comments.should == "some new comments"
    end

    it "should let you update the attribute using #update_attributes" do
      @action.update_attributes(comments: "some new comments")
      @action.comments.should == "some new comments"
    end
  end

  def create_and_reload_action_from_db
    Action.find Action.create(title: "some action", comments: "some comments")
  end
end
