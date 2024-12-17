# app/models/geotracker_query.rb

require_dependency 'redmine/security'

class GeotrackerQuery
    include Redmine::Security
  
    attr_accessor :project, :user, :filters, :group_by, :column_names, :totalable_names
    attr_reader :errors
  
    def initialize(attributes=nil)
      @filters = {}
      @group_by = nil
      @column_names = []
      @totalable_names = []
      @errors = {}
      
      set_attributes(attributes) if attributes
    end
  
    def locations(options={})
      order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
      
      GeotrackerLocation.
        where(statement).
        where(project_statement).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset]).
        order(order_option).
        preload(:user, :issue)
    end
  
    def location_count
      GeotrackerLocation.
        where(statement).
        where(project_statement).
        count
    end
  
    def available_filters
      @available_filters ||= begin
        filters = {
          'user_id' => {
            type: :list_optional,
            order: 1,
            values: project.users.map { |u| [u.name, u.id.to_s] }
          },
          'issue_id' => {
            type: :tree,
            order: 2,
            values: project.issues.map { |i| ["##{i.id} #{i.subject}", i.id.to_s] }
          },
          'created_on' => {
            type: :date_past,
            order: 3
          },
          'status' => {
            type: :list,
            order: 4,
            values: GeotrackerLocation::STATUSES.map { |s| [l(:"location_status_#{s}"), s] }
          },
          'accuracy' => {
            type: :float,
            order: 5
          },
          'within_radius' => {
            type: :radius_search,
            order: 6
          }
        }
  
        if project
          filters['tracker_id'] = {
            type: :list,
            order: 7,
            values: project.trackers.map { |t| [t.name, t.id.to_s] }
          }
        end
  
        filters
      end
    end
  
    def statement
      filters_clauses = []
      filters.each_key do |field|
        next if field == 'within_radius'
        v = values_for(field).clone
        next unless v.any?
        
        operator = operator_for(field)
        sql = ''
        
        case field
        when 'user_id'
          sql = 'user_id IN (' + v.map{|val| "'#{ActiveRecord::Base.connection.quote_string(val)}'"}.join(',') + ')'
        when 'issue_id'
          sql = 'issue_id IN (' + v.join(',') + ')'
        when 'created_on'
          sql = date_clause('created_at', operator, v)
        when 'status'
          sql = 'status IN (' + v.map{|val| "'#{ActiveRecord::Base.connection.quote_string(val)}'"}.join(',') + ')'
        when 'accuracy'
          sql = numeric_clause('accuracy', operator, v)
        end
  
        filters_clauses << '(' + sql + ')'
      end
  
      # Añadir búsqueda por radio si está presente
      if filters['within_radius']
        v = values_for('within_radius')
        if v.size == 3 # lat, lng, radio en metros
          filters_clauses << radius_search_clause(v[0], v[1], v[2])
        end
      end
  
      filters_clauses.any? ? filters_clauses.join(' AND ') : nil
    end
  
    private
  
    def radius_search_clause(lat, lng, radius)
      "ST_DWithin(coordinates::geography, ST_SetSRID(ST_MakePoint(#{lng}, #{lat}), 4326)::geography, #{radius})"
    end
  
    def date_clause(table_field, operator, values)
      date_clause_from_operator(table_field, operator, values)
    end
  
    def numeric_clause(table_field, operator, values)
      case operator
      when '='
        "#{table_field} = #{values.first.to_f}"
      when '>='
        "#{table_field} >= #{values.first.to_f}"
      when '<='
        "#{table_field} <= #{values.first.to_f}"
      when '><'
        "#{table_field} BETWEEN #{values[0].to_f} AND #{values[1].to_f}"
      end
    end
  
    def project_statement
      project ? ["project_id = ?", project.id] : nil
    end
  end