require "faraday"
require 'faraday_middleware'
require "active_support/all"

module FootballDataClient
  module Models
    class Links
      def initialize links
        @links = links
      end

      def owner
        @links["self"]["href"]
      end

      def method_missing name, *args, &block
        camelized_name = name.to_s.camelize(:lower)

        if @links.keys.include?(camelized_name)
          @links[camelized_name]["href"]
        else
          super
        end
      end
    end

    class Result
      def initialize results={}
        @results = results
      end

      def method_missing name, *args, &block
        camelized_name = name.to_s.camelize(:lower)

        if @results.keys.include?(camelized_name)
          @results[camelized_name]
        else
          super
        end
      end
    end

    class Team
      def self.from_json json={}
        links = Links.new json["_links"]

        self.new json["code"], json["name"], json["shortName"], json["crestUrl"], links
      end

      attr_reader :code, :name, :short_name, :crest_url, :links

      def initialize code, name, short_name, crest_url, links
        @code = code
        @name = name
        @short_name = short_name
        @crest_url = crest_url
        @links = links
      end
    end

    class Fixture
      def self.from_json json={}
        links = Links.new json["_links"]
        result = Result.new json["result"]
        date_time = Time.zone.parse json["date"]

        self.new(date_time, json["status"], json["matchday"], json["homeTeamName"], json["awayTeamName"], result, links)
      end

      attr_reader :date, :status, :matchday, :home_team, :away_team, :result, :links

      def initialize date, status, matchday, home_team, away_team, result, links
        @date = date
        @status = status
        @matchday = matchday
        @home_team = home_team
        @away_team = away_team
        @result = result
        @links = links
      end

      def finished?
        @status.downcase == "finished"
      end
    end

    class Season
      def self.from_json json={}
        links = Links.new json["_links"]
        
        self.new(json["id"], json["caption"], json["league"], json["year"], links, json)
      end

      attr_reader :id, :name, :league_code, :year, :links, :attributes

      def initialize id, name, league_code, year, links, attributes
        @id = id
        @name = name
        @league_code = league_code
        @year = year
        @links = links
        @attributes = attributes
      end

      def matches_league? league_code
        league_code.to_s.downcase == @league_code.to_s.downcase
      end
    end
  end

  class Client
    BASE_URI = "http://api.football-data.org"

    def initialize key
      @key = key
    end

    def fetch_teams_for_season season
      response = connection.get(season.links.teams)

      return [] unless response.success?

      response.body["teams"].map {|json| Models::Team.from_json(json) }
    end

    def fetch_season_for_league league_code, options={}
      seasons = seasons_for_year(options[:year])

      seasons.detect {|season| season.matches_league?(league_code) }
    end

    def fetch_fixtures_for_season season
      response = connection.get(season.links.fixtures)

      return [] unless response.success?

      response.body["fixtures"].map {|json| Models::Fixture.from_json(json) }
    end

    def seasons_for_year year = DataTime.now.year
      response = connection.get("/v1/soccerseasons?season=#{year}")

      return [] unless response.success?

      response.body.map {|json| Models::Season.from_json(json) }
    end

    def connection
      @connection ||= Faraday.new(:url => BASE_URI, headers: { "X-Auth-Token" => @key }) do |conn|
        conn.response :json, :content_type => /\bjson$/
        conn.request :json
        conn.adapter Faraday.default_adapter
      end
    end
  end
end