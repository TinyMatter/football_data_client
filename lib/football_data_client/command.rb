module FootballDataClient
  class Command
    class BaseAction
      def initialize key, options
        @key = key
        @options = options
      end

      protected

      def client
        @client ||= FootballDataClient::Client.new @key
      end
    end

    class ListSeasonsAction < BaseAction
      def perform!
        seasons = client.seasons_for_year @options[:year]

        seasons.each do |season|
          puts "[#{season.id} - #{season.league_code}] #{season.name}"
        end
      end
    end

    class ListFixturesAction < BaseAction
      def perform!
        fixtures_by_matchday.keys.sort.each do |matchday|
          fixtures = fixtures_by_matchday[matchday]

          puts "== Matchday #{matchday}:"

          fixtures.each do |fixture|
            if fixture.finished?
              puts "\t#{fixture.away_team} (#{fixture.result.goals_away_team}) @ #{fixture.home_team} (#{fixture.result.goals_home_team})\t\t\t\t#{fixture.date.in_time_zone.to_formatted_s(:long)}"
            else
              puts "\t#{fixture.away_team} @ #{fixture.home_team}\t\t#{fixture.date.in_time_zone.to_formatted_s(:long)}"
            end  
          end
        end
      end

      private

      def league_code
        (@options[:league] || "PL").upcase.to_sym
      end

      def pl_season
        @pl_season ||= client.fetch_season_for_league(league_code, @options)
      end

      def pl_fixtures
        @pl_fixtures ||= client.fetch_fixtures_for_season(pl_season).group_by 
      end

      def fixtures_by_matchday
        @fixtures_by_matchday ||= pl_fixtures.group_by &:matchday
      end
    end

    def initialize key, options
      @key = key
      @options = options
    end

    def perform_action!
      Time.zone = @options[:zone] || "London"

      action.perform!
    end

    private

    def action
      @action ||= action_klass.new(@key, @options)
    end

    def action_klass
      {
        "list-fixtures" => ListFixturesAction,
        "list-seasons" => ListSeasonsAction
      }[@options[:action]]
    end
  end
end