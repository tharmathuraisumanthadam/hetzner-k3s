require "../../node_pool"
require "../../../hetzner/location"

class Configuration::Settings::NodePool::Location
  getter errors : Array(String)
  getter pool : Configuration::MasterNodePool | Configuration::WorkerNodePool
  getter pool_type : Symbol
  getter masters_pool : Configuration::MasterNodePool
  getter all_locations : Array(Hetzner::Location)

  def initialize(@errors, @pool, @pool_type, @masters_pool, @all_locations)
  end

  def self.network_zone_by_location(location)
    case location
    when "ash"
      "ash"
    when "hil"
      "hil"
    when "sin"
      "sin"
    else
      "eu-central"
    end
  end

  def validate
    if masters_pool?
      validate_masters_pool_locations
    else
      validate_worker_pool_location
    end
  end

  private def masters_pool?
    pool_type == :masters
  end

  private def masters_network_zone
    network_zone_by_location(masters_pool.locations.first)
  end

  private def validate_masters_pool_locations
    if masters_pool.locations.uniq.size != masters_pool.instance_count && masters_pool.locations.uniq.size != 1
      errors << "The number of unique locations specified for masters does not match the number of instances"
    else
      validate_masters_locations_and_network_zone
    end
  end

  private def validate_masters_locations_and_network_zone
    return if masters_pool.locations.size > 0 && masters_pool.locations.all? { |loc| location_exists?(loc) } && masters_pool.locations.map { |loc| network_zone_by_location(loc) }.uniq.size == 1
    errors << "All must be in valid locations and in the same same network zone when using a private network"
  end

  private def validate_worker_pool_location
    pool_location = pool.as(Configuration::WorkerNodePool).location
    return if location_exists?(pool_location) && network_zone_by_location(pool_location) == masters_network_zone

    errors << "All workers must be in valid locations and in the same same network zone as the masters when using a private network. If the masters are located in Ashburn, then all the worker must be located in Ashburn too. Same thing for Hillsboro and Singapore. If the masters are located in Germany and/or Finland, then also the workers must all be located in either Germany or Finland since these locations belong to the same network zone."
  end

  private def location_exists?(location_name)
    all_locations.any? { |loc| loc.name == location_name }
  end

  private def network_zone_by_location(location)
    ::Configuration::Settings::NodePool::Location.network_zone_by_location(location)
  end
end
