class RebuildStateInventoryViewsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Start with a new thread per class in SEARCHABLE_VIEWS
    threads = Array.new(DrugSearchService::SEARCHABLE_VIEWS.count) do |i|
      Thread.new do
        DrugSearchService::SEARCHABLE_VIEWS[i].refresh
      end
    end

    # Kick 'em off
    threads.map(&:join)
  end
end
