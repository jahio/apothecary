require 'securerandom'

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  #
  # Before saving the record, generate a new UUID based on v7 of the algorithm.
  # This functionality is part of the Ruby stdlib under the 'securerandom' library.
  # Version 7 has a bit of an advantage over version 4 in that it uses the current
  # UNIX timestamp in its initial generation, leading to some minor measure of
  # consistency/predictability in the output, which will make sorting in databases
  # somewhat easier - perhaps not for *this* application, but certainly for other
  # things talking to the database at some point in the future.
  #
  # See here for more info on v7:
  #   https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-04.html#name-uuid-version-7
  #
  before_create :generate_uuid_v7

  #
  # Since everything is based on UUIDs in our database, we need at minimum:
  #   - the created_at field present in all cases (validation)
  #   - and to set the implicit order column (for Model.first etc.) as created_at
  #     since otherwise Rails will assume, and try to use, an integer-based ID
  #

  self.implicit_order_column = "created_at"

  validates :created_at, presence: true

  private

  def generate_uuid_v7
    return if self.class.attribute_types['id'].type != :uuid

    self.id ||= SecureRandom.uuid_v7
  end

end
