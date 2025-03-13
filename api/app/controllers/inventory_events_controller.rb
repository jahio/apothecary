class InventoryEventsController < ApplicationController
  before_action :check_payload

  def create
    # If we get this far we should have a reasonably valid @inventory_event object
    @inventory_event.save
    render json: @inventory_event.to_json, status: 200
  end

  private

  def check_payload
    @inventory_event = InventoryEvent.new(inventory_event_params)
    [:pharmacy, :drug].each do |x|
      if @inventory_event.send(x).blank?
        render json: {
          message: "Invalid #{x} ID specified",
          inventory_event: @inventory_event.to_h
        }, status: 400
        halt
        return false
      end
    end
  end

  #
  # When testing this, we need a single param key:
  # inventory_event
  #
  # With a plain text JSON value, such as:
  # { "pharmacy_id": "01958840-7054-7909-8465-af9fbab4022b", "drug_id": "01958840-702c-7dab-8b26-5e2edf5582ef", "qty": 30, "operation": "pickup" }
  #
  def inventory_event_params
    JSON.parse(params.expect(:inventory_event))
  end
end
