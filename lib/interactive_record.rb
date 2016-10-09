require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = <<-SQL
    PRAGMA table_info('#{table_name}')
    SQL

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |col_info|
      column_names << col_info["name"]
    end
    column_names.compact
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if do |col_name|
      col_name == "id"
    end.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name) == nil
    end
    values.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = #{'name'}"
    DB[:conn].execute(sql)
  end

  def self.find_by(attr_hash)
    sql = "SELECT * FROM #{table_name} WHERE #{attr_hash.keys[0]} = '#{attr_hash.values[0]}'"
    DB[:conn].execute(sql)
  end


end