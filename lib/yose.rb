require "pg"
require "monitor"
require "pp"
require "json"
require "securerandom"

module Yose
  module_function
=begin
create extension moddatetime;

create table world (
uid uuid
, obj jsonb
, mtime timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
, primary key(uid));

CREATE TRIGGER world_moddatetime
  BEFORE UPDATE ON world
  FOR EACH ROW
  EXECUTE PROCEDURE moddatetime (mtime);

CREATE INDEX world_idxgin ON world USING GIN (obj jsonb_path_ops);
=end
  def create_table(name="world")
    db = Yose::DB.instance
    db.conn.exec("create extension moddatetime;") rescue nil
    db.transaction do |c|
      c.exec("create table #{name} (
        uid uuid
        , obj jsonb
        , mtime timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
        , primary key(uid));")
      c.exec("CREATE TRIGGER #{name}_moddatetime
        BEFORE UPDATE ON #{name}
        FOR EACH ROW
        EXECUTE PROCEDURE moddatetime (mtime);")
      c.exec("CREATE INDEX #{name}_idxgin 
        ON #{name} USING GIN (obj jsonb_path_ops);")
    end
  end

  def drop_table(name)
    db = Yose::DB.instance
    db.conn.exec("drop INDEX #{name}_idxgin") rescue nil
    db.conn.exec("drop TRIGGER #{name}_moddatetime on #{name}") rescue nil
    db.conn.exec("drop table #{name}") rescue nil
  end

  class DB
    include MonitorMixin
    def self.instance
      @instance = self.new unless @instance
      @instance.synchronize do
        @instance = self.new unless @instance.ping
      end
      return @instance
    rescue
      nil
    end

    def initialize
      super()
      url = ENV['YOSE_DATABASE_URL'] || ENV['DATABASE_URL'] || 'postgres:///yose'
      @conn = PG.connect(url)
      @conn.type_map_for_results = PG::BasicTypeMapForResults.new(@conn)
    end
    attr :conn

    def ping
      @conn.exec("select 1")
      true
    rescue
      false
    end

    def transaction
      #FIXME
      synchronize do
        @conn.transaction do |c|
          yield(c)
        end
      end
    end
  end

  class Store
    def initialize(name='world')
      @name = name
    end

    def as_json(json)
      (Hash === json) ? json.to_json : json
    end

    def as_pg_time(time)
      time.strftime("%F %T.%6N")
    end
    
    def transaction(&proc)
      DB.instance.transaction(&proc)
    end

    def alloc(json)
      sql =<<EOQ
insert into #{@name}
  (uid, obj) 
values
  ($1, $2)
returning uid::text;
EOQ
      transaction do |c|
        c.exec_params(sql, [SecureRandom.uuid, as_json(json)]).first['uid']
      end
    end

    def alloc!(json)
      sql =<<EOQ
insert into #{@name}
  (uid, obj) 
values
  ($1, $2)
returning uid::text;
EOQ
      transaction do |c|
        json = as_json(json)
        sz = c.exec_params("select count(*) from #{@name} where obj @> $1",
                            [json]).first['count']
        raise "already exist #{json}" if sz > 0
        c.exec_params(sql, [SecureRandom.uuid, json]).first['uid']
      end
    end

    def free(uid)
      sql =<<EOQ
delete from #{@name} where uid = $1 returning obj;
EOQ
      transaction do |c|
        c.exec_params(sql, [uid]).to_a.dig(0, 'obj')
      end
    end
    alias forget free

    def [](uid)
      sql =<<EOQ
select obj from #{@name} where uid = $1 limit 1;
EOQ
      transaction do |c|
        c.exec_params(sql, [uid]).to_a.dig(0, 'obj')
      end
    end

    def mtime(uid)
      sql =<<EOQ
select mtime from #{@name} where uid = $1 limit 1;
EOQ
      transaction do |c|
        c.exec_params(sql, [uid]).to_a.dig(0, 'mtime')
      end
    end

    def search(json)
      sql =<<EOQ
select uid::text, obj, mtime from #{@name} where obj @> $1::jsonb;
EOQ
      transaction do |c|
        c.exec_params(sql, [as_json(json)]).to_a
      end
    end

    def update(uid, json)
      sql =<<EOQ
update #{@name} set obj = obj || $2::jsonb where uid = $1 returning obj;
EOQ
      transaction do |c|
        c.exec_params(sql, [uid, as_json(json)]).to_a.to_a.dig(0, 'obj')
      end
    end
    alias merge update

    def replace(uid, json)
      sql =<<EOQ
update #{@name} set obj = $2::jsonb where uid = $1 returning obj;
EOQ
      transaction do |c|
        c.exec_params(sql, [uid, as_json(json)]).to_a.dig(0, 'obj')
      end
    end

    def delete(uid, key)
      sql =<<EOQ
update #{@name} set obj = obj - $2 where uid = $1 returning obj;
EOQ
      transaction do |c|
        c.exec_params(sql, [uid, key]).to_a.dig(0, 'obj')
      end
    end

    def recent(since)
      sql =<<EOQ
select uid::text, obj, mtime from #{@name} where mtime > $1 order by mtime desc;
EOQ
      transaction do |c|
        c.exec_params(sql, [as_pg_time(since)]).to_a
      end
    end
  end
end

if __FILE__ == $0
  Yose::create_table
end