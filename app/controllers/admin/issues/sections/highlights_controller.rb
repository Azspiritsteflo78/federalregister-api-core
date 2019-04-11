class Admin::Issues::Sections::HighlightsController < AdminController
  skip_before_filter :verify_authenticity_token

  def create
    @publication_date = Date.parse(params[:issue_id])
    @section = Section.find_by_slug(params[:section_id])
    @section_highlight = SectionHighlight.new(params[:section_highlight])
    @section_highlight.section = @section
    @section_highlight.publication_date = @publication_date
    @section_highlight.save
    @section_highlight.move_to_top
    @redirect_to = admin_issue_section_path(@publication_date.to_s(:mdy_dash), @section)

    unless request.xhr?
      redirect_to @redirect_to
    end
  end

  def update
    @publication_date = Date.parse(params[:issue_id])
    @section = Section.find_by_slug(params[:section_id])
    @section_highlight = SectionHighlight.find_by_publication_date_and_section_id_and_entry_id!(@publication_date, @section, params[:id])

    if @section_highlight.update_attributes(params[:section_highlight])
      respond_to do |wants|
        wants.html do
          redirect_to admin_issue_section_path(@publication_date.to_s(:db), @section)
        end
        wants.js do
          render :nothing => true
        end
      end
    else
      render :action => :edit
    end
  end

  def destroy
    @publication_date = Date.parse(params[:issue_id])
    @section = Section.find_by_slug(params[:section_id])
    @section_highlight = SectionHighlight.find_by_publication_date_and_section_id_and_entry_id!(@publication_date, @section, params[:id])
    @section_highlight.destroy
    render :nothing => true
  end
end
