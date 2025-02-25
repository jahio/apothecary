require "jennifer"
require "pg"
require "json"

module PharmacyInventoryAPI
  # Point type to represent PostGIS geography points
  struct Point
    property x : Float64
    property y : Float64

    def initialize(@x, @y)
    end

    def to_json
      {
        longitude: @x,
        latitude: @y
      }.to_json
    end

    def to_s
      "POINT(#{@x} #{@y})"
    end
  end

  # Module to handle PostGIS-specific functionality
  module PostGIS
    extend self

    # Create a PostGIS point from lon/lat
    def point(longitude : Float64, latitude : Float64) : Point
      Point.new(longitude, latitude)
    end

    # Calculate distance in meters between two points
    def distance(point1 : Point, point2 : Point) : Float64
      result = Jennifer::QueryBuilder.new.with_sql(
        "SELECT ST_Distance(
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, 
          ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
        ) as distance", 
        [point1.x, point1.y, point2.x, point2.y]
      ).first
      
      result ? result["distance"].as(Float64) : 0.0
    end

    # Create a point from PostGIS representation
    def from_postgis_point(postgis_point : String) : Point
      # Parse from "POINT(lon lat)" format
      match = postgis_point.match(/POINT\(([0-9\.-]+) ([0-9\.-]+)\)/)
      
      if match && match.size >= 3
        Point.new(match[1].to_f, match[2].to_f)
      else
        # Default to (0,0) if unable to parse
        Point.new(0.0, 0.0)
      end
    end

    # Find records within a radius in miles
    def within_radius(table : String, lat : Float64, lng : Float64, radius_miles : Float64)
      radius_meters = radius_miles * 1609.34
      
      Jennifer::QueryBuilder.new.with_sql(
        "SELECT * FROM #{table} 
         WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint($1, $2), 4326), $3)",
        [lng, lat, radius_meters]
      )
    end

    # Register custom converter for PostgreSQL's point type
    class PointConverter < DB::Converter
      def self.from_rs(rs)
        val = rs.read(String | Nil)
        val ? from_postgis_point(val) : Point.new(0.0, 0.0)
      end
      
      def self.to_db(value : Point)
        "POINT(#{value.x} #{value.y})"
      end
    end
  end
end

# Register the custom converter with Jennifer
Jennifer::Config.mapping(
  PharmacyInventoryAPI::Point, 
  {
    "postgres" => PharmacyInventoryAPI::PostGIS::PointConverter
  }
)