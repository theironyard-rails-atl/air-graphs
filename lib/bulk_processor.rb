  class BulkProcessor
    def initialize batch_size: 100
      @batch, @batch_size = [], batch_size
    end

    def flush!
      return unless @batch.any?
      $neo.batch *@batch
      @batch.clear
    end

    def method_missing *args
      @batch << args
      flush! if @batch.size >= @batch_size
    end
  end
