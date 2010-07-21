class Admin::IssuesController < AdminController
  def index
    @issues = Issue.most_recent(50)
  end
  
  def show
    @publication_date = Date.parse(params[:id])
    @entries_without_sections = Entry.published_on(@publication_date).all(:include => :section_assignments, :conditions => "section_assignments.id IS NULL")
    @sections = Section.all
    @issue_approval = IssueApproval.find_by_publication_date(@publication_date)
  end
  
  def preview
    @sections = Section.all
    @issue = Issue.new(Date.parse(params[:id]))
    @preview = true
    @faux_controller = "special"
    @faux_action = "home"
    render :template => "special/home", :layout => 'application'
  end
end