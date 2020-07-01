module ElasticsearchIndexer
  INDICES = [
    $entry_repository,
    PublicInspectionDocumentRepository.new(
      index_name: PublicInspectionDocumentRepository::ACTUAL_INDEX_NAME,
      client: DEFAULT_ES_CLIENT
    )
  ]

  def self.create_indices
    INDICES.each {|i| i.create_index!}
  end

  def self.update_mapping
    INDICES.each {|i| i.update_mapping!}
  end

  def self.resync_index_auditing
    EntryChange.delete_all
    entry_change_collection = Entry.
      where(delta: true).
      pluck(:id).
      map{|entry_id| {entry_id: entry_id}}
    
    if entry_change_collection.present?
      EntryChange.insert_all(entry_change_collection)
    end
  end

  ES_TEMP_FILE = "tmp/use_elasticsearch_#{Rails.env}"
  def self.es_enabled?
    SETTINGS['elasticsearch']['enabled']
  end

  BATCH_SIZE = 500
  def self.reindex_entries(recreate_index: false)
    if recreate_index
      $entry_repository.create_index!(force: true)
    end
    total_entries     = Entry.count
    entries_completed = 0
    Entry.pre_joined_for_es_indexing.find_in_batches(batch_size: BATCH_SIZE) do |entry_batch|
      Entry.bulk_index(entry_batch, refresh: false)
      entries_completed += BATCH_SIZE
      puts "Entry Indexing #{(entries_completed.to_f/total_entries * 100).round(2)}% complete"
    end

    $entry_repository.refresh_index!
  end

  def self.handle_entry_changes
    remove_deleted_entries
    reindex_modified_entries
    #NOTE: Once ES is deployed and Sphinx is removed, we may want to consider removing the delta flag from the entries in question after reindexing
  end

  def self.remove_deleted_entries
    deleted_entry_ids.each do |entry_id|
      $entry_repository.delete(entry_id, refresh: false)
    end

    $entry_repository.refresh_index!
  end

  def self.reindex_modified_entries
    Entry.
      where(id: EntryChange.where.not(entry_id: deleted_entry_ids).pluck(:entry_id)).
      find_in_batches(batch_size: BATCH_SIZE) do |entry_batch|
        Entry.bulk_index(entry_batch, refresh: false)
      end

    $entry_repository.refresh_index!
  end

  def self.deleted_entry_ids
    EntryChange.
      joins("LEFT JOIN entries on entry_changes.entry_id = entries.id").
      where("entries.id IS NULL").
      pluck(:entry_id)
  end

  def self.assign_pi_index_alias
    if DEFAULT_ES_CLIENT.indices.exists(index: PublicInspectionDocumentRepository::ACTUAL_INDEX_NAME)
      DEFAULT_ES_CLIENT.indices.update_aliases body: {
        actions: [
          { add: {
            index: PublicInspectionDocumentRepository::ACTUAL_INDEX_NAME,
            alias: PublicInspectionDocumentRepository::ALIAS_NAME,
            } }
        ]
      }
    end
  end

end
