class TableOfContentsTransformer::PublicInspection::RegularFiling < TableOfContentsTransformer::PublicInspection
  def toc_presenter
    @toc_presenter ||= TableOfContentsPresenter.new(
      issue.
        public_inspection_documents.
        regular_filing.
        scoped(:include => :docket_numbers),
      :always_include_parent_agencies => true
    )
  end

  def self.toc_file_exists?(date)
    path_manager = FileSystemPathManager.new(date)
    File.exists?(path_manager.public_inspection_issue_regular_filing_json_toc_path)
  end

  private

  def json_path
    path_manager.public_inspection_issue_regular_filing_json_toc_path
  end
end
