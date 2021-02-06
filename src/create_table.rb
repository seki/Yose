require_relative 'yose'

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
  db.transaction do |c|
    c.exec("create extension moddatetime;") rescue nil
  end
  db.transaction do |c|
    c.exec("create table #{name} (
      uid uuid
      , obj jsonb
      , mtime timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
      , primary key(uid));")
    c.exec("CREATE TRIGGER #{name}_moddatetime
      BEFORE UPDATE ON world
      FOR EACH ROW
      EXECUTE PROCEDURE moddatetime (mtime);")
    c.exec("CREATE INDEX #{name}_idxgin 
      ON #{name} USING GIN (obj jsonb_path_ops);")
  end
end

if __FILE__ == $0
  create_table
end